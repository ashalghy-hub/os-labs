# 模块二任务三：Buddy System

## 提示词一：实现与接入

```text
[PROMPT]
要求：完成 uCore Lab2 功能模块二任务三，参考现有物理内存管理框架，从零实现 Buddy System（伙伴系统）分配器并接入内核。

目标文件：新增 code/kern/mm/buddy_pmm.c、buddy_pmm.h；在 code/kern/mm/pmm.c 中添加必要的管理器选择逻辑。
保留已有 page_init()、First-Fit、Best-Fit 及其测试，不修改 Page 结构、公开分配接口和 tools 中的评分逻辑，不实现 SLUB，不编写实验报告。

操作要求：阅读真实代码后修改实际文件，保持现有代码风格，添加必要注释。先完成分配器及基本状态检查，完整测试由下一份提示词补充。
运行环境以当前机器实际可用的工具链和 WSL 为准，不照搬其他成员的环境路径。不能运行的检查必须明确说明。

[RELY]
接口定义：code/kern/mm/pmm.h 中的 struct pmm_manager。
页面结构与状态宏：memlayout.h；页大小：mmu.h；链表操作：libs/list.h。
参考 default_pmm.c、best_fit_pmm.c 理解注册、分配、释放和检查的调用方式。

page_init() 已负责探测内存、建立 pages 数组，并将可用的连续页面以 Reserved 状态交给当前管理器的 init_memmap()。
相邻 Page 描述符对应相邻物理页；page2ppn()、page2pa() 可用于地址计算。npage 是物理页号上界，描述符数量为 npage-nbase，不能混淆。

[GUARANTEE]
新增并实现以下接口：
    static void buddy_init(void);
    static void buddy_init_memmap(struct Page *base, size_t n);
    static struct Page *buddy_alloc_pages(size_t n);
    static void buddy_free_pages(struct Page *base, size_t n);
    static size_t buddy_nr_free_pages(void);
    static void buddy_check(void);

定义 const struct pmm_manager buddy_pmm_manager，并在 buddy_pmm.h 中声明，将各接口正确注册。
允许增加模块内部的辅助函数和元数据，但不能依赖尚未实现的堆分配器，也不能递归调用 alloc_pages() 来取得自身管理所需的元数据。

在 pmm.c 中支持通过编译宏 PMM_USE_BUDDY 选择 Buddy；未定义时保持原有 Best-Fit。启用 Buddy 后，初始化、分配、释放和检查必须实际走 Buddy 接口，不能只修改名称输出。
初始 buddy_check() 至少检查空闲块大小、对齐、链表与空闲页计数的一致性，不得用空函数冒充检查。

[SPECIFICATION]
共同约束：
- 按阶管理空闲块，k 阶块包含 2^k 个连续物理页。
- 统一使用物理页号确定块对齐和伙伴关系，不能混用虚拟地址、描述符下标和物理页号。
- 只有同阶、空闲且互为伙伴的块才能合并，不能因为物理相邻就直接合并。
- 空闲块不能重叠，不能包含保留页或已分配页；nr_free 统计实际空闲页数。

buddy_init：
初始化各阶空闲链表、计数和内部状态。

buddy_init_memmap：
接收 n>0 的有效连续 Reserved 页面，将其拆成满足大小和对齐要求的二次幂块。
起点不按大块对齐、长度不是二次幂时，也必须保留全部可用页，不能直接丢弃前后零散页面。
注册后正确更新页面状态，并在符合条件时合并伙伴。

buddy_alloc_pages：
n>0；将请求向上取整为最小的 2^k 页。
查找合适阶的空闲块，必要时逐级拆分，返回实际分配块的首页面。
记录原始请求和实际块大小，扣除实际分配的页数。
没有合适块或请求无法安全取整时返回 NULL，失败不能改变分配器状态。

buddy_free_pages：
调用者传入原分配返回的首页面和原始请求 n。
核对分配记录，回收整个实际分配块，并逐级合并空闲伙伴。
本实现不支持部分释放；对可检测的重复释放、块内指针、参数不匹配、保留页或越界范围，在修改状态前使用 assert() 拒绝。

buddy_nr_free_pages：
返回实际空闲页数，不改变状态。

验证要求：
- 使用全新构建目录或强制重新编译，避免仓库内已有 obj/bin 影响结果。
- 分别验证默认 Best-Fit 和启用 PMM_USE_BUDDY 的构建。
- 如旧 loader 启动方式与当前 QEMU 不兼容，可直接使用 -kernel 启动验证，不顺带修改无关启动或评分脚本。
- 不要求 Buddy 模式通过只检查 Best-Fit 管理器身份的 Test 2，也不得修改该测试伪造通过。
- 简要说明算法、接口约定、改动文件和实际验证结果；不把打印管理器名称当作算法正确的证明。
```

## 提示词二：测试设计与验证

```text
[PROMPT]
要求：针对上一份提示词生成的 Buddy System 实现，设计并编写测试函数，验证初始化、分配、拆分、释放和伙伴合并的正确性。

先阅读实际生成的 buddy_pmm.c、buddy_pmm.h 和 pmm.c，再确定测试方式。不要仅根据函数名称假设实现行为。
本次只补充 Buddy 测试与必要的测试接入，不修改 First-Fit、Best-Fit、page_init() 或既有评分工具；若发现 Buddy 实现缺陷，可以修复，但必须说明原因，不能通过放宽断言使测试通过。

[RELY]
Buddy 已通过 struct pmm_manager 接入，PMM_USE_BUDDY 控制管理器选择。
接口为 alloc_pages(n)、free_pages(base,n)、nr_free_pages()，也可以在模块内部调用对应 Buddy 接口。
申请 n 页实际占用向上取整的 2^k 页；释放传入原始 n，不支持部分释放。
模块内部状态以真实代码为准，不能照搬 Best-Fit 测试只保存 free_list 和 nr_free 的方法。

[GUARANTEE]
实现并接入 buddy_check()，由启用 Buddy 的内核启动流程实际执行。
测试使用 assert() 检查结果，覆盖成功和失败路径，不能只打印 PASS。
测试前后核对空闲页数量和分配器结构，正常结束时必须归还全部测试分配，不能泄漏页面或损坏原空闲区。
测试需要受控内存布局时，采用独立测试状态或可靠的隔离方案，不得把仍由真实分配器管理的页面重复注册。

[SPECIFICATION]
至少覆盖：

1. 初始化与注册
验证非二次幂长度、非大块对齐起点能够完整注册，不丢失页面。
核对各阶块大小、对齐、非重叠和空闲页计数。

2. 基本分配与释放
测试 1、2、4、8 页等请求；返回范围有效且连续，多次分配互不重叠。
释放后空闲页数恢复。

3. 非二次幂请求
测试 3 页实际占 4 页、5 页实际占 8 页。
通过计数变化和分配范围验证实际占用；使用原始 n 释放后完整恢复。

4. 逐级拆分
在受控条件下从大块分配小块，确认剩余部分仍可分配且没有重叠。
验证分配块与剩余空闲块的元数据一致。

5. 伙伴合并
释放同阶伙伴后能够重新获得更大块，覆盖多级合并及不同释放顺序。
同时验证相邻但不互为伙伴的块不会被错误合并。测试布局必须保证能区分这两种情况。

6. 分配失败
测试总页数不足、没有满足阶数的块、超大请求等情况。
失败返回 NULL，空闲计数和已有分配保持不变。

7. 数据隔离
通过合法虚实地址转换访问测试页面，写入不同标记，确认不同分配互不覆盖。
不访问保留页、固件或内核数据。

8. 多轮操作与状态恢复
使用可复现的多轮分配、交错释放，反复检查块结构、非重叠和空闲计数。
结束后恢复基准状态，并确认仍能正常分配。

非法参数会触发 assert()，如需验证重复释放、部分释放或错误 n，应设计独立运行的负向用例，不得让预期 panic 中断正常测试后仍声称全部通过。

验证与输出：
- 强制重新编译 Buddy 配置并实际运行，记录命令、关键输出及失败信息。
- 内核最后的无限循环导致 timeout，不等于测试失败；必须确认测试完成且无非预期 panic。
- 简要列出每组测试覆盖的行为、预期结果，以及它为什么能发现对应错误。
- 测试受环境限制未执行时明确说明，不能把预期结果写成实测结果。
```

## 实现与验证结果

新增 `code/kern/mm/buddy_pmm.c`、`buddy_pmm.h`，在 `pmm.c` 中通过 `PMM_USE_BUDDY` 选择 Buddy，默认保持 Best-Fit。按物理页号判断伙伴，各阶使用独立空闲链表；请求向上取整到二次幂页数，释放须传原始请求，不支持部分释放。

2026-10-18 在 WSL Ubuntu 26.04.1、RISC-V GCC 14.2.0、QEMU 10.2.1 中完成全新目录构建和运行。以下命令在 `code` 目录执行可以复现；验证时实际使用临时源码副本，未复用原有 obj/bin。

```sh
# 正向测试：启用 Buddy
make -B -j2 DEFS=-DPMM_USE_BUDDY
timeout 5s qemu-system-riscv64 -machine virt -nographic -bios default -kernel bin/ucore.img

# 回归：切回默认 Best-Fit
make -B -j2 DEFS=
timeout 5s qemu-system-riscv64 -machine virt -nographic -bios default -kernel bin/ucore.img

# 独立负向测试示例：重复释放；编号 1～7 分别构建、分别运行
make -B -j2 DEFS="-DPMM_USE_BUDDY -DBUDDY_NEGATIVE_TEST=1"
timeout 3s qemu-system-riscv64 -machine virt -nographic -bios default -kernel bin/ucore.img
```

| 测试 | 覆盖内容及有效性 |
|---|---|
| 注册 | 注册起点偏移 1 页、长度 13 页的区间，逐页分配验证没有遗漏；另验证分批注册后合并 |
| 基本分配 | 申请 1/2/4/8 页，检查对齐、连续、互不重叠及释放后计数恢复 |
| 非二次幂 | 申请 3/5 页分别扣除 4/8 页，按原始请求释放，验证记录与计数约定 |
| 拆分 | 从 16 页块分出 1 页，检查 1/2/4/8 页尾块并分配剩余全部页面，发现丢块和重复分配 |
| 合并 | 释放同阶伙伴后重新取得大块；第 1、2 页虽相邻但不是伙伴，不能合成 2 页块 |
| 失败 | 覆盖空池、容量不足、无合适阶与超大请求，核对失败前后元数据指纹不变 |
| 数据隔离 | 向真实分配的 1/4/8 页写入不同标记，再逐字节检查，包括向上取整的尾部 |
| 多轮操作 | 固定种子执行 128 步分配释放，每步检查结构，结束后恢复并重新分配整个测试区 |

受控场景使用 64 个独立测试描述符，不访问它们计算出的物理地址。测试保存并恢复真实描述符数组指针、页号上界、所有阶链表根和两个计数，再执行真实页数据测试。

实测八组正向检查全部通过，恢复后空闲页数为 31927，输出：

```text
buddy_check: all 8 groups passed; live allocator restored
check_alloc_page() succeeded!
```

默认 Best-Fit 同样输出 `check_alloc_page() succeeded!`。负向编号 1～7 分别对应重复释放、部分释放、错误请求大小、块内指针、零申请、保留页和越界释放，七次独立启动均命中预期断言。正向内核最后循环、负向内核断言后停留，均由 timeout 结束；退出码 124 本身不作为通过依据。

未发现需要修复的 Buddy 分配逻辑缺陷；未修改已有分配器、`page_init()`、公开结构或评分工具。Buddy 模式不使用只验证 Best-Fit 管理器身份的旧 Test 2 作为验收依据。
