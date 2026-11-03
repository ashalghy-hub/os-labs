# 功能模块二：中断与异常处理

负责人：2412303-袁煜杰。

## 任务与完成范围

依据[Lab3练习要求](http://oslab.mobisys.top/lab2026/_book/lab3/lab3_2_1_exercise.html)，在小组模块一提交 `2d1c913` 基础上完成 `interrupt_handler()` 与 `exception_handler()`。模块一的 `SAVE_ALL`、`RESTORE_ALL`、`__alltraps`、Trap frame布局以及 `trap()`、`trap_dispatch()`、打印辅助函数均保留。

## 提示词与规格整理

以下为按本次实际任务归纳的复现提示词，供后续理解与复现；不是先前对话的逐字记录。

```text
[PROMPT]
完成uCore Lab3功能模块二，在已有模块一基础上实现中断与异常处理。
先读取真实框架和练习要求，保留组员代码，不修改已有处理辅助函数和评分判定。
完成后实际构建、运行测试，如有环境问题，说明问题、修正范围和验证结果。

[RELY]
模块一已保存上下文并将struct trapframe *传给trap()。
trap_dispatch()通过cause最高位区分中断和异常，分别调用两个待实现函数。
复用trap.h、riscv.h、clock.h、sbi.h以及print_ticks()、print_trapframe()。
clock_set_next_event()设置下一次定时事件，ticks记录时钟中断次数，TICK_NUM为100。
已有环境和代码中的宏定义优先于假设；框架未给出SHUTDOWN_AFTER具体值时明确记录默认配置。

[GUARANTEE]
实现并保留以下签名：
    void interrupt_handler(struct trapframe *tf);
    void exception_handler(struct trapframe *tf);
正常处理后返回已有上下文恢复及sret路径。
保留lab3功能标记并填写负责成员学号，不修改SAVE_ALL、trapframe和模块一实现。
不更改测试条件、预期输出匹配或评分分值。

[SPECIFICATION]
interrupt_handler：去除cause中的中断标志后按原因分类；普通中断输出类型提示。
IRQ_S_TIMER每次先设置下一次事件，ticks增加一次，每100次打印100 ticks；
累计统计输出达到SHUTDOWN_AFTER时调用sbi_shutdown()。
未知中断输出原因并调用print_trapframe()。
exception_handler：非法指令和断点分别输出Illegal instruction at、Breakpoint at及地址；
根据指令低位编码区分16/32位长度，分别将epc推进2/4字节，避免重复异常。
先读取半字，不因16位指令可能位于页尾而无条件读取4字节。
不猜测本框架不支持的更长指令长度；其他异常使用print_trapframe()诊断。
实际验证上下文恢复、不同指令长度、兜底处理、连续时钟与关机阈值。
```

## 实现与指导书要求对应

| 要求 | 实现 |
| --- | --- |
| 中断原因识别 | 清除cause最高位后匹配已有IRQ宏，普通中断给出相应提示 |
| 持续时钟事件 | 每次IRQ_S_TIMER调用clock_set_next_event()，再递增ticks |
| 周期输出与关机 | 每TICK_NUM次打印统计，累计输出达到阈值后调用SBI关机 |
| 未知中断与异常 | 复用print_trapframe()，未知中断另外输出原因编号 |
| 非法指令与断点恢复 | 根据低位编码判定16/32位长度，推进tf->epc后返回 |
| 接口与模块一保护 | 两个函数签名不变，保留原Trap frame、汇编保存恢复与其他trap.c函数 |
| 负责人标记 | 保留lab3 function2，并填写2412303 |

指导书和当前框架均未定义 `SHUTDOWN_AFTER` 的具体数值。本实现默认10，含义为输出10次统计后关机，可通过 `-DSHUTDOWN_AFTER=...` 覆盖；这是本实现的默认配置，不作为指导书明确规定的数值。

## 实现与验证过程

第一轮补齐两个处理函数，仅改变trap.c。初次编译发现当前汇编器不识别旧CSR名sbadaddr；使用同一CSR的现名stval后可以编译，但原始入口没有开启分页后低地址取指所需的映射，运行尚未到C入口。先在独立副本中验证最小兼容修正，评分与边界测试通过。

提交前将兼容修正纳入工程，再从实际提交候选复制到全新目录运行评分，不再依赖验证专用补丁、宏参数或QEMU包装。具体改动为：

| 文件 | 改动目的 |
| --- | --- |
| code/kern/trap/trap.c | 新增两个处理函数、SBI头文件依赖和可覆盖关机阈值 |
| code/kern/init/entry.S | 根表第2项增加低地址恒等映射，保留第511项高地址映射和组员栈初始化 |
| code/libs/riscv.h | 仅在汇编预处理时将旧名sbadaddr映射为stval，不改变CSR编号或模块一保存布局 |
| code/Makefile | qemu/debug/test使用-kernel将入口交给OpenSBI |
| code/tools/grade.sh | 仅将旧loader启动参数换成-kernel；测试代码、匹配条件、分数和时限不变 |

## 实际测试结果

测试日期：2026-11-03。环境：WSL Ubuntu、riscv64-unknown-elf-gcc 14.2.0、QEMU 10.2.1，RISC-V virt单hart。

在code目录执行：

```bash
make grade
```

提交候选在全新构建目录中实测退出码0，输出：

```text
  - trap entry, register restore, and breakpoint EPC: PASS (35/35)
  - illegal instruction EPC advance and return: PASS (25/25)
  - re-armed supervisor timer and repeated trap return: PASS (40/40)
Total Score: 100/100
```

- 上下文与断点测试：验证汇编入口、寄存器恢复和异常返回位置，说明模块二与已有模块一能够衔接。
- 非法指令与兜底测试：验证32位非法指令恢复、软件中断提示及未知中断/异常现场输出。
- 持续时钟测试：持续到至少200次时钟中断，验证每次重设事件及反复Trap返回，不以第一次打印成功代替持续正确。

另在独立测试副本分别触发16位非法指令、32位非法指令、16位断点、32位断点，每次都能继续执行后续代码，输出：

```text
MODULE2_BOUNDARY illegal16: PASS
MODULE2_BOUNDARY illegal32: PASS
MODULE2_BOUNDARY breakpoint16: PASS
MODULE2_BOUNDARY breakpoint32: PASS
MODULE2_BOUNDARY_ALL_PASS
```

该副本以 `DEFS=-DSHUTDOWN_AFTER=2` 构建，之后只输出两次 `100 ticks` 并正常关机，QEMU退出码0，无panic和timeout，验证阈值统计的是输出次数而不是单次中断。额外测试接入只在测试副本进行，不提交测试钩子或改变原评分用例。

评分套件中的部分内核测试以超时结束，原脚本根据实际完成标记和规定输出判定，不能单凭timeout退出码推断功能正确。以上是实际运行记录，不是预期结果。完整团队实验报告与学习答辩理解进度另行整理。
