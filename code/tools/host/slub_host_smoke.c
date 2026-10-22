/*
 * slub_host_smoke.c —— 宿主侧最小冒烟（不是完整测试套件）
 *
 * 覆盖：kmalloc(0)/kfree(NULL) 契约、对齐、写读校验、大对象、
 * 页分配故障注入、跨 CPU 释放（CPU A 分配 / CPU B 释放）、
 * slub_shrink 后空闲页回到基线且活跃对象为 0。
 *
 * 运行：make -C tools/host run
 */

#include <slub.h>
#include <slub_port.h>

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* slub_host_port.c 提供 */
void slub_host_bind_cpu(unsigned int cpu);
unsigned int slub_host_nr_free_pages(void);

static void check(int cond, const char *what) {
    if (!cond) {
        fprintf(stderr, "FAIL: %s\n", what);
        exit(1);
    }
    printf("  ok: %s\n", what);
}

/* ---------------- 跨 CPU 传递队列（有界 + 条件变量） ---------------- */

#define QCAP 1024

struct queue {
    pthread_mutex_t m;
    pthread_cond_t not_empty, not_full;
    void *slots[QCAP];
    unsigned int n, head, closed;
};

static void queue_init(struct queue *q) {
    pthread_mutex_init(&q->m, NULL);
    pthread_cond_init(&q->not_empty, NULL);
    pthread_cond_init(&q->not_full, NULL);
    q->n = q->head = q->closed = 0;
}

static void queue_push(struct queue *q, void *p) {
    pthread_mutex_lock(&q->m);
    while (q->n == QCAP && !q->closed)
        pthread_cond_wait(&q->not_full, &q->m);
    q->slots[(q->head + q->n) % QCAP] = p;
    q->n++;
    pthread_cond_signal(&q->not_empty);
    pthread_mutex_unlock(&q->m);
}

static void queue_close(struct queue *q) {
    pthread_mutex_lock(&q->m);
    q->closed = 1;
    pthread_cond_broadcast(&q->not_empty);
    pthread_cond_broadcast(&q->not_full);
    pthread_mutex_unlock(&q->m);
}

static void *queue_pop(struct queue *q) {
    void *p = NULL;
    pthread_mutex_lock(&q->m);
    while (q->n == 0 && !q->closed)
        pthread_cond_wait(&q->not_empty, &q->m);
    if (q->n != 0) {
        p = q->slots[q->head];
        q->head = (q->head + 1) % QCAP;
        q->n--;
        pthread_cond_signal(&q->not_full);
    }
    pthread_mutex_unlock(&q->m);
    return p;
}

/* ---------------- 跨 CPU 分配/释放 ---------------- */

#define XCPU_N 1500
static const size_t xcpu_sizes[5] = {8, 64, 300, 1000, 5000};

struct producer_arg {
    struct queue *q;
    int failed;
};

static void *producer(void *arg) {
    struct producer_arg *pa = arg;
    int i;

    slub_host_bind_cpu(0); /* CPU A：分配 */
    for (i = 0; i < XCPU_N; i++) {
        size_t sz = xcpu_sizes[i % 5];
        unsigned char *p = kmalloc(sz);
        if (p == NULL) {
            pa->failed = 1;
            break;
        }
        memset(p, (unsigned char)(i & 0xFF), sz); /* 触碰首尾页 */
        p[sz - 1] = (unsigned char)(i & 0xFF);
        queue_push(pa->q, p);
    }
    queue_close(pa->q); /* 无论成功与否都让消费侧退出等待 */
    return NULL;
}

static void *consumer(void *arg) {
    struct queue *q = arg;
    int i;

    slub_host_bind_cpu(1); /* CPU B：释放（跨 CPU free） */
    for (i = 0; i < XCPU_N; i++) {
        unsigned char *p = queue_pop(q);
        if (p == NULL) break;
        if (p[xcpu_sizes[i % 5] - 1] != (unsigned char)(i & 0xFF)) {
            fprintf(stderr, "FAIL: cross-cpu object data corrupted (i=%d)\n", i);
            exit(1);
        }
        kfree(p);
    }
    return NULL;
}

int main(void) {
    size_t baseline, after;
    struct slub_class_info info;
    struct queue q;
    struct producer_arg pa;
    pthread_t tp, tc;
    int i;

    printf("slub_host_smoke: start (SLUB_NCPUS=%d, pool free=%u pages)\n",
           (int)SLUB_NCPUS, slub_host_nr_free_pages());

    slub_init();
    baseline = slub_port_nr_free_pages(); /* slub_init 内部已 shrink 过 */
    printf("  baseline free pages: %lu\n", (unsigned long)baseline);

    /* 1. 基本契约 */
    check(kmalloc(0) == NULL, "kmalloc(0) == NULL");
    kfree(NULL); /* 无操作 */
    check(1, "kfree(NULL) is a no-op");

    /* 2. 小对象：对齐 + 写读校验 */
    for (i = 1; i <= (int)SLUB_MAX_SMALL_SIZE; i = i * 2 + 1) {
        unsigned char *p = kmalloc((size_t)i);
        int j, bad = 0;
        check(p != NULL, "small allocation succeeds");
        check(((unsigned long)p % SLUB_MIN_ALIGN) == 0, "16-byte alignment");
        for (j = 0; j < i; j++) p[j] = (unsigned char)(j * 7);
        for (j = 0; j < i; j++)
            if (p[j] != (unsigned char)(j * 7)) bad = 1;
        check(!bad, "small object data intact");
        slub_check_ptr(p); /* 调试检查：活对象应通过校验 */
        kfree(p);
    }

    /* 3. 大对象 */
    {
        unsigned char *big = kmalloc(SLUB_MAX_SMALL_SIZE + 12345);
        check(big != NULL, "large allocation succeeds");
        check(((unsigned long)big % SLUB_MIN_ALIGN) == 0, "large alignment");
        memset(big, 0x5A, SLUB_MAX_SMALL_SIZE + 12345);
        check(big[SLUB_MAX_SMALL_SIZE + 12344] == 0x5A, "large object writable");
        kfree(big);
    }
    check(slub_user_objects() == 0, "no live objects after freeing");

    /* 4. 页分配故障注入（大对象路径必然触发底层页分配） */
    slub_fault_inject(1);
    check(kmalloc(SLUB_MAX_SMALL_SIZE + 4096) == NULL,
          "page fault injection makes allocation fail");
    check(slub_fault_hits() >= 1, "fault injection hit counted");
    slub_fault_clear();
    {
        void *p = kmalloc(SLUB_MAX_SMALL_SIZE + 4096);
        check(p != NULL, "allocation works again after clearing faults");
        kfree(p);
    }

    /* 5. 跨 CPU：CPU A 分配 / CPU B 释放 */
    queue_init(&q);
    pa.q = &q;
    pa.failed = 0;
    check(pthread_create(&tp, NULL, producer, &pa) == 0, "producer thread");
    check(pthread_create(&tc, NULL, consumer, &q) == 0, "consumer thread");
    pthread_join(tp, NULL);
    pthread_join(tc, NULL);
    check(!pa.failed, "producer never ran out of memory");
    check(slub_user_objects() == 0, "all cross-cpu objects freed");

    /* 6. shrink：空闲页回到基线、无 slab 残留、统计自洽 */
    slub_shrink();
    after = slub_port_nr_free_pages();
    printf("  free pages after shrink: %lu (baseline %lu)\n",
           (unsigned long)after, (unsigned long)baseline);
    check(after == baseline, "free pages restored to baseline");
    check(slub_slab_pages() == 0, "no slab/large pages held");
    check(slub_user_objects() == 0 && slub_large_objects() == 0,
          "no live objects");

    if (slub_get_class_info(0, &info) == 0) {
        printf("  class0: objsize=%lu sheaf=%lu barn=%lu slab_pages=%lu "
               "objs_per_slab=%lu alloc_fast=%lu alloc_slow=%lu slab_new=%lu\n",
               (unsigned long)info.objsize, (unsigned long)info.sheaf_cap,
               (unsigned long)info.barn_cap, (unsigned long)info.slab_pages,
               (unsigned long)info.objs_per_slab,
               (unsigned long)info.alloc_fast, (unsigned long)info.alloc_slow,
               (unsigned long)info.slab_new);
    }
    printf("slub_host_smoke: PASS (fixed overhead %lu bytes)\n",
           (unsigned long)slub_fixed_overhead());
    return 0;
}
