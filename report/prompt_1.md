[PROMPT]

实现 RISC-V64 uCore Lab2 的物理内存初始化函数 `page_init()`。

目标文件：`kern/mm/pmm.c`

在 `//lab2 function1 YOUR CODE` 位置实现缺失的 `page_init()`。

当前 `pmm_init()` 已经调用该函数，但工程没有提供声明或定义。

1. 根据 Device Tree 提供的 RAM 范围确定物理页数量。
2. 初始化内核虚拟地址与物理地址之间的转换偏移量。
3. 在内核镜像末尾分配 `struct Page` 描述符数组。
4. 初始化所有物理页描述符，默认标记为 Reserved。
5. 计算内核镜像、启动栈、已有页表和描述符数组占用的物理内存范围。
6. 将剩余可用物理页交给当前 `pmm_manager`。
7. 保证已有的物理页地址转换函数和分配器检查逻辑正常工作。

不要修改或删除已有测试来使实现通过。

[RELY]

内存布局：`kern/mm/memlayout.h`

- `KERNBASE`
- `KERNEL_BEGIN_PADDR`
- `KERNEL_BEGIN_VADDR`
- `PHYSICAL_MEMORY_OFFSET`
- `KMEMSIZE`
- `KERNTOP`
- `struct Page`
- `PG_reserved`
- `SetPageReserved(page)`
- `ClearPageReserved(page)`
- `PageReserved(page)`

- 物理内存起点：`0x80000000`
- 内核物理起点：`0x80200000`
- 内核虚拟起点：`0xFFFFFFFFC0200000`
- 虚实地址偏移：`0xFFFFFFFF40000000`

当前高半区直接映射满足：

`VA = PA + PHYSICAL_MEMORY_OFFSET`

不要将高半区虚拟地址当作物理地址使用。

页面参数：`kern/mm/mmu.h`

- `PGSIZE`
- `PGSHIFT`
- `PPN(address)`

地址转换：`kern/mm/pmm.h`

- `PADDR(kva)`
- `page2pa(page)`
- `page2ppn(page)`
- `pa2page(pa)`
- `set_page_ref(page, value)`

注意：

- `PADDR()` 依赖 `va_pa_offset`，必须先初始化该变量。
- `page2ppn()` 使用 `nbase` 作为物理页号基准。
- `pa2page()` 没有完整的下界检查，调用前必须保证物理地址不小于 `DRAM_BASE`。
- `KADDR()` 当前被注释，禁止直接假设该接口可用。

全局变量：`kern/mm/pmm.c`

- `struct Page *pages`
- `size_t npage`
- `const size_t nbase`
- `uint64_t va_pa_offset`
- `const struct pmm_manager *pmm_manager`

设备树接口：`kern/driver/dtb.h`

- `get_memory_base()`
- `get_memory_size()`

`dtb_init()` 已在 `kern_init()` 中调用，早于 `pmm_init()`。

`kern/mm/pmm.c` 已提供：

`static void init_memmap(struct Page *base, size_t n)`

该函数委托给：

`pmm_manager->init_memmap(base, n)`

调用之前，所有待释放页面的 `PageReserved` 必须为真，因为 `default_init_memmap()` 依赖这个前置条件。

- 链接符号 `extern char end[]`
- `ROUNDUP()`

[GUARANTEE]

必须而且只交付以下函数：

**1. `static void page_init(void)`**

定义位置：`kern/mm/pmm.c`，位于 `pmm_init()` 之前。

函数原型必须为：

`static void page_init(void);`

如确有必要，可以添加少量仅供 `page_init()` 使用的 `static` 辅助函数，但必须说明原因。

必须保证：

- 初始化结束时，所有全局内存管理变量具有正确值。
- 已占用物理页不出现在分配器的空闲页集合中。
- 页描述符数组与物理页号的映射关系正确。
- 不发生内存布局计算的整数溢出。
- 不通过覆盖测试、硬编码测试结果等方式通过验收。
- 如果由于垃圾框架导致不得不补充其他实现/声明。只添加声明并标明TODO而不是像大脑缺失一样什么都不写。
- 如果由于垃圾框架导致没跑到测试地方就crash了，可以改成正确的实现并且标明/* SKELETON FIX */。

交付时提供：

1. 实现逻辑的简短说明。
2. 编译与测试结果。

[SPECIFICATION]

自己看实现，C语言都看不明白就滚吧。

