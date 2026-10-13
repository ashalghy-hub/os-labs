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


EOI:
     实现完成。page_init() 已加入 kern/mm/pmm.c:67，原型为 static void page_init(void);，位于 pmm_init() 之前。

     实现逻辑：

     1. 先置 va_pa_offset = PHYSICAL_MEMORY_OFFSET（0xFFFFFFFF40000000），否则 PADDR() 非法。满足 VA = PA + OFFSET，从不对高半区 VA 当 PA 用。
     2. mem_begin/size = get_memory_base/size()，__builtin_add_overflow 防 base+size 溢出，npage = PPN(mem_end)，与测试 PPN(mem_base+mem_size) 一致，并断言 npage >
        nbase（nbase = DRAM_BASE/PGSIZE）。
     3. pages = ROUNDUP(end, PGSIZE)（虚拟地址，页对齐、>=end），共 n = npage-nbase 个描述符，与 page2ppn/pa2page 的 nbase 偏置对应。
     4. 全部 flags = 1<<PG_reserved, property=0, ref=0，满足 default_init_memmap() 的 PageReserved 前置条件。
     5. 描述符字节数 n*sizeof(Page) 做乘法/加法溢出检查，freemem_va = ROUNDUP(pages_va+bytes)，freemem_pa = PADDR(freemem_va)；再显式 max(PADDR(bootstacktop), PADDR(
        boot_page_table)+PGSIZE, PADDR(end))（三者本就在 end 之前，文档化已占用范围）。
     6. mem_end_aligned = ROUNDDOWN(mem_end)，freemem 与 mem_begin 对齐后若 freemem < mem_end 则 init_memmap(pa2page(freemem), (mem_end-freemem)>>PGSHIFT)。保证 freemem
        >= DRAM_BASE（pa2page 无下界检查），已占用页保持 Reserved 不进空闲链表，无整数溢出。

     框架修复（均已标明）：

     - kern/mm/best_fit_pmm.c：骨架引用了未定义的 free_list/nr_free 和缺失 best_fit_pmm_manager，根本编译不过。加 /* SKELETON FIX */ 的最小 free_area 定义 + TODO
       Exercise 2 存根 manager，仅为放行构建/Test1，不实现 best-fit。
     - kern/init/entry.S：/* SKELETON FIX */，原页表只有 index511 高半区映射，csrw satp 后低 PC（0x80200038）无映射，-d int 可见 exec_page_fault epc=0x80200000 死循环，
       测不到试。补 index2 恒等映射 0x80000000->0x80000000 (1G)。

     编译与测试（工具链 riscv64-linux-gnu-，本机无 riscv64-unknown-elf-）：

     - make GCCPREFIX=riscv64-linux-gnu- 通过，无警告（-Werror）。
     - 注入 tools/inject.py 到临时拷贝后 make 通过，qemu -kernel bin/ucore.img 输出：
       page_init: npage=557056 nbase=524288 freemem=80348000 mem_end=88000000 nr_free=31928
       check_alloc_page() succeeded!
       [Test 1] Page Init: PASS
       [Test 2] Best-Fit: FAIL (pmm_manager=default_pmm_manager)
       Test1 通过；Test2 失败属预期（Exercise2 未做，pmm_manager 保持 default，且未硬编码测试结果）。
     - 原树（未注入）同样启动并 check_alloc_page() succeeded!。

