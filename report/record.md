# Lab1 实验记录

日期：2026-10-06（Asia/Shanghai）。所有结果来自当前目录的 `lab1.zip` 与本机实际运行。小组成员为袁煜杰、张龙飞和王逸凌，实际分工待填写。

## 1. 任务与交付约定

阅读课程 Lab1 全章、环境配置与 AI 协作章节。实验包括入口汇编解释和 GDB 启动跟踪，报告需说明整体逻辑、核心模块、知识点对应和未覆盖的 OS 原理。仓库 README 要求每次实验使用 `labx` 分支和 `code/`、`report/` 目录，因此创建 `lab1` 分支，将压缩包里的 `lab1/` 内容放入 `code/`。

网站正文快照保存在 `reference/`，报告源文件为 `report.md`，不需要 LaTeX 或 PDF 才能满足本次 Markdown 提交要求。

## 2. 环境检查与配置

发现已有 Ubuntu WSL2、GNU make 和 `riscv64-unknown-elf-gcc`，缺少 QEMU 和 RISC-V GDB。执行了：

```bash
# 在现有 Ubuntu 内以 root 安装（一般使用 sudo）
apt-get update
apt-get install -y qemu-system-misc gdb-multiarch
apt-cache search qemu-system-riscv
apt-get install -y --no-install-recommends qemu-system-riscv
```

最初按常见包名安装 `qemu-system-misc`，但当前 Ubuntu 26.04 已将 RISC-V 拆为独立软件包；因此第一次检查出现 `qemu-system-riscv64: command not found`，查询软件包后补装 `qemu-system-riscv`，同时安装其 OpenSBI 依赖。最终实际版本在 `logs/environment.txt`。

本地命令工具的普通沙箱无法创建进程，返回 `setup refresh had errors`。经工具授权使用可运行的终端完成项目操作。Git 还报告目录所有者不同，因此使用命令级 `git -c safe.directory=...`，没有修改全局 `safe.directory` 配置。

## 3. 原始构建和启动故障

在 `code/` 中构建原始代码：

```bash
make V=
timeout 6s make qemu
```

原始构建通过，日志为 `logs/build-original.txt`。原始 QEMU 启动有 OpenSBI 横幅，但没有内核打印；日志 `logs/qemu-original.txt` 显示 `Domain0 Next Address = 0`。内核末尾本来就为死循环，timeout 用于结束测试；是否启动成功应检查内核输出与调试状态，不能只用 timeout 返回码判断。

## 4. 修复和验证

将 `Makefile` 的运行、调试目标中的 `-device loader,file=...,addr=0x80200000` 改为 `-kernel $(UCOREIMG)`，使当前 QEMU 默认动态固件取得下一阶段信息。另使 `GDB` 可通过命令行覆盖，`make gdb GDB=gdb-multiarch` 可用。修改后的 `make qemu` 成功打印 `(THU.CST) os is loading ...`，日志为 `logs/qemu.txt`。

新增 `tools/boot.gdb` 与 `tools/verify.py`，自动进行强制重编译、ELF 信息记录、QEMU 启动、GDB 跟踪及结束 QEMU。脚本只清理自己创建的 QEMU 进程；1234 端口被占用时直接报错，不结束其他进程。

首次跟踪验证通过。随后补强 PC、预加载字节、尾跳转和死循环断言时，编辑脚本误将固件入口断言重复放到最后循环处，GDB 返回 1；定位后删除重复断言，再次完整验证通过。该失败属于调试脚本编辑错误，未修改内核来迎合断言。

最终实测：

| 观察项 | 结果 |
|---|---|
| 初始 PC | `0x1000` |
| 六条复位指令后 PC | `0x80000000` |
| 内核第一条指令 PC | `0x80200000` |
| CPU 执行前的内核字节 | 前 16 字节与裸镜像一致 |
| 启动栈区间 | `0x80201000` 到 `0x80203000`（末端不包含） |
| 初始化后 SP | `0x80203000`，满足 16 字节对齐 |
| 尾跳转 RA | 转移前后均为 `0x80005b52` |
| C 入口 PC | `0x8020000a` |
| BSS 边界 | `edata = end = 0x80203008`，本次为空 |
| cprintf 返回值 | 30 |
| 最终循环 PC | `0x8020003a`，单步三次仍相同 |
| 内核打印 | `(THU.CST) os is loading ...` |
| GDB 退出状态 | 0 |

本次在复位暂停时镜像已经加载，写监视点无法追溯宿主预加载。使用阶段断点观察 OpenSBI 到内核的交接，不把指导书的建议当成必然出现的实测现象。

## 5. 原始证据与截图

- `logs/build-original.txt`：原始代码构建。
- `logs/qemu-original.txt`：旧启动参数的真实失败现象。
- `logs/build.txt`：最终构建。
- `logs/environment.txt`：工具版本。
- `logs/elf.txt`、`logs/symbols.txt`：ELF 段和符号地址。
- `logs/gdb.txt`：最终真实调试记录。
- `logs/qemu-debug.txt`：配合最终调试的 OpenSBI 与内核串口输出。
- `logs/verification.txt`：最终验证结果。
- `logs/source-integrity.txt`：对原压缩包文件的逐项比较。
- `code/tools/render-evidence.ps1`：将原始日志转为静态 HTML 并使用 Edge 截图，可在项目根目录执行 `powershell -ExecutionPolicy Bypass -File code/tools/render-evidence.ps1` 重新生成。
- `images/reset.png`、`kernel.png`、`qemu.png`：浏览器对原始日志页面的截图；相应 HTML 一并保存。它们不是交互终端截图。

## 6. 复现与提交

```bash
# Ubuntu 26.04 缺少工具时：
sudo apt-get install gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf \
    make qemu-system-riscv gdb-multiarch python3

# 仓库根目录：
cd code
make
make qemu
# 退出 QEMU：Ctrl+A，然后按 X
python3 tools/verify.py

# 手动调试分别在两个终端中执行：
make debug
make gdb GDB=gdb-multiarch
```

构建产物为 `code/bin/kernel` 和 `code/bin/ucore.img`，自动验证时会重新生成。构建缓存与浏览器临时目录不提交。

Git 提交与推送状态见仓库历史和本次任务最终回复；本文件不预先宣称尚未执行的推送成功。提交材料后由组长补全成员信息、实际分工，并在课程指定平台提交仓库链接。

## 7. 优化后的提示词

```markdown
[PROMPT]
根据 Lab1 指导书和已有代码，完成内核启动实验，并整理实验记录与报告。

[RELY]
使用项目中的入口汇编、链接脚本和 SBI 输出函数，在 QEMU 中运行，用 GDB 调试。

[GUARANTEE]
保留原有内核功能，只修改必要的配置或代码；解释栈初始化和入口跳转的作用。

[SPECIFICATION]
Pre-Condition：实验环境和工具已准备好。
Post-Condition：内核能够编译、启动并输出信息，GDB 能跟踪到内核入口。
记录实际遇到的问题、修改方法和测试结果，报告按模板完成。
```
