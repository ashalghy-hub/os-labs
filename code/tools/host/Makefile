# Host (Linux) build of the kern/mm slub allocator for testing.
#
#   make smoke   - original smoke test (fast)
#   make debug   - full sequential suite + SLUB_DEBUG invariant check after
#                  every allocation/free (slower, catches allocator corruption)
#   make test    - full sequential suite (13 cases, fixed seed, fast)
#   make test-seed3 - same suite with an external seed override (SLUB_TEST_SEED)
#   make neg     - negative tests: double free / wild pointer must panic
#   make mt      - multithreaded concurrency suite (pinned threads, real mutexes)
#   make tsan    - concurrency suite under ThreadSanitizer
#   make run-all - smoke + debug + test + test-seed3 + neg + mt
#   make clean

CC      ?= gcc
NCPUS   ?= 4
CFLAGS  := -O2 -g -Wall -Wextra -Wno-unused-parameter -Wno-sign-compare -pthread -DSLUB_HOST_PORT -DSLUB_NCPUS=$(NCPUS)
LDLIBS  := -lpthread

BUILD   := build
SMOKEBIN  := $(BUILD)/slub_host_smoke
DEBUGBIN  := $(BUILD)/slub_host_debug
TESTBIN   := $(BUILD)/slub_host_test
NEGBIN    := $(BUILD)/slub_host_neg
MTBIN     := $(BUILD)/slub_host_mt
TSANBIN   := $(BUILD)/slub_host_tsan

# Shared code under test (single source shared with the kernel build).
SLUB_SRCS := ../../kern/mm/slub.c
TEST_SRCS := ../../kern/mm/slub_test.c
PORT_SRCS := slub_host_port.c
INCLUDES  := -I../../kern/mm -I../../kern -I.

.PHONY: all clean smoke debug test test-seed3 neg mt tsan run-all run

all: smoke

$(BUILD):
	@mkdir -p $(BUILD)

smoke: $(SMOKEBIN)
	./$(SMOKEBIN)

# 兼容旧入口：make run == make smoke
run: smoke

$(SMOKEBIN): slub_host_smoke.c $(SLUB_SRCS) $(PORT_SRCS) | $(BUILD)
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $^ $(LDLIBS)

# Full sequential suite with permanent SLUB_DEBUG invariant validation after
# every operation (SLUB_TEST_VALIDATE).  Any invariant violation prints a line
# containing "INVALID" and is counted as a test failure.
$(DEBUGBIN): slub_host_main.c $(SLUB_SRCS) $(TEST_SRCS) $(PORT_SRCS) | $(BUILD)
	$(CC) $(CFLAGS) -O0 -DSLUB_DEBUG -DSLUB_TEST -DSLUB_TEST_VALIDATE $(INCLUDES) -o $@ $^ $(LDLIBS)

debug: $(DEBUGBIN)
	./$(DEBUGBIN)

# Full sequential suite, fast build.  Seed overridable from outside:
#   SLUB_TEST_SEED=12345 ./build/slub_host_test
$(TESTBIN): slub_host_main.c $(SLUB_SRCS) $(TEST_SRCS) $(PORT_SRCS) | $(BUILD)
	$(CC) $(CFLAGS) -DSLUB_TEST $(INCLUDES) -o $@ $^ $(LDLIBS)

test: $(TESTBIN)
	./$(TESTBIN)

test-seed3: $(TESTBIN)
	SLUB_TEST_SEED=12345 ./$(TESTBIN)

# Negative tests: double free and wild pointer must panic (via SLUB_DEBUG).
$(NEGBIN): slub_host_neg.c $(SLUB_SRCS) $(PORT_SRCS) | $(BUILD)
	$(CC) $(CFLAGS) -O0 -DSLUB_DEBUG $(INCLUDES) -o $@ $^ $(LDLIBS)

neg: $(NEGBIN)
	./$(NEGBIN)

# Concurrency suite (pinned threads, real mutexes, shared address registry).
# Shrink for a quick run: make mt MT_ITERS=2 MT_CHURN_ROUNDS=2
$(MTBIN): slub_host_mt.c slub_host_main.c $(SLUB_SRCS) $(PORT_SRCS) | $(BUILD)
	$(CC) $(filter-out -DSLUB_NCPUS=%,$(CFLAGS)) -DSLUB_NCPUS=5 -DSLUB_MT $(MT_ITERS:%=-DMT_ITERS=%) $(MT_CHURN_ROUNDS:%=-DMT_CHURN_ROUNDS=%) $(INCLUDES) -o $@ $^ $(LDLIBS)

mt: $(MTBIN)
	./$(MTBIN)

# ThreadSanitizer build of the concurrency suite (aarch64 host => weaker
# memory orders; races are reported, not necessarily crashed).
$(TSANBIN): slub_host_mt.c slub_host_main.c $(SLUB_SRCS) $(PORT_SRCS) | $(BUILD)
	$(CC) $(filter-out -DSLUB_NCPUS=%,$(CFLAGS)) -O1 -fsanitize=thread -g -DSLUB_NCPUS=5 -DSLUB_MT $(INCLUDES) -o $@ $^ $(LDLIBS)

tsan: $(TSANBIN)
	TSAN_OPTIONS="halt_on_error=0" ./$(TSANBIN)

run-all: smoke debug test test-seed3 neg mt
	@echo "ALL HOST TARGETS COMPLETED"

clean:
	rm -rf $(BUILD)
