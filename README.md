# 操作系统实验 — Lab1

本分支为三人小组的 Lab1 实验材料，组长及成员身份在报告中待填写。

- [实验报告](report/report.md)：全部练习答案、模块和 OS 原理分析。
- [实验记录](report/record.md)：配置、故障、修复及复现步骤。
- [提示词记录](report/prompt.md)：真实任务提示词与需求规格。
- `code/`：原始最小内核、Makefile 兼容修复和验证脚本。
- `report/logs/`：实际构建、GDB 与串口日志。
- `report/images/`：原始日志渲染页面的截图及 HTML。

## 分支和提交结构

每次实验使用独立分支 `labx`，例如本分支 `lab1`。源码位于 `code/`，报告、提示词和截图位于 `report/`。

## 在 Ubuntu / WSL 中复现

Ubuntu 26.04：

```bash
sudo apt-get install gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf \
    make qemu-system-riscv gdb-multiarch python3
cd code
make
make qemu
```

退出 QEMU：按 `Ctrl+A`，松开后按 `X`。

自动构建并记录启动调试：

```bash
python3 tools/verify.py
```

手动调试：两个终端均进入 `code/`，分别运行 `make debug` 和 `make gdb GDB=gdb-multiarch`。

构建生成 `code/bin/kernel`（ELF）和 `code/bin/ucore.img`（裸镜像），不将构建缓存提交到仓库。最终测试限定于报告列出的工具版本和 QEMU 单 hart 环境。
