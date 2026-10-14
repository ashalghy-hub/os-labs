#include <pmm.h>
#include <list.h>
#include <best_fit_pmm.h>
#include <stdio.h>

//lab2 function2-2 YOUR CODE
/* SKELETON FIX: the skeleton's basic_check/best_fit_check use
 * free_list/nr_free and grade's Test 2 references best_fit_pmm_manager,
 * but the skeleton defines none of them, so the tree does not even
 * compile/link before Test 1 (page_init) can run.
 * Provide minimal definitions here only to unblock the build.
 * TODO: full best-fit allocator (init/init_memmap/alloc/free/check)
 * is Exercise 2 and is intentionally left as stubs. */
/* The comment above records the Task 1 skeleton state. Exercise 2 is now
 * implemented below; original TODO comments are retained as task markers. */
static free_area_t free_area;
#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void best_fit_init(void); // TODO: Exercise 2
static void best_fit_init_memmap(struct Page *base, size_t n); // TODO: Exercise 2
static struct Page *best_fit_alloc_pages(size_t n); // TODO: Exercise 2
static void best_fit_free_pages(struct Page *base, size_t n); // TODO: Exercise 2
static size_t best_fit_nr_free_pages(void); // TODO: Exercise 2
static void best_fit_check(void);

// Keep blocks ordered by address and merge both adjacent neighbors.
static void
best_fit_insert_block(struct Page *base, size_t n) {
    // 1. find the insertion position in the address-ordered free list.
    // Adjacent Page descriptors represent adjacent physical pages.
    list_entry_t *next = list_next(&free_list);
    while (next != &free_list && le2page(next, page_link) < base) {
        next = list_next(next);
    }
    list_entry_t *prev = list_prev(next);
    // 2. check that the new range does not overlap either neighboring block.
    if (prev != &free_list) {
        struct Page *p = le2page(prev, page_link);
        assert(p + p->property <= base);
    }
    if (next != &free_list) {
        assert(base + n <= le2page(next, page_link));
    }

    // 3. register the block head and count only the newly added pages.
    base->property = n;
    SetPageProperty(base);
    list_add_before(next, &base->page_link);
    nr_free += n;

    // 4. merge with the preceding block if their physical ranges are adjacent.
    // Its head remains valid; base becomes an interior page of the merged block.
    if (prev != &free_list) {
        struct Page *p = le2page(prev, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            base->property = 0;
            list_del(&base->page_link);
            base = p;
        }
    }
    // 5. merge with the following block, using the updated head after step 4.
    // Coalescing changes block boundaries, so nr_free must not increase again.
    if (next != &free_list) {
        struct Page *p = le2page(next, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            p->property = 0;
            list_del(&p->page_link);
        }
    }
}

static void
best_fit_init(void) {
    // 1. initialize manager state before page_init() registers free memory.
    list_init(&free_list);
    nr_free = 0;
}

static void
best_fit_init_memmap(struct Page *base, size_t n) {
    // TODO(Exercise 2): implement best-fit init_memmap
    // 1. validate the whole range before changing any page state.
    // page_init() leaves these descriptors Reserved until registration.
    assert(n > 0);
    for (struct Page *p = base; p != base + n; p ++) {
        assert(PageReserved(p));
    }
    // 2. make the pages available and reset block metadata and references.
    for (struct Page *p = base; p != base + n; p ++) {
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    // 3. insert by address and coalesce with any adjacent registered blocks.
    best_fit_insert_block(base, n);
}

static struct Page *
best_fit_alloc_pages(size_t n) {
    // TODO(Exercise 2): implement best-fit alloc
    // 1. reject an empty request and return NULL if total free pages are insufficient.
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    // 2. choose the smallest block whose length is at least n.
    // Strictly smaller replacements preserve the lowest-address choice on ties.
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n &&
            (page == NULL || p->property < page->property)) {
            page = p;
            if (p->property == n) {
                // An exact match is optimal; later blocks cannot improve it.
                break;
            }
        }
    }
    // 3. remove the selected block and clear its free-block head metadata.
    // If no contiguous block fits, leave all state unchanged and return NULL.
    if (page != NULL) {
        size_t remaining = page->property - n;
        list_entry_t *prev = list_prev(&page->page_link);
        list_del(&page->page_link);
        ClearPageProperty(page);
        page->property = 0;
        // 4. allocate from the low-address end and retain the remaining free tail.
        // Reuse the old list position to preserve address order.
        if (remaining > 0) {
            struct Page *p = page + n;
            p->property = remaining;
            SetPageProperty(p);
            list_add(prev, &p->page_link);
        }
        // 5. deduct exactly the requested pages, not the original block length.
        nr_free -= n;
    }
    return page;
}

static void
best_fit_free_pages(struct Page *base, size_t n) {
    // TODO(Exercise 2): implement best-fit free
    // 1. check every page before resetting flags or reference counts.
    // Reserved pages and existing free-block heads cannot be released here.
    assert(n > 0);
    for (struct Page *p = base; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
    }
    // 2. reset the returned pages; only the eventual block head has a property.
    for (struct Page *p = base; p != base + n; p ++) {
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    // 3. register the returned range and merge with both adjacent free blocks.
    best_fit_insert_block(base, n);
}

static size_t
best_fit_nr_free_pages(void) {
    // Return the number of free pages, rather than the number of free blocks.
    return nr_free;
}

// Register the allocator operations; retain the framework's existing check.
const struct pmm_manager best_fit_pmm_manager = {
    .name = "best_fit_pmm_manager",
    .init = best_fit_init,
    .init_memmap = best_fit_init_memmap,
    .alloc_pages = best_fit_alloc_pages,
    .free_pages = best_fit_free_pages,
    .nr_free_pages = best_fit_nr_free_pages,
    .check = best_fit_check,
};

// Framework tests: students must not modify basic_check or best_fit_check.
static void
basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    free_page(p0);
    assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    free_list = free_list_store;
    nr_free = nr_free_store;

    free_page(p);
    free_page(p1);
    free_page(p2);
}

static void
best_fit_check(void) {
    int score = 0, sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count++, total += p->property;
    }
    assert(total == nr_free_pages());

    basic_check();

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
    free_pages(p0 + 4, 1);
    assert(alloc_pages(4) == NULL);
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
    assert(alloc_pages(2) != NULL);
    assert(p0 + 4 == p1);

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    assert(nr_free == 0);
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
}
