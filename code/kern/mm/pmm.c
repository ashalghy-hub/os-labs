#include <default_pmm.h>
#include <best_fit_pmm.h>
#include <buddy_pmm.h>
#include <defs.h>
#include <error.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <riscv.h>
#include <dtb.h>

// virtual address of physical page array
struct Page *pages;
// amount of physical memory (in pages)
size_t npage = 0;
// the kernel image is mapped at VA=KERNBASE and PA=info.base
uint64_t va_pa_offset;
// memory starts at 0x80000000 in RISC-V
// DRAM_BASE defined in riscv.h as 0x80000000
const size_t nbase = DRAM_BASE / PGSIZE;

// virtual address of boot-time page directory
uintptr_t *satp_virtual = NULL;
// physical address of boot-time page directory
uintptr_t satp_physical;

// physical memory management
const struct pmm_manager *pmm_manager;


static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    // Select Buddy explicitly; retain Best-Fit for the existing lab2 tests.
#ifdef PMM_USE_BUDDY
    pmm_manager = &buddy_pmm_manager;
#else
    pmm_manager = &best_fit_pmm_manager;
#endif
    cprintf("memory management: %s\n", pmm_manager->name);
    // 2. initialize the manager before page_init() registers available pages.
    pmm_manager->init();
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
}

//lab2 function1 YOUR CODE
static void page_init(void);

static void page_init(void) {
    // 1. init virtual-physical offset first: PADDR() depends on it.
    // High-half direct mapping satisfies VA = PA + PHYSICAL_MEMORY_OFFSET.
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;

    // 2. fetch RAM range from device tree (dtb_init() already ran in kern_init).
    uint64_t mem_begin = get_memory_base();
    uint64_t mem_size = get_memory_size();
    uint64_t mem_end = 0;
    if (__builtin_add_overflow(mem_begin, mem_size, &mem_end)) {
        panic("page_init: memory range overflow (base %lx size %lx)\n", mem_begin, mem_size);
    }

    // 3. total physical pages = PPN(mem_end) (floor for unaligned end).
    // Test expects exactly PPN(mem_base + mem_size).
    npage = PPN(mem_end);
    if (npage <= nbase) {
        panic("page_init: npage %lu <= nbase %lu\n", (unsigned long)npage, (unsigned long)nbase);
    }

    // 4. place Page descriptors right after kernel image, page-aligned (virtual addr!).
    extern char end[];
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    // number of Page structs: one per physical page in [DRAM_BASE, mem_end)
    size_t n = npage - nbase;

    // 5. mark every page descriptor Reserved by default.
    // default_init_memmap() requires PageReserved == 1 as precondition.
    for (size_t i = 0; i < n; i ++) {
        pages[i].flags = (1UL << PG_reserved);
        pages[i].property = 0;
        set_page_ref(pages + i, 0);
    }

    // 6. compute occupied physical range:
    // kernel image + bootstack + boot page table (all < end via kernel.ld/entry.S)
    // plus the Page descriptor array itself.
    // Guard against integer overflow in size computation.
    if (n > (size_t)-1 / sizeof(struct Page)) {
        panic("page_init: Page array size overflow\n");
    }
    size_t pages_bytes = n * sizeof(struct Page);
    uintptr_t pages_va = (uintptr_t)pages;
    if (pages_va > (uintptr_t)-1 - pages_bytes) {
        panic("page_init: Page array end overflow\n");
    }
    uintptr_t array_end_va = pages_va + pages_bytes;
    uintptr_t freemem_va = ROUNDUP(array_end_va, PGSIZE);
    // ROUNDUP overflow guard (far from 2^64 in practice, but be strict)
    if (freemem_va < array_end_va) {
        panic("page_init: freemem_va overflow\n");
    }
    // freemem_va >= KERNBASE holds since pages >= end >= KERNBASE,
    // so PADDR() is legal here (never treat high-half VA as PA).
    uintptr_t freemem_pa = PADDR(freemem_va);

    // Explicitly cover bootstack and boot page table even though the
    // linker already places them before `end`. This documents the
    // occupied range and stays correct if the layout ever changes.
    extern char bootstack[], bootstacktop[];
    extern char boot_page_table_sv39[];
    uintptr_t bootstack_end_pa = PADDR((uintptr_t)bootstacktop);
    uintptr_t pt_end_pa = PADDR((uintptr_t)boot_page_table_sv39) + PGSIZE;
    uintptr_t kern_end_pa = PADDR((uintptr_t)end);
    if (bootstack_end_pa > freemem_pa) {
        freemem_pa = ROUNDUP(bootstack_end_pa, PGSIZE);
    }
    if (pt_end_pa > freemem_pa) {
        freemem_pa = ROUNDUP(pt_end_pa, PGSIZE);
    }
    if (kern_end_pa > freemem_pa) {
        freemem_pa = ROUNDUP(kern_end_pa, PGSIZE);
    }
    // freemem_pa is page-aligned because every input was rounded up
    // (PGSIZE divides PHYSICAL_MEMORY_OFFSET, so VA/PA rounding agrees).

    // 7. hand remaining pages to the pmm manager.
    uint64_t mem_end_aligned = ROUNDDOWN(mem_end, PGSIZE);
    uintptr_t mem_begin_aligned = (uintptr_t)ROUNDUP(mem_begin, PGSIZE);
    if (freemem_pa < mem_begin_aligned) {
        freemem_pa = mem_begin_aligned;
    }
    // pa2page() has no lower-bound check: guarantee freemem_pa >= DRAM_BASE.
    if (freemem_pa < DRAM_BASE) {
        panic("page_init: freemem %lx below DRAM_BASE\n", (unsigned long)freemem_pa);
    }
    if (freemem_pa < mem_end_aligned) {
        struct Page *base = pa2page(freemem_pa);
        size_t free_n = (size_t)((mem_end_aligned - freemem_pa) >> PGSHIFT);
        if (free_n > 0) {
            init_memmap(base, free_n);
        }
    }

    cprintf("page_init: npage=%lu nbase=%lu freemem=%lx mem_end=%lx nr_free=%lu\n",
            (unsigned long)npage, (unsigned long)nbase,
            (unsigned long)freemem_pa, (unsigned long)mem_end,
            (unsigned long)nr_free_pages());
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
    // We need to alloc/free the physical memory (granularity is 4KB or other size).
    // So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    // First we should init a physical memory manager(pmm) based on the framework.
    // Then pmm can alloc/free the physical memory.
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();

    // use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();

    extern char boot_page_table_sv39[];
    satp_virtual = (pte_t*)boot_page_table_sv39;
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}
