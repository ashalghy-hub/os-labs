# 宿主多线程冒烟：把同一份 kern/mm/slub.c 构建到 Linux 用户态。
# 不参与内核构建（本目录不在 Makefile 的 KSRCDIR/LIBDIR 中）。
#
#   make          构建 slub_host_smoke
#   make run      构建并运行冒烟
#   make clean    清理
#
# -DSLUB_HOST_PORT   选择宿主移植层（tools/host/slub_host_port.c）
# -DSLUB_NCPUS=4     模拟 4 个逻辑 CPU（线程绑定后即为各自的 sheaf 归属）
# EXTRA_DEFS         追加开关，例如 make EXTRA_DEFS=-DSLUB_DEBUG run

TOP   := ../..
CC    ?= gcc
CFLAGS ?= -Wall -O2 -g -pthread
DEFS  := -DSLUB_HOST_PORT -DSLUB_NCPUS=4 $(EXTRA_DEFS)
INC   := -I$(TOP)/kern/mm

SRCS  := slub_host_port.c slub_host_smoke.c $(TOP)/kern/mm/slub.c
DEPS  := $(TOP)/kern/mm/slub.h $(TOP)/kern/mm/slub_port.h

all: slub_host_smoke

slub_host_smoke: $(SRCS) $(DEPS)
	$(CC) $(CFLAGS) $(DEFS) $(INC) -o $@ $(SRCS) -lpthread

run: slub_host_smoke
	./slub_host_smoke

clean:
	rm -f slub_host_smoke

.PHONY: all run clean
