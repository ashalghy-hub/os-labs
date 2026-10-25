#!/bin/sh
# run_all.sh —— 依次跑宿主全部测试并给出总判定
#
#   1) smoke       原冒烟用例（契约/对齐/跨 CPU/回收）
#   2) debug       顺序 13 用例 + 每次操作后 SLUB_DEBUG 不变量校验
#   3) test        顺序 13 用例（快速构建，固定种子）
#   4) test-seed3  同上，外部种子覆盖（SLUB_TEST_SEED=12345）
#   5) neg         负向用例（重复释放/非法指针必须 panic）
#   6) mt          真多线程并发用例
#
# 判定不依赖单个命令的退出码组合以外的东西；任一失败即总失败。
# TSan（make tsan）需系统提供 libtsan；本机若缺失则跳过并如实标注。

set -u
cd "$(dirname "$0")" || exit 1

rc=0
run() {
    echo "==== $* ===="
    if ! "$@"; then
        echo "==== $* : FAILED ===="
        rc=1
    else
        echo "==== $* : ok ===="
    fi
}

run make smoke
run make debug
run make test
run make test-seed3
run make neg
run make mt

if make tsan >/dev/null 2>&1; then
    run make tsan
else
    echo "==== tsan SKIPPED: toolchain/libtsan not available on this host ===="
fi

if [ "$rc" -eq 0 ]; then
    echo "HOST_RUN_ALL: PASS"
else
    echo "HOST_RUN_ALL: FAIL"
fi
exit "$rc"
