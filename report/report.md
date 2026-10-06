# Lab1 实验报告：最小可执行内核与启动流程

实验日期：2026 年 10 月 6 日

代码仓库：https://github.com/ashalghy-hub/os-labs

实验分支：`lab1`

实验平台：Windows + Ubuntu 26.04.1 WSL2，QEMU `virt`，RISC-V 64 位。

| 角色 | 姓名 | 学号 | 班级 | 分工 |
|---|---|---|---|---|
| 组长（提交者） | 待填写 | 待填写 | 待填写 | 待小组确认 |
| 成员 2 | 待填写 | 待填写 | 待填写 | 待小组确认 |
| 成员 3 | 待填写 | 待填写 | 待填写 | 待小组确认 |

说明：实验操作由 AI 助手协助执行；本报告依据本机实际编译和调试日志整理。成员身份、分工和个人学习感受由小组自行补全，不将 AI 的操作冒充成员独立完成的操作。

## 1. 实验目标、要求与完成情况

依据[实验目的](http://8.135.34.58/lab2026/_book/lab1/lab1_1_goals.html)、[练习](http://8.135.34.58/lab2026/_book/lab1/lab1_2_1_exercise.html)和[报告要求](http://8.135.34.58/lab2026/_book/lab1/lab1_5_requirement.html)，本实验围绕“启动一个能输出字符串并进入死循环的最小内核”展开。

| 要求 | 完成内容 | 核对依据 |
|---|---|---|
| 理解链接、交叉编译和内存布局 | 分析 Makefile、链接脚本及 ELF 段和入口 | `logs/build.txt`、`logs/elf.txt` |
| 练习 1：解释入口操作 | 解释 `la sp, bootstacktop`、`tail kern_init`，并用寄存器验证 | 第 4 节、`logs/gdb.txt` |
| 练习 2：GDB 跟踪复位到内核入口 | 从 `0x1000` 单步进入固件，在 `0x80200000` 断下 | 第 5 节、`tools/boot.gdb` |
| 理解输出模块 | 分析从 `cprintf` 到 SBI、串口的调用链 | 第 6 节、`logs/qemu-debug.txt` |
| 说明整体逻辑、核心模块和原理对应关系 | 分别给出流程、模块说明和知识点表格 | 第 2、3、7 节 |
| 记录 AI 协作、错误和测试 | 保存原始提示词、实验记录、失败及成功日志 | `prompt.md`、`record.md` |
| 按仓库约定组织材料 | `lab1` 分支下 `code/`、`report/` 和 `report/images/` | 仓库 README |

本次没有要求实现新的内存管理、进程调度或中断处理函数；压缩包已包含最小内核。本次改动集中在当前工具环境下的启动兼容性和可复现验证，不额外扩展内核功能。

## 2. 整体逻辑线与操作流程

本章的逻辑是先确定内核在哪里运行，再生成与地址匹配的镜像，接着通过固件进入内核，建立 C 语言运行所需的栈和静态存储环境，最后通过固件服务实现最小输出。GDB 用来逐段验证这些环节。

构建流程：

```text
C / 汇编源文件
  → riscv64-unknown-elf-gcc 编译为 .o
  → ld 按 tools/kernel.ld 链接为 bin/kernel（ELF）
  → objcopy -O binary 生成 bin/ucore.img（裸镜像）
```

实际启动流程：

```text
QEMU 在 CPU 执行前准备内存、固件、内核镜像和设备树
  → CPU 复位 PC = 0x1000，执行 MROM 复位跳板
  → 跳到 0x80000000，执行 OpenSBI（M 模式）
  → OpenSBI 初始化并将控制权交给下一阶段（配置为 S 模式）
  → 0x80200000：kern_entry，初始化 sp
  → kern_init：清零 BSS，格式化打印
  → while (1)：原地循环
```

操作顺序为：阅读网站及源码 → 检查 WSL 与交叉编译器 → 补齐 QEMU/GDB → 编译原始代码 → 运行并发现启动兼容问题 → 修改 Makefile → GDB 验证 → 保存日志和截图 → 整理报告与提示词 → Git 提交。

注意区分“把镜像放入内存”和“CPU 开始执行镜像”。本次 QEMU 在复位暂停时已经放好了内核；OpenSBI负责运行环境初始化和控制权移交。该结论来自本次配置，不能据此断言所有固件和实体开发板都采用相同加载机制。

## 3. 环境、项目组成与内存布局

### 3.1 实际工具版本

| 工具 | 实测版本 |
|---|---|
| Ubuntu | 26.04.1 LTS，WSL2 |
| RISC-V GCC | 14.2.0 |
| GNU ld | 2.45.50.20251209 |
| GNU make | 4.4.1 |
| QEMU | 10.2.1 |
| GDB | gdb-multiarch 17.1 |
| OpenSBI | 启动横幅 v1.8，软件包版本 1.8.1-1 |

安装记录和注意事项见 `record.md`。Ubuntu 26.04 将 RISC-V 模拟器放在 `qemu-system-riscv` 软件包中，安装 `qemu-system-misc` 后仍缺少 `qemu-system-riscv64`，因此补装前者。无需为本实验重新从源码构建 GCC 或 QEMU。

### 3.2 核心文件与功能

| 文件 | 作用与关键点 |
|---|---|
| `kern/init/entry.S` | 定义 `kern_entry`，设置内核栈，尾跳转进入 C；在 `.data` 预留启动栈 |
| `kern/init/init.c` | `kern_init` 清理 BSS，调用 `cprintf` 输出，随后死循环；带 `noreturn` 属性 |
| `kern/mm/mmu.h`、`memlayout.h` | 定义页大小与栈大小：页为 4096 字节，栈为两页，共 8192 字节 |
| `tools/kernel.ld` | 指定 RISC-V 架构、入口符号、基址和各段次序，并定义 `edata`、`end` |
| `Makefile`、`tools/function.mk` | 管理编译、链接、反汇编、镜像生成及 QEMU/GDB 命令 |
| `kern/libs/stdio.c` | `cprintf`、`vcprintf` 和字符输出回调，封装可变参数与输出计数 |
| `libs/printfmt.c` | `vprintfmt` 解析格式字符串，逐字符调用回调 |
| `kern/driver/console.c` | `cons_putc` 连接高层输出和 SBI 字符输出 |
| `libs/sbi.c` | 将服务号和参数放入寄存器，通过 `ecall` 请求 OpenSBI 服务 |
| `libs/string.c` | 提供 `memset` 等内核使用的基础库函数 |
| `tools/boot.gdb`、`tools/verify.py` | 本次新增：记录实际调试过程，执行构建、地址、栈和输出断言 |

网站项目树含有一些后续模块名称，但本次压缩包并没有完整的 `debug/`、`trap/` 或物理页管理实现。本报告以压缩包中的实际文件为准。

### 3.3 链接与实际地址

链接脚本使用 `ENTRY(kern_entry)` 指定 ELF 入口，通过位置计数器 `. = 0x80200000` 设置内核起点，再依次安排代码、只读数据和可写数据。`.data` 前使用 `ALIGN(0x1000)`，启动栈本身也按页对齐。`edata` 标记初始化数据之后的位置，`end` 标记 BSS 结束位置。

本次 `readelf` 与 GDB 观察如下：

| 对象 | 地址或范围 | 说明 |
|---|---|---|
| MROM 复位跳板 | `0x1000` 起 | 不是 OpenSBI 的主体 |
| OpenSBI | `0x80000000` 起 | QEMU 默认固件 |
| ELF 入口、`kern_entry` | `0x80200000` | 与内核加载地址一致 |
| `kern_init` | `0x8020000a` | 紧接入口汇编 |
| `.text` | `0x80200000`，大小 `0x4ae` | 可执行代码 |
| `.rodata` | `0x802004b0`，大小 `0x270` | 字符串等只读数据 |
| `.data`、`bootstack` | `0x80201000` | 启动栈占 8192 字节 |
| `bootstacktop` | `0x80203000` | 栈空间末端的后一地址 |
| `.sdata` | `0x80203000`，大小 8 字节 | 栈向低地址增长，故不与此数据重叠 |
| `edata`、`end` | 均为 `0x80203008` | 本次最终链接的 BSS 区间为空 |
| 设备树地址 `a1` | `0x87e00000` | 属于本次 QEMU 配置，不能作为通用常量 |

`bin/kernel` 保留入口、段信息、符号和调试信息，供 GDB 使用；`bin/ucore.img` 是无 ELF 文件头的裸镜像，其加载地址由 QEMU 参数和平台约定决定。普通 `.bss` 是 NOBITS，通常不会直接占据 `objcopy -O binary` 的镜像内容；由初始化代码清零。本次栈放在 `.data`，因此实际占用镜像空间。

## 4. 练习 1：内核入口操作

### 4.1 `la sp, bootstacktop`

`la` 是汇编伪指令，作用是将符号 `bootstacktop` 的地址装入栈指针 `sp`，不是读取该地址里的内容。源码在 `.data` 中为 `bootstack` 预留 `KSTACKSIZE` 字节，再将末端标记为 `bootstacktop`。RISC-V 栈向低地址增长，因此以末端作为初始栈顶。

目的：为 C 函数的局部变量、保存寄存器和函数调用建立内核自己的栈，使内核不再依赖 OpenSBI 的栈。页对齐且长度为整页倍数，也满足本次 RISC-V ABI 的 16 字节栈对齐要求。

本次链接后的实际指令为：

```asm
0x80200000: auipc sp, 0x3
0x80200004: mv    sp, sp
```

第二条是 `addi sp, sp, 0` 的别名；低位偏移恰好为零。执行两条机器指令后，`sp` 从固件栈地址 `0x80045e30` 变为 `0x80203000`，与 `&bootstacktop` 一致。GDB 脚本对该地址和 16 字节对齐进行了断言。

### 4.2 `tail kern_init`

`tail` 也是伪指令，表示不为本次转移创建新的返回地址的尾跳转。它将控制流转交给 `kern_init`，用于从汇编入口进入 C 初始化函数。一般可展开为 `auipc` 和以 `x0` 为目的寄存器的 `jalr`；具体指令由距离、链接器松弛和压缩指令支持决定。

本次实际被松弛为地址 `0x80200008` 的两字节跳转，GDB 显示：

```asm
0x80200008: j 0x8020000a <kern_init>
```

进入 `kern_init` 前后，`ra` 均为 `0x80005b52`，说明尾跳转没有设置新的返回地址。该值由上一阶段留下，并不代表内核应该返回固件。`kern_init` 使用 `noreturn` 且末尾为无限循环，因此此处不需要返回 `kern_entry`。

## 5. 练习 2：GDB 验证启动流程

### 5.1 调试方法

交互式操作使用两个 WSL 终端，在 `code/` 中执行：

```bash
# 终端 1：启动暂停的 QEMU，等待 GDB
make debug

# 终端 2：连接并加载 ELF 符号
make gdb GDB=gdb-multiarch
```

`-S` 使 CPU 在第一条指令之前暂停；`-s` 开启 1234 端口。自动验证脚本将端口限制在本机 `127.0.0.1`，并依次运行同类 GDB 命令：

```gdb
info registers pc a0 a1 a2 sp
x/8i 0x1000
x/4gx 0x1018
x/4i 0x80200000
si 6
break *0x80200000
continue
info registers pc sp ra a0 a1 mstatus mepc satp
x/6i $pc
si 2
break kern_init
continue
break cprintf
continue
finish
```

自动重现完整实验：

```bash
cd code
python3 tools/verify.py
```

实际 GDB 退出状态为 0，完整日志见 [gdb.txt](logs/gdb.txt)。截图来自这些原始日志的浏览器渲染页面，内容可逐行与文本核对；它们不是交互终端窗口截图，未使用指导书的示例输出冒充实测数据。

### 5.2 加电最初的指令在哪里、完成什么功能

本次 CPU 最初执行的指令位于 QEMU `virt` 的 MROM，起点是 `0x1000`。它们是：

| 地址 | 实际指令 | 功能 |
|---|---|---|
| `0x1000` | `auipc t0,0x0` | 获取当前复位跳板的基准地址 `0x1000` |
| `0x1004` | `addi a2,t0,40` | 将 `a2` 设为 `0x1028`，指向固件动态信息结构 |
| `0x1008` | `csrr a0,mhartid` | 读取 hart 编号，本次为 0 |
| `0x100c` | `ld a1,32(t0)` | 从 `0x1020` 读取设备树指针，本次为 `0x87e00000` |
| `0x1010` | `ld t0,24(t0)` | 从 `0x1018` 读取固件入口 `0x80000000` |
| `0x1014` | `jr t0` | 跳入 OpenSBI 主体 |

`0x1018` 后含指针和固件参数数据，不能把连续反汇编显示的所有内容都当成将要执行的指令。`si 6` 之后，实际 `pc = 0x80000000`、`a0 = 0`、`a1 = 0x87e00000`、`a2 = 0x1028`。这些复位指令主要准备固件启动参数并移交控制权，而不是完成整个操作系统初始化。`0x1000` 是本次模拟平台的选择，RISC-V ISA 不要求所有芯片采用该复位地址。

![复位指令和 OpenSBI 入口的实测日志页面截图](images/reset.png)

### 5.3 从 OpenSBI 到内核第一条指令

在 `0x80200000` 设置断点并继续，GDB 停在 `kern_entry` 的第一条指令，源码定位为 `entry.S` 第 7 行：

```text
pc   = 0x80200000
sp   = 0x80045e30   （尚未初始化内核栈）
ra   = 0x80005b52
mepc = 0x80200000
satp = 0
```

OpenSBI 的串口日志给出 `Domain0 Next Address = 0x80200000` 和 `Domain0 Next Mode = S-mode`；GDB 观察到 `satp = 0`，表示此时未启用分页地址转换。执行入口的两条指令后，栈正确切换，再进入 `kern_init`。此处将大量固件内部指令交给 `continue` 执行，配合阶段断点验证控制流，不声称逐条单步了整套 OpenSBI。

### 5.4 为什么写监视点没有捕捉加载瞬间

练习提示建议 `watch *0x80200000`。本次在复位暂停时，该地址已经能反汇编为 `kern_entry`；自动脚本还逐字节比较了这里前 16 字节与 `ucore.img` 的前 16 字节，确认镜像在 CPU 执行前已加载。

写监视点观察的是建立监视点之后的目标执行写入，不能追溯 QEMU 在启动准备阶段的宿主侧预加载。因此本次建立后删除了该监视点，用入口断点验证控制权移交，没有把“没有触发”解释为“镜像没有加载”。指导书描述的加载职责与具体运行方式应结合 QEMU 命令实际区分。

### 5.5 C 初始化、输出与死循环

进入 `kern_init` 时，`edata = end = 0x80203008`，因此本次 `memset` 长度为 0。源码具备 BSS 清零流程，但本次不能声称验证了非空 BSS 的逐字节清零。

在 `cprintf` 断下时，GDB 读取 `a0` 指向格式字符串 `%s\n\n`，`a1` 指向 `(THU.CST) os is loading ...\n`。执行 `finish` 返回 `kern_init` 后，打印函数返回计数为 30。串口输出与预期一致。

最后 PC 位于 `0x8020003a`，反汇编为跳转到自身。单步三次后 PC 仍相同，确认进入了设计中的无限循环。自动脚本在验证完成后主动结束 QEMU；手动运行也可用 `Ctrl+A` 后按 `X` 退出，不能因为内核不主动退出而判为启动失败。

![内核入口、栈和输出后循环的实测日志页面截图](images/kernel.png)

## 6. 输出模块与实际兼容性修改

### 6.1 从格式字符串到串口

输出调用链为：

```text
kern_init
  → cprintf → vcprintf → vprintfmt
  → cputch → cons_putc → sbi_console_putchar
  → sbi_call：a7 = 1，a0 = 字符，执行 ecall
  → OpenSBI 字符输出服务
  → QEMU 模拟串口 → 宿主终端/日志
```

`cprintf` 使用 `va_start`、`va_end` 管理可变参数，`vcprintf` 维护字符计数；`vprintfmt` 解析 `%s` 等格式，并通过回调输出。这样格式化逻辑不需要知道底层设备细节。`cons_putc` 将设备接口与格式化接口分开，SBI 再将 S 模式内核和 M 模式硬件服务分开。

源码采用旧版 SBI 字符输出接口。当前 OpenSBI 的扩展列表包含 `legacy`，故本次仍能使用；不能把这次成功理解为所有未来固件都保证支持相同接口。输入和定时器并非本次测试范围。

![OpenSBI 和内核输出的实测日志页面截图](images/qemu.png)

### 6.2 为什么修改 Makefile

原始代码编译成功，但使用以下旧启动参数：

```text
-device loader,file=bin/ucore.img,addr=0x80200000
```

原始运行日志显示 OpenSBI v1.8 的 `Domain0 Next Address` 为 `0x0000000000000000`，没有打印内核消息。该 loader 参数把字节放入内存，但在本次 QEMU 默认动态固件组合下没有向固件正确传递下一阶段地址。

将 `qemu` 和 `debug` 目标改成：

```text
-machine virt -nographic -bios default -kernel bin/ucore.img
```

该方式使 QEMU 为当前 `virt` 平台设置内核加载和固件下一阶段信息。实测下一阶段地址变为 `0x80200000`，内核正常打印。修复前后输出分别保存为 [qemu-original.txt](logs/qemu-original.txt) 与 [qemu-debug.txt](logs/qemu-debug.txt)。

另将 GDB 变量设为可覆盖的 `GDB ?= $(GCCPREFIX)gdb`，使 `make gdb GDB=gdb-multiarch` 生效，保留对原课程工具链的默认兼容。没有修改 `kern_init` 的打印字符串和死循环，也没有修改入口汇编或链接脚本的地址。

## 7. 重要知识点与 OS 原理的对应关系

| 实验知识点 | OS 原理对应点 | 含义、关系及本实验的边界 |
|---|---|---|
| 复位跳板、固件、内核入口 | 系统启动与引导 | 用分阶段控制权移交建立运行环境；本次采用模拟器预加载，区别于实际从磁盘读取内核的引导链 |
| 交叉编译与 ELF/裸镜像 | 程序构建、装载与运行 | 宿主运行编译器，目标执行 RISC-V 指令；ELF 描述布局，裸镜像依赖外部地址约定，没有实现通用 ELF 装载器 |
| 链接脚本与固定基址 | 地址空间和内存布局 | 段和符号有确定地址，入口必须与加载位置一致；本次 `satp=0`，没有建立分页虚拟地址空间 |
| 启动栈、栈指针与 ABI | 执行上下文、函数调用 | 栈支持保存寄存器和局部状态；这里只建立单个内核栈，没有进程栈、线程切换或上下文调度 |
| `edata`、`end` 和 BSS | 程序初始存储状态 | 静态零初始化通常由加载/初始化环节保证；本次 BSS 为空，说明理解源码职责与实际测试范围须分开 |
| SBI 与 `ecall` | 特权级、异常、服务接口 | 较低特权级向固件请求服务；本次是内核向固件调用，区别于用户程序向 OS 发起系统调用 |
| 格式化输出的分层封装 | 设备抽象与模块化 | 上层格式化、中层控制台、下层固件各有职责；尚无完整驱动框架或中断驱动 I/O |
| 断点、单步和寄存器检查 | 可观测性与故障定位 | 直接验证启动阶段状态，补充纯源码推理；断点能证明到达阶段，但不等于逐条验证全部固件内部实现 |

OS 原理中重要、但本次未实现的内容包括：进程/线程管理与调度，抢占与上下文切换，同步互斥和死锁，物理页分配与回收，页表/TLB/虚拟内存，缺页和页面置换，用户态隔离与系统调用，文件系统和持久存储，网络协议栈，以及完整中断异常处理。Lab1 只为后续这些功能建立可启动、可输出、可调试的基础。

## 8. 结果、局限与提交核对

本机完成了干净重编译、ELF 入口核查、GDB 复位地址/固件地址/内核地址断言、栈地址和对齐断言、尾跳转 `ra` 检查、镜像预加载比较、串口输出验证和最终死循环验证。通过结果见 [verification.txt](logs/verification.txt)。

本次验证限定于上述工具版本、单 hart 的 QEMU `virt` 默认环境；没有测试真实硬件、其他固件版本、输入服务、多核启动或非空 BSS。报告中的寄存器值和链接地址（除既定入口外）应以重新构建后的日志为准，不能在更换工具链后直接照抄。

小组提交前需补齐三位成员信息、真实分工及课程平台要求的仓库链接；若任课教师另要求交互终端窗口截图，应补充该类型截图。仓库不包含学生密码、令牌或虚构测试结论。

## 9. 参考资料与原始记录

- [Lab1 指导书](http://8.135.34.58/lab2026/_book/lab1/lab1.html)
- [练习要求](http://8.135.34.58/lab2026/_book/lab1/lab1_2_1_exercise.html)
- [报告要求](http://8.135.34.58/lab2026/_book/lab1/lab1_5_requirement.html)
- [环境配置](http://8.135.34.58/lab2026/_book/lab0/3_startdash.html)
- [GDB 使用说明](http://8.135.34.58/lab2026/_book/lab1/lab1_4_gdb.html)
- [AI 提示词结构](http://8.135.34.58/lab2026/_book/lab0.5/3_prompt_structure.html)
- 本目录 `reference/`：2026-10-06 读取的课程正文快照，便于核对当时要求。
- [实验记录](record.md)、[提示词记录](prompt.md)、`logs/` 原始日志及 `images/` 日志页面截图。
