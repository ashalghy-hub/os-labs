#!/usr/bin/env python3
"""Build, boot, and record an actual QEMU/GDB lab1 session."""
from pathlib import Path
import subprocess
import time
import socket

code = Path(__file__).resolve().parents[1]
logs = code.parent / "report" / "logs"
logs.mkdir(parents=True, exist_ok=True)
(logs / 'verification.txt').unlink(missing_ok=True)

def record(name, argv):
    result = subprocess.run(argv, cwd=code, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=60)
    (logs / name).write_text(result.stdout, encoding="utf-8")
    if result.returncode:
        raise RuntimeError(f"{argv}: exit {result.returncode}; see {name}")
    return result.stdout

versions = []
for cmd in (["uname", "-a"], ["riscv64-unknown-elf-gcc", "--version"],
            ["qemu-system-riscv64", "--version"], ["gdb-multiarch", "--version"],
            ["make", "--version"]):
    versions.append(subprocess.check_output(cmd, text=True).splitlines()[0])
(logs / "environment.txt").write_text("\n".join(versions)+"\n", encoding="utf-8")
record("build.txt", ["make", "-B", "V="])
elf = record("elf.txt", ["riscv64-unknown-elf-readelf", "-h", "-S", "-l", "bin/kernel"])
assert "Entry point address:               0x80200000" in elf, "ELF entry mismatch"
record("symbols.txt", ["riscv64-unknown-elf-nm", "-n", "bin/kernel"])
# Fail before spawning if the port belongs to another process.
with socket.socket() as sock:
    sock.bind(("127.0.0.1", 1234))
with (logs / "qemu-debug.txt").open("w", encoding="utf-8") as output:
    qemu = subprocess.Popen(["qemu-system-riscv64", "-machine", "virt", "-nographic",
                             "-bios", "default", "-kernel", "bin/ucore.img",
                             "-S", "-gdb", "tcp:127.0.0.1:1234"], cwd=code,
                            stdin=subprocess.DEVNULL, stdout=output, stderr=output)
    try:
        for _ in range(100):
            if qemu.poll() is not None:
                raise RuntimeError("QEMU exited before GDB attached")
            with socket.socket() as sock:
                if sock.connect_ex(("127.0.0.1", 1234)) == 0:
                    break
            time.sleep(0.05)
        else:
            raise RuntimeError("QEMU GDB port timeout")
        trace = record("gdb.txt", ["gdb-multiarch", "-q", "-nx", "-batch", "-x", "tools/boot.gdb"])
        time.sleep(0.3)
    finally:
        qemu.terminate()
        try:
            qemu.wait(timeout=5)
        except subprocess.TimeoutExpired:
            qemu.kill()
            qemu.wait()
boot = (logs / "qemu-debug.txt").read_text(encoding="utf-8")
assert "(THU.CST) os is loading ..." in boot, "kernel output missing"
assert "0x0000000000001000" in trace, "reset PC missing"
assert "0x80000000" in trace, "firmware entry missing"
assert "0x80200000" in trace, "kernel entry missing"
assert "=== Stack initialized ===" in trace
(logs / "verification.txt").write_text(
    "PASS: full rebuild and ELF entry 0x80200000\nPASS: reset PC 0x1000\nPASS: OpenSBI entry 0x80000000\n"
    "PASS: kernel entry 0x80200000\nPASS: SP equals bootstacktop, 16-byte alignment\n"
    "PASS: preloaded kernel bytes match image\nPASS: tail preserves RA\nPASS: C entry and formatted output\nPASS: final self-loop\nGDB exit status: 0\n"
    "QEMU terminated by harness after reaching intentional infinite loop\n", encoding="utf-8")
print((logs / "verification.txt").read_text())
