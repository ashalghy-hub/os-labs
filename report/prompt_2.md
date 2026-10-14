```text
[PROMPT]
要求：实现Best-Fit连续物理内存分配算法，完成空闲页初始化、连续页分配、页面回收和相邻空闲块合并。
完成Best-Fit模块后，在kern/mm/pmm.c的init_pmm_manager()中将当前物理内存管理器切换为best_fit_pmm_manager。
目标位置：code/kern/mm/best_fit_pmm.c文件中标有lab2和YOUR CODE的位置；code/kern/mm/pmm.c中的init_pmm_manager()。
操作要求：必须在项目中修改实际文件，不能只输出代码片段。当前Best-Fit文件已有内部状态、函数声明和注册结构，但部分函数仍是触发断言的占位实现，需要在现有基础上补全。
保留已有page_init()、First-Fit实现及其他无关逻辑，不得修改要求之外的任何位置，不得修改basic_check()、best_fit_check()和tools中的测试、评分逻辑，也不得硬编码测试结果。
测试环境：WSL的Ubuntu-20.04，运行目录为/home/ddn/work/lab2/code，对应本机Windows路径\\wsl.localhost\Ubuntu-20.04\home\ddn\work\lab2\code。
同步要求：本项目D:\work\os-labs\code与上述WSL目录中的源码要同步修改，在WSL目录中测试成功通过后再完整同步测试文件。
输出要求：使用下面[RELY]、[GUARANTEE]、[SPECIFICATION]中的信息，以工程真实代码为准。完成后简要说明修改内容、Best-Fit选择规则、编译和测试结果，以及算法是否还有改进空间。无法运行的检查应说明原因，不能写成已经通过。
代码要求：保证风格一致，注释适当添加与调整（可仿照page_init()注释形式）。

[RELY]
直接复用任务一完成的page_init()及现有分配接口，不需要重新实现内存探测、描述符布局和地址转换。page_init()会将可用页面以Reserved状态交给当前管理器的init_memmap()。
参考code/kern/mm/default_pmm.c中的完整First-Fit实现；接口、页面结构和链表操作分别以pmm.h、memlayout.h、libs/list.h中的真实定义为准。
页面结构的关键字段：ref为引用计数，flags保存页面标志，property记录空闲块首页面的连续页数，page_link连接空闲块首页面；相邻Page描述符对应相邻物理页。
PageReserved表示保留页，PageProperty表示空闲块首页面；可复用对应状态宏、set_page_ref()、le2page()和现有链表函数。
best_fit_pmm.h已声明best_fit_pmm_manager；现有测试会直接保存、清空和恢复free_list及nr_free，不能依赖测试不会同步维护的额外状态。

[GUARANTEE]
必须实现或补全以下接口（已经有TODO标记），定义位置为code/kern/mm/best_fit_pmm.c：
    static void best_fit_init(void);
    static void best_fit_init_memmap(struct Page *base, size_t n);
    static struct Page *best_fit_alloc_pages(size_t n);
    static void best_fit_free_pages(struct Page *base, size_t n);
    static size_t best_fit_nr_free_pages(void);

必须保留并正确配置const struct pmm_manager best_fit_pmm_manager，将上述接口及已有best_fit_check()注册到对应成员，name为"best_fit_pmm_manager"。
必须修改code/kern/mm/pmm.c中的static void init_pmm_manager(void)，使其选择并初始化best_fit_pmm_manager。
可以添加仅供本模块使用的static辅助函数、内部宏和静态变量，但不得修改公开接口、Page结构或既有测试函数。
必须通过basic_check()和best_fit_check()，并使注入测试输出[Test 1] Page Init: PASS和[Test 2] Best-Fit: PASS。


[SPECIFICATION]
共同状态约束：
- free_list按物理地址递增排列，只包含互不重叠的空闲块首页面；首页面设置PageProperty并记录块长度，其余页面不设置该标志。
- 空闲页面不设置PageReserved，引用计数为0；已分配页面不在空闲区中，nr_free等于空闲页总数。
- 注册或回收页面后合并相邻空闲块，合并不额外增加空闲页数。

best_fit_init(void)
Pre-Condition：在注册空闲区和分配页面之前调用。
Post-Condition：空闲链表为空，nr_free为0，可以接收空闲区注册。

best_fit_init_memmap(struct Page *base, size_t n)
Pre-Condition：管理器已初始化，n > 0，范围内页面有效、连续、尚未注册且均为Reserved。
Post-Condition：该范围成为空闲区，nr_free增加n，其他页面状态不变，共同状态约束成立。

best_fit_alloc_pages(size_t n)
Pre-Condition：管理器已初始化，n > 0，共同状态约束成立。
Post-Condition：成功时返回恰好n个连续页的首描述符，nr_free减少n；失败时返回NULL，管理器和页面状态不变。
Case 1：有满足请求的块时，选择长度不小于n的最小块；长度相同时选择物理地址较小的块。恰好匹配时分配整个块，否则分配低地址端n页，剩余部分保留为空闲块。
Case 2：链表为空、总页数不足或没有足够大的连续块时返回NULL，不能拼接不相邻的块。

best_fit_free_pages(struct Page *base, size_t n)
Pre-Condition：管理器已初始化，n > 0，范围内页面有效、连续且已分配，不含Reserved页面或已有空闲页面。
Post-Condition：页面回到空闲区，nr_free增加n；与前后相邻块合并，清除失效块首标志和链表节点，共同状态约束成立。
Requirements：允许释放原分配范围中的合法连续子区间，不要求按分配顺序释放；调用者不得重复释放。

best_fit_nr_free_pages(void)
Pre-Condition：管理器已初始化，共同状态约束成立。
Post-Condition：返回nr_free，不改变状态；无空闲页时返回0。

init_pmm_manager(void)
Pre-Condition：由pmm_init()调用，先于page_init()。
Post-Condition：选择并初始化best_fit_pmm_manager，保留名称输出，后续分配、释放和检查均使用Best-Fit接口。

Requirements：分配器对n为0、注册非Reserved页面、回收Reserved页面或已有空闲块首页面等可检测的参数错误使用assert()终止；不得分配保留页或已分配页。算法时空复杂度不做要求。

验证要求：
- 同步源码后，在WSL的/home/ddn/work/lab2/code下编译和运行，工具链已经准备好，确认已有检查完成，并输出check_alloc_page() succeeded!。
- 使用make grade，或在临时副本中通过tools/inject.py注入测试后运行，确认两个测试均为PASS；记录实际命令和结果。
- 测试未执行时说明原因，不得记为通过。
- 完成后给出测试方法供手动测试。
```

## 测试方法以及预期结果（报告与测试中使用，之后需删除）

测试环境为WSL的Ubuntu-22.04，以下命令在WSL终端中执行。测试前确认本地code与/home/ddn/work/lab2/code中的源码一致。

### 1. 编译并运行已有检查

```bash
make -B -j2
timeout 8s qemu-system-riscv64 -machine virt -nographic -bios default -kernel bin/ucore.img
```

make -B用于完整重编译，避免旧构建产物影响结果。预期编译无错误，内核使用Best-Fit管理器，basic_check()和best_fit_check()中的断言均通过，关键输出为：

```text
memory management: best_fit_pmm_manager
check_alloc_page() succeeded!
```

内核最后会进入无限循环，因此timeout结束QEMU属于正常停止，不能只根据进程退出码判断测试失败，应检查上述输出及是否出现断言失败或panic。本机测试使用-kernel启动，原Makefile中的-device loader方式存在启动兼容性问题，本任务未修改启动和评分脚本。

### 2. 在临时副本中运行注入测试

```bash
test_dir=$(mktemp -d /tmp/lab2-task2.XXXXXX)
cp -a kern libs tools Makefile "$test_dir/"
python3 tools/inject.py "$test_dir"
make -C "$test_dir" -j2 DEFS=-Ducore_test
timeout 8s qemu-system-riscv64 -machine virt -nographic -bios default -kernel "$test_dir/bin/ucore.img"
```

临时目录只复制源码和构建配置，不复制obj、bin；注入操作也只作用于副本。DEFS=-Ducore_test用于显示已有Best-Fit检查的评分进度。预期关键输出为：

```text
grading: 6 / 6 points
check_alloc_page() succeeded!
[Test 1] Page Init: PASS
[Test 2] Best-Fit: PASS
```

上述结果已在本次测试中得到。其中Test 2检查是否接入best_fit_pmm_manager，具体分配行为由之前执行的basic_check()和best_fit_check()验证，不能只根据Test 2的PASS判断算法正确。

## 问题回答：你的Best-Fit算法是否有进一步的改进空间？（这是之后在实验报告中需要的，后面要迁移）

### 当前实现

当前实现用按物理地址排序的双向链表管理空闲块，每个块只把首页面放入链表。property记录该块的连续页数，PageProperty标记块首，nr_free记录全部空闲页的总数。

申请n页时，查找所有足够大的块，选择其中最小的一个；大小相同时选择地址较低的块。例如有8页、5页、3页三个空闲块，申请4页时选择5页块，分配前4页，剩下1页继续保留为空闲块。若申请5页，则使用整个5页块；找到恰好匹配的块时可以提前结束查找。

释放页面时按地址插回链表，如果与前后空闲块连续，就合并成更大的空闲块。设空闲块数为F，分配查找的最坏时间复杂度为O(F)；释放n页时，还要处理这些页面的状态，复杂度为O(n + F)。

### 改进空间

有进一步的改进空间，主要有两点：

- 提高查找效率。当前最坏需要遍历所有空闲块，可以增加按块大小和地址排序的平衡树，将查找降为O(log F)。但拆分、合并时必须同步维护索引，还要兼容现有测试直接恢复链表状态的约定。
- 加强非法操作检查，强化代码健壮性。当前已有页面状态和重叠断言，还可以在修改页面状态前检查范围是否越界、是否重复释放，使错误更容易定位。

此外，Best-Fit只让本次分配剩下的空间尽量小，不保证长期运行后的碎片最少。当前相邻块合并能减少部分外部碎片，但无法合并被已分配页面隔开的空闲块。
