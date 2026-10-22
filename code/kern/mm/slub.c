/*
 * slub.c —— 简化的 SLUB 内核对象分配器
 *
 * ============================ 设计来源 ============================
 * 参考 Linux v7.2 mm/slub.c 的 sheaf/barn 机制（本次抓取自
 * https://raw.githubusercontent.com/torvalds/linux/v7.2/mm/slub.c，
 * 共 10011 行；仅针对 sheaf/barn 与同步说明部分核对，未逐行通读全部内容）：
 *   - struct slab_sheaf { objects[], size, capacity }：每 CPU 每 cache 一组；
 *   - struct node_barn { lock, sheaves_full/empty, nr_full/nr_empty }：
 *     有界共享池（MAX_FULL_SHEAVES / MAX_EMPTY_SHEAVES = 10）；
 *   - 本地 sheaf 在 !RT 下只关抢占、不做原子操作（快路径不碰全局锁）；
 *   - barn 用 spin_lock_irqsave；flush 时先批量拷到栈数组再释放本地锁；
 *   - 锁序：cpu_hotplug_lock > slab_mutex > (local sheaves, barn->lock,
 *     node->list_lock) > slab_lock > object_map_lock。
 * 本实现按同一层次裁剪：每尺寸类一个 barn（简化为有界共享池）、
 * 单一全局 slab 描述符表（简化 node list）。
 *
 * ============================ 分层布局 ============================
 *   [kmalloc/kfree]
 *        |  尺寸类 16/32/64/128/256/512/1024/2048；更大 -> 连续页 + 32B 头
 *   [每 CPU 每尺寸类 main/sheaf + spare sheaf]   <- 快路径，仅本地临界区
 *        |
 *   [每尺寸类共享 barn]                          <- 有界批量中转
 *        |
 *   [slab：页内定长槽位 + 侵入式空闲链]          <- cache 锁
 *        |
 *   [底层页分配器 best-fit / buddy]              <- 全局 slub_pmm_lock
 *
 * 大对象（>2048 字节）不进 slab：alloc_pages(npages) 连续页，
 * 页首放 32 字节头部（magic/base/npages/pad），返回 用户 = 页首+32，
 * sizeof(头部)==32 保证返回值仍 16 字节对齐；释放时按头部记录的
 * “原始请求页数” free_pages（同时满足 buddy 的 property==n 断言与
 * best-fit 的按 n 回收）。
 *
 * ============================ 关键不变量 ============================
 *  1. 小对象指针 <=> (活跃 slab 范围, 且 (ptr-base) % objsize == 0)；
 *     slab 范围按页分配，彼此不相交，因此归属唯一。
 *  2. slab->inuse = 不在 slab 空闲链上的对象数 = 用户 + sheaf + barn；
 *     inuse==0 当且仅当该 slab 无任何引用，才可以归还页。
 *  3. slab 状态机（均在 cache 锁下）：
 *       新建(EMPTY, 未入链) -> 取用后 PARTIAL(入 partial 链) 或 FULL(不入链)
 *       FULL   --(首个对象回到 slab)--> PARTIAL
 *       PARTIAL --(空闲链被取空)--> FULL
 *       PARTIAL --(最后一个对象回来, inuse==0)--> EMPTY
 *                                   -> 保留在 empty 链(每 cache <= 2 个) 或直接销毁
 *       EMPTY  --(被 refill 取用)--> PARTIAL/FULL
 *  4. 对象归属四态互斥：user / CPU sheaf / barn / slab-freelist；
 *     任一时刻恰好属于其中一种（由所有变更点在同一锁下完成指针搬移保证）。
 *  5. 侵入式空闲链的链接指针写在“空闲对象”内部，因此对象至少 16 字节
 *     且 16 字节对齐（>= 指针宽度）。
 *  6. slab 元数据是静态描述符池（SLUB_MAX_SLABS），按 base 排序的静态
 *     索引数组供锁无关二分查找归属；插入/删除在 index 锁下逐元素移位，
 *     所有中间态保持“有序含重复”，读侧始终收敛到唯一正确区间。
 *
 * ============================ 锁顺序 ============================
 *  1. local  (每 CPU/每尺寸类 sheaf 临界区；内核后端=关本地中断+屏障，
 *             不做原子操作，也不是多核互斥)
 *  2. barn   (每尺寸类共享池)
 *  3. cache  (每尺寸类 slab 链/freelist/inuse/新建销毁)
 *  4. index  (全局描述符池 + 归属索引)
 *  5. pmm    (全局，串行化非线程安全的底层页分配器)
 *  规则：嵌套加锁只允许编号递增（local 永不嵌套任何锁；barn 与 cache
 *  永不嵌套——批量拷贝到栈数组后先释放再取下一把）。
 *  acquire/release：spin_lock 内含 acquire 全屏障，spin_unlock 内含
 *  release 全屏障；local_lock/unlock 关中断 + 屏障。
 *  关中断只用于防同核中断重入自旋死锁，绝不用于替代多核互斥。
 *  快路径（本地 sheaf 命中）不取任何全局锁；kmalloc/kfree 因此是
 *  中断安全的（所有自旋锁都关中断持有）。
 *
 * ============================ 跨 CPU 释放路径 ============================
 *  CPU A: kmalloc -> slab/其他 CPU 的 barn -> 本地 sheaf -> 用户；
 *  对象经任何跨 CPU 通道（本分配器的 barn 锁，或测试自建的同步队列）
 *  传递时都存在 release-acquire 链，因此 CPU B 的 kfree 做锁无关二分查找
 *  时必然能看到该 slab 的索引项（与 Linux 的 virt_to_slab() 无锁读同构）。
 *  CPU B: kfree -> 二分归属 -> 本地 sheaf（快）-> barn（批量中转）->
 *         slab 空闲链（慢，cache 锁）；对象可以留在其他 CPU 的 sheaf/barn
 *         中，后续由任一 CPU 继续分配出去（这是 sheaf/barn 的设计意图）。
 *
 * ============================ 简化限制 ============================
 *  - 单核后端：SLUB_NCPUS=1，CPU 定位来自 entry.S 的 boot_hartid（硬件 ID）；
 *    不以“恒为 0 的 CPU ID”冒充 SMP。CPU 定位/本地临界区/共享锁全部经
 *    slub_port.h 抽象，同一份分配核心可直接接入多线程宿主测试
 *    （tools/host/slub_host_port.c，-DSLUB_HOST_PORT -DSLUB_NCPUS=N）。
 *  - 每尺寸类一个有界 barn（而非 full/empty 双向 sheaf 栈）。
 *  - empty 链每 cache 只保留 SLUB_EMPTY_KEEP 个空 slab，多余立即归还页。
 *  - 归属查找用全局有序索引（O(log n)），不按 node/NUMA 分片。
 *  - 不做对象外元数据（无 per-object header / 无 on-slab 内存布局记录），
 *    slab 尺寸类由指针归属推断；因此重复释放/非法指针只能 panic 诊断，
 *    不能静默恢复。
 *
 * ============================ 固定开销 ============================
 *  slub_fixed_overhead() 返回全部静态结构的 sizeof 之和（描述符池、
 *  归属索引、sheaf/barn 存储、cache/barn 结构、锁与统计），可测量可解释；
 *  slub_init() 会打印该值与回收后的空闲页基线。
 */

#include <slub.h>
#include <slub_port.h>

/* ------------------------- 内部常量 ------------------------- */

/* 每个 sheaf 的最大容量（objsize<=256 用 32，512..2048 用 16） */
#define SLUB_SHEAF_MAX_CAP 32
/* 每 (CPU, 尺寸类) 的 sheaf 存储槽位：main + spare 各一份 */
#define SLUB_SHEAF_SLOTS (2 * SLUB_SHEAF_MAX_CAP)
/* barn 容量 = sheaf 容量的 4 倍 */
#define SLUB_BARN_FACTOR 4
#define SLUB_MAX_BARN (SLUB_BARN_FACTOR * SLUB_SHEAF_MAX_CAP)
/* slab 描述符池：静态上限（页分配通常会先耗尽，这里只是二道保险） */
#define SLUB_MAX_SLABS 1024
/* 单个 slab 的最大页数（本实现最大为 8：2048 尺寸类） */
#define SLUB_MAX_SLAB_PAGES 16
/* 每个 cache 保留的空 slab 数量上限，超出立即归还页 */
#define SLUB_EMPTY_KEEP 2
/* 大对象头部魔数（'SLUBLRG'） */
#define SLUB_MAGIC_LARGE 0x534C55424C524747ULL

/* 大对象头部：32 字节，16 字节对齐（4 个 8 字节字段） */
struct slub_large_hdr {
    uintptr_t magic;
    slub_page_t *base;   /* 底层页描述符（归还时用原始请求页数） */
    size_t npages;       /* 原始请求页数 */
    uintptr_t pad;
};

/* slab 状态（描述符返回池时 state 置 0） */
#define SLUB_SLAB_FULL 1
#define SLUB_SLAB_PARTIAL 2
#define SLUB_SLAB_EMPTY 3

struct slub_slab {
    uintptr_t base;            /* slab 首页内核虚拟地址（页对齐，用于归属查找） */
    slub_page_t *pages;        /* 底层页描述符 */
    unsigned int npages;
    unsigned int capacity;     /* 对象槽数 */
    unsigned int inuse;        /* 不在 slab 空闲链上的对象数 = 用户+sheaf+barn */
    unsigned char cls;         /* 尺寸类（创建后不可变） */
    unsigned char state;       /* SLUB_SLAB_* */
    void *freelist;            /* 侵入式空闲链（链接指针放在空闲对象内） */
    struct slub_slab *next;    /* partial/empty 链（空闲描述符也用它串链） */
};

struct slub_cache {
    size_t objsize;
    unsigned int sheaf_cap;
    unsigned int barn_cap;
    unsigned int slab_pages;
    slub_spinlock_t lock;              /* 保护链表/freelist/inuse/新建销毁 */
    struct slub_slab *partial;
    struct slub_slab *empty;
    unsigned int nr_partial, nr_empty, nr_full, nr_slabs, nr_slab_pages;
    size_t inuse_objs;                 /* 缓存层维护的 Σslab->inuse */
    /* 以下计数均在 cache 锁下更新 */
    size_t stat_refill, stat_flush;
    size_t stat_slab_new, stat_slab_free, stat_page_fail, stat_desc_fail;
};

struct slub_barn {
    slub_spinlock_t lock;
    void **objs;
    unsigned int size, cap;
    size_t stat_get, stat_put;         /* barn 锁下更新 */
};

struct slub_sheaf {
    void **objs;
    unsigned int size, cap;
};

struct slub_cpu_cache {
    struct slub_sheaf main;
    struct slub_sheaf spare;
};

struct slub_cpu_stat {
    size_t alloc_fast, alloc_slow;
    size_t free_fast, free_slow;
    size_t user;                       /* 该 CPU 该尺寸类的用户持有数 */
};

/* ------------------------- 静态存储 ------------------------- */

static const size_t slub_sizes[SLUB_NCLASSES] = {16, 32, 64, 128, 256, 512, 1024,
                                                 2048};

static struct slub_cache slub_caches[SLUB_NCLASSES];
static struct slub_barn slub_barns[SLUB_NCLASSES];
static struct slub_cpu_cache slub_cc[SLUB_NCPUS][SLUB_NCLASSES];
static struct slub_cpu_stat slub_cs[SLUB_NCPUS][SLUB_NCLASSES];

static void *slub_sheaf_store[SLUB_NCPUS][SLUB_NCLASSES][SLUB_SHEAF_SLOTS];
static void *slub_barn_store[SLUB_NCLASSES][SLUB_MAX_BARN];

/* slab 描述符池 + 按 base 升序的归属索引（索引项数 <= 已分配描述符数） */
static struct slub_slab slub_pool[SLUB_MAX_SLABS];
static struct slub_slab *slub_index[SLUB_MAX_SLABS];
static struct slub_slab *slub_pool_free;
static unsigned int slub_index_nr;
static slub_spinlock_t slub_index_lock; /* 层 4 */
static slub_spinlock_t slub_pmm_lock;   /* 层 5 */

static volatile int slub_inited;
static size_t slub_large_user, slub_large_pages; /* slub_pmm_lock 保护 */
static size_t slub_fault_left, slub_fault_hit_cnt;

/* 大对象头部静态断言：32 字节且 16 字节对齐 */
typedef char slub_large_hdr_size_ok[(sizeof(struct slub_large_hdr) ==
                                     SLUB_LARGE_HDR_SIZE)
                                        ? 1
                                        : -1];
typedef char slub_large_hdr_align_ok[(sizeof(struct slub_large_hdr) %
                                      SLUB_MIN_ALIGN == 0)
                                         ? 1
                                         : -1];

/* ------------------------- 小工具 ------------------------- */

static inline unsigned int slub_cpu(void) {
    unsigned int cpu = slub_port_cpu_id();
    if (cpu >= SLUB_NCPUS) {
        slub_port_panic("slub: cpu id %lu >= SLUB_NCPUS %d (build with a "
                        "larger SLUB_NCPUS)",
                        (unsigned long)cpu, SLUB_NCPUS);
    }
    return cpu;
}

static inline int slub_ptr_in_ram(const void *ptr) {
    uintptr_t a = (uintptr_t)ptr;
    return a >= (uintptr_t)slub_port_ram_low() &&
           a < (uintptr_t)slub_port_ram_high();
}

/* 返回 >= size 的最小尺寸类下标；0 或超过最大尺寸返回 -1 */
static int slub_class_of(size_t size) {
    int cls;
    if (size == 0 || size > SLUB_MAX_SMALL_SIZE) return -1;
    for (cls = 0; cls < (int)SLUB_NCLASSES; cls++) {
        if (size <= slub_sizes[cls]) return cls;
    }
    return -1;
}

/* 把 n 个对象压入 sheaf，返回实际压入数（调用方持本地临界区） */
static unsigned int slub_sheaf_push(struct slub_sheaf *sf, void **objs,
                                    unsigned int n) {
    unsigned int i;
    if (n > sf->cap - sf->size) n = sf->cap - sf->size;
    for (i = 0; i < n; i++) sf->objs[sf->size + i] = objs[i];
    sf->size += n;
    return n;
}

/* 取空 sheaf 到栈数组，返回取出数（调用方持本地临界区） */
static unsigned int slub_sheaf_drain(struct slub_sheaf *sf, void **out) {
    unsigned int n = sf->size, i;
    for (i = 0; i < n; i++) out[i] = sf->objs[i];
    sf->size = 0;
    return n;
}

/* ------------------------- slab 归属索引 ------------------------- */

/*
 * 锁无关二分查找：数组始终按 base 升序（插入/删除在 index 锁下逐元素
 * 移位，中间态为“有序含重复”，因此始终收敛）。正确性依赖发布顺序：
 * slab 建立索引在 cache 锁（release）内完成，任何跨 CPU 的对象传递都
 * 经过 release-acquire 链（barn 锁或测试自建同步），所以释放方必能看到。
 */
static struct slub_slab *slub_slab_lookup(const void *ptr) {
    uintptr_t a = (uintptr_t)ptr;
    unsigned int lo = 0, hi = slub_index_nr, mid;
    struct slub_slab *s;

    while (lo < hi) {
        mid = lo + (hi - lo) / 2;
        s = slub_index[mid];
        if (a < s->base) {
            hi = mid;
        } else if (a >= s->base + (uintptr_t)s->npages * SLUB_PAGE_SIZE) {
            lo = mid + 1;
        } else {
            return s;
        }
    }
    return NULL;
}

/* 以下两个函数必须持有 slub_index_lock（层 4） */
static void slub_index_insert_locked(struct slub_slab *s) {
    unsigned int lo = 0, hi = slub_index_nr, mid, i;

    if (slub_index_nr >= SLUB_MAX_SLABS) {
        slub_port_panic("slub: slab registry overflow");
    }
    while (lo < hi) {
        mid = lo + (hi - lo) / 2;
        if (slub_index[mid]->base < s->base)
            lo = mid + 1;
        else
            hi = mid;
    }
    for (i = slub_index_nr; i > lo; i--) slub_index[i] = slub_index[i - 1];
    slub_index[lo] = s;
    slub_index_nr++;
}

static void slub_index_remove_locked(struct slub_slab *s) {
    unsigned int lo = 0, hi = slub_index_nr, mid, i;

    while (lo < hi) {
        mid = lo + (hi - lo) / 2;
        if (slub_index[mid]->base < s->base)
            lo = mid + 1;
        else
            hi = mid;
    }
    if (lo >= slub_index_nr || slub_index[lo] != s) {
        slub_port_panic("slub: slab %lx is not registered",
                        (unsigned long)s->base);
    }
    for (i = lo; i + 1 < slub_index_nr; i++) slub_index[i] = slub_index[i + 1];
    slub_index_nr--;
}

/* ------------------------- 底层页分配（含故障注入） ------------------------- */

static slub_page_t *slub_pages_alloc(size_t npages) {
    slub_page_t *base;
    slub_port_flags_t f;

    slub_port_spin_lock(&slub_pmm_lock, &f);
    if (slub_fault_left != 0) {
        slub_fault_left--;
        slub_fault_hit_cnt++;
        base = NULL;
    } else {
        base = slub_port_pages_alloc(npages);
    }
    slub_port_spin_unlock(&slub_pmm_lock, &f);
    return base;
}

static void slub_pages_free(slub_page_t *base, size_t npages) {
    slub_port_flags_t f;

    slub_port_spin_lock(&slub_pmm_lock, &f);
    slub_port_pages_free(base, npages);
    slub_port_spin_unlock(&slub_pmm_lock, &f);
}

/* ------------------------- 共享 barn ------------------------- */

static unsigned int slub_barn_put(unsigned int cls, void **objs,
                                  unsigned int n) {
    struct slub_barn *b = &slub_barns[cls];
    slub_port_flags_t f;
    unsigned int i, k;

    slub_port_spin_lock(&b->lock, &f);
    i = b->cap - b->size;
    if (i > n) i = n;
    for (k = 0; k < i; k++) b->objs[b->size + k] = objs[k];
    b->size += i;
    if (i != 0) b->stat_put += i;
    slub_port_spin_unlock(&b->lock, &f);
    return i;
}

static unsigned int slub_barn_take(unsigned int cls, void **out,
                                   unsigned int want) {
    struct slub_barn *b = &slub_barns[cls];
    slub_port_flags_t f;
    unsigned int n, k;

    slub_port_spin_lock(&b->lock, &f);
    n = b->size;
    if (n > want) n = want;
    for (k = 0; k < n; k++) out[k] = b->objs[b->size - n + k];
    b->size -= n;
    if (n != 0) b->stat_get += n;
    slub_port_spin_unlock(&b->lock, &f);
    return n;
}

/* ------------------------- slab 生命周期 ------------------------- */

static void slub_slab_unlink_partial(struct slub_cache *c,
                                     struct slub_slab *s) {
    struct slub_slab **pp = &c->partial;

    while (*pp != NULL && *pp != s) pp = &(*pp)->next;
    if (*pp == NULL) {
        slub_port_panic("slub: partial slab %lx is not linked",
                        (unsigned long)s->base);
    }
    *pp = s->next;
    s->next = NULL;
    c->nr_partial--;
}

/* 归还 slab 占用的页（调用方持 cache 锁） */
static void slub_slab_destroy(struct slub_cache *c, struct slub_slab *s) {
    slub_page_t *pages = s->pages;   /* 先取出，描述符回池后可能被复用 */
    unsigned int npages = s->npages;
    slub_port_flags_t f;

    if (s->inuse != 0) {
        slub_port_panic("slub: destroy slab %lx with %lu objects in use",
                        (unsigned long)s->base, (unsigned long)s->inuse);
    }
    slub_port_spin_lock(&slub_index_lock, &f);
    slub_index_remove_locked(s);
    s->state = 0;
    s->freelist = NULL;
    s->next = slub_pool_free;
    slub_pool_free = s;
    slub_port_spin_unlock(&slub_index_lock, &f);

    c->nr_slabs--;
    c->nr_slab_pages -= c->slab_pages;
    c->stat_slab_free++;
    slub_pages_free(pages, npages);
}

/*
 * 新建 slab：分配页 -> 取描述符 -> 初始化 -> 发布到归属索引。
 * 描述符池耗尽时把已分配的页还回去（不泄漏）。调用方持 cache 锁。
 */
static struct slub_slab *slub_slab_create(struct slub_cache *c,
                                           unsigned int cls) {
    slub_page_t *pages;
    struct slub_slab *s;
    slub_port_flags_t f;
    uintptr_t kva;
    unsigned int cap, i;

    pages = slub_pages_alloc(c->slab_pages);
    if (pages == NULL) {
        c->stat_page_fail++;
        return NULL;
    }

    slub_port_spin_lock(&slub_index_lock, &f);
    s = slub_pool_free;
    if (s != NULL) slub_pool_free = s->next;
    slub_port_spin_unlock(&slub_index_lock, &f);

    if (s == NULL) {
        slub_pages_free(pages, c->slab_pages);
        c->stat_desc_fail++;
        return NULL;
    }

    /* 初始化（尚未进索引，其他 CPU 不可见） */
    kva = (uintptr_t)slub_port_page_kva(pages);
    cap = (unsigned int)((c->slab_pages * SLUB_PAGE_SIZE) / c->objsize);
    s->base = kva;
    s->pages = pages;
    s->npages = c->slab_pages;
    s->capacity = cap;
    s->inuse = 0;
    s->cls = (unsigned char)cls;
    s->state = SLUB_SLAB_EMPTY; /* 尚未入链，由 refill 决定 PARTIAL/FULL */
    s->next = NULL;
    s->freelist = NULL;
    for (i = 0; i < cap; i++) {
        void *obj = (void *)(kva + (uintptr_t)i * c->objsize);
        *(void **)obj = s->freelist;
        s->freelist = obj;
    }

    /* 发布（index 锁 unlock 自带 release 屏障） */
    slub_port_spin_lock(&slub_index_lock, &f);
    slub_index_insert_locked(s);
    slub_port_spin_unlock(&slub_index_lock, &f);

    c->nr_slabs++;
    c->nr_slab_pages += c->slab_pages;
    c->stat_slab_new++;
    return s;
}

/* slab 层补充：partial -> empty -> 新建，直到凑满 want 或无资源（持 cache 锁） */
static unsigned int slub_slab_refill(unsigned int cls, void **out,
                                     unsigned int want) {
    struct slub_cache *c = &slub_caches[cls];
    slub_port_flags_t f;
    unsigned int got = 0;

    slub_port_spin_lock(&c->lock, &f);
    while (got < want) {
        struct slub_slab *s;

        if (c->partial != NULL) {
            s = c->partial;
            c->partial = s->next;
            s->next = NULL;
            c->nr_partial--;
        } else if (c->empty != NULL) {
            s = c->empty;
            c->empty = s->next;
            s->next = NULL;
            c->nr_empty--;
        } else {
            s = slub_slab_create(c, cls);
            if (s == NULL) break; /* 页耗尽 / 描述符耗尽 */
        }

        while (got < want && s->freelist != NULL) {
            void *obj = s->freelist;
            s->freelist = *(void **)obj;
            s->inuse++;
            out[got++] = obj;
        }

        if (s->freelist == NULL) {
            s->state = SLUB_SLAB_FULL;
            c->nr_full++;
        } else {
            s->state = SLUB_SLAB_PARTIAL;
            s->next = c->partial;
            c->partial = s;
            c->nr_partial++;
        }
    }
    c->inuse_objs += got;
    c->stat_refill += got;
    slub_port_spin_unlock(&c->lock, &f);
    return got;
}

/* 把一个对象放回 slab 空闲链（调用方持 cache 锁） */
static void slub_slab_release_obj(struct slub_cache *c, unsigned int cls,
                                  void *obj) {
    struct slub_slab *s = slub_slab_lookup(obj);
    int was_full;

    if (s == NULL || s->cls != cls) {
        slub_port_panic("slub: object %lx does not belong to class %lu",
                        (unsigned long)obj, (unsigned long)cls);
    }
    if (((uintptr_t)obj - s->base) % c->objsize != 0) {
        slub_port_panic("slub: object %lx is not at a slot boundary",
                        (unsigned long)obj);
    }
    if (s->state == SLUB_SLAB_EMPTY) {
        slub_port_panic("slub: object %lx comes from an empty slab",
                        (unsigned long)obj);
    }

    was_full = (s->state == SLUB_SLAB_FULL);
    *(void **)obj = s->freelist; /* 侵入式空闲链 */
    s->freelist = obj;
    s->inuse--;

    if (s->inuse == 0) {
        /* 最后一个引用消失：slab 变空 -> 摘链，保留或归还页 */
        if (s->state == SLUB_SLAB_PARTIAL) {
            slub_slab_unlink_partial(c, s);
        } else if (s->state == SLUB_SLAB_FULL) {
            c->nr_full--;
        }
        s->state = SLUB_SLAB_EMPTY;
        if (c->nr_empty < SLUB_EMPTY_KEEP) {
            s->next = c->empty;
            c->empty = s;
            c->nr_empty++;
        } else {
            slub_slab_destroy(c, s);
        }
    } else if (was_full) {
        s->state = SLUB_SLAB_PARTIAL;
        s->next = c->partial;
        c->partial = s;
        c->nr_partial++;
        c->nr_full--;
    }
    c->inuse_objs--;
    c->stat_flush++;
}

/* ------------------------- 对象归集路径 ------------------------- */

#define SLUB_PUT_ALL 0  /* sheaf -> barn -> slab 全级联 */
#define SLUB_PUT_SLAB 1 /* 只回 slab（slub_shrink 用） */

static void slub_put_objects(unsigned int cls, void **objs, unsigned int n,
                             int target) {
    struct slub_cache *c = &slub_caches[cls];
    slub_port_flags_t f;
    unsigned int i = 0;

    if (target == SLUB_PUT_ALL) {
        struct slub_cpu_cache *cc = &slub_cc[slub_cpu()][cls];

        slub_port_local_lock(&f);
        i += slub_sheaf_push(&cc->main, objs + i, n - i);
        i += slub_sheaf_push(&cc->spare, objs + i, n - i);
        slub_port_local_unlock(&f);
        if (i == n) return;

        i += slub_barn_put(cls, objs + i, n - i); /* 批量拷贝后已释放本地锁 */
        if (i == n) return;
    }

    slub_port_spin_lock(&c->lock, &f);
    for (; i < n; i++) slub_slab_release_obj(c, cls, objs[i]);
    slub_port_spin_unlock(&c->lock, &f);
}

/* ------------------------- 分配 ------------------------- */

static void *slub_alloc_small(unsigned int cls) {
    struct slub_cache *c = &slub_caches[cls];
    unsigned int cpu = slub_cpu();
    slub_port_flags_t f;
    void *batch[SLUB_SHEAF_MAX_CAP];
    unsigned int n;
    void *result;

    /* 快路径：本地 main/spare sheaf，仅本地临界区，不碰全局锁 */
    slub_port_local_lock(&f);
    if (slub_cc[cpu][cls].main.size != 0) {
        result = slub_cc[cpu][cls].main.objs[--slub_cc[cpu][cls].main.size];
        slub_cs[cpu][cls].alloc_fast++;
        slub_cs[cpu][cls].user++;
        slub_port_local_unlock(&f);
        return result;
    }
    if (slub_cc[cpu][cls].spare.size != 0) {
        result = slub_cc[cpu][cls].spare.objs[--slub_cc[cpu][cls].spare.size];
        slub_cs[cpu][cls].alloc_fast++;
        slub_cs[cpu][cls].user++;
        slub_port_local_unlock(&f);
        return result;
    }
    slub_port_local_unlock(&f);

    /* 慢路径 1：批量从共享 barn 取（barn 锁） */
    n = slub_barn_take(cls, batch, c->sheaf_cap);
    /* 慢路径 2：slab 层补充（cache 锁，可能新建 slab 走页分配器） */
    if (n == 0) n = slub_slab_refill(cls, batch, c->sheaf_cap);
    if (n == 0) return NULL;

    result = batch[0];
    if (n > 1) slub_put_objects(cls, batch + 1, n - 1, SLUB_PUT_ALL);

    slub_port_local_lock(&f);
    slub_cs[cpu][cls].alloc_slow++;
    slub_cs[cpu][cls].user++;
    slub_port_local_unlock(&f);
    return result;
}

static void *slub_alloc_large(size_t size) {
    size_t bytes, npages;
    slub_page_t *base;
    struct slub_large_hdr *h;
    slub_port_flags_t f;

    /* 逐项溢出检查 */
    if (size > SIZE_MAX - SLUB_LARGE_HDR_SIZE) return NULL;
    bytes = size + SLUB_LARGE_HDR_SIZE;
    if (bytes > SIZE_MAX - (SLUB_PAGE_SIZE - 1)) return NULL;
    npages = (bytes + SLUB_PAGE_SIZE - 1) / SLUB_PAGE_SIZE; /* 无乘法 */

    base = slub_pages_alloc(npages);
    if (base == NULL) return NULL;

    h = (struct slub_large_hdr *)slub_port_page_kva(base);
    h->magic = SLUB_MAGIC_LARGE;
    h->base = base;
    h->npages = npages;
    h->pad = 0;

    slub_port_spin_lock(&slub_pmm_lock, &f);
    slub_large_user++;
    slub_large_pages += npages;
    slub_port_spin_unlock(&slub_pmm_lock, &f);

    return (char *)h + SLUB_LARGE_HDR_SIZE; /* 页对齐 + 32 => 16 对齐 */
}

void *kmalloc(size_t size) {
    int cls;

    if (size == 0) return NULL;
    if (slub_inited == 0) {
        slub_port_panic("slub: kmalloc before slub_init");
    }

    cls = slub_class_of(size);
    if (cls >= 0) return slub_alloc_small((unsigned int)cls);
    return slub_alloc_large(size);
}

/* ------------------------- 释放 ------------------------- */

static void slub_free_small(unsigned int cls, void *ptr) {
    unsigned int cpu = slub_cpu();
    slub_port_flags_t f;

    slub_port_local_lock(&f);
    slub_cs[cpu][cls].user--;
    /* 快路径：本地 sheaf */
    if (slub_cc[cpu][cls].main.size < slub_cc[cpu][cls].main.cap) {
        slub_cc[cpu][cls].main.objs[slub_cc[cpu][cls].main.size++] = ptr;
        slub_cs[cpu][cls].free_fast++;
        slub_port_local_unlock(&f);
        return;
    }
    if (slub_cc[cpu][cls].spare.size < slub_cc[cpu][cls].spare.cap) {
        slub_cc[cpu][cls].spare.objs[slub_cc[cpu][cls].spare.size++] = ptr;
        slub_cs[cpu][cls].free_fast++;
        slub_port_local_unlock(&f);
        return;
    }
    slub_cs[cpu][cls].free_slow++;
    slub_port_local_unlock(&f);

    /* 本地已满：进入共享层（barn 有界 -> slab 空闲链） */
    slub_put_objects(cls, &ptr, 1, SLUB_PUT_ALL);
}

static void slub_free_large(void *ptr) {
    uintptr_t a = (uintptr_t)ptr;
    struct slub_large_hdr *h = (struct slub_large_hdr *)(a - SLUB_LARGE_HDR_SIZE);
    slub_page_t *base;
    size_t npages;

    if (h->magic != SLUB_MAGIC_LARGE) {
        slub_port_panic("slub: kfree(%lx): no slab and no valid large header "
                        "(double free or foreign pointer)",
                        (unsigned long)a);
    }
    if ((uintptr_t)slub_port_page_kva(h->base) + SLUB_LARGE_HDR_SIZE != a ||
        h->npages == 0) {
        slub_port_panic("slub: kfree(%lx): corrupt large object header",
                        (unsigned long)a);
    }
    base = h->base;
    npages = h->npages;
    h->magic = 0; /* 释放后置空：重复释放会被上面的魔数检查抓到 */

    slub_port_flags_t f;
    slub_port_spin_lock(&slub_pmm_lock, &f);
    slub_large_user--;
    slub_large_pages -= npages;
    slub_port_pages_free(base, npages); /* 用原始请求页数 */
    slub_port_spin_unlock(&slub_pmm_lock, &f);
}

void kfree(void *ptr) {
    struct slub_slab *s;

    if (ptr == NULL) return; /* 契约：无操作 */
    if (slub_inited == 0) {
        slub_port_panic("slub: kfree before slub_init");
    }
    if (((uintptr_t)ptr & (SLUB_MIN_ALIGN - 1)) != 0) {
        slub_port_panic("slub: kfree(%lx): not %d-byte aligned",
                        (unsigned long)(uintptr_t)ptr, SLUB_MIN_ALIGN);
    }

#ifdef SLUB_DEBUG
    /* 深度诊断：重复释放 / 非法指针（正常路径默认关闭） */
    slub_check_ptr(ptr);
#endif

    /* 归属查找（锁无关二分；失败则按大对象处理） */
    s = slub_slab_lookup(ptr);
    if (s != NULL) {
        unsigned int cls = s->cls;
        if (((uintptr_t)ptr - s->base) % slub_caches[cls].objsize != 0) {
            slub_port_panic("slub: kfree(%lx): not a slot start of its slab",
                            (unsigned long)(uintptr_t)ptr);
        }
        slub_free_small(cls, ptr);
        return;
    }

    /* 指针合法性边界：大对象头必须落在 RAM 映射内再解引用 */
    if (!slub_ptr_in_ram(ptr) ||
        (uintptr_t)ptr < (uintptr_t)slub_port_ram_low() + SLUB_LARGE_HDR_SIZE) {
        slub_port_panic("slub: kfree(%lx): pointer outside RAM",
                        (unsigned long)(uintptr_t)ptr);
    }
    slub_free_large(ptr);
}

/* ------------------------- shrink ------------------------- */

/*
 * 回收空闲内存：排空每 CPU sheaf 与共享 barn -> 归还空 slab 的页。
 * 前提：所有调用者静止（无并发 kmalloc/kfree，无对象正在跨 CPU 传递）。
 * 不释放仍被用户持有的对象；大对象保持不动（它们由用户持有）。
 */
void slub_shrink(void) {
    unsigned int cls, cpu;

    if (slub_inited == 0) return;

    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
        struct slub_cache *c = &slub_caches[cls];
        struct slub_barn *b = &slub_barns[cls];
        void *batch[SLUB_SHEAF_MAX_CAP];
        slub_port_flags_t f;
        unsigned int n;

        /* 1) CPU 本地 sheaf -> slab 层（静止态下可逐 CPU 排空） */
        for (cpu = 0; cpu < SLUB_NCPUS; cpu++) {
            slub_port_local_lock(&f);
            n = slub_sheaf_drain(&slub_cc[cpu][cls].main, batch);
            slub_port_local_unlock(&f);
            if (n != 0) slub_put_objects(cls, batch, n, SLUB_PUT_SLAB);

            slub_port_local_lock(&f);
            n = slub_sheaf_drain(&slub_cc[cpu][cls].spare, batch);
            slub_port_local_unlock(&f);
            if (n != 0) slub_put_objects(cls, batch, n, SLUB_PUT_SLAB);
        }

        /* 2) 共享 barn -> slab 层（分批，不经过 barn） */
        for (;;) {
            unsigned int k;
            slub_port_spin_lock(&b->lock, &f);
            k = b->size;
            if (k > SLUB_SHEAF_MAX_CAP) k = SLUB_SHEAF_MAX_CAP;
            for (n = 0; n < k; n++) batch[n] = b->objs[b->size - k + n];
            b->size -= k;
            slub_port_spin_unlock(&b->lock, &f);
            if (k == 0) break;
            slub_put_objects(cls, batch, k, SLUB_PUT_SLAB);
        }

        /* 3) 归还所有空 slab；partial 链上的 slab 必然有活跃对象 */
        slub_port_spin_lock(&c->lock, &f);
        {
            struct slub_slab *s;
            for (s = c->partial; s != NULL; s = s->next) {
                slub_port_assert(s->inuse > 0);
            }
        }
        while (c->empty != NULL) {
            struct slub_slab *s = c->empty;
            c->empty = s->next;
            s->next = NULL;
            c->nr_empty--;
            slub_slab_destroy(c, s);
        }
        slub_port_spin_unlock(&c->lock, &f);
    }
}

/* ------------------------- 只读信息 / 统计 ------------------------- */

size_t slub_nr_classes(void) {
    return SLUB_NCLASSES;
}

int slub_size_to_class(size_t size) {
    return slub_class_of(size);
}

size_t slub_class_size(size_t cls) {
    if (cls >= SLUB_NCLASSES) return 0;
    return slub_sizes[cls];
}

int slub_get_class_info(size_t cls, struct slub_class_info *out) {
    struct slub_class_info info = {0};
    struct slub_cache *c;
    struct slub_barn *b;
    slub_port_flags_t f;
    unsigned int cpu;

    if (out == NULL || cls >= SLUB_NCLASSES) return -1;
    c = &slub_caches[cls];
    b = &slub_barns[cls];

    slub_port_spin_lock(&c->lock, &f);
    info.nr_slabs = c->nr_slabs;
    info.nr_partial = c->nr_partial;
    info.nr_full = c->nr_full;
    info.nr_empty = c->nr_empty;
    info.slab_pages_used = c->nr_slab_pages;
    info.inuse_objs = c->inuse_objs;
    info.slab_new = c->stat_slab_new;
    info.slab_free = c->stat_slab_free;
    info.slab_fail = c->stat_page_fail + c->stat_desc_fail;
    info.refill = c->stat_refill;
    info.flush = c->stat_flush;
    slub_port_spin_unlock(&c->lock, &f);

    slub_port_spin_lock(&b->lock, &f);
    info.barn_get = b->stat_get;
    info.barn_put = b->stat_put;
    slub_port_spin_unlock(&b->lock, &f);

    for (cpu = 0; cpu < SLUB_NCPUS; cpu++) {
        slub_port_local_lock(&f);
        info.alloc_fast += slub_cs[cpu][cls].alloc_fast;
        info.alloc_slow += slub_cs[cpu][cls].alloc_slow;
        info.free_fast += slub_cs[cpu][cls].free_fast;
        info.free_slow += slub_cs[cpu][cls].free_slow;
        info.user_objs += slub_cs[cpu][cls].user;
        slub_port_local_unlock(&f);
    }

    info.objsize = slub_sizes[cls];
    info.sheaf_cap = c->sheaf_cap;
    info.barn_cap = c->barn_cap;
    info.slab_pages = c->slab_pages;
    info.objs_per_slab = c->slab_pages * SLUB_PAGE_SIZE / c->objsize;
    *out = info;
    return 0;
}

size_t slub_user_objects(void) {
    size_t total = 0;
    unsigned int cpu, cls;
    slub_port_flags_t f;

    for (cpu = 0; cpu < SLUB_NCPUS; cpu++) {
        slub_port_local_lock(&f);
        for (cls = 0; cls < SLUB_NCLASSES; cls++) total += slub_cs[cpu][cls].user;
        slub_port_local_unlock(&f);
    }
    slub_port_spin_lock(&slub_pmm_lock, &f);
    total += slub_large_user;
    slub_port_spin_unlock(&slub_pmm_lock, &f);
    return total;
}

size_t slub_large_objects(void) {
    size_t n;
    slub_port_flags_t f;

    slub_port_spin_lock(&slub_pmm_lock, &f);
    n = slub_large_user;
    slub_port_spin_unlock(&slub_pmm_lock, &f);
    return n;
}

size_t slub_slab_pages(void) {
    size_t total = 0;
    unsigned int cls;
    slub_port_flags_t f;

    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
        slub_port_spin_lock(&slub_caches[cls].lock, &f);
        total += slub_caches[cls].nr_slab_pages;
        slub_port_spin_unlock(&slub_caches[cls].lock, &f);
    }
    slub_port_spin_lock(&slub_pmm_lock, &f);
    total += slub_large_pages;
    slub_port_spin_unlock(&slub_pmm_lock, &f);
    return total;
}

size_t slub_fixed_overhead(void) {
    return sizeof(slub_caches) + sizeof(slub_barns) + sizeof(slub_cc) +
           sizeof(slub_cs) + sizeof(slub_sheaf_store) + sizeof(slub_barn_store) +
           sizeof(slub_pool) + sizeof(slub_index) + sizeof(slub_pool_free) +
           sizeof(slub_index_nr) + sizeof(slub_index_lock) +
           sizeof(slub_pmm_lock) + sizeof(slub_inited) +
           sizeof(slub_large_user) + sizeof(slub_large_pages) +
           sizeof(slub_fault_left) + sizeof(slub_fault_hit_cnt) +
           sizeof(slub_sizes);
}

/* ------------------------- 故障注入 ------------------------- */

void slub_fault_inject(size_t npages) {
    slub_port_flags_t f;

    slub_port_spin_lock(&slub_pmm_lock, &f);
    slub_fault_left = npages;
    slub_port_spin_unlock(&slub_pmm_lock, &f);
}

void slub_fault_clear(void) {
    slub_port_flags_t f;

    slub_port_spin_lock(&slub_pmm_lock, &f);
    slub_fault_left = 0;
    slub_port_spin_unlock(&slub_pmm_lock, &f);
}

size_t slub_fault_hits(void) {
    size_t n;
    slub_port_flags_t f;

    slub_port_spin_lock(&slub_pmm_lock, &f);
    n = slub_fault_hit_cnt;
    slub_port_spin_unlock(&slub_pmm_lock, &f);
    return n;
}

/* ------------------------- 调试检查 ------------------------- */

/*
 * 校验 ptr 是否为“当前可释放”的对象，有问题直接 panic。
 * 诊断路径会遍历各 CPU 的 sheaf / barn / slab 空闲链（只读），
 * 建议在静止态调用；内核单核下 kfree 前置调用是安全的。
 */
void slub_check_ptr(void *ptr) {
    uintptr_t a = (uintptr_t)ptr;
    struct slub_slab *s;
    unsigned int cls, cpu, i, k;

    if (ptr == NULL) return;
    if ((a & (SLUB_MIN_ALIGN - 1)) != 0) {
        slub_port_panic("slub: pointer %lx is not %d-byte aligned",
                        (unsigned long)a, SLUB_MIN_ALIGN);
    }
    if (!slub_ptr_in_ram(ptr)) {
        slub_port_panic("slub: pointer %lx is outside RAM", (unsigned long)a);
    }

    s = slub_slab_lookup(ptr);
    if (s != NULL) {
        cls = s->cls;
        if ((a - s->base) % slub_caches[cls].objsize != 0) {
            slub_port_panic("slub: pointer %lx is not a slot start",
                            (unsigned long)a);
        }
        /* 重复释放检测：对象若还在 sheaf/barn/空闲链上，说明已释放过 */
        for (cpu = 0; cpu < SLUB_NCPUS; cpu++) {
            struct slub_sheaf *sf[2];
            sf[0] = &slub_cc[cpu][cls].main;
            sf[1] = &slub_cc[cpu][cls].spare;
            for (k = 0; k < 2; k++) {
                for (i = 0; i < sf[k]->size; i++) {
                    if (sf[k]->objs[i] == ptr) {
                        slub_port_panic("slub: double free of %lx (still in a "
                                        "sheaf)",
                                        (unsigned long)a);
                    }
                }
            }
        }
        for (i = 0; i < slub_barns[cls].size; i++) {
            if (slub_barns[cls].objs[i] == ptr) {
                slub_port_panic("slub: double free of %lx (still in the barn)",
                                (unsigned long)a);
            }
        }
        {
            void *o;
            for (o = s->freelist; o != NULL; o = *(void **)o) {
                if (o == ptr) {
                    slub_port_panic("slub: double free of %lx (already on the "
                                    "slab freelist)",
                                    (unsigned long)a);
                }
            }
        }
        return;
    }

    /* 不属于任何 slab：应当是大对象 */
    if (a < (uintptr_t)slub_port_ram_low() + SLUB_LARGE_HDR_SIZE) {
        slub_port_panic("slub: pointer %lx is too low to carry a header",
                        (unsigned long)a);
    }
    {
        struct slub_large_hdr *h =
            (struct slub_large_hdr *)(a - SLUB_LARGE_HDR_SIZE);
        if (h->magic != SLUB_MAGIC_LARGE) {
            slub_port_panic("slub: pointer %lx has neither a slab nor a valid "
                            "large header (double free or foreign pointer)",
                            (unsigned long)a);
        }
        if ((uintptr_t)slub_port_page_kva(h->base) + SLUB_LARGE_HDR_SIZE != a ||
            h->npages == 0) {
            slub_port_panic("slub: large object header at %lx is inconsistent",
                            (unsigned long)a);
        }
    }
}

/* ------------------------- 初始化 ------------------------- */

/* 启动冒烟：最小功能自检（契约 / 各尺寸类对齐写读 / 大对象） */
static void slub_smoke(void) {
    unsigned char *p;
    size_t i, sz;
    int cls;

    if (kmalloc(0) != NULL) {
        slub_port_panic("slub_smoke: kmalloc(0) must be NULL");
    }
    kfree(NULL); /* 无操作 */

    /* 每个尺寸类：分配 -> 16 对齐 -> 整对象写读 -> 释放 */
    for (cls = 0; cls < (int)SLUB_NCLASSES; cls++) {
        sz = slub_sizes[cls];
        p = kmalloc(sz);
        if (p == NULL) {
            slub_port_panic("slub_smoke: class %d allocation failed", cls);
        }
        if (((uintptr_t)p & (SLUB_MIN_ALIGN - 1)) != 0) {
            slub_port_panic("slub_smoke: class %d alignment violated", cls);
        }
        for (i = 0; i < sz; i++) p[i] = (unsigned char)(0x40 + cls + i);
        for (i = 0; i < sz; i++) {
            if (p[i] != (unsigned char)(0x40 + cls + i)) {
                slub_port_panic("slub_smoke: class %d data mismatch", cls);
            }
        }
        slub_check_ptr(p); /* 调试检查接口：活对象应通过校验 */
        kfree(p);
    }

    /* 大对象路径（连续页 + 32 字节头部） */
    p = kmalloc(SLUB_MAX_SMALL_SIZE + 1);
    if (p == NULL) {
        slub_port_panic("slub_smoke: large allocation failed");
    }
    if (((uintptr_t)p & (SLUB_MIN_ALIGN - 1)) != 0) {
        slub_port_panic("slub_smoke: large alignment violated");
    }
    for (i = 0; i < SLUB_MAX_SMALL_SIZE + 1; i++) p[i] = (unsigned char)(i * 3);
    for (i = 0; i < SLUB_MAX_SMALL_SIZE + 1; i++) {
        if (p[i] != (unsigned char)(i * 3)) {
            slub_port_panic("slub_smoke: large object data mismatch");
        }
    }
    slub_check_ptr(p);
    kfree(p);

    slub_port_printf("slub_smoke: 8 classes + large alloc/write/free OK\n");
}

void slub_init(void) {
    unsigned int cls, cpu, i;

    if (slub_inited != 0) return;

    slub_port_spin_init(&slub_index_lock);
    slub_port_spin_init(&slub_pmm_lock);

    /* slab 描述符池 */
    for (i = 0; i < SLUB_MAX_SLABS; i++) {
        slub_pool[i].state = 0;
        slub_pool[i].next = (i + 1 < SLUB_MAX_SLABS) ? &slub_pool[i + 1] : NULL;
    }
    slub_pool_free = &slub_pool[0];
    slub_index_nr = 0;

    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
        struct slub_cache *c = &slub_caches[cls];
        unsigned int sheaf_cap =
            (slub_sizes[cls] <= 256) ? SLUB_SHEAF_MAX_CAP : 16;
        unsigned int barn_cap = sheaf_cap * SLUB_BARN_FACTOR;
        unsigned int slab_pages =
            (unsigned int)((sheaf_cap * slub_sizes[cls] + SLUB_PAGE_SIZE - 1) /
                           SLUB_PAGE_SIZE);

        slub_port_assert(sheaf_cap <= SLUB_SHEAF_MAX_CAP);
        slub_port_assert(barn_cap <= SLUB_MAX_BARN);
        slub_port_assert(slab_pages >= 1 && slab_pages <= SLUB_MAX_SLAB_PAGES);
        /* 一次补充（sheaf 容量）必须落在一个 slab 内 */
        slub_port_assert(slab_pages * SLUB_PAGE_SIZE / slub_sizes[cls] >=
                         sheaf_cap);

        c->objsize = slub_sizes[cls];
        c->sheaf_cap = sheaf_cap;
        c->barn_cap = barn_cap;
        c->slab_pages = slab_pages;
        slub_port_spin_init(&c->lock);
        c->partial = NULL;
        c->empty = NULL;
        c->nr_partial = c->nr_empty = c->nr_full = 0;
        c->nr_slabs = c->nr_slab_pages = 0;
        c->inuse_objs = 0;
        c->stat_refill = c->stat_flush = 0;
        c->stat_slab_new = c->stat_slab_free = 0;
        c->stat_page_fail = c->stat_desc_fail = 0;

        slub_port_spin_init(&slub_barns[cls].lock);
        slub_barns[cls].objs = slub_barn_store[cls];
        slub_barns[cls].size = 0;
        slub_barns[cls].cap = barn_cap;
        slub_barns[cls].stat_get = 0;
        slub_barns[cls].stat_put = 0;

        for (cpu = 0; cpu < SLUB_NCPUS; cpu++) {
            slub_cc[cpu][cls].main.objs = slub_sheaf_store[cpu][cls];
            slub_cc[cpu][cls].main.size = 0;
            slub_cc[cpu][cls].main.cap = sheaf_cap;
            slub_cc[cpu][cls].spare.objs = slub_sheaf_store[cpu][cls] + sheaf_cap;
            slub_cc[cpu][cls].spare.size = 0;
            slub_cc[cpu][cls].spare.cap = sheaf_cap;
            slub_cs[cpu][cls].alloc_fast = 0;
            slub_cs[cpu][cls].alloc_slow = 0;
            slub_cs[cpu][cls].free_fast = 0;
            slub_cs[cpu][cls].free_slow = 0;
            slub_cs[cpu][cls].user = 0;
        }
    }

    slub_large_user = 0;
    slub_large_pages = 0;
    slub_fault_left = 0;
    slub_fault_hit_cnt = 0;
    slub_inited = 1;

    slub_smoke();
    slub_shrink(); /* 冒烟用到的 slab 全部回收，回到干净基线 */

    slub_port_printf("slub_init: %d classes, %d cpus, fixed overhead %lu "
                     "bytes, nr_free_pages %lu\n",
                     (int)SLUB_NCLASSES, (int)SLUB_NCPUS,
                     (unsigned long)slub_fixed_overhead(),
                     (unsigned long)slub_port_nr_free_pages());
}
