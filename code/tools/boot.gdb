set pagination off
set confirm off
set architecture riscv:rv64
file bin/kernel
target remote localhost:1234
echo \n=== RESET: PC and instructions ===\n
info registers pc a0 a1 a2 sp
python
assert int(gdb.parse_and_eval('$pc')) == 0x1000, 'reset PC mismatch'
end
x/8i 0x1000
x/4gx 0x1018
echo \n=== Kernel already loaded before first CPU instruction ===\n
x/4i 0x80200000
python
assert bytes(gdb.selected_inferior().read_memory(0x80200000, 16)) == open('bin/ucore.img', 'rb').read(16), 'preloaded kernel mismatch'
end
watch *(unsigned int *)0x80200000
delete 1
si 6
echo \n=== OpenSBI entry after six reset instructions ===\n
info registers pc a0 a1 a2
python
assert int(gdb.parse_and_eval('$pc')) == 0x80000000, 'firmware PC mismatch'
end
x/4i $pc
break *0x80200000
continue
echo \n=== Kernel entry and privilege state ===\n
info registers pc sp ra a0 a1 mstatus mepc satp
python
assert int(gdb.parse_and_eval('$pc')) == 0x80200000, 'kernel PC mismatch'
firmware_ra = int(gdb.parse_and_eval('$ra'))
end
x/6i $pc
p/x &bootstack
p/x &bootstacktop
p/d (char *)&bootstacktop - (char *)&bootstack
si 2
echo \n=== Stack initialized ===\n
info registers pc sp ra
python
assert int(gdb.parse_and_eval('$sp')) == int(gdb.parse_and_eval('&bootstacktop')), 'stack initialization failed'
assert int(gdb.parse_and_eval('$sp')) % 16 == 0, 'stack alignment failed'
end
break kern_init
continue
echo \n=== Tail transfer into C ===\n
info registers pc sp ra
python
assert int(gdb.parse_and_eval('$pc')) == int(gdb.parse_and_eval('&kern_init')), 'C entry mismatch'
assert int(gdb.parse_and_eval('$ra')) == firmware_ra, 'tail changed ra'
end
p/x &edata
p/x &end
break cprintf
continue
echo \n=== BSS initialization completed; cprintf called ===\n
info registers pc sp
x/s $a0
x/s $a1
finish
echo \n=== Output complete; final kernel loop ===\n
x/4i $pc
info registers pc sp
python
loop_pc = int(gdb.parse_and_eval('$pc'))
end
si 3
python
assert int(gdb.parse_and_eval('$pc')) == loop_pc, 'final loop mismatch'
end
detach
quit
