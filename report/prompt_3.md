[PROMPT]
**任务**：修改文件 `code/kern/process/proc.c`、`code/kern/schedule/sched.c` 与 `code/kern/process/switch.S`，实现 Lab4 功能模块三“进程调度”，使内核具备空闲等待、FIFO/轮转调度选择、地址空间与当前进程切换，以及底层寄存器上下文切换的能力，完成从 `idleproc` 调度并运行 `initproc` 及其他内核线程的闭环。

**操作要求**：你必须在项目中修改实际文件，而不是仅展示代码片段。仅在三个目标文件中标有 `//LAB4 function3 YOUR CODE` 的区域补全实现，保留 `LAB4 function3` 标记并将 `YOUR CODE` 替换为学号 `2412303`。保留已有辅助函数、模块一（`pmm.c`）与模块二（`proc.c`）实现、首次运行恢复链路（`forkret` / `forkrets` / `__trapret` / `kernel_thread_entry`）及原有构建与评分脚本，不得修改无关文件或引入本工程不存在的接口。

**输出要求**：直接进行文件操作，严格依据下面 `[RELY]`、`[GUARANTEE]`、`[SPECIFICATION]` 部分以及工程真实代码完成实现，保持函数签名和代码风格与现有工程一致。

[RELY]
// 宏定义（libs/riscv.h, kern/process/proc.h, kern/sync/sync.h）
#define STORE sd                 // RV64; RV32 下为 sw
#define LOAD  ld                 // RV64; RV32 下为 lw
#define REGBYTES (1 << LOG_REGBYTES) // RV64 下为 8
#define SATP_MODE_SV39 8
#define RISCV_PGSHIFT 12
#define le2proc(le, member) to_struct((le), struct proc_struct, member)
#define local_intr_save(x)    do { x = __intr_save(); } while (0)
#define local_intr_restore(x) __intr_restore(x);

// 数据结构（kern/process/proc.h）
enum proc_state {
    PROC_UNINIT = 0,
    PROC_SLEEPING,
    PROC_RUNNABLE,
    PROC_ZOMBIE,
};

struct context {
    uintptr_t ra;
    uintptr_t sp;
    uintptr_t s0;
    uintptr_t s1;
    uintptr_t s2;
    uintptr_t s3;
    uintptr_t s4;
    uintptr_t s5;
    uintptr_t s6;
    uintptr_t s7;
    uintptr_t s8;
    uintptr_t s9;
    uintptr_t s10;
    uintptr_t s11;
};

struct proc_struct {
    enum proc_state state;
    int pid;
    int runs;
    uintptr_t kstack;
    volatile bool need_resched;
    struct proc_struct *parent;
    struct mm_struct *mm;
    struct context context;
    struct trapframe *tf;
    uintptr_t pgdir;              // 页目录物理基址（内核线程为 boot_pgdir_pa）
    uint32_t flags;
    char name[PROC_NAME_LEN + 1];
    list_entry_t list_link;
    list_entry_t hash_link;
};

// 全局变量与可用函数（kern/process/proc.h, libs/list.h, kern/mm/pmm.h, libs/riscv.h）
extern list_entry_t proc_list;
extern struct proc_struct *idleproc, *initproc, *current;
extern uintptr_t boot_pgdir_pa;

static inline list_entry_t *list_next(list_entry_t *listelm);
static inline void flush_tlb(void);
write_csr(reg, val); // 参照 kern/mm/pmm.c 中 enable_paging() 的 Sv39 satp 写法

// 首次运行恢复链路（已由框架与模块二建立）
// switch_to 恢复 context(ra=forkret, sp=proc->tf)
//   -> forkret() -> forkrets(current->tf) -> __trapret -> sret -> kernel_thread_entry -> fn(arg)

// 注意：libs/riscv.h 中的 lsatp() 为 Sv32 遗留实现，无法构造 Sv39 的 satp，本模块禁止调用。

[GUARANTEE]
必须实现的主要接口（保持声明与签名不变）：
```c
// code/kern/process/proc.c
void cpu_idle(void);
void proc_run(struct proc_struct *proc);

// code/kern/schedule/sched.c
void schedule(void);

// code/kern/process/switch.S
void switch_to(struct context *from, struct context *to);
```

你可以根据需要添加：
- 必要的局部辅助逻辑与清晰注释（仅限模块三标记区域内）
- 不得更改任何公开函数签名、结构体定义或跨模块全局变量语义

[SPECIFICATION]
## cpu_idle
**Pre-Condition**:
- 内核初始化已完成，`proc_init()` 已建立 `idleproc` 与 `initproc`，当前执行线程为 `idleproc` 且中断已开启。

**Post-Condition**:
- 作为空闲线程的主循环永不返回；只要当前线程被标记为需要重新调度，就触发一次调度让出 CPU，并在之后再次切回空闲线程时继续循环等待。

**Requirements**:
- 需满足头文件中的 `__attribute__((noreturn))` 约定，持续检测当前线程的重新调度标志并在置位时发起调度，不应提前退出循环。

## schedule
**Pre-Condition**:
- 进程链表与 `idleproc`、`current` 均已由 `proc_init()` 初始化完成。
- `idleproc` 不挂接在全局进程链表中，所有通过创建流程登记的普通线程均挂接在进程链表中。

**Post-Condition**:
- 当前线程的重新调度标志被清除；系统按 FIFO/轮转策略选出下一个处于可运行状态的线程（若无则回退到 `idleproc`），递增选中线程的运行计数；若选中线程不同于当前线程，则完成切换使其在 CPU 上运行；返回时中断使能状态恢复到进入前的值。

  **Case 1**:
  - 当前线程是 `idleproc` 时，从全局进程链表的表头之后开始顺序查找，选中第一个处于可运行状态的线程作为切换目标。

  **Case 2**:
  - 当前线程不是 `idleproc` 时，从当前线程在进程链表中的后继节点开始循环扫描（扫描经过表头节点时跳过，不将其当作进程节点），选中遇到的第一个处于可运行状态的线程，实现轮转调度。

  **Case 3**:
  - 扫描完整个进程链表后仍未找到任何处于可运行状态的线程（包括链表为空或其余线程均不可运行且当前线程也不可运行），则回退选择 `idleproc` 作为目标线程。

  **Case 4**:
  - 最终选中的目标线程与当前线程相同时，仅更新其运行计数并直接结束本次调度，不发起进程切换；目标线程与当前线程不同时，调用切换接口将 CPU 交予目标线程。

**Requirements**:
- 整个调度选择与切换触发过程必须在关中断临界区内执行，并在退出时恢复进入前的中断状态，避免并发修改进程链表或运行状态。

## proc_run
**Pre-Condition**:
- 参数 `proc` 指向有效的已初始化进程控制块，其页目录基址与上下文（或首次运行的 `forkret` 上下文）已准备就绪。

**Post-Condition**:
- 当目标进程与当前进程不同时，系统当前进程指针更新为目标进程，处理器页表切换为目标进程的 Sv39 页表并刷新 TLB，CPU 执行现场通过上下文切换迁移至目标进程；当原进程后续再次被切换回来时，从切换调用点之后恢复执行并还原进入前的中断状态。

  **Case 1**:
  - 目标进程与当前进程相同时，不做任何状态修改与上下文切换，直接返回。

  **Case 2**:
  - 目标进程与当前进程不同且为首次运行的内核线程时，在关中断临界区内先更新当前进程指针，再将目标页目录物理基址按 Sv39 格式写入页表基址寄存器并刷新 TLB，随后执行底层上下文切换，使新线程经由预设的首次运行链路进入线程入口函数（由 `sret` 恢复目标线程预设的中断使能状态）。

  **Case 3**:
  - 目标进程与当前进程不同且为曾被切换出去的线程时，完成当前进程更新、页表切换与 TLB 刷新后，底层上下文切换将恢复该线程上次切出时的寄存器现场与栈帧，并由其自身执行临界区末尾的中断状态恢复逻辑继续运行。

**Requirements**:
- 必须在调用底层上下文切换之前更新当前进程指针，确保首次运行线程进入 `forkret` 时读到的是新线程自身的中断帧。
- 页表切换必须按 Sv39 格式设置 `satp` 并执行 TLB 刷新，禁止调用 Sv32 遗留接口 `lsatp()`。
- 切换关键区必须由支持嵌套的本地中断保存与恢复机制保护，确保单独调用或由调度器嵌套调用均不破坏中断状态。

## switch_to
**Pre-Condition**:
- 第一参数指向原线程上下文结构，第二参数指向目标线程上下文结构，两个指针均指向合法可访问的内核内存。

**Post-Condition**:
- 原线程的返回地址、栈指针与所有被调用者保存寄存器按结构体字段顺序完整保存到原上下文中；目标线程对应的所有寄存器从目标上下文完整恢复，随后跳转至恢复后的返回地址继续执行。

**Requirements**:
- 仅负责底层寄存器上下文的保存与恢复，不参与任何调度策略判断或进程状态修改。
- 读写偏移必须与 `struct context` 的字段排列（`ra`、`sp`、`s0` 至 `s11`）及字长步长 `REGBYTES` 严格一致，并满足指令地址对齐要求。
