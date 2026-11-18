[PROMPT]
任务：实现Lab4功能模块二“进程创建及初始化功能”，补全alloc_proc、proc_init、kernel_thread、do_fork、copy_thread和copy_mm，使内核具备创建、登记内核线程并准备首次运行现场的能力。
目标位置：code/kern/process/proc.c中标有//LAB4 function2 YOUR CODE的位置，六个函数均在该区域内实现。
操作要求：必须在项目中修改实际文件，不能只输出代码片段。保留已有辅助函数和//LAB4 function3 YOUR CODE标记；只能修改功能模块二相关文件，其他无关框架与文件保持不变，只需要实现模块二，不能越过。
注释要求：保留LAB4 function2标记，将YOUR CODE替换为与工程已有代码一致的学号2413625；适当说明PCB初始化、首次运行链路、临界区与失败清理，风格与现有工程一致。
测试环境：在已有WSL环境中使用RISC-V工具链验证；本机项目路径为D:\work\os-labs，WSL挂载路径为/mnt/d/work/os-labs，编译目录为/mnt/d/work/os-labs/code。
输出要求：使用下面[RELY]、[GUARANTEE]、[SPECIFICATION]中的信息，以工程真实代码为准。完成后简要说明修改内容、idleproc的特殊性、trapframe与context的分工、失败清理路径、编译及验证结果，并给出手动验证方法。

[RELY]

- 先阅读proc.c中的get_pid、hash_proc、find_proc、setup_kstack、put_kstack、set_proc_name、forkret和init_main，确认签名、返回值与调用约定；同时阅读proc.h、trap.h、entry.S、trapentry.S及sched.c中的wakeup_proc。
- struct proc_struct包含state、pid、runs、kstack、need_resched、parent、mm、context、tf、pgdir、flags、name、list_link和hash_link。字段及类型以proc.h为准。
- 可以使用proc_list、hash_list、nr_process、current、idleproc、initproc和bootstack；hash_list与nr_process是proc.c内的静态对象。
- 已有常量包括PROC_UNINIT、PROC_RUNNABLE、MAX_PROCESS、MAX_PID、PROC_NAME_LEN、HASH_LIST_SIZE、KSTACKPAGE、KSTACKSIZE、CLONE_VM、E_NO_MEM和E_NO_FREE_PROC。
- kmalloc、kfree、memset、memcpy用于内存分配及初始化；内核栈使用setup_kstack和put_kstack配对管理。
- get_pid分配正PID，hash_proc登记PID哈希表，find_proc按正PID查找；list_init、list_add、le2proc用于链表管理，local_intr_save和local_intr_restore用于保护登记过程并恢复原中断状态。
- boot_pgdir_pa是内核页目录物理基址，内核线程共享内核地址空间，mm为NULL；不引入mm_create、dup_mmap、load_esp0或cr3等本项目不存在的接口或符号。
- struct context保存切换时使用的ra、sp和s0到s11；struct trapframe保存首次恢复所需的通用寄存器、status与epc等字段。
- kernel_thread_entry先执行move a0, s1，再以jalr s0调用线程函数，函数返回后调用do_exit。当前do_exit会panic，这是已有框架行为，本模块不扩展退出与回收机制。
- forkret调用forkrets(current->tf)，forkrets将sp指向该trapframe并跳转__trapret；__trapret恢复寄存器、sstatus和sepc，随后执行sret。
- read_csr(sstatus)、SSTATUS_SPP、SSTATUS_SPIE、SSTATUS_SIE用于构造新线程的返回状态；wakeup_proc要求目标当前既不是PROC_RUNNABLE也不是PROC_ZOMBIE，并将其置为PROC_RUNNABLE。
- 框架中含有检查函数，但是依赖模块三，可做关于模块二的静态检查。

[GUARANTEE]
必须在code/kern/process/proc.c中实现以下六个函数，保持签名不变：
    static struct proc_struct *alloc_proc(void);
    void proc_init(void);
    int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);
    int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
    static void copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf);
    static int copy_mm(uint32_t clone_flags, struct proc_struct *proc);

只能在功能模块二标记区域补全实现、必要的局部声明及注释，不得改变已有框架。
确保每个函数在被调用前已有定义或声明。
alloc_proc成功时返回安全初始化的PCB，失败返回NULL；kernel_thread与do_fork成功返回新线程的正PID，失败返回负错误码。
proc_init返回时，current为idleproc，idleproc与initproc均为PROC_RUNNABLE，initproc已完成登记且首次运行现场完整，能够与后续模块三的调度切换衔接。
copy_mm保持完整接口，本阶段不复制用户地址空间，成功返回0，内核线程mm保持NULL。

[SPECIFICATION]
共同状态约束：

- 本阶段只创建内核线程，调用链为proc_init -> kernel_thread -> do_fork -> copy_mm/copy_thread，创建时current及传入的trapframe有效，current->mm为NULL。
- PCB初始化、内核栈分配和首次现场构造必须在唤醒之前完成，不能让半初始化线程进入PROC_RUNNABLE。
- 首次运行链路为：后续switch_to恢复context -> forkret -> forkrets(current->tf) -> __trapret -> sret -> kernel_thread_entry -> fn(arg)。context决定切换后的内核入口，trapframe决定sret后的寄存器、特权状态和线程入口。
- 内核栈大小及trapframe布局以工程定义为准，trapframe完整位于新线程的内核栈内，context.sp与首次调用C函数时的栈满足RISC-V的16字节对齐约定。
- idleproc计入nr_process，但不插入proc_list或hash_list；普通新线程同时登记到这两个结构。初始化只在启动阶段执行一次，不重复重置。

alloc_proc
前置：内存分配接口可用。
达成效果：使用kmalloc(sizeof(struct proc_struct))分配PCB，失败返回NULL；成功时state为PROC_UNINIT、pid为-1、runs为0、kstack为0、need_resched为0、parent与mm与tf均为NULL、flags为0、pgdir为boot_pgdir_pa，context与name全部清零。
注意：PCB所有字段都应有确定初值，可先将整个结构清零，再设置state、pid与pgdir等字段；list_link与hash_link也应初始化为确定的未挂接状态，可使用list_init。

kernel_thread
前置：fn是有效的内核线程入口，current已建立。
达成效果：在当前栈上构造并清零局部struct trapframe，设置gpr.s0为fn、gpr.s1为arg、epc为kernel_thread_entry的地址；函数及参数地址按目标字段类型转换。设置status为(read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE，再调用do_fork(clone_flags | CLONE_VM, 0, &tf)并原样返回结果。
注意：这只构造保存的状态。SPP使sret返回S态，SPIE使返回后的SIE置位；sret会更新相关状态位，不能声称返回后sstatus逐位不变。局部tf由copy_thread复制到新线程栈中。

proc_init
前置：启动栈与内核页表已经建立。
达成效果：初始化proc_list与HASH_LIST_SIZE个hash_list桶；通过alloc_proc创建idleproc，失败时panic。设置idleproc->pid为0、state为PROC_RUNNABLE、kstack为(uintptr_t)bootstack、need_resched为1，使用set_proc_name命名为"idle"，nr_process加一，并在创建其他线程前设置current = idleproc。
随后调用kernel_thread(init_main, "Hello world!!", 0)，返回值小于等于0时panic；通过find_proc取回initproc，先确认非NULL再命名为"init"，断言idleproc的PID为0、initproc的PID为1。正常返回时nr_process为2。
注意：idleproc直接复用启动以来的执行现场，不需要多余操作；初始化时其tf为NULL、context为零。

copy_mm
前置：当前及新建线程均为内核线程，current->mm为NULL，proc->mm已由alloc_proc初始化为NULL。
达成效果：保留static int copy_mm(uint32_t clone_flags, struct proc_struct *proc)接口，当前阶段返回0，不分配、复制或修改用户地址空间，也不改变proc->mm。

copy_thread
前置：proc的内核栈已成功分配，tf指向有效的来源trapframe，context已由alloc_proc清零。
达成效果：将proc->tf设为(struct trapframe *)(proc->kstack + KSTACKSIZE) - 1，并完整复制*tf。设置proc->tf->gpr.a0 = 0；esp非0时gpr.sp取esp，否则取(uintptr_t)proc->tf。设置context.ra = (uintptr_t)forkret、context.sp = (uintptr_t)proc->tf，其余context字段保持零值。

do_fork
前置：current有效，tf有效，本阶段current->mm为NULL。
达成效果：

1. 若nr_process >= MAX_PROCESS，返回-E_NO_FREE_PROC，不分配资源；计数包含idleproc。
2. 调用alloc_proc，失败返回-E_NO_MEM；成功后设置proc->parent = current。
3. 调用setup_kstack，失败时释放PCB，并返回该负错误码。
4. 调用copy_mm(clone_flags, proc)，失败时先put_kstack再kfree，并返回copy_mm的负错误码；不要把所有辅助函数错误一律覆盖为-E_NO_MEM。
5. 调用copy_thread(proc, stack, tf)，构造新线程自己的trapframe与context；此时保持PROC_UNINIT。
6. 使用local_intr_save与local_intr_restore，在同一临界区内依次完成proc->pid = get_pid()、hash_proc(proc)、list_add(&proc_list, &proc->list_link)、nr_process加一，然后恢复进入临界区前的中断状态。
7. 完成登记后调用wakeup_proc(proc)，将其置为PROC_RUNNABLE，返回proc->pid。
   注意：get_pid、哈希登记、链表登记与计数更新必须保持一致；失败发生在登记前，不能提前增加nr_process。按分配的逆序释放资源，不重复释放，不释放借用的current或来源tf。

验证要求：

- 静态检查六个函数均位于功能模块二区域，声明与定义一致，功能模块三标记及所有无关文件保持不变；核对PID分配、登记顺序、唤醒时状态、资源释放顺序与中断状态恢复。
- 检查idleproc：pid为0、state为PROC_RUNNABLE、kstack等于bootstack、need_resched为1、name为"idle"，tf与context.ra为0，parent与mm为NULL，runs与flags为0；不挂接两个全局进程表。
- 检查initproc：pid为1、state为PROC_RUNNABLE、parent为idleproc、mm为NULL、name为"init"，context.ra为forkret、context.sp为其自身tf；tf中的s0/s1/epc/status及默认gpr.sp符合首次运行约定，并同时登记在proc_list和对应哈希桶中。
- 检查proc_init返回时current为idleproc、nr_process为2；核对多次创建时存活线程PID不冲突，进程数量上限返回-E_NO_FREE_PROC。达到上限之前也可能先耗尽物理内存，此时应返回-E_NO_MEM。
- 检查alloc_proc与setup_kstack失败时不泄漏、不改变进程表和计数；copy_mm当前恒成功，其失败分支通过静态审查确认清理与错误透传，必要时才在可清理的临时副本中注入失败，不修改原工程的测试或评分文件。
- 先验证proc.c能用工程现有编译参数独立编译。模块三未完成，只需要验证模块二部分。
- 如果由于模块三缺失无法进行验证进行静态检查并单独说明即可。
- 说明实际执行的编译与测试命令、结果及未验证部分。
