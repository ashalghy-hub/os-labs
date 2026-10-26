PROJ	:= lab2
EMPTY	:=
SPACE	:= $(EMPTY) $(EMPTY)
SLASH	:= /

V       := @

# 工具链选择：优先使用 riscv64-unknown-elf-；本机没有该工具链时回退到发行版
# 的 riscv64-linux-gnu- 交叉工具链（本仓库当前开发环境即如此）。
# 命令行/环境变量 GCCPREFIX=... 仍然优先（可用 ifndef 检测到）。
ifndef GCCPREFIX
GCCPREFIX := $(shell sh -c 'command -v riscv64-unknown-elf-gcc >/dev/null 2>&1 && echo riscv64-unknown-elf- || echo riscv64-linux-gnu-')
endif

ifndef QEMU
QEMU := qemu-system-riscv64
endif

ifndef SPIKE
SPIKE := spike
endif

# eliminate default suffix rules
.SUFFIXES: .c .S .h

# delete target files if there is an error (or make is interrupted)
.DELETE_ON_ERROR:

# define compiler and flags
HOSTCC		:= gcc
HOSTCFLAGS	:= -Wall -O2

GDB		:= $(GCCPREFIX)gdb

CC		:= $(GCCPREFIX)gcc
CFLAGS  := -mcmodel=medany -std=gnu99 -Wno-unused -Werror 
CFLAGS	+= -fno-builtin -Wall -O2 -nostdinc $(DEFS)
CFLAGS	+= -fno-stack-protector -ffunction-sections -fdata-sections
CFLAGS	+= -g
CFLAGS2 = $(CFLAGS) -D ucore_test
CTYPE	:= c S
LD      := $(GCCPREFIX)ld
LDFLAGS	:= -m elf64lriscv
LDFLAGS	+= -nostdlib --gc-sections

OBJCOPY := $(GCCPREFIX)objcopy
OBJDUMP := $(GCCPREFIX)objdump

COPY	:= cp
MKDIR   := mkdir -p
MV		:= mv
RM		:= rm -f
AWK		:= awk
SED		:= sed
SH		:= sh
TR		:= tr
TOUCH	:= touch -c

OBJDIR	:= obj
BINDIR	:= bin

ALLOBJS	:=
ALLDEPS	:=
TARGETS	:=

include tools/function.mk

listf_cc = $(call listf,$(1),$(CTYPE))

# for cc
add_files_cc = $(call add_files,$(1),$(CC),$(CFLAGS) $(3),$(2),$(4))
add_files_cc2 = $(call add_files,$(1),$(CC),$(CFLAGS2) $(3),$(2),$(4))
create_target_cc = $(call create_target,$(1),$(2),$(3),$(CC),$(CFLAGS))

# for hostcc
add_files_host = $(call add_files,$(1),$(HOSTCC),$(HOSTCFLAGS),$(2),$(3))
create_target_host = $(call create_target,$(1),$(2),$(3),$(HOSTCC),$(HOSTCFLAGS))

cgtype = $(patsubst %.$(2),%.$(3),$(1))
objfile = $(call toobj,$(1))
asmfile = $(call cgtype,$(call toobj,$(1)),o,asm)
outfile = $(call cgtype,$(call toobj,$(1)),o,out)
symfile = $(call cgtype,$(call toobj,$(1)),o,sym)

# for match pattern
match = $(shell echo $(2) | $(AWK) '{for(i=1;i<=NF;i++){if(match("$(1)","^"$$(i)"$$")){exit 1;}}}'; echo $$?)

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# include kernel/user

INCLUDE	+= libs/

CFLAGS	+= $(addprefix -I,$(INCLUDE))

LIBDIR	+= libs

$(call add_files_cc,$(call listf_cc,$(LIBDIR)),libs,)

# -------------------------------------------------------------------
# kernel

KINCLUDE	+= kern/debug/ \
			   kern/driver/ \
			   kern/mm/ \
			   kern/arch/

KSRCDIR		+= kern/init \
			   kern/libs \
			   kern/debug \
			   kern/driver \
			   kern/mm

KCFLAGS		+= $(addprefix -I,$(KINCLUDE))

ifeq ($(MAKECMDGOALS),test)
$(call add_files_cc2,$(call listf_cc,$(KSRCDIR)),kernel,$(KCFLAGS))
else
$(call add_files_cc,$(call listf_cc,$(KSRCDIR)),kernel,$(KCFLAGS))
endif
KOBJS	= $(call read_packet,kernel libs)

# create kernel target
kernel = $(call totarget,kernel)

$(kernel): tools/kernel.ld

$(kernel): $(KOBJS)
	@echo + ld $@
	$(V)$(LD) $(LDFLAGS) -T tools/kernel.ld -o $@ $(KOBJS)
	@$(OBJDUMP) -S $@ > $(call asmfile,kernel)
	@$(OBJDUMP) -t $@ | $(SED) '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $(call symfile,kernel)

$(call create_target,kernel)

# -------------------------------------------------------------------
# create ucore.img
UCOREIMG	:= $(call totarget,ucore.img)


$(UCOREIMG): $(kernel)
	$(OBJCOPY) $(kernel) --strip-all -O binary $@

$(call create_target,ucore.img)

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

$(call finish_all)

IGNORE_ALLDEPS	= clean \
				  dist-clean \
				  grade \
				  touch \
				  print-.+ \
				  handin

ifeq ($(call match,$(MAKECMDGOALS),$(IGNORE_ALLDEPS)),0)
-include $(ALLDEPS)
endif

# files for grade script

TARGETS: $(TARGETS)

.DEFAULT_GOAL := TARGETS
.PHONY: qemu spike test
# 引导方式说明：本工程的内核以 0xFFFFFFFFC0200000 链接，由 OpenSBI 移交
# 控制权后从物理地址 0x80200000 执行。旧写法 `-device loader,file=...,addr=
# 0x80200000` 只把镜像写进内存、不会把入口地址告诉固件；在当前工具环境
# (QEMU 10.1.5 + 自带 OpenSBI v1.5.1) 下 OpenSBI 的 "Domain0 Next Address"
# 会是 0x0，内核从未执行。改用 `-kernel $(UCOREIMG)`（裸二进制，QEMU 同样
# 装载到 0x80200000）可把入口交给 OpenSBI，启动恢复正常。
qemu: $(UCOREIMG) $(SWAPIMG) $(SFSIMG)
	$(V)$(QEMU) \
		-machine virt \
		-nographic \
		-bios default \
		-kernel $(UCOREIMG)

debug: $(UCOREIMG) $(SWAPIMG) $(SFSIMG)
	$(V)$(QEMU) \
		-machine virt \
		-nographic \
		-bios default \
		-kernel $(UCOREIMG) \
		-s -S

gdb:
	riscv64-unknown-elf-gdb \
    -ex 'file bin/kernel' \
    -ex 'set arch riscv:rv64' \
    -ex 'target remote localhost:1234'

test: $(UCOREIMG) $(SWAPIMG) $(SFSIMG)
	$(V)$(QEMU) \
		-machine virt \
		-nographic \
		-bios default \
		-kernel $(UCOREIMG)
spike: $(UCOREIMG) $(SWAPIMG) $(SFSIMG)
	$(V)$(SPIKE) $(UCOREIMG)

# -------------------------------------------------------------------
# SLUB 测试构建/运行：
#   make slub-test         默认 Best-Fit 页分配器 + -DSLUB_TEST
#   make slub-test-buddy   PMM_USE_BUDDY 页分配器 + -DSLUB_TEST
# 切换配置前强制 clean（不同 -D 组合不能复用旧对象文件）。
# 运行判定由 tools/slub_test/run_slub_test.sh 完成：内核通过后仍在
# 空转（while(1)），因此不看 QEMU 退出码，而是轮询 SLUB_TEST_PASS /
# SLUB_TEST_FAIL / panic 标记并带超时。
SLUB_TEST_TIMEOUT ?= 300
SLUB_TEST_IMG     := bin/ucore.img

.PHONY: slub-test slub-test-buddy
slub-test:
	$(V)$(MAKE) clean
	$(V)$(MAKE) DEFS="$(DEFS) -DSLUB_TEST"
	$(V)$(SH) tools/slub_test/run_slub_test.sh $(SLUB_TEST_IMG) $(SLUB_TEST_TIMEOUT)

slub-test-buddy:
	$(V)$(MAKE) clean
	$(V)$(MAKE) DEFS="$(DEFS) -DSLUB_TEST -DPMM_USE_BUDDY"
	$(V)$(SH) tools/slub_test/run_slub_test.sh $(SLUB_TEST_IMG) $(SLUB_TEST_TIMEOUT)

# 宿主侧测试（同一份 slub.c + 同一份 slub_test.c 构建到 Linux 用户态）：
#   make slub-test-host    顺序用例 + 真多线程并发用例 + 负向用例（fork 子进程）
slub-test-host:
	$(V)$(MAKE) -C tools/host run-all

.PHONY: grade touch

GRADE_GDB_IN	:= .gdb.in
GRADE_QEMU_OUT	:= .qemu.out
HANDIN			:= proj$(PROJ)-handin.tar.gz

TOUCH_FILES		:=

MAKEOPTS		:= --quiet --no-print-directory

GRADE_TMP	:= /tmp/lab2_grade

grade:
	$(V)$(MAKE) $(MAKEOPTS) clean
	$(V)$(RM) -rf $(GRADE_TMP)
	$(V)$(MKDIR) $(GRADE_TMP)
	$(V)tar -C . --exclude=.git --exclude=.vscode --exclude=vcs -cf - . | tar -C $(GRADE_TMP) -xf -
	$(V)python3 tools/inject.py $(GRADE_TMP)
	$(V)cd $(GRADE_TMP) && $(SH) tools/grade.sh
	$(V)$(RM) -rf $(GRADE_TMP)

touch:
	$(V)$(foreach f,$(TOUCH_FILES),$(TOUCH) $(f))

print-%:
	@echo $($(shell echo $(patsubst print-%,%,$@) | $(TR) [a-z] [A-Z]))

.PHONY: clean dist-clean handin packall tags
clean:
	$(V)$(RM) $(GRADE_GDB_IN) $(GRADE_QEMU_OUT) cscope* tags
	-$(RM) -r $(OBJDIR) $(BINDIR)

dist-clean: clean
	-$(RM) $(HANDIN)

handin: packall
	@echo Please visit http://learn.tsinghua.edu.cn and upload $(HANDIN). Thanks!

packall: clean
	@$(RM) -f $(HANDIN)
	@tar -czf $(HANDIN) `find . -type f -o -type d | grep -v '^\.*$$' | grep -vF '$(HANDIN)'`

tags:
	@echo TAGS ALL
	$(V)rm -f cscope.files cscope.in.out cscope.out cscope.po.out tags
	$(V)find . -type f -name "*.[chS]" >cscope.files
	$(V)cscope -bq 
	$(V)ctags -L cscope.files
