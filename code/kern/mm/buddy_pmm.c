#include <buddy_pmm.h>
#include <list.h>
#include <stdio.h>

/* lab2 function2-3: Buddy System.
 * Page.property holds a free block's size or an allocated head's original
 * request. Private flags distinguish managed pages, allocations and heads,
 * without changing struct Page or requiring a heap for allocation records.
 */
#define BUDDY_MANAGED       (1UL << 2)
#define BUDDY_ALLOCATED     (1UL << 3)
#define BUDDY_ALLOC_HEAD    (1UL << 4)

/* Block lengths must fit Page.property; all shifts also fit RV64 size_t. */
enum { BUDDY_MAX_ORDER = sizeof(((struct Page *)0)->property) * 8 - 1 };
static list_entry_t free_lists[BUDDY_MAX_ORDER + 1];
static size_t nr_free, nr_managed;

static size_t
buddy_block_size(unsigned int order) {
    assert(order <= BUDDY_MAX_ORDER);
    return (size_t)1 << order;
}

/* Validate numeric addresses before doing Page pointer arithmetic. */
static size_t
buddy_page_index(struct Page *page) {
    assert(pages != NULL && npage > nbase);
    uintptr_t addr = (uintptr_t)page, start = (uintptr_t)pages;
    assert(addr >= start);
    uintptr_t offset = addr - start;
    assert(offset % sizeof(struct Page) == 0);
    size_t index = offset / sizeof(struct Page);
    assert(index < npage - nbase);
    return index;
}

static void
buddy_validate_range(struct Page *base, size_t n) {
    size_t index = buddy_page_index(base);
    assert(n > 0 && n <= npage - nbase - index);
}

/* Bounded rounding: an unrepresentable request cannot overflow or mutate state. */
static bool
buddy_request_order(size_t n, unsigned int *order) {
    unsigned int k = 0;
    if (n > buddy_block_size(BUDDY_MAX_ORDER)) {
        return 0;
    }
    while (buddy_block_size(k) < n) {
        k ++;
    }
    *order = k;
    return 1;
}

/* Use absolute physical page numbers, never a descriptor-array-relative XOR. */
static struct Page *
buddy_find_partner(struct Page *base, unsigned int order) {
    size_t length = buddy_block_size(order);
    ppn_t partner_ppn = page2ppn(base) ^ length;
    if (partner_ppn < nbase || partner_ppn >= npage ||
        length > npage - partner_ppn) {
        return NULL;
    }
    struct Page *partner = pages + (partner_ppn - nbase);
    if (!(partner->flags & BUDDY_MANAGED) ||
        (partner->flags & BUDDY_ALLOCATED) || PageReserved(partner) ||
        !PageProperty(partner) || partner->property != length) {
        return NULL;
    }
    return partner;
}

/* All pages are already free. Only block-head metadata changes during merging. */
static void
buddy_insert_block(struct Page *base, unsigned int order) {
    while (order < BUDDY_MAX_ORDER) {
        struct Page *partner = buddy_find_partner(base, order);
        if (partner == NULL) {
            break;
        }
        list_del_init(&partner->page_link);
        ClearPageProperty(partner);
        partner->property = 0;
        if (page2ppn(partner) < page2ppn(base)) {
            base = partner;
        }
        order ++;
    }
    base->property = buddy_block_size(order);
    SetPageProperty(base);
    list_add(&free_lists[order], &base->page_link);
}

static void
buddy_init(void) {
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
        list_init(&free_lists[k]);
    }
    nr_free = nr_managed = 0;
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    buddy_validate_range(base, n);
    /* Check the entire registration before changing its state. */
    for (size_t i = 0; i < n; i ++) {
        assert(PageReserved(base + i));
        assert(!(base[i].flags & BUDDY_MANAGED));
    }
    for (size_t i = 0; i < n; i ++) {
        base[i].flags = BUDDY_MANAGED;
        base[i].property = 0;
        set_page_ref(base + i, 0);
        list_init(&base[i].page_link);
    }
    nr_free += n;
    nr_managed += n;

    /* Cover the exact range with physically aligned power-of-two blocks. */
    size_t remaining = n;
    while (remaining > 0) {
        unsigned int order = 0;
        ppn_t ppn = page2ppn(base);
        while (order < BUDDY_MAX_ORDER &&
               buddy_block_size(order + 1) <= remaining &&
               (ppn & (buddy_block_size(order + 1) - 1)) == 0) {
            order ++;
        }
        size_t length = buddy_block_size(order);
        buddy_insert_block(base, order);
        base += length;
        remaining -= length;
    }
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    unsigned int requested_order;
    if (!buddy_request_order(n, &requested_order)) {
        return NULL;
    }
    size_t length = buddy_block_size(requested_order);
    if (length > nr_free) {
        return NULL;
    }
    unsigned int order = requested_order;
    while (order <= BUDDY_MAX_ORDER && list_empty(&free_lists[order])) {
        order ++;
    }
    if (order > BUDDY_MAX_ORDER) {
        return NULL;
    }
    struct Page *base = le2page(list_next(&free_lists[order]), page_link);
    list_del_init(&base->page_link);
    ClearPageProperty(base);
    base->property = 0;

    /* Keep the lower half and return each upper half to its own order list. */
    while (order > requested_order) {
        order --;
        struct Page *upper = base + buddy_block_size(order);
        upper->property = buddy_block_size(order);
        SetPageProperty(upper);
        list_add(&free_lists[order], &upper->page_link);
    }
    for (size_t i = 0; i < length; i ++) {
        base[i].flags = BUDDY_MANAGED | BUDDY_ALLOCATED;
        base[i].property = 0;
        set_page_ref(base + i, 0);
    }
    base->flags |= BUDDY_ALLOC_HEAD;
    base->property = n;
    nr_free -= length;
    return base;
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    buddy_validate_range(base, n);
    /* The original request is checked as well as the rounded allocation size. */
    assert((base->flags & BUDDY_ALLOC_HEAD) && base->property == n);
    unsigned int order;
    assert(buddy_request_order(n, &order));
    size_t length = buddy_block_size(order);
    buddy_validate_range(base, length);
    assert((page2ppn(base) & (length - 1)) == 0);
    for (size_t i = 0; i < length; i ++) {
        struct Page *p = base + i;
        assert((p->flags & BUDDY_MANAGED) && (p->flags & BUDDY_ALLOCATED));
        assert(!PageReserved(p) && !PageProperty(p));
        assert(i == 0 || !(p->flags & BUDDY_ALLOC_HEAD));
    }
    for (size_t i = 0; i < length; i ++) {
        base[i].flags = BUDDY_MANAGED;
        base[i].property = 0;
        set_page_ref(base + i, 0);
    }
    nr_free += length;
    buddy_insert_block(base, order);
}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}

/* Walk both the lists and the descriptor partition: count equality alone
 * would miss overlapping blocks or an allocated page on a free list.
 */
static void
buddy_check_state(void) {
    size_t listed_pages = 0, listed_blocks = 0;
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
        size_t length = buddy_block_size(k);
        list_entry_t *head = &free_lists[k], *prev = head, *le = list_next(head);
        while (le != head) {
            assert(++ listed_blocks <= nr_managed);
            struct Page *p = le2page(le, page_link);
            buddy_validate_range(p, length);
            assert(le->prev == prev);
            assert(PageProperty(p) && p->property == length);
            assert((page2ppn(p) & (length - 1)) == 0);
            if (k < BUDDY_MAX_ORDER) {
                assert(buddy_find_partner(p, k) == NULL);
            }
            listed_pages += length;
            prev = le;
            le = list_next(le);
        }
        assert(head->prev == prev);
    }

    size_t free_pages = 0, free_blocks = 0, managed_pages = 0;
    for (size_t i = 0; i < npage - nbase;) {
        struct Page *base = pages + i;
        if (!(base->flags & BUDDY_MANAGED)) {
            assert(PageReserved(base));
            i ++;
            continue;
        }
        bool allocated = (base->flags & BUDDY_ALLOCATED) != 0;
        unsigned int order;
        assert(base->property > 0 && buddy_request_order(base->property, &order));
        size_t length = buddy_block_size(order);
        buddy_validate_range(base, length);
        assert((page2ppn(base) & (length - 1)) == 0);
        if (allocated) {
            assert(base->flags & BUDDY_ALLOC_HEAD);
            assert(!PageProperty(base));
        } else {
            assert(PageProperty(base) && base->property == length);
            free_pages += length;
            free_blocks ++;
        }
        for (size_t j = 0; j < length; j ++) {
            struct Page *p = base + j;
            assert((p->flags & BUDDY_MANAGED) && !PageReserved(p));
            assert(((p->flags & BUDDY_ALLOCATED) != 0) == allocated);
            if (j > 0) {
                assert(!PageProperty(p) && !(p->flags & BUDDY_ALLOC_HEAD));
                assert(p->property == 0);
            } else if (!allocated) {
                assert(!(p->flags & BUDDY_ALLOC_HEAD));
            }
            assert(page_ref(p) == 0);
        }
        managed_pages += length;
        i += length;
    }
    assert(managed_pages == nr_managed);
    assert(free_pages == nr_free && listed_pages == nr_free);
    assert(free_blocks == listed_blocks);
}

/* Synthetic descriptors exercise exact layouts without re-registering live
 * physical pages. Their calculated physical addresses are NEVER dereferenced.
 * The data-isolation check runs separately on real allocated pages.
 */
enum { BUDDY_TEST_PAGES = 64 };
static struct Page buddy_test_pages[BUDDY_TEST_PAGES];

static void
buddy_test_reset(void) {
    assert(pages == buddy_test_pages && npage == nbase + BUDDY_TEST_PAGES);
    buddy_init();
    for (size_t i = 0; i < BUDDY_TEST_PAGES; i ++) {
        pages[i].flags = (1UL << PG_reserved);
        pages[i].property = 0;
        set_page_ref(pages + i, 0);
        list_init(&pages[i].page_link);
    }
    buddy_check_state();
}

/* Include list order, page metadata and allocation records, not just nr_free.
 * Padding and uninitialized links on unregistered pages are not inspected.
 */
static uint64_t
buddy_test_fingerprint(void) {
    uint64_t hash = 14695981039346656037ULL;
#define BUDDY_TEST_MIX(value) (hash = (hash ^ (uint64_t)(value)) * 1099511628211ULL)
    BUDDY_TEST_MIX(nr_free);
    BUDDY_TEST_MIX(nr_managed);
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
        BUDDY_TEST_MIX((uintptr_t)free_lists[k].next);
        BUDDY_TEST_MIX((uintptr_t)free_lists[k].prev);
    }
    for (size_t i = 0; i < npage - nbase; i ++) {
        struct Page *p = pages + i;
        BUDDY_TEST_MIX(p->flags);
        BUDDY_TEST_MIX(p->property);
        BUDDY_TEST_MIX(page_ref(p));
        if (p->flags & BUDDY_MANAGED) {
            BUDDY_TEST_MIX((uintptr_t)p->page_link.next);
            BUDDY_TEST_MIX((uintptr_t)p->page_link.prev);
        }
    }
#undef BUDDY_TEST_MIX
    return hash;
}

static void
buddy_test_failure(size_t request) {
    uint64_t before = buddy_test_fingerprint();
    assert(buddy_alloc_pages(request) == NULL);
    assert(buddy_test_fingerprint() == before);
    buddy_check_state();
}

static size_t
buddy_test_allocation(struct Page *p, size_t request) {
    assert(p != NULL && p->property == request);
    unsigned int order;
    assert(buddy_request_order(request, &order));
    size_t length = buddy_block_size(order);
    buddy_validate_range(p, length);
    assert((page2ppn(p) & (length - 1)) == 0);
    for (size_t i = 0; i < length; i ++) {
        assert((p[i].flags & BUDDY_ALLOCATED) && !PageReserved(p + i));
        assert(!PageProperty(p + i));
        assert(pa2page(page2pa(p + i)) == p + i);
    }
    return length;
}

static void
buddy_test_disjoint(struct Page *a, size_t an, struct Page *b, size_t bn) {
    ppn_t ap = page2ppn(a), bp = page2ppn(b);
    assert(ap + an <= bp || bp + bn <= ap);
}

static void
buddy_test_registration(void) {
    buddy_test_reset();
    /* [1,14) is neither power-of-two sized nor large-block aligned. */
    buddy_init_memmap(pages + 1, 13);
    assert(nr_free == 13 && nr_managed == 13);
    assert(pages[1].property == 1 && pages[2].property == 2);
    assert(pages[4].property == 4 && pages[8].property == 4);
    assert(pages[12].property == 2);
    buddy_check_state();
    struct Page *blocks[13];
    uint64_t seen = 0;
    for (size_t i = 0; i < 13; i ++) {
        blocks[i] = buddy_alloc_pages(1);
        assert(buddy_test_allocation(blocks[i], 1) == 1);
        size_t index = buddy_page_index(blocks[i]);
        assert(index >= 1 && index < 14);
        assert(!(seen & ((uint64_t)1 << index)));
        seen |= (uint64_t)1 << index;
        buddy_check_state();
    }
    assert(seen == (((uint64_t)1 << 14) - 2) && nr_free == 0);
    buddy_test_failure(1);
    for (size_t i = 0; i < 13; i ++) {
        buddy_free_pages(blocks[(i * 5) % 13], 1);
        buddy_check_state();
    }
    assert(nr_free == 13);

    /* Adjacent separately registered ranges must also coalesce correctly. */
    buddy_test_reset();
    buddy_init_memmap(pages, 3);
    buddy_init_memmap(pages + 3, 5);
    buddy_check_state();
    assert(nr_free == 8 && pages[0].property == 8);
    struct Page *whole = buddy_alloc_pages(8);
    assert(whole == pages);
    buddy_free_pages(whole, 8);
    cprintf("[Buddy 1] initialization and exact registration: PASS\n");
}

static void
buddy_test_basic(void) {
    buddy_test_reset();
    buddy_init_memmap(pages, BUDDY_TEST_PAGES);
    struct Page *blocks[4];
    size_t used = 0;
    for (size_t i = 0; i < 4; i ++) {
        size_t length = (size_t)1 << i;
        blocks[i] = buddy_alloc_pages(length);
        assert(buddy_test_allocation(blocks[i], length) == length);
        for (size_t j = 0; j < i; j ++) {
            buddy_test_disjoint(blocks[i], length, blocks[j], (size_t)1 << j);
        }
        used += length;
        assert(nr_free == BUDDY_TEST_PAGES - used);
        buddy_check_state();
    }
    const unsigned int release_order[] = {2, 0, 3, 1};
    for (size_t i = 0; i < 4; i ++) {
        unsigned int k = release_order[i];
        buddy_free_pages(blocks[k], (size_t)1 << k);
        buddy_check_state();
    }
    assert(nr_free == BUDDY_TEST_PAGES && pages[0].property == BUDDY_TEST_PAGES);
    cprintf("[Buddy 2] 1/2/4/8-page allocation and release: PASS\n");
}

static void
buddy_test_rounding(void) {
    buddy_test_reset();
    buddy_init_memmap(pages, 16);
    struct Page *a = buddy_alloc_pages(3), *b = buddy_alloc_pages(5);
    assert(buddy_test_allocation(a, 3) == 4);
    assert(buddy_test_allocation(b, 5) == 8);
    buddy_test_disjoint(a, 4, b, 8);
    assert(nr_free == 4);
    buddy_check_state();
    buddy_free_pages(a, 3);
    assert(nr_free == 8);
    buddy_free_pages(b, 5);
    assert(nr_free == 16 && pages[0].property == 16);
    buddy_check_state();
    cprintf("[Buddy 3] rounded allocation and original-size free: PASS\n");
}

static void
buddy_test_split(void) {
    buddy_test_reset();
    buddy_init_memmap(pages, 16);
    struct Page *blocks[16];
    blocks[0] = buddy_alloc_pages(1);
    assert(blocks[0] == pages);
    /* Splitting a 16-page block leaves exactly 1, 2, 4 and 8-page tails. */
    for (unsigned int k = 0; k < 4; k ++) {
        struct Page *tail = pages + buddy_block_size(k);
        assert(PageProperty(tail) && tail->property == buddy_block_size(k));
        assert(list_next(&free_lists[k]) == &tail->page_link);
        assert(list_next(&tail->page_link) == &free_lists[k]);
    }
    buddy_check_state();
    uint64_t seen = 1;
    for (size_t i = 1; i < 16; i ++) {
        blocks[i] = buddy_alloc_pages(1);
        buddy_test_allocation(blocks[i], 1);
        size_t index = buddy_page_index(blocks[i]);
        assert(index < 16 && !(seen & ((uint64_t)1 << index)));
        seen |= (uint64_t)1 << index;
        buddy_check_state();
    }
    assert(seen == 0xffff && nr_free == 0);
    buddy_test_failure(1);
    for (size_t i = 16; i > 0; i --) {
        buddy_free_pages(blocks[i - 1], 1);
        buddy_check_state();
    }
    assert(nr_free == 16 && pages[0].property == 16);
    cprintf("[Buddy 4] multi-level split and reuse of every tail: PASS\n");
}

static void
buddy_test_merge(void) {
    buddy_test_reset();
    buddy_init_memmap(pages, 8);
    struct Page *blocks[8];
    unsigned int seen = 0;
    for (size_t i = 0; i < 8; i ++) {
        struct Page *p = buddy_alloc_pages(1);
        buddy_test_allocation(p, 1);
        size_t index = buddy_page_index(p);
        assert(index < 8 && !(seen & (1U << index)));
        seen |= 1U << index;
        blocks[index] = p;
    }
    assert(seen == 0xff);
    /* Pages 1 and 2 are adjacent but have different buddies (0 and 3). */
    buddy_free_pages(blocks[1], 1);
    buddy_free_pages(blocks[2], 1);
    assert(nr_free == 2 && pages[1].property == 1 && pages[2].property == 1);
    buddy_check_state();
    buddy_test_failure(2);
    buddy_free_pages(blocks[0], 1);
    assert(pages[0].property == 2);
    struct Page *pair = buddy_alloc_pages(2);
    assert(pair == pages && nr_free == 1);
    buddy_free_pages(pair, 2);
    buddy_free_pages(blocks[3], 1);
    assert(pages[0].property == 4 && nr_free == 4);
    buddy_check_state();
    const unsigned int release_order[] = {4, 6, 5, 7};
    for (size_t i = 0; i < 4; i ++) {
        buddy_free_pages(blocks[release_order[i]], 1);
        buddy_check_state();
    }
    assert(nr_free == 8 && pages[0].property == 8);
    struct Page *whole = buddy_alloc_pages(8);
    assert(whole == pages && nr_free == 0);
    buddy_free_pages(whole, 8);
    cprintf("[Buddy 5] true buddies, non-buddies and recursive merge: PASS\n");
}

static void
buddy_test_failures(void) {
    buddy_test_reset();
    buddy_test_failure(1);
    buddy_init_memmap(pages, 16);
    buddy_test_failure(17);
    struct Page *p = buddy_alloc_pages(3);
    assert(buddy_test_allocation(p, 3) == 4);
    buddy_test_failure(16);
    buddy_test_failure(buddy_block_size(BUDDY_MAX_ORDER) + 1);
    buddy_test_failure((size_t)-1);
    assert(p->property == 3 && (p->flags & BUDDY_ALLOC_HEAD));
    buddy_free_pages(p, 3);
    assert(nr_free == 16);
    cprintf("[Buddy 6] allocation failures preserve all state: PASS\n");
}

static void
buddy_test_rounds(void) {
    buddy_test_reset();
    buddy_init_memmap(pages, BUDDY_TEST_PAGES);
    struct Page *slots[8] = {NULL};
    size_t requests[8] = {0}, lengths[8] = {0};
    uint32_t seed = 0x2026;
    for (size_t step = 0; step < 128; step ++) {
        seed = seed * 1664525U + 1013904223U;
        size_t slot = (seed >> 16) % 8;
        if (slots[slot] != NULL) {
            buddy_free_pages(slots[slot], requests[slot]);
            slots[slot] = NULL;
        } else {
            size_t request = 1 + (seed >> 8) % 9;
            uint64_t before = buddy_test_fingerprint();
            slots[slot] = buddy_alloc_pages(request);
            if (slots[slot] != NULL) {
                requests[slot] = request;
                lengths[slot] = buddy_test_allocation(slots[slot], request);
            } else {
                assert(buddy_test_fingerprint() == before);
            }
        }
        size_t used = 0;
        for (size_t i = 0; i < 8; i ++) {
            if (slots[i] == NULL) {
                continue;
            }
            used += buddy_test_allocation(slots[i], requests[i]);
            for (size_t j = 0; j < i; j ++) {
                if (slots[j] != NULL) {
                    buddy_test_disjoint(slots[i], lengths[i], slots[j], lengths[j]);
                }
            }
        }
        assert(nr_free == BUDDY_TEST_PAGES - used);
        buddy_check_state();
    }
    for (size_t i = 0; i < 8; i ++) {
        if (slots[i] != NULL) {
            buddy_free_pages(slots[i], requests[i]);
            buddy_check_state();
        }
    }
    assert(nr_free == BUDDY_TEST_PAGES);
    struct Page *whole = buddy_alloc_pages(BUDDY_TEST_PAGES);
    assert(whole == pages && nr_free == 0);
    buddy_free_pages(whole, BUDDY_TEST_PAGES);
    buddy_check_state();
    cprintf("[Buddy 8] 128 reproducible operations and full recovery: PASS\n");
}

static void
buddy_test_data(void) {
    size_t before = nr_free_pages();
    const size_t requests[] = {1, 3, 5}, lengths[] = {1, 4, 8};
    struct Page *blocks[3];
    volatile uint8_t *buffers[3];
    size_t used = 0;
    for (size_t i = 0; i < 3; i ++) {
        blocks[i] = alloc_pages(requests[i]);
        assert(buddy_test_allocation(blocks[i], requests[i]) == lengths[i]);
        for (size_t j = 0; j < i; j ++) {
            buddy_test_disjoint(blocks[i], lengths[i], blocks[j], lengths[j]);
        }
        uintptr_t pa = page2pa(blocks[i]);
        buffers[i] = (volatile uint8_t *)(pa + va_pa_offset);
        assert(pa >= KERNEL_BEGIN_PADDR && PADDR(buffers[i]) == pa);
        used += lengths[i];
        assert(nr_free_pages() == before - used);
        for (size_t byte = 0; byte < lengths[i] * PGSIZE; byte ++) {
            buffers[i][byte] = (uint8_t)(i * 73 + byte);
        }
        buddy_check_state();
    }
    /* Verify after ALL writes, including each rounded allocation's tail. */
    for (size_t i = 0; i < 3; i ++) {
        for (size_t byte = 0; byte < lengths[i] * PGSIZE; byte ++) {
            assert(buffers[i][byte] == (uint8_t)(i * 73 + byte));
        }
    }
    for (size_t i = 3; i > 0; i --) {
        free_pages(blocks[i - 1], requests[i - 1]);
        buddy_check_state();
    }
    assert(nr_free_pages() == before);
    cprintf("[Buddy 7] real-page data isolation and rounded tails: PASS\n");
}

#ifdef BUDDY_NEGATIVE_TEST
/* Each case runs in its own QEMU boot and MUST panic, never report PASS. */
static void
buddy_test_negative(void) {
    buddy_test_reset();
    buddy_init_memmap(pages, 16);
    struct Page *p = buddy_alloc_pages(3);
    assert(p != NULL);
    cprintf("[Buddy negative %d] EXPECT ASSERT\n", BUDDY_NEGATIVE_TEST);
    switch (BUDDY_NEGATIVE_TEST) {
    case 1: buddy_free_pages(p, 3); buddy_free_pages(p, 3); break;
    case 2: buddy_free_pages(p, 1); break;
    case 3: buddy_free_pages(p, 4); break;
    case 4: buddy_free_pages(p + 1, 1); break;
    case 5: buddy_alloc_pages(0); break;
    case 6: buddy_free_pages(pages + 63, 1); break;
    case 7: buddy_free_pages(pages + BUDDY_TEST_PAGES, 1); break;
    default: panic("unknown BUDDY_NEGATIVE_TEST");
    }
    panic("Buddy negative test FAILED: invalid operation was accepted");
}
#endif

static void
buddy_check(void) {
    buddy_check_state();
    /* Save every order root and both counters. Live descriptor nodes are not
     * touched while globals point at the synthetic descriptor array; restore
     * the original roots at their original addresses before using them again.
     */
    struct Page *saved_pages = pages;
    size_t saved_npage = npage, saved_free = nr_free, saved_managed = nr_managed;
    uint64_t saved_fingerprint = buddy_test_fingerprint();
    list_entry_t saved_lists[BUDDY_MAX_ORDER + 1];
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
        saved_lists[k] = free_lists[k];
    }
    pages = buddy_test_pages;
    npage = nbase + BUDDY_TEST_PAGES;
#ifdef BUDDY_NEGATIVE_TEST
    buddy_test_negative();
#endif
    buddy_test_registration();
    buddy_test_basic();
    buddy_test_rounding();
    buddy_test_split();
    buddy_test_merge();
    buddy_test_failures();
    buddy_test_rounds();
    assert(nr_free == nr_managed);

    pages = saved_pages;
    npage = saved_npage;
    nr_free = saved_free;
    nr_managed = saved_managed;
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
        free_lists[k] = saved_lists[k];
    }
    assert(buddy_test_fingerprint() == saved_fingerprint);
    buddy_check_state();
    buddy_test_data();
    assert(nr_free_pages() == saved_free && nr_managed == saved_managed);
    buddy_check_state();
    struct Page *again = alloc_pages(1);
    assert(again != NULL);
    free_pages(again, 1);
    assert(nr_free_pages() == saved_free);
    buddy_check_state();
    cprintf("buddy_check: all 8 groups passed; live allocator restored\n");
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
