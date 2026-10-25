
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000d297          	auipc	t0,0xd
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020d000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000d297          	auipc	t0,0xd
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020d008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020c2b7          	lui	t0,0xc020c
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020c137          	lui	sp,0xc020c

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d628293          	addi	t0,t0,214 # ffffffffc02000d6 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc020bff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00007517          	auipc	a0,0x7
ffffffffc0200050:	23450513          	addi	a0,a0,564 # ffffffffc0207280 <etext+0x4>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0fa000ef          	jal	ffffffffc0200150 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00007517          	auipc	a0,0x7
ffffffffc0200066:	23e50513          	addi	a0,a0,574 # ffffffffc02072a0 <etext+0x24>
ffffffffc020006a:	0e6000ef          	jal	ffffffffc0200150 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00007597          	auipc	a1,0x7
ffffffffc0200072:	20e58593          	addi	a1,a1,526 # ffffffffc020727c <etext>
ffffffffc0200076:	00007517          	auipc	a0,0x7
ffffffffc020007a:	24a50513          	addi	a0,a0,586 # ffffffffc02072c0 <etext+0x44>
ffffffffc020007e:	0d2000ef          	jal	ffffffffc0200150 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	0000d597          	auipc	a1,0xd
ffffffffc0200086:	f9e58593          	addi	a1,a1,-98 # ffffffffc020d020 <buddy_test_pages>
ffffffffc020008a:	00007517          	auipc	a0,0x7
ffffffffc020008e:	25650513          	addi	a0,a0,598 # ffffffffc02072e0 <etext+0x64>
ffffffffc0200092:	0be000ef          	jal	ffffffffc0200150 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00027597          	auipc	a1,0x27
ffffffffc020009a:	7e258593          	addi	a1,a1,2018 # ffffffffc0227878 <end>
ffffffffc020009e:	00007517          	auipc	a0,0x7
ffffffffc02000a2:	26250513          	addi	a0,a0,610 # ffffffffc0207300 <etext+0x84>
ffffffffc02000a6:	0aa000ef          	jal	ffffffffc0200150 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00000717          	auipc	a4,0x0
ffffffffc02000ae:	02c70713          	addi	a4,a4,44 # ffffffffc02000d6 <kern_init>
ffffffffc02000b2:	00028797          	auipc	a5,0x28
ffffffffc02000b6:	bc578793          	addi	a5,a5,-1083 # ffffffffc0227c77 <end+0x3ff>
ffffffffc02000ba:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000bc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c6:	95be                	add	a1,a1,a5
ffffffffc02000c8:	85a9                	srai	a1,a1,0xa
ffffffffc02000ca:	00007517          	auipc	a0,0x7
ffffffffc02000ce:	25650513          	addi	a0,a0,598 # ffffffffc0207320 <etext+0xa4>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a8b5                	j	ffffffffc0200150 <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	0000d517          	auipc	a0,0xd
ffffffffc02000da:	f4a50513          	addi	a0,a0,-182 # ffffffffc020d020 <buddy_test_pages>
ffffffffc02000de:	00027617          	auipc	a2,0x27
ffffffffc02000e2:	79a60613          	addi	a2,a2,1946 # ffffffffc0227878 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	17c070ef          	jal	ffffffffc020726a <memset>
    dtb_init();
ffffffffc02000f2:	13e000ef          	jal	ffffffffc0200230 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	130000ef          	jal	ffffffffc0200226 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	0000a517          	auipc	a0,0xa
ffffffffc02000fe:	9ae50513          	addi	a0,a0,-1618 # ffffffffc0209aa8 <etext+0x282c>
ffffffffc0200102:	082000ef          	jal	ffffffffc0200184 <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();   // init physical memory management
ffffffffc020010a:	7c8020ef          	jal	ffffffffc02028d2 <pmm_init>
    slub_init();  // init the SLUB object allocator (on top of the page
ffffffffc020010e:	64e040ef          	jal	ffffffffc020475c <slub_init>
                  // allocator; prints its own smoke result + fixed overhead)
#ifdef SLUB_TEST
    check_slub(); // SLUB 压力/回收/故障恢复测试；仅 -DSLUB_TEST 构建执行，
ffffffffc0200112:	4c3060ef          	jal	ffffffffc0206dd4 <check_slub>
                  // 输出 SLUB_TEST_PASS / SLUB_TEST_FAIL 供 tools/slub_test/
                  // run_slub_test.sh 判定
#endif

    /* do nothing */
    while (1)
ffffffffc0200116:	a001                	j	ffffffffc0200116 <kern_init+0x40>

ffffffffc0200118 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200118:	1101                	addi	sp,sp,-32
ffffffffc020011a:	ec06                	sd	ra,24(sp)
ffffffffc020011c:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc020011e:	10a000ef          	jal	ffffffffc0200228 <cons_putc>
    (*cnt) ++;
ffffffffc0200122:	65a2                	ld	a1,8(sp)
}
ffffffffc0200124:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
ffffffffc0200126:	419c                	lw	a5,0(a1)
ffffffffc0200128:	2785                	addiw	a5,a5,1
ffffffffc020012a:	c19c                	sw	a5,0(a1)
}
ffffffffc020012c:	6105                	addi	sp,sp,32
ffffffffc020012e:	8082                	ret

ffffffffc0200130 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200130:	1101                	addi	sp,sp,-32
ffffffffc0200132:	862a                	mv	a2,a0
ffffffffc0200134:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200136:	00000517          	auipc	a0,0x0
ffffffffc020013a:	fe250513          	addi	a0,a0,-30 # ffffffffc0200118 <cputch>
ffffffffc020013e:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200140:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200142:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200144:	523060ef          	jal	ffffffffc0206e66 <vprintfmt>
    return cnt;
}
ffffffffc0200148:	60e2                	ld	ra,24(sp)
ffffffffc020014a:	4532                	lw	a0,12(sp)
ffffffffc020014c:	6105                	addi	sp,sp,32
ffffffffc020014e:	8082                	ret

ffffffffc0200150 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200150:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200152:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc0200156:	f42e                	sd	a1,40(sp)
ffffffffc0200158:	f832                	sd	a2,48(sp)
ffffffffc020015a:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015c:	862a                	mv	a2,a0
ffffffffc020015e:	004c                	addi	a1,sp,4
ffffffffc0200160:	00000517          	auipc	a0,0x0
ffffffffc0200164:	fb850513          	addi	a0,a0,-72 # ffffffffc0200118 <cputch>
ffffffffc0200168:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc020016a:	ec06                	sd	ra,24(sp)
ffffffffc020016c:	e0ba                	sd	a4,64(sp)
ffffffffc020016e:	e4be                	sd	a5,72(sp)
ffffffffc0200170:	e8c2                	sd	a6,80(sp)
ffffffffc0200172:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc0200176:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200178:	4ef060ef          	jal	ffffffffc0206e66 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017c:	60e2                	ld	ra,24(sp)
ffffffffc020017e:	4512                	lw	a0,4(sp)
ffffffffc0200180:	6125                	addi	sp,sp,96
ffffffffc0200182:	8082                	ret

ffffffffc0200184 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200184:	1101                	addi	sp,sp,-32
ffffffffc0200186:	e822                	sd	s0,16(sp)
ffffffffc0200188:	ec06                	sd	ra,24(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3a>
ffffffffc0200192:	e426                	sd	s1,8(sp)
ffffffffc0200194:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc0200196:	4481                	li	s1,0
    cons_putc(c);
ffffffffc0200198:	090000ef          	jal	ffffffffc0200228 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	0405                	addi	s0,s0,1
ffffffffc02001a2:	87a6                	mv	a5,s1
    (*cnt) ++;
ffffffffc02001a4:	2485                	addiw	s1,s1,1
    while ((c = *str ++) != '\0') {
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x14>
    cons_putc(c);
ffffffffc02001a8:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001aa:	0027841b          	addiw	s0,a5,2
ffffffffc02001ae:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001b0:	078000ef          	jal	ffffffffc0200228 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b4:	60e2                	ld	ra,24(sp)
ffffffffc02001b6:	8522                	mv	a0,s0
ffffffffc02001b8:	6442                	ld	s0,16(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    cons_putc(c);
ffffffffc02001be:	4529                	li	a0,10
ffffffffc02001c0:	068000ef          	jal	ffffffffc0200228 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001c4:	4405                	li	s0,1
}
ffffffffc02001c6:	60e2                	ld	ra,24(sp)
ffffffffc02001c8:	8522                	mv	a0,s0
ffffffffc02001ca:	6442                	ld	s0,16(sp)
ffffffffc02001cc:	6105                	addi	sp,sp,32
ffffffffc02001ce:	8082                	ret

ffffffffc02001d0 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001d0:	00027317          	auipc	t1,0x27
ffffffffc02001d4:	5d032303          	lw	t1,1488(t1) # ffffffffc02277a0 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d8:	715d                	addi	sp,sp,-80
ffffffffc02001da:	ec06                	sd	ra,24(sp)
ffffffffc02001dc:	f436                	sd	a3,40(sp)
ffffffffc02001de:	f83a                	sd	a4,48(sp)
ffffffffc02001e0:	fc3e                	sd	a5,56(sp)
ffffffffc02001e2:	e0c2                	sd	a6,64(sp)
ffffffffc02001e4:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e6:	00030363          	beqz	t1,ffffffffc02001ec <__panic+0x1c>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001ea:	a001                	j	ffffffffc02001ea <__panic+0x1a>
    is_panic = 1;
ffffffffc02001ec:	4705                	li	a4,1
    va_start(ap, fmt);
ffffffffc02001ee:	103c                	addi	a5,sp,40
ffffffffc02001f0:	e822                	sd	s0,16(sp)
ffffffffc02001f2:	8432                	mv	s0,a2
ffffffffc02001f4:	862e                	mv	a2,a1
ffffffffc02001f6:	85aa                	mv	a1,a0
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f8:	00007517          	auipc	a0,0x7
ffffffffc02001fc:	15850513          	addi	a0,a0,344 # ffffffffc0207350 <etext+0xd4>
    is_panic = 1;
ffffffffc0200200:	00027697          	auipc	a3,0x27
ffffffffc0200204:	5ae6a023          	sw	a4,1440(a3) # ffffffffc02277a0 <is_panic>
    va_start(ap, fmt);
ffffffffc0200208:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020020a:	f47ff0ef          	jal	ffffffffc0200150 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020020e:	65a2                	ld	a1,8(sp)
ffffffffc0200210:	8522                	mv	a0,s0
ffffffffc0200212:	f1fff0ef          	jal	ffffffffc0200130 <vcprintf>
    cprintf("\n");
ffffffffc0200216:	00007517          	auipc	a0,0x7
ffffffffc020021a:	15a50513          	addi	a0,a0,346 # ffffffffc0207370 <etext+0xf4>
ffffffffc020021e:	f33ff0ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc0200222:	6442                	ld	s0,16(sp)
ffffffffc0200224:	b7d9                	j	ffffffffc02001ea <__panic+0x1a>

ffffffffc0200226 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200226:	8082                	ret

ffffffffc0200228 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200228:	0ff57513          	zext.b	a0,a0
ffffffffc020022c:	7990606f          	j	ffffffffc02071c4 <sbi_console_putchar>

ffffffffc0200230 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200230:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc0200232:	00007517          	auipc	a0,0x7
ffffffffc0200236:	14650513          	addi	a0,a0,326 # ffffffffc0207378 <etext+0xfc>
void dtb_init(void) {
ffffffffc020023a:	f406                	sd	ra,40(sp)
ffffffffc020023c:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc020023e:	f13ff0ef          	jal	ffffffffc0200150 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200242:	0000d597          	auipc	a1,0xd
ffffffffc0200246:	dbe5b583          	ld	a1,-578(a1) # ffffffffc020d000 <boot_hartid>
ffffffffc020024a:	00007517          	auipc	a0,0x7
ffffffffc020024e:	13e50513          	addi	a0,a0,318 # ffffffffc0207388 <etext+0x10c>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200252:	0000d417          	auipc	s0,0xd
ffffffffc0200256:	db640413          	addi	s0,s0,-586 # ffffffffc020d008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020025a:	ef7ff0ef          	jal	ffffffffc0200150 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025e:	600c                	ld	a1,0(s0)
ffffffffc0200260:	00007517          	auipc	a0,0x7
ffffffffc0200264:	13850513          	addi	a0,a0,312 # ffffffffc0207398 <etext+0x11c>
ffffffffc0200268:	ee9ff0ef          	jal	ffffffffc0200150 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020026c:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020026e:	00007517          	auipc	a0,0x7
ffffffffc0200272:	14250513          	addi	a0,a0,322 # ffffffffc02073b0 <etext+0x134>
    if (boot_dtb == 0) {
ffffffffc0200276:	10070163          	beqz	a4,ffffffffc0200378 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020027a:	57f5                	li	a5,-3
ffffffffc020027c:	07fa                	slli	a5,a5,0x1e
ffffffffc020027e:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200280:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc0200282:	d00e06b7          	lui	a3,0xd00e0
ffffffffc0200286:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfeb8675>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020028e:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200292:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200296:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a0:	8e49                	or	a2,a2,a0
ffffffffc02002a2:	0ff7f793          	zext.b	a5,a5
ffffffffc02002a6:	8dd1                	or	a1,a1,a2
ffffffffc02002a8:	07a2                	slli	a5,a5,0x8
ffffffffc02002aa:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ac:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02002b0:	0cd59863          	bne	a1,a3,ffffffffc0200380 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002b4:	4710                	lw	a2,8(a4)
ffffffffc02002b6:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02002b8:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ba:	0086541b          	srliw	s0,a2,0x8
ffffffffc02002be:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002c2:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02002c6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ca:	0186151b          	slliw	a0,a2,0x18
ffffffffc02002ce:	0186959b          	slliw	a1,a3,0x18
ffffffffc02002d2:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d6:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002da:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002de:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02002e2:	01c56533          	or	a0,a0,t3
ffffffffc02002e6:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ea:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ee:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f2:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	0ff6f693          	zext.b	a3,a3
ffffffffc02002fa:	8c49                	or	s0,s0,a0
ffffffffc02002fc:	0622                	slli	a2,a2,0x8
ffffffffc02002fe:	8fcd                	or	a5,a5,a1
ffffffffc0200300:	06a2                	slli	a3,a3,0x8
ffffffffc0200302:	8c51                	or	s0,s0,a2
ffffffffc0200304:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200306:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200308:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020030a:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020030c:	9381                	srli	a5,a5,0x20
ffffffffc020030e:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200310:	4301                	li	t1,0
        switch (token) {
ffffffffc0200312:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200314:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200316:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc020031a:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020031c:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020031e:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200322:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200326:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020032e:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200332:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200336:	8ed1                	or	a3,a3,a2
ffffffffc0200338:	0ff77713          	zext.b	a4,a4
ffffffffc020033c:	8fd5                	or	a5,a5,a3
ffffffffc020033e:	0722                	slli	a4,a4,0x8
ffffffffc0200340:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc0200342:	05178763          	beq	a5,a7,ffffffffc0200390 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc0200348:	00f8e963          	bltu	a7,a5,ffffffffc020035a <dtb_init+0x12a>
ffffffffc020034c:	07c78d63          	beq	a5,t3,ffffffffc02003c6 <dtb_init+0x196>
ffffffffc0200350:	4709                	li	a4,2
ffffffffc0200352:	00e79763          	bne	a5,a4,ffffffffc0200360 <dtb_init+0x130>
ffffffffc0200356:	4301                	li	t1,0
ffffffffc0200358:	b7d1                	j	ffffffffc020031c <dtb_init+0xec>
ffffffffc020035a:	4711                	li	a4,4
ffffffffc020035c:	fce780e3          	beq	a5,a4,ffffffffc020031c <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200360:	00007517          	auipc	a0,0x7
ffffffffc0200364:	11850513          	addi	a0,a0,280 # ffffffffc0207478 <etext+0x1fc>
ffffffffc0200368:	de9ff0ef          	jal	ffffffffc0200150 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020036c:	64e2                	ld	s1,24(sp)
ffffffffc020036e:	6942                	ld	s2,16(sp)
ffffffffc0200370:	00007517          	auipc	a0,0x7
ffffffffc0200374:	14050513          	addi	a0,a0,320 # ffffffffc02074b0 <etext+0x234>
}
ffffffffc0200378:	7402                	ld	s0,32(sp)
ffffffffc020037a:	70a2                	ld	ra,40(sp)
ffffffffc020037c:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc020037e:	bbc9                	j	ffffffffc0200150 <cprintf>
}
ffffffffc0200380:	7402                	ld	s0,32(sp)
ffffffffc0200382:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200384:	00007517          	auipc	a0,0x7
ffffffffc0200388:	04c50513          	addi	a0,a0,76 # ffffffffc02073d0 <etext+0x154>
}
ffffffffc020038c:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020038e:	b3c9                	j	ffffffffc0200150 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200390:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200392:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200396:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020039a:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020039e:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003a2:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02003a6:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003aa:	8ed1                	or	a3,a3,a2
ffffffffc02003ac:	0ff77713          	zext.b	a4,a4
ffffffffc02003b0:	8fd5                	or	a5,a5,a3
ffffffffc02003b2:	0722                	slli	a4,a4,0x8
ffffffffc02003b4:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003b6:	04031463          	bnez	t1,ffffffffc02003fe <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02003ba:	1782                	slli	a5,a5,0x20
ffffffffc02003bc:	9381                	srli	a5,a5,0x20
ffffffffc02003be:	043d                	addi	s0,s0,15
ffffffffc02003c0:	943e                	add	s0,s0,a5
ffffffffc02003c2:	9871                	andi	s0,s0,-4
                break;
ffffffffc02003c4:	bfa1                	j	ffffffffc020031c <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02003c6:	8522                	mv	a0,s0
ffffffffc02003c8:	e01a                	sd	t1,0(sp)
ffffffffc02003ca:	615060ef          	jal	ffffffffc02071de <strlen>
ffffffffc02003ce:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003d0:	4619                	li	a2,6
ffffffffc02003d2:	8522                	mv	a0,s0
ffffffffc02003d4:	00007597          	auipc	a1,0x7
ffffffffc02003d8:	02458593          	addi	a1,a1,36 # ffffffffc02073f8 <etext+0x17c>
ffffffffc02003dc:	667060ef          	jal	ffffffffc0207242 <strncmp>
ffffffffc02003e0:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003e2:	0411                	addi	s0,s0,4
ffffffffc02003e4:	0004879b          	sext.w	a5,s1
ffffffffc02003e8:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003ea:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003ee:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f0:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02003f4:	00ff0837          	lui	a6,0xff0
ffffffffc02003f8:	488d                	li	a7,3
ffffffffc02003fa:	4e05                	li	t3,1
ffffffffc02003fc:	b705                	j	ffffffffc020031c <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003fe:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200400:	00007597          	auipc	a1,0x7
ffffffffc0200404:	00058593          	mv	a1,a1
ffffffffc0200408:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020040a:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020040e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200412:	0187169b          	slliw	a3,a4,0x18
ffffffffc0200416:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020041e:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200422:	8ed1                	or	a3,a3,a2
ffffffffc0200424:	0ff77713          	zext.b	a4,a4
ffffffffc0200428:	0722                	slli	a4,a4,0x8
ffffffffc020042a:	8d55                	or	a0,a0,a3
ffffffffc020042c:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020042e:	1502                	slli	a0,a0,0x20
ffffffffc0200430:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200432:	954a                	add	a0,a0,s2
ffffffffc0200434:	e01a                	sd	t1,0(sp)
ffffffffc0200436:	5dd060ef          	jal	ffffffffc0207212 <strcmp>
ffffffffc020043a:	67a2                	ld	a5,8(sp)
ffffffffc020043c:	473d                	li	a4,15
ffffffffc020043e:	6302                	ld	t1,0(sp)
ffffffffc0200440:	00ff0837          	lui	a6,0xff0
ffffffffc0200444:	488d                	li	a7,3
ffffffffc0200446:	4e05                	li	t3,1
ffffffffc0200448:	f6f779e3          	bgeu	a4,a5,ffffffffc02003ba <dtb_init+0x18a>
ffffffffc020044c:	f53d                	bnez	a0,ffffffffc02003ba <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020044e:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200452:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200456:	00007517          	auipc	a0,0x7
ffffffffc020045a:	fb250513          	addi	a0,a0,-78 # ffffffffc0207408 <etext+0x18c>
           fdt32_to_cpu(x >> 32);
ffffffffc020045e:	0206d793          	srli	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200462:	0087d31b          	srliw	t1,a5,0x8
ffffffffc0200466:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020046a:	02075893          	srli	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020046e:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200472:	0187959b          	slliw	a1,a5,0x18
ffffffffc0200476:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047e:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200482:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200486:	01037333          	and	t1,t1,a6
ffffffffc020048a:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020048e:	01e5e5b3          	or	a1,a1,t5
ffffffffc0200492:	0ff7f793          	zext.b	a5,a5
ffffffffc0200496:	01de6e33          	or	t3,t3,t4
ffffffffc020049a:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020049e:	01067633          	and	a2,a2,a6
ffffffffc02004a2:	0086d31b          	srliw	t1,a3,0x8
ffffffffc02004a6:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004aa:	07a2                	slli	a5,a5,0x8
ffffffffc02004ac:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02004b0:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02004b4:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02004b8:	8ddd                	or	a1,a1,a5
ffffffffc02004ba:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004be:	0186979b          	slliw	a5,a3,0x18
ffffffffc02004c2:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c6:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ca:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d2:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d6:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004da:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004de:	08a2                	slli	a7,a7,0x8
ffffffffc02004e0:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e4:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e8:	0ff6f693          	zext.b	a3,a3
ffffffffc02004ec:	01de6833          	or	a6,t3,t4
ffffffffc02004f0:	0ff77713          	zext.b	a4,a4
ffffffffc02004f4:	01166633          	or	a2,a2,a7
ffffffffc02004f8:	0067e7b3          	or	a5,a5,t1
ffffffffc02004fc:	06a2                	slli	a3,a3,0x8
ffffffffc02004fe:	01046433          	or	s0,s0,a6
ffffffffc0200502:	0722                	slli	a4,a4,0x8
ffffffffc0200504:	8fd5                	or	a5,a5,a3
ffffffffc0200506:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200508:	1582                	slli	a1,a1,0x20
ffffffffc020050a:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020050c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020050e:	9201                	srli	a2,a2,0x20
ffffffffc0200510:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200512:	1402                	slli	s0,s0,0x20
ffffffffc0200514:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200518:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc020051a:	c37ff0ef          	jal	ffffffffc0200150 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020051e:	85a6                	mv	a1,s1
ffffffffc0200520:	00007517          	auipc	a0,0x7
ffffffffc0200524:	f0850513          	addi	a0,a0,-248 # ffffffffc0207428 <etext+0x1ac>
ffffffffc0200528:	c29ff0ef          	jal	ffffffffc0200150 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020052c:	01445613          	srli	a2,s0,0x14
ffffffffc0200530:	85a2                	mv	a1,s0
ffffffffc0200532:	00007517          	auipc	a0,0x7
ffffffffc0200536:	f0e50513          	addi	a0,a0,-242 # ffffffffc0207440 <etext+0x1c4>
ffffffffc020053a:	c17ff0ef          	jal	ffffffffc0200150 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020053e:	009405b3          	add	a1,s0,s1
ffffffffc0200542:	15fd                	addi	a1,a1,-1 # ffffffffc02073ff <etext+0x183>
ffffffffc0200544:	00007517          	auipc	a0,0x7
ffffffffc0200548:	f1c50513          	addi	a0,a0,-228 # ffffffffc0207460 <etext+0x1e4>
ffffffffc020054c:	c05ff0ef          	jal	ffffffffc0200150 <cprintf>
        memory_base = mem_base;
ffffffffc0200550:	00027797          	auipc	a5,0x27
ffffffffc0200554:	2697b023          	sd	s1,608(a5) # ffffffffc02277b0 <memory_base>
        memory_size = mem_size;
ffffffffc0200558:	00027797          	auipc	a5,0x27
ffffffffc020055c:	2487b823          	sd	s0,592(a5) # ffffffffc02277a8 <memory_size>
ffffffffc0200560:	b531                	j	ffffffffc020036c <dtb_init+0x13c>

ffffffffc0200562 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200562:	00027517          	auipc	a0,0x27
ffffffffc0200566:	24e53503          	ld	a0,590(a0) # ffffffffc02277b0 <memory_base>
ffffffffc020056a:	8082                	ret

ffffffffc020056c <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc020056c:	00027517          	auipc	a0,0x27
ffffffffc0200570:	23c53503          	ld	a0,572(a0) # ffffffffc02277a8 <memory_size>
ffffffffc0200574:	8082                	ret

ffffffffc0200576 <buddy_init>:
    list_add(&free_lists[order], &base->page_link);
}

static void
buddy_init(void) {
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
ffffffffc0200576:	0000d797          	auipc	a5,0xd
ffffffffc020057a:	4aa78793          	addi	a5,a5,1194 # ffffffffc020da20 <free_lists>
ffffffffc020057e:	0000d717          	auipc	a4,0xd
ffffffffc0200582:	6a270713          	addi	a4,a4,1698 # ffffffffc020dc20 <slub_index>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200586:	e79c                	sd	a5,8(a5)
ffffffffc0200588:	e39c                	sd	a5,0(a5)
ffffffffc020058a:	07c1                	addi	a5,a5,16
ffffffffc020058c:	fee79de3          	bne	a5,a4,ffffffffc0200586 <buddy_init+0x10>
        list_init(&free_lists[k]);
    }
    nr_free = nr_managed = 0;
ffffffffc0200590:	00027797          	auipc	a5,0x27
ffffffffc0200594:	2207b423          	sd	zero,552(a5) # ffffffffc02277b8 <nr_managed>
ffffffffc0200598:	00027797          	auipc	a5,0x27
ffffffffc020059c:	2207b423          	sd	zero,552(a5) # ffffffffc02277c0 <nr_free>
}
ffffffffc02005a0:	8082                	ret

ffffffffc02005a2 <buddy_nr_free_pages>:
}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005a2:	00027517          	auipc	a0,0x27
ffffffffc02005a6:	21e53503          	ld	a0,542(a0) # ffffffffc02277c0 <nr_free>
ffffffffc02005aa:	8082                	ret

ffffffffc02005ac <buddy_test_fingerprint>:
 */
static uint64_t
buddy_test_fingerprint(void) {
    uint64_t hash = 14695981039346656037ULL;
#define BUDDY_TEST_MIX(value) (hash = (hash ^ (uint64_t)(value)) * 1099511628211ULL)
    BUDDY_TEST_MIX(nr_free);
ffffffffc02005ac:	f2fca7b7          	lui	a5,0xf2fca
ffffffffc02005b0:	42111737          	lui	a4,0x42111
ffffffffc02005b4:	00027517          	auipc	a0,0x27
ffffffffc02005b8:	20c53503          	ld	a0,524(a0) # ffffffffc02277c0 <nr_free>
ffffffffc02005bc:	73978793          	addi	a5,a5,1849 # fffffffff2fca739 <end+0x32da2ec1>
ffffffffc02005c0:	0706                	slli	a4,a4,0x1
ffffffffc02005c2:	32570713          	addi	a4,a4,805 # 42111325 <kern_entry-0xffffffff7e0eecdb>
ffffffffc02005c6:	178a                	slli	a5,a5,0x22
ffffffffc02005c8:	4605                	li	a2,1
ffffffffc02005ca:	97ba                	add	a5,a5,a4
ffffffffc02005cc:	1622                	slli	a2,a2,0x28
ffffffffc02005ce:	8d3d                	xor	a0,a0,a5
ffffffffc02005d0:	1b360613          	addi	a2,a2,435
ffffffffc02005d4:	02c50533          	mul	a0,a0,a2
    BUDDY_TEST_MIX(nr_managed);
ffffffffc02005d8:	00027797          	auipc	a5,0x27
ffffffffc02005dc:	1e07b783          	ld	a5,480(a5) # ffffffffc02277b8 <nr_managed>
ffffffffc02005e0:	0000d717          	auipc	a4,0xd
ffffffffc02005e4:	44070713          	addi	a4,a4,1088 # ffffffffc020da20 <free_lists>
ffffffffc02005e8:	0000d597          	auipc	a1,0xd
ffffffffc02005ec:	63858593          	addi	a1,a1,1592 # ffffffffc020dc20 <slub_index>
ffffffffc02005f0:	8d3d                	xor	a0,a0,a5
ffffffffc02005f2:	02c50533          	mul	a0,a0,a2
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
        BUDDY_TEST_MIX((uintptr_t)free_lists[k].next);
ffffffffc02005f6:	671c                	ld	a5,8(a4)
        BUDDY_TEST_MIX((uintptr_t)free_lists[k].prev);
ffffffffc02005f8:	6314                	ld	a3,0(a4)
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
ffffffffc02005fa:	0741                	addi	a4,a4,16
        BUDDY_TEST_MIX((uintptr_t)free_lists[k].next);
ffffffffc02005fc:	8fa9                	xor	a5,a5,a0
ffffffffc02005fe:	02c787b3          	mul	a5,a5,a2
        BUDDY_TEST_MIX((uintptr_t)free_lists[k].prev);
ffffffffc0200602:	8ebd                	xor	a3,a3,a5
ffffffffc0200604:	02c68533          	mul	a0,a3,a2
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
ffffffffc0200608:	feb717e3          	bne	a4,a1,ffffffffc02005f6 <buddy_test_fingerprint+0x4a>
    }
    for (size_t i = 0; i < npage - nbase; i ++) {
ffffffffc020060c:	00027897          	auipc	a7,0x27
ffffffffc0200610:	1dc8b883          	ld	a7,476(a7) # ffffffffc02277e8 <npage>
ffffffffc0200614:	00009797          	auipc	a5,0x9
ffffffffc0200618:	7947b783          	ld	a5,1940(a5) # ffffffffc0209da8 <nbase>
ffffffffc020061c:	04f88963          	beq	a7,a5,ffffffffc020066e <buddy_test_fingerprint+0xc2>
ffffffffc0200620:	40f888b3          	sub	a7,a7,a5
        struct Page *p = pages + i;
        BUDDY_TEST_MIX(p->flags);
ffffffffc0200624:	4605                	li	a2,1
ffffffffc0200626:	00027797          	auipc	a5,0x27
ffffffffc020062a:	1ca7b783          	ld	a5,458(a5) # ffffffffc02277f0 <pages>
ffffffffc020062e:	1622                	slli	a2,a2,0x28
ffffffffc0200630:	1b360613          	addi	a2,a2,435
    for (size_t i = 0; i < npage - nbase; i ++) {
ffffffffc0200634:	4801                	li	a6,0
        BUDDY_TEST_MIX(p->flags);
ffffffffc0200636:	6794                	ld	a3,8(a5)
        BUDDY_TEST_MIX(p->property);
ffffffffc0200638:	0107e703          	lwu	a4,16(a5)
        BUDDY_TEST_MIX(page_ref(p));
ffffffffc020063c:	438c                	lw	a1,0(a5)
        BUDDY_TEST_MIX(p->flags);
ffffffffc020063e:	8d35                	xor	a0,a0,a3
ffffffffc0200640:	02c50533          	mul	a0,a0,a2
        if (p->flags & BUDDY_MANAGED) {
ffffffffc0200644:	8a91                	andi	a3,a3,4
    for (size_t i = 0; i < npage - nbase; i ++) {
ffffffffc0200646:	0805                	addi	a6,a6,1 # ff0001 <kern_entry-0xffffffffbf20ffff>
        BUDDY_TEST_MIX(p->property);
ffffffffc0200648:	8f29                	xor	a4,a4,a0
ffffffffc020064a:	02c70733          	mul	a4,a4,a2
        BUDDY_TEST_MIX(page_ref(p));
ffffffffc020064e:	8db9                	xor	a1,a1,a4
ffffffffc0200650:	02c58533          	mul	a0,a1,a2
        if (p->flags & BUDDY_MANAGED) {
ffffffffc0200654:	ca89                	beqz	a3,ffffffffc0200666 <buddy_test_fingerprint+0xba>
            BUDDY_TEST_MIX((uintptr_t)p->page_link.next);
ffffffffc0200656:	7398                	ld	a4,32(a5)
            BUDDY_TEST_MIX((uintptr_t)p->page_link.prev);
ffffffffc0200658:	6f94                	ld	a3,24(a5)
            BUDDY_TEST_MIX((uintptr_t)p->page_link.next);
ffffffffc020065a:	8f29                	xor	a4,a4,a0
ffffffffc020065c:	02c70733          	mul	a4,a4,a2
            BUDDY_TEST_MIX((uintptr_t)p->page_link.prev);
ffffffffc0200660:	8eb9                	xor	a3,a3,a4
ffffffffc0200662:	02c68533          	mul	a0,a3,a2
    for (size_t i = 0; i < npage - nbase; i ++) {
ffffffffc0200666:	02878793          	addi	a5,a5,40
ffffffffc020066a:	fd1866e3          	bltu	a6,a7,ffffffffc0200636 <buddy_test_fingerprint+0x8a>
        }
    }
#undef BUDDY_TEST_MIX
    return hash;
}
ffffffffc020066e:	8082                	ret

ffffffffc0200670 <buddy_page_index>:
    assert(pages != NULL && npage > nbase);
ffffffffc0200670:	00027797          	auipc	a5,0x27
ffffffffc0200674:	1807b783          	ld	a5,384(a5) # ffffffffc02277f0 <pages>
buddy_page_index(struct Page *page) {
ffffffffc0200678:	1141                	addi	sp,sp,-16
ffffffffc020067a:	e406                	sd	ra,8(sp)
    assert(pages != NULL && npage > nbase);
ffffffffc020067c:	c7a9                	beqz	a5,ffffffffc02006c6 <buddy_page_index+0x56>
ffffffffc020067e:	00027697          	auipc	a3,0x27
ffffffffc0200682:	16a6b683          	ld	a3,362(a3) # ffffffffc02277e8 <npage>
ffffffffc0200686:	00009617          	auipc	a2,0x9
ffffffffc020068a:	72263603          	ld	a2,1826(a2) # ffffffffc0209da8 <nbase>
ffffffffc020068e:	02d67c63          	bgeu	a2,a3,ffffffffc02006c6 <buddy_page_index+0x56>
    assert(addr >= start);
ffffffffc0200692:	08f56963          	bltu	a0,a5,ffffffffc0200724 <buddy_page_index+0xb4>
    uintptr_t offset = addr - start;
ffffffffc0200696:	ccccd737          	lui	a4,0xccccd
ffffffffc020069a:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcaa5455>
ffffffffc020069e:	40f507b3          	sub	a5,a0,a5
ffffffffc02006a2:	02071513          	slli	a0,a4,0x20
ffffffffc02006a6:	953a                	add	a0,a0,a4
ffffffffc02006a8:	02a7b533          	mulhu	a0,a5,a0
ffffffffc02006ac:	8115                	srli	a0,a0,0x5
ffffffffc02006ae:	00251713          	slli	a4,a0,0x2
ffffffffc02006b2:	972a                	add	a4,a4,a0
ffffffffc02006b4:	070e                	slli	a4,a4,0x3
    assert(offset % sizeof(struct Page) == 0);
ffffffffc02006b6:	04e79763          	bne	a5,a4,ffffffffc0200704 <buddy_page_index+0x94>
    assert(index < npage - nbase);
ffffffffc02006ba:	8e91                	sub	a3,a3,a2
ffffffffc02006bc:	02d57463          	bgeu	a0,a3,ffffffffc02006e4 <buddy_page_index+0x74>
}
ffffffffc02006c0:	60a2                	ld	ra,8(sp)
ffffffffc02006c2:	0141                	addi	sp,sp,16
ffffffffc02006c4:	8082                	ret
    assert(pages != NULL && npage > nbase);
ffffffffc02006c6:	00007697          	auipc	a3,0x7
ffffffffc02006ca:	e0268693          	addi	a3,a3,-510 # ffffffffc02074c8 <etext+0x24c>
ffffffffc02006ce:	00007617          	auipc	a2,0x7
ffffffffc02006d2:	e1a60613          	addi	a2,a2,-486 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02006d6:	45f1                	li	a1,28
ffffffffc02006d8:	00007517          	auipc	a0,0x7
ffffffffc02006dc:	e2850513          	addi	a0,a0,-472 # ffffffffc0207500 <etext+0x284>
ffffffffc02006e0:	af1ff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(index < npage - nbase);
ffffffffc02006e4:	00007697          	auipc	a3,0x7
ffffffffc02006e8:	e6c68693          	addi	a3,a3,-404 # ffffffffc0207550 <etext+0x2d4>
ffffffffc02006ec:	00007617          	auipc	a2,0x7
ffffffffc02006f0:	dfc60613          	addi	a2,a2,-516 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02006f4:	02200593          	li	a1,34
ffffffffc02006f8:	00007517          	auipc	a0,0x7
ffffffffc02006fc:	e0850513          	addi	a0,a0,-504 # ffffffffc0207500 <etext+0x284>
ffffffffc0200700:	ad1ff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(offset % sizeof(struct Page) == 0);
ffffffffc0200704:	00007697          	auipc	a3,0x7
ffffffffc0200708:	e2468693          	addi	a3,a3,-476 # ffffffffc0207528 <etext+0x2ac>
ffffffffc020070c:	00007617          	auipc	a2,0x7
ffffffffc0200710:	ddc60613          	addi	a2,a2,-548 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200714:	02000593          	li	a1,32
ffffffffc0200718:	00007517          	auipc	a0,0x7
ffffffffc020071c:	de850513          	addi	a0,a0,-536 # ffffffffc0207500 <etext+0x284>
ffffffffc0200720:	ab1ff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(addr >= start);
ffffffffc0200724:	00007697          	auipc	a3,0x7
ffffffffc0200728:	df468693          	addi	a3,a3,-524 # ffffffffc0207518 <etext+0x29c>
ffffffffc020072c:	00007617          	auipc	a2,0x7
ffffffffc0200730:	dbc60613          	addi	a2,a2,-580 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200734:	45f9                	li	a1,30
ffffffffc0200736:	00007517          	auipc	a0,0x7
ffffffffc020073a:	dca50513          	addi	a0,a0,-566 # ffffffffc0207500 <etext+0x284>
ffffffffc020073e:	a93ff0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0200742 <buddy_find_partner>:
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200742:	00027717          	auipc	a4,0x27
ffffffffc0200746:	0ae73703          	ld	a4,174(a4) # ffffffffc02277f0 <pages>
ffffffffc020074a:	ccccd6b7          	lui	a3,0xccccd
ffffffffc020074e:	ccd68693          	addi	a3,a3,-819 # ffffffffcccccccd <end+0xcaa5455>
ffffffffc0200752:	02069613          	slli	a2,a3,0x20
ffffffffc0200756:	40e507b3          	sub	a5,a0,a4
ffffffffc020075a:	9636                	add	a2,a2,a3
ffffffffc020075c:	878d                	srai	a5,a5,0x3
ffffffffc020075e:	02c787b3          	mul	a5,a5,a2
ffffffffc0200762:	00009617          	auipc	a2,0x9
ffffffffc0200766:	64663603          	ld	a2,1606(a2) # ffffffffc0209da8 <nbase>
    return (size_t)1 << order;
ffffffffc020076a:	4685                	li	a3,1
ffffffffc020076c:	00b695b3          	sll	a1,a3,a1
ffffffffc0200770:	97b2                	add	a5,a5,a2
    ppn_t partner_ppn = page2ppn(base) ^ length;
ffffffffc0200772:	8fad                	xor	a5,a5,a1
    if (partner_ppn < nbase || partner_ppn >= npage ||
ffffffffc0200774:	02c7e763          	bltu	a5,a2,ffffffffc02007a2 <buddy_find_partner+0x60>
ffffffffc0200778:	00027697          	auipc	a3,0x27
ffffffffc020077c:	0706b683          	ld	a3,112(a3) # ffffffffc02277e8 <npage>
ffffffffc0200780:	02d7f163          	bgeu	a5,a3,ffffffffc02007a2 <buddy_find_partner+0x60>
        length > npage - partner_ppn) {
ffffffffc0200784:	8e9d                	sub	a3,a3,a5
    if (partner_ppn < nbase || partner_ppn >= npage ||
ffffffffc0200786:	00b6ee63          	bltu	a3,a1,ffffffffc02007a2 <buddy_find_partner+0x60>
    struct Page *partner = pages + (partner_ppn - nbase);
ffffffffc020078a:	8f91                	sub	a5,a5,a2
ffffffffc020078c:	00279693          	slli	a3,a5,0x2
ffffffffc0200790:	97b6                	add	a5,a5,a3
ffffffffc0200792:	078e                	slli	a5,a5,0x3
ffffffffc0200794:	00f70533          	add	a0,a4,a5
        (partner->flags & BUDDY_ALLOCATED) || PageReserved(partner) ||
ffffffffc0200798:	651c                	ld	a5,8(a0)
ffffffffc020079a:	4719                	li	a4,6
ffffffffc020079c:	8bbd                	andi	a5,a5,15
ffffffffc020079e:	00e78463          	beq	a5,a4,ffffffffc02007a6 <buddy_find_partner+0x64>
        return NULL;
ffffffffc02007a2:	4501                	li	a0,0
}
ffffffffc02007a4:	8082                	ret
        !PageProperty(partner) || partner->property != length) {
ffffffffc02007a6:	01056783          	lwu	a5,16(a0)
ffffffffc02007aa:	feb79ce3          	bne	a5,a1,ffffffffc02007a2 <buddy_find_partner+0x60>
}
ffffffffc02007ae:	8082                	ret

ffffffffc02007b0 <buddy_insert_block>:
buddy_insert_block(struct Page *base, unsigned int order) {
ffffffffc02007b0:	7139                	addi	sp,sp,-64
ffffffffc02007b2:	f04a                	sd	s2,32(sp)
ffffffffc02007b4:	ec4e                	sd	s3,24(sp)
ffffffffc02007b6:	e852                	sd	s4,16(sp)
ffffffffc02007b8:	fc06                	sd	ra,56(sp)
    while (order < BUDDY_MAX_ORDER) {
ffffffffc02007ba:	497d                	li	s2,31
buddy_insert_block(struct Page *base, unsigned int order) {
ffffffffc02007bc:	89ae                	mv	s3,a1
ffffffffc02007be:	8a2a                	mv	s4,a0
    while (order < BUDDY_MAX_ORDER) {
ffffffffc02007c0:	0f258063          	beq	a1,s2,ffffffffc02008a0 <buddy_insert_block+0xf0>
ffffffffc02007c4:	ccccd7b7          	lui	a5,0xccccd
ffffffffc02007c8:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcaa5455>
ffffffffc02007cc:	f426                	sd	s1,40(sp)
ffffffffc02007ce:	e456                	sd	s5,8(sp)
ffffffffc02007d0:	00009497          	auipc	s1,0x9
ffffffffc02007d4:	5d84b483          	ld	s1,1496(s1) # ffffffffc0209da8 <nbase>
ffffffffc02007d8:	00027a97          	auipc	s5,0x27
ffffffffc02007dc:	018aba83          	ld	s5,24(s5) # ffffffffc02277f0 <pages>
ffffffffc02007e0:	f822                	sd	s0,48(sp)
ffffffffc02007e2:	02079413          	slli	s0,a5,0x20
ffffffffc02007e6:	943e                	add	s0,s0,a5
        struct Page *partner = buddy_find_partner(base, order);
ffffffffc02007e8:	85ce                	mv	a1,s3
ffffffffc02007ea:	8552                	mv	a0,s4
ffffffffc02007ec:	f57ff0ef          	jal	ffffffffc0200742 <buddy_find_partner>
ffffffffc02007f0:	415a07b3          	sub	a5,s4,s5
ffffffffc02007f4:	41550733          	sub	a4,a0,s5
ffffffffc02007f8:	878d                	srai	a5,a5,0x3
ffffffffc02007fa:	870d                	srai	a4,a4,0x3
        list_del_init(&partner->page_link);
ffffffffc02007fc:	01850613          	addi	a2,a0,24
        if (partner == NULL) {
ffffffffc0200800:	c159                	beqz	a0,ffffffffc0200886 <buddy_insert_block+0xd6>
ffffffffc0200802:	028787b3          	mul	a5,a5,s0
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
ffffffffc0200806:	01853803          	ld	a6,24(a0)
ffffffffc020080a:	710c                	ld	a1,32(a0)
        ClearPageProperty(partner);
ffffffffc020080c:	6514                	ld	a3,8(a0)
        order ++;
ffffffffc020080e:	2985                	addiw	s3,s3,1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200810:	00b83423          	sd	a1,8(a6)
    next->prev = prev;
ffffffffc0200814:	0105b023          	sd	a6,0(a1)
        ClearPageProperty(partner);
ffffffffc0200818:	9af5                	andi	a3,a3,-3
    elm->prev = elm->next = elm;
ffffffffc020081a:	f110                	sd	a2,32(a0)
ffffffffc020081c:	ed10                	sd	a2,24(a0)
ffffffffc020081e:	02870733          	mul	a4,a4,s0
ffffffffc0200822:	97a6                	add	a5,a5,s1
        partner->property = 0;
ffffffffc0200824:	00052823          	sw	zero,16(a0)
        ClearPageProperty(partner);
ffffffffc0200828:	e514                	sd	a3,8(a0)
ffffffffc020082a:	9726                	add	a4,a4,s1
        if (page2ppn(partner) < page2ppn(base)) {
ffffffffc020082c:	00f77363          	bgeu	a4,a5,ffffffffc0200832 <buddy_insert_block+0x82>
            base = partner;
ffffffffc0200830:	8a2a                	mv	s4,a0
    while (order < BUDDY_MAX_ORDER) {
ffffffffc0200832:	fb299be3          	bne	s3,s2,ffffffffc02007e8 <buddy_insert_block+0x38>
ffffffffc0200836:	7442                	ld	s0,48(sp)
ffffffffc0200838:	74a2                	ld	s1,40(sp)
ffffffffc020083a:	6aa2                	ld	s5,8(sp)
ffffffffc020083c:	02099793          	slli	a5,s3,0x20
ffffffffc0200840:	9381                	srli	a5,a5,0x20
ffffffffc0200842:	1f000713          	li	a4,496
ffffffffc0200846:	800006b7          	lui	a3,0x80000
    base->property = buddy_block_size(order);
ffffffffc020084a:	00da2823          	sw	a3,16(s4)
    __list_add(elm, listelm, listelm->next);
ffffffffc020084e:	0000d597          	auipc	a1,0xd
ffffffffc0200852:	1d258593          	addi	a1,a1,466 # ffffffffc020da20 <free_lists>
    SetPageProperty(base);
ffffffffc0200856:	008a3683          	ld	a3,8(s4)
ffffffffc020085a:	0792                	slli	a5,a5,0x4
ffffffffc020085c:	97ae                	add	a5,a5,a1
ffffffffc020085e:	6790                	ld	a2,8(a5)
ffffffffc0200860:	0026e693          	ori	a3,a3,2
ffffffffc0200864:	00da3423          	sd	a3,8(s4)
    list_add(&free_lists[order], &base->page_link);
ffffffffc0200868:	018a0693          	addi	a3,s4,24
    prev->next = next->prev = elm;
ffffffffc020086c:	e214                	sd	a3,0(a2)
}
ffffffffc020086e:	70e2                	ld	ra,56(sp)
ffffffffc0200870:	e794                	sd	a3,8(a5)
    list_add(&free_lists[order], &base->page_link);
ffffffffc0200872:	972e                	add	a4,a4,a1
    elm->prev = prev;
ffffffffc0200874:	00ea3c23          	sd	a4,24(s4)
    elm->next = next;
ffffffffc0200878:	02ca3023          	sd	a2,32(s4)
}
ffffffffc020087c:	7902                	ld	s2,32(sp)
ffffffffc020087e:	69e2                	ld	s3,24(sp)
ffffffffc0200880:	6a42                	ld	s4,16(sp)
ffffffffc0200882:	6121                	addi	sp,sp,64
ffffffffc0200884:	8082                	ret
ffffffffc0200886:	02099793          	slli	a5,s3,0x20
    return (size_t)1 << order;
ffffffffc020088a:	4685                	li	a3,1
ffffffffc020088c:	9381                	srli	a5,a5,0x20
ffffffffc020088e:	013696b3          	sll	a3,a3,s3
ffffffffc0200892:	7442                	ld	s0,48(sp)
ffffffffc0200894:	74a2                	ld	s1,40(sp)
ffffffffc0200896:	6aa2                	ld	s5,8(sp)
    base->property = buddy_block_size(order);
ffffffffc0200898:	2681                	sext.w	a3,a3
ffffffffc020089a:	00479713          	slli	a4,a5,0x4
ffffffffc020089e:	b775                	j	ffffffffc020084a <buddy_insert_block+0x9a>
ffffffffc02008a0:	87ae                	mv	a5,a1
    while (order < BUDDY_MAX_ORDER) {
ffffffffc02008a2:	1f000713          	li	a4,496
ffffffffc02008a6:	800006b7          	lui	a3,0x80000
ffffffffc02008aa:	b745                	j	ffffffffc020084a <buddy_insert_block+0x9a>

ffffffffc02008ac <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc02008ac:	711d                	addi	sp,sp,-96
ffffffffc02008ae:	e4a6                	sd	s1,72(sp)
ffffffffc02008b0:	84ae                	mv	s1,a1
ffffffffc02008b2:	ec5e                	sd	s7,24(sp)
ffffffffc02008b4:	ec86                	sd	ra,88(sp)
ffffffffc02008b6:	e8a2                	sd	s0,80(sp)
ffffffffc02008b8:	e0ca                	sd	s2,64(sp)
ffffffffc02008ba:	fc4e                	sd	s3,56(sp)
ffffffffc02008bc:	f852                	sd	s4,48(sp)
ffffffffc02008be:	f456                	sd	s5,40(sp)
ffffffffc02008c0:	f05a                	sd	s6,32(sp)
ffffffffc02008c2:	e862                	sd	s8,16(sp)
ffffffffc02008c4:	e466                	sd	s9,8(sp)
ffffffffc02008c6:	8baa                	mv	s7,a0
    size_t index = buddy_page_index(base);
ffffffffc02008c8:	da9ff0ef          	jal	ffffffffc0200670 <buddy_page_index>
    assert(n > 0 && n <= npage - nbase - index);
ffffffffc02008cc:	18048963          	beqz	s1,ffffffffc0200a5e <buddy_init_memmap+0x1b2>
ffffffffc02008d0:	00009917          	auipc	s2,0x9
ffffffffc02008d4:	4d893903          	ld	s2,1240(s2) # ffffffffc0209da8 <nbase>
ffffffffc02008d8:	00027797          	auipc	a5,0x27
ffffffffc02008dc:	f107b783          	ld	a5,-240(a5) # ffffffffc02277e8 <npage>
ffffffffc02008e0:	008b8713          	addi	a4,s7,8
    for (size_t i = 0; i < n; i ++) {
ffffffffc02008e4:	4401                	li	s0,0
    assert(n > 0 && n <= npage - nbase - index);
ffffffffc02008e6:	412787b3          	sub	a5,a5,s2
ffffffffc02008ea:	8f89                	sub	a5,a5,a0
ffffffffc02008ec:	1697e963          	bltu	a5,s1,ffffffffc0200a5e <buddy_init_memmap+0x1b2>
        assert(PageReserved(base + i));
ffffffffc02008f0:	631c                	ld	a5,0(a4)
ffffffffc02008f2:	0017f693          	andi	a3,a5,1
ffffffffc02008f6:	14068463          	beqz	a3,ffffffffc0200a3e <buddy_init_memmap+0x192>
        assert(!(base[i].flags & BUDDY_MANAGED));
ffffffffc02008fa:	8b91                	andi	a5,a5,4
ffffffffc02008fc:	12079163          	bnez	a5,ffffffffc0200a1e <buddy_init_memmap+0x172>
    for (size_t i = 0; i < n; i ++) {
ffffffffc0200900:	0405                	addi	s0,s0,1
ffffffffc0200902:	02870713          	addi	a4,a4,40
ffffffffc0200906:	fe8495e3          	bne	s1,s0,ffffffffc02008f0 <buddy_init_memmap+0x44>
ffffffffc020090a:	00241713          	slli	a4,s0,0x2
ffffffffc020090e:	9722                	add	a4,a4,s0
ffffffffc0200910:	070e                	slli	a4,a4,0x3
ffffffffc0200912:	0761                	addi	a4,a4,24
ffffffffc0200914:	975e                	add	a4,a4,s7
ffffffffc0200916:	018b8793          	addi	a5,s7,24
        base[i].flags = BUDDY_MANAGED;
ffffffffc020091a:	4691                	li	a3,4
ffffffffc020091c:	fed7b823          	sd	a3,-16(a5)
        base[i].property = 0;
ffffffffc0200920:	fe07ac23          	sw	zero,-8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200924:	fe07a423          	sw	zero,-24(a5)
    elm->prev = elm->next = elm;
ffffffffc0200928:	e79c                	sd	a5,8(a5)
ffffffffc020092a:	e39c                	sd	a5,0(a5)
    for (size_t i = 0; i < n; i ++) {
ffffffffc020092c:	02878793          	addi	a5,a5,40
ffffffffc0200930:	fee796e3          	bne	a5,a4,ffffffffc020091c <buddy_init_memmap+0x70>
    nr_free += n;
ffffffffc0200934:	00027697          	auipc	a3,0x27
ffffffffc0200938:	e8c6b683          	ld	a3,-372(a3) # ffffffffc02277c0 <nr_free>
    nr_managed += n;
ffffffffc020093c:	00027717          	auipc	a4,0x27
ffffffffc0200940:	e7c73703          	ld	a4,-388(a4) # ffffffffc02277b8 <nr_managed>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200944:	ccccd7b7          	lui	a5,0xccccd
ffffffffc0200948:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcaa5455>
ffffffffc020094c:	00027997          	auipc	s3,0x27
ffffffffc0200950:	ea49b983          	ld	s3,-348(s3) # ffffffffc02277f0 <pages>
ffffffffc0200954:	02079493          	slli	s1,a5,0x20
    nr_free += n;
ffffffffc0200958:	96a2                	add	a3,a3,s0
    nr_managed += n;
ffffffffc020095a:	9722                	add	a4,a4,s0
ffffffffc020095c:	94be                	add	s1,s1,a5
        while (order < BUDDY_MAX_ORDER &&
ffffffffc020095e:	4a85                	li	s5,1
    nr_free += n;
ffffffffc0200960:	00027797          	auipc	a5,0x27
ffffffffc0200964:	e6d7b023          	sd	a3,-416(a5) # ffffffffc02277c0 <nr_free>
    nr_managed += n;
ffffffffc0200968:	00027797          	auipc	a5,0x27
ffffffffc020096c:	e4e7b823          	sd	a4,-432(a5) # ffffffffc02277b8 <nr_managed>
               buddy_block_size(order + 1) <= remaining &&
ffffffffc0200970:	4b7d                	li	s6,31
        base += length;
ffffffffc0200972:	02800a13          	li	s4,40
        while (order < BUDDY_MAX_ORDER &&
ffffffffc0200976:	05540663          	beq	s0,s5,ffffffffc02009c2 <buddy_init_memmap+0x116>
ffffffffc020097a:	413b8733          	sub	a4,s7,s3
ffffffffc020097e:	870d                	srai	a4,a4,0x3
ffffffffc0200980:	02970733          	mul	a4,a4,s1
ffffffffc0200984:	974a                	add	a4,a4,s2
               (ppn & (buddy_block_size(order + 1) - 1)) == 0) {
ffffffffc0200986:	00177793          	andi	a5,a4,1
               buddy_block_size(order + 1) <= remaining &&
ffffffffc020098a:	e3d1                	bnez	a5,ffffffffc0200a0e <buddy_init_memmap+0x162>
ffffffffc020098c:	4585                	li	a1,1
ffffffffc020098e:	a031                	j	ffffffffc020099a <buddy_init_memmap+0xee>
               (ppn & (buddy_block_size(order + 1) - 1)) == 0) {
ffffffffc0200990:	17fd                	addi	a5,a5,-1
ffffffffc0200992:	8ff9                	and	a5,a5,a4
               buddy_block_size(order + 1) <= remaining &&
ffffffffc0200994:	eb89                	bnez	a5,ffffffffc02009a6 <buddy_init_memmap+0xfa>
ffffffffc0200996:	05658563          	beq	a1,s6,ffffffffc02009e0 <buddy_init_memmap+0x134>
ffffffffc020099a:	86ae                	mv	a3,a1
ffffffffc020099c:	2585                	addiw	a1,a1,1
    return (size_t)1 << order;
ffffffffc020099e:	00ba97b3          	sll	a5,s5,a1
        while (order < BUDDY_MAX_ORDER &&
ffffffffc02009a2:	fef477e3          	bgeu	s0,a5,ffffffffc0200990 <buddy_init_memmap+0xe4>
    return (size_t)1 << order;
ffffffffc02009a6:	00da9cb3          	sll	s9,s5,a3
ffffffffc02009aa:	85b6                	mv	a1,a3
        buddy_insert_block(base, order);
ffffffffc02009ac:	855e                	mv	a0,s7
        remaining -= length;
ffffffffc02009ae:	41940433          	sub	s0,s0,s9
        base += length;
ffffffffc02009b2:	00da1c33          	sll	s8,s4,a3
        buddy_insert_block(base, order);
ffffffffc02009b6:	dfbff0ef          	jal	ffffffffc02007b0 <buddy_insert_block>
    while (remaining > 0) {
ffffffffc02009ba:	cc0d                	beqz	s0,ffffffffc02009f4 <buddy_init_memmap+0x148>
        base += length;
ffffffffc02009bc:	9be2                	add	s7,s7,s8
        while (order < BUDDY_MAX_ORDER &&
ffffffffc02009be:	fb541ee3          	bne	s0,s5,ffffffffc020097a <buddy_init_memmap+0xce>
}
ffffffffc02009c2:	6446                	ld	s0,80(sp)
ffffffffc02009c4:	60e6                	ld	ra,88(sp)
ffffffffc02009c6:	64a6                	ld	s1,72(sp)
ffffffffc02009c8:	6906                	ld	s2,64(sp)
ffffffffc02009ca:	79e2                	ld	s3,56(sp)
ffffffffc02009cc:	7a42                	ld	s4,48(sp)
ffffffffc02009ce:	7aa2                	ld	s5,40(sp)
ffffffffc02009d0:	7b02                	ld	s6,32(sp)
ffffffffc02009d2:	6c42                	ld	s8,16(sp)
ffffffffc02009d4:	6ca2                	ld	s9,8(sp)
        buddy_insert_block(base, order);
ffffffffc02009d6:	855e                	mv	a0,s7
}
ffffffffc02009d8:	6be2                	ld	s7,24(sp)
        buddy_insert_block(base, order);
ffffffffc02009da:	4581                	li	a1,0
}
ffffffffc02009dc:	6125                	addi	sp,sp,96
        buddy_insert_block(base, order);
ffffffffc02009de:	bbc9                	j	ffffffffc02007b0 <buddy_insert_block>
ffffffffc02009e0:	01fa9c93          	slli	s9,s5,0x1f
ffffffffc02009e4:	4c15                	li	s8,5
ffffffffc02009e6:	855e                	mv	a0,s7
        remaining -= length;
ffffffffc02009e8:	41940433          	sub	s0,s0,s9
ffffffffc02009ec:	1c0a                	slli	s8,s8,0x22
        buddy_insert_block(base, order);
ffffffffc02009ee:	dc3ff0ef          	jal	ffffffffc02007b0 <buddy_insert_block>
    while (remaining > 0) {
ffffffffc02009f2:	f469                	bnez	s0,ffffffffc02009bc <buddy_init_memmap+0x110>
}
ffffffffc02009f4:	60e6                	ld	ra,88(sp)
ffffffffc02009f6:	6446                	ld	s0,80(sp)
ffffffffc02009f8:	64a6                	ld	s1,72(sp)
ffffffffc02009fa:	6906                	ld	s2,64(sp)
ffffffffc02009fc:	79e2                	ld	s3,56(sp)
ffffffffc02009fe:	7a42                	ld	s4,48(sp)
ffffffffc0200a00:	7aa2                	ld	s5,40(sp)
ffffffffc0200a02:	7b02                	ld	s6,32(sp)
ffffffffc0200a04:	6be2                	ld	s7,24(sp)
ffffffffc0200a06:	6c42                	ld	s8,16(sp)
ffffffffc0200a08:	6ca2                	ld	s9,8(sp)
ffffffffc0200a0a:	6125                	addi	sp,sp,96
ffffffffc0200a0c:	8082                	ret
        buddy_insert_block(base, order);
ffffffffc0200a0e:	855e                	mv	a0,s7
ffffffffc0200a10:	4581                	li	a1,0
ffffffffc0200a12:	d9fff0ef          	jal	ffffffffc02007b0 <buddy_insert_block>
        base += length;
ffffffffc0200a16:	028b8b93          	addi	s7,s7,40
        remaining -= length;
ffffffffc0200a1a:	147d                	addi	s0,s0,-1
    while (remaining > 0) {
ffffffffc0200a1c:	bfa9                	j	ffffffffc0200976 <buddy_init_memmap+0xca>
        assert(!(base[i].flags & BUDDY_MANAGED));
ffffffffc0200a1e:	00007697          	auipc	a3,0x7
ffffffffc0200a22:	baa68693          	addi	a3,a3,-1110 # ffffffffc02075c8 <etext+0x34c>
ffffffffc0200a26:	00007617          	auipc	a2,0x7
ffffffffc0200a2a:	ac260613          	addi	a2,a2,-1342 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200a2e:	06f00593          	li	a1,111
ffffffffc0200a32:	00007517          	auipc	a0,0x7
ffffffffc0200a36:	ace50513          	addi	a0,a0,-1330 # ffffffffc0207500 <etext+0x284>
ffffffffc0200a3a:	f96ff0ef          	jal	ffffffffc02001d0 <__panic>
        assert(PageReserved(base + i));
ffffffffc0200a3e:	00007697          	auipc	a3,0x7
ffffffffc0200a42:	b7268693          	addi	a3,a3,-1166 # ffffffffc02075b0 <etext+0x334>
ffffffffc0200a46:	00007617          	auipc	a2,0x7
ffffffffc0200a4a:	aa260613          	addi	a2,a2,-1374 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200a4e:	06e00593          	li	a1,110
ffffffffc0200a52:	00007517          	auipc	a0,0x7
ffffffffc0200a56:	aae50513          	addi	a0,a0,-1362 # ffffffffc0207500 <etext+0x284>
ffffffffc0200a5a:	f76ff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(n > 0 && n <= npage - nbase - index);
ffffffffc0200a5e:	00007697          	auipc	a3,0x7
ffffffffc0200a62:	b2a68693          	addi	a3,a3,-1238 # ffffffffc0207588 <etext+0x30c>
ffffffffc0200a66:	00007617          	auipc	a2,0x7
ffffffffc0200a6a:	a8260613          	addi	a2,a2,-1406 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200a6e:	02900593          	li	a1,41
ffffffffc0200a72:	00007517          	auipc	a0,0x7
ffffffffc0200a76:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0207500 <etext+0x284>
ffffffffc0200a7a:	f56ff0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0200a7e <buddy_alloc_pages>:
buddy_alloc_pages(size_t n) {
ffffffffc0200a7e:	1141                	addi	sp,sp,-16
ffffffffc0200a80:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200a82:	14050563          	beqz	a0,ffffffffc0200bcc <buddy_alloc_pages+0x14e>
    if (n > buddy_block_size(BUDDY_MAX_ORDER)) {
ffffffffc0200a86:	4705                	li	a4,1
ffffffffc0200a88:	01f71793          	slli	a5,a4,0x1f
ffffffffc0200a8c:	04a7e763          	bltu	a5,a0,ffffffffc0200ada <buddy_alloc_pages+0x5c>
    unsigned int k = 0;
ffffffffc0200a90:	4781                	li	a5,0
    assert(order <= BUDDY_MAX_ORDER);
ffffffffc0200a92:	02000693          	li	a3,32
ffffffffc0200a96:	a021                	j	ffffffffc0200a9e <buddy_alloc_pages+0x20>
        k ++;
ffffffffc0200a98:	2785                	addiw	a5,a5,1
    assert(order <= BUDDY_MAX_ORDER);
ffffffffc0200a9a:	10d78a63          	beq	a5,a3,ffffffffc0200bae <buddy_alloc_pages+0x130>
    return (size_t)1 << order;
ffffffffc0200a9e:	00f71633          	sll	a2,a4,a5
    while (buddy_block_size(k) < n) {
ffffffffc0200aa2:	fea66be3          	bltu	a2,a0,ffffffffc0200a98 <buddy_alloc_pages+0x1a>
    if (length > nr_free) {
ffffffffc0200aa6:	00027f17          	auipc	t5,0x27
ffffffffc0200aaa:	d1af3f03          	ld	t5,-742(t5) # ffffffffc02277c0 <nr_free>
ffffffffc0200aae:	02cf6663          	bltu	t5,a2,ffffffffc0200ada <buddy_alloc_pages+0x5c>
ffffffffc0200ab2:	02079693          	slli	a3,a5,0x20
ffffffffc0200ab6:	01c6d713          	srli	a4,a3,0x1c
ffffffffc0200aba:	0000d597          	auipc	a1,0xd
ffffffffc0200abe:	f6658593          	addi	a1,a1,-154 # ffffffffc020da20 <free_lists>
ffffffffc0200ac2:	972e                	add	a4,a4,a1
    unsigned int order = requested_order;
ffffffffc0200ac4:	86be                	mv	a3,a5
    while (order <= BUDDY_MAX_ORDER && list_empty(&free_lists[order])) {
ffffffffc0200ac6:	02000893          	li	a7,32
ffffffffc0200aca:	00873803          	ld	a6,8(a4)
ffffffffc0200ace:	00e81b63          	bne	a6,a4,ffffffffc0200ae4 <buddy_alloc_pages+0x66>
        order ++;
ffffffffc0200ad2:	2685                	addiw	a3,a3,1
    while (order <= BUDDY_MAX_ORDER && list_empty(&free_lists[order])) {
ffffffffc0200ad4:	0741                	addi	a4,a4,16
ffffffffc0200ad6:	ff169ae3          	bne	a3,a7,ffffffffc0200aca <buddy_alloc_pages+0x4c>
}
ffffffffc0200ada:	60a2                	ld	ra,8(sp)
        return NULL;
ffffffffc0200adc:	4e81                	li	t4,0
}
ffffffffc0200ade:	8576                	mv	a0,t4
ffffffffc0200ae0:	0141                	addi	sp,sp,16
ffffffffc0200ae2:	8082                	ret
    return listelm->next;
ffffffffc0200ae4:	02069813          	slli	a6,a3,0x20
ffffffffc0200ae8:	01c85713          	srli	a4,a6,0x1c
ffffffffc0200aec:	972e                	add	a4,a4,a1
ffffffffc0200aee:	00873e03          	ld	t3,8(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200af2:	000e3883          	ld	a7,0(t3)
ffffffffc0200af6:	008e3803          	ld	a6,8(t3)
    ClearPageProperty(base);
ffffffffc0200afa:	ff0e3703          	ld	a4,-16(t3)
    struct Page *base = le2page(list_next(&free_lists[order]), page_link);
ffffffffc0200afe:	fe8e0e93          	addi	t4,t3,-24
    prev->next = next;
ffffffffc0200b02:	0108b423          	sd	a6,8(a7)
    next->prev = prev;
ffffffffc0200b06:	01183023          	sd	a7,0(a6)
    ClearPageProperty(base);
ffffffffc0200b0a:	9b75                	andi	a4,a4,-3
    elm->prev = elm->next = elm;
ffffffffc0200b0c:	01ce3423          	sd	t3,8(t3)
ffffffffc0200b10:	01ce3023          	sd	t3,0(t3)
ffffffffc0200b14:	feee3823          	sd	a4,-16(t3)
    while (order > requested_order) {
ffffffffc0200b18:	04d7f863          	bgeu	a5,a3,ffffffffc0200b68 <buddy_alloc_pages+0xea>
ffffffffc0200b1c:	36fd                	addiw	a3,a3,-1
ffffffffc0200b1e:	02069813          	slli	a6,a3,0x20
ffffffffc0200b22:	01c85713          	srli	a4,a6,0x1c
ffffffffc0200b26:	95ba                	add	a1,a1,a4
        struct Page *upper = base + buddy_block_size(order);
ffffffffc0200b28:	02800293          	li	t0,40
    return (size_t)1 << order;
ffffffffc0200b2c:	4f85                	li	t6,1
ffffffffc0200b2e:	a011                	j	ffffffffc0200b32 <buddy_alloc_pages+0xb4>
ffffffffc0200b30:	36fd                	addiw	a3,a3,-1
        struct Page *upper = base + buddy_block_size(order);
ffffffffc0200b32:	00d29733          	sll	a4,t0,a3
ffffffffc0200b36:	9776                	add	a4,a4,t4
        SetPageProperty(upper);
ffffffffc0200b38:	00873803          	ld	a6,8(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200b3c:	0085b303          	ld	t1,8(a1)
    return (size_t)1 << order;
ffffffffc0200b40:	00df98b3          	sll	a7,t6,a3
        SetPageProperty(upper);
ffffffffc0200b44:	00286813          	ori	a6,a6,2
ffffffffc0200b48:	01073423          	sd	a6,8(a4)
        upper->property = buddy_block_size(order);
ffffffffc0200b4c:	01172823          	sw	a7,16(a4)
        list_add(&free_lists[order], &upper->page_link);
ffffffffc0200b50:	01870813          	addi	a6,a4,24
    prev->next = next->prev = elm;
ffffffffc0200b54:	01033023          	sd	a6,0(t1)
ffffffffc0200b58:	0105b423          	sd	a6,8(a1)
    elm->prev = prev;
ffffffffc0200b5c:	ef0c                	sd	a1,24(a4)
    elm->next = next;
ffffffffc0200b5e:	02673023          	sd	t1,32(a4)
    while (order > requested_order) {
ffffffffc0200b62:	15c1                	addi	a1,a1,-16
ffffffffc0200b64:	fcf696e3          	bne	a3,a5,ffffffffc0200b30 <buddy_alloc_pages+0xb2>
    for (size_t i = 0; i < length; i ++) {
ffffffffc0200b68:	02800713          	li	a4,40
ffffffffc0200b6c:	00f71733          	sll	a4,a4,a5
ffffffffc0200b70:	9772                	add	a4,a4,t3
ffffffffc0200b72:	87f2                	mv	a5,t3
        base[i].flags = BUDDY_MANAGED | BUDDY_ALLOCATED;
ffffffffc0200b74:	46b1                	li	a3,12
ffffffffc0200b76:	fed7b823          	sd	a3,-16(a5)
        base[i].property = 0;
ffffffffc0200b7a:	fe07ac23          	sw	zero,-8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200b7e:	fe07a423          	sw	zero,-24(a5)
    for (size_t i = 0; i < length; i ++) {
ffffffffc0200b82:	02878793          	addi	a5,a5,40
ffffffffc0200b86:	fef718e3          	bne	a4,a5,ffffffffc0200b76 <buddy_alloc_pages+0xf8>
    base->flags |= BUDDY_ALLOC_HEAD;
ffffffffc0200b8a:	ff0e3783          	ld	a5,-16(t3)
}
ffffffffc0200b8e:	60a2                	ld	ra,8(sp)
    nr_free -= length;
ffffffffc0200b90:	40cf0f33          	sub	t5,t5,a2
    base->flags |= BUDDY_ALLOC_HEAD;
ffffffffc0200b94:	0107e793          	ori	a5,a5,16
    base->property = n;
ffffffffc0200b98:	feae2c23          	sw	a0,-8(t3)
    nr_free -= length;
ffffffffc0200b9c:	00027717          	auipc	a4,0x27
ffffffffc0200ba0:	c3e73223          	sd	t5,-988(a4) # ffffffffc02277c0 <nr_free>
    base->flags |= BUDDY_ALLOC_HEAD;
ffffffffc0200ba4:	fefe3823          	sd	a5,-16(t3)
}
ffffffffc0200ba8:	8576                	mv	a0,t4
ffffffffc0200baa:	0141                	addi	sp,sp,16
ffffffffc0200bac:	8082                	ret
    assert(order <= BUDDY_MAX_ORDER);
ffffffffc0200bae:	00007697          	auipc	a3,0x7
ffffffffc0200bb2:	9ba68693          	addi	a3,a3,-1606 # ffffffffc0207568 <etext+0x2ec>
ffffffffc0200bb6:	00007617          	auipc	a2,0x7
ffffffffc0200bba:	93260613          	addi	a2,a2,-1742 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200bbe:	45d5                	li	a1,21
ffffffffc0200bc0:	00007517          	auipc	a0,0x7
ffffffffc0200bc4:	94050513          	addi	a0,a0,-1728 # ffffffffc0207500 <etext+0x284>
ffffffffc0200bc8:	e08ff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(n > 0);
ffffffffc0200bcc:	00007697          	auipc	a3,0x7
ffffffffc0200bd0:	a2468693          	addi	a3,a3,-1500 # ffffffffc02075f0 <etext+0x374>
ffffffffc0200bd4:	00007617          	auipc	a2,0x7
ffffffffc0200bd8:	91460613          	addi	a2,a2,-1772 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200bdc:	08d00593          	li	a1,141
ffffffffc0200be0:	00007517          	auipc	a0,0x7
ffffffffc0200be4:	92050513          	addi	a0,a0,-1760 # ffffffffc0207500 <etext+0x284>
ffffffffc0200be8:	de8ff0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0200bec <buddy_test_allocation>:
    assert(buddy_test_fingerprint() == before);
    buddy_check_state();
}

static size_t
buddy_test_allocation(struct Page *p, size_t request) {
ffffffffc0200bec:	7179                	addi	sp,sp,-48
ffffffffc0200bee:	f406                	sd	ra,40(sp)
    assert(p != NULL && p->property == request);
ffffffffc0200bf0:	1c050b63          	beqz	a0,ffffffffc0200dc6 <buddy_test_allocation+0x1da>
ffffffffc0200bf4:	01056703          	lwu	a4,16(a0)
ffffffffc0200bf8:	87aa                	mv	a5,a0
ffffffffc0200bfa:	1cb71663          	bne	a4,a1,ffffffffc0200dc6 <buddy_test_allocation+0x1da>
    if (n > buddy_block_size(BUDDY_MAX_ORDER)) {
ffffffffc0200bfe:	4685                	li	a3,1
ffffffffc0200c00:	01f69713          	slli	a4,a3,0x1f
ffffffffc0200c04:	0cb76663          	bltu	a4,a1,ffffffffc0200cd0 <buddy_test_allocation+0xe4>
    unsigned int k = 0;
ffffffffc0200c08:	4701                	li	a4,0
    assert(order <= BUDDY_MAX_ORDER);
ffffffffc0200c0a:	02000613          	li	a2,32
ffffffffc0200c0e:	a021                	j	ffffffffc0200c16 <buddy_test_allocation+0x2a>
        k ++;
ffffffffc0200c10:	2705                	addiw	a4,a4,1
    assert(order <= BUDDY_MAX_ORDER);
ffffffffc0200c12:	14c70b63          	beq	a4,a2,ffffffffc0200d68 <buddy_test_allocation+0x17c>
    return (size_t)1 << order;
ffffffffc0200c16:	00e69e33          	sll	t3,a3,a4
    while (buddy_block_size(k) < n) {
ffffffffc0200c1a:	febe6be3          	bltu	t3,a1,ffffffffc0200c10 <buddy_test_allocation+0x24>
    size_t index = buddy_page_index(base);
ffffffffc0200c1e:	853e                	mv	a0,a5
ffffffffc0200c20:	00e10fa3          	sb	a4,31(sp)
ffffffffc0200c24:	e872                	sd	t3,16(sp)
ffffffffc0200c26:	e43e                	sd	a5,8(sp)
ffffffffc0200c28:	a49ff0ef          	jal	ffffffffc0200670 <buddy_page_index>
    assert(n > 0 && n <= npage - nbase - index);
ffffffffc0200c2c:	00027317          	auipc	t1,0x27
ffffffffc0200c30:	bbc33303          	ld	t1,-1092(t1) # ffffffffc02277e8 <npage>
ffffffffc0200c34:	00009697          	auipc	a3,0x9
ffffffffc0200c38:	1746b683          	ld	a3,372(a3) # ffffffffc0209da8 <nbase>
ffffffffc0200c3c:	6e42                	ld	t3,16(sp)
ffffffffc0200c3e:	67a2                	ld	a5,8(sp)
ffffffffc0200c40:	40d30733          	sub	a4,t1,a3
ffffffffc0200c44:	8f09                	sub	a4,a4,a0
ffffffffc0200c46:	01f14883          	lbu	a7,31(sp)
ffffffffc0200c4a:	13c76e63          	bltu	a4,t3,ffffffffc0200d86 <buddy_test_allocation+0x19a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c4e:	00027617          	auipc	a2,0x27
ffffffffc0200c52:	ba263603          	ld	a2,-1118(a2) # ffffffffc02277f0 <pages>
ffffffffc0200c56:	ccccd737          	lui	a4,0xccccd
ffffffffc0200c5a:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcaa5455>
ffffffffc0200c5e:	02071813          	slli	a6,a4,0x20
ffffffffc0200c62:	983a                	add	a6,a6,a4
ffffffffc0200c64:	40c78733          	sub	a4,a5,a2
ffffffffc0200c68:	870d                	srai	a4,a4,0x3
ffffffffc0200c6a:	03070733          	mul	a4,a4,a6
    unsigned int order;
    assert(buddy_request_order(request, &order));
    size_t length = buddy_block_size(order);
    buddy_validate_range(p, length);
    assert((page2ppn(p) & (length - 1)) == 0);
ffffffffc0200c6e:	fffe0593          	addi	a1,t3,-1
ffffffffc0200c72:	9736                	add	a4,a4,a3
ffffffffc0200c74:	8f6d                	and	a4,a4,a1
ffffffffc0200c76:	12071863          	bnez	a4,ffffffffc0200da6 <buddy_test_allocation+0x1ba>
ffffffffc0200c7a:	02800593          	li	a1,40
ffffffffc0200c7e:	011595b3          	sll	a1,a1,a7
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200c82:	58fd                	li	a7,-1
ffffffffc0200c84:	853e                	mv	a0,a5
ffffffffc0200c86:	95be                	add	a1,a1,a5
ffffffffc0200c88:	00c8d893          	srli	a7,a7,0xc
    for (size_t i = 0; i < length; i ++) {
        assert((p[i].flags & BUDDY_ALLOCATED) && !PageReserved(p + i));
ffffffffc0200c8c:	4ea1                	li	t4,8
ffffffffc0200c8e:	651c                	ld	a5,8(a0)
ffffffffc0200c90:	0097f713          	andi	a4,a5,9
ffffffffc0200c94:	05d71e63          	bne	a4,t4,ffffffffc0200cf0 <buddy_test_allocation+0x104>
        assert(!PageProperty(p + i));
ffffffffc0200c98:	8b89                	andi	a5,a5,2
ffffffffc0200c9a:	e7dd                	bnez	a5,ffffffffc0200d48 <buddy_test_allocation+0x15c>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c9c:	40c507b3          	sub	a5,a0,a2
ffffffffc0200ca0:	878d                	srai	a5,a5,0x3
ffffffffc0200ca2:	030787b3          	mul	a5,a5,a6
ffffffffc0200ca6:	97b6                	add	a5,a5,a3
    if (PPN(pa) >= npage) {
ffffffffc0200ca8:	0117f7b3          	and	a5,a5,a7
ffffffffc0200cac:	0867f263          	bgeu	a5,t1,ffffffffc0200d30 <buddy_test_allocation+0x144>
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200cb0:	8f95                	sub	a5,a5,a3
ffffffffc0200cb2:	00279713          	slli	a4,a5,0x2
ffffffffc0200cb6:	97ba                	add	a5,a5,a4
ffffffffc0200cb8:	078e                	slli	a5,a5,0x3
ffffffffc0200cba:	97b2                	add	a5,a5,a2
        assert(pa2page(page2pa(p + i)) == p + i);
ffffffffc0200cbc:	04f51a63          	bne	a0,a5,ffffffffc0200d10 <buddy_test_allocation+0x124>
    for (size_t i = 0; i < length; i ++) {
ffffffffc0200cc0:	02850513          	addi	a0,a0,40
ffffffffc0200cc4:	fcb515e3          	bne	a0,a1,ffffffffc0200c8e <buddy_test_allocation+0xa2>
    }
    return length;
}
ffffffffc0200cc8:	70a2                	ld	ra,40(sp)
ffffffffc0200cca:	8572                	mv	a0,t3
ffffffffc0200ccc:	6145                	addi	sp,sp,48
ffffffffc0200cce:	8082                	ret
    assert(buddy_request_order(request, &order));
ffffffffc0200cd0:	00007697          	auipc	a3,0x7
ffffffffc0200cd4:	95068693          	addi	a3,a3,-1712 # ffffffffc0207620 <etext+0x3a4>
ffffffffc0200cd8:	00007617          	auipc	a2,0x7
ffffffffc0200cdc:	81060613          	addi	a2,a2,-2032 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200ce0:	15200593          	li	a1,338
ffffffffc0200ce4:	00007517          	auipc	a0,0x7
ffffffffc0200ce8:	81c50513          	addi	a0,a0,-2020 # ffffffffc0207500 <etext+0x284>
ffffffffc0200cec:	ce4ff0ef          	jal	ffffffffc02001d0 <__panic>
        assert((p[i].flags & BUDDY_ALLOCATED) && !PageReserved(p + i));
ffffffffc0200cf0:	00007697          	auipc	a3,0x7
ffffffffc0200cf4:	98068693          	addi	a3,a3,-1664 # ffffffffc0207670 <etext+0x3f4>
ffffffffc0200cf8:	00006617          	auipc	a2,0x6
ffffffffc0200cfc:	7f060613          	addi	a2,a2,2032 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200d00:	15700593          	li	a1,343
ffffffffc0200d04:	00006517          	auipc	a0,0x6
ffffffffc0200d08:	7fc50513          	addi	a0,a0,2044 # ffffffffc0207500 <etext+0x284>
ffffffffc0200d0c:	cc4ff0ef          	jal	ffffffffc02001d0 <__panic>
        assert(pa2page(page2pa(p + i)) == p + i);
ffffffffc0200d10:	00007697          	auipc	a3,0x7
ffffffffc0200d14:	9e068693          	addi	a3,a3,-1568 # ffffffffc02076f0 <etext+0x474>
ffffffffc0200d18:	00006617          	auipc	a2,0x6
ffffffffc0200d1c:	7d060613          	addi	a2,a2,2000 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200d20:	15900593          	li	a1,345
ffffffffc0200d24:	00006517          	auipc	a0,0x6
ffffffffc0200d28:	7dc50513          	addi	a0,a0,2012 # ffffffffc0207500 <etext+0x284>
ffffffffc0200d2c:	ca4ff0ef          	jal	ffffffffc02001d0 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0200d30:	00007617          	auipc	a2,0x7
ffffffffc0200d34:	99060613          	addi	a2,a2,-1648 # ffffffffc02076c0 <etext+0x444>
ffffffffc0200d38:	06a00593          	li	a1,106
ffffffffc0200d3c:	00007517          	auipc	a0,0x7
ffffffffc0200d40:	9a450513          	addi	a0,a0,-1628 # ffffffffc02076e0 <etext+0x464>
ffffffffc0200d44:	c8cff0ef          	jal	ffffffffc02001d0 <__panic>
        assert(!PageProperty(p + i));
ffffffffc0200d48:	00007697          	auipc	a3,0x7
ffffffffc0200d4c:	96068693          	addi	a3,a3,-1696 # ffffffffc02076a8 <etext+0x42c>
ffffffffc0200d50:	00006617          	auipc	a2,0x6
ffffffffc0200d54:	79860613          	addi	a2,a2,1944 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200d58:	15800593          	li	a1,344
ffffffffc0200d5c:	00006517          	auipc	a0,0x6
ffffffffc0200d60:	7a450513          	addi	a0,a0,1956 # ffffffffc0207500 <etext+0x284>
ffffffffc0200d64:	c6cff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(order <= BUDDY_MAX_ORDER);
ffffffffc0200d68:	00007697          	auipc	a3,0x7
ffffffffc0200d6c:	80068693          	addi	a3,a3,-2048 # ffffffffc0207568 <etext+0x2ec>
ffffffffc0200d70:	00006617          	auipc	a2,0x6
ffffffffc0200d74:	77860613          	addi	a2,a2,1912 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200d78:	45d5                	li	a1,21
ffffffffc0200d7a:	00006517          	auipc	a0,0x6
ffffffffc0200d7e:	78650513          	addi	a0,a0,1926 # ffffffffc0207500 <etext+0x284>
ffffffffc0200d82:	c4eff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(n > 0 && n <= npage - nbase - index);
ffffffffc0200d86:	00007697          	auipc	a3,0x7
ffffffffc0200d8a:	80268693          	addi	a3,a3,-2046 # ffffffffc0207588 <etext+0x30c>
ffffffffc0200d8e:	00006617          	auipc	a2,0x6
ffffffffc0200d92:	75a60613          	addi	a2,a2,1882 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200d96:	02900593          	li	a1,41
ffffffffc0200d9a:	00006517          	auipc	a0,0x6
ffffffffc0200d9e:	76650513          	addi	a0,a0,1894 # ffffffffc0207500 <etext+0x284>
ffffffffc0200da2:	c2eff0ef          	jal	ffffffffc02001d0 <__panic>
    assert((page2ppn(p) & (length - 1)) == 0);
ffffffffc0200da6:	00007697          	auipc	a3,0x7
ffffffffc0200daa:	8a268693          	addi	a3,a3,-1886 # ffffffffc0207648 <etext+0x3cc>
ffffffffc0200dae:	00006617          	auipc	a2,0x6
ffffffffc0200db2:	73a60613          	addi	a2,a2,1850 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200db6:	15500593          	li	a1,341
ffffffffc0200dba:	00006517          	auipc	a0,0x6
ffffffffc0200dbe:	74650513          	addi	a0,a0,1862 # ffffffffc0207500 <etext+0x284>
ffffffffc0200dc2:	c0eff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(p != NULL && p->property == request);
ffffffffc0200dc6:	00007697          	auipc	a3,0x7
ffffffffc0200dca:	83268693          	addi	a3,a3,-1998 # ffffffffc02075f8 <etext+0x37c>
ffffffffc0200dce:	00006617          	auipc	a2,0x6
ffffffffc0200dd2:	71a60613          	addi	a2,a2,1818 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200dd6:	15000593          	li	a1,336
ffffffffc0200dda:	00006517          	auipc	a0,0x6
ffffffffc0200dde:	72650513          	addi	a0,a0,1830 # ffffffffc0207500 <etext+0x284>
ffffffffc0200de2:	beeff0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0200de6 <buddy_free_pages>:
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200de6:	1101                	addi	sp,sp,-32
ffffffffc0200de8:	e822                	sd	s0,16(sp)
ffffffffc0200dea:	e42e                	sd	a1,8(sp)
ffffffffc0200dec:	ec06                	sd	ra,24(sp)
ffffffffc0200dee:	842a                	mv	s0,a0
    size_t index = buddy_page_index(base);
ffffffffc0200df0:	881ff0ef          	jal	ffffffffc0200670 <buddy_page_index>
    assert(n > 0 && n <= npage - nbase - index);
ffffffffc0200df4:	65a2                	ld	a1,8(sp)
ffffffffc0200df6:	1c058763          	beqz	a1,ffffffffc0200fc4 <buddy_free_pages+0x1de>
ffffffffc0200dfa:	00009697          	auipc	a3,0x9
ffffffffc0200dfe:	fae6b683          	ld	a3,-82(a3) # ffffffffc0209da8 <nbase>
ffffffffc0200e02:	00027797          	auipc	a5,0x27
ffffffffc0200e06:	9e67b783          	ld	a5,-1562(a5) # ffffffffc02277e8 <npage>
ffffffffc0200e0a:	8f95                	sub	a5,a5,a3
ffffffffc0200e0c:	40a78533          	sub	a0,a5,a0
ffffffffc0200e10:	1ab56a63          	bltu	a0,a1,ffffffffc0200fc4 <buddy_free_pages+0x1de>
    assert((base->flags & BUDDY_ALLOC_HEAD) && base->property == n);
ffffffffc0200e14:	641c                	ld	a5,8(s0)
ffffffffc0200e16:	8bc1                	andi	a5,a5,16
ffffffffc0200e18:	18078663          	beqz	a5,ffffffffc0200fa4 <buddy_free_pages+0x1be>
ffffffffc0200e1c:	01046783          	lwu	a5,16(s0)
ffffffffc0200e20:	18b79263          	bne	a5,a1,ffffffffc0200fa4 <buddy_free_pages+0x1be>
    if (n > buddy_block_size(BUDDY_MAX_ORDER)) {
ffffffffc0200e24:	4785                	li	a5,1
ffffffffc0200e26:	01f79713          	slli	a4,a5,0x1f
ffffffffc0200e2a:	0cb76e63          	bltu	a4,a1,ffffffffc0200f06 <buddy_free_pages+0x120>
    unsigned int k = 0;
ffffffffc0200e2e:	4881                	li	a7,0
    assert(order <= BUDDY_MAX_ORDER);
ffffffffc0200e30:	02000713          	li	a4,32
ffffffffc0200e34:	a021                	j	ffffffffc0200e3c <buddy_free_pages+0x56>
        k ++;
ffffffffc0200e36:	2885                	addiw	a7,a7,1
    assert(order <= BUDDY_MAX_ORDER);
ffffffffc0200e38:	12e88763          	beq	a7,a4,ffffffffc0200f66 <buddy_free_pages+0x180>
    return (size_t)1 << order;
ffffffffc0200e3c:	01179833          	sll	a6,a5,a7
    while (buddy_block_size(k) < n) {
ffffffffc0200e40:	feb86be3          	bltu	a6,a1,ffffffffc0200e36 <buddy_free_pages+0x50>
    assert(n > 0 && n <= npage - nbase - index);
ffffffffc0200e44:	19056063          	bltu	a0,a6,ffffffffc0200fc4 <buddy_free_pages+0x1de>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e48:	00027797          	auipc	a5,0x27
ffffffffc0200e4c:	9a87b783          	ld	a5,-1624(a5) # ffffffffc02277f0 <pages>
ffffffffc0200e50:	ccccd737          	lui	a4,0xccccd
ffffffffc0200e54:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcaa5455>
ffffffffc0200e58:	02071613          	slli	a2,a4,0x20
ffffffffc0200e5c:	40f407b3          	sub	a5,s0,a5
ffffffffc0200e60:	9732                	add	a4,a4,a2
ffffffffc0200e62:	878d                	srai	a5,a5,0x3
ffffffffc0200e64:	02e787b3          	mul	a5,a5,a4
    assert((page2ppn(base) & (length - 1)) == 0);
ffffffffc0200e68:	fff80713          	addi	a4,a6,-1
ffffffffc0200e6c:	97b6                	add	a5,a5,a3
ffffffffc0200e6e:	8ff9                	and	a5,a5,a4
ffffffffc0200e70:	10079a63          	bnez	a5,ffffffffc0200f84 <buddy_free_pages+0x19e>
        assert((p->flags & BUDDY_MANAGED) && (p->flags & BUDDY_ALLOCATED));
ffffffffc0200e74:	6418                	ld	a4,8(s0)
ffffffffc0200e76:	47b1                	li	a5,12
ffffffffc0200e78:	8522                	mv	a0,s0
ffffffffc0200e7a:	00f775b3          	and	a1,a4,a5
ffffffffc0200e7e:	00840693          	addi	a3,s0,8
ffffffffc0200e82:	0af59263          	bne	a1,a5,ffffffffc0200f26 <buddy_free_pages+0x140>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200e86:	8b0d                	andi	a4,a4,3
ffffffffc0200e88:	ef5d                	bnez	a4,ffffffffc0200f46 <buddy_free_pages+0x160>
    for (size_t i = 0; i < length; i ++) {
ffffffffc0200e8a:	0705                	addi	a4,a4,1
ffffffffc0200e8c:	03070e63          	beq	a4,a6,ffffffffc0200ec8 <buddy_free_pages+0xe2>
        assert((p->flags & BUDDY_MANAGED) && (p->flags & BUDDY_ALLOCATED));
ffffffffc0200e90:	769c                	ld	a5,40(a3)
    for (size_t i = 0; i < length; i ++) {
ffffffffc0200e92:	02868693          	addi	a3,a3,40
        assert((p->flags & BUDDY_MANAGED) && (p->flags & BUDDY_ALLOCATED));
ffffffffc0200e96:	00c7f613          	andi	a2,a5,12
ffffffffc0200e9a:	08b61663          	bne	a2,a1,ffffffffc0200f26 <buddy_free_pages+0x140>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200e9e:	0037f613          	andi	a2,a5,3
ffffffffc0200ea2:	e255                	bnez	a2,ffffffffc0200f46 <buddy_free_pages+0x160>
        assert(i == 0 || !(p->flags & BUDDY_ALLOC_HEAD));
ffffffffc0200ea4:	8bc1                	andi	a5,a5,16
ffffffffc0200ea6:	d3f5                	beqz	a5,ffffffffc0200e8a <buddy_free_pages+0xa4>
ffffffffc0200ea8:	00007697          	auipc	a3,0x7
ffffffffc0200eac:	95868693          	addi	a3,a3,-1704 # ffffffffc0207800 <etext+0x584>
ffffffffc0200eb0:	00006617          	auipc	a2,0x6
ffffffffc0200eb4:	63860613          	addi	a2,a2,1592 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200eb8:	0c300593          	li	a1,195
ffffffffc0200ebc:	00006517          	auipc	a0,0x6
ffffffffc0200ec0:	64450513          	addi	a0,a0,1604 # ffffffffc0207500 <etext+0x284>
ffffffffc0200ec4:	b0cff0ef          	jal	ffffffffc02001d0 <__panic>
ffffffffc0200ec8:	02800793          	li	a5,40
ffffffffc0200ecc:	011797b3          	sll	a5,a5,a7
ffffffffc0200ed0:	97a2                	add	a5,a5,s0
        base[i].flags = BUDDY_MANAGED;
ffffffffc0200ed2:	4711                	li	a4,4
ffffffffc0200ed4:	e518                	sd	a4,8(a0)
        base[i].property = 0;
ffffffffc0200ed6:	00052823          	sw	zero,16(a0)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200eda:	00052023          	sw	zero,0(a0)
    for (size_t i = 0; i < length; i ++) {
ffffffffc0200ede:	02850513          	addi	a0,a0,40
ffffffffc0200ee2:	fef519e3          	bne	a0,a5,ffffffffc0200ed4 <buddy_free_pages+0xee>
    nr_free += length;
ffffffffc0200ee6:	00027797          	auipc	a5,0x27
ffffffffc0200eea:	8da7b783          	ld	a5,-1830(a5) # ffffffffc02277c0 <nr_free>
    buddy_insert_block(base, order);
ffffffffc0200eee:	8522                	mv	a0,s0
}
ffffffffc0200ef0:	6442                	ld	s0,16(sp)
ffffffffc0200ef2:	60e2                	ld	ra,24(sp)
    nr_free += length;
ffffffffc0200ef4:	97c2                	add	a5,a5,a6
ffffffffc0200ef6:	00027717          	auipc	a4,0x27
ffffffffc0200efa:	8cf73523          	sd	a5,-1846(a4) # ffffffffc02277c0 <nr_free>
    buddy_insert_block(base, order);
ffffffffc0200efe:	85c6                	mv	a1,a7
}
ffffffffc0200f00:	6105                	addi	sp,sp,32
    buddy_insert_block(base, order);
ffffffffc0200f02:	8afff06f          	j	ffffffffc02007b0 <buddy_insert_block>
    assert(buddy_request_order(n, &order));
ffffffffc0200f06:	00007697          	auipc	a3,0x7
ffffffffc0200f0a:	84a68693          	addi	a3,a3,-1974 # ffffffffc0207750 <etext+0x4d4>
ffffffffc0200f0e:	00006617          	auipc	a2,0x6
ffffffffc0200f12:	5da60613          	addi	a2,a2,1498 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200f16:	0bb00593          	li	a1,187
ffffffffc0200f1a:	00006517          	auipc	a0,0x6
ffffffffc0200f1e:	5e650513          	addi	a0,a0,1510 # ffffffffc0207500 <etext+0x284>
ffffffffc0200f22:	aaeff0ef          	jal	ffffffffc02001d0 <__panic>
        assert((p->flags & BUDDY_MANAGED) && (p->flags & BUDDY_ALLOCATED));
ffffffffc0200f26:	00007697          	auipc	a3,0x7
ffffffffc0200f2a:	87268693          	addi	a3,a3,-1934 # ffffffffc0207798 <etext+0x51c>
ffffffffc0200f2e:	00006617          	auipc	a2,0x6
ffffffffc0200f32:	5ba60613          	addi	a2,a2,1466 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200f36:	0c100593          	li	a1,193
ffffffffc0200f3a:	00006517          	auipc	a0,0x6
ffffffffc0200f3e:	5c650513          	addi	a0,a0,1478 # ffffffffc0207500 <etext+0x284>
ffffffffc0200f42:	a8eff0ef          	jal	ffffffffc02001d0 <__panic>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200f46:	00007697          	auipc	a3,0x7
ffffffffc0200f4a:	89268693          	addi	a3,a3,-1902 # ffffffffc02077d8 <etext+0x55c>
ffffffffc0200f4e:	00006617          	auipc	a2,0x6
ffffffffc0200f52:	59a60613          	addi	a2,a2,1434 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200f56:	0c200593          	li	a1,194
ffffffffc0200f5a:	00006517          	auipc	a0,0x6
ffffffffc0200f5e:	5a650513          	addi	a0,a0,1446 # ffffffffc0207500 <etext+0x284>
ffffffffc0200f62:	a6eff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(order <= BUDDY_MAX_ORDER);
ffffffffc0200f66:	00006697          	auipc	a3,0x6
ffffffffc0200f6a:	60268693          	addi	a3,a3,1538 # ffffffffc0207568 <etext+0x2ec>
ffffffffc0200f6e:	00006617          	auipc	a2,0x6
ffffffffc0200f72:	57a60613          	addi	a2,a2,1402 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200f76:	45d5                	li	a1,21
ffffffffc0200f78:	00006517          	auipc	a0,0x6
ffffffffc0200f7c:	58850513          	addi	a0,a0,1416 # ffffffffc0207500 <etext+0x284>
ffffffffc0200f80:	a50ff0ef          	jal	ffffffffc02001d0 <__panic>
    assert((page2ppn(base) & (length - 1)) == 0);
ffffffffc0200f84:	00006697          	auipc	a3,0x6
ffffffffc0200f88:	7ec68693          	addi	a3,a3,2028 # ffffffffc0207770 <etext+0x4f4>
ffffffffc0200f8c:	00006617          	auipc	a2,0x6
ffffffffc0200f90:	55c60613          	addi	a2,a2,1372 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200f94:	0be00593          	li	a1,190
ffffffffc0200f98:	00006517          	auipc	a0,0x6
ffffffffc0200f9c:	56850513          	addi	a0,a0,1384 # ffffffffc0207500 <etext+0x284>
ffffffffc0200fa0:	a30ff0ef          	jal	ffffffffc02001d0 <__panic>
    assert((base->flags & BUDDY_ALLOC_HEAD) && base->property == n);
ffffffffc0200fa4:	00006697          	auipc	a3,0x6
ffffffffc0200fa8:	77468693          	addi	a3,a3,1908 # ffffffffc0207718 <etext+0x49c>
ffffffffc0200fac:	00006617          	auipc	a2,0x6
ffffffffc0200fb0:	53c60613          	addi	a2,a2,1340 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200fb4:	0b900593          	li	a1,185
ffffffffc0200fb8:	00006517          	auipc	a0,0x6
ffffffffc0200fbc:	54850513          	addi	a0,a0,1352 # ffffffffc0207500 <etext+0x284>
ffffffffc0200fc0:	a10ff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(n > 0 && n <= npage - nbase - index);
ffffffffc0200fc4:	00006697          	auipc	a3,0x6
ffffffffc0200fc8:	5c468693          	addi	a3,a3,1476 # ffffffffc0207588 <etext+0x30c>
ffffffffc0200fcc:	00006617          	auipc	a2,0x6
ffffffffc0200fd0:	51c60613          	addi	a2,a2,1308 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0200fd4:	02900593          	li	a1,41
ffffffffc0200fd8:	00006517          	auipc	a0,0x6
ffffffffc0200fdc:	52850513          	addi	a0,a0,1320 # ffffffffc0207500 <etext+0x284>
ffffffffc0200fe0:	9f0ff0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0200fe4 <buddy_check_state>:
buddy_check_state(void) {
ffffffffc0200fe4:	7171                	addi	sp,sp,-176
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200fe6:	ccccd7b7          	lui	a5,0xccccd
ffffffffc0200fea:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcaa5455>
            assert(++ listed_blocks <= nr_managed);
ffffffffc0200fee:	00026717          	auipc	a4,0x26
ffffffffc0200ff2:	7ca73703          	ld	a4,1994(a4) # ffffffffc02277b8 <nr_managed>
buddy_check_state(void) {
ffffffffc0200ff6:	f8da                	sd	s6,112(sp)
ffffffffc0200ff8:	f0e2                	sd	s8,96(sp)
    assert(n > 0 && n <= npage - nbase - index);
ffffffffc0200ffa:	00026b17          	auipc	s6,0x26
ffffffffc0200ffe:	7eeb3b03          	ld	s6,2030(s6) # ffffffffc02277e8 <npage>
ffffffffc0201002:	00009c17          	auipc	s8,0x9
ffffffffc0201006:	da6c3c03          	ld	s8,-602(s8) # ffffffffc0209da8 <nbase>
buddy_check_state(void) {
ffffffffc020100a:	f4de                	sd	s7,104(sp)
ffffffffc020100c:	e8ea                	sd	s10,80(sp)
ffffffffc020100e:	02079b93          	slli	s7,a5,0x20
ffffffffc0201012:	00026d17          	auipc	s10,0x26
ffffffffc0201016:	7ded3d03          	ld	s10,2014(s10) # ffffffffc02277f0 <pages>
ffffffffc020101a:	97de                	add	a5,a5,s7
ffffffffc020101c:	ed26                	sd	s1,152(sp)
ffffffffc020101e:	e94a                	sd	s2,144(sp)
ffffffffc0201020:	e54e                	sd	s3,136(sp)
ffffffffc0201022:	e152                	sd	s4,128(sp)
ffffffffc0201024:	f506                	sd	ra,168(sp)
ffffffffc0201026:	f122                	sd	s0,160(sp)
ffffffffc0201028:	fcd6                	sd	s5,120(sp)
ffffffffc020102a:	ece6                	sd	s9,88(sp)
ffffffffc020102c:	e4ee                	sd	s11,72(sp)
            assert(++ listed_blocks <= nr_managed);
ffffffffc020102e:	e43a                	sd	a4,8(sp)
ffffffffc0201030:	e83e                	sd	a5,16(sp)
    assert(n > 0 && n <= npage - nbase - index);
ffffffffc0201032:	418b0b33          	sub	s6,s6,s8
ffffffffc0201036:	0000da17          	auipc	s4,0xd
ffffffffc020103a:	9eaa0a13          	addi	s4,s4,-1558 # ffffffffc020da20 <free_lists>
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
ffffffffc020103e:	4981                	li	s3,0
    size_t listed_pages = 0, listed_blocks = 0;
ffffffffc0201040:	4481                	li	s1,0
ffffffffc0201042:	4901                	li	s2,0
    return listelm->next;
ffffffffc0201044:	008a3d83          	ld	s11,8(s4)
        while (le != head) {
ffffffffc0201048:	074d8e63          	beq	s11,s4,ffffffffc02010c4 <buddy_check_state+0xe0>
    return (size_t)1 << order;
ffffffffc020104c:	4785                	li	a5,1
ffffffffc020104e:	01379433          	sll	s0,a5,s3
            assert((page2ppn(p) & (length - 1)) == 0);
ffffffffc0201052:	fff40a93          	addi	s5,s0,-1
        list_entry_t *head = &free_lists[k], *prev = head, *le = list_next(head);
ffffffffc0201056:	8bd2                	mv	s7,s4
ffffffffc0201058:	a011                	j	ffffffffc020105c <buddy_check_state+0x78>
ffffffffc020105a:	8dbe                	mv	s11,a5
            assert(++ listed_blocks <= nr_managed);
ffffffffc020105c:	67a2                	ld	a5,8(sp)
ffffffffc020105e:	0485                	addi	s1,s1,1
ffffffffc0201060:	2297ed63          	bltu	a5,s1,ffffffffc020129a <buddy_check_state+0x2b6>
            struct Page *p = le2page(le, page_link);
ffffffffc0201064:	fe8d8c93          	addi	s9,s11,-24
    size_t index = buddy_page_index(base);
ffffffffc0201068:	8566                	mv	a0,s9
ffffffffc020106a:	e06ff0ef          	jal	ffffffffc0200670 <buddy_page_index>
    assert(n > 0 && n <= npage - nbase - index);
ffffffffc020106e:	40ab0533          	sub	a0,s6,a0
ffffffffc0201072:	24856463          	bltu	a0,s0,ffffffffc02012ba <buddy_check_state+0x2d6>
            assert(le->prev == prev);
ffffffffc0201076:	000db783          	ld	a5,0(s11)
ffffffffc020107a:	27779063          	bne	a5,s7,ffffffffc02012da <buddy_check_state+0x2f6>
            assert(PageProperty(p) && p->property == length);
ffffffffc020107e:	ff0db783          	ld	a5,-16(s11)
ffffffffc0201082:	8b89                	andi	a5,a5,2
ffffffffc0201084:	18078e63          	beqz	a5,ffffffffc0201220 <buddy_check_state+0x23c>
ffffffffc0201088:	ff8de783          	lwu	a5,-8(s11)
ffffffffc020108c:	18879a63          	bne	a5,s0,ffffffffc0201220 <buddy_check_state+0x23c>
ffffffffc0201090:	6742                	ld	a4,16(sp)
ffffffffc0201092:	41ac87b3          	sub	a5,s9,s10
ffffffffc0201096:	878d                	srai	a5,a5,0x3
ffffffffc0201098:	02e787b3          	mul	a5,a5,a4
ffffffffc020109c:	97e2                	add	a5,a5,s8
            assert((page2ppn(p) & (length - 1)) == 0);
ffffffffc020109e:	0157f7b3          	and	a5,a5,s5
ffffffffc02010a2:	24079c63          	bnez	a5,ffffffffc02012fa <buddy_check_state+0x316>
            if (k < BUDDY_MAX_ORDER) {
ffffffffc02010a6:	47fd                	li	a5,31
ffffffffc02010a8:	00f98863          	beq	s3,a5,ffffffffc02010b8 <buddy_check_state+0xd4>
                assert(buddy_find_partner(p, k) == NULL);
ffffffffc02010ac:	8566                	mv	a0,s9
ffffffffc02010ae:	85ce                	mv	a1,s3
ffffffffc02010b0:	e92ff0ef          	jal	ffffffffc0200742 <buddy_find_partner>
ffffffffc02010b4:	26051363          	bnez	a0,ffffffffc020131a <buddy_check_state+0x336>
ffffffffc02010b8:	008db783          	ld	a5,8(s11)
            listed_pages += length;
ffffffffc02010bc:	9922                	add	s2,s2,s0
        while (le != head) {
ffffffffc02010be:	8bee                	mv	s7,s11
ffffffffc02010c0:	f9479de3          	bne	a5,s4,ffffffffc020105a <buddy_check_state+0x76>
        assert(head->prev == prev);
ffffffffc02010c4:	000a3783          	ld	a5,0(s4)
ffffffffc02010c8:	41b79c63          	bne	a5,s11,ffffffffc02014e0 <buddy_check_state+0x4fc>
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
ffffffffc02010cc:	2985                	addiw	s3,s3,1
ffffffffc02010ce:	02000793          	li	a5,32
ffffffffc02010d2:	0a41                	addi	s4,s4,16
ffffffffc02010d4:	f6f998e3          	bne	s3,a5,ffffffffc0201044 <buddy_check_state+0x60>
    for (size_t i = 0; i < npage - nbase;) {
ffffffffc02010d8:	3a0b0163          	beqz	s6,ffffffffc020147a <buddy_check_state+0x496>
ffffffffc02010dc:	4d81                	li	s11,0
    size_t free_pages = 0, free_blocks = 0, managed_pages = 0;
ffffffffc02010de:	4881                	li	a7,0
ffffffffc02010e0:	4581                	li	a1,0
ffffffffc02010e2:	4801                	li	a6,0
    return (size_t)1 << order;
ffffffffc02010e4:	4a85                	li	s5,1
    assert(order <= BUDDY_MAX_ORDER);
ffffffffc02010e6:	8bce                	mv	s7,s3
            assert((p->flags & BUDDY_MANAGED) && !PageReserved(p));
ffffffffc02010e8:	4a11                	li	s4,4
        struct Page *base = pages + i;
ffffffffc02010ea:	002d9713          	slli	a4,s11,0x2
ffffffffc02010ee:	976e                	add	a4,a4,s11
ffffffffc02010f0:	070e                	slli	a4,a4,0x3
ffffffffc02010f2:	00ed0433          	add	s0,s10,a4
        if (!(base->flags & BUDDY_MANAGED)) {
ffffffffc02010f6:	00843e03          	ld	t3,8(s0)
ffffffffc02010fa:	004e7793          	andi	a5,t3,4
ffffffffc02010fe:	e7a1                	bnez	a5,ffffffffc0201146 <buddy_check_state+0x162>
            assert(PageReserved(base));
ffffffffc0201100:	001e7e13          	andi	t3,t3,1
ffffffffc0201104:	360e0f63          	beqz	t3,ffffffffc0201482 <buddy_check_state+0x49e>
            i ++;
ffffffffc0201108:	0d85                	addi	s11,s11,1
    for (size_t i = 0; i < npage - nbase;) {
ffffffffc020110a:	ff6de0e3          	bltu	s11,s6,ffffffffc02010ea <buddy_check_state+0x106>
    assert(managed_pages == nr_managed);
ffffffffc020110e:	67a2                	ld	a5,8(sp)
ffffffffc0201110:	29179563          	bne	a5,a7,ffffffffc020139a <buddy_check_state+0x3b6>
    assert(free_pages == nr_free && listed_pages == nr_free);
ffffffffc0201114:	00026797          	auipc	a5,0x26
ffffffffc0201118:	6ac7b783          	ld	a5,1708(a5) # ffffffffc02277c0 <nr_free>
ffffffffc020111c:	25279f63          	bne	a5,s2,ffffffffc020137a <buddy_check_state+0x396>
ffffffffc0201120:	25079d63          	bne	a5,a6,ffffffffc020137a <buddy_check_state+0x396>
    assert(free_blocks == listed_blocks);
ffffffffc0201124:	22b49b63          	bne	s1,a1,ffffffffc020135a <buddy_check_state+0x376>
}
ffffffffc0201128:	70aa                	ld	ra,168(sp)
ffffffffc020112a:	740a                	ld	s0,160(sp)
ffffffffc020112c:	64ea                	ld	s1,152(sp)
ffffffffc020112e:	694a                	ld	s2,144(sp)
ffffffffc0201130:	69aa                	ld	s3,136(sp)
ffffffffc0201132:	6a0a                	ld	s4,128(sp)
ffffffffc0201134:	7ae6                	ld	s5,120(sp)
ffffffffc0201136:	7b46                	ld	s6,112(sp)
ffffffffc0201138:	7ba6                	ld	s7,104(sp)
ffffffffc020113a:	7c06                	ld	s8,96(sp)
ffffffffc020113c:	6ce6                	ld	s9,88(sp)
ffffffffc020113e:	6d46                	ld	s10,80(sp)
ffffffffc0201140:	6da6                	ld	s11,72(sp)
ffffffffc0201142:	614d                	addi	sp,sp,176
ffffffffc0201144:	8082                	ret
        assert(base->property > 0 && buddy_request_order(base->property, &order));
ffffffffc0201146:	4810                	lw	a2,16(s0)
ffffffffc0201148:	fff6079b          	addiw	a5,a2,-1
    if (n > buddy_block_size(BUDDY_MAX_ORDER)) {
ffffffffc020114c:	1207c763          	bltz	a5,ffffffffc020127a <buddy_check_state+0x296>
        assert(base->property > 0 && buddy_request_order(base->property, &order));
ffffffffc0201150:	1602                	slli	a2,a2,0x20
ffffffffc0201152:	9201                	srli	a2,a2,0x20
    unsigned int k = 0;
ffffffffc0201154:	4781                	li	a5,0
ffffffffc0201156:	a021                	j	ffffffffc020115e <buddy_check_state+0x17a>
        k ++;
ffffffffc0201158:	2785                	addiw	a5,a5,1
    assert(order <= BUDDY_MAX_ORDER);
ffffffffc020115a:	35778463          	beq	a5,s7,ffffffffc02014a2 <buddy_check_state+0x4be>
    return (size_t)1 << order;
ffffffffc020115e:	00fa99b3          	sll	s3,s5,a5
    while (buddy_block_size(k) < n) {
ffffffffc0201162:	fec9ebe3          	bltu	s3,a2,ffffffffc0201158 <buddy_check_state+0x174>
    size_t index = buddy_page_index(base);
ffffffffc0201166:	8522                	mv	a0,s0
ffffffffc0201168:	fc3a                	sd	a4,56(sp)
ffffffffc020116a:	f82e                	sd	a1,48(sp)
ffffffffc020116c:	f442                	sd	a6,40(sp)
ffffffffc020116e:	f032                	sd	a2,32(sp)
ffffffffc0201170:	ec46                	sd	a7,24(sp)
ffffffffc0201172:	e872                	sd	t3,16(sp)
ffffffffc0201174:	cfcff0ef          	jal	ffffffffc0200670 <buddy_page_index>
    assert(n > 0 && n <= npage - nbase - index);
ffffffffc0201178:	40ab07b3          	sub	a5,s6,a0
ffffffffc020117c:	6e42                	ld	t3,16(sp)
ffffffffc020117e:	68e2                	ld	a7,24(sp)
ffffffffc0201180:	7602                	ld	a2,32(sp)
ffffffffc0201182:	7822                	ld	a6,40(sp)
ffffffffc0201184:	75c2                	ld	a1,48(sp)
ffffffffc0201186:	7762                	ld	a4,56(sp)
ffffffffc0201188:	00009317          	auipc	t1,0x9
ffffffffc020118c:	c1033303          	ld	t1,-1008(t1) # ffffffffc0209d98 <error_string+0x38>
ffffffffc0201190:	1337e563          	bltu	a5,s3,ffffffffc02012ba <buddy_check_state+0x2d6>
ffffffffc0201194:	40375693          	srai	a3,a4,0x3
ffffffffc0201198:	026686b3          	mul	a3,a3,t1
        assert((page2ppn(base) & (length - 1)) == 0);
ffffffffc020119c:	fff98793          	addi	a5,s3,-1
ffffffffc02011a0:	96e2                	add	a3,a3,s8
ffffffffc02011a2:	8efd                	and	a3,a3,a5
ffffffffc02011a4:	30069e63          	bnez	a3,ffffffffc02014c0 <buddy_check_state+0x4dc>
        bool allocated = (base->flags & BUDDY_ALLOCATED) != 0;
ffffffffc02011a8:	008e7513          	andi	a0,t3,8
        if (allocated) {
ffffffffc02011ac:	e951                	bnez	a0,ffffffffc0201240 <buddy_check_state+0x25c>
            assert(PageProperty(base) && base->property == length);
ffffffffc02011ae:	001e5793          	srli	a5,t3,0x1
ffffffffc02011b2:	8b85                	andi	a5,a5,1
ffffffffc02011b4:	2a078363          	beqz	a5,ffffffffc020145a <buddy_check_state+0x476>
ffffffffc02011b8:	2b361163          	bne	a2,s3,ffffffffc020145a <buddy_check_state+0x476>
            free_pages += length;
ffffffffc02011bc:	984e                	add	a6,a6,s3
            free_blocks ++;
ffffffffc02011be:	0585                	addi	a1,a1,1
ffffffffc02011c0:	8722                	mv	a4,s0
        bool allocated = (base->flags & BUDDY_ALLOCATED) != 0;
ffffffffc02011c2:	00355e13          	srli	t3,a0,0x3
        for (size_t j = 0; j < length; j ++) {
ffffffffc02011c6:	a839                	j	ffffffffc02011e4 <buddy_check_state+0x200>
                assert(!PageProperty(p) && !(p->flags & BUDDY_ALLOC_HEAD));
ffffffffc02011c8:	8bc9                	andi	a5,a5,18
ffffffffc02011ca:	22079863          	bnez	a5,ffffffffc02013fa <buddy_check_state+0x416>
                assert(p->property == 0);
ffffffffc02011ce:	4b1c                	lw	a5,16(a4)
ffffffffc02011d0:	20079563          	bnez	a5,ffffffffc02013da <buddy_check_state+0x3f6>
            assert(page_ref(p) == 0);
ffffffffc02011d4:	431c                	lw	a5,0(a4)
ffffffffc02011d6:	1e079263          	bnez	a5,ffffffffc02013ba <buddy_check_state+0x3d6>
        for (size_t j = 0; j < length; j ++) {
ffffffffc02011da:	0685                	addi	a3,a3,1
ffffffffc02011dc:	02870713          	addi	a4,a4,40
ffffffffc02011e0:	09368863          	beq	a3,s3,ffffffffc0201270 <buddy_check_state+0x28c>
            assert((p->flags & BUDDY_MANAGED) && !PageReserved(p));
ffffffffc02011e4:	671c                	ld	a5,8(a4)
ffffffffc02011e6:	0057f613          	andi	a2,a5,5
ffffffffc02011ea:	25461863          	bne	a2,s4,ffffffffc020143a <buddy_check_state+0x456>
            assert(((p->flags & BUDDY_ALLOCATED) != 0) == allocated);
ffffffffc02011ee:	0037d613          	srli	a2,a5,0x3
ffffffffc02011f2:	8a05                	andi	a2,a2,1
ffffffffc02011f4:	22ce1363          	bne	t3,a2,ffffffffc020141a <buddy_check_state+0x436>
            if (j > 0) {
ffffffffc02011f8:	fae1                	bnez	a3,ffffffffc02011c8 <buddy_check_state+0x1e4>
            } else if (!allocated) {
ffffffffc02011fa:	fd69                	bnez	a0,ffffffffc02011d4 <buddy_check_state+0x1f0>
                assert(!(p->flags & BUDDY_ALLOC_HEAD));
ffffffffc02011fc:	8bc1                	andi	a5,a5,16
ffffffffc02011fe:	dbf9                	beqz	a5,ffffffffc02011d4 <buddy_check_state+0x1f0>
ffffffffc0201200:	00007697          	auipc	a3,0x7
ffffffffc0201204:	85868693          	addi	a3,a3,-1960 # ffffffffc0207a58 <etext+0x7dc>
ffffffffc0201208:	00006617          	auipc	a2,0x6
ffffffffc020120c:	2e060613          	addi	a2,a2,736 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0201210:	10b00593          	li	a1,267
ffffffffc0201214:	00006517          	auipc	a0,0x6
ffffffffc0201218:	2ec50513          	addi	a0,a0,748 # ffffffffc0207500 <etext+0x284>
ffffffffc020121c:	fb5fe0ef          	jal	ffffffffc02001d0 <__panic>
            assert(PageProperty(p) && p->property == length);
ffffffffc0201220:	00006697          	auipc	a3,0x6
ffffffffc0201224:	64868693          	addi	a3,a3,1608 # ffffffffc0207868 <etext+0x5ec>
ffffffffc0201228:	00006617          	auipc	a2,0x6
ffffffffc020122c:	2c060613          	addi	a2,a2,704 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0201230:	0e100593          	li	a1,225
ffffffffc0201234:	00006517          	auipc	a0,0x6
ffffffffc0201238:	2cc50513          	addi	a0,a0,716 # ffffffffc0207500 <etext+0x284>
ffffffffc020123c:	f95fe0ef          	jal	ffffffffc02001d0 <__panic>
            assert(base->flags & BUDDY_ALLOC_HEAD);
ffffffffc0201240:	010e7793          	andi	a5,t3,16
ffffffffc0201244:	0e078b63          	beqz	a5,ffffffffc020133a <buddy_check_state+0x356>
            assert(!PageProperty(base));
ffffffffc0201248:	002e7e13          	andi	t3,t3,2
ffffffffc020124c:	f60e0ae3          	beqz	t3,ffffffffc02011c0 <buddy_check_state+0x1dc>
ffffffffc0201250:	00006697          	auipc	a3,0x6
ffffffffc0201254:	70868693          	addi	a3,a3,1800 # ffffffffc0207958 <etext+0x6dc>
ffffffffc0201258:	00006617          	auipc	a2,0x6
ffffffffc020125c:	29060613          	addi	a2,a2,656 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0201260:	0fd00593          	li	a1,253
ffffffffc0201264:	00006517          	auipc	a0,0x6
ffffffffc0201268:	29c50513          	addi	a0,a0,668 # ffffffffc0207500 <etext+0x284>
ffffffffc020126c:	f65fe0ef          	jal	ffffffffc02001d0 <__panic>
        i += length;
ffffffffc0201270:	9db6                	add	s11,s11,a3
        managed_pages += length;
ffffffffc0201272:	98b6                	add	a7,a7,a3
    for (size_t i = 0; i < npage - nbase;) {
ffffffffc0201274:	e76debe3          	bltu	s11,s6,ffffffffc02010ea <buddy_check_state+0x106>
ffffffffc0201278:	bd59                	j	ffffffffc020110e <buddy_check_state+0x12a>
        assert(base->property > 0 && buddy_request_order(base->property, &order));
ffffffffc020127a:	00006697          	auipc	a3,0x6
ffffffffc020127e:	67668693          	addi	a3,a3,1654 # ffffffffc02078f0 <etext+0x674>
ffffffffc0201282:	00006617          	auipc	a2,0x6
ffffffffc0201286:	26660613          	addi	a2,a2,614 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020128a:	0f700593          	li	a1,247
ffffffffc020128e:	00006517          	auipc	a0,0x6
ffffffffc0201292:	27250513          	addi	a0,a0,626 # ffffffffc0207500 <etext+0x284>
ffffffffc0201296:	f3bfe0ef          	jal	ffffffffc02001d0 <__panic>
            assert(++ listed_blocks <= nr_managed);
ffffffffc020129a:	00006697          	auipc	a3,0x6
ffffffffc020129e:	59668693          	addi	a3,a3,1430 # ffffffffc0207830 <etext+0x5b4>
ffffffffc02012a2:	00006617          	auipc	a2,0x6
ffffffffc02012a6:	24660613          	addi	a2,a2,582 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02012aa:	0dd00593          	li	a1,221
ffffffffc02012ae:	00006517          	auipc	a0,0x6
ffffffffc02012b2:	25250513          	addi	a0,a0,594 # ffffffffc0207500 <etext+0x284>
ffffffffc02012b6:	f1bfe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(n > 0 && n <= npage - nbase - index);
ffffffffc02012ba:	00006697          	auipc	a3,0x6
ffffffffc02012be:	2ce68693          	addi	a3,a3,718 # ffffffffc0207588 <etext+0x30c>
ffffffffc02012c2:	00006617          	auipc	a2,0x6
ffffffffc02012c6:	22660613          	addi	a2,a2,550 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02012ca:	02900593          	li	a1,41
ffffffffc02012ce:	00006517          	auipc	a0,0x6
ffffffffc02012d2:	23250513          	addi	a0,a0,562 # ffffffffc0207500 <etext+0x284>
ffffffffc02012d6:	efbfe0ef          	jal	ffffffffc02001d0 <__panic>
            assert(le->prev == prev);
ffffffffc02012da:	00006697          	auipc	a3,0x6
ffffffffc02012de:	57668693          	addi	a3,a3,1398 # ffffffffc0207850 <etext+0x5d4>
ffffffffc02012e2:	00006617          	auipc	a2,0x6
ffffffffc02012e6:	20660613          	addi	a2,a2,518 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02012ea:	0e000593          	li	a1,224
ffffffffc02012ee:	00006517          	auipc	a0,0x6
ffffffffc02012f2:	21250513          	addi	a0,a0,530 # ffffffffc0207500 <etext+0x284>
ffffffffc02012f6:	edbfe0ef          	jal	ffffffffc02001d0 <__panic>
            assert((page2ppn(p) & (length - 1)) == 0);
ffffffffc02012fa:	00006697          	auipc	a3,0x6
ffffffffc02012fe:	34e68693          	addi	a3,a3,846 # ffffffffc0207648 <etext+0x3cc>
ffffffffc0201302:	00006617          	auipc	a2,0x6
ffffffffc0201306:	1e660613          	addi	a2,a2,486 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020130a:	0e200593          	li	a1,226
ffffffffc020130e:	00006517          	auipc	a0,0x6
ffffffffc0201312:	1f250513          	addi	a0,a0,498 # ffffffffc0207500 <etext+0x284>
ffffffffc0201316:	ebbfe0ef          	jal	ffffffffc02001d0 <__panic>
                assert(buddy_find_partner(p, k) == NULL);
ffffffffc020131a:	00006697          	auipc	a3,0x6
ffffffffc020131e:	57e68693          	addi	a3,a3,1406 # ffffffffc0207898 <etext+0x61c>
ffffffffc0201322:	00006617          	auipc	a2,0x6
ffffffffc0201326:	1c660613          	addi	a2,a2,454 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020132a:	0e400593          	li	a1,228
ffffffffc020132e:	00006517          	auipc	a0,0x6
ffffffffc0201332:	1d250513          	addi	a0,a0,466 # ffffffffc0207500 <etext+0x284>
ffffffffc0201336:	e9bfe0ef          	jal	ffffffffc02001d0 <__panic>
            assert(base->flags & BUDDY_ALLOC_HEAD);
ffffffffc020133a:	00006697          	auipc	a3,0x6
ffffffffc020133e:	5fe68693          	addi	a3,a3,1534 # ffffffffc0207938 <etext+0x6bc>
ffffffffc0201342:	00006617          	auipc	a2,0x6
ffffffffc0201346:	1a660613          	addi	a2,a2,422 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020134a:	0fc00593          	li	a1,252
ffffffffc020134e:	00006517          	auipc	a0,0x6
ffffffffc0201352:	1b250513          	addi	a0,a0,434 # ffffffffc0207500 <etext+0x284>
ffffffffc0201356:	e7bfe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(free_blocks == listed_blocks);
ffffffffc020135a:	00006697          	auipc	a3,0x6
ffffffffc020135e:	78e68693          	addi	a3,a3,1934 # ffffffffc0207ae8 <etext+0x86c>
ffffffffc0201362:	00006617          	auipc	a2,0x6
ffffffffc0201366:	18660613          	addi	a2,a2,390 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020136a:	11400593          	li	a1,276
ffffffffc020136e:	00006517          	auipc	a0,0x6
ffffffffc0201372:	19250513          	addi	a0,a0,402 # ffffffffc0207500 <etext+0x284>
ffffffffc0201376:	e5bfe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(free_pages == nr_free && listed_pages == nr_free);
ffffffffc020137a:	00006697          	auipc	a3,0x6
ffffffffc020137e:	73668693          	addi	a3,a3,1846 # ffffffffc0207ab0 <etext+0x834>
ffffffffc0201382:	00006617          	auipc	a2,0x6
ffffffffc0201386:	16660613          	addi	a2,a2,358 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020138a:	11300593          	li	a1,275
ffffffffc020138e:	00006517          	auipc	a0,0x6
ffffffffc0201392:	17250513          	addi	a0,a0,370 # ffffffffc0207500 <etext+0x284>
ffffffffc0201396:	e3bfe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(managed_pages == nr_managed);
ffffffffc020139a:	00006697          	auipc	a3,0x6
ffffffffc020139e:	6f668693          	addi	a3,a3,1782 # ffffffffc0207a90 <etext+0x814>
ffffffffc02013a2:	00006617          	auipc	a2,0x6
ffffffffc02013a6:	14660613          	addi	a2,a2,326 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02013aa:	11200593          	li	a1,274
ffffffffc02013ae:	00006517          	auipc	a0,0x6
ffffffffc02013b2:	15250513          	addi	a0,a0,338 # ffffffffc0207500 <etext+0x284>
ffffffffc02013b6:	e1bfe0ef          	jal	ffffffffc02001d0 <__panic>
            assert(page_ref(p) == 0);
ffffffffc02013ba:	00006697          	auipc	a3,0x6
ffffffffc02013be:	6be68693          	addi	a3,a3,1726 # ffffffffc0207a78 <etext+0x7fc>
ffffffffc02013c2:	00006617          	auipc	a2,0x6
ffffffffc02013c6:	12660613          	addi	a2,a2,294 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02013ca:	10d00593          	li	a1,269
ffffffffc02013ce:	00006517          	auipc	a0,0x6
ffffffffc02013d2:	13250513          	addi	a0,a0,306 # ffffffffc0207500 <etext+0x284>
ffffffffc02013d6:	dfbfe0ef          	jal	ffffffffc02001d0 <__panic>
                assert(p->property == 0);
ffffffffc02013da:	00006697          	auipc	a3,0x6
ffffffffc02013de:	66668693          	addi	a3,a3,1638 # ffffffffc0207a40 <etext+0x7c4>
ffffffffc02013e2:	00006617          	auipc	a2,0x6
ffffffffc02013e6:	10660613          	addi	a2,a2,262 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02013ea:	10900593          	li	a1,265
ffffffffc02013ee:	00006517          	auipc	a0,0x6
ffffffffc02013f2:	11250513          	addi	a0,a0,274 # ffffffffc0207500 <etext+0x284>
ffffffffc02013f6:	ddbfe0ef          	jal	ffffffffc02001d0 <__panic>
                assert(!PageProperty(p) && !(p->flags & BUDDY_ALLOC_HEAD));
ffffffffc02013fa:	00006697          	auipc	a3,0x6
ffffffffc02013fe:	60e68693          	addi	a3,a3,1550 # ffffffffc0207a08 <etext+0x78c>
ffffffffc0201402:	00006617          	auipc	a2,0x6
ffffffffc0201406:	0e660613          	addi	a2,a2,230 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020140a:	10800593          	li	a1,264
ffffffffc020140e:	00006517          	auipc	a0,0x6
ffffffffc0201412:	0f250513          	addi	a0,a0,242 # ffffffffc0207500 <etext+0x284>
ffffffffc0201416:	dbbfe0ef          	jal	ffffffffc02001d0 <__panic>
            assert(((p->flags & BUDDY_ALLOCATED) != 0) == allocated);
ffffffffc020141a:	00006697          	auipc	a3,0x6
ffffffffc020141e:	5b668693          	addi	a3,a3,1462 # ffffffffc02079d0 <etext+0x754>
ffffffffc0201422:	00006617          	auipc	a2,0x6
ffffffffc0201426:	0c660613          	addi	a2,a2,198 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020142a:	10600593          	li	a1,262
ffffffffc020142e:	00006517          	auipc	a0,0x6
ffffffffc0201432:	0d250513          	addi	a0,a0,210 # ffffffffc0207500 <etext+0x284>
ffffffffc0201436:	d9bfe0ef          	jal	ffffffffc02001d0 <__panic>
            assert((p->flags & BUDDY_MANAGED) && !PageReserved(p));
ffffffffc020143a:	00006697          	auipc	a3,0x6
ffffffffc020143e:	56668693          	addi	a3,a3,1382 # ffffffffc02079a0 <etext+0x724>
ffffffffc0201442:	00006617          	auipc	a2,0x6
ffffffffc0201446:	0a660613          	addi	a2,a2,166 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020144a:	10500593          	li	a1,261
ffffffffc020144e:	00006517          	auipc	a0,0x6
ffffffffc0201452:	0b250513          	addi	a0,a0,178 # ffffffffc0207500 <etext+0x284>
ffffffffc0201456:	d7bfe0ef          	jal	ffffffffc02001d0 <__panic>
            assert(PageProperty(base) && base->property == length);
ffffffffc020145a:	00006697          	auipc	a3,0x6
ffffffffc020145e:	51668693          	addi	a3,a3,1302 # ffffffffc0207970 <etext+0x6f4>
ffffffffc0201462:	00006617          	auipc	a2,0x6
ffffffffc0201466:	08660613          	addi	a2,a2,134 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020146a:	0ff00593          	li	a1,255
ffffffffc020146e:	00006517          	auipc	a0,0x6
ffffffffc0201472:	09250513          	addi	a0,a0,146 # ffffffffc0207500 <etext+0x284>
ffffffffc0201476:	d5bfe0ef          	jal	ffffffffc02001d0 <__panic>
    size_t free_pages = 0, free_blocks = 0, managed_pages = 0;
ffffffffc020147a:	4881                	li	a7,0
ffffffffc020147c:	4581                	li	a1,0
ffffffffc020147e:	4801                	li	a6,0
ffffffffc0201480:	b179                	j	ffffffffc020110e <buddy_check_state+0x12a>
            assert(PageReserved(base));
ffffffffc0201482:	00006697          	auipc	a3,0x6
ffffffffc0201486:	45668693          	addi	a3,a3,1110 # ffffffffc02078d8 <etext+0x65c>
ffffffffc020148a:	00006617          	auipc	a2,0x6
ffffffffc020148e:	05e60613          	addi	a2,a2,94 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0201492:	0f100593          	li	a1,241
ffffffffc0201496:	00006517          	auipc	a0,0x6
ffffffffc020149a:	06a50513          	addi	a0,a0,106 # ffffffffc0207500 <etext+0x284>
ffffffffc020149e:	d33fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(order <= BUDDY_MAX_ORDER);
ffffffffc02014a2:	00006697          	auipc	a3,0x6
ffffffffc02014a6:	0c668693          	addi	a3,a3,198 # ffffffffc0207568 <etext+0x2ec>
ffffffffc02014aa:	00006617          	auipc	a2,0x6
ffffffffc02014ae:	03e60613          	addi	a2,a2,62 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02014b2:	45d5                	li	a1,21
ffffffffc02014b4:	00006517          	auipc	a0,0x6
ffffffffc02014b8:	04c50513          	addi	a0,a0,76 # ffffffffc0207500 <etext+0x284>
ffffffffc02014bc:	d15fe0ef          	jal	ffffffffc02001d0 <__panic>
        assert((page2ppn(base) & (length - 1)) == 0);
ffffffffc02014c0:	00006697          	auipc	a3,0x6
ffffffffc02014c4:	2b068693          	addi	a3,a3,688 # ffffffffc0207770 <etext+0x4f4>
ffffffffc02014c8:	00006617          	auipc	a2,0x6
ffffffffc02014cc:	02060613          	addi	a2,a2,32 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02014d0:	0fa00593          	li	a1,250
ffffffffc02014d4:	00006517          	auipc	a0,0x6
ffffffffc02014d8:	02c50513          	addi	a0,a0,44 # ffffffffc0207500 <etext+0x284>
ffffffffc02014dc:	cf5fe0ef          	jal	ffffffffc02001d0 <__panic>
        assert(head->prev == prev);
ffffffffc02014e0:	00006697          	auipc	a3,0x6
ffffffffc02014e4:	3e068693          	addi	a3,a3,992 # ffffffffc02078c0 <etext+0x644>
ffffffffc02014e8:	00006617          	auipc	a2,0x6
ffffffffc02014ec:	00060613          	mv	a2,a2
ffffffffc02014f0:	0ea00593          	li	a1,234
ffffffffc02014f4:	00006517          	auipc	a0,0x6
ffffffffc02014f8:	00c50513          	addi	a0,a0,12 # ffffffffc0207500 <etext+0x284>
ffffffffc02014fc:	cd5fe0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0201500 <buddy_test_reset>:
    assert(pages == buddy_test_pages && npage == nbase + BUDDY_TEST_PAGES);
ffffffffc0201500:	00026717          	auipc	a4,0x26
ffffffffc0201504:	2f073703          	ld	a4,752(a4) # ffffffffc02277f0 <pages>
ffffffffc0201508:	0000c797          	auipc	a5,0xc
ffffffffc020150c:	b1878793          	addi	a5,a5,-1256 # ffffffffc020d020 <buddy_test_pages>
ffffffffc0201510:	06f71963          	bne	a4,a5,ffffffffc0201582 <buddy_test_reset+0x82>
ffffffffc0201514:	00009697          	auipc	a3,0x9
ffffffffc0201518:	8946b683          	ld	a3,-1900(a3) # ffffffffc0209da8 <nbase>
ffffffffc020151c:	00026617          	auipc	a2,0x26
ffffffffc0201520:	2cc63603          	ld	a2,716(a2) # ffffffffc02277e8 <npage>
ffffffffc0201524:	0000c797          	auipc	a5,0xc
ffffffffc0201528:	4fc78793          	addi	a5,a5,1276 # ffffffffc020da20 <free_lists>
ffffffffc020152c:	04068693          	addi	a3,a3,64
ffffffffc0201530:	0000c717          	auipc	a4,0xc
ffffffffc0201534:	6f070713          	addi	a4,a4,1776 # ffffffffc020dc20 <slub_index>
ffffffffc0201538:	04c69563          	bne	a3,a2,ffffffffc0201582 <buddy_test_reset+0x82>
    elm->prev = elm->next = elm;
ffffffffc020153c:	e79c                	sd	a5,8(a5)
ffffffffc020153e:	e39c                	sd	a5,0(a5)
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
ffffffffc0201540:	07c1                	addi	a5,a5,16
ffffffffc0201542:	fee79de3          	bne	a5,a4,ffffffffc020153c <buddy_test_reset+0x3c>
    nr_free = nr_managed = 0;
ffffffffc0201546:	00026797          	auipc	a5,0x26
ffffffffc020154a:	2607b923          	sd	zero,626(a5) # ffffffffc02277b8 <nr_managed>
ffffffffc020154e:	00026797          	auipc	a5,0x26
ffffffffc0201552:	2607b923          	sd	zero,626(a5) # ffffffffc02277c0 <nr_free>
    for (size_t i = 0; i < BUDDY_TEST_PAGES; i ++) {
ffffffffc0201556:	0000c797          	auipc	a5,0xc
ffffffffc020155a:	ae278793          	addi	a5,a5,-1310 # ffffffffc020d038 <buddy_test_pages+0x18>
ffffffffc020155e:	0000c697          	auipc	a3,0xc
ffffffffc0201562:	4da68693          	addi	a3,a3,1242 # ffffffffc020da38 <free_lists+0x18>
        pages[i].flags = (1UL << PG_reserved);
ffffffffc0201566:	4705                	li	a4,1
ffffffffc0201568:	fee7b823          	sd	a4,-16(a5)
        pages[i].property = 0;
ffffffffc020156c:	fe07ac23          	sw	zero,-8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201570:	fe07a423          	sw	zero,-24(a5)
ffffffffc0201574:	e79c                	sd	a5,8(a5)
ffffffffc0201576:	e39c                	sd	a5,0(a5)
    for (size_t i = 0; i < BUDDY_TEST_PAGES; i ++) {
ffffffffc0201578:	02878793          	addi	a5,a5,40
ffffffffc020157c:	fed796e3          	bne	a5,a3,ffffffffc0201568 <buddy_test_reset+0x68>
    buddy_check_state();
ffffffffc0201580:	b495                	j	ffffffffc0200fe4 <buddy_check_state>
buddy_test_reset(void) {
ffffffffc0201582:	1141                	addi	sp,sp,-16
    assert(pages == buddy_test_pages && npage == nbase + BUDDY_TEST_PAGES);
ffffffffc0201584:	00006697          	auipc	a3,0x6
ffffffffc0201588:	58468693          	addi	a3,a3,1412 # ffffffffc0207b08 <etext+0x88c>
ffffffffc020158c:	00006617          	auipc	a2,0x6
ffffffffc0201590:	f5c60613          	addi	a2,a2,-164 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0201594:	12000593          	li	a1,288
ffffffffc0201598:	00006517          	auipc	a0,0x6
ffffffffc020159c:	f6850513          	addi	a0,a0,-152 # ffffffffc0207500 <etext+0x284>
buddy_test_reset(void) {
ffffffffc02015a0:	e406                	sd	ra,8(sp)
    assert(pages == buddy_test_pages && npage == nbase + BUDDY_TEST_PAGES);
ffffffffc02015a2:	c2ffe0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc02015a6 <buddy_test_failure>:
buddy_test_failure(size_t request) {
ffffffffc02015a6:	1101                	addi	sp,sp,-32
ffffffffc02015a8:	e822                	sd	s0,16(sp)
ffffffffc02015aa:	e426                	sd	s1,8(sp)
ffffffffc02015ac:	ec06                	sd	ra,24(sp)
ffffffffc02015ae:	842a                	mv	s0,a0
    uint64_t before = buddy_test_fingerprint();
ffffffffc02015b0:	ffdfe0ef          	jal	ffffffffc02005ac <buddy_test_fingerprint>
ffffffffc02015b4:	84aa                	mv	s1,a0
    assert(buddy_alloc_pages(request) == NULL);
ffffffffc02015b6:	8522                	mv	a0,s0
ffffffffc02015b8:	cc6ff0ef          	jal	ffffffffc0200a7e <buddy_alloc_pages>
ffffffffc02015bc:	e911                	bnez	a0,ffffffffc02015d0 <buddy_test_failure+0x2a>
    assert(buddy_test_fingerprint() == before);
ffffffffc02015be:	feffe0ef          	jal	ffffffffc02005ac <buddy_test_fingerprint>
ffffffffc02015c2:	02951763          	bne	a0,s1,ffffffffc02015f0 <buddy_test_failure+0x4a>
}
ffffffffc02015c6:	6442                	ld	s0,16(sp)
ffffffffc02015c8:	60e2                	ld	ra,24(sp)
ffffffffc02015ca:	64a2                	ld	s1,8(sp)
ffffffffc02015cc:	6105                	addi	sp,sp,32
    buddy_check_state();
ffffffffc02015ce:	bc19                	j	ffffffffc0200fe4 <buddy_check_state>
    assert(buddy_alloc_pages(request) == NULL);
ffffffffc02015d0:	00006697          	auipc	a3,0x6
ffffffffc02015d4:	57868693          	addi	a3,a3,1400 # ffffffffc0207b48 <etext+0x8cc>
ffffffffc02015d8:	00006617          	auipc	a2,0x6
ffffffffc02015dc:	f1060613          	addi	a2,a2,-240 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02015e0:	14900593          	li	a1,329
ffffffffc02015e4:	00006517          	auipc	a0,0x6
ffffffffc02015e8:	f1c50513          	addi	a0,a0,-228 # ffffffffc0207500 <etext+0x284>
ffffffffc02015ec:	be5fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(buddy_test_fingerprint() == before);
ffffffffc02015f0:	00006697          	auipc	a3,0x6
ffffffffc02015f4:	58068693          	addi	a3,a3,1408 # ffffffffc0207b70 <etext+0x8f4>
ffffffffc02015f8:	00006617          	auipc	a2,0x6
ffffffffc02015fc:	ef060613          	addi	a2,a2,-272 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0201600:	14a00593          	li	a1,330
ffffffffc0201604:	00006517          	auipc	a0,0x6
ffffffffc0201608:	efc50513          	addi	a0,a0,-260 # ffffffffc0207500 <etext+0x284>
ffffffffc020160c:	bc5fe0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0201610 <buddy_check>:
    panic("Buddy negative test FAILED: invalid operation was accepted");
}
#endif

static void
buddy_check(void) {
ffffffffc0201610:	ba010113          	addi	sp,sp,-1120
ffffffffc0201614:	44113c23          	sd	ra,1112(sp)
ffffffffc0201618:	41a13023          	sd	s10,1024(sp)
ffffffffc020161c:	3fb13c23          	sd	s11,1016(sp)
ffffffffc0201620:	44813823          	sd	s0,1104(sp)
ffffffffc0201624:	44913423          	sd	s1,1096(sp)
ffffffffc0201628:	45213023          	sd	s2,1088(sp)
ffffffffc020162c:	43313c23          	sd	s3,1080(sp)
ffffffffc0201630:	43413823          	sd	s4,1072(sp)
ffffffffc0201634:	43513423          	sd	s5,1064(sp)
ffffffffc0201638:	43613023          	sd	s6,1056(sp)
ffffffffc020163c:	41713c23          	sd	s7,1048(sp)
ffffffffc0201640:	41813823          	sd	s8,1040(sp)
ffffffffc0201644:	41913423          	sd	s9,1032(sp)
    buddy_check_state();
ffffffffc0201648:	99dff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    /* Save every order root and both counters. Live descriptor nodes are not
     * touched while globals point at the synthetic descriptor array; restore
     * the original roots at their original addresses before using them again.
     */
    struct Page *saved_pages = pages;
ffffffffc020164c:	00026797          	auipc	a5,0x26
ffffffffc0201650:	1a47b783          	ld	a5,420(a5) # ffffffffc02277f0 <pages>
ffffffffc0201654:	0000cd17          	auipc	s10,0xc
ffffffffc0201658:	3ccd0d13          	addi	s10,s10,972 # ffffffffc020da20 <free_lists>
ffffffffc020165c:	1f010d93          	addi	s11,sp,496
ffffffffc0201660:	e4be                	sd	a5,72(sp)
    size_t saved_npage = npage, saved_free = nr_free, saved_managed = nr_managed;
ffffffffc0201662:	00026797          	auipc	a5,0x26
ffffffffc0201666:	15e7b783          	ld	a5,350(a5) # ffffffffc02277c0 <nr_free>
ffffffffc020166a:	fc3e                	sd	a5,56(sp)
ffffffffc020166c:	00026797          	auipc	a5,0x26
ffffffffc0201670:	14c7b783          	ld	a5,332(a5) # ffffffffc02277b8 <nr_managed>
ffffffffc0201674:	e0be                	sd	a5,64(sp)
ffffffffc0201676:	00026797          	auipc	a5,0x26
ffffffffc020167a:	1727b783          	ld	a5,370(a5) # ffffffffc02277e8 <npage>
ffffffffc020167e:	e8be                	sd	a5,80(sp)
    uint64_t saved_fingerprint = buddy_test_fingerprint();
ffffffffc0201680:	f2dfe0ef          	jal	ffffffffc02005ac <buddy_test_fingerprint>
ffffffffc0201684:	ecaa                	sd	a0,88(sp)
ffffffffc0201686:	876e                	mv	a4,s11
ffffffffc0201688:	87ea                	mv	a5,s10
ffffffffc020168a:	0000c597          	auipc	a1,0xc
ffffffffc020168e:	59658593          	addi	a1,a1,1430 # ffffffffc020dc20 <slub_index>
    list_entry_t saved_lists[BUDDY_MAX_ORDER + 1];
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
        saved_lists[k] = free_lists[k];
ffffffffc0201692:	6390                	ld	a2,0(a5)
ffffffffc0201694:	6794                	ld	a3,8(a5)
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
ffffffffc0201696:	07c1                	addi	a5,a5,16
        saved_lists[k] = free_lists[k];
ffffffffc0201698:	e310                	sd	a2,0(a4)
ffffffffc020169a:	e714                	sd	a3,8(a4)
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
ffffffffc020169c:	0741                	addi	a4,a4,16
ffffffffc020169e:	feb79ae3          	bne	a5,a1,ffffffffc0201692 <buddy_check+0x82>
    }
    pages = buddy_test_pages;
    npage = nbase + BUDDY_TEST_PAGES;
ffffffffc02016a2:	00008c17          	auipc	s8,0x8
ffffffffc02016a6:	706c3c03          	ld	s8,1798(s8) # ffffffffc0209da8 <nbase>
    pages = buddy_test_pages;
ffffffffc02016aa:	00026797          	auipc	a5,0x26
ffffffffc02016ae:	14678793          	addi	a5,a5,326 # ffffffffc02277f0 <pages>
ffffffffc02016b2:	0000cb17          	auipc	s6,0xc
ffffffffc02016b6:	96eb0b13          	addi	s6,s6,-1682 # ffffffffc020d020 <buddy_test_pages>
ffffffffc02016ba:	0167b023          	sd	s6,0(a5)
    npage = nbase + BUDDY_TEST_PAGES;
ffffffffc02016be:	040c0793          	addi	a5,s8,64
ffffffffc02016c2:	00026717          	auipc	a4,0x26
ffffffffc02016c6:	12f73323          	sd	a5,294(a4) # ffffffffc02277e8 <npage>
    buddy_test_reset();
ffffffffc02016ca:	e37ff0ef          	jal	ffffffffc0201500 <buddy_test_reset>
    buddy_init_memmap(pages + 1, 13);
ffffffffc02016ce:	45b5                	li	a1,13
ffffffffc02016d0:	0000c517          	auipc	a0,0xc
ffffffffc02016d4:	97850513          	addi	a0,a0,-1672 # ffffffffc020d048 <buddy_test_pages+0x28>
ffffffffc02016d8:	9d4ff0ef          	jal	ffffffffc02008ac <buddy_init_memmap>
    assert(nr_free == 13 && nr_managed == 13);
ffffffffc02016dc:	00026797          	auipc	a5,0x26
ffffffffc02016e0:	0e47b783          	ld	a5,228(a5) # ffffffffc02277c0 <nr_free>
ffffffffc02016e4:	4735                	li	a4,13
ffffffffc02016e6:	56e797e3          	bne	a5,a4,ffffffffc0202454 <buddy_check+0xe44>
ffffffffc02016ea:	00026717          	auipc	a4,0x26
ffffffffc02016ee:	0ce73703          	ld	a4,206(a4) # ffffffffc02277b8 <nr_managed>
ffffffffc02016f2:	56f711e3          	bne	a4,a5,ffffffffc0202454 <buddy_check+0xe44>
    assert(pages[1].property == 1 && pages[2].property == 2);
ffffffffc02016f6:	0000c917          	auipc	s2,0xc
ffffffffc02016fa:	96292903          	lw	s2,-1694(s2) # ffffffffc020d058 <buddy_test_pages+0x38>
ffffffffc02016fe:	4785                	li	a5,1
ffffffffc0201700:	52f91ae3          	bne	s2,a5,ffffffffc0202434 <buddy_check+0xe24>
ffffffffc0201704:	0000c797          	auipc	a5,0xc
ffffffffc0201708:	97c7a783          	lw	a5,-1668(a5) # ffffffffc020d080 <buddy_test_pages+0x60>
ffffffffc020170c:	4709                	li	a4,2
ffffffffc020170e:	52e793e3          	bne	a5,a4,ffffffffc0202434 <buddy_check+0xe24>
    assert(pages[4].property == 4 && pages[8].property == 4);
ffffffffc0201712:	0000c717          	auipc	a4,0xc
ffffffffc0201716:	9be72703          	lw	a4,-1602(a4) # ffffffffc020d0d0 <buddy_test_pages+0xb0>
ffffffffc020171a:	4691                	li	a3,4
ffffffffc020171c:	4ed71ce3          	bne	a4,a3,ffffffffc0202414 <buddy_check+0xe04>
ffffffffc0201720:	0000c697          	auipc	a3,0xc
ffffffffc0201724:	a506a683          	lw	a3,-1456(a3) # ffffffffc020d170 <buddy_test_pages+0x150>
ffffffffc0201728:	4ee696e3          	bne	a3,a4,ffffffffc0202414 <buddy_check+0xe04>
    assert(pages[12].property == 2);
ffffffffc020172c:	0000c717          	auipc	a4,0xc
ffffffffc0201730:	ae472703          	lw	a4,-1308(a4) # ffffffffc020d210 <buddy_test_pages+0x1f0>
ffffffffc0201734:	4cf710e3          	bne	a4,a5,ffffffffc02023f4 <buddy_check+0xde4>
    buddy_check_state();
ffffffffc0201738:	8adff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    for (size_t i = 0; i < 13; i ++) {
ffffffffc020173c:	1a84                	addi	s1,sp,368
ffffffffc020173e:	1d810a93          	addi	s5,sp,472
    uint64_t seen = 0;
ffffffffc0201742:	4b81                	li	s7,0
        assert(index >= 1 && index < 14);
ffffffffc0201744:	4a31                	li	s4,12
        blocks[i] = buddy_alloc_pages(1);
ffffffffc0201746:	4505                	li	a0,1
ffffffffc0201748:	b36ff0ef          	jal	ffffffffc0200a7e <buddy_alloc_pages>
        assert(buddy_test_allocation(blocks[i], 1) == 1);
ffffffffc020174c:	4585                	li	a1,1
        blocks[i] = buddy_alloc_pages(1);
ffffffffc020174e:	e088                	sd	a0,0(s1)
ffffffffc0201750:	89aa                	mv	s3,a0
        assert(buddy_test_allocation(blocks[i], 1) == 1);
ffffffffc0201752:	c9aff0ef          	jal	ffffffffc0200bec <buddy_test_allocation>
ffffffffc0201756:	842a                	mv	s0,a0
ffffffffc0201758:	47251ee3          	bne	a0,s2,ffffffffc02023d4 <buddy_check+0xdc4>
        size_t index = buddy_page_index(blocks[i]);
ffffffffc020175c:	854e                	mv	a0,s3
ffffffffc020175e:	f13fe0ef          	jal	ffffffffc0200670 <buddy_page_index>
        assert(index >= 1 && index < 14);
ffffffffc0201762:	fff50793          	addi	a5,a0,-1
ffffffffc0201766:	44fa67e3          	bltu	s4,a5,ffffffffc02023b4 <buddy_check+0xda4>
        assert(!(seen & ((uint64_t)1 << index)));
ffffffffc020176a:	00abd7b3          	srl	a5,s7,a0
ffffffffc020176e:	8b85                	andi	a5,a5,1
ffffffffc0201770:	420792e3          	bnez	a5,ffffffffc0202394 <buddy_check+0xd84>
        seen |= (uint64_t)1 << index;
ffffffffc0201774:	00a917b3          	sll	a5,s2,a0
    for (size_t i = 0; i < 13; i ++) {
ffffffffc0201778:	04a1                	addi	s1,s1,8
        seen |= (uint64_t)1 << index;
ffffffffc020177a:	00fbebb3          	or	s7,s7,a5
        buddy_check_state();
ffffffffc020177e:	867ff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    for (size_t i = 0; i < 13; i ++) {
ffffffffc0201782:	fd5492e3          	bne	s1,s5,ffffffffc0201746 <buddy_check+0x136>
    assert(seen == (((uint64_t)1 << 14) - 2) && nr_free == 0);
ffffffffc0201786:	6791                	lui	a5,0x4
ffffffffc0201788:	17f9                	addi	a5,a5,-2 # 3ffe <kern_entry-0xffffffffc01fc002>
ffffffffc020178a:	3efb95e3          	bne	s7,a5,ffffffffc0202374 <buddy_check+0xd64>
ffffffffc020178e:	00026797          	auipc	a5,0x26
ffffffffc0201792:	0327b783          	ld	a5,50(a5) # ffffffffc02277c0 <nr_free>
ffffffffc0201796:	3c079fe3          	bnez	a5,ffffffffc0202374 <buddy_check+0xd64>
    buddy_test_failure(1);
ffffffffc020179a:	854a                	mv	a0,s2
ffffffffc020179c:	e0bff0ef          	jal	ffffffffc02015a6 <buddy_test_failure>
        buddy_free_pages(blocks[(i * 5) % 13], 1);
ffffffffc02017a0:	000c57b7          	lui	a5,0xc5
ffffffffc02017a4:	ec578793          	addi	a5,a5,-315 # c4ec5 <kern_entry-0xffffffffc013b13b>
ffffffffc02017a8:	276274b7          	lui	s1,0x27627
ffffffffc02017ac:	07b2                	slli	a5,a5,0xc
ffffffffc02017ae:	62748493          	addi	s1,s1,1575 # 27627627 <kern_entry-0xffffffff98bd89d9>
ffffffffc02017b2:	ec578793          	addi	a5,a5,-315
ffffffffc02017b6:	1486                	slli	s1,s1,0x21
ffffffffc02017b8:	94be                	add	s1,s1,a5
    buddy_test_failure(1);
ffffffffc02017ba:	4a01                	li	s4,0
    for (size_t i = 0; i < 13; i ++) {
ffffffffc02017bc:	04100913          	li	s2,65
        buddy_free_pages(blocks[(i * 5) % 13], 1);
ffffffffc02017c0:	029a3733          	mulhu	a4,s4,s1
ffffffffc02017c4:	4585                	li	a1,1
ffffffffc02017c6:	8309                	srli	a4,a4,0x2
ffffffffc02017c8:	00171793          	slli	a5,a4,0x1
ffffffffc02017cc:	97ba                	add	a5,a5,a4
ffffffffc02017ce:	078a                	slli	a5,a5,0x2
ffffffffc02017d0:	97ba                	add	a5,a5,a4
ffffffffc02017d2:	40fa07b3          	sub	a5,s4,a5
ffffffffc02017d6:	078e                	slli	a5,a5,0x3
ffffffffc02017d8:	978a                	add	a5,a5,sp
ffffffffc02017da:	1707b503          	ld	a0,368(a5)
    for (size_t i = 0; i < 13; i ++) {
ffffffffc02017de:	0a15                	addi	s4,s4,5
        buddy_free_pages(blocks[(i * 5) % 13], 1);
ffffffffc02017e0:	e06ff0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
        buddy_check_state();
ffffffffc02017e4:	801ff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    for (size_t i = 0; i < 13; i ++) {
ffffffffc02017e8:	fd2a1ce3          	bne	s4,s2,ffffffffc02017c0 <buddy_check+0x1b0>
    assert(nr_free == 13);
ffffffffc02017ec:	00026717          	auipc	a4,0x26
ffffffffc02017f0:	fd473703          	ld	a4,-44(a4) # ffffffffc02277c0 <nr_free>
ffffffffc02017f4:	47b5                	li	a5,13
ffffffffc02017f6:	34f71fe3          	bne	a4,a5,ffffffffc0202354 <buddy_check+0xd44>
    buddy_test_reset();
ffffffffc02017fa:	d07ff0ef          	jal	ffffffffc0201500 <buddy_test_reset>
    buddy_init_memmap(pages, 3);
ffffffffc02017fe:	458d                	li	a1,3
ffffffffc0201800:	0000c517          	auipc	a0,0xc
ffffffffc0201804:	82050513          	addi	a0,a0,-2016 # ffffffffc020d020 <buddy_test_pages>
ffffffffc0201808:	8a4ff0ef          	jal	ffffffffc02008ac <buddy_init_memmap>
    buddy_init_memmap(pages + 3, 5);
ffffffffc020180c:	4595                	li	a1,5
ffffffffc020180e:	0000c517          	auipc	a0,0xc
ffffffffc0201812:	88a50513          	addi	a0,a0,-1910 # ffffffffc020d098 <buddy_test_pages+0x78>
ffffffffc0201816:	896ff0ef          	jal	ffffffffc02008ac <buddy_init_memmap>
    buddy_check_state();
ffffffffc020181a:	fcaff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    assert(nr_free == 8 && pages[0].property == 8);
ffffffffc020181e:	00026797          	auipc	a5,0x26
ffffffffc0201822:	fa27b783          	ld	a5,-94(a5) # ffffffffc02277c0 <nr_free>
ffffffffc0201826:	4721                	li	a4,8
ffffffffc0201828:	30e796e3          	bne	a5,a4,ffffffffc0202334 <buddy_check+0xd24>
ffffffffc020182c:	0000c497          	auipc	s1,0xc
ffffffffc0201830:	8044a483          	lw	s1,-2044(s1) # ffffffffc020d030 <buddy_test_pages+0x10>
ffffffffc0201834:	30f490e3          	bne	s1,a5,ffffffffc0202334 <buddy_check+0xd24>
    struct Page *whole = buddy_alloc_pages(8);
ffffffffc0201838:	8526                	mv	a0,s1
ffffffffc020183a:	a44ff0ef          	jal	ffffffffc0200a7e <buddy_alloc_pages>
    assert(whole == pages);
ffffffffc020183e:	2d651be3          	bne	a0,s6,ffffffffc0202314 <buddy_check+0xd04>
    buddy_free_pages(whole, 8);
ffffffffc0201842:	85a6                	mv	a1,s1
ffffffffc0201844:	da2ff0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
    cprintf("[Buddy 1] initialization and exact registration: PASS\n");
ffffffffc0201848:	00006517          	auipc	a0,0x6
ffffffffc020184c:	4f850513          	addi	a0,a0,1272 # ffffffffc0207d40 <etext+0xac4>
ffffffffc0201850:	901fe0ef          	jal	ffffffffc0200150 <cprintf>
    buddy_test_reset();
ffffffffc0201854:	cadff0ef          	jal	ffffffffc0201500 <buddy_test_reset>
    buddy_init_memmap(pages, BUDDY_TEST_PAGES);
ffffffffc0201858:	00026497          	auipc	s1,0x26
ffffffffc020185c:	f984b483          	ld	s1,-104(s1) # ffffffffc02277f0 <pages>
ffffffffc0201860:	04000593          	li	a1,64
ffffffffc0201864:	0d010b13          	addi	s6,sp,208
ffffffffc0201868:	8526                	mv	a0,s1
ffffffffc020186a:	842ff0ef          	jal	ffffffffc02008ac <buddy_init_memmap>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020186e:	ccccd7b7          	lui	a5,0xccccd
ffffffffc0201872:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcaa5455>
ffffffffc0201876:	02079313          	slli	t1,a5,0x20
    for (size_t i = 0; i < 4; i ++) {
ffffffffc020187a:	e46a                	sd	s10,8(sp)
ffffffffc020187c:	00f30cb3          	add	s9,t1,a5
    buddy_init_memmap(pages, BUDDY_TEST_PAGES);
ffffffffc0201880:	8a5a                	mv	s4,s6
    for (size_t i = 0; i < 4; i ++) {
ffffffffc0201882:	4b81                	li	s7,0
        size_t length = (size_t)1 << i;
ffffffffc0201884:	4a85                	li	s5,1
    for (size_t i = 0; i < 4; i ++) {
ffffffffc0201886:	4991                	li	s3,4
ffffffffc0201888:	e06e                	sd	s11,0(sp)
ffffffffc020188a:	4d01                	li	s10,0
ffffffffc020188c:	8926                	mv	s2,s1
        size_t length = (size_t)1 << i;
ffffffffc020188e:	017a9db3          	sll	s11,s5,s7
        blocks[i] = buddy_alloc_pages(length);
ffffffffc0201892:	856e                	mv	a0,s11
ffffffffc0201894:	9eaff0ef          	jal	ffffffffc0200a7e <buddy_alloc_pages>
        assert(buddy_test_allocation(blocks[i], length) == length);
ffffffffc0201898:	85ee                	mv	a1,s11
        blocks[i] = buddy_alloc_pages(length);
ffffffffc020189a:	00aa3023          	sd	a0,0(s4)
ffffffffc020189e:	84aa                	mv	s1,a0
        assert(buddy_test_allocation(blocks[i], length) == length);
ffffffffc02018a0:	b4cff0ef          	jal	ffffffffc0200bec <buddy_test_allocation>
ffffffffc02018a4:	24ad98e3          	bne	s11,a0,ffffffffc02022f4 <buddy_check+0xce4>
        for (size_t j = 0; j < i; j ++) {
ffffffffc02018a8:	060b8063          	beqz	s7,ffffffffc0201908 <buddy_check+0x2f8>
ffffffffc02018ac:	41248633          	sub	a2,s1,s2
ffffffffc02018b0:	860d                	srai	a2,a2,0x3
ffffffffc02018b2:	03960633          	mul	a2,a2,s9
    assert(ap + an <= bp || bp + bn <= ap);
ffffffffc02018b6:	86da                	mv	a3,s6
        for (size_t j = 0; j < i; j ++) {
ffffffffc02018b8:	4701                	li	a4,0
ffffffffc02018ba:	9662                	add	a2,a2,s8
    assert(ap + an <= bp || bp + bn <= ap);
ffffffffc02018bc:	00cd88b3          	add	a7,s11,a2
ffffffffc02018c0:	629c                	ld	a5,0(a3)
ffffffffc02018c2:	412787b3          	sub	a5,a5,s2
ffffffffc02018c6:	878d                	srai	a5,a5,0x3
ffffffffc02018c8:	039787b3          	mul	a5,a5,s9
ffffffffc02018cc:	97e2                	add	a5,a5,s8
ffffffffc02018ce:	0117f763          	bgeu	a5,a7,ffffffffc02018dc <buddy_check+0x2cc>
            buddy_test_disjoint(blocks[i], length, blocks[j], (size_t)1 << j);
ffffffffc02018d2:	00ea95b3          	sll	a1,s5,a4
    assert(ap + an <= bp || bp + bn <= ap);
ffffffffc02018d6:	97ae                	add	a5,a5,a1
ffffffffc02018d8:	56f66e63          	bltu	a2,a5,ffffffffc0201e54 <buddy_check+0x844>
        for (size_t j = 0; j < i; j ++) {
ffffffffc02018dc:	0705                	addi	a4,a4,1
ffffffffc02018de:	06a1                	addi	a3,a3,8
ffffffffc02018e0:	ff7710e3          	bne	a4,s7,ffffffffc02018c0 <buddy_check+0x2b0>
        assert(nr_free == BUDDY_TEST_PAGES - used);
ffffffffc02018e4:	00026797          	auipc	a5,0x26
ffffffffc02018e8:	edc7b783          	ld	a5,-292(a5) # ffffffffc02277c0 <nr_free>
        used += length;
ffffffffc02018ec:	9d6e                	add	s10,s10,s11
        assert(nr_free == BUDDY_TEST_PAGES - used);
ffffffffc02018ee:	04000713          	li	a4,64
ffffffffc02018f2:	41a70733          	sub	a4,a4,s10
ffffffffc02018f6:	18f71fe3          	bne	a4,a5,ffffffffc0202294 <buddy_check+0xc84>
    for (size_t i = 0; i < 4; i ++) {
ffffffffc02018fa:	0b85                	addi	s7,s7,1
        buddy_check_state();
ffffffffc02018fc:	ee8ff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    for (size_t i = 0; i < 4; i ++) {
ffffffffc0201900:	033b8463          	beq	s7,s3,ffffffffc0201928 <buddy_check+0x318>
ffffffffc0201904:	0a21                	addi	s4,s4,8
ffffffffc0201906:	b761                	j	ffffffffc020188e <buddy_check+0x27e>
        assert(nr_free == BUDDY_TEST_PAGES - used);
ffffffffc0201908:	00026717          	auipc	a4,0x26
ffffffffc020190c:	eb873703          	ld	a4,-328(a4) # ffffffffc02277c0 <nr_free>
        used += length;
ffffffffc0201910:	0d05                	addi	s10,s10,1
        assert(nr_free == BUDDY_TEST_PAGES - used);
ffffffffc0201912:	04000793          	li	a5,64
ffffffffc0201916:	41a787b3          	sub	a5,a5,s10
ffffffffc020191a:	16f71de3          	bne	a4,a5,ffffffffc0202294 <buddy_check+0xc84>
        buddy_check_state();
ffffffffc020191e:	ec6ff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    for (size_t i = 0; i < 4; i ++) {
ffffffffc0201922:	0a21                	addi	s4,s4,8
ffffffffc0201924:	8ba2                	mv	s7,s0
ffffffffc0201926:	b7a5                	j	ffffffffc020188e <buddy_check+0x27e>
    const unsigned int release_order[] = {2, 0, 3, 1};
ffffffffc0201928:	4785                	li	a5,1
ffffffffc020192a:	1782                	slli	a5,a5,0x20
ffffffffc020192c:	078d                	addi	a5,a5,3
ffffffffc020192e:	6d82                	ld	s11,0(sp)
ffffffffc0201930:	6d22                	ld	s10,8(sp)
ffffffffc0201932:	febe                	sd	a5,376(sp)
ffffffffc0201934:	4789                	li	a5,2
ffffffffc0201936:	84ca                	mv	s1,s2
ffffffffc0201938:	fabe                	sd	a5,368(sp)
ffffffffc020193a:	17010a93          	addi	s5,sp,368
ffffffffc020193e:	18010a13          	addi	s4,sp,384
        buddy_free_pages(blocks[k], (size_t)1 << k);
ffffffffc0201942:	4905                	li	s2,1
        unsigned int k = release_order[i];
ffffffffc0201944:	000aa583          	lw	a1,0(s5)
    for (size_t i = 0; i < 4; i ++) {
ffffffffc0201948:	0a91                	addi	s5,s5,4
        buddy_free_pages(blocks[k], (size_t)1 << k);
ffffffffc020194a:	02059713          	slli	a4,a1,0x20
ffffffffc020194e:	01d75793          	srli	a5,a4,0x1d
ffffffffc0201952:	97da                	add	a5,a5,s6
ffffffffc0201954:	6388                	ld	a0,0(a5)
ffffffffc0201956:	00b915b3          	sll	a1,s2,a1
ffffffffc020195a:	c8cff0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
        buddy_check_state();
ffffffffc020195e:	e86ff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    for (size_t i = 0; i < 4; i ++) {
ffffffffc0201962:	ff4a91e3          	bne	s5,s4,ffffffffc0201944 <buddy_check+0x334>
    assert(nr_free == BUDDY_TEST_PAGES && pages[0].property == BUDDY_TEST_PAGES);
ffffffffc0201966:	00026797          	auipc	a5,0x26
ffffffffc020196a:	e5a7b783          	ld	a5,-422(a5) # ffffffffc02277c0 <nr_free>
ffffffffc020196e:	04000713          	li	a4,64
ffffffffc0201972:	16e791e3          	bne	a5,a4,ffffffffc02022d4 <buddy_check+0xcc4>
ffffffffc0201976:	4898                	lw	a4,16(s1)
ffffffffc0201978:	14f71ee3          	bne	a4,a5,ffffffffc02022d4 <buddy_check+0xcc4>
    cprintf("[Buddy 2] 1/2/4/8-page allocation and release: PASS\n");
ffffffffc020197c:	00006517          	auipc	a0,0x6
ffffffffc0201980:	4c450513          	addi	a0,a0,1220 # ffffffffc0207e40 <etext+0xbc4>
ffffffffc0201984:	fccfe0ef          	jal	ffffffffc0200150 <cprintf>
    buddy_test_reset();
ffffffffc0201988:	b79ff0ef          	jal	ffffffffc0201500 <buddy_test_reset>
    buddy_init_memmap(pages, 16);
ffffffffc020198c:	00026497          	auipc	s1,0x26
ffffffffc0201990:	e644b483          	ld	s1,-412(s1) # ffffffffc02277f0 <pages>
ffffffffc0201994:	45c1                	li	a1,16
ffffffffc0201996:	8526                	mv	a0,s1
ffffffffc0201998:	f15fe0ef          	jal	ffffffffc02008ac <buddy_init_memmap>
    struct Page *a = buddy_alloc_pages(3), *b = buddy_alloc_pages(5);
ffffffffc020199c:	450d                	li	a0,3
ffffffffc020199e:	8e0ff0ef          	jal	ffffffffc0200a7e <buddy_alloc_pages>
ffffffffc02019a2:	892a                	mv	s2,a0
ffffffffc02019a4:	4515                	li	a0,5
ffffffffc02019a6:	8d8ff0ef          	jal	ffffffffc0200a7e <buddy_alloc_pages>
ffffffffc02019aa:	8aaa                	mv	s5,a0
    assert(buddy_test_allocation(a, 3) == 4);
ffffffffc02019ac:	458d                	li	a1,3
ffffffffc02019ae:	854a                	mv	a0,s2
ffffffffc02019b0:	a3cff0ef          	jal	ffffffffc0200bec <buddy_test_allocation>
ffffffffc02019b4:	4791                	li	a5,4
ffffffffc02019b6:	0ef51fe3          	bne	a0,a5,ffffffffc02022b4 <buddy_check+0xca4>
    assert(buddy_test_allocation(b, 5) == 8);
ffffffffc02019ba:	4595                	li	a1,5
ffffffffc02019bc:	8556                	mv	a0,s5
ffffffffc02019be:	a2eff0ef          	jal	ffffffffc0200bec <buddy_test_allocation>
ffffffffc02019c2:	47a1                	li	a5,8
ffffffffc02019c4:	0af518e3          	bne	a0,a5,ffffffffc0202274 <buddy_check+0xc64>
ffffffffc02019c8:	ccccd7b7          	lui	a5,0xccccd
ffffffffc02019cc:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcaa5455>
ffffffffc02019d0:	02079693          	slli	a3,a5,0x20
ffffffffc02019d4:	40990733          	sub	a4,s2,s1
ffffffffc02019d8:	96be                	add	a3,a3,a5
ffffffffc02019da:	870d                	srai	a4,a4,0x3
ffffffffc02019dc:	409a87b3          	sub	a5,s5,s1
ffffffffc02019e0:	02d70733          	mul	a4,a4,a3
ffffffffc02019e4:	878d                	srai	a5,a5,0x3
ffffffffc02019e6:	02d787b3          	mul	a5,a5,a3
ffffffffc02019ea:	9762                	add	a4,a4,s8
    assert(ap + an <= bp || bp + bn <= ap);
ffffffffc02019ec:	00470693          	addi	a3,a4,4
ffffffffc02019f0:	97e2                	add	a5,a5,s8
ffffffffc02019f2:	04d7ede3          	bltu	a5,a3,ffffffffc020224c <buddy_check+0xc3c>
    assert(nr_free == 4);
ffffffffc02019f6:	00026a17          	auipc	s4,0x26
ffffffffc02019fa:	dcaa3a03          	ld	s4,-566(s4) # ffffffffc02277c0 <nr_free>
ffffffffc02019fe:	4791                	li	a5,4
ffffffffc0201a00:	04fa1ae3          	bne	s4,a5,ffffffffc0202254 <buddy_check+0xc44>
    buddy_check_state();
ffffffffc0201a04:	de0ff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    buddy_free_pages(a, 3);
ffffffffc0201a08:	854a                	mv	a0,s2
ffffffffc0201a0a:	458d                	li	a1,3
ffffffffc0201a0c:	bdaff0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
    assert(nr_free == 8);
ffffffffc0201a10:	00026917          	auipc	s2,0x26
ffffffffc0201a14:	db093903          	ld	s2,-592(s2) # ffffffffc02277c0 <nr_free>
ffffffffc0201a18:	47a1                	li	a5,8
ffffffffc0201a1a:	00f90463          	beq	s2,a5,ffffffffc0201a22 <buddy_check+0x412>
ffffffffc0201a1e:	6710006f          	j	ffffffffc020288e <buddy_check+0x127e>
    buddy_free_pages(b, 5);
ffffffffc0201a22:	8556                	mv	a0,s5
ffffffffc0201a24:	4595                	li	a1,5
ffffffffc0201a26:	bc0ff0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
    assert(nr_free == 16 && pages[0].property == 16);
ffffffffc0201a2a:	00026797          	auipc	a5,0x26
ffffffffc0201a2e:	d967b783          	ld	a5,-618(a5) # ffffffffc02277c0 <nr_free>
ffffffffc0201a32:	4741                	li	a4,16
ffffffffc0201a34:	00e78463          	beq	a5,a4,ffffffffc0201a3c <buddy_check+0x42c>
ffffffffc0201a38:	6370006f          	j	ffffffffc020286e <buddy_check+0x125e>
ffffffffc0201a3c:	0104aa83          	lw	s5,16(s1)
ffffffffc0201a40:	00fa8463          	beq	s5,a5,ffffffffc0201a48 <buddy_check+0x438>
ffffffffc0201a44:	62b0006f          	j	ffffffffc020286e <buddy_check+0x125e>
    buddy_check_state();
ffffffffc0201a48:	d9cff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    cprintf("[Buddy 3] rounded allocation and original-size free: PASS\n");
ffffffffc0201a4c:	00006517          	auipc	a0,0x6
ffffffffc0201a50:	4cc50513          	addi	a0,a0,1228 # ffffffffc0207f18 <etext+0xc9c>
ffffffffc0201a54:	efcfe0ef          	jal	ffffffffc0200150 <cprintf>
    buddy_test_reset();
ffffffffc0201a58:	aa9ff0ef          	jal	ffffffffc0201500 <buddy_test_reset>
    buddy_init_memmap(pages, 16);
ffffffffc0201a5c:	00026497          	auipc	s1,0x26
ffffffffc0201a60:	d944b483          	ld	s1,-620(s1) # ffffffffc02277f0 <pages>
ffffffffc0201a64:	85d6                	mv	a1,s5
ffffffffc0201a66:	8526                	mv	a0,s1
ffffffffc0201a68:	e45fe0ef          	jal	ffffffffc02008ac <buddy_init_memmap>
    blocks[0] = buddy_alloc_pages(1);
ffffffffc0201a6c:	4505                	li	a0,1
ffffffffc0201a6e:	810ff0ef          	jal	ffffffffc0200a7e <buddy_alloc_pages>
ffffffffc0201a72:	8b2a                	mv	s6,a0
ffffffffc0201a74:	faaa                	sd	a0,368(sp)
    assert(blocks[0] == pages);
ffffffffc0201a76:	0000c697          	auipc	a3,0xc
ffffffffc0201a7a:	faa68693          	addi	a3,a3,-86 # ffffffffc020da20 <free_lists>
    for (unsigned int k = 0; k < 4; k ++) {
ffffffffc0201a7e:	4701                	li	a4,0
        struct Page *tail = pages + buddy_block_size(k);
ffffffffc0201a80:	02800893          	li	a7,40
    return (size_t)1 << order;
ffffffffc0201a84:	4505                	li	a0,1
    assert(blocks[0] == pages);
ffffffffc0201a86:	5d6494e3          	bne	s1,s6,ffffffffc020284e <buddy_check+0x123e>
        struct Page *tail = pages + buddy_block_size(k);
ffffffffc0201a8a:	00e897b3          	sll	a5,a7,a4
ffffffffc0201a8e:	97da                	add	a5,a5,s6
        assert(PageProperty(tail) && tail->property == buddy_block_size(k));
ffffffffc0201a90:	6790                	ld	a2,8(a5)
ffffffffc0201a92:	8a09                	andi	a2,a2,2
ffffffffc0201a94:	58060de3          	beqz	a2,ffffffffc020282e <buddy_check+0x121e>
ffffffffc0201a98:	0107e583          	lwu	a1,16(a5)
    return (size_t)1 << order;
ffffffffc0201a9c:	00e51633          	sll	a2,a0,a4
        assert(PageProperty(tail) && tail->property == buddy_block_size(k));
ffffffffc0201aa0:	58c597e3          	bne	a1,a2,ffffffffc020282e <buddy_check+0x121e>
        assert(list_next(&free_lists[k]) == &tail->page_link);
ffffffffc0201aa4:	668c                	ld	a1,8(a3)
ffffffffc0201aa6:	01878613          	addi	a2,a5,24
ffffffffc0201aaa:	56c592e3          	bne	a1,a2,ffffffffc020280e <buddy_check+0x11fe>
        assert(list_next(&tail->page_link) == &free_lists[k]);
ffffffffc0201aae:	739c                	ld	a5,32(a5)
ffffffffc0201ab0:	52d79fe3          	bne	a5,a3,ffffffffc02027ee <buddy_check+0x11de>
    for (unsigned int k = 0; k < 4; k ++) {
ffffffffc0201ab4:	2705                	addiw	a4,a4,1
ffffffffc0201ab6:	06c1                	addi	a3,a3,16
ffffffffc0201ab8:	fd4719e3          	bne	a4,s4,ffffffffc0201a8a <buddy_check+0x47a>
    buddy_check_state();
ffffffffc0201abc:	d28ff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    for (size_t i = 1; i < 16; i ++) {
ffffffffc0201ac0:	1aa4                	addi	s1,sp,376
        blocks[i] = buddy_alloc_pages(1);
ffffffffc0201ac2:	4a85                	li	s5,1
        assert(index < 16 && !(seen & ((uint64_t)1 << index)));
ffffffffc0201ac4:	4a3d                	li	s4,15
        blocks[i] = buddy_alloc_pages(1);
ffffffffc0201ac6:	4505                	li	a0,1
ffffffffc0201ac8:	fb7fe0ef          	jal	ffffffffc0200a7e <buddy_alloc_pages>
        buddy_test_allocation(blocks[i], 1);
ffffffffc0201acc:	4585                	li	a1,1
        blocks[i] = buddy_alloc_pages(1);
ffffffffc0201ace:	e088                	sd	a0,0(s1)
ffffffffc0201ad0:	89aa                	mv	s3,a0
        buddy_test_allocation(blocks[i], 1);
ffffffffc0201ad2:	91aff0ef          	jal	ffffffffc0200bec <buddy_test_allocation>
        size_t index = buddy_page_index(blocks[i]);
ffffffffc0201ad6:	854e                	mv	a0,s3
ffffffffc0201ad8:	b99fe0ef          	jal	ffffffffc0200670 <buddy_page_index>
        assert(index < 16 && !(seen & ((uint64_t)1 << index)));
ffffffffc0201adc:	4eaa69e3          	bltu	s4,a0,ffffffffc02027ce <buddy_check+0x11be>
ffffffffc0201ae0:	00a457b3          	srl	a5,s0,a0
ffffffffc0201ae4:	8b85                	andi	a5,a5,1
ffffffffc0201ae6:	4e0794e3          	bnez	a5,ffffffffc02027ce <buddy_check+0x11be>
        seen |= (uint64_t)1 << index;
ffffffffc0201aea:	00aa9533          	sll	a0,s5,a0
ffffffffc0201aee:	8c49                	or	s0,s0,a0
        buddy_check_state();
ffffffffc0201af0:	cf4ff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    for (size_t i = 1; i < 16; i ++) {
ffffffffc0201af4:	04a1                	addi	s1,s1,8
ffffffffc0201af6:	1b9c                	addi	a5,sp,496
ffffffffc0201af8:	fc9797e3          	bne	a5,s1,ffffffffc0201ac6 <buddy_check+0x4b6>
    assert(seen == 0xffff && nr_free == 0);
ffffffffc0201afc:	67c1                	lui	a5,0x10
ffffffffc0201afe:	17fd                	addi	a5,a5,-1 # ffff <kern_entry-0xffffffffc01f0001>
ffffffffc0201b00:	4af417e3          	bne	s0,a5,ffffffffc02027ae <buddy_check+0x119e>
ffffffffc0201b04:	00026797          	auipc	a5,0x26
ffffffffc0201b08:	cbc7b783          	ld	a5,-836(a5) # ffffffffc02277c0 <nr_free>
ffffffffc0201b0c:	4a0791e3          	bnez	a5,ffffffffc02027ae <buddy_check+0x119e>
    buddy_test_failure(1);
ffffffffc0201b10:	4505                	li	a0,1
ffffffffc0201b12:	a95ff0ef          	jal	ffffffffc02015a6 <buddy_test_failure>
    for (size_t i = 16; i > 0; i --) {
ffffffffc0201b16:	13a4                	addi	s1,sp,488
ffffffffc0201b18:	12a0                	addi	s0,sp,360
        buddy_free_pages(blocks[i - 1], 1);
ffffffffc0201b1a:	6088                	ld	a0,0(s1)
ffffffffc0201b1c:	4585                	li	a1,1
    for (size_t i = 16; i > 0; i --) {
ffffffffc0201b1e:	14e1                	addi	s1,s1,-8
        buddy_free_pages(blocks[i - 1], 1);
ffffffffc0201b20:	ac6ff0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
        buddy_check_state();
ffffffffc0201b24:	cc0ff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    for (size_t i = 16; i > 0; i --) {
ffffffffc0201b28:	fe9419e3          	bne	s0,s1,ffffffffc0201b1a <buddy_check+0x50a>
    assert(nr_free == 16 && pages[0].property == 16);
ffffffffc0201b2c:	00026797          	auipc	a5,0x26
ffffffffc0201b30:	c947b783          	ld	a5,-876(a5) # ffffffffc02277c0 <nr_free>
ffffffffc0201b34:	4741                	li	a4,16
ffffffffc0201b36:	44e79ce3          	bne	a5,a4,ffffffffc020278e <buddy_check+0x117e>
ffffffffc0201b3a:	010b2703          	lw	a4,16(s6)
ffffffffc0201b3e:	44f718e3          	bne	a4,a5,ffffffffc020278e <buddy_check+0x117e>
    cprintf("[Buddy 4] multi-level split and reuse of every tail: PASS\n");
ffffffffc0201b42:	00006517          	auipc	a0,0x6
ffffffffc0201b46:	51e50513          	addi	a0,a0,1310 # ffffffffc0208060 <etext+0xde4>
ffffffffc0201b4a:	e06fe0ef          	jal	ffffffffc0200150 <cprintf>
    buddy_test_reset();
ffffffffc0201b4e:	9b3ff0ef          	jal	ffffffffc0201500 <buddy_test_reset>
    buddy_init_memmap(pages, 8);
ffffffffc0201b52:	00026a17          	auipc	s4,0x26
ffffffffc0201b56:	c9ea3a03          	ld	s4,-866(s4) # ffffffffc02277f0 <pages>
ffffffffc0201b5a:	45a1                	li	a1,8
    unsigned int seen = 0;
ffffffffc0201b5c:	4b01                	li	s6,0
    buddy_init_memmap(pages, 8);
ffffffffc0201b5e:	8552                	mv	a0,s4
ffffffffc0201b60:	d4dfe0ef          	jal	ffffffffc02008ac <buddy_init_memmap>
        assert(index < 8 && !(seen & (1U << index)));
ffffffffc0201b64:	4a9d                	li	s5,7
        seen |= 1U << index;
ffffffffc0201b66:	4485                	li	s1,1
        struct Page *p = buddy_alloc_pages(1);
ffffffffc0201b68:	4505                	li	a0,1
ffffffffc0201b6a:	f15fe0ef          	jal	ffffffffc0200a7e <buddy_alloc_pages>
        buddy_test_allocation(p, 1);
ffffffffc0201b6e:	4585                	li	a1,1
        struct Page *p = buddy_alloc_pages(1);
ffffffffc0201b70:	842a                	mv	s0,a0
        buddy_test_allocation(p, 1);
ffffffffc0201b72:	87aff0ef          	jal	ffffffffc0200bec <buddy_test_allocation>
        size_t index = buddy_page_index(p);
ffffffffc0201b76:	8522                	mv	a0,s0
ffffffffc0201b78:	af9fe0ef          	jal	ffffffffc0200670 <buddy_page_index>
        assert(index < 8 && !(seen & (1U << index)));
ffffffffc0201b7c:	3eaae9e3          	bltu	s5,a0,ffffffffc020276e <buddy_check+0x115e>
ffffffffc0201b80:	00ab57bb          	srlw	a5,s6,a0
ffffffffc0201b84:	8b85                	andi	a5,a5,1
ffffffffc0201b86:	3e0794e3          	bnez	a5,ffffffffc020276e <buddy_check+0x115e>
        blocks[index] = p;
ffffffffc0201b8a:	00351793          	slli	a5,a0,0x3
ffffffffc0201b8e:	978a                	add	a5,a5,sp
        seen |= 1U << index;
ffffffffc0201b90:	00a4953b          	sllw	a0,s1,a0
    for (size_t i = 0; i < 8; i ++) {
ffffffffc0201b94:	197d                	addi	s2,s2,-1
        blocks[index] = p;
ffffffffc0201b96:	1687b823          	sd	s0,368(a5)
        seen |= 1U << index;
ffffffffc0201b9a:	01656b33          	or	s6,a0,s6
    for (size_t i = 0; i < 8; i ++) {
ffffffffc0201b9e:	fc0915e3          	bnez	s2,ffffffffc0201b68 <buddy_check+0x558>
    assert(seen == 0xff);
ffffffffc0201ba2:	0ff00793          	li	a5,255
ffffffffc0201ba6:	3afb14e3          	bne	s6,a5,ffffffffc020274e <buddy_check+0x113e>
    buddy_free_pages(blocks[1], 1);
ffffffffc0201baa:	7576                	ld	a0,376(sp)
ffffffffc0201bac:	4585                	li	a1,1
ffffffffc0201bae:	a38ff0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
    buddy_free_pages(blocks[2], 1);
ffffffffc0201bb2:	651a                	ld	a0,384(sp)
ffffffffc0201bb4:	4585                	li	a1,1
ffffffffc0201bb6:	a30ff0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
    assert(nr_free == 2 && pages[1].property == 1 && pages[2].property == 1);
ffffffffc0201bba:	00026717          	auipc	a4,0x26
ffffffffc0201bbe:	c0673703          	ld	a4,-1018(a4) # ffffffffc02277c0 <nr_free>
ffffffffc0201bc2:	4789                	li	a5,2
ffffffffc0201bc4:	f43a                	sd	a4,40(sp)
ffffffffc0201bc6:	36f714e3          	bne	a4,a5,ffffffffc020272e <buddy_check+0x111e>
ffffffffc0201bca:	038a2783          	lw	a5,56(s4)
ffffffffc0201bce:	4705                	li	a4,1
ffffffffc0201bd0:	34e79fe3          	bne	a5,a4,ffffffffc020272e <buddy_check+0x111e>
ffffffffc0201bd4:	060a2403          	lw	s0,96(s4)
ffffffffc0201bd8:	34f41be3          	bne	s0,a5,ffffffffc020272e <buddy_check+0x111e>
    buddy_check_state();
ffffffffc0201bdc:	c08ff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    buddy_test_failure(2);
ffffffffc0201be0:	74a2                	ld	s1,40(sp)
ffffffffc0201be2:	8526                	mv	a0,s1
ffffffffc0201be4:	9c3ff0ef          	jal	ffffffffc02015a6 <buddy_test_failure>
    buddy_free_pages(blocks[0], 1);
ffffffffc0201be8:	7556                	ld	a0,368(sp)
ffffffffc0201bea:	85a2                	mv	a1,s0
ffffffffc0201bec:	9faff0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
    assert(pages[0].property == 2);
ffffffffc0201bf0:	010a2783          	lw	a5,16(s4)
ffffffffc0201bf4:	30979de3          	bne	a5,s1,ffffffffc020270e <buddy_check+0x10fe>
    struct Page *pair = buddy_alloc_pages(2);
ffffffffc0201bf8:	7522                	ld	a0,40(sp)
ffffffffc0201bfa:	e85fe0ef          	jal	ffffffffc0200a7e <buddy_alloc_pages>
ffffffffc0201bfe:	84aa                	mv	s1,a0
    assert(pair == pages && nr_free == 1);
ffffffffc0201c00:	2eaa17e3          	bne	s4,a0,ffffffffc02026ee <buddy_check+0x10de>
ffffffffc0201c04:	00026797          	auipc	a5,0x26
ffffffffc0201c08:	bbc7b783          	ld	a5,-1092(a5) # ffffffffc02277c0 <nr_free>
ffffffffc0201c0c:	f83e                	sd	a5,48(sp)
ffffffffc0201c0e:	2e8790e3          	bne	a5,s0,ffffffffc02026ee <buddy_check+0x10de>
    buddy_free_pages(pair, 2);
ffffffffc0201c12:	4589                	li	a1,2
ffffffffc0201c14:	9d2ff0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
    buddy_free_pages(blocks[3], 1);
ffffffffc0201c18:	653a                	ld	a0,392(sp)
ffffffffc0201c1a:	4585                	li	a1,1
ffffffffc0201c1c:	9caff0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
    assert(pages[0].property == 4 && nr_free == 4);
ffffffffc0201c20:	489c                	lw	a5,16(s1)
ffffffffc0201c22:	4711                	li	a4,4
ffffffffc0201c24:	2ae795e3          	bne	a5,a4,ffffffffc02026ce <buddy_check+0x10be>
ffffffffc0201c28:	00026717          	auipc	a4,0x26
ffffffffc0201c2c:	b9873703          	ld	a4,-1128(a4) # ffffffffc02277c0 <nr_free>
ffffffffc0201c30:	28f71fe3          	bne	a4,a5,ffffffffc02026ce <buddy_check+0x10be>
    buddy_check_state();
ffffffffc0201c34:	bb0ff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    const unsigned int release_order[] = {4, 6, 5, 7};
ffffffffc0201c38:	470d                	li	a4,3
ffffffffc0201c3a:	479d                	li	a5,7
ffffffffc0201c3c:	1706                	slli	a4,a4,0x21
ffffffffc0201c3e:	1782                	slli	a5,a5,0x20
ffffffffc0201c40:	0711                	addi	a4,a4,4
ffffffffc0201c42:	0795                	addi	a5,a5,5
ffffffffc0201c44:	fa3a                	sd	a4,304(sp)
ffffffffc0201c46:	fe3e                	sd	a5,312(sp)
    for (size_t i = 0; i < 4; i ++) {
ffffffffc0201c48:	13010913          	addi	s2,sp,304
ffffffffc0201c4c:	0280                	addi	s0,sp,320
        buddy_free_pages(blocks[release_order[i]], 1);
ffffffffc0201c4e:	00096783          	lwu	a5,0(s2)
ffffffffc0201c52:	4585                	li	a1,1
    for (size_t i = 0; i < 4; i ++) {
ffffffffc0201c54:	0911                	addi	s2,s2,4
        buddy_free_pages(blocks[release_order[i]], 1);
ffffffffc0201c56:	078e                	slli	a5,a5,0x3
ffffffffc0201c58:	978a                	add	a5,a5,sp
ffffffffc0201c5a:	1707b503          	ld	a0,368(a5)
ffffffffc0201c5e:	988ff0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
        buddy_check_state();
ffffffffc0201c62:	b82ff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    for (size_t i = 0; i < 4; i ++) {
ffffffffc0201c66:	fe8914e3          	bne	s2,s0,ffffffffc0201c4e <buddy_check+0x63e>
    assert(nr_free == 8 && pages[0].property == 8);
ffffffffc0201c6a:	00026797          	auipc	a5,0x26
ffffffffc0201c6e:	b567b783          	ld	a5,-1194(a5) # ffffffffc02277c0 <nr_free>
ffffffffc0201c72:	4721                	li	a4,8
ffffffffc0201c74:	22e79de3          	bne	a5,a4,ffffffffc02026ae <buddy_check+0x109e>
ffffffffc0201c78:	4880                	lw	s0,16(s1)
ffffffffc0201c7a:	22f41ae3          	bne	s0,a5,ffffffffc02026ae <buddy_check+0x109e>
    struct Page *whole = buddy_alloc_pages(8);
ffffffffc0201c7e:	8522                	mv	a0,s0
ffffffffc0201c80:	dfffe0ef          	jal	ffffffffc0200a7e <buddy_alloc_pages>
    assert(whole == pages && nr_free == 0);
ffffffffc0201c84:	20a495e3          	bne	s1,a0,ffffffffc020268e <buddy_check+0x107e>
ffffffffc0201c88:	00026797          	auipc	a5,0x26
ffffffffc0201c8c:	b387b783          	ld	a5,-1224(a5) # ffffffffc02277c0 <nr_free>
ffffffffc0201c90:	1e079fe3          	bnez	a5,ffffffffc020268e <buddy_check+0x107e>
    buddy_free_pages(whole, 8);
ffffffffc0201c94:	85a2                	mv	a1,s0
ffffffffc0201c96:	950ff0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
    cprintf("[Buddy 5] true buddies, non-buddies and recursive merge: PASS\n");
ffffffffc0201c9a:	00006517          	auipc	a0,0x6
ffffffffc0201c9e:	50650513          	addi	a0,a0,1286 # ffffffffc02081a0 <etext+0xf24>
ffffffffc0201ca2:	caefe0ef          	jal	ffffffffc0200150 <cprintf>
    buddy_test_reset();
ffffffffc0201ca6:	85bff0ef          	jal	ffffffffc0201500 <buddy_test_reset>
    buddy_test_failure(1);
ffffffffc0201caa:	4505                	li	a0,1
ffffffffc0201cac:	8fbff0ef          	jal	ffffffffc02015a6 <buddy_test_failure>
    buddy_init_memmap(pages, 16);
ffffffffc0201cb0:	00026517          	auipc	a0,0x26
ffffffffc0201cb4:	b4053503          	ld	a0,-1216(a0) # ffffffffc02277f0 <pages>
ffffffffc0201cb8:	45c1                	li	a1,16
ffffffffc0201cba:	bf3fe0ef          	jal	ffffffffc02008ac <buddy_init_memmap>
    buddy_test_failure(17);
ffffffffc0201cbe:	4545                	li	a0,17
ffffffffc0201cc0:	8e7ff0ef          	jal	ffffffffc02015a6 <buddy_test_failure>
    struct Page *p = buddy_alloc_pages(3);
ffffffffc0201cc4:	450d                	li	a0,3
ffffffffc0201cc6:	db9fe0ef          	jal	ffffffffc0200a7e <buddy_alloc_pages>
    assert(buddy_test_allocation(p, 3) == 4);
ffffffffc0201cca:	458d                	li	a1,3
    struct Page *p = buddy_alloc_pages(3);
ffffffffc0201ccc:	84aa                	mv	s1,a0
    assert(buddy_test_allocation(p, 3) == 4);
ffffffffc0201cce:	f1ffe0ef          	jal	ffffffffc0200bec <buddy_test_allocation>
ffffffffc0201cd2:	4791                	li	a5,4
ffffffffc0201cd4:	18f51de3          	bne	a0,a5,ffffffffc020266e <buddy_check+0x105e>
    buddy_test_failure(16);
ffffffffc0201cd8:	4541                	li	a0,16
ffffffffc0201cda:	8cdff0ef          	jal	ffffffffc02015a6 <buddy_test_failure>
    buddy_test_failure(buddy_block_size(BUDDY_MAX_ORDER) + 1);
ffffffffc0201cde:	4505                	li	a0,1
ffffffffc0201ce0:	057e                	slli	a0,a0,0x1f
ffffffffc0201ce2:	0505                	addi	a0,a0,1
ffffffffc0201ce4:	8c3ff0ef          	jal	ffffffffc02015a6 <buddy_test_failure>
    buddy_test_failure((size_t)-1);
ffffffffc0201ce8:	557d                	li	a0,-1
ffffffffc0201cea:	8bdff0ef          	jal	ffffffffc02015a6 <buddy_test_failure>
    assert(p->property == 3 && (p->flags & BUDDY_ALLOC_HEAD));
ffffffffc0201cee:	488c                	lw	a1,16(s1)
ffffffffc0201cf0:	478d                	li	a5,3
ffffffffc0201cf2:	14f59ee3          	bne	a1,a5,ffffffffc020264e <buddy_check+0x103e>
ffffffffc0201cf6:	649c                	ld	a5,8(s1)
ffffffffc0201cf8:	8bc1                	andi	a5,a5,16
ffffffffc0201cfa:	14078ae3          	beqz	a5,ffffffffc020264e <buddy_check+0x103e>
    buddy_free_pages(p, 3);
ffffffffc0201cfe:	8526                	mv	a0,s1
ffffffffc0201d00:	8e6ff0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
    assert(nr_free == 16);
ffffffffc0201d04:	00026717          	auipc	a4,0x26
ffffffffc0201d08:	abc73703          	ld	a4,-1348(a4) # ffffffffc02277c0 <nr_free>
ffffffffc0201d0c:	47c1                	li	a5,16
ffffffffc0201d0e:	12f710e3          	bne	a4,a5,ffffffffc020262e <buddy_check+0x101e>
    cprintf("[Buddy 6] allocation failures preserve all state: PASS\n");
ffffffffc0201d12:	00006517          	auipc	a0,0x6
ffffffffc0201d16:	53e50513          	addi	a0,a0,1342 # ffffffffc0208250 <etext+0xfd4>
ffffffffc0201d1a:	c36fe0ef          	jal	ffffffffc0200150 <cprintf>
    buddy_test_reset();
ffffffffc0201d1e:	fe2ff0ef          	jal	ffffffffc0201500 <buddy_test_reset>
    buddy_init_memmap(pages, BUDDY_TEST_PAGES);
ffffffffc0201d22:	00026b97          	auipc	s7,0x26
ffffffffc0201d26:	acebbb83          	ld	s7,-1330(s7) # ffffffffc02277f0 <pages>
ffffffffc0201d2a:	04000593          	li	a1,64
    uint32_t seed = 0x2026;
ffffffffc0201d2e:	6909                	lui	s2,0x2
    buddy_init_memmap(pages, BUDDY_TEST_PAGES);
ffffffffc0201d30:	855e                	mv	a0,s7
ffffffffc0201d32:	b7bfe0ef          	jal	ffffffffc02008ac <buddy_init_memmap>
ffffffffc0201d36:	ccccd7b7          	lui	a5,0xccccd
ffffffffc0201d3a:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcaa5455>
ffffffffc0201d3e:	02079313          	slli	t1,a5,0x20
        seed = seed * 1664525U + 1013904223U;
ffffffffc0201d42:	00196737          	lui	a4,0x196
ffffffffc0201d46:	00f30cb3          	add	s9,t1,a5
ffffffffc0201d4a:	60d7071b          	addiw	a4,a4,1549 # 19660d <kern_entry-0xffffffffc00699f3>
ffffffffc0201d4e:	3c6ef7b7          	lui	a5,0x3c6ef
ffffffffc0201d52:	35f7879b          	addiw	a5,a5,863 # 3c6ef35f <kern_entry-0xffffffff83b10ca1>
ffffffffc0201d56:	c43a                	sw	a4,8(sp)
ffffffffc0201d58:	c83e                	sw	a5,16(sp)
ffffffffc0201d5a:	47a2                	lw	a5,8(sp)
    uint32_t seed = 0x2026;
ffffffffc0201d5c:	02690913          	addi	s2,s2,38 # 2026 <kern_entry-0xffffffffc01fdfda>
    size_t requests[8] = {0}, lengths[8] = {0};
ffffffffc0201d60:	f0ee                	sd	s11,96(sp)
        seed = seed * 1664525U + 1013904223U;
ffffffffc0201d62:	02f9093b          	mulw	s2,s2,a5
ffffffffc0201d66:	47c2                	lw	a5,16(sp)
    size_t requests[8] = {0}, lengths[8] = {0};
ffffffffc0201d68:	f4ea                	sd	s10,104(sp)
    struct Page *slots[8] = {NULL};
ffffffffc0201d6a:	f982                	sd	zero,240(sp)
ffffffffc0201d6c:	fd82                	sd	zero,248(sp)
ffffffffc0201d6e:	e202                	sd	zero,256(sp)
ffffffffc0201d70:	e602                	sd	zero,264(sp)
ffffffffc0201d72:	ea02                	sd	zero,272(sp)
ffffffffc0201d74:	ee02                	sd	zero,280(sp)
ffffffffc0201d76:	f202                	sd	zero,288(sp)
        seed = seed * 1664525U + 1013904223U;
ffffffffc0201d78:	0127893b          	addw	s2,a5,s2
        size_t slot = (seed >> 16) % 8;
ffffffffc0201d7c:	01095a1b          	srliw	s4,s2,0x10
    struct Page *slots[8] = {NULL};
ffffffffc0201d80:	f602                	sd	zero,296(sp)
    size_t requests[8] = {0}, lengths[8] = {0};
ffffffffc0201d82:	fa02                	sd	zero,304(sp)
ffffffffc0201d84:	fe02                	sd	zero,312(sp)
ffffffffc0201d86:	e282                	sd	zero,320(sp)
ffffffffc0201d88:	e682                	sd	zero,328(sp)
ffffffffc0201d8a:	ea82                	sd	zero,336(sp)
ffffffffc0201d8c:	ee82                	sd	zero,344(sp)
ffffffffc0201d8e:	f282                	sd	zero,352(sp)
ffffffffc0201d90:	f682                	sd	zero,360(sp)
ffffffffc0201d92:	fa82                	sd	zero,368(sp)
ffffffffc0201d94:	fe82                	sd	zero,376(sp)
ffffffffc0201d96:	e302                	sd	zero,384(sp)
ffffffffc0201d98:	e702                	sd	zero,392(sp)
ffffffffc0201d9a:	eb02                	sd	zero,400(sp)
ffffffffc0201d9c:	ef02                	sd	zero,408(sp)
ffffffffc0201d9e:	f302                	sd	zero,416(sp)
ffffffffc0201da0:	f702                	sd	zero,424(sp)
ffffffffc0201da2:	4501                	li	a0,0
ffffffffc0201da4:	8d62                	mv	s10,s8
        size_t slot = (seed >> 16) % 8;
ffffffffc0201da6:	1984                	addi	s1,sp,240
    size_t requests[8] = {0}, lengths[8] = {0};
ffffffffc0201da8:	08000993          	li	s3,128
ffffffffc0201dac:	8dde                	mv	s11,s7
        size_t slot = (seed >> 16) % 8;
ffffffffc0201dae:	007a7c13          	andi	s8,s4,7
        if (slots[slot] != NULL) {
ffffffffc0201db2:	10050b63          	beqz	a0,ffffffffc0201ec8 <buddy_check+0x8b8>
            buddy_free_pages(slots[slot], requests[slot]);
ffffffffc0201db6:	003c1a13          	slli	s4,s8,0x3
ffffffffc0201dba:	014107b3          	add	a5,sp,s4
ffffffffc0201dbe:	1307b583          	ld	a1,304(a5)
            slots[slot] = NULL;
ffffffffc0201dc2:	9a26                	add	s4,s4,s1
            buddy_free_pages(slots[slot], requests[slot]);
ffffffffc0201dc4:	822ff0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
            slots[slot] = NULL;
ffffffffc0201dc8:	000a3023          	sd	zero,0(s4)
        for (size_t i = 0; i < 8; i ++) {
ffffffffc0201dcc:	1a1c                	addi	a5,sp,304
ffffffffc0201dce:	85ce                	mv	a1,s3
ffffffffc0201dd0:	ec26                	sd	s1,24(sp)
ffffffffc0201dd2:	89ca                	mv	s3,s2
ffffffffc0201dd4:	f03e                	sd	a5,32(sp)
ffffffffc0201dd6:	8922                	mv	s2,s0
ffffffffc0201dd8:	17010a93          	addi	s5,sp,368
ffffffffc0201ddc:	8c26                	mv	s8,s1
ffffffffc0201dde:	4b81                	li	s7,0
ffffffffc0201de0:	4b01                	li	s6,0
ffffffffc0201de2:	843e                	mv	s0,a5
ffffffffc0201de4:	a039                	j	ffffffffc0201df2 <buddy_check+0x7e2>
ffffffffc0201de6:	0b05                	addi	s6,s6,1
ffffffffc0201de8:	092b0663          	beq	s6,s2,ffffffffc0201e74 <buddy_check+0x864>
ffffffffc0201dec:	0c21                	addi	s8,s8,8
ffffffffc0201dee:	0421                	addi	s0,s0,8
ffffffffc0201df0:	0aa1                	addi	s5,s5,8
            if (slots[i] == NULL) {
ffffffffc0201df2:	000c3a03          	ld	s4,0(s8)
ffffffffc0201df6:	fe0a08e3          	beqz	s4,ffffffffc0201de6 <buddy_check+0x7d6>
ffffffffc0201dfa:	e04a                	sd	s2,0(sp)
ffffffffc0201dfc:	8962                	mv	s2,s8
ffffffffc0201dfe:	8c5a                	mv	s8,s6
ffffffffc0201e00:	8b2e                	mv	s6,a1
            used += buddy_test_allocation(slots[i], requests[i]);
ffffffffc0201e02:	600c                	ld	a1,0(s0)
ffffffffc0201e04:	8552                	mv	a0,s4
ffffffffc0201e06:	de7fe0ef          	jal	ffffffffc0200bec <buddy_test_allocation>
ffffffffc0201e0a:	9baa                	add	s7,s7,a0
            for (size_t j = 0; j < i; j ++) {
ffffffffc0201e0c:	100c0663          	beqz	s8,ffffffffc0201f18 <buddy_check+0x908>
ffffffffc0201e10:	41ba06b3          	sub	a3,s4,s11
ffffffffc0201e14:	868d                	srai	a3,a3,0x3
ffffffffc0201e16:	039686b3          	mul	a3,a3,s9
ffffffffc0201e1a:	85da                	mv	a1,s6
ffffffffc0201e1c:	1a90                	addi	a2,sp,368
ffffffffc0201e1e:	8b62                	mv	s6,s8
ffffffffc0201e20:	8726                	mv	a4,s1
ffffffffc0201e22:	8c4a                	mv	s8,s2
ffffffffc0201e24:	6902                	ld	s2,0(sp)
ffffffffc0201e26:	96ea                	add	a3,a3,s10
ffffffffc0201e28:	a029                	j	ffffffffc0201e32 <buddy_check+0x822>
ffffffffc0201e2a:	0721                	addi	a4,a4,8
ffffffffc0201e2c:	0621                	addi	a2,a2,8
ffffffffc0201e2e:	faec0ce3          	beq	s8,a4,ffffffffc0201de6 <buddy_check+0x7d6>
                if (slots[j] != NULL) {
ffffffffc0201e32:	631c                	ld	a5,0(a4)
ffffffffc0201e34:	dbfd                	beqz	a5,ffffffffc0201e2a <buddy_check+0x81a>
ffffffffc0201e36:	41b787b3          	sub	a5,a5,s11
ffffffffc0201e3a:	878d                	srai	a5,a5,0x3
ffffffffc0201e3c:	039787b3          	mul	a5,a5,s9
    assert(ap + an <= bp || bp + bn <= ap);
ffffffffc0201e40:	000ab503          	ld	a0,0(s5)
ffffffffc0201e44:	9536                	add	a0,a0,a3
ffffffffc0201e46:	97ea                	add	a5,a5,s10
ffffffffc0201e48:	fea7f1e3          	bgeu	a5,a0,ffffffffc0201e2a <buddy_check+0x81a>
ffffffffc0201e4c:	6208                	ld	a0,0(a2)
ffffffffc0201e4e:	97aa                	add	a5,a5,a0
ffffffffc0201e50:	fcf6fde3          	bgeu	a3,a5,ffffffffc0201e2a <buddy_check+0x81a>
ffffffffc0201e54:	00006697          	auipc	a3,0x6
ffffffffc0201e58:	f5c68693          	addi	a3,a3,-164 # ffffffffc0207db0 <etext+0xb34>
ffffffffc0201e5c:	00005617          	auipc	a2,0x5
ffffffffc0201e60:	68c60613          	addi	a2,a2,1676 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0201e64:	16100593          	li	a1,353
ffffffffc0201e68:	00005517          	auipc	a0,0x5
ffffffffc0201e6c:	69850513          	addi	a0,a0,1688 # ffffffffc0207500 <etext+0x284>
ffffffffc0201e70:	b60fe0ef          	jal	ffffffffc02001d0 <__panic>
        assert(nr_free == BUDDY_TEST_PAGES - used);
ffffffffc0201e74:	00026717          	auipc	a4,0x26
ffffffffc0201e78:	94c73703          	ld	a4,-1716(a4) # ffffffffc02277c0 <nr_free>
ffffffffc0201e7c:	04000793          	li	a5,64
ffffffffc0201e80:	417787b3          	sub	a5,a5,s7
ffffffffc0201e84:	844a                	mv	s0,s2
ffffffffc0201e86:	894e                	mv	s2,s3
ffffffffc0201e88:	78e79363          	bne	a5,a4,ffffffffc020260e <buddy_check+0xffe>
    for (size_t step = 0; step < 128; step ++) {
ffffffffc0201e8c:	fff58993          	addi	s3,a1,-1
        buddy_check_state();
ffffffffc0201e90:	954ff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    for (size_t step = 0; step < 128; step ++) {
ffffffffc0201e94:	0c098763          	beqz	s3,ffffffffc0201f62 <buddy_check+0x952>
        seed = seed * 1664525U + 1013904223U;
ffffffffc0201e98:	47a2                	lw	a5,8(sp)
        size_t slot = (seed >> 16) % 8;
ffffffffc0201e9a:	6742                	ld	a4,16(sp)
        seed = seed * 1664525U + 1013904223U;
ffffffffc0201e9c:	032787bb          	mulw	a5,a5,s2
        size_t slot = (seed >> 16) % 8;
ffffffffc0201ea0:	97ba                	add	a5,a5,a4
ffffffffc0201ea2:	02d79713          	slli	a4,a5,0x2d
ffffffffc0201ea6:	03d75793          	srli	a5,a4,0x3d
        if (slots[slot] != NULL) {
ffffffffc0201eaa:	078e                	slli	a5,a5,0x3
ffffffffc0201eac:	97a6                	add	a5,a5,s1
ffffffffc0201eae:	6388                	ld	a0,0(a5)
        seed = seed * 1664525U + 1013904223U;
ffffffffc0201eb0:	47a2                	lw	a5,8(sp)
ffffffffc0201eb2:	02f9093b          	mulw	s2,s2,a5
ffffffffc0201eb6:	47c2                	lw	a5,16(sp)
ffffffffc0201eb8:	0127893b          	addw	s2,a5,s2
        size_t slot = (seed >> 16) % 8;
ffffffffc0201ebc:	01095a1b          	srliw	s4,s2,0x10
ffffffffc0201ec0:	007a7c13          	andi	s8,s4,7
        if (slots[slot] != NULL) {
ffffffffc0201ec4:	ee0519e3          	bnez	a0,ffffffffc0201db6 <buddy_check+0x7a6>
            size_t request = 1 + (seed >> 8) % 9;
ffffffffc0201ec8:	38e397b7          	lui	a5,0x38e39
ffffffffc0201ecc:	0089571b          	srliw	a4,s2,0x8
ffffffffc0201ed0:	e3978793          	addi	a5,a5,-455 # 38e38e39 <kern_entry-0xffffffff873c71c7>
ffffffffc0201ed4:	02f707b3          	mul	a5,a4,a5
            slots[slot] = buddy_alloc_pages(request);
ffffffffc0201ed8:	0c0e                	slli	s8,s8,0x3
            size_t request = 1 + (seed >> 8) % 9;
ffffffffc0201eda:	9385                	srli	a5,a5,0x21
ffffffffc0201edc:	0037969b          	slliw	a3,a5,0x3
ffffffffc0201ee0:	9fb5                	addw	a5,a5,a3
ffffffffc0201ee2:	40f70a3b          	subw	s4,a4,a5
ffffffffc0201ee6:	2a05                	addiw	s4,s4,1
ffffffffc0201ee8:	1a02                	slli	s4,s4,0x20
            uint64_t before = buddy_test_fingerprint();
ffffffffc0201eea:	ec2fe0ef          	jal	ffffffffc02005ac <buddy_test_fingerprint>
            size_t request = 1 + (seed >> 8) % 9;
ffffffffc0201eee:	020a5a13          	srli	s4,s4,0x20
            uint64_t before = buddy_test_fingerprint();
ffffffffc0201ef2:	8aaa                	mv	s5,a0
            slots[slot] = buddy_alloc_pages(request);
ffffffffc0201ef4:	8552                	mv	a0,s4
ffffffffc0201ef6:	b89fe0ef          	jal	ffffffffc0200a7e <buddy_alloc_pages>
ffffffffc0201efa:	018487b3          	add	a5,s1,s8
ffffffffc0201efe:	e388                	sd	a0,0(a5)
            if (slots[slot] != NULL) {
ffffffffc0201f00:	cd0d                	beqz	a0,ffffffffc0201f3a <buddy_check+0x92a>
                requests[slot] = request;
ffffffffc0201f02:	018107b3          	add	a5,sp,s8
ffffffffc0201f06:	1347b823          	sd	s4,304(a5)
                lengths[slot] = buddy_test_allocation(slots[slot], request);
ffffffffc0201f0a:	85d2                	mv	a1,s4
ffffffffc0201f0c:	ce1fe0ef          	jal	ffffffffc0200bec <buddy_test_allocation>
ffffffffc0201f10:	9c0a                	add	s8,s8,sp
ffffffffc0201f12:	16ac3823          	sd	a0,368(s8)
ffffffffc0201f16:	bd5d                	j	ffffffffc0201dcc <buddy_check+0x7bc>
            if (slots[i] == NULL) {
ffffffffc0201f18:	00893a03          	ld	s4,8(s2)
ffffffffc0201f1c:	000a1a63          	bnez	s4,ffffffffc0201f30 <buddy_check+0x920>
        for (size_t i = 0; i < 8; i ++) {
ffffffffc0201f20:	85da                	mv	a1,s6
ffffffffc0201f22:	01090c13          	addi	s8,s2,16
ffffffffc0201f26:	7b22                	ld	s6,40(sp)
ffffffffc0201f28:	6902                	ld	s2,0(sp)
ffffffffc0201f2a:	0441                	addi	s0,s0,16
ffffffffc0201f2c:	0ac1                	addi	s5,s5,16
ffffffffc0201f2e:	b5d1                	j	ffffffffc0201df2 <buddy_check+0x7e2>
ffffffffc0201f30:	7c42                	ld	s8,48(sp)
ffffffffc0201f32:	0aa1                	addi	s5,s5,8
ffffffffc0201f34:	0421                	addi	s0,s0,8
ffffffffc0201f36:	0921                	addi	s2,s2,8
ffffffffc0201f38:	b5e9                	j	ffffffffc0201e02 <buddy_check+0x7f2>
                assert(buddy_test_fingerprint() == before);
ffffffffc0201f3a:	e72fe0ef          	jal	ffffffffc02005ac <buddy_test_fingerprint>
ffffffffc0201f3e:	e8aa87e3          	beq	s5,a0,ffffffffc0201dcc <buddy_check+0x7bc>
ffffffffc0201f42:	00006697          	auipc	a3,0x6
ffffffffc0201f46:	c2e68693          	addi	a3,a3,-978 # ffffffffc0207b70 <etext+0x8f4>
ffffffffc0201f4a:	00005617          	auipc	a2,0x5
ffffffffc0201f4e:	59e60613          	addi	a2,a2,1438 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0201f52:	22b00593          	li	a1,555
ffffffffc0201f56:	00005517          	auipc	a0,0x5
ffffffffc0201f5a:	5aa50513          	addi	a0,a0,1450 # ffffffffc0207500 <etext+0x284>
ffffffffc0201f5e:	a72fe0ef          	jal	ffffffffc02001d0 <__panic>
ffffffffc0201f62:	8c6a                	mv	s8,s10
ffffffffc0201f64:	8bee                	mv	s7,s11
ffffffffc0201f66:	7d26                	ld	s10,104(sp)
ffffffffc0201f68:	7d86                	ld	s11,96(sp)
ffffffffc0201f6a:	6462                	ld	s0,24(sp)
ffffffffc0201f6c:	7902                	ld	s2,32(sp)
ffffffffc0201f6e:	04048493          	addi	s1,s1,64
        if (slots[i] != NULL) {
ffffffffc0201f72:	6008                	ld	a0,0(s0)
ffffffffc0201f74:	c519                	beqz	a0,ffffffffc0201f82 <buddy_check+0x972>
            buddy_free_pages(slots[i], requests[i]);
ffffffffc0201f76:	00093583          	ld	a1,0(s2)
ffffffffc0201f7a:	e6dfe0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
            buddy_check_state();
ffffffffc0201f7e:	866ff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    for (size_t i = 0; i < 8; i ++) {
ffffffffc0201f82:	0421                	addi	s0,s0,8
ffffffffc0201f84:	0921                	addi	s2,s2,8
ffffffffc0201f86:	fe9416e3          	bne	s0,s1,ffffffffc0201f72 <buddy_check+0x962>
    assert(nr_free == BUDDY_TEST_PAGES);
ffffffffc0201f8a:	00026417          	auipc	s0,0x26
ffffffffc0201f8e:	83643403          	ld	s0,-1994(s0) # ffffffffc02277c0 <nr_free>
ffffffffc0201f92:	04000793          	li	a5,64
ffffffffc0201f96:	64f41c63          	bne	s0,a5,ffffffffc02025ee <buddy_check+0xfde>
    struct Page *whole = buddy_alloc_pages(BUDDY_TEST_PAGES);
ffffffffc0201f9a:	8522                	mv	a0,s0
ffffffffc0201f9c:	ae3fe0ef          	jal	ffffffffc0200a7e <buddy_alloc_pages>
    assert(whole == pages && nr_free == 0);
ffffffffc0201fa0:	62ab9763          	bne	s7,a0,ffffffffc02025ce <buddy_check+0xfbe>
ffffffffc0201fa4:	00026797          	auipc	a5,0x26
ffffffffc0201fa8:	81c7b783          	ld	a5,-2020(a5) # ffffffffc02277c0 <nr_free>
ffffffffc0201fac:	62079163          	bnez	a5,ffffffffc02025ce <buddy_check+0xfbe>
    buddy_free_pages(whole, BUDDY_TEST_PAGES);
ffffffffc0201fb0:	85a2                	mv	a1,s0
ffffffffc0201fb2:	e35fe0ef          	jal	ffffffffc0200de6 <buddy_free_pages>
    buddy_check_state();
ffffffffc0201fb6:	82eff0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    cprintf("[Buddy 8] 128 reproducible operations and full recovery: PASS\n");
ffffffffc0201fba:	00006517          	auipc	a0,0x6
ffffffffc0201fbe:	2ee50513          	addi	a0,a0,750 # ffffffffc02082a8 <etext+0x102c>
ffffffffc0201fc2:	98efe0ef          	jal	ffffffffc0200150 <cprintf>
    buddy_test_rounding();
    buddy_test_split();
    buddy_test_merge();
    buddy_test_failures();
    buddy_test_rounds();
    assert(nr_free == nr_managed);
ffffffffc0201fc6:	00025717          	auipc	a4,0x25
ffffffffc0201fca:	7fa73703          	ld	a4,2042(a4) # ffffffffc02277c0 <nr_free>
ffffffffc0201fce:	00025797          	auipc	a5,0x25
ffffffffc0201fd2:	7ea7b783          	ld	a5,2026(a5) # ffffffffc02277b8 <nr_managed>
ffffffffc0201fd6:	5cf71c63          	bne	a4,a5,ffffffffc02025ae <buddy_check+0xf9e>

    pages = saved_pages;
ffffffffc0201fda:	6726                	ld	a4,72(sp)
ffffffffc0201fdc:	00026797          	auipc	a5,0x26
ffffffffc0201fe0:	81478793          	addi	a5,a5,-2028 # ffffffffc02277f0 <pages>
ffffffffc0201fe4:	e398                	sd	a4,0(a5)
    npage = saved_npage;
ffffffffc0201fe6:	6746                	ld	a4,80(sp)
ffffffffc0201fe8:	00026797          	auipc	a5,0x26
ffffffffc0201fec:	80e7b023          	sd	a4,-2048(a5) # ffffffffc02277e8 <npage>
    nr_free = saved_free;
ffffffffc0201ff0:	7762                	ld	a4,56(sp)
ffffffffc0201ff2:	00025797          	auipc	a5,0x25
ffffffffc0201ff6:	7ce78793          	addi	a5,a5,1998 # ffffffffc02277c0 <nr_free>
ffffffffc0201ffa:	e398                	sd	a4,0(a5)
    nr_managed = saved_managed;
ffffffffc0201ffc:	6706                	ld	a4,64(sp)
ffffffffc0201ffe:	00025797          	auipc	a5,0x25
ffffffffc0202002:	7ba78793          	addi	a5,a5,1978 # ffffffffc02277b8 <nr_managed>
ffffffffc0202006:	e398                	sd	a4,0(a5)
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
ffffffffc0202008:	1f9c                	addi	a5,sp,1008
        free_lists[k] = saved_lists[k];
ffffffffc020200a:	000db683          	ld	a3,0(s11)
ffffffffc020200e:	008db703          	ld	a4,8(s11)
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
ffffffffc0202012:	0dc1                	addi	s11,s11,16
        free_lists[k] = saved_lists[k];
ffffffffc0202014:	00dd3023          	sd	a3,0(s10)
ffffffffc0202018:	00ed3423          	sd	a4,8(s10)
    for (unsigned int k = 0; k <= BUDDY_MAX_ORDER; k ++) {
ffffffffc020201c:	0d41                	addi	s10,s10,16
ffffffffc020201e:	fefd96e3          	bne	s11,a5,ffffffffc020200a <buddy_check+0x9fa>
    }
    assert(buddy_test_fingerprint() == saved_fingerprint);
ffffffffc0202022:	d8afe0ef          	jal	ffffffffc02005ac <buddy_test_fingerprint>
ffffffffc0202026:	67e6                	ld	a5,88(sp)
ffffffffc0202028:	56f51363          	bne	a0,a5,ffffffffc020258e <buddy_check+0xf7e>
    buddy_check_state();
ffffffffc020202c:	fb9fe0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    size_t before = nr_free_pages();
ffffffffc0202030:	097000ef          	jal	ffffffffc02028c6 <nr_free_pages>
ffffffffc0202034:	ccccd7b7          	lui	a5,0xccccd
ffffffffc0202038:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcaa5455>
ffffffffc020203c:	02079413          	slli	s0,a5,0x20
    const size_t requests[] = {1, 3, 5}, lengths[] = {1, 4, 8};
ffffffffc0202040:	4715                	li	a4,5
ffffffffc0202042:	943e                	add	s0,s0,a5
ffffffffc0202044:	4785                	li	a5,1
ffffffffc0202046:	e13a                	sd	a4,128(sp)
ffffffffc0202048:	f8be                	sd	a5,112(sp)
ffffffffc020204a:	4711                	li	a4,4
ffffffffc020204c:	e53e                	sd	a5,136(sp)
        assert(pa >= KERNEL_BEGIN_PADDR && PADDR(buffers[i]) == pa);
ffffffffc020204e:	40100793          	li	a5,1025
ffffffffc0202052:	0a010d93          	addi	s11,sp,160
ffffffffc0202056:	08810c93          	addi	s9,sp,136
    const size_t requests[] = {1, 3, 5}, lengths[] = {1, 4, 8};
ffffffffc020205a:	e93a                	sd	a4,144(sp)
ffffffffc020205c:	4b0d                	li	s6,3
ffffffffc020205e:	4721                	li	a4,8
        assert(pa >= KERNEL_BEGIN_PADDR && PADDR(buffers[i]) == pa);
ffffffffc0202060:	07d6                	slli	a5,a5,0x15
    const size_t requests[] = {1, 3, 5}, lengths[] = {1, 4, 8};
ffffffffc0202062:	84ee                	mv	s1,s11
ffffffffc0202064:	8a66                	mv	s4,s9
        assert(pa >= KERNEL_BEGIN_PADDR && PADDR(buffers[i]) == pa);
ffffffffc0202066:	e466                	sd	s9,8(sp)
ffffffffc0202068:	e86e                	sd	s11,16(sp)
    size_t before = nr_free_pages();
ffffffffc020206a:	e02a                	sd	a0,0(sp)
    const size_t requests[] = {1, 3, 5}, lengths[] = {1, 4, 8};
ffffffffc020206c:	ed3a                	sd	a4,152(sp)
ffffffffc020206e:	fcda                	sd	s6,120(sp)
ffffffffc0202070:	07010993          	addi	s3,sp,112
        assert(pa >= KERNEL_BEGIN_PADDR && PADDR(buffers[i]) == pa);
ffffffffc0202074:	ec3e                	sd	a5,24(sp)
    size_t used = 0;
ffffffffc0202076:	4901                	li	s2,0
    const size_t requests[] = {1, 3, 5}, lengths[] = {1, 4, 8};
ffffffffc0202078:	4d01                	li	s10,0
        buffers[i] = (volatile uint8_t *)(pa + va_pa_offset);
ffffffffc020207a:	00025b97          	auipc	s7,0x25
ffffffffc020207e:	766b8b93          	addi	s7,s7,1894 # ffffffffc02277e0 <va_pa_offset>
        assert(pa >= KERNEL_BEGIN_PADDR && PADDR(buffers[i]) == pa);
ffffffffc0202082:	8ce2                	mv	s9,s8
ffffffffc0202084:	4d81                	li	s11,0
        blocks[i] = alloc_pages(requests[i]);
ffffffffc0202086:	0009ba83          	ld	s5,0(s3)
ffffffffc020208a:	8556                	mv	a0,s5
ffffffffc020208c:	023000ef          	jal	ffffffffc02028ae <alloc_pages>
        assert(buddy_test_allocation(blocks[i], requests[i]) == lengths[i]);
ffffffffc0202090:	85d6                	mv	a1,s5
        blocks[i] = alloc_pages(requests[i]);
ffffffffc0202092:	e088                	sd	a0,0(s1)
ffffffffc0202094:	8c2a                	mv	s8,a0
        assert(buddy_test_allocation(blocks[i], requests[i]) == lengths[i]);
ffffffffc0202096:	b57fe0ef          	jal	ffffffffc0200bec <buddy_test_allocation>
ffffffffc020209a:	000a3a83          	ld	s5,0(s4)
ffffffffc020209e:	4d551863          	bne	a0,s5,ffffffffc020256e <buddy_check+0xf5e>
        for (size_t j = 0; j < i; j ++) {
ffffffffc02020a2:	040d8063          	beqz	s11,ffffffffc02020e2 <buddy_check+0xad2>
ffffffffc02020a6:	00025517          	auipc	a0,0x25
ffffffffc02020aa:	74a53503          	ld	a0,1866(a0) # ffffffffc02277f0 <pages>
    assert(ap + an <= bp || bp + bn <= ap);
ffffffffc02020ae:	65a2                	ld	a1,8(sp)
ffffffffc02020b0:	66c2                	ld	a3,16(sp)
ffffffffc02020b2:	40ac0733          	sub	a4,s8,a0
ffffffffc02020b6:	870d                	srai	a4,a4,0x3
ffffffffc02020b8:	02870733          	mul	a4,a4,s0
ffffffffc02020bc:	9766                	add	a4,a4,s9
ffffffffc02020be:	00ea88b3          	add	a7,s5,a4
ffffffffc02020c2:	629c                	ld	a5,0(a3)
ffffffffc02020c4:	8f89                	sub	a5,a5,a0
ffffffffc02020c6:	878d                	srai	a5,a5,0x3
ffffffffc02020c8:	028787b3          	mul	a5,a5,s0
ffffffffc02020cc:	97e6                	add	a5,a5,s9
ffffffffc02020ce:	0117f663          	bgeu	a5,a7,ffffffffc02020da <buddy_check+0xaca>
ffffffffc02020d2:	6190                	ld	a2,0(a1)
ffffffffc02020d4:	97b2                	add	a5,a5,a2
ffffffffc02020d6:	d6f76fe3          	bltu	a4,a5,ffffffffc0201e54 <buddy_check+0x844>
        for (size_t j = 0; j < i; j ++) {
ffffffffc02020da:	06a1                	addi	a3,a3,8
ffffffffc02020dc:	05a1                	addi	a1,a1,8
ffffffffc02020de:	fe9692e3          	bne	a3,s1,ffffffffc02020c2 <buddy_check+0xab2>
ffffffffc02020e2:	00025797          	auipc	a5,0x25
ffffffffc02020e6:	70e7b783          	ld	a5,1806(a5) # ffffffffc02277f0 <pages>
        buffers[i] = (volatile uint8_t *)(pa + va_pa_offset);
ffffffffc02020ea:	000bb703          	ld	a4,0(s7)
ffffffffc02020ee:	003d9693          	slli	a3,s11,0x3
ffffffffc02020f2:	40fc07b3          	sub	a5,s8,a5
ffffffffc02020f6:	878d                	srai	a5,a5,0x3
ffffffffc02020f8:	028787b3          	mul	a5,a5,s0
ffffffffc02020fc:	968a                	add	a3,a3,sp
ffffffffc02020fe:	97e6                	add	a5,a5,s9
    return page2ppn(page) << PGSHIFT;
ffffffffc0202100:	07b2                	slli	a5,a5,0xc
ffffffffc0202102:	00e78c33          	add	s8,a5,a4
        assert(pa >= KERNEL_BEGIN_PADDR && PADDR(buffers[i]) == pa);
ffffffffc0202106:	6762                	ld	a4,24(sp)
        buffers[i] = (volatile uint8_t *)(pa + va_pa_offset);
ffffffffc0202108:	0b86bc23          	sd	s8,184(a3)
        assert(pa >= KERNEL_BEGIN_PADDR && PADDR(buffers[i]) == pa);
ffffffffc020210c:	44e7e163          	bltu	a5,a4,ffffffffc020254e <buddy_check+0xf3e>
ffffffffc0202110:	c02007b7          	lui	a5,0xc0200
ffffffffc0202114:	42fc6063          	bltu	s8,a5,ffffffffc0202534 <buddy_check+0xf24>
        assert(nr_free_pages() == before - used);
ffffffffc0202118:	7ae000ef          	jal	ffffffffc02028c6 <nr_free_pages>
ffffffffc020211c:	6782                	ld	a5,0(sp)
        used += lengths[i];
ffffffffc020211e:	9956                	add	s2,s2,s5
        assert(nr_free_pages() == before - used);
ffffffffc0202120:	412787b3          	sub	a5,a5,s2
ffffffffc0202124:	3ef51863          	bne	a0,a5,ffffffffc0202514 <buddy_check+0xf04>
        for (size_t byte = 0; byte < lengths[i] * PGSIZE; byte ++) {
ffffffffc0202128:	00ca9593          	slli	a1,s5,0xc
ffffffffc020212c:	4781                	li	a5,0
            buffers[i][byte] = (uint8_t)(i * 73 + byte);
ffffffffc020212e:	00fc0733          	add	a4,s8,a5
ffffffffc0202132:	01a786bb          	addw	a3,a5,s10
ffffffffc0202136:	00d70023          	sb	a3,0(a4)
        for (size_t byte = 0; byte < lengths[i] * PGSIZE; byte ++) {
ffffffffc020213a:	0785                	addi	a5,a5,1 # ffffffffc0200001 <kern_entry+0x1>
ffffffffc020213c:	feb7e9e3          	bltu	a5,a1,ffffffffc020212e <buddy_check+0xb1e>
    for (size_t i = 0; i < 3; i ++) {
ffffffffc0202140:	0d85                	addi	s11,s11,1
        buddy_check_state();
ffffffffc0202142:	ea3fe0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    for (size_t i = 0; i < 3; i ++) {
ffffffffc0202146:	09a1                	addi	s3,s3,8
ffffffffc0202148:	04a1                	addi	s1,s1,8
ffffffffc020214a:	0a21                	addi	s4,s4,8
ffffffffc020214c:	049d0d1b          	addiw	s10,s10,73
ffffffffc0202150:	f36d9be3          	bne	s11,s6,ffffffffc0202086 <buddy_check+0xa76>
ffffffffc0202154:	6ca2                	ld	s9,8(sp)
ffffffffc0202156:	6dc2                	ld	s11,16(sp)
ffffffffc0202158:	0b810c13          	addi	s8,sp,184
ffffffffc020215c:	4501                	li	a0,0
    for (size_t i = 0; i < 3; i ++) {
ffffffffc020215e:	0db00813          	li	a6,219
        for (size_t byte = 0; byte < lengths[i] * PGSIZE; byte ++) {
ffffffffc0202162:	000cb603          	ld	a2,0(s9)
ffffffffc0202166:	0632                	slli	a2,a2,0xc
ffffffffc0202168:	c215                	beqz	a2,ffffffffc020218c <buddy_check+0xb7c>
ffffffffc020216a:	000c3703          	ld	a4,0(s8)
            assert(buffers[i][byte] == (uint8_t)(i * 73 + byte));
ffffffffc020216e:	87ba                	mv	a5,a4
ffffffffc0202170:	963a                	add	a2,a2,a4
ffffffffc0202172:	40e505bb          	subw	a1,a0,a4
ffffffffc0202176:	0007c683          	lbu	a3,0(a5)
ffffffffc020217a:	00f5873b          	addw	a4,a1,a5
ffffffffc020217e:	0ff77713          	zext.b	a4,a4
ffffffffc0202182:	36d71963          	bne	a4,a3,ffffffffc02024f4 <buddy_check+0xee4>
        for (size_t byte = 0; byte < lengths[i] * PGSIZE; byte ++) {
ffffffffc0202186:	0785                	addi	a5,a5,1
ffffffffc0202188:	fef617e3          	bne	a2,a5,ffffffffc0202176 <buddy_check+0xb66>
    for (size_t i = 0; i < 3; i ++) {
ffffffffc020218c:	0495051b          	addiw	a0,a0,73
ffffffffc0202190:	0ff57513          	zext.b	a0,a0
ffffffffc0202194:	0ca1                	addi	s9,s9,8
ffffffffc0202196:	0c21                	addi	s8,s8,8
ffffffffc0202198:	fd0515e3          	bne	a0,a6,ffffffffc0202162 <buddy_check+0xb52>
ffffffffc020219c:	0100                	addi	s0,sp,128
ffffffffc020219e:	fe8d8493          	addi	s1,s11,-24
        free_pages(blocks[i - 1], requests[i - 1]);
ffffffffc02021a2:	600c                	ld	a1,0(s0)
ffffffffc02021a4:	010db503          	ld	a0,16(s11)
    for (size_t i = 3; i > 0; i --) {
ffffffffc02021a8:	1de1                	addi	s11,s11,-8
ffffffffc02021aa:	1461                	addi	s0,s0,-8
        free_pages(blocks[i - 1], requests[i - 1]);
ffffffffc02021ac:	70e000ef          	jal	ffffffffc02028ba <free_pages>
        buddy_check_state();
ffffffffc02021b0:	e35fe0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    for (size_t i = 3; i > 0; i --) {
ffffffffc02021b4:	ffb497e3          	bne	s1,s11,ffffffffc02021a2 <buddy_check+0xb92>
    assert(nr_free_pages() == before);
ffffffffc02021b8:	70e000ef          	jal	ffffffffc02028c6 <nr_free_pages>
ffffffffc02021bc:	6782                	ld	a5,0(sp)
ffffffffc02021be:	30a79b63          	bne	a5,a0,ffffffffc02024d4 <buddy_check+0xec4>
    cprintf("[Buddy 7] real-page data isolation and rounded tails: PASS\n");
ffffffffc02021c2:	00006517          	auipc	a0,0x6
ffffffffc02021c6:	28650513          	addi	a0,a0,646 # ffffffffc0208448 <etext+0x11cc>
ffffffffc02021ca:	f87fd0ef          	jal	ffffffffc0200150 <cprintf>
    buddy_test_data();
    assert(nr_free_pages() == saved_free && nr_managed == saved_managed);
ffffffffc02021ce:	6f8000ef          	jal	ffffffffc02028c6 <nr_free_pages>
ffffffffc02021d2:	77e2                	ld	a5,56(sp)
ffffffffc02021d4:	2ef51063          	bne	a0,a5,ffffffffc02024b4 <buddy_check+0xea4>
ffffffffc02021d8:	00025797          	auipc	a5,0x25
ffffffffc02021dc:	5e07b783          	ld	a5,1504(a5) # ffffffffc02277b8 <nr_managed>
ffffffffc02021e0:	6706                	ld	a4,64(sp)
ffffffffc02021e2:	2ce79963          	bne	a5,a4,ffffffffc02024b4 <buddy_check+0xea4>
    buddy_check_state();
ffffffffc02021e6:	dfffe0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    struct Page *again = alloc_pages(1);
ffffffffc02021ea:	4505                	li	a0,1
ffffffffc02021ec:	6c2000ef          	jal	ffffffffc02028ae <alloc_pages>
    assert(again != NULL);
ffffffffc02021f0:	2a050263          	beqz	a0,ffffffffc0202494 <buddy_check+0xe84>
    free_pages(again, 1);
ffffffffc02021f4:	4585                	li	a1,1
ffffffffc02021f6:	6c4000ef          	jal	ffffffffc02028ba <free_pages>
    assert(nr_free_pages() == saved_free);
ffffffffc02021fa:	6cc000ef          	jal	ffffffffc02028c6 <nr_free_pages>
ffffffffc02021fe:	77e2                	ld	a5,56(sp)
ffffffffc0202200:	26f51a63          	bne	a0,a5,ffffffffc0202474 <buddy_check+0xe64>
    buddy_check_state();
ffffffffc0202204:	de1fe0ef          	jal	ffffffffc0200fe4 <buddy_check_state>
    cprintf("buddy_check: all 8 groups passed; live allocator restored\n");
}
ffffffffc0202208:	45013403          	ld	s0,1104(sp)
ffffffffc020220c:	45813083          	ld	ra,1112(sp)
ffffffffc0202210:	44813483          	ld	s1,1096(sp)
ffffffffc0202214:	44013903          	ld	s2,1088(sp)
ffffffffc0202218:	43813983          	ld	s3,1080(sp)
ffffffffc020221c:	43013a03          	ld	s4,1072(sp)
ffffffffc0202220:	42813a83          	ld	s5,1064(sp)
ffffffffc0202224:	42013b03          	ld	s6,1056(sp)
ffffffffc0202228:	41813b83          	ld	s7,1048(sp)
ffffffffc020222c:	41013c03          	ld	s8,1040(sp)
ffffffffc0202230:	40813c83          	ld	s9,1032(sp)
ffffffffc0202234:	40013d03          	ld	s10,1024(sp)
ffffffffc0202238:	3f813d83          	ld	s11,1016(sp)
    cprintf("buddy_check: all 8 groups passed; live allocator restored\n");
ffffffffc020223c:	00006517          	auipc	a0,0x6
ffffffffc0202240:	2bc50513          	addi	a0,a0,700 # ffffffffc02084f8 <etext+0x127c>
}
ffffffffc0202244:	46010113          	addi	sp,sp,1120
    cprintf("buddy_check: all 8 groups passed; live allocator restored\n");
ffffffffc0202248:	f09fd06f          	j	ffffffffc0200150 <cprintf>
    assert(ap + an <= bp || bp + bn <= ap);
ffffffffc020224c:	07a1                	addi	a5,a5,8
ffffffffc020224e:	faf77463          	bgeu	a4,a5,ffffffffc02019f6 <buddy_check+0x3e6>
ffffffffc0202252:	b109                	j	ffffffffc0201e54 <buddy_check+0x844>
    assert(nr_free == 4);
ffffffffc0202254:	00006697          	auipc	a3,0x6
ffffffffc0202258:	c7468693          	addi	a3,a3,-908 # ffffffffc0207ec8 <etext+0xc4c>
ffffffffc020225c:	00005617          	auipc	a2,0x5
ffffffffc0202260:	28c60613          	addi	a2,a2,652 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0202264:	1b000593          	li	a1,432
ffffffffc0202268:	00005517          	auipc	a0,0x5
ffffffffc020226c:	29850513          	addi	a0,a0,664 # ffffffffc0207500 <etext+0x284>
ffffffffc0202270:	f61fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(buddy_test_allocation(b, 5) == 8);
ffffffffc0202274:	00006697          	auipc	a3,0x6
ffffffffc0202278:	c2c68693          	addi	a3,a3,-980 # ffffffffc0207ea0 <etext+0xc24>
ffffffffc020227c:	00005617          	auipc	a2,0x5
ffffffffc0202280:	26c60613          	addi	a2,a2,620 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0202284:	1ae00593          	li	a1,430
ffffffffc0202288:	00005517          	auipc	a0,0x5
ffffffffc020228c:	27850513          	addi	a0,a0,632 # ffffffffc0207500 <etext+0x284>
ffffffffc0202290:	f41fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(nr_free == BUDDY_TEST_PAGES - used);
ffffffffc0202294:	00006697          	auipc	a3,0x6
ffffffffc0202298:	b3c68693          	addi	a3,a3,-1220 # ffffffffc0207dd0 <etext+0xb54>
ffffffffc020229c:	00005617          	auipc	a2,0x5
ffffffffc02022a0:	24c60613          	addi	a2,a2,588 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02022a4:	19b00593          	li	a1,411
ffffffffc02022a8:	00005517          	auipc	a0,0x5
ffffffffc02022ac:	25850513          	addi	a0,a0,600 # ffffffffc0207500 <etext+0x284>
ffffffffc02022b0:	f21fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(buddy_test_allocation(a, 3) == 4);
ffffffffc02022b4:	00006697          	auipc	a3,0x6
ffffffffc02022b8:	bc468693          	addi	a3,a3,-1084 # ffffffffc0207e78 <etext+0xbfc>
ffffffffc02022bc:	00005617          	auipc	a2,0x5
ffffffffc02022c0:	22c60613          	addi	a2,a2,556 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02022c4:	1ad00593          	li	a1,429
ffffffffc02022c8:	00005517          	auipc	a0,0x5
ffffffffc02022cc:	23850513          	addi	a0,a0,568 # ffffffffc0207500 <etext+0x284>
ffffffffc02022d0:	f01fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free == BUDDY_TEST_PAGES && pages[0].property == BUDDY_TEST_PAGES);
ffffffffc02022d4:	00006697          	auipc	a3,0x6
ffffffffc02022d8:	b2468693          	addi	a3,a3,-1244 # ffffffffc0207df8 <etext+0xb7c>
ffffffffc02022dc:	00005617          	auipc	a2,0x5
ffffffffc02022e0:	20c60613          	addi	a2,a2,524 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02022e4:	1a400593          	li	a1,420
ffffffffc02022e8:	00005517          	auipc	a0,0x5
ffffffffc02022ec:	21850513          	addi	a0,a0,536 # ffffffffc0207500 <etext+0x284>
ffffffffc02022f0:	ee1fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(buddy_test_allocation(blocks[i], length) == length);
ffffffffc02022f4:	00006697          	auipc	a3,0x6
ffffffffc02022f8:	a8468693          	addi	a3,a3,-1404 # ffffffffc0207d78 <etext+0xafc>
ffffffffc02022fc:	00005617          	auipc	a2,0x5
ffffffffc0202300:	1ec60613          	addi	a2,a2,492 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0202304:	19600593          	li	a1,406
ffffffffc0202308:	00005517          	auipc	a0,0x5
ffffffffc020230c:	1f850513          	addi	a0,a0,504 # ffffffffc0207500 <etext+0x284>
ffffffffc0202310:	ec1fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(whole == pages);
ffffffffc0202314:	00006697          	auipc	a3,0x6
ffffffffc0202318:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0207d30 <etext+0xab4>
ffffffffc020231c:	00005617          	auipc	a2,0x5
ffffffffc0202320:	1cc60613          	addi	a2,a2,460 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0202324:	18800593          	li	a1,392
ffffffffc0202328:	00005517          	auipc	a0,0x5
ffffffffc020232c:	1d850513          	addi	a0,a0,472 # ffffffffc0207500 <etext+0x284>
ffffffffc0202330:	ea1fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free == 8 && pages[0].property == 8);
ffffffffc0202334:	00006697          	auipc	a3,0x6
ffffffffc0202338:	9d468693          	addi	a3,a3,-1580 # ffffffffc0207d08 <etext+0xa8c>
ffffffffc020233c:	00005617          	auipc	a2,0x5
ffffffffc0202340:	1ac60613          	addi	a2,a2,428 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0202344:	18600593          	li	a1,390
ffffffffc0202348:	00005517          	auipc	a0,0x5
ffffffffc020234c:	1b850513          	addi	a0,a0,440 # ffffffffc0207500 <etext+0x284>
ffffffffc0202350:	e81fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free == 13);
ffffffffc0202354:	00006697          	auipc	a3,0x6
ffffffffc0202358:	9a468693          	addi	a3,a3,-1628 # ffffffffc0207cf8 <etext+0xa7c>
ffffffffc020235c:	00005617          	auipc	a2,0x5
ffffffffc0202360:	18c60613          	addi	a2,a2,396 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0202364:	17f00593          	li	a1,383
ffffffffc0202368:	00005517          	auipc	a0,0x5
ffffffffc020236c:	19850513          	addi	a0,a0,408 # ffffffffc0207500 <etext+0x284>
ffffffffc0202370:	e61fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(seen == (((uint64_t)1 << 14) - 2) && nr_free == 0);
ffffffffc0202374:	00006697          	auipc	a3,0x6
ffffffffc0202378:	94c68693          	addi	a3,a3,-1716 # ffffffffc0207cc0 <etext+0xa44>
ffffffffc020237c:	00005617          	auipc	a2,0x5
ffffffffc0202380:	16c60613          	addi	a2,a2,364 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0202384:	17900593          	li	a1,377
ffffffffc0202388:	00005517          	auipc	a0,0x5
ffffffffc020238c:	17850513          	addi	a0,a0,376 # ffffffffc0207500 <etext+0x284>
ffffffffc0202390:	e41fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(!(seen & ((uint64_t)1 << index)));
ffffffffc0202394:	00006697          	auipc	a3,0x6
ffffffffc0202398:	90468693          	addi	a3,a3,-1788 # ffffffffc0207c98 <etext+0xa1c>
ffffffffc020239c:	00005617          	auipc	a2,0x5
ffffffffc02023a0:	14c60613          	addi	a2,a2,332 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02023a4:	17500593          	li	a1,373
ffffffffc02023a8:	00005517          	auipc	a0,0x5
ffffffffc02023ac:	15850513          	addi	a0,a0,344 # ffffffffc0207500 <etext+0x284>
ffffffffc02023b0:	e21fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(index >= 1 && index < 14);
ffffffffc02023b4:	00006697          	auipc	a3,0x6
ffffffffc02023b8:	8c468693          	addi	a3,a3,-1852 # ffffffffc0207c78 <etext+0x9fc>
ffffffffc02023bc:	00005617          	auipc	a2,0x5
ffffffffc02023c0:	12c60613          	addi	a2,a2,300 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02023c4:	17400593          	li	a1,372
ffffffffc02023c8:	00005517          	auipc	a0,0x5
ffffffffc02023cc:	13850513          	addi	a0,a0,312 # ffffffffc0207500 <etext+0x284>
ffffffffc02023d0:	e01fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(buddy_test_allocation(blocks[i], 1) == 1);
ffffffffc02023d4:	00006697          	auipc	a3,0x6
ffffffffc02023d8:	87468693          	addi	a3,a3,-1932 # ffffffffc0207c48 <etext+0x9cc>
ffffffffc02023dc:	00005617          	auipc	a2,0x5
ffffffffc02023e0:	10c60613          	addi	a2,a2,268 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02023e4:	17200593          	li	a1,370
ffffffffc02023e8:	00005517          	auipc	a0,0x5
ffffffffc02023ec:	11850513          	addi	a0,a0,280 # ffffffffc0207500 <etext+0x284>
ffffffffc02023f0:	de1fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(pages[12].property == 2);
ffffffffc02023f4:	00006697          	auipc	a3,0x6
ffffffffc02023f8:	83c68693          	addi	a3,a3,-1988 # ffffffffc0207c30 <etext+0x9b4>
ffffffffc02023fc:	00005617          	auipc	a2,0x5
ffffffffc0202400:	0ec60613          	addi	a2,a2,236 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0202404:	16c00593          	li	a1,364
ffffffffc0202408:	00005517          	auipc	a0,0x5
ffffffffc020240c:	0f850513          	addi	a0,a0,248 # ffffffffc0207500 <etext+0x284>
ffffffffc0202410:	dc1fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(pages[4].property == 4 && pages[8].property == 4);
ffffffffc0202414:	00005697          	auipc	a3,0x5
ffffffffc0202418:	7e468693          	addi	a3,a3,2020 # ffffffffc0207bf8 <etext+0x97c>
ffffffffc020241c:	00005617          	auipc	a2,0x5
ffffffffc0202420:	0cc60613          	addi	a2,a2,204 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0202424:	16b00593          	li	a1,363
ffffffffc0202428:	00005517          	auipc	a0,0x5
ffffffffc020242c:	0d850513          	addi	a0,a0,216 # ffffffffc0207500 <etext+0x284>
ffffffffc0202430:	da1fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(pages[1].property == 1 && pages[2].property == 2);
ffffffffc0202434:	00005697          	auipc	a3,0x5
ffffffffc0202438:	78c68693          	addi	a3,a3,1932 # ffffffffc0207bc0 <etext+0x944>
ffffffffc020243c:	00005617          	auipc	a2,0x5
ffffffffc0202440:	0ac60613          	addi	a2,a2,172 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0202444:	16a00593          	li	a1,362
ffffffffc0202448:	00005517          	auipc	a0,0x5
ffffffffc020244c:	0b850513          	addi	a0,a0,184 # ffffffffc0207500 <etext+0x284>
ffffffffc0202450:	d81fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free == 13 && nr_managed == 13);
ffffffffc0202454:	00005697          	auipc	a3,0x5
ffffffffc0202458:	74468693          	addi	a3,a3,1860 # ffffffffc0207b98 <etext+0x91c>
ffffffffc020245c:	00005617          	auipc	a2,0x5
ffffffffc0202460:	08c60613          	addi	a2,a2,140 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0202464:	16900593          	li	a1,361
ffffffffc0202468:	00005517          	auipc	a0,0x5
ffffffffc020246c:	09850513          	addi	a0,a0,152 # ffffffffc0207500 <etext+0x284>
ffffffffc0202470:	d61fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == saved_free);
ffffffffc0202474:	00006697          	auipc	a3,0x6
ffffffffc0202478:	06468693          	addi	a3,a3,100 # ffffffffc02084d8 <etext+0x125c>
ffffffffc020247c:	00005617          	auipc	a2,0x5
ffffffffc0202480:	06c60613          	addi	a2,a2,108 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0202484:	2b200593          	li	a1,690
ffffffffc0202488:	00005517          	auipc	a0,0x5
ffffffffc020248c:	07850513          	addi	a0,a0,120 # ffffffffc0207500 <etext+0x284>
ffffffffc0202490:	d41fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(again != NULL);
ffffffffc0202494:	00006697          	auipc	a3,0x6
ffffffffc0202498:	03468693          	addi	a3,a3,52 # ffffffffc02084c8 <etext+0x124c>
ffffffffc020249c:	00005617          	auipc	a2,0x5
ffffffffc02024a0:	04c60613          	addi	a2,a2,76 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02024a4:	2b000593          	li	a1,688
ffffffffc02024a8:	00005517          	auipc	a0,0x5
ffffffffc02024ac:	05850513          	addi	a0,a0,88 # ffffffffc0207500 <etext+0x284>
ffffffffc02024b0:	d21fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == saved_free && nr_managed == saved_managed);
ffffffffc02024b4:	00006697          	auipc	a3,0x6
ffffffffc02024b8:	fd468693          	addi	a3,a3,-44 # ffffffffc0208488 <etext+0x120c>
ffffffffc02024bc:	00005617          	auipc	a2,0x5
ffffffffc02024c0:	02c60613          	addi	a2,a2,44 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02024c4:	2ad00593          	li	a1,685
ffffffffc02024c8:	00005517          	auipc	a0,0x5
ffffffffc02024cc:	03850513          	addi	a0,a0,56 # ffffffffc0207500 <etext+0x284>
ffffffffc02024d0:	d01fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before);
ffffffffc02024d4:	00006697          	auipc	a3,0x6
ffffffffc02024d8:	f5468693          	addi	a3,a3,-172 # ffffffffc0208428 <etext+0x11ac>
ffffffffc02024dc:	00005617          	auipc	a2,0x5
ffffffffc02024e0:	00c60613          	addi	a2,a2,12 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02024e4:	26c00593          	li	a1,620
ffffffffc02024e8:	00005517          	auipc	a0,0x5
ffffffffc02024ec:	01850513          	addi	a0,a0,24 # ffffffffc0207500 <etext+0x284>
ffffffffc02024f0:	ce1fd0ef          	jal	ffffffffc02001d0 <__panic>
            assert(buffers[i][byte] == (uint8_t)(i * 73 + byte));
ffffffffc02024f4:	00006697          	auipc	a3,0x6
ffffffffc02024f8:	f0468693          	addi	a3,a3,-252 # ffffffffc02083f8 <etext+0x117c>
ffffffffc02024fc:	00005617          	auipc	a2,0x5
ffffffffc0202500:	fec60613          	addi	a2,a2,-20 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0202504:	26500593          	li	a1,613
ffffffffc0202508:	00005517          	auipc	a0,0x5
ffffffffc020250c:	ff850513          	addi	a0,a0,-8 # ffffffffc0207500 <etext+0x284>
ffffffffc0202510:	cc1fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(nr_free_pages() == before - used);
ffffffffc0202514:	00006697          	auipc	a3,0x6
ffffffffc0202518:	ebc68693          	addi	a3,a3,-324 # ffffffffc02083d0 <etext+0x1154>
ffffffffc020251c:	00005617          	auipc	a2,0x5
ffffffffc0202520:	fcc60613          	addi	a2,a2,-52 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0202524:	25c00593          	li	a1,604
ffffffffc0202528:	00005517          	auipc	a0,0x5
ffffffffc020252c:	fd850513          	addi	a0,a0,-40 # ffffffffc0207500 <etext+0x284>
ffffffffc0202530:	ca1fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(pa >= KERNEL_BEGIN_PADDR && PADDR(buffers[i]) == pa);
ffffffffc0202534:	86e2                	mv	a3,s8
ffffffffc0202536:	00006617          	auipc	a2,0x6
ffffffffc020253a:	e3a60613          	addi	a2,a2,-454 # ffffffffc0208370 <etext+0x10f4>
ffffffffc020253e:	25a00593          	li	a1,602
ffffffffc0202542:	00005517          	auipc	a0,0x5
ffffffffc0202546:	fbe50513          	addi	a0,a0,-66 # ffffffffc0207500 <etext+0x284>
ffffffffc020254a:	c87fd0ef          	jal	ffffffffc02001d0 <__panic>
ffffffffc020254e:	00006697          	auipc	a3,0x6
ffffffffc0202552:	e4a68693          	addi	a3,a3,-438 # ffffffffc0208398 <etext+0x111c>
ffffffffc0202556:	00005617          	auipc	a2,0x5
ffffffffc020255a:	f9260613          	addi	a2,a2,-110 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020255e:	25a00593          	li	a1,602
ffffffffc0202562:	00005517          	auipc	a0,0x5
ffffffffc0202566:	f9e50513          	addi	a0,a0,-98 # ffffffffc0207500 <etext+0x284>
ffffffffc020256a:	c67fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(buddy_test_allocation(blocks[i], requests[i]) == lengths[i]);
ffffffffc020256e:	00006697          	auipc	a3,0x6
ffffffffc0202572:	dc268693          	addi	a3,a3,-574 # ffffffffc0208330 <etext+0x10b4>
ffffffffc0202576:	00005617          	auipc	a2,0x5
ffffffffc020257a:	f7260613          	addi	a2,a2,-142 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020257e:	25400593          	li	a1,596
ffffffffc0202582:	00005517          	auipc	a0,0x5
ffffffffc0202586:	f7e50513          	addi	a0,a0,-130 # ffffffffc0207500 <etext+0x284>
ffffffffc020258a:	c47fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(buddy_test_fingerprint() == saved_fingerprint);
ffffffffc020258e:	00006697          	auipc	a3,0x6
ffffffffc0202592:	d7268693          	addi	a3,a3,-654 # ffffffffc0208300 <etext+0x1084>
ffffffffc0202596:	00005617          	auipc	a2,0x5
ffffffffc020259a:	f5260613          	addi	a2,a2,-174 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020259e:	2aa00593          	li	a1,682
ffffffffc02025a2:	00005517          	auipc	a0,0x5
ffffffffc02025a6:	f5e50513          	addi	a0,a0,-162 # ffffffffc0207500 <etext+0x284>
ffffffffc02025aa:	c27fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free == nr_managed);
ffffffffc02025ae:	00006697          	auipc	a3,0x6
ffffffffc02025b2:	d3a68693          	addi	a3,a3,-710 # ffffffffc02082e8 <etext+0x106c>
ffffffffc02025b6:	00005617          	auipc	a2,0x5
ffffffffc02025ba:	f3260613          	addi	a2,a2,-206 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02025be:	2a100593          	li	a1,673
ffffffffc02025c2:	00005517          	auipc	a0,0x5
ffffffffc02025c6:	f3e50513          	addi	a0,a0,-194 # ffffffffc0207500 <etext+0x284>
ffffffffc02025ca:	c07fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(whole == pages && nr_free == 0);
ffffffffc02025ce:	00006697          	auipc	a3,0x6
ffffffffc02025d2:	bb268693          	addi	a3,a3,-1102 # ffffffffc0208180 <etext+0xf04>
ffffffffc02025d6:	00005617          	auipc	a2,0x5
ffffffffc02025da:	f1260613          	addi	a2,a2,-238 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02025de:	24500593          	li	a1,581
ffffffffc02025e2:	00005517          	auipc	a0,0x5
ffffffffc02025e6:	f1e50513          	addi	a0,a0,-226 # ffffffffc0207500 <etext+0x284>
ffffffffc02025ea:	be7fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free == BUDDY_TEST_PAGES);
ffffffffc02025ee:	00006697          	auipc	a3,0x6
ffffffffc02025f2:	c9a68693          	addi	a3,a3,-870 # ffffffffc0208288 <etext+0x100c>
ffffffffc02025f6:	00005617          	auipc	a2,0x5
ffffffffc02025fa:	ef260613          	addi	a2,a2,-270 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02025fe:	24300593          	li	a1,579
ffffffffc0202602:	00005517          	auipc	a0,0x5
ffffffffc0202606:	efe50513          	addi	a0,a0,-258 # ffffffffc0207500 <etext+0x284>
ffffffffc020260a:	bc7fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(nr_free == BUDDY_TEST_PAGES - used);
ffffffffc020260e:	00005697          	auipc	a3,0x5
ffffffffc0202612:	7c268693          	addi	a3,a3,1986 # ffffffffc0207dd0 <etext+0xb54>
ffffffffc0202616:	00005617          	auipc	a2,0x5
ffffffffc020261a:	ed260613          	addi	a2,a2,-302 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020261e:	23a00593          	li	a1,570
ffffffffc0202622:	00005517          	auipc	a0,0x5
ffffffffc0202626:	ede50513          	addi	a0,a0,-290 # ffffffffc0207500 <etext+0x284>
ffffffffc020262a:	ba7fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free == 16);
ffffffffc020262e:	00006697          	auipc	a3,0x6
ffffffffc0202632:	c1268693          	addi	a3,a3,-1006 # ffffffffc0208240 <etext+0xfc4>
ffffffffc0202636:	00005617          	auipc	a2,0x5
ffffffffc020263a:	eb260613          	addi	a2,a2,-334 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020263e:	21200593          	li	a1,530
ffffffffc0202642:	00005517          	auipc	a0,0x5
ffffffffc0202646:	ebe50513          	addi	a0,a0,-322 # ffffffffc0207500 <etext+0x284>
ffffffffc020264a:	b87fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(p->property == 3 && (p->flags & BUDDY_ALLOC_HEAD));
ffffffffc020264e:	00006697          	auipc	a3,0x6
ffffffffc0202652:	bba68693          	addi	a3,a3,-1094 # ffffffffc0208208 <etext+0xf8c>
ffffffffc0202656:	00005617          	auipc	a2,0x5
ffffffffc020265a:	e9260613          	addi	a2,a2,-366 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020265e:	21000593          	li	a1,528
ffffffffc0202662:	00005517          	auipc	a0,0x5
ffffffffc0202666:	e9e50513          	addi	a0,a0,-354 # ffffffffc0207500 <etext+0x284>
ffffffffc020266a:	b67fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(buddy_test_allocation(p, 3) == 4);
ffffffffc020266e:	00006697          	auipc	a3,0x6
ffffffffc0202672:	b7268693          	addi	a3,a3,-1166 # ffffffffc02081e0 <etext+0xf64>
ffffffffc0202676:	00005617          	auipc	a2,0x5
ffffffffc020267a:	e7260613          	addi	a2,a2,-398 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020267e:	20c00593          	li	a1,524
ffffffffc0202682:	00005517          	auipc	a0,0x5
ffffffffc0202686:	e7e50513          	addi	a0,a0,-386 # ffffffffc0207500 <etext+0x284>
ffffffffc020268a:	b47fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(whole == pages && nr_free == 0);
ffffffffc020268e:	00006697          	auipc	a3,0x6
ffffffffc0202692:	af268693          	addi	a3,a3,-1294 # ffffffffc0208180 <etext+0xf04>
ffffffffc0202696:	00005617          	auipc	a2,0x5
ffffffffc020269a:	e5260613          	addi	a2,a2,-430 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020269e:	20000593          	li	a1,512
ffffffffc02026a2:	00005517          	auipc	a0,0x5
ffffffffc02026a6:	e5e50513          	addi	a0,a0,-418 # ffffffffc0207500 <etext+0x284>
ffffffffc02026aa:	b27fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free == 8 && pages[0].property == 8);
ffffffffc02026ae:	00005697          	auipc	a3,0x5
ffffffffc02026b2:	65a68693          	addi	a3,a3,1626 # ffffffffc0207d08 <etext+0xa8c>
ffffffffc02026b6:	00005617          	auipc	a2,0x5
ffffffffc02026ba:	e3260613          	addi	a2,a2,-462 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02026be:	1fe00593          	li	a1,510
ffffffffc02026c2:	00005517          	auipc	a0,0x5
ffffffffc02026c6:	e3e50513          	addi	a0,a0,-450 # ffffffffc0207500 <etext+0x284>
ffffffffc02026ca:	b07fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(pages[0].property == 4 && nr_free == 4);
ffffffffc02026ce:	00006697          	auipc	a3,0x6
ffffffffc02026d2:	a8a68693          	addi	a3,a3,-1398 # ffffffffc0208158 <etext+0xedc>
ffffffffc02026d6:	00005617          	auipc	a2,0x5
ffffffffc02026da:	e1260613          	addi	a2,a2,-494 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02026de:	1f700593          	li	a1,503
ffffffffc02026e2:	00005517          	auipc	a0,0x5
ffffffffc02026e6:	e1e50513          	addi	a0,a0,-482 # ffffffffc0207500 <etext+0x284>
ffffffffc02026ea:	ae7fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(pair == pages && nr_free == 1);
ffffffffc02026ee:	00006697          	auipc	a3,0x6
ffffffffc02026f2:	a4a68693          	addi	a3,a3,-1462 # ffffffffc0208138 <etext+0xebc>
ffffffffc02026f6:	00005617          	auipc	a2,0x5
ffffffffc02026fa:	df260613          	addi	a2,a2,-526 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02026fe:	1f400593          	li	a1,500
ffffffffc0202702:	00005517          	auipc	a0,0x5
ffffffffc0202706:	dfe50513          	addi	a0,a0,-514 # ffffffffc0207500 <etext+0x284>
ffffffffc020270a:	ac7fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(pages[0].property == 2);
ffffffffc020270e:	00006697          	auipc	a3,0x6
ffffffffc0202712:	a1268693          	addi	a3,a3,-1518 # ffffffffc0208120 <etext+0xea4>
ffffffffc0202716:	00005617          	auipc	a2,0x5
ffffffffc020271a:	dd260613          	addi	a2,a2,-558 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020271e:	1f200593          	li	a1,498
ffffffffc0202722:	00005517          	auipc	a0,0x5
ffffffffc0202726:	dde50513          	addi	a0,a0,-546 # ffffffffc0207500 <etext+0x284>
ffffffffc020272a:	aa7fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free == 2 && pages[1].property == 1 && pages[2].property == 1);
ffffffffc020272e:	00006697          	auipc	a3,0x6
ffffffffc0202732:	9aa68693          	addi	a3,a3,-1622 # ffffffffc02080d8 <etext+0xe5c>
ffffffffc0202736:	00005617          	auipc	a2,0x5
ffffffffc020273a:	db260613          	addi	a2,a2,-590 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020273e:	1ee00593          	li	a1,494
ffffffffc0202742:	00005517          	auipc	a0,0x5
ffffffffc0202746:	dbe50513          	addi	a0,a0,-578 # ffffffffc0207500 <etext+0x284>
ffffffffc020274a:	a87fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(seen == 0xff);
ffffffffc020274e:	00006697          	auipc	a3,0x6
ffffffffc0202752:	97a68693          	addi	a3,a3,-1670 # ffffffffc02080c8 <etext+0xe4c>
ffffffffc0202756:	00005617          	auipc	a2,0x5
ffffffffc020275a:	d9260613          	addi	a2,a2,-622 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020275e:	1ea00593          	li	a1,490
ffffffffc0202762:	00005517          	auipc	a0,0x5
ffffffffc0202766:	d9e50513          	addi	a0,a0,-610 # ffffffffc0207500 <etext+0x284>
ffffffffc020276a:	a67fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(index < 8 && !(seen & (1U << index)));
ffffffffc020276e:	00006697          	auipc	a3,0x6
ffffffffc0202772:	93268693          	addi	a3,a3,-1742 # ffffffffc02080a0 <etext+0xe24>
ffffffffc0202776:	00005617          	auipc	a2,0x5
ffffffffc020277a:	d7260613          	addi	a2,a2,-654 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020277e:	1e600593          	li	a1,486
ffffffffc0202782:	00005517          	auipc	a0,0x5
ffffffffc0202786:	d7e50513          	addi	a0,a0,-642 # ffffffffc0207500 <etext+0x284>
ffffffffc020278a:	a47fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free == 16 && pages[0].property == 16);
ffffffffc020278e:	00005697          	auipc	a3,0x5
ffffffffc0202792:	75a68693          	addi	a3,a3,1882 # ffffffffc0207ee8 <etext+0xc6c>
ffffffffc0202796:	00005617          	auipc	a2,0x5
ffffffffc020279a:	d5260613          	addi	a2,a2,-686 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020279e:	1d800593          	li	a1,472
ffffffffc02027a2:	00005517          	auipc	a0,0x5
ffffffffc02027a6:	d5e50513          	addi	a0,a0,-674 # ffffffffc0207500 <etext+0x284>
ffffffffc02027aa:	a27fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(seen == 0xffff && nr_free == 0);
ffffffffc02027ae:	00006697          	auipc	a3,0x6
ffffffffc02027b2:	89268693          	addi	a3,a3,-1902 # ffffffffc0208040 <etext+0xdc4>
ffffffffc02027b6:	00005617          	auipc	a2,0x5
ffffffffc02027ba:	d3260613          	addi	a2,a2,-718 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02027be:	1d200593          	li	a1,466
ffffffffc02027c2:	00005517          	auipc	a0,0x5
ffffffffc02027c6:	d3e50513          	addi	a0,a0,-706 # ffffffffc0207500 <etext+0x284>
ffffffffc02027ca:	a07fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(index < 16 && !(seen & ((uint64_t)1 << index)));
ffffffffc02027ce:	00006697          	auipc	a3,0x6
ffffffffc02027d2:	84268693          	addi	a3,a3,-1982 # ffffffffc0208010 <etext+0xd94>
ffffffffc02027d6:	00005617          	auipc	a2,0x5
ffffffffc02027da:	d1260613          	addi	a2,a2,-750 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02027de:	1ce00593          	li	a1,462
ffffffffc02027e2:	00005517          	auipc	a0,0x5
ffffffffc02027e6:	d1e50513          	addi	a0,a0,-738 # ffffffffc0207500 <etext+0x284>
ffffffffc02027ea:	9e7fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(list_next(&tail->page_link) == &free_lists[k]);
ffffffffc02027ee:	00005697          	auipc	a3,0x5
ffffffffc02027f2:	7f268693          	addi	a3,a3,2034 # ffffffffc0207fe0 <etext+0xd64>
ffffffffc02027f6:	00005617          	auipc	a2,0x5
ffffffffc02027fa:	cf260613          	addi	a2,a2,-782 # ffffffffc02074e8 <etext+0x26c>
ffffffffc02027fe:	1c600593          	li	a1,454
ffffffffc0202802:	00005517          	auipc	a0,0x5
ffffffffc0202806:	cfe50513          	addi	a0,a0,-770 # ffffffffc0207500 <etext+0x284>
ffffffffc020280a:	9c7fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(list_next(&free_lists[k]) == &tail->page_link);
ffffffffc020280e:	00005697          	auipc	a3,0x5
ffffffffc0202812:	7a268693          	addi	a3,a3,1954 # ffffffffc0207fb0 <etext+0xd34>
ffffffffc0202816:	00005617          	auipc	a2,0x5
ffffffffc020281a:	cd260613          	addi	a2,a2,-814 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020281e:	1c500593          	li	a1,453
ffffffffc0202822:	00005517          	auipc	a0,0x5
ffffffffc0202826:	cde50513          	addi	a0,a0,-802 # ffffffffc0207500 <etext+0x284>
ffffffffc020282a:	9a7fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(PageProperty(tail) && tail->property == buddy_block_size(k));
ffffffffc020282e:	00005697          	auipc	a3,0x5
ffffffffc0202832:	74268693          	addi	a3,a3,1858 # ffffffffc0207f70 <etext+0xcf4>
ffffffffc0202836:	00005617          	auipc	a2,0x5
ffffffffc020283a:	cb260613          	addi	a2,a2,-846 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020283e:	1c400593          	li	a1,452
ffffffffc0202842:	00005517          	auipc	a0,0x5
ffffffffc0202846:	cbe50513          	addi	a0,a0,-834 # ffffffffc0207500 <etext+0x284>
ffffffffc020284a:	987fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(blocks[0] == pages);
ffffffffc020284e:	00005697          	auipc	a3,0x5
ffffffffc0202852:	70a68693          	addi	a3,a3,1802 # ffffffffc0207f58 <etext+0xcdc>
ffffffffc0202856:	00005617          	auipc	a2,0x5
ffffffffc020285a:	c9260613          	addi	a2,a2,-878 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020285e:	1c000593          	li	a1,448
ffffffffc0202862:	00005517          	auipc	a0,0x5
ffffffffc0202866:	c9e50513          	addi	a0,a0,-866 # ffffffffc0207500 <etext+0x284>
ffffffffc020286a:	967fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free == 16 && pages[0].property == 16);
ffffffffc020286e:	00005697          	auipc	a3,0x5
ffffffffc0202872:	67a68693          	addi	a3,a3,1658 # ffffffffc0207ee8 <etext+0xc6c>
ffffffffc0202876:	00005617          	auipc	a2,0x5
ffffffffc020287a:	c7260613          	addi	a2,a2,-910 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020287e:	1b500593          	li	a1,437
ffffffffc0202882:	00005517          	auipc	a0,0x5
ffffffffc0202886:	c7e50513          	addi	a0,a0,-898 # ffffffffc0207500 <etext+0x284>
ffffffffc020288a:	947fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free == 8);
ffffffffc020288e:	00005697          	auipc	a3,0x5
ffffffffc0202892:	64a68693          	addi	a3,a3,1610 # ffffffffc0207ed8 <etext+0xc5c>
ffffffffc0202896:	00005617          	auipc	a2,0x5
ffffffffc020289a:	c5260613          	addi	a2,a2,-942 # ffffffffc02074e8 <etext+0x26c>
ffffffffc020289e:	1b300593          	li	a1,435
ffffffffc02028a2:	00005517          	auipc	a0,0x5
ffffffffc02028a6:	c5e50513          	addi	a0,a0,-930 # ffffffffc0207500 <etext+0x284>
ffffffffc02028aa:	927fd0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc02028ae <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc02028ae:	00025797          	auipc	a5,0x25
ffffffffc02028b2:	f1a7b783          	ld	a5,-230(a5) # ffffffffc02277c8 <pmm_manager>
ffffffffc02028b6:	6f9c                	ld	a5,24(a5)
ffffffffc02028b8:	8782                	jr	a5

ffffffffc02028ba <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc02028ba:	00025797          	auipc	a5,0x25
ffffffffc02028be:	f0e7b783          	ld	a5,-242(a5) # ffffffffc02277c8 <pmm_manager>
ffffffffc02028c2:	739c                	ld	a5,32(a5)
ffffffffc02028c4:	8782                	jr	a5

ffffffffc02028c6 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc02028c6:	00025797          	auipc	a5,0x25
ffffffffc02028ca:	f027b783          	ld	a5,-254(a5) # ffffffffc02277c8 <pmm_manager>
ffffffffc02028ce:	779c                	ld	a5,40(a5)
ffffffffc02028d0:	8782                	jr	a5

ffffffffc02028d2 <pmm_init>:
    pmm_manager = &buddy_pmm_manager;
ffffffffc02028d2:	00007797          	auipc	a5,0x7
ffffffffc02028d6:	1f678793          	addi	a5,a5,502 # ffffffffc0209ac8 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02028da:	638c                	ld	a1,0(a5)
            (unsigned long)freemem_pa, (unsigned long)mem_end,
            (unsigned long)nr_free_pages());
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02028dc:	7139                	addi	sp,sp,-64
ffffffffc02028de:	fc06                	sd	ra,56(sp)
ffffffffc02028e0:	f822                	sd	s0,48(sp)
ffffffffc02028e2:	f426                	sd	s1,40(sp)
ffffffffc02028e4:	f04a                	sd	s2,32(sp)
ffffffffc02028e6:	ec4e                	sd	s3,24(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc02028e8:	00025497          	auipc	s1,0x25
ffffffffc02028ec:	ee048493          	addi	s1,s1,-288 # ffffffffc02277c8 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02028f0:	00006517          	auipc	a0,0x6
ffffffffc02028f4:	c6050513          	addi	a0,a0,-928 # ffffffffc0208550 <etext+0x12d4>
    pmm_manager = &buddy_pmm_manager;
ffffffffc02028f8:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02028fa:	857fd0ef          	jal	ffffffffc0200150 <cprintf>
    pmm_manager->init();
ffffffffc02028fe:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202900:	00025917          	auipc	s2,0x25
ffffffffc0202904:	ee090913          	addi	s2,s2,-288 # ffffffffc02277e0 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202908:	679c                	ld	a5,8(a5)
ffffffffc020290a:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020290c:	57f5                	li	a5,-3
ffffffffc020290e:	07fa                	slli	a5,a5,0x1e
ffffffffc0202910:	00f93023          	sd	a5,0(s2)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202914:	c4ffd0ef          	jal	ffffffffc0200562 <get_memory_base>
ffffffffc0202918:	842a                	mv	s0,a0
    uint64_t mem_size = get_memory_size();
ffffffffc020291a:	c53fd0ef          	jal	ffffffffc020056c <get_memory_size>
    if (__builtin_add_overflow(mem_begin, mem_size, &mem_end)) {
ffffffffc020291e:	00a40733          	add	a4,s0,a0
ffffffffc0202922:	22876c63          	bltu	a4,s0,ffffffffc0202b5a <pmm_init+0x288>
    npage = PPN(mem_end);
ffffffffc0202926:	00c75593          	srli	a1,a4,0xc
ffffffffc020292a:	00025797          	auipc	a5,0x25
ffffffffc020292e:	eab7bf23          	sd	a1,-322(a5) # ffffffffc02277e8 <npage>
    if (npage <= nbase) {
ffffffffc0202932:	000808b7          	lui	a7,0x80
ffffffffc0202936:	20b8f463          	bgeu	a7,a1,ffffffffc0202b3e <pmm_init+0x26c>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020293a:	76fd                	lui	a3,0xfffff
ffffffffc020293c:	00026817          	auipc	a6,0x26
ffffffffc0202940:	f3b80813          	addi	a6,a6,-197 # ffffffffc0228877 <end+0xfff>
ffffffffc0202944:	00259613          	slli	a2,a1,0x2
ffffffffc0202948:	00d87833          	and	a6,a6,a3
ffffffffc020294c:	962e                	add	a2,a2,a1
ffffffffc020294e:	fec006b7          	lui	a3,0xfec00
ffffffffc0202952:	96c2                	add	a3,a3,a6
ffffffffc0202954:	060e                	slli	a2,a2,0x3
ffffffffc0202956:	00025797          	auipc	a5,0x25
ffffffffc020295a:	e907bd23          	sd	a6,-358(a5) # ffffffffc02277f0 <pages>
ffffffffc020295e:	9636                	add	a2,a2,a3
    size_t n = npage - nbase;
ffffffffc0202960:	411588b3          	sub	a7,a1,a7
ffffffffc0202964:	87c2                	mv	a5,a6
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202966:	00025517          	auipc	a0,0x25
ffffffffc020296a:	f1250513          	addi	a0,a0,-238 # ffffffffc0227878 <end>
        pages[i].flags = (1UL << PG_reserved);
ffffffffc020296e:	4685                	li	a3,1
ffffffffc0202970:	e794                	sd	a3,8(a5)
        pages[i].property = 0;
ffffffffc0202972:	0007a823          	sw	zero,16(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0202976:	0007a023          	sw	zero,0(a5)
    for (size_t i = 0; i < n; i ++) {
ffffffffc020297a:	02878793          	addi	a5,a5,40
ffffffffc020297e:	fef619e3          	bne	a2,a5,ffffffffc0202970 <pmm_init+0x9e>
    size_t pages_bytes = n * sizeof(struct Page);
ffffffffc0202982:	00289793          	slli	a5,a7,0x2
ffffffffc0202986:	97c6                	add	a5,a5,a7
ffffffffc0202988:	078e                	slli	a5,a5,0x3
    if (pages_va > (uintptr_t)-1 - pages_bytes) {
ffffffffc020298a:	010786b3          	add	a3,a5,a6
ffffffffc020298e:	22f6ea63          	bltu	a3,a5,ffffffffc0202bc2 <pmm_init+0x2f0>
    uintptr_t freemem_va = ROUNDUP(array_end_va, PGSIZE);
ffffffffc0202992:	6885                	lui	a7,0x1
ffffffffc0202994:	fff88e13          	addi	t3,a7,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0202998:	01c687b3          	add	a5,a3,t3
ffffffffc020299c:	737d                	lui	t1,0xfffff
ffffffffc020299e:	0067f7b3          	and	a5,a5,t1
    if (freemem_va < array_end_va) {
ffffffffc02029a2:	20d7e463          	bltu	a5,a3,ffffffffc0202baa <pmm_init+0x2d8>
    uintptr_t freemem_pa = PADDR(freemem_va);
ffffffffc02029a6:	c02006b7          	lui	a3,0xc0200
ffffffffc02029aa:	1ed7e363          	bltu	a5,a3,ffffffffc0202b90 <pmm_init+0x2be>
    uintptr_t bootstack_end_pa = PADDR((uintptr_t)bootstacktop);
ffffffffc02029ae:	00009617          	auipc	a2,0x9
ffffffffc02029b2:	65260613          	addi	a2,a2,1618 # ffffffffc020c000 <boot_page_table_sv39>
ffffffffc02029b6:	1cd66063          	bltu	a2,a3,ffffffffc0202b76 <pmm_init+0x2a4>
    uintptr_t pt_end_pa = PADDR((uintptr_t)boot_page_table_sv39) + PGSIZE;
ffffffffc02029ba:	00009997          	auipc	s3,0x9
ffffffffc02029be:	64698993          	addi	s3,s3,1606 # ffffffffc020c000 <boot_page_table_sv39>
ffffffffc02029c2:	16d9e163          	bltu	s3,a3,ffffffffc0202b24 <pmm_init+0x252>
    uintptr_t kern_end_pa = PADDR((uintptr_t)end);
ffffffffc02029c6:	12d56f63          	bltu	a0,a3,ffffffffc0202b04 <pmm_init+0x232>
    uintptr_t freemem_pa = PADDR(freemem_va);
ffffffffc02029ca:	00093683          	ld	a3,0(s2)
    uintptr_t bootstack_end_pa = PADDR((uintptr_t)bootstacktop);
ffffffffc02029ce:	00009617          	auipc	a2,0x9
ffffffffc02029d2:	63260613          	addi	a2,a2,1586 # ffffffffc020c000 <boot_page_table_sv39>
    uintptr_t freemem_pa = PADDR(freemem_va);
ffffffffc02029d6:	8f95                	sub	a5,a5,a3
    uintptr_t bootstack_end_pa = PADDR((uintptr_t)bootstacktop);
ffffffffc02029d8:	8e15                	sub	a2,a2,a3
    uintptr_t kern_end_pa = PADDR((uintptr_t)end);
ffffffffc02029da:	8d15                	sub	a0,a0,a3
    uintptr_t pt_end_pa = PADDR((uintptr_t)boot_page_table_sv39) + PGSIZE;
ffffffffc02029dc:	40d986b3          	sub	a3,s3,a3
ffffffffc02029e0:	98b6                	add	a7,a7,a3
    if (bootstack_end_pa > freemem_pa) {
ffffffffc02029e2:	00c7f563          	bgeu	a5,a2,ffffffffc02029ec <pmm_init+0x11a>
        freemem_pa = ROUNDUP(bootstack_end_pa, PGSIZE);
ffffffffc02029e6:	9672                	add	a2,a2,t3
ffffffffc02029e8:	006677b3          	and	a5,a2,t1
    if (pt_end_pa > freemem_pa) {
ffffffffc02029ec:	0117f763          	bgeu	a5,a7,ffffffffc02029fa <pmm_init+0x128>
        freemem_pa = ROUNDUP(pt_end_pa, PGSIZE);
ffffffffc02029f0:	6789                	lui	a5,0x2
ffffffffc02029f2:	17fd                	addi	a5,a5,-1 # 1fff <kern_entry-0xffffffffc01fe001>
ffffffffc02029f4:	96be                	add	a3,a3,a5
ffffffffc02029f6:	77fd                	lui	a5,0xfffff
ffffffffc02029f8:	8ff5                	and	a5,a5,a3
    if (kern_end_pa > freemem_pa) {
ffffffffc02029fa:	00a7f763          	bgeu	a5,a0,ffffffffc0202a08 <pmm_init+0x136>
        freemem_pa = ROUNDUP(kern_end_pa, PGSIZE);
ffffffffc02029fe:	6785                	lui	a5,0x1
ffffffffc0202a00:	17fd                	addi	a5,a5,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0202a02:	953e                	add	a0,a0,a5
ffffffffc0202a04:	77fd                	lui	a5,0xfffff
ffffffffc0202a06:	8fe9                	and	a5,a5,a0
    uintptr_t mem_begin_aligned = (uintptr_t)ROUNDUP(mem_begin, PGSIZE);
ffffffffc0202a08:	6685                	lui	a3,0x1
ffffffffc0202a0a:	16fd                	addi	a3,a3,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0202a0c:	96a2                	add	a3,a3,s0
    if (freemem_pa < mem_begin_aligned) {
ffffffffc0202a0e:	767d                	lui	a2,0xfffff
ffffffffc0202a10:	00c6f433          	and	s0,a3,a2
ffffffffc0202a14:	08f46363          	bltu	s0,a5,ffffffffc0202a9a <pmm_init+0x1c8>
    if (freemem_pa < DRAM_BASE) {
ffffffffc0202a18:	800007b7          	lui	a5,0x80000
ffffffffc0202a1c:	fff7c793          	not	a5,a5
ffffffffc0202a20:	0c87f563          	bgeu	a5,s0,ffffffffc0202aea <pmm_init+0x218>
    uint64_t mem_end_aligned = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202a24:	77fd                	lui	a5,0xfffff
ffffffffc0202a26:	8ff9                	and	a5,a5,a4
    if (freemem_pa < mem_end_aligned) {
ffffffffc0202a28:	06f46b63          	bltu	s0,a5,ffffffffc0202a9e <pmm_init+0x1cc>
    return pmm_manager->nr_free_pages();
ffffffffc0202a2c:	609c                	ld	a5,0(s1)
ffffffffc0202a2e:	e43a                	sd	a4,8(sp)
ffffffffc0202a30:	e02e                	sd	a1,0(sp)
ffffffffc0202a32:	779c                	ld	a5,40(a5)
ffffffffc0202a34:	9782                	jalr	a5
    cprintf("page_init: npage=%lu nbase=%lu freemem=%lx mem_end=%lx nr_free=%lu\n",
ffffffffc0202a36:	6722                	ld	a4,8(sp)
ffffffffc0202a38:	6582                	ld	a1,0(sp)
ffffffffc0202a3a:	86a2                	mv	a3,s0
ffffffffc0202a3c:	00080637          	lui	a2,0x80
    return pmm_manager->nr_free_pages();
ffffffffc0202a40:	87aa                	mv	a5,a0
    cprintf("page_init: npage=%lu nbase=%lu freemem=%lx mem_end=%lx nr_free=%lu\n",
ffffffffc0202a42:	00006517          	auipc	a0,0x6
ffffffffc0202a46:	c0650513          	addi	a0,a0,-1018 # ffffffffc0208648 <etext+0x13cc>
ffffffffc0202a4a:	f06fd0ef          	jal	ffffffffc0200150 <cprintf>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0202a4e:	609c                	ld	a5,0(s1)
ffffffffc0202a50:	7b9c                	ld	a5,48(a5)
ffffffffc0202a52:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202a54:	00006517          	auipc	a0,0x6
ffffffffc0202a58:	c3c50513          	addi	a0,a0,-964 # ffffffffc0208690 <etext+0x1414>
ffffffffc0202a5c:	ef4fd0ef          	jal	ffffffffc0200150 <cprintf>
    satp_physical = PADDR(satp_virtual);
ffffffffc0202a60:	00093783          	ld	a5,0(s2)
}
ffffffffc0202a64:	7442                	ld	s0,48(sp)
ffffffffc0202a66:	70e2                	ld	ra,56(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0202a68:	40f987b3          	sub	a5,s3,a5
}
ffffffffc0202a6c:	74a2                	ld	s1,40(sp)
ffffffffc0202a6e:	7902                	ld	s2,32(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0202a70:	00025717          	auipc	a4,0x25
ffffffffc0202a74:	d6f73023          	sd	a5,-672(a4) # ffffffffc02277d0 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0202a78:	863e                	mv	a2,a5
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0202a7a:	00025797          	auipc	a5,0x25
ffffffffc0202a7e:	d537bf23          	sd	s3,-674(a5) # ffffffffc02277d8 <satp_virtual>
}
ffffffffc0202a82:	69e2                	ld	s3,24(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0202a84:	00009597          	auipc	a1,0x9
ffffffffc0202a88:	57c58593          	addi	a1,a1,1404 # ffffffffc020c000 <boot_page_table_sv39>
ffffffffc0202a8c:	00006517          	auipc	a0,0x6
ffffffffc0202a90:	c2450513          	addi	a0,a0,-988 # ffffffffc02086b0 <etext+0x1434>
}
ffffffffc0202a94:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0202a96:	ebafd06f          	j	ffffffffc0200150 <cprintf>
    if (freemem_pa < mem_begin_aligned) {
ffffffffc0202a9a:	843e                	mv	s0,a5
ffffffffc0202a9c:	bfb5                	j	ffffffffc0202a18 <pmm_init+0x146>
    if (PPN(pa) >= npage) {
ffffffffc0202a9e:	00c45613          	srli	a2,s0,0xc
ffffffffc0202aa2:	02b67863          	bgeu	a2,a1,ffffffffc0202ad2 <pmm_init+0x200>
        size_t free_n = (size_t)((mem_end_aligned - freemem_pa) >> PGSHIFT);
ffffffffc0202aa6:	8f81                	sub	a5,a5,s0
ffffffffc0202aa8:	83b1                	srli	a5,a5,0xc
        if (free_n > 0) {
ffffffffc0202aaa:	d3c9                	beqz	a5,ffffffffc0202a2c <pmm_init+0x15a>
    pmm_manager->init_memmap(base, n);
ffffffffc0202aac:	608c                	ld	a1,0(s1)
    return &pages[PPN(pa) - nbase];
ffffffffc0202aae:	fff80537          	lui	a0,0xfff80
ffffffffc0202ab2:	962a                	add	a2,a2,a0
ffffffffc0202ab4:	00261513          	slli	a0,a2,0x2
ffffffffc0202ab8:	9532                	add	a0,a0,a2
ffffffffc0202aba:	6990                	ld	a2,16(a1)
ffffffffc0202abc:	050e                	slli	a0,a0,0x3
ffffffffc0202abe:	85be                	mv	a1,a5
ffffffffc0202ac0:	9542                	add	a0,a0,a6
ffffffffc0202ac2:	e03a                	sd	a4,0(sp)
ffffffffc0202ac4:	9602                	jalr	a2
    cprintf("page_init: npage=%lu nbase=%lu freemem=%lx mem_end=%lx nr_free=%lu\n",
ffffffffc0202ac6:	00025597          	auipc	a1,0x25
ffffffffc0202aca:	d225b583          	ld	a1,-734(a1) # ffffffffc02277e8 <npage>
ffffffffc0202ace:	6702                	ld	a4,0(sp)
}
ffffffffc0202ad0:	bfb1                	j	ffffffffc0202a2c <pmm_init+0x15a>
        panic("pa2page called with invalid pa");
ffffffffc0202ad2:	00005617          	auipc	a2,0x5
ffffffffc0202ad6:	bee60613          	addi	a2,a2,-1042 # ffffffffc02076c0 <etext+0x444>
ffffffffc0202ada:	06a00593          	li	a1,106
ffffffffc0202ade:	00005517          	auipc	a0,0x5
ffffffffc0202ae2:	c0250513          	addi	a0,a0,-1022 # ffffffffc02076e0 <etext+0x464>
ffffffffc0202ae6:	eeafd0ef          	jal	ffffffffc02001d0 <__panic>
        panic("page_init: freemem %lx below DRAM_BASE\n", (unsigned long)freemem_pa);
ffffffffc0202aea:	86a2                	mv	a3,s0
ffffffffc0202aec:	00006617          	auipc	a2,0x6
ffffffffc0202af0:	b3460613          	addi	a2,a2,-1228 # ffffffffc0208620 <etext+0x13a4>
ffffffffc0202af4:	09f00593          	li	a1,159
ffffffffc0202af8:	00006517          	auipc	a0,0x6
ffffffffc0202afc:	aa850513          	addi	a0,a0,-1368 # ffffffffc02085a0 <etext+0x1324>
ffffffffc0202b00:	ed0fd0ef          	jal	ffffffffc02001d0 <__panic>
    uintptr_t kern_end_pa = PADDR((uintptr_t)end);
ffffffffc0202b04:	00025697          	auipc	a3,0x25
ffffffffc0202b08:	d7468693          	addi	a3,a3,-652 # ffffffffc0227878 <end>
ffffffffc0202b0c:	00006617          	auipc	a2,0x6
ffffffffc0202b10:	86460613          	addi	a2,a2,-1948 # ffffffffc0208370 <etext+0x10f4>
ffffffffc0202b14:	08a00593          	li	a1,138
ffffffffc0202b18:	00006517          	auipc	a0,0x6
ffffffffc0202b1c:	a8850513          	addi	a0,a0,-1400 # ffffffffc02085a0 <etext+0x1324>
ffffffffc0202b20:	eb0fd0ef          	jal	ffffffffc02001d0 <__panic>
    uintptr_t pt_end_pa = PADDR((uintptr_t)boot_page_table_sv39) + PGSIZE;
ffffffffc0202b24:	86ce                	mv	a3,s3
ffffffffc0202b26:	00006617          	auipc	a2,0x6
ffffffffc0202b2a:	84a60613          	addi	a2,a2,-1974 # ffffffffc0208370 <etext+0x10f4>
ffffffffc0202b2e:	08900593          	li	a1,137
ffffffffc0202b32:	00006517          	auipc	a0,0x6
ffffffffc0202b36:	a6e50513          	addi	a0,a0,-1426 # ffffffffc02085a0 <etext+0x1324>
ffffffffc0202b3a:	e96fd0ef          	jal	ffffffffc02001d0 <__panic>
        panic("page_init: npage %lu <= nbase %lu\n", (unsigned long)npage, (unsigned long)nbase);
ffffffffc0202b3e:	86ae                	mv	a3,a1
ffffffffc0202b40:	8746                	mv	a4,a7
ffffffffc0202b42:	00006617          	auipc	a2,0x6
ffffffffc0202b46:	a6e60613          	addi	a2,a2,-1426 # ffffffffc02085b0 <etext+0x1334>
ffffffffc0202b4a:	05b00593          	li	a1,91
ffffffffc0202b4e:	00006517          	auipc	a0,0x6
ffffffffc0202b52:	a5250513          	addi	a0,a0,-1454 # ffffffffc02085a0 <etext+0x1324>
ffffffffc0202b56:	e7afd0ef          	jal	ffffffffc02001d0 <__panic>
        panic("page_init: memory range overflow (base %lx size %lx)\n", mem_begin, mem_size);
ffffffffc0202b5a:	872a                	mv	a4,a0
ffffffffc0202b5c:	86a2                	mv	a3,s0
ffffffffc0202b5e:	00006617          	auipc	a2,0x6
ffffffffc0202b62:	a0a60613          	addi	a2,a2,-1526 # ffffffffc0208568 <etext+0x12ec>
ffffffffc0202b66:	05400593          	li	a1,84
ffffffffc0202b6a:	00006517          	auipc	a0,0x6
ffffffffc0202b6e:	a3650513          	addi	a0,a0,-1482 # ffffffffc02085a0 <etext+0x1324>
ffffffffc0202b72:	e5efd0ef          	jal	ffffffffc02001d0 <__panic>
    uintptr_t bootstack_end_pa = PADDR((uintptr_t)bootstacktop);
ffffffffc0202b76:	86b2                	mv	a3,a2
ffffffffc0202b78:	08800593          	li	a1,136
ffffffffc0202b7c:	00005617          	auipc	a2,0x5
ffffffffc0202b80:	7f460613          	addi	a2,a2,2036 # ffffffffc0208370 <etext+0x10f4>
ffffffffc0202b84:	00006517          	auipc	a0,0x6
ffffffffc0202b88:	a1c50513          	addi	a0,a0,-1508 # ffffffffc02085a0 <etext+0x1324>
ffffffffc0202b8c:	e44fd0ef          	jal	ffffffffc02001d0 <__panic>
    uintptr_t freemem_pa = PADDR(freemem_va);
ffffffffc0202b90:	86be                	mv	a3,a5
ffffffffc0202b92:	00005617          	auipc	a2,0x5
ffffffffc0202b96:	7de60613          	addi	a2,a2,2014 # ffffffffc0208370 <etext+0x10f4>
ffffffffc0202b9a:	08100593          	li	a1,129
ffffffffc0202b9e:	00006517          	auipc	a0,0x6
ffffffffc0202ba2:	a0250513          	addi	a0,a0,-1534 # ffffffffc02085a0 <etext+0x1324>
ffffffffc0202ba6:	e2afd0ef          	jal	ffffffffc02001d0 <__panic>
        panic("page_init: freemem_va overflow\n");
ffffffffc0202baa:	00006617          	auipc	a2,0x6
ffffffffc0202bae:	a5660613          	addi	a2,a2,-1450 # ffffffffc0208600 <etext+0x1384>
ffffffffc0202bb2:	07d00593          	li	a1,125
ffffffffc0202bb6:	00006517          	auipc	a0,0x6
ffffffffc0202bba:	9ea50513          	addi	a0,a0,-1558 # ffffffffc02085a0 <etext+0x1324>
ffffffffc0202bbe:	e12fd0ef          	jal	ffffffffc02001d0 <__panic>
        panic("page_init: Page array end overflow\n");
ffffffffc0202bc2:	00006617          	auipc	a2,0x6
ffffffffc0202bc6:	a1660613          	addi	a2,a2,-1514 # ffffffffc02085d8 <etext+0x135c>
ffffffffc0202bca:	07700593          	li	a1,119
ffffffffc0202bce:	00006517          	auipc	a0,0x6
ffffffffc0202bd2:	9d250513          	addi	a0,a0,-1582 # ffffffffc02085a0 <etext+0x1324>
ffffffffc0202bd6:	dfafd0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0202bda <slub_pages_alloc>:
    /* entry.S 保存的启动 hart 硬件 ID（单核环境下为 0，但来源是硬件而非常量） */
    return (unsigned int)boot_hartid;
}

static inline void slub_port_local_lock(slub_port_flags_t *flags) {
    unsigned long s = read_csr(sstatus);
ffffffffc0202bda:	100026f3          	csrr	a3,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0202bde:	8a89                	andi	a3,a3,2
    if (*flags) {
ffffffffc0202be0:	c299                	beqz	a3,ffffffffc0202be6 <slub_pages_alloc+0xc>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0202be2:	100177f3          	csrrci	a5,sstatus,2
    }
    __sync_synchronize();
ffffffffc0202be6:	0330000f          	fence	rw,rw
static inline void slub_port_spin_lock(slub_spinlock_t *lock,
                                       slub_port_flags_t *flags) {
    /* 关本地中断：防止“同核中断里再取同一把锁”的自旋死锁；
     * 多核互斥完全由下面的原子操作提供。 */
    slub_port_local_lock(flags);
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0202bea:	00025717          	auipc	a4,0x25
ffffffffc0202bee:	c3670713          	addi	a4,a4,-970 # ffffffffc0227820 <slub_pmm_lock>
ffffffffc0202bf2:	4785                	li	a5,1
ffffffffc0202bf4:	0cf727af          	amoswap.w.aq	a5,a5,(a4)
ffffffffc0202bf8:	2781                	sext.w	a5,a5
ffffffffc0202bfa:	ffe5                	bnez	a5,ffffffffc0202bf2 <slub_pages_alloc+0x18>
        /* 自旋等待；锁序保证不会出现持锁自等待 */
    }
    __sync_synchronize(); /* acquire */
ffffffffc0202bfc:	0330000f          	fence	rw,rw
static slub_page_t *slub_pages_alloc(size_t npages) {
    slub_page_t *base;
    slub_port_flags_t f;

    slub_port_spin_lock(&slub_pmm_lock, &f);
    if (slub_fault_left != 0) {
ffffffffc0202c00:	00025797          	auipc	a5,0x25
ffffffffc0202c04:	c007b783          	ld	a5,-1024(a5) # ffffffffc0227800 <slub_fault_left>
ffffffffc0202c08:	eb8d                	bnez	a5,ffffffffc0202c3a <slub_pages_alloc+0x60>
static slub_page_t *slub_pages_alloc(size_t npages) {
ffffffffc0202c0a:	1101                	addi	sp,sp,-32
ffffffffc0202c0c:	e436                	sd	a3,8(sp)
ffffffffc0202c0e:	ec06                	sd	ra,24(sp)
    slub_port_local_unlock(flags);
}

static inline slub_page_t *slub_port_pages_alloc(size_t npages) {
    /* 调用方（slub.c）持有 slub_pmm_lock：底层 best-fit/buddy 均非线程安全 */
    return alloc_pages(npages);
ffffffffc0202c10:	c9fff0ef          	jal	ffffffffc02028ae <alloc_pages>
ffffffffc0202c14:	66a2                	ld	a3,8(sp)
ffffffffc0202c16:	00025717          	auipc	a4,0x25
ffffffffc0202c1a:	c0a70713          	addi	a4,a4,-1014 # ffffffffc0227820 <slub_pmm_lock>
    __sync_synchronize(); /* release */
ffffffffc0202c1e:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0202c22:	0310000f          	fence	rw,w
ffffffffc0202c26:	00072023          	sw	zero,0(a4)
    __sync_synchronize();
ffffffffc0202c2a:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0202c2e:	c299                	beqz	a3,ffffffffc0202c34 <slub_pages_alloc+0x5a>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0202c30:	100167f3          	csrrsi	a5,sstatus,2
    } else {
        base = slub_port_pages_alloc(npages);
    }
    slub_port_spin_unlock(&slub_pmm_lock, &f);
    return base;
}
ffffffffc0202c34:	60e2                	ld	ra,24(sp)
ffffffffc0202c36:	6105                	addi	sp,sp,32
ffffffffc0202c38:	8082                	ret
        slub_fault_hit_cnt++;
ffffffffc0202c3a:	00025617          	auipc	a2,0x25
ffffffffc0202c3e:	bbe63603          	ld	a2,-1090(a2) # ffffffffc02277f8 <slub_fault_hit_cnt>
        slub_fault_left--;
ffffffffc0202c42:	17fd                	addi	a5,a5,-1
ffffffffc0202c44:	00025597          	auipc	a1,0x25
ffffffffc0202c48:	baf5be23          	sd	a5,-1092(a1) # ffffffffc0227800 <slub_fault_left>
        slub_fault_hit_cnt++;
ffffffffc0202c4c:	00160793          	addi	a5,a2,1
ffffffffc0202c50:	00025617          	auipc	a2,0x25
ffffffffc0202c54:	baf63423          	sd	a5,-1112(a2) # ffffffffc02277f8 <slub_fault_hit_cnt>
        base = NULL;
ffffffffc0202c58:	4501                	li	a0,0
    __sync_synchronize(); /* release */
ffffffffc0202c5a:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0202c5e:	0310000f          	fence	rw,w
ffffffffc0202c62:	00072023          	sw	zero,0(a4)
    __sync_synchronize();
ffffffffc0202c66:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0202c6a:	c681                	beqz	a3,ffffffffc0202c72 <slub_pages_alloc+0x98>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0202c6c:	100167f3          	csrrsi	a5,sstatus,2
    return base;
ffffffffc0202c70:	8082                	ret
}
ffffffffc0202c72:	8082                	ret

ffffffffc0202c74 <slub_slab_lookup>:
    unsigned long s = read_csr(sstatus);
ffffffffc0202c74:	10002e73          	csrr	t3,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0202c78:	002e7e13          	andi	t3,t3,2
    if (*flags) {
ffffffffc0202c7c:	000e0463          	beqz	t3,ffffffffc0202c84 <slub_slab_lookup+0x10>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0202c80:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0202c84:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0202c88:	00025817          	auipc	a6,0x25
ffffffffc0202c8c:	ba080813          	addi	a6,a6,-1120 # ffffffffc0227828 <slub_index_lock>
ffffffffc0202c90:	4705                	li	a4,1
ffffffffc0202c92:	0ce8272f          	amoswap.w.aq	a4,a4,(a6)
ffffffffc0202c96:	2701                	sext.w	a4,a4
ffffffffc0202c98:	ff65                	bnez	a4,ffffffffc0202c90 <slub_slab_lookup+0x1c>
    __sync_synchronize(); /* acquire */
ffffffffc0202c9a:	0330000f          	fence	rw,rw
    hi = slub_index_nr;
ffffffffc0202c9e:	00025617          	auipc	a2,0x25
ffffffffc0202ca2:	b8e62603          	lw	a2,-1138(a2) # ffffffffc022782c <slub_index_nr>
        s = slub_index[mid];
ffffffffc0202ca6:	0000b897          	auipc	a7,0xb
ffffffffc0202caa:	f7a88893          	addi	a7,a7,-134 # ffffffffc020dc20 <slub_index>
    while (lo < hi) {
ffffffffc0202cae:	a031                	j	ffffffffc0202cba <slub_slab_lookup+0x46>
        s = slub_index[mid];
ffffffffc0202cb0:	6294                	ld	a3,0(a3)
        if (a < s->base) {
ffffffffc0202cb2:	628c                	ld	a1,0(a3)
ffffffffc0202cb4:	02b57e63          	bgeu	a0,a1,ffffffffc0202cf0 <slub_slab_lookup+0x7c>
            hi = mid;
ffffffffc0202cb8:	863e                	mv	a2,a5
        mid = lo + (hi - lo) / 2;
ffffffffc0202cba:	40e607bb          	subw	a5,a2,a4
ffffffffc0202cbe:	0017d79b          	srliw	a5,a5,0x1
ffffffffc0202cc2:	9fb9                	addw	a5,a5,a4
        s = slub_index[mid];
ffffffffc0202cc4:	02079593          	slli	a1,a5,0x20
ffffffffc0202cc8:	01d5d693          	srli	a3,a1,0x1d
ffffffffc0202ccc:	96c6                	add	a3,a3,a7
    while (lo < hi) {
ffffffffc0202cce:	fec761e3          	bltu	a4,a2,ffffffffc0202cb0 <slub_slab_lookup+0x3c>
ffffffffc0202cd2:	4681                	li	a3,0
    __sync_synchronize(); /* release */
ffffffffc0202cd4:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0202cd8:	0310000f          	fence	rw,w
ffffffffc0202cdc:	00082023          	sw	zero,0(a6)
    __sync_synchronize();
ffffffffc0202ce0:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0202ce4:	000e0463          	beqz	t3,ffffffffc0202cec <slub_slab_lookup+0x78>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0202ce8:	100167f3          	csrrsi	a5,sstatus,2
}
ffffffffc0202cec:	8536                	mv	a0,a3
ffffffffc0202cee:	8082                	ret
        } else if (a >= s->base + (uintptr_t)s->npages * SLUB_PAGE_SIZE) {
ffffffffc0202cf0:	0106e303          	lwu	t1,16(a3)
            lo = mid + 1;
ffffffffc0202cf4:	0017871b          	addiw	a4,a5,1
        } else if (a >= s->base + (uintptr_t)s->npages * SLUB_PAGE_SIZE) {
ffffffffc0202cf8:	00c31793          	slli	a5,t1,0xc
ffffffffc0202cfc:	97ae                	add	a5,a5,a1
ffffffffc0202cfe:	faf57ee3          	bgeu	a0,a5,ffffffffc0202cba <slub_slab_lookup+0x46>
ffffffffc0202d02:	bfc9                	j	ffffffffc0202cd4 <slub_slab_lookup+0x60>

ffffffffc0202d04 <slub_slab_destroy>:
static void slub_slab_destroy(struct slub_cache *c, struct slub_slab *s) {
    slub_page_t *pages = s->pages;   /* 先取出，描述符回池后可能被复用 */
    unsigned int npages = s->npages;
    slub_port_flags_t f;

    if (s->inuse != 0) {
ffffffffc0202d04:	4d98                	lw	a4,24(a1)
static void slub_slab_destroy(struct slub_cache *c, struct slub_slab *s) {
ffffffffc0202d06:	1101                	addi	sp,sp,-32
ffffffffc0202d08:	ec06                	sd	ra,24(sp)
ffffffffc0202d0a:	e822                	sd	s0,16(sp)
ffffffffc0202d0c:	e426                	sd	s1,8(sp)
    if (s->inuse != 0) {
ffffffffc0202d0e:	18071963          	bnez	a4,ffffffffc0202ea0 <slub_slab_destroy+0x19c>
ffffffffc0202d12:	8e2a                	mv	t3,a0
    unsigned int npages = s->npages;
ffffffffc0202d14:	0105af03          	lw	t5,16(a1)
    slub_page_t *pages = s->pages;   /* 先取出，描述符回池后可能被复用 */
ffffffffc0202d18:	6588                	ld	a0,8(a1)
    unsigned long s = read_csr(sstatus);
ffffffffc0202d1a:	10002ef3          	csrr	t4,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0202d1e:	002efe93          	andi	t4,t4,2
    if (*flags) {
ffffffffc0202d22:	140e9f63          	bnez	t4,ffffffffc0202e80 <slub_slab_destroy+0x17c>
    __sync_synchronize();
ffffffffc0202d26:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0202d2a:	00025897          	auipc	a7,0x25
ffffffffc0202d2e:	afe88893          	addi	a7,a7,-1282 # ffffffffc0227828 <slub_index_lock>
ffffffffc0202d32:	4785                	li	a5,1
ffffffffc0202d34:	0cf8a7af          	amoswap.w.aq	a5,a5,(a7)
ffffffffc0202d38:	2781                	sext.w	a5,a5
ffffffffc0202d3a:	ffe5                	bnez	a5,ffffffffc0202d32 <slub_slab_destroy+0x2e>
    __sync_synchronize(); /* acquire */
ffffffffc0202d3c:	0330000f          	fence	rw,rw
    unsigned int lo = 0, hi = slub_index_nr, mid, i;
ffffffffc0202d40:	00025f97          	auipc	t6,0x25
ffffffffc0202d44:	aecfaf83          	lw	t6,-1300(t6) # ffffffffc022782c <slub_index_nr>
        if (slub_index[mid]->base < s->base)
ffffffffc0202d48:	0000b317          	auipc	t1,0xb
ffffffffc0202d4c:	ed830313          	addi	t1,t1,-296 # ffffffffc020dc20 <slub_index>
    unsigned int lo = 0, hi = slub_index_nr, mid, i;
ffffffffc0202d50:	867e                	mv	a2,t6
    while (lo < hi) {
ffffffffc0202d52:	02c7f663          	bgeu	a5,a2,ffffffffc0202d7e <slub_slab_destroy+0x7a>
        mid = lo + (hi - lo) / 2;
ffffffffc0202d56:	40f6073b          	subw	a4,a2,a5
ffffffffc0202d5a:	0017571b          	srliw	a4,a4,0x1
ffffffffc0202d5e:	9f3d                	addw	a4,a4,a5
        if (slub_index[mid]->base < s->base)
ffffffffc0202d60:	02071813          	slli	a6,a4,0x20
ffffffffc0202d64:	01d85693          	srli	a3,a6,0x1d
ffffffffc0202d68:	969a                	add	a3,a3,t1
ffffffffc0202d6a:	0006b803          	ld	a6,0(a3)
ffffffffc0202d6e:	6194                	ld	a3,0(a1)
ffffffffc0202d70:	00083803          	ld	a6,0(a6)
ffffffffc0202d74:	10d86063          	bltu	a6,a3,ffffffffc0202e74 <slub_slab_destroy+0x170>
            hi = mid;
ffffffffc0202d78:	863a                	mv	a2,a4
    while (lo < hi) {
ffffffffc0202d7a:	fcc7eee3          	bltu	a5,a2,ffffffffc0202d56 <slub_slab_destroy+0x52>
    if (lo >= slub_index_nr || slub_index[lo] != s) {
ffffffffc0202d7e:	11f7f463          	bgeu	a5,t6,ffffffffc0202e86 <slub_slab_destroy+0x182>
ffffffffc0202d82:	02079713          	slli	a4,a5,0x20
ffffffffc0202d86:	9301                	srli	a4,a4,0x20
ffffffffc0202d88:	0000b317          	auipc	t1,0xb
ffffffffc0202d8c:	e9830313          	addi	t1,t1,-360 # ffffffffc020dc20 <slub_index>
ffffffffc0202d90:	00371693          	slli	a3,a4,0x3
ffffffffc0202d94:	969a                	add	a3,a3,t1
ffffffffc0202d96:	6294                	ld	a3,0(a3)
ffffffffc0202d98:	0ed59763          	bne	a1,a3,ffffffffc0202e86 <slub_slab_destroy+0x182>
    for (i = lo; i + 1 < slub_index_nr; i++) slub_index[i] = slub_index[i + 1];
ffffffffc0202d9c:	2785                	addiw	a5,a5,1
ffffffffc0202d9e:	ffff881b          	addiw	a6,t6,-1
ffffffffc0202da2:	03f7f563          	bgeu	a5,t6,ffffffffc0202dcc <slub_slab_destroy+0xc8>
ffffffffc0202da6:	02079613          	slli	a2,a5,0x20
ffffffffc0202daa:	01d65693          	srli	a3,a2,0x1d
ffffffffc0202dae:	ffff881b          	addiw	a6,t6,-1
ffffffffc0202db2:	969a                	add	a3,a3,t1
ffffffffc0202db4:	a029                	j	ffffffffc0202dbe <slub_slab_destroy+0xba>
ffffffffc0202db6:	02079713          	slli	a4,a5,0x20
ffffffffc0202dba:	9301                	srli	a4,a4,0x20
ffffffffc0202dbc:	2785                	addiw	a5,a5,1
ffffffffc0202dbe:	6290                	ld	a2,0(a3)
ffffffffc0202dc0:	070e                	slli	a4,a4,0x3
ffffffffc0202dc2:	971a                	add	a4,a4,t1
ffffffffc0202dc4:	e310                	sd	a2,0(a4)
ffffffffc0202dc6:	06a1                	addi	a3,a3,8
ffffffffc0202dc8:	fef817e3          	bne	a6,a5,ffffffffc0202db6 <slub_slab_destroy+0xb2>
    }
    slub_port_spin_lock(&slub_index_lock, &f);
    slub_index_remove_locked(s);
    s->state = 0;
    s->freelist = NULL;
    s->next = slub_pool_free;
ffffffffc0202dcc:	00025797          	auipc	a5,0x25
ffffffffc0202dd0:	a647b783          	ld	a5,-1436(a5) # ffffffffc0227830 <slub_pool_free>
    slub_index_nr--;
ffffffffc0202dd4:	00025717          	auipc	a4,0x25
ffffffffc0202dd8:	a5072c23          	sw	a6,-1448(a4) # ffffffffc022782c <slub_index_nr>
    s->state = 0;
ffffffffc0202ddc:	00058ea3          	sb	zero,29(a1)
    s->next = slub_pool_free;
ffffffffc0202de0:	f59c                	sd	a5,40(a1)
    s->freelist = NULL;
ffffffffc0202de2:	0205b023          	sd	zero,32(a1)
    slub_pool_free = s;
ffffffffc0202de6:	00025797          	auipc	a5,0x25
ffffffffc0202dea:	a4b7b523          	sd	a1,-1462(a5) # ffffffffc0227830 <slub_pool_free>
    __sync_synchronize(); /* release */
ffffffffc0202dee:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0202df2:	0310000f          	fence	rw,w
ffffffffc0202df6:	0008a023          	sw	zero,0(a7)
    __sync_synchronize();
ffffffffc0202dfa:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0202dfe:	000e8463          	beqz	t4,ffffffffc0202e06 <slub_slab_destroy+0x102>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0202e02:	100167f3          	csrrsi	a5,sstatus,2
    slub_port_spin_unlock(&slub_index_lock, &f);

    c->nr_slabs--;
ffffffffc0202e06:	034e2683          	lw	a3,52(t3)
    c->nr_slab_pages -= c->slab_pages;
ffffffffc0202e0a:	038e2703          	lw	a4,56(t3)
    c->stat_slab_free++;
ffffffffc0202e0e:	060e3783          	ld	a5,96(t3)
    c->nr_slab_pages -= c->slab_pages;
ffffffffc0202e12:	010e2603          	lw	a2,16(t3)
    c->nr_slabs--;
ffffffffc0202e16:	36fd                	addiw	a3,a3,-1
    c->stat_slab_free++;
ffffffffc0202e18:	0785                	addi	a5,a5,1
    c->nr_slab_pages -= c->slab_pages;
ffffffffc0202e1a:	9f11                	subw	a4,a4,a2
    slub_pages_free(pages, npages);
ffffffffc0202e1c:	020f1593          	slli	a1,t5,0x20
ffffffffc0202e20:	9181                	srli	a1,a1,0x20
    c->nr_slabs--;
ffffffffc0202e22:	02de2a23          	sw	a3,52(t3)
    c->nr_slab_pages -= c->slab_pages;
ffffffffc0202e26:	02ee2c23          	sw	a4,56(t3)
    c->stat_slab_free++;
ffffffffc0202e2a:	06fe3023          	sd	a5,96(t3)
    unsigned long s = read_csr(sstatus);
ffffffffc0202e2e:	100024f3          	csrr	s1,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0202e32:	8889                	andi	s1,s1,2
    if (*flags) {
ffffffffc0202e34:	e0b9                	bnez	s1,ffffffffc0202e7a <slub_slab_destroy+0x176>
    __sync_synchronize();
ffffffffc0202e36:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0202e3a:	00025417          	auipc	s0,0x25
ffffffffc0202e3e:	9e640413          	addi	s0,s0,-1562 # ffffffffc0227820 <slub_pmm_lock>
ffffffffc0202e42:	4785                	li	a5,1
ffffffffc0202e44:	0cf427af          	amoswap.w.aq	a5,a5,(s0)
ffffffffc0202e48:	2781                	sext.w	a5,a5
ffffffffc0202e4a:	ffe5                	bnez	a5,ffffffffc0202e42 <slub_slab_destroy+0x13e>
    __sync_synchronize(); /* acquire */
ffffffffc0202e4c:	0330000f          	fence	rw,rw
}

static inline void slub_port_pages_free(slub_page_t *base, size_t npages) {
    /* npages 必须是当初分配时的原始请求值（buddy 断言 property==n） */
    free_pages(base, npages);
ffffffffc0202e50:	a6bff0ef          	jal	ffffffffc02028ba <free_pages>
    __sync_synchronize(); /* release */
ffffffffc0202e54:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0202e58:	0310000f          	fence	rw,w
ffffffffc0202e5c:	00042023          	sw	zero,0(s0)
    __sync_synchronize();
ffffffffc0202e60:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0202e64:	c099                	beqz	s1,ffffffffc0202e6a <slub_slab_destroy+0x166>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0202e66:	100167f3          	csrrsi	a5,sstatus,2
}
ffffffffc0202e6a:	60e2                	ld	ra,24(sp)
ffffffffc0202e6c:	6442                	ld	s0,16(sp)
ffffffffc0202e6e:	64a2                	ld	s1,8(sp)
ffffffffc0202e70:	6105                	addi	sp,sp,32
ffffffffc0202e72:	8082                	ret
            lo = mid + 1;
ffffffffc0202e74:	0017079b          	addiw	a5,a4,1
ffffffffc0202e78:	bde9                	j	ffffffffc0202d52 <slub_slab_destroy+0x4e>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0202e7a:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0202e7e:	bf65                	j	ffffffffc0202e36 <slub_slab_destroy+0x132>
ffffffffc0202e80:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0202e84:	b54d                	j	ffffffffc0202d26 <slub_slab_destroy+0x22>
        slub_port_panic("slub: slab %lx is not registered",
ffffffffc0202e86:	6194                	ld	a3,0(a1)
ffffffffc0202e88:	00006617          	auipc	a2,0x6
ffffffffc0202e8c:	8a860613          	addi	a2,a2,-1880 # ffffffffc0208730 <etext+0x14b4>
ffffffffc0202e90:	15c00593          	li	a1,348
ffffffffc0202e94:	00006517          	auipc	a0,0x6
ffffffffc0202e98:	88c50513          	addi	a0,a0,-1908 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0202e9c:	b34fd0ef          	jal	ffffffffc02001d0 <__panic>
        slub_port_panic("slub: destroy slab %lx with %lu objects in use",
ffffffffc0202ea0:	6194                	ld	a3,0(a1)
ffffffffc0202ea2:	1702                	slli	a4,a4,0x20
ffffffffc0202ea4:	9301                	srli	a4,a4,0x20
ffffffffc0202ea6:	00006617          	auipc	a2,0x6
ffffffffc0202eaa:	84a60613          	addi	a2,a2,-1974 # ffffffffc02086f0 <etext+0x1474>
ffffffffc0202eae:	1b600593          	li	a1,438
ffffffffc0202eb2:	00006517          	auipc	a0,0x6
ffffffffc0202eb6:	86e50513          	addi	a0,a0,-1938 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0202eba:	b16fd0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0202ebe <slub_put_objects>:

#define SLUB_PUT_ALL 0  /* sheaf -> barn -> slab 全级联 */
#define SLUB_PUT_SLAB 1 /* 只回 slab（slub_shrink 用） */

static void slub_put_objects(unsigned int cls, void **objs, unsigned int n,
                             int target) {
ffffffffc0202ebe:	7175                	addi	sp,sp,-144
ffffffffc0202ec0:	f4ce                	sd	s3,104(sp)
ffffffffc0202ec2:	ecd6                	sd	s5,88(sp)
ffffffffc0202ec4:	02051993          	slli	s3,a0,0x20
ffffffffc0202ec8:	e506                	sd	ra,136(sp)
ffffffffc0202eca:	fca6                	sd	s1,120(sp)
ffffffffc0202ecc:	8aaa                	mv	s5,a0
    struct slub_cache *c = &slub_caches[cls];
ffffffffc0202ece:	0209d993          	srli	s3,s3,0x20
    slub_port_flags_t f;
    unsigned int i = 0;

    if (target == SLUB_PUT_ALL) {
ffffffffc0202ed2:	34069163          	bnez	a3,ffffffffc0203214 <slub_put_objects+0x356>
    if (cpu >= SLUB_NCPUS) {
ffffffffc0202ed6:	0000a797          	auipc	a5,0xa
ffffffffc0202eda:	12a7a783          	lw	a5,298(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0202ede:	44079063          	bnez	a5,ffffffffc020331e <slub_put_objects+0x460>
    unsigned long s = read_csr(sstatus);
ffffffffc0202ee2:	10002ff3          	csrr	t6,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0202ee6:	002fff93          	andi	t6,t6,2
    if (*flags) {
ffffffffc0202eea:	000f8463          	beqz	t6,ffffffffc0202ef2 <slub_put_objects+0x34>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0202eee:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0202ef2:	0330000f          	fence	rw,rw
    if (n > sf->cap - sf->size) n = sf->cap - sf->size;
ffffffffc0202ef6:	0001cf17          	auipc	t5,0x1c
ffffffffc0202efa:	e6af0f13          	addi	t5,t5,-406 # ffffffffc021ed60 <slub_cc>
ffffffffc0202efe:	00599793          	slli	a5,s3,0x5
ffffffffc0202f02:	97fa                	add	a5,a5,t5
ffffffffc0202f04:	0087a283          	lw	t0,8(a5)
ffffffffc0202f08:	47dc                	lw	a5,12(a5)
ffffffffc0202f0a:	405787bb          	subw	a5,a5,t0
ffffffffc0202f0e:	88be                	mv	a7,a5
ffffffffc0202f10:	00f67363          	bgeu	a2,a5,ffffffffc0202f16 <slub_put_objects+0x58>
ffffffffc0202f14:	88b2                	mv	a7,a2
ffffffffc0202f16:	00088e9b          	sext.w	t4,a7
    for (i = 0; i < n; i++) sf->objs[sf->size + i] = objs[i];
ffffffffc0202f1a:	020e8663          	beqz	t4,ffffffffc0202f46 <slub_put_objects+0x88>
ffffffffc0202f1e:	00599313          	slli	t1,s3,0x5
ffffffffc0202f22:	011288bb          	addw	a7,t0,a7
ffffffffc0202f26:	937a                	add	t1,t1,t5
ffffffffc0202f28:	852e                	mv	a0,a1
ffffffffc0202f2a:	8796                	mv	a5,t0
ffffffffc0202f2c:	00033683          	ld	a3,0(t1)
ffffffffc0202f30:	6118                	ld	a4,0(a0)
ffffffffc0202f32:	02079e13          	slli	t3,a5,0x20
ffffffffc0202f36:	01de5813          	srli	a6,t3,0x1d
ffffffffc0202f3a:	96c2                	add	a3,a3,a6
ffffffffc0202f3c:	2785                	addiw	a5,a5,1
ffffffffc0202f3e:	e298                	sd	a4,0(a3)
ffffffffc0202f40:	0521                	addi	a0,a0,8
ffffffffc0202f42:	ff1795e3          	bne	a5,a7,ffffffffc0202f2c <slub_put_objects+0x6e>
    sf->size += n;
ffffffffc0202f46:	00599793          	slli	a5,s3,0x5
ffffffffc0202f4a:	97fa                	add	a5,a5,t5
    if (n > sf->cap - sf->size) n = sf->cap - sf->size;
ffffffffc0202f4c:	4fd8                	lw	a4,28(a5)
ffffffffc0202f4e:	0187a383          	lw	t2,24(a5)
    sf->size += n;
ffffffffc0202f52:	01d282bb          	addw	t0,t0,t4
ffffffffc0202f56:	0057a423          	sw	t0,8(a5)
    if (n > sf->cap - sf->size) n = sf->cap - sf->size;
ffffffffc0202f5a:	407707bb          	subw	a5,a4,t2
        struct slub_cpu_cache *cc = &slub_cc[slub_cpu()][cls];

        slub_port_local_lock(&f);
        i += slub_sheaf_push(&cc->main, objs + i, n - i);
        i += slub_sheaf_push(&cc->spare, objs + i, n - i);
ffffffffc0202f5e:	41d6073b          	subw	a4,a2,t4
    if (n > sf->cap - sf->size) n = sf->cap - sf->size;
ffffffffc0202f62:	833e                	mv	t1,a5
ffffffffc0202f64:	00f77363          	bgeu	a4,a5,ffffffffc0202f6a <slub_put_objects+0xac>
ffffffffc0202f68:	833a                	mv	t1,a4
ffffffffc0202f6a:	0003071b          	sext.w	a4,t1
    for (i = 0; i < n; i++) sf->objs[sf->size + i] = objs[i];
ffffffffc0202f6e:	cb1d                	beqz	a4,ffffffffc0202fa4 <slub_put_objects+0xe6>
ffffffffc0202f70:	020e9793          	slli	a5,t4,0x20
ffffffffc0202f74:	01d7d513          	srli	a0,a5,0x1d
ffffffffc0202f78:	00599e13          	slli	t3,s3,0x5
ffffffffc0202f7c:	0063833b          	addw	t1,t2,t1
ffffffffc0202f80:	952e                	add	a0,a0,a1
ffffffffc0202f82:	9e7a                	add	t3,t3,t5
        i += slub_sheaf_push(&cc->spare, objs + i, n - i);
ffffffffc0202f84:	879e                	mv	a5,t2
    for (i = 0; i < n; i++) sf->objs[sf->size + i] = objs[i];
ffffffffc0202f86:	010e3683          	ld	a3,16(t3)
ffffffffc0202f8a:	00053803          	ld	a6,0(a0)
ffffffffc0202f8e:	02079293          	slli	t0,a5,0x20
ffffffffc0202f92:	01d2d893          	srli	a7,t0,0x1d
ffffffffc0202f96:	96c6                	add	a3,a3,a7
ffffffffc0202f98:	2785                	addiw	a5,a5,1
ffffffffc0202f9a:	0106b023          	sd	a6,0(a3)
ffffffffc0202f9e:	0521                	addi	a0,a0,8
ffffffffc0202fa0:	fef313e3          	bne	t1,a5,ffffffffc0202f86 <slub_put_objects+0xc8>
    sf->size += n;
ffffffffc0202fa4:	00599793          	slli	a5,s3,0x5
ffffffffc0202fa8:	00e383bb          	addw	t2,t2,a4
ffffffffc0202fac:	97fa                	add	a5,a5,t5
ffffffffc0202fae:	0077ac23          	sw	t2,24(a5)
        i += slub_sheaf_push(&cc->spare, objs + i, n - i);
ffffffffc0202fb2:	01d7073b          	addw	a4,a4,t4
    __sync_synchronize();
ffffffffc0202fb6:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0202fba:	000f8463          	beqz	t6,ffffffffc0202fc2 <slub_put_objects+0x104>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0202fbe:	100167f3          	csrrsi	a5,sstatus,2
        slub_port_local_unlock(&f);
        if (i == n) return;
ffffffffc0202fc2:	24e60363          	beq	a2,a4,ffffffffc0203208 <slub_put_objects+0x34a>
ffffffffc0202fc6:	e122                	sd	s0,128(sp)

        i += slub_barn_put(cls, objs + i, n - i); /* 批量拷贝后已释放本地锁 */
ffffffffc0202fc8:	40e6083b          	subw	a6,a2,a4
    unsigned long s = read_csr(sstatus);
ffffffffc0202fcc:	10002ff3          	csrr	t6,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0202fd0:	002fff93          	andi	t6,t6,2
    if (*flags) {
ffffffffc0202fd4:	2c0f9863          	bnez	t6,ffffffffc02032a4 <slub_put_objects+0x3e6>
    __sync_synchronize();
ffffffffc0202fd8:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0202fdc:	00299513          	slli	a0,s3,0x2
ffffffffc0202fe0:	954e                	add	a0,a0,s3
ffffffffc0202fe2:	050e                	slli	a0,a0,0x3
ffffffffc0202fe4:	0001cf17          	auipc	t5,0x1c
ffffffffc0202fe8:	e7cf0f13          	addi	t5,t5,-388 # ffffffffc021ee60 <slub_barns>
ffffffffc0202fec:	957a                	add	a0,a0,t5
ffffffffc0202fee:	4785                	li	a5,1
ffffffffc0202ff0:	0cf527af          	amoswap.w.aq	a5,a5,(a0)
ffffffffc0202ff4:	2781                	sext.w	a5,a5
ffffffffc0202ff6:	ffe5                	bnez	a5,ffffffffc0202fee <slub_put_objects+0x130>
    __sync_synchronize(); /* acquire */
ffffffffc0202ff8:	0330000f          	fence	rw,rw
    i = b->cap - b->size;
ffffffffc0202ffc:	00299693          	slli	a3,s3,0x2
ffffffffc0203000:	96ce                	add	a3,a3,s3
ffffffffc0203002:	068e                	slli	a3,a3,0x3
ffffffffc0203004:	96fa                	add	a3,a3,t5
ffffffffc0203006:	4a9c                	lw	a5,16(a3)
ffffffffc0203008:	4ad4                	lw	a3,20(a3)
ffffffffc020300a:	9e9d                	subw	a3,a3,a5
    if (i > n) i = n;
ffffffffc020300c:	8e36                	mv	t3,a3
ffffffffc020300e:	28d86963          	bltu	a6,a3,ffffffffc02032a0 <slub_put_objects+0x3e2>
        i += slub_barn_put(cls, objs + i, n - i); /* 批量拷贝后已释放本地锁 */
ffffffffc0203012:	01c704bb          	addw	s1,a4,t3
    if (i > n) i = n;
ffffffffc0203016:	000e041b          	sext.w	s0,t3
        i += slub_barn_put(cls, objs + i, n - i); /* 批量拷贝后已释放本地锁 */
ffffffffc020301a:	8826                	mv	a6,s1
    for (k = 0; k < i; k++) b->objs[b->size + k] = objs[k];
ffffffffc020301c:	28040a63          	beqz	s0,ffffffffc02032b0 <slub_put_objects+0x3f2>
ffffffffc0203020:	00299393          	slli	t2,s3,0x2
ffffffffc0203024:	93ce                	add	t2,t2,s3
ffffffffc0203026:	02071693          	slli	a3,a4,0x20
ffffffffc020302a:	01d6d713          	srli	a4,a3,0x1d
ffffffffc020302e:	00339e93          	slli	t4,t2,0x3
ffffffffc0203032:	972e                	add	a4,a4,a1
ffffffffc0203034:	01c78e3b          	addw	t3,a5,t3
ffffffffc0203038:	9efa                	add	t4,t4,t5
ffffffffc020303a:	008eb683          	ld	a3,8(t4)
ffffffffc020303e:	00073883          	ld	a7,0(a4)
ffffffffc0203042:	02079293          	slli	t0,a5,0x20
ffffffffc0203046:	01d2d313          	srli	t1,t0,0x1d
ffffffffc020304a:	969a                	add	a3,a3,t1
ffffffffc020304c:	2785                	addiw	a5,a5,1
ffffffffc020304e:	0116b023          	sd	a7,0(a3)
ffffffffc0203052:	0721                	addi	a4,a4,8
ffffffffc0203054:	fefe13e3          	bne	t3,a5,ffffffffc020303a <slub_put_objects+0x17c>
    b->size += i;
ffffffffc0203058:	038e                	slli	t2,t2,0x3
ffffffffc020305a:	9f1e                	add	t5,t5,t2
    if (i != 0) b->stat_put += i;
ffffffffc020305c:	020f3783          	ld	a5,32(t5)
ffffffffc0203060:	1402                	slli	s0,s0,0x20
ffffffffc0203062:	9001                	srli	s0,s0,0x20
ffffffffc0203064:	97a2                	add	a5,a5,s0
    b->size += i;
ffffffffc0203066:	01cf2823          	sw	t3,16(t5)
    if (i != 0) b->stat_put += i;
ffffffffc020306a:	02ff3023          	sd	a5,32(t5)
    __sync_synchronize(); /* release */
ffffffffc020306e:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0203072:	0310000f          	fence	rw,w
ffffffffc0203076:	00052023          	sw	zero,0(a0)
    __sync_synchronize();
ffffffffc020307a:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc020307e:	220f9663          	bnez	t6,ffffffffc02032aa <slub_put_objects+0x3ec>
        if (i == n) return;
ffffffffc0203082:	640a                	ld	s0,128(sp)
ffffffffc0203084:	18960263          	beq	a2,s1,ffffffffc0203208 <slub_put_objects+0x34a>
ffffffffc0203088:	e8da                	sd	s6,80(sp)
ffffffffc020308a:	00499b13          	slli	s6,s3,0x4
ffffffffc020308e:	413b0b33          	sub	s6,s6,s3
ffffffffc0203092:	e0e2                	sd	s8,64(sp)
ffffffffc0203094:	fc66                	sd	s9,56(sp)
ffffffffc0203096:	0b0e                	slli	s6,s6,0x3
    unsigned long s = read_csr(sstatus);
ffffffffc0203098:	10002cf3          	csrr	s9,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc020309c:	002cf793          	andi	a5,s9,2
ffffffffc02030a0:	e83e                	sd	a5,16(sp)
    if (*flags) {
ffffffffc02030a2:	18079963          	bnez	a5,ffffffffc0203234 <slub_put_objects+0x376>
    __sync_synchronize();
ffffffffc02030a6:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc02030aa:	0001cc17          	auipc	s8,0x1c
ffffffffc02030ae:	ef6c0c13          	addi	s8,s8,-266 # ffffffffc021efa0 <slub_caches>
ffffffffc02030b2:	014b0493          	addi	s1,s6,20
ffffffffc02030b6:	94e2                	add	s1,s1,s8
ffffffffc02030b8:	4785                	li	a5,1
ffffffffc02030ba:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
ffffffffc02030be:	2781                	sext.w	a5,a5
ffffffffc02030c0:	ffe5                	bnez	a5,ffffffffc02030b8 <slub_put_objects+0x1fa>
    __sync_synchronize(); /* acquire */
ffffffffc02030c2:	0330000f          	fence	rw,rw
    }

    slub_port_spin_lock(&c->lock, &f);
    for (; i < n; i++) slub_slab_release_obj(c, cls, objs[i]);
ffffffffc02030c6:	12c87463          	bgeu	a6,a2,ffffffffc02031ee <slub_put_objects+0x330>
ffffffffc02030ca:	e122                	sd	s0,128(sp)
ffffffffc02030cc:	fff6041b          	addiw	s0,a2,-1
ffffffffc02030d0:	4104043b          	subw	s0,s0,a6
ffffffffc02030d4:	1402                	slli	s0,s0,0x20
ffffffffc02030d6:	1802                	slli	a6,a6,0x20
ffffffffc02030d8:	02085813          	srli	a6,a6,0x20
ffffffffc02030dc:	9001                	srli	s0,s0,0x20
ffffffffc02030de:	9442                	add	s0,s0,a6
ffffffffc02030e0:	f86a                	sd	s10,48(sp)
    if (((uintptr_t)obj - s->base) % c->objsize != 0) {
ffffffffc02030e2:	00499d13          	slli	s10,s3,0x4
ffffffffc02030e6:	413d0733          	sub	a4,s10,s3
ffffffffc02030ea:	00858793          	addi	a5,a1,8
ffffffffc02030ee:	040e                	slli	s0,s0,0x3
ffffffffc02030f0:	f46e                	sd	s11,40(sp)
ffffffffc02030f2:	080e                	slli	a6,a6,0x3
ffffffffc02030f4:	943e                	add	s0,s0,a5
ffffffffc02030f6:	00371d93          	slli	s11,a4,0x3
    struct slub_cache *c = &slub_caches[cls];
ffffffffc02030fa:	016c07b3          	add	a5,s8,s6
ffffffffc02030fe:	f8ca                	sd	s2,112(sp)
ffffffffc0203100:	f0d2                	sd	s4,96(sp)
ffffffffc0203102:	e4de                	sd	s7,72(sp)
    if (((uintptr_t)obj - s->base) % c->objsize != 0) {
ffffffffc0203104:	ec3a                	sd	a4,24(sp)
ffffffffc0203106:	01058cb3          	add	s9,a1,a6
ffffffffc020310a:	9de2                	add	s11,s11,s8
    struct slub_cache *c = &slub_caches[cls];
ffffffffc020310c:	e43e                	sd	a5,8(sp)
    if (s->state == SLUB_SLAB_EMPTY) {
ffffffffc020310e:	490d                	li	s2,3
    } else if (was_full) {
ffffffffc0203110:	4a05                	li	s4,1
        s->state = SLUB_SLAB_PARTIAL;
ffffffffc0203112:	4b89                	li	s7,2
ffffffffc0203114:	a0a9                	j	ffffffffc020315e <slub_put_objects+0x2a0>
        if (s->state == SLUB_SLAB_PARTIAL) {
ffffffffc0203116:	13760763          	beq	a2,s7,ffffffffc0203244 <slub_put_objects+0x386>
        } else if (s->state == SLUB_SLAB_FULL) {
ffffffffc020311a:	01461763          	bne	a2,s4,ffffffffc0203128 <slub_put_objects+0x26a>
            c->nr_full--;
ffffffffc020311e:	030da783          	lw	a5,48(s11)
ffffffffc0203122:	37fd                	addiw	a5,a5,-1
ffffffffc0203124:	02fda823          	sw	a5,48(s11)
        s->state = SLUB_SLAB_EMPTY;
ffffffffc0203128:	01250ea3          	sb	s2,29(a0)
        if (c->nr_empty < SLUB_EMPTY_KEEP) {
ffffffffc020312c:	02cda783          	lw	a5,44(s11)
ffffffffc0203130:	10fa6563          	bltu	s4,a5,ffffffffc020323a <slub_put_objects+0x37c>
            s->next = c->empty;
ffffffffc0203134:	020db683          	ld	a3,32(s11)
            c->nr_empty++;
ffffffffc0203138:	2785                	addiw	a5,a5,1
            s->next = c->empty;
ffffffffc020313a:	f514                	sd	a3,40(a0)
            c->nr_empty++;
ffffffffc020313c:	02fda623          	sw	a5,44(s11)
            c->empty = s;
ffffffffc0203140:	02adb023          	sd	a0,32(s11)
    c->inuse_objs--;
ffffffffc0203144:	040db683          	ld	a3,64(s11)
    c->stat_flush++;
ffffffffc0203148:	050db783          	ld	a5,80(s11)
    for (; i < n; i++) slub_slab_release_obj(c, cls, objs[i]);
ffffffffc020314c:	0ca1                	addi	s9,s9,8
    c->inuse_objs--;
ffffffffc020314e:	16fd                	addi	a3,a3,-1
    c->stat_flush++;
ffffffffc0203150:	0785                	addi	a5,a5,1
    c->inuse_objs--;
ffffffffc0203152:	04ddb023          	sd	a3,64(s11)
    c->stat_flush++;
ffffffffc0203156:	04fdb823          	sd	a5,80(s11)
    for (; i < n; i++) slub_slab_release_obj(c, cls, objs[i]);
ffffffffc020315a:	09940463          	beq	s0,s9,ffffffffc02031e2 <slub_put_objects+0x324>
ffffffffc020315e:	000cbd03          	ld	s10,0(s9)
    struct slub_slab *s = slub_slab_lookup(obj);
ffffffffc0203162:	856a                	mv	a0,s10
ffffffffc0203164:	b11ff0ef          	jal	ffffffffc0202c74 <slub_slab_lookup>
    if (s == NULL || s->cls != cls) {
ffffffffc0203168:	16050363          	beqz	a0,ffffffffc02032ce <slub_put_objects+0x410>
ffffffffc020316c:	01c54783          	lbu	a5,28(a0)
ffffffffc0203170:	15579f63          	bne	a5,s5,ffffffffc02032ce <slub_put_objects+0x410>
    if (((uintptr_t)obj - s->base) % c->objsize != 0) {
ffffffffc0203174:	00053803          	ld	a6,0(a0)
ffffffffc0203178:	000db603          	ld	a2,0(s11)
ffffffffc020317c:	410d07b3          	sub	a5,s10,a6
ffffffffc0203180:	02c7f7b3          	remu	a5,a5,a2
ffffffffc0203184:	16079363          	bnez	a5,ffffffffc02032ea <slub_put_objects+0x42c>
    if (s->state == SLUB_SLAB_EMPTY) {
ffffffffc0203188:	01d54603          	lbu	a2,29(a0)
ffffffffc020318c:	17260c63          	beq	a2,s2,ffffffffc0203304 <slub_put_objects+0x446>
    s->inuse--;
ffffffffc0203190:	4d1c                	lw	a5,24(a0)
    *(void **)obj = s->freelist; /* 侵入式空闲链 */
ffffffffc0203192:	710c                	ld	a1,32(a0)
    s->inuse--;
ffffffffc0203194:	37fd                	addiw	a5,a5,-1
    *(void **)obj = s->freelist; /* 侵入式空闲链 */
ffffffffc0203196:	00bd3023          	sd	a1,0(s10)
    s->freelist = obj;
ffffffffc020319a:	03a53023          	sd	s10,32(a0)
    s->inuse--;
ffffffffc020319e:	cd1c                	sw	a5,24(a0)
    if (s->inuse == 0) {
ffffffffc02031a0:	dbbd                	beqz	a5,ffffffffc0203116 <slub_put_objects+0x258>
    } else if (was_full) {
ffffffffc02031a2:	fb4611e3          	bne	a2,s4,ffffffffc0203144 <slub_put_objects+0x286>
        s->state = SLUB_SLAB_PARTIAL;
ffffffffc02031a6:	01750ea3          	sb	s7,29(a0)
        s->next = c->partial;
ffffffffc02031aa:	018db783          	ld	a5,24(s11)
        c->nr_partial++;
ffffffffc02031ae:	028da683          	lw	a3,40(s11)
    for (; i < n; i++) slub_slab_release_obj(c, cls, objs[i]);
ffffffffc02031b2:	0ca1                	addi	s9,s9,8
        s->next = c->partial;
ffffffffc02031b4:	f51c                	sd	a5,40(a0)
        c->nr_full--;
ffffffffc02031b6:	030da783          	lw	a5,48(s11)
        c->nr_partial++;
ffffffffc02031ba:	2685                	addiw	a3,a3,1
ffffffffc02031bc:	02dda423          	sw	a3,40(s11)
        c->nr_full--;
ffffffffc02031c0:	37fd                	addiw	a5,a5,-1
    c->inuse_objs--;
ffffffffc02031c2:	040db683          	ld	a3,64(s11)
        c->nr_full--;
ffffffffc02031c6:	02fda823          	sw	a5,48(s11)
    c->stat_flush++;
ffffffffc02031ca:	050db783          	ld	a5,80(s11)
    c->inuse_objs--;
ffffffffc02031ce:	16fd                	addi	a3,a3,-1
        c->partial = s;
ffffffffc02031d0:	00adbc23          	sd	a0,24(s11)
    c->stat_flush++;
ffffffffc02031d4:	0785                	addi	a5,a5,1
    c->inuse_objs--;
ffffffffc02031d6:	04ddb023          	sd	a3,64(s11)
    c->stat_flush++;
ffffffffc02031da:	04fdb823          	sd	a5,80(s11)
    for (; i < n; i++) slub_slab_release_obj(c, cls, objs[i]);
ffffffffc02031de:	f99410e3          	bne	s0,s9,ffffffffc020315e <slub_put_objects+0x2a0>
ffffffffc02031e2:	640a                	ld	s0,128(sp)
ffffffffc02031e4:	7946                	ld	s2,112(sp)
ffffffffc02031e6:	7a06                	ld	s4,96(sp)
ffffffffc02031e8:	6ba6                	ld	s7,72(sp)
ffffffffc02031ea:	7d42                	ld	s10,48(sp)
ffffffffc02031ec:	7da2                	ld	s11,40(sp)
    __sync_synchronize(); /* release */
ffffffffc02031ee:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc02031f2:	0310000f          	fence	rw,w
ffffffffc02031f6:	0004a023          	sw	zero,0(s1)
    __sync_synchronize();
ffffffffc02031fa:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02031fe:	67c2                	ld	a5,16(sp)
ffffffffc0203200:	efc9                	bnez	a5,ffffffffc020329a <slub_put_objects+0x3dc>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0203202:	6b46                	ld	s6,80(sp)
ffffffffc0203204:	6c06                	ld	s8,64(sp)
ffffffffc0203206:	7ce2                	ld	s9,56(sp)
    slub_port_spin_unlock(&c->lock, &f);
}
ffffffffc0203208:	60aa                	ld	ra,136(sp)
ffffffffc020320a:	74e6                	ld	s1,120(sp)
ffffffffc020320c:	79a6                	ld	s3,104(sp)
ffffffffc020320e:	6ae6                	ld	s5,88(sp)
ffffffffc0203210:	6149                	addi	sp,sp,144
ffffffffc0203212:	8082                	ret
ffffffffc0203214:	e8da                	sd	s6,80(sp)
ffffffffc0203216:	e0e2                	sd	s8,64(sp)
ffffffffc0203218:	fc66                	sd	s9,56(sp)
    unsigned int i = 0;
ffffffffc020321a:	4801                	li	a6,0
ffffffffc020321c:	00499b13          	slli	s6,s3,0x4
ffffffffc0203220:	413b0b33          	sub	s6,s6,s3
ffffffffc0203224:	0b0e                	slli	s6,s6,0x3
    unsigned long s = read_csr(sstatus);
ffffffffc0203226:	10002cf3          	csrr	s9,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc020322a:	002cf793          	andi	a5,s9,2
ffffffffc020322e:	e83e                	sd	a5,16(sp)
    if (*flags) {
ffffffffc0203230:	e6078be3          	beqz	a5,ffffffffc02030a6 <slub_put_objects+0x1e8>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0203234:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0203238:	b5bd                	j	ffffffffc02030a6 <slub_put_objects+0x1e8>
            slub_slab_destroy(c, s);
ffffffffc020323a:	85aa                	mv	a1,a0
ffffffffc020323c:	6522                	ld	a0,8(sp)
ffffffffc020323e:	ac7ff0ef          	jal	ffffffffc0202d04 <slub_slab_destroy>
ffffffffc0203242:	b709                	j	ffffffffc0203144 <slub_put_objects+0x286>
    struct slub_slab **pp = &c->partial;
ffffffffc0203244:	67e2                	ld	a5,24(sp)
ffffffffc0203246:	078e                	slli	a5,a5,0x3
ffffffffc0203248:	97e2                	add	a5,a5,s8
    while (*pp != NULL && *pp != s) pp = &(*pp)->next;
ffffffffc020324a:	6f9c                	ld	a5,24(a5)
ffffffffc020324c:	cb99                	beqz	a5,ffffffffc0203262 <slub_put_objects+0x3a4>
    struct slub_slab **pp = &c->partial;
ffffffffc020324e:	018b0693          	addi	a3,s6,24
ffffffffc0203252:	96e2                	add	a3,a3,s8
    while (*pp != NULL && *pp != s) pp = &(*pp)->next;
ffffffffc0203254:	629c                	ld	a5,0(a3)
ffffffffc0203256:	02f50363          	beq	a0,a5,ffffffffc020327c <slub_put_objects+0x3be>
ffffffffc020325a:	02878693          	addi	a3,a5,40
ffffffffc020325e:	779c                	ld	a5,40(a5)
ffffffffc0203260:	fbfd                	bnez	a5,ffffffffc0203256 <slub_put_objects+0x398>
        slub_port_panic("slub: partial slab %lx is not linked",
ffffffffc0203262:	86c2                	mv	a3,a6
ffffffffc0203264:	00005617          	auipc	a2,0x5
ffffffffc0203268:	5cc60613          	addi	a2,a2,1484 # ffffffffc0208830 <etext+0x15b4>
ffffffffc020326c:	1a700593          	li	a1,423
ffffffffc0203270:	00005517          	auipc	a0,0x5
ffffffffc0203274:	4b050513          	addi	a0,a0,1200 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0203278:	f59fc0ef          	jal	ffffffffc02001d0 <__panic>
    c->nr_partial--;
ffffffffc020327c:	00499793          	slli	a5,s3,0x4
ffffffffc0203280:	413787b3          	sub	a5,a5,s3
ffffffffc0203284:	078e                	slli	a5,a5,0x3
    *pp = s->next;
ffffffffc0203286:	750c                	ld	a1,40(a0)
    c->nr_partial--;
ffffffffc0203288:	97e2                	add	a5,a5,s8
ffffffffc020328a:	5790                	lw	a2,40(a5)
    *pp = s->next;
ffffffffc020328c:	e28c                	sd	a1,0(a3)
    s->next = NULL;
ffffffffc020328e:	02053423          	sd	zero,40(a0)
    c->nr_partial--;
ffffffffc0203292:	fff6069b          	addiw	a3,a2,-1
ffffffffc0203296:	d794                	sw	a3,40(a5)
}
ffffffffc0203298:	bd41                	j	ffffffffc0203128 <slub_put_objects+0x26a>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc020329a:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020329e:	b795                	j	ffffffffc0203202 <slub_put_objects+0x344>
    if (i > n) i = n;
ffffffffc02032a0:	8e42                	mv	t3,a6
ffffffffc02032a2:	bb85                	j	ffffffffc0203012 <slub_put_objects+0x154>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc02032a4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02032a8:	bb05                	j	ffffffffc0202fd8 <slub_put_objects+0x11a>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc02032aa:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02032ae:	bbd1                	j	ffffffffc0203082 <slub_put_objects+0x1c4>
    __sync_synchronize(); /* release */
ffffffffc02032b0:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc02032b4:	0310000f          	fence	rw,w
ffffffffc02032b8:	00052023          	sw	zero,0(a0)
    __sync_synchronize();
ffffffffc02032bc:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02032c0:	fe0f95e3          	bnez	t6,ffffffffc02032aa <slub_put_objects+0x3ec>
ffffffffc02032c4:	640a                	ld	s0,128(sp)
ffffffffc02032c6:	e8da                	sd	s6,80(sp)
ffffffffc02032c8:	e0e2                	sd	s8,64(sp)
ffffffffc02032ca:	fc66                	sd	s9,56(sp)
ffffffffc02032cc:	bf81                	j	ffffffffc020321c <slub_put_objects+0x35e>
        slub_port_panic("slub: object %lx does not belong to class %lu",
ffffffffc02032ce:	874e                	mv	a4,s3
ffffffffc02032d0:	86ea                	mv	a3,s10
ffffffffc02032d2:	00005617          	auipc	a2,0x5
ffffffffc02032d6:	4ce60613          	addi	a2,a2,1230 # ffffffffc02087a0 <etext+0x1524>
ffffffffc02032da:	23900593          	li	a1,569
ffffffffc02032de:	00005517          	auipc	a0,0x5
ffffffffc02032e2:	44250513          	addi	a0,a0,1090 # ffffffffc0208720 <etext+0x14a4>
ffffffffc02032e6:	eebfc0ef          	jal	ffffffffc02001d0 <__panic>
        slub_port_panic("slub: object %lx is not at a slot boundary",
ffffffffc02032ea:	86ea                	mv	a3,s10
ffffffffc02032ec:	00005617          	auipc	a2,0x5
ffffffffc02032f0:	4e460613          	addi	a2,a2,1252 # ffffffffc02087d0 <etext+0x1554>
ffffffffc02032f4:	23d00593          	li	a1,573
ffffffffc02032f8:	00005517          	auipc	a0,0x5
ffffffffc02032fc:	42850513          	addi	a0,a0,1064 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0203300:	ed1fc0ef          	jal	ffffffffc02001d0 <__panic>
        slub_port_panic("slub: object %lx comes from an empty slab",
ffffffffc0203304:	86ea                	mv	a3,s10
ffffffffc0203306:	00005617          	auipc	a2,0x5
ffffffffc020330a:	4fa60613          	addi	a2,a2,1274 # ffffffffc0208800 <etext+0x1584>
ffffffffc020330e:	24100593          	li	a1,577
ffffffffc0203312:	00005517          	auipc	a0,0x5
ffffffffc0203316:	40e50513          	addi	a0,a0,1038 # ffffffffc0208720 <etext+0x14a4>
ffffffffc020331a:	eb7fc0ef          	jal	ffffffffc02001d0 <__panic>
        slub_port_panic("slub: cpu id %lu >= SLUB_NCPUS %d (build with a "
ffffffffc020331e:	0000a697          	auipc	a3,0xa
ffffffffc0203322:	ce26e683          	lwu	a3,-798(a3) # ffffffffc020d000 <boot_hartid>
ffffffffc0203326:	4705                	li	a4,1
ffffffffc0203328:	00005617          	auipc	a2,0x5
ffffffffc020332c:	43060613          	addi	a2,a2,1072 # ffffffffc0208758 <etext+0x14dc>
ffffffffc0203330:	0e500593          	li	a1,229
ffffffffc0203334:	00005517          	auipc	a0,0x5
ffffffffc0203338:	3ec50513          	addi	a0,a0,1004 # ffffffffc0208720 <etext+0x14a4>
ffffffffc020333c:	e122                	sd	s0,128(sp)
ffffffffc020333e:	f8ca                	sd	s2,112(sp)
ffffffffc0203340:	f0d2                	sd	s4,96(sp)
ffffffffc0203342:	e8da                	sd	s6,80(sp)
ffffffffc0203344:	e4de                	sd	s7,72(sp)
ffffffffc0203346:	e0e2                	sd	s8,64(sp)
ffffffffc0203348:	fc66                	sd	s9,56(sp)
ffffffffc020334a:	f86a                	sd	s10,48(sp)
ffffffffc020334c:	f46e                	sd	s11,40(sp)
ffffffffc020334e:	e83fc0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0203352 <slub_alloc_small>:
    if (cpu >= SLUB_NCPUS) {
ffffffffc0203352:	0000a797          	auipc	a5,0xa
ffffffffc0203356:	cae7a783          	lw	a5,-850(a5) # ffffffffc020d000 <boot_hartid>

/* ------------------------- 分配 ------------------------- */

static void *slub_alloc_small(unsigned int cls) {
ffffffffc020335a:	7165                	addi	sp,sp,-400
ffffffffc020335c:	e706                	sd	ra,392(sp)
ffffffffc020335e:	e322                	sd	s0,384(sp)
    if (cpu >= SLUB_NCPUS) {
ffffffffc0203360:	6a079963          	bnez	a5,ffffffffc0203a12 <slub_alloc_small+0x6c0>
ffffffffc0203364:	8e2a                	mv	t3,a0
    unsigned long s = read_csr(sstatus);
ffffffffc0203366:	100026f3          	csrr	a3,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc020336a:	8a89                	andi	a3,a3,2
    if (*flags) {
ffffffffc020336c:	c299                	beqz	a3,ffffffffc0203372 <slub_alloc_small+0x20>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc020336e:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0203372:	0330000f          	fence	rw,rw
    unsigned int n;
    void *result;

    /* 快路径：本地 main/spare sheaf，仅本地临界区，不碰全局锁 */
    slub_port_local_lock(&f);
    if (slub_cc[cpu][cls].main.size != 0) {
ffffffffc0203376:	020e1313          	slli	t1,t3,0x20
ffffffffc020337a:	02035313          	srli	t1,t1,0x20
ffffffffc020337e:	00531713          	slli	a4,t1,0x5
ffffffffc0203382:	0001c797          	auipc	a5,0x1c
ffffffffc0203386:	9de78793          	addi	a5,a5,-1570 # ffffffffc021ed60 <slub_cc>
ffffffffc020338a:	97ba                	add	a5,a5,a4
ffffffffc020338c:	4798                	lw	a4,8(a5)
ffffffffc020338e:	2c071263          	bnez	a4,ffffffffc0203652 <slub_alloc_small+0x300>
        slub_cs[cpu][cls].alloc_fast++;
        slub_cs[cpu][cls].user++;
        slub_port_local_unlock(&f);
        return result;
    }
    if (slub_cc[cpu][cls].spare.size != 0) {
ffffffffc0203392:	4f98                	lw	a4,24(a5)
ffffffffc0203394:	24071363          	bnez	a4,ffffffffc02035da <slub_alloc_small+0x288>
    __sync_synchronize();
ffffffffc0203398:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc020339c:	c299                	beqz	a3,ffffffffc02033a2 <slub_alloc_small+0x50>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc020339e:	100167f3          	csrrsi	a5,sstatus,2
        return result;
    }
    slub_port_local_unlock(&f);

    /* 慢路径 1：批量从共享 barn 取（barn 锁） */
    n = slub_barn_take(cls, batch, c->sheaf_cap);
ffffffffc02033a2:	00431793          	slli	a5,t1,0x4
ffffffffc02033a6:	406787b3          	sub	a5,a5,t1
ffffffffc02033aa:	0001cf97          	auipc	t6,0x1c
ffffffffc02033ae:	bf6f8f93          	addi	t6,t6,-1034 # ffffffffc021efa0 <slub_caches>
ffffffffc02033b2:	078e                	slli	a5,a5,0x3
ffffffffc02033b4:	97fe                	add	a5,a5,t6
ffffffffc02033b6:	4790                	lw	a2,8(a5)
    unsigned long s = read_csr(sstatus);
ffffffffc02033b8:	10002f73          	csrr	t5,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc02033bc:	002f7f13          	andi	t5,t5,2
    if (*flags) {
ffffffffc02033c0:	100f1463          	bnez	t5,ffffffffc02034c8 <slub_alloc_small+0x176>
    __sync_synchronize();
ffffffffc02033c4:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc02033c8:	00231693          	slli	a3,t1,0x2
ffffffffc02033cc:	969a                	add	a3,a3,t1
ffffffffc02033ce:	068e                	slli	a3,a3,0x3
ffffffffc02033d0:	0001ce97          	auipc	t4,0x1c
ffffffffc02033d4:	a90e8e93          	addi	t4,t4,-1392 # ffffffffc021ee60 <slub_barns>
ffffffffc02033d8:	96f6                	add	a3,a3,t4
ffffffffc02033da:	4785                	li	a5,1
ffffffffc02033dc:	0cf6a7af          	amoswap.w.aq	a5,a5,(a3)
ffffffffc02033e0:	2781                	sext.w	a5,a5
ffffffffc02033e2:	ffe5                	bnez	a5,ffffffffc02033da <slub_alloc_small+0x88>
    __sync_synchronize(); /* acquire */
ffffffffc02033e4:	0330000f          	fence	rw,rw
    n = b->size;
ffffffffc02033e8:	00231793          	slli	a5,t1,0x2
ffffffffc02033ec:	979a                	add	a5,a5,t1
ffffffffc02033ee:	078e                	slli	a5,a5,0x3
ffffffffc02033f0:	97f6                	add	a5,a5,t4
ffffffffc02033f2:	4b88                	lw	a0,16(a5)
    if (n > want) n = want;
ffffffffc02033f4:	8732                	mv	a4,a2
ffffffffc02033f6:	0cc56463          	bltu	a0,a2,ffffffffc02034be <slub_alloc_small+0x16c>
ffffffffc02033fa:	0007061b          	sext.w	a2,a4
    for (k = 0; k < n; k++) out[k] = b->objs[b->size - n + k];
ffffffffc02033fe:	ca61                	beqz	a2,ffffffffc02034ce <slub_alloc_small+0x17c>
ffffffffc0203400:	00231793          	slli	a5,t1,0x2
ffffffffc0203404:	979a                	add	a5,a5,t1
ffffffffc0203406:	078e                	slli	a5,a5,0x3
ffffffffc0203408:	97f6                	add	a5,a5,t4
ffffffffc020340a:	40e50fbb          	subw	t6,a0,a4
ffffffffc020340e:	0087b803          	ld	a6,8(a5)
ffffffffc0203412:	008c                	addi	a1,sp,64
ffffffffc0203414:	87fe                	mv	a5,t6
ffffffffc0203416:	02079893          	slli	a7,a5,0x20
ffffffffc020341a:	01d8d713          	srli	a4,a7,0x1d
ffffffffc020341e:	9742                	add	a4,a4,a6
ffffffffc0203420:	6318                	ld	a4,0(a4)
ffffffffc0203422:	2785                	addiw	a5,a5,1
ffffffffc0203424:	05a1                	addi	a1,a1,8
ffffffffc0203426:	fee5bc23          	sd	a4,-8(a1)
ffffffffc020342a:	fef516e3          	bne	a0,a5,ffffffffc0203416 <slub_alloc_small+0xc4>
    b->size -= n;
ffffffffc020342e:	00231793          	slli	a5,t1,0x2
ffffffffc0203432:	979a                	add	a5,a5,t1
ffffffffc0203434:	078e                	slli	a5,a5,0x3
ffffffffc0203436:	9ebe                	add	t4,t4,a5
    if (n != 0) b->stat_get += n;
ffffffffc0203438:	018eb783          	ld	a5,24(t4)
ffffffffc020343c:	02061713          	slli	a4,a2,0x20
ffffffffc0203440:	9301                	srli	a4,a4,0x20
ffffffffc0203442:	97ba                	add	a5,a5,a4
    b->size -= n;
ffffffffc0203444:	01fea823          	sw	t6,16(t4)
    if (n != 0) b->stat_get += n;
ffffffffc0203448:	00febc23          	sd	a5,24(t4)
    __sync_synchronize(); /* release */
ffffffffc020344c:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0203450:	0310000f          	fence	rw,w
ffffffffc0203454:	0006a023          	sw	zero,0(a3)
    __sync_synchronize();
ffffffffc0203458:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc020345c:	000f0463          	beqz	t5,ffffffffc0203464 <slub_alloc_small+0x112>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0203460:	100167f3          	csrrsi	a5,sstatus,2
    /* 慢路径 2：slab 层补充（cache 锁，可能新建 slab 走页分配器） */
    if (n == 0) n = slub_slab_refill(cls, batch, c->sheaf_cap);
    if (n == 0) return NULL;

    result = batch[0];
    if (n > 1) slub_put_objects(cls, batch + 1, n - 1, SLUB_PUT_ALL);
ffffffffc0203464:	4785                	li	a5,1
    result = batch[0];
ffffffffc0203466:	6406                	ld	s0,64(sp)
    if (n > 1) slub_put_objects(cls, batch + 1, n - 1, SLUB_PUT_ALL);
ffffffffc0203468:	00f60a63          	beq	a2,a5,ffffffffc020347c <slub_alloc_small+0x12a>
ffffffffc020346c:	367d                	addiw	a2,a2,-1
ffffffffc020346e:	8572                	mv	a0,t3
ffffffffc0203470:	4681                	li	a3,0
ffffffffc0203472:	00ac                	addi	a1,sp,72
ffffffffc0203474:	e41a                	sd	t1,8(sp)
ffffffffc0203476:	a49ff0ef          	jal	ffffffffc0202ebe <slub_put_objects>
ffffffffc020347a:	6322                	ld	t1,8(sp)
    unsigned long s = read_csr(sstatus);
ffffffffc020347c:	100027f3          	csrr	a5,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0203480:	8b89                	andi	a5,a5,2
    if (*flags) {
ffffffffc0203482:	1a078063          	beqz	a5,ffffffffc0203622 <slub_alloc_small+0x2d0>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0203486:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc020348a:	0330000f          	fence	rw,rw

    slub_port_local_lock(&f);
    slub_cs[cpu][cls].alloc_slow++;
ffffffffc020348e:	00231713          	slli	a4,t1,0x2
ffffffffc0203492:	971a                	add	a4,a4,t1
ffffffffc0203494:	070e                	slli	a4,a4,0x3
ffffffffc0203496:	0001b797          	auipc	a5,0x1b
ffffffffc020349a:	78a78793          	addi	a5,a5,1930 # ffffffffc021ec20 <slub_cs>
ffffffffc020349e:	97ba                	add	a5,a5,a4
ffffffffc02034a0:	6794                	ld	a3,8(a5)
    slub_cs[cpu][cls].user++;
ffffffffc02034a2:	7398                	ld	a4,32(a5)
    slub_cs[cpu][cls].alloc_slow++;
ffffffffc02034a4:	0685                	addi	a3,a3,1
    slub_cs[cpu][cls].user++;
ffffffffc02034a6:	0705                	addi	a4,a4,1
    slub_cs[cpu][cls].alloc_slow++;
ffffffffc02034a8:	e794                	sd	a3,8(a5)
    slub_cs[cpu][cls].user++;
ffffffffc02034aa:	f398                	sd	a4,32(a5)
    __sync_synchronize();
ffffffffc02034ac:	0330000f          	fence	rw,rw
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc02034b0:	100167f3          	csrrsi	a5,sstatus,2
    slub_port_local_unlock(&f);
    return result;
}
ffffffffc02034b4:	60ba                	ld	ra,392(sp)
ffffffffc02034b6:	8522                	mv	a0,s0
ffffffffc02034b8:	641a                	ld	s0,384(sp)
ffffffffc02034ba:	6159                	addi	sp,sp,400
ffffffffc02034bc:	8082                	ret
    if (n > want) n = want;
ffffffffc02034be:	872a                	mv	a4,a0
ffffffffc02034c0:	0007061b          	sext.w	a2,a4
    for (k = 0; k < n; k++) out[k] = b->objs[b->size - n + k];
ffffffffc02034c4:	fe15                	bnez	a2,ffffffffc0203400 <slub_alloc_small+0xae>
ffffffffc02034c6:	a021                	j	ffffffffc02034ce <slub_alloc_small+0x17c>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc02034c8:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02034cc:	bde5                	j	ffffffffc02033c4 <slub_alloc_small+0x72>
ffffffffc02034ce:	eed6                	sd	s5,344(sp)
    __sync_synchronize(); /* release */
ffffffffc02034d0:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc02034d4:	0310000f          	fence	rw,w
ffffffffc02034d8:	0006a023          	sw	zero,0(a3)
    __sync_synchronize();
ffffffffc02034dc:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02034e0:	180f1f63          	bnez	t5,ffffffffc020367e <slub_alloc_small+0x32c>
    if (n == 0) n = slub_slab_refill(cls, batch, c->sheaf_cap);
ffffffffc02034e4:	00431793          	slli	a5,t1,0x4
ffffffffc02034e8:	406787b3          	sub	a5,a5,t1
ffffffffc02034ec:	078e                	slli	a5,a5,0x3
ffffffffc02034ee:	97fe                	add	a5,a5,t6
ffffffffc02034f0:	0087a803          	lw	a6,8(a5)
    unsigned long s = read_csr(sstatus);
ffffffffc02034f4:	100027f3          	csrr	a5,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc02034f8:	8b89                	andi	a5,a5,2
ffffffffc02034fa:	8abe                	mv	s5,a5
    if (*flags) {
ffffffffc02034fc:	c399                	beqz	a5,ffffffffc0203502 <slub_alloc_small+0x1b0>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc02034fe:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0203502:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0203506:	00431e93          	slli	t4,t1,0x4
ffffffffc020350a:	406e8eb3          	sub	t4,t4,t1
ffffffffc020350e:	0e8e                	slli	t4,t4,0x3
ffffffffc0203510:	0ed1                	addi	t4,t4,20
ffffffffc0203512:	9efe                	add	t4,t4,t6
ffffffffc0203514:	4605                	li	a2,1
ffffffffc0203516:	0ccea62f          	amoswap.w.aq	a2,a2,(t4)
ffffffffc020351a:	2601                	sext.w	a2,a2
ffffffffc020351c:	fe65                	bnez	a2,ffffffffc0203514 <slub_alloc_small+0x1c2>
    __sync_synchronize(); /* acquire */
ffffffffc020351e:	0330000f          	fence	rw,rw
    while (got < want) {
ffffffffc0203522:	4c080b63          	beqz	a6,ffffffffc02039f8 <slub_alloc_small+0x6a6>
        if (c->partial != NULL) {
ffffffffc0203526:	00431793          	slli	a5,t1,0x4
ffffffffc020352a:	406787b3          	sub	a5,a5,t1
ffffffffc020352e:	00379893          	slli	a7,a5,0x3
ffffffffc0203532:	eada                	sd	s6,336(sp)
ffffffffc0203534:	98fe                	add	a7,a7,t6
ffffffffc0203536:	8b3e                	mv	s6,a5
            s->state = SLUB_SLAB_PARTIAL;
ffffffffc0203538:	4289                	li	t0,2
ffffffffc020353a:	04010f13          	addi	t5,sp,64
        if (c->partial != NULL) {
ffffffffc020353e:	0188b703          	ld	a4,24(a7)
ffffffffc0203542:	22070d63          	beqz	a4,ffffffffc020377c <slub_alloc_small+0x42a>
            c->partial = s->next;
ffffffffc0203546:	7714                	ld	a3,40(a4)
            c->nr_partial--;
ffffffffc0203548:	0288a783          	lw	a5,40(a7)
            c->partial = s->next;
ffffffffc020354c:	00d8bc23          	sd	a3,24(a7)
            s->next = NULL;
ffffffffc0203550:	02073423          	sd	zero,40(a4)
            c->nr_partial--;
ffffffffc0203554:	37fd                	addiw	a5,a5,-1
ffffffffc0203556:	02f8a423          	sw	a5,40(a7)
        if (s->freelist == NULL) {
ffffffffc020355a:	731c                	ld	a5,32(a4)
        while (got < want && s->freelist != NULL) {
ffffffffc020355c:	25067063          	bgeu	a2,a6,ffffffffc020379c <slub_alloc_small+0x44a>
ffffffffc0203560:	02061693          	slli	a3,a2,0x20
ffffffffc0203564:	01d6d593          	srli	a1,a3,0x1d
ffffffffc0203568:	95fa                	add	a1,a1,t5
ffffffffc020356a:	cf91                	beqz	a5,ffffffffc0203586 <slub_alloc_small+0x234>
            s->inuse++;
ffffffffc020356c:	4f14                	lw	a3,24(a4)
            s->freelist = *(void **)obj;
ffffffffc020356e:	6388                	ld	a0,0(a5)
            out[got++] = obj;
ffffffffc0203570:	e19c                	sd	a5,0(a1)
            s->inuse++;
ffffffffc0203572:	0016879b          	addiw	a5,a3,1
            s->freelist = *(void **)obj;
ffffffffc0203576:	f308                	sd	a0,32(a4)
            out[got++] = obj;
ffffffffc0203578:	2605                	addiw	a2,a2,1
            s->inuse++;
ffffffffc020357a:	cf1c                	sw	a5,24(a4)
        while (got < want && s->freelist != NULL) {
ffffffffc020357c:	05a1                	addi	a1,a1,8
ffffffffc020357e:	10c80363          	beq	a6,a2,ffffffffc0203684 <slub_alloc_small+0x332>
ffffffffc0203582:	87aa                	mv	a5,a0
ffffffffc0203584:	f7e5                	bnez	a5,ffffffffc020356c <slub_alloc_small+0x21a>
            s->state = SLUB_SLAB_FULL;
ffffffffc0203586:	4785                	li	a5,1
ffffffffc0203588:	00f70ea3          	sb	a5,29(a4)
            c->nr_full++;
ffffffffc020358c:	0308a783          	lw	a5,48(a7)
ffffffffc0203590:	2785                	addiw	a5,a5,1
ffffffffc0203592:	02f8a823          	sw	a5,48(a7)
    while (got < want) {
ffffffffc0203596:	fb0664e3          	bltu	a2,a6,ffffffffc020353e <slub_alloc_small+0x1ec>
    c->inuse_objs += got;
ffffffffc020359a:	00431793          	slli	a5,t1,0x4
ffffffffc020359e:	406787b3          	sub	a5,a5,t1
ffffffffc02035a2:	078e                	slli	a5,a5,0x3
ffffffffc02035a4:	9fbe                	add	t6,t6,a5
ffffffffc02035a6:	040fb683          	ld	a3,64(t6)
    c->stat_refill += got;
ffffffffc02035aa:	048fb703          	ld	a4,72(t6)
    c->inuse_objs += got;
ffffffffc02035ae:	02061793          	slli	a5,a2,0x20
ffffffffc02035b2:	9381                	srli	a5,a5,0x20
ffffffffc02035b4:	96be                	add	a3,a3,a5
    c->stat_refill += got;
ffffffffc02035b6:	97ba                	add	a5,a5,a4
    c->inuse_objs += got;
ffffffffc02035b8:	04dfb023          	sd	a3,64(t6)
    c->stat_refill += got;
ffffffffc02035bc:	04ffb423          	sd	a5,72(t6)
    __sync_synchronize(); /* release */
ffffffffc02035c0:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc02035c4:	0310000f          	fence	rw,w
ffffffffc02035c8:	000ea023          	sw	zero,0(t4)
    __sync_synchronize();
ffffffffc02035cc:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02035d0:	180a9e63          	bnez	s5,ffffffffc020376c <slub_alloc_small+0x41a>
ffffffffc02035d4:	6af6                	ld	s5,344(sp)
ffffffffc02035d6:	6b56                	ld	s6,336(sp)
ffffffffc02035d8:	b571                	j	ffffffffc0203464 <slub_alloc_small+0x112>
        slub_cs[cpu][cls].alloc_fast++;
ffffffffc02035da:	00231593          	slli	a1,t1,0x2
ffffffffc02035de:	959a                	add	a1,a1,t1
ffffffffc02035e0:	058e                	slli	a1,a1,0x3
ffffffffc02035e2:	0001b617          	auipc	a2,0x1b
ffffffffc02035e6:	63e60613          	addi	a2,a2,1598 # ffffffffc021ec20 <slub_cs>
ffffffffc02035ea:	962e                	add	a2,a2,a1
ffffffffc02035ec:	00063803          	ld	a6,0(a2)
        slub_cs[cpu][cls].user++;
ffffffffc02035f0:	7208                	ld	a0,32(a2)
        result = slub_cc[cpu][cls].spare.objs[--slub_cc[cpu][cls].spare.size];
ffffffffc02035f2:	377d                	addiw	a4,a4,-1
ffffffffc02035f4:	6b8c                	ld	a1,16(a5)
ffffffffc02035f6:	02071313          	slli	t1,a4,0x20
ffffffffc02035fa:	01d35893          	srli	a7,t1,0x1d
        slub_cs[cpu][cls].alloc_fast++;
ffffffffc02035fe:	0805                	addi	a6,a6,1
        slub_cs[cpu][cls].user++;
ffffffffc0203600:	0505                	addi	a0,a0,1
        result = slub_cc[cpu][cls].spare.objs[--slub_cc[cpu][cls].spare.size];
ffffffffc0203602:	cf98                	sw	a4,24(a5)
ffffffffc0203604:	011587b3          	add	a5,a1,a7
        slub_cs[cpu][cls].alloc_fast++;
ffffffffc0203608:	01063023          	sd	a6,0(a2)
        slub_cs[cpu][cls].user++;
ffffffffc020360c:	f208                	sd	a0,32(a2)
        result = slub_cc[cpu][cls].spare.objs[--slub_cc[cpu][cls].spare.size];
ffffffffc020360e:	6380                	ld	s0,0(a5)
    __sync_synchronize();
ffffffffc0203610:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0203614:	e8069ee3          	bnez	a3,ffffffffc02034b0 <slub_alloc_small+0x15e>
}
ffffffffc0203618:	60ba                	ld	ra,392(sp)
ffffffffc020361a:	8522                	mv	a0,s0
ffffffffc020361c:	641a                	ld	s0,384(sp)
ffffffffc020361e:	6159                	addi	sp,sp,400
ffffffffc0203620:	8082                	ret
    __sync_synchronize();
ffffffffc0203622:	0330000f          	fence	rw,rw
    slub_cs[cpu][cls].alloc_slow++;
ffffffffc0203626:	00231713          	slli	a4,t1,0x2
ffffffffc020362a:	971a                	add	a4,a4,t1
ffffffffc020362c:	070e                	slli	a4,a4,0x3
ffffffffc020362e:	0001b797          	auipc	a5,0x1b
ffffffffc0203632:	5f278793          	addi	a5,a5,1522 # ffffffffc021ec20 <slub_cs>
ffffffffc0203636:	97ba                	add	a5,a5,a4
ffffffffc0203638:	6794                	ld	a3,8(a5)
    slub_cs[cpu][cls].user++;
ffffffffc020363a:	7398                	ld	a4,32(a5)
    slub_cs[cpu][cls].alloc_slow++;
ffffffffc020363c:	0685                	addi	a3,a3,1
    slub_cs[cpu][cls].user++;
ffffffffc020363e:	0705                	addi	a4,a4,1
    slub_cs[cpu][cls].alloc_slow++;
ffffffffc0203640:	e794                	sd	a3,8(a5)
    slub_cs[cpu][cls].user++;
ffffffffc0203642:	f398                	sd	a4,32(a5)
    __sync_synchronize();
ffffffffc0203644:	0330000f          	fence	rw,rw
}
ffffffffc0203648:	60ba                	ld	ra,392(sp)
ffffffffc020364a:	8522                	mv	a0,s0
ffffffffc020364c:	641a                	ld	s0,384(sp)
ffffffffc020364e:	6159                	addi	sp,sp,400
ffffffffc0203650:	8082                	ret
        slub_cs[cpu][cls].alloc_fast++;
ffffffffc0203652:	00231593          	slli	a1,t1,0x2
ffffffffc0203656:	959a                	add	a1,a1,t1
ffffffffc0203658:	058e                	slli	a1,a1,0x3
ffffffffc020365a:	0001b617          	auipc	a2,0x1b
ffffffffc020365e:	5c660613          	addi	a2,a2,1478 # ffffffffc021ec20 <slub_cs>
ffffffffc0203662:	962e                	add	a2,a2,a1
ffffffffc0203664:	00063803          	ld	a6,0(a2)
        slub_cs[cpu][cls].user++;
ffffffffc0203668:	7208                	ld	a0,32(a2)
        result = slub_cc[cpu][cls].main.objs[--slub_cc[cpu][cls].main.size];
ffffffffc020366a:	377d                	addiw	a4,a4,-1
ffffffffc020366c:	02071313          	slli	t1,a4,0x20
ffffffffc0203670:	638c                	ld	a1,0(a5)
ffffffffc0203672:	01d35893          	srli	a7,t1,0x1d
        slub_cs[cpu][cls].alloc_fast++;
ffffffffc0203676:	0805                	addi	a6,a6,1
        slub_cs[cpu][cls].user++;
ffffffffc0203678:	0505                	addi	a0,a0,1
        result = slub_cc[cpu][cls].main.objs[--slub_cc[cpu][cls].main.size];
ffffffffc020367a:	c798                	sw	a4,8(a5)
ffffffffc020367c:	b761                	j	ffffffffc0203604 <slub_alloc_small+0x2b2>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc020367e:	100167f3          	csrrsi	a5,sstatus,2
    if (n == 0) n = slub_slab_refill(cls, batch, c->sheaf_cap);
ffffffffc0203682:	b58d                	j	ffffffffc02034e4 <slub_alloc_small+0x192>
        if (s->freelist == NULL) {
ffffffffc0203684:	d109                	beqz	a0,ffffffffc0203586 <slub_alloc_small+0x234>
            s->state = SLUB_SLAB_PARTIAL;
ffffffffc0203686:	00570ea3          	sb	t0,29(a4)
            c->nr_partial++;
ffffffffc020368a:	0288a783          	lw	a5,40(a7)
            s->next = c->partial;
ffffffffc020368e:	0188b683          	ld	a3,24(a7)
            c->nr_partial++;
ffffffffc0203692:	2785                	addiw	a5,a5,1
            s->next = c->partial;
ffffffffc0203694:	f714                	sd	a3,40(a4)
            c->partial = s;
ffffffffc0203696:	00e8bc23          	sd	a4,24(a7)
            c->nr_partial++;
ffffffffc020369a:	02f8a423          	sw	a5,40(a7)
    while (got < want) {
ffffffffc020369e:	eb0660e3          	bltu	a2,a6,ffffffffc020353e <slub_alloc_small+0x1ec>
ffffffffc02036a2:	bde5                	j	ffffffffc020359a <slub_alloc_small+0x248>
    __sync_synchronize(); /* release */
ffffffffc02036a4:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc02036a8:	0310000f          	fence	rw,w
ffffffffc02036ac:	0005a023          	sw	zero,0(a1)
    __sync_synchronize();
ffffffffc02036b0:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02036b4:	c299                	beqz	a3,ffffffffc02036ba <slub_alloc_small+0x368>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc02036b6:	100167f3          	csrrsi	a5,sstatus,2
        slub_pages_free(pages, c->slab_pages);
ffffffffc02036ba:	00431793          	slli	a5,t1,0x4
ffffffffc02036be:	406787b3          	sub	a5,a5,t1
ffffffffc02036c2:	078e                	slli	a5,a5,0x3
ffffffffc02036c4:	97fe                	add	a5,a5,t6
ffffffffc02036c6:	0107e583          	lwu	a1,16(a5)
    unsigned long s = read_csr(sstatus);
ffffffffc02036ca:	10002473          	csrr	s0,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc02036ce:	8809                	andi	s0,s0,2
    if (*flags) {
ffffffffc02036d0:	c019                	beqz	s0,ffffffffc02036d6 <slub_alloc_small+0x384>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc02036d2:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc02036d6:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc02036da:	00024497          	auipc	s1,0x24
ffffffffc02036de:	14648493          	addi	s1,s1,326 # ffffffffc0227820 <slub_pmm_lock>
ffffffffc02036e2:	4785                	li	a5,1
ffffffffc02036e4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
ffffffffc02036e8:	2781                	sext.w	a5,a5
ffffffffc02036ea:	ffe5                	bnez	a5,ffffffffc02036e2 <slub_alloc_small+0x390>
ffffffffc02036ec:	f072                	sd	t3,32(sp)
ffffffffc02036ee:	ec1a                	sd	t1,24(sp)
ffffffffc02036f0:	e876                	sd	t4,16(sp)
ffffffffc02036f2:	e432                	sd	a2,8(sp)
    __sync_synchronize(); /* acquire */
ffffffffc02036f4:	0330000f          	fence	rw,rw
    free_pages(base, npages);
ffffffffc02036f8:	8552                	mv	a0,s4
ffffffffc02036fa:	9c0ff0ef          	jal	ffffffffc02028ba <free_pages>
    __sync_synchronize(); /* release */
ffffffffc02036fe:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0203702:	0310000f          	fence	rw,w
ffffffffc0203706:	0004a023          	sw	zero,0(s1)
    __sync_synchronize();
ffffffffc020370a:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc020370e:	0001cf97          	auipc	t6,0x1c
ffffffffc0203712:	892f8f93          	addi	t6,t6,-1902 # ffffffffc021efa0 <slub_caches>
ffffffffc0203716:	6622                	ld	a2,8(sp)
ffffffffc0203718:	6ec2                	ld	t4,16(sp)
ffffffffc020371a:	6362                	ld	t1,24(sp)
ffffffffc020371c:	7e02                	ld	t3,32(sp)
ffffffffc020371e:	c019                	beqz	s0,ffffffffc0203724 <slub_alloc_small+0x3d2>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0203720:	100167f3          	csrrsi	a5,sstatus,2
        c->stat_desc_fail++;
ffffffffc0203724:	00431793          	slli	a5,t1,0x4
ffffffffc0203728:	406787b3          	sub	a5,a5,t1
ffffffffc020372c:	078e                	slli	a5,a5,0x3
ffffffffc020372e:	97fe                	add	a5,a5,t6
ffffffffc0203730:	7bb8                	ld	a4,112(a5)
ffffffffc0203732:	74f6                	ld	s1,376(sp)
ffffffffc0203734:	0705                	addi	a4,a4,1
ffffffffc0203736:	fbb8                	sd	a4,112(a5)
    c->inuse_objs += got;
ffffffffc0203738:	00431793          	slli	a5,t1,0x4
ffffffffc020373c:	406787b3          	sub	a5,a5,t1
ffffffffc0203740:	078e                	slli	a5,a5,0x3
ffffffffc0203742:	97fe                	add	a5,a5,t6
ffffffffc0203744:	63ac                	ld	a1,64(a5)
    c->stat_refill += got;
ffffffffc0203746:	67b4                	ld	a3,72(a5)
    c->inuse_objs += got;
ffffffffc0203748:	02061713          	slli	a4,a2,0x20
ffffffffc020374c:	9301                	srli	a4,a4,0x20
ffffffffc020374e:	95ba                	add	a1,a1,a4
    c->stat_refill += got;
ffffffffc0203750:	9736                	add	a4,a4,a3
    c->inuse_objs += got;
ffffffffc0203752:	e3ac                	sd	a1,64(a5)
    c->stat_refill += got;
ffffffffc0203754:	e7b8                	sd	a4,72(a5)
    __sync_synchronize(); /* release */
ffffffffc0203756:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc020375a:	0310000f          	fence	rw,w
ffffffffc020375e:	000ea023          	sw	zero,0(t4)
    __sync_synchronize();
ffffffffc0203762:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0203766:	7a16                	ld	s4,352(sp)
ffffffffc0203768:	000a8463          	beqz	s5,ffffffffc0203770 <slub_alloc_small+0x41e>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc020376c:	100167f3          	csrrsi	a5,sstatus,2
    if (n == 0) return NULL;
ffffffffc0203770:	e60612e3          	bnez	a2,ffffffffc02035d4 <slub_alloc_small+0x282>
ffffffffc0203774:	6b56                	ld	s6,336(sp)
ffffffffc0203776:	6af6                	ld	s5,344(sp)
ffffffffc0203778:	4401                	li	s0,0
ffffffffc020377a:	bb2d                	j	ffffffffc02034b4 <slub_alloc_small+0x162>
        } else if (c->empty != NULL) {
ffffffffc020377c:	0208b703          	ld	a4,32(a7)
ffffffffc0203780:	cf05                	beqz	a4,ffffffffc02037b8 <slub_alloc_small+0x466>
            c->empty = s->next;
ffffffffc0203782:	7714                	ld	a3,40(a4)
            c->nr_empty--;
ffffffffc0203784:	02c8a783          	lw	a5,44(a7)
            c->empty = s->next;
ffffffffc0203788:	02d8b023          	sd	a3,32(a7)
            c->nr_empty--;
ffffffffc020378c:	37fd                	addiw	a5,a5,-1
            s->next = NULL;
ffffffffc020378e:	02073423          	sd	zero,40(a4)
            c->nr_empty--;
ffffffffc0203792:	02f8a623          	sw	a5,44(a7)
        if (s->freelist == NULL) {
ffffffffc0203796:	731c                	ld	a5,32(a4)
        while (got < want && s->freelist != NULL) {
ffffffffc0203798:	dd0664e3          	bltu	a2,a6,ffffffffc0203560 <slub_alloc_small+0x20e>
        if (s->freelist == NULL) {
ffffffffc020379c:	ee0795e3          	bnez	a5,ffffffffc0203686 <slub_alloc_small+0x334>
            c->nr_full++;
ffffffffc02037a0:	07800793          	li	a5,120
ffffffffc02037a4:	02f307b3          	mul	a5,t1,a5
            s->state = SLUB_SLAB_FULL;
ffffffffc02037a8:	4685                	li	a3,1
ffffffffc02037aa:	00d70ea3          	sb	a3,29(a4)
            c->nr_full++;
ffffffffc02037ae:	97fe                	add	a5,a5,t6
ffffffffc02037b0:	5b98                	lw	a4,48(a5)
ffffffffc02037b2:	2705                	addiw	a4,a4,1
ffffffffc02037b4:	db98                	sw	a4,48(a5)
    while (got < want) {
ffffffffc02037b6:	b3d5                	j	ffffffffc020359a <slub_alloc_small+0x248>
    pages = slub_pages_alloc(c->slab_pages);
ffffffffc02037b8:	003b1413          	slli	s0,s6,0x3
ffffffffc02037bc:	947e                	add	s0,s0,t6
ffffffffc02037be:	01046503          	lwu	a0,16(s0)
ffffffffc02037c2:	f2d2                	sd	s4,352(sp)
ffffffffc02037c4:	fc72                	sd	t3,56(sp)
ffffffffc02037c6:	f81a                	sd	t1,48(sp)
ffffffffc02037c8:	f446                	sd	a7,40(sp)
ffffffffc02037ca:	f076                	sd	t4,32(sp)
ffffffffc02037cc:	ec32                	sd	a2,24(sp)
ffffffffc02037ce:	e83a                	sd	a4,16(sp)
ffffffffc02037d0:	e442                	sd	a6,8(sp)
ffffffffc02037d2:	c08ff0ef          	jal	ffffffffc0202bda <slub_pages_alloc>
    if (pages == NULL) {
ffffffffc02037d6:	6822                	ld	a6,8(sp)
ffffffffc02037d8:	6742                	ld	a4,16(sp)
ffffffffc02037da:	6662                	ld	a2,24(sp)
ffffffffc02037dc:	7e82                	ld	t4,32(sp)
ffffffffc02037de:	78a2                	ld	a7,40(sp)
ffffffffc02037e0:	7342                	ld	t1,48(sp)
ffffffffc02037e2:	7e62                	ld	t3,56(sp)
    pages = slub_pages_alloc(c->slab_pages);
ffffffffc02037e4:	8a2a                	mv	s4,a0
    if (pages == NULL) {
ffffffffc02037e6:	0001bf97          	auipc	t6,0x1b
ffffffffc02037ea:	7baf8f93          	addi	t6,t6,1978 # ffffffffc021efa0 <slub_caches>
ffffffffc02037ee:	4289                	li	t0,2
ffffffffc02037f0:	04010f13          	addi	t5,sp,64
ffffffffc02037f4:	1e050e63          	beqz	a0,ffffffffc02039f0 <slub_alloc_small+0x69e>
ffffffffc02037f8:	fea6                	sd	s1,376(sp)
    unsigned long s = read_csr(sstatus);
ffffffffc02037fa:	100026f3          	csrr	a3,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc02037fe:	8a89                	andi	a3,a3,2
    if (*flags) {
ffffffffc0203800:	c299                	beqz	a3,ffffffffc0203806 <slub_alloc_small+0x4b4>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0203802:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0203806:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc020380a:	00024597          	auipc	a1,0x24
ffffffffc020380e:	01e58593          	addi	a1,a1,30 # ffffffffc0227828 <slub_index_lock>
ffffffffc0203812:	4785                	li	a5,1
ffffffffc0203814:	0cf5a7af          	amoswap.w.aq	a5,a5,(a1)
ffffffffc0203818:	2781                	sext.w	a5,a5
ffffffffc020381a:	ffe5                	bnez	a5,ffffffffc0203812 <slub_alloc_small+0x4c0>
    __sync_synchronize(); /* acquire */
ffffffffc020381c:	0330000f          	fence	rw,rw
    s = slub_pool_free;
ffffffffc0203820:	00024517          	auipc	a0,0x24
ffffffffc0203824:	01053503          	ld	a0,16(a0) # ffffffffc0227830 <slub_pool_free>
    if (s != NULL) slub_pool_free = s->next;
ffffffffc0203828:	e6050ee3          	beqz	a0,ffffffffc02036a4 <slub_alloc_small+0x352>
ffffffffc020382c:	7500                	ld	s0,40(a0)
ffffffffc020382e:	faca                	sd	s2,368(sp)
ffffffffc0203830:	f6ce                	sd	s3,360(sp)
ffffffffc0203832:	e6de                	sd	s7,328(sp)
ffffffffc0203834:	00024497          	auipc	s1,0x24
ffffffffc0203838:	fe84be23          	sd	s0,-4(s1) # ffffffffc0227830 <slub_pool_free>
    __sync_synchronize(); /* release */
ffffffffc020383c:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0203840:	0310000f          	fence	rw,w
ffffffffc0203844:	0005a023          	sw	zero,0(a1)
    __sync_synchronize();
ffffffffc0203848:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc020384c:	18069f63          	bnez	a3,ffffffffc02039ea <slub_alloc_small+0x698>
    cap = (unsigned int)((c->slab_pages * SLUB_PAGE_SIZE) / c->objsize);
ffffffffc0203850:	00431693          	slli	a3,t1,0x4
ffffffffc0203854:	406686b3          	sub	a3,a3,t1
ffffffffc0203858:	068e                	slli	a3,a3,0x3
ffffffffc020385a:	96fe                	add	a3,a3,t6
ffffffffc020385c:	4a80                	lw	s0,16(a3)
ffffffffc020385e:	6284                	ld	s1,0(a3)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203860:	ccccd6b7          	lui	a3,0xccccd
ffffffffc0203864:	00c4191b          	slliw	s2,s0,0xc
ffffffffc0203868:	1902                	slli	s2,s2,0x20
ffffffffc020386a:	02095913          	srli	s2,s2,0x20
    s->npages = c->slab_pages;
ffffffffc020386e:	c900                	sw	s0,16(a0)
    cap = (unsigned int)((c->slab_pages * SLUB_PAGE_SIZE) / c->objsize);
ffffffffc0203870:	02995433          	divu	s0,s2,s1
ffffffffc0203874:	ccd68693          	addi	a3,a3,-819 # ffffffffcccccccd <end+0xcaa5455>
ffffffffc0203878:	02069393          	slli	t2,a3,0x20
ffffffffc020387c:	00d389b3          	add	s3,t2,a3
ffffffffc0203880:	00024697          	auipc	a3,0x24
ffffffffc0203884:	f706b683          	ld	a3,-144(a3) # ffffffffc02277f0 <pages>
    s->pages = pages;
ffffffffc0203888:	01453423          	sd	s4,8(a0)
}

static inline void *slub_port_page_kva(slub_page_t *base) {
    /* 按真实映射关系访问物理页：VA = PA + va_pa_offset（勿解引用物理地址） */
    return (void *)(page2pa(base) + va_pa_offset);
ffffffffc020388c:	00024397          	auipc	t2,0x24
ffffffffc0203890:	f543b383          	ld	t2,-172(t2) # ffffffffc02277e0 <va_pa_offset>
ffffffffc0203894:	40da06b3          	sub	a3,s4,a3
ffffffffc0203898:	868d                	srai	a3,a3,0x3
ffffffffc020389a:	00006a17          	auipc	s4,0x6
ffffffffc020389e:	50ea3a03          	ld	s4,1294(s4) # ffffffffc0209da8 <nbase>
    s->inuse = 0;
ffffffffc02038a2:	00052c23          	sw	zero,24(a0)
    s->cls = (unsigned char)cls;
ffffffffc02038a6:	01c50e23          	sb	t3,28(a0)
    s->next = NULL;
ffffffffc02038aa:	02053423          	sd	zero,40(a0)
    s->freelist = NULL;
ffffffffc02038ae:	02053023          	sd	zero,32(a0)
ffffffffc02038b2:	033686b3          	mul	a3,a3,s3
    cap = (unsigned int)((c->slab_pages * SLUB_PAGE_SIZE) / c->objsize);
ffffffffc02038b6:	2401                	sext.w	s0,s0
    s->state = SLUB_SLAB_EMPTY; /* 尚未入链，由 refill 决定 PARTIAL/FULL */
ffffffffc02038b8:	498d                	li	s3,3
    s->capacity = cap;
ffffffffc02038ba:	c940                	sw	s0,20(a0)
    s->state = SLUB_SLAB_EMPTY; /* 尚未入链，由 refill 决定 PARTIAL/FULL */
ffffffffc02038bc:	01350ea3          	sb	s3,29(a0)
ffffffffc02038c0:	96d2                	add	a3,a3,s4
    return page2ppn(page) << PGSHIFT;
ffffffffc02038c2:	06b2                	slli	a3,a3,0xc
ffffffffc02038c4:	969e                	add	a3,a3,t2
    s->base = kva;
ffffffffc02038c6:	e114                	sd	a3,0(a0)
    for (i = 0; i < cap; i++) {
ffffffffc02038c8:	00996963          	bltu	s2,s1,ffffffffc02038da <slub_alloc_small+0x588>
        *(void **)obj = s->freelist;
ffffffffc02038cc:	e298                	sd	a4,0(a3)
    for (i = 0; i < cap; i++) {
ffffffffc02038ce:	2785                	addiw	a5,a5,1
        void *obj = (void *)(kva + (uintptr_t)i * c->objsize);
ffffffffc02038d0:	8736                	mv	a4,a3
    for (i = 0; i < cap; i++) {
ffffffffc02038d2:	96a6                	add	a3,a3,s1
ffffffffc02038d4:	fef41ce3          	bne	s0,a5,ffffffffc02038cc <slub_alloc_small+0x57a>
ffffffffc02038d8:	f118                	sd	a4,32(a0)
    unsigned long s = read_csr(sstatus);
ffffffffc02038da:	100027f3          	csrr	a5,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc02038de:	8b89                	andi	a5,a5,2
ffffffffc02038e0:	8bbe                	mv	s7,a5
    if (*flags) {
ffffffffc02038e2:	c399                	beqz	a5,ffffffffc02038e8 <slub_alloc_small+0x596>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc02038e4:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc02038e8:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc02038ec:	4705                	li	a4,1
ffffffffc02038ee:	0ce5a72f          	amoswap.w.aq	a4,a4,(a1)
ffffffffc02038f2:	2701                	sext.w	a4,a4
ffffffffc02038f4:	ff65                	bnez	a4,ffffffffc02038ec <slub_alloc_small+0x59a>
    __sync_synchronize(); /* acquire */
ffffffffc02038f6:	0330000f          	fence	rw,rw
    unsigned int lo = 0, hi = slub_index_nr, mid, i;
ffffffffc02038fa:	00024697          	auipc	a3,0x24
ffffffffc02038fe:	f326a683          	lw	a3,-206(a3) # ffffffffc022782c <slub_index_nr>
    if (slub_index_nr >= SLUB_MAX_SLABS) {
ffffffffc0203902:	3ff00793          	li	a5,1023
    unsigned int lo = 0, hi = slub_index_nr, mid, i;
ffffffffc0203906:	8a36                	mv	s4,a3
    if (slub_index_nr >= SLUB_MAX_SLABS) {
ffffffffc0203908:	12d7ed63          	bltu	a5,a3,ffffffffc0203a42 <slub_alloc_small+0x6f0>
    unsigned int lo = 0, hi = slub_index_nr, mid, i;
ffffffffc020390c:	8936                	mv	s2,a3
ffffffffc020390e:	0000a497          	auipc	s1,0xa
ffffffffc0203912:	31248493          	addi	s1,s1,786 # ffffffffc020dc20 <slub_index>
    while (lo < hi) {
ffffffffc0203916:	03277463          	bgeu	a4,s2,ffffffffc020393e <slub_alloc_small+0x5ec>
        mid = lo + (hi - lo) / 2;
ffffffffc020391a:	40e907bb          	subw	a5,s2,a4
ffffffffc020391e:	0017d79b          	srliw	a5,a5,0x1
ffffffffc0203922:	9fb9                	addw	a5,a5,a4
        if (slub_index[mid]->base < s->base)
ffffffffc0203924:	02079413          	slli	s0,a5,0x20
ffffffffc0203928:	01d45693          	srli	a3,s0,0x1d
ffffffffc020392c:	96a6                	add	a3,a3,s1
ffffffffc020392e:	6280                	ld	s0,0(a3)
ffffffffc0203930:	6114                	ld	a3,0(a0)
ffffffffc0203932:	6000                	ld	s0,0(s0)
ffffffffc0203934:	0ad46863          	bltu	s0,a3,ffffffffc02039e4 <slub_alloc_small+0x692>
            hi = mid;
ffffffffc0203938:	893e                	mv	s2,a5
    while (lo < hi) {
ffffffffc020393a:	ff2760e3          	bltu	a4,s2,ffffffffc020391a <slub_alloc_small+0x5c8>
    for (i = slub_index_nr; i > lo; i--) slub_index[i] = slub_index[i - 1];
ffffffffc020393e:	05477463          	bgeu	a4,s4,ffffffffc0203986 <slub_alloc_small+0x634>
ffffffffc0203942:	fffa079b          	addiw	a5,s4,-1
ffffffffc0203946:	40e7843b          	subw	s0,a5,a4
ffffffffc020394a:	1402                	slli	s0,s0,0x20
ffffffffc020394c:	1782                	slli	a5,a5,0x20
ffffffffc020394e:	9381                	srli	a5,a5,0x20
ffffffffc0203950:	9001                	srli	s0,s0,0x20
ffffffffc0203952:	020a1913          	slli	s2,s4,0x20
ffffffffc0203956:	40878433          	sub	s0,a5,s0
ffffffffc020395a:	0000a697          	auipc	a3,0xa
ffffffffc020395e:	2be68693          	addi	a3,a3,702 # ffffffffc020dc18 <free_lists+0x1f8>
ffffffffc0203962:	01d95393          	srli	t2,s2,0x1d
ffffffffc0203966:	040e                	slli	s0,s0,0x3
ffffffffc0203968:	00379913          	slli	s2,a5,0x3
ffffffffc020396c:	9436                	add	s0,s0,a3
ffffffffc020396e:	012487b3          	add	a5,s1,s2
ffffffffc0203972:	0007b983          	ld	s3,0(a5)
ffffffffc0203976:	412786b3          	sub	a3,a5,s2
ffffffffc020397a:	969e                	add	a3,a3,t2
ffffffffc020397c:	0136b023          	sd	s3,0(a3)
ffffffffc0203980:	17e1                	addi	a5,a5,-8
ffffffffc0203982:	fe8798e3          	bne	a5,s0,ffffffffc0203972 <slub_alloc_small+0x620>
    slub_index[lo] = s;
ffffffffc0203986:	02071693          	slli	a3,a4,0x20
ffffffffc020398a:	01d6d793          	srli	a5,a3,0x1d
ffffffffc020398e:	97a6                	add	a5,a5,s1
    slub_index_nr++;
ffffffffc0203990:	001a071b          	addiw	a4,s4,1
    slub_index[lo] = s;
ffffffffc0203994:	e388                	sd	a0,0(a5)
    slub_index_nr++;
ffffffffc0203996:	00024797          	auipc	a5,0x24
ffffffffc020399a:	e8e7ab23          	sw	a4,-362(a5) # ffffffffc022782c <slub_index_nr>
    __sync_synchronize(); /* release */
ffffffffc020399e:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc02039a2:	0310000f          	fence	rw,w
ffffffffc02039a6:	0005a023          	sw	zero,0(a1)
    __sync_synchronize();
ffffffffc02039aa:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02039ae:	000b8463          	beqz	s7,ffffffffc02039b6 <slub_alloc_small+0x664>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc02039b2:	100167f3          	csrrsi	a5,sstatus,2
    c->nr_slabs++;
ffffffffc02039b6:	00431793          	slli	a5,t1,0x4
ffffffffc02039ba:	406787b3          	sub	a5,a5,t1
ffffffffc02039be:	078e                	slli	a5,a5,0x3
ffffffffc02039c0:	97fe                	add	a5,a5,t6
ffffffffc02039c2:	5bd4                	lw	a3,52(a5)
    c->nr_slab_pages += c->slab_pages;
ffffffffc02039c4:	5f80                	lw	s0,56(a5)
ffffffffc02039c6:	4b8c                	lw	a1,16(a5)
    c->nr_slabs++;
ffffffffc02039c8:	2685                	addiw	a3,a3,1
ffffffffc02039ca:	dbd4                	sw	a3,52(a5)
    c->stat_slab_new++;
ffffffffc02039cc:	6fb4                	ld	a3,88(a5)
    c->nr_slab_pages += c->slab_pages;
ffffffffc02039ce:	9da1                	addw	a1,a1,s0
ffffffffc02039d0:	74f6                	ld	s1,376(sp)
    c->stat_slab_new++;
ffffffffc02039d2:	0685                	addi	a3,a3,1
ffffffffc02039d4:	7956                	ld	s2,368(sp)
ffffffffc02039d6:	79b6                	ld	s3,360(sp)
ffffffffc02039d8:	7a16                	ld	s4,352(sp)
ffffffffc02039da:	6bb6                	ld	s7,328(sp)
            s = slub_slab_create(c, cls);
ffffffffc02039dc:	872a                	mv	a4,a0
    c->nr_slab_pages += c->slab_pages;
ffffffffc02039de:	df8c                	sw	a1,56(a5)
    c->stat_slab_new++;
ffffffffc02039e0:	efb4                	sd	a3,88(a5)
            if (s == NULL) break; /* 页耗尽 / 描述符耗尽 */
ffffffffc02039e2:	bea5                	j	ffffffffc020355a <slub_alloc_small+0x208>
            lo = mid + 1;
ffffffffc02039e4:	0017871b          	addiw	a4,a5,1
ffffffffc02039e8:	b73d                	j	ffffffffc0203916 <slub_alloc_small+0x5c4>
ffffffffc02039ea:	100166f3          	csrrsi	a3,sstatus,2
    if (s == NULL) {
ffffffffc02039ee:	b58d                	j	ffffffffc0203850 <slub_alloc_small+0x4fe>
        c->stat_page_fail++;
ffffffffc02039f0:	743c                	ld	a5,104(s0)
ffffffffc02039f2:	0785                	addi	a5,a5,1
ffffffffc02039f4:	f43c                	sd	a5,104(s0)
            if (s == NULL) break; /* 页耗尽 / 描述符耗尽 */
ffffffffc02039f6:	b389                	j	ffffffffc0203738 <slub_alloc_small+0x3e6>
    __sync_synchronize(); /* release */
ffffffffc02039f8:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc02039fc:	0310000f          	fence	rw,w
ffffffffc0203a00:	000ea023          	sw	zero,0(t4)
    __sync_synchronize();
ffffffffc0203a04:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0203a08:	d60a87e3          	beqz	s5,ffffffffc0203776 <slub_alloc_small+0x424>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0203a0c:	100167f3          	csrrsi	a5,sstatus,2
    if (n == 0) return NULL;
ffffffffc0203a10:	b39d                	j	ffffffffc0203776 <slub_alloc_small+0x424>
        slub_port_panic("slub: cpu id %lu >= SLUB_NCPUS %d (build with a "
ffffffffc0203a12:	00009697          	auipc	a3,0x9
ffffffffc0203a16:	5ee6e683          	lwu	a3,1518(a3) # ffffffffc020d000 <boot_hartid>
ffffffffc0203a1a:	4705                	li	a4,1
ffffffffc0203a1c:	00005617          	auipc	a2,0x5
ffffffffc0203a20:	d3c60613          	addi	a2,a2,-708 # ffffffffc0208758 <etext+0x14dc>
ffffffffc0203a24:	0e500593          	li	a1,229
ffffffffc0203a28:	00005517          	auipc	a0,0x5
ffffffffc0203a2c:	cf850513          	addi	a0,a0,-776 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0203a30:	fea6                	sd	s1,376(sp)
ffffffffc0203a32:	faca                	sd	s2,368(sp)
ffffffffc0203a34:	f6ce                	sd	s3,360(sp)
ffffffffc0203a36:	f2d2                	sd	s4,352(sp)
ffffffffc0203a38:	eed6                	sd	s5,344(sp)
ffffffffc0203a3a:	eada                	sd	s6,336(sp)
ffffffffc0203a3c:	e6de                	sd	s7,328(sp)
ffffffffc0203a3e:	f92fc0ef          	jal	ffffffffc02001d0 <__panic>
        slub_port_panic("slub: slab registry overflow");
ffffffffc0203a42:	00005617          	auipc	a2,0x5
ffffffffc0203a46:	e1660613          	addi	a2,a2,-490 # ffffffffc0208858 <etext+0x15dc>
ffffffffc0203a4a:	14300593          	li	a1,323
ffffffffc0203a4e:	00005517          	auipc	a0,0x5
ffffffffc0203a52:	cd250513          	addi	a0,a0,-814 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0203a56:	f7afc0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0203a5a <slub_shrink.part.0>:
/*
 * 回收空闲内存：排空每 CPU sheaf 与共享 barn -> 归还空 slab 的页。
 * 前提：所有调用者静止（无并发 kmalloc/kfree，无对象正在跨 CPU 传递）。
 * 不释放仍被用户持有的对象；大对象保持不动（它们由用户持有）。
 */
void slub_shrink(void) {
ffffffffc0203a5a:	714d                	addi	sp,sp,-336
ffffffffc0203a5c:	e2a2                	sd	s0,320(sp)
ffffffffc0203a5e:	fe26                	sd	s1,312(sp)
ffffffffc0203a60:	fa4a                	sd	s2,304(sp)
ffffffffc0203a62:	f64e                	sd	s3,296(sp)
ffffffffc0203a64:	f252                	sd	s4,288(sp)
ffffffffc0203a66:	ee56                	sd	s5,280(sp)
ffffffffc0203a68:	e686                	sd	ra,328(sp)
ffffffffc0203a6a:	e65e                	sd	s7,264(sp)
ffffffffc0203a6c:	e262                	sd	s8,256(sp)
ffffffffc0203a6e:	0001b417          	auipc	s0,0x1b
ffffffffc0203a72:	53240413          	addi	s0,s0,1330 # ffffffffc021efa0 <slub_caches>
ffffffffc0203a76:	0001ba17          	auipc	s4,0x1b
ffffffffc0203a7a:	3eaa0a13          	addi	s4,s4,1002 # ffffffffc021ee60 <slub_barns>
ffffffffc0203a7e:	0001ba97          	auipc	s5,0x1b
ffffffffc0203a82:	2e2a8a93          	addi	s5,s5,738 # ffffffffc021ed60 <slub_cc>
    unsigned int cls, cpu;

    if (slub_inited == 0) return;

    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
ffffffffc0203a86:	4481                	li	s1,0
        /* 2) 共享 barn -> slab 层（分批，不经过 barn） */
        for (;;) {
            unsigned int k;
            slub_port_spin_lock(&b->lock, &f);
            k = b->size;
            if (k > SLUB_SHEAF_MAX_CAP) k = SLUB_SHEAF_MAX_CAP;
ffffffffc0203a88:	02000913          	li	s2,32
    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
ffffffffc0203a8c:	49a1                	li	s3,8
    unsigned long s = read_csr(sstatus);
ffffffffc0203a8e:	10002573          	csrr	a0,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0203a92:	8909                	andi	a0,a0,2
    if (*flags) {
ffffffffc0203a94:	10051d63          	bnez	a0,ffffffffc0203bae <slub_shrink.part.0+0x154>
    __sync_synchronize();
ffffffffc0203a98:	0330000f          	fence	rw,rw
    unsigned int n = sf->size, i;
ffffffffc0203a9c:	008aa603          	lw	a2,8(s5)
    for (i = 0; i < n; i++) out[i] = sf->objs[i];
ffffffffc0203aa0:	1c060763          	beqz	a2,ffffffffc0203c6e <slub_shrink.part.0+0x214>
ffffffffc0203aa4:	000ab783          	ld	a5,0(s5)
ffffffffc0203aa8:	02061713          	slli	a4,a2,0x20
ffffffffc0203aac:	01d75593          	srli	a1,a4,0x1d
ffffffffc0203ab0:	95be                	add	a1,a1,a5
ffffffffc0203ab2:	870a                	mv	a4,sp
ffffffffc0203ab4:	6394                	ld	a3,0(a5)
ffffffffc0203ab6:	07a1                	addi	a5,a5,8
ffffffffc0203ab8:	0721                	addi	a4,a4,8
ffffffffc0203aba:	fed73c23          	sd	a3,-8(a4)
ffffffffc0203abe:	feb79be3          	bne	a5,a1,ffffffffc0203ab4 <slub_shrink.part.0+0x5a>
    sf->size = 0;
ffffffffc0203ac2:	000aa423          	sw	zero,8(s5)
    __sync_synchronize();
ffffffffc0203ac6:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0203aca:	c119                	beqz	a0,ffffffffc0203ad0 <slub_shrink.part.0+0x76>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0203acc:	100167f3          	csrrsi	a5,sstatus,2
            if (n != 0) slub_put_objects(cls, batch, n, SLUB_PUT_SLAB);
ffffffffc0203ad0:	4685                	li	a3,1
ffffffffc0203ad2:	858a                	mv	a1,sp
ffffffffc0203ad4:	8526                	mv	a0,s1
ffffffffc0203ad6:	be8ff0ef          	jal	ffffffffc0202ebe <slub_put_objects>
    unsigned long s = read_csr(sstatus);
ffffffffc0203ada:	10002573          	csrr	a0,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0203ade:	8909                	andi	a0,a0,2
    if (*flags) {
ffffffffc0203ae0:	e95d                	bnez	a0,ffffffffc0203b96 <slub_shrink.part.0+0x13c>
    __sync_synchronize();
ffffffffc0203ae2:	0330000f          	fence	rw,rw
    unsigned int n = sf->size, i;
ffffffffc0203ae6:	018aa603          	lw	a2,24(s5)
    for (i = 0; i < n; i++) out[i] = sf->objs[i];
ffffffffc0203aea:	18060563          	beqz	a2,ffffffffc0203c74 <slub_shrink.part.0+0x21a>
ffffffffc0203aee:	010ab783          	ld	a5,16(s5)
ffffffffc0203af2:	02061713          	slli	a4,a2,0x20
ffffffffc0203af6:	01d75593          	srli	a1,a4,0x1d
ffffffffc0203afa:	95be                	add	a1,a1,a5
ffffffffc0203afc:	870a                	mv	a4,sp
ffffffffc0203afe:	6394                	ld	a3,0(a5)
ffffffffc0203b00:	07a1                	addi	a5,a5,8
ffffffffc0203b02:	0721                	addi	a4,a4,8
ffffffffc0203b04:	fed73c23          	sd	a3,-8(a4)
ffffffffc0203b08:	feb79be3          	bne	a5,a1,ffffffffc0203afe <slub_shrink.part.0+0xa4>
    sf->size = 0;
ffffffffc0203b0c:	000aac23          	sw	zero,24(s5)
    __sync_synchronize();
ffffffffc0203b10:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0203b14:	ed35                	bnez	a0,ffffffffc0203b90 <slub_shrink.part.0+0x136>
            if (n != 0) slub_put_objects(cls, batch, n, SLUB_PUT_SLAB);
ffffffffc0203b16:	4685                	li	a3,1
ffffffffc0203b18:	858a                	mv	a1,sp
ffffffffc0203b1a:	8526                	mv	a0,s1
ffffffffc0203b1c:	ba2ff0ef          	jal	ffffffffc0202ebe <slub_put_objects>
    unsigned long s = read_csr(sstatus);
ffffffffc0203b20:	100028f3          	csrr	a7,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0203b24:	0028f893          	andi	a7,a7,2
    if (*flags) {
ffffffffc0203b28:	00088463          	beqz	a7,ffffffffc0203b30 <slub_shrink.part.0+0xd6>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0203b2c:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0203b30:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0203b34:	4785                	li	a5,1
ffffffffc0203b36:	0cfa27af          	amoswap.w.aq	a5,a5,(s4)
ffffffffc0203b3a:	2781                	sext.w	a5,a5
ffffffffc0203b3c:	ffe5                	bnez	a5,ffffffffc0203b34 <slub_shrink.part.0+0xda>
    __sync_synchronize(); /* acquire */
ffffffffc0203b3e:	0330000f          	fence	rw,rw
            k = b->size;
ffffffffc0203b42:	010a2583          	lw	a1,16(s4)
            for (n = 0; n < k; n++) batch[n] = b->objs[b->size - k + n];
ffffffffc0203b46:	c1c9                	beqz	a1,ffffffffc0203bc8 <slub_shrink.part.0+0x16e>
            if (k > SLUB_SHEAF_MAX_CAP) k = SLUB_SHEAF_MAX_CAP;
ffffffffc0203b48:	0005861b          	sext.w	a2,a1
ffffffffc0203b4c:	00b97463          	bgeu	s2,a1,ffffffffc0203b54 <slub_shrink.part.0+0xfa>
ffffffffc0203b50:	02000613          	li	a2,32
            for (n = 0; n < k; n++) batch[n] = b->objs[b->size - k + n];
ffffffffc0203b54:	008a3503          	ld	a0,8(s4)
            b->size -= k;
ffffffffc0203b58:	9d91                	subw	a1,a1,a2
ffffffffc0203b5a:	868a                	mv	a3,sp
            for (n = 0; n < k; n++) batch[n] = b->objs[b->size - k + n];
ffffffffc0203b5c:	00b7873b          	addw	a4,a5,a1
ffffffffc0203b60:	02071813          	slli	a6,a4,0x20
ffffffffc0203b64:	01d85713          	srli	a4,a6,0x1d
ffffffffc0203b68:	972a                	add	a4,a4,a0
ffffffffc0203b6a:	6318                	ld	a4,0(a4)
ffffffffc0203b6c:	2785                	addiw	a5,a5,1
ffffffffc0203b6e:	06a1                	addi	a3,a3,8
ffffffffc0203b70:	fee6bc23          	sd	a4,-8(a3)
ffffffffc0203b74:	fec7e4e3          	bltu	a5,a2,ffffffffc0203b5c <slub_shrink.part.0+0x102>
            b->size -= k;
ffffffffc0203b78:	00ba2823          	sw	a1,16(s4)
    __sync_synchronize(); /* release */
ffffffffc0203b7c:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0203b80:	0310000f          	fence	rw,w
ffffffffc0203b84:	000a2023          	sw	zero,0(s4)
    __sync_synchronize();
ffffffffc0203b88:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0203b8c:	f80885e3          	beqz	a7,ffffffffc0203b16 <slub_shrink.part.0+0xbc>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0203b90:	100167f3          	csrrsi	a5,sstatus,2
            if (n != 0) slub_put_objects(cls, batch, n, SLUB_PUT_SLAB);
ffffffffc0203b94:	b749                	j	ffffffffc0203b16 <slub_shrink.part.0+0xbc>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0203b96:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0203b9a:	0330000f          	fence	rw,rw
    unsigned int n = sf->size, i;
ffffffffc0203b9e:	018aa603          	lw	a2,24(s5)
    for (i = 0; i < n; i++) out[i] = sf->objs[i];
ffffffffc0203ba2:	f631                	bnez	a2,ffffffffc0203aee <slub_shrink.part.0+0x94>
    __sync_synchronize();
ffffffffc0203ba4:	0330000f          	fence	rw,rw
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0203ba8:	100167f3          	csrrsi	a5,sstatus,2
            if (n != 0) slub_put_objects(cls, batch, n, SLUB_PUT_SLAB);
ffffffffc0203bac:	bf95                	j	ffffffffc0203b20 <slub_shrink.part.0+0xc6>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0203bae:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0203bb2:	0330000f          	fence	rw,rw
    unsigned int n = sf->size, i;
ffffffffc0203bb6:	008aa603          	lw	a2,8(s5)
    for (i = 0; i < n; i++) out[i] = sf->objs[i];
ffffffffc0203bba:	ee0615e3          	bnez	a2,ffffffffc0203aa4 <slub_shrink.part.0+0x4a>
    __sync_synchronize();
ffffffffc0203bbe:	0330000f          	fence	rw,rw
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0203bc2:	100167f3          	csrrsi	a5,sstatus,2
            if (n != 0) slub_put_objects(cls, batch, n, SLUB_PUT_SLAB);
ffffffffc0203bc6:	bf11                	j	ffffffffc0203ada <slub_shrink.part.0+0x80>
    __sync_synchronize(); /* release */
ffffffffc0203bc8:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0203bcc:	0310000f          	fence	rw,w
ffffffffc0203bd0:	000a2023          	sw	zero,0(s4)
    __sync_synchronize();
ffffffffc0203bd4:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0203bd8:	00088463          	beqz	a7,ffffffffc0203be0 <slub_shrink.part.0+0x186>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0203bdc:	100167f3          	csrrsi	a5,sstatus,2
    unsigned long s = read_csr(sstatus);
ffffffffc0203be0:	10002c73          	csrr	s8,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0203be4:	002c7c13          	andi	s8,s8,2
    if (*flags) {
ffffffffc0203be8:	000c0463          	beqz	s8,ffffffffc0203bf0 <slub_shrink.part.0+0x196>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0203bec:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0203bf0:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0203bf4:	01440b93          	addi	s7,s0,20
ffffffffc0203bf8:	4785                	li	a5,1
ffffffffc0203bfa:	0cfba7af          	amoswap.w.aq	a5,a5,(s7)
ffffffffc0203bfe:	2781                	sext.w	a5,a5
ffffffffc0203c00:	ffe5                	bnez	a5,ffffffffc0203bf8 <slub_shrink.part.0+0x19e>
    __sync_synchronize(); /* acquire */
ffffffffc0203c02:	0330000f          	fence	rw,rw

        /* 3) 归还所有空 slab；partial 链上的 slab 必然有活跃对象 */
        slub_port_spin_lock(&c->lock, &f);
        {
            struct slub_slab *s;
            for (s = c->partial; s != NULL; s = s->next) {
ffffffffc0203c06:	6c1c                	ld	a5,24(s0)
ffffffffc0203c08:	c38d                	beqz	a5,ffffffffc0203c2a <slub_shrink.part.0+0x1d0>
                slub_port_assert(s->inuse > 0);
ffffffffc0203c0a:	4f98                	lw	a4,24(a5)
ffffffffc0203c0c:	c73d                	beqz	a4,ffffffffc0203c7a <slub_shrink.part.0+0x220>
            for (s = c->partial; s != NULL; s = s->next) {
ffffffffc0203c0e:	779c                	ld	a5,40(a5)
ffffffffc0203c10:	ffed                	bnez	a5,ffffffffc0203c0a <slub_shrink.part.0+0x1b0>
            }
        }
        while (c->empty != NULL) {
ffffffffc0203c12:	700c                	ld	a1,32(s0)
ffffffffc0203c14:	cd89                	beqz	a1,ffffffffc0203c2e <slub_shrink.part.0+0x1d4>
            struct slub_slab *s = c->empty;
            c->empty = s->next;
ffffffffc0203c16:	7598                	ld	a4,40(a1)
            s->next = NULL;
            c->nr_empty--;
ffffffffc0203c18:	545c                	lw	a5,44(s0)
            slub_slab_destroy(c, s);
ffffffffc0203c1a:	8522                	mv	a0,s0
            c->empty = s->next;
ffffffffc0203c1c:	f018                	sd	a4,32(s0)
            s->next = NULL;
ffffffffc0203c1e:	0205b423          	sd	zero,40(a1)
            c->nr_empty--;
ffffffffc0203c22:	37fd                	addiw	a5,a5,-1
ffffffffc0203c24:	d45c                	sw	a5,44(s0)
            slub_slab_destroy(c, s);
ffffffffc0203c26:	8deff0ef          	jal	ffffffffc0202d04 <slub_slab_destroy>
        while (c->empty != NULL) {
ffffffffc0203c2a:	700c                	ld	a1,32(s0)
ffffffffc0203c2c:	f5ed                	bnez	a1,ffffffffc0203c16 <slub_shrink.part.0+0x1bc>
    __sync_synchronize(); /* release */
ffffffffc0203c2e:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0203c32:	0310000f          	fence	rw,w
ffffffffc0203c36:	000ba023          	sw	zero,0(s7)
    __sync_synchronize();
ffffffffc0203c3a:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0203c3e:	000c0463          	beqz	s8,ffffffffc0203c46 <slub_shrink.part.0+0x1ec>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0203c42:	100167f3          	csrrsi	a5,sstatus,2
    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
ffffffffc0203c46:	2485                	addiw	s1,s1,1
ffffffffc0203c48:	07840413          	addi	s0,s0,120
ffffffffc0203c4c:	028a0a13          	addi	s4,s4,40
ffffffffc0203c50:	020a8a93          	addi	s5,s5,32
ffffffffc0203c54:	e3349de3          	bne	s1,s3,ffffffffc0203a8e <slub_shrink.part.0+0x34>
        }
        slub_port_spin_unlock(&c->lock, &f);
    }
}
ffffffffc0203c58:	60b6                	ld	ra,328(sp)
ffffffffc0203c5a:	6416                	ld	s0,320(sp)
ffffffffc0203c5c:	74f2                	ld	s1,312(sp)
ffffffffc0203c5e:	7952                	ld	s2,304(sp)
ffffffffc0203c60:	79b2                	ld	s3,296(sp)
ffffffffc0203c62:	7a12                	ld	s4,288(sp)
ffffffffc0203c64:	6af2                	ld	s5,280(sp)
ffffffffc0203c66:	6bb2                	ld	s7,264(sp)
ffffffffc0203c68:	6c12                	ld	s8,256(sp)
ffffffffc0203c6a:	6171                	addi	sp,sp,336
ffffffffc0203c6c:	8082                	ret
    __sync_synchronize();
ffffffffc0203c6e:	0330000f          	fence	rw,rw
            if (n != 0) slub_put_objects(cls, batch, n, SLUB_PUT_SLAB);
ffffffffc0203c72:	b5a5                	j	ffffffffc0203ada <slub_shrink.part.0+0x80>
ffffffffc0203c74:	0330000f          	fence	rw,rw
            if (n != 0) slub_put_objects(cls, batch, n, SLUB_PUT_SLAB);
ffffffffc0203c78:	b565                	j	ffffffffc0203b20 <slub_shrink.part.0+0xc6>
                slub_port_assert(s->inuse > 0);
ffffffffc0203c7a:	00005697          	auipc	a3,0x5
ffffffffc0203c7e:	bfe68693          	addi	a3,a3,-1026 # ffffffffc0208878 <etext+0x15fc>
ffffffffc0203c82:	00004617          	auipc	a2,0x4
ffffffffc0203c86:	86660613          	addi	a2,a2,-1946 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0203c8a:	36700593          	li	a1,871
ffffffffc0203c8e:	00005517          	auipc	a0,0x5
ffffffffc0203c92:	a9250513          	addi	a0,a0,-1390 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0203c96:	ea5a                	sd	s6,272(sp)
ffffffffc0203c98:	d38fc0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0203c9c <kmalloc>:
    if (size == 0) return NULL;
ffffffffc0203c9c:	10050f63          	beqz	a0,ffffffffc0203dba <kmalloc+0x11e>
    if (slub_inited == 0) {
ffffffffc0203ca0:	00024797          	auipc	a5,0x24
ffffffffc0203ca4:	b787a783          	lw	a5,-1160(a5) # ffffffffc0227818 <slub_inited>
void *kmalloc(size_t size) {
ffffffffc0203ca8:	1101                	addi	sp,sp,-32
ffffffffc0203caa:	ec06                	sd	ra,24(sp)
ffffffffc0203cac:	872a                	mv	a4,a0
    if (slub_inited == 0) {
ffffffffc0203cae:	10078863          	beqz	a5,ffffffffc0203dbe <kmalloc+0x122>
    if (size == 0 || size > SLUB_MAX_SMALL_SIZE) return -1;
ffffffffc0203cb2:	fff50793          	addi	a5,a0,-1
ffffffffc0203cb6:	7ff00693          	li	a3,2047
ffffffffc0203cba:	0ef6e863          	bltu	a3,a5,ffffffffc0203daa <kmalloc+0x10e>
ffffffffc0203cbe:	00006797          	auipc	a5,0x6
ffffffffc0203cc2:	e4278793          	addi	a5,a5,-446 # ffffffffc0209b00 <slub_sizes>
    for (cls = 0; cls < (int)SLUB_NCLASSES; cls++) {
ffffffffc0203cc6:	4501                	li	a0,0
ffffffffc0203cc8:	4621                	li	a2,8
        if (size <= slub_sizes[cls]) return cls;
ffffffffc0203cca:	6394                	ld	a3,0(a5)
ffffffffc0203ccc:	0ce6f563          	bgeu	a3,a4,ffffffffc0203d96 <kmalloc+0xfa>
    for (cls = 0; cls < (int)SLUB_NCLASSES; cls++) {
ffffffffc0203cd0:	2505                	addiw	a0,a0,1
ffffffffc0203cd2:	07a1                	addi	a5,a5,8
ffffffffc0203cd4:	fec51be3          	bne	a0,a2,ffffffffc0203cca <kmalloc+0x2e>
    npages = (bytes + SLUB_PAGE_SIZE - 1) / SLUB_PAGE_SIZE; /* 无乘法 */
ffffffffc0203cd8:	6785                	lui	a5,0x1
ffffffffc0203cda:	07fd                	addi	a5,a5,31 # 101f <kern_entry-0xffffffffc01fefe1>
ffffffffc0203cdc:	973e                	add	a4,a4,a5
ffffffffc0203cde:	8331                	srli	a4,a4,0xc
    base = slub_pages_alloc(npages);
ffffffffc0203ce0:	853a                	mv	a0,a4
ffffffffc0203ce2:	e43a                	sd	a4,8(sp)
ffffffffc0203ce4:	ef7fe0ef          	jal	ffffffffc0202bda <slub_pages_alloc>
    if (base == NULL) return NULL;
ffffffffc0203ce8:	c569                	beqz	a0,ffffffffc0203db2 <kmalloc+0x116>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203cea:	00024697          	auipc	a3,0x24
ffffffffc0203cee:	b066b683          	ld	a3,-1274(a3) # ffffffffc02277f0 <pages>
ffffffffc0203cf2:	ccccd7b7          	lui	a5,0xccccd
ffffffffc0203cf6:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcaa5455>
ffffffffc0203cfa:	02079613          	slli	a2,a5,0x20
ffffffffc0203cfe:	40d506b3          	sub	a3,a0,a3
ffffffffc0203d02:	97b2                	add	a5,a5,a2
ffffffffc0203d04:	868d                	srai	a3,a3,0x3
ffffffffc0203d06:	02f686b3          	mul	a3,a3,a5
ffffffffc0203d0a:	00006597          	auipc	a1,0x6
ffffffffc0203d0e:	09e5b583          	ld	a1,158(a1) # ffffffffc0209da8 <nbase>
    return (void *)(page2pa(base) + va_pa_offset);
ffffffffc0203d12:	00024617          	auipc	a2,0x24
ffffffffc0203d16:	ace63603          	ld	a2,-1330(a2) # ffffffffc02277e0 <va_pa_offset>
    h->magic = SLUB_MAGIC_LARGE;
ffffffffc0203d1a:	00006797          	auipc	a5,0x6
ffffffffc0203d1e:	0867b783          	ld	a5,134(a5) # ffffffffc0209da0 <error_string+0x40>
    h->npages = npages;
ffffffffc0203d22:	6722                	ld	a4,8(sp)
ffffffffc0203d24:	96ae                	add	a3,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0203d26:	06b2                	slli	a3,a3,0xc
ffffffffc0203d28:	96b2                	add	a3,a3,a2
    h->base = base;
ffffffffc0203d2a:	e688                	sd	a0,8(a3)
    h->npages = npages;
ffffffffc0203d2c:	ea98                	sd	a4,16(a3)
    h->pad = 0;
ffffffffc0203d2e:	0006bc23          	sd	zero,24(a3)
    h->magic = SLUB_MAGIC_LARGE;
ffffffffc0203d32:	e29c                	sd	a5,0(a3)
    unsigned long s = read_csr(sstatus);
ffffffffc0203d34:	100025f3          	csrr	a1,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0203d38:	8989                	andi	a1,a1,2
    if (*flags) {
ffffffffc0203d3a:	e5ad                	bnez	a1,ffffffffc0203da4 <kmalloc+0x108>
    __sync_synchronize();
ffffffffc0203d3c:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0203d40:	00024617          	auipc	a2,0x24
ffffffffc0203d44:	ae060613          	addi	a2,a2,-1312 # ffffffffc0227820 <slub_pmm_lock>
ffffffffc0203d48:	4785                	li	a5,1
ffffffffc0203d4a:	0cf627af          	amoswap.w.aq	a5,a5,(a2)
ffffffffc0203d4e:	2781                	sext.w	a5,a5
ffffffffc0203d50:	ffe5                	bnez	a5,ffffffffc0203d48 <kmalloc+0xac>
    __sync_synchronize(); /* acquire */
ffffffffc0203d52:	0330000f          	fence	rw,rw
    slub_large_pages += npages;
ffffffffc0203d56:	00024517          	auipc	a0,0x24
ffffffffc0203d5a:	ab253503          	ld	a0,-1358(a0) # ffffffffc0227808 <slub_large_pages>
    slub_large_user++;
ffffffffc0203d5e:	00024797          	auipc	a5,0x24
ffffffffc0203d62:	ab27b783          	ld	a5,-1358(a5) # ffffffffc0227810 <slub_large_user>
    slub_large_pages += npages;
ffffffffc0203d66:	972a                	add	a4,a4,a0
    slub_large_user++;
ffffffffc0203d68:	0785                	addi	a5,a5,1
    slub_large_pages += npages;
ffffffffc0203d6a:	00024517          	auipc	a0,0x24
ffffffffc0203d6e:	a8e53f23          	sd	a4,-1378(a0) # ffffffffc0227808 <slub_large_pages>
    slub_large_user++;
ffffffffc0203d72:	00024717          	auipc	a4,0x24
ffffffffc0203d76:	a8f73f23          	sd	a5,-1378(a4) # ffffffffc0227810 <slub_large_user>
    __sync_synchronize(); /* release */
ffffffffc0203d7a:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0203d7e:	0310000f          	fence	rw,w
ffffffffc0203d82:	00062023          	sw	zero,0(a2)
    __sync_synchronize();
ffffffffc0203d86:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0203d8a:	e991                	bnez	a1,ffffffffc0203d9e <kmalloc+0x102>
}
ffffffffc0203d8c:	60e2                	ld	ra,24(sp)
    return (char *)h + SLUB_LARGE_HDR_SIZE; /* 页对齐 + 32 => 16 对齐 */
ffffffffc0203d8e:	02068513          	addi	a0,a3,32
}
ffffffffc0203d92:	6105                	addi	sp,sp,32
ffffffffc0203d94:	8082                	ret
ffffffffc0203d96:	60e2                	ld	ra,24(sp)
ffffffffc0203d98:	6105                	addi	sp,sp,32
    if (cls >= 0) return slub_alloc_small((unsigned int)cls);
ffffffffc0203d9a:	db8ff06f          	j	ffffffffc0203352 <slub_alloc_small>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0203d9e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0203da2:	b7ed                	j	ffffffffc0203d8c <kmalloc+0xf0>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0203da4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0203da8:	bf51                	j	ffffffffc0203d3c <kmalloc+0xa0>
    if (size > SIZE_MAX - SLUB_LARGE_HDR_SIZE) return NULL;
ffffffffc0203daa:	77fd                	lui	a5,0xfffff
ffffffffc0203dac:	1781                	addi	a5,a5,-32 # ffffffffffffefe0 <end+0x3fdd7768>
ffffffffc0203dae:	f2a7f5e3          	bgeu	a5,a0,ffffffffc0203cd8 <kmalloc+0x3c>
}
ffffffffc0203db2:	60e2                	ld	ra,24(sp)
    if (size == 0) return NULL;
ffffffffc0203db4:	4501                	li	a0,0
}
ffffffffc0203db6:	6105                	addi	sp,sp,32
ffffffffc0203db8:	8082                	ret
    if (size == 0) return NULL;
ffffffffc0203dba:	4501                	li	a0,0
}
ffffffffc0203dbc:	8082                	ret
        slub_port_panic("slub: kmalloc before slub_init");
ffffffffc0203dbe:	00005617          	auipc	a2,0x5
ffffffffc0203dc2:	aca60613          	addi	a2,a2,-1334 # ffffffffc0208888 <etext+0x160c>
ffffffffc0203dc6:	2cf00593          	li	a1,719
ffffffffc0203dca:	00005517          	auipc	a0,0x5
ffffffffc0203dce:	95650513          	addi	a0,a0,-1706 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0203dd2:	bfefc0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0203dd6 <kfree>:
    if (ptr == NULL) return; /* 契约：无操作 */
ffffffffc0203dd6:	20050d63          	beqz	a0,ffffffffc0203ff0 <kfree+0x21a>
    if (slub_inited == 0) {
ffffffffc0203dda:	00024797          	auipc	a5,0x24
ffffffffc0203dde:	a3e7a783          	lw	a5,-1474(a5) # ffffffffc0227818 <slub_inited>
void kfree(void *ptr) {
ffffffffc0203de2:	7179                	addi	sp,sp,-48
ffffffffc0203de4:	f406                	sd	ra,40(sp)
    if (slub_inited == 0) {
ffffffffc0203de6:	26078463          	beqz	a5,ffffffffc020404e <kfree+0x278>
    if (((uintptr_t)ptr & (SLUB_MIN_ALIGN - 1)) != 0) {
ffffffffc0203dea:	00f57793          	andi	a5,a0,15
ffffffffc0203dee:	86aa                	mv	a3,a0
ffffffffc0203df0:	24079263          	bnez	a5,ffffffffc0204034 <kfree+0x25e>
ffffffffc0203df4:	e42a                	sd	a0,8(sp)
    s = slub_slab_lookup(ptr);
ffffffffc0203df6:	e7ffe0ef          	jal	ffffffffc0202c74 <slub_slab_lookup>
    if (s != NULL) {
ffffffffc0203dfa:	66a2                	ld	a3,8(sp)
ffffffffc0203dfc:	c54d                	beqz	a0,ffffffffc0203ea6 <kfree+0xd0>
        unsigned int cls = s->cls;
ffffffffc0203dfe:	01c54603          	lbu	a2,28(a0)
        if (((uintptr_t)ptr - s->base) % slub_caches[cls].objsize != 0) {
ffffffffc0203e02:	6118                	ld	a4,0(a0)
ffffffffc0203e04:	0001b597          	auipc	a1,0x1b
ffffffffc0203e08:	19c58593          	addi	a1,a1,412 # ffffffffc021efa0 <slub_caches>
ffffffffc0203e0c:	02061793          	slli	a5,a2,0x20
ffffffffc0203e10:	9381                	srli	a5,a5,0x20
        unsigned int cls = s->cls;
ffffffffc0203e12:	0006051b          	sext.w	a0,a2
        if (((uintptr_t)ptr - s->base) % slub_caches[cls].objsize != 0) {
ffffffffc0203e16:	00479613          	slli	a2,a5,0x4
ffffffffc0203e1a:	8e1d                	sub	a2,a2,a5
ffffffffc0203e1c:	060e                	slli	a2,a2,0x3
ffffffffc0203e1e:	95b2                	add	a1,a1,a2
ffffffffc0203e20:	6190                	ld	a2,0(a1)
ffffffffc0203e22:	40e68733          	sub	a4,a3,a4
ffffffffc0203e26:	02c77733          	remu	a4,a4,a2
ffffffffc0203e2a:	24071f63          	bnez	a4,ffffffffc0204088 <kfree+0x2b2>
    if (cpu >= SLUB_NCPUS) {
ffffffffc0203e2e:	00009717          	auipc	a4,0x9
ffffffffc0203e32:	1d272703          	lw	a4,466(a4) # ffffffffc020d000 <boot_hartid>
ffffffffc0203e36:	ec36                	sd	a3,24(sp)
ffffffffc0203e38:	22071763          	bnez	a4,ffffffffc0204066 <kfree+0x290>
    unsigned long s = read_csr(sstatus);
ffffffffc0203e3c:	100028f3          	csrr	a7,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0203e40:	0028f893          	andi	a7,a7,2
    if (*flags) {
ffffffffc0203e44:	00088463          	beqz	a7,ffffffffc0203e4c <kfree+0x76>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0203e48:	10017773          	csrrci	a4,sstatus,2
    __sync_synchronize();
ffffffffc0203e4c:	0330000f          	fence	rw,rw
    slub_cs[cpu][cls].user--;
ffffffffc0203e50:	00279713          	slli	a4,a5,0x2
ffffffffc0203e54:	973e                	add	a4,a4,a5
ffffffffc0203e56:	070e                	slli	a4,a4,0x3
ffffffffc0203e58:	0001b697          	auipc	a3,0x1b
ffffffffc0203e5c:	dc868693          	addi	a3,a3,-568 # ffffffffc021ec20 <slub_cs>
ffffffffc0203e60:	96ba                	add	a3,a3,a4
ffffffffc0203e62:	7290                	ld	a2,32(a3)
    if (slub_cc[cpu][cls].main.size < slub_cc[cpu][cls].main.cap) {
ffffffffc0203e64:	0001b717          	auipc	a4,0x1b
ffffffffc0203e68:	efc70713          	addi	a4,a4,-260 # ffffffffc021ed60 <slub_cc>
ffffffffc0203e6c:	0796                	slli	a5,a5,0x5
ffffffffc0203e6e:	97ba                	add	a5,a5,a4
ffffffffc0203e70:	478c                	lw	a1,8(a5)
ffffffffc0203e72:	00c7a803          	lw	a6,12(a5)
    slub_cs[cpu][cls].user--;
ffffffffc0203e76:	fff60713          	addi	a4,a2,-1
ffffffffc0203e7a:	f298                	sd	a4,32(a3)
    if (slub_cc[cpu][cls].main.size < slub_cc[cpu][cls].main.cap) {
ffffffffc0203e7c:	0705e963          	bltu	a1,a6,ffffffffc0203eee <kfree+0x118>
    if (slub_cc[cpu][cls].spare.size < slub_cc[cpu][cls].spare.cap) {
ffffffffc0203e80:	4f98                	lw	a4,24(a5)
ffffffffc0203e82:	4fd0                	lw	a2,28(a5)
ffffffffc0203e84:	16c76763          	bltu	a4,a2,ffffffffc0203ff2 <kfree+0x21c>
    slub_cs[cpu][cls].free_slow++;
ffffffffc0203e88:	6e9c                	ld	a5,24(a3)
ffffffffc0203e8a:	0785                	addi	a5,a5,1
ffffffffc0203e8c:	ee9c                	sd	a5,24(a3)
    __sync_synchronize();
ffffffffc0203e8e:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0203e92:	04089b63          	bnez	a7,ffffffffc0203ee8 <kfree+0x112>
    slub_put_objects(cls, &ptr, 1, SLUB_PUT_ALL);
ffffffffc0203e96:	4681                	li	a3,0
ffffffffc0203e98:	4605                	li	a2,1
ffffffffc0203e9a:	082c                	addi	a1,sp,24
ffffffffc0203e9c:	822ff0ef          	jal	ffffffffc0202ebe <slub_put_objects>
}
ffffffffc0203ea0:	70a2                	ld	ra,40(sp)
ffffffffc0203ea2:	6145                	addi	sp,sp,48
ffffffffc0203ea4:	8082                	ret
static inline size_t slub_port_nr_free_pages(void) {
    return nr_free_pages();
}

static inline void *slub_port_ram_low(void) {
    return (void *)(nbase * (size_t)PGSIZE + va_pa_offset);
ffffffffc0203ea6:	00006817          	auipc	a6,0x6
ffffffffc0203eaa:	f0283803          	ld	a6,-254(a6) # ffffffffc0209da8 <nbase>
ffffffffc0203eae:	00024717          	auipc	a4,0x24
ffffffffc0203eb2:	93273703          	ld	a4,-1742(a4) # ffffffffc02277e0 <va_pa_offset>
ffffffffc0203eb6:	00c81793          	slli	a5,a6,0xc
ffffffffc0203eba:	97ba                	add	a5,a5,a4
    return a >= (uintptr_t)slub_port_ram_low() &&
ffffffffc0203ebc:	00f6ea63          	bltu	a3,a5,ffffffffc0203ed0 <kfree+0xfa>
}

static inline void *slub_port_ram_high(void) {
    return (void *)(npage * (size_t)PGSIZE + va_pa_offset);
ffffffffc0203ec0:	00024617          	auipc	a2,0x24
ffffffffc0203ec4:	92863603          	ld	a2,-1752(a2) # ffffffffc02277e8 <npage>
ffffffffc0203ec8:	0632                	slli	a2,a2,0xc
ffffffffc0203eca:	963a                	add	a2,a2,a4
ffffffffc0203ecc:	04c6e863          	bltu	a3,a2,ffffffffc0203f1c <kfree+0x146>
        slub_port_panic("slub: kfree(%lx): pointer outside RAM",
ffffffffc0203ed0:	00005617          	auipc	a2,0x5
ffffffffc0203ed4:	a5060613          	addi	a2,a2,-1456 # ffffffffc0208920 <etext+0x16a4>
ffffffffc0203ed8:	32f00593          	li	a1,815
ffffffffc0203edc:	00005517          	auipc	a0,0x5
ffffffffc0203ee0:	84450513          	addi	a0,a0,-1980 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0203ee4:	aecfc0ef          	jal	ffffffffc02001d0 <__panic>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0203ee8:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0203eec:	b76d                	j	ffffffffc0203e96 <kfree+0xc0>
        slub_cc[cpu][cls].main.objs[slub_cc[cpu][cls].main.size++] = ptr;
ffffffffc0203eee:	6390                	ld	a2,0(a5)
        slub_cs[cpu][cls].free_fast++;
ffffffffc0203ef0:	6a98                	ld	a4,16(a3)
        slub_cc[cpu][cls].main.objs[slub_cc[cpu][cls].main.size++] = ptr;
ffffffffc0203ef2:	6562                	ld	a0,24(sp)
ffffffffc0203ef4:	02059313          	slli	t1,a1,0x20
ffffffffc0203ef8:	01d35813          	srli	a6,t1,0x1d
ffffffffc0203efc:	2585                	addiw	a1,a1,1
ffffffffc0203efe:	c78c                	sw	a1,8(a5)
ffffffffc0203f00:	9642                	add	a2,a2,a6
        slub_cs[cpu][cls].free_fast++;
ffffffffc0203f02:	00170793          	addi	a5,a4,1
        slub_cc[cpu][cls].main.objs[slub_cc[cpu][cls].main.size++] = ptr;
ffffffffc0203f06:	e208                	sd	a0,0(a2)
        slub_cs[cpu][cls].free_fast++;
ffffffffc0203f08:	ea9c                	sd	a5,16(a3)
    __sync_synchronize();
ffffffffc0203f0a:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0203f0e:	f80889e3          	beqz	a7,ffffffffc0203ea0 <kfree+0xca>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0203f12:	100167f3          	csrrsi	a5,sstatus,2
}
ffffffffc0203f16:	70a2                	ld	ra,40(sp)
ffffffffc0203f18:	6145                	addi	sp,sp,48
ffffffffc0203f1a:	8082                	ret
        (uintptr_t)ptr < (uintptr_t)slub_port_ram_low() + SLUB_LARGE_HDR_SIZE) {
ffffffffc0203f1c:	02078793          	addi	a5,a5,32
    if (!slub_ptr_in_ram(ptr) ||
ffffffffc0203f20:	faf6e8e3          	bltu	a3,a5,ffffffffc0203ed0 <kfree+0xfa>
    if (h->magic != SLUB_MAGIC_LARGE) {
ffffffffc0203f24:	29a637b7          	lui	a5,0x29a63
ffffffffc0203f28:	aa178793          	addi	a5,a5,-1375 # 29a62aa1 <kern_entry-0xffffffff9679d55f>
ffffffffc0203f2c:	4c524637          	lui	a2,0x4c524
ffffffffc0203f30:	fe06b583          	ld	a1,-32(a3)
ffffffffc0203f34:	1786                	slli	a5,a5,0x21
ffffffffc0203f36:	74760613          	addi	a2,a2,1863 # 4c524747 <kern_entry-0xffffffff73cdb8b9>
ffffffffc0203f3a:	97b2                	add	a5,a5,a2
ffffffffc0203f3c:	16f59263          	bne	a1,a5,ffffffffc02040a0 <kfree+0x2ca>
    if ((uintptr_t)slub_port_page_kva(h->base) + SLUB_LARGE_HDR_SIZE != a ||
ffffffffc0203f40:	fe86b503          	ld	a0,-24(a3)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203f44:	00024797          	auipc	a5,0x24
ffffffffc0203f48:	8ac7b783          	ld	a5,-1876(a5) # ffffffffc02277f0 <pages>
ffffffffc0203f4c:	ccccd637          	lui	a2,0xccccd
ffffffffc0203f50:	ccd60613          	addi	a2,a2,-819 # ffffffffcccccccd <end+0xcaa5455>
ffffffffc0203f54:	02061593          	slli	a1,a2,0x20
ffffffffc0203f58:	40f507b3          	sub	a5,a0,a5
ffffffffc0203f5c:	962e                	add	a2,a2,a1
ffffffffc0203f5e:	878d                	srai	a5,a5,0x3
ffffffffc0203f60:	02c787b3          	mul	a5,a5,a2
ffffffffc0203f64:	02070713          	addi	a4,a4,32
ffffffffc0203f68:	97c2                	add	a5,a5,a6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203f6a:	07b2                	slli	a5,a5,0xc
ffffffffc0203f6c:	97ba                	add	a5,a5,a4
ffffffffc0203f6e:	0af69763          	bne	a3,a5,ffffffffc020401c <kfree+0x246>
        h->npages == 0) {
ffffffffc0203f72:	ff06b583          	ld	a1,-16(a3)
    if ((uintptr_t)slub_port_page_kva(h->base) + SLUB_LARGE_HDR_SIZE != a ||
ffffffffc0203f76:	c1dd                	beqz	a1,ffffffffc020401c <kfree+0x246>
    h->magic = 0; /* 释放后置空：重复释放会被上面的魔数检查抓到 */
ffffffffc0203f78:	fe06b023          	sd	zero,-32(a3)
    unsigned long s = read_csr(sstatus);
ffffffffc0203f7c:	100026f3          	csrr	a3,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0203f80:	8a89                	andi	a3,a3,2
    if (*flags) {
ffffffffc0203f82:	c299                	beqz	a3,ffffffffc0203f88 <kfree+0x1b2>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0203f84:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0203f88:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0203f8c:	00024717          	auipc	a4,0x24
ffffffffc0203f90:	89470713          	addi	a4,a4,-1900 # ffffffffc0227820 <slub_pmm_lock>
ffffffffc0203f94:	4785                	li	a5,1
ffffffffc0203f96:	0cf727af          	amoswap.w.aq	a5,a5,(a4)
ffffffffc0203f9a:	2781                	sext.w	a5,a5
ffffffffc0203f9c:	ffe5                	bnez	a5,ffffffffc0203f94 <kfree+0x1be>
ffffffffc0203f9e:	e436                	sd	a3,8(sp)
    __sync_synchronize(); /* acquire */
ffffffffc0203fa0:	0330000f          	fence	rw,rw
    slub_large_pages -= npages;
ffffffffc0203fa4:	00024617          	auipc	a2,0x24
ffffffffc0203fa8:	86463603          	ld	a2,-1948(a2) # ffffffffc0227808 <slub_large_pages>
    slub_large_user--;
ffffffffc0203fac:	00024797          	auipc	a5,0x24
ffffffffc0203fb0:	8647b783          	ld	a5,-1948(a5) # ffffffffc0227810 <slub_large_user>
    slub_large_pages -= npages;
ffffffffc0203fb4:	8e0d                	sub	a2,a2,a1
    slub_large_user--;
ffffffffc0203fb6:	17fd                	addi	a5,a5,-1
    slub_large_pages -= npages;
ffffffffc0203fb8:	00024817          	auipc	a6,0x24
ffffffffc0203fbc:	84c83823          	sd	a2,-1968(a6) # ffffffffc0227808 <slub_large_pages>
    slub_large_user--;
ffffffffc0203fc0:	00024617          	auipc	a2,0x24
ffffffffc0203fc4:	84f63823          	sd	a5,-1968(a2) # ffffffffc0227810 <slub_large_user>
    free_pages(base, npages);
ffffffffc0203fc8:	8f3fe0ef          	jal	ffffffffc02028ba <free_pages>
    __sync_synchronize(); /* release */
ffffffffc0203fcc:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0203fd0:	00024717          	auipc	a4,0x24
ffffffffc0203fd4:	85070713          	addi	a4,a4,-1968 # ffffffffc0227820 <slub_pmm_lock>
ffffffffc0203fd8:	0310000f          	fence	rw,w
ffffffffc0203fdc:	00072023          	sw	zero,0(a4)
    __sync_synchronize();
ffffffffc0203fe0:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0203fe4:	66a2                	ld	a3,8(sp)
ffffffffc0203fe6:	ea068de3          	beqz	a3,ffffffffc0203ea0 <kfree+0xca>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0203fea:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0203fee:	b725                	j	ffffffffc0203f16 <kfree+0x140>
ffffffffc0203ff0:	8082                	ret
        slub_cc[cpu][cls].spare.objs[slub_cc[cpu][cls].spare.size++] = ptr;
ffffffffc0203ff2:	6b8c                	ld	a1,16(a5)
        slub_cs[cpu][cls].free_fast++;
ffffffffc0203ff4:	6a90                	ld	a2,16(a3)
        slub_cc[cpu][cls].spare.objs[slub_cc[cpu][cls].spare.size++] = ptr;
ffffffffc0203ff6:	6562                	ld	a0,24(sp)
ffffffffc0203ff8:	02071313          	slli	t1,a4,0x20
ffffffffc0203ffc:	01d35813          	srli	a6,t1,0x1d
ffffffffc0204000:	2705                	addiw	a4,a4,1
ffffffffc0204002:	cf98                	sw	a4,24(a5)
ffffffffc0204004:	95c2                	add	a1,a1,a6
        slub_cs[cpu][cls].free_fast++;
ffffffffc0204006:	00160793          	addi	a5,a2,1
        slub_cc[cpu][cls].spare.objs[slub_cc[cpu][cls].spare.size++] = ptr;
ffffffffc020400a:	e188                	sd	a0,0(a1)
        slub_cs[cpu][cls].free_fast++;
ffffffffc020400c:	ea9c                	sd	a5,16(a3)
    __sync_synchronize();
ffffffffc020400e:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0204012:	e80887e3          	beqz	a7,ffffffffc0203ea0 <kfree+0xca>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0204016:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020401a:	bdf5                	j	ffffffffc0203f16 <kfree+0x140>
        slub_port_panic("slub: kfree(%lx): corrupt large object header",
ffffffffc020401c:	00005617          	auipc	a2,0x5
ffffffffc0204020:	98460613          	addi	a2,a2,-1660 # ffffffffc02089a0 <etext+0x1724>
ffffffffc0204024:	30000593          	li	a1,768
ffffffffc0204028:	00004517          	auipc	a0,0x4
ffffffffc020402c:	6f850513          	addi	a0,a0,1784 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0204030:	9a0fc0ef          	jal	ffffffffc02001d0 <__panic>
        slub_port_panic("slub: kfree(%lx): not %d-byte aligned",
ffffffffc0204034:	4741                	li	a4,16
ffffffffc0204036:	00005617          	auipc	a2,0x5
ffffffffc020403a:	89260613          	addi	a2,a2,-1902 # ffffffffc02088c8 <etext+0x164c>
ffffffffc020403e:	31700593          	li	a1,791
ffffffffc0204042:	00004517          	auipc	a0,0x4
ffffffffc0204046:	6de50513          	addi	a0,a0,1758 # ffffffffc0208720 <etext+0x14a4>
ffffffffc020404a:	986fc0ef          	jal	ffffffffc02001d0 <__panic>
        slub_port_panic("slub: kfree before slub_init");
ffffffffc020404e:	00005617          	auipc	a2,0x5
ffffffffc0204052:	85a60613          	addi	a2,a2,-1958 # ffffffffc02088a8 <etext+0x162c>
ffffffffc0204056:	31400593          	li	a1,788
ffffffffc020405a:	00004517          	auipc	a0,0x4
ffffffffc020405e:	6c650513          	addi	a0,a0,1734 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0204062:	96efc0ef          	jal	ffffffffc02001d0 <__panic>
        slub_port_panic("slub: cpu id %lu >= SLUB_NCPUS %d (build with a "
ffffffffc0204066:	00009697          	auipc	a3,0x9
ffffffffc020406a:	f9a6e683          	lwu	a3,-102(a3) # ffffffffc020d000 <boot_hartid>
ffffffffc020406e:	4705                	li	a4,1
ffffffffc0204070:	00004617          	auipc	a2,0x4
ffffffffc0204074:	6e860613          	addi	a2,a2,1768 # ffffffffc0208758 <etext+0x14dc>
ffffffffc0204078:	0e500593          	li	a1,229
ffffffffc020407c:	00004517          	auipc	a0,0x4
ffffffffc0204080:	6a450513          	addi	a0,a0,1700 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0204084:	94cfc0ef          	jal	ffffffffc02001d0 <__panic>
            slub_port_panic("slub: kfree(%lx): not a slot start of its slab",
ffffffffc0204088:	00005617          	auipc	a2,0x5
ffffffffc020408c:	86860613          	addi	a2,a2,-1944 # ffffffffc02088f0 <etext+0x1674>
ffffffffc0204090:	32500593          	li	a1,805
ffffffffc0204094:	00004517          	auipc	a0,0x4
ffffffffc0204098:	68c50513          	addi	a0,a0,1676 # ffffffffc0208720 <etext+0x14a4>
ffffffffc020409c:	934fc0ef          	jal	ffffffffc02001d0 <__panic>
        slub_port_panic("slub: kfree(%lx): no slab and no valid large header "
ffffffffc02040a0:	00005617          	auipc	a2,0x5
ffffffffc02040a4:	8a860613          	addi	a2,a2,-1880 # ffffffffc0208948 <etext+0x16cc>
ffffffffc02040a8:	2fa00593          	li	a1,762
ffffffffc02040ac:	00004517          	auipc	a0,0x4
ffffffffc02040b0:	67450513          	addi	a0,a0,1652 # ffffffffc0208720 <etext+0x14a4>
ffffffffc02040b4:	91cfc0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc02040b8 <slub_shrink>:
    if (slub_inited == 0) return;
ffffffffc02040b8:	00023797          	auipc	a5,0x23
ffffffffc02040bc:	7607a783          	lw	a5,1888(a5) # ffffffffc0227818 <slub_inited>
ffffffffc02040c0:	c399                	beqz	a5,ffffffffc02040c6 <slub_shrink+0xe>
ffffffffc02040c2:	999ff06f          	j	ffffffffc0203a5a <slub_shrink.part.0>
}
ffffffffc02040c6:	8082                	ret

ffffffffc02040c8 <slub_nr_classes>:

/* ------------------------- 只读信息 / 统计 ------------------------- */

size_t slub_nr_classes(void) {
    return SLUB_NCLASSES;
}
ffffffffc02040c8:	4521                	li	a0,8
ffffffffc02040ca:	8082                	ret

ffffffffc02040cc <slub_size_to_class>:
    if (size == 0 || size > SLUB_MAX_SMALL_SIZE) return -1;
ffffffffc02040cc:	fff50713          	addi	a4,a0,-1
ffffffffc02040d0:	7ff00793          	li	a5,2047
ffffffffc02040d4:	00e7ef63          	bltu	a5,a4,ffffffffc02040f2 <slub_size_to_class+0x26>
ffffffffc02040d8:	00006717          	auipc	a4,0x6
ffffffffc02040dc:	a2870713          	addi	a4,a4,-1496 # ffffffffc0209b00 <slub_sizes>
    for (cls = 0; cls < (int)SLUB_NCLASSES; cls++) {
ffffffffc02040e0:	4781                	li	a5,0
ffffffffc02040e2:	4621                	li	a2,8
        if (size <= slub_sizes[cls]) return cls;
ffffffffc02040e4:	6314                	ld	a3,0(a4)
    for (cls = 0; cls < (int)SLUB_NCLASSES; cls++) {
ffffffffc02040e6:	0721                	addi	a4,a4,8
        if (size <= slub_sizes[cls]) return cls;
ffffffffc02040e8:	00a6f663          	bgeu	a3,a0,ffffffffc02040f4 <slub_size_to_class+0x28>
    for (cls = 0; cls < (int)SLUB_NCLASSES; cls++) {
ffffffffc02040ec:	2785                	addiw	a5,a5,1
ffffffffc02040ee:	fec79be3          	bne	a5,a2,ffffffffc02040e4 <slub_size_to_class+0x18>
    if (size == 0 || size > SLUB_MAX_SMALL_SIZE) return -1;
ffffffffc02040f2:	57fd                	li	a5,-1

int slub_size_to_class(size_t size) {
    return slub_class_of(size);
}
ffffffffc02040f4:	853e                	mv	a0,a5
ffffffffc02040f6:	8082                	ret

ffffffffc02040f8 <slub_class_size>:

size_t slub_class_size(size_t cls) {
    if (cls >= SLUB_NCLASSES) return 0;
ffffffffc02040f8:	479d                	li	a5,7
ffffffffc02040fa:	00a7ea63          	bltu	a5,a0,ffffffffc020410e <slub_class_size+0x16>
    return slub_sizes[cls];
ffffffffc02040fe:	050e                	slli	a0,a0,0x3
ffffffffc0204100:	00006797          	auipc	a5,0x6
ffffffffc0204104:	a0078793          	addi	a5,a5,-1536 # ffffffffc0209b00 <slub_sizes>
ffffffffc0204108:	97aa                	add	a5,a5,a0
ffffffffc020410a:	6388                	ld	a0,0(a5)
ffffffffc020410c:	8082                	ret
    if (cls >= SLUB_NCLASSES) return 0;
ffffffffc020410e:	4501                	li	a0,0
}
ffffffffc0204110:	8082                	ret

ffffffffc0204112 <slub_get_class_info>:
    struct slub_cache *c;
    struct slub_barn *b;
    slub_port_flags_t f;
    unsigned int cpu;

    if (out == NULL || cls >= SLUB_NCLASSES) return -1;
ffffffffc0204112:	20058563          	beqz	a1,ffffffffc020431c <slub_get_class_info+0x20a>
ffffffffc0204116:	00853793          	sltiu	a5,a0,8
ffffffffc020411a:	20078163          	beqz	a5,ffffffffc020431c <slub_get_class_info+0x20a>
int slub_get_class_info(size_t cls, struct slub_class_info *out) {
ffffffffc020411e:	715d                	addi	sp,sp,-80
ffffffffc0204120:	e4a2                	sd	s0,72(sp)
ffffffffc0204122:	e0a6                	sd	s1,64(sp)
ffffffffc0204124:	fc4a                	sd	s2,56(sp)
ffffffffc0204126:	f84e                	sd	s3,48(sp)
ffffffffc0204128:	f452                	sd	s4,40(sp)
ffffffffc020412a:	f056                	sd	s5,32(sp)
ffffffffc020412c:	ec5a                	sd	s6,24(sp)
ffffffffc020412e:	e85e                	sd	s7,16(sp)
ffffffffc0204130:	e462                	sd	s8,8(sp)
ffffffffc0204132:	e066                	sd	s9,0(sp)
    unsigned long s = read_csr(sstatus);
ffffffffc0204134:	10002873          	csrr	a6,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0204138:	00287813          	andi	a6,a6,2
    if (*flags) {
ffffffffc020413c:	1c081d63          	bnez	a6,ffffffffc0204316 <slub_get_class_info+0x204>
    __sync_synchronize();
ffffffffc0204140:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0204144:	00451693          	slli	a3,a0,0x4
ffffffffc0204148:	40a68733          	sub	a4,a3,a0
ffffffffc020414c:	070e                	slli	a4,a4,0x3
ffffffffc020414e:	0751                	addi	a4,a4,20
ffffffffc0204150:	0001b317          	auipc	t1,0x1b
ffffffffc0204154:	e5030313          	addi	t1,t1,-432 # ffffffffc021efa0 <slub_caches>
ffffffffc0204158:	971a                	add	a4,a4,t1
ffffffffc020415a:	4785                	li	a5,1
ffffffffc020415c:	0cf727af          	amoswap.w.aq	a5,a5,(a4)
ffffffffc0204160:	2781                	sext.w	a5,a5
ffffffffc0204162:	ffe5                	bnez	a5,ffffffffc020415a <slub_get_class_info+0x48>
    __sync_synchronize(); /* acquire */
ffffffffc0204164:	0330000f          	fence	rw,rw
    c = &slub_caches[cls];
    b = &slub_barns[cls];

    slub_port_spin_lock(&c->lock, &f);
    info.nr_slabs = c->nr_slabs;
ffffffffc0204168:	40a687b3          	sub	a5,a3,a0
ffffffffc020416c:	078e                	slli	a5,a5,0x3
ffffffffc020416e:	979a                	add	a5,a5,t1
    info.nr_empty = c->nr_empty;
    info.slab_pages_used = c->nr_slab_pages;
    info.inuse_objs = c->inuse_objs;
    info.slab_new = c->stat_slab_new;
    info.slab_free = c->stat_slab_free;
    info.slab_fail = c->stat_page_fail + c->stat_desc_fail;
ffffffffc0204170:	0687b883          	ld	a7,104(a5)
ffffffffc0204174:	7bb0                	ld	a2,112(a5)
    info.nr_slabs = c->nr_slabs;
ffffffffc0204176:	0347e903          	lwu	s2,52(a5)
    info.nr_partial = c->nr_partial;
ffffffffc020417a:	0287e483          	lwu	s1,40(a5)
    info.nr_full = c->nr_full;
ffffffffc020417e:	0307e403          	lwu	s0,48(a5)
    info.nr_empty = c->nr_empty;
ffffffffc0204182:	02c7e383          	lwu	t2,44(a5)
    info.slab_pages_used = c->nr_slab_pages;
ffffffffc0204186:	0387e283          	lwu	t0,56(a5)
    info.inuse_objs = c->inuse_objs;
ffffffffc020418a:	0407bf83          	ld	t6,64(a5)
    info.slab_new = c->stat_slab_new;
ffffffffc020418e:	0587be83          	ld	t4,88(a5)
    info.slab_free = c->stat_slab_free;
ffffffffc0204192:	0607be03          	ld	t3,96(a5)
    info.refill = c->stat_refill;
ffffffffc0204196:	0487bf03          	ld	t5,72(a5)
    info.flush = c->stat_flush;
ffffffffc020419a:	0507b983          	ld	s3,80(a5)
    info.slab_fail = c->stat_page_fail + c->stat_desc_fail;
ffffffffc020419e:	98b2                	add	a7,a7,a2
    __sync_synchronize(); /* release */
ffffffffc02041a0:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc02041a4:	0310000f          	fence	rw,w
ffffffffc02041a8:	00072023          	sw	zero,0(a4)
    __sync_synchronize();
ffffffffc02041ac:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02041b0:	00080463          	beqz	a6,ffffffffc02041b8 <slub_get_class_info+0xa6>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc02041b4:	100167f3          	csrrsi	a5,sstatus,2
    unsigned long s = read_csr(sstatus);
ffffffffc02041b8:	10002af3          	csrr	s5,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc02041bc:	002afa93          	andi	s5,s5,2
    if (*flags) {
ffffffffc02041c0:	140a9863          	bnez	s5,ffffffffc0204310 <slub_get_class_info+0x1fe>
    __sync_synchronize();
ffffffffc02041c4:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc02041c8:	00251813          	slli	a6,a0,0x2
ffffffffc02041cc:	00a80733          	add	a4,a6,a0
ffffffffc02041d0:	070e                	slli	a4,a4,0x3
ffffffffc02041d2:	0001ba17          	auipc	s4,0x1b
ffffffffc02041d6:	c8ea0a13          	addi	s4,s4,-882 # ffffffffc021ee60 <slub_barns>
ffffffffc02041da:	9752                	add	a4,a4,s4
ffffffffc02041dc:	4785                	li	a5,1
ffffffffc02041de:	0cf727af          	amoswap.w.aq	a5,a5,(a4)
ffffffffc02041e2:	2781                	sext.w	a5,a5
ffffffffc02041e4:	ffe5                	bnez	a5,ffffffffc02041dc <slub_get_class_info+0xca>
    __sync_synchronize(); /* acquire */
ffffffffc02041e6:	0330000f          	fence	rw,rw
    slub_port_spin_unlock(&c->lock, &f);

    slub_port_spin_lock(&b->lock, &f);
    info.barn_get = b->stat_get;
ffffffffc02041ea:	00a807b3          	add	a5,a6,a0
ffffffffc02041ee:	078e                	slli	a5,a5,0x3
ffffffffc02041f0:	97d2                	add	a5,a5,s4
ffffffffc02041f2:	0187ba03          	ld	s4,24(a5)
    info.barn_put = b->stat_put;
ffffffffc02041f6:	7390                	ld	a2,32(a5)
    __sync_synchronize(); /* release */
ffffffffc02041f8:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc02041fc:	0310000f          	fence	rw,w
ffffffffc0204200:	00072023          	sw	zero,0(a4)
    __sync_synchronize();
ffffffffc0204204:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0204208:	000a8463          	beqz	s5,ffffffffc0204210 <slub_get_class_info+0xfe>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc020420c:	100167f3          	csrrsi	a5,sstatus,2
    unsigned long s = read_csr(sstatus);
ffffffffc0204210:	100027f3          	csrr	a5,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0204214:	8b89                	andi	a5,a5,2
    if (*flags) {
ffffffffc0204216:	e7e1                	bnez	a5,ffffffffc02042de <slub_get_class_info+0x1cc>
    __sync_synchronize();
ffffffffc0204218:	0330000f          	fence	rw,rw
    slub_port_spin_unlock(&b->lock, &f);

    for (cpu = 0; cpu < SLUB_NCPUS; cpu++) {
        slub_port_local_lock(&f);
        info.alloc_fast += slub_cs[cpu][cls].alloc_fast;
ffffffffc020421c:	982a                	add	a6,a6,a0
ffffffffc020421e:	080e                	slli	a6,a6,0x3
ffffffffc0204220:	0001b797          	auipc	a5,0x1b
ffffffffc0204224:	a0078793          	addi	a5,a5,-1536 # ffffffffc021ec20 <slub_cs>
ffffffffc0204228:	97c2                	add	a5,a5,a6
ffffffffc020422a:	0007bb03          	ld	s6,0(a5)
        info.alloc_slow += slub_cs[cpu][cls].alloc_slow;
ffffffffc020422e:	0087ba83          	ld	s5,8(a5)
        info.free_fast += slub_cs[cpu][cls].free_fast;
ffffffffc0204232:	0107b803          	ld	a6,16(a5)
        info.free_slow += slub_cs[cpu][cls].free_slow;
ffffffffc0204236:	6f98                	ld	a4,24(a5)
        info.user_objs += slub_cs[cpu][cls].user;
ffffffffc0204238:	0207bb83          	ld	s7,32(a5)
    __sync_synchronize();
ffffffffc020423c:	0330000f          	fence	rw,rw
        slub_port_local_unlock(&f);
    }

    info.objsize = slub_sizes[cls];
    info.sheaf_cap = c->sheaf_cap;
ffffffffc0204240:	40a687b3          	sub	a5,a3,a0
ffffffffc0204244:	078e                	slli	a5,a5,0x3
ffffffffc0204246:	979a                	add	a5,a5,t1
    info.barn_cap = c->barn_cap;
    info.slab_pages = c->slab_pages;
ffffffffc0204248:	4b94                	lw	a3,16(a5)
    info.objsize = slub_sizes[cls];
ffffffffc020424a:	00006c17          	auipc	s8,0x6
ffffffffc020424e:	8b6c0c13          	addi	s8,s8,-1866 # ffffffffc0209b00 <slub_sizes>
ffffffffc0204252:	050e                	slli	a0,a0,0x3
ffffffffc0204254:	9562                	add	a0,a0,s8
    info.objs_per_slab = c->slab_pages * SLUB_PAGE_SIZE / c->objsize;
ffffffffc0204256:	0007b303          	ld	t1,0(a5)
    info.sheaf_cap = c->sheaf_cap;
ffffffffc020425a:	0087ec03          	lwu	s8,8(a5)
    *out = info;
ffffffffc020425e:	00053c83          	ld	s9,0(a0)
    info.barn_cap = c->barn_cap;
ffffffffc0204262:	00c7e503          	lwu	a0,12(a5)
    info.objs_per_slab = c->slab_pages * SLUB_PAGE_SIZE / c->objsize;
ffffffffc0204266:	00c6979b          	slliw	a5,a3,0xc
ffffffffc020426a:	1782                	slli	a5,a5,0x20
ffffffffc020426c:	9381                	srli	a5,a5,0x20
ffffffffc020426e:	0267d7b3          	divu	a5,a5,t1
    *out = info;
ffffffffc0204272:	fd80                	sd	s0,56(a1)
    return 0;
}
ffffffffc0204274:	6426                	ld	s0,72(sp)
    info.slab_pages = c->slab_pages;
ffffffffc0204276:	1682                	slli	a3,a3,0x20
ffffffffc0204278:	9281                	srli	a3,a3,0x20
    *out = info;
ffffffffc020427a:	0195b023          	sd	s9,0(a1)
ffffffffc020427e:	0185b423          	sd	s8,8(a1)
ffffffffc0204282:	e988                	sd	a0,16(a1)
ffffffffc0204284:	0325b423          	sd	s2,40(a1)
ffffffffc0204288:	f984                	sd	s1,48(a1)
}
ffffffffc020428a:	7962                	ld	s2,56(sp)
ffffffffc020428c:	6486                	ld	s1,64(sp)
    *out = info;
ffffffffc020428e:	0575bc23          	sd	s7,88(a1)
ffffffffc0204292:	0765b023          	sd	s6,96(a1)
ffffffffc0204296:	0755b423          	sd	s5,104(a1)
ffffffffc020429a:	0935b423          	sd	s3,136(a1)
ffffffffc020429e:	0475b023          	sd	t2,64(a1)
}
ffffffffc02042a2:	79c2                	ld	s3,48(sp)
    *out = info;
ffffffffc02042a4:	0455b423          	sd	t0,72(a1)
ffffffffc02042a8:	05f5b823          	sd	t6,80(a1)
ffffffffc02042ac:	0705b823          	sd	a6,112(a1)
ffffffffc02042b0:	fdb8                	sd	a4,120(a1)
ffffffffc02042b2:	09e5b023          	sd	t5,128(a1)
ffffffffc02042b6:	0945b823          	sd	s4,144(a1)
ffffffffc02042ba:	edd0                	sd	a2,152(a1)
ffffffffc02042bc:	0bd5b023          	sd	t4,160(a1)
ffffffffc02042c0:	0bc5b423          	sd	t3,168(a1)
ffffffffc02042c4:	0b15b823          	sd	a7,176(a1)
    info.slab_pages = c->slab_pages;
ffffffffc02042c8:	ed94                	sd	a3,24(a1)
    return 0;
ffffffffc02042ca:	4501                	li	a0,0
    *out = info;
ffffffffc02042cc:	f19c                	sd	a5,32(a1)
}
ffffffffc02042ce:	7a22                	ld	s4,40(sp)
ffffffffc02042d0:	7a82                	ld	s5,32(sp)
ffffffffc02042d2:	6b62                	ld	s6,24(sp)
ffffffffc02042d4:	6bc2                	ld	s7,16(sp)
ffffffffc02042d6:	6c22                	ld	s8,8(sp)
ffffffffc02042d8:	6c82                	ld	s9,0(sp)
ffffffffc02042da:	6161                	addi	sp,sp,80
ffffffffc02042dc:	8082                	ret
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc02042de:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc02042e2:	0330000f          	fence	rw,rw
        info.alloc_fast += slub_cs[cpu][cls].alloc_fast;
ffffffffc02042e6:	982a                	add	a6,a6,a0
ffffffffc02042e8:	080e                	slli	a6,a6,0x3
ffffffffc02042ea:	0001b797          	auipc	a5,0x1b
ffffffffc02042ee:	93678793          	addi	a5,a5,-1738 # ffffffffc021ec20 <slub_cs>
ffffffffc02042f2:	97c2                	add	a5,a5,a6
ffffffffc02042f4:	0007bb03          	ld	s6,0(a5)
        info.alloc_slow += slub_cs[cpu][cls].alloc_slow;
ffffffffc02042f8:	0087ba83          	ld	s5,8(a5)
        info.free_fast += slub_cs[cpu][cls].free_fast;
ffffffffc02042fc:	0107b803          	ld	a6,16(a5)
        info.free_slow += slub_cs[cpu][cls].free_slow;
ffffffffc0204300:	6f98                	ld	a4,24(a5)
        info.user_objs += slub_cs[cpu][cls].user;
ffffffffc0204302:	0207bb83          	ld	s7,32(a5)
    __sync_synchronize();
ffffffffc0204306:	0330000f          	fence	rw,rw
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc020430a:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020430e:	bf0d                	j	ffffffffc0204240 <slub_get_class_info+0x12e>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0204310:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0204314:	bd45                	j	ffffffffc02041c4 <slub_get_class_info+0xb2>
ffffffffc0204316:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020431a:	b51d                	j	ffffffffc0204140 <slub_get_class_info+0x2e>
    if (out == NULL || cls >= SLUB_NCLASSES) return -1;
ffffffffc020431c:	557d                	li	a0,-1
}
ffffffffc020431e:	8082                	ret

ffffffffc0204320 <slub_user_objects>:
    unsigned long s = read_csr(sstatus);
ffffffffc0204320:	10002673          	csrr	a2,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0204324:	8a09                	andi	a2,a2,2
    if (*flags) {
ffffffffc0204326:	c219                	beqz	a2,ffffffffc020432c <slub_user_objects+0xc>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0204328:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc020432c:	0330000f          	fence	rw,rw
    unsigned int cpu, cls;
    slub_port_flags_t f;

    for (cpu = 0; cpu < SLUB_NCPUS; cpu++) {
        slub_port_local_lock(&f);
        for (cls = 0; cls < SLUB_NCLASSES; cls++) total += slub_cs[cpu][cls].user;
ffffffffc0204330:	0001b797          	auipc	a5,0x1b
ffffffffc0204334:	8f078793          	addi	a5,a5,-1808 # ffffffffc021ec20 <slub_cs>
ffffffffc0204338:	0001b697          	auipc	a3,0x1b
ffffffffc020433c:	a2868693          	addi	a3,a3,-1496 # ffffffffc021ed60 <slub_cc>
    size_t total = 0;
ffffffffc0204340:	4501                	li	a0,0
        for (cls = 0; cls < SLUB_NCLASSES; cls++) total += slub_cs[cpu][cls].user;
ffffffffc0204342:	7398                	ld	a4,32(a5)
ffffffffc0204344:	02878793          	addi	a5,a5,40
ffffffffc0204348:	953a                	add	a0,a0,a4
ffffffffc020434a:	fef69ce3          	bne	a3,a5,ffffffffc0204342 <slub_user_objects+0x22>
    __sync_synchronize();
ffffffffc020434e:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0204352:	c219                	beqz	a2,ffffffffc0204358 <slub_user_objects+0x38>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0204354:	100167f3          	csrrsi	a5,sstatus,2
    unsigned long s = read_csr(sstatus);
ffffffffc0204358:	100026f3          	csrr	a3,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc020435c:	8a89                	andi	a3,a3,2
    if (*flags) {
ffffffffc020435e:	c299                	beqz	a3,ffffffffc0204364 <slub_user_objects+0x44>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0204360:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0204364:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0204368:	00023717          	auipc	a4,0x23
ffffffffc020436c:	4b870713          	addi	a4,a4,1208 # ffffffffc0227820 <slub_pmm_lock>
ffffffffc0204370:	4785                	li	a5,1
ffffffffc0204372:	0cf727af          	amoswap.w.aq	a5,a5,(a4)
ffffffffc0204376:	2781                	sext.w	a5,a5
ffffffffc0204378:	ffe5                	bnez	a5,ffffffffc0204370 <slub_user_objects+0x50>
    __sync_synchronize(); /* acquire */
ffffffffc020437a:	0330000f          	fence	rw,rw
        slub_port_local_unlock(&f);
    }
    slub_port_spin_lock(&slub_pmm_lock, &f);
    total += slub_large_user;
ffffffffc020437e:	00023797          	auipc	a5,0x23
ffffffffc0204382:	4927b783          	ld	a5,1170(a5) # ffffffffc0227810 <slub_large_user>
    __sync_synchronize(); /* release */
ffffffffc0204386:	0330000f          	fence	rw,rw
ffffffffc020438a:	953e                	add	a0,a0,a5
    __sync_lock_release(&lock->locked);
ffffffffc020438c:	0310000f          	fence	rw,w
ffffffffc0204390:	00072023          	sw	zero,0(a4)
    __sync_synchronize();
ffffffffc0204394:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0204398:	c299                	beqz	a3,ffffffffc020439e <slub_user_objects+0x7e>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc020439a:	100167f3          	csrrsi	a5,sstatus,2
    slub_port_spin_unlock(&slub_pmm_lock, &f);
    return total;
}
ffffffffc020439e:	8082                	ret

ffffffffc02043a0 <slub_slab_pages>:
size_t slub_slab_pages(void) {
    size_t total = 0;
    unsigned int cls;
    slub_port_flags_t f;

    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
ffffffffc02043a0:	0001b717          	auipc	a4,0x1b
ffffffffc02043a4:	c1470713          	addi	a4,a4,-1004 # ffffffffc021efb4 <slub_caches+0x14>
ffffffffc02043a8:	0001b517          	auipc	a0,0x1b
ffffffffc02043ac:	fcc50513          	addi	a0,a0,-52 # ffffffffc021f374 <order.3+0x14>
    size_t total = 0;
ffffffffc02043b0:	4581                	li	a1,0
    unsigned long s = read_csr(sstatus);
ffffffffc02043b2:	10002673          	csrr	a2,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc02043b6:	8a09                	andi	a2,a2,2
    if (*flags) {
ffffffffc02043b8:	c219                	beqz	a2,ffffffffc02043be <slub_slab_pages+0x1e>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc02043ba:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc02043be:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc02043c2:	4785                	li	a5,1
ffffffffc02043c4:	0cf727af          	amoswap.w.aq	a5,a5,(a4)
ffffffffc02043c8:	2781                	sext.w	a5,a5
ffffffffc02043ca:	ffe5                	bnez	a5,ffffffffc02043c2 <slub_slab_pages+0x22>
    __sync_synchronize(); /* acquire */
ffffffffc02043cc:	0330000f          	fence	rw,rw
        slub_port_spin_lock(&slub_caches[cls].lock, &f);
        total += slub_caches[cls].nr_slab_pages;
ffffffffc02043d0:	02476783          	lwu	a5,36(a4)
    __sync_synchronize(); /* release */
ffffffffc02043d4:	0330000f          	fence	rw,rw
ffffffffc02043d8:	95be                	add	a1,a1,a5
    __sync_lock_release(&lock->locked);
ffffffffc02043da:	0310000f          	fence	rw,w
ffffffffc02043de:	00072023          	sw	zero,0(a4)
    __sync_synchronize();
ffffffffc02043e2:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02043e6:	c219                	beqz	a2,ffffffffc02043ec <slub_slab_pages+0x4c>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc02043e8:	100167f3          	csrrsi	a5,sstatus,2
    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
ffffffffc02043ec:	07870713          	addi	a4,a4,120
ffffffffc02043f0:	fca711e3          	bne	a4,a0,ffffffffc02043b2 <slub_slab_pages+0x12>
    unsigned long s = read_csr(sstatus);
ffffffffc02043f4:	100026f3          	csrr	a3,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc02043f8:	8a89                	andi	a3,a3,2
    if (*flags) {
ffffffffc02043fa:	c299                	beqz	a3,ffffffffc0204400 <slub_slab_pages+0x60>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc02043fc:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0204400:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0204404:	00023717          	auipc	a4,0x23
ffffffffc0204408:	41c70713          	addi	a4,a4,1052 # ffffffffc0227820 <slub_pmm_lock>
ffffffffc020440c:	4785                	li	a5,1
ffffffffc020440e:	0cf727af          	amoswap.w.aq	a5,a5,(a4)
ffffffffc0204412:	2781                	sext.w	a5,a5
ffffffffc0204414:	ffe5                	bnez	a5,ffffffffc020440c <slub_slab_pages+0x6c>
    __sync_synchronize(); /* acquire */
ffffffffc0204416:	0330000f          	fence	rw,rw
        slub_port_spin_unlock(&slub_caches[cls].lock, &f);
    }
    slub_port_spin_lock(&slub_pmm_lock, &f);
    total += slub_large_pages;
ffffffffc020441a:	00023797          	auipc	a5,0x23
ffffffffc020441e:	3ee7b783          	ld	a5,1006(a5) # ffffffffc0227808 <slub_large_pages>
    __sync_synchronize(); /* release */
ffffffffc0204422:	0330000f          	fence	rw,rw
ffffffffc0204426:	00f58533          	add	a0,a1,a5
    __sync_lock_release(&lock->locked);
ffffffffc020442a:	0310000f          	fence	rw,w
ffffffffc020442e:	00072023          	sw	zero,0(a4)
    __sync_synchronize();
ffffffffc0204432:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0204436:	c299                	beqz	a3,ffffffffc020443c <slub_slab_pages+0x9c>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0204438:	100167f3          	csrrsi	a5,sstatus,2
    slub_port_spin_unlock(&slub_pmm_lock, &f);
    return total;
}
ffffffffc020443c:	8082                	ret

ffffffffc020443e <slub_fixed_overhead>:
           sizeof(slub_index_nr) + sizeof(slub_index_lock) +
           sizeof(slub_pmm_lock) + sizeof(slub_inited) +
           sizeof(slub_large_user) + sizeof(slub_large_pages) +
           sizeof(slub_fault_left) + sizeof(slub_fault_hit_cnt) +
           sizeof(slub_sizes);
}
ffffffffc020443e:	6545                	lui	a0,0x11
ffffffffc0204440:	7b850513          	addi	a0,a0,1976 # 117b8 <kern_entry-0xffffffffc01ee848>
ffffffffc0204444:	8082                	ret

ffffffffc0204446 <slub_fault_inject>:
    unsigned long s = read_csr(sstatus);
ffffffffc0204446:	100026f3          	csrr	a3,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc020444a:	8a89                	andi	a3,a3,2
    if (*flags) {
ffffffffc020444c:	c299                	beqz	a3,ffffffffc0204452 <slub_fault_inject+0xc>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc020444e:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0204452:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0204456:	00023717          	auipc	a4,0x23
ffffffffc020445a:	3ca70713          	addi	a4,a4,970 # ffffffffc0227820 <slub_pmm_lock>
ffffffffc020445e:	4785                	li	a5,1
ffffffffc0204460:	0cf727af          	amoswap.w.aq	a5,a5,(a4)
ffffffffc0204464:	2781                	sext.w	a5,a5
ffffffffc0204466:	ffe5                	bnez	a5,ffffffffc020445e <slub_fault_inject+0x18>
    __sync_synchronize(); /* acquire */
ffffffffc0204468:	0330000f          	fence	rw,rw

void slub_fault_inject(size_t npages) {
    slub_port_flags_t f;

    slub_port_spin_lock(&slub_pmm_lock, &f);
    slub_fault_left = npages;
ffffffffc020446c:	00023797          	auipc	a5,0x23
ffffffffc0204470:	38a7ba23          	sd	a0,916(a5) # ffffffffc0227800 <slub_fault_left>
    __sync_synchronize(); /* release */
ffffffffc0204474:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0204478:	0310000f          	fence	rw,w
ffffffffc020447c:	00072023          	sw	zero,0(a4)
    __sync_synchronize();
ffffffffc0204480:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0204484:	c299                	beqz	a3,ffffffffc020448a <slub_fault_inject+0x44>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0204486:	100167f3          	csrrsi	a5,sstatus,2
    slub_port_spin_unlock(&slub_pmm_lock, &f);
}
ffffffffc020448a:	8082                	ret

ffffffffc020448c <slub_fault_clear>:
    unsigned long s = read_csr(sstatus);
ffffffffc020448c:	100026f3          	csrr	a3,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0204490:	8a89                	andi	a3,a3,2
    if (*flags) {
ffffffffc0204492:	c299                	beqz	a3,ffffffffc0204498 <slub_fault_clear+0xc>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0204494:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0204498:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc020449c:	00023717          	auipc	a4,0x23
ffffffffc02044a0:	38470713          	addi	a4,a4,900 # ffffffffc0227820 <slub_pmm_lock>
ffffffffc02044a4:	4785                	li	a5,1
ffffffffc02044a6:	0cf727af          	amoswap.w.aq	a5,a5,(a4)
ffffffffc02044aa:	2781                	sext.w	a5,a5
ffffffffc02044ac:	ffe5                	bnez	a5,ffffffffc02044a4 <slub_fault_clear+0x18>
    __sync_synchronize(); /* acquire */
ffffffffc02044ae:	0330000f          	fence	rw,rw

void slub_fault_clear(void) {
    slub_port_flags_t f;

    slub_port_spin_lock(&slub_pmm_lock, &f);
    slub_fault_left = 0;
ffffffffc02044b2:	00023797          	auipc	a5,0x23
ffffffffc02044b6:	3407b723          	sd	zero,846(a5) # ffffffffc0227800 <slub_fault_left>
    __sync_synchronize(); /* release */
ffffffffc02044ba:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc02044be:	0310000f          	fence	rw,w
ffffffffc02044c2:	00072023          	sw	zero,0(a4)
    __sync_synchronize();
ffffffffc02044c6:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02044ca:	c299                	beqz	a3,ffffffffc02044d0 <slub_fault_clear+0x44>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc02044cc:	100167f3          	csrrsi	a5,sstatus,2
    slub_port_spin_unlock(&slub_pmm_lock, &f);
}
ffffffffc02044d0:	8082                	ret

ffffffffc02044d2 <slub_fault_hits>:
    unsigned long s = read_csr(sstatus);
ffffffffc02044d2:	100026f3          	csrr	a3,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc02044d6:	8a89                	andi	a3,a3,2
    if (*flags) {
ffffffffc02044d8:	c299                	beqz	a3,ffffffffc02044de <slub_fault_hits+0xc>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc02044da:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc02044de:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc02044e2:	00023717          	auipc	a4,0x23
ffffffffc02044e6:	33e70713          	addi	a4,a4,830 # ffffffffc0227820 <slub_pmm_lock>
ffffffffc02044ea:	4785                	li	a5,1
ffffffffc02044ec:	0cf727af          	amoswap.w.aq	a5,a5,(a4)
ffffffffc02044f0:	2781                	sext.w	a5,a5
ffffffffc02044f2:	ffe5                	bnez	a5,ffffffffc02044ea <slub_fault_hits+0x18>
    __sync_synchronize(); /* acquire */
ffffffffc02044f4:	0330000f          	fence	rw,rw
size_t slub_fault_hits(void) {
    size_t n;
    slub_port_flags_t f;

    slub_port_spin_lock(&slub_pmm_lock, &f);
    n = slub_fault_hit_cnt;
ffffffffc02044f8:	00023517          	auipc	a0,0x23
ffffffffc02044fc:	30053503          	ld	a0,768(a0) # ffffffffc02277f8 <slub_fault_hit_cnt>
    __sync_synchronize(); /* release */
ffffffffc0204500:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0204504:	0310000f          	fence	rw,w
ffffffffc0204508:	00072023          	sw	zero,0(a4)
    __sync_synchronize();
ffffffffc020450c:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0204510:	c299                	beqz	a3,ffffffffc0204516 <slub_fault_hits+0x44>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0204512:	100167f3          	csrrsi	a5,sstatus,2
    slub_port_spin_unlock(&slub_pmm_lock, &f);
    return n;
}
ffffffffc0204516:	8082                	ret

ffffffffc0204518 <slub_check_ptr>:
void slub_check_ptr(void *ptr) {
    uintptr_t a = (uintptr_t)ptr;
    struct slub_slab *s;
    unsigned int cls, cpu, i, k;

    if (ptr == NULL) return;
ffffffffc0204518:	18050c63          	beqz	a0,ffffffffc02046b0 <slub_check_ptr+0x198>
void slub_check_ptr(void *ptr) {
ffffffffc020451c:	7179                	addi	sp,sp,-48
ffffffffc020451e:	f406                	sd	ra,40(sp)
    if ((a & (SLUB_MIN_ALIGN - 1)) != 0) {
ffffffffc0204520:	00f57793          	andi	a5,a0,15
ffffffffc0204524:	86aa                	mv	a3,a0
ffffffffc0204526:	1e079663          	bnez	a5,ffffffffc0204712 <slub_check_ptr+0x1fa>
    return (void *)(nbase * (size_t)PGSIZE + va_pa_offset);
ffffffffc020452a:	00006597          	auipc	a1,0x6
ffffffffc020452e:	87e5b583          	ld	a1,-1922(a1) # ffffffffc0209da8 <nbase>
ffffffffc0204532:	00023617          	auipc	a2,0x23
ffffffffc0204536:	2ae63603          	ld	a2,686(a2) # ffffffffc02277e0 <va_pa_offset>
ffffffffc020453a:	00c59713          	slli	a4,a1,0xc
ffffffffc020453e:	00c707b3          	add	a5,a4,a2
    return a >= (uintptr_t)slub_port_ram_low() &&
ffffffffc0204542:	0cf56e63          	bltu	a0,a5,ffffffffc020461e <slub_check_ptr+0x106>
    return (void *)(npage * (size_t)PGSIZE + va_pa_offset);
ffffffffc0204546:	00023797          	auipc	a5,0x23
ffffffffc020454a:	2a27b783          	ld	a5,674(a5) # ffffffffc02277e8 <npage>
ffffffffc020454e:	07b2                	slli	a5,a5,0xc
ffffffffc0204550:	97b2                	add	a5,a5,a2
ffffffffc0204552:	0cf57663          	bgeu	a0,a5,ffffffffc020461e <slub_check_ptr+0x106>
    }
    if (!slub_ptr_in_ram(ptr)) {
        slub_port_panic("slub: pointer %lx is outside RAM", (unsigned long)a);
    }

    s = slub_slab_lookup(ptr);
ffffffffc0204556:	e83a                	sd	a4,16(sp)
ffffffffc0204558:	ec2e                	sd	a1,24(sp)
ffffffffc020455a:	e42a                	sd	a0,8(sp)
ffffffffc020455c:	f18fe0ef          	jal	ffffffffc0202c74 <slub_slab_lookup>
    if (s != NULL) {
ffffffffc0204560:	66a2                	ld	a3,8(sp)
ffffffffc0204562:	6742                	ld	a4,16(sp)
ffffffffc0204564:	65e2                	ld	a1,24(sp)
ffffffffc0204566:	c961                	beqz	a0,ffffffffc0204636 <slub_check_ptr+0x11e>
        cls = s->cls;
        if ((a - s->base) % slub_caches[cls].objsize != 0) {
ffffffffc0204568:	01c54583          	lbu	a1,28(a0)
ffffffffc020456c:	0001b617          	auipc	a2,0x1b
ffffffffc0204570:	a3460613          	addi	a2,a2,-1484 # ffffffffc021efa0 <slub_caches>
ffffffffc0204574:	611c                	ld	a5,0(a0)
ffffffffc0204576:	00459713          	slli	a4,a1,0x4
ffffffffc020457a:	8f0d                	sub	a4,a4,a1
ffffffffc020457c:	070e                	slli	a4,a4,0x3
ffffffffc020457e:	9732                	add	a4,a4,a2
ffffffffc0204580:	6318                	ld	a4,0(a4)
ffffffffc0204582:	40f687b3          	sub	a5,a3,a5
ffffffffc0204586:	02e7f7b3          	remu	a5,a5,a4
ffffffffc020458a:	1a079163          	bnez	a5,ffffffffc020472c <slub_check_ptr+0x214>
        for (cpu = 0; cpu < SLUB_NCPUS; cpu++) {
            struct slub_sheaf *sf[2];
            sf[0] = &slub_cc[cpu][cls].main;
            sf[1] = &slub_cc[cpu][cls].spare;
            for (k = 0; k < 2; k++) {
                for (i = 0; i < sf[k]->size; i++) {
ffffffffc020458e:	0001a817          	auipc	a6,0x1a
ffffffffc0204592:	7d280813          	addi	a6,a6,2002 # ffffffffc021ed60 <slub_cc>
ffffffffc0204596:	00559793          	slli	a5,a1,0x5
ffffffffc020459a:	97c2                	add	a5,a5,a6
ffffffffc020459c:	4790                	lw	a2,8(a5)
ffffffffc020459e:	ce09                	beqz	a2,ffffffffc02045b8 <slub_check_ptr+0xa0>
ffffffffc02045a0:	639c                	ld	a5,0(a5)
ffffffffc02045a2:	02061713          	slli	a4,a2,0x20
ffffffffc02045a6:	01d75613          	srli	a2,a4,0x1d
ffffffffc02045aa:	963e                	add	a2,a2,a5
                    if (sf[k]->objs[i] == ptr) {
ffffffffc02045ac:	6398                	ld	a4,0(a5)
ffffffffc02045ae:	10e68263          	beq	a3,a4,ffffffffc02046b2 <slub_check_ptr+0x19a>
                for (i = 0; i < sf[k]->size; i++) {
ffffffffc02045b2:	07a1                	addi	a5,a5,8
ffffffffc02045b4:	fec79ce3          	bne	a5,a2,ffffffffc02045ac <slub_check_ptr+0x94>
ffffffffc02045b8:	00559793          	slli	a5,a1,0x5
ffffffffc02045bc:	983e                	add	a6,a6,a5
ffffffffc02045be:	01882603          	lw	a2,24(a6)
ffffffffc02045c2:	ce11                	beqz	a2,ffffffffc02045de <slub_check_ptr+0xc6>
ffffffffc02045c4:	01083783          	ld	a5,16(a6)
ffffffffc02045c8:	02061713          	slli	a4,a2,0x20
ffffffffc02045cc:	01d75613          	srli	a2,a4,0x1d
ffffffffc02045d0:	963e                	add	a2,a2,a5
                    if (sf[k]->objs[i] == ptr) {
ffffffffc02045d2:	6398                	ld	a4,0(a5)
ffffffffc02045d4:	0ce68f63          	beq	a3,a4,ffffffffc02046b2 <slub_check_ptr+0x19a>
                for (i = 0; i < sf[k]->size; i++) {
ffffffffc02045d8:	07a1                	addi	a5,a5,8
ffffffffc02045da:	fef61ce3          	bne	a2,a5,ffffffffc02045d2 <slub_check_ptr+0xba>
                                        (unsigned long)a);
                    }
                }
            }
        }
        for (i = 0; i < slub_barns[cls].size; i++) {
ffffffffc02045de:	00259793          	slli	a5,a1,0x2
ffffffffc02045e2:	97ae                	add	a5,a5,a1
ffffffffc02045e4:	078e                	slli	a5,a5,0x3
ffffffffc02045e6:	0001b717          	auipc	a4,0x1b
ffffffffc02045ea:	87a70713          	addi	a4,a4,-1926 # ffffffffc021ee60 <slub_barns>
ffffffffc02045ee:	97ba                	add	a5,a5,a4
ffffffffc02045f0:	4b90                	lw	a2,16(a5)
ffffffffc02045f2:	ce09                	beqz	a2,ffffffffc020460c <slub_check_ptr+0xf4>
ffffffffc02045f4:	679c                	ld	a5,8(a5)
ffffffffc02045f6:	02061713          	slli	a4,a2,0x20
ffffffffc02045fa:	01d75613          	srli	a2,a4,0x1d
ffffffffc02045fe:	963e                	add	a2,a2,a5
            if (slub_barns[cls].objs[i] == ptr) {
ffffffffc0204600:	6398                	ld	a4,0(a5)
ffffffffc0204602:	0ed70063          	beq	a4,a3,ffffffffc02046e2 <slub_check_ptr+0x1ca>
        for (i = 0; i < slub_barns[cls].size; i++) {
ffffffffc0204606:	07a1                	addi	a5,a5,8
ffffffffc0204608:	fef61ce3          	bne	a2,a5,ffffffffc0204600 <slub_check_ptr+0xe8>
                                (unsigned long)a);
            }
        }
        {
            void *o;
            for (o = s->freelist; o != NULL; o = *(void **)o) {
ffffffffc020460c:	711c                	ld	a5,32(a0)
ffffffffc020460e:	c789                	beqz	a5,ffffffffc0204618 <slub_check_ptr+0x100>
                if (o == ptr) {
ffffffffc0204610:	0af68d63          	beq	a3,a5,ffffffffc02046ca <slub_check_ptr+0x1b2>
            for (o = s->freelist; o != NULL; o = *(void **)o) {
ffffffffc0204614:	639c                	ld	a5,0(a5)
ffffffffc0204616:	ffed                	bnez	a5,ffffffffc0204610 <slub_check_ptr+0xf8>
            h->npages == 0) {
            slub_port_panic("slub: large object header at %lx is inconsistent",
                            (unsigned long)a);
        }
    }
}
ffffffffc0204618:	70a2                	ld	ra,40(sp)
ffffffffc020461a:	6145                	addi	sp,sp,48
ffffffffc020461c:	8082                	ret
        slub_port_panic("slub: pointer %lx is outside RAM", (unsigned long)a);
ffffffffc020461e:	00004617          	auipc	a2,0x4
ffffffffc0204622:	3e260613          	addi	a2,a2,994 # ffffffffc0208a00 <etext+0x1784>
ffffffffc0204626:	4f900593          	li	a1,1273
ffffffffc020462a:	00004517          	auipc	a0,0x4
ffffffffc020462e:	0f650513          	addi	a0,a0,246 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0204632:	b9ffb0ef          	jal	ffffffffc02001d0 <__panic>
    return (void *)(nbase * (size_t)PGSIZE + va_pa_offset);
ffffffffc0204636:	00023617          	auipc	a2,0x23
ffffffffc020463a:	1aa63603          	ld	a2,426(a2) # ffffffffc02277e0 <va_pa_offset>
ffffffffc020463e:	02060613          	addi	a2,a2,32
    if (a < (uintptr_t)slub_port_ram_low() + SLUB_LARGE_HDR_SIZE) {
ffffffffc0204642:	9732                	add	a4,a4,a2
ffffffffc0204644:	10e6e063          	bltu	a3,a4,ffffffffc0204744 <slub_check_ptr+0x22c>
        if (h->magic != SLUB_MAGIC_LARGE) {
ffffffffc0204648:	29a637b7          	lui	a5,0x29a63
ffffffffc020464c:	aa178793          	addi	a5,a5,-1375 # 29a62aa1 <kern_entry-0xffffffff9679d55f>
ffffffffc0204650:	4c524737          	lui	a4,0x4c524
ffffffffc0204654:	fe06b503          	ld	a0,-32(a3)
ffffffffc0204658:	1786                	slli	a5,a5,0x21
ffffffffc020465a:	74770713          	addi	a4,a4,1863 # 4c524747 <kern_entry-0xffffffff73cdb8b9>
ffffffffc020465e:	97ba                	add	a5,a5,a4
ffffffffc0204660:	08f51d63          	bne	a0,a5,ffffffffc02046fa <slub_check_ptr+0x1e2>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0204664:	fe86b783          	ld	a5,-24(a3)
ffffffffc0204668:	00023817          	auipc	a6,0x23
ffffffffc020466c:	18883803          	ld	a6,392(a6) # ffffffffc02277f0 <pages>
ffffffffc0204670:	ccccd737          	lui	a4,0xccccd
ffffffffc0204674:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcaa5455>
ffffffffc0204678:	02071513          	slli	a0,a4,0x20
ffffffffc020467c:	410787b3          	sub	a5,a5,a6
ffffffffc0204680:	972a                	add	a4,a4,a0
ffffffffc0204682:	878d                	srai	a5,a5,0x3
ffffffffc0204684:	02e787b3          	mul	a5,a5,a4
ffffffffc0204688:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc020468a:	07b2                	slli	a5,a5,0xc
        if ((uintptr_t)slub_port_page_kva(h->base) + SLUB_LARGE_HDR_SIZE != a ||
ffffffffc020468c:	97b2                	add	a5,a5,a2
ffffffffc020468e:	00f69563          	bne	a3,a5,ffffffffc0204698 <slub_check_ptr+0x180>
ffffffffc0204692:	ff06b783          	ld	a5,-16(a3)
ffffffffc0204696:	f3c9                	bnez	a5,ffffffffc0204618 <slub_check_ptr+0x100>
            slub_port_panic("slub: large object header at %lx is inconsistent",
ffffffffc0204698:	00004617          	auipc	a2,0x4
ffffffffc020469c:	4e060613          	addi	a2,a2,1248 # ffffffffc0208b78 <etext+0x18fc>
ffffffffc02046a0:	53400593          	li	a1,1332
ffffffffc02046a4:	00004517          	auipc	a0,0x4
ffffffffc02046a8:	07c50513          	addi	a0,a0,124 # ffffffffc0208720 <etext+0x14a4>
ffffffffc02046ac:	b25fb0ef          	jal	ffffffffc02001d0 <__panic>
ffffffffc02046b0:	8082                	ret
                        slub_port_panic("slub: double free of %lx (still in a "
ffffffffc02046b2:	00004617          	auipc	a2,0x4
ffffffffc02046b6:	39e60613          	addi	a2,a2,926 # ffffffffc0208a50 <etext+0x17d4>
ffffffffc02046ba:	50b00593          	li	a1,1291
ffffffffc02046be:	00004517          	auipc	a0,0x4
ffffffffc02046c2:	06250513          	addi	a0,a0,98 # ffffffffc0208720 <etext+0x14a4>
ffffffffc02046c6:	b0bfb0ef          	jal	ffffffffc02001d0 <__panic>
                    slub_port_panic("slub: double free of %lx (already on the "
ffffffffc02046ca:	00004617          	auipc	a2,0x4
ffffffffc02046ce:	3e660613          	addi	a2,a2,998 # ffffffffc0208ab0 <etext+0x1834>
ffffffffc02046d2:	51c00593          	li	a1,1308
ffffffffc02046d6:	00004517          	auipc	a0,0x4
ffffffffc02046da:	04a50513          	addi	a0,a0,74 # ffffffffc0208720 <etext+0x14a4>
ffffffffc02046de:	af3fb0ef          	jal	ffffffffc02001d0 <__panic>
                slub_port_panic("slub: double free of %lx (still in the barn)",
ffffffffc02046e2:	00004617          	auipc	a2,0x4
ffffffffc02046e6:	39e60613          	addi	a2,a2,926 # ffffffffc0208a80 <etext+0x1804>
ffffffffc02046ea:	51400593          	li	a1,1300
ffffffffc02046ee:	00004517          	auipc	a0,0x4
ffffffffc02046f2:	03250513          	addi	a0,a0,50 # ffffffffc0208720 <etext+0x14a4>
ffffffffc02046f6:	adbfb0ef          	jal	ffffffffc02001d0 <__panic>
            slub_port_panic("slub: pointer %lx has neither a slab nor a valid "
ffffffffc02046fa:	00004617          	auipc	a2,0x4
ffffffffc02046fe:	41e60613          	addi	a2,a2,1054 # ffffffffc0208b18 <etext+0x189c>
ffffffffc0204702:	52e00593          	li	a1,1326
ffffffffc0204706:	00004517          	auipc	a0,0x4
ffffffffc020470a:	01a50513          	addi	a0,a0,26 # ffffffffc0208720 <etext+0x14a4>
ffffffffc020470e:	ac3fb0ef          	jal	ffffffffc02001d0 <__panic>
        slub_port_panic("slub: pointer %lx is not %d-byte aligned",
ffffffffc0204712:	4741                	li	a4,16
ffffffffc0204714:	00004617          	auipc	a2,0x4
ffffffffc0204718:	2bc60613          	addi	a2,a2,700 # ffffffffc02089d0 <etext+0x1754>
ffffffffc020471c:	4f500593          	li	a1,1269
ffffffffc0204720:	00004517          	auipc	a0,0x4
ffffffffc0204724:	00050513          	mv	a0,a0
ffffffffc0204728:	aa9fb0ef          	jal	ffffffffc02001d0 <__panic>
            slub_port_panic("slub: pointer %lx is not a slot start",
ffffffffc020472c:	00004617          	auipc	a2,0x4
ffffffffc0204730:	2fc60613          	addi	a2,a2,764 # ffffffffc0208a28 <etext+0x17ac>
ffffffffc0204734:	50000593          	li	a1,1280
ffffffffc0204738:	00004517          	auipc	a0,0x4
ffffffffc020473c:	fe850513          	addi	a0,a0,-24 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0204740:	a91fb0ef          	jal	ffffffffc02001d0 <__panic>
        slub_port_panic("slub: pointer %lx is too low to carry a header",
ffffffffc0204744:	00004617          	auipc	a2,0x4
ffffffffc0204748:	3a460613          	addi	a2,a2,932 # ffffffffc0208ae8 <etext+0x186c>
ffffffffc020474c:	52700593          	li	a1,1319
ffffffffc0204750:	00004517          	auipc	a0,0x4
ffffffffc0204754:	fd050513          	addi	a0,a0,-48 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0204758:	a79fb0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc020475c <slub_init>:
    kfree(p);

    slub_port_printf("slub_smoke: 8 classes + large alloc/write/free OK\n");
}

void slub_init(void) {
ffffffffc020475c:	715d                	addi	sp,sp,-80
ffffffffc020475e:	f44e                	sd	s3,40(sp)
    unsigned int cls, cpu, i;

    if (slub_inited != 0) return;
ffffffffc0204760:	00023997          	auipc	s3,0x23
ffffffffc0204764:	0b89a983          	lw	s3,184(s3) # ffffffffc0227818 <slub_inited>
void slub_init(void) {
ffffffffc0204768:	e486                	sd	ra,72(sp)
    if (slub_inited != 0) return;
ffffffffc020476a:	00098663          	beqz	s3,ffffffffc0204776 <slub_init+0x1a>
    slub_port_printf("slub_init: %d classes, %d cpus, fixed overhead %lu "
                     "bytes, nr_free_pages %lu\n",
                     (int)SLUB_NCLASSES, (int)SLUB_NCPUS,
                     (unsigned long)slub_fixed_overhead(),
                     (unsigned long)slub_port_nr_free_pages());
}
ffffffffc020476e:	60a6                	ld	ra,72(sp)
ffffffffc0204770:	79a2                	ld	s3,40(sp)
ffffffffc0204772:	6161                	addi	sp,sp,80
ffffffffc0204774:	8082                	ret
ffffffffc0204776:	e0a2                	sd	s0,64(sp)
ffffffffc0204778:	fc26                	sd	s1,56(sp)
ffffffffc020477a:	f84a                	sd	s2,48(sp)
ffffffffc020477c:	f052                	sd	s4,32(sp)
ffffffffc020477e:	ec56                	sd	s5,24(sp)
ffffffffc0204780:	e85a                	sd	s6,16(sp)
    lock->locked = 0;
ffffffffc0204782:	00023797          	auipc	a5,0x23
ffffffffc0204786:	0a07a323          	sw	zero,166(a5) # ffffffffc0227828 <slub_index_lock>
    __sync_synchronize();
ffffffffc020478a:	0330000f          	fence	rw,rw
    lock->locked = 0;
ffffffffc020478e:	00023797          	auipc	a5,0x23
ffffffffc0204792:	0807a923          	sw	zero,146(a5) # ffffffffc0227820 <slub_pmm_lock>
    __sync_synchronize();
ffffffffc0204796:	0330000f          	fence	rw,rw
        slub_pool[i].state = 0;
ffffffffc020479a:	0000b797          	auipc	a5,0xb
ffffffffc020479e:	4a0781a3          	sb	zero,1187(a5) # ffffffffc020fc3d <slub_pool+0x1d>
        slub_pool[i].next = (i + 1 < SLUB_MAX_SLABS) ? &slub_pool[i + 1] : NULL;
ffffffffc02047a2:	0000b797          	auipc	a5,0xb
ffffffffc02047a6:	4ae78793          	addi	a5,a5,1198 # ffffffffc020fc50 <slub_pool+0x30>
ffffffffc02047aa:	00017717          	auipc	a4,0x17
ffffffffc02047ae:	47670713          	addi	a4,a4,1142 # ffffffffc021bc20 <slub_barn_store>
ffffffffc02047b2:	fef7bc23          	sd	a5,-8(a5)
        slub_pool[i].state = 0;
ffffffffc02047b6:	00078ea3          	sb	zero,29(a5)
        slub_pool[i].next = (i + 1 < SLUB_MAX_SLABS) ? &slub_pool[i + 1] : NULL;
ffffffffc02047ba:	03078793          	addi	a5,a5,48
ffffffffc02047be:	fee79ae3          	bne	a5,a4,ffffffffc02047b2 <slub_init+0x56>
ffffffffc02047c2:	0000b797          	auipc	a5,0xb
ffffffffc02047c6:	45e78793          	addi	a5,a5,1118 # ffffffffc020fc20 <slub_pool>
    slub_pool_free = &slub_pool[0];
ffffffffc02047ca:	00023717          	auipc	a4,0x23
ffffffffc02047ce:	06f73323          	sd	a5,102(a4) # ffffffffc0227830 <slub_pool_free>
ffffffffc02047d2:	00005917          	auipc	s2,0x5
ffffffffc02047d6:	32e90913          	addi	s2,s2,814 # ffffffffc0209b00 <slub_sizes>
ffffffffc02047da:	0001ae97          	auipc	t4,0x1a
ffffffffc02047de:	7c6e8e93          	addi	t4,t4,1990 # ffffffffc021efa0 <slub_caches>
ffffffffc02047e2:	0001ae17          	auipc	t3,0x1a
ffffffffc02047e6:	67ee0e13          	addi	t3,t3,1662 # ffffffffc021ee60 <slub_barns>
            (unsigned int)((sheaf_cap * slub_sizes[cls] + SLUB_PAGE_SIZE - 1) /
ffffffffc02047ea:	6505                	lui	a0,0x1
        slub_pool[i].next = (i + 1 < SLUB_MAX_SLABS) ? &slub_pool[i + 1] : NULL;
ffffffffc02047ec:	00017797          	auipc	a5,0x17
ffffffffc02047f0:	4207b623          	sd	zero,1068(a5) # ffffffffc021bc18 <slub_pool+0xbff8>
    slub_index_nr = 0;
ffffffffc02047f4:	00023797          	auipc	a5,0x23
ffffffffc02047f8:	0207ac23          	sw	zero,56(a5) # ffffffffc022782c <slub_index_nr>
ffffffffc02047fc:	8fca                	mv	t6,s2
ffffffffc02047fe:	87f6                	mv	a5,t4
ffffffffc0204800:	85f2                	mv	a1,t3
            (unsigned int)((sheaf_cap * slub_sizes[cls] + SLUB_PAGE_SIZE - 1) /
ffffffffc0204802:	157d                	addi	a0,a0,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0204804:	00017f17          	auipc	t5,0x17
ffffffffc0204808:	41cf0f13          	addi	t5,t5,1052 # ffffffffc021bc20 <slub_barn_store>
ffffffffc020480c:	00019317          	auipc	t1,0x19
ffffffffc0204810:	41430313          	addi	t1,t1,1044 # ffffffffc021dc20 <slub_sheaf_store>
ffffffffc0204814:	0001a717          	auipc	a4,0x1a
ffffffffc0204818:	54c70713          	addi	a4,a4,1356 # ffffffffc021ed60 <slub_cc>
ffffffffc020481c:	0001a617          	auipc	a2,0x1a
ffffffffc0204820:	40460613          	addi	a2,a2,1028 # ffffffffc021ec20 <slub_cs>
    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
ffffffffc0204824:	4481                	li	s1,0
            (slub_sizes[cls] <= 256) ? SLUB_SHEAF_MAX_CAP : 16;
ffffffffc0204826:	10000413          	li	s0,256
        slub_port_assert(slab_pages >= 1 && slab_pages <= SLUB_MAX_SLAB_PAGES);
ffffffffc020482a:	43bd                	li	t2,15
ffffffffc020482c:	a209                	j	ffffffffc020492e <slub_init+0x1d2>
            (slub_sizes[cls] <= 256) ? SLUB_SHEAF_MAX_CAP : 16;
ffffffffc020482e:	02000813          	li	a6,32
        unsigned int sheaf_cap =
ffffffffc0204832:	82c2                	mv	t0,a6
            (slub_sizes[cls] <= 256) ? SLUB_SHEAF_MAX_CAP : 16;
ffffffffc0204834:	08000a13          	li	s4,128
            (unsigned int)((sheaf_cap * slub_sizes[cls] + SLUB_PAGE_SIZE - 1) /
ffffffffc0204838:	030b08b3          	mul	a7,s6,a6
ffffffffc020483c:	98aa                	add	a7,a7,a0
ffffffffc020483e:	00c8d893          	srli	a7,a7,0xc
        slub_port_assert(slab_pages >= 1 && slab_pages <= SLUB_MAX_SLAB_PAGES);
ffffffffc0204842:	fff8869b          	addiw	a3,a7,-1
ffffffffc0204846:	26d3e363          	bltu	t2,a3,ffffffffc0204aac <slub_init+0x350>
        slub_port_assert(slab_pages * SLUB_PAGE_SIZE / slub_sizes[cls] >=
ffffffffc020484a:	00c8969b          	slliw	a3,a7,0xc
ffffffffc020484e:	1682                	slli	a3,a3,0x20
ffffffffc0204850:	9281                	srli	a3,a3,0x20
ffffffffc0204852:	0366d6b3          	divu	a3,a3,s6
ffffffffc0204856:	2d06e163          	bltu	a3,a6,ffffffffc0204b18 <slub_init+0x3bc>
    lock->locked = 0;
ffffffffc020485a:	02049a93          	slli	s5,s1,0x20
ffffffffc020485e:	020ada93          	srli	s5,s5,0x20
ffffffffc0204862:	004a9693          	slli	a3,s5,0x4
ffffffffc0204866:	415686b3          	sub	a3,a3,s5
ffffffffc020486a:	068e                	slli	a3,a3,0x3
        c->objsize = slub_sizes[cls];
ffffffffc020486c:	0167b023          	sd	s6,0(a5)
        c->sheaf_cap = sheaf_cap;
ffffffffc0204870:	0057a423          	sw	t0,8(a5)
        c->barn_cap = barn_cap;
ffffffffc0204874:	0147a623          	sw	s4,12(a5)
        c->slab_pages = slab_pages;
ffffffffc0204878:	0117a823          	sw	a7,16(a5)
ffffffffc020487c:	96f6                	add	a3,a3,t4
ffffffffc020487e:	0006aa23          	sw	zero,20(a3)
    __sync_synchronize();
ffffffffc0204882:	0330000f          	fence	rw,rw
    lock->locked = 0;
ffffffffc0204886:	002a9893          	slli	a7,s5,0x2
ffffffffc020488a:	98d6                	add	a7,a7,s5
ffffffffc020488c:	088e                	slli	a7,a7,0x3
ffffffffc020488e:	98f2                	add	a7,a7,t3
        c->partial = NULL;
ffffffffc0204890:	0007bc23          	sd	zero,24(a5)
        c->empty = NULL;
ffffffffc0204894:	0207b023          	sd	zero,32(a5)
        c->nr_slabs = c->nr_slab_pages = 0;
ffffffffc0204898:	0207ac23          	sw	zero,56(a5)
        c->nr_partial = c->nr_empty = c->nr_full = 0;
ffffffffc020489c:	0207b423          	sd	zero,40(a5)
ffffffffc02048a0:	0207b823          	sd	zero,48(a5)
        c->inuse_objs = 0;
ffffffffc02048a4:	0407b023          	sd	zero,64(a5)
        c->stat_refill = c->stat_flush = 0;
ffffffffc02048a8:	0407b823          	sd	zero,80(a5)
ffffffffc02048ac:	0407b423          	sd	zero,72(a5)
        c->stat_slab_new = c->stat_slab_free = 0;
ffffffffc02048b0:	0607b023          	sd	zero,96(a5)
ffffffffc02048b4:	0407bc23          	sd	zero,88(a5)
        c->stat_page_fail = c->stat_desc_fail = 0;
ffffffffc02048b8:	0607b823          	sd	zero,112(a5)
ffffffffc02048bc:	0607b423          	sd	zero,104(a5)
ffffffffc02048c0:	0008a023          	sw	zero,0(a7)
    __sync_synchronize();
ffffffffc02048c4:	0330000f          	fence	rw,rw
            slub_cc[cpu][cls].spare.objs = slub_sheaf_store[cpu][cls] + sheaf_cap;
ffffffffc02048c8:	080e                	slli	a6,a6,0x3
ffffffffc02048ca:	981a                	add	a6,a6,t1
        slub_barns[cls].objs = slub_barn_store[cls];
ffffffffc02048cc:	01e5b423          	sd	t5,8(a1)
            slub_cc[cpu][cls].main.objs = slub_sheaf_store[cpu][cls];
ffffffffc02048d0:	00673023          	sd	t1,0(a4)
            slub_cc[cpu][cls].spare.objs = slub_sheaf_store[cpu][cls] + sheaf_cap;
ffffffffc02048d4:	01073823          	sd	a6,16(a4)
        slub_barns[cls].size = 0;
ffffffffc02048d8:	0005a823          	sw	zero,16(a1)
        slub_barns[cls].cap = barn_cap;
ffffffffc02048dc:	0145aa23          	sw	s4,20(a1)
        slub_barns[cls].stat_get = 0;
ffffffffc02048e0:	0005bc23          	sd	zero,24(a1)
        slub_barns[cls].stat_put = 0;
ffffffffc02048e4:	0205b023          	sd	zero,32(a1)
            slub_cc[cpu][cls].main.size = 0;
ffffffffc02048e8:	00072423          	sw	zero,8(a4)
            slub_cc[cpu][cls].main.cap = sheaf_cap;
ffffffffc02048ec:	00572623          	sw	t0,12(a4)
            slub_cc[cpu][cls].spare.size = 0;
ffffffffc02048f0:	00072c23          	sw	zero,24(a4)
            slub_cc[cpu][cls].spare.cap = sheaf_cap;
ffffffffc02048f4:	00572e23          	sw	t0,28(a4)
            slub_cs[cpu][cls].alloc_fast = 0;
ffffffffc02048f8:	00063023          	sd	zero,0(a2)
            slub_cs[cpu][cls].alloc_slow = 0;
ffffffffc02048fc:	00063423          	sd	zero,8(a2)
            slub_cs[cpu][cls].free_fast = 0;
ffffffffc0204900:	00063823          	sd	zero,16(a2)
            slub_cs[cpu][cls].free_slow = 0;
ffffffffc0204904:	00063c23          	sd	zero,24(a2)
            slub_cs[cpu][cls].user = 0;
ffffffffc0204908:	02063023          	sd	zero,32(a2)
    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
ffffffffc020490c:	46a1                	li	a3,8
ffffffffc020490e:	2485                	addiw	s1,s1,1
ffffffffc0204910:	9fb6                	add	t6,t6,a3
ffffffffc0204912:	07878793          	addi	a5,a5,120
ffffffffc0204916:	400f0f13          	addi	t5,t5,1024
ffffffffc020491a:	02858593          	addi	a1,a1,40
ffffffffc020491e:	20030313          	addi	t1,t1,512
ffffffffc0204922:	02070713          	addi	a4,a4,32
ffffffffc0204926:	02860613          	addi	a2,a2,40
ffffffffc020492a:	00d48b63          	beq	s1,a3,ffffffffc0204940 <slub_init+0x1e4>
            (slub_sizes[cls] <= 256) ? SLUB_SHEAF_MAX_CAP : 16;
ffffffffc020492e:	000fbb03          	ld	s6,0(t6)
ffffffffc0204932:	ef647ee3          	bgeu	s0,s6,ffffffffc020482e <slub_init+0xd2>
ffffffffc0204936:	4841                	li	a6,16
        unsigned int sheaf_cap =
ffffffffc0204938:	82c2                	mv	t0,a6
ffffffffc020493a:	04000a13          	li	s4,64
ffffffffc020493e:	bded                	j	ffffffffc0204838 <slub_init+0xdc>
    slub_inited = 1;
ffffffffc0204940:	4785                	li	a5,1
    slub_large_user = 0;
ffffffffc0204942:	00023717          	auipc	a4,0x23
ffffffffc0204946:	ec073723          	sd	zero,-306(a4) # ffffffffc0227810 <slub_large_user>
    slub_large_pages = 0;
ffffffffc020494a:	00023717          	auipc	a4,0x23
ffffffffc020494e:	ea073f23          	sd	zero,-322(a4) # ffffffffc0227808 <slub_large_pages>
    slub_fault_left = 0;
ffffffffc0204952:	00023717          	auipc	a4,0x23
ffffffffc0204956:	ea073723          	sd	zero,-338(a4) # ffffffffc0227800 <slub_fault_left>
    slub_fault_hit_cnt = 0;
ffffffffc020495a:	00023717          	auipc	a4,0x23
ffffffffc020495e:	e8073f23          	sd	zero,-354(a4) # ffffffffc02277f8 <slub_fault_hit_cnt>
    slub_inited = 1;
ffffffffc0204962:	00023717          	auipc	a4,0x23
ffffffffc0204966:	eaf72b23          	sw	a5,-330(a4) # ffffffffc0227818 <slub_inited>
        sz = slub_sizes[cls];
ffffffffc020496a:	00093403          	ld	s0,0(s2)
        p = kmalloc(sz);
ffffffffc020496e:	8522                	mv	a0,s0
ffffffffc0204970:	b2cff0ef          	jal	ffffffffc0203c9c <kmalloc>
ffffffffc0204974:	8a2a                	mv	s4,a0
        if (p == NULL) {
ffffffffc0204976:	16050763          	beqz	a0,ffffffffc0204ae4 <slub_init+0x388>
        if (((uintptr_t)p & (SLUB_MIN_ALIGN - 1)) != 0) {
ffffffffc020497a:	00f57713          	andi	a4,a0,15
ffffffffc020497e:	87aa                	mv	a5,a0
ffffffffc0204980:	16071f63          	bnez	a4,ffffffffc0204afe <slub_init+0x3a2>
        for (i = 0; i < sz; i++) p[i] = (unsigned char)(0x40 + cls + i);
ffffffffc0204984:	c815                	beqz	s0,ffffffffc02049b8 <slub_init+0x25c>
ffffffffc0204986:	0409881b          	addiw	a6,s3,64
ffffffffc020498a:	008505b3          	add	a1,a0,s0
ffffffffc020498e:	40a8083b          	subw	a6,a6,a0
ffffffffc0204992:	872a                	mv	a4,a0
ffffffffc0204994:	0107063b          	addw	a2,a4,a6
ffffffffc0204998:	00c70023          	sb	a2,0(a4)
ffffffffc020499c:	0705                	addi	a4,a4,1
ffffffffc020499e:	feb71be3          	bne	a4,a1,ffffffffc0204994 <slub_init+0x238>
            if (p[i] != (unsigned char)(0x40 + cls + i)) {
ffffffffc02049a2:	0007c603          	lbu	a2,0(a5)
ffffffffc02049a6:	0107873b          	addw	a4,a5,a6
ffffffffc02049aa:	0ff77713          	zext.b	a4,a4
ffffffffc02049ae:	0ae61a63          	bne	a2,a4,ffffffffc0204a62 <slub_init+0x306>
        for (i = 0; i < sz; i++) {
ffffffffc02049b2:	0785                	addi	a5,a5,1
ffffffffc02049b4:	feb797e3          	bne	a5,a1,ffffffffc02049a2 <slub_init+0x246>
        slub_check_ptr(p); /* 调试检查接口：活对象应通过校验 */
ffffffffc02049b8:	8552                	mv	a0,s4
ffffffffc02049ba:	b5fff0ef          	jal	ffffffffc0204518 <slub_check_ptr>
        kfree(p);
ffffffffc02049be:	8552                	mv	a0,s4
    for (cls = 0; cls < (int)SLUB_NCLASSES; cls++) {
ffffffffc02049c0:	2985                	addiw	s3,s3,1
        kfree(p);
ffffffffc02049c2:	c14ff0ef          	jal	ffffffffc0203dd6 <kfree>
    for (cls = 0; cls < (int)SLUB_NCLASSES; cls++) {
ffffffffc02049c6:	0921                	addi	s2,s2,8
ffffffffc02049c8:	fa9991e3          	bne	s3,s1,ffffffffc020496a <slub_init+0x20e>
    p = kmalloc(SLUB_MAX_SMALL_SIZE + 1);
ffffffffc02049cc:	6505                	lui	a0,0x1
ffffffffc02049ce:	80150513          	addi	a0,a0,-2047 # 801 <kern_entry-0xffffffffc01ff7ff>
ffffffffc02049d2:	acaff0ef          	jal	ffffffffc0203c9c <kmalloc>
    if (p == NULL) {
ffffffffc02049d6:	0e050b63          	beqz	a0,ffffffffc0204acc <slub_init+0x370>
    if (((uintptr_t)p & (SLUB_MIN_ALIGN - 1)) != 0) {
ffffffffc02049da:	00f57793          	andi	a5,a0,15
ffffffffc02049de:	872a                	mv	a4,a0
ffffffffc02049e0:	ebd5                	bnez	a5,ffffffffc0204a94 <slub_init+0x338>
ffffffffc02049e2:	7ff50613          	addi	a2,a0,2047
ffffffffc02049e6:	0609                	addi	a2,a2,2
ffffffffc02049e8:	87aa                	mv	a5,a0
ffffffffc02049ea:	4681                	li	a3,0
    for (i = 0; i < SLUB_MAX_SMALL_SIZE + 1; i++) p[i] = (unsigned char)(i * 3);
ffffffffc02049ec:	00d78023          	sb	a3,0(a5)
ffffffffc02049f0:	0785                	addi	a5,a5,1
ffffffffc02049f2:	268d                	addiw	a3,a3,3
ffffffffc02049f4:	fec79ce3          	bne	a5,a2,ffffffffc02049ec <slub_init+0x290>
ffffffffc02049f8:	4781                	li	a5,0
        if (p[i] != (unsigned char)(i * 3)) {
ffffffffc02049fa:	00074683          	lbu	a3,0(a4)
ffffffffc02049fe:	06f69f63          	bne	a3,a5,ffffffffc0204a7c <slub_init+0x320>
    for (i = 0; i < SLUB_MAX_SMALL_SIZE + 1; i++) {
ffffffffc0204a02:	278d                	addiw	a5,a5,3
ffffffffc0204a04:	0705                	addi	a4,a4,1
ffffffffc0204a06:	0ff7f793          	zext.b	a5,a5
ffffffffc0204a0a:	fec718e3          	bne	a4,a2,ffffffffc02049fa <slub_init+0x29e>
    slub_check_ptr(p);
ffffffffc0204a0e:	e42a                	sd	a0,8(sp)
ffffffffc0204a10:	b09ff0ef          	jal	ffffffffc0204518 <slub_check_ptr>
    kfree(p);
ffffffffc0204a14:	6522                	ld	a0,8(sp)
ffffffffc0204a16:	bc0ff0ef          	jal	ffffffffc0203dd6 <kfree>
    slub_port_printf("slub_smoke: 8 classes + large alloc/write/free OK\n");
ffffffffc0204a1a:	00004517          	auipc	a0,0x4
ffffffffc0204a1e:	2e650513          	addi	a0,a0,742 # ffffffffc0208d00 <etext+0x1a84>
ffffffffc0204a22:	f2efb0ef          	jal	ffffffffc0200150 <cprintf>
    if (slub_inited == 0) return;
ffffffffc0204a26:	00023797          	auipc	a5,0x23
ffffffffc0204a2a:	df27a783          	lw	a5,-526(a5) # ffffffffc0227818 <slub_inited>
ffffffffc0204a2e:	c399                	beqz	a5,ffffffffc0204a34 <slub_init+0x2d8>
ffffffffc0204a30:	82aff0ef          	jal	ffffffffc0203a5a <slub_shrink.part.0>
    return nr_free_pages();
ffffffffc0204a34:	e93fd0ef          	jal	ffffffffc02028c6 <nr_free_pages>
    slub_port_printf("slub_init: %d classes, %d cpus, fixed overhead %lu "
ffffffffc0204a38:	6406                	ld	s0,64(sp)
ffffffffc0204a3a:	74e2                	ld	s1,56(sp)
ffffffffc0204a3c:	7942                	ld	s2,48(sp)
ffffffffc0204a3e:	7a02                	ld	s4,32(sp)
ffffffffc0204a40:	6ae2                	ld	s5,24(sp)
ffffffffc0204a42:	6b42                	ld	s6,16(sp)
}
ffffffffc0204a44:	60a6                	ld	ra,72(sp)
ffffffffc0204a46:	79a2                	ld	s3,40(sp)
    slub_port_printf("slub_init: %d classes, %d cpus, fixed overhead %lu "
ffffffffc0204a48:	66c5                	lui	a3,0x11
ffffffffc0204a4a:	872a                	mv	a4,a0
ffffffffc0204a4c:	7b868693          	addi	a3,a3,1976 # 117b8 <kern_entry-0xffffffffc01ee848>
ffffffffc0204a50:	4605                	li	a2,1
ffffffffc0204a52:	45a1                	li	a1,8
ffffffffc0204a54:	00004517          	auipc	a0,0x4
ffffffffc0204a58:	2e450513          	addi	a0,a0,740 # ffffffffc0208d38 <etext+0x1abc>
}
ffffffffc0204a5c:	6161                	addi	sp,sp,80
    slub_port_printf("slub_init: %d classes, %d cpus, fixed overhead %lu "
ffffffffc0204a5e:	ef2fb06f          	j	ffffffffc0200150 <cprintf>
                slub_port_panic("slub_smoke: class %d data mismatch", cls);
ffffffffc0204a62:	86ce                	mv	a3,s3
ffffffffc0204a64:	00004617          	auipc	a2,0x4
ffffffffc0204a68:	1fc60613          	addi	a2,a2,508 # ffffffffc0208c60 <etext+0x19e4>
ffffffffc0204a6c:	55400593          	li	a1,1364
ffffffffc0204a70:	00004517          	auipc	a0,0x4
ffffffffc0204a74:	cb050513          	addi	a0,a0,-848 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0204a78:	f58fb0ef          	jal	ffffffffc02001d0 <__panic>
            slub_port_panic("slub_smoke: large object data mismatch");
ffffffffc0204a7c:	00004617          	auipc	a2,0x4
ffffffffc0204a80:	25c60613          	addi	a2,a2,604 # ffffffffc0208cd8 <etext+0x1a5c>
ffffffffc0204a84:	56600593          	li	a1,1382
ffffffffc0204a88:	00004517          	auipc	a0,0x4
ffffffffc0204a8c:	c9850513          	addi	a0,a0,-872 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0204a90:	f40fb0ef          	jal	ffffffffc02001d0 <__panic>
        slub_port_panic("slub_smoke: large alignment violated");
ffffffffc0204a94:	00004617          	auipc	a2,0x4
ffffffffc0204a98:	21c60613          	addi	a2,a2,540 # ffffffffc0208cb0 <etext+0x1a34>
ffffffffc0204a9c:	56100593          	li	a1,1377
ffffffffc0204aa0:	00004517          	auipc	a0,0x4
ffffffffc0204aa4:	c8050513          	addi	a0,a0,-896 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0204aa8:	f28fb0ef          	jal	ffffffffc02001d0 <__panic>
        slub_port_assert(slab_pages >= 1 && slab_pages <= SLUB_MAX_SLAB_PAGES);
ffffffffc0204aac:	00004697          	auipc	a3,0x4
ffffffffc0204ab0:	10468693          	addi	a3,a3,260 # ffffffffc0208bb0 <etext+0x1934>
ffffffffc0204ab4:	00003617          	auipc	a2,0x3
ffffffffc0204ab8:	a3460613          	addi	a2,a2,-1484 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0204abc:	58a00593          	li	a1,1418
ffffffffc0204ac0:	00004517          	auipc	a0,0x4
ffffffffc0204ac4:	c6050513          	addi	a0,a0,-928 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0204ac8:	f08fb0ef          	jal	ffffffffc02001d0 <__panic>
        slub_port_panic("slub_smoke: large allocation failed");
ffffffffc0204acc:	00004617          	auipc	a2,0x4
ffffffffc0204ad0:	1bc60613          	addi	a2,a2,444 # ffffffffc0208c88 <etext+0x1a0c>
ffffffffc0204ad4:	55e00593          	li	a1,1374
ffffffffc0204ad8:	00004517          	auipc	a0,0x4
ffffffffc0204adc:	c4850513          	addi	a0,a0,-952 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0204ae0:	ef0fb0ef          	jal	ffffffffc02001d0 <__panic>
            slub_port_panic("slub_smoke: class %d allocation failed", cls);
ffffffffc0204ae4:	86ce                	mv	a3,s3
ffffffffc0204ae6:	00004617          	auipc	a2,0x4
ffffffffc0204aea:	12a60613          	addi	a2,a2,298 # ffffffffc0208c10 <etext+0x1994>
ffffffffc0204aee:	54c00593          	li	a1,1356
ffffffffc0204af2:	00004517          	auipc	a0,0x4
ffffffffc0204af6:	c2e50513          	addi	a0,a0,-978 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0204afa:	ed6fb0ef          	jal	ffffffffc02001d0 <__panic>
            slub_port_panic("slub_smoke: class %d alignment violated", cls);
ffffffffc0204afe:	86ce                	mv	a3,s3
ffffffffc0204b00:	00004617          	auipc	a2,0x4
ffffffffc0204b04:	13860613          	addi	a2,a2,312 # ffffffffc0208c38 <etext+0x19bc>
ffffffffc0204b08:	54f00593          	li	a1,1359
ffffffffc0204b0c:	00004517          	auipc	a0,0x4
ffffffffc0204b10:	c1450513          	addi	a0,a0,-1004 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0204b14:	ebcfb0ef          	jal	ffffffffc02001d0 <__panic>
        slub_port_assert(slab_pages * SLUB_PAGE_SIZE / slub_sizes[cls] >=
ffffffffc0204b18:	00004697          	auipc	a3,0x4
ffffffffc0204b1c:	0c068693          	addi	a3,a3,192 # ffffffffc0208bd8 <etext+0x195c>
ffffffffc0204b20:	00003617          	auipc	a2,0x3
ffffffffc0204b24:	9c860613          	addi	a2,a2,-1592 # ffffffffc02074e8 <etext+0x26c>
ffffffffc0204b28:	58c00593          	li	a1,1420
ffffffffc0204b2c:	00004517          	auipc	a0,0x4
ffffffffc0204b30:	bf450513          	addi	a0,a0,-1036 # ffffffffc0208720 <etext+0x14a4>
ffffffffc0204b34:	e9cfb0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0204b38 <t_verify_all>:
    }
}

static void t_verify_all(void) {
    unsigned int i;
    for (i = 0; i < t_n; i++) {
ffffffffc0204b38:	00023317          	auipc	t1,0x23
ffffffffc0204b3c:	d1032303          	lw	t1,-752(t1) # ffffffffc0227848 <t_n>
ffffffffc0204b40:	2c030163          	beqz	t1,ffffffffc0204e02 <t_verify_all+0x2ca>
ffffffffc0204b44:	02031793          	slli	a5,t1,0x20
ffffffffc0204b48:	9381                	srli	a5,a5,0x20
ffffffffc0204b4a:	00179f93          	slli	t6,a5,0x1
static void t_verify_all(void) {
ffffffffc0204b4e:	715d                	addi	sp,sp,-80
    h *= 0x100000001B3UL;
ffffffffc0204b50:	4e05                	li	t3,1
ffffffffc0204b52:	9fbe                	add	t6,t6,a5
    unsigned long h = (unsigned long)id * 2654435761UL +
ffffffffc0204b54:	13c6f2b7          	lui	t0,0x13c6f
static void t_verify_all(void) {
ffffffffc0204b58:	f84a                	sd	s2,48(sp)
ffffffffc0204b5a:	0f8e                	slli	t6,t6,0x3
ffffffffc0204b5c:	0001c917          	auipc	s2,0x1c
ffffffffc0204b60:	04490913          	addi	s2,s2,68 # ffffffffc0220ba0 <t_objs>
    h *= 0x100000001B3UL;
ffffffffc0204b64:	1e22                	slli	t3,t3,0x28
    unsigned long h = (unsigned long)id * 2654435761UL +
ffffffffc0204b66:	028e                	slli	t0,t0,0x3
    for (i = 0; i < o->size; i++) {
ffffffffc0204b68:	6ea9                	lui	t4,0xa
static void t_verify_all(void) {
ffffffffc0204b6a:	e0a2                	sd	s0,64(sp)
ffffffffc0204b6c:	fc26                	sd	s1,56(sp)
ffffffffc0204b6e:	e486                	sd	ra,72(sp)
ffffffffc0204b70:	f44e                	sd	s3,40(sp)
ffffffffc0204b72:	f052                	sd	s4,32(sp)
ffffffffc0204b74:	ec56                	sd	s5,24(sp)
ffffffffc0204b76:	9fca                	add	t6,t6,s2
    unsigned long h = (unsigned long)id * 2654435761UL +
ffffffffc0204b78:	9b128293          	addi	t0,t0,-1615 # 13c6e9b1 <kern_entry-0xffffffffac59164f>
    h *= 0x100000001B3UL;
ffffffffc0204b7c:	1b3e0e13          	addi	t3,t3,435
    for (i = 0; i < t_n; i++) {
ffffffffc0204b80:	844a                	mv	s0,s2
ffffffffc0204b82:	8f4a                	mv	t5,s2
    for (i = 0; i < o->size; i++) {
ffffffffc0204b84:	e37e8e93          	addi	t4,t4,-457 # 9e37 <kern_entry-0xffffffffc01f61c9>
    h *= 0x100000001B3UL;
ffffffffc0204b88:	4485                	li	s1,1
    for (i = 0; i < o->size; i++) {
ffffffffc0204b8a:	008f3683          	ld	a3,8(t5)
ffffffffc0204b8e:	26068663          	beqz	a3,ffffffffc0204dfa <t_verify_all+0x2c2>
        unsigned char want = tpat(o->id, i, o->round);
ffffffffc0204b92:	010f2583          	lw	a1,16(t5)
ffffffffc0204b96:	014f2783          	lw	a5,20(t5)
        if (o->p[i] != want) {
ffffffffc0204b9a:	000f3603          	ld	a2,0(t5)
    unsigned long h = (unsigned long)id * 2654435761UL +
ffffffffc0204b9e:	02558533          	mul	a0,a1,t0
                      (unsigned long)round * 97UL;
ffffffffc0204ba2:	00179813          	slli	a6,a5,0x1
ffffffffc0204ba6:	983e                	add	a6,a6,a5
ffffffffc0204ba8:	0816                	slli	a6,a6,0x5
ffffffffc0204baa:	983e                	add	a6,a6,a5
    for (i = 0; i < o->size; i++) {
ffffffffc0204bac:	4701                	li	a4,0
ffffffffc0204bae:	9542                	add	a0,a0,a6
ffffffffc0204bb0:	a021                	j	ffffffffc0204bb8 <t_verify_all+0x80>
ffffffffc0204bb2:	0705                	addi	a4,a4,1
ffffffffc0204bb4:	24d70363          	beq	a4,a3,ffffffffc0204dfa <t_verify_all+0x2c2>
    h ^= h >> 11;
ffffffffc0204bb8:	00b55893          	srli	a7,a0,0xb
ffffffffc0204bbc:	00a8c8b3          	xor	a7,a7,a0
    h *= 0x100000001B3UL;
ffffffffc0204bc0:	03c888b3          	mul	a7,a7,t3
        if (o->p[i] != want) {
ffffffffc0204bc4:	00e60833          	add	a6,a2,a4
ffffffffc0204bc8:	00084803          	lbu	a6,0(a6)
    for (i = 0; i < o->size; i++) {
ffffffffc0204bcc:	9576                	add	a0,a0,t4
    return (unsigned char)(h >> 5);
ffffffffc0204bce:	0058d893          	srli	a7,a7,0x5
ffffffffc0204bd2:	0ff8f893          	zext.b	a7,a7
        if (o->p[i] != want) {
ffffffffc0204bd6:	fd088ee3          	beq	a7,a6,ffffffffc0204bb2 <t_verify_all+0x7a>
            slub_port_printf(
ffffffffc0204bda:	00004517          	auipc	a0,0x4
ffffffffc0204bde:	1ae50513          	addi	a0,a0,430 # ffffffffc0208d88 <etext+0x1b0c>
ffffffffc0204be2:	d6efb0ef          	jal	ffffffffc0200150 <cprintf>
        if (!t_verify_obj(&t_objs[i])) {
            TFAIL("live object content corrupted");
ffffffffc0204be6:	00023797          	auipc	a5,0x23
ffffffffc0204bea:	c697af23          	sw	s1,-898(a5) # ffffffffc0227864 <t_case_failed>
ffffffffc0204bee:	00023817          	auipc	a6,0x23
ffffffffc0204bf2:	c6a83803          	ld	a6,-918(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0204bf6:	00008797          	auipc	a5,0x8
ffffffffc0204bfa:	40a7a783          	lw	a5,1034(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0204bfe:	00023717          	auipc	a4,0x23
ffffffffc0204c02:	c6a73703          	ld	a4,-918(a4) # ffffffffc0227868 <t_iters>
ffffffffc0204c06:	00023697          	auipc	a3,0x23
ffffffffc0204c0a:	c6a6b683          	ld	a3,-918(a3) # ffffffffc0227870 <t_size>
ffffffffc0204c0e:	00008597          	auipc	a1,0x8
ffffffffc0204c12:	4025b583          	ld	a1,1026(a1) # ffffffffc020d010 <t_case>
ffffffffc0204c16:	00004617          	auipc	a2,0x4
ffffffffc0204c1a:	1c260613          	addi	a2,a2,450 # ffffffffc0208dd8 <etext+0x1b5c>
ffffffffc0204c1e:	00004517          	auipc	a0,0x4
ffffffffc0204c22:	1da50513          	addi	a0,a0,474 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0204c26:	d2afb0ef          	jal	ffffffffc0200150 <cprintf>
    for (i = 0; i < t_n; i++) {
ffffffffc0204c2a:	00023317          	auipc	t1,0x23
ffffffffc0204c2e:	c1e32303          	lw	t1,-994(t1) # ffffffffc0227848 <t_n>
ffffffffc0204c32:	1a030b63          	beqz	t1,ffffffffc0204de8 <t_verify_all+0x2b0>
ffffffffc0204c36:	0001b497          	auipc	s1,0x1b
ffffffffc0204c3a:	d6a48493          	addi	s1,s1,-662 # ffffffffc021f9a0 <idx.6>
    for (i = 0; i < t_n; i++) {
ffffffffc0204c3e:	89a6                	mv	s3,s1
ffffffffc0204c40:	8aa6                	mv	s5,s1
ffffffffc0204c42:	4a01                	li	s4,0
ffffffffc0204c44:	a031                	j	ffffffffc0204c50 <t_verify_all+0x118>
    for (i = 0; i < t_n; i++) {
ffffffffc0204c46:	2a05                	addiw	s4,s4,1
ffffffffc0204c48:	0a91                	addi	s5,s5,4
ffffffffc0204c4a:	0961                	addi	s2,s2,24
ffffffffc0204c4c:	066a7d63          	bgeu	s4,t1,ffffffffc0204cc6 <t_verify_all+0x18e>
        if (((uintptr_t)t_objs[i].p % SLUB_MIN_ALIGN) != 0) {
ffffffffc0204c50:	00093603          	ld	a2,0(s2)
        idx[i] = i;
ffffffffc0204c54:	014aa023          	sw	s4,0(s5)
        if (((uintptr_t)t_objs[i].p % SLUB_MIN_ALIGN) != 0) {
ffffffffc0204c58:	00f67793          	andi	a5,a2,15
ffffffffc0204c5c:	d7ed                	beqz	a5,ffffffffc0204c46 <t_verify_all+0x10e>
            slub_port_printf("  detail: obj id=%u ptr=%p\n", t_objs[i].id,
ffffffffc0204c5e:	01092583          	lw	a1,16(s2)
ffffffffc0204c62:	00004517          	auipc	a0,0x4
ffffffffc0204c66:	1de50513          	addi	a0,a0,478 # ffffffffc0208e40 <etext+0x1bc4>
    for (i = 0; i < t_n; i++) {
ffffffffc0204c6a:	2a05                	addiw	s4,s4,1
            slub_port_printf("  detail: obj id=%u ptr=%p\n", t_objs[i].id,
ffffffffc0204c6c:	ce4fb0ef          	jal	ffffffffc0200150 <cprintf>
            TFAIL("object not %d-byte aligned");
ffffffffc0204c70:	4605                	li	a2,1
ffffffffc0204c72:	00023817          	auipc	a6,0x23
ffffffffc0204c76:	be683803          	ld	a6,-1050(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0204c7a:	00008797          	auipc	a5,0x8
ffffffffc0204c7e:	3867a783          	lw	a5,902(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0204c82:	00023717          	auipc	a4,0x23
ffffffffc0204c86:	be673703          	ld	a4,-1050(a4) # ffffffffc0227868 <t_iters>
ffffffffc0204c8a:	00023697          	auipc	a3,0x23
ffffffffc0204c8e:	be66b683          	ld	a3,-1050(a3) # ffffffffc0227870 <t_size>
ffffffffc0204c92:	00008597          	auipc	a1,0x8
ffffffffc0204c96:	37e5b583          	ld	a1,894(a1) # ffffffffc020d010 <t_case>
ffffffffc0204c9a:	00023517          	auipc	a0,0x23
ffffffffc0204c9e:	bcc52523          	sw	a2,-1078(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0204ca2:	00004517          	auipc	a0,0x4
ffffffffc0204ca6:	15650513          	addi	a0,a0,342 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0204caa:	00004617          	auipc	a2,0x4
ffffffffc0204cae:	1b660613          	addi	a2,a2,438 # ffffffffc0208e60 <etext+0x1be4>
ffffffffc0204cb2:	c9efb0ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc0204cb6:	00023317          	auipc	t1,0x23
ffffffffc0204cba:	b9232303          	lw	t1,-1134(t1) # ffffffffc0227848 <t_n>
    for (i = 0; i < t_n; i++) {
ffffffffc0204cbe:	0a91                	addi	s5,s5,4
ffffffffc0204cc0:	0961                	addi	s2,s2,24
ffffffffc0204cc2:	f86a67e3          	bltu	s4,t1,ffffffffc0204c50 <t_verify_all+0x118>
    for (i = 1; i < t_n; i++) {
ffffffffc0204cc6:	4e05                	li	t3,1
ffffffffc0204cc8:	126e7063          	bgeu	t3,t1,ffffffffc0204de8 <t_verify_all+0x2b0>
ffffffffc0204ccc:	e85a                	sd	s6,16(sp)
ffffffffc0204cce:	e45e                	sd	s7,8(sp)
ffffffffc0204cd0:	0001be97          	auipc	t4,0x1b
ffffffffc0204cd4:	cd4e8e93          	addi	t4,t4,-812 # ffffffffc021f9a4 <idx.6+0x4>
ffffffffc0204cd8:	4801                	li	a6,0
ffffffffc0204cda:	5571                	li	a0,-4
        unsigned int v = idx[i];
ffffffffc0204cdc:	000eaf03          	lw	t5,0(t4)
                                 (uintptr_t)t_objs[v].p;
ffffffffc0204ce0:	8776                	mv	a4,t4
        for (j = i; j > 0 && (uintptr_t)t_objs[idx[j - 1]].p >
ffffffffc0204ce2:	86f2                	mv	a3,t3
                                 (uintptr_t)t_objs[v].p;
ffffffffc0204ce4:	020f1613          	slli	a2,t5,0x20
ffffffffc0204ce8:	9201                	srli	a2,a2,0x20
ffffffffc0204cea:	00161793          	slli	a5,a2,0x1
ffffffffc0204cee:	97b2                	add	a5,a5,a2
ffffffffc0204cf0:	078e                	slli	a5,a5,0x3
ffffffffc0204cf2:	97a2                	add	a5,a5,s0
ffffffffc0204cf4:	0007b883          	ld	a7,0(a5)
        for (j = i; j > 0 && (uintptr_t)t_objs[idx[j - 1]].p >
ffffffffc0204cf8:	00e507b3          	add	a5,a0,a4
ffffffffc0204cfc:	97c2                	add	a5,a5,a6
ffffffffc0204cfe:	438c                	lw	a1,0(a5)
ffffffffc0204d00:	02059613          	slli	a2,a1,0x20
ffffffffc0204d04:	9201                	srli	a2,a2,0x20
ffffffffc0204d06:	00161793          	slli	a5,a2,0x1
ffffffffc0204d0a:	97b2                	add	a5,a5,a2
ffffffffc0204d0c:	078e                	slli	a5,a5,0x3
ffffffffc0204d0e:	97a2                	add	a5,a5,s0
ffffffffc0204d10:	639c                	ld	a5,0(a5)
ffffffffc0204d12:	00f8f663          	bgeu	a7,a5,ffffffffc0204d1e <t_verify_all+0x1e6>
            idx[j] = idx[j - 1];
ffffffffc0204d16:	c30c                	sw	a1,0(a4)
        for (j = i; j > 0 && (uintptr_t)t_objs[idx[j - 1]].p >
ffffffffc0204d18:	36fd                	addiw	a3,a3,-1
ffffffffc0204d1a:	1771                	addi	a4,a4,-4
ffffffffc0204d1c:	fef1                	bnez	a3,ffffffffc0204cf8 <t_verify_all+0x1c0>
        idx[j] = v;
ffffffffc0204d1e:	02069793          	slli	a5,a3,0x20
ffffffffc0204d22:	01e7d693          	srli	a3,a5,0x1e
ffffffffc0204d26:	96ce                	add	a3,a3,s3
ffffffffc0204d28:	01e6a023          	sw	t5,0(a3)
    for (i = 1; i < t_n; i++) {
ffffffffc0204d2c:	2e05                	addiw	t3,t3,1
ffffffffc0204d2e:	0e91                	addi	t4,t4,4
ffffffffc0204d30:	1571                	addi	a0,a0,-4
ffffffffc0204d32:	0811                	addi	a6,a6,4
ffffffffc0204d34:	fbc314e3          	bne	t1,t3,ffffffffc0204cdc <t_verify_all+0x1a4>
    for (i = 1; i < t_n; i++) {
ffffffffc0204d38:	4b85                	li	s7,1
            TFAIL("live object ranges overlap");
ffffffffc0204d3a:	8b5e                	mv	s6,s7
ffffffffc0204d3c:	00023a97          	auipc	s5,0x23
ffffffffc0204d40:	b1ca8a93          	addi	s5,s5,-1252 # ffffffffc0227858 <t_seed_cfg>
    return (unsigned int)boot_hartid;
ffffffffc0204d44:	00008a17          	auipc	s4,0x8
ffffffffc0204d48:	2bca0a13          	addi	s4,s4,700 # ffffffffc020d000 <boot_hartid>
ffffffffc0204d4c:	00023997          	auipc	s3,0x23
ffffffffc0204d50:	b1c98993          	addi	s3,s3,-1252 # ffffffffc0227868 <t_iters>
ffffffffc0204d54:	00023917          	auipc	s2,0x23
ffffffffc0204d58:	b1c90913          	addi	s2,s2,-1252 # ffffffffc0227870 <t_size>
ffffffffc0204d5c:	a029                	j	ffffffffc0204d66 <t_verify_all+0x22e>
    for (i = 1; i < t_n; i++) {
ffffffffc0204d5e:	2b85                	addiw	s7,s7,1
ffffffffc0204d60:	0491                	addi	s1,s1,4
ffffffffc0204d62:	086bf163          	bgeu	s7,t1,ffffffffc0204de4 <t_verify_all+0x2ac>
        if ((uintptr_t)a->p + a->size > (uintptr_t)b->p) {
ffffffffc0204d66:	0004e703          	lwu	a4,0(s1)
ffffffffc0204d6a:	0044e683          	lwu	a3,4(s1)
ffffffffc0204d6e:	00171793          	slli	a5,a4,0x1
ffffffffc0204d72:	97ba                	add	a5,a5,a4
ffffffffc0204d74:	00169713          	slli	a4,a3,0x1
ffffffffc0204d78:	9736                	add	a4,a4,a3
ffffffffc0204d7a:	078e                	slli	a5,a5,0x3
ffffffffc0204d7c:	97a2                	add	a5,a5,s0
ffffffffc0204d7e:	070e                	slli	a4,a4,0x3
ffffffffc0204d80:	638c                	ld	a1,0(a5)
ffffffffc0204d82:	6790                	ld	a2,8(a5)
ffffffffc0204d84:	00e407b3          	add	a5,s0,a4
ffffffffc0204d88:	6394                	ld	a3,0(a5)
ffffffffc0204d8a:	00c58733          	add	a4,a1,a2
ffffffffc0204d8e:	fce6f8e3          	bgeu	a3,a4,ffffffffc0204d5e <t_verify_all+0x226>
            slub_port_printf("  detail: [%p,+%lu) overlaps [%p,+%lu)\n",
ffffffffc0204d92:	6798                	ld	a4,8(a5)
ffffffffc0204d94:	00004517          	auipc	a0,0x4
ffffffffc0204d98:	0ec50513          	addi	a0,a0,236 # ffffffffc0208e80 <etext+0x1c04>
    for (i = 1; i < t_n; i++) {
ffffffffc0204d9c:	2b85                	addiw	s7,s7,1
            slub_port_printf("  detail: [%p,+%lu) overlaps [%p,+%lu)\n",
ffffffffc0204d9e:	bb2fb0ef          	jal	ffffffffc0200150 <cprintf>
            TFAIL("live object ranges overlap");
ffffffffc0204da2:	000ab803          	ld	a6,0(s5)
ffffffffc0204da6:	000a2783          	lw	a5,0(s4)
ffffffffc0204daa:	0009b703          	ld	a4,0(s3)
ffffffffc0204dae:	00093683          	ld	a3,0(s2)
ffffffffc0204db2:	00008597          	auipc	a1,0x8
ffffffffc0204db6:	25e5b583          	ld	a1,606(a1) # ffffffffc020d010 <t_case>
ffffffffc0204dba:	00004617          	auipc	a2,0x4
ffffffffc0204dbe:	0ee60613          	addi	a2,a2,238 # ffffffffc0208ea8 <etext+0x1c2c>
ffffffffc0204dc2:	00004517          	auipc	a0,0x4
ffffffffc0204dc6:	03650513          	addi	a0,a0,54 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0204dca:	00023897          	auipc	a7,0x23
ffffffffc0204dce:	a968ad23          	sw	s6,-1382(a7) # ffffffffc0227864 <t_case_failed>
ffffffffc0204dd2:	b7efb0ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc0204dd6:	00023317          	auipc	t1,0x23
ffffffffc0204dda:	a7232303          	lw	t1,-1422(t1) # ffffffffc0227848 <t_n>
    for (i = 1; i < t_n; i++) {
ffffffffc0204dde:	0491                	addi	s1,s1,4
ffffffffc0204de0:	f86be3e3          	bltu	s7,t1,ffffffffc0204d66 <t_verify_all+0x22e>
ffffffffc0204de4:	6b42                	ld	s6,16(sp)
ffffffffc0204de6:	6ba2                	ld	s7,8(sp)
            slub_port_printf("  detail: invariant: %s\n", err);
            TFAIL("slub internal invariant violated");
        }
    }
#endif
}
ffffffffc0204de8:	60a6                	ld	ra,72(sp)
ffffffffc0204dea:	6406                	ld	s0,64(sp)
ffffffffc0204dec:	74e2                	ld	s1,56(sp)
ffffffffc0204dee:	7942                	ld	s2,48(sp)
ffffffffc0204df0:	79a2                	ld	s3,40(sp)
ffffffffc0204df2:	7a02                	ld	s4,32(sp)
ffffffffc0204df4:	6ae2                	ld	s5,24(sp)
ffffffffc0204df6:	6161                	addi	sp,sp,80
ffffffffc0204df8:	8082                	ret
    for (i = 0; i < t_n; i++) {
ffffffffc0204dfa:	0f61                	addi	t5,t5,24
ffffffffc0204dfc:	d9ff17e3          	bne	t5,t6,ffffffffc0204b8a <t_verify_all+0x52>
ffffffffc0204e00:	bd1d                	j	ffffffffc0204c36 <t_verify_all+0xfe>
ffffffffc0204e02:	8082                	ret

ffffffffc0204e04 <t_alloc>:

/* 分配并登记：非 NULL、16 对齐、写满请求范围 */
static struct tobj *t_alloc(size_t size) {
ffffffffc0204e04:	7179                	addi	sp,sp,-48
    struct tobj *o;
    unsigned char *p;
    size_t i;

    t_size = size;
    if (t_n >= TMAX_OBJS) {
ffffffffc0204e06:	00023717          	auipc	a4,0x23
ffffffffc0204e0a:	a4272703          	lw	a4,-1470(a4) # ffffffffc0227848 <t_n>
static struct tobj *t_alloc(size_t size) {
ffffffffc0204e0e:	f022                	sd	s0,32(sp)
ffffffffc0204e10:	ec26                	sd	s1,24(sp)
ffffffffc0204e12:	f406                	sd	ra,40(sp)
    t_size = size;
ffffffffc0204e14:	00023497          	auipc	s1,0x23
ffffffffc0204e18:	a5c48493          	addi	s1,s1,-1444 # ffffffffc0227870 <t_size>
ffffffffc0204e1c:	e088                	sd	a0,0(s1)
    if (t_n >= TMAX_OBJS) {
ffffffffc0204e1e:	47f00793          	li	a5,1151
static struct tobj *t_alloc(size_t size) {
ffffffffc0204e22:	842a                	mv	s0,a0
    if (t_n >= TMAX_OBJS) {
ffffffffc0204e24:	18e7e163          	bltu	a5,a4,ffffffffc0204fa6 <t_alloc+0x1a2>
        TFAIL("static object table exhausted");
        return NULL;
    }
    p = kmalloc(size);
ffffffffc0204e28:	e75fe0ef          	jal	ffffffffc0203c9c <kmalloc>
ffffffffc0204e2c:	88aa                	mv	a7,a0
    if (p == NULL) {
ffffffffc0204e2e:	22050063          	beqz	a0,ffffffffc020504e <t_alloc+0x24a>
        TFAIL("kmalloc returned NULL for a legal size");
        return NULL;
    }
    /* 活跃地址唯一性：不得把仍存活对象的地址再发一遍 */
    for (i = 0; i < t_n; i++) {
ffffffffc0204e32:	00023617          	auipc	a2,0x23
ffffffffc0204e36:	a1662603          	lw	a2,-1514(a2) # ffffffffc0227848 <t_n>
ffffffffc0204e3a:	c651                	beqz	a2,ffffffffc0204ec6 <t_alloc+0xc2>
ffffffffc0204e3c:	1602                	slli	a2,a2,0x20
ffffffffc0204e3e:	0001c517          	auipc	a0,0x1c
ffffffffc0204e42:	d6250513          	addi	a0,a0,-670 # ffffffffc0220ba0 <t_objs>
ffffffffc0204e46:	9201                	srli	a2,a2,0x20
ffffffffc0204e48:	87aa                	mv	a5,a0
ffffffffc0204e4a:	4701                	li	a4,0
ffffffffc0204e4c:	a021                	j	ffffffffc0204e54 <t_alloc+0x50>
ffffffffc0204e4e:	0705                	addi	a4,a4,1
ffffffffc0204e50:	06c70b63          	beq	a4,a2,ffffffffc0204ec6 <t_alloc+0xc2>
        if (t_objs[i].p == p) {
ffffffffc0204e54:	6394                	ld	a3,0(a5)
    for (i = 0; i < t_n; i++) {
ffffffffc0204e56:	07e1                	addi	a5,a5,24
        if (t_objs[i].p == p) {
ffffffffc0204e58:	ff169be3          	bne	a3,a7,ffffffffc0204e4e <t_alloc+0x4a>
            slub_port_printf(
                "  detail: ptr=%p size=%lu reissued to new id=%u, still live "
                "as id=%u size=%lu\n",
                (void *)p, (unsigned long)size, t_next_id, t_objs[i].id,
                (unsigned long)t_objs[i].size);
ffffffffc0204e5c:	00171793          	slli	a5,a4,0x1
ffffffffc0204e60:	97ba                	add	a5,a5,a4
ffffffffc0204e62:	078e                	slli	a5,a5,0x3
ffffffffc0204e64:	953e                	add	a0,a0,a5
            slub_port_printf(
ffffffffc0204e66:	651c                	ld	a5,8(a0)
ffffffffc0204e68:	4918                	lw	a4,16(a0)
ffffffffc0204e6a:	00023697          	auipc	a3,0x23
ffffffffc0204e6e:	9da6a683          	lw	a3,-1574(a3) # ffffffffc0227844 <t_next_id>
ffffffffc0204e72:	85c6                	mv	a1,a7
ffffffffc0204e74:	8622                	mv	a2,s0
ffffffffc0204e76:	00004517          	auipc	a0,0x4
ffffffffc0204e7a:	09a50513          	addi	a0,a0,154 # ffffffffc0208f10 <etext+0x1c94>
ffffffffc0204e7e:	e446                	sd	a7,8(sp)
ffffffffc0204e80:	ad0fb0ef          	jal	ffffffffc0200150 <cprintf>
            TFAIL("kmalloc reissued a still-live address");
ffffffffc0204e84:	4605                	li	a2,1
ffffffffc0204e86:	6094                	ld	a3,0(s1)
ffffffffc0204e88:	00023817          	auipc	a6,0x23
ffffffffc0204e8c:	9d083803          	ld	a6,-1584(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0204e90:	00008797          	auipc	a5,0x8
ffffffffc0204e94:	1707a783          	lw	a5,368(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0204e98:	00023717          	auipc	a4,0x23
ffffffffc0204e9c:	9d073703          	ld	a4,-1584(a4) # ffffffffc0227868 <t_iters>
ffffffffc0204ea0:	00008597          	auipc	a1,0x8
ffffffffc0204ea4:	1705b583          	ld	a1,368(a1) # ffffffffc020d010 <t_case>
ffffffffc0204ea8:	00023517          	auipc	a0,0x23
ffffffffc0204eac:	9ac52e23          	sw	a2,-1604(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0204eb0:	00004517          	auipc	a0,0x4
ffffffffc0204eb4:	f4850513          	addi	a0,a0,-184 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0204eb8:	00004617          	auipc	a2,0x4
ffffffffc0204ebc:	0a860613          	addi	a2,a2,168 # ffffffffc0208f60 <etext+0x1ce4>
ffffffffc0204ec0:	a90fb0ef          	jal	ffffffffc0200150 <cprintf>
            break;
ffffffffc0204ec4:	68a2                	ld	a7,8(sp)
        }
    }
    if (((uintptr_t)p % SLUB_MIN_ALIGN) != 0) {
ffffffffc0204ec6:	00f8f793          	andi	a5,a7,15
ffffffffc0204eca:	12079463          	bnez	a5,ffffffffc0204ff2 <t_alloc+0x1ee>
                         (unsigned long)size);
        TFAIL("kmalloc result not 16-byte aligned");
        kfree(p);
        return NULL;
    }
    o = &t_objs[t_n++];
ffffffffc0204ece:	00023797          	auipc	a5,0x23
ffffffffc0204ed2:	97a7a783          	lw	a5,-1670(a5) # ffffffffc0227848 <t_n>
    o->p = p;
    o->size = size;
    o->id = t_next_id++;
ffffffffc0204ed6:	00023717          	auipc	a4,0x23
ffffffffc0204eda:	96e72703          	lw	a4,-1682(a4) # ffffffffc0227844 <t_next_id>
    o->round = t_round;
ffffffffc0204ede:	00023617          	auipc	a2,0x23
ffffffffc0204ee2:	96262603          	lw	a2,-1694(a2) # ffffffffc0227840 <t_round>
    o = &t_objs[t_n++];
ffffffffc0204ee6:	02079593          	slli	a1,a5,0x20
ffffffffc0204eea:	9181                	srli	a1,a1,0x20
ffffffffc0204eec:	0017869b          	addiw	a3,a5,1
ffffffffc0204ef0:	00159793          	slli	a5,a1,0x1
ffffffffc0204ef4:	97ae                	add	a5,a5,a1
ffffffffc0204ef6:	078e                	slli	a5,a5,0x3
ffffffffc0204ef8:	0001c517          	auipc	a0,0x1c
ffffffffc0204efc:	ca850513          	addi	a0,a0,-856 # ffffffffc0220ba0 <t_objs>
ffffffffc0204f00:	953e                	add	a0,a0,a5
    o->id = t_next_id++;
ffffffffc0204f02:	0017079b          	addiw	a5,a4,1
    o = &t_objs[t_n++];
ffffffffc0204f06:	00023597          	auipc	a1,0x23
ffffffffc0204f0a:	94d5a123          	sw	a3,-1726(a1) # ffffffffc0227848 <t_n>
    o->p = p;
ffffffffc0204f0e:	01153023          	sd	a7,0(a0)
    o->size = size;
ffffffffc0204f12:	e500                	sd	s0,8(a0)
    o->id = t_next_id++;
ffffffffc0204f14:	c918                	sw	a4,16(a0)
    o->round = t_round;
ffffffffc0204f16:	c950                	sw	a2,20(a0)
    o->id = t_next_id++;
ffffffffc0204f18:	00023697          	auipc	a3,0x23
ffffffffc0204f1c:	92f6a623          	sw	a5,-1748(a3) # ffffffffc0227844 <t_next_id>
    for (i = 0; i < size; i++) p[i] = tpat(o->id, i, o->round);
ffffffffc0204f20:	cc35                	beqz	s0,ffffffffc0204f9c <t_alloc+0x198>
    unsigned long h = (unsigned long)id * 2654435761UL +
ffffffffc0204f22:	13c6f337          	lui	t1,0x13c6f
ffffffffc0204f26:	030e                	slli	t1,t1,0x3
ffffffffc0204f28:	9b130313          	addi	t1,t1,-1615 # 13c6e9b1 <kern_entry-0xffffffffac59164f>
ffffffffc0204f2c:	02670733          	mul	a4,a4,t1
                      (unsigned long)round * 97UL;
ffffffffc0204f30:	00161793          	slli	a5,a2,0x1
ffffffffc0204f34:	97b2                	add	a5,a5,a2
ffffffffc0204f36:	0796                	slli	a5,a5,0x5
ffffffffc0204f38:	97b2                	add	a5,a5,a2
    h *= 0x100000001B3UL;
ffffffffc0204f3a:	4e05                	li	t3,1
ffffffffc0204f3c:	1e22                	slli	t3,t3,0x28
ffffffffc0204f3e:	1b3e0e13          	addi	t3,t3,435
ffffffffc0204f42:	4685                	li	a3,1
ffffffffc0204f44:	97ba                	add	a5,a5,a4
    h ^= h >> 11;
ffffffffc0204f46:	00b7d713          	srli	a4,a5,0xb
ffffffffc0204f4a:	8fb9                	xor	a5,a5,a4
    h *= 0x100000001B3UL;
ffffffffc0204f4c:	03c787b3          	mul	a5,a5,t3
    return (unsigned char)(h >> 5);
ffffffffc0204f50:	8395                	srli	a5,a5,0x5
ffffffffc0204f52:	00f88023          	sb	a5,0(a7)
    for (i = 0; i < size; i++) p[i] = tpat(o->id, i, o->round);
ffffffffc0204f56:	04d40363          	beq	s0,a3,ffffffffc0204f9c <t_alloc+0x198>
ffffffffc0204f5a:	65a9                	lui	a1,0xa
ffffffffc0204f5c:	e3758593          	addi	a1,a1,-457 # 9e37 <kern_entry-0xffffffffc01f61c9>
ffffffffc0204f60:	00888833          	add	a6,a7,s0
ffffffffc0204f64:	96c6                	add	a3,a3,a7
ffffffffc0204f66:	8eae                	mv	t4,a1
ffffffffc0204f68:	88aa                	mv	a7,a0
    unsigned long h = (unsigned long)id * 2654435761UL +
ffffffffc0204f6a:	0108e783          	lwu	a5,16(a7)
                      (unsigned long)round * 97UL;
ffffffffc0204f6e:	0148e603          	lwu	a2,20(a7)
    for (i = 0; i < size; i++) p[i] = tpat(o->id, i, o->round);
ffffffffc0204f72:	0685                	addi	a3,a3,1
    unsigned long h = (unsigned long)id * 2654435761UL +
ffffffffc0204f74:	026787b3          	mul	a5,a5,t1
                      (unsigned long)round * 97UL;
ffffffffc0204f78:	00161713          	slli	a4,a2,0x1
ffffffffc0204f7c:	9732                	add	a4,a4,a2
ffffffffc0204f7e:	0716                	slli	a4,a4,0x5
ffffffffc0204f80:	9732                	add	a4,a4,a2
    unsigned long h = (unsigned long)id * 2654435761UL +
ffffffffc0204f82:	97ba                	add	a5,a5,a4
ffffffffc0204f84:	97ae                	add	a5,a5,a1
    h ^= h >> 11;
ffffffffc0204f86:	00b7d713          	srli	a4,a5,0xb
ffffffffc0204f8a:	8fb9                	xor	a5,a5,a4
    h *= 0x100000001B3UL;
ffffffffc0204f8c:	03c787b3          	mul	a5,a5,t3
    for (i = 0; i < size; i++) p[i] = tpat(o->id, i, o->round);
ffffffffc0204f90:	95f6                	add	a1,a1,t4
    return (unsigned char)(h >> 5);
ffffffffc0204f92:	8395                	srli	a5,a5,0x5
ffffffffc0204f94:	fef68fa3          	sb	a5,-1(a3)
    for (i = 0; i < size; i++) p[i] = tpat(o->id, i, o->round);
ffffffffc0204f98:	fcd819e3          	bne	a6,a3,ffffffffc0204f6a <t_alloc+0x166>
    TVALIDATE_OP("t_alloc");
    return o;
}
ffffffffc0204f9c:	70a2                	ld	ra,40(sp)
ffffffffc0204f9e:	7402                	ld	s0,32(sp)
ffffffffc0204fa0:	64e2                	ld	s1,24(sp)
ffffffffc0204fa2:	6145                	addi	sp,sp,48
ffffffffc0204fa4:	8082                	ret
        TFAIL("static object table exhausted");
ffffffffc0204fa6:	4605                	li	a2,1
ffffffffc0204fa8:	00023817          	auipc	a6,0x23
ffffffffc0204fac:	8b083803          	ld	a6,-1872(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0204fb0:	00008797          	auipc	a5,0x8
ffffffffc0204fb4:	0507a783          	lw	a5,80(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0204fb8:	00023717          	auipc	a4,0x23
ffffffffc0204fbc:	8b073703          	ld	a4,-1872(a4) # ffffffffc0227868 <t_iters>
ffffffffc0204fc0:	00008597          	auipc	a1,0x8
ffffffffc0204fc4:	0505b583          	ld	a1,80(a1) # ffffffffc020d010 <t_case>
ffffffffc0204fc8:	86aa                	mv	a3,a0
ffffffffc0204fca:	00023517          	auipc	a0,0x23
ffffffffc0204fce:	88c52d23          	sw	a2,-1894(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0204fd2:	00004517          	auipc	a0,0x4
ffffffffc0204fd6:	e2650513          	addi	a0,a0,-474 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0204fda:	00004617          	auipc	a2,0x4
ffffffffc0204fde:	eee60613          	addi	a2,a2,-274 # ffffffffc0208ec8 <etext+0x1c4c>
ffffffffc0204fe2:	96efb0ef          	jal	ffffffffc0200150 <cprintf>
        return NULL;
ffffffffc0204fe6:	4501                	li	a0,0
}
ffffffffc0204fe8:	70a2                	ld	ra,40(sp)
ffffffffc0204fea:	7402                	ld	s0,32(sp)
ffffffffc0204fec:	64e2                	ld	s1,24(sp)
ffffffffc0204fee:	6145                	addi	sp,sp,48
ffffffffc0204ff0:	8082                	ret
        slub_port_printf("  detail: ptr=%p size=%lu\n", (void *)p,
ffffffffc0204ff2:	85c6                	mv	a1,a7
ffffffffc0204ff4:	8622                	mv	a2,s0
ffffffffc0204ff6:	00004517          	auipc	a0,0x4
ffffffffc0204ffa:	f9250513          	addi	a0,a0,-110 # ffffffffc0208f88 <etext+0x1d0c>
ffffffffc0204ffe:	e446                	sd	a7,8(sp)
ffffffffc0205000:	950fb0ef          	jal	ffffffffc0200150 <cprintf>
        TFAIL("kmalloc result not 16-byte aligned");
ffffffffc0205004:	6094                	ld	a3,0(s1)
ffffffffc0205006:	00023817          	auipc	a6,0x23
ffffffffc020500a:	85283803          	ld	a6,-1966(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc020500e:	00008797          	auipc	a5,0x8
ffffffffc0205012:	ff27a783          	lw	a5,-14(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0205016:	00023717          	auipc	a4,0x23
ffffffffc020501a:	85273703          	ld	a4,-1966(a4) # ffffffffc0227868 <t_iters>
ffffffffc020501e:	00008597          	auipc	a1,0x8
ffffffffc0205022:	ff25b583          	ld	a1,-14(a1) # ffffffffc020d010 <t_case>
ffffffffc0205026:	4605                	li	a2,1
ffffffffc0205028:	00023517          	auipc	a0,0x23
ffffffffc020502c:	82c52e23          	sw	a2,-1988(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0205030:	00004517          	auipc	a0,0x4
ffffffffc0205034:	dc850513          	addi	a0,a0,-568 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0205038:	00004617          	auipc	a2,0x4
ffffffffc020503c:	f7060613          	addi	a2,a2,-144 # ffffffffc0208fa8 <etext+0x1d2c>
ffffffffc0205040:	910fb0ef          	jal	ffffffffc0200150 <cprintf>
        kfree(p);
ffffffffc0205044:	6522                	ld	a0,8(sp)
ffffffffc0205046:	d91fe0ef          	jal	ffffffffc0203dd6 <kfree>
        return NULL;
ffffffffc020504a:	4501                	li	a0,0
ffffffffc020504c:	bf71                	j	ffffffffc0204fe8 <t_alloc+0x1e4>
        TFAIL("kmalloc returned NULL for a legal size");
ffffffffc020504e:	4605                	li	a2,1
ffffffffc0205050:	6094                	ld	a3,0(s1)
ffffffffc0205052:	00023817          	auipc	a6,0x23
ffffffffc0205056:	80683803          	ld	a6,-2042(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc020505a:	00008797          	auipc	a5,0x8
ffffffffc020505e:	fa67a783          	lw	a5,-90(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0205062:	00023717          	auipc	a4,0x23
ffffffffc0205066:	80673703          	ld	a4,-2042(a4) # ffffffffc0227868 <t_iters>
ffffffffc020506a:	00008597          	auipc	a1,0x8
ffffffffc020506e:	fa65b583          	ld	a1,-90(a1) # ffffffffc020d010 <t_case>
ffffffffc0205072:	00022517          	auipc	a0,0x22
ffffffffc0205076:	7ec52923          	sw	a2,2034(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc020507a:	00004517          	auipc	a0,0x4
ffffffffc020507e:	d7e50513          	addi	a0,a0,-642 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0205082:	00004617          	auipc	a2,0x4
ffffffffc0205086:	e6660613          	addi	a2,a2,-410 # ffffffffc0208ee8 <etext+0x1c6c>
ffffffffc020508a:	8c6fb0ef          	jal	ffffffffc0200150 <cprintf>
        return NULL;
ffffffffc020508e:	4501                	li	a0,0
ffffffffc0205090:	bfa1                	j	ffffffffc0204fe8 <t_alloc+0x1e4>

ffffffffc0205092 <t_free_at>:

/* 释放第 i 个存活对象（保持其余对象相对顺序） */
static void t_free_at(unsigned int i) {
ffffffffc0205092:	7179                	addi	sp,sp,-48
ffffffffc0205094:	ec26                	sd	s1,24(sp)
    kfree(t_objs[i].p);
ffffffffc0205096:	02051493          	slli	s1,a0,0x20
ffffffffc020509a:	9081                	srli	s1,s1,0x20
ffffffffc020509c:	00149713          	slli	a4,s1,0x1
ffffffffc02050a0:	9726                	add	a4,a4,s1
static void t_free_at(unsigned int i) {
ffffffffc02050a2:	e84a                	sd	s2,16(sp)
    kfree(t_objs[i].p);
ffffffffc02050a4:	070e                	slli	a4,a4,0x3
ffffffffc02050a6:	0001c917          	auipc	s2,0x1c
ffffffffc02050aa:	afa90913          	addi	s2,s2,-1286 # ffffffffc0220ba0 <t_objs>
ffffffffc02050ae:	974a                	add	a4,a4,s2
static void t_free_at(unsigned int i) {
ffffffffc02050b0:	f022                	sd	s0,32(sp)
ffffffffc02050b2:	842a                	mv	s0,a0
    kfree(t_objs[i].p);
ffffffffc02050b4:	6308                	ld	a0,0(a4)
ffffffffc02050b6:	e43a                	sd	a4,8(sp)
static void t_free_at(unsigned int i) {
ffffffffc02050b8:	f406                	sd	ra,40(sp)
    kfree(t_objs[i].p);
ffffffffc02050ba:	d1dfe0ef          	jal	ffffffffc0203dd6 <kfree>
    for (; i + 1 < t_n; i++) t_objs[i] = t_objs[i + 1];
ffffffffc02050be:	00022617          	auipc	a2,0x22
ffffffffc02050c2:	78a62603          	lw	a2,1930(a2) # ffffffffc0227848 <t_n>
ffffffffc02050c6:	0014051b          	addiw	a0,s0,1
ffffffffc02050ca:	6722                	ld	a4,8(sp)
ffffffffc02050cc:	04c57063          	bgeu	a0,a2,ffffffffc020510c <t_free_at+0x7a>
ffffffffc02050d0:	367d                	addiw	a2,a2,-1
ffffffffc02050d2:	a011                	j	ffffffffc02050d6 <t_free_at+0x44>
ffffffffc02050d4:	2505                	addiw	a0,a0,1
ffffffffc02050d6:	00149793          	slli	a5,s1,0x1
ffffffffc02050da:	6f14                	ld	a3,24(a4)
ffffffffc02050dc:	97a6                	add	a5,a5,s1
ffffffffc02050de:	078e                	slli	a5,a5,0x3
ffffffffc02050e0:	97ca                	add	a5,a5,s2
ffffffffc02050e2:	e394                	sd	a3,0(a5)
ffffffffc02050e4:	7314                	ld	a3,32(a4)
ffffffffc02050e6:	02051493          	slli	s1,a0,0x20
ffffffffc02050ea:	9081                	srli	s1,s1,0x20
ffffffffc02050ec:	e794                	sd	a3,8(a5)
ffffffffc02050ee:	7714                	ld	a3,40(a4)
ffffffffc02050f0:	0761                	addi	a4,a4,24
ffffffffc02050f2:	eb94                	sd	a3,16(a5)
ffffffffc02050f4:	fec510e3          	bne	a0,a2,ffffffffc02050d4 <t_free_at+0x42>
    t_n--;
    TVALIDATE_OP("t_free_at");
}
ffffffffc02050f8:	70a2                	ld	ra,40(sp)
ffffffffc02050fa:	7402                	ld	s0,32(sp)
    t_n--;
ffffffffc02050fc:	00022797          	auipc	a5,0x22
ffffffffc0205100:	74c7a623          	sw	a2,1868(a5) # ffffffffc0227848 <t_n>
}
ffffffffc0205104:	64e2                	ld	s1,24(sp)
ffffffffc0205106:	6942                	ld	s2,16(sp)
ffffffffc0205108:	6145                	addi	sp,sp,48
ffffffffc020510a:	8082                	ret
ffffffffc020510c:	70a2                	ld	ra,40(sp)
ffffffffc020510e:	7402                	ld	s0,32(sp)
ffffffffc0205110:	367d                	addiw	a2,a2,-1
    t_n--;
ffffffffc0205112:	00022797          	auipc	a5,0x22
ffffffffc0205116:	72c7ab23          	sw	a2,1846(a5) # ffffffffc0227848 <t_n>
}
ffffffffc020511a:	64e2                	ld	s1,24(sp)
ffffffffc020511c:	6942                	ld	s2,16(sp)
ffffffffc020511e:	6145                	addi	sp,sp,48
ffffffffc0205120:	8082                	ret

ffffffffc0205122 <t_expect_baseline>:

/* ------------------------- 全局基线 / 统计快照 ------------------------- */

static size_t t_baseline; /* slub_shrink 后的空闲页基线（含固定元数据开销） */

static void t_expect_baseline(const char *why) {
ffffffffc0205122:	1141                	addi	sp,sp,-16
ffffffffc0205124:	e022                	sd	s0,0(sp)
ffffffffc0205126:	e406                	sd	ra,8(sp)
ffffffffc0205128:	842a                	mv	s0,a0
    return nr_free_pages();
ffffffffc020512a:	f9cfd0ef          	jal	ffffffffc02028c6 <nr_free_pages>
    size_t free_pages = slub_port_nr_free_pages();
    if (free_pages != t_baseline) {
ffffffffc020512e:	00022617          	auipc	a2,0x22
ffffffffc0205132:	70a63603          	ld	a2,1802(a2) # ffffffffc0227838 <t_baseline>
ffffffffc0205136:	04a60963          	beq	a2,a0,ffffffffc0205188 <t_expect_baseline+0x66>
        slub_port_printf("  detail: free_pages=%lu baseline=%lu\n",
ffffffffc020513a:	85aa                	mv	a1,a0
ffffffffc020513c:	00004517          	auipc	a0,0x4
ffffffffc0205140:	e9450513          	addi	a0,a0,-364 # ffffffffc0208fd0 <etext+0x1d54>
ffffffffc0205144:	80cfb0ef          	jal	ffffffffc0200150 <cprintf>
                         (unsigned long)free_pages,
                         (unsigned long)t_baseline);
        TFAIL(why);
ffffffffc0205148:	00022817          	auipc	a6,0x22
ffffffffc020514c:	71083803          	ld	a6,1808(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0205150:	00008797          	auipc	a5,0x8
ffffffffc0205154:	eb07a783          	lw	a5,-336(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0205158:	00022717          	auipc	a4,0x22
ffffffffc020515c:	71073703          	ld	a4,1808(a4) # ffffffffc0227868 <t_iters>
ffffffffc0205160:	00022697          	auipc	a3,0x22
ffffffffc0205164:	7106b683          	ld	a3,1808(a3) # ffffffffc0227870 <t_size>
ffffffffc0205168:	00008597          	auipc	a1,0x8
ffffffffc020516c:	ea85b583          	ld	a1,-344(a1) # ffffffffc020d010 <t_case>
ffffffffc0205170:	4885                	li	a7,1
ffffffffc0205172:	8622                	mv	a2,s0
ffffffffc0205174:	00004517          	auipc	a0,0x4
ffffffffc0205178:	c8450513          	addi	a0,a0,-892 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc020517c:	00022317          	auipc	t1,0x22
ffffffffc0205180:	6f132423          	sw	a7,1768(t1) # ffffffffc0227864 <t_case_failed>
ffffffffc0205184:	fcdfa0ef          	jal	ffffffffc0200150 <cprintf>
    }
    if (slub_user_objects() != 0) {
ffffffffc0205188:	998ff0ef          	jal	ffffffffc0204320 <slub_user_objects>
ffffffffc020518c:	e901                	bnez	a0,ffffffffc020519c <t_expect_baseline+0x7a>
        slub_port_printf("  detail: user_objects=%lu\n",
                         (unsigned long)slub_user_objects());
        TFAIL("user object count not zero after full free + shrink");
    }
    if (slub_slab_pages() != 0) {
ffffffffc020518e:	a12ff0ef          	jal	ffffffffc02043a0 <slub_slab_pages>
ffffffffc0205192:	e525                	bnez	a0,ffffffffc02051fa <t_expect_baseline+0xd8>
        slub_port_printf("  detail: slab_pages=%lu\n",
                         (unsigned long)slub_slab_pages());
        TFAIL("slub still holds pages after full free + shrink");
    }
}
ffffffffc0205194:	60a2                	ld	ra,8(sp)
ffffffffc0205196:	6402                	ld	s0,0(sp)
ffffffffc0205198:	0141                	addi	sp,sp,16
ffffffffc020519a:	8082                	ret
                         (unsigned long)slub_user_objects());
ffffffffc020519c:	984ff0ef          	jal	ffffffffc0204320 <slub_user_objects>
ffffffffc02051a0:	85aa                	mv	a1,a0
        slub_port_printf("  detail: user_objects=%lu\n",
ffffffffc02051a2:	00004517          	auipc	a0,0x4
ffffffffc02051a6:	e5650513          	addi	a0,a0,-426 # ffffffffc0208ff8 <etext+0x1d7c>
ffffffffc02051aa:	fa7fa0ef          	jal	ffffffffc0200150 <cprintf>
        TFAIL("user object count not zero after full free + shrink");
ffffffffc02051ae:	4605                	li	a2,1
ffffffffc02051b0:	00022817          	auipc	a6,0x22
ffffffffc02051b4:	6a883803          	ld	a6,1704(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc02051b8:	00008797          	auipc	a5,0x8
ffffffffc02051bc:	e487a783          	lw	a5,-440(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc02051c0:	00022717          	auipc	a4,0x22
ffffffffc02051c4:	6a873703          	ld	a4,1704(a4) # ffffffffc0227868 <t_iters>
ffffffffc02051c8:	00022697          	auipc	a3,0x22
ffffffffc02051cc:	6a86b683          	ld	a3,1704(a3) # ffffffffc0227870 <t_size>
ffffffffc02051d0:	00008597          	auipc	a1,0x8
ffffffffc02051d4:	e405b583          	ld	a1,-448(a1) # ffffffffc020d010 <t_case>
ffffffffc02051d8:	00022517          	auipc	a0,0x22
ffffffffc02051dc:	68c52623          	sw	a2,1676(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc02051e0:	00004517          	auipc	a0,0x4
ffffffffc02051e4:	c1850513          	addi	a0,a0,-1000 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc02051e8:	00004617          	auipc	a2,0x4
ffffffffc02051ec:	e3060613          	addi	a2,a2,-464 # ffffffffc0209018 <etext+0x1d9c>
ffffffffc02051f0:	f61fa0ef          	jal	ffffffffc0200150 <cprintf>
    if (slub_slab_pages() != 0) {
ffffffffc02051f4:	9acff0ef          	jal	ffffffffc02043a0 <slub_slab_pages>
ffffffffc02051f8:	dd51                	beqz	a0,ffffffffc0205194 <t_expect_baseline+0x72>
                         (unsigned long)slub_slab_pages());
ffffffffc02051fa:	9a6ff0ef          	jal	ffffffffc02043a0 <slub_slab_pages>
ffffffffc02051fe:	85aa                	mv	a1,a0
        slub_port_printf("  detail: slab_pages=%lu\n",
ffffffffc0205200:	00004517          	auipc	a0,0x4
ffffffffc0205204:	e5050513          	addi	a0,a0,-432 # ffffffffc0209050 <etext+0x1dd4>
ffffffffc0205208:	f49fa0ef          	jal	ffffffffc0200150 <cprintf>
}
ffffffffc020520c:	6402                	ld	s0,0(sp)
ffffffffc020520e:	60a2                	ld	ra,8(sp)
        TFAIL("slub still holds pages after full free + shrink");
ffffffffc0205210:	4605                	li	a2,1
ffffffffc0205212:	00022817          	auipc	a6,0x22
ffffffffc0205216:	64683803          	ld	a6,1606(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc020521a:	00008797          	auipc	a5,0x8
ffffffffc020521e:	de67a783          	lw	a5,-538(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0205222:	00022717          	auipc	a4,0x22
ffffffffc0205226:	64673703          	ld	a4,1606(a4) # ffffffffc0227868 <t_iters>
ffffffffc020522a:	00022697          	auipc	a3,0x22
ffffffffc020522e:	6466b683          	ld	a3,1606(a3) # ffffffffc0227870 <t_size>
ffffffffc0205232:	00008597          	auipc	a1,0x8
ffffffffc0205236:	dde5b583          	ld	a1,-546(a1) # ffffffffc020d010 <t_case>
ffffffffc020523a:	00022517          	auipc	a0,0x22
ffffffffc020523e:	62c52523          	sw	a2,1578(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0205242:	00004617          	auipc	a2,0x4
ffffffffc0205246:	e2e60613          	addi	a2,a2,-466 # ffffffffc0209070 <etext+0x1df4>
ffffffffc020524a:	00004517          	auipc	a0,0x4
ffffffffc020524e:	bae50513          	addi	a0,a0,-1106 # ffffffffc0208df8 <etext+0x1b7c>
}
ffffffffc0205252:	0141                	addi	sp,sp,16
        TFAIL("slub still holds pages after full free + shrink");
ffffffffc0205254:	efdfa06f          	j	ffffffffc0200150 <cprintf>

ffffffffc0205258 <case_shrink_baseline>:
    }
}

/* ------------------------- 用例 9：回收基线（混合分配/全释放/排空/shrink） ------------------------- */

static void case_shrink_baseline(void) {
ffffffffc0205258:	7139                	addi	sp,sp,-64
ffffffffc020525a:	fc06                	sd	ra,56(sp)
ffffffffc020525c:	f822                	sd	s0,48(sp)
ffffffffc020525e:	f426                	sd	s1,40(sp)
ffffffffc0205260:	f04a                	sd	s2,32(sp)
ffffffffc0205262:	ec4e                	sd	s3,24(sp)
ffffffffc0205264:	e852                	sd	s4,16(sp)
ffffffffc0205266:	e456                	sd	s5,8(sp)
ffffffffc0205268:	e05a                	sd	s6,0(sp)
    static const size_t sizes[] = {16, 64, 256, 1024, 3000, 9000};
    unsigned int round, k;

    slub_shrink();
ffffffffc020526a:	e4ffe0ef          	jal	ffffffffc02040b8 <slub_shrink>
ffffffffc020526e:	e58fd0ef          	jal	ffffffffc02028c6 <nr_free_pages>
    t_baseline = slub_port_nr_free_pages();
ffffffffc0205272:	00022797          	auipc	a5,0x22
ffffffffc0205276:	5ca7b323          	sd	a0,1478(a5) # ffffffffc0227838 <t_baseline>
    if (slub_slab_pages() != 0 || slub_user_objects() != 0)
ffffffffc020527a:	926ff0ef          	jal	ffffffffc02043a0 <slub_slab_pages>
ffffffffc020527e:	0e051d63          	bnez	a0,ffffffffc0205378 <case_shrink_baseline+0x120>
ffffffffc0205282:	89eff0ef          	jal	ffffffffc0204320 <slub_user_objects>
ffffffffc0205286:	0e051963          	bnez	a0,ffffffffc0205378 <case_shrink_baseline+0x120>
        TFAIL("not clean after shrink at suite start");

    for (round = 0; round < 3; round++) {
        t_round = round;
        for (k = 0; k < 240; k++) {
            if (t_alloc(sizes[trand() % 6]) == NULL) break;
ffffffffc020528a:	aaaab7b7          	lui	a5,0xaaaab
ffffffffc020528e:	aab78793          	addi	a5,a5,-1365 # ffffffffaaaaaaab <kern_entry-0x15755555>
ffffffffc0205292:	02079413          	slli	s0,a5,0x20
ffffffffc0205296:	943e                	add	s0,s0,a5
static void case_shrink_baseline(void) {
ffffffffc0205298:	4901                	li	s2,0
ffffffffc020529a:	00022a17          	auipc	s4,0x22
ffffffffc020529e:	5b6a0a13          	addi	s4,s4,1462 # ffffffffc0227850 <t_rng>
ffffffffc02052a2:	00005497          	auipc	s1,0x5
ffffffffc02052a6:	93648493          	addi	s1,s1,-1738 # ffffffffc0209bd8 <sizes.5>
            t_iters++;
ffffffffc02052aa:	00022a97          	auipc	s5,0x22
ffffffffc02052ae:	5bea8a93          	addi	s5,s5,1470 # ffffffffc0227868 <t_iters>
    for (round = 0; round < 3; round++) {
ffffffffc02052b2:	498d                	li	s3,3
        t_round = round;
ffffffffc02052b4:	00022797          	auipc	a5,0x22
ffffffffc02052b8:	5927a623          	sw	s2,1420(a5) # ffffffffc0227840 <t_round>
ffffffffc02052bc:	0f000b13          	li	s6,240
ffffffffc02052c0:	a801                	j	ffffffffc02052d0 <case_shrink_baseline+0x78>
            t_iters++;
ffffffffc02052c2:	000ab783          	ld	a5,0(s5)
ffffffffc02052c6:	0785                	addi	a5,a5,1
ffffffffc02052c8:	00fab023          	sd	a5,0(s5)
        for (k = 0; k < 240; k++) {
ffffffffc02052cc:	020b0e63          	beqz	s6,ffffffffc0205308 <case_shrink_baseline+0xb0>
    unsigned long x = t_rng;
ffffffffc02052d0:	000a3783          	ld	a5,0(s4)
        for (k = 0; k < 240; k++) {
ffffffffc02052d4:	3b7d                	addiw	s6,s6,-1
    x ^= x << 13;
ffffffffc02052d6:	00d79713          	slli	a4,a5,0xd
ffffffffc02052da:	8fb9                	xor	a5,a5,a4
    x ^= x >> 7;
ffffffffc02052dc:	0077d713          	srli	a4,a5,0x7
ffffffffc02052e0:	8fb9                	xor	a5,a5,a4
    x ^= x << 17;
ffffffffc02052e2:	01179713          	slli	a4,a5,0x11
ffffffffc02052e6:	8fb9                	xor	a5,a5,a4
            if (t_alloc(sizes[trand() % 6]) == NULL) break;
ffffffffc02052e8:	0287b6b3          	mulhu	a3,a5,s0
    t_rng = x;
ffffffffc02052ec:	00fa3023          	sd	a5,0(s4)
            if (t_alloc(sizes[trand() % 6]) == NULL) break;
ffffffffc02052f0:	8289                	srli	a3,a3,0x2
ffffffffc02052f2:	00169713          	slli	a4,a3,0x1
ffffffffc02052f6:	9736                	add	a4,a4,a3
ffffffffc02052f8:	0706                	slli	a4,a4,0x1
ffffffffc02052fa:	8f99                	sub	a5,a5,a4
ffffffffc02052fc:	078e                	slli	a5,a5,0x3
ffffffffc02052fe:	97a6                	add	a5,a5,s1
ffffffffc0205300:	6388                	ld	a0,0(a5)
ffffffffc0205302:	b03ff0ef          	jal	ffffffffc0204e04 <t_alloc>
ffffffffc0205306:	fd55                	bnez	a0,ffffffffc02052c2 <case_shrink_baseline+0x6a>
        }
        while (t_n != 0) {
ffffffffc0205308:	00022517          	auipc	a0,0x22
ffffffffc020530c:	54052503          	lw	a0,1344(a0) # ffffffffc0227848 <t_n>
ffffffffc0205310:	cd1d                	beqz	a0,ffffffffc020534e <case_shrink_baseline+0xf6>
    unsigned long x = t_rng;
ffffffffc0205312:	000a3783          	ld	a5,0(s4)
            t_free_at((unsigned int)(trand() % t_n));
ffffffffc0205316:	1502                	slli	a0,a0,0x20
ffffffffc0205318:	9101                	srli	a0,a0,0x20
    x ^= x << 13;
ffffffffc020531a:	00d79713          	slli	a4,a5,0xd
ffffffffc020531e:	8fb9                	xor	a5,a5,a4
    x ^= x >> 7;
ffffffffc0205320:	0077d713          	srli	a4,a5,0x7
ffffffffc0205324:	8fb9                	xor	a5,a5,a4
    x ^= x << 17;
ffffffffc0205326:	01179713          	slli	a4,a5,0x11
ffffffffc020532a:	8fb9                	xor	a5,a5,a4
            t_free_at((unsigned int)(trand() % t_n));
ffffffffc020532c:	02a7f533          	remu	a0,a5,a0
    t_rng = x;
ffffffffc0205330:	00fa3023          	sd	a5,0(s4)
            t_free_at((unsigned int)(trand() % t_n));
ffffffffc0205334:	2501                	sext.w	a0,a0
ffffffffc0205336:	d5dff0ef          	jal	ffffffffc0205092 <t_free_at>
            t_iters++;
ffffffffc020533a:	000ab783          	ld	a5,0(s5)
        while (t_n != 0) {
ffffffffc020533e:	00022517          	auipc	a0,0x22
ffffffffc0205342:	50a52503          	lw	a0,1290(a0) # ffffffffc0227848 <t_n>
            t_iters++;
ffffffffc0205346:	0785                	addi	a5,a5,1
ffffffffc0205348:	00fab023          	sd	a5,0(s5)
        while (t_n != 0) {
ffffffffc020534c:	f179                	bnez	a0,ffffffffc0205312 <case_shrink_baseline+0xba>
        }
        slub_shrink();
ffffffffc020534e:	d6bfe0ef          	jal	ffffffffc02040b8 <slub_shrink>
        t_expect_baseline("free pages not restored after alloc/free/shrink");
ffffffffc0205352:	00004517          	auipc	a0,0x4
ffffffffc0205356:	d7650513          	addi	a0,a0,-650 # ffffffffc02090c8 <etext+0x1e4c>
    for (round = 0; round < 3; round++) {
ffffffffc020535a:	2905                	addiw	s2,s2,1
        t_expect_baseline("free pages not restored after alloc/free/shrink");
ffffffffc020535c:	dc7ff0ef          	jal	ffffffffc0205122 <t_expect_baseline>
    for (round = 0; round < 3; round++) {
ffffffffc0205360:	f5391ae3          	bne	s2,s3,ffffffffc02052b4 <case_shrink_baseline+0x5c>
    }
}
ffffffffc0205364:	70e2                	ld	ra,56(sp)
ffffffffc0205366:	7442                	ld	s0,48(sp)
ffffffffc0205368:	74a2                	ld	s1,40(sp)
ffffffffc020536a:	7902                	ld	s2,32(sp)
ffffffffc020536c:	69e2                	ld	s3,24(sp)
ffffffffc020536e:	6a42                	ld	s4,16(sp)
ffffffffc0205370:	6aa2                	ld	s5,8(sp)
ffffffffc0205372:	6b02                	ld	s6,0(sp)
ffffffffc0205374:	6121                	addi	sp,sp,64
ffffffffc0205376:	8082                	ret
        TFAIL("not clean after shrink at suite start");
ffffffffc0205378:	4605                	li	a2,1
ffffffffc020537a:	00022817          	auipc	a6,0x22
ffffffffc020537e:	4de83803          	ld	a6,1246(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0205382:	00008797          	auipc	a5,0x8
ffffffffc0205386:	c7e7a783          	lw	a5,-898(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc020538a:	00022717          	auipc	a4,0x22
ffffffffc020538e:	4de73703          	ld	a4,1246(a4) # ffffffffc0227868 <t_iters>
ffffffffc0205392:	00022697          	auipc	a3,0x22
ffffffffc0205396:	4de6b683          	ld	a3,1246(a3) # ffffffffc0227870 <t_size>
ffffffffc020539a:	00008597          	auipc	a1,0x8
ffffffffc020539e:	c765b583          	ld	a1,-906(a1) # ffffffffc020d010 <t_case>
ffffffffc02053a2:	00022517          	auipc	a0,0x22
ffffffffc02053a6:	4cc52123          	sw	a2,1218(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc02053aa:	00004517          	auipc	a0,0x4
ffffffffc02053ae:	a4e50513          	addi	a0,a0,-1458 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc02053b2:	00004617          	auipc	a2,0x4
ffffffffc02053b6:	cee60613          	addi	a2,a2,-786 # ffffffffc02090a0 <etext+0x1e24>
ffffffffc02053ba:	d97fa0ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc02053be:	b5f1                	j	ffffffffc020528a <case_shrink_baseline+0x32>

ffffffffc02053c0 <case_null_free>:
static void case_null_free(void) {
ffffffffc02053c0:	81010113          	addi	sp,sp,-2032
ffffffffc02053c4:	7e113423          	sd	ra,2024(sp)
ffffffffc02053c8:	7e813023          	sd	s0,2016(sp)
ffffffffc02053cc:	7c913c23          	sd	s1,2008(sp)
ffffffffc02053d0:	7d213823          	sd	s2,2000(sp)
ffffffffc02053d4:	7d313423          	sd	s3,1992(sp)
ffffffffc02053d8:	7b613823          	sd	s6,1968(sp)
ffffffffc02053dc:	7b713423          	sd	s7,1960(sp)
ffffffffc02053e0:	7d413023          	sd	s4,1984(sp)
ffffffffc02053e4:	7b513c23          	sd	s5,1976(sp)
ffffffffc02053e8:	7b813023          	sd	s8,1952(sp)
ffffffffc02053ec:	c2010113          	addi	sp,sp,-992
    size_t u0 = slub_user_objects(), p0 = slub_port_nr_free_pages();
ffffffffc02053f0:	f31fe0ef          	jal	ffffffffc0204320 <slub_user_objects>
ffffffffc02053f4:	8b2a                	mv	s6,a0
ffffffffc02053f6:	cd0fd0ef          	jal	ffffffffc02028c6 <nr_free_pages>
ffffffffc02053fa:	8baa                	mv	s7,a0
    for (cls = 0; cls < SLUB_NCLASSES; cls++) slub_get_class_info(cls, &a[cls]);
ffffffffc02053fc:	848a                	mv	s1,sp
ffffffffc02053fe:	890a                	mv	s2,sp
ffffffffc0205400:	4401                	li	s0,0
ffffffffc0205402:	49a1                	li	s3,8
ffffffffc0205404:	85ca                	mv	a1,s2
ffffffffc0205406:	8522                	mv	a0,s0
ffffffffc0205408:	0405                	addi	s0,s0,1
ffffffffc020540a:	d09fe0ef          	jal	ffffffffc0204112 <slub_get_class_info>
ffffffffc020540e:	0b890913          	addi	s2,s2,184
ffffffffc0205412:	ff3419e3          	bne	s0,s3,ffffffffc0205404 <case_null_free+0x44>
ffffffffc0205416:	3e800413          	li	s0,1000
    for (i = 0; i < 1000; i++) kfree(NULL);
ffffffffc020541a:	4501                	li	a0,0
ffffffffc020541c:	347d                	addiw	s0,s0,-1
ffffffffc020541e:	9b9fe0ef          	jal	ffffffffc0203dd6 <kfree>
ffffffffc0205422:	fc65                	bnez	s0,ffffffffc020541a <case_null_free+0x5a>
    t_iters = 1000;
ffffffffc0205424:	00022a17          	auipc	s4,0x22
ffffffffc0205428:	444a0a13          	addi	s4,s4,1092 # ffffffffc0227868 <t_iters>
ffffffffc020542c:	3e800793          	li	a5,1000
ffffffffc0205430:	5c010413          	addi	s0,sp,1472
ffffffffc0205434:	00fa3023          	sd	a5,0(s4)
ffffffffc0205438:	89a2                	mv	s3,s0
ffffffffc020543a:	4901                	li	s2,0
    for (cls = 0; cls < SLUB_NCLASSES; cls++) slub_get_class_info(cls, &b[cls]);
ffffffffc020543c:	4aa1                	li	s5,8
ffffffffc020543e:	85ce                	mv	a1,s3
ffffffffc0205440:	854a                	mv	a0,s2
ffffffffc0205442:	0905                	addi	s2,s2,1
ffffffffc0205444:	ccffe0ef          	jal	ffffffffc0204112 <slub_get_class_info>
ffffffffc0205448:	0b898993          	addi	s3,s3,184
ffffffffc020544c:	ff5919e3          	bne	s2,s5,ffffffffc020543e <case_null_free+0x7e>
    if (slub_user_objects() != u0 || slub_port_nr_free_pages() != p0)
ffffffffc0205450:	ed1fe0ef          	jal	ffffffffc0204320 <slub_user_objects>
ffffffffc0205454:	13650f63          	beq	a0,s6,ffffffffc0205592 <case_null_free+0x1d2>
        TFAIL("kfree(NULL) changed global state");
ffffffffc0205458:	4605                	li	a2,1
ffffffffc020545a:	00022817          	auipc	a6,0x22
ffffffffc020545e:	3fe83803          	ld	a6,1022(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0205462:	00008797          	auipc	a5,0x8
ffffffffc0205466:	b9e7a783          	lw	a5,-1122(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc020546a:	000a3703          	ld	a4,0(s4)
ffffffffc020546e:	00022697          	auipc	a3,0x22
ffffffffc0205472:	4026b683          	ld	a3,1026(a3) # ffffffffc0227870 <t_size>
ffffffffc0205476:	00008597          	auipc	a1,0x8
ffffffffc020547a:	b9a5b583          	ld	a1,-1126(a1) # ffffffffc020d010 <t_case>
ffffffffc020547e:	00022517          	auipc	a0,0x22
ffffffffc0205482:	3ec52323          	sw	a2,998(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0205486:	00004517          	auipc	a0,0x4
ffffffffc020548a:	97250513          	addi	a0,a0,-1678 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc020548e:	00004617          	auipc	a2,0x4
ffffffffc0205492:	c6a60613          	addi	a2,a2,-918 # ffffffffc02090f8 <etext+0x1e7c>
ffffffffc0205496:	cbbfa0ef          	jal	ffffffffc0200150 <cprintf>
    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
ffffffffc020549a:	5c040c13          	addi	s8,s0,1472
            TFAIL("kfree(NULL) changed class statistics");
ffffffffc020549e:	4b85                	li	s7,1
ffffffffc02054a0:	00022b17          	auipc	s6,0x22
ffffffffc02054a4:	3b8b0b13          	addi	s6,s6,952 # ffffffffc0227858 <t_seed_cfg>
    return (unsigned int)boot_hartid;
ffffffffc02054a8:	00008a97          	auipc	s5,0x8
ffffffffc02054ac:	b58a8a93          	addi	s5,s5,-1192 # ffffffffc020d000 <boot_hartid>
ffffffffc02054b0:	00022997          	auipc	s3,0x22
ffffffffc02054b4:	3c098993          	addi	s3,s3,960 # ffffffffc0227870 <t_size>
ffffffffc02054b8:	00008917          	auipc	s2,0x8
ffffffffc02054bc:	b5890913          	addi	s2,s2,-1192 # ffffffffc020d010 <t_case>
ffffffffc02054c0:	a83d                	j	ffffffffc02054fe <case_null_free+0x13e>
ffffffffc02054c2:	000b3803          	ld	a6,0(s6)
ffffffffc02054c6:	000aa783          	lw	a5,0(s5)
ffffffffc02054ca:	000a3703          	ld	a4,0(s4)
ffffffffc02054ce:	0009b683          	ld	a3,0(s3)
ffffffffc02054d2:	00093583          	ld	a1,0(s2)
ffffffffc02054d6:	00004617          	auipc	a2,0x4
ffffffffc02054da:	c4a60613          	addi	a2,a2,-950 # ffffffffc0209120 <etext+0x1ea4>
ffffffffc02054de:	00004517          	auipc	a0,0x4
ffffffffc02054e2:	91a50513          	addi	a0,a0,-1766 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc02054e6:	00022897          	auipc	a7,0x22
ffffffffc02054ea:	3778af23          	sw	s7,894(a7) # ffffffffc0227864 <t_case_failed>
ffffffffc02054ee:	c63fa0ef          	jal	ffffffffc0200150 <cprintf>
    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
ffffffffc02054f2:	0b840413          	addi	s0,s0,184
ffffffffc02054f6:	0b848493          	addi	s1,s1,184
ffffffffc02054fa:	07840363          	beq	s0,s8,ffffffffc0205560 <case_null_free+0x1a0>
        if (b[cls].alloc_fast != a[cls].alloc_fast ||
ffffffffc02054fe:	7038                	ld	a4,96(s0)
ffffffffc0205500:	70bc                	ld	a5,96(s1)
ffffffffc0205502:	fcf710e3          	bne	a4,a5,ffffffffc02054c2 <case_null_free+0x102>
ffffffffc0205506:	7438                	ld	a4,104(s0)
ffffffffc0205508:	74bc                	ld	a5,104(s1)
ffffffffc020550a:	faf71ce3          	bne	a4,a5,ffffffffc02054c2 <case_null_free+0x102>
            b[cls].alloc_slow != a[cls].alloc_slow ||
ffffffffc020550e:	7838                	ld	a4,112(s0)
ffffffffc0205510:	78bc                	ld	a5,112(s1)
ffffffffc0205512:	faf718e3          	bne	a4,a5,ffffffffc02054c2 <case_null_free+0x102>
            b[cls].free_fast != a[cls].free_fast ||
ffffffffc0205516:	7c38                	ld	a4,120(s0)
ffffffffc0205518:	7cbc                	ld	a5,120(s1)
ffffffffc020551a:	faf714e3          	bne	a4,a5,ffffffffc02054c2 <case_null_free+0x102>
            b[cls].free_slow != a[cls].free_slow ||
ffffffffc020551e:	6058                	ld	a4,128(s0)
ffffffffc0205520:	60dc                	ld	a5,128(s1)
ffffffffc0205522:	faf710e3          	bne	a4,a5,ffffffffc02054c2 <case_null_free+0x102>
            b[cls].refill != a[cls].refill || b[cls].flush != a[cls].flush ||
ffffffffc0205526:	6458                	ld	a4,136(s0)
ffffffffc0205528:	64dc                	ld	a5,136(s1)
ffffffffc020552a:	f8f71ce3          	bne	a4,a5,ffffffffc02054c2 <case_null_free+0x102>
ffffffffc020552e:	6858                	ld	a4,144(s0)
ffffffffc0205530:	68dc                	ld	a5,144(s1)
ffffffffc0205532:	f8f718e3          	bne	a4,a5,ffffffffc02054c2 <case_null_free+0x102>
            b[cls].barn_get != a[cls].barn_get ||
ffffffffc0205536:	6c58                	ld	a4,152(s0)
ffffffffc0205538:	6cdc                	ld	a5,152(s1)
ffffffffc020553a:	f8f714e3          	bne	a4,a5,ffffffffc02054c2 <case_null_free+0x102>
            b[cls].barn_put != a[cls].barn_put ||
ffffffffc020553e:	7058                	ld	a4,160(s0)
ffffffffc0205540:	70dc                	ld	a5,160(s1)
ffffffffc0205542:	f8f710e3          	bne	a4,a5,ffffffffc02054c2 <case_null_free+0x102>
            b[cls].slab_new != a[cls].slab_new ||
ffffffffc0205546:	7458                	ld	a4,168(s0)
ffffffffc0205548:	74dc                	ld	a5,168(s1)
ffffffffc020554a:	f6f71ce3          	bne	a4,a5,ffffffffc02054c2 <case_null_free+0x102>
            b[cls].slab_free != a[cls].slab_free ||
ffffffffc020554e:	7418                	ld	a4,40(s0)
ffffffffc0205550:	749c                	ld	a5,40(s1)
ffffffffc0205552:	f6f718e3          	bne	a4,a5,ffffffffc02054c2 <case_null_free+0x102>
            b[cls].nr_slabs != a[cls].nr_slabs ||
ffffffffc0205556:	6c38                	ld	a4,88(s0)
ffffffffc0205558:	6cbc                	ld	a5,88(s1)
ffffffffc020555a:	f6f714e3          	bne	a4,a5,ffffffffc02054c2 <case_null_free+0x102>
ffffffffc020555e:	bf51                	j	ffffffffc02054f2 <case_null_free+0x132>
}
ffffffffc0205560:	3e010113          	addi	sp,sp,992
ffffffffc0205564:	7e813083          	ld	ra,2024(sp)
ffffffffc0205568:	7e013403          	ld	s0,2016(sp)
ffffffffc020556c:	7d813483          	ld	s1,2008(sp)
ffffffffc0205570:	7d013903          	ld	s2,2000(sp)
ffffffffc0205574:	7c813983          	ld	s3,1992(sp)
ffffffffc0205578:	7c013a03          	ld	s4,1984(sp)
ffffffffc020557c:	7b813a83          	ld	s5,1976(sp)
ffffffffc0205580:	7b013b03          	ld	s6,1968(sp)
ffffffffc0205584:	7a813b83          	ld	s7,1960(sp)
ffffffffc0205588:	7a013c03          	ld	s8,1952(sp)
ffffffffc020558c:	7f010113          	addi	sp,sp,2032
ffffffffc0205590:	8082                	ret
    return nr_free_pages();
ffffffffc0205592:	b34fd0ef          	jal	ffffffffc02028c6 <nr_free_pages>
    if (slub_user_objects() != u0 || slub_port_nr_free_pages() != p0)
ffffffffc0205596:	ed7511e3          	bne	a0,s7,ffffffffc0205458 <case_null_free+0x98>
ffffffffc020559a:	b701                	j	ffffffffc020549a <case_null_free+0xda>

ffffffffc020559c <case_page_boundary>:
static void case_page_boundary(void) {
ffffffffc020559c:	1101                	addi	sp,sp,-32
ffffffffc020559e:	e822                	sd	s0,16(sp)
ffffffffc02055a0:	e426                	sd	s1,8(sp)
ffffffffc02055a2:	e04a                	sd	s2,0(sp)
ffffffffc02055a4:	ec06                	sd	ra,24(sp)
ffffffffc02055a6:	00004417          	auipc	s0,0x4
ffffffffc02055aa:	5ba40413          	addi	s0,s0,1466 # ffffffffc0209b60 <sizes.1>
ffffffffc02055ae:	00004917          	auipc	s2,0x4
ffffffffc02055b2:	5ea90913          	addi	s2,s2,1514 # ffffffffc0209b98 <bad.2>
ffffffffc02055b6:	00022497          	auipc	s1,0x22
ffffffffc02055ba:	2b248493          	addi	s1,s1,690 # ffffffffc0227868 <t_iters>
        t_iters++;
ffffffffc02055be:	609c                	ld	a5,0(s1)
        t_alloc(sizes[i]); /* 非 NULL/对齐/写满由 t_alloc 断言 */
ffffffffc02055c0:	6008                	ld	a0,0(s0)
    for (i = 0; i < sizeof(sizes) / sizeof(sizes[0]); i++) {
ffffffffc02055c2:	0421                	addi	s0,s0,8
        t_iters++;
ffffffffc02055c4:	0785                	addi	a5,a5,1
ffffffffc02055c6:	e09c                	sd	a5,0(s1)
        t_alloc(sizes[i]); /* 非 NULL/对齐/写满由 t_alloc 断言 */
ffffffffc02055c8:	83dff0ef          	jal	ffffffffc0204e04 <t_alloc>
    for (i = 0; i < sizeof(sizes) / sizeof(sizes[0]); i++) {
ffffffffc02055cc:	ff2419e3          	bne	s0,s2,ffffffffc02055be <case_page_boundary+0x22>
    t_verify_all();
ffffffffc02055d0:	d68ff0ef          	jal	ffffffffc0204b38 <t_verify_all>
    while (t_n != 0) t_free_at(t_n - 1);
ffffffffc02055d4:	00022517          	auipc	a0,0x22
ffffffffc02055d8:	27452503          	lw	a0,628(a0) # ffffffffc0227848 <t_n>
ffffffffc02055dc:	c909                	beqz	a0,ffffffffc02055ee <case_page_boundary+0x52>
ffffffffc02055de:	357d                	addiw	a0,a0,-1
ffffffffc02055e0:	ab3ff0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc02055e4:	00022517          	auipc	a0,0x22
ffffffffc02055e8:	26452503          	lw	a0,612(a0) # ffffffffc0227848 <t_n>
ffffffffc02055ec:	f96d                	bnez	a0,ffffffffc02055de <case_page_boundary+0x42>
}
ffffffffc02055ee:	60e2                	ld	ra,24(sp)
ffffffffc02055f0:	6442                	ld	s0,16(sp)
ffffffffc02055f2:	64a2                	ld	s1,8(sp)
ffffffffc02055f4:	6902                	ld	s2,0(sp)
ffffffffc02055f6:	6105                	addi	sp,sp,32
ffffffffc02055f8:	8082                	ret

ffffffffc02055fa <case_sustained_churn>:
static void case_sustained_churn(void) {
ffffffffc02055fa:	ce010113          	addi	sp,sp,-800
ffffffffc02055fe:	30813823          	sd	s0,784(sp)
ffffffffc0205602:	2f313c23          	sd	s3,760(sp)
ffffffffc0205606:	2f413823          	sd	s4,752(sp)
ffffffffc020560a:	2f513423          	sd	s5,744(sp)
ffffffffc020560e:	30113c23          	sd	ra,792(sp)
ffffffffc0205612:	30913423          	sd	s1,776(sp)
ffffffffc0205616:	31213023          	sd	s2,768(sp)
ffffffffc020561a:	2f613023          	sd	s6,736(sp)
    for (cls = 0; cls < slub_nr_classes(); cls++) {
ffffffffc020561e:	4981                	li	s3,0
        t_size = objsize;
ffffffffc0205620:	00022a17          	auipc	s4,0x22
ffffffffc0205624:	250a0a13          	addi	s4,s4,592 # ffffffffc0227870 <t_size>
        if (n > TMAX_OBJS - 8) n = TMAX_OBJS - 8;
ffffffffc0205628:	47800a93          	li	s5,1144
            t_iters++;
ffffffffc020562c:	00022417          	auipc	s0,0x22
ffffffffc0205630:	23c40413          	addi	s0,s0,572 # ffffffffc0227868 <t_iters>
    for (cls = 0; cls < slub_nr_classes(); cls++) {
ffffffffc0205634:	a95fe0ef          	jal	ffffffffc02040c8 <slub_nr_classes>
ffffffffc0205638:	14a9f863          	bgeu	s3,a0,ffffffffc0205788 <case_sustained_churn+0x18e>
        size_t objsize = slub_class_size(cls);
ffffffffc020563c:	854e                	mv	a0,s3
ffffffffc020563e:	abbfe0ef          	jal	ffffffffc02040f8 <slub_class_size>
ffffffffc0205642:	892a                	mv	s2,a0
        if (slub_get_class_info(cls, &i0) != 0) {
ffffffffc0205644:	858a                	mv	a1,sp
ffffffffc0205646:	854e                	mv	a0,s3
        t_size = objsize;
ffffffffc0205648:	012a3023          	sd	s2,0(s4)
        if (slub_get_class_info(cls, &i0) != 0) {
ffffffffc020564c:	ac7fe0ef          	jal	ffffffffc0204112 <slub_get_class_info>
ffffffffc0205650:	3e051163          	bnez	a0,ffffffffc0205a32 <case_sustained_churn+0x438>
        n = (unsigned int)(2 * i0.objs_per_slab + 2 * i0.barn_cap +
ffffffffc0205654:	7702                	ld	a4,32(sp)
ffffffffc0205656:	66c2                	ld	a3,16(sp)
ffffffffc0205658:	67a2                	ld	a5,8(sp)
ffffffffc020565a:	9f35                	addw	a4,a4,a3
ffffffffc020565c:	0017979b          	slliw	a5,a5,0x1
ffffffffc0205660:	9fb9                	addw	a5,a5,a4
ffffffffc0205662:	0017979b          	slliw	a5,a5,0x1
        for (k = 0; k < n; k++) {
ffffffffc0205666:	c39d                	beqz	a5,ffffffffc020568c <case_sustained_churn+0x92>
        if (n > TMAX_OBJS - 8) n = TMAX_OBJS - 8;
ffffffffc0205668:	00078b1b          	sext.w	s6,a5
ffffffffc020566c:	00faf463          	bgeu	s5,a5,ffffffffc0205674 <case_sustained_churn+0x7a>
ffffffffc0205670:	47800b13          	li	s6,1144
        for (k = 0; k < n; k++) {
ffffffffc0205674:	4481                	li	s1,0
ffffffffc0205676:	a031                	j	ffffffffc0205682 <case_sustained_churn+0x88>
            t_iters++;
ffffffffc0205678:	601c                	ld	a5,0(s0)
ffffffffc020567a:	0785                	addi	a5,a5,1
ffffffffc020567c:	e01c                	sd	a5,0(s0)
        for (k = 0; k < n; k++) {
ffffffffc020567e:	0164f763          	bgeu	s1,s6,ffffffffc020568c <case_sustained_churn+0x92>
            if (t_alloc(objsize) == NULL) break;
ffffffffc0205682:	854a                	mv	a0,s2
ffffffffc0205684:	f80ff0ef          	jal	ffffffffc0204e04 <t_alloc>
        for (k = 0; k < n; k++) {
ffffffffc0205688:	2485                	addiw	s1,s1,1
            if (t_alloc(objsize) == NULL) break;
ffffffffc020568a:	f57d                	bnez	a0,ffffffffc0205678 <case_sustained_churn+0x7e>
        t_verify_all();
ffffffffc020568c:	cacff0ef          	jal	ffffffffc0204b38 <t_verify_all>
        slub_get_class_info(cls, &i1);
ffffffffc0205690:	192c                	addi	a1,sp,184
ffffffffc0205692:	854e                	mv	a0,s3
ffffffffc0205694:	a7ffe0ef          	jal	ffffffffc0204112 <slub_get_class_info>
        if (i1.slab_new == i0.slab_new) TFAIL("slab_new did not advance");
ffffffffc0205698:	6776                	ld	a4,344(sp)
ffffffffc020569a:	778a                	ld	a5,160(sp)
ffffffffc020569c:	34f70c63          	beq	a4,a5,ffffffffc02059f4 <case_sustained_churn+0x3fa>
        if (i1.refill == i0.refill) TFAIL("refill path not exercised");
ffffffffc02056a0:	7772                	ld	a4,312(sp)
ffffffffc02056a2:	678a                	ld	a5,128(sp)
ffffffffc02056a4:	30f70963          	beq	a4,a5,ffffffffc02059b6 <case_sustained_churn+0x3bc>
        if (i1.alloc_slow == i0.alloc_slow) TFAIL("slow alloc path missing");
ffffffffc02056a8:	7712                	ld	a4,288(sp)
ffffffffc02056aa:	77a6                	ld	a5,104(sp)
ffffffffc02056ac:	2cf70663          	beq	a4,a5,ffffffffc0205978 <case_sustained_churn+0x37e>
        if (i1.nr_slabs <= i0.nr_slabs) TFAIL("slab count did not grow");
ffffffffc02056b0:	770e                	ld	a4,224(sp)
ffffffffc02056b2:	77a2                	ld	a5,40(sp)
ffffffffc02056b4:	18e7f063          	bgeu	a5,a4,ffffffffc0205834 <case_sustained_churn+0x23a>
        while (t_n != 0) {
ffffffffc02056b8:	00022797          	auipc	a5,0x22
ffffffffc02056bc:	1907a783          	lw	a5,400(a5) # ffffffffc0227848 <t_n>
ffffffffc02056c0:	cf81                	beqz	a5,ffffffffc02056d8 <case_sustained_churn+0xde>
            t_free_at(0);
ffffffffc02056c2:	4501                	li	a0,0
ffffffffc02056c4:	9cfff0ef          	jal	ffffffffc0205092 <t_free_at>
            t_iters++;
ffffffffc02056c8:	601c                	ld	a5,0(s0)
        while (t_n != 0) {
ffffffffc02056ca:	00022717          	auipc	a4,0x22
ffffffffc02056ce:	17e72703          	lw	a4,382(a4) # ffffffffc0227848 <t_n>
            t_iters++;
ffffffffc02056d2:	0785                	addi	a5,a5,1
ffffffffc02056d4:	e01c                	sd	a5,0(s0)
        while (t_n != 0) {
ffffffffc02056d6:	f775                	bnez	a4,ffffffffc02056c2 <case_sustained_churn+0xc8>
        slub_get_class_info(cls, &i2);
ffffffffc02056d8:	1a8c                	addi	a1,sp,368
ffffffffc02056da:	854e                	mv	a0,s3
ffffffffc02056dc:	a37fe0ef          	jal	ffffffffc0204112 <slub_get_class_info>
        if (i2.free_slow == i1.free_slow) TFAIL("free slow path missing");
ffffffffc02056e0:	773e                	ld	a4,488(sp)
ffffffffc02056e2:	77d2                	ld	a5,304(sp)
ffffffffc02056e4:	1cf70663          	beq	a4,a5,ffffffffc02058b0 <case_sustained_churn+0x2b6>
        if (i2.flush == i1.flush) TFAIL("slab flush path missing");
ffffffffc02056e8:	777e                	ld	a4,504(sp)
ffffffffc02056ea:	6796                	ld	a5,320(sp)
ffffffffc02056ec:	20f70463          	beq	a4,a5,ffffffffc02058f4 <case_sustained_churn+0x2fa>
        if (i2.barn_put == i1.barn_put) TFAIL("barn put path missing");
ffffffffc02056f0:	20813703          	ld	a4,520(sp)
ffffffffc02056f4:	67d6                	ld	a5,336(sp)
ffffffffc02056f6:	24f70263          	beq	a4,a5,ffffffffc020593a <case_sustained_churn+0x340>
        if (i2.slab_free == i1.slab_free && i2.nr_empty == 0)
ffffffffc02056fa:	21813703          	ld	a4,536(sp)
ffffffffc02056fe:	7796                	ld	a5,352(sp)
ffffffffc0205700:	0af70763          	beq	a4,a5,ffffffffc02057ae <case_sustained_churn+0x1b4>
        m = (unsigned int)(2 * i0.sheaf_cap + i0.barn_cap + 1);
ffffffffc0205704:	67a2                	ld	a5,8(sp)
ffffffffc0205706:	6b42                	ld	s6,16(sp)
ffffffffc0205708:	0017979b          	slliw	a5,a5,0x1
ffffffffc020570c:	2b05                	addiw	s6,s6,1
ffffffffc020570e:	00fb0b3b          	addw	s6,s6,a5
        for (k = 0; k < m; k++) {
ffffffffc0205712:	000b0e63          	beqz	s6,ffffffffc020572e <case_sustained_churn+0x134>
ffffffffc0205716:	4481                	li	s1,0
ffffffffc0205718:	a031                	j	ffffffffc0205724 <case_sustained_churn+0x12a>
            t_iters++;
ffffffffc020571a:	601c                	ld	a5,0(s0)
ffffffffc020571c:	0785                	addi	a5,a5,1
ffffffffc020571e:	e01c                	sd	a5,0(s0)
        for (k = 0; k < m; k++) {
ffffffffc0205720:	009b0763          	beq	s6,s1,ffffffffc020572e <case_sustained_churn+0x134>
            if (t_alloc(objsize) == NULL) break;
ffffffffc0205724:	854a                	mv	a0,s2
ffffffffc0205726:	edeff0ef          	jal	ffffffffc0204e04 <t_alloc>
        for (k = 0; k < m; k++) {
ffffffffc020572a:	2485                	addiw	s1,s1,1
            if (t_alloc(objsize) == NULL) break;
ffffffffc020572c:	f57d                	bnez	a0,ffffffffc020571a <case_sustained_churn+0x120>
        slub_get_class_info(cls, &i3);
ffffffffc020572e:	142c                	addi	a1,sp,552
ffffffffc0205730:	854e                	mv	a0,s3
ffffffffc0205732:	9e1fe0ef          	jal	ffffffffc0204112 <slub_get_class_info>
        if (i3.barn_get == i2.barn_get) TFAIL("barn get path missing");
ffffffffc0205736:	2b813703          	ld	a4,696(sp)
ffffffffc020573a:	20013783          	ld	a5,512(sp)
ffffffffc020573e:	12f70a63          	beq	a4,a5,ffffffffc0205872 <case_sustained_churn+0x278>
        t_verify_all();
ffffffffc0205742:	bf6ff0ef          	jal	ffffffffc0204b38 <t_verify_all>
    while (t_n != 0) t_free_at(t_n - 1);
ffffffffc0205746:	00022517          	auipc	a0,0x22
ffffffffc020574a:	10252503          	lw	a0,258(a0) # ffffffffc0227848 <t_n>
ffffffffc020574e:	c909                	beqz	a0,ffffffffc0205760 <case_sustained_churn+0x166>
ffffffffc0205750:	357d                	addiw	a0,a0,-1
ffffffffc0205752:	941ff0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc0205756:	00022517          	auipc	a0,0x22
ffffffffc020575a:	0f252503          	lw	a0,242(a0) # ffffffffc0227848 <t_n>
ffffffffc020575e:	f96d                	bnez	a0,ffffffffc0205750 <case_sustained_churn+0x156>
        slub_shrink();
ffffffffc0205760:	959fe0ef          	jal	ffffffffc02040b8 <slub_shrink>
        slub_get_class_info(cls, &i3);
ffffffffc0205764:	142c                	addi	a1,sp,552
ffffffffc0205766:	854e                	mv	a0,s3
ffffffffc0205768:	9abfe0ef          	jal	ffffffffc0204112 <slub_get_class_info>
        if (i3.nr_slabs != 0) TFAIL("slabs not released after shrink");
ffffffffc020576c:	25013783          	ld	a5,592(sp)
ffffffffc0205770:	e3d9                	bnez	a5,ffffffffc02057f6 <case_sustained_churn+0x1fc>
        t_expect_baseline("free pages drifted after class churn");
ffffffffc0205772:	00004517          	auipc	a0,0x4
ffffffffc0205776:	b0e50513          	addi	a0,a0,-1266 # ffffffffc0209280 <etext+0x2004>
ffffffffc020577a:	9a9ff0ef          	jal	ffffffffc0205122 <t_expect_baseline>
    for (cls = 0; cls < slub_nr_classes(); cls++) {
ffffffffc020577e:	0985                	addi	s3,s3,1
ffffffffc0205780:	949fe0ef          	jal	ffffffffc02040c8 <slub_nr_classes>
ffffffffc0205784:	eaa9ece3          	bltu	s3,a0,ffffffffc020563c <case_sustained_churn+0x42>
}
ffffffffc0205788:	31813083          	ld	ra,792(sp)
ffffffffc020578c:	31013403          	ld	s0,784(sp)
ffffffffc0205790:	30813483          	ld	s1,776(sp)
ffffffffc0205794:	30013903          	ld	s2,768(sp)
ffffffffc0205798:	2f813983          	ld	s3,760(sp)
ffffffffc020579c:	2f013a03          	ld	s4,752(sp)
ffffffffc02057a0:	2e813a83          	ld	s5,744(sp)
ffffffffc02057a4:	2e013b03          	ld	s6,736(sp)
ffffffffc02057a8:	32010113          	addi	sp,sp,800
ffffffffc02057ac:	8082                	ret
        if (i2.slab_free == i1.slab_free && i2.nr_empty == 0)
ffffffffc02057ae:	77da                	ld	a5,432(sp)
ffffffffc02057b0:	fbb1                	bnez	a5,ffffffffc0205704 <case_sustained_churn+0x10a>
            TFAIL("no empty/destroyed slab after full free");
ffffffffc02057b2:	4605                	li	a2,1
ffffffffc02057b4:	00022817          	auipc	a6,0x22
ffffffffc02057b8:	0a483803          	ld	a6,164(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc02057bc:	00008797          	auipc	a5,0x8
ffffffffc02057c0:	8447a783          	lw	a5,-1980(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc02057c4:	00022717          	auipc	a4,0x22
ffffffffc02057c8:	0a473703          	ld	a4,164(a4) # ffffffffc0227868 <t_iters>
ffffffffc02057cc:	000a3683          	ld	a3,0(s4)
ffffffffc02057d0:	00008597          	auipc	a1,0x8
ffffffffc02057d4:	8405b583          	ld	a1,-1984(a1) # ffffffffc020d010 <t_case>
ffffffffc02057d8:	00022517          	auipc	a0,0x22
ffffffffc02057dc:	08c52623          	sw	a2,140(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc02057e0:	00003517          	auipc	a0,0x3
ffffffffc02057e4:	61850513          	addi	a0,a0,1560 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc02057e8:	00004617          	auipc	a2,0x4
ffffffffc02057ec:	a3860613          	addi	a2,a2,-1480 # ffffffffc0209220 <etext+0x1fa4>
ffffffffc02057f0:	961fa0ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc02057f4:	bf01                	j	ffffffffc0205704 <case_sustained_churn+0x10a>
        if (i3.nr_slabs != 0) TFAIL("slabs not released after shrink");
ffffffffc02057f6:	4605                	li	a2,1
ffffffffc02057f8:	00022817          	auipc	a6,0x22
ffffffffc02057fc:	06083803          	ld	a6,96(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0205800:	00008797          	auipc	a5,0x8
ffffffffc0205804:	8007a783          	lw	a5,-2048(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0205808:	6018                	ld	a4,0(s0)
ffffffffc020580a:	000a3683          	ld	a3,0(s4)
ffffffffc020580e:	00008597          	auipc	a1,0x8
ffffffffc0205812:	8025b583          	ld	a1,-2046(a1) # ffffffffc020d010 <t_case>
ffffffffc0205816:	00022517          	auipc	a0,0x22
ffffffffc020581a:	04c52723          	sw	a2,78(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc020581e:	00003517          	auipc	a0,0x3
ffffffffc0205822:	5da50513          	addi	a0,a0,1498 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0205826:	00004617          	auipc	a2,0x4
ffffffffc020582a:	a3a60613          	addi	a2,a2,-1478 # ffffffffc0209260 <etext+0x1fe4>
ffffffffc020582e:	923fa0ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc0205832:	b781                	j	ffffffffc0205772 <case_sustained_churn+0x178>
        if (i1.nr_slabs <= i0.nr_slabs) TFAIL("slab count did not grow");
ffffffffc0205834:	4605                	li	a2,1
ffffffffc0205836:	00022817          	auipc	a6,0x22
ffffffffc020583a:	02283803          	ld	a6,34(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc020583e:	00007797          	auipc	a5,0x7
ffffffffc0205842:	7c27a783          	lw	a5,1986(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0205846:	6018                	ld	a4,0(s0)
ffffffffc0205848:	000a3683          	ld	a3,0(s4)
ffffffffc020584c:	00007597          	auipc	a1,0x7
ffffffffc0205850:	7c45b583          	ld	a1,1988(a1) # ffffffffc020d010 <t_case>
ffffffffc0205854:	00022517          	auipc	a0,0x22
ffffffffc0205858:	00c52823          	sw	a2,16(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc020585c:	00003517          	auipc	a0,0x3
ffffffffc0205860:	59c50513          	addi	a0,a0,1436 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0205864:	00004617          	auipc	a2,0x4
ffffffffc0205868:	95c60613          	addi	a2,a2,-1700 # ffffffffc02091c0 <etext+0x1f44>
ffffffffc020586c:	8e5fa0ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc0205870:	b5a1                	j	ffffffffc02056b8 <case_sustained_churn+0xbe>
        if (i3.barn_get == i2.barn_get) TFAIL("barn get path missing");
ffffffffc0205872:	4605                	li	a2,1
ffffffffc0205874:	00022817          	auipc	a6,0x22
ffffffffc0205878:	fe483803          	ld	a6,-28(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc020587c:	00007797          	auipc	a5,0x7
ffffffffc0205880:	7847a783          	lw	a5,1924(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0205884:	6018                	ld	a4,0(s0)
ffffffffc0205886:	000a3683          	ld	a3,0(s4)
ffffffffc020588a:	00007597          	auipc	a1,0x7
ffffffffc020588e:	7865b583          	ld	a1,1926(a1) # ffffffffc020d010 <t_case>
ffffffffc0205892:	00022517          	auipc	a0,0x22
ffffffffc0205896:	fcc52923          	sw	a2,-46(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc020589a:	00003517          	auipc	a0,0x3
ffffffffc020589e:	55e50513          	addi	a0,a0,1374 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc02058a2:	00004617          	auipc	a2,0x4
ffffffffc02058a6:	9a660613          	addi	a2,a2,-1626 # ffffffffc0209248 <etext+0x1fcc>
ffffffffc02058aa:	8a7fa0ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc02058ae:	bd51                	j	ffffffffc0205742 <case_sustained_churn+0x148>
        if (i2.free_slow == i1.free_slow) TFAIL("free slow path missing");
ffffffffc02058b0:	00007797          	auipc	a5,0x7
ffffffffc02058b4:	7507a783          	lw	a5,1872(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc02058b8:	6018                	ld	a4,0(s0)
ffffffffc02058ba:	4605                	li	a2,1
ffffffffc02058bc:	00022817          	auipc	a6,0x22
ffffffffc02058c0:	f9c83803          	ld	a6,-100(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc02058c4:	000a3683          	ld	a3,0(s4)
ffffffffc02058c8:	00007597          	auipc	a1,0x7
ffffffffc02058cc:	7485b583          	ld	a1,1864(a1) # ffffffffc020d010 <t_case>
ffffffffc02058d0:	00022517          	auipc	a0,0x22
ffffffffc02058d4:	f8c52a23          	sw	a2,-108(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc02058d8:	00003517          	auipc	a0,0x3
ffffffffc02058dc:	52050513          	addi	a0,a0,1312 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc02058e0:	00004617          	auipc	a2,0x4
ffffffffc02058e4:	8f860613          	addi	a2,a2,-1800 # ffffffffc02091d8 <etext+0x1f5c>
ffffffffc02058e8:	869fa0ef          	jal	ffffffffc0200150 <cprintf>
        if (i2.flush == i1.flush) TFAIL("slab flush path missing");
ffffffffc02058ec:	777e                	ld	a4,504(sp)
ffffffffc02058ee:	6796                	ld	a5,320(sp)
ffffffffc02058f0:	e0f710e3          	bne	a4,a5,ffffffffc02056f0 <case_sustained_churn+0xf6>
ffffffffc02058f4:	00007797          	auipc	a5,0x7
ffffffffc02058f8:	70c7a783          	lw	a5,1804(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc02058fc:	6018                	ld	a4,0(s0)
ffffffffc02058fe:	4605                	li	a2,1
ffffffffc0205900:	00022817          	auipc	a6,0x22
ffffffffc0205904:	f5883803          	ld	a6,-168(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0205908:	000a3683          	ld	a3,0(s4)
ffffffffc020590c:	00007597          	auipc	a1,0x7
ffffffffc0205910:	7045b583          	ld	a1,1796(a1) # ffffffffc020d010 <t_case>
ffffffffc0205914:	00022517          	auipc	a0,0x22
ffffffffc0205918:	f4c52823          	sw	a2,-176(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc020591c:	00003517          	auipc	a0,0x3
ffffffffc0205920:	4dc50513          	addi	a0,a0,1244 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0205924:	00004617          	auipc	a2,0x4
ffffffffc0205928:	8cc60613          	addi	a2,a2,-1844 # ffffffffc02091f0 <etext+0x1f74>
ffffffffc020592c:	825fa0ef          	jal	ffffffffc0200150 <cprintf>
        if (i2.barn_put == i1.barn_put) TFAIL("barn put path missing");
ffffffffc0205930:	20813703          	ld	a4,520(sp)
ffffffffc0205934:	67d6                	ld	a5,336(sp)
ffffffffc0205936:	dcf712e3          	bne	a4,a5,ffffffffc02056fa <case_sustained_churn+0x100>
ffffffffc020593a:	4605                	li	a2,1
ffffffffc020593c:	00022817          	auipc	a6,0x22
ffffffffc0205940:	f1c83803          	ld	a6,-228(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0205944:	00007797          	auipc	a5,0x7
ffffffffc0205948:	6bc7a783          	lw	a5,1724(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc020594c:	6018                	ld	a4,0(s0)
ffffffffc020594e:	000a3683          	ld	a3,0(s4)
ffffffffc0205952:	00007597          	auipc	a1,0x7
ffffffffc0205956:	6be5b583          	ld	a1,1726(a1) # ffffffffc020d010 <t_case>
ffffffffc020595a:	00022517          	auipc	a0,0x22
ffffffffc020595e:	f0c52523          	sw	a2,-246(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0205962:	00003517          	auipc	a0,0x3
ffffffffc0205966:	49650513          	addi	a0,a0,1174 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc020596a:	00004617          	auipc	a2,0x4
ffffffffc020596e:	89e60613          	addi	a2,a2,-1890 # ffffffffc0209208 <etext+0x1f8c>
ffffffffc0205972:	fdefa0ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc0205976:	b351                	j	ffffffffc02056fa <case_sustained_churn+0x100>
        if (i1.alloc_slow == i0.alloc_slow) TFAIL("slow alloc path missing");
ffffffffc0205978:	4605                	li	a2,1
ffffffffc020597a:	00022817          	auipc	a6,0x22
ffffffffc020597e:	ede83803          	ld	a6,-290(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0205982:	00007797          	auipc	a5,0x7
ffffffffc0205986:	67e7a783          	lw	a5,1662(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc020598a:	6018                	ld	a4,0(s0)
ffffffffc020598c:	000a3683          	ld	a3,0(s4)
ffffffffc0205990:	00007597          	auipc	a1,0x7
ffffffffc0205994:	6805b583          	ld	a1,1664(a1) # ffffffffc020d010 <t_case>
ffffffffc0205998:	00022517          	auipc	a0,0x22
ffffffffc020599c:	ecc52623          	sw	a2,-308(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc02059a0:	00003517          	auipc	a0,0x3
ffffffffc02059a4:	45850513          	addi	a0,a0,1112 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc02059a8:	00004617          	auipc	a2,0x4
ffffffffc02059ac:	80060613          	addi	a2,a2,-2048 # ffffffffc02091a8 <etext+0x1f2c>
ffffffffc02059b0:	fa0fa0ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc02059b4:	b9f5                	j	ffffffffc02056b0 <case_sustained_churn+0xb6>
        if (i1.refill == i0.refill) TFAIL("refill path not exercised");
ffffffffc02059b6:	4605                	li	a2,1
ffffffffc02059b8:	00022817          	auipc	a6,0x22
ffffffffc02059bc:	ea083803          	ld	a6,-352(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc02059c0:	00007797          	auipc	a5,0x7
ffffffffc02059c4:	6407a783          	lw	a5,1600(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc02059c8:	6018                	ld	a4,0(s0)
ffffffffc02059ca:	000a3683          	ld	a3,0(s4)
ffffffffc02059ce:	00007597          	auipc	a1,0x7
ffffffffc02059d2:	6425b583          	ld	a1,1602(a1) # ffffffffc020d010 <t_case>
ffffffffc02059d6:	00022517          	auipc	a0,0x22
ffffffffc02059da:	e8c52723          	sw	a2,-370(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc02059de:	00003517          	auipc	a0,0x3
ffffffffc02059e2:	41a50513          	addi	a0,a0,1050 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc02059e6:	00003617          	auipc	a2,0x3
ffffffffc02059ea:	7a260613          	addi	a2,a2,1954 # ffffffffc0209188 <etext+0x1f0c>
ffffffffc02059ee:	f62fa0ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc02059f2:	b95d                	j	ffffffffc02056a8 <case_sustained_churn+0xae>
        if (i1.slab_new == i0.slab_new) TFAIL("slab_new did not advance");
ffffffffc02059f4:	4605                	li	a2,1
ffffffffc02059f6:	00022817          	auipc	a6,0x22
ffffffffc02059fa:	e6283803          	ld	a6,-414(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc02059fe:	00007797          	auipc	a5,0x7
ffffffffc0205a02:	6027a783          	lw	a5,1538(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0205a06:	6018                	ld	a4,0(s0)
ffffffffc0205a08:	000a3683          	ld	a3,0(s4)
ffffffffc0205a0c:	00007597          	auipc	a1,0x7
ffffffffc0205a10:	6045b583          	ld	a1,1540(a1) # ffffffffc020d010 <t_case>
ffffffffc0205a14:	00022517          	auipc	a0,0x22
ffffffffc0205a18:	e4c52823          	sw	a2,-432(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0205a1c:	00003517          	auipc	a0,0x3
ffffffffc0205a20:	3dc50513          	addi	a0,a0,988 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0205a24:	00003617          	auipc	a2,0x3
ffffffffc0205a28:	74460613          	addi	a2,a2,1860 # ffffffffc0209168 <etext+0x1eec>
ffffffffc0205a2c:	f24fa0ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc0205a30:	b985                	j	ffffffffc02056a0 <case_sustained_churn+0xa6>
            TFAIL("slub_get_class_info failed");
ffffffffc0205a32:	4605                	li	a2,1
ffffffffc0205a34:	000a3683          	ld	a3,0(s4)
ffffffffc0205a38:	00022817          	auipc	a6,0x22
ffffffffc0205a3c:	e2083803          	ld	a6,-480(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0205a40:	00007797          	auipc	a5,0x7
ffffffffc0205a44:	5c07a783          	lw	a5,1472(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0205a48:	00022717          	auipc	a4,0x22
ffffffffc0205a4c:	e2073703          	ld	a4,-480(a4) # ffffffffc0227868 <t_iters>
ffffffffc0205a50:	00007597          	auipc	a1,0x7
ffffffffc0205a54:	5c05b583          	ld	a1,1472(a1) # ffffffffc020d010 <t_case>
ffffffffc0205a58:	00022517          	auipc	a0,0x22
ffffffffc0205a5c:	e0c52623          	sw	a2,-500(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0205a60:	00003517          	auipc	a0,0x3
ffffffffc0205a64:	39850513          	addi	a0,a0,920 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0205a68:	00003617          	auipc	a2,0x3
ffffffffc0205a6c:	6e060613          	addi	a2,a2,1760 # ffffffffc0209148 <etext+0x1ecc>
ffffffffc0205a70:	ee0fa0ef          	jal	ffffffffc0200150 <cprintf>
            return;
ffffffffc0205a74:	bb11                	j	ffffffffc0205788 <case_sustained_churn+0x18e>

ffffffffc0205a76 <case_class_bounds>:
static void case_class_bounds(void) {
ffffffffc0205a76:	7159                	addi	sp,sp,-112
ffffffffc0205a78:	f062                	sd	s8,32(sp)
                                                : -1);
ffffffffc0205a7a:	6c05                	lui	s8,0x1
static void case_class_bounds(void) {
ffffffffc0205a7c:	fc56                	sd	s5,56(sp)
ffffffffc0205a7e:	f486                	sd	ra,104(sp)
ffffffffc0205a80:	f0a2                	sd	s0,96(sp)
ffffffffc0205a82:	eca6                	sd	s1,88(sp)
ffffffffc0205a84:	e8ca                	sd	s2,80(sp)
ffffffffc0205a86:	e4ce                	sd	s3,72(sp)
ffffffffc0205a88:	e0d2                	sd	s4,64(sp)
ffffffffc0205a8a:	f85a                	sd	s6,48(sp)
ffffffffc0205a8c:	f45e                	sd	s7,40(sp)
    for (cls = 0; cls < slub_nr_classes(); cls++) {
ffffffffc0205a8e:	4a81                	li	s5,0
                                                : -1);
ffffffffc0205a90:	800c0c13          	addi	s8,s8,-2048 # 800 <kern_entry-0xffffffffc01ff800>
    for (cls = 0; cls < slub_nr_classes(); cls++) {
ffffffffc0205a94:	e34fe0ef          	jal	ffffffffc02040c8 <slub_nr_classes>
ffffffffc0205a98:	0caaf363          	bgeu	s5,a0,ffffffffc0205b5e <case_class_bounds+0xe8>
        size_t s = slub_class_size(cls);
ffffffffc0205a9c:	8556                	mv	a0,s5
ffffffffc0205a9e:	e5afe0ef          	jal	ffffffffc02040f8 <slub_class_size>
        req[0] = (s == 16) ? 1 : s - 1;
ffffffffc0205aa2:	4741                	li	a4,16
        size_t s = slub_class_size(cls);
ffffffffc0205aa4:	8a2a                	mv	s4,a0
        req[0] = (s == 16) ? 1 : s - 1;
ffffffffc0205aa6:	4785                	li	a5,1
ffffffffc0205aa8:	00e50463          	beq	a0,a4,ffffffffc0205ab0 <case_class_bounds+0x3a>
ffffffffc0205aac:	fff50793          	addi	a5,a0,-1
ffffffffc0205ab0:	e43e                	sd	a5,8(sp)
        req[2] = s + 1;
ffffffffc0205ab2:	001a0793          	addi	a5,s4,1
ffffffffc0205ab6:	ec3e                	sd	a5,24(sp)
        req[1] = s;
ffffffffc0205ab8:	e852                	sd	s4,16(sp)
        for (k = 0; k < 3; k++) {
ffffffffc0205aba:	0024                	addi	s1,sp,8
ffffffffc0205abc:	00022997          	auipc	s3,0x22
ffffffffc0205ac0:	dac98993          	addi	s3,s3,-596 # ffffffffc0227868 <t_iters>
            int want_cls = (req[k] <= s) ? (int)cls
ffffffffc0205ac4:	000a8b1b          	sext.w	s6,s5
                TFAIL("unexpected size class mapping");
ffffffffc0205ac8:	4b85                	li	s7,1
            int want_cls = (req[k] <= s) ? (int)cls
ffffffffc0205aca:	6080                	ld	s0,0(s1)
ffffffffc0205acc:	597d                	li	s2,-1
                                         : (req[k] <= SLUB_MAX_SMALL_SIZE
ffffffffc0205ace:	0c8a6363          	bltu	s4,s0,ffffffffc0205b94 <case_class_bounds+0x11e>
            int want_cls = (req[k] <= s) ? (int)cls
ffffffffc0205ad2:	895a                	mv	s2,s6
            t_iters++;
ffffffffc0205ad4:	0009b783          	ld	a5,0(s3)
            if (t_alloc(req[k]) == NULL) continue;
ffffffffc0205ad8:	8522                	mv	a0,s0
            t_iters++;
ffffffffc0205ada:	0785                	addi	a5,a5,1
ffffffffc0205adc:	00f9b023          	sd	a5,0(s3)
            if (t_alloc(req[k]) == NULL) continue;
ffffffffc0205ae0:	b24ff0ef          	jal	ffffffffc0204e04 <t_alloc>
ffffffffc0205ae4:	87aa                	mv	a5,a0
            if (slub_size_to_class(req[k]) != want_cls) {
ffffffffc0205ae6:	8522                	mv	a0,s0
            if (t_alloc(req[k]) == NULL) continue;
ffffffffc0205ae8:	c3b5                	beqz	a5,ffffffffc0205b4c <case_class_bounds+0xd6>
            if (slub_size_to_class(req[k]) != want_cls) {
ffffffffc0205aea:	de2fe0ef          	jal	ffffffffc02040cc <slub_size_to_class>
ffffffffc0205aee:	87aa                	mv	a5,a0
                slub_port_printf("  detail: size=%lu -> class %d want %d\n",
ffffffffc0205af0:	8522                	mv	a0,s0
            if (slub_size_to_class(req[k]) != want_cls) {
ffffffffc0205af2:	05278d63          	beq	a5,s2,ffffffffc0205b4c <case_class_bounds+0xd6>
                slub_port_printf("  detail: size=%lu -> class %d want %d\n",
ffffffffc0205af6:	dd6fe0ef          	jal	ffffffffc02040cc <slub_size_to_class>
ffffffffc0205afa:	862a                	mv	a2,a0
ffffffffc0205afc:	86ca                	mv	a3,s2
ffffffffc0205afe:	85a2                	mv	a1,s0
ffffffffc0205b00:	00003517          	auipc	a0,0x3
ffffffffc0205b04:	7a850513          	addi	a0,a0,1960 # ffffffffc02092a8 <etext+0x202c>
ffffffffc0205b08:	e48fa0ef          	jal	ffffffffc0200150 <cprintf>
                TFAIL("unexpected size class mapping");
ffffffffc0205b0c:	0009b703          	ld	a4,0(s3)
ffffffffc0205b10:	00022817          	auipc	a6,0x22
ffffffffc0205b14:	d4883803          	ld	a6,-696(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0205b18:	00007797          	auipc	a5,0x7
ffffffffc0205b1c:	4e87a783          	lw	a5,1256(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0205b20:	00022697          	auipc	a3,0x22
ffffffffc0205b24:	d506b683          	ld	a3,-688(a3) # ffffffffc0227870 <t_size>
ffffffffc0205b28:	00007597          	auipc	a1,0x7
ffffffffc0205b2c:	4e85b583          	ld	a1,1256(a1) # ffffffffc020d010 <t_case>
ffffffffc0205b30:	00003617          	auipc	a2,0x3
ffffffffc0205b34:	7a060613          	addi	a2,a2,1952 # ffffffffc02092d0 <etext+0x2054>
ffffffffc0205b38:	00003517          	auipc	a0,0x3
ffffffffc0205b3c:	2c050513          	addi	a0,a0,704 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0205b40:	00022897          	auipc	a7,0x22
ffffffffc0205b44:	d378a223          	sw	s7,-732(a7) # ffffffffc0227864 <t_case_failed>
ffffffffc0205b48:	e08fa0ef          	jal	ffffffffc0200150 <cprintf>
        for (k = 0; k < 3; k++) {
ffffffffc0205b4c:	04a1                	addi	s1,s1,8
ffffffffc0205b4e:	101c                	addi	a5,sp,32
ffffffffc0205b50:	f6f49de3          	bne	s1,a5,ffffffffc0205aca <case_class_bounds+0x54>
    for (cls = 0; cls < slub_nr_classes(); cls++) {
ffffffffc0205b54:	0a85                	addi	s5,s5,1
ffffffffc0205b56:	d72fe0ef          	jal	ffffffffc02040c8 <slub_nr_classes>
ffffffffc0205b5a:	f4aae1e3          	bltu	s5,a0,ffffffffc0205a9c <case_class_bounds+0x26>
    t_verify_all();
ffffffffc0205b5e:	fdbfe0ef          	jal	ffffffffc0204b38 <t_verify_all>
    while (t_n != 0) t_free_at(t_n - 1);
ffffffffc0205b62:	00022517          	auipc	a0,0x22
ffffffffc0205b66:	ce652503          	lw	a0,-794(a0) # ffffffffc0227848 <t_n>
ffffffffc0205b6a:	c909                	beqz	a0,ffffffffc0205b7c <case_class_bounds+0x106>
ffffffffc0205b6c:	357d                	addiw	a0,a0,-1
ffffffffc0205b6e:	d24ff0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc0205b72:	00022517          	auipc	a0,0x22
ffffffffc0205b76:	cd652503          	lw	a0,-810(a0) # ffffffffc0227848 <t_n>
ffffffffc0205b7a:	f96d                	bnez	a0,ffffffffc0205b6c <case_class_bounds+0xf6>
}
ffffffffc0205b7c:	70a6                	ld	ra,104(sp)
ffffffffc0205b7e:	7406                	ld	s0,96(sp)
ffffffffc0205b80:	64e6                	ld	s1,88(sp)
ffffffffc0205b82:	6946                	ld	s2,80(sp)
ffffffffc0205b84:	69a6                	ld	s3,72(sp)
ffffffffc0205b86:	6a06                	ld	s4,64(sp)
ffffffffc0205b88:	7ae2                	ld	s5,56(sp)
ffffffffc0205b8a:	7b42                	ld	s6,48(sp)
ffffffffc0205b8c:	7ba2                	ld	s7,40(sp)
ffffffffc0205b8e:	7c02                	ld	s8,32(sp)
ffffffffc0205b90:	6165                	addi	sp,sp,112
ffffffffc0205b92:	8082                	ret
                                                : -1);
ffffffffc0205b94:	f48c60e3          	bltu	s8,s0,ffffffffc0205ad4 <case_class_bounds+0x5e>
            int want_cls = (req[k] <= s) ? (int)cls
ffffffffc0205b98:	001a891b          	addiw	s2,s5,1
ffffffffc0205b9c:	bf25                	j	ffffffffc0205ad4 <case_class_bounds+0x5e>

ffffffffc0205b9e <case_sizes_edge>:
static void case_sizes_edge(void) {
ffffffffc0205b9e:	7179                	addi	sp,sp,-48
    if (t_alloc(16) == NULL || t_alloc(64) == NULL) return;
ffffffffc0205ba0:	4541                	li	a0,16
static void case_sizes_edge(void) {
ffffffffc0205ba2:	f406                	sd	ra,40(sp)
    if (t_alloc(16) == NULL || t_alloc(64) == NULL) return;
ffffffffc0205ba4:	a60ff0ef          	jal	ffffffffc0204e04 <t_alloc>
ffffffffc0205ba8:	18050063          	beqz	a0,ffffffffc0205d28 <case_sizes_edge+0x18a>
ffffffffc0205bac:	04000513          	li	a0,64
ffffffffc0205bb0:	a54ff0ef          	jal	ffffffffc0204e04 <t_alloc>
ffffffffc0205bb4:	16050a63          	beqz	a0,ffffffffc0205d28 <case_sizes_edge+0x18a>
    if (kmalloc(0) != NULL) TFAIL("kmalloc(0) must return NULL");
ffffffffc0205bb8:	4501                	li	a0,0
ffffffffc0205bba:	e84a                	sd	s2,16(sp)
ffffffffc0205bbc:	f022                	sd	s0,32(sp)
ffffffffc0205bbe:	ec26                	sd	s1,24(sp)
ffffffffc0205bc0:	e44e                	sd	s3,8(sp)
ffffffffc0205bc2:	e052                	sd	s4,0(sp)
    t_size = 0;
ffffffffc0205bc4:	00022797          	auipc	a5,0x22
ffffffffc0205bc8:	ca07b623          	sd	zero,-852(a5) # ffffffffc0227870 <t_size>
    if (kmalloc(0) != NULL) TFAIL("kmalloc(0) must return NULL");
ffffffffc0205bcc:	8d0fe0ef          	jal	ffffffffc0203c9c <kmalloc>
ffffffffc0205bd0:	00022917          	auipc	s2,0x22
ffffffffc0205bd4:	c9890913          	addi	s2,s2,-872 # ffffffffc0227868 <t_iters>
ffffffffc0205bd8:	c131                	beqz	a0,ffffffffc0205c1c <case_sizes_edge+0x7e>
ffffffffc0205bda:	4605                	li	a2,1
ffffffffc0205bdc:	00022817          	auipc	a6,0x22
ffffffffc0205be0:	c7c83803          	ld	a6,-900(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0205be4:	00007797          	auipc	a5,0x7
ffffffffc0205be8:	41c7a783          	lw	a5,1052(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0205bec:	00093703          	ld	a4,0(s2)
ffffffffc0205bf0:	00022697          	auipc	a3,0x22
ffffffffc0205bf4:	c806b683          	ld	a3,-896(a3) # ffffffffc0227870 <t_size>
ffffffffc0205bf8:	00007597          	auipc	a1,0x7
ffffffffc0205bfc:	4185b583          	ld	a1,1048(a1) # ffffffffc020d010 <t_case>
ffffffffc0205c00:	00022517          	auipc	a0,0x22
ffffffffc0205c04:	c6c52223          	sw	a2,-924(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0205c08:	00003517          	auipc	a0,0x3
ffffffffc0205c0c:	1f050513          	addi	a0,a0,496 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0205c10:	00003617          	auipc	a2,0x3
ffffffffc0205c14:	6e060613          	addi	a2,a2,1760 # ffffffffc02092f0 <etext+0x2074>
ffffffffc0205c18:	d38fa0ef          	jal	ffffffffc0200150 <cprintf>
    if (slub_size_to_class(0) != -1) TFAIL("size 0 must map to no class");
ffffffffc0205c1c:	4501                	li	a0,0
ffffffffc0205c1e:	caefe0ef          	jal	ffffffffc02040cc <slub_size_to_class>
ffffffffc0205c22:	57fd                	li	a5,-1
ffffffffc0205c24:	04f50363          	beq	a0,a5,ffffffffc0205c6a <case_sizes_edge+0xcc>
ffffffffc0205c28:	4605                	li	a2,1
ffffffffc0205c2a:	00022817          	auipc	a6,0x22
ffffffffc0205c2e:	c2e83803          	ld	a6,-978(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0205c32:	00007797          	auipc	a5,0x7
ffffffffc0205c36:	3ce7a783          	lw	a5,974(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0205c3a:	00093703          	ld	a4,0(s2)
ffffffffc0205c3e:	00022697          	auipc	a3,0x22
ffffffffc0205c42:	c326b683          	ld	a3,-974(a3) # ffffffffc0227870 <t_size>
ffffffffc0205c46:	00007597          	auipc	a1,0x7
ffffffffc0205c4a:	3ca5b583          	ld	a1,970(a1) # ffffffffc020d010 <t_case>
ffffffffc0205c4e:	00022517          	auipc	a0,0x22
ffffffffc0205c52:	c0c52b23          	sw	a2,-1002(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0205c56:	00003517          	auipc	a0,0x3
ffffffffc0205c5a:	1a250513          	addi	a0,a0,418 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0205c5e:	00003617          	auipc	a2,0x3
ffffffffc0205c62:	6b260613          	addi	a2,a2,1714 # ffffffffc0209310 <etext+0x2094>
ffffffffc0205c66:	ceafa0ef          	jal	ffffffffc0200150 <cprintf>
    t_verify_all();
ffffffffc0205c6a:	ecffe0ef          	jal	ffffffffc0204b38 <t_verify_all>
    for (i = 0; i < sizeof(sizes) / sizeof(sizes[0]); i++) {
ffffffffc0205c6e:	00004497          	auipc	s1,0x4
ffffffffc0205c72:	ed248493          	addi	s1,s1,-302 # ffffffffc0209b40 <sizes.0>
ffffffffc0205c76:	00004997          	auipc	s3,0x4
ffffffffc0205c7a:	eea98993          	addi	s3,s3,-278 # ffffffffc0209b60 <sizes.1>
        int cls = slub_size_to_class(sizes[i]);
ffffffffc0205c7e:	6080                	ld	s0,0(s1)
ffffffffc0205c80:	8522                	mv	a0,s0
ffffffffc0205c82:	c4afe0ef          	jal	ffffffffc02040cc <slub_size_to_class>
        t_iters++;
ffffffffc0205c86:	00093783          	ld	a5,0(s2)
        int cls = slub_size_to_class(sizes[i]);
ffffffffc0205c8a:	8a2a                	mv	s4,a0
        if (t_alloc(sizes[i]) == NULL) continue;
ffffffffc0205c8c:	8522                	mv	a0,s0
        t_iters++;
ffffffffc0205c8e:	0785                	addi	a5,a5,1
ffffffffc0205c90:	00f93023          	sd	a5,0(s2)
        if (t_alloc(sizes[i]) == NULL) continue;
ffffffffc0205c94:	970ff0ef          	jal	ffffffffc0204e04 <t_alloc>
ffffffffc0205c98:	87aa                	mv	a5,a0
            slub_port_printf("  detail: size=%lu -> class %d\n",
ffffffffc0205c9a:	85a2                	mv	a1,s0
        if (cls != (sizes[i] <= 16 ? 0 : 1)) {
ffffffffc0205c9c:	01143413          	sltiu	s0,s0,17
            slub_port_printf("  detail: size=%lu -> class %d\n",
ffffffffc0205ca0:	8652                	mv	a2,s4
ffffffffc0205ca2:	00003517          	auipc	a0,0x3
ffffffffc0205ca6:	68e50513          	addi	a0,a0,1678 # ffffffffc0209330 <etext+0x20b4>
        if (cls != (sizes[i] <= 16 ? 0 : 1)) {
ffffffffc0205caa:	00143413          	seqz	s0,s0
        if (t_alloc(sizes[i]) == NULL) continue;
ffffffffc0205cae:	c7b1                	beqz	a5,ffffffffc0205cfa <case_sizes_edge+0x15c>
        if (cls != (sizes[i] <= 16 ? 0 : 1)) {
ffffffffc0205cb0:	05440563          	beq	s0,s4,ffffffffc0205cfa <case_sizes_edge+0x15c>
            slub_port_printf("  detail: size=%lu -> class %d\n",
ffffffffc0205cb4:	c9cfa0ef          	jal	ffffffffc0200150 <cprintf>
            TFAIL("unexpected size class mapping");
ffffffffc0205cb8:	00022817          	auipc	a6,0x22
ffffffffc0205cbc:	ba083803          	ld	a6,-1120(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0205cc0:	00007797          	auipc	a5,0x7
ffffffffc0205cc4:	3407a783          	lw	a5,832(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0205cc8:	00093703          	ld	a4,0(s2)
ffffffffc0205ccc:	00022697          	auipc	a3,0x22
ffffffffc0205cd0:	ba46b683          	ld	a3,-1116(a3) # ffffffffc0227870 <t_size>
ffffffffc0205cd4:	00007597          	auipc	a1,0x7
ffffffffc0205cd8:	33c5b583          	ld	a1,828(a1) # ffffffffc020d010 <t_case>
ffffffffc0205cdc:	4405                	li	s0,1
ffffffffc0205cde:	00003617          	auipc	a2,0x3
ffffffffc0205ce2:	5f260613          	addi	a2,a2,1522 # ffffffffc02092d0 <etext+0x2054>
ffffffffc0205ce6:	00003517          	auipc	a0,0x3
ffffffffc0205cea:	11250513          	addi	a0,a0,274 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0205cee:	00022897          	auipc	a7,0x22
ffffffffc0205cf2:	b688ab23          	sw	s0,-1162(a7) # ffffffffc0227864 <t_case_failed>
ffffffffc0205cf6:	c5afa0ef          	jal	ffffffffc0200150 <cprintf>
    for (i = 0; i < sizeof(sizes) / sizeof(sizes[0]); i++) {
ffffffffc0205cfa:	04a1                	addi	s1,s1,8
ffffffffc0205cfc:	f93491e3          	bne	s1,s3,ffffffffc0205c7e <case_sizes_edge+0xe0>
    t_verify_all();
ffffffffc0205d00:	e39fe0ef          	jal	ffffffffc0204b38 <t_verify_all>
    while (t_n != 0) t_free_at(t_n - 1);
ffffffffc0205d04:	00022517          	auipc	a0,0x22
ffffffffc0205d08:	b4452503          	lw	a0,-1212(a0) # ffffffffc0227848 <t_n>
ffffffffc0205d0c:	c909                	beqz	a0,ffffffffc0205d1e <case_sizes_edge+0x180>
ffffffffc0205d0e:	357d                	addiw	a0,a0,-1
ffffffffc0205d10:	b82ff0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc0205d14:	00022517          	auipc	a0,0x22
ffffffffc0205d18:	b3452503          	lw	a0,-1228(a0) # ffffffffc0227848 <t_n>
ffffffffc0205d1c:	f96d                	bnez	a0,ffffffffc0205d0e <case_sizes_edge+0x170>
ffffffffc0205d1e:	7402                	ld	s0,32(sp)
ffffffffc0205d20:	64e2                	ld	s1,24(sp)
ffffffffc0205d22:	6942                	ld	s2,16(sp)
ffffffffc0205d24:	69a2                	ld	s3,8(sp)
ffffffffc0205d26:	6a02                	ld	s4,0(sp)
}
ffffffffc0205d28:	70a2                	ld	ra,40(sp)
ffffffffc0205d2a:	6145                	addi	sp,sp,48
ffffffffc0205d2c:	8082                	ret

ffffffffc0205d2e <case_check_ptr>:
    t_expect_baseline("not restored after fault injection recovery");
}

/* ------------------------- 用例 13：调试指针校验（正向） ------------------------- */

static void case_check_ptr(void) {
ffffffffc0205d2e:	1101                	addi	sp,sp,-32
    size_t cls;

    slub_check_ptr(NULL); /* 契约：无操作 */
ffffffffc0205d30:	4501                	li	a0,0
static void case_check_ptr(void) {
ffffffffc0205d32:	e822                	sd	s0,16(sp)
ffffffffc0205d34:	e426                	sd	s1,8(sp)
ffffffffc0205d36:	ec06                	sd	ra,24(sp)
    for (cls = 0; cls < slub_nr_classes(); cls++) {
ffffffffc0205d38:	4401                	li	s0,0
    slub_check_ptr(NULL); /* 契约：无操作 */
ffffffffc0205d3a:	fdefe0ef          	jal	ffffffffc0204518 <slub_check_ptr>
        if (t_alloc(slub_class_size(cls)) == NULL) return;
        t_iters++;
ffffffffc0205d3e:	00022497          	auipc	s1,0x22
ffffffffc0205d42:	b2a48493          	addi	s1,s1,-1238 # ffffffffc0227868 <t_iters>
    for (cls = 0; cls < slub_nr_classes(); cls++) {
ffffffffc0205d46:	a811                	j	ffffffffc0205d5a <case_check_ptr+0x2c>
        if (t_alloc(slub_class_size(cls)) == NULL) return;
ffffffffc0205d48:	bb0fe0ef          	jal	ffffffffc02040f8 <slub_class_size>
ffffffffc0205d4c:	8b8ff0ef          	jal	ffffffffc0204e04 <t_alloc>
ffffffffc0205d50:	c149                	beqz	a0,ffffffffc0205dd2 <case_check_ptr+0xa4>
        t_iters++;
ffffffffc0205d52:	609c                	ld	a5,0(s1)
    for (cls = 0; cls < slub_nr_classes(); cls++) {
ffffffffc0205d54:	0405                	addi	s0,s0,1
        t_iters++;
ffffffffc0205d56:	0785                	addi	a5,a5,1
ffffffffc0205d58:	e09c                	sd	a5,0(s1)
    for (cls = 0; cls < slub_nr_classes(); cls++) {
ffffffffc0205d5a:	b6efe0ef          	jal	ffffffffc02040c8 <slub_nr_classes>
ffffffffc0205d5e:	87aa                	mv	a5,a0
        if (t_alloc(slub_class_size(cls)) == NULL) return;
ffffffffc0205d60:	8522                	mv	a0,s0
    for (cls = 0; cls < slub_nr_classes(); cls++) {
ffffffffc0205d62:	fef463e3          	bltu	s0,a5,ffffffffc0205d48 <case_check_ptr+0x1a>
    }
    if (t_alloc(SLUB_MAX_SMALL_SIZE + 5000) == NULL) return;
ffffffffc0205d66:	6509                	lui	a0,0x2
ffffffffc0205d68:	b8850513          	addi	a0,a0,-1144 # 1b88 <kern_entry-0xffffffffc01fe478>
ffffffffc0205d6c:	898ff0ef          	jal	ffffffffc0204e04 <t_alloc>
ffffffffc0205d70:	c12d                	beqz	a0,ffffffffc0205dd2 <case_check_ptr+0xa4>
    {
        unsigned int i;
        for (i = 0; i < t_n; i++) slub_check_ptr(t_objs[i].p);
ffffffffc0205d72:	00022797          	auipc	a5,0x22
ffffffffc0205d76:	ad67a783          	lw	a5,-1322(a5) # ffffffffc0227848 <t_n>
ffffffffc0205d7a:	c38d                	beqz	a5,ffffffffc0205d9c <case_check_ptr+0x6e>
ffffffffc0205d7c:	0001b497          	auipc	s1,0x1b
ffffffffc0205d80:	e2448493          	addi	s1,s1,-476 # ffffffffc0220ba0 <t_objs>
ffffffffc0205d84:	4401                	li	s0,0
ffffffffc0205d86:	6088                	ld	a0,0(s1)
ffffffffc0205d88:	2405                	addiw	s0,s0,1
ffffffffc0205d8a:	04e1                	addi	s1,s1,24
ffffffffc0205d8c:	f8cfe0ef          	jal	ffffffffc0204518 <slub_check_ptr>
ffffffffc0205d90:	00022797          	auipc	a5,0x22
ffffffffc0205d94:	ab87a783          	lw	a5,-1352(a5) # ffffffffc0227848 <t_n>
ffffffffc0205d98:	fef467e3          	bltu	s0,a5,ffffffffc0205d86 <case_check_ptr+0x58>
    }
    t_verify_all();
ffffffffc0205d9c:	d9dfe0ef          	jal	ffffffffc0204b38 <t_verify_all>
    while (t_n != 0) t_free_at(t_n - 1);
ffffffffc0205da0:	00022517          	auipc	a0,0x22
ffffffffc0205da4:	aa852503          	lw	a0,-1368(a0) # ffffffffc0227848 <t_n>
ffffffffc0205da8:	c909                	beqz	a0,ffffffffc0205dba <case_check_ptr+0x8c>
ffffffffc0205daa:	357d                	addiw	a0,a0,-1
ffffffffc0205dac:	ae6ff0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc0205db0:	00022517          	auipc	a0,0x22
ffffffffc0205db4:	a9852503          	lw	a0,-1384(a0) # ffffffffc0227848 <t_n>
ffffffffc0205db8:	f96d                	bnez	a0,ffffffffc0205daa <case_check_ptr+0x7c>
    t_free_all();
    slub_shrink();
ffffffffc0205dba:	afefe0ef          	jal	ffffffffc02040b8 <slub_shrink>
    t_expect_baseline("not restored after check_ptr case");
}
ffffffffc0205dbe:	6442                	ld	s0,16(sp)
ffffffffc0205dc0:	60e2                	ld	ra,24(sp)
ffffffffc0205dc2:	64a2                	ld	s1,8(sp)
    t_expect_baseline("not restored after check_ptr case");
ffffffffc0205dc4:	00003517          	auipc	a0,0x3
ffffffffc0205dc8:	58c50513          	addi	a0,a0,1420 # ffffffffc0209350 <etext+0x20d4>
}
ffffffffc0205dcc:	6105                	addi	sp,sp,32
    t_expect_baseline("not restored after check_ptr case");
ffffffffc0205dce:	b54ff06f          	j	ffffffffc0205122 <t_expect_baseline>
}
ffffffffc0205dd2:	60e2                	ld	ra,24(sp)
ffffffffc0205dd4:	6442                	ld	s0,16(sp)
ffffffffc0205dd6:	64a2                	ld	s1,8(sp)
ffffffffc0205dd8:	6105                	addi	sp,sp,32
ffffffffc0205dda:	8082                	ret

ffffffffc0205ddc <t_run>:

/* ------------------------- 用例驱动 ------------------------- */

static void t_run(void (*fn)(void), const char *name) {
ffffffffc0205ddc:	1101                	addi	sp,sp,-32
ffffffffc0205dde:	e822                	sd	s0,16(sp)
ffffffffc0205de0:	e426                	sd	s1,8(sp)
ffffffffc0205de2:	ec06                	sd	ra,24(sp)
    t_case = name;
ffffffffc0205de4:	00007497          	auipc	s1,0x7
ffffffffc0205de8:	22c48493          	addi	s1,s1,556 # ffffffffc020d010 <t_case>
    t_case_failed = 0;
ffffffffc0205dec:	00022797          	auipc	a5,0x22
ffffffffc0205df0:	a607ac23          	sw	zero,-1416(a5) # ffffffffc0227864 <t_case_failed>
    t_size = 0;
ffffffffc0205df4:	00022797          	auipc	a5,0x22
ffffffffc0205df8:	a607be23          	sd	zero,-1412(a5) # ffffffffc0227870 <t_size>
    t_iters = 0;
ffffffffc0205dfc:	00022797          	auipc	a5,0x22
ffffffffc0205e00:	a607b623          	sd	zero,-1428(a5) # ffffffffc0227868 <t_iters>
static void t_run(void (*fn)(void), const char *name) {
ffffffffc0205e04:	842e                	mv	s0,a1
    t_case = name;
ffffffffc0205e06:	e08c                	sd	a1,0(s1)
    fn();
ffffffffc0205e08:	9502                	jalr	a0
    if (t_n != 0) {
ffffffffc0205e0a:	00022797          	auipc	a5,0x22
ffffffffc0205e0e:	a3e7a783          	lw	a5,-1474(a5) # ffffffffc0227848 <t_n>
ffffffffc0205e12:	e7b9                	bnez	a5,ffffffffc0205e60 <t_run+0x84>
        TFAIL("case left live objects behind");
        t_free_all();
    }
    slub_port_printf("SLUB_TEST_CASE %s %s\n", name,
ffffffffc0205e14:	00022797          	auipc	a5,0x22
ffffffffc0205e18:	a507a783          	lw	a5,-1456(a5) # ffffffffc0227864 <t_case_failed>
ffffffffc0205e1c:	00003617          	auipc	a2,0x3
ffffffffc0205e20:	56460613          	addi	a2,a2,1380 # ffffffffc0209380 <etext+0x2104>
ffffffffc0205e24:	c789                	beqz	a5,ffffffffc0205e2e <t_run+0x52>
ffffffffc0205e26:	00003617          	auipc	a2,0x3
ffffffffc0205e2a:	55260613          	addi	a2,a2,1362 # ffffffffc0209378 <etext+0x20fc>
ffffffffc0205e2e:	85a2                	mv	a1,s0
ffffffffc0205e30:	00003517          	auipc	a0,0x3
ffffffffc0205e34:	57850513          	addi	a0,a0,1400 # ffffffffc02093a8 <etext+0x212c>
ffffffffc0205e38:	b18fa0ef          	jal	ffffffffc0200150 <cprintf>
                     t_case_failed ? "FAIL" : "PASS");
    t_total_failed += t_case_failed;
ffffffffc0205e3c:	00022717          	auipc	a4,0x22
ffffffffc0205e40:	a2472703          	lw	a4,-1500(a4) # ffffffffc0227860 <t_total_failed>
ffffffffc0205e44:	00022797          	auipc	a5,0x22
ffffffffc0205e48:	a207a783          	lw	a5,-1504(a5) # ffffffffc0227864 <t_case_failed>
}
ffffffffc0205e4c:	60e2                	ld	ra,24(sp)
ffffffffc0205e4e:	6442                	ld	s0,16(sp)
    t_total_failed += t_case_failed;
ffffffffc0205e50:	9fb9                	addw	a5,a5,a4
ffffffffc0205e52:	00022717          	auipc	a4,0x22
ffffffffc0205e56:	a0f72723          	sw	a5,-1522(a4) # ffffffffc0227860 <t_total_failed>
}
ffffffffc0205e5a:	64a2                	ld	s1,8(sp)
ffffffffc0205e5c:	6105                	addi	sp,sp,32
ffffffffc0205e5e:	8082                	ret
        TFAIL("case left live objects behind");
ffffffffc0205e60:	4605                	li	a2,1
ffffffffc0205e62:	00022717          	auipc	a4,0x22
ffffffffc0205e66:	a0673703          	ld	a4,-1530(a4) # ffffffffc0227868 <t_iters>
ffffffffc0205e6a:	00022697          	auipc	a3,0x22
ffffffffc0205e6e:	a066b683          	ld	a3,-1530(a3) # ffffffffc0227870 <t_size>
ffffffffc0205e72:	608c                	ld	a1,0(s1)
ffffffffc0205e74:	00022817          	auipc	a6,0x22
ffffffffc0205e78:	9e483803          	ld	a6,-1564(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0205e7c:	00007797          	auipc	a5,0x7
ffffffffc0205e80:	1847a783          	lw	a5,388(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0205e84:	00022517          	auipc	a0,0x22
ffffffffc0205e88:	9ec52023          	sw	a2,-1568(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0205e8c:	00003517          	auipc	a0,0x3
ffffffffc0205e90:	f6c50513          	addi	a0,a0,-148 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0205e94:	00003617          	auipc	a2,0x3
ffffffffc0205e98:	4f460613          	addi	a2,a2,1268 # ffffffffc0209388 <etext+0x210c>
ffffffffc0205e9c:	ab4fa0ef          	jal	ffffffffc0200150 <cprintf>
    while (t_n != 0) t_free_at(t_n - 1);
ffffffffc0205ea0:	00022517          	auipc	a0,0x22
ffffffffc0205ea4:	9a852503          	lw	a0,-1624(a0) # ffffffffc0227848 <t_n>
ffffffffc0205ea8:	d535                	beqz	a0,ffffffffc0205e14 <t_run+0x38>
ffffffffc0205eaa:	357d                	addiw	a0,a0,-1
ffffffffc0205eac:	9e6ff0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc0205eb0:	00022517          	auipc	a0,0x22
ffffffffc0205eb4:	99852503          	lw	a0,-1640(a0) # ffffffffc0227848 <t_n>
ffffffffc0205eb8:	f96d                	bnez	a0,ffffffffc0205eaa <t_run+0xce>
ffffffffc0205eba:	bfa9                	j	ffffffffc0205e14 <t_run+0x38>

ffffffffc0205ebc <case_overflow>:
static void case_overflow(void) {
ffffffffc0205ebc:	715d                	addi	sp,sp,-80
    if (t_alloc(32) == NULL || t_alloc(4000) == NULL) return;
ffffffffc0205ebe:	02000513          	li	a0,32
static void case_overflow(void) {
ffffffffc0205ec2:	e486                	sd	ra,72(sp)
    if (t_alloc(32) == NULL || t_alloc(4000) == NULL) return;
ffffffffc0205ec4:	f41fe0ef          	jal	ffffffffc0204e04 <t_alloc>
ffffffffc0205ec8:	10050c63          	beqz	a0,ffffffffc0205fe0 <case_overflow+0x124>
ffffffffc0205ecc:	6505                	lui	a0,0x1
ffffffffc0205ece:	fa050513          	addi	a0,a0,-96 # fa0 <kern_entry-0xffffffffc01ff060>
ffffffffc0205ed2:	f33fe0ef          	jal	ffffffffc0204e04 <t_alloc>
ffffffffc0205ed6:	10050563          	beqz	a0,ffffffffc0205fe0 <case_overflow+0x124>
ffffffffc0205eda:	e0a2                	sd	s0,64(sp)
ffffffffc0205edc:	fc26                	sd	s1,56(sp)
ffffffffc0205ede:	f84a                	sd	s2,48(sp)
ffffffffc0205ee0:	f44e                	sd	s3,40(sp)
ffffffffc0205ee2:	f052                	sd	s4,32(sp)
ffffffffc0205ee4:	ec56                	sd	s5,24(sp)
ffffffffc0205ee6:	e85a                	sd	s6,16(sp)
ffffffffc0205ee8:	e45e                	sd	s7,8(sp)
ffffffffc0205eea:	e062                	sd	s8,0(sp)
ffffffffc0205eec:	9dbfc0ef          	jal	ffffffffc02028c6 <nr_free_pages>
ffffffffc0205ef0:	8c2a                	mv	s8,a0
    for (i = 0; i < sizeof(bad) / sizeof(bad[0]); i++) {
ffffffffc0205ef2:	00004417          	auipc	s0,0x4
ffffffffc0205ef6:	ca640413          	addi	s0,s0,-858 # ffffffffc0209b98 <bad.2>
ffffffffc0205efa:	00004997          	auipc	s3,0x4
ffffffffc0205efe:	cde98993          	addi	s3,s3,-802 # ffffffffc0209bd8 <sizes.5>
ffffffffc0205f02:	00022917          	auipc	s2,0x22
ffffffffc0205f06:	96e90913          	addi	s2,s2,-1682 # ffffffffc0227870 <t_size>
ffffffffc0205f0a:	00022497          	auipc	s1,0x22
ffffffffc0205f0e:	95e48493          	addi	s1,s1,-1698 # ffffffffc0227868 <t_iters>
            TFAIL("zero/overflow request must return NULL");
ffffffffc0205f12:	4b85                	li	s7,1
ffffffffc0205f14:	00022b17          	auipc	s6,0x22
ffffffffc0205f18:	944b0b13          	addi	s6,s6,-1724 # ffffffffc0227858 <t_seed_cfg>
    return (unsigned int)boot_hartid;
ffffffffc0205f1c:	00007a97          	auipc	s5,0x7
ffffffffc0205f20:	0e4a8a93          	addi	s5,s5,228 # ffffffffc020d000 <boot_hartid>
ffffffffc0205f24:	00007a17          	auipc	s4,0x7
ffffffffc0205f28:	0eca0a13          	addi	s4,s4,236 # ffffffffc020d010 <t_case>
        t_iters++;
ffffffffc0205f2c:	609c                	ld	a5,0(s1)
        t_size = bad[i];
ffffffffc0205f2e:	6008                	ld	a0,0(s0)
        t_iters++;
ffffffffc0205f30:	0785                	addi	a5,a5,1
ffffffffc0205f32:	e09c                	sd	a5,0(s1)
        t_size = bad[i];
ffffffffc0205f34:	00a93023          	sd	a0,0(s2)
        if (kmalloc(bad[i]) != NULL) {
ffffffffc0205f38:	d65fd0ef          	jal	ffffffffc0203c9c <kmalloc>
ffffffffc0205f3c:	87aa                	mv	a5,a0
            TFAIL("zero/overflow request must return NULL");
ffffffffc0205f3e:	00003617          	auipc	a2,0x3
ffffffffc0205f42:	48260613          	addi	a2,a2,1154 # ffffffffc02093c0 <etext+0x2144>
ffffffffc0205f46:	00003517          	auipc	a0,0x3
ffffffffc0205f4a:	eb250513          	addi	a0,a0,-334 # ffffffffc0208df8 <etext+0x1b7c>
        if (kmalloc(bad[i]) != NULL) {
ffffffffc0205f4e:	c385                	beqz	a5,ffffffffc0205f6e <case_overflow+0xb2>
            TFAIL("zero/overflow request must return NULL");
ffffffffc0205f50:	000b3803          	ld	a6,0(s6)
ffffffffc0205f54:	000aa783          	lw	a5,0(s5)
ffffffffc0205f58:	6098                	ld	a4,0(s1)
ffffffffc0205f5a:	00093683          	ld	a3,0(s2)
ffffffffc0205f5e:	000a3583          	ld	a1,0(s4)
ffffffffc0205f62:	00022897          	auipc	a7,0x22
ffffffffc0205f66:	9178a123          	sw	s7,-1790(a7) # ffffffffc0227864 <t_case_failed>
ffffffffc0205f6a:	9e6fa0ef          	jal	ffffffffc0200150 <cprintf>
    for (i = 0; i < sizeof(bad) / sizeof(bad[0]); i++) {
ffffffffc0205f6e:	0421                	addi	s0,s0,8
ffffffffc0205f70:	fb341ee3          	bne	s0,s3,ffffffffc0205f2c <case_overflow+0x70>
    t_verify_all(); /* 既有对象未被失败请求破坏 */
ffffffffc0205f74:	bc5fe0ef          	jal	ffffffffc0204b38 <t_verify_all>
    return nr_free_pages();
ffffffffc0205f78:	94ffc0ef          	jal	ffffffffc02028c6 <nr_free_pages>
    if (slub_port_nr_free_pages() != before) {
ffffffffc0205f7c:	04ac0463          	beq	s8,a0,ffffffffc0205fc4 <case_overflow+0x108>
        TFAIL("failed allocations changed free page count");
ffffffffc0205f80:	4605                	li	a2,1
ffffffffc0205f82:	6098                	ld	a4,0(s1)
ffffffffc0205f84:	00093683          	ld	a3,0(s2)
ffffffffc0205f88:	00022817          	auipc	a6,0x22
ffffffffc0205f8c:	8d083803          	ld	a6,-1840(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0205f90:	00007797          	auipc	a5,0x7
ffffffffc0205f94:	0707a783          	lw	a5,112(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0205f98:	00007597          	auipc	a1,0x7
ffffffffc0205f9c:	0785b583          	ld	a1,120(a1) # ffffffffc020d010 <t_case>
ffffffffc0205fa0:	00022517          	auipc	a0,0x22
ffffffffc0205fa4:	8cc52223          	sw	a2,-1852(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0205fa8:	00003517          	auipc	a0,0x3
ffffffffc0205fac:	e5050513          	addi	a0,a0,-432 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0205fb0:	00003617          	auipc	a2,0x3
ffffffffc0205fb4:	43860613          	addi	a2,a2,1080 # ffffffffc02093e8 <etext+0x216c>
ffffffffc0205fb8:	998fa0ef          	jal	ffffffffc0200150 <cprintf>
    while (t_n != 0) t_free_at(t_n - 1);
ffffffffc0205fbc:	a021                	j	ffffffffc0205fc4 <case_overflow+0x108>
ffffffffc0205fbe:	357d                	addiw	a0,a0,-1
ffffffffc0205fc0:	8d2ff0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc0205fc4:	00022517          	auipc	a0,0x22
ffffffffc0205fc8:	88452503          	lw	a0,-1916(a0) # ffffffffc0227848 <t_n>
ffffffffc0205fcc:	f96d                	bnez	a0,ffffffffc0205fbe <case_overflow+0x102>
ffffffffc0205fce:	6406                	ld	s0,64(sp)
ffffffffc0205fd0:	74e2                	ld	s1,56(sp)
ffffffffc0205fd2:	7942                	ld	s2,48(sp)
ffffffffc0205fd4:	79a2                	ld	s3,40(sp)
ffffffffc0205fd6:	7a02                	ld	s4,32(sp)
ffffffffc0205fd8:	6ae2                	ld	s5,24(sp)
ffffffffc0205fda:	6b42                	ld	s6,16(sp)
ffffffffc0205fdc:	6ba2                	ld	s7,8(sp)
ffffffffc0205fde:	6c02                	ld	s8,0(sp)
}
ffffffffc0205fe0:	60a6                	ld	ra,72(sp)
ffffffffc0205fe2:	6161                	addi	sp,sp,80
ffffffffc0205fe4:	8082                	ret

ffffffffc0205fe6 <case_free_orders>:
static void case_free_orders(void) {
ffffffffc0205fe6:	7119                	addi	sp,sp,-128
ffffffffc0205fe8:	f0ca                	sd	s2,96(sp)
ffffffffc0205fea:	ecce                	sd	s3,88(sp)
ffffffffc0205fec:	e8d2                	sd	s4,80(sp)
ffffffffc0205fee:	e4d6                	sd	s5,72(sp)
ffffffffc0205ff0:	e0da                	sd	s6,64(sp)
ffffffffc0205ff2:	fc5e                	sd	s7,56(sp)
ffffffffc0205ff4:	fc86                	sd	ra,120(sp)
ffffffffc0205ff6:	f8a2                	sd	s0,112(sp)
    for (ord = 0; ord < 4; ord++) {
ffffffffc0205ff8:	e402                	sd	zero,8(sp)
ffffffffc0205ffa:	00022b97          	auipc	s7,0x22
ffffffffc0205ffe:	876b8b93          	addi	s7,s7,-1930 # ffffffffc0227870 <t_size>
ffffffffc0206002:	00019a97          	auipc	s5,0x19
ffffffffc0206006:	67ea8a93          	addi	s5,s5,1662 # ffffffffc021f680 <ids.4>
ffffffffc020600a:	0001aa17          	auipc	s4,0x1a
ffffffffc020600e:	996a0a13          	addi	s4,s4,-1642 # ffffffffc021f9a0 <idx.6>
            ids[i] = t_objs[t_n - 1].id;
ffffffffc0206012:	0001b997          	auipc	s3,0x1b
ffffffffc0206016:	b8e98993          	addi	s3,s3,-1138 # ffffffffc0220ba0 <t_objs>
            if (i == ORD_K / 2) {
ffffffffc020601a:	06400913          	li	s2,100
        for (i = 0; i < ORD_K; i++) {
ffffffffc020601e:	0c800b13          	li	s6,200
        t_round = ord;
ffffffffc0206022:	6722                	ld	a4,8(sp)
ffffffffc0206024:	00019417          	auipc	s0,0x19
ffffffffc0206028:	65c40413          	addi	s0,s0,1628 # ffffffffc021f680 <ids.4>
ffffffffc020602c:	00022797          	auipc	a5,0x22
ffffffffc0206030:	80e7aa23          	sw	a4,-2028(a5) # ffffffffc0227840 <t_round>
        t_size = 32;
ffffffffc0206034:	02000793          	li	a5,32
ffffffffc0206038:	00fbb023          	sd	a5,0(s7)
        for (i = 0; i < ORD_K; i++) {
ffffffffc020603c:	a005                	j	ffffffffc020605c <case_free_orders+0x76>
            ids[i] = t_objs[t_n - 1].id;
ffffffffc020603e:	fff6071b          	addiw	a4,a2,-1
ffffffffc0206042:	1702                	slli	a4,a4,0x20
ffffffffc0206044:	9301                	srli	a4,a4,0x20
ffffffffc0206046:	00171793          	slli	a5,a4,0x1
ffffffffc020604a:	97ba                	add	a5,a5,a4
ffffffffc020604c:	078e                	slli	a5,a5,0x3
ffffffffc020604e:	97ce                	add	a5,a5,s3
ffffffffc0206050:	4b9c                	lw	a5,16(a5)
        for (i = 0; i < ORD_K; i++) {
ffffffffc0206052:	0411                	addi	s0,s0,4
            ids[i] = t_objs[t_n - 1].id;
ffffffffc0206054:	fef42e23          	sw	a5,-4(s0)
        for (i = 0; i < ORD_K; i++) {
ffffffffc0206058:	03440f63          	beq	s0,s4,ffffffffc0206096 <case_free_orders+0xb0>
            if (t_alloc(32) == NULL) {
ffffffffc020605c:	02000513          	li	a0,32
ffffffffc0206060:	da5fe0ef          	jal	ffffffffc0204e04 <t_alloc>
            ids[i] = t_objs[t_n - 1].id;
ffffffffc0206064:	00021617          	auipc	a2,0x21
ffffffffc0206068:	7e462603          	lw	a2,2020(a2) # ffffffffc0227848 <t_n>
            if (t_alloc(32) == NULL) {
ffffffffc020606c:	f969                	bnez	a0,ffffffffc020603e <case_free_orders+0x58>
    while (t_n != 0) t_free_at(t_n - 1);
ffffffffc020606e:	ca11                	beqz	a2,ffffffffc0206082 <case_free_orders+0x9c>
ffffffffc0206070:	fff6051b          	addiw	a0,a2,-1
ffffffffc0206074:	81eff0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc0206078:	00021617          	auipc	a2,0x21
ffffffffc020607c:	7d062603          	lw	a2,2000(a2) # ffffffffc0227848 <t_n>
ffffffffc0206080:	fa65                	bnez	a2,ffffffffc0206070 <case_free_orders+0x8a>
}
ffffffffc0206082:	70e6                	ld	ra,120(sp)
ffffffffc0206084:	7446                	ld	s0,112(sp)
ffffffffc0206086:	7906                	ld	s2,96(sp)
ffffffffc0206088:	69e6                	ld	s3,88(sp)
ffffffffc020608a:	6a46                	ld	s4,80(sp)
ffffffffc020608c:	6aa6                	ld	s5,72(sp)
ffffffffc020608e:	6b06                	ld	s6,64(sp)
ffffffffc0206090:	7be2                	ld	s7,56(sp)
ffffffffc0206092:	6109                	addi	sp,sp,128
ffffffffc0206094:	8082                	ret
        switch (ord) {
ffffffffc0206096:	6722                	ld	a4,8(sp)
ffffffffc0206098:	f4a6                	sd	s1,104(sp)
ffffffffc020609a:	f862                	sd	s8,48(sp)
ffffffffc020609c:	f466                	sd	s9,40(sp)
ffffffffc020609e:	f06a                	sd	s10,32(sp)
ffffffffc02060a0:	ec6e                	sd	s11,24(sp)
ffffffffc02060a2:	4785                	li	a5,1
ffffffffc02060a4:	1cf70463          	beq	a4,a5,ffffffffc020626c <case_free_orders+0x286>
ffffffffc02060a8:	4789                	li	a5,2
ffffffffc02060aa:	18f70863          	beq	a4,a5,ffffffffc020623a <case_free_orders+0x254>
ffffffffc02060ae:	12070d63          	beqz	a4,ffffffffc02061e8 <case_free_orders+0x202>
ffffffffc02060b2:	00019517          	auipc	a0,0x19
ffffffffc02060b6:	2ae50513          	addi	a0,a0,686 # ffffffffc021f360 <order.3>
ffffffffc02060ba:	872a                	mv	a4,a0
            for (i = 0; i < ORD_K; i++) order[i] = i;
ffffffffc02060bc:	4781                	li	a5,0
ffffffffc02060be:	0c800693          	li	a3,200
ffffffffc02060c2:	c31c                	sw	a5,0(a4)
ffffffffc02060c4:	2785                	addiw	a5,a5,1
ffffffffc02060c6:	0711                	addi	a4,a4,4
ffffffffc02060c8:	fed79de3          	bne	a5,a3,ffffffffc02060c2 <case_free_orders+0xdc>
ffffffffc02060cc:	00021697          	auipc	a3,0x21
ffffffffc02060d0:	7846b683          	ld	a3,1924(a3) # ffffffffc0227850 <t_rng>
ffffffffc02060d4:	873e                	mv	a4,a5
ffffffffc02060d6:	00019597          	auipc	a1,0x19
ffffffffc02060da:	5a658593          	addi	a1,a1,1446 # ffffffffc021f67c <order.3+0x31c>
    x ^= x << 13;
ffffffffc02060de:	00d69793          	slli	a5,a3,0xd
ffffffffc02060e2:	8fb5                	xor	a5,a5,a3
    x ^= x >> 7;
ffffffffc02060e4:	0077d693          	srli	a3,a5,0x7
ffffffffc02060e8:	8fb5                	xor	a5,a5,a3
    x ^= x << 17;
ffffffffc02060ea:	01179693          	slli	a3,a5,0x11
ffffffffc02060ee:	8ebd                	xor	a3,a3,a5
                unsigned int j2 = (unsigned int)(trand() % i);
ffffffffc02060f0:	02e6f7b3          	remu	a5,a3,a4
                unsigned int tmp = order[i - 1];
ffffffffc02060f4:	0005a883          	lw	a7,0(a1)
            for (i = ORD_K; i > 1; i--) {
ffffffffc02060f8:	15f1                	addi	a1,a1,-4
                order[i - 1] = order[j2];
ffffffffc02060fa:	177d                	addi	a4,a4,-1
ffffffffc02060fc:	02079813          	slli	a6,a5,0x20
ffffffffc0206100:	01e85793          	srli	a5,a6,0x1e
ffffffffc0206104:	97aa                	add	a5,a5,a0
ffffffffc0206106:	0007a803          	lw	a6,0(a5)
ffffffffc020610a:	0105a223          	sw	a6,4(a1)
                order[j2] = tmp;
ffffffffc020610e:	0117a023          	sw	a7,0(a5)
            for (i = ORD_K; i > 1; i--) {
ffffffffc0206112:	fca596e3          	bne	a1,a0,ffffffffc02060de <case_free_orders+0xf8>
ffffffffc0206116:	01052223          	sw	a6,4(a0)
ffffffffc020611a:	00021717          	auipc	a4,0x21
ffffffffc020611e:	72d73b23          	sd	a3,1846(a4) # ffffffffc0227850 <t_rng>
ffffffffc0206122:	0117a023          	sw	a7,0(a5)
        for (i = 0; i < ORD_K; i++) {
ffffffffc0206126:	00021497          	auipc	s1,0x21
ffffffffc020612a:	74248493          	addi	s1,s1,1858 # ffffffffc0227868 <t_iters>
            t_iters++;
ffffffffc020612e:	6098                	ld	a4,0(s1)
ffffffffc0206130:	00019417          	auipc	s0,0x19
ffffffffc0206134:	23040413          	addi	s0,s0,560 # ffffffffc021f360 <order.3>
        for (i = 0; i < ORD_K; i++) {
ffffffffc0206138:	4c01                	li	s8,0
            t_iters++;
ffffffffc020613a:	0705                	addi	a4,a4,1
ffffffffc020613c:	e098                	sd	a4,0(s1)
    TFAIL("tried to free an id that is no longer live");
ffffffffc020613e:	4d85                	li	s11,1
ffffffffc0206140:	00021d17          	auipc	s10,0x21
ffffffffc0206144:	718d0d13          	addi	s10,s10,1816 # ffffffffc0227858 <t_seed_cfg>
    return (unsigned int)boot_hartid;
ffffffffc0206148:	00007c97          	auipc	s9,0x7
ffffffffc020614c:	eb8c8c93          	addi	s9,s9,-328 # ffffffffc020d000 <boot_hartid>
    for (i = 0; i < t_n; i++) {
ffffffffc0206150:	c239                	beqz	a2,ffffffffc0206196 <case_free_orders+0x1b0>
            t_free_id(ids[order[i]]);
ffffffffc0206152:	00046683          	lwu	a3,0(s0)
ffffffffc0206156:	0001b797          	auipc	a5,0x1b
ffffffffc020615a:	a5a78793          	addi	a5,a5,-1446 # ffffffffc0220bb0 <t_objs+0x10>
    for (i = 0; i < t_n; i++) {
ffffffffc020615e:	4501                	li	a0,0
            t_free_id(ids[order[i]]);
ffffffffc0206160:	068a                	slli	a3,a3,0x2
ffffffffc0206162:	96d6                	add	a3,a3,s5
ffffffffc0206164:	428c                	lw	a1,0(a3)
ffffffffc0206166:	a021                	j	ffffffffc020616e <case_free_orders+0x188>
    for (i = 0; i < t_n; i++) {
ffffffffc0206168:	2505                	addiw	a0,a0,1
ffffffffc020616a:	02c50663          	beq	a0,a2,ffffffffc0206196 <case_free_orders+0x1b0>
        if (t_objs[i].id == id) {
ffffffffc020616e:	4394                	lw	a3,0(a5)
    for (i = 0; i < t_n; i++) {
ffffffffc0206170:	07e1                	addi	a5,a5,24
        if (t_objs[i].id == id) {
ffffffffc0206172:	feb69be3          	bne	a3,a1,ffffffffc0206168 <case_free_orders+0x182>
            t_free_at(i);
ffffffffc0206176:	f1dfe0ef          	jal	ffffffffc0205092 <t_free_at>
            if (i == ORD_K / 2) {
ffffffffc020617a:	052c0863          	beq	s8,s2,ffffffffc02061ca <case_free_orders+0x1e4>
        for (i = 0; i < ORD_K; i++) {
ffffffffc020617e:	2c05                	addiw	s8,s8,1
ffffffffc0206180:	096c0163          	beq	s8,s6,ffffffffc0206202 <case_free_orders+0x21c>
ffffffffc0206184:	0411                	addi	s0,s0,4
            t_iters++;
ffffffffc0206186:	6098                	ld	a4,0(s1)
    for (i = 0; i < t_n; i++) {
ffffffffc0206188:	00021617          	auipc	a2,0x21
ffffffffc020618c:	6c062603          	lw	a2,1728(a2) # ffffffffc0227848 <t_n>
            t_iters++;
ffffffffc0206190:	0705                	addi	a4,a4,1
ffffffffc0206192:	e098                	sd	a4,0(s1)
    for (i = 0; i < t_n; i++) {
ffffffffc0206194:	fe5d                	bnez	a2,ffffffffc0206152 <case_free_orders+0x16c>
    TFAIL("tried to free an id that is no longer live");
ffffffffc0206196:	000d3803          	ld	a6,0(s10)
ffffffffc020619a:	000ca783          	lw	a5,0(s9)
ffffffffc020619e:	000bb683          	ld	a3,0(s7)
ffffffffc02061a2:	00007597          	auipc	a1,0x7
ffffffffc02061a6:	e6e5b583          	ld	a1,-402(a1) # ffffffffc020d010 <t_case>
ffffffffc02061aa:	00003617          	auipc	a2,0x3
ffffffffc02061ae:	26e60613          	addi	a2,a2,622 # ffffffffc0209418 <etext+0x219c>
ffffffffc02061b2:	00003517          	auipc	a0,0x3
ffffffffc02061b6:	c4650513          	addi	a0,a0,-954 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc02061ba:	00021317          	auipc	t1,0x21
ffffffffc02061be:	6bb32523          	sw	s11,1706(t1) # ffffffffc0227864 <t_case_failed>
ffffffffc02061c2:	f8ff90ef          	jal	ffffffffc0200150 <cprintf>
            if (i == ORD_K / 2) {
ffffffffc02061c6:	fb2c1ce3          	bne	s8,s2,ffffffffc020617e <case_free_orders+0x198>
ffffffffc02061ca:	02800c13          	li	s8,40
                for (j = 0; j < ORD_REFILL; j++) t_alloc(512);
ffffffffc02061ce:	20000513          	li	a0,512
ffffffffc02061d2:	3c7d                	addiw	s8,s8,-1
ffffffffc02061d4:	c31fe0ef          	jal	ffffffffc0204e04 <t_alloc>
ffffffffc02061d8:	fe0c1be3          	bnez	s8,ffffffffc02061ce <case_free_orders+0x1e8>
                t_verify_all();
ffffffffc02061dc:	95dfe0ef          	jal	ffffffffc0204b38 <t_verify_all>
        for (i = 0; i < ORD_K; i++) {
ffffffffc02061e0:	0411                	addi	s0,s0,4
ffffffffc02061e2:	06500c13          	li	s8,101
ffffffffc02061e6:	b745                	j	ffffffffc0206186 <case_free_orders+0x1a0>
ffffffffc02061e8:	00019717          	auipc	a4,0x19
ffffffffc02061ec:	17870713          	addi	a4,a4,376 # ffffffffc021f360 <order.3>
            for (i = 0; i < ORD_K; i++) order[i] = i;
ffffffffc02061f0:	4781                	li	a5,0
ffffffffc02061f2:	0c800693          	li	a3,200
ffffffffc02061f6:	c31c                	sw	a5,0(a4)
ffffffffc02061f8:	2785                	addiw	a5,a5,1
ffffffffc02061fa:	0711                	addi	a4,a4,4
ffffffffc02061fc:	fed79de3          	bne	a5,a3,ffffffffc02061f6 <case_free_orders+0x210>
ffffffffc0206200:	b71d                	j	ffffffffc0206126 <case_free_orders+0x140>
        t_verify_all(); /* 同尺寸类释放后剩余对象仍完好 */
ffffffffc0206202:	937fe0ef          	jal	ffffffffc0204b38 <t_verify_all>
    while (t_n != 0) t_free_at(t_n - 1);
ffffffffc0206206:	00021517          	auipc	a0,0x21
ffffffffc020620a:	64252503          	lw	a0,1602(a0) # ffffffffc0227848 <t_n>
ffffffffc020620e:	c909                	beqz	a0,ffffffffc0206220 <case_free_orders+0x23a>
ffffffffc0206210:	357d                	addiw	a0,a0,-1
ffffffffc0206212:	e81fe0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc0206216:	00021517          	auipc	a0,0x21
ffffffffc020621a:	63252503          	lw	a0,1586(a0) # ffffffffc0227848 <t_n>
ffffffffc020621e:	f96d                	bnez	a0,ffffffffc0206210 <case_free_orders+0x22a>
    for (ord = 0; ord < 4; ord++) {
ffffffffc0206220:	67a2                	ld	a5,8(sp)
ffffffffc0206222:	74a6                	ld	s1,104(sp)
ffffffffc0206224:	7c42                	ld	s8,48(sp)
ffffffffc0206226:	0017871b          	addiw	a4,a5,1
ffffffffc020622a:	e43a                	sd	a4,8(sp)
ffffffffc020622c:	4791                	li	a5,4
ffffffffc020622e:	7ca2                	ld	s9,40(sp)
ffffffffc0206230:	7d02                	ld	s10,32(sp)
ffffffffc0206232:	6de2                	ld	s11,24(sp)
ffffffffc0206234:	e4f707e3          	beq	a4,a5,ffffffffc0206082 <case_free_orders+0x9c>
ffffffffc0206238:	b3ed                	j	ffffffffc0206022 <case_free_orders+0x3c>
ffffffffc020623a:	00019797          	auipc	a5,0x19
ffffffffc020623e:	2b678793          	addi	a5,a5,694 # ffffffffc021f4f0 <order.3+0x190>
        switch (ord) {
ffffffffc0206242:	00019717          	auipc	a4,0x19
ffffffffc0206246:	11e70713          	addi	a4,a4,286 # ffffffffc021f360 <order.3>
ffffffffc020624a:	4681                	li	a3,0
            for (i = 0; i < ORD_K / 2; i++) order[i] = 2 * i;
ffffffffc020624c:	c314                	sw	a3,0(a4)
ffffffffc020624e:	0711                	addi	a4,a4,4
ffffffffc0206250:	2689                	addiw	a3,a3,2
ffffffffc0206252:	fef71de3          	bne	a4,a5,ffffffffc020624c <case_free_orders+0x266>
ffffffffc0206256:	00019697          	auipc	a3,0x19
ffffffffc020625a:	42a68693          	addi	a3,a3,1066 # ffffffffc021f680 <ids.4>
ffffffffc020625e:	4705                	li	a4,1
            for (i = ORD_K / 2; i < ORD_K; i++) order[i] = 2 * (i - ORD_K / 2) + 1;
ffffffffc0206260:	c398                	sw	a4,0(a5)
ffffffffc0206262:	0791                	addi	a5,a5,4
ffffffffc0206264:	2709                	addiw	a4,a4,2
ffffffffc0206266:	fed79de3          	bne	a5,a3,ffffffffc0206260 <case_free_orders+0x27a>
ffffffffc020626a:	bd75                	j	ffffffffc0206126 <case_free_orders+0x140>
ffffffffc020626c:	00019717          	auipc	a4,0x19
ffffffffc0206270:	0f470713          	addi	a4,a4,244 # ffffffffc021f360 <order.3>
        switch (ord) {
ffffffffc0206274:	0c700793          	li	a5,199
            for (i = 0; i < ORD_K; i++) order[i] = ORD_K - 1 - i;
ffffffffc0206278:	56fd                	li	a3,-1
ffffffffc020627a:	c31c                	sw	a5,0(a4)
ffffffffc020627c:	37fd                	addiw	a5,a5,-1
ffffffffc020627e:	0711                	addi	a4,a4,4
ffffffffc0206280:	fed79de3          	bne	a5,a3,ffffffffc020627a <case_free_orders+0x294>
ffffffffc0206284:	b54d                	j	ffffffffc0206126 <case_free_orders+0x140>

ffffffffc0206286 <case_shrink_live>:
static void case_shrink_live(void) {
ffffffffc0206286:	1101                	addi	sp,sp,-32
ffffffffc0206288:	ec06                	sd	ra,24(sp)
ffffffffc020628a:	e822                	sd	s0,16(sp)
ffffffffc020628c:	e426                	sd	s1,8(sp)
ffffffffc020628e:	e04a                	sd	s2,0(sp)
    slub_shrink();
ffffffffc0206290:	e29fd0ef          	jal	ffffffffc02040b8 <slub_shrink>
    return nr_free_pages();
ffffffffc0206294:	e32fc0ef          	jal	ffffffffc02028c6 <nr_free_pages>
    t_baseline = slub_port_nr_free_pages();
ffffffffc0206298:	00021917          	auipc	s2,0x21
ffffffffc020629c:	5a090913          	addi	s2,s2,1440 # ffffffffc0227838 <t_baseline>
ffffffffc02062a0:	00a93023          	sd	a0,0(s2)
ffffffffc02062a4:	07800413          	li	s0,120
        t_iters++;
ffffffffc02062a8:	00021497          	auipc	s1,0x21
ffffffffc02062ac:	5c048493          	addi	s1,s1,1472 # ffffffffc0227868 <t_iters>
ffffffffc02062b0:	a029                	j	ffffffffc02062ba <case_shrink_live+0x34>
ffffffffc02062b2:	609c                	ld	a5,0(s1)
ffffffffc02062b4:	0785                	addi	a5,a5,1
ffffffffc02062b6:	e09c                	sd	a5,0(s1)
    for (k = 0; k < 120; k++) {
ffffffffc02062b8:	cc09                	beqz	s0,ffffffffc02062d2 <case_shrink_live+0x4c>
        if (t_alloc(64) == NULL) return;
ffffffffc02062ba:	04000513          	li	a0,64
ffffffffc02062be:	b47fe0ef          	jal	ffffffffc0204e04 <t_alloc>
    for (k = 0; k < 120; k++) {
ffffffffc02062c2:	347d                	addiw	s0,s0,-1
        if (t_alloc(64) == NULL) return;
ffffffffc02062c4:	f57d                	bnez	a0,ffffffffc02062b2 <case_shrink_live+0x2c>
}
ffffffffc02062c6:	60e2                	ld	ra,24(sp)
ffffffffc02062c8:	6442                	ld	s0,16(sp)
ffffffffc02062ca:	64a2                	ld	s1,8(sp)
ffffffffc02062cc:	6902                	ld	s2,0(sp)
ffffffffc02062ce:	6105                	addi	sp,sp,32
ffffffffc02062d0:	8082                	ret
    for (k = t_n; k > 0; k -= 3) t_free_at(k - 1);
ffffffffc02062d2:	00021417          	auipc	s0,0x21
ffffffffc02062d6:	57642403          	lw	s0,1398(s0) # ffffffffc0227848 <t_n>
ffffffffc02062da:	c419                	beqz	s0,ffffffffc02062e8 <case_shrink_live+0x62>
ffffffffc02062dc:	fff4051b          	addiw	a0,s0,-1
ffffffffc02062e0:	3475                	addiw	s0,s0,-3
ffffffffc02062e2:	db1fe0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc02062e6:	f87d                	bnez	s0,ffffffffc02062dc <case_shrink_live+0x56>
    slub_shrink();
ffffffffc02062e8:	dd1fd0ef          	jal	ffffffffc02040b8 <slub_shrink>
    if (t_n == 0) {
ffffffffc02062ec:	00021797          	auipc	a5,0x21
ffffffffc02062f0:	55c7a783          	lw	a5,1372(a5) # ffffffffc0227848 <t_n>
ffffffffc02062f4:	12078063          	beqz	a5,ffffffffc0206414 <case_shrink_live+0x18e>
    if (slub_user_objects() != t_n) {
ffffffffc02062f8:	828fe0ef          	jal	ffffffffc0204320 <slub_user_objects>
ffffffffc02062fc:	00021797          	auipc	a5,0x21
ffffffffc0206300:	54c7e783          	lwu	a5,1356(a5) # ffffffffc0227848 <t_n>
ffffffffc0206304:	04f50f63          	beq	a0,a5,ffffffffc0206362 <case_shrink_live+0xdc>
                         (unsigned long)slub_user_objects(), t_n);
ffffffffc0206308:	818fe0ef          	jal	ffffffffc0204320 <slub_user_objects>
        slub_port_printf("  detail: user_objects=%lu live=%u\n",
ffffffffc020630c:	00021617          	auipc	a2,0x21
ffffffffc0206310:	53c62603          	lw	a2,1340(a2) # ffffffffc0227848 <t_n>
                         (unsigned long)slub_user_objects(), t_n);
ffffffffc0206314:	85aa                	mv	a1,a0
        slub_port_printf("  detail: user_objects=%lu live=%u\n",
ffffffffc0206316:	00003517          	auipc	a0,0x3
ffffffffc020631a:	15250513          	addi	a0,a0,338 # ffffffffc0209468 <etext+0x21ec>
ffffffffc020631e:	e33f90ef          	jal	ffffffffc0200150 <cprintf>
        TFAIL("user object count changed across shrink");
ffffffffc0206322:	4605                	li	a2,1
ffffffffc0206324:	6098                	ld	a4,0(s1)
ffffffffc0206326:	00021817          	auipc	a6,0x21
ffffffffc020632a:	53283803          	ld	a6,1330(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc020632e:	00007797          	auipc	a5,0x7
ffffffffc0206332:	cd27a783          	lw	a5,-814(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0206336:	00021697          	auipc	a3,0x21
ffffffffc020633a:	53a6b683          	ld	a3,1338(a3) # ffffffffc0227870 <t_size>
ffffffffc020633e:	00007597          	auipc	a1,0x7
ffffffffc0206342:	cd25b583          	ld	a1,-814(a1) # ffffffffc020d010 <t_case>
ffffffffc0206346:	00021517          	auipc	a0,0x21
ffffffffc020634a:	50c52f23          	sw	a2,1310(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc020634e:	00003517          	auipc	a0,0x3
ffffffffc0206352:	aaa50513          	addi	a0,a0,-1366 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0206356:	00003617          	auipc	a2,0x3
ffffffffc020635a:	13a60613          	addi	a2,a2,314 # ffffffffc0209490 <etext+0x2214>
ffffffffc020635e:	df3f90ef          	jal	ffffffffc0200150 <cprintf>
    if (slub_slab_pages() == 0) TFAIL("pages of live objects were reclaimed");
ffffffffc0206362:	83efe0ef          	jal	ffffffffc02043a0 <slub_slab_pages>
ffffffffc0206366:	0e050c63          	beqz	a0,ffffffffc020645e <case_shrink_live+0x1d8>
ffffffffc020636a:	d5cfc0ef          	jal	ffffffffc02028c6 <nr_free_pages>
ffffffffc020636e:	842a                	mv	s0,a0
    if (slub_port_nr_free_pages() + slub_slab_pages() != t_baseline) {
ffffffffc0206370:	830fe0ef          	jal	ffffffffc02043a0 <slub_slab_pages>
ffffffffc0206374:	00093783          	ld	a5,0(s2)
ffffffffc0206378:	942a                	add	s0,s0,a0
ffffffffc020637a:	06f40163          	beq	s0,a5,ffffffffc02063dc <case_shrink_live+0x156>
ffffffffc020637e:	d48fc0ef          	jal	ffffffffc02028c6 <nr_free_pages>
ffffffffc0206382:	842a                	mv	s0,a0
                         (unsigned long)slub_slab_pages(),
ffffffffc0206384:	81cfe0ef          	jal	ffffffffc02043a0 <slub_slab_pages>
        slub_port_printf("  detail: free=%lu held=%lu baseline=%lu\n",
ffffffffc0206388:	00093683          	ld	a3,0(s2)
                         (unsigned long)slub_slab_pages(),
ffffffffc020638c:	862a                	mv	a2,a0
        slub_port_printf("  detail: free=%lu held=%lu baseline=%lu\n",
ffffffffc020638e:	85a2                	mv	a1,s0
ffffffffc0206390:	00003517          	auipc	a0,0x3
ffffffffc0206394:	15050513          	addi	a0,a0,336 # ffffffffc02094e0 <etext+0x2264>
ffffffffc0206398:	db9f90ef          	jal	ffffffffc0200150 <cprintf>
        TFAIL("free+held pages must equal baseline exactly");
ffffffffc020639c:	4605                	li	a2,1
ffffffffc020639e:	6098                	ld	a4,0(s1)
ffffffffc02063a0:	00021817          	auipc	a6,0x21
ffffffffc02063a4:	4b883803          	ld	a6,1208(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc02063a8:	00007797          	auipc	a5,0x7
ffffffffc02063ac:	c587a783          	lw	a5,-936(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc02063b0:	00021697          	auipc	a3,0x21
ffffffffc02063b4:	4c06b683          	ld	a3,1216(a3) # ffffffffc0227870 <t_size>
ffffffffc02063b8:	00007597          	auipc	a1,0x7
ffffffffc02063bc:	c585b583          	ld	a1,-936(a1) # ffffffffc020d010 <t_case>
ffffffffc02063c0:	00021517          	auipc	a0,0x21
ffffffffc02063c4:	4ac52223          	sw	a2,1188(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc02063c8:	00003517          	auipc	a0,0x3
ffffffffc02063cc:	a3050513          	addi	a0,a0,-1488 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc02063d0:	00003617          	auipc	a2,0x3
ffffffffc02063d4:	14060613          	addi	a2,a2,320 # ffffffffc0209510 <etext+0x2294>
ffffffffc02063d8:	d79f90ef          	jal	ffffffffc0200150 <cprintf>
    t_verify_all(); /* shrink 后存活对象内容仍正确 */
ffffffffc02063dc:	f5cfe0ef          	jal	ffffffffc0204b38 <t_verify_all>
    while (t_n != 0) t_free_at(t_n - 1);
ffffffffc02063e0:	00021517          	auipc	a0,0x21
ffffffffc02063e4:	46852503          	lw	a0,1128(a0) # ffffffffc0227848 <t_n>
ffffffffc02063e8:	c909                	beqz	a0,ffffffffc02063fa <case_shrink_live+0x174>
ffffffffc02063ea:	357d                	addiw	a0,a0,-1
ffffffffc02063ec:	ca7fe0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc02063f0:	00021517          	auipc	a0,0x21
ffffffffc02063f4:	45852503          	lw	a0,1112(a0) # ffffffffc0227848 <t_n>
ffffffffc02063f8:	f96d                	bnez	a0,ffffffffc02063ea <case_shrink_live+0x164>
    slub_shrink();
ffffffffc02063fa:	cbffd0ef          	jal	ffffffffc02040b8 <slub_shrink>
}
ffffffffc02063fe:	6442                	ld	s0,16(sp)
ffffffffc0206400:	60e2                	ld	ra,24(sp)
ffffffffc0206402:	64a2                	ld	s1,8(sp)
ffffffffc0206404:	6902                	ld	s2,0(sp)
    t_expect_baseline("not restored after freeing the held objects");
ffffffffc0206406:	00003517          	auipc	a0,0x3
ffffffffc020640a:	13a50513          	addi	a0,a0,314 # ffffffffc0209540 <etext+0x22c4>
}
ffffffffc020640e:	6105                	addi	sp,sp,32
    t_expect_baseline("not restored after freeing the held objects");
ffffffffc0206410:	d13fe06f          	j	ffffffffc0205122 <t_expect_baseline>
}
ffffffffc0206414:	6442                	ld	s0,16(sp)
        TFAIL("all objects unexpectedly gone");
ffffffffc0206416:	6098                	ld	a4,0(s1)
}
ffffffffc0206418:	60e2                	ld	ra,24(sp)
ffffffffc020641a:	64a2                	ld	s1,8(sp)
ffffffffc020641c:	6902                	ld	s2,0(sp)
        TFAIL("all objects unexpectedly gone");
ffffffffc020641e:	4605                	li	a2,1
ffffffffc0206420:	00021817          	auipc	a6,0x21
ffffffffc0206424:	43883803          	ld	a6,1080(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0206428:	00007797          	auipc	a5,0x7
ffffffffc020642c:	bd87a783          	lw	a5,-1064(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0206430:	00021697          	auipc	a3,0x21
ffffffffc0206434:	4406b683          	ld	a3,1088(a3) # ffffffffc0227870 <t_size>
ffffffffc0206438:	00007597          	auipc	a1,0x7
ffffffffc020643c:	bd85b583          	ld	a1,-1064(a1) # ffffffffc020d010 <t_case>
ffffffffc0206440:	00021517          	auipc	a0,0x21
ffffffffc0206444:	42c52223          	sw	a2,1060(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0206448:	00003617          	auipc	a2,0x3
ffffffffc020644c:	00060613          	mv	a2,a2
ffffffffc0206450:	00003517          	auipc	a0,0x3
ffffffffc0206454:	9a850513          	addi	a0,a0,-1624 # ffffffffc0208df8 <etext+0x1b7c>
}
ffffffffc0206458:	6105                	addi	sp,sp,32
        TFAIL("all objects unexpectedly gone");
ffffffffc020645a:	cf7f906f          	j	ffffffffc0200150 <cprintf>
    if (slub_slab_pages() == 0) TFAIL("pages of live objects were reclaimed");
ffffffffc020645e:	4605                	li	a2,1
ffffffffc0206460:	00021817          	auipc	a6,0x21
ffffffffc0206464:	3f883803          	ld	a6,1016(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0206468:	00007797          	auipc	a5,0x7
ffffffffc020646c:	b987a783          	lw	a5,-1128(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0206470:	6098                	ld	a4,0(s1)
ffffffffc0206472:	00021697          	auipc	a3,0x21
ffffffffc0206476:	3fe6b683          	ld	a3,1022(a3) # ffffffffc0227870 <t_size>
ffffffffc020647a:	00007597          	auipc	a1,0x7
ffffffffc020647e:	b965b583          	ld	a1,-1130(a1) # ffffffffc020d010 <t_case>
ffffffffc0206482:	00021517          	auipc	a0,0x21
ffffffffc0206486:	3ec52123          	sw	a2,994(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc020648a:	00003517          	auipc	a0,0x3
ffffffffc020648e:	96e50513          	addi	a0,a0,-1682 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0206492:	00003617          	auipc	a2,0x3
ffffffffc0206496:	02660613          	addi	a2,a2,38 # ffffffffc02094b8 <etext+0x223c>
ffffffffc020649a:	cb7f90ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc020649e:	b5f1                	j	ffffffffc020636a <case_shrink_live+0xe4>

ffffffffc02064a0 <case_fault_inject.part.0>:
static void case_fault_inject(void) {
ffffffffc02064a0:	7145                	addi	sp,sp,-464
ffffffffc02064a2:	e786                	sd	ra,456(sp)
ffffffffc02064a4:	e3a2                	sd	s0,448(sp)
ffffffffc02064a6:	ff26                	sd	s1,440(sp)
ffffffffc02064a8:	f74e                	sd	s3,424(sp)
ffffffffc02064aa:	f352                	sd	s4,416(sp)
ffffffffc02064ac:	fb4a                	sd	s2,432(sp)
ffffffffc02064ae:	ef56                	sd	s5,408(sp)
ffffffffc02064b0:	eb5a                	sd	s6,400(sp)
ffffffffc02064b2:	e75e                	sd	s7,392(sp)
ffffffffc02064b4:	e362                	sd	s8,384(sp)
ffffffffc02064b6:	fee6                	sd	s9,376(sp)
    slub_shrink();
ffffffffc02064b8:	c01fd0ef          	jal	ffffffffc02040b8 <slub_shrink>
ffffffffc02064bc:	c0afc0ef          	jal	ffffffffc02028c6 <nr_free_pages>
ffffffffc02064c0:	8a2a                	mv	s4,a0
    hits0 = slub_fault_hits();
ffffffffc02064c2:	810fe0ef          	jal	ffffffffc02044d2 <slub_fault_hits>
    slub_get_class_info(0, &i0);
ffffffffc02064c6:	858a                	mv	a1,sp
    hits0 = slub_fault_hits();
ffffffffc02064c8:	89aa                	mv	s3,a0
    slub_get_class_info(0, &i0);
ffffffffc02064ca:	4501                	li	a0,0
ffffffffc02064cc:	c47fd0ef          	jal	ffffffffc0204112 <slub_get_class_info>
    slub_fault_inject(1);
ffffffffc02064d0:	4505                	li	a0,1
ffffffffc02064d2:	f75fd0ef          	jal	ffffffffc0204446 <slub_fault_inject>
    t_iters++;
ffffffffc02064d6:	00021417          	auipc	s0,0x21
ffffffffc02064da:	39240413          	addi	s0,s0,914 # ffffffffc0227868 <t_iters>
ffffffffc02064de:	601c                	ld	a5,0(s0)
    t_size = 16;
ffffffffc02064e0:	4541                	li	a0,16
ffffffffc02064e2:	00021497          	auipc	s1,0x21
ffffffffc02064e6:	38e48493          	addi	s1,s1,910 # ffffffffc0227870 <t_size>
    t_iters++;
ffffffffc02064ea:	0785                	addi	a5,a5,1
ffffffffc02064ec:	e01c                	sd	a5,0(s0)
    t_size = 16;
ffffffffc02064ee:	e088                	sd	a0,0(s1)
    if (kmalloc(16) != NULL) TFAIL("allocation must fail under injected fault");
ffffffffc02064f0:	facfd0ef          	jal	ffffffffc0203c9c <kmalloc>
ffffffffc02064f4:	cd15                	beqz	a0,ffffffffc0206530 <case_fault_inject.part.0+0x90>
ffffffffc02064f6:	4605                	li	a2,1
ffffffffc02064f8:	00021817          	auipc	a6,0x21
ffffffffc02064fc:	36083803          	ld	a6,864(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0206500:	00007797          	auipc	a5,0x7
ffffffffc0206504:	b007a783          	lw	a5,-1280(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0206508:	6018                	ld	a4,0(s0)
ffffffffc020650a:	6094                	ld	a3,0(s1)
ffffffffc020650c:	00007597          	auipc	a1,0x7
ffffffffc0206510:	b045b583          	ld	a1,-1276(a1) # ffffffffc020d010 <t_case>
ffffffffc0206514:	00021517          	auipc	a0,0x21
ffffffffc0206518:	34c52823          	sw	a2,848(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc020651c:	00003517          	auipc	a0,0x3
ffffffffc0206520:	8dc50513          	addi	a0,a0,-1828 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0206524:	00003617          	auipc	a2,0x3
ffffffffc0206528:	04c60613          	addi	a2,a2,76 # ffffffffc0209570 <etext+0x22f4>
ffffffffc020652c:	c25f90ef          	jal	ffffffffc0200150 <cprintf>
    slub_get_class_info(0, &i1);
ffffffffc0206530:	192c                	addi	a1,sp,184
ffffffffc0206532:	4501                	li	a0,0
ffffffffc0206534:	bdffd0ef          	jal	ffffffffc0204112 <slub_get_class_info>
    if (i1.slab_fail == i0.slab_fail) TFAIL("slab failure not recorded");
ffffffffc0206538:	7736                	ld	a4,360(sp)
ffffffffc020653a:	77ca                	ld	a5,176(sp)
ffffffffc020653c:	28f70363          	beq	a4,a5,ffffffffc02067c2 <case_fault_inject.part.0+0x322>
    if (slub_fault_hits() != hits0 + 1) TFAIL("fault injection not hit");
ffffffffc0206540:	f93fd0ef          	jal	ffffffffc02044d2 <slub_fault_hits>
ffffffffc0206544:	00198793          	addi	a5,s3,1
ffffffffc0206548:	02f50f63          	beq	a0,a5,ffffffffc0206586 <case_fault_inject.part.0+0xe6>
ffffffffc020654c:	4605                	li	a2,1
ffffffffc020654e:	00021817          	auipc	a6,0x21
ffffffffc0206552:	30a83803          	ld	a6,778(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0206556:	00007797          	auipc	a5,0x7
ffffffffc020655a:	aaa7a783          	lw	a5,-1366(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc020655e:	6018                	ld	a4,0(s0)
ffffffffc0206560:	6094                	ld	a3,0(s1)
ffffffffc0206562:	00007597          	auipc	a1,0x7
ffffffffc0206566:	aae5b583          	ld	a1,-1362(a1) # ffffffffc020d010 <t_case>
ffffffffc020656a:	00021517          	auipc	a0,0x21
ffffffffc020656e:	2ec52d23          	sw	a2,762(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0206572:	00003517          	auipc	a0,0x3
ffffffffc0206576:	88650513          	addi	a0,a0,-1914 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc020657a:	00003617          	auipc	a2,0x3
ffffffffc020657e:	04660613          	addi	a2,a2,70 # ffffffffc02095c0 <etext+0x2344>
ffffffffc0206582:	bcff90ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc0206586:	b40fc0ef          	jal	ffffffffc02028c6 <nr_free_pages>
    if (slub_port_nr_free_pages() != bf)
ffffffffc020658a:	02aa0f63          	beq	s4,a0,ffffffffc02065c8 <case_fault_inject.part.0+0x128>
        TFAIL("failed slab creation leaked pages");
ffffffffc020658e:	4605                	li	a2,1
ffffffffc0206590:	00021817          	auipc	a6,0x21
ffffffffc0206594:	2c883803          	ld	a6,712(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0206598:	00007797          	auipc	a5,0x7
ffffffffc020659c:	a687a783          	lw	a5,-1432(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc02065a0:	6018                	ld	a4,0(s0)
ffffffffc02065a2:	6094                	ld	a3,0(s1)
ffffffffc02065a4:	00007597          	auipc	a1,0x7
ffffffffc02065a8:	a6c5b583          	ld	a1,-1428(a1) # ffffffffc020d010 <t_case>
ffffffffc02065ac:	00021517          	auipc	a0,0x21
ffffffffc02065b0:	2ac52c23          	sw	a2,696(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc02065b4:	00003517          	auipc	a0,0x3
ffffffffc02065b8:	84450513          	addi	a0,a0,-1980 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc02065bc:	00003617          	auipc	a2,0x3
ffffffffc02065c0:	01c60613          	addi	a2,a2,28 # ffffffffc02095d8 <etext+0x235c>
ffffffffc02065c4:	b8df90ef          	jal	ffffffffc0200150 <cprintf>
    slub_fault_inject(1);
ffffffffc02065c8:	4505                	li	a0,1
ffffffffc02065ca:	e7dfd0ef          	jal	ffffffffc0204446 <slub_fault_inject>
    t_iters++;
ffffffffc02065ce:	601c                	ld	a5,0(s0)
    t_size = 8192;
ffffffffc02065d0:	6509                	lui	a0,0x2
ffffffffc02065d2:	e088                	sd	a0,0(s1)
    t_iters++;
ffffffffc02065d4:	0785                	addi	a5,a5,1
ffffffffc02065d6:	e01c                	sd	a5,0(s0)
    if (kmalloc(8192) != NULL)
ffffffffc02065d8:	ec4fd0ef          	jal	ffffffffc0203c9c <kmalloc>
ffffffffc02065dc:	cd15                	beqz	a0,ffffffffc0206618 <case_fault_inject.part.0+0x178>
        TFAIL("large allocation must fail under injected fault");
ffffffffc02065de:	4605                	li	a2,1
ffffffffc02065e0:	00021817          	auipc	a6,0x21
ffffffffc02065e4:	27883803          	ld	a6,632(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc02065e8:	00007797          	auipc	a5,0x7
ffffffffc02065ec:	a187a783          	lw	a5,-1512(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc02065f0:	6018                	ld	a4,0(s0)
ffffffffc02065f2:	6094                	ld	a3,0(s1)
ffffffffc02065f4:	00007597          	auipc	a1,0x7
ffffffffc02065f8:	a1c5b583          	ld	a1,-1508(a1) # ffffffffc020d010 <t_case>
ffffffffc02065fc:	00021517          	auipc	a0,0x21
ffffffffc0206600:	26c52423          	sw	a2,616(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0206604:	00002517          	auipc	a0,0x2
ffffffffc0206608:	7f450513          	addi	a0,a0,2036 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc020660c:	00003617          	auipc	a2,0x3
ffffffffc0206610:	ff460613          	addi	a2,a2,-12 # ffffffffc0209600 <etext+0x2384>
ffffffffc0206614:	b3df90ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc0206618:	aaefc0ef          	jal	ffffffffc02028c6 <nr_free_pages>
    if (slub_port_nr_free_pages() != bf)
ffffffffc020661c:	02aa0f63          	beq	s4,a0,ffffffffc020665a <case_fault_inject.part.0+0x1ba>
        TFAIL("failed large allocation leaked pages");
ffffffffc0206620:	4605                	li	a2,1
ffffffffc0206622:	00021817          	auipc	a6,0x21
ffffffffc0206626:	23683803          	ld	a6,566(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc020662a:	00007797          	auipc	a5,0x7
ffffffffc020662e:	9d67a783          	lw	a5,-1578(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0206632:	6018                	ld	a4,0(s0)
ffffffffc0206634:	6094                	ld	a3,0(s1)
ffffffffc0206636:	00007597          	auipc	a1,0x7
ffffffffc020663a:	9da5b583          	ld	a1,-1574(a1) # ffffffffc020d010 <t_case>
ffffffffc020663e:	00021517          	auipc	a0,0x21
ffffffffc0206642:	22c52323          	sw	a2,550(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0206646:	00002517          	auipc	a0,0x2
ffffffffc020664a:	7b250513          	addi	a0,a0,1970 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc020664e:	00003617          	auipc	a2,0x3
ffffffffc0206652:	fe260613          	addi	a2,a2,-30 # ffffffffc0209630 <etext+0x23b4>
ffffffffc0206656:	afbf90ef          	jal	ffffffffc0200150 <cprintf>
    slub_fault_inject(3);
ffffffffc020665a:	450d                	li	a0,3
ffffffffc020665c:	debfd0ef          	jal	ffffffffc0204446 <slub_fault_inject>
ffffffffc0206660:	490d                	li	s2,3
        t_size = 64;
ffffffffc0206662:	04000a93          	li	s5,64
        if (kmalloc(64) != NULL) TFAIL("allocation must fail under fault");
ffffffffc0206666:	4c85                	li	s9,1
ffffffffc0206668:	00021c17          	auipc	s8,0x21
ffffffffc020666c:	1f0c0c13          	addi	s8,s8,496 # ffffffffc0227858 <t_seed_cfg>
    return (unsigned int)boot_hartid;
ffffffffc0206670:	00007b97          	auipc	s7,0x7
ffffffffc0206674:	990b8b93          	addi	s7,s7,-1648 # ffffffffc020d000 <boot_hartid>
ffffffffc0206678:	00007b17          	auipc	s6,0x7
ffffffffc020667c:	998b0b13          	addi	s6,s6,-1640 # ffffffffc020d010 <t_case>
        t_iters++;
ffffffffc0206680:	601c                	ld	a5,0(s0)
        if (kmalloc(64) != NULL) TFAIL("allocation must fail under fault");
ffffffffc0206682:	04000513          	li	a0,64
        t_size = 64;
ffffffffc0206686:	0154b023          	sd	s5,0(s1)
        t_iters++;
ffffffffc020668a:	0785                	addi	a5,a5,1
ffffffffc020668c:	e01c                	sd	a5,0(s0)
        if (kmalloc(64) != NULL) TFAIL("allocation must fail under fault");
ffffffffc020668e:	e0efd0ef          	jal	ffffffffc0203c9c <kmalloc>
ffffffffc0206692:	87aa                	mv	a5,a0
ffffffffc0206694:	00003617          	auipc	a2,0x3
ffffffffc0206698:	fc460613          	addi	a2,a2,-60 # ffffffffc0209658 <etext+0x23dc>
ffffffffc020669c:	00002517          	auipc	a0,0x2
ffffffffc02066a0:	75c50513          	addi	a0,a0,1884 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc02066a4:	cf99                	beqz	a5,ffffffffc02066c2 <case_fault_inject.part.0+0x222>
ffffffffc02066a6:	000c3803          	ld	a6,0(s8)
ffffffffc02066aa:	000ba783          	lw	a5,0(s7)
ffffffffc02066ae:	6018                	ld	a4,0(s0)
ffffffffc02066b0:	6094                	ld	a3,0(s1)
ffffffffc02066b2:	000b3583          	ld	a1,0(s6)
ffffffffc02066b6:	00021897          	auipc	a7,0x21
ffffffffc02066ba:	1b98a723          	sw	s9,430(a7) # ffffffffc0227864 <t_case_failed>
ffffffffc02066be:	a93f90ef          	jal	ffffffffc0200150 <cprintf>
    for (i = 0; i < 3; i++) {
ffffffffc02066c2:	397d                	addiw	s2,s2,-1
ffffffffc02066c4:	fa091ee3          	bnez	s2,ffffffffc0206680 <case_fault_inject.part.0+0x1e0>
    if (slub_fault_hits() != hits0 + 5) TFAIL("fault hit count mismatch");
ffffffffc02066c8:	e0bfd0ef          	jal	ffffffffc02044d2 <slub_fault_hits>
ffffffffc02066cc:	0995                	addi	s3,s3,5
ffffffffc02066ce:	03350f63          	beq	a0,s3,ffffffffc020670c <case_fault_inject.part.0+0x26c>
ffffffffc02066d2:	4605                	li	a2,1
ffffffffc02066d4:	00021817          	auipc	a6,0x21
ffffffffc02066d8:	18483803          	ld	a6,388(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc02066dc:	00007797          	auipc	a5,0x7
ffffffffc02066e0:	9247a783          	lw	a5,-1756(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc02066e4:	6018                	ld	a4,0(s0)
ffffffffc02066e6:	6094                	ld	a3,0(s1)
ffffffffc02066e8:	00007597          	auipc	a1,0x7
ffffffffc02066ec:	9285b583          	ld	a1,-1752(a1) # ffffffffc020d010 <t_case>
ffffffffc02066f0:	00021517          	auipc	a0,0x21
ffffffffc02066f4:	16c52a23          	sw	a2,372(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc02066f8:	00002517          	auipc	a0,0x2
ffffffffc02066fc:	70050513          	addi	a0,a0,1792 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0206700:	00003617          	auipc	a2,0x3
ffffffffc0206704:	f8060613          	addi	a2,a2,-128 # ffffffffc0209680 <etext+0x2404>
ffffffffc0206708:	a49f90ef          	jal	ffffffffc0200150 <cprintf>
    return nr_free_pages();
ffffffffc020670c:	9bafc0ef          	jal	ffffffffc02028c6 <nr_free_pages>
    if (slub_port_nr_free_pages() != bf) TFAIL("fault path leaked pages");
ffffffffc0206710:	02aa0f63          	beq	s4,a0,ffffffffc020674e <case_fault_inject.part.0+0x2ae>
ffffffffc0206714:	4605                	li	a2,1
ffffffffc0206716:	6018                	ld	a4,0(s0)
ffffffffc0206718:	6094                	ld	a3,0(s1)
ffffffffc020671a:	00021817          	auipc	a6,0x21
ffffffffc020671e:	13e83803          	ld	a6,318(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0206722:	00007797          	auipc	a5,0x7
ffffffffc0206726:	8de7a783          	lw	a5,-1826(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc020672a:	00007597          	auipc	a1,0x7
ffffffffc020672e:	8e65b583          	ld	a1,-1818(a1) # ffffffffc020d010 <t_case>
ffffffffc0206732:	00021517          	auipc	a0,0x21
ffffffffc0206736:	12c52923          	sw	a2,306(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc020673a:	00002517          	auipc	a0,0x2
ffffffffc020673e:	6be50513          	addi	a0,a0,1726 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0206742:	00003617          	auipc	a2,0x3
ffffffffc0206746:	f5e60613          	addi	a2,a2,-162 # ffffffffc02096a0 <etext+0x2424>
ffffffffc020674a:	a07f90ef          	jal	ffffffffc0200150 <cprintf>
    t_verify_all(); /* 既有对象不受失败影响 */
ffffffffc020674e:	beafe0ef          	jal	ffffffffc0204b38 <t_verify_all>
    slub_fault_clear();
ffffffffc0206752:	d3bfd0ef          	jal	ffffffffc020448c <slub_fault_clear>
        struct tobj *a = t_alloc(16);
ffffffffc0206756:	4541                	li	a0,16
ffffffffc0206758:	eacfe0ef          	jal	ffffffffc0204e04 <t_alloc>
ffffffffc020675c:	842a                	mv	s0,a0
        struct tobj *b = t_alloc(64);
ffffffffc020675e:	04000513          	li	a0,64
ffffffffc0206762:	ea2fe0ef          	jal	ffffffffc0204e04 <t_alloc>
        if (a && b && c) t_verify_all();
ffffffffc0206766:	00a034b3          	snez	s1,a0
ffffffffc020676a:	00803433          	snez	s0,s0
        struct tobj *c = t_alloc(8192);
ffffffffc020676e:	6509                	lui	a0,0x2
        if (a && b && c) t_verify_all();
ffffffffc0206770:	8c65                	and	s0,s0,s1
        struct tobj *c = t_alloc(8192);
ffffffffc0206772:	e92fe0ef          	jal	ffffffffc0204e04 <t_alloc>
        if (a && b && c) t_verify_all();
ffffffffc0206776:	cc01                	beqz	s0,ffffffffc020678e <case_fault_inject.part.0+0x2ee>
ffffffffc0206778:	c919                	beqz	a0,ffffffffc020678e <case_fault_inject.part.0+0x2ee>
ffffffffc020677a:	bbefe0ef          	jal	ffffffffc0204b38 <t_verify_all>
    while (t_n != 0) t_free_at(t_n - 1);
ffffffffc020677e:	00021517          	auipc	a0,0x21
ffffffffc0206782:	0ca52503          	lw	a0,202(a0) # ffffffffc0227848 <t_n>
ffffffffc0206786:	c909                	beqz	a0,ffffffffc0206798 <case_fault_inject.part.0+0x2f8>
ffffffffc0206788:	357d                	addiw	a0,a0,-1
ffffffffc020678a:	909fe0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc020678e:	00021517          	auipc	a0,0x21
ffffffffc0206792:	0ba52503          	lw	a0,186(a0) # ffffffffc0227848 <t_n>
ffffffffc0206796:	f96d                	bnez	a0,ffffffffc0206788 <case_fault_inject.part.0+0x2e8>
    slub_shrink();
ffffffffc0206798:	921fd0ef          	jal	ffffffffc02040b8 <slub_shrink>
    t_expect_baseline("not restored after fault injection recovery");
ffffffffc020679c:	00003517          	auipc	a0,0x3
ffffffffc02067a0:	f1c50513          	addi	a0,a0,-228 # ffffffffc02096b8 <etext+0x243c>
ffffffffc02067a4:	97ffe0ef          	jal	ffffffffc0205122 <t_expect_baseline>
}
ffffffffc02067a8:	60be                	ld	ra,456(sp)
ffffffffc02067aa:	641e                	ld	s0,448(sp)
ffffffffc02067ac:	74fa                	ld	s1,440(sp)
ffffffffc02067ae:	795a                	ld	s2,432(sp)
ffffffffc02067b0:	79ba                	ld	s3,424(sp)
ffffffffc02067b2:	7a1a                	ld	s4,416(sp)
ffffffffc02067b4:	6afa                	ld	s5,408(sp)
ffffffffc02067b6:	6b5a                	ld	s6,400(sp)
ffffffffc02067b8:	6bba                	ld	s7,392(sp)
ffffffffc02067ba:	6c1a                	ld	s8,384(sp)
ffffffffc02067bc:	7cf6                	ld	s9,376(sp)
ffffffffc02067be:	6179                	addi	sp,sp,464
ffffffffc02067c0:	8082                	ret
    if (i1.slab_fail == i0.slab_fail) TFAIL("slab failure not recorded");
ffffffffc02067c2:	4605                	li	a2,1
ffffffffc02067c4:	00021817          	auipc	a6,0x21
ffffffffc02067c8:	09483803          	ld	a6,148(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc02067cc:	00007797          	auipc	a5,0x7
ffffffffc02067d0:	8347a783          	lw	a5,-1996(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc02067d4:	6018                	ld	a4,0(s0)
ffffffffc02067d6:	6094                	ld	a3,0(s1)
ffffffffc02067d8:	00007597          	auipc	a1,0x7
ffffffffc02067dc:	8385b583          	ld	a1,-1992(a1) # ffffffffc020d010 <t_case>
ffffffffc02067e0:	00021517          	auipc	a0,0x21
ffffffffc02067e4:	08c52223          	sw	a2,132(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc02067e8:	00002517          	auipc	a0,0x2
ffffffffc02067ec:	61050513          	addi	a0,a0,1552 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc02067f0:	00003617          	auipc	a2,0x3
ffffffffc02067f4:	db060613          	addi	a2,a2,-592 # ffffffffc02095a0 <etext+0x2324>
ffffffffc02067f8:	959f90ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc02067fc:	b391                	j	ffffffffc0206540 <case_fault_inject.part.0+0xa0>

ffffffffc02067fe <case_fault_inject>:
static void case_fault_inject(void) {
ffffffffc02067fe:	1141                	addi	sp,sp,-16
ffffffffc0206800:	e406                	sd	ra,8(sp)
    slub_shrink();
ffffffffc0206802:	8b7fd0ef          	jal	ffffffffc02040b8 <slub_shrink>
ffffffffc0206806:	8c0fc0ef          	jal	ffffffffc02028c6 <nr_free_pages>
    t_baseline = slub_port_nr_free_pages();
ffffffffc020680a:	00021717          	auipc	a4,0x21
ffffffffc020680e:	02a73723          	sd	a0,46(a4) # ffffffffc0227838 <t_baseline>
    if (t_alloc(128) == NULL || t_alloc(5000) == NULL) return;
ffffffffc0206812:	08000513          	li	a0,128
ffffffffc0206816:	deefe0ef          	jal	ffffffffc0204e04 <t_alloc>
ffffffffc020681a:	c919                	beqz	a0,ffffffffc0206830 <case_fault_inject+0x32>
ffffffffc020681c:	6505                	lui	a0,0x1
ffffffffc020681e:	38850513          	addi	a0,a0,904 # 1388 <kern_entry-0xffffffffc01fec78>
ffffffffc0206822:	de2fe0ef          	jal	ffffffffc0204e04 <t_alloc>
ffffffffc0206826:	c509                	beqz	a0,ffffffffc0206830 <case_fault_inject+0x32>
}
ffffffffc0206828:	60a2                	ld	ra,8(sp)
ffffffffc020682a:	0141                	addi	sp,sp,16
ffffffffc020682c:	c75ff06f          	j	ffffffffc02064a0 <case_fault_inject.part.0>
ffffffffc0206830:	60a2                	ld	ra,8(sp)
ffffffffc0206832:	0141                	addi	sp,sp,16
ffffffffc0206834:	8082                	ret

ffffffffc0206836 <case_integrity_mix>:
static void case_integrity_mix(void) {
ffffffffc0206836:	7139                	addi	sp,sp,-64
ffffffffc0206838:	f426                	sd	s1,40(sp)
ffffffffc020683a:	fc06                	sd	ra,56(sp)
ffffffffc020683c:	f822                	sd	s0,48(sp)
ffffffffc020683e:	4481                	li	s1,0
ffffffffc0206840:	03c00413          	li	s0,60
ffffffffc0206844:	a011                	j	ffffffffc0206848 <case_integrity_mix+0x12>
        for (k = 0; k < MIX_PER_CLASS; k++) {
ffffffffc0206846:	c815                	beqz	s0,ffffffffc020687a <case_integrity_mix+0x44>
            if (t_alloc(slub_class_size(cls)) == NULL) {
ffffffffc0206848:	8526                	mv	a0,s1
ffffffffc020684a:	8affd0ef          	jal	ffffffffc02040f8 <slub_class_size>
ffffffffc020684e:	db6fe0ef          	jal	ffffffffc0204e04 <t_alloc>
        for (k = 0; k < MIX_PER_CLASS; k++) {
ffffffffc0206852:	347d                	addiw	s0,s0,-1
            if (t_alloc(slub_class_size(cls)) == NULL) {
ffffffffc0206854:	f96d                	bnez	a0,ffffffffc0206846 <case_integrity_mix+0x10>
    while (t_n != 0) t_free_at(t_n - 1);
ffffffffc0206856:	00021517          	auipc	a0,0x21
ffffffffc020685a:	ff252503          	lw	a0,-14(a0) # ffffffffc0227848 <t_n>
ffffffffc020685e:	c909                	beqz	a0,ffffffffc0206870 <case_integrity_mix+0x3a>
ffffffffc0206860:	357d                	addiw	a0,a0,-1
ffffffffc0206862:	831fe0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc0206866:	00021517          	auipc	a0,0x21
ffffffffc020686a:	fe252503          	lw	a0,-30(a0) # ffffffffc0227848 <t_n>
ffffffffc020686e:	f96d                	bnez	a0,ffffffffc0206860 <case_integrity_mix+0x2a>
}
ffffffffc0206870:	70e2                	ld	ra,56(sp)
ffffffffc0206872:	7442                	ld	s0,48(sp)
ffffffffc0206874:	74a2                	ld	s1,40(sp)
ffffffffc0206876:	6121                	addi	sp,sp,64
ffffffffc0206878:	8082                	ret
    for (cls = 0; cls < MIX_CLASSES; cls++) {
ffffffffc020687a:	0485                	addi	s1,s1,1
ffffffffc020687c:	4799                	li	a5,6
ffffffffc020687e:	fcf491e3          	bne	s1,a5,ffffffffc0206840 <case_integrity_mix+0xa>
ffffffffc0206882:	f04a                	sd	s2,32(sp)
            if (t_alloc(slub_class_size((round + k) % MIX_CLASSES)) == NULL)
ffffffffc0206884:	2aaab937          	lui	s2,0x2aaab
ffffffffc0206888:	ec4e                	sd	s3,24(sp)
ffffffffc020688a:	e852                	sd	s4,16(sp)
ffffffffc020688c:	e456                	sd	s5,8(sp)
ffffffffc020688e:	aab90913          	addi	s2,s2,-1365 # 2aaaaaab <kern_entry-0xffffffff95755555>
    t_verify_all();
ffffffffc0206892:	aa6fe0ef          	jal	ffffffffc0204b38 <t_verify_all>
ffffffffc0206896:	02900493          	li	s1,41
ffffffffc020689a:	00021417          	auipc	s0,0x21
ffffffffc020689e:	fb640413          	addi	s0,s0,-74 # ffffffffc0227850 <t_rng>
        t_iters++;
ffffffffc02068a2:	00021697          	auipc	a3,0x21
ffffffffc02068a6:	fc668693          	addi	a3,a3,-58 # ffffffffc0227868 <t_iters>
ffffffffc02068aa:	629c                	ld	a5,0(a3)
        unsigned int before = t_n, freed = 0;
ffffffffc02068ac:	00021a17          	auipc	s4,0x21
ffffffffc02068b0:	f9ca2a03          	lw	s4,-100(s4) # ffffffffc0227848 <t_n>
ffffffffc02068b4:	fd84899b          	addiw	s3,s1,-40
        t_iters++;
ffffffffc02068b8:	0785                	addi	a5,a5,1
        t_round = round;
ffffffffc02068ba:	00021717          	auipc	a4,0x21
ffffffffc02068be:	f9372323          	sw	s3,-122(a4) # ffffffffc0227840 <t_round>
        t_iters++;
ffffffffc02068c2:	e29c                	sd	a5,0(a3)
        while (freed * 3 < before) {
ffffffffc02068c4:	4a81                	li	s5,0
        t_verify_all();
ffffffffc02068c6:	a72fe0ef          	jal	ffffffffc0204b38 <t_verify_all>
        while (freed * 3 < before) {
ffffffffc02068ca:	020a0c63          	beqz	s4,ffffffffc0206902 <case_integrity_mix+0xcc>
    unsigned long x = t_rng;
ffffffffc02068ce:	601c                	ld	a5,0(s0)
            unsigned int i = (unsigned int)(trand() % t_n);
ffffffffc02068d0:	00021517          	auipc	a0,0x21
ffffffffc02068d4:	f7856503          	lwu	a0,-136(a0) # ffffffffc0227848 <t_n>
        while (freed * 3 < before) {
ffffffffc02068d8:	2a8d                	addiw	s5,s5,3
    x ^= x << 13;
ffffffffc02068da:	00d79713          	slli	a4,a5,0xd
ffffffffc02068de:	8fb9                	xor	a5,a5,a4
    x ^= x >> 7;
ffffffffc02068e0:	0077d713          	srli	a4,a5,0x7
ffffffffc02068e4:	8fb9                	xor	a5,a5,a4
    x ^= x << 17;
ffffffffc02068e6:	01179713          	slli	a4,a5,0x11
ffffffffc02068ea:	8fb9                	xor	a5,a5,a4
            unsigned int i = (unsigned int)(trand() % t_n);
ffffffffc02068ec:	02a7f533          	remu	a0,a5,a0
    t_rng = x;
ffffffffc02068f0:	e01c                	sd	a5,0(s0)
            t_free_at(i);
ffffffffc02068f2:	2501                	sext.w	a0,a0
ffffffffc02068f4:	f9efe0ef          	jal	ffffffffc0205092 <t_free_at>
        while (freed * 3 < before) {
ffffffffc02068f8:	fd4aebe3          	bltu	s5,s4,ffffffffc02068ce <case_integrity_mix+0x98>
ffffffffc02068fc:	a019                	j	ffffffffc0206902 <case_integrity_mix+0xcc>
        for (k = 0; k < 40; k++) {
ffffffffc02068fe:	03348763          	beq	s1,s3,ffffffffc020692c <case_integrity_mix+0xf6>
            if (t_alloc(slub_class_size((round + k) % MIX_CLASSES)) == NULL)
ffffffffc0206902:	032987b3          	mul	a5,s3,s2
ffffffffc0206906:	41f9d71b          	sraiw	a4,s3,0x1f
ffffffffc020690a:	9381                	srli	a5,a5,0x20
ffffffffc020690c:	9f99                	subw	a5,a5,a4
ffffffffc020690e:	0017951b          	slliw	a0,a5,0x1
ffffffffc0206912:	9d3d                	addw	a0,a0,a5
ffffffffc0206914:	0015151b          	slliw	a0,a0,0x1
ffffffffc0206918:	40a9853b          	subw	a0,s3,a0
ffffffffc020691c:	1502                	slli	a0,a0,0x20
ffffffffc020691e:	9101                	srli	a0,a0,0x20
ffffffffc0206920:	fd8fd0ef          	jal	ffffffffc02040f8 <slub_class_size>
ffffffffc0206924:	ce0fe0ef          	jal	ffffffffc0204e04 <t_alloc>
        for (k = 0; k < 40; k++) {
ffffffffc0206928:	2985                	addiw	s3,s3,1
            if (t_alloc(slub_class_size((round + k) % MIX_CLASSES)) == NULL)
ffffffffc020692a:	f971                	bnez	a0,ffffffffc02068fe <case_integrity_mix+0xc8>
        t_verify_all(); /* 所有存活对象（老+新）内容与区间正确 */
ffffffffc020692c:	a0cfe0ef          	jal	ffffffffc0204b38 <t_verify_all>
    for (round = 1; round <= MIX_ROUNDS; round++) {
ffffffffc0206930:	2485                	addiw	s1,s1,1
ffffffffc0206932:	02c00793          	li	a5,44
ffffffffc0206936:	f6f496e3          	bne	s1,a5,ffffffffc02068a2 <case_integrity_mix+0x6c>
ffffffffc020693a:	a021                	j	ffffffffc0206942 <case_integrity_mix+0x10c>
    while (t_n != 0) t_free_at(t_n - 1);
ffffffffc020693c:	357d                	addiw	a0,a0,-1
ffffffffc020693e:	f54fe0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc0206942:	00021517          	auipc	a0,0x21
ffffffffc0206946:	f0652503          	lw	a0,-250(a0) # ffffffffc0227848 <t_n>
ffffffffc020694a:	f96d                	bnez	a0,ffffffffc020693c <case_integrity_mix+0x106>
}
ffffffffc020694c:	70e2                	ld	ra,56(sp)
ffffffffc020694e:	7442                	ld	s0,48(sp)
ffffffffc0206950:	7902                	ld	s2,32(sp)
ffffffffc0206952:	69e2                	ld	s3,24(sp)
ffffffffc0206954:	6a42                	ld	s4,16(sp)
ffffffffc0206956:	6aa2                	ld	s5,8(sp)
ffffffffc0206958:	74a2                	ld	s1,40(sp)
ffffffffc020695a:	6121                	addi	sp,sp,64
ffffffffc020695c:	8082                	ret

ffffffffc020695e <case_cached_pages>:
static void case_cached_pages(void) {
ffffffffc020695e:	7151                	addi	sp,sp,-240
ffffffffc0206960:	f586                	sd	ra,232(sp)
ffffffffc0206962:	eda6                	sd	s1,216(sp)
ffffffffc0206964:	e9ca                	sd	s2,208(sp)
    slub_shrink();
ffffffffc0206966:	f52fd0ef          	jal	ffffffffc02040b8 <slub_shrink>
ffffffffc020696a:	f5dfb0ef          	jal	ffffffffc02028c6 <nr_free_pages>
    t_baseline = slub_port_nr_free_pages();
ffffffffc020696e:	00021917          	auipc	s2,0x21
ffffffffc0206972:	eca90913          	addi	s2,s2,-310 # ffffffffc0227838 <t_baseline>
ffffffffc0206976:	00a93023          	sd	a0,0(s2)
    t_size = 64;
ffffffffc020697a:	00021497          	auipc	s1,0x21
ffffffffc020697e:	ef648493          	addi	s1,s1,-266 # ffffffffc0227870 <t_size>
ffffffffc0206982:	04000793          	li	a5,64
    if (slub_get_class_info(2, &i0) != 0) { /* class 2 = 64B */
ffffffffc0206986:	002c                	addi	a1,sp,8
ffffffffc0206988:	4509                	li	a0,2
    t_size = 64;
ffffffffc020698a:	e09c                	sd	a5,0(s1)
    if (slub_get_class_info(2, &i0) != 0) { /* class 2 = 64B */
ffffffffc020698c:	f86fd0ef          	jal	ffffffffc0204112 <slub_get_class_info>
ffffffffc0206990:	1a051163          	bnez	a0,ffffffffc0206b32 <case_cached_pages+0x1d4>
    n = 4 * i0.barn_cap + 2 * (2 * i0.sheaf_cap) + 2 * i0.objs_per_slab;
ffffffffc0206994:	6742                	ld	a4,16(sp)
ffffffffc0206996:	e5ce                	sd	s3,200(sp)
ffffffffc0206998:	69e2                	ld	s3,24(sp)
ffffffffc020699a:	77a2                	ld	a5,40(sp)
ffffffffc020699c:	f1a2                	sd	s0,224(sp)
ffffffffc020699e:	99ba                	add	s3,s3,a4
ffffffffc02069a0:	0986                	slli	s3,s3,0x1
ffffffffc02069a2:	99be                	add	s3,s3,a5
ffffffffc02069a4:	0986                	slli	s3,s3,0x1
    for (k = 0; k < n; k++) {
ffffffffc02069a6:	04098f63          	beqz	s3,ffffffffc0206a04 <case_cached_pages+0xa6>
ffffffffc02069aa:	e1d2                	sd	s4,192(sp)
ffffffffc02069ac:	4401                	li	s0,0
        t_iters++;
ffffffffc02069ae:	00021a17          	auipc	s4,0x21
ffffffffc02069b2:	ebaa0a13          	addi	s4,s4,-326 # ffffffffc0227868 <t_iters>
ffffffffc02069b6:	a801                	j	ffffffffc02069c6 <case_cached_pages+0x68>
ffffffffc02069b8:	000a3783          	ld	a5,0(s4)
ffffffffc02069bc:	0785                	addi	a5,a5,1
ffffffffc02069be:	00fa3023          	sd	a5,0(s4)
    for (k = 0; k < n; k++) {
ffffffffc02069c2:	05377063          	bgeu	a4,s3,ffffffffc0206a02 <case_cached_pages+0xa4>
        if (t_alloc(64) == NULL) {
ffffffffc02069c6:	04000513          	li	a0,64
ffffffffc02069ca:	c3afe0ef          	jal	ffffffffc0204e04 <t_alloc>
    for (k = 0; k < n; k++) {
ffffffffc02069ce:	2405                	addiw	s0,s0,1
ffffffffc02069d0:	02041713          	slli	a4,s0,0x20
ffffffffc02069d4:	9301                	srli	a4,a4,0x20
        if (t_alloc(64) == NULL) {
ffffffffc02069d6:	f16d                	bnez	a0,ffffffffc02069b8 <case_cached_pages+0x5a>
    while (t_n != 0) t_free_at(t_n - 1);
ffffffffc02069d8:	00021517          	auipc	a0,0x21
ffffffffc02069dc:	e7052503          	lw	a0,-400(a0) # ffffffffc0227848 <t_n>
ffffffffc02069e0:	c909                	beqz	a0,ffffffffc02069f2 <case_cached_pages+0x94>
ffffffffc02069e2:	357d                	addiw	a0,a0,-1
ffffffffc02069e4:	eaefe0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc02069e8:	00021517          	auipc	a0,0x21
ffffffffc02069ec:	e6052503          	lw	a0,-416(a0) # ffffffffc0227848 <t_n>
ffffffffc02069f0:	f96d                	bnez	a0,ffffffffc02069e2 <case_cached_pages+0x84>
ffffffffc02069f2:	740e                	ld	s0,224(sp)
}
ffffffffc02069f4:	70ae                	ld	ra,232(sp)
ffffffffc02069f6:	69ae                	ld	s3,200(sp)
ffffffffc02069f8:	6a0e                	ld	s4,192(sp)
ffffffffc02069fa:	64ee                	ld	s1,216(sp)
ffffffffc02069fc:	694e                	ld	s2,208(sp)
ffffffffc02069fe:	616d                	addi	sp,sp,240
ffffffffc0206a00:	8082                	ret
ffffffffc0206a02:	6a0e                	ld	s4,192(sp)
    t_verify_all();
ffffffffc0206a04:	934fe0ef          	jal	ffffffffc0204b38 <t_verify_all>
    while (t_n != 0) t_free_at((unsigned int)(trand() % t_n));
ffffffffc0206a08:	00021517          	auipc	a0,0x21
ffffffffc0206a0c:	e4052503          	lw	a0,-448(a0) # ffffffffc0227848 <t_n>
ffffffffc0206a10:	cd05                	beqz	a0,ffffffffc0206a48 <case_cached_pages+0xea>
ffffffffc0206a12:	00021417          	auipc	s0,0x21
ffffffffc0206a16:	e3e40413          	addi	s0,s0,-450 # ffffffffc0227850 <t_rng>
    unsigned long x = t_rng;
ffffffffc0206a1a:	601c                	ld	a5,0(s0)
    while (t_n != 0) t_free_at((unsigned int)(trand() % t_n));
ffffffffc0206a1c:	1502                	slli	a0,a0,0x20
ffffffffc0206a1e:	9101                	srli	a0,a0,0x20
    x ^= x << 13;
ffffffffc0206a20:	00d79713          	slli	a4,a5,0xd
ffffffffc0206a24:	8fb9                	xor	a5,a5,a4
    x ^= x >> 7;
ffffffffc0206a26:	0077d713          	srli	a4,a5,0x7
ffffffffc0206a2a:	8fb9                	xor	a5,a5,a4
    x ^= x << 17;
ffffffffc0206a2c:	01179713          	slli	a4,a5,0x11
ffffffffc0206a30:	8fb9                	xor	a5,a5,a4
    while (t_n != 0) t_free_at((unsigned int)(trand() % t_n));
ffffffffc0206a32:	02a7f533          	remu	a0,a5,a0
    t_rng = x;
ffffffffc0206a36:	e01c                	sd	a5,0(s0)
    while (t_n != 0) t_free_at((unsigned int)(trand() % t_n));
ffffffffc0206a38:	2501                	sext.w	a0,a0
ffffffffc0206a3a:	e58fe0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc0206a3e:	00021517          	auipc	a0,0x21
ffffffffc0206a42:	e0a52503          	lw	a0,-502(a0) # ffffffffc0227848 <t_n>
ffffffffc0206a46:	f971                	bnez	a0,ffffffffc0206a1a <case_cached_pages+0xbc>
    if (slub_user_objects() != 0) TFAIL("user object count should be zero");
ffffffffc0206a48:	8d9fd0ef          	jal	ffffffffc0204320 <slub_user_objects>
ffffffffc0206a4c:	12051863          	bnez	a0,ffffffffc0206b7c <case_cached_pages+0x21e>
    held = slub_slab_pages();
ffffffffc0206a50:	951fd0ef          	jal	ffffffffc02043a0 <slub_slab_pages>
ffffffffc0206a54:	842a                	mv	s0,a0
    if (held == 0) TFAIL("pages with cached pointers were returned early");
ffffffffc0206a56:	16050863          	beqz	a0,ffffffffc0206bc6 <case_cached_pages+0x268>
ffffffffc0206a5a:	e6dfb0ef          	jal	ffffffffc02028c6 <nr_free_pages>
    if (slub_port_nr_free_pages() + held != t_baseline) {
ffffffffc0206a5e:	00093783          	ld	a5,0(s2)
ffffffffc0206a62:	9522                	add	a0,a0,s0
ffffffffc0206a64:	04f50e63          	beq	a0,a5,ffffffffc0206ac0 <case_cached_pages+0x162>
ffffffffc0206a68:	e5ffb0ef          	jal	ffffffffc02028c6 <nr_free_pages>
        slub_port_printf("  detail: free=%lu held=%lu baseline=%lu\n",
ffffffffc0206a6c:	00093683          	ld	a3,0(s2)
ffffffffc0206a70:	85aa                	mv	a1,a0
ffffffffc0206a72:	8622                	mv	a2,s0
ffffffffc0206a74:	00003517          	auipc	a0,0x3
ffffffffc0206a78:	a6c50513          	addi	a0,a0,-1428 # ffffffffc02094e0 <etext+0x2264>
ffffffffc0206a7c:	ed4f90ef          	jal	ffffffffc0200150 <cprintf>
        TFAIL("free page accounting mismatch while caches hold pointers");
ffffffffc0206a80:	4605                	li	a2,1
ffffffffc0206a82:	6094                	ld	a3,0(s1)
ffffffffc0206a84:	00021817          	auipc	a6,0x21
ffffffffc0206a88:	dd483803          	ld	a6,-556(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0206a8c:	00006797          	auipc	a5,0x6
ffffffffc0206a90:	5747a783          	lw	a5,1396(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0206a94:	00021717          	auipc	a4,0x21
ffffffffc0206a98:	dd473703          	ld	a4,-556(a4) # ffffffffc0227868 <t_iters>
ffffffffc0206a9c:	00006597          	auipc	a1,0x6
ffffffffc0206aa0:	5745b583          	ld	a1,1396(a1) # ffffffffc020d010 <t_case>
ffffffffc0206aa4:	00021517          	auipc	a0,0x21
ffffffffc0206aa8:	dcc52023          	sw	a2,-576(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0206aac:	00002517          	auipc	a0,0x2
ffffffffc0206ab0:	34c50513          	addi	a0,a0,844 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0206ab4:	00003617          	auipc	a2,0x3
ffffffffc0206ab8:	c8c60613          	addi	a2,a2,-884 # ffffffffc0209740 <etext+0x24c4>
ffffffffc0206abc:	e94f90ef          	jal	ffffffffc0200150 <cprintf>
    m = 2 * i0.sheaf_cap + i0.barn_cap + 8;
ffffffffc0206ac0:	6942                	ld	s2,16(sp)
ffffffffc0206ac2:	67e2                	ld	a5,24(sp)
ffffffffc0206ac4:	0906                	slli	s2,s2,0x1
ffffffffc0206ac6:	07a1                	addi	a5,a5,8
ffffffffc0206ac8:	993e                	add	s2,s2,a5
    for (k = 0; k < m; k++) {
ffffffffc0206aca:	02090663          	beqz	s2,ffffffffc0206af6 <case_cached_pages+0x198>
ffffffffc0206ace:	4401                	li	s0,0
        t_iters++;
ffffffffc0206ad0:	00021497          	auipc	s1,0x21
ffffffffc0206ad4:	d9848493          	addi	s1,s1,-616 # ffffffffc0227868 <t_iters>
ffffffffc0206ad8:	a031                	j	ffffffffc0206ae4 <case_cached_pages+0x186>
ffffffffc0206ada:	609c                	ld	a5,0(s1)
ffffffffc0206adc:	0785                	addi	a5,a5,1
ffffffffc0206ade:	e09c                	sd	a5,0(s1)
    for (k = 0; k < m; k++) {
ffffffffc0206ae0:	01277b63          	bgeu	a4,s2,ffffffffc0206af6 <case_cached_pages+0x198>
        if (t_alloc(64) == NULL) break;
ffffffffc0206ae4:	04000513          	li	a0,64
ffffffffc0206ae8:	b1cfe0ef          	jal	ffffffffc0204e04 <t_alloc>
    for (k = 0; k < m; k++) {
ffffffffc0206aec:	2405                	addiw	s0,s0,1
ffffffffc0206aee:	02041713          	slli	a4,s0,0x20
ffffffffc0206af2:	9301                	srli	a4,a4,0x20
        if (t_alloc(64) == NULL) break;
ffffffffc0206af4:	f17d                	bnez	a0,ffffffffc0206ada <case_cached_pages+0x17c>
    t_verify_all();
ffffffffc0206af6:	842fe0ef          	jal	ffffffffc0204b38 <t_verify_all>
    while (t_n != 0) t_free_at(t_n - 1);
ffffffffc0206afa:	00021517          	auipc	a0,0x21
ffffffffc0206afe:	d4e52503          	lw	a0,-690(a0) # ffffffffc0227848 <t_n>
ffffffffc0206b02:	c909                	beqz	a0,ffffffffc0206b14 <case_cached_pages+0x1b6>
ffffffffc0206b04:	357d                	addiw	a0,a0,-1
ffffffffc0206b06:	d8cfe0ef          	jal	ffffffffc0205092 <t_free_at>
ffffffffc0206b0a:	00021517          	auipc	a0,0x21
ffffffffc0206b0e:	d3e52503          	lw	a0,-706(a0) # ffffffffc0227848 <t_n>
ffffffffc0206b12:	f96d                	bnez	a0,ffffffffc0206b04 <case_cached_pages+0x1a6>
    slub_shrink();
ffffffffc0206b14:	da4fd0ef          	jal	ffffffffc02040b8 <slub_shrink>
    t_expect_baseline("pages not recovered after draining caches");
ffffffffc0206b18:	00003517          	auipc	a0,0x3
ffffffffc0206b1c:	c6850513          	addi	a0,a0,-920 # ffffffffc0209780 <etext+0x2504>
ffffffffc0206b20:	e02fe0ef          	jal	ffffffffc0205122 <t_expect_baseline>
}
ffffffffc0206b24:	70ae                	ld	ra,232(sp)
    t_expect_baseline("pages not recovered after draining caches");
ffffffffc0206b26:	740e                	ld	s0,224(sp)
ffffffffc0206b28:	69ae                	ld	s3,200(sp)
}
ffffffffc0206b2a:	64ee                	ld	s1,216(sp)
ffffffffc0206b2c:	694e                	ld	s2,208(sp)
ffffffffc0206b2e:	616d                	addi	sp,sp,240
ffffffffc0206b30:	8082                	ret
        TFAIL("slub_get_class_info failed");
ffffffffc0206b32:	6094                	ld	a3,0(s1)
ffffffffc0206b34:	4605                	li	a2,1
ffffffffc0206b36:	00021817          	auipc	a6,0x21
ffffffffc0206b3a:	d2283803          	ld	a6,-734(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0206b3e:	00006797          	auipc	a5,0x6
ffffffffc0206b42:	4c27a783          	lw	a5,1218(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0206b46:	00021717          	auipc	a4,0x21
ffffffffc0206b4a:	d2273703          	ld	a4,-734(a4) # ffffffffc0227868 <t_iters>
ffffffffc0206b4e:	00006597          	auipc	a1,0x6
ffffffffc0206b52:	4c25b583          	ld	a1,1218(a1) # ffffffffc020d010 <t_case>
ffffffffc0206b56:	00021517          	auipc	a0,0x21
ffffffffc0206b5a:	d0c52723          	sw	a2,-754(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0206b5e:	00002517          	auipc	a0,0x2
ffffffffc0206b62:	29a50513          	addi	a0,a0,666 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0206b66:	00002617          	auipc	a2,0x2
ffffffffc0206b6a:	5e260613          	addi	a2,a2,1506 # ffffffffc0209148 <etext+0x1ecc>
ffffffffc0206b6e:	de2f90ef          	jal	ffffffffc0200150 <cprintf>
}
ffffffffc0206b72:	70ae                	ld	ra,232(sp)
ffffffffc0206b74:	64ee                	ld	s1,216(sp)
ffffffffc0206b76:	694e                	ld	s2,208(sp)
ffffffffc0206b78:	616d                	addi	sp,sp,240
ffffffffc0206b7a:	8082                	ret
    if (slub_user_objects() != 0) TFAIL("user object count should be zero");
ffffffffc0206b7c:	00021817          	auipc	a6,0x21
ffffffffc0206b80:	cdc83803          	ld	a6,-804(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0206b84:	00006797          	auipc	a5,0x6
ffffffffc0206b88:	47c7a783          	lw	a5,1148(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0206b8c:	00021717          	auipc	a4,0x21
ffffffffc0206b90:	cdc73703          	ld	a4,-804(a4) # ffffffffc0227868 <t_iters>
ffffffffc0206b94:	6094                	ld	a3,0(s1)
ffffffffc0206b96:	00006597          	auipc	a1,0x6
ffffffffc0206b9a:	47a5b583          	ld	a1,1146(a1) # ffffffffc020d010 <t_case>
ffffffffc0206b9e:	4605                	li	a2,1
ffffffffc0206ba0:	00021517          	auipc	a0,0x21
ffffffffc0206ba4:	ccc52223          	sw	a2,-828(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0206ba8:	00002517          	auipc	a0,0x2
ffffffffc0206bac:	25050513          	addi	a0,a0,592 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0206bb0:	00003617          	auipc	a2,0x3
ffffffffc0206bb4:	b3860613          	addi	a2,a2,-1224 # ffffffffc02096e8 <etext+0x246c>
ffffffffc0206bb8:	d98f90ef          	jal	ffffffffc0200150 <cprintf>
    held = slub_slab_pages();
ffffffffc0206bbc:	fe4fd0ef          	jal	ffffffffc02043a0 <slub_slab_pages>
ffffffffc0206bc0:	842a                	mv	s0,a0
    if (held == 0) TFAIL("pages with cached pointers were returned early");
ffffffffc0206bc2:	e8051ce3          	bnez	a0,ffffffffc0206a5a <case_cached_pages+0xfc>
ffffffffc0206bc6:	4605                	li	a2,1
ffffffffc0206bc8:	00021817          	auipc	a6,0x21
ffffffffc0206bcc:	c9083803          	ld	a6,-880(a6) # ffffffffc0227858 <t_seed_cfg>
ffffffffc0206bd0:	00006797          	auipc	a5,0x6
ffffffffc0206bd4:	4307a783          	lw	a5,1072(a5) # ffffffffc020d000 <boot_hartid>
ffffffffc0206bd8:	00021717          	auipc	a4,0x21
ffffffffc0206bdc:	c9073703          	ld	a4,-880(a4) # ffffffffc0227868 <t_iters>
ffffffffc0206be0:	6094                	ld	a3,0(s1)
ffffffffc0206be2:	00006597          	auipc	a1,0x6
ffffffffc0206be6:	42e5b583          	ld	a1,1070(a1) # ffffffffc020d010 <t_case>
ffffffffc0206bea:	00021517          	auipc	a0,0x21
ffffffffc0206bee:	c6c52d23          	sw	a2,-902(a0) # ffffffffc0227864 <t_case_failed>
ffffffffc0206bf2:	00002517          	auipc	a0,0x2
ffffffffc0206bf6:	20650513          	addi	a0,a0,518 # ffffffffc0208df8 <etext+0x1b7c>
ffffffffc0206bfa:	00003617          	auipc	a2,0x3
ffffffffc0206bfe:	b1660613          	addi	a2,a2,-1258 # ffffffffc0209710 <etext+0x2494>
ffffffffc0206c02:	d4ef90ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc0206c06:	bd91                	j	ffffffffc0206a5a <case_cached_pages+0xfc>

ffffffffc0206c08 <slub_test_run>:

int slub_test_run(unsigned long seed) {
ffffffffc0206c08:	1101                	addi	sp,sp,-32
ffffffffc0206c0a:	ec06                	sd	ra,24(sp)
ffffffffc0206c0c:	e822                	sd	s0,16(sp)
ffffffffc0206c0e:	87aa                	mv	a5,a0
    t_seed_cfg = (seed != 0) ? seed : SLUB_TEST_SEED;
ffffffffc0206c10:	ed01                	bnez	a0,ffffffffc0206c28 <slub_test_run+0x20>
ffffffffc0206c12:	ffe087b7          	lui	a5,0xffe08
ffffffffc0206c16:	17dd                	addi	a5,a5,-9 # ffffffffffe07ff7 <end+0x3fbe077f>
ffffffffc0206c18:	07b6                	slli	a5,a5,0xd
ffffffffc0206c1a:	51b78793          	addi	a5,a5,1307
ffffffffc0206c1e:	07b2                	slli	a5,a5,0xc
ffffffffc0206c20:	bc178793          	addi	a5,a5,-1087
ffffffffc0206c24:	07c2                	slli	a5,a5,0x10
ffffffffc0206c26:	17b9                	addi	a5,a5,-18
    t_n = 0;
    t_next_id = 0;
    t_round = 0;
    t_total_failed = 0;

    slub_port_printf("SLUB_TEST_BEGIN seed=%lu cpus=%d classes=%d\n",
ffffffffc0206c28:	85be                	mv	a1,a5
ffffffffc0206c2a:	46a1                	li	a3,8
ffffffffc0206c2c:	4605                	li	a2,1
    t_seed_cfg = (seed != 0) ? seed : SLUB_TEST_SEED;
ffffffffc0206c2e:	00021417          	auipc	s0,0x21
ffffffffc0206c32:	c2a40413          	addi	s0,s0,-982 # ffffffffc0227858 <t_seed_cfg>
    slub_port_printf("SLUB_TEST_BEGIN seed=%lu cpus=%d classes=%d\n",
ffffffffc0206c36:	00003517          	auipc	a0,0x3
ffffffffc0206c3a:	b7a50513          	addi	a0,a0,-1158 # ffffffffc02097b0 <etext+0x2534>
    t_rng = t_seed_cfg;
ffffffffc0206c3e:	00021717          	auipc	a4,0x21
ffffffffc0206c42:	c0f73923          	sd	a5,-1006(a4) # ffffffffc0227850 <t_rng>
    t_seed_cfg = (seed != 0) ? seed : SLUB_TEST_SEED;
ffffffffc0206c46:	e01c                	sd	a5,0(s0)
    t_n = 0;
ffffffffc0206c48:	00021717          	auipc	a4,0x21
ffffffffc0206c4c:	c0072023          	sw	zero,-1024(a4) # ffffffffc0227848 <t_n>
    t_next_id = 0;
ffffffffc0206c50:	00021717          	auipc	a4,0x21
ffffffffc0206c54:	be072a23          	sw	zero,-1036(a4) # ffffffffc0227844 <t_next_id>
    t_round = 0;
ffffffffc0206c58:	00021717          	auipc	a4,0x21
ffffffffc0206c5c:	be072423          	sw	zero,-1048(a4) # ffffffffc0227840 <t_round>
    t_total_failed = 0;
ffffffffc0206c60:	00021717          	auipc	a4,0x21
ffffffffc0206c64:	c0072023          	sw	zero,-1024(a4) # ffffffffc0227860 <t_total_failed>
    slub_port_printf("SLUB_TEST_BEGIN seed=%lu cpus=%d classes=%d\n",
ffffffffc0206c68:	ce8f90ef          	jal	ffffffffc0200150 <cprintf>
                     t_seed_cfg, (int)SLUB_NCPUS, (int)SLUB_NCLASSES);
    slub_port_printf("SLUB_TEST_NOTE negative misuse (double free / foreign "
ffffffffc0206c6c:	00003517          	auipc	a0,0x3
ffffffffc0206c70:	b7450513          	addi	a0,a0,-1164 # ffffffffc02097e0 <etext+0x2564>
ffffffffc0206c74:	cdcf90ef          	jal	ffffffffc0200150 <cprintf>
                     "pointer) panics by contract; kernel suite excludes it, "
                     "host slub_host_neg covers it in a child process\n");

    /* 安静环境下先 shrink，记录空闲页基线（固定元数据开销包含在内） */
    slub_shrink();
ffffffffc0206c78:	c40fd0ef          	jal	ffffffffc02040b8 <slub_shrink>
ffffffffc0206c7c:	c4bfb0ef          	jal	ffffffffc02028c6 <nr_free_pages>
    t_baseline = slub_port_nr_free_pages();
ffffffffc0206c80:	00021797          	auipc	a5,0x21
ffffffffc0206c84:	baa7bc23          	sd	a0,-1096(a5) # ffffffffc0227838 <t_baseline>
ffffffffc0206c88:	e42a                	sd	a0,8(sp)
    slub_port_printf("SLUB_TEST_BASELINE free_pages=%lu fixed_overhead=%lu\n",
                     (unsigned long)t_baseline,
                     (unsigned long)slub_fixed_overhead());
ffffffffc0206c8a:	fb4fd0ef          	jal	ffffffffc020443e <slub_fixed_overhead>
    slub_port_printf("SLUB_TEST_BASELINE free_pages=%lu fixed_overhead=%lu\n",
ffffffffc0206c8e:	65a2                	ld	a1,8(sp)
                     (unsigned long)slub_fixed_overhead());
ffffffffc0206c90:	862a                	mv	a2,a0
    slub_port_printf("SLUB_TEST_BASELINE free_pages=%lu fixed_overhead=%lu\n",
ffffffffc0206c92:	00003517          	auipc	a0,0x3
ffffffffc0206c96:	bee50513          	addi	a0,a0,-1042 # ffffffffc0209880 <etext+0x2604>
ffffffffc0206c9a:	cb6f90ef          	jal	ffffffffc0200150 <cprintf>

    t_run(case_sizes_edge, "sizes_edge");
ffffffffc0206c9e:	00003597          	auipc	a1,0x3
ffffffffc0206ca2:	c1a58593          	addi	a1,a1,-998 # ffffffffc02098b8 <etext+0x263c>
ffffffffc0206ca6:	fffff517          	auipc	a0,0xfffff
ffffffffc0206caa:	ef850513          	addi	a0,a0,-264 # ffffffffc0205b9e <case_sizes_edge>
ffffffffc0206cae:	92eff0ef          	jal	ffffffffc0205ddc <t_run>
    t_run(case_class_bounds, "class_bounds");
ffffffffc0206cb2:	00003597          	auipc	a1,0x3
ffffffffc0206cb6:	c1658593          	addi	a1,a1,-1002 # ffffffffc02098c8 <etext+0x264c>
ffffffffc0206cba:	fffff517          	auipc	a0,0xfffff
ffffffffc0206cbe:	dbc50513          	addi	a0,a0,-580 # ffffffffc0205a76 <case_class_bounds>
ffffffffc0206cc2:	91aff0ef          	jal	ffffffffc0205ddc <t_run>
    t_run(case_page_boundary, "page_boundary");
ffffffffc0206cc6:	00003597          	auipc	a1,0x3
ffffffffc0206cca:	c1258593          	addi	a1,a1,-1006 # ffffffffc02098d8 <etext+0x265c>
ffffffffc0206cce:	fffff517          	auipc	a0,0xfffff
ffffffffc0206cd2:	8ce50513          	addi	a0,a0,-1842 # ffffffffc020559c <case_page_boundary>
ffffffffc0206cd6:	906ff0ef          	jal	ffffffffc0205ddc <t_run>
    t_run(case_overflow, "overflow");
ffffffffc0206cda:	00003597          	auipc	a1,0x3
ffffffffc0206cde:	c0e58593          	addi	a1,a1,-1010 # ffffffffc02098e8 <etext+0x266c>
ffffffffc0206ce2:	fffff517          	auipc	a0,0xfffff
ffffffffc0206ce6:	1da50513          	addi	a0,a0,474 # ffffffffc0205ebc <case_overflow>
ffffffffc0206cea:	8f2ff0ef          	jal	ffffffffc0205ddc <t_run>
    t_run(case_integrity_mix, "integrity_mix");
ffffffffc0206cee:	00003597          	auipc	a1,0x3
ffffffffc0206cf2:	c0a58593          	addi	a1,a1,-1014 # ffffffffc02098f8 <etext+0x267c>
ffffffffc0206cf6:	00000517          	auipc	a0,0x0
ffffffffc0206cfa:	b4050513          	addi	a0,a0,-1216 # ffffffffc0206836 <case_integrity_mix>
ffffffffc0206cfe:	8deff0ef          	jal	ffffffffc0205ddc <t_run>
    t_run(case_free_orders, "free_orders");
ffffffffc0206d02:	00003597          	auipc	a1,0x3
ffffffffc0206d06:	c0658593          	addi	a1,a1,-1018 # ffffffffc0209908 <etext+0x268c>
ffffffffc0206d0a:	fffff517          	auipc	a0,0xfffff
ffffffffc0206d0e:	2dc50513          	addi	a0,a0,732 # ffffffffc0205fe6 <case_free_orders>
ffffffffc0206d12:	8caff0ef          	jal	ffffffffc0205ddc <t_run>
    t_run(case_sustained_churn, "sustained_churn");
ffffffffc0206d16:	00003597          	auipc	a1,0x3
ffffffffc0206d1a:	c0258593          	addi	a1,a1,-1022 # ffffffffc0209918 <etext+0x269c>
ffffffffc0206d1e:	fffff517          	auipc	a0,0xfffff
ffffffffc0206d22:	8dc50513          	addi	a0,a0,-1828 # ffffffffc02055fa <case_sustained_churn>
ffffffffc0206d26:	8b6ff0ef          	jal	ffffffffc0205ddc <t_run>
    t_run(case_null_free, "null_free");
ffffffffc0206d2a:	00003597          	auipc	a1,0x3
ffffffffc0206d2e:	bfe58593          	addi	a1,a1,-1026 # ffffffffc0209928 <etext+0x26ac>
ffffffffc0206d32:	ffffe517          	auipc	a0,0xffffe
ffffffffc0206d36:	68e50513          	addi	a0,a0,1678 # ffffffffc02053c0 <case_null_free>
ffffffffc0206d3a:	8a2ff0ef          	jal	ffffffffc0205ddc <t_run>
    t_run(case_shrink_baseline, "shrink_baseline");
ffffffffc0206d3e:	00003597          	auipc	a1,0x3
ffffffffc0206d42:	bfa58593          	addi	a1,a1,-1030 # ffffffffc0209938 <etext+0x26bc>
ffffffffc0206d46:	ffffe517          	auipc	a0,0xffffe
ffffffffc0206d4a:	51250513          	addi	a0,a0,1298 # ffffffffc0205258 <case_shrink_baseline>
ffffffffc0206d4e:	88eff0ef          	jal	ffffffffc0205ddc <t_run>
    t_run(case_shrink_live, "shrink_live");
ffffffffc0206d52:	00003597          	auipc	a1,0x3
ffffffffc0206d56:	bf658593          	addi	a1,a1,-1034 # ffffffffc0209948 <etext+0x26cc>
ffffffffc0206d5a:	fffff517          	auipc	a0,0xfffff
ffffffffc0206d5e:	52c50513          	addi	a0,a0,1324 # ffffffffc0206286 <case_shrink_live>
ffffffffc0206d62:	87aff0ef          	jal	ffffffffc0205ddc <t_run>
    t_run(case_cached_pages, "cached_pages");
ffffffffc0206d66:	00003597          	auipc	a1,0x3
ffffffffc0206d6a:	bf258593          	addi	a1,a1,-1038 # ffffffffc0209958 <etext+0x26dc>
ffffffffc0206d6e:	00000517          	auipc	a0,0x0
ffffffffc0206d72:	bf050513          	addi	a0,a0,-1040 # ffffffffc020695e <case_cached_pages>
ffffffffc0206d76:	866ff0ef          	jal	ffffffffc0205ddc <t_run>
    t_run(case_fault_inject, "fault_inject");
ffffffffc0206d7a:	00003597          	auipc	a1,0x3
ffffffffc0206d7e:	bee58593          	addi	a1,a1,-1042 # ffffffffc0209968 <etext+0x26ec>
ffffffffc0206d82:	00000517          	auipc	a0,0x0
ffffffffc0206d86:	a7c50513          	addi	a0,a0,-1412 # ffffffffc02067fe <case_fault_inject>
ffffffffc0206d8a:	852ff0ef          	jal	ffffffffc0205ddc <t_run>
    t_run(case_check_ptr, "check_ptr");
ffffffffc0206d8e:	fffff517          	auipc	a0,0xfffff
ffffffffc0206d92:	fa050513          	addi	a0,a0,-96 # ffffffffc0205d2e <case_check_ptr>
ffffffffc0206d96:	00003597          	auipc	a1,0x3
ffffffffc0206d9a:	be258593          	addi	a1,a1,-1054 # ffffffffc0209978 <etext+0x26fc>
ffffffffc0206d9e:	83eff0ef          	jal	ffffffffc0205ddc <t_run>

    if (t_total_failed != 0) {
ffffffffc0206da2:	00021517          	auipc	a0,0x21
ffffffffc0206da6:	abe52503          	lw	a0,-1346(a0) # ffffffffc0227860 <t_total_failed>
ffffffffc0206daa:	e509                	bnez	a0,ffffffffc0206db4 <slub_test_run+0x1ac>
        slub_port_printf("SLUB_TEST_FAIL total_cases_failed=%d seed=%lu\n",
                         t_total_failed, t_seed_cfg);
    }
    return t_total_failed;
}
ffffffffc0206dac:	60e2                	ld	ra,24(sp)
ffffffffc0206dae:	6442                	ld	s0,16(sp)
ffffffffc0206db0:	6105                	addi	sp,sp,32
ffffffffc0206db2:	8082                	ret
        slub_port_printf("SLUB_TEST_FAIL total_cases_failed=%d seed=%lu\n",
ffffffffc0206db4:	6010                	ld	a2,0(s0)
ffffffffc0206db6:	85aa                	mv	a1,a0
ffffffffc0206db8:	00003517          	auipc	a0,0x3
ffffffffc0206dbc:	bd050513          	addi	a0,a0,-1072 # ffffffffc0209988 <etext+0x270c>
ffffffffc0206dc0:	b90f90ef          	jal	ffffffffc0200150 <cprintf>
}
ffffffffc0206dc4:	60e2                	ld	ra,24(sp)
ffffffffc0206dc6:	6442                	ld	s0,16(sp)
    return t_total_failed;
ffffffffc0206dc8:	00021517          	auipc	a0,0x21
ffffffffc0206dcc:	a9852503          	lw	a0,-1384(a0) # ffffffffc0227860 <t_total_failed>
}
ffffffffc0206dd0:	6105                	addi	sp,sp,32
ffffffffc0206dd2:	8082                	ret

ffffffffc0206dd4 <check_slub>:

/* ------------------------- 内核入口 ------------------------- */

void check_slub(void) {
ffffffffc0206dd4:	1141                	addi	sp,sp,-16
    if (slub_test_run(0) == 0) {
ffffffffc0206dd6:	4501                	li	a0,0
void check_slub(void) {
ffffffffc0206dd8:	e406                	sd	ra,8(sp)
    if (slub_test_run(0) == 0) {
ffffffffc0206dda:	e2fff0ef          	jal	ffffffffc0206c08 <slub_test_run>
ffffffffc0206dde:	e909                	bnez	a0,ffffffffc0206df0 <check_slub+0x1c>
        slub_port_printf("SLUB_TEST_PASS\n");
    } else {
        slub_port_printf("SLUB_TEST_DONE_WITH_FAILURES\n");
    }
}
ffffffffc0206de0:	60a2                	ld	ra,8(sp)
        slub_port_printf("SLUB_TEST_PASS\n");
ffffffffc0206de2:	00003517          	auipc	a0,0x3
ffffffffc0206de6:	bd650513          	addi	a0,a0,-1066 # ffffffffc02099b8 <etext+0x273c>
}
ffffffffc0206dea:	0141                	addi	sp,sp,16
        slub_port_printf("SLUB_TEST_PASS\n");
ffffffffc0206dec:	b64f906f          	j	ffffffffc0200150 <cprintf>
}
ffffffffc0206df0:	60a2                	ld	ra,8(sp)
        slub_port_printf("SLUB_TEST_DONE_WITH_FAILURES\n");
ffffffffc0206df2:	00003517          	auipc	a0,0x3
ffffffffc0206df6:	bd650513          	addi	a0,a0,-1066 # ffffffffc02099c8 <etext+0x274c>
}
ffffffffc0206dfa:	0141                	addi	sp,sp,16
        slub_port_printf("SLUB_TEST_DONE_WITH_FAILURES\n");
ffffffffc0206dfc:	b54f906f          	j	ffffffffc0200150 <cprintf>

ffffffffc0206e00 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206e00:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0206e02:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206e06:	f022                	sd	s0,32(sp)
ffffffffc0206e08:	ec26                	sd	s1,24(sp)
ffffffffc0206e0a:	e84a                	sd	s2,16(sp)
ffffffffc0206e0c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0206e0e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206e12:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc0206e14:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0206e18:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206e1c:	84aa                	mv	s1,a0
ffffffffc0206e1e:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc0206e20:	03067d63          	bgeu	a2,a6,ffffffffc0206e5a <printnum+0x5a>
ffffffffc0206e24:	e44e                	sd	s3,8(sp)
ffffffffc0206e26:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0206e28:	4785                	li	a5,1
ffffffffc0206e2a:	00e7d763          	bge	a5,a4,ffffffffc0206e38 <printnum+0x38>
            putch(padc, putdat);
ffffffffc0206e2e:	85ca                	mv	a1,s2
ffffffffc0206e30:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0206e32:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0206e34:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0206e36:	fc65                	bnez	s0,ffffffffc0206e2e <printnum+0x2e>
ffffffffc0206e38:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206e3a:	00003797          	auipc	a5,0x3
ffffffffc0206e3e:	bb678793          	addi	a5,a5,-1098 # ffffffffc02099f0 <etext+0x2774>
ffffffffc0206e42:	97d2                	add	a5,a5,s4
}
ffffffffc0206e44:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206e46:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0206e4a:	70a2                	ld	ra,40(sp)
ffffffffc0206e4c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206e4e:	85ca                	mv	a1,s2
ffffffffc0206e50:	87a6                	mv	a5,s1
}
ffffffffc0206e52:	6942                	ld	s2,16(sp)
ffffffffc0206e54:	64e2                	ld	s1,24(sp)
ffffffffc0206e56:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206e58:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0206e5a:	03065633          	divu	a2,a2,a6
ffffffffc0206e5e:	8722                	mv	a4,s0
ffffffffc0206e60:	fa1ff0ef          	jal	ffffffffc0206e00 <printnum>
ffffffffc0206e64:	bfd9                	j	ffffffffc0206e3a <printnum+0x3a>

ffffffffc0206e66 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0206e66:	7119                	addi	sp,sp,-128
ffffffffc0206e68:	f4a6                	sd	s1,104(sp)
ffffffffc0206e6a:	f0ca                	sd	s2,96(sp)
ffffffffc0206e6c:	ecce                	sd	s3,88(sp)
ffffffffc0206e6e:	e8d2                	sd	s4,80(sp)
ffffffffc0206e70:	e4d6                	sd	s5,72(sp)
ffffffffc0206e72:	e0da                	sd	s6,64(sp)
ffffffffc0206e74:	f862                	sd	s8,48(sp)
ffffffffc0206e76:	fc86                	sd	ra,120(sp)
ffffffffc0206e78:	f8a2                	sd	s0,112(sp)
ffffffffc0206e7a:	fc5e                	sd	s7,56(sp)
ffffffffc0206e7c:	f466                	sd	s9,40(sp)
ffffffffc0206e7e:	f06a                	sd	s10,32(sp)
ffffffffc0206e80:	ec6e                	sd	s11,24(sp)
ffffffffc0206e82:	84aa                	mv	s1,a0
ffffffffc0206e84:	8c32                	mv	s8,a2
ffffffffc0206e86:	8a36                	mv	s4,a3
ffffffffc0206e88:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206e8a:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206e8e:	05500b13          	li	s6,85
ffffffffc0206e92:	00003a97          	auipc	s5,0x3
ffffffffc0206e96:	d76a8a93          	addi	s5,s5,-650 # ffffffffc0209c08 <sizes.5+0x30>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206e9a:	000c4503          	lbu	a0,0(s8)
ffffffffc0206e9e:	001c0413          	addi	s0,s8,1
ffffffffc0206ea2:	01350a63          	beq	a0,s3,ffffffffc0206eb6 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0206ea6:	cd0d                	beqz	a0,ffffffffc0206ee0 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0206ea8:	85ca                	mv	a1,s2
ffffffffc0206eaa:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206eac:	00044503          	lbu	a0,0(s0)
ffffffffc0206eb0:	0405                	addi	s0,s0,1
ffffffffc0206eb2:	ff351ae3          	bne	a0,s3,ffffffffc0206ea6 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0206eb6:	5cfd                	li	s9,-1
ffffffffc0206eb8:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0206eba:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0206ebe:	4b81                	li	s7,0
ffffffffc0206ec0:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206ec2:	00044683          	lbu	a3,0(s0)
ffffffffc0206ec6:	00140c13          	addi	s8,s0,1
ffffffffc0206eca:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0206ece:	0ff5f593          	zext.b	a1,a1
ffffffffc0206ed2:	02bb6663          	bltu	s6,a1,ffffffffc0206efe <vprintfmt+0x98>
ffffffffc0206ed6:	058a                	slli	a1,a1,0x2
ffffffffc0206ed8:	95d6                	add	a1,a1,s5
ffffffffc0206eda:	4198                	lw	a4,0(a1)
ffffffffc0206edc:	9756                	add	a4,a4,s5
ffffffffc0206ede:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0206ee0:	70e6                	ld	ra,120(sp)
ffffffffc0206ee2:	7446                	ld	s0,112(sp)
ffffffffc0206ee4:	74a6                	ld	s1,104(sp)
ffffffffc0206ee6:	7906                	ld	s2,96(sp)
ffffffffc0206ee8:	69e6                	ld	s3,88(sp)
ffffffffc0206eea:	6a46                	ld	s4,80(sp)
ffffffffc0206eec:	6aa6                	ld	s5,72(sp)
ffffffffc0206eee:	6b06                	ld	s6,64(sp)
ffffffffc0206ef0:	7be2                	ld	s7,56(sp)
ffffffffc0206ef2:	7c42                	ld	s8,48(sp)
ffffffffc0206ef4:	7ca2                	ld	s9,40(sp)
ffffffffc0206ef6:	7d02                	ld	s10,32(sp)
ffffffffc0206ef8:	6de2                	ld	s11,24(sp)
ffffffffc0206efa:	6109                	addi	sp,sp,128
ffffffffc0206efc:	8082                	ret
            putch('%', putdat);
ffffffffc0206efe:	85ca                	mv	a1,s2
ffffffffc0206f00:	02500513          	li	a0,37
ffffffffc0206f04:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0206f06:	fff44783          	lbu	a5,-1(s0)
ffffffffc0206f0a:	02500713          	li	a4,37
ffffffffc0206f0e:	8c22                	mv	s8,s0
ffffffffc0206f10:	f8e785e3          	beq	a5,a4,ffffffffc0206e9a <vprintfmt+0x34>
ffffffffc0206f14:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0206f18:	1c7d                	addi	s8,s8,-1
ffffffffc0206f1a:	fee79de3          	bne	a5,a4,ffffffffc0206f14 <vprintfmt+0xae>
ffffffffc0206f1e:	bfb5                	j	ffffffffc0206e9a <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0206f20:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0206f24:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0206f26:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0206f2a:	fd06071b          	addiw	a4,a2,-48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206f2e:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc0206f30:	02e56363          	bltu	a0,a4,ffffffffc0206f56 <vprintfmt+0xf0>
                precision = precision * 10 + ch - '0';
ffffffffc0206f34:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0206f38:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0206f3c:	0197073b          	addw	a4,a4,s9
ffffffffc0206f40:	0017171b          	slliw	a4,a4,0x1
ffffffffc0206f44:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0206f46:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0206f4a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0206f4c:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0206f50:	8636                	mv	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0206f52:	feb571e3          	bgeu	a0,a1,ffffffffc0206f34 <vprintfmt+0xce>
            if (width < 0)
ffffffffc0206f56:	f60d56e3          	bgez	s10,ffffffffc0206ec2 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0206f5a:	8d66                	mv	s10,s9
ffffffffc0206f5c:	5cfd                	li	s9,-1
ffffffffc0206f5e:	b795                	j	ffffffffc0206ec2 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206f60:	8db6                	mv	s11,a3
ffffffffc0206f62:	8462                	mv	s0,s8
ffffffffc0206f64:	bfb9                	j	ffffffffc0206ec2 <vprintfmt+0x5c>
ffffffffc0206f66:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0206f68:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0206f6a:	bfa1                	j	ffffffffc0206ec2 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0206f6c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0206f6e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0206f72:	00f74463          	blt	a4,a5,ffffffffc0206f7a <vprintfmt+0x114>
    else if (lflag) {
ffffffffc0206f76:	1a078763          	beqz	a5,ffffffffc0207124 <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc0206f7a:	000a3603          	ld	a2,0(s4)
ffffffffc0206f7e:	46c1                	li	a3,16
ffffffffc0206f80:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0206f82:	000d879b          	sext.w	a5,s11
ffffffffc0206f86:	876a                	mv	a4,s10
ffffffffc0206f88:	85ca                	mv	a1,s2
ffffffffc0206f8a:	8526                	mv	a0,s1
ffffffffc0206f8c:	e75ff0ef          	jal	ffffffffc0206e00 <printnum>
            break;
ffffffffc0206f90:	b729                	j	ffffffffc0206e9a <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0206f92:	000a2503          	lw	a0,0(s4)
ffffffffc0206f96:	85ca                	mv	a1,s2
ffffffffc0206f98:	0a21                	addi	s4,s4,8
ffffffffc0206f9a:	9482                	jalr	s1
            break;
ffffffffc0206f9c:	bdfd                	j	ffffffffc0206e9a <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0206f9e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0206fa0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0206fa4:	00f74463          	blt	a4,a5,ffffffffc0206fac <vprintfmt+0x146>
    else if (lflag) {
ffffffffc0206fa8:	16078963          	beqz	a5,ffffffffc020711a <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc0206fac:	000a3603          	ld	a2,0(s4)
ffffffffc0206fb0:	46a9                	li	a3,10
ffffffffc0206fb2:	8a2e                	mv	s4,a1
ffffffffc0206fb4:	b7f9                	j	ffffffffc0206f82 <vprintfmt+0x11c>
            putch('0', putdat);
ffffffffc0206fb6:	85ca                	mv	a1,s2
ffffffffc0206fb8:	03000513          	li	a0,48
ffffffffc0206fbc:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0206fbe:	85ca                	mv	a1,s2
ffffffffc0206fc0:	07800513          	li	a0,120
ffffffffc0206fc4:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0206fc6:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0206fca:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0206fcc:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0206fce:	bf55                	j	ffffffffc0206f82 <vprintfmt+0x11c>
            putch(ch, putdat);
ffffffffc0206fd0:	85ca                	mv	a1,s2
ffffffffc0206fd2:	02500513          	li	a0,37
ffffffffc0206fd6:	9482                	jalr	s1
            break;
ffffffffc0206fd8:	b5c9                	j	ffffffffc0206e9a <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0206fda:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206fde:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0206fe0:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0206fe2:	bf95                	j	ffffffffc0206f56 <vprintfmt+0xf0>
    if (lflag >= 2) {
ffffffffc0206fe4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0206fe6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0206fea:	00f74463          	blt	a4,a5,ffffffffc0206ff2 <vprintfmt+0x18c>
    else if (lflag) {
ffffffffc0206fee:	12078163          	beqz	a5,ffffffffc0207110 <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc0206ff2:	000a3603          	ld	a2,0(s4)
ffffffffc0206ff6:	46a1                	li	a3,8
ffffffffc0206ff8:	8a2e                	mv	s4,a1
ffffffffc0206ffa:	b761                	j	ffffffffc0206f82 <vprintfmt+0x11c>
            if (width < 0)
ffffffffc0206ffc:	876a                	mv	a4,s10
ffffffffc0206ffe:	000d5363          	bgez	s10,ffffffffc0207004 <vprintfmt+0x19e>
ffffffffc0207002:	4701                	li	a4,0
ffffffffc0207004:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0207008:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020700a:	bd65                	j	ffffffffc0206ec2 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc020700c:	000d841b          	sext.w	s0,s11
ffffffffc0207010:	fd340793          	addi	a5,s0,-45
ffffffffc0207014:	00f037b3          	snez	a5,a5
ffffffffc0207018:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020701c:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0207020:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0207022:	008a0793          	addi	a5,s4,8
ffffffffc0207026:	e43e                	sd	a5,8(sp)
ffffffffc0207028:	100d8c63          	beqz	s11,ffffffffc0207140 <vprintfmt+0x2da>
            if (width > 0 && padc != '-') {
ffffffffc020702c:	12071363          	bnez	a4,ffffffffc0207152 <vprintfmt+0x2ec>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0207030:	000dc783          	lbu	a5,0(s11)
ffffffffc0207034:	0007851b          	sext.w	a0,a5
ffffffffc0207038:	c78d                	beqz	a5,ffffffffc0207062 <vprintfmt+0x1fc>
ffffffffc020703a:	0d85                	addi	s11,s11,1
ffffffffc020703c:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020703e:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0207042:	000cc563          	bltz	s9,ffffffffc020704c <vprintfmt+0x1e6>
ffffffffc0207046:	3cfd                	addiw	s9,s9,-1
ffffffffc0207048:	008c8d63          	beq	s9,s0,ffffffffc0207062 <vprintfmt+0x1fc>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020704c:	020b9663          	bnez	s7,ffffffffc0207078 <vprintfmt+0x212>
                    putch(ch, putdat);
ffffffffc0207050:	85ca                	mv	a1,s2
ffffffffc0207052:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0207054:	000dc783          	lbu	a5,0(s11)
ffffffffc0207058:	0d85                	addi	s11,s11,1
ffffffffc020705a:	3d7d                	addiw	s10,s10,-1
ffffffffc020705c:	0007851b          	sext.w	a0,a5
ffffffffc0207060:	f3ed                	bnez	a5,ffffffffc0207042 <vprintfmt+0x1dc>
            for (; width > 0; width --) {
ffffffffc0207062:	01a05963          	blez	s10,ffffffffc0207074 <vprintfmt+0x20e>
                putch(' ', putdat);
ffffffffc0207066:	85ca                	mv	a1,s2
ffffffffc0207068:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc020706c:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc020706e:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0207070:	fe0d1be3          	bnez	s10,ffffffffc0207066 <vprintfmt+0x200>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0207074:	6a22                	ld	s4,8(sp)
ffffffffc0207076:	b515                	j	ffffffffc0206e9a <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0207078:	3781                	addiw	a5,a5,-32
ffffffffc020707a:	fcfa7be3          	bgeu	s4,a5,ffffffffc0207050 <vprintfmt+0x1ea>
                    putch('?', putdat);
ffffffffc020707e:	03f00513          	li	a0,63
ffffffffc0207082:	85ca                	mv	a1,s2
ffffffffc0207084:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0207086:	000dc783          	lbu	a5,0(s11)
ffffffffc020708a:	0d85                	addi	s11,s11,1
ffffffffc020708c:	3d7d                	addiw	s10,s10,-1
ffffffffc020708e:	0007851b          	sext.w	a0,a5
ffffffffc0207092:	dbe1                	beqz	a5,ffffffffc0207062 <vprintfmt+0x1fc>
ffffffffc0207094:	fa0cd9e3          	bgez	s9,ffffffffc0207046 <vprintfmt+0x1e0>
ffffffffc0207098:	b7c5                	j	ffffffffc0207078 <vprintfmt+0x212>
            if (err < 0) {
ffffffffc020709a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020709e:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc02070a0:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02070a2:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc02070a6:	8fb9                	xor	a5,a5,a4
ffffffffc02070a8:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02070ac:	02d64563          	blt	a2,a3,ffffffffc02070d6 <vprintfmt+0x270>
ffffffffc02070b0:	00003797          	auipc	a5,0x3
ffffffffc02070b4:	cb078793          	addi	a5,a5,-848 # ffffffffc0209d60 <error_string>
ffffffffc02070b8:	00369713          	slli	a4,a3,0x3
ffffffffc02070bc:	97ba                	add	a5,a5,a4
ffffffffc02070be:	639c                	ld	a5,0(a5)
ffffffffc02070c0:	cb99                	beqz	a5,ffffffffc02070d6 <vprintfmt+0x270>
                printfmt(putch, putdat, "%s", p);
ffffffffc02070c2:	86be                	mv	a3,a5
ffffffffc02070c4:	00003617          	auipc	a2,0x3
ffffffffc02070c8:	95c60613          	addi	a2,a2,-1700 # ffffffffc0209a20 <etext+0x27a4>
ffffffffc02070cc:	85ca                	mv	a1,s2
ffffffffc02070ce:	8526                	mv	a0,s1
ffffffffc02070d0:	0d4000ef          	jal	ffffffffc02071a4 <printfmt>
ffffffffc02070d4:	b3d9                	j	ffffffffc0206e9a <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02070d6:	00003617          	auipc	a2,0x3
ffffffffc02070da:	93a60613          	addi	a2,a2,-1734 # ffffffffc0209a10 <etext+0x2794>
ffffffffc02070de:	85ca                	mv	a1,s2
ffffffffc02070e0:	8526                	mv	a0,s1
ffffffffc02070e2:	0c2000ef          	jal	ffffffffc02071a4 <printfmt>
ffffffffc02070e6:	bb55                	j	ffffffffc0206e9a <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02070e8:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02070ea:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc02070ee:	00f74363          	blt	a4,a5,ffffffffc02070f4 <vprintfmt+0x28e>
    else if (lflag) {
ffffffffc02070f2:	cf81                	beqz	a5,ffffffffc020710a <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc02070f4:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02070f8:	02044b63          	bltz	s0,ffffffffc020712e <vprintfmt+0x2c8>
            num = getint(&ap, lflag);
ffffffffc02070fc:	8622                	mv	a2,s0
ffffffffc02070fe:	8a5e                	mv	s4,s7
ffffffffc0207100:	46a9                	li	a3,10
ffffffffc0207102:	b541                	j	ffffffffc0206f82 <vprintfmt+0x11c>
            lflag ++;
ffffffffc0207104:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0207106:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0207108:	bb6d                	j	ffffffffc0206ec2 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc020710a:	000a2403          	lw	s0,0(s4)
ffffffffc020710e:	b7ed                	j	ffffffffc02070f8 <vprintfmt+0x292>
        return va_arg(*ap, unsigned int);
ffffffffc0207110:	000a6603          	lwu	a2,0(s4)
ffffffffc0207114:	46a1                	li	a3,8
ffffffffc0207116:	8a2e                	mv	s4,a1
ffffffffc0207118:	b5ad                	j	ffffffffc0206f82 <vprintfmt+0x11c>
ffffffffc020711a:	000a6603          	lwu	a2,0(s4)
ffffffffc020711e:	46a9                	li	a3,10
ffffffffc0207120:	8a2e                	mv	s4,a1
ffffffffc0207122:	b585                	j	ffffffffc0206f82 <vprintfmt+0x11c>
ffffffffc0207124:	000a6603          	lwu	a2,0(s4)
ffffffffc0207128:	46c1                	li	a3,16
ffffffffc020712a:	8a2e                	mv	s4,a1
ffffffffc020712c:	bd99                	j	ffffffffc0206f82 <vprintfmt+0x11c>
                putch('-', putdat);
ffffffffc020712e:	85ca                	mv	a1,s2
ffffffffc0207130:	02d00513          	li	a0,45
ffffffffc0207134:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0207136:	40800633          	neg	a2,s0
ffffffffc020713a:	8a5e                	mv	s4,s7
ffffffffc020713c:	46a9                	li	a3,10
ffffffffc020713e:	b591                	j	ffffffffc0206f82 <vprintfmt+0x11c>
            if (width > 0 && padc != '-') {
ffffffffc0207140:	ef1d                	bnez	a4,ffffffffc020717e <vprintfmt+0x318>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0207142:	02800793          	li	a5,40
ffffffffc0207146:	853e                	mv	a0,a5
ffffffffc0207148:	00003d97          	auipc	s11,0x3
ffffffffc020714c:	8c1d8d93          	addi	s11,s11,-1855 # ffffffffc0209a09 <etext+0x278d>
ffffffffc0207150:	b5f5                	j	ffffffffc020703c <vprintfmt+0x1d6>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0207152:	85e6                	mv	a1,s9
ffffffffc0207154:	856e                	mv	a0,s11
ffffffffc0207156:	0a0000ef          	jal	ffffffffc02071f6 <strnlen>
ffffffffc020715a:	40ad0d3b          	subw	s10,s10,a0
ffffffffc020715e:	01a05863          	blez	s10,ffffffffc020716e <vprintfmt+0x308>
                    putch(padc, putdat);
ffffffffc0207162:	85ca                	mv	a1,s2
ffffffffc0207164:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0207166:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0207168:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020716a:	fe0d1ce3          	bnez	s10,ffffffffc0207162 <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020716e:	000dc783          	lbu	a5,0(s11)
ffffffffc0207172:	0007851b          	sext.w	a0,a5
ffffffffc0207176:	ec0792e3          	bnez	a5,ffffffffc020703a <vprintfmt+0x1d4>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020717a:	6a22                	ld	s4,8(sp)
ffffffffc020717c:	bb39                	j	ffffffffc0206e9a <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020717e:	85e6                	mv	a1,s9
ffffffffc0207180:	00003517          	auipc	a0,0x3
ffffffffc0207184:	88850513          	addi	a0,a0,-1912 # ffffffffc0209a08 <etext+0x278c>
ffffffffc0207188:	06e000ef          	jal	ffffffffc02071f6 <strnlen>
ffffffffc020718c:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0207190:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0207194:	00003d97          	auipc	s11,0x3
ffffffffc0207198:	874d8d93          	addi	s11,s11,-1932 # ffffffffc0209a08 <etext+0x278c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020719c:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020719e:	fda042e3          	bgtz	s10,ffffffffc0207162 <vprintfmt+0x2fc>
ffffffffc02071a2:	bd61                	j	ffffffffc020703a <vprintfmt+0x1d4>

ffffffffc02071a4 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02071a4:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02071a6:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02071aa:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02071ac:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02071ae:	ec06                	sd	ra,24(sp)
ffffffffc02071b0:	f83a                	sd	a4,48(sp)
ffffffffc02071b2:	fc3e                	sd	a5,56(sp)
ffffffffc02071b4:	e0c2                	sd	a6,64(sp)
ffffffffc02071b6:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02071b8:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02071ba:	cadff0ef          	jal	ffffffffc0206e66 <vprintfmt>
}
ffffffffc02071be:	60e2                	ld	ra,24(sp)
ffffffffc02071c0:	6161                	addi	sp,sp,80
ffffffffc02071c2:	8082                	ret

ffffffffc02071c4 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02071c4:	00006717          	auipc	a4,0x6
ffffffffc02071c8:	e5473703          	ld	a4,-428(a4) # ffffffffc020d018 <SBI_CONSOLE_PUTCHAR>
ffffffffc02071cc:	4781                	li	a5,0
ffffffffc02071ce:	88ba                	mv	a7,a4
ffffffffc02071d0:	852a                	mv	a0,a0
ffffffffc02071d2:	85be                	mv	a1,a5
ffffffffc02071d4:	863e                	mv	a2,a5
ffffffffc02071d6:	00000073          	ecall
ffffffffc02071da:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02071dc:	8082                	ret

ffffffffc02071de <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02071de:	00054783          	lbu	a5,0(a0)
ffffffffc02071e2:	cb81                	beqz	a5,ffffffffc02071f2 <strlen+0x14>
    size_t cnt = 0;
ffffffffc02071e4:	4781                	li	a5,0
        cnt ++;
ffffffffc02071e6:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc02071e8:	00f50733          	add	a4,a0,a5
ffffffffc02071ec:	00074703          	lbu	a4,0(a4)
ffffffffc02071f0:	fb7d                	bnez	a4,ffffffffc02071e6 <strlen+0x8>
    }
    return cnt;
}
ffffffffc02071f2:	853e                	mv	a0,a5
ffffffffc02071f4:	8082                	ret

ffffffffc02071f6 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02071f6:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02071f8:	e589                	bnez	a1,ffffffffc0207202 <strnlen+0xc>
ffffffffc02071fa:	a811                	j	ffffffffc020720e <strnlen+0x18>
        cnt ++;
ffffffffc02071fc:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02071fe:	00f58863          	beq	a1,a5,ffffffffc020720e <strnlen+0x18>
ffffffffc0207202:	00f50733          	add	a4,a0,a5
ffffffffc0207206:	00074703          	lbu	a4,0(a4)
ffffffffc020720a:	fb6d                	bnez	a4,ffffffffc02071fc <strnlen+0x6>
ffffffffc020720c:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020720e:	852e                	mv	a0,a1
ffffffffc0207210:	8082                	ret

ffffffffc0207212 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0207212:	00054783          	lbu	a5,0(a0)
ffffffffc0207216:	e791                	bnez	a5,ffffffffc0207222 <strcmp+0x10>
ffffffffc0207218:	a015                	j	ffffffffc020723c <strcmp+0x2a>
ffffffffc020721a:	00054783          	lbu	a5,0(a0)
ffffffffc020721e:	cb91                	beqz	a5,ffffffffc0207232 <strcmp+0x20>
ffffffffc0207220:	0585                	addi	a1,a1,1
ffffffffc0207222:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0207226:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0207228:	fef709e3          	beq	a4,a5,ffffffffc020721a <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020722c:	40e7853b          	subw	a0,a5,a4
ffffffffc0207230:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0207232:	0015c703          	lbu	a4,1(a1)
}
ffffffffc0207236:	40e7853b          	subw	a0,a5,a4
ffffffffc020723a:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020723c:	0005c703          	lbu	a4,0(a1)
ffffffffc0207240:	b7f5                	j	ffffffffc020722c <strcmp+0x1a>

ffffffffc0207242 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0207242:	ce01                	beqz	a2,ffffffffc020725a <strncmp+0x18>
ffffffffc0207244:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0207248:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020724a:	cb91                	beqz	a5,ffffffffc020725e <strncmp+0x1c>
ffffffffc020724c:	0005c703          	lbu	a4,0(a1)
ffffffffc0207250:	00f71763          	bne	a4,a5,ffffffffc020725e <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0207254:	0505                	addi	a0,a0,1
ffffffffc0207256:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0207258:	f675                	bnez	a2,ffffffffc0207244 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020725a:	4501                	li	a0,0
ffffffffc020725c:	8082                	ret
ffffffffc020725e:	00054503          	lbu	a0,0(a0)
ffffffffc0207262:	0005c783          	lbu	a5,0(a1)
ffffffffc0207266:	9d1d                	subw	a0,a0,a5
}
ffffffffc0207268:	8082                	ret

ffffffffc020726a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020726a:	ca01                	beqz	a2,ffffffffc020727a <memset+0x10>
ffffffffc020726c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020726e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0207270:	0785                	addi	a5,a5,1
ffffffffc0207272:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0207276:	fef61de3          	bne	a2,a5,ffffffffc0207270 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020727a:	8082                	ret
