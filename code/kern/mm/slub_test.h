/*
 * slub_test.h —— SLUB 分配器测试套件入口
 *
 * check_slub():   内核入口。仅在以 -DSLUB_TEST 构建时由 kern/init/init.c
 *                 在 pmm_init() + slub_init() 之后、业务代码之前调用；
 *                 默认构建下 slub_test.c 编译为空，不影响正常启动。
 * slub_test_run():顺序用例主体（内核与宿主共享同一实现），返回失败用例数；
 *                 成功路径不打印最终标记，由调用方（check_slub 或宿主 main）
 *                 在全部用例（含并发）完成后输出 SLUB_TEST_PASS。
 */

#ifndef __KERN_MM_SLUB_TEST_H__
#define __KERN_MM_SLUB_TEST_H__

void check_slub(void);
int slub_test_run(unsigned long seed); /* 0 表示全部用例通过 */

#endif /* !__KERN_MM_SLUB_TEST_H__ */
