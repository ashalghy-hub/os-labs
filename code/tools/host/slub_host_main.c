/*
 * slub_host_main.c —— 宿主测试主程序
 *
 * 运行同一份 slub.c + 同一份 slub_test.c：
 *   默认      顺序功能/回收/故障恢复用例（与内核一致，13 个用例）
 *   --neg     负向用例（重复释放/非法指针必须 panic，独立进程运行）
 *   -DMT      再追加多线程并发用例
 * 全部通过打印 SLUB_TEST_PASS，否则打印 SLUB_TEST_FAIL。
 *
 * 用法：./slub_host_test [seed]        （seed 也可用环境变量 SLUB_TEST_SEED）
 *       ./slub_host_neg               （负向用例，见 slub_host_neg.c）
 */

#include <slub.h>
#include <slub_test.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void slub_host_bind_cpu(unsigned int cpu);
#ifdef SLUB_MT
int slub_test_mt(unsigned long seed);
#endif

int main(int argc, char **argv) {
    unsigned long seed = 0;
    const char *env = getenv("SLUB_TEST_SEED");
    int fail = 0;
    int i;

    if (env && *env)
        seed = strtoul(env, NULL, 0);
    for (i = 1; i < argc; i++)
        seed = strtoul(argv[i], NULL, 0);

    slub_host_bind_cpu(0);
    slub_init();

#ifdef SLUB_TEST
    fail = slub_test_run(seed); /* 顺序用例（成功时不打最终标记） */
#endif
#ifdef SLUB_MT
    if (fail == 0)
        fail = slub_test_mt(seed); /* 并发用例 */
#endif

    if (fail != 0) {
        printf("SLUB_TEST_FAIL host_total_failures=%d seed=%lu\n", fail,
               seed ? seed : (unsigned long)0xC0FFEE51ABC0FFEEUL);
        return 1;
    }
    printf("SLUB_TEST_PASS\n");
    return 0;
}
