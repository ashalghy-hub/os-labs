/*
 * slub_host_port.c —— SLUB 分配器的宿主（Linux 用户态）移植层实现
 *
 * 目的：把同一份 kern/mm/slub.c 构建成宿主程序，用于多线程宿主测试
 * （例如 CPU A 分配 / CPU B 释放、并发分配释放不丢失对象等）。
 * 仅此文件依赖 libc/pthread；slub.c 本身不依赖任何宿主线程库。
 *
 * 提供：
 *   - 页池：静态连续页池（可用 -DSLUB_HOST_POOL_MB 调整），
 *     slub_port_pages_alloc/free 用“首个满足长度的连续空闲段”分配；
 *     由于 slub.c 只在 slub_pmm_lock 下调用它们，页池自身不需要加锁。
 *   - CPU 定位：线程局部 slub_host_bind_cpu(cpu) 绑定逻辑 CPU 号
 *     （范围 [0, SLUB_NCPUS)）。
 *   - 本地临界区：本 CPU 的 sheaf 由绑定线程独占，因此实现为内存屏障
 *     （不承担互斥语义；真正的互斥全部由 spinlock 提供）。
 *   - 共享自旋锁：pthread 互斥锁。
 *   - panic：打印后 abort。
 */

#include <slub_port.h>

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef SLUB_HOST_POOL_MB
#define SLUB_HOST_POOL_MB 64
#endif

#define HOST_POOL_PAGES ((SLUB_HOST_POOL_MB) * 1024 * 1024 / SLUB_PAGE_SIZE)

/* 页描述符（slub_port.h 里只是前向声明） */
struct slub_host_page {
    size_t index;
};

static unsigned char host_arena[HOST_POOL_PAGES * SLUB_PAGE_SIZE]
    __attribute__((aligned(4096)));
static struct slub_host_page host_pages[HOST_POOL_PAGES];
static unsigned char host_used[HOST_POOL_PAGES];
static size_t host_free_pages = HOST_POOL_PAGES;

static __thread unsigned host_cpu_id; /* 默认 0，主线程无需显式绑定 */

void slub_host_bind_cpu(unsigned int cpu) {
    if (cpu >= SLUB_NCPUS) {
        fprintf(stderr, "slub_host: cpu %u out of range (SLUB_NCPUS=%d)\n",
                cpu, SLUB_NCPUS);
        abort();
    }
    host_cpu_id = cpu;
}

unsigned int slub_host_nr_free_pages(void) {
    return (unsigned int)__sync_fetch_and_add(&host_free_pages, 0);
}

unsigned int slub_port_cpu_id(void) {
    return host_cpu_id;
}

/*
 * 本地临界区：slub.c 用它标记“本 CPU 的 sheaf 正在更新”。
 * 宿主侧每个 sheaf 由绑定线程独占，因此这里只需要屏障，
 * 以保持与内核版本相同的读写顺序（不作为多核互斥）。
 */
void slub_port_local_lock(slub_port_flags_t *flags) {
    (void)flags;
    __sync_synchronize();
}

void slub_port_local_unlock(slub_port_flags_t *flags) {
    (void)flags;
    __sync_synchronize();
}

void slub_port_spin_init(slub_spinlock_t *lock) {
    if (pthread_mutex_init(&lock->mutex, NULL) != 0) {
        fprintf(stderr, "slub_host: pthread_mutex_init failed\n");
        abort();
    }
}

void slub_port_spin_lock(slub_spinlock_t *lock, slub_port_flags_t *flags) {
    (void)flags;
    if (pthread_mutex_lock(&lock->mutex) != 0) {
        fprintf(stderr, "slub_host: pthread_mutex_lock failed\n");
        abort();
    }
}

void slub_port_spin_unlock(slub_spinlock_t *lock, slub_port_flags_t *flags) {
    (void)flags;
    if (pthread_mutex_unlock(&lock->mutex) != 0) {
        fprintf(stderr, "slub_host: pthread_mutex_unlock failed\n");
        abort();
    }
}

/* 页池：找第一段长度 >= npages 的连续空闲区间 */
slub_page_t *slub_port_pages_alloc(size_t npages) {
    size_t i, run = 0;

    if (npages == 0 || npages > HOST_POOL_PAGES) return NULL;
    for (i = 0; i < HOST_POOL_PAGES; i++) {
        if (host_used[i]) {
            run = 0;
            continue;
        }
        if (++run == npages) {
            size_t start = i + 1 - npages, k;
            for (k = 0; k < npages; k++) host_used[start + k] = 1;
            host_free_pages -= npages;
            return &host_pages[start];
        }
    }
    return NULL;
}

void slub_port_pages_free(slub_page_t *base, size_t npages) {
    size_t start = base - host_pages, k;

    if (start + npages > HOST_POOL_PAGES) {
        fprintf(stderr, "slub_host: free out of range\n");
        abort();
    }
    for (k = 0; k < npages; k++) {
        if (!host_used[start + k]) {
            fprintf(stderr, "slub_host: double free of page %lu\n",
                    (unsigned long)(start + k));
            abort();
        }
        host_used[start + k] = 0;
    }
    host_free_pages += npages;
}

void *slub_port_page_kva(slub_page_t *base) {
    return host_arena + (size_t)(base - host_pages) * SLUB_PAGE_SIZE;
}

size_t slub_port_nr_free_pages(void) {
    return host_free_pages;
}

void *slub_port_ram_low(void) {
    return host_arena;
}

void *slub_port_ram_high(void) {
    return host_arena + sizeof(host_arena);
}

void slub_port_printf(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vfprintf(stdout, fmt, ap);
    va_end(ap);
    fflush(stdout);
}

void slub_port_panic(const char *fmt, ...) {
    va_list ap;
    fprintf(stderr, "slub_host: panic: ");
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fprintf(stderr, "\n");
    abort();
}
