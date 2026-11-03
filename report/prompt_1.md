```text
[PROMPT]
任务：实现Lab3功能模块一“Trap上下文恢复与Trap入口功能”，补全RESTORE_ALL和__alltraps，使内核形成“Trap进入 -> 保存上下文 -> 调用C语言处理函数 -> 恢复上下文 -> sret返回”的完整流程。
目标位置：code/kern/trap/trapentry.S中两处标有lab3 function1 YOUR CODE的位置。
操作要求：必须在项目中修改实际文件，不能只输出代码片段。在现有框架上补全两个标记位置，保留SAVE_ALL、__trapret、末尾的sret及其他无关代码；不得修改struct trapframe、trap()函数签名、模块二的中断与异常处理函数、Lab2内存管理代码以及tools中的测试、注入和评分逻辑，不得硬编码测试结果。
注释要求：保留lab3 function1标记，将YOUR CODE替换为与已迁入Lab2代码一致的学号2413625；适当添加说明上下文布局、栈指针恢复和函数调用关系的注释，风格与现有工程一致。
测试环境：在已有WSL环境中使用RISC-V工具链验证；本机项目路径为D:\work\os-labs，WSL挂载路径为/mnt/d/work/os-labs，编译目录为/mnt/d/work/os-labs/code。
输出要求：使用下面[RELY]、[GUARANTEE]、[SPECIFICATION]中的信息，以工程真实代码为准。完成后简要说明修改内容、Trap frame与寄存器的对应关系、sp为何需要特殊处理、编译及验证结果，并给出手动验证方法。未执行或受其他模块影响的检查应如实说明，不能写成已经通过。

[RELY]
- trapentry.S中的SAVE_ALL已经将寄存器保存到栈上的中断帧（Trap frame），恢复时按相同位置读取。
- trap.h中的struct trapframe描述这块内存：gpr保存x0到x31，后面依次是status、epc、badvaddr、cause。
- 中断帧共36格：第0到31格保存对应编号的通用寄存器，第32到35格依次保存上述四个字段；x2对应原sp，SAVE_ALL 中对 x2(sp) 的处理方式与其他通用寄存器并不完全相同，因此设计 RESTORE_ALL 时不能简单地把所有寄存器按照完全相同的方式恢复。
- riscv.h提供LOAD、STORE和REGBYTES宏。当前每格8字节，中断帧共288字节，偏移使用现有宏表达。
- 保存后，当前sp指向中断帧，原sp保存在tf->gpr.sp中。恢复时最后再恢复sp，避免影响其他数据的读取。
- 已有接口为void trap(struct trapframe *tf)：通过a0传入中断帧地址，调用时栈按16字节对齐。
- trap()可以修改中断帧，例如调整返回位置tf->epc；恢复时以处理后的内容为准。
- 已有__trapret入口负责执行RESTORE_ALL，随后通过sret按恢复后的sepc和sstatus返回。

[GUARANTEE]
必须在code/kern/trap/trapentry.S中实现或补全以下汇编接口：
    .macro RESTORE_ALL
        从当前sp指向的Trap frame恢复处理器上下文。
    .endm

    __alltraps:
        保留已有SAVE_ALL，在其后建立与void trap(struct trapframe *tf)的调用关系。

必须保留并正确衔接现有返回路径：
    __trapret:
        RESTORE_ALL
        sret

RESTORE_ALL是汇编宏，__alltraps和__trapret是汇编标签，不能将其替换为同名的普通C函数。
只能在两处功能模块一标记位置补全实现及必要注释，不得改变已有框架。
trap() 返回以后，应能够进入 __trapret，完成上下文恢复并通过 sret 返回。

[SPECIFICATION]
共同状态约束：
- Trap frame布局以现有SAVE_ALL和struct trapframe为准；保存槽位与恢复槽位必须逐项对应。
- Trap发生前的内核栈有效并满足调用约定；保存后的Trap frame完整、可访问，在C函数调用及恢复过程中保持有效。
- 除C语言处理函数明确修改的上下文外，Trap返回后应保留被打断程序的通用寄存器值和栈指针，x0始终为0。
- 本模块只负责上下文传递、恢复和返回，不负责判断Trap原因、推进异常epc、递增ticks或实现时钟事件设置。
- 不主动开启中断；遵循当前框架的中断状态管理及sret返回机制，不扩展用户态栈切换或新的嵌套Trap机制。

RESTORE_ALL
前置：C语言Trap处理函数已经返回，sp重新指向当前Trap frame首地址T；Trap frame仍然有效，其中status、epc和gpr字段包含应恢复的上下文，返回地址及特权状态满足sret的使用条件。
达成效果：通用寄存器x1到x31恢复为Trap frame中的对应值，x0保持为0；sstatus和sepc写入Trap frame中处理后的status和epc；sp恢复为tf->gpr.sp，当前Trap frame不再占用被打断程序的栈空间。执行可继续进入已有sret。
情况1：处理函数没有修改保存的上下文时，恢复被打断时的寄存器和返回位置，使其继续原执行流。
情况2：处理函数合法修改了tf->epc、tf->status或某个通用寄存器槽位时，以修改后的内容恢复，不能用恢复代码内缓存的旧值覆盖处理结果。
注意：恢复用于访问Trap frame的栈指针之前，必须完成其他仍需从该Trap frame读取的恢复操作；不得因提前恢复sp或临时寄存器而失去正确的取数地址。badvaddr和cause是诊断字段，不需要将其写回sbadaddr或scause；不要求恢复原sscratch。RESTORE_ALL只完成恢复，最终Trap返回由已有sret完成。

__alltraps
前置：处理器已因Trap进入当前内核的统一入口，使用有效的内核栈，原sp满足16字节对齐；已有SAVE_ALL可以在该栈上建立完整Trap frame。
达成效果：在已有SAVE_ALL之后，将当前Trap frame首地址作为唯一参数传给trap(struct trapframe *tf)。trap()返回时，sp与调用trap()前指向同一个Trap frame；随后执行进入__trapret，完成恢复并通过已有sret返回。
注意：传入a0的值必须是Trap frame首地址，不是原sp或某个字段的地址；调用C函数时遵守RISC-V调用约定和栈对齐要求。调用可能覆盖ra、a0及其他调用者保存寄存器，不能依赖这些寄存器在调用后仍保存临时值，被打断时的原值应由Trap frame提供。每次正常返回的Trap都必须完成一次与保存相配对的恢复，不得漏恢复、重复恢复或造成栈指针累积偏移。

__trapret与sret衔接
前置：sp指向处理完成后的有效Trap frame，RESTORE_ALL满足上述规格。
达成效果：RESTORE_ALL完成恢复后，由现有sret将控制流转移到处理后的tf->epc，并按RISC-V特权规范更新相关状态；后续发生的Trap仍可复用同一套保存、调用、恢复流程。
注意：不得使用普通函数返回代替Trap返回；不要将sret执行后的sstatus描述为与保存值逐位不变，因为sret本身会更新SIE、SPIE、SPP等状态。

验证要求：
- 先检查两处功能模块一标记均已补全，SAVE_ALL、Trap frame布局、__trapret及已有sret未被改变；核对恢复槽位、sp处理顺序和调用边界的栈对齐。
- 这个模块完成后，系统应能够形成完整的“Trap 进入 -> 上下文保存 -> C 语言处理 -> 上下文恢复 -> Trap 返回”闭环。
- 要确认目标汇编文件能够独立编译；需要时用RISC-V反汇编工具检查实际指令和对trap的调用。
- 当前功能模块二中的interrupt_handler()和exception_handler()尚未实现，这部分不需要实现，不能为了测试通过实现
- 如需独立验证运行行为，可在可清理的临时副本中设置最小Trap处理测试：检查C函数收到的Trap frame地址和对齐，合法调整测试异常的返回位置，确认Trap返回后的寄存器、sp及连续多次返回行为。说明测试作用。
- 环境makefile参数可能有些问题，可以修改为-kernel规避。
```
