/*
 * slub.h —— 简化的 SLUB 内核对象分配器（公开接口）
 *
 * 本模块在页分配器（kern/mm/best_fit_pmm.c / buddy_pmm.c）之上提供第二层：
 * “尺寸类 slab + 每 CPU sheaf 缓存 + 每尺寸类共享 barn 池”，
 * 设计参考 Linux v7.2 mm/slub.c 的 sheaf/barn 机制（见 slub.c 顶部的设计说明）。
 *
 * 分配契约（对所有调用者可见）：
 *   - kmalloc(0)          返回 NULL，且不报错；
 *   - kfree(NULL)         无操作；
 *   - kmalloc 失败        返回 NULL（内存不足或页分配故障注入生效）；
 *   - 返回值满足 16 字节对齐；
 *   - 只接受本模块 kmalloc 返回且尚未释放的指针；
 *   - 重复释放 / 释放非本模块指针 / 非槽位对齐指针属于误用，
 *     正常构建下会触发 panic（见 slub_check_ptr 的诊断细节），不承诺静默处理。
 *
 * 并发契约：
 *   - kmalloc/kfree 可在多线程（每线程绑定一个逻辑 CPU）与中断上下文使用；
 *   - 跨 CPU 释放（CPU A 分配、CPU B 释放）是受支持的路径；
 *   - slub_shrink() 要求“所有调用者静止”（无并发 kmalloc/kfree、无对象正在跨 CPU 传递）。
 *
 * 编译开关：
 *   - SLUB_HOST_PORT：把同一份 slub.c 构建到宿主（Linux 用户态）上，
 *     移植层由 tools/host/slub_host_port.c 提供（用于多线程宿主测试）；
 *   - SLUB_DEBUG：在 kfree 前自动执行 slub_check_ptr 的重复释放/非法指针检测；
 *   - SLUB_NCPUS：并行 CPU 槽数，默认 1（本内核单核运行）。
 */

#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#ifdef SLUB_HOST_PORT
#include <stddef.h>
#else
#include <defs.h>
#endif

#ifndef SIZE_MAX
#define SIZE_MAX ((size_t)-1)
#endif

/* 逻辑 CPU 槽数：内核当前为单核（QEMU 未指定 -smp，OpenSBI 只启动 boot hart），
 * 因此后端默认 1；宿主多线程测试用 -DSLUB_NCPUS=N 覆盖。 */
#ifndef SLUB_NCPUS
#define SLUB_NCPUS 1
#endif

/* 返回值对齐保证（也适用于大对象：32 字节头部 + 页对齐基址） */
#define SLUB_MIN_ALIGN 16

/* 尺寸类：16/32/64/128/256/512/1024/2048；更大请求走连续页分配 */
#define SLUB_NCLASSES 8
#define SLUB_MAX_SMALL_SIZE 2048

/* 大对象头部尺寸（32 字节，保证返回值仍为 16 字节对齐） */
#define SLUB_LARGE_HDR_SIZE 32

/* ---------- 基本分配接口 ---------- */
void slub_init(void);
void *kmalloc(size_t size);
void kfree(void *ptr);

/* 回收空闲内存：排空 CPU 本地 sheaf 缓存与共享 barn、
 * 归还空 slab 占用的页；不会释放仍被用户持有的对象。
 * 前提：所有调用者静止（无并发 kmalloc/kfree/跨 CPU 对象传递）。
 * 幂等：在静止状态下可反复调用。 */
void slub_shrink(void);

/* ---------- 只读信息 / 统计 ---------- */
struct slub_class_info {
    size_t objsize;        /* 尺寸类对象字节数 */
    size_t sheaf_cap;      /* 每 CPU main/spare sheaf 容量（对象数） */
    size_t barn_cap;       /* 每尺寸类共享 barn 容量（对象数） */
    size_t slab_pages;     /* 每个 slab 占用的页数 */
    size_t objs_per_slab;  /* 每个 slab 的对象槽数 */
    size_t nr_slabs;       /* 当前 slab 总数 */
    size_t nr_partial;     /* 挂在 partial 链上的 slab 数 */
    size_t nr_full;        /* 满的 slab 数（不挂链） */
    size_t nr_empty;       /* 保留在 empty 链上的空 slab 数 */
    size_t slab_pages_used;/* 该尺寸类占用的底层页数 */
    size_t inuse_objs;     /* 不在 slab 空闲链上的对象数（用户 + sheaf + barn） */
    size_t user_objs;      /* 用户持有的对象数（不含 sheaf/barn 缓存） */
    size_t alloc_fast;     /* 本地 sheaf 命中分配数（各 CPU 累加） */
    size_t alloc_slow;     /* barn/slab 补充路径分配数（各 CPU 累加） */
    size_t free_fast;      /* 本地 sheaf 命中释放数 */
    size_t free_slow;      /* 进入共享层（barn/slab）的释放数 */
    size_t refill;         /* slab 层补充给 sheaf/barn 的对象数 */
    size_t flush;          /* 回到 slab 空闲链的对象数 */
    size_t barn_get;       /* barn 批量取出对象数 */
    size_t barn_put;       /* barn 批量放入对象数 */
    size_t slab_new;       /* 新建 slab 次数 */
    size_t slab_free;      /* 销毁 slab（归还页）次数 */
    size_t slab_fail;      /* 新建 slab 失败次数（页分配失败 / 描述符耗尽） */
};

size_t slub_nr_classes(void);
/* 尺寸类下标；size==0 或大于 SLUB_MAX_SMALL_SIZE 返回 -1 */
int slub_size_to_class(size_t size);
/* 下标越界返回 0 */
size_t slub_class_size(size_t cls);
/* 成功返回 0；cls 越界或 out==NULL 返回 -1 */
int slub_get_class_info(size_t cls, struct slub_class_info *out);

/* 全局汇总（测试用：观察回收效果与占用量） */
size_t slub_user_objects(void);    /* 用户持有对象总数（小对象 + 大对象） */
size_t slub_large_objects(void);   /* 活跃大对象个数 */
size_t slub_slab_pages(void);      /* SLUB 持有的底层页数（所有 slab + 大对象） */
size_t slub_fixed_overhead(void);  /* 初始化后固定保留的静态开销（字节，sizeof 累加） */

/* ---------- 底层页分配故障注入（运行时接口，不改变默认构建） ----------
 * 让接下来 npages 次底层页分配尝试返回失败（已成功的分配不受影响，
 * 进行中的分配也不被打断）；npages==0 等价于 slub_fault_clear()。
 * 注意：需先排空本地 sheaf/barn 缓存，才能确保触发到目标分配。 */
void slub_fault_inject(size_t npages);
void slub_fault_clear(void);
size_t slub_fault_hits(void);      /* 已触发的失败次数 */

/* ---------- 调试检查 ----------
 * 校验 ptr 是否为“当前可释放”的对象：
 *   - 指针 16 字节对齐且落在 RAM 映射范围内；
 *   - 要么属于某个活跃 slab 且位于合法槽位；
 *   - 要么大对象头部 magic/base/npages 一致；
 *   - 且不在任何 sheaf/barn/slab 空闲链上（即非重复释放）。
 * 出现问题直接 panic（不静默），无问题时无副作用返回。 */
void slub_check_ptr(void *ptr);

#ifdef SLUB_DEBUG
/* 全局一致性校验（测试/调试用，静止态调用）：
 * 空闲链无环且不越界、freelist+inuse==capacity、partial/empty/full 状态
 * 与链表归属一致、对象四态互斥（Σinuse == 用户+sheaf+barn 计数）。
 * 返回 NULL 表示一致；否则返回静态错误描述串（下次调用前有效）。 */
const char *slub_debug_validate(void);
#endif

#endif /* !__KERN_MM_SLUB_H__ */
