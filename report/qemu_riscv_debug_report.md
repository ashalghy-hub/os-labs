# QEMU RISC-V 虚拟地址翻译与 TCG SoftTLB 调试报告

**环境：** Fedora 43 / AArch64 Host；QEMU 10.1.5（RISC-V system emulation，TCG）；RISC-V 64-bit `virt` Guest

## 一、实验目标

本次实验探究 **QEMU 在执行 RISC-V Guest 指令时，如何根据 Guest 的页表、权限状态与物理地址空间完成访存**。核心问题是：一次 Guest 访存为何会进入 `get_physical_address()`；哪些调用来自真实的 Guest 执行，哪些来自调试器；成功翻译后为什么还要操作 QEMU SoftTLB；MMIO 又如何区别于普通 RAM。

应严格区分四个对象：

1. **Guest Virtual Address（GVA）**：Guest 指令或 Guest GDB 给出的 RISC-V 虚拟地址。
2. **Guest Physical Address（GPA）**：RISC-V 地址翻译得到的物理地址；无二阶段翻译时可视为本实验中的最终 Guest 物理地址。
3. **QEMU SoftTLB**：TCG 的软件访存加速缓存，记录翻译结果和 RAM/MMIO 等访问属性；它不是硬件 TLB 的逐项模拟。
4. **Host Virtual Address（HVA）**：Host 进程访问其内存时使用的地址。Guest RAM 通常可关联到 HVA；MMIO 需要转交设备模型，不能简单当作 Host 内存指针解引用。

实验采用两个不同层次的 GDB：**Host GDB attach 到 `qemu-system-riscv64` 进程调试 QEMU C 代码；Guest GDB 通过 QEMU gdbstub 调试 RISC-V Guest**。两者同时存在会产生调试器触发的内存翻译，必须区分证据来源。

## 二、环境搭建与调试命令

### 2.1 宿主进程调试

调试中 Host GDB 附加至 QEMU 进程；最初曾停在 glibc 的 `__syscall_cancel_arch()`，并显示若干 Fedora 43 `*-debuginfo` 缺失提示。

```bash
# Host shell：找到 QEMU，检查是否是期望的进程
pgrep -af qemu-system-riscv64

# Host shell：附加；替换成上一步确认的 PID
sudo gdb -q -p <QEMU_PID>
```

### 2.2 双 GDB 复现实验：补充的模板

```bash
# 终端 A：QEMU（-s 打开 1234 端口 gdbstub；-S 在 Guest 启动前暂停）
make debug

# 终端 B：Guest GDB（调试 RISC-V 代码，不是 QEMU Host C 代码）
make gdb

# 终端 C：Host GDB（调试 QEMU 内部执行流程）
sudo gdb -q -p <QEMU_PID>
(gdb) set pagination off
(gdb) set print pretty on
(gdb) info threads
(gdb) thread apply all bt 5
```

若无需从启动首条指令开始观察，可省略 `-S`，只保留 `-s`。Guest GDB 操作 Guest 内存时会经 gdbstub 进入 QEMU 地址翻译调试路径，与正常执行路径不同。

### 2.3 主要 Host GDB 断点与观察指令

以下断点是明确涉及或为后续复现整理的命令。

```gdb
break riscv_cpu_tlb_fill
break get_physical_address
break get_physical_address if !is_debug
break get_physical_address_pmp
break tlb_set_page_full
break helper_tlb_flush

info breakpoints
disable breakpoints
# 按需要重新启用某个断点，例如 enable 2
continue
```

注意：`tlb_set_page_full` 是此前建议关注的 **TCG 通用填充实现**；RISC-V 目标代码可调用 `tlb_set_page` 包装路径，不应在未抓到该断点时声称已经观察到它执行。`helper_tlb_flush` 及特定符号是否存在应以当前 QEMU 构建的 `info functions` 或 `nm` 为准。

## 三、实测调用栈 A：Guest GDB 读取内存触发的调试翻译

第一组调用栈命中：

```text
#0 get_physical_address(
       addr=18446744072637906944,
       mmu_idx=1,
       first_stage=true, two_stage=false,
       is_debug=true, is_probe=false)
   at ../target/riscv/cpu_helper.c:1192
#1 riscv_cpu_get_phys_page_debug(...)
   at ../target/riscv/cpu_helper.c:1667
#2 cpu_get_phys_page_attrs_debug(...)
#3 cpu_memory_rw_debug(...)
#4 handle_read_mem(...)
#5 process_string_cmd("mffffffffc02000c0,40")
... gdbstub 的包处理、Socket/GLib 事件循环 ...
... main
```

关键数据：

- `18446744072637906944` = **`0xffffffffc0200000`**。
- gdbstub RSP 请求 `mffffffffc02000c0,40` 表示从 **`0xffffffffc02000c0` 读取 `0x40=64` 字节**。
- `cpu_memory_rw_debug()` **先将地址按 Guest 页边界对齐**，以取得物理页基址，再加回原页内偏移 `0xc0`。所以请求地址与 `get_physical_address()` 参数差 `0xc0` 是正常现象。
- `is_debug=true` 且调用链包含 `handle_read_mem()`，足以判定这次命中是 **Guest GDB 通过 gdbstub 主动读内存**，不是 Guest CPU 正在执行一条 load，也不能作为 TCG SoftTLB miss 的证据。
- `mmu_idx=1` 对应 S-mode 的有效 MMU 上下文（以此版常规索引定义为前提），表示这次调试读取需要按 Guest 当前的监督态内存翻译语义解释；是否实际遍历页表还取决于 `satp` 等状态。

为区分调试器触发与真实 Guest 执行，使用：

```gdb
# Host GDB
break get_physical_address if !is_debug
break riscv_cpu_tlb_fill
info threads
thread apply all bt 5
continue

# 只有想重现 RSP 读内存时，在 Guest GDB 发起下面的操作：
x/64bx 0xffffffffc02000c0
```

`x/64bx` 是复现上述访问意图的命令；**不能反推它就是原始记录中 Guest GDB 实际输入的精确命令**。GDB 发送的数据包分片大小也可能与显示命令不同。

## 四、实测调用栈 B：Guest 运行中经 TCG SoftTLB miss 进入地址翻译

第二组调用栈：

```text
get_physical_address(
  addr=2147760656,  # 0x80043a10
  mmu_idx=3,
  first_stage=true, two_stage=false,
  is_debug=false, is_probe=false)
  <- riscv_cpu_tlb_fill
  <- tlb_fill_align
  <- mmu_lookup1
  <- mmu_lookup
  <- do_ld8_mmu
  <- code_gen_buffer
  <- cpu_tb_exec
  <- cpu_exec_loop
  <- tcg_cpu_exec
  <- mttcg_cpu_thread_fn
  <- qemu_thread_start
  <- start_thread
  <- thread_start
```

这一次的 `is_debug=false`，且栈底来自 QEMU TCG vCPU 执行线程。它表示 Guest 指令产生的 **8 字节读访问** 进入 C helper 的慢路径，在 `mmu_lookup1` 中未获得可直接使用的 SoftTLB 命中，继而触发目标架构的 `riscv_cpu_tlb_fill()` 和地址翻译。

但它**不等于已经观察到 Sv39 页表遍历**：`mmu_idx=3` 对应有效 M-mode 内存上下文；在该模式下（未由 MPRV 改成 S/U 有效权限），`get_physical_address()` 可以直接返回 `physical=addr`，跳过 `satp` 页表 walk。此后 QEMU 仍然需要做 PMP 检查以及 SoftTLB 填充。地址 `0x80043a10` 处于 `virt` 机型 DRAM 起始地址 `0x80000000` 之后，符合启动期间访问 RAM 的情形，但栈本身没有说明读到了什么数据。

## 五、实测调用栈 C：访问 UART MMIO 的 1 字节读取

第三组调用栈最具辨识度：

```text
#0 get_physical_address(
     addr=268435461,  # 0x10000005
     mmu_idx=3, first_stage=true, two_stage=false,
     is_debug=false, is_probe=false)
...
riscv_cpu_tlb_fill
  <- tlb_fill_align
  <- mmu_lookup1
  <- mmu_lookup
  <- do_ld1_mmu
  <- helper_ldub_mmu
  <- code_gen_buffer
  <- cpu_tb_exec
  <- cpu_loop_exec_tb
  <- cpu_exec_loop
  <- cpu_exec_setjmp
  <- cpu_exec
  <- tcg_cpu_exec
  <- mttcg_cpu_thread_fn
  <- qemu_thread_start
  <- start_thread
  <- thread_start
```

地址 `0x10000005 = 0x10000000 + 5`。在 QEMU RISC-V `virt` 机器上，`0x10000000` 为 **UART0（NS16550 兼容）** 的 MMIO 基址，偏移 5 是 **Line Status Register（LSR）**。`helper_ldub_mmu` / `do_ld1_mmu` 说明这条路径在执行 **1 字节加载**。这是软件模拟串口、轮询设备状态时非常典型的访问。

此处至少分成三个独立动作：

1. Guest 给出地址 `0x10000005`；有效 M-mode 下架构地址翻译可直接得到同值物理地址，并执行必要 PMP 检查。
2. QEMU 的 SoftTLB / 内存子系统判定它属于 IO `MemoryRegion`，而不是普通 Guest RAM 快速映射。
3. 最终访问需要由 UART 设备模型执行 `read` 回调（具体函数名与实际版本/配置有关）。**已有栈只直接证实到地址翻译及 1 字节加载路径；设备回调的具体帧尚未在原记录中抓到。**

可补抓 MMIO 分派链：

```gdb
break memory_region_dispatch_read
break serial_ioport_read
# 若以上符号不可见，先执行：
info functions memory_region_dispatch_read
info functions serial_ioport_read
continue
bt 16
p/x addr
```

以上两个断点为后续验证用，不属于已经确认命中的断点。不同版本、内联及设备模型实现会影响能否按函数名命中。

## 六、`get_physical_address_pmp()` 的位置与意义

最初关注的 `get_physical_address()` 解决“GVA 到 GPA 是否需要页表转换、如何转换”的问题；但 **`get_physical_address_pmp()` 解决的是 Guest 物理地址权限（PMP）检查**，两者职责不同。

PMP 在本流程中至少有两个值得区分的位置：

- **页表遍历期间**：当 S/U 模式启用分页，QEMU 需要读取页表项（PTE）；对应 PTE 的物理地址访问也可能要经过 PMP 权限检查。
- **目标访存地址翻译完成后**：`riscv_cpu_tlb_fill()` 获取最终物理地址之后，对该次 load/store/fetch 的 PMP 权限和可缓存的 TLB 页粒度进行处理。即使 M-mode 访存没有 Sv39 页表 walk，也不能据此认为 PMP 逻辑一定不会执行。

不能把这两类 PMP 检查混同；还应注意 **debug 专用入口不完全等同于正常 TCG 访存入口**。

建议断点与状态检查：

```gdb
break get_physical_address_pmp
break get_physical_address if !is_debug
break riscv_cpu_tlb_fill
continue

# 进入 PMP 断点后
bt 12
p/x addr
p size
p access_type
p mode
p/x env->pmp_state
```

最后一条结构字段可能随 QEMU 版本变化；如 GDB 报无此成员，应查看 `ptype *env` / `ptype CPURISCVState`、`list`，不要把字段名当成已验证的稳定接口。先看 `bt` 才能区分当前 PMP 是在 PTE walk 内发生，还是翻译完成后的最终地址权限检查。

## 七、`code_gen_buffer()` 为什么没有 C 源码

第三次调试记录直接看到：

```text
#7  0x0000ffff5cd6ed44 in code_gen_buffer ()
#8  0x0000aaaaba90b7d8 in cpu_tb_exec (
       cpu=0xaaaada533820,
       itb=0xffff5cd6ec00 <code_gen_buffer+27572>,
       tb_exit=0xffff549fdafc)
    at ../accel/tcg/cpu-exec.c:438
```

`code_gen_buffer` 不是一个普通的 C 函数源码文件；它是 **QEMU TCG JIT 生成的 Host 机器码区域**。此处 Host 是 AArch64，而 Guest 指令集是 RISC-V。`cpu_tb_exec()` 跳入翻译块（Translation Block，TB），TB 中的 Host 指令在必要时调用 `helper_ldub_mmu` 等 C helper。因此回溯能够跨越 **生成的机器码帧** 和 **QEMU C helper 帧**，但无法对 JIT 区域直接 `list` 出一份对应的 C 函数源代码。

```gdb
# Host GDB；观察当前停点周围的 Host AArch64 指令
frame 7
p/x $pc
x/16i $pc
disassemble /r $pc-32, $pc+96
info symbol $pc

# 返回 C 侧代码帧，查看 TB 的执行位置
frame 8
list
p/x itb
bt 12
```

`-d in_asm,op,op_opt,out_asm` 可在 QEMU 启动时输出 Guest 反汇编、TCG IR 和 Host 生成指令（具体项用 `qemu-system-riscv64 -d help` 核实），用于关联 Guest 指令和 Host 代码；开启后会产生大量日志，建议短时实验。


# 八、 实际physical address获取

```c
static int get_physical_address(CPURISCVState *env, hwaddr *physical,
                                int *ret_prot, vaddr addr,
                                target_ulong *fault_pte_addr,
                                int access_type, int mmu_idx,
                                bool first_stage, bool two_stage,
                                bool is_debug, bool is_probe)
{
    /*
     * NOTE: the env->pc value visible here will not be
     * correct, but the value visible to the exception handler
     * (riscv_cpu_do_interrupt) is correct
     */
    MemTxResult res;
    MemTxAttrs attrs = MEMTXATTRS_UNSPECIFIED;
    int mode = mmuidx_priv(mmu_idx);
    bool virt = mmuidx_2stage(mmu_idx);
    bool use_background = false;
    hwaddr ppn;
    int napot_bits = 0;
    target_ulong napot_mask;
    bool is_sstack_idx = ((mmu_idx & MMU_IDX_SS_WRITE) == MMU_IDX_SS_WRITE);
    bool sstack_page = false;

    if (do_svukte_check(env, first_stage, mode, virt) &&
        !check_svukte_addr(env, addr)) {
        return TRANSLATE_FAIL;
    }

    /*
     * Check if we should use the background registers for the two
     * stage translation. We don't need to check if we actually need
     * two stage translation as that happened before this function
     * was called. Background registers will be used if the guest has
     * forced a two stage translation to be on (in HS or M mode).
     */
    if (!env->virt_enabled && two_stage) {
        use_background = true;
    }

    if (mode == PRV_M || !riscv_cpu_cfg(env)->mmu) {
        *physical = addr;
        *ret_prot = PAGE_READ | PAGE_WRITE | PAGE_EXEC;
        return TRANSLATE_SUCCESS;
    }

    *ret_prot = 0;

    hwaddr base;
    int levels, ptidxbits, ptesize, vm, widened;

    if (first_stage == true) {
        if (use_background) {
            if (riscv_cpu_mxl(env) == MXL_RV32) {
                base = (hwaddr)get_field(env->vsatp, SATP32_PPN) << PGSHIFT;
                vm = get_field(env->vsatp, SATP32_MODE);
            } else {
                base = (hwaddr)get_field(env->vsatp, SATP64_PPN) << PGSHIFT;
                vm = get_field(env->vsatp, SATP64_MODE);
            }
        } else {
            if (riscv_cpu_mxl(env) == MXL_RV32) {
                base = (hwaddr)get_field(env->satp, SATP32_PPN) << PGSHIFT;
                vm = get_field(env->satp, SATP32_MODE);
            } else {
                base = (hwaddr)get_field(env->satp, SATP64_PPN) << PGSHIFT;
                vm = get_field(env->satp, SATP64_MODE);
            }
        }
        widened = 0;
    } else {
        if (riscv_cpu_mxl(env) == MXL_RV32) {
            base = (hwaddr)get_field(env->hgatp, SATP32_PPN) << PGSHIFT;
            vm = get_field(env->hgatp, SATP32_MODE);
        } else {
            base = (hwaddr)get_field(env->hgatp, SATP64_PPN) << PGSHIFT;
            vm = get_field(env->hgatp, SATP64_MODE);
        }
        widened = 2;
    }

    switch (vm) {
    case VM_1_10_SV32:
      levels = 2; ptidxbits = 10; ptesize = 4; break;
    case VM_1_10_SV39:
      levels = 3; ptidxbits = 9; ptesize = 8; break;
    case VM_1_10_SV48:
      levels = 4; ptidxbits = 9; ptesize = 8; break;
    case VM_1_10_SV57:
      levels = 5; ptidxbits = 9; ptesize = 8; break;
    case VM_1_10_MBARE:
        *physical = addr;
        *ret_prot = PAGE_READ | PAGE_WRITE | PAGE_EXEC;
        return TRANSLATE_SUCCESS;
    default:
      g_assert_not_reached();
    }

    CPUState *cs = env_cpu(env);
    int va_bits = PGSHIFT + levels * ptidxbits + widened;
    int sxlen = 16 << riscv_cpu_sxl(env);
    int sxlen_bytes = sxlen / 8;

    if (first_stage == true) {
        target_ulong mask, masked_msbs;

        if (sxlen > (va_bits - 1)) {
            mask = (1L << (sxlen - (va_bits - 1))) - 1;
        } else {
            mask = 0;
        }
        masked_msbs = (addr >> (va_bits - 1)) & mask;

        if (masked_msbs != 0 && masked_msbs != mask) {
            return TRANSLATE_FAIL;
        }
    } else {
        if (vm != VM_1_10_SV32 && addr >> va_bits != 0) {
            return TRANSLATE_FAIL;
        }
    }

    bool pbmte = env->menvcfg & MENVCFG_PBMTE;
    bool svade = riscv_cpu_cfg(env)->ext_svade;
    bool svadu = riscv_cpu_cfg(env)->ext_svadu;
    bool adue = svadu ? env->menvcfg & MENVCFG_ADUE : !svade;
    bool svrsw60t59b = riscv_cpu_cfg(env)->ext_svrsw60t59b;

    if (first_stage && two_stage && env->virt_enabled) {
        pbmte = pbmte && (env->henvcfg & HENVCFG_PBMTE);
        adue = adue && (env->henvcfg & HENVCFG_ADUE);
    }

    int ptshift = (levels - 1) * ptidxbits;
    target_ulong pte;
    hwaddr pte_addr;
    int i;

 restart:
    for (i = 0; i < levels; i++, ptshift -= ptidxbits) {
        target_ulong idx;
        if (i == 0) {
            idx = (addr >> (PGSHIFT + ptshift)) &
                           ((1 << (ptidxbits + widened)) - 1);
        } else {
            idx = (addr >> (PGSHIFT + ptshift)) &
                           ((1 << ptidxbits) - 1);
        }

        /* check that physical address of PTE is legal */

        if (two_stage && first_stage) {
            int vbase_prot;
            hwaddr vbase;

            /* Do the second stage translation on the base PTE address. */
            int vbase_ret = get_physical_address(env, &vbase, &vbase_prot,
                                                 base, NULL, MMU_DATA_LOAD,
                                                 MMUIdx_U, false, true,
                                                 is_debug, false);

            if (vbase_ret != TRANSLATE_SUCCESS) {
                if (fault_pte_addr) {
                    *fault_pte_addr = (base + idx * ptesize) >> 2;
                }
                return TRANSLATE_G_STAGE_FAIL;
            }

            pte_addr = vbase + idx * ptesize;
        } else {
            pte_addr = base + idx * ptesize;
        }

        int pmp_prot;
        int pmp_ret = get_physical_address_pmp(env, &pmp_prot, pte_addr,
                                               sxlen_bytes,
                                               MMU_DATA_LOAD, PRV_S);
        if (pmp_ret != TRANSLATE_SUCCESS) {
            return TRANSLATE_PMP_FAIL;
        }

        if (riscv_cpu_mxl(env) == MXL_RV32) {
            pte = address_space_ldl(cs->as, pte_addr, attrs, &res);
        } else {
            pte = address_space_ldq(cs->as, pte_addr, attrs, &res);
        }

        if (res != MEMTX_OK) {
            return TRANSLATE_FAIL;
        }

        if (riscv_cpu_sxl(env) == MXL_RV32) {
            ppn = pte >> PTE_PPN_SHIFT;
        } else {
            if (pte & PTE_RESERVED(svrsw60t59b)) {
                qemu_log_mask(LOG_GUEST_ERROR, "%s: reserved bits set in PTE: "
                              "addr: 0x%" HWADDR_PRIx " pte: 0x" TARGET_FMT_lx "\n",
                              __func__, pte_addr, pte);
                return TRANSLATE_FAIL;
            }

            if (!pbmte && (pte & PTE_PBMT)) {
                /* Reserved without Svpbmt. */
                qemu_log_mask(LOG_GUEST_ERROR, "%s: PBMT bits set in PTE, "
                              "and Svpbmt extension is disabled: "
                              "addr: 0x%" HWADDR_PRIx " pte: 0x" TARGET_FMT_lx "\n",
                              __func__, pte_addr, pte);
                return TRANSLATE_FAIL;
            }

            if (!riscv_cpu_cfg(env)->ext_svnapot && (pte & PTE_N)) {
                /* Reserved without Svnapot extension */
                qemu_log_mask(LOG_GUEST_ERROR, "%s: N bit set in PTE, "
                              "and Svnapot extension is disabled: "
                              "addr: 0x%" HWADDR_PRIx " pte: 0x" TARGET_FMT_lx "\n",
                              __func__, pte_addr, pte);
                return TRANSLATE_FAIL;
            }

            ppn = (pte & (target_ulong)PTE_PPN_MASK) >> PTE_PPN_SHIFT;
        }

        if (!(pte & PTE_V)) {
            /* Invalid PTE */
            return TRANSLATE_FAIL;
        }

        if (pte & (PTE_R | PTE_W | PTE_X)) {
            goto leaf;
        }

        if (pte & (PTE_D | PTE_A | PTE_U | PTE_ATTR)) {
            /* D, A, and U bits are reserved in non-leaf/inner PTEs */
            qemu_log_mask(LOG_GUEST_ERROR, "%s: D, A, or U bits set in non-leaf PTE: "
                          "addr: 0x%" HWADDR_PRIx " pte: 0x" TARGET_FMT_lx "\n",
                          __func__, pte_addr, pte);
            return TRANSLATE_FAIL;
        }
        /* Inner PTE, continue walking */
        base = ppn << PGSHIFT;
    }

    /* No leaf pte at any translation level. */
    return TRANSLATE_FAIL;

 leaf:
    if (ppn & ((1ULL << ptshift) - 1)) {
        /* Misaligned PPN */
        qemu_log_mask(LOG_GUEST_ERROR, "%s: PPN bits in PTE is misaligned: "
                      "addr: 0x%" HWADDR_PRIx " pte: 0x" TARGET_FMT_lx "\n",
                      __func__, pte_addr, pte);
        return TRANSLATE_FAIL;
    }
    if (!pbmte && (pte & PTE_PBMT)) {
        /* Reserved without Svpbmt. */
        qemu_log_mask(LOG_GUEST_ERROR, "%s: PBMT bits set in PTE, "
                      "and Svpbmt extension is disabled: "
                      "addr: 0x%" HWADDR_PRIx " pte: 0x" TARGET_FMT_lx "\n",
                      __func__, pte_addr, pte);
        return TRANSLATE_FAIL;
    }

    target_ulong rwx = pte & (PTE_R | PTE_W | PTE_X);
    /* Check for reserved combinations of RWX flags. */
    switch (rwx) {
    case PTE_W | PTE_X:
        return TRANSLATE_FAIL;
    case PTE_W:
        /* if bcfi enabled, PTE_W is not reserved and shadow stack page */
        if (cpu_get_bcfien(env) && first_stage) {
            sstack_page = true;
            /*
             * if ss index, read and write allowed. else if not a probe
             * then only read allowed
             */
            rwx = is_sstack_idx ? (PTE_R | PTE_W) : (is_probe ? 0 :  PTE_R);
            break;
        }
        return TRANSLATE_FAIL;
    case PTE_R:
        /*
         * no matter what's the `access_type`, shadow stack access to readonly
         * memory are always store page faults. During unwind, loads will be
         * promoted as store fault.
         */
        if (is_sstack_idx) {
            return TRANSLATE_FAIL;
        }
        break;
    }

    int prot = 0;
    if (rwx & PTE_R) {
        prot |= PAGE_READ;
    }
    if (rwx & PTE_W) {
        prot |= PAGE_WRITE;
    }
    if (rwx & PTE_X) {
        bool mxr = false;

        /*
         * Use mstatus for first stage or for the second stage without
         * virt_enabled (MPRV+MPV)
         */
        if (first_stage || !env->virt_enabled) {
            mxr = get_field(env->mstatus, MSTATUS_MXR);
        }

        /* MPRV+MPV case, check VSSTATUS */
        if (first_stage && two_stage && !env->virt_enabled) {
            mxr |= get_field(env->vsstatus, MSTATUS_MXR);
        }

        /*
         * Setting MXR at HS-level overrides both VS-stage and G-stage
         * execute-only permissions
         */
        if (env->virt_enabled) {
            mxr |= get_field(env->mstatus_hs, MSTATUS_MXR);
        }

        if (mxr) {
            prot |= PAGE_READ;
        }
        prot |= PAGE_EXEC;
    }

    if (pte & PTE_U) {
        if (mode != PRV_U) {
            if (!mmuidx_sum(mmu_idx)) {
                return TRANSLATE_FAIL;
            }
            /* SUM allows only read+write, not execute. */
            prot &= PAGE_READ | PAGE_WRITE;
        }
    } else if (mode != PRV_S) {
        /* Supervisor PTE flags when not S mode */
        return TRANSLATE_FAIL;
    }

    if (!((prot >> access_type) & 1)) {
        /*
         * Access check failed, access check failures for shadow stack are
         * access faults.
         */
        return sstack_page ? TRANSLATE_PMP_FAIL : TRANSLATE_FAIL;
    }

    target_ulong updated_pte = pte;

    /*
     * If ADUE is enabled, set accessed and dirty bits.
     * Otherwise raise an exception if necessary.
     */
    if (adue) {
        updated_pte |= PTE_A | (access_type == MMU_DATA_STORE ? PTE_D : 0);
    } else if (!(pte & PTE_A) ||
               (access_type == MMU_DATA_STORE && !(pte & PTE_D))) {
        return TRANSLATE_FAIL;
    }

    /* Page table updates need to be atomic with MTTCG enabled */
    if (updated_pte != pte && !is_debug) {
        if (!adue) {
            return TRANSLATE_FAIL;
        }

        /*
         * - if accessed or dirty bits need updating, and the PTE is
         *   in RAM, then we do so atomically with a compare and swap.
         * - if the PTE is in IO space or ROM, then it can't be updated
         *   and we return TRANSLATE_FAIL.
         * - if the PTE changed by the time we went to update it, then
         *   it is no longer valid and we must re-walk the page table.
         */
        MemoryRegion *mr;
        hwaddr l = sxlen_bytes, addr1;
        mr = address_space_translate(cs->as, pte_addr, &addr1, &l,
                                     false, MEMTXATTRS_UNSPECIFIED);
        if (memory_region_is_ram(mr)) {
            target_ulong *pte_pa = qemu_map_ram_ptr(mr->ram_block, addr1);
            target_ulong old_pte;
            if (riscv_cpu_sxl(env) == MXL_RV32) {
                old_pte = qatomic_cmpxchg((uint32_t *)pte_pa, cpu_to_le32(pte), cpu_to_le32(updated_pte));
                old_pte = le32_to_cpu(old_pte);
            } else {
                old_pte = qatomic_cmpxchg(pte_pa, cpu_to_le64(pte), cpu_to_le64(updated_pte));
                old_pte = le64_to_cpu(old_pte);
            }
            if (old_pte != pte) {
                goto restart;
            }
            pte = updated_pte;
        } else {
            /*
             * Misconfigured PTE in ROM (AD bits are not preset) or
             * PTE is in IO space and can't be updated atomically.
             */
            return TRANSLATE_FAIL;
        }
    }

    /* For superpage mappings, make a fake leaf PTE for the TLB's benefit. */
    target_ulong vpn = addr >> PGSHIFT;

    if (riscv_cpu_cfg(env)->ext_svnapot && (pte & PTE_N)) {
        napot_bits = ctzl(ppn) + 1;
        if ((i != (levels - 1)) || (napot_bits != 4)) {
            return TRANSLATE_FAIL;
        }
    }

    napot_mask = (1 << napot_bits) - 1;
    *physical = (((ppn & ~napot_mask) | (vpn & napot_mask) |
                  (vpn & (((target_ulong)1 << ptshift) - 1))
                 ) << PGSHIFT) | (addr & ~TARGET_PAGE_MASK);

    /*
     * Remove write permission unless this is a store, or the page is
     * already dirty, so that we TLB miss on later writes to update
     * the dirty bit.
     */
    if (access_type != MMU_DATA_STORE && !(pte & PTE_D)) {
        prot &= ~PAGE_WRITE;
    }
    *ret_prot = prot;

    return TRANSLATE_SUCCESS;
}
```

## 实现概要

### 第一段：特殊检查和快速路径

```c
if (do_svukte_check(...) && !check_svukte_addr(...))
    return TRANSLATE_FAIL;
```

这是 Svukte 扩展相关检查，可以先忽略。

```c
if (!env->virt_enabled && two_stage)
    use_background = true;
```

两阶段翻译时，如果当前不在虚拟化模式但强制两阶段，第一阶段使用“背景寄存器”`vsatp`。

```c
if (mode == PRV_M || !riscv_cpu_cfg(env)->mmu) {
    *physical = addr;
    *ret_prot = PAGE_READ | PAGE_WRITE | PAGE_EXEC;
    return TRANSLATE_SUCCESS;
}
```

M 模式或没有 MMU：恒等映射，直接成功。这是最简单的快速路径。

---

### 第二段：选择页表基址和分页模式

```c
if (first_stage) {
    if (use_background) 用 vsatp;
    else 用 satp;
} else {
    用 hgatp;
}
```

然后根据 `vm` 字段决定：

- Sv32：2 级，每级 10 位，PTE 4 字节
- Sv39：3 级，每级 9 位，PTE 8 字节
- Sv48：4 级
- Sv57：5 级
- MBare：直接恒等映射

`widened` 是第二阶段额外位宽，SV32 的 G-stage 特殊。

---

### 第三段：检查地址宽度

第一阶段：

```c
masked_msbs = (addr >> (va_bits - 1)) & mask;
if (masked_msbs != 0 && masked_msbs != mask)
    return TRANSLATE_FAIL;
```

这是检查虚拟地址是否符号扩展正确，也就是 canonical 检查。

第二阶段：

```c
if (vm != VM_1_10_SV32 && addr >> va_bits != 0)
    return TRANSLATE_FAIL;
```

GPA 高位必须为 0。

---

### 第四段：读取扩展开关

```c
bool pbmte = env->menvcfg & MENVCFG_PBMTE;
bool svade = ...;
bool svadu = ...;
bool adue = ...;
bool svrsw60t59b = ...;
```

这些是 Svpbmt、Svade/Svadu、A/D 位更新、保留位等扩展开关。第一遍阅读可以先跳过，知道它们影响 PTE 保留位和 A/D 更新即可。

---

### 第五段：页表遍历主循环

```c
restart:
for (i = 0; i < levels; i++, ptshift -= ptidxbits) {
```

每一级：

1. 计算页表索引 `idx`
2. 计算 PTE 地址 `pte_addr = base + idx * ptesize`
3. 如果两阶段且第一阶段，PTE 地址本身是 GPA，需要递归做 G-stage 翻译：

```c
int vbase_ret = get_physical_address(env, &vbase, &vbase_prot,
                                     base, NULL, MMU_DATA_LOAD,
                                     MMUIdx_U, false, true,
                                     is_debug, false);
```

这里递归调用自己，`first_stage=false, two_stage=true`，也就是用 `hgatp` 做第二阶段翻译。

4. PMP 检查 PTE 地址
5. 从地址空间读 PTE：

```c
pte = address_space_ldq(cs->as, pte_addr, attrs, &res);
```

6. 解析 PPN，检查保留位：

```c
if (!(pte & PTE_V)) return TRANSLATE_FAIL;
if (pte & (PTE_R | PTE_W | PTE_X)) goto leaf;
if (pte & (PTE_D | PTE_A | PTE_U | PTE_ATTR)) return TRANSLATE_FAIL;
base = ppn << PGSHIFT;
```

非叶子 PTE 不能有 D/A/U 等位；继续下一级。

如果循环完还没找到叶子，失败。

---

### 第六段：叶子 PTE 处理

到 `leaf:` 后做这些事：

1. 检查 PPN 对齐，防止大页映射未对齐
2. 检查 PBMT 保留位
3. 处理 R/W/X 组合：

```c
case PTE_W | PTE_X: return FAIL;
case PTE_W: ... shadow stack 特例
case PTE_R: ... shadow stack 只读特例
```

正常 RISC-V 中 `W|X` 保留，单独 `W` 也保留，除非某些扩展/BCFI shadow stack 场景。

4. 计算 `prot`：

```c
if (rwx & PTE_R) prot |= PAGE_READ;
if (rwx & PTE_W) prot |= PAGE_WRITE;
if (rwx & PTE_X) {
    ... MXR 检查 ...
    prot |= PAGE_EXEC;
}
```

如果 `MXR` 置位，可执行页也加读权限。

5. 检查 U/S 权限：

- PTE_U 且当前不是 U 模式：需要 SUM，且 SUM 只给读写，不给执行
- 非 PTE_U 且当前不是 S 模式：失败

6. 检查本次访问类型是否被允许：

```c
if (!((prot >> access_type) & 1))
    return ... TRANSLATE_FAIL;
```

这是用权限位图检查读/写/取指。

---

### 第七段：A/D 位和 PTE 原子更新

```c
if (adue) {
    updated_pte |= PTE_A | (store ? PTE_D : 0);
} else if (!(pte & PTE_A) || (store && !(pte & PTE_D))) {
    return TRANSLATE_FAIL;
}
```

如果启用 ADUE，自动置 Accessed/Dirty；否则缺 A/D 就失败，由上层触发页错误。

如果 PTE 需要更新且不是 debug：

- 找到 PTE 所在 MemoryRegion
- 必须是 RAM
- 用 `qatomic_cmpxchg` 原子比较交换
- 如果发现 PTE 被别人改了，`goto restart` 重新走页表

这段是为了 MTTCG 下多核安全。

---

### 第八段：计算最终物理地址

```c
target_ulong vpn = addr >> PGSHIFT;
...
*physical = (((ppn & ~napot_mask) | (vpn & napot_mask) |
              (vpn & (((target_ulong)1 << ptshift) - 1))
             ) << PGSHIFT) | (addr & ~TARGET_PAGE_MASK);
```

这里把：

- 大页 PPN
- 虚拟页号中属于大页内的低位
- 页内偏移

拼成最终物理地址。Svnapot 的 `napot_mask` 是特殊连续页优化。

最后：

```c
if (access_type != MMU_DATA_STORE && !(pte & PTE_D)) {
    prot &= ~PAGE_WRITE;
}
```

如果这次不是写，而且页还没 Dirty，就先把写权限去掉。这样以后真正写的时候会 TLB miss，再进来置 Dirty 位。

---


# 九、qemu的实际翻译

1. 首先区分两种翻译
QEMU TCG 实际上存在两条不同的翻译流程：
翻译	输入	输出	主要实现
指令翻译	RISC-V 指令	AArch64 机器码	target/riscv/、tcg/
地址翻译	Guest Virtual Address	Guest Physical Address，再映射到 Host 内存或 MMIO	target/riscv/cpu_helper.c、accel/tcg/cputlb.c
指令翻译发生在 Translation Block（TB）生成期间；地址翻译通常发生在生成的 TB 执行期间，并利用软件 TLB 缓存结果。
2. 指令翻译：RISC-V → TCG IR → AArch64
RISC-V 指令
    │
    ▼
RISC-V Translator
    │
    ▼
TCG IR
    │
    ▼
TCG Optimizer
    │
    ▼
AArch64 Backend
    │
    ▼
code_gen_buffer
    │
    ▼
执行生成的 Host 机器码
例如：
ld a0, 0(a1)
RISC-V frontend 会生成对应的 TCG qemu_ld 操作。
AArch64 backend 把它转换成：
* 软件 TLB 查询指令。
* TLB hit 时的直接 Host 内存读取。
* TLB miss 或需要特殊处理时跳转到 C helper 的代码。  
因此，GDB 中的：
#7 code_gen_buffer()
#8 cpu_tb_exec()
并不代表缺少源码。
code_gen_buffer 是运行时生成的机器码区域，本身没有对应的 C 源码行。
相关实现：
target/riscv/insn_trans/
tcg/aarch64/tcg-target.c.inc
accel/tcg/cpu-exec.c
AArch64 backend 中值得关注的函数：
prepare_host_addr()
tgen_qemu_ld()
tcg_out_qemu_ld_direct()
tcg_out_qemu_ld_slow_path()
3. 地址翻译：软件 TLB Fast Path
对于普通内存访问，QEMU 不会每次调用 get_physical_address()。
TCG 将软件 TLB 查询直接编译成 AArch64 机器码：
Guest VA
    │
    ▼
计算 TLB index
    │
    ▼
查找 CPUTLBEntry
    │
    ▼
检查地址匹配及访问标志
    │
    ├── RAM TLB hit
    │      │
    │      ▼
    │   HVA = GVA + addend
    │      │
    │      ▼
    │   AArch64 ldr/str
    │
    └── miss / MMIO / 特殊访问
           │
           ▼
        Slow Path
核心结构是 CPUTLBEntry：
* addr_read / addr_write / addr_code：用于命中判断及访问属性检查。
* addend：Guest 地址到 Host RAM 地址的偏移量。  
对可直接访问的 Host RAM：
\[ HVA = GVA + \text{addend} \]
其中：
\[ \text{addend}=HVA_{\text{page}}-GVA_{\text{page}} \]
普通 RAM TLB hit 时，不会调用 mmu_lookup()，也不会重新进行 RISC-V 页表遍历。
4. 地址翻译：软件 TLB Slow Path
当直接生成的机器码无法完成访问时，进入 C helper。
你观察到的调用栈：
code_gen_buffer()
    │
    ▼
helper_ldub_mmu()       // 部分访问使用
    │
    ▼
do_ld1_mmu() / do_ld8_mmu()
    │
    ▼
mmu_lookup()
    │
    ▼
mmu_lookup1()
    │
    ▼
tlb_fill_align()
    │
    ▼
riscv_cpu_tlb_fill()
    │
    ▼
get_physical_address()
其中：
mmu_lookup()
是通用 TCG 内存访问解析逻辑：
* 查询软件 TLB，必要时触发 refill。
* 检查是否跨越基础 Guest 页面。
* 处理 watchpoint、dirty tracking、特殊字节序等标志。
* 准备 Host RAM 指针或 MMIO 所需的信息。
riscv_cpu_tlb_fill()
是 RISC-V 架构相关的 refill 入口：
* 调用 RISC-V 地址翻译算法。
* 检查 PMP 等访问约束。
* 根据结果调用 tlb_set_page() 等接口安装软件 TLB 映射。 
get_physical_address()
负责 ISA 语义中的地址翻译：
* M-mode 正常访存通常不经 satp 分页。
* S/U-mode 根据需要进行 Sv39/Sv48/Sv57 页表遍历。
* 处理普通 4 KiB 页面、Superpage、Svnapot 等情况。
* 检查 PTE 的有效性、权限及其他架构约束。
* 输出 Guest Physical Address 和权限。 
上一节提到的：
*physical = (((ppn & ~napot_mask)
              | (vpn & napot_mask)
              | (vpn & (((target_ulong)1 << ptshift) - 1)))
             << PGSHIFT)
            | (addr & ~TARGET_PAGE_MASK);
只是把 RISC-V 的叶子 PTE 翻译为最终 Guest 物理地址。
它不负责生成 Host 指针。
5. GPA 如何转换成 Host RAM 或 MMIO？
这个过程由通用 QEMU Memory API 完成。
get_physical_address()
         │
         ▼
        GPA
         │
         ▼
tlb_set_page()
         │
         ▼
tlb_set_page_full()
         │
         ▼
address_space_translate_for_iotlb()
         │
         ▼
MemoryRegionSection
         │
         ├── RAM
         │    ├── 获取 Host RAM pointer
         │    └── 缓存 addend
         │
         └── MMIO
              ├── 保存设备映射信息
              └── 标记 TLB_MMIO
因此，通用软件 TLB 不需要了解 Sv39 页表格式。
它只需要架构相关代码提供的：
Guest VA
Guest PA
访问权限
翻译上下文
映射大小
然后由 Memory API 解析 Guest 物理地址对应什么。
6. 最终访问：RAM 与 MMIO
对于你之前的两个地址：
Guest 地址	类型	最终执行方式
0x80043a10	virt 机器的 RAM	Host 内存访问
0x10000005	virt 机器的 UART LSR 寄存器	MMIO 回调
普通 RAM：
GVA
 ↓
软件 TLB
 ↓
HVA = GVA + addend
 ↓
Host ldr/str
MMIO：
GVA
 ↓
软件 TLB
 ↓
TLB_MMIO
 ↓
do_ld_mmio_beN()
 ↓
memory_region_dispatch_read()
 ↓
serial_ioport_read()
MMIO 没有必要对应一个可直接解引用的 HVA。
因此，你在 0x10000005 观察到的访问不会最终执行普通 Host RAM load，而是调用设备模拟逻辑。(尽管本次实验中没有进一步深入)
7. 关于跨页与 Superpage
mmu_lookup() 使用：
last = addr + l->page[0].size - 1;
crosspage = (addr ^ last) & TARGET_PAGE_MASK;
检查一次内存访问是否跨越 QEMU 的基础目标页面边界。
它不需要知道 RISC-V 页表是普通页面还是 Superpage。
对于跨页的非对齐访问：
Guest load
   ├── 第一页：mmu_lookup1()
   └── 第二页：mmu_lookup1()
两页可能对应不同的物理映射和权限。
RISC-V 的 2 MiB Superpage 也不意味着 QEMU 必然缓存整个 2 MiB 的软件 TLB 项。在前面讨论的实现中，通常仍按基础 4 KiB 粒度缓存。
这意味着：
Guest 页表粒度与 QEMU 软件 TLB 缓存粒度是两个不同概念。
最终结论
QEMU 没有逐条模拟 Guest 的硬件 TLB 操作，而是实现了一套用于加速内存访问的软件地址翻译缓存。
整体机制可以概括为：
\[ \boxed{ \begin{gathered} \text{Guest VA} \xrightarrow{\text{RISC-V MMU}} \text{Guest PA}\\ \downarrow\\ \text{QEMU Memory API} \xrightarrow{} \text{Host RAM / MMIO} \end{gathered} } \]
这条转换路径的结果由软件 TLB 缓存。TCG 再把软件 TLB 查询编译成 Host 机器指令，使得普通 RAM 命中时不需要进入 C helper。
最关键的抽象边界是 riscv_cpu_tlb_fill() 与 tlb_set_page()：前者处理 RISC-V ISA 的地址翻译规则，后者将翻译结果交给通用 TCG SoftMMU。



