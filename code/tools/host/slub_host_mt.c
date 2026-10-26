/*
 * slub_host_mt.c —— 宿主侧真多线程并发用例
 *
 * 与内核测试共享同一份分配核心（kern/mm/slub.c），只通过 slub_port.h 的
 * 移植层获得线程/锁/页池语义（tools/host/slub_host_port.c：
 * 线程绑定逻辑 CPU、pthread 互斥、固定页池）。不另写分配器。
 *
 * 覆盖：
 *   mt_ring   N 个线程组成环形生产者-消费者：每个线程绑定一个逻辑 CPU，
 *             分配并写满对象 -> 经正确同步（互斥+条件变量）的有界队列
 *             交给下一 CPU 校验并释放，形成跨 CPU 释放；对象经队列传递
 *             构成 release-acquire 链。校验：内容、活跃地址唯一性
 *             （跨线程全局集合）、最终资源回收、死锁超时。
 *   mt_churn  N 个线程各自持本地对象集做混合分配/释放，最大化共享
 *             barn/slab/页分配器的竞争；对象归各线程私有，校验不需额外锁。
 *
 * 失败输出与内核套件同格式：case/why/size/iters/cpu(线程号)/seed。
 * 全部通过由调用方（slub_host_main.c）打印 SLUB_TEST_PASS。
 *
 * 局限（如实说明）：
 *   - 这是宿主（Linux 用户态、多核）上的真并发，不是 RISC-V SMP 验证；
 *   - 逻辑 CPU 数 = SLUB_NCPUS，通过 slub_host_bind_cpu 绑定；
 *   - 并发测试通过不等于证明无竞态，只说明这些交错未暴露问题。
 */

#include <slub.h>
#include <slub_port.h>

#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* slub_host_port.c */
void slub_host_bind_cpu(unsigned int cpu);

#ifndef MT_NCPU
#define MT_NCPU 4
#endif
#ifndef MT_ITERS
#define MT_ITERS 6000 /* ring 用例：每线程生产对象数 */
#endif
#ifndef MT_CHURN_ROUNDS
#define MT_CHURN_ROUNDS 4000 /* churn 用例：每线程本地操作轮数 */
#endif
#ifndef MT_TIMEOUT
#define MT_TIMEOUT 60 /* 死锁/挂起超时（秒） */
#endif

#define CHURN_SET 256 /* churn 用例每线程本地存活对象上限 */

/* ---------------- 失败报告（与内核套件同字段） ---------------- */

static unsigned long mt_seed;
static int mt_failures;

static void mt_fail(const char *kase, size_t size, unsigned long iters,
                    unsigned int cpu, const char *why) {
    mt_failures++;
    printf("SLUB_TEST_FAIL case=%s why=%s size=%lu iters=%lu cpu=%u seed=%lu\n",
           kase, why, (unsigned long)size, iters, cpu, mt_seed);
    fflush(stdout);
}

/* ---------------- 字节模式（对象 tag + 字节偏移） ---------------- */

static unsigned char mtpat(unsigned long tag, size_t off) {
    unsigned long h = tag * 2654435761UL + (unsigned long)off * 40503UL;
    h ^= h >> 11;
    h *= 0x100000001B3UL;
    return (unsigned char)(h >> 5);
}

/* ---------------- 活跃地址集合（线程安全，跨线程查重） ---------------- */

#define USET_SHARDS 8
#define USET_SLOTS 8192
#define USET_TOMB 1 /* 开放寻址删除墓碑（tab 值；真实键 = ptr+1 >= 2） */

struct uset_shard {
    pthread_mutex_t m;
    uintptr_t tab[USET_SLOTS]; /* 0=空；1=墓碑；否则 ptr+1 */
};

static struct uset_shard uset[USET_SHARDS];

static unsigned long uhash(uintptr_t a) {
    a ^= a >> 30;
    a *= 0xbf58476d1ce4e5b9UL;
    a ^= a >> 27;
    a *= 0x94d049bb133111ebUL;
    a ^= a >> 31;
    return (unsigned long)a;
}

static void uset_init(void) {
    int i;
    for (i = 0; i < USET_SHARDS; i++) {
        pthread_mutex_init(&uset[i].m, NULL);
        memset(uset[i].tab, 0, sizeof(uset[i].tab));
    }
}

/* 0=新插入；-1=地址仍存活（重复分配！）；-2=表满 */
static int uset_insert(void *p) {
    uintptr_t key = (uintptr_t)p + 1;
    unsigned long h = uhash((uintptr_t)p);
    struct uset_shard *s = &uset[h % USET_SHARDS];
    unsigned int i = (unsigned int)(h % USET_SLOTS), n;
    unsigned int first_tomb = USET_SLOTS;
    int rc = -2;

    pthread_mutex_lock(&s->m);
    for (n = 0; n < USET_SLOTS; n++) {
        if (s->tab[i] == 0) {
            /* 空槽：探测链在此终止，用最近的墓碑（若有）避免链断裂 */
            s->tab[first_tomb != USET_SLOTS ? first_tomb : i] = key;
            rc = 0;
            break;
        }
        if (s->tab[i] == USET_TOMB) {
            if (first_tomb == USET_SLOTS) first_tomb = i;
        } else if (s->tab[i] == key) {
            rc = -1;
            break;
        }
        i = (i + 1) % USET_SLOTS;
    }
    pthread_mutex_unlock(&s->m);
    return rc;
}

/* 0=已从集合移除；-1=地址本就不在集合（错误释放） */
static int uset_remove(void *p) {
    uintptr_t key = (uintptr_t)p + 1;
    unsigned long h = uhash((uintptr_t)p);
    struct uset_shard *s = &uset[h % USET_SHARDS];
    unsigned int i = (unsigned int)(h % USET_SLOTS), n;
    int rc = -1;

    pthread_mutex_lock(&s->m);
    for (n = 0; n < USET_SLOTS; n++) {
        if (s->tab[i] == 0) break; /* 探测链终止：不在表中 */
        if (s->tab[i] == key) {
            s->tab[i] = USET_TOMB; /* 置墓碑而非清空，保持探测链完整 */
            rc = 0;
            break;
        }
        i = (i + 1) % USET_SLOTS;
    }
    pthread_mutex_unlock(&s->m);
    return rc;
}

static unsigned long uset_count(void) {
    unsigned long total = 0;
    int i;
    for (i = 0; i < USET_SHARDS; i++) {
        unsigned int j;
        pthread_mutex_lock(&uset[i].m);
        for (j = 0; j < USET_SLOTS; j++)
            if (uset[i].tab[j] != 0 && uset[i].tab[j] != USET_TOMB) total++;
        pthread_mutex_unlock(&uset[i].m);
    }
    return total;
}

/* ---------------- 有界同步队列（互斥 + 条件变量 + 截止时间） ---------------- */

#define QCAP 1024 /* 每队列容量：限制在途对象数，避免压垮宿主页池 */

struct mtitem {
    void *p;
    size_t size;
    unsigned long tag;
};

struct mtq {
    pthread_mutex_t m;
    pthread_cond_t ne, nf;
    struct mtitem slots[QCAP];
    unsigned int head, n, closed;
};

static struct timespec mt_deadline; /* 全局截止时间（死锁超时） */
static pthread_barrier_t mt_bar;    /* 协调所有线程同时启动 */
static volatile int ring_produce_done; /* 已完成生产的线程数（原子增） */

static int ts_later(struct timespec a, struct timespec b) {
    return a.tv_sec > b.tv_sec ||
           (a.tv_sec == b.tv_sec && a.tv_nsec > b.tv_nsec);
}

static void mt_reset_deadline(void) {
    clock_gettime(CLOCK_REALTIME, &mt_deadline);
    mt_deadline.tv_sec += MT_TIMEOUT;
}

static int mt_timed_out(void) {
    struct timespec now;
    clock_gettime(CLOCK_REALTIME, &now);
    return ts_later(now, mt_deadline);
}

static void q_init(struct mtq *q) {
    pthread_mutex_init(&q->m, NULL);
    pthread_cond_init(&q->ne, NULL);
    pthread_cond_init(&q->nf, NULL);
    q->head = q->n = q->closed = 0;
}

/* 非阻塞尝试；满/空返回 -1 */
static int q_try_push(struct mtq *q, struct mtitem it) {
    int rc = -1;
    pthread_mutex_lock(&q->m);
    if (q->n < QCAP) {
        q->slots[(q->head + q->n) % QCAP] = it;
        q->n++;
        pthread_cond_signal(&q->ne);
        rc = 0;
    }
    pthread_mutex_unlock(&q->m);
    return rc;
}

static int q_try_pop(struct mtq *q, struct mtitem *out) {
    int rc = -1;
    pthread_mutex_lock(&q->m);
    if (q->n != 0) {
        *out = q->slots[q->head];
        q->head = (q->head + 1) % QCAP;
        q->n--;
        pthread_cond_signal(&q->nf);
        rc = 0;
    }
    pthread_mutex_unlock(&q->m);
    return rc;
}

static void q_close(struct mtq *q) {
    pthread_mutex_lock(&q->m);
    q->closed = 1;
    pthread_cond_broadcast(&q->ne);
    pthread_cond_broadcast(&q->nf);
    pthread_mutex_unlock(&q->m);
}

/* 队列是否已空（终止检测用：所有生产者产完后，空即永空） */
static int q_empty(struct mtq *q) {
    int rc;
    pthread_mutex_lock(&q->m);
    rc = (q->n == 0);
    pthread_mutex_unlock(&q->m);
    return rc;
}

/* 无进展时短暂等待上游信号（100ms 时间片，配合全局截止时间检测死锁） */
static void q_wait_slice(struct mtq *in) {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    ts.tv_nsec += 100000000;
    if (ts.tv_nsec >= 1000000000) {
        ts.tv_sec++;
        ts.tv_nsec -= 1000000000;
    }
    pthread_mutex_lock(&in->m);
    if (in->n == 0 && !in->closed) pthread_cond_timedwait(&in->ne, &in->m, &ts);
    pthread_mutex_unlock(&in->m);
}

/* ---------------- 尺寸选择（固定种子可复现） ---------------- */

static const size_t mt_sizes[] = {1,    15,   16,    17,    31,    32,
                                  33,   64,   127,   128,   255,   256,
                                  511,  512,  1000,  1024,  2047,  2048,
                                  2049, 4095, 4096,  4112,  9000,  16384};

static size_t mt_pick_size(unsigned int thread, unsigned long seq) {
    unsigned long h = (unsigned long)thread * 7919UL + seq * 104729UL +
                      (mt_seed & 0xfffffUL);
    return mt_sizes[h % (sizeof(mt_sizes) / sizeof(mt_sizes[0]))];
}

/* ---------------- mt_ring：跨 CPU 生产者-消费者 ---------------- */

struct mt_ring_arg {
    int id;
    struct mtq *in, *out;
    struct mtq *all;
    int nq;
    unsigned long produced, consumed;
    int failed;
};

static void *ring_thread(void *varg) {
    struct mt_ring_arg *a = varg;
    const char *kase = "mt_ring";
    unsigned long seq = 0;
    struct mtitem it;
    int registered = 0;

    slub_host_bind_cpu((unsigned int)a->id);
    pthread_barrier_wait(&mt_bar);

    /* 生产 + 消费交替推进，避免环形队列结构性死锁；
     * 所有等待都有 100ms 时间片，超过全局截止时间判超时。 */
    for (;;) {
        int progressed = 0;

        if (mt_timed_out()) {
            mt_fail(kase, 0, a->produced + a->consumed, (unsigned int)a->id,
                    "timeout waiting on queue (deadlock or livelock)");
            a->failed = 1;
            {
                int i;
                for (i = 0; i < a->nq; i++) q_close(&a->all[i]);
            }
            break;
        }

        /* 1) 先尽量排空入队（跨 CPU 校验 + 释放） */
        while (q_try_pop(a->in, &it) == 0) {
            unsigned char *p = it.p;
            size_t j;
            for (j = 0; j < it.size; j++) {
                if (p[j] != mtpat(it.tag, j)) {
                    mt_fail(kase, it.size, a->consumed, (unsigned int)a->id,
                            "object content corrupted across CPU handoff");
                    a->failed = 1;
                    break;
                }
            }
            if (uset_remove(p) != 0) {
                mt_fail(kase, it.size, a->consumed, (unsigned int)a->id,
                        "freed address was not live in the registry");
                a->failed = 1;
            }
            kfree(p);
            a->consumed++;
            progressed = 1;
            if (a->failed) break;
        }
        if (a->failed) break;

        /* 2) 出队有空位就继续生产（每 64 个切回消费侧保证公平） */
        while (!a->failed && seq < MT_ITERS) {
            size_t sz = mt_pick_size((unsigned int)a->id, seq);
            unsigned long tag = ((unsigned long)(unsigned int)a->id << 32) |
                                (seq & 0xffffffffUL);
            unsigned char *p;
            size_t j;

            p = kmalloc(sz);
            if (p == NULL) {
                mt_fail(kase, sz, seq, (unsigned int)a->id,
                        "kmalloc failed while memory was available");
                a->failed = 1;
                break;
            }
            if (((uintptr_t)p % SLUB_MIN_ALIGN) != 0) {
                mt_fail(kase, sz, seq, (unsigned int)a->id,
                        "kmalloc result not 16-byte aligned");
                a->failed = 1;
                kfree(p);
                break;
            }
            if (uset_insert(p) != 0) {
                mt_fail(kase, sz, seq, (unsigned int)a->id,
                        "kmalloc reissued a still-live address");
                a->failed = 1;
                kfree(p);
                break;
            }
            for (j = 0; j < sz; j++) p[j] = mtpat(tag, j);
            it.p = p;
            it.size = sz;
            it.tag = tag;
            if (q_try_push(a->out, it) != 0) {
                /* 出队满：回滚登记，稍后重试 */
                uset_remove(p);
                kfree(p);
                break;
            }
            a->produced++;
            seq++;
            progressed = 1;
            if ((seq & 0x3f) == 0) break;
        }

        /* 3) 终止检测（环拓扑不能等"上游关闭"——会互等）：
         *    自己产完 && 所有线程都产完 && 入队已空 => 不可能再有新对象，
         *    安全退出（下游同样按此条件退出，不会漏消费）。 */
        if (seq >= MT_ITERS) {
            if (!registered) {
                __sync_fetch_and_add(&ring_produce_done, 1);
                registered = 1;
            }
            if (ring_produce_done >= MT_NCPU && q_empty(a->in)) break;
        }

        /* 4) 双向都无进展：短暂等待上游信号 */
        if (!progressed) q_wait_slice(a->in);
    }

    /* 无论成败都关闭出队，保证下游不会等不到关闭信号 */
    q_close(a->out);
    return NULL;
}

static int run_mt_ring(void) {
    pthread_t th[MT_NCPU];
    struct mt_ring_arg args[MT_NCPU];
    struct mtq q[MT_NCPU];
    int i, failed = 0;
    unsigned long produced = 0, consumed = 0;

    for (i = 0; i < MT_NCPU; i++) q_init(&q[i]);
    ring_produce_done = 0;
    pthread_barrier_init(&mt_bar, NULL, MT_NCPU);

    for (i = 0; i < MT_NCPU; i++) {
        args[i].id = i;
        args[i].in = &q[i];                  /* 上游 (i-1+N)%N 生产 */
        args[i].out = &q[(i + 1) % MT_NCPU]; /* 本线程生产到下游 */
        args[i].all = q;
        args[i].nq = MT_NCPU;
        args[i].produced = args[i].consumed = 0;
        args[i].failed = 0;
        pthread_create(&th[i], NULL, ring_thread, &args[i]);
    }
    for (i = 0; i < MT_NCPU; i++) pthread_join(th[i], NULL);
    pthread_barrier_destroy(&mt_bar);

    for (i = 0; i < MT_NCPU; i++) {
        failed |= args[i].failed;
        produced += args[i].produced;
        consumed += args[i].consumed;
    }
    printf("  mt_ring: produced=%lu consumed=%lu\n", produced, consumed);

    if (produced != consumed) {
        mt_fail("mt_ring", 0, produced, 0,
                "produced/consumed counts differ (objects lost in flight)");
        failed = 1;
    }
    if (uset_count() != 0) {
        mt_fail("mt_ring", 0, 0, 0, "live address registry not empty at end");
        failed = 1;
    }
    return failed;
}

/* ---------------- mt_churn：多线程混合分配/释放（私有对象集） ---------------- */

struct mt_churn_arg {
    int id;
    unsigned long ops;
    int failed;
};

struct churn_obj {
    unsigned char *p;
    size_t size;
    unsigned long tag;
};

static void *churn_thread(void *varg) {
    struct mt_churn_arg *a = varg;
    const char *kase = "mt_churn";
    struct churn_obj live[CHURN_SET];
    unsigned int nlive = 0;
    unsigned long round;
    unsigned long rs = mt_seed ^ (0x9e3779b97f4a7c15UL * (unsigned long)(a->id + 1));

    slub_host_bind_cpu((unsigned int)a->id);
    pthread_barrier_wait(&mt_bar);

    for (round = 0; round < MT_CHURN_ROUNDS && !a->failed; round++) {
        rs ^= rs << 13;
        rs ^= rs >> 7;
        rs ^= rs << 17;

        if (nlive == 0 || (nlive < CHURN_SET && (rs & 1))) {
            size_t sz = mt_pick_size((unsigned int)a->id, rs >> 8);
            unsigned long tag = ((unsigned long)(unsigned int)a->id << 40) |
                                (round & 0xffffffUL);
            unsigned char *p = kmalloc(sz);
            size_t j;

            if (p == NULL) {
                mt_fail(kase, sz, round, (unsigned int)a->id,
                        "kmalloc failed while memory was available");
                a->failed = 1;
                break;
            }
            if (uset_insert(p) != 0) {
                mt_fail(kase, sz, round, (unsigned int)a->id,
                        "kmalloc reissued a still-live address");
                a->failed = 1;
                kfree(p);
                break;
            }
            for (j = 0; j < sz; j++) p[j] = mtpat(tag, j);
            live[nlive].p = p;
            live[nlive].size = sz;
            live[nlive].tag = tag;
            nlive++;
            a->ops++;
        } else {
            unsigned int i = (unsigned int)((rs >> 8) % nlive);

            if (uset_remove(live[i].p) != 0) {
                mt_fail(kase, live[i].size, round, (unsigned int)a->id,
                        "freed address was not live in the registry");
                a->failed = 1;
                break;
            }
            kfree(live[i].p);
            live[i] = live[nlive - 1];
            nlive--;
            a->ops++;
        }

        /* 每 64 轮全量校验一次本地存活对象（私有，无需加锁） */
        if ((round & 63) == 63) {
            unsigned int k;
            for (k = 0; k < nlive && !a->failed; k++) {
                size_t j;
                for (j = 0; j < live[k].size; j++) {
                    if (live[k].p[j] != mtpat(live[k].tag, j)) {
                        mt_fail(kase, live[k].size, round, (unsigned int)a->id,
                                "local live object content corrupted");
                        a->failed = 1;
                        break;
                    }
                }
            }
        }
    }

    /* 收尾：校验并释放全部本地对象 */
    while (nlive != 0 && !a->failed) {
        size_t j;
        nlive--;
        for (j = 0; j < live[nlive].size; j++) {
            if (live[nlive].p[j] != mtpat(live[nlive].tag, j)) {
                mt_fail(kase, live[nlive].size, 0, (unsigned int)a->id,
                        "local live object content corrupted at cleanup");
                a->failed = 1;
                break;
            }
        }
        if (a->failed) break;
        if (uset_remove(live[nlive].p) != 0) {
            mt_fail(kase, live[nlive].size, 0, (unsigned int)a->id,
                    "freed address was not live in the registry");
            a->failed = 1;
            break;
        }
        kfree(live[nlive].p);
    }
    return NULL;
}

static int run_mt_churn(void) {
    pthread_t th[MT_NCPU];
    struct mt_churn_arg args[MT_NCPU];
    int i, failed = 0;

    pthread_barrier_init(&mt_bar, NULL, MT_NCPU);
    for (i = 0; i < MT_NCPU; i++) {
        args[i].id = i;
        args[i].ops = 0;
        args[i].failed = 0;
        pthread_create(&th[i], NULL, churn_thread, &args[i]);
    }
    for (i = 0; i < MT_NCPU; i++) pthread_join(th[i], NULL);
    pthread_barrier_destroy(&mt_bar);

    for (i = 0; i < MT_NCPU; i++) failed |= args[i].failed;
    printf("  mt_churn: ops=%lu+%lu+%lu+%lu\n", args[0].ops, args[1].ops,
           args[2].ops, args[3].ops);
    return failed;
}

/* ---------------- 入口（由 slub_host_main.c 调用） ---------------- */

int slub_test_mt(unsigned long seed) {
    size_t baseline;

    mt_seed = (seed != 0) ? seed : 0xC0FFEE51ABC0FFEEUL;
    mt_failures = 0;
    uset_init();

    printf("SLUB_TEST_BEGIN_MT cpus=%d timeout=%ds seed=%lu\n", MT_NCPU,
           MT_TIMEOUT, mt_seed);

    slub_shrink();
    baseline = slub_port_nr_free_pages();

    mt_reset_deadline();
    run_mt_ring();
    printf("SLUB_TEST_CASE mt_ring %s\n", mt_failures ? "FAIL" : "PASS");

    {
        int before = mt_failures;
        mt_reset_deadline();
        run_mt_churn();
        printf("SLUB_TEST_CASE mt_churn %s\n",
               mt_failures > before ? "FAIL" : "PASS");
    }

    /* 最终资源回收：全部释放 + shrink 后空闲页严格回到基线 */
    slub_shrink();
    if (slub_port_nr_free_pages() != baseline) {
        printf("  detail: free_pages=%lu baseline=%lu\n",
               (unsigned long)slub_port_nr_free_pages(),
               (unsigned long)baseline);
        mt_fail("mt_final", 0, 0, 0, "free pages did not return to baseline");
    }
    if (slub_user_objects() != 0 || slub_slab_pages() != 0) {
        mt_fail("mt_final", 0, 0, 0, "objects/pages still held after shrink");
    }
    if (uset_count() != 0) {
        mt_fail("mt_final", 0, 0, 0, "live address registry not empty");
    }
#ifdef SLUB_DEBUG
    {
        const char *err = slub_debug_validate();
        if (err != NULL) {
            printf("  detail: invariant: %s\n", err);
            mt_fail("mt_final", 0, 0, 0, "slub internal invariant violated");
        }
    }
#endif
    return mt_failures;
}
