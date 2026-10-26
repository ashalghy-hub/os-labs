#!/bin/sh
# run_slub_test.sh —— 运行 SLUB 内核测试并自动判定结果
#
# 用法: tools/slub_test/run_slub_test.sh [ucore.img 路径] [超时秒数,默认 300]
#
# 判定依据（内核测试完成后仍在 while(1) 空转，QEMU 不会自行退出，
# 所以不看 QEMU 退出码）：
#   PASS   日志中出现最终标记 SLUB_TEST_PASS，
#          且没有 SLUB_TEST_FAIL / kernel panic / assertion failed
#   FAIL   日志中出现 SLUB_TEST_FAIL 或 panic，或出现失败用例标记
#   TIMEOUT 超时未等到最终标记（并单独报告，避免把挂起当通过）
#
# 退出码: 0=PASS  1=FAIL  2=TIMEOUT

IMG=${1:-bin/ucore.img}
TMO=${2:-300}
QEMU=${QEMU:-qemu-system-riscv64}

if [ ! -f "$IMG" ]; then
    echo "slub_test: image $IMG not found (run make slub-test first)" >&2
    exit 1
fi

LOG=${SLUB_TEST_LOG:-/tmp/slub_test_qemu.log}
: > "$LOG"

echo "slub_test: running $IMG (timeout ${TMO}s), log: $LOG"

$QEMU -machine virt -nographic -bios default -kernel "$IMG" \
    </dev/null >"$LOG" 2>&1 &
QPID=$!

# 轮询日志直到出现最终标记 / 失败标记 / panic，或超时 / QEMU 退出
i=0
while [ "$i" -lt "$TMO" ]; do
    if grep -q "SLUB_TEST_PASS" "$LOG" 2>/dev/null ||
       grep -q "SLUB_TEST_FAIL" "$LOG" 2>/dev/null ||
       grep -q "kernel panic" "$LOG" 2>/dev/null; then
        break
    fi
    if ! kill -0 "$QPID" 2>/dev/null; then
        break   # QEMU 提前退出（例如固件错误），直接进入判定
    fi
    sleep 1
    i=$((i + 1))
done

kill "$QPID" 2>/dev/null
wait "$QPID" 2>/dev/null

echo "slub_test: ---- SLUB 测试输出 ----"
grep -E "SLUB_TEST_|kernel panic|assertion failed|slub_init|slub_smoke" "$LOG" \
    | sed 's/^/  /'
echo "slub_test: ----------------------"

rc=2
reason="timeout after ${TMO}s: no final marker (kernel hung?)"
if grep -q "SLUB_TEST_FAIL" "$LOG"; then
    rc=1
    reason="SLUB_TEST_FAIL marker present"
elif grep -q "kernel panic" "$LOG" || grep -q "assertion failed" "$LOG"; then
    rc=1
    reason="kernel panic/assertion in log"
elif grep -q "SLUB_TEST_PASS" "$LOG"; then
    rc=0
    reason="SLUB_TEST_PASS"
fi

echo "slub_test: RESULT=$rc ($reason)"
exit "$rc"
