/*
 * slub_port.h —— SLUB 分配器的平台移植层
 *
 * slub.c 只通过本文件声明的接口与平台交互，不直接依赖 CPU/锁/页分配细节：
 *   - CPU 定位        slub_port_cpu_id()
 *   - 本地临界区      slub_port_local_lock/unlock   （防同核中断重入，不是多核互斥）
 *   - 共享自旋锁      slub_port_spin_*              （acquire/release 语义）
 *   - 底层页分配      slub_port_pages_alloc/free、slub_port_page_kva、
 *                     slub_port_nr_free_pages
 *   - 指针合法性边界  slub_port_ram_low/high        （可解引用的 RAM KVA 范围）
 *   - 输出/致命错误   slub_port_printf / slub_port_panic
 *
 * 两个后端：
 *   - 内核后端（默认）：当前内核只启动 1 个 hart（QEMU 未指定 -smp，
 *     OpenSBI 仅启动 boot hart），因此 SLUB_NCPUS=1。
 *     CPU 定位来自 entry.S 记录的 boot_hartid（硬件 ID，而不是硬编码 0）；
 *     本地临界区 = 关本地中断（SIE）+ 内存屏障；
 *     自旋锁 = 原子 test-and-set + 关中断（关中断不能代替多核互斥）。
 *     若将来启用 SMP：保持本文件接口不变，替换为真正的 per-CPU 结构与原子锁，
 *     并把 SLUB_NCPUS 调整为实际 hart 数即可接入同一份分配核心。
 *   - 宿主后端（SLUB_HOST_PORT）：tools/host/slub_host_port.c 用
 *     pthread 互斥 + TLS CPU 绑定实现同一组接口，供多线程宿主测试使用。
 */

#ifndef __KERN_MM_SLUB_PORT_H__
#define __KERN_MM_SLUB_PORT_H__

#ifdef SLUB_HOST_PORT

/* ------------------------- 宿主适配层 ------------------------- */
#include <stddef.h>
#include <stdint.h>
#include <pthread.h>

#ifndef SLUB_PAGE_SIZE
#define SLUB_PAGE_SIZE 4096
#endif

typedef int slub_port_flags_t;

/* 由 tools/host/slub_host_port.c 定义（页池描述符） */
typedef struct slub_host_page slub_page_t;

typedef struct slub_spinlock {
    pthread_mutex_t mutex;
} slub_spinlock_t;

unsigned int slub_port_cpu_id(void);
void slub_port_local_lock(slub_port_flags_t *flags);
void slub_port_local_unlock(slub_port_flags_t *flags);
void slub_port_spin_init(slub_spinlock_t *lock);
void slub_port_spin_lock(slub_spinlock_t *lock, slub_port_flags_t *flags);
void slub_port_spin_unlock(slub_spinlock_t *lock, slub_port_flags_t *flags);

slub_page_t *slub_port_pages_alloc(size_t npages);      /* NULL=失败 */
void slub_port_pages_free(slub_page_t *base, size_t npages);
void *slub_port_page_kva(slub_page_t *base);            /* 页的内核虚拟地址 */
size_t slub_port_nr_free_pages(void);
void *slub_port_ram_low(void);                          /* 可解引用地址下界 */
void *slub_port_ram_high(void);                         /* 可解引用地址上界（不含） */

void slub_port_printf(const char *fmt, ...);
void slub_port_panic(const char *fmt, ...) __attribute__((noreturn));
#define slub_port_assert(x)                                                     \
    do {                                                                        \
        if (!(x))                                                               \
            slub_port_panic("slub: assertion failed: %s (%s:%d)", #x, __FILE__, \
                            __LINE__);                                          \
    } while (0)

#else /* ------------------------- 内核后端 ------------------------- */

#include <assert.h>
#include <defs.h>
#include <dtb.h>
#include <mmu.h>
#include <pmm.h>
#include <riscv.h>
#include <stdio.h>

/* 页大小沿用 mmu.h（PGSIZE），slub.c 统一使用 SLUB_PAGE_SIZE */
#ifndef SLUB_PAGE_SIZE
#define SLUB_PAGE_SIZE PGSIZE
#endif

typedef int slub_port_flags_t;
typedef struct Page slub_page_t;

typedef struct slub_spinlock {
    volatile unsigned int locked; /* 0=空闲 1=持锁（真正的互斥靠原子指令） */
} slub_spinlock_t;

static inline unsigned int slub_port_cpu_id(void) {
    /* entry.S 保存的启动 hart 硬件 ID（单核环境下为 0，但来源是硬件而非常量） */
    return (unsigned int)boot_hartid;
}

static inline void slub_port_local_lock(slub_port_flags_t *flags) {
    unsigned long s = read_csr(sstatus);
    *flags = (s & SSTATUS_SIE) != 0;
    if (*flags) {
        clear_csr(sstatus, SSTATUS_SIE);
    }
    __sync_synchronize();
}

static inline void slub_port_local_unlock(slub_port_flags_t *flags) {
    __sync_synchronize();
    if (*flags) {
        set_csr(sstatus, SSTATUS_SIE);
    }
    *flags = 0;
}

static inline void slub_port_spin_init(slub_spinlock_t *lock) {
    lock->locked = 0;
    __sync_synchronize();
}

static inline void slub_port_spin_lock(slub_spinlock_t *lock,
                                       slub_port_flags_t *flags) {
    /* 关本地中断：防止“同核中断里再取同一把锁”的自旋死锁；
     * 多核互斥完全由下面的原子操作提供。 */
    slub_port_local_lock(flags);
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
        /* 自旋等待；锁序保证不会出现持锁自等待 */
    }
    __sync_synchronize(); /* acquire */
}

static inline void slub_port_spin_unlock(slub_spinlock_t *lock,
                                         slub_port_flags_t *flags) {
    __sync_synchronize(); /* release */
    __sync_lock_release(&lock->locked);
    slub_port_local_unlock(flags);
}

static inline slub_page_t *slub_port_pages_alloc(size_t npages) {
    /* 调用方（slub.c）持有 slub_pmm_lock：底层 best-fit/buddy 均非线程安全 */
    return alloc_pages(npages);
}

static inline void slub_port_pages_free(slub_page_t *base, size_t npages) {
    /* npages 必须是当初分配时的原始请求值（buddy 断言 property==n） */
    free_pages(base, npages);
}

static inline void *slub_port_page_kva(slub_page_t *base) {
    /* 按真实映射关系访问物理页：VA = PA + va_pa_offset（勿解引用物理地址） */
    return (void *)(page2pa(base) + va_pa_offset);
}

static inline size_t slub_port_nr_free_pages(void) {
    return nr_free_pages();
}

static inline void *slub_port_ram_low(void) {
    return (void *)(nbase * (size_t)PGSIZE + va_pa_offset);
}

static inline void *slub_port_ram_high(void) {
    return (void *)(npage * (size_t)PGSIZE + va_pa_offset);
}

#define slub_port_printf cprintf
#define slub_port_panic(...) panic(__VA_ARGS__)
#define slub_port_assert(x) assert(x)

#endif /* SLUB_HOST_PORT */

#endif /* !__KERN_MM_SLUB_PORT_H__ */
