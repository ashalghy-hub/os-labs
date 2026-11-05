# 操作系统实验报告

## 实验基本信息

| 项目 | 内容 |
|------|------|
| **实验名称** | Lab 3: Trap机制与中断异常处理 |
| **小组成员** | 2412303-袁煜杰、2413625-张龙飞、2413357-王逸凌 |
| **完成日期** | 2026-11-03 |

### 小组分工

| 成员 | 负责的练习/模块 |
|------|----------------|
| 2412303-袁煜杰 | 功能模块二：中断与异常处理（interrupt_handler、exception_handler） |
| 2413625-张龙飞 | 功能模块一：Trap上下文恢复与Trap入口（RESTORE_ALL、__alltraps） |
| 2413357-王逸凌 | 报告整理、总结与润色 |

---

## 一、实验目的

本实验的主要目的是：

1. 理解 RISC-V 特权级架构中 Trap（中断与异常）的硬件机制，包括 sstatus、sepc、scause、stvec、sscratch 等控制状态寄存器的作用，以及 sret 返回指令的语义。
2. 掌握 Trap 上下文保存与恢复的完整流程：SAVE_ALL 将通用寄存器和 CSR 保存到内核栈上的 Trap frame，RESTORE_ALL 将处理后的上下文恢复到寄存器并通过 sret 返回被打断的执行流。
3. 理解 Trap frame（中断帧）的数据结构设计，包括 36 个槽位的布局（32 个通用寄存器 + status、epc、badvaddr、cause 四个 CSR），以及 sp 寄存器恢复时需要特殊处理的原因。
4. 实现统一的中断和异常处理函数，掌握中断原因识别、时钟事件持续触发、异常 epc 推进（区分 16/32 位指令）以及未知中断/异常的兜底诊断。
5. 通过自动化评分测试验证“Trap 进入 -> 上下文保存 -> C 语言处理 -> 上下文恢复 -> Trap 返回”的完整闭环，并学习使用结构化提示词（PROMPT、RELY、GUARANTEE、SPECIFICATION）辅助开发、结合实际代码与运行结果检验生成内容。

---

## 二、实验环境

小组使用的 AI 工具及对应运行环境如下：

| 成员 | AI 编程工具 | 底层模型 | 备注 |
|------|------------|---------|------|
| 2412303-袁煜杰 | TODO | TODO | 无 |
| 2413625-张龙飞 | TODO | TODO | 无 |
| 2413357-王逸凌 | 未使用 | 无 | 无 |

**说明：**

- **AI 编程工具**：指具体使用的终端工具、编辑器插件、桌面应用或浏览器界面。
- **底层模型**：指该工具使用的大语言模型及版本；未记录的版本由对应成员确认后填写。

**测试环境：** WSL Ubuntu、riscv64-unknown-elf-gcc 14.2.0、QEMU 10.2.1，RISC-V virt 单 hart/Linux 服务器（Fedora、QEMU 10.1.5、riscv64 交叉 GCC 15.2.1、OpenSBI v1.5.1）。

---

## 三、实验整体逻辑分析

### 2.1 本章节的逻辑主线

Lab3 围绕 RISC-V 的 Trap 机制展开，解决“硬件如何将控制权交给内核、内核如何处理并安全返回”的问题。当 CPU 在 S 模式下遇到中断或异常时，硬件自动完成特权级切换并跳转到 stvec 指向的统一入口 `__alltraps`。SAVE_ALL 将全部通用寄存器和 sstatus、sepc、sbadaddr、scause 保存到内核栈上的 Trap frame，随后调用 C 语言处理函数 `trap()`。处理函数通过 `trap_dispatch()` 区分中断和异常，分别调用 `interrupt_handler()` 和 `exception_handler()`。处理完成后经 `__trapret` 执行 RESTORE_ALL 恢复上下文，最后通过 sret 返回被打断的执行流。

整个流程形成“Trap 进入 → 上下文保存 → C 语言处理 → 上下文恢复 → Trap 返回”的完整闭环。模块一负责上下文保存/恢复与 Trap 入口的汇编框架，模块二负责中断原因识别、时钟事件驱动和异常 epc 推进等 C 语言处理逻辑。

### 2.2 功能的逐步实现

1. 首先理解 Trap frame 的数据结构设计：`struct trapframe` 包含 `struct pushregs gpr`（32 个通用寄存器）和 status、epc、badvaddr、cause 四个字段，共 36 个 8 字节槽位（288 字节）。SAVE_ALL 已按此布局保存，RESTORE_ALL 需逐项对应恢复。
2. 完成 RESTORE_ALL 宏：从 sp 指向的 Trap frame 恢复 sstatus 和 sepc（使用 t0 作临时寄存器），再恢复 x1、x3–x31（跳过 x0），最后恢复 x2（sp）。sp 必须最后恢复，因为它是读取 Trap frame 的地址基准。
3. 完成 `__alltraps` 入口：在 SAVE_ALL 之后，将当前 sp（Trap frame 首地址）通过 `mv a0, sp` 传给 `trap()`，`jal trap` 调用 C 处理函数，返回后落入 `__trapret`。
4. 实现 `interrupt_handler()`：清除 cause 最高位后按 IRQ 编号分类。IRQ_S_TIMER 每次先设置下一次时钟事件、递增 ticks，每 TICK_NUM（100）次打印统计，累计输出达到阈值后关机。未知中断输出原因并调用 `print_trapframe()`。
5. 实现 `exception_handler()`：对非法指令和断点输出诊断信息，读取 epc 处的指令低半字判断 16/32 位长度，分别推进 epc 2/4 字节避免重复异常。其他异常调用 `print_trapframe()` 兜底。
6. 通过注入测试和 `make grade` 验证三个测试用例：上下文保存/恢复与断点返回、非法指令 epc 推进与返回、持续时钟中断与反复 Trap 返回，总分 100/100。

---

## 四、实验内容与实现

### 功能模块：模块一——Trap上下文恢复与Trap入口功能

**负责人：** 2413625-张龙飞

#### 模块功能描述

**需要实现/修改的函数：**

```asm
# trapentry.S：RESTORE_ALL 汇编宏
.macro RESTORE_ALL
    # 从当前 sp 指向的 Trap frame 恢复处理器上下文
.endm

# trapentry.S：__alltraps 入口
__alltraps:
    SAVE_ALL
    # 将 Trap frame 首地址传给 trap()，调用后进入 __trapret
```

**功能说明：**

在 `code/kern/trap/trapentry.S` 中补全两处标有 `lab3 function1` 标记的位置（实现后按要求填写学号 2413625）。RESTORE_ALL 负责从 Trap frame 恢复全部处理器上下文，`__alltraps` 负责在 SAVE_ALL 之后建立与 `trap()` 函数的调用关系。保留 SAVE_ALL、`__trapret`、末尾的 sret 及其他无关代码不变；不得修改 `struct trapframe`、`trap()` 的函数签名和 tools 中的测试、注入与评分逻辑。

**Trap frame 与寄存器的对应关系：**

`struct trapframe` 在栈上占据 36 个 8 字节槽位（RV64 下 REGBYTES=8，共 288 字节）：

| 槽位 | 对应寄存器/字段 | 说明 |
|------|----------------|------|
| 0 | x0 (zero) | 硬连线零，恢复时不需要 |
| 1 | x1 (ra) | 返回地址 |
| 2 | x2 (sp) | 栈指针，**需特殊处理** |
| 3–31 | x3–x31 | 其余通用寄存器 |
| 32 | sstatus | 状态寄存器 |
| 33 | sepc | 异常程序计数器 |
| 34 | sbadaddr | 诊断字段，不写回 |
| 35 | scause | 诊断字段，不写回 |

**sp 为何需要特殊处理：**

SAVE_ALL 首先执行 `csrw sscratch, sp` 保存原 sp，然后 `addi sp, sp, -36*REGBYTES` 在栈上分配 Trap frame 空间。保存 x2(sp) 时用 `csrrw s0, sscratch, x0` 将原 sp 从 sscratch 读入 s0 再存入槽位 2。因此，Trap frame 中的 sp 保存的是**被中断时的原始 sp**，而非当前指向 Trap frame 的 sp。恢复时，RESTORE_ALL 以 sp 为基址读取 Trap frame 各槽位，如果提前恢复 x2(sp)，后续所有 LOAD 都会以错误的基址寻址，因此必须最后恢复 sp。

**`__alltraps` 的调用约定：**

SAVE_ALL 后，当前 sp 指向 Trap frame 首地址。`mv a0, sp` 将其作为第一个参数传给 `trap(struct trapframe *tf)`。调用前 sp 需 16 字节对齐：SAVE_ALL 分配 288 字节（36×8），调用前 sp 已按 RISC-V 调用约定 16 字节对齐，288 = 18×16，因此减去 288 后仍保持 16 字节对齐。`jal trap` 调用 C 函数，返回后 sp 与调用前相同（仍指向 Trap frame），随后落入 `__trapret` 执行 RESTORE_ALL 和 sret。调用可能覆盖 ra、a0 等调用者保存寄存器，被打断时的原值一律以 Trap frame 为准。

#### 实现迭代过程

完整提示词见 [prompt_1.md](prompt_1.md)，采用 PROMPT、RELY、GUARANTEE、SPECIFICATION 四部分结构，本模块共 1 轮实现。

---

##### 第一次迭代：完成 RESTORE_ALL 与 __alltraps

**遇到的问题：**

- RESTORE_ALL 必须与已提供的 SAVE_ALL 保持逐项对应，不能自行假设 Trap frame 布局；其中 x2(sp) 的保存路径与其他通用寄存器不同，恢复顺序若照搬其他寄存器会破坏取数基址。
- 模块开发时功能模块二的 `interrupt_handler()`、`exception_handler()` 尚未实现（提示词明确不得为测试通过而代为实现），完整闭环无法立即运行验证。

**问题解决策略：**

- 在提示词的 [RELY]/[SPECIFICATION] 中明确 36 槽位布局、sp 经 sscratch 中转的保存关系和“sp 最后恢复、t0 可先临时覆盖”的约束，让 AI 按已有 SAVE_ALL 生成配对的恢复序列。
- 先以编译和反汇编核对实际指令序列（加载槽位偏移、a0 传参、jal trap 的调用边界），再在两模块合并后用注入的上下文测试验证运行行为。

**最终结果：**

RESTORE_ALL 的恢复顺序为：先用 t0 从槽位 32、33 加载 sstatus 和 sepc（t0 的原值保存在槽位 5，后续会恢复，临时覆盖无影响）；再按槽位 1、3、4、…、31 恢复 x1、x3–x31；最后执行 `LOAD x2, 2*REGBYTES(sp)` 恢复原始 sp，此时 Trap frame 不再占用被打断程序的栈空间。badvaddr 与 cause 是诊断字段，不写回 CSR。`__alltraps` 以 `mv a0, sp` 传参、`jal trap` 调用，返回后落入 `__trapret`。编译与反汇编核对通过；两模块合并后，注入 GRADE_LAB3_CONTEXT 测试在 t0–t6、s0–s11、a1–a7 中填入已知值后执行 ebreak，Trap 处理返回后逐个检查寄存器保持原值，全部通过（详见“五、测试与验证”）。

**关键改进点总结：**

1. **[PROMPT]：** 明确只补全 trapentry.S 中两处 `lab3 function1` 标记位置，保留 SAVE_ALL、`__trapret`、sret 与 Trap frame 布局，不得修改 struct trapframe、trap() 签名、模块二函数和评分逻辑。
2. **[RELY]：** 以 SAVE_ALL 的实际保存关系和 struct trapframe 的 36 槽位布局为前提，特别说明 x2(sp) 经 sscratch 中转保存、恢复时最后加载，避免生成“按统一顺序恢复全部寄存器”的错误序列。
3. **[GUARANTEE]：** 要求 RESTORE_ALL 与已有 `__trapret`、sret 正确衔接，`__alltraps` 按 RISC-V 调用约定把 Trap frame 首地址经 a0 传给 trap()，且调用前后 sp 都指向同一 Trap frame。
4. **[SPECIFICATION]：** 用前置条件与达成效果描述恢复行为：恢复槽位与保存槽位逐项对应，处理函数对 tf 的合法修改以修改后内容为准；并注明 sret 执行后 sstatus 会按特权规范更新 SIE、SPIE、SPP，不承诺与保存值逐位相同。

---

### 功能模块：模块二——中断与异常处理功能

**负责人：** 2412303-袁煜杰

#### 模块功能描述

**需要实现/修改的函数：**

```c
// trap.c：中断处理
void interrupt_handler(struct trapframe *tf);
// trap.c：异常处理
void exception_handler(struct trapframe *tf);
```

**功能说明：**

在 `code/kern/trap/trap.c` 中实现两个处理函数。`trap_dispatch()` 已通过 cause 最高位区分中断（最高位为 1）和异常（最高位为 0），分别调用两个函数。保留模块一的 SAVE_ALL、RESTORE_ALL、Trap frame 布局以及 `trap()`、`print_trapframe()` 等已有接口不变，函数签名不得修改。

**中断处理（interrupt_handler）：**

- 去除 cause 最高位后按 IRQ 编号分类（IRQ_U_SOFT 到 IRQ_M_EXT）。普通中断输出类型提示，如 "Supervisor software interrupt"。
- **IRQ_S_TIMER**：每次先调用 `clock_set_next_event()` 设置下一次定时事件（SBI 一次只设置一个事件，不重设则只能收到一次时钟中断），再递增 ticks——ticks 每收到一次时钟中断必须增加一次。当 ticks 达到 TICK_NUM（100）的整数倍时输出规定格式的统计信息 "100 ticks"。实现另用计数器统计输出次数，累计输出达到 SHUTDOWN_AFTER 后调用 `sbi_shutdown()` 关机。指导书与框架均未定义 SHUTDOWN_AFTER 的具体数值，本实现默认 10，可通过 `-DSHUTDOWN_AFTER=...` 覆盖；这是实现的默认配置，不作为指导书规定的数值。
- 未知中断输出原因编号并调用 `print_trapframe(tf)` 输出完整 Trap frame 辅助调试。

**异常处理（exception_handler）：**

- **非法指令**（CAUSE_ILLEGAL_INSTRUCTION）与**断点**（CAUSE_BREAKPOINT）：按规定格式输出 "Illegal instruction at 0x..." / "Breakpoint at 0x..." 与 tf->epc 地址。
- 根据 epc 处指令的低位编码判断指令长度并正确推进 tf->epc，使 Trap 返回后不会重复执行已触发异常的指令：先读取半字（2 字节），避免 16 位指令位于页尾时读取 4 字节越界；低 2 位不全为 1 则是 16 位压缩指令（RVC），epc += 2；低 5 位不全为 1 则是 32 位指令，epc += 4。不能假定所有异常使用相同的 epc 偏移量。
- 对本框架不支持的更长指令编码不猜测推进量，改用 `print_trapframe(tf)` 输出现场；其他未要求具体处理的异常同样调用 `print_trapframe(tf)` 兜底。

#### 实现迭代过程

完整提示词见 [prompt_2.md](prompt_2.md)，采用同样的四部分结构，本模块按 2 轮展开。

---

##### 第一次迭代：补齐两个处理函数

**遇到的问题：**

- 当前汇编器不识别旧 CSR 名 `sbadaddr`，SAVE_ALL 中的 `csrr` 无法汇编通过。
- 原始入口在开启分页后低地址取指缺乏映射，运行时在到达 C 入口前就触发执行页错误，测不到处理函数。
- 开发环境沿用 Lab1 记录的旧 loader 启动参数时内核无法正常进入（固件下一级地址为 0），处理函数的运行验证受阻。

**问题解决策略：**

- 在 `code/libs/riscv.h` 中将旧名 `sbadaddr` 映射为同一 CSR 的现名 `stval`，不改变 CSR 编号和模块一的保存布局。
- 在 `code/kern/init/entry.S` 根表第 2 项增加低地址恒等映射（0x80000000 → 0x80000000，1G 大页），保留第 511 项高地址映射和组员的栈初始化。
- 将 Makefile 的 qemu/debug/test 目标和 tools/grade.sh 的启动参数统一改为 `-kernel`，把入口交给 OpenSBI；测试代码、匹配条件、分值与时限不变。

**最终结果：**

两个处理函数实现完成，兼容修正纳入工程，改动范围如下：

| 文件 | 改动目的 |
| --- | --- |
| code/kern/trap/trap.c | 新增两个处理函数、SBI 头文件依赖和可覆盖的关机阈值 |
| code/kern/init/entry.S | 根表第 2 项增加低地址恒等映射，保留第 511 项高地址映射 |
| code/libs/riscv.h | 旧 CSR 名 sbadaddr 映射为现名 stval，不改变编号与布局 |
| code/Makefile | qemu/debug/test 使用 -kernel 将入口交给 OpenSBI |
| code/tools/grade.sh | 仅将旧 loader 启动参数换成 -kernel，评分逻辑不变 |

---

##### 第二次迭代：评分验证与边界测试

**遇到的问题：**

- 编译通过不能证明 epc 推进正确：若 16/32 位长度判断错误，Trap 返回后会重复执行同一异常指令形成异常循环。
- SHUTDOWN_AFTER 的语义（统计统计信息的输出次数，而不是单次中断次数）需要实测确认，不能只看第一次打印。

**问题解决策略：**

- 从实际提交候选复制到全新目录执行 `make grade`，覆盖断点返回、32 位非法指令、持续时钟三个评分用例。
- 在可清理的测试副本中补充 16/32 位 × 非法指令/断点四种组合的边界用例，并以 `-DSHUTDOWN_AFTER=2` 构建检查关机阈值；测试钩子只在副本中使用，不提交、不改变评分用例。

**最终结果：**

评分用例与边界测试全部通过，SHUTDOWN_AFTER=2 构建恰好输出两次 "100 ticks" 后正常关机（详见“五、测试与验证”）。

**关键改进点总结：**

1. **[PROMPT]：** 明确在模块一基础上只实现两个处理函数，保留 SAVE_ALL、RESTORE_ALL、Trap frame 布局、trap() 与 trap_dispatch()，不修改测试条件、预期输出匹配和评分分值；环境问题如实说明并限定修正范围。
2. **[RELY]：** 以 trap_dispatch() 的 cause 最高位分流、clock_set_next_event() 的单次事件语义、ticks 与 TICK_NUM 的既有定义为前提；宏定义以工程已有为准，SHUTDOWN_AFTER 未定义时记录默认值而不冒充指导书规定。
3. **[GUARANTEE]：** 锁定 `interrupt_handler()`、`exception_handler()` 签名和 `lab3 function2` 标记（学号 2412303），正常处理后与统一的上下文恢复、sret 返回路径衔接。
4. **[SPECIFICATION]：** 把“持续时钟中断”“统计输出与关机”“epc 按指令长度推进”“未知类型兜底”写成可检查的行为条件，并要求先读半字、不猜测更长指令编码；验证区分正常运行、预期输出和 timeout，不以单次打印代替持续正确。

---

### Challenge：无

本次 Lab3 未设置独立 Challenge 任务。

---

## 五、测试与验证

### 测试环境与方法

测试分为两次：2026 年 11 月 3 日在 WSL Ubuntu（riscv64-unknown-elf-gcc 14.2.0、QEMU 10.2.1）完成初测；2026 年 11 月 5 日在 Linux 服务器（Fedora、QEMU 10.1.5、riscv64 交叉 GCC 15.2.1）复核，两次结果一致。以下输出为复核实测记录。

在 code 目录执行：

```bash
make grade
```

`make grade` 会自动清理旧构建、复制到临时评分目录（/tmp/lab3_grade）、注入测试（tools/inject.py）、编译并调用 tools/grade.sh 启动 QEMU 运行三个测试用例，无需手动复制源码或单独运行 QEMU。inject.py 只修改临时评分副本：把 tools/test_lab3.{c,h} 与 test_lab3_context.S 复制到 kern/test/，并在 kern_init() 中 idt_init()、clock_init()、intr_enable() 之后分别插入异常/上下文测试、ticks 初值检查和等待时钟的测试调用；学生的原始源码不被修改。grade.sh 对每个用例分别清理、构建（`DEFS+=-DGRADE_LAB3_CONTEXT/-DGRADE_LAB3_ILLEGAL/-DGRADE_LAB3_TIMER`）、限时启动 QEMU（8s/8s/30s），并按规定的输出标记判定得分。

### 评分测试用例说明

| 测试 | 验证内容 | 分值 |
|------|---------|------|
| Test 1: Trap entry and breakpoint return | 汇编入口、寄存器恢复、断点 epc 推进 | 35 |
| Test 2: Illegal instruction return | 32 位非法指令 epc 推进、软件中断提示、未知中断/异常兜底 | 25 |
| Test 3: Sustained supervisor timer | 持续时钟中断（≥200 次）、每次重设事件、反复 Trap 返回 | 40 |

**Test 1**（test_lab3_context.S）在 t0–t6、s0–s11、a1–a7 中填入已知值后执行 ebreak 触发断点异常（工具链将其汇编为 16 位压缩指令 c.ebreak）。trap() → exception_handler() 将 epc 推进 2 字节，返回后逐个检查寄存器值是否保持不变，验证 SAVE_ALL 与 RESTORE_ALL 的正确配对；输出需包含 "Breakpoint at"。

**Test 2** 执行自定义非法指令 `.word 0x0000007b`（32 位），验证 epc 推进 4 字节后程序继续执行。随后由测试直接构造软件中断（IRQ_S_SOFT）、未知中断（cause 15）和未知异常（cause 20），验证类型提示与 `print_trapframe()` 兜底输出；输出需包含 "Illegal instruction at"、"Supervisor software interrupt"、"Unknown interrupt: cause 15" 和 "cause    0x00000014"。

**Test 3** 使能时钟中断后自旋等待 ticks 达到 200，验证每次 IRQ_S_TIMER 都正确调用 `clock_set_next_event()` 重设事件、递增 ticks，且多次 Trap 返回后上下文不退化。timebase 为 100000 个时钟周期（QEMU virt 平台 10MHz），中断间隔约 10ms，200 次约 2 秒；输出需包含 "100 ticks" 与 "ticks=200"，不以第一次打印成功代替持续正确。

### 实际测试结果

提交候选在全新构建目录中实测退出码 0，`make grade` 输出：

```text
lab3 injection complete
Building trap entry, register restore, and breakpoint EPC...
Running trap entry, register restore, and breakpoint EPC...
  - trap entry, register restore, and breakpoint EPC: PASS (35/35)
Building illegal instruction EPC advance and return...
Running illegal instruction EPC advance and return...
  - illegal instruction EPC advance and return: PASS (25/25)
Building re-armed supervisor timer and repeated trap return...
Running re-armed supervisor timer and repeated trap return...
  - re-armed supervisor timer and repeated trap return: PASS (40/40)
Total Score: 100/100
```

三项测试全部通过，总分 100/100。对应运行日志的关键片段：

```text
Breakpoint at 0xffffffffc0201b84
[Test 1] Trap entry and breakpoint return: PASS (35/35)
```

```text
Illegal instruction at 0xffffffffc0201b36
Supervisor software interrupt
Unknown interrupt: cause 15
trapframe at 0xffffffffc0205eb0
  ...
  cause    0x0000000f
trapframe at 0xffffffffc0205eb0
  ...
  cause    0x00000014
[Test 2] Illegal instruction return: PASS (25/25)
```

- **上下文与断点测试**：验证汇编入口、寄存器恢复和异常返回位置，说明模块二与模块一能够正确衔接。
- **非法指令与兜底测试**：验证 32 位非法指令 epc 推进、软件中断提示及未知中断/异常现场输出。
- **持续时钟测试**：持续到至少 200 次时钟中断，验证每次重设事件及反复 Trap 返回的正确性。

### 边界与阈值补充验证

另在可清理的测试副本中分别触发 16 位非法指令（`.short 0x0000`）、32 位非法指令（`.word 0x0000007b`）、16 位断点（c.ebreak）和 32 位断点（`.word 0x00100073`），四种组合在 Trap 返回后都能继续执行后续代码：

```text
MODULE2_BOUNDARY illegal16: PASS
MODULE2_BOUNDARY illegal32: PASS
MODULE2_BOUNDARY breakpoint16: PASS
MODULE2_BOUNDARY breakpoint32: PASS
MODULE2_BOUNDARY_ALL_PASS
```

以 `DEFS=-DSHUTDOWN_AFTER=2` 构建后，内核输出两次 "100 ticks" 后正常关机，QEMU 退出码 0，无 panic 和 timeout，验证阈值统计的是统计信息的输出次数而不是单次中断。额外测试仅在测试副本进行，不提交测试钩子，也不改变原评分用例。

---

## 六、实验总结与收获

### 对操作系统的理解

1. 本实验涉及的主要知识点及其与 OS 原理的关系：

| 实验知识点 | 对应 OS 原理 | 含义、关系和差异 |
|------------|-------------|------------------|
| Trap 机制 | 中断与异常处理 | 硬件自动完成特权级切换并跳转到统一入口；本次只处理 S 模式 Trap，未涉及 U→S 系统调用 |
| Trap frame 上下文保存/恢复 | 进程上下文切换 | SAVE_ALL/RESTORE_ALL 实现寄存器级上下文保存，是进程切换的基础；本次未实现多进程调度 |
| sret 返回指令 | 特权级与执行流恢复 | 按 sstatus/sepc 恢复执行状态并返回被打断位置；sret 会更新 SIE、SPIE、SPP 等字段 |
| stvec 统一向量入口 | 异常向量表 | 所有 Trap 共享一个入口点，通过 cause 区分类型；未实现独立中断向量表 |
| sscratch 中转寄存器 | 内核/用户栈切换 | 用于在 Trap 入口安全获取原 sp；本次全部在内核态，未实现用户态栈切换 |
| 中断驱动的时钟 | 时钟与定时器 | 通过 SBI 设置下一次事件，ticks 累积驱动周期性任务；未实现进程时间片调度 |
| 异常 epc 推进 | 指令解码与恢复 | 根据指令低 2 位判断 16/32 位长度，推进 epc 跳过出错指令；避免重复触发同一异常 |
| 打印诊断与兜底 | 系统调试与容错 | print_trapframe() 输出完整现场用于诊断；未知中断/异常的兜底处理保证系统不挂死 |

2. OS 原理中重要、但本实验尚未完整实现的内容包括：用户态与内核态的栈切换（sscratch 仅用于内核态保存 sp）、嵌套 Trap 处理、系统调用（U→S Trap）、进程调度与上下文切换、虚拟内存缺页异常处理、多核中断处理与同步等。当前工作主要完成了 S 模式下的 Trap 处理闭环，尚未建立完整的用户进程模型。

### AI 协作开发的经验

本次实验中，小组成员通过结构化提示词（PROMPT、RELY、GUARANTEE、SPECIFICATION）向 AI 明确任务范围、已有条件、交付要求和行为规格，有效减少了模块间接口约定不一致的问题。例如，模块一在 RELY 中明确了 Trap frame 的 36 槽位布局和 sp 的特殊处理方式，模块二在 SPECIFICATION 中明确了 16/32 位指令判断逻辑和 SHUTDOWN_AFTER 的语义，两个模块并行开发而未发生布局或签名冲突。

测试要求应与功能规格对应：上下文恢复要检查寄存器逐项配对和 sp 恢复顺序，异常处理要检查 epc 推进与后续执行，时钟中断要检查事件重设和持续返回，而不是只看编译通过或单次输出。把实现和验证分开组织（评分用例在提交候选上运行，边界用例在可清理副本中运行），有助于保证结论对应真实行为。

AI 生成的结果仍需结合代码阅读和实际运行验证。编译通过只能说明语法正确，不能代替功能验证；本次实验中，sbadaddr 兼容性问题和低地址映射缺失都是通过实际运行日志发现并修复的。各成员保留了所用提示词、实现迭代过程和运行日志，合并时核对 Trap frame 布局、函数签名和测试条件，保证实现与报告结论一致。

---
