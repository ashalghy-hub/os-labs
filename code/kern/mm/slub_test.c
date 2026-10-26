/*
 * slub_test.c —— SLUB 分配器的功能 / 布局 / 数据完整性 / 释放复用 /
 *                回收 / 故障恢复 测试套件（内核与宿主共享同一实现）
 *
 * 构建开关：
 *   SLUB_TEST          定义后本文件才产出代码（内核默认构建为空翻译单元，
 *                      正常启动不会执行任何压力测试）。
 *   SLUB_TEST_SEED     随机种子覆盖（默认固定值；运行开始时打印）。
 *
 * 使用的被测接口（全部来自 slub.h，只读统计来自 slub_get_class_info 等）：
 *   kmalloc / kfree / slub_shrink / slub_size_to_class / slub_class_size /
 *   slub_get_class_info / slub_user_objects / slub_slab_pages /
 *   slub_fault_inject / slub_fault_clear / slub_fault_hits / slub_check_ptr
 *
 * 测试自身的记录全部使用本文件的静态数组（不调用待测 kmalloc，
 * 避免循环依赖与统计污染）。
 *
 * 输出约定（供 tools/slub_test/run_slub_test.sh 自动判定）：
 *   SLUB_TEST_BEGIN  ...          套件开始（含种子/CPU 数/尺寸类数）
 *   SLUB_TEST_CASE <name> PASS    单个用例通过
 *   SLUB_TEST_FAIL case=... why=... size=... iters=... cpu=... seed=...
 *                                  单条断言失败（含全部定位信息）
 *   SLUB_TEST_CASE <name> FAIL    单个用例失败
 *   SLUB_TEST_FAIL total_cases_failed=N seed=...   套件失败收尾
 *   SLUB_TEST_PASS                由调用方在全部用例完成后打印
 *
 * 未纳入通过条件的行为（契约即 panic，无法在内核内恢复）：
 *   重复释放 / 非法指针 / 非槽位指针 —— 内核侧只做正向校验
 *   （slub_check_ptr 对活对象），负向用例由宿主 slub_host_neg 以
 *   fork+子进程预期崩溃的方式独立运行，不中止正常测试集。
 */

#include <slub.h>
#include <slub_port.h>
#include <string.h>

#ifdef SLUB_TEST

#ifndef SLUB_TEST_SEED
#define SLUB_TEST_SEED 0xC0FFEE51ABC0FFEEUL
#endif

/* ------------------------- 失败上下文 / 框架 ------------------------- */

static const char *t_case = "?";
static size_t t_size;         /* 当前关注的请求大小（失败输出） */
static unsigned long t_iters; /* 当前用例迭代计数（失败输出） */
static int t_case_failed;
static int t_total_failed;
static unsigned long t_seed_cfg; /* 原始种子（外部可覆盖，失败时打印） */
static unsigned long t_rng;

#define TFAIL(why)                                                          \
    do {                                                                    \
        t_case_failed = 1;                                                  \
        slub_port_printf("SLUB_TEST_FAIL case=%s why=%s size=%lu iters=%lu "\
                         "cpu=%u seed=%lu\n",                               \
                         t_case, (why), (unsigned long)t_size, t_iters,     \
                         slub_port_cpu_id(), t_seed_cfg);                   \
    } while (0)

/* 固定种子 xorshift64（状态非零） */
static unsigned long trand(void) {
    unsigned long x = t_rng;
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    t_rng = x;
    return x;
}

#ifdef SLUB_DEBUG
/* 分配器内部不变量校验（t_verify_all 等阶段点调用）；
 * SLUB_TEST_VALIDATE 定义时进一步在每次分配/释放后调用，用于快速定位
 * 首次破坏点（开销大，开发期/QEMU 下慎用）。 */
static void t_validate(const char *where) {
    const char *err = slub_debug_validate();
    if (err != NULL) {
        slub_port_printf("  detail: invariant at %s: %s\n", where, err);
        TFAIL("slub internal invariant violated");
    }
}
#ifdef SLUB_TEST_VALIDATE
#define TVALIDATE_OP(where) t_validate(where)
#else
#define TVALIDATE_OP(where) ((void)0)
#endif
#else
#define t_validate(where) ((void)0)
#define TVALIDATE_OP(where) ((void)0)
#endif

/* ------------------------- 静态对象记录表 ------------------------- */

#define TMAX_OBJS 1152

struct tobj {
    unsigned char *p;
    size_t size;
    unsigned int id;
    unsigned int round;
};

static struct tobj t_objs[TMAX_OBJS];
static unsigned int t_n; /* 存活对象占用 t_objs[0, t_n) */
static unsigned int t_next_id;
static unsigned int t_round;

/* (对象编号, 字节偏移, 轮次) -> 字节模式；不存表，随时可重算 */
static unsigned char tpat(unsigned int id, size_t off, unsigned int round) {
    unsigned long h = (unsigned long)id * 2654435761UL +
                      (unsigned long)off * 40503UL +
                      (unsigned long)round * 97UL;
    h ^= h >> 11;
    h *= 0x100000001B3UL;
    return (unsigned char)(h >> 5);
}

/* 校验单个存活对象：只读用户请求范围 [0, size)，逐字节比对模式 */
static int t_verify_obj(struct tobj *o) {
    size_t i;
    for (i = 0; i < o->size; i++) {
        unsigned char want = tpat(o->id, i, o->round);
        if (o->p[i] != want) {
            slub_port_printf(
                "  detail: obj id=%u ptr=%p size=%lu off=%lu round=%u "
                "got=0x%x want=0x%x\n",
                o->id, (void *)o->p, (unsigned long)o->size,
                (unsigned long)i, o->round, (unsigned int)o->p[i],
                (unsigned int)want);
            return 0;
        }
    }
    return 1;
}

/* 地址区间互不重叠 + 16 字节对齐（按地址排序后比较相邻区间） */
static void t_check_layout(void) {
    static unsigned int idx[TMAX_OBJS];
    unsigned int i, j;

    for (i = 0; i < t_n; i++) {
        idx[i] = i;
        if (((uintptr_t)t_objs[i].p % SLUB_MIN_ALIGN) != 0) {
            slub_port_printf("  detail: obj id=%u ptr=%p\n", t_objs[i].id,
                             (void *)t_objs[i].p);
            TFAIL("object not %d-byte aligned");
        }
    }
    /* 插入排序（静态空间，n <= TMAX_OBJS） */
    for (i = 1; i < t_n; i++) {
        unsigned int v = idx[i];
        for (j = i; j > 0 && (uintptr_t)t_objs[idx[j - 1]].p >
                                 (uintptr_t)t_objs[v].p;
             j--) {
            idx[j] = idx[j - 1];
        }
        idx[j] = v;
    }
    for (i = 1; i < t_n; i++) {
        struct tobj *a = &t_objs[idx[i - 1]], *b = &t_objs[idx[i]];
        if ((uintptr_t)a->p + a->size > (uintptr_t)b->p) {
            slub_port_printf("  detail: [%p,+%lu) overlaps [%p,+%lu)\n",
                             (void *)a->p, (unsigned long)a->size,
                             (void *)b->p, (unsigned long)b->size);
            TFAIL("live object ranges overlap");
        }
    }
}

static void t_verify_all(void) {
    unsigned int i;
    for (i = 0; i < t_n; i++) {
        if (!t_verify_obj(&t_objs[i])) {
            TFAIL("live object content corrupted");
            break;
        }
    }
    t_check_layout();
#ifdef SLUB_DEBUG
    {
        /* 调试不变量：内容被破坏时同步检查分配器内部状态，便于定位 */
        const char *err = slub_debug_validate();
        if (err != NULL) {
            slub_port_printf("  detail: invariant: %s\n", err);
            TFAIL("slub internal invariant violated");
        }
    }
#endif
}

/* 分配并登记：非 NULL、16 对齐、写满请求范围 */
static struct tobj *t_alloc(size_t size) {
    struct tobj *o;
    unsigned char *p;
    size_t i;

    t_size = size;
    if (t_n >= TMAX_OBJS) {
        TFAIL("static object table exhausted");
        return NULL;
    }
    p = kmalloc(size);
    if (p == NULL) {
        TFAIL("kmalloc returned NULL for a legal size");
        return NULL;
    }
    /* 活跃地址唯一性：不得把仍存活对象的地址再发一遍 */
    for (i = 0; i < t_n; i++) {
        if (t_objs[i].p == p) {
            slub_port_printf(
                "  detail: ptr=%p size=%lu reissued to new id=%u, still live "
                "as id=%u size=%lu\n",
                (void *)p, (unsigned long)size, t_next_id, t_objs[i].id,
                (unsigned long)t_objs[i].size);
            TFAIL("kmalloc reissued a still-live address");
            break;
        }
    }
    if (((uintptr_t)p % SLUB_MIN_ALIGN) != 0) {
        slub_port_printf("  detail: ptr=%p size=%lu\n", (void *)p,
                         (unsigned long)size);
        TFAIL("kmalloc result not 16-byte aligned");
        kfree(p);
        return NULL;
    }
    o = &t_objs[t_n++];
    o->p = p;
    o->size = size;
    o->id = t_next_id++;
    o->round = t_round;
    for (i = 0; i < size; i++) p[i] = tpat(o->id, i, o->round);
    TVALIDATE_OP("t_alloc");
    return o;
}

/* 释放第 i 个存活对象（保持其余对象相对顺序） */
static void t_free_at(unsigned int i) {
    kfree(t_objs[i].p);
    for (; i + 1 < t_n; i++) t_objs[i] = t_objs[i + 1];
    t_n--;
    TVALIDATE_OP("t_free_at");
}

/* 按对象 id 释放：索引会因移位与新分配而变化，id 恒定 */
static void t_free_id(unsigned int id) {
    unsigned int i;
    for (i = 0; i < t_n; i++) {
        if (t_objs[i].id == id) {
            t_free_at(i);
            return;
        }
    }
    TFAIL("tried to free an id that is no longer live");
}

static void t_free_all(void) {
    while (t_n != 0) t_free_at(t_n - 1);
}

/* ------------------------- 全局基线 / 统计快照 ------------------------- */

static size_t t_baseline; /* slub_shrink 后的空闲页基线（含固定元数据开销） */

static void t_expect_baseline(const char *why) {
    size_t free_pages = slub_port_nr_free_pages();
    if (free_pages != t_baseline) {
        slub_port_printf("  detail: free_pages=%lu baseline=%lu\n",
                         (unsigned long)free_pages,
                         (unsigned long)t_baseline);
        TFAIL(why);
    }
    if (slub_user_objects() != 0) {
        slub_port_printf("  detail: user_objects=%lu\n",
                         (unsigned long)slub_user_objects());
        TFAIL("user object count not zero after full free + shrink");
    }
    if (slub_slab_pages() != 0) {
        slub_port_printf("  detail: slab_pages=%lu\n",
                         (unsigned long)slub_slab_pages());
        TFAIL("slub still holds pages after full free + shrink");
    }
}

/* ------------------------- 用例 1：极端尺寸边界 ------------------------- */

static void case_sizes_edge(void) {
    static const size_t sizes[] = {1, 15, 16, 17};
    unsigned int i;

    /* 先持有对象，确认 kmalloc(0) 契约且不改动既有对象 */
    if (t_alloc(16) == NULL || t_alloc(64) == NULL) return;
    t_size = 0;
    if (kmalloc(0) != NULL) TFAIL("kmalloc(0) must return NULL");
    if (slub_size_to_class(0) != -1) TFAIL("size 0 must map to no class");
    t_verify_all();

    for (i = 0; i < sizeof(sizes) / sizeof(sizes[0]); i++) {
        int cls = slub_size_to_class(sizes[i]);
        t_iters++;
        if (t_alloc(sizes[i]) == NULL) continue;
        if (cls != (sizes[i] <= 16 ? 0 : 1)) {
            slub_port_printf("  detail: size=%lu -> class %d\n",
                             (unsigned long)sizes[i], cls);
            TFAIL("unexpected size class mapping");
        }
    }
    t_verify_all();
    t_free_all();
}

/* ------------------------- 用例 2：每个尺寸类上限 s-1/s/s+1 ------------------------- */

static void case_class_bounds(void) {
    size_t cls;

    for (cls = 0; cls < slub_nr_classes(); cls++) {
        size_t s = slub_class_size(cls);
        size_t req[3];
        unsigned int k;

        req[0] = (s == 16) ? 1 : s - 1;
        req[1] = s;
        req[2] = s + 1;
        for (k = 0; k < 3; k++) {
            int want_cls = (req[k] <= s) ? (int)cls
                                         : (req[k] <= SLUB_MAX_SMALL_SIZE
                                                ? (int)cls + 1
                                                : -1);
            t_iters++;
            if (t_alloc(req[k]) == NULL) continue;
            if (slub_size_to_class(req[k]) != want_cls) {
                slub_port_printf("  detail: size=%lu -> class %d want %d\n",
                                 (unsigned long)req[k],
                                 slub_size_to_class(req[k]), want_cls);
                TFAIL("unexpected size class mapping");
            }
        }
    }
    /* 所有边界尺寸对象同时存活，互不重叠、内容完好 */
    t_verify_all();
    t_free_all();
}

/* ------------------------- 用例 3：页边界与多页请求 ------------------------- */

static void case_page_boundary(void) {
    static const size_t sizes[] = {
        SLUB_PAGE_SIZE - 1, SLUB_PAGE_SIZE, SLUB_PAGE_SIZE + 1,
        2 * SLUB_PAGE_SIZE - 13, 3 * SLUB_PAGE_SIZE + 1234,
        SLUB_MAX_SMALL_SIZE + 1, SLUB_MAX_SMALL_SIZE + 4097};
    unsigned int i;

    for (i = 0; i < sizeof(sizes) / sizeof(sizes[0]); i++) {
        t_iters++;
        t_alloc(sizes[i]); /* 非 NULL/对齐/写满由 t_alloc 断言 */
    }
    t_verify_all();
    t_free_all();
}

/* ------------------------- 用例 4：零/溢出请求必须失败且无副作用 ------------------------- */

static void case_overflow(void) {
    static const size_t bad[] = {0,
                                 SIZE_MAX,
                                 SIZE_MAX - 1,
                                 SIZE_MAX - 31,
                                 SIZE_MAX - 32,
                                 SIZE_MAX - 4095,
                                 SIZE_MAX - 4096,
                                 SIZE_MAX - 4128};
    size_t before;
    unsigned int i;

    /* 保持存活对象，验证失败请求不改变它们 */
    if (t_alloc(32) == NULL || t_alloc(4000) == NULL) return;
    before = slub_port_nr_free_pages();

    for (i = 0; i < sizeof(bad) / sizeof(bad[0]); i++) {
        t_size = bad[i];
        t_iters++;
        if (kmalloc(bad[i]) != NULL) {
            TFAIL("zero/overflow request must return NULL");
        }
    }
    t_verify_all(); /* 既有对象未被失败请求破坏 */
    if (slub_port_nr_free_pages() != before) {
        TFAIL("failed allocations changed free page count");
    }
    t_free_all();
}

/* ------------------------- 用例 5：多尺寸混合存活完整性 ------------------------- */

static void case_integrity_mix(void) {
    enum { MIX_CLASSES = 6, MIX_PER_CLASS = 60, MIX_ROUNDS = 3 };
    unsigned int cls, k, round;

    for (cls = 0; cls < MIX_CLASSES; cls++) {
        for (k = 0; k < MIX_PER_CLASS; k++) {
            if (t_alloc(slub_class_size(cls)) == NULL) {
                t_free_all();
                return;
            }
        }
    }
    t_verify_all();

    /* 多轮：校验 -> 固定种子随机释放约 1/3 -> 补充其它尺寸对象 -> 再校验。
     * 新对象使用新轮次的字节模式，老对象模式不变，可同时检出串写。 */
    for (round = 1; round <= MIX_ROUNDS; round++) {
        unsigned int before = t_n, freed = 0;
        t_round = round;
        t_iters++;
        t_verify_all();
        while (freed * 3 < before) {
            unsigned int i = (unsigned int)(trand() % t_n);
            t_free_at(i);
            freed++;
        }
        for (k = 0; k < 40; k++) {
            if (t_alloc(slub_class_size((round + k) % MIX_CLASSES)) == NULL)
                break;
        }
        t_verify_all(); /* 所有存活对象（老+新）内容与区间正确 */
    }
    t_free_all();
}

/* ------------------------- 用例 6：释放顺序（顺序/逆序/交错/随机） ------------------------- */

static void case_free_orders(void) {
    enum { ORD_K = 200, ORD_REFILL = 40 };
    static unsigned int order[ORD_K];
    static unsigned int ids[ORD_K]; /* 对象 id：与数组移位无关 */
    unsigned int ord, i, j;

    for (ord = 0; ord < 4; ord++) {
        t_round = ord;
        t_size = 32;
        for (i = 0; i < ORD_K; i++) {
            if (t_alloc(32) == NULL) {
                t_free_all();
                return;
            }
            ids[i] = t_objs[t_n - 1].id;
        }
        /* 生成释放顺序 */
        switch (ord) {
        case 0: /* 顺序 */
            for (i = 0; i < ORD_K; i++) order[i] = i;
            break;
        case 1: /* 逆序 */
            for (i = 0; i < ORD_K; i++) order[i] = ORD_K - 1 - i;
            break;
        case 2: /* 交错：先全部偶数位，再全部奇数位 */
            for (i = 0; i < ORD_K / 2; i++) order[i] = 2 * i;
            for (i = ORD_K / 2; i < ORD_K; i++) order[i] = 2 * (i - ORD_K / 2) + 1;
            break;
        default: /* 固定种子随机（Fisher-Yates） */
            for (i = 0; i < ORD_K; i++) order[i] = i;
            for (i = ORD_K; i > 1; i--) {
                unsigned int j2 = (unsigned int)(trand() % i);
                unsigned int tmp = order[i - 1];
                order[i - 1] = order[j2];
                order[j2] = tmp;
            }
            break;
        }
        for (i = 0; i < ORD_K; i++) {
            t_iters++;
            t_free_id(ids[order[i]]);
            if (i == ORD_K / 2) {
                /* 释放一半后继续分配不同尺寸对象并校验所有存活对象 */
                for (j = 0; j < ORD_REFILL; j++) t_alloc(512);
                t_verify_all();
            }
        }
        t_verify_all(); /* 同尺寸类释放后剩余对象仍完好 */
        t_free_all();
    }
}

/* ------------------------- 用例 7：同尺寸类持续分配，跨越各层容量 ------------------------- */

static void case_sustained_churn(void) {
    size_t cls;

    for (cls = 0; cls < slub_nr_classes(); cls++) {
        struct slub_class_info i0, i1, i2, i3;
        size_t objsize = slub_class_size(cls);
        unsigned int n, m, k;

        t_size = objsize;
        if (slub_get_class_info(cls, &i0) != 0) {
            TFAIL("slub_get_class_info failed");
            return;
        }
        /* 跨越：一个 slab 容量 ×2 + barn 容量 ×2 + main+spare ×2 */
        n = (unsigned int)(2 * i0.objs_per_slab + 2 * i0.barn_cap +
                           2 * (2 * i0.sheaf_cap));
        if (n > TMAX_OBJS - 8) n = TMAX_OBJS - 8;

        for (k = 0; k < n; k++) {
            if (t_alloc(objsize) == NULL) break;
            t_iters++;
        }
        t_verify_all();
        slub_get_class_info(cls, &i1);
        if (i1.slab_new == i0.slab_new) TFAIL("slab_new did not advance");
        if (i1.refill == i0.refill) TFAIL("refill path not exercised");
        if (i1.alloc_slow == i0.alloc_slow) TFAIL("slow alloc path missing");
        if (i1.nr_slabs <= i0.nr_slabs) TFAIL("slab count did not grow");

        /* 前向（分配序）全部释放：最先释放的前 2*sheaf+barn 个对象被缓存层
         * 吸收并集中钉在最初的 slab 上，其余 slab 必然排空 -> empty/destroy。
         * （随机顺序会让缓存指针散布到所有 slab，反而观察不到该转换，
         *  随机释放由 integrity_mix / shrink_baseline 等用例覆盖。） */
        while (t_n != 0) {
            t_free_at(0);
            t_iters++;
        }
        slub_get_class_info(cls, &i2);
        if (i2.free_slow == i1.free_slow) TFAIL("free slow path missing");
        if (i2.flush == i1.flush) TFAIL("slab flush path missing");
        if (i2.barn_put == i1.barn_put) TFAIL("barn put path missing");
        if (i2.slab_free == i1.slab_free && i2.nr_empty == 0)
            TFAIL("no empty/destroyed slab after full free");

        /* 重新分配：先命中 sheaf，再命中 barn（barn_get 必须推进） */
        m = (unsigned int)(2 * i0.sheaf_cap + i0.barn_cap + 1);
        for (k = 0; k < m; k++) {
            if (t_alloc(objsize) == NULL) break;
            t_iters++;
        }
        slub_get_class_info(cls, &i3);
        if (i3.barn_get == i2.barn_get) TFAIL("barn get path missing");
        t_verify_all();

        t_free_all();
        slub_shrink();
        slub_get_class_info(cls, &i3);
        if (i3.nr_slabs != 0) TFAIL("slabs not released after shrink");
        t_expect_baseline("free pages drifted after class churn");
    }
}

/* ------------------------- 用例 8：kfree(NULL) 不改变任何状态 ------------------------- */

static void case_null_free(void) {
    struct slub_class_info a[SLUB_NCLASSES], b[SLUB_NCLASSES];
    size_t u0 = slub_user_objects(), p0 = slub_port_nr_free_pages();
    unsigned int cls, i;

    for (cls = 0; cls < SLUB_NCLASSES; cls++) slub_get_class_info(cls, &a[cls]);
    for (i = 0; i < 1000; i++) kfree(NULL);
    t_iters = 1000;
    for (cls = 0; cls < SLUB_NCLASSES; cls++) slub_get_class_info(cls, &b[cls]);

    if (slub_user_objects() != u0 || slub_port_nr_free_pages() != p0)
        TFAIL("kfree(NULL) changed global state");
    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
        if (b[cls].alloc_fast != a[cls].alloc_fast ||
            b[cls].alloc_slow != a[cls].alloc_slow ||
            b[cls].free_fast != a[cls].free_fast ||
            b[cls].free_slow != a[cls].free_slow ||
            b[cls].refill != a[cls].refill || b[cls].flush != a[cls].flush ||
            b[cls].barn_get != a[cls].barn_get ||
            b[cls].barn_put != a[cls].barn_put ||
            b[cls].slab_new != a[cls].slab_new ||
            b[cls].slab_free != a[cls].slab_free ||
            b[cls].nr_slabs != a[cls].nr_slabs ||
            b[cls].user_objs != a[cls].user_objs) {
            TFAIL("kfree(NULL) changed class statistics");
        }
    }
}

/* ------------------------- 用例 9：回收基线（混合分配/全释放/排空/shrink） ------------------------- */

static void case_shrink_baseline(void) {
    static const size_t sizes[] = {16, 64, 256, 1024, 3000, 9000};
    unsigned int round, k;

    slub_shrink();
    t_baseline = slub_port_nr_free_pages();
    if (slub_slab_pages() != 0 || slub_user_objects() != 0)
        TFAIL("not clean after shrink at suite start");

    for (round = 0; round < 3; round++) {
        t_round = round;
        for (k = 0; k < 240; k++) {
            if (t_alloc(sizes[trand() % 6]) == NULL) break;
            t_iters++;
        }
        while (t_n != 0) {
            t_free_at((unsigned int)(trand() % t_n));
            t_iters++;
        }
        slub_shrink();
        t_expect_baseline("free pages not restored after alloc/free/shrink");
    }
}

/* ------------------------- 用例 10：持有对象时 shrink，内容与页仍正确 ------------------------- */

static void case_shrink_live(void) {
    unsigned int k;

    slub_shrink();
    t_baseline = slub_port_nr_free_pages();

    for (k = 0; k < 120; k++) {
        if (t_alloc(64) == NULL) return;
        t_iters++;
    }
    /* 释放约 1/3 进入 sheaf/barn/empty 缓存，然后静止态 shrink */
    for (k = t_n; k > 0; k -= 3) t_free_at(k - 1);
    slub_shrink();

    if (t_n == 0) {
        TFAIL("all objects unexpectedly gone");
        return;
    }
    if (slub_user_objects() != t_n) {
        slub_port_printf("  detail: user_objects=%lu live=%u\n",
                         (unsigned long)slub_user_objects(), t_n);
        TFAIL("user object count changed across shrink");
    }
    if (slub_slab_pages() == 0) TFAIL("pages of live objects were reclaimed");
    if (slub_port_nr_free_pages() + slub_slab_pages() != t_baseline) {
        slub_port_printf("  detail: free=%lu held=%lu baseline=%lu\n",
                         (unsigned long)slub_port_nr_free_pages(),
                         (unsigned long)slub_slab_pages(),
                         (unsigned long)t_baseline);
        TFAIL("free+held pages must equal baseline exactly");
    }
    t_verify_all(); /* shrink 后存活对象内容仍正确 */

    t_free_all();
    slub_shrink();
    t_expect_baseline("not restored after freeing the held objects");
}

/* ------------------------- 用例 11：用户全释放但缓存仍持有指针时不得提前还页 ------------------------- */

static void case_cached_pages(void) {
    struct slub_class_info i0;
    size_t n, m, held;
    unsigned int k;

    slub_shrink();
    t_baseline = slub_port_nr_free_pages();
    t_size = 64;
    if (slub_get_class_info(2, &i0) != 0) { /* class 2 = 64B */
        TFAIL("slub_get_class_info failed");
        return;
    }
    /* 数量足以让 sheaf+barn 吸收相当一批指针，其余回 slab */
    n = 4 * i0.barn_cap + 2 * (2 * i0.sheaf_cap) + 2 * i0.objs_per_slab;
    for (k = 0; k < n; k++) {
        if (t_alloc(64) == NULL) {
            t_free_all();
            return;
        }
        t_iters++;
    }
    t_verify_all();
    while (t_n != 0) t_free_at((unsigned int)(trand() % t_n));

    /* 用户对象归零，但 main/spare/barn 与 empty 链仍缓存指针：
     * 页面不得被提前归还（用页计数与只读统计判断，不读已释放指针） */
    if (slub_user_objects() != 0) TFAIL("user object count should be zero");
    held = slub_slab_pages();
    if (held == 0) TFAIL("pages with cached pointers were returned early");
    if (slub_port_nr_free_pages() + held != t_baseline) {
        slub_port_printf("  detail: free=%lu held=%lu baseline=%lu\n",
                         (unsigned long)slub_port_nr_free_pages(),
                         (unsigned long)held, (unsigned long)t_baseline);
        TFAIL("free page accounting mismatch while caches hold pointers");
    }
    /* 页所有权：缓存期间再分配应成功（复用缓存页） */
    m = 2 * i0.sheaf_cap + i0.barn_cap + 8;
    for (k = 0; k < m; k++) {
        if (t_alloc(64) == NULL) break;
        t_iters++;
    }
    t_verify_all();
    t_free_all();

    /* 排空（shrink）后才回收 */
    slub_shrink();
    t_expect_baseline("pages not recovered after draining caches");
}

/* ------------------------- 用例 12：页分配故障注入 / 失败恢复 ------------------------- */

static void case_fault_inject(void) {
    struct slub_class_info i0, i1;
    size_t hits0, bf;
    unsigned int i;

    slub_shrink();
    t_baseline = slub_port_nr_free_pages();
    /* 持有两个既有对象，贯穿整个故障过程验证其内容 */
    if (t_alloc(128) == NULL || t_alloc(5000) == NULL) return;

    /* 先排空目标尺寸类缓存，确保故障打在“slab 新建”上 */
    slub_shrink();
    bf = slub_port_nr_free_pages();
    hits0 = slub_fault_hits();
    slub_get_class_info(0, &i0);

    slub_fault_inject(1);
    t_size = 16;
    t_iters++;
    if (kmalloc(16) != NULL) TFAIL("allocation must fail under injected fault");
    slub_get_class_info(0, &i1);
    if (i1.slab_fail == i0.slab_fail) TFAIL("slab failure not recorded");
    if (slub_fault_hits() != hits0 + 1) TFAIL("fault injection not hit");
    if (slub_port_nr_free_pages() != bf)
        TFAIL("failed slab creation leaked pages");

    /* 大对象路径失败：不得泄漏部分页 */
    slub_fault_inject(1);
    t_size = 8192;
    t_iters++;
    if (kmalloc(8192) != NULL)
        TFAIL("large allocation must fail under injected fault");
    if (slub_port_nr_free_pages() != bf)
        TFAIL("failed large allocation leaked pages");

    /* 连续三次失败，计数与页数都保持一致 */
    slub_fault_inject(3);
    for (i = 0; i < 3; i++) {
        t_size = 64;
        t_iters++;
        if (kmalloc(64) != NULL) TFAIL("allocation must fail under fault");
    }
    if (slub_fault_hits() != hits0 + 5) TFAIL("fault hit count mismatch");
    if (slub_port_nr_free_pages() != bf) TFAIL("fault path leaked pages");

    t_verify_all(); /* 既有对象不受失败影响 */

    /* 恢复：解除故障后可正常分配、写读、回收 */
    slub_fault_clear();
    {
        struct tobj *a = t_alloc(16);
        struct tobj *b = t_alloc(64);
        struct tobj *c = t_alloc(8192);
        if (a && b && c) t_verify_all();
    }
    t_free_all();
    slub_shrink();
    t_expect_baseline("not restored after fault injection recovery");
}

/* ------------------------- 用例 13：调试指针校验（正向） ------------------------- */

static void case_check_ptr(void) {
    size_t cls;

    slub_check_ptr(NULL); /* 契约：无操作 */
    for (cls = 0; cls < slub_nr_classes(); cls++) {
        if (t_alloc(slub_class_size(cls)) == NULL) return;
        t_iters++;
    }
    if (t_alloc(SLUB_MAX_SMALL_SIZE + 5000) == NULL) return;
    {
        unsigned int i;
        for (i = 0; i < t_n; i++) slub_check_ptr(t_objs[i].p);
    }
    t_verify_all();
    t_free_all();
    slub_shrink();
    t_expect_baseline("not restored after check_ptr case");
}

/* ------------------------- 用例驱动 ------------------------- */

static void t_run(void (*fn)(void), const char *name) {
    t_case = name;
    t_case_failed = 0;
    t_size = 0;
    t_iters = 0;
    fn();
    if (t_n != 0) {
        TFAIL("case left live objects behind");
        t_free_all();
    }
    slub_port_printf("SLUB_TEST_CASE %s %s\n", name,
                     t_case_failed ? "FAIL" : "PASS");
    t_total_failed += t_case_failed;
}

int slub_test_run(unsigned long seed) {
    t_seed_cfg = (seed != 0) ? seed : SLUB_TEST_SEED;
    t_rng = t_seed_cfg;
    t_n = 0;
    t_next_id = 0;
    t_round = 0;
    t_total_failed = 0;

    slub_port_printf("SLUB_TEST_BEGIN seed=%lu cpus=%d classes=%d\n",
                     t_seed_cfg, (int)SLUB_NCPUS, (int)SLUB_NCLASSES);
    slub_port_printf("SLUB_TEST_NOTE negative misuse (double free / foreign "
                     "pointer) panics by contract; kernel suite excludes it, "
                     "host slub_host_neg covers it in a child process\n");

    /* 安静环境下先 shrink，记录空闲页基线（固定元数据开销包含在内） */
    slub_shrink();
    t_baseline = slub_port_nr_free_pages();
    slub_port_printf("SLUB_TEST_BASELINE free_pages=%lu fixed_overhead=%lu\n",
                     (unsigned long)t_baseline,
                     (unsigned long)slub_fixed_overhead());

    t_run(case_sizes_edge, "sizes_edge");
    t_run(case_class_bounds, "class_bounds");
    t_run(case_page_boundary, "page_boundary");
    t_run(case_overflow, "overflow");
    t_run(case_integrity_mix, "integrity_mix");
    t_run(case_free_orders, "free_orders");
    t_run(case_sustained_churn, "sustained_churn");
    t_run(case_null_free, "null_free");
    t_run(case_shrink_baseline, "shrink_baseline");
    t_run(case_shrink_live, "shrink_live");
    t_run(case_cached_pages, "cached_pages");
    t_run(case_fault_inject, "fault_inject");
    t_run(case_check_ptr, "check_ptr");

    if (t_total_failed != 0) {
        slub_port_printf("SLUB_TEST_FAIL total_cases_failed=%d seed=%lu\n",
                         t_total_failed, t_seed_cfg);
    }
    return t_total_failed;
}

/* ------------------------- 内核入口 ------------------------- */

void check_slub(void) {
    if (slub_test_run(0) == 0) {
        slub_port_printf("SLUB_TEST_PASS\n");
    } else {
        slub_port_printf("SLUB_TEST_DONE_WITH_FAILURES\n");
    }
}

#endif /* SLUB_TEST */
