
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00008297          	auipc	t0,0x8
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0208000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00008297          	auipc	t0,0x8
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0208008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02072b7          	lui	t0,0xc0207
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
ffffffffc020003c:	c0207137          	lui	sp,0xc0207

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
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0206ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00003517          	auipc	a0,0x3
ffffffffc0200050:	27450513          	addi	a0,a0,628 # ffffffffc02032c0 <etext+0xe>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00003517          	auipc	a0,0x3
ffffffffc0200066:	27e50513          	addi	a0,a0,638 # ffffffffc02032e0 <etext+0x2e>
ffffffffc020006a:	0e2000ef          	jal	ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00003597          	auipc	a1,0x3
ffffffffc0200072:	24458593          	addi	a1,a1,580 # ffffffffc02032b2 <etext>
ffffffffc0200076:	00003517          	auipc	a0,0x3
ffffffffc020007a:	28a50513          	addi	a0,a0,650 # ffffffffc0203300 <etext+0x4e>
ffffffffc020007e:	0ce000ef          	jal	ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00008597          	auipc	a1,0x8
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0208018 <free_area>
ffffffffc020008a:	00003517          	auipc	a0,0x3
ffffffffc020008e:	29650513          	addi	a0,a0,662 # ffffffffc0203320 <etext+0x6e>
ffffffffc0200092:	0ba000ef          	jal	ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00019597          	auipc	a1,0x19
ffffffffc020009a:	76258593          	addi	a1,a1,1890 # ffffffffc02197f8 <end>
ffffffffc020009e:	00003517          	auipc	a0,0x3
ffffffffc02000a2:	2a250513          	addi	a0,a0,674 # ffffffffc0203340 <etext+0x8e>
ffffffffc02000a6:	0a6000ef          	jal	ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00000717          	auipc	a4,0x0
ffffffffc02000ae:	02c70713          	addi	a4,a4,44 # ffffffffc02000d6 <kern_init>
ffffffffc02000b2:	0001a797          	auipc	a5,0x1a
ffffffffc02000b6:	b4578793          	addi	a5,a5,-1211 # ffffffffc0219bf7 <end+0x3ff>
ffffffffc02000ba:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000bc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c6:	95be                	add	a1,a1,a5
ffffffffc02000c8:	85a9                	srai	a1,a1,0xa
ffffffffc02000ca:	00003517          	auipc	a0,0x3
ffffffffc02000ce:	29650513          	addi	a0,a0,662 # ffffffffc0203360 <etext+0xae>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a8a5                	j	ffffffffc020014c <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00008517          	auipc	a0,0x8
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0208018 <free_area>
ffffffffc02000de:	00019617          	auipc	a2,0x19
ffffffffc02000e2:	71a60613          	addi	a2,a2,1818 # ffffffffc02197f8 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	1b2030ef          	jal	ffffffffc02032a0 <memset>
    dtb_init();
ffffffffc02000f2:	13a000ef          	jal	ffffffffc020022c <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	12c000ef          	jal	ffffffffc0200222 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00004517          	auipc	a0,0x4
ffffffffc02000fe:	0de50513          	addi	a0,a0,222 # ffffffffc02041d8 <etext+0xf26>
ffffffffc0200102:	07e000ef          	jal	ffffffffc0200180 <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();   // init physical memory management
ffffffffc020010a:	745000ef          	jal	ffffffffc020104e <pmm_init>
    slub_init();  // init the SLUB object allocator (on top of the page
ffffffffc020010e:	14d020ef          	jal	ffffffffc0202a5a <slub_init>
                  // allocator; prints its own smoke result + fixed overhead)

    /* do nothing */
    while (1)
ffffffffc0200112:	a001                	j	ffffffffc0200112 <kern_init+0x3c>

ffffffffc0200114 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200114:	1101                	addi	sp,sp,-32
ffffffffc0200116:	ec06                	sd	ra,24(sp)
ffffffffc0200118:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc020011a:	10a000ef          	jal	ffffffffc0200224 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	65a2                	ld	a1,8(sp)
}
ffffffffc0200120:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
ffffffffc0200122:	419c                	lw	a5,0(a1)
ffffffffc0200124:	2785                	addiw	a5,a5,1
ffffffffc0200126:	c19c                	sw	a5,0(a1)
}
ffffffffc0200128:	6105                	addi	sp,sp,32
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe250513          	addi	a0,a0,-30 # ffffffffc0200114 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	55d020ef          	jal	ffffffffc0202e9c <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc0200152:	f42e                	sd	a1,40(sp)
ffffffffc0200154:	f832                	sd	a2,48(sp)
ffffffffc0200156:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200158:	862a                	mv	a2,a0
ffffffffc020015a:	004c                	addi	a1,sp,4
ffffffffc020015c:	00000517          	auipc	a0,0x0
ffffffffc0200160:	fb850513          	addi	a0,a0,-72 # ffffffffc0200114 <cputch>
ffffffffc0200164:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc0200166:	ec06                	sd	ra,24(sp)
ffffffffc0200168:	e0ba                	sd	a4,64(sp)
ffffffffc020016a:	e4be                	sd	a5,72(sp)
ffffffffc020016c:	e8c2                	sd	a6,80(sp)
ffffffffc020016e:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc0200170:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200174:	529020ef          	jal	ffffffffc0202e9c <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200178:	60e2                	ld	ra,24(sp)
ffffffffc020017a:	4512                	lw	a0,4(sp)
ffffffffc020017c:	6125                	addi	sp,sp,96
ffffffffc020017e:	8082                	ret

ffffffffc0200180 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200180:	1101                	addi	sp,sp,-32
ffffffffc0200182:	e822                	sd	s0,16(sp)
ffffffffc0200184:	ec06                	sd	ra,24(sp)
ffffffffc0200186:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200188:	00054503          	lbu	a0,0(a0)
ffffffffc020018c:	c51d                	beqz	a0,ffffffffc02001ba <cputs+0x3a>
ffffffffc020018e:	e426                	sd	s1,8(sp)
ffffffffc0200190:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc0200192:	4481                	li	s1,0
    cons_putc(c);
ffffffffc0200194:	090000ef          	jal	ffffffffc0200224 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200198:	00044503          	lbu	a0,0(s0)
ffffffffc020019c:	0405                	addi	s0,s0,1
ffffffffc020019e:	87a6                	mv	a5,s1
    (*cnt) ++;
ffffffffc02001a0:	2485                	addiw	s1,s1,1
    while ((c = *str ++) != '\0') {
ffffffffc02001a2:	f96d                	bnez	a0,ffffffffc0200194 <cputs+0x14>
    cons_putc(c);
ffffffffc02001a4:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001a6:	0027841b          	addiw	s0,a5,2
ffffffffc02001aa:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001ac:	078000ef          	jal	ffffffffc0200224 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b0:	60e2                	ld	ra,24(sp)
ffffffffc02001b2:	8522                	mv	a0,s0
ffffffffc02001b4:	6442                	ld	s0,16(sp)
ffffffffc02001b6:	6105                	addi	sp,sp,32
ffffffffc02001b8:	8082                	ret
    cons_putc(c);
ffffffffc02001ba:	4529                	li	a0,10
ffffffffc02001bc:	068000ef          	jal	ffffffffc0200224 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001c0:	4405                	li	s0,1
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	8522                	mv	a0,s0
ffffffffc02001c6:	6442                	ld	s0,16(sp)
ffffffffc02001c8:	6105                	addi	sp,sp,32
ffffffffc02001ca:	8082                	ret

ffffffffc02001cc <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001cc:	00019317          	auipc	t1,0x19
ffffffffc02001d0:	5a432303          	lw	t1,1444(t1) # ffffffffc0219770 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d4:	715d                	addi	sp,sp,-80
ffffffffc02001d6:	ec06                	sd	ra,24(sp)
ffffffffc02001d8:	f436                	sd	a3,40(sp)
ffffffffc02001da:	f83a                	sd	a4,48(sp)
ffffffffc02001dc:	fc3e                	sd	a5,56(sp)
ffffffffc02001de:	e0c2                	sd	a6,64(sp)
ffffffffc02001e0:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e2:	00030363          	beqz	t1,ffffffffc02001e8 <__panic+0x1c>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e6:	a001                	j	ffffffffc02001e6 <__panic+0x1a>
    is_panic = 1;
ffffffffc02001e8:	4705                	li	a4,1
    va_start(ap, fmt);
ffffffffc02001ea:	103c                	addi	a5,sp,40
ffffffffc02001ec:	e822                	sd	s0,16(sp)
ffffffffc02001ee:	8432                	mv	s0,a2
ffffffffc02001f0:	862e                	mv	a2,a1
ffffffffc02001f2:	85aa                	mv	a1,a0
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f4:	00003517          	auipc	a0,0x3
ffffffffc02001f8:	19c50513          	addi	a0,a0,412 # ffffffffc0203390 <etext+0xde>
    is_panic = 1;
ffffffffc02001fc:	00019697          	auipc	a3,0x19
ffffffffc0200200:	56e6aa23          	sw	a4,1396(a3) # ffffffffc0219770 <is_panic>
    va_start(ap, fmt);
ffffffffc0200204:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200206:	f47ff0ef          	jal	ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc020020a:	65a2                	ld	a1,8(sp)
ffffffffc020020c:	8522                	mv	a0,s0
ffffffffc020020e:	f1fff0ef          	jal	ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200212:	00003517          	auipc	a0,0x3
ffffffffc0200216:	19e50513          	addi	a0,a0,414 # ffffffffc02033b0 <etext+0xfe>
ffffffffc020021a:	f33ff0ef          	jal	ffffffffc020014c <cprintf>
ffffffffc020021e:	6442                	ld	s0,16(sp)
ffffffffc0200220:	b7d9                	j	ffffffffc02001e6 <__panic+0x1a>

ffffffffc0200222 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200222:	8082                	ret

ffffffffc0200224 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200224:	0ff57513          	zext.b	a0,a0
ffffffffc0200228:	7d30206f          	j	ffffffffc02031fa <sbi_console_putchar>

ffffffffc020022c <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020022c:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020022e:	00003517          	auipc	a0,0x3
ffffffffc0200232:	18a50513          	addi	a0,a0,394 # ffffffffc02033b8 <etext+0x106>
void dtb_init(void) {
ffffffffc0200236:	f406                	sd	ra,40(sp)
ffffffffc0200238:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc020023a:	f13ff0ef          	jal	ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023e:	00008597          	auipc	a1,0x8
ffffffffc0200242:	dc25b583          	ld	a1,-574(a1) # ffffffffc0208000 <boot_hartid>
ffffffffc0200246:	00003517          	auipc	a0,0x3
ffffffffc020024a:	18250513          	addi	a0,a0,386 # ffffffffc02033c8 <etext+0x116>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020024e:	00008417          	auipc	s0,0x8
ffffffffc0200252:	dba40413          	addi	s0,s0,-582 # ffffffffc0208008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200256:	ef7ff0ef          	jal	ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025a:	600c                	ld	a1,0(s0)
ffffffffc020025c:	00003517          	auipc	a0,0x3
ffffffffc0200260:	17c50513          	addi	a0,a0,380 # ffffffffc02033d8 <etext+0x126>
ffffffffc0200264:	ee9ff0ef          	jal	ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200268:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020026a:	00003517          	auipc	a0,0x3
ffffffffc020026e:	18650513          	addi	a0,a0,390 # ffffffffc02033f0 <etext+0x13e>
    if (boot_dtb == 0) {
ffffffffc0200272:	10070163          	beqz	a4,ffffffffc0200374 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200276:	57f5                	li	a5,-3
ffffffffc0200278:	07fa                	slli	a5,a5,0x1e
ffffffffc020027a:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020027c:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020027e:	d00e06b7          	lui	a3,0xd00e0
ffffffffc0200282:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfec66f5>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200286:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020028a:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020028e:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200296:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029a:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029c:	8e49                	or	a2,a2,a0
ffffffffc020029e:	0ff7f793          	zext.b	a5,a5
ffffffffc02002a2:	8dd1                	or	a1,a1,a2
ffffffffc02002a4:	07a2                	slli	a5,a5,0x8
ffffffffc02002a6:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a8:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02002ac:	0cd59863          	bne	a1,a3,ffffffffc020037c <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002b0:	4710                	lw	a2,8(a4)
ffffffffc02002b2:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02002b4:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002b6:	0086541b          	srliw	s0,a2,0x8
ffffffffc02002ba:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002be:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02002c2:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c6:	0186151b          	slliw	a0,a2,0x18
ffffffffc02002ca:	0186959b          	slliw	a1,a3,0x18
ffffffffc02002ce:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d2:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d6:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002da:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02002de:	01c56533          	or	a0,a0,t3
ffffffffc02002e2:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e6:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ea:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ee:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f2:	0ff6f693          	zext.b	a3,a3
ffffffffc02002f6:	8c49                	or	s0,s0,a0
ffffffffc02002f8:	0622                	slli	a2,a2,0x8
ffffffffc02002fa:	8fcd                	or	a5,a5,a1
ffffffffc02002fc:	06a2                	slli	a3,a3,0x8
ffffffffc02002fe:	8c51                	or	s0,s0,a2
ffffffffc0200300:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200302:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200304:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200306:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200308:	9381                	srli	a5,a5,0x20
ffffffffc020030a:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc020030c:	4301                	li	t1,0
        switch (token) {
ffffffffc020030e:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200310:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200312:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200316:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200318:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020031a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020031e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200322:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200326:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020032a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200332:	8ed1                	or	a3,a3,a2
ffffffffc0200334:	0ff77713          	zext.b	a4,a4
ffffffffc0200338:	8fd5                	or	a5,a5,a3
ffffffffc020033a:	0722                	slli	a4,a4,0x8
ffffffffc020033c:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc020033e:	05178763          	beq	a5,a7,ffffffffc020038c <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200342:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc0200344:	00f8e963          	bltu	a7,a5,ffffffffc0200356 <dtb_init+0x12a>
ffffffffc0200348:	07c78d63          	beq	a5,t3,ffffffffc02003c2 <dtb_init+0x196>
ffffffffc020034c:	4709                	li	a4,2
ffffffffc020034e:	00e79763          	bne	a5,a4,ffffffffc020035c <dtb_init+0x130>
ffffffffc0200352:	4301                	li	t1,0
ffffffffc0200354:	b7d1                	j	ffffffffc0200318 <dtb_init+0xec>
ffffffffc0200356:	4711                	li	a4,4
ffffffffc0200358:	fce780e3          	beq	a5,a4,ffffffffc0200318 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020035c:	00003517          	auipc	a0,0x3
ffffffffc0200360:	15c50513          	addi	a0,a0,348 # ffffffffc02034b8 <etext+0x206>
ffffffffc0200364:	de9ff0ef          	jal	ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200368:	64e2                	ld	s1,24(sp)
ffffffffc020036a:	6942                	ld	s2,16(sp)
ffffffffc020036c:	00003517          	auipc	a0,0x3
ffffffffc0200370:	18450513          	addi	a0,a0,388 # ffffffffc02034f0 <etext+0x23e>
}
ffffffffc0200374:	7402                	ld	s0,32(sp)
ffffffffc0200376:	70a2                	ld	ra,40(sp)
ffffffffc0200378:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc020037a:	bbc9                	j	ffffffffc020014c <cprintf>
}
ffffffffc020037c:	7402                	ld	s0,32(sp)
ffffffffc020037e:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200380:	00003517          	auipc	a0,0x3
ffffffffc0200384:	09050513          	addi	a0,a0,144 # ffffffffc0203410 <etext+0x15e>
}
ffffffffc0200388:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020038a:	b3c9                	j	ffffffffc020014c <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020038c:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020038e:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200392:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200396:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020039a:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020039e:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02003a2:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003a6:	8ed1                	or	a3,a3,a2
ffffffffc02003a8:	0ff77713          	zext.b	a4,a4
ffffffffc02003ac:	8fd5                	or	a5,a5,a3
ffffffffc02003ae:	0722                	slli	a4,a4,0x8
ffffffffc02003b0:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003b2:	04031463          	bnez	t1,ffffffffc02003fa <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02003b6:	1782                	slli	a5,a5,0x20
ffffffffc02003b8:	9381                	srli	a5,a5,0x20
ffffffffc02003ba:	043d                	addi	s0,s0,15
ffffffffc02003bc:	943e                	add	s0,s0,a5
ffffffffc02003be:	9871                	andi	s0,s0,-4
                break;
ffffffffc02003c0:	bfa1                	j	ffffffffc0200318 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02003c2:	8522                	mv	a0,s0
ffffffffc02003c4:	e01a                	sd	t1,0(sp)
ffffffffc02003c6:	64f020ef          	jal	ffffffffc0203214 <strlen>
ffffffffc02003ca:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003cc:	4619                	li	a2,6
ffffffffc02003ce:	8522                	mv	a0,s0
ffffffffc02003d0:	00003597          	auipc	a1,0x3
ffffffffc02003d4:	06858593          	addi	a1,a1,104 # ffffffffc0203438 <etext+0x186>
ffffffffc02003d8:	6a1020ef          	jal	ffffffffc0203278 <strncmp>
ffffffffc02003dc:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003de:	0411                	addi	s0,s0,4
ffffffffc02003e0:	0004879b          	sext.w	a5,s1
ffffffffc02003e4:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e6:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003ea:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003ec:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02003f0:	00ff0837          	lui	a6,0xff0
ffffffffc02003f4:	488d                	li	a7,3
ffffffffc02003f6:	4e05                	li	t3,1
ffffffffc02003f8:	b705                	j	ffffffffc0200318 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003fa:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003fc:	00003597          	auipc	a1,0x3
ffffffffc0200400:	04458593          	addi	a1,a1,68 # ffffffffc0203440 <etext+0x18e>
ffffffffc0200404:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200406:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020040a:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020040e:	0187169b          	slliw	a3,a4,0x18
ffffffffc0200412:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200416:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020041a:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	8ed1                	or	a3,a3,a2
ffffffffc0200420:	0ff77713          	zext.b	a4,a4
ffffffffc0200424:	0722                	slli	a4,a4,0x8
ffffffffc0200426:	8d55                	or	a0,a0,a3
ffffffffc0200428:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020042a:	1502                	slli	a0,a0,0x20
ffffffffc020042c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020042e:	954a                	add	a0,a0,s2
ffffffffc0200430:	e01a                	sd	t1,0(sp)
ffffffffc0200432:	617020ef          	jal	ffffffffc0203248 <strcmp>
ffffffffc0200436:	67a2                	ld	a5,8(sp)
ffffffffc0200438:	473d                	li	a4,15
ffffffffc020043a:	6302                	ld	t1,0(sp)
ffffffffc020043c:	00ff0837          	lui	a6,0xff0
ffffffffc0200440:	488d                	li	a7,3
ffffffffc0200442:	4e05                	li	t3,1
ffffffffc0200444:	f6f779e3          	bgeu	a4,a5,ffffffffc02003b6 <dtb_init+0x18a>
ffffffffc0200448:	f53d                	bnez	a0,ffffffffc02003b6 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020044a:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020044e:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200452:	00003517          	auipc	a0,0x3
ffffffffc0200456:	ff650513          	addi	a0,a0,-10 # ffffffffc0203448 <etext+0x196>
           fdt32_to_cpu(x >> 32);
ffffffffc020045a:	0206d793          	srli	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020045e:	0087d31b          	srliw	t1,a5,0x8
ffffffffc0200462:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200466:	02075893          	srli	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020046a:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046e:	0187959b          	slliw	a1,a5,0x18
ffffffffc0200472:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200476:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200482:	01037333          	and	t1,t1,a6
ffffffffc0200486:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020048a:	01e5e5b3          	or	a1,a1,t5
ffffffffc020048e:	0ff7f793          	zext.b	a5,a5
ffffffffc0200492:	01de6e33          	or	t3,t3,t4
ffffffffc0200496:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020049a:	01067633          	and	a2,a2,a6
ffffffffc020049e:	0086d31b          	srliw	t1,a3,0x8
ffffffffc02004a2:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a6:	07a2                	slli	a5,a5,0x8
ffffffffc02004a8:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02004ac:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02004b0:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02004b4:	8ddd                	or	a1,a1,a5
ffffffffc02004b6:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ba:	0186979b          	slliw	a5,a3,0x18
ffffffffc02004be:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c2:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c6:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ca:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ce:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d2:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d6:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004da:	08a2                	slli	a7,a7,0x8
ffffffffc02004dc:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e0:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e4:	0ff6f693          	zext.b	a3,a3
ffffffffc02004e8:	01de6833          	or	a6,t3,t4
ffffffffc02004ec:	0ff77713          	zext.b	a4,a4
ffffffffc02004f0:	01166633          	or	a2,a2,a7
ffffffffc02004f4:	0067e7b3          	or	a5,a5,t1
ffffffffc02004f8:	06a2                	slli	a3,a3,0x8
ffffffffc02004fa:	01046433          	or	s0,s0,a6
ffffffffc02004fe:	0722                	slli	a4,a4,0x8
ffffffffc0200500:	8fd5                	or	a5,a5,a3
ffffffffc0200502:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200504:	1582                	slli	a1,a1,0x20
ffffffffc0200506:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200508:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020050a:	9201                	srli	a2,a2,0x20
ffffffffc020050c:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020050e:	1402                	slli	s0,s0,0x20
ffffffffc0200510:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200514:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200516:	c37ff0ef          	jal	ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020051a:	85a6                	mv	a1,s1
ffffffffc020051c:	00003517          	auipc	a0,0x3
ffffffffc0200520:	f4c50513          	addi	a0,a0,-180 # ffffffffc0203468 <etext+0x1b6>
ffffffffc0200524:	c29ff0ef          	jal	ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200528:	01445613          	srli	a2,s0,0x14
ffffffffc020052c:	85a2                	mv	a1,s0
ffffffffc020052e:	00003517          	auipc	a0,0x3
ffffffffc0200532:	f5250513          	addi	a0,a0,-174 # ffffffffc0203480 <etext+0x1ce>
ffffffffc0200536:	c17ff0ef          	jal	ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020053a:	009405b3          	add	a1,s0,s1
ffffffffc020053e:	15fd                	addi	a1,a1,-1
ffffffffc0200540:	00003517          	auipc	a0,0x3
ffffffffc0200544:	f6050513          	addi	a0,a0,-160 # ffffffffc02034a0 <etext+0x1ee>
ffffffffc0200548:	c05ff0ef          	jal	ffffffffc020014c <cprintf>
        memory_base = mem_base;
ffffffffc020054c:	00019797          	auipc	a5,0x19
ffffffffc0200550:	2297ba23          	sd	s1,564(a5) # ffffffffc0219780 <memory_base>
        memory_size = mem_size;
ffffffffc0200554:	00019797          	auipc	a5,0x19
ffffffffc0200558:	2287b223          	sd	s0,548(a5) # ffffffffc0219778 <memory_size>
ffffffffc020055c:	b531                	j	ffffffffc0200368 <dtb_init+0x13c>

ffffffffc020055e <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020055e:	00019517          	auipc	a0,0x19
ffffffffc0200562:	22253503          	ld	a0,546(a0) # ffffffffc0219780 <memory_base>
ffffffffc0200566:	8082                	ret

ffffffffc0200568 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200568:	00019517          	auipc	a0,0x19
ffffffffc020056c:	21053503          	ld	a0,528(a0) # ffffffffc0219778 <memory_size>
ffffffffc0200570:	8082                	ret

ffffffffc0200572 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200572:	00008797          	auipc	a5,0x8
ffffffffc0200576:	aa678793          	addi	a5,a5,-1370 # ffffffffc0208018 <free_area>
ffffffffc020057a:	e79c                	sd	a5,8(a5)
ffffffffc020057c:	e39c                	sd	a5,0(a5)

static void
best_fit_init(void) {
    // 1. initialize manager state before page_init() registers free memory.
    list_init(&free_list);
    nr_free = 0;
ffffffffc020057e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200582:	8082                	ret

ffffffffc0200584 <best_fit_nr_free_pages>:

static size_t
best_fit_nr_free_pages(void) {
    // Return the number of free pages, rather than the number of free blocks.
    return nr_free;
}
ffffffffc0200584:	00008517          	auipc	a0,0x8
ffffffffc0200588:	aa456503          	lwu	a0,-1372(a0) # ffffffffc0208028 <free_area+0x10>
ffffffffc020058c:	8082                	ret

ffffffffc020058e <best_fit_insert_block>:
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020058e:	00008697          	auipc	a3,0x8
ffffffffc0200592:	a8a68693          	addi	a3,a3,-1398 # ffffffffc0208018 <free_area>
ffffffffc0200596:	669c                	ld	a5,8(a3)
best_fit_insert_block(struct Page *base, size_t n) {
ffffffffc0200598:	1141                	addi	sp,sp,-16
ffffffffc020059a:	e406                	sd	ra,8(sp)
    while (next != &free_list && le2page(next, page_link) < base) {
ffffffffc020059c:	00d79663          	bne	a5,a3,ffffffffc02005a8 <best_fit_insert_block+0x1a>
ffffffffc02005a0:	a8fd                	j	ffffffffc020069e <best_fit_insert_block+0x110>
ffffffffc02005a2:	679c                	ld	a5,8(a5)
ffffffffc02005a4:	0cd78463          	beq	a5,a3,ffffffffc020066c <best_fit_insert_block+0xde>
ffffffffc02005a8:	fe878713          	addi	a4,a5,-24
ffffffffc02005ac:	fea76be3          	bltu	a4,a0,ffffffffc02005a2 <best_fit_insert_block+0x14>
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc02005b0:	6398                	ld	a4,0(a5)
    if (prev != &free_list) {
ffffffffc02005b2:	00d70c63          	beq	a4,a3,ffffffffc02005ca <best_fit_insert_block+0x3c>
        assert(p + p->property <= base);
ffffffffc02005b6:	ff876803          	lwu	a6,-8(a4)
ffffffffc02005ba:	00281613          	slli	a2,a6,0x2
ffffffffc02005be:	9642                	add	a2,a2,a6
ffffffffc02005c0:	060e                	slli	a2,a2,0x3
ffffffffc02005c2:	1621                	addi	a2,a2,-24
ffffffffc02005c4:	963a                	add	a2,a2,a4
ffffffffc02005c6:	0ec56963          	bltu	a0,a2,ffffffffc02006b8 <best_fit_insert_block+0x12a>
    if (next != &free_list) {
ffffffffc02005ca:	00d78b63          	beq	a5,a3,ffffffffc02005e0 <best_fit_insert_block+0x52>
        assert(base + n <= le2page(next, page_link));
ffffffffc02005ce:	00259613          	slli	a2,a1,0x2
ffffffffc02005d2:	962e                	add	a2,a2,a1
ffffffffc02005d4:	060e                	slli	a2,a2,0x3
ffffffffc02005d6:	962a                	add	a2,a2,a0
ffffffffc02005d8:	fe878813          	addi	a6,a5,-24
ffffffffc02005dc:	10c86d63          	bltu	a6,a2,ffffffffc02006f6 <best_fit_insert_block+0x168>
    SetPageProperty(base);
ffffffffc02005e0:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc02005e4:	00008617          	auipc	a2,0x8
ffffffffc02005e8:	a4462603          	lw	a2,-1468(a2) # ffffffffc0208028 <free_area+0x10>
    base->property = n;
ffffffffc02005ec:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02005ee:	0028e813          	ori	a6,a7,2
ffffffffc02005f2:	01053423          	sd	a6,8(a0)
    list_add_before(next, &base->page_link);
ffffffffc02005f6:	01850813          	addi	a6,a0,24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02005fa:	0107b023          	sd	a6,0(a5)
ffffffffc02005fe:	01073423          	sd	a6,8(a4)
    nr_free += n;
ffffffffc0200602:	9e2d                	addw	a2,a2,a1
    elm->next = next;
ffffffffc0200604:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200606:	ed18                	sd	a4,24(a0)
ffffffffc0200608:	ca90                	sw	a2,16(a3)
    if (prev != &free_list) {
ffffffffc020060a:	02d70163          	beq	a4,a3,ffffffffc020062c <best_fit_insert_block+0x9e>
        if (p + p->property == base) {
ffffffffc020060e:	ff872303          	lw	t1,-8(a4)
        struct Page *p = le2page(prev, page_link);
ffffffffc0200612:	fe870e13          	addi	t3,a4,-24
        if (p + p->property == base) {
ffffffffc0200616:	02031813          	slli	a6,t1,0x20
ffffffffc020061a:	02085813          	srli	a6,a6,0x20
ffffffffc020061e:	00281613          	slli	a2,a6,0x2
ffffffffc0200622:	9642                	add	a2,a2,a6
ffffffffc0200624:	060e                	slli	a2,a2,0x3
ffffffffc0200626:	9672                	add	a2,a2,t3
ffffffffc0200628:	02c50463          	beq	a0,a2,ffffffffc0200650 <best_fit_insert_block+0xc2>
    if (next != &free_list) {
ffffffffc020062c:	00d78f63          	beq	a5,a3,ffffffffc020064a <best_fit_insert_block+0xbc>
        if (base + base->property == p) {
ffffffffc0200630:	490c                	lw	a1,16(a0)
        struct Page *p = le2page(next, page_link);
ffffffffc0200632:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0200636:	02059613          	slli	a2,a1,0x20
ffffffffc020063a:	9201                	srli	a2,a2,0x20
ffffffffc020063c:	00261713          	slli	a4,a2,0x2
ffffffffc0200640:	9732                	add	a4,a4,a2
ffffffffc0200642:	070e                	slli	a4,a4,0x3
ffffffffc0200644:	972a                	add	a4,a4,a0
ffffffffc0200646:	02d70763          	beq	a4,a3,ffffffffc0200674 <best_fit_insert_block+0xe6>
}
ffffffffc020064a:	60a2                	ld	ra,8(sp)
ffffffffc020064c:	0141                	addi	sp,sp,16
ffffffffc020064e:	8082                	ret
            p->property += base->property;
ffffffffc0200650:	0065833b          	addw	t1,a1,t1
ffffffffc0200654:	fe672c23          	sw	t1,-8(a4)
            ClearPageProperty(base);
ffffffffc0200658:	ffd8f893          	andi	a7,a7,-3
ffffffffc020065c:	01153423          	sd	a7,8(a0)
            base->property = 0;
ffffffffc0200660:	00052823          	sw	zero,16(a0)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200664:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200666:	e398                	sd	a4,0(a5)
            base = p;
ffffffffc0200668:	8572                	mv	a0,t3
ffffffffc020066a:	b7c9                	j	ffffffffc020062c <best_fit_insert_block+0x9e>
    return listelm->prev;
ffffffffc020066c:	6398                	ld	a4,0(a5)
    if (prev != &free_list) {
ffffffffc020066e:	f4f714e3          	bne	a4,a5,ffffffffc02005b6 <best_fit_insert_block+0x28>
ffffffffc0200672:	b7bd                	j	ffffffffc02005e0 <best_fit_insert_block+0x52>
            base->property += p->property;
ffffffffc0200674:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200678:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020067c:	0007b803          	ld	a6,0(a5)
ffffffffc0200680:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200682:	9ead                	addw	a3,a3,a1
ffffffffc0200684:	c914                	sw	a3,16(a0)
            ClearPageProperty(p);
ffffffffc0200686:	9b75                	andi	a4,a4,-3
            p->property = 0;
ffffffffc0200688:	fe07ac23          	sw	zero,-8(a5)
            ClearPageProperty(p);
ffffffffc020068c:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0200690:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200692:	00c83423          	sd	a2,8(a6) # ff0008 <kern_entry-0xffffffffbf20fff8>
    next->prev = prev;
ffffffffc0200696:	01063023          	sd	a6,0(a2)
ffffffffc020069a:	0141                	addi	sp,sp,16
ffffffffc020069c:	8082                	ret
    return listelm->prev;
ffffffffc020069e:	6398                	ld	a4,0(a5)
    if (prev != &free_list) {
ffffffffc02006a0:	02f70c63          	beq	a4,a5,ffffffffc02006d8 <best_fit_insert_block+0x14a>
        assert(p + p->property <= base);
ffffffffc02006a4:	ff876803          	lwu	a6,-8(a4)
ffffffffc02006a8:	00281613          	slli	a2,a6,0x2
ffffffffc02006ac:	9642                	add	a2,a2,a6
ffffffffc02006ae:	060e                	slli	a2,a2,0x3
ffffffffc02006b0:	1621                	addi	a2,a2,-24
ffffffffc02006b2:	963a                	add	a2,a2,a4
ffffffffc02006b4:	f2c576e3          	bgeu	a0,a2,ffffffffc02005e0 <best_fit_insert_block+0x52>
ffffffffc02006b8:	00003697          	auipc	a3,0x3
ffffffffc02006bc:	e5068693          	addi	a3,a3,-432 # ffffffffc0203508 <etext+0x256>
ffffffffc02006c0:	00003617          	auipc	a2,0x3
ffffffffc02006c4:	e6060613          	addi	a2,a2,-416 # ffffffffc0203520 <etext+0x26e>
ffffffffc02006c8:	02800593          	li	a1,40
ffffffffc02006cc:	00003517          	auipc	a0,0x3
ffffffffc02006d0:	e6c50513          	addi	a0,a0,-404 # ffffffffc0203538 <etext+0x286>
ffffffffc02006d4:	af9ff0ef          	jal	ffffffffc02001cc <__panic>
    SetPageProperty(base);
ffffffffc02006d8:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc02006da:	4b98                	lw	a4,16(a5)
    base->property = n;
ffffffffc02006dc:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02006de:	00266613          	ori	a2,a2,2
ffffffffc02006e2:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc02006e4:	9f2d                	addw	a4,a4,a1
    list_add_before(next, &base->page_link);
ffffffffc02006e6:	01850613          	addi	a2,a0,24
    elm->next = next;
ffffffffc02006ea:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02006ec:	ed1c                	sd	a5,24(a0)
    nr_free += n;
ffffffffc02006ee:	cb98                	sw	a4,16(a5)
    prev->next = next->prev = elm;
ffffffffc02006f0:	e390                	sd	a2,0(a5)
ffffffffc02006f2:	e790                	sd	a2,8(a5)
    if (prev != &free_list) {
ffffffffc02006f4:	bf25                	j	ffffffffc020062c <best_fit_insert_block+0x9e>
        assert(base + n <= le2page(next, page_link));
ffffffffc02006f6:	00003697          	auipc	a3,0x3
ffffffffc02006fa:	e5a68693          	addi	a3,a3,-422 # ffffffffc0203550 <etext+0x29e>
ffffffffc02006fe:	00003617          	auipc	a2,0x3
ffffffffc0200702:	e2260613          	addi	a2,a2,-478 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200706:	02b00593          	li	a1,43
ffffffffc020070a:	00003517          	auipc	a0,0x3
ffffffffc020070e:	e2e50513          	addi	a0,a0,-466 # ffffffffc0203538 <etext+0x286>
ffffffffc0200712:	abbff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200716 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200716:	c16d                	beqz	a0,ffffffffc02007f8 <best_fit_alloc_pages+0xe2>
    if (n > nr_free) {
ffffffffc0200718:	00008897          	auipc	a7,0x8
ffffffffc020071c:	9108a883          	lw	a7,-1776(a7) # ffffffffc0208028 <free_area+0x10>
ffffffffc0200720:	862a                	mv	a2,a0
ffffffffc0200722:	00008597          	auipc	a1,0x8
ffffffffc0200726:	8f658593          	addi	a1,a1,-1802 # ffffffffc0208018 <free_area>
ffffffffc020072a:	02089793          	slli	a5,a7,0x20
ffffffffc020072e:	9381                	srli	a5,a5,0x20
ffffffffc0200730:	0ca7e263          	bltu	a5,a0,ffffffffc02007f4 <best_fit_alloc_pages+0xde>
    return listelm->next;
ffffffffc0200734:	659c                	ld	a5,8(a1)
    struct Page *page = NULL;
ffffffffc0200736:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200738:	06b78463          	beq	a5,a1,ffffffffc02007a0 <best_fit_alloc_pages+0x8a>
        if (p->property >= n &&
ffffffffc020073c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200740:	02071693          	slli	a3,a4,0x20
ffffffffc0200744:	9281                	srli	a3,a3,0x20
ffffffffc0200746:	04c6e963          	bltu	a3,a2,ffffffffc0200798 <best_fit_alloc_pages+0x82>
ffffffffc020074a:	e90d                	bnez	a0,ffffffffc020077c <best_fit_alloc_pages+0x66>
        struct Page *p = le2page(le, page_link);
ffffffffc020074c:	fe878513          	addi	a0,a5,-24
            if (p->property == n) {
ffffffffc0200750:	04d60963          	beq	a2,a3,ffffffffc02007a2 <best_fit_alloc_pages+0x8c>
ffffffffc0200754:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200756:	04b78663          	beq	a5,a1,ffffffffc02007a2 <best_fit_alloc_pages+0x8c>
        if (p->property >= n &&
ffffffffc020075a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020075e:	02071693          	slli	a3,a4,0x20
ffffffffc0200762:	9281                	srli	a3,a3,0x20
ffffffffc0200764:	00c6fc63          	bgeu	a3,a2,ffffffffc020077c <best_fit_alloc_pages+0x66>
ffffffffc0200768:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020076a:	02b78a63          	beq	a5,a1,ffffffffc020079e <best_fit_alloc_pages+0x88>
        if (p->property >= n &&
ffffffffc020076e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200772:	02071693          	slli	a3,a4,0x20
ffffffffc0200776:	9281                	srli	a3,a3,0x20
ffffffffc0200778:	02c6e063          	bltu	a3,a2,ffffffffc0200798 <best_fit_alloc_pages+0x82>
            (page == NULL || p->property < page->property)) {
ffffffffc020077c:	01052803          	lw	a6,16(a0)
ffffffffc0200780:	fd0766e3          	bltu	a4,a6,ffffffffc020074c <best_fit_alloc_pages+0x36>
ffffffffc0200784:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200786:	00b78c63          	beq	a5,a1,ffffffffc020079e <best_fit_alloc_pages+0x88>
        if (p->property >= n &&
ffffffffc020078a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020078e:	02071693          	slli	a3,a4,0x20
ffffffffc0200792:	9281                	srli	a3,a3,0x20
ffffffffc0200794:	fec6f6e3          	bgeu	a3,a2,ffffffffc0200780 <best_fit_alloc_pages+0x6a>
ffffffffc0200798:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020079a:	fab791e3          	bne	a5,a1,ffffffffc020073c <best_fit_alloc_pages+0x26>
    if (page != NULL) {
ffffffffc020079e:	e111                	bnez	a0,ffffffffc02007a2 <best_fit_alloc_pages+0x8c>
}
ffffffffc02007a0:	8082                	ret
    return listelm->prev;
ffffffffc02007a2:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc02007a4:	7114                	ld	a3,32(a0)
        ClearPageProperty(page);
ffffffffc02007a6:	651c                	ld	a5,8(a0)
        size_t remaining = page->property - n;
ffffffffc02007a8:	01056803          	lwu	a6,16(a0)
    prev->next = next;
ffffffffc02007ac:	e714                	sd	a3,8(a4)
    next->prev = prev;
ffffffffc02007ae:	e298                	sd	a4,0(a3)
        ClearPageProperty(page);
ffffffffc02007b0:	9bf5                	andi	a5,a5,-3
        page->property = 0;
ffffffffc02007b2:	00052823          	sw	zero,16(a0)
        ClearPageProperty(page);
ffffffffc02007b6:	e51c                	sd	a5,8(a0)
        size_t remaining = page->property - n;
ffffffffc02007b8:	40c80333          	sub	t1,a6,a2
        if (remaining > 0) {
ffffffffc02007bc:	02c80763          	beq	a6,a2,ffffffffc02007ea <best_fit_alloc_pages+0xd4>
            struct Page *p = page + n;
ffffffffc02007c0:	00261793          	slli	a5,a2,0x2
ffffffffc02007c4:	97b2                	add	a5,a5,a2
ffffffffc02007c6:	078e                	slli	a5,a5,0x3
ffffffffc02007c8:	97aa                	add	a5,a5,a0
            SetPageProperty(p);
ffffffffc02007ca:	0087b803          	ld	a6,8(a5)
            p->property = remaining;
ffffffffc02007ce:	0067a823          	sw	t1,16(a5)
            list_add(prev, &p->page_link);
ffffffffc02007d2:	01878313          	addi	t1,a5,24
            SetPageProperty(p);
ffffffffc02007d6:	00286813          	ori	a6,a6,2
ffffffffc02007da:	0107b423          	sd	a6,8(a5)
    prev->next = next->prev = elm;
ffffffffc02007de:	0066b023          	sd	t1,0(a3)
ffffffffc02007e2:	00673423          	sd	t1,8(a4)
    elm->next = next;
ffffffffc02007e6:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc02007e8:	ef98                	sd	a4,24(a5)
        nr_free -= n;
ffffffffc02007ea:	40c888bb          	subw	a7,a7,a2
ffffffffc02007ee:	0115a823          	sw	a7,16(a1)
ffffffffc02007f2:	8082                	ret
    return page;
ffffffffc02007f4:	4501                	li	a0,0
ffffffffc02007f6:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc02007f8:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02007fa:	00003697          	auipc	a3,0x3
ffffffffc02007fe:	d7e68693          	addi	a3,a3,-642 # ffffffffc0203578 <etext+0x2c6>
ffffffffc0200802:	00003617          	auipc	a2,0x3
ffffffffc0200806:	d1e60613          	addi	a2,a2,-738 # ffffffffc0203520 <etext+0x26e>
ffffffffc020080a:	06a00593          	li	a1,106
ffffffffc020080e:	00003517          	auipc	a0,0x3
ffffffffc0200812:	d2a50513          	addi	a0,a0,-726 # ffffffffc0203538 <etext+0x286>
best_fit_alloc_pages(size_t n) {
ffffffffc0200816:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200818:	9b5ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc020081c <best_fit_check>:
    free_page(p1);
    free_page(p2);
}

static void
best_fit_check(void) {
ffffffffc020081c:	711d                	addi	sp,sp,-96
ffffffffc020081e:	e0ca                	sd	s2,64(sp)
    return listelm->next;
ffffffffc0200820:	00007917          	auipc	s2,0x7
ffffffffc0200824:	7f890913          	addi	s2,s2,2040 # ffffffffc0208018 <free_area>
ffffffffc0200828:	00893783          	ld	a5,8(s2)
ffffffffc020082c:	ec86                	sd	ra,88(sp)
ffffffffc020082e:	e8a2                	sd	s0,80(sp)
ffffffffc0200830:	e4a6                	sd	s1,72(sp)
ffffffffc0200832:	fc4e                	sd	s3,56(sp)
ffffffffc0200834:	f852                	sd	s4,48(sp)
ffffffffc0200836:	f456                	sd	s5,40(sp)
ffffffffc0200838:	f05a                	sd	s6,32(sp)
ffffffffc020083a:	ec5e                	sd	s7,24(sp)
ffffffffc020083c:	e862                	sd	s8,16(sp)
ffffffffc020083e:	e466                	sd	s9,8(sp)
    int score = 0, sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200840:	2b278f63          	beq	a5,s2,ffffffffc0200afe <best_fit_check+0x2e2>
    int count = 0, total = 0;
ffffffffc0200844:	4401                	li	s0,0
ffffffffc0200846:	4481                	li	s1,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200848:	ff07b703          	ld	a4,-16(a5)
ffffffffc020084c:	8b09                	andi	a4,a4,2
ffffffffc020084e:	2a070c63          	beqz	a4,ffffffffc0200b06 <best_fit_check+0x2ea>
        count++, total += p->property;
ffffffffc0200852:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200856:	679c                	ld	a5,8(a5)
ffffffffc0200858:	2485                	addiw	s1,s1,1
ffffffffc020085a:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020085c:	ff2796e3          	bne	a5,s2,ffffffffc0200848 <best_fit_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200860:	89a2                	mv	s3,s0
ffffffffc0200862:	7e0000ef          	jal	ffffffffc0201042 <nr_free_pages>
ffffffffc0200866:	39351063          	bne	a0,s3,ffffffffc0200be6 <best_fit_check+0x3ca>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020086a:	4505                	li	a0,1
ffffffffc020086c:	7be000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc0200870:	8aaa                	mv	s5,a0
ffffffffc0200872:	3a050a63          	beqz	a0,ffffffffc0200c26 <best_fit_check+0x40a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200876:	4505                	li	a0,1
ffffffffc0200878:	7b2000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc020087c:	89aa                	mv	s3,a0
ffffffffc020087e:	38050463          	beqz	a0,ffffffffc0200c06 <best_fit_check+0x3ea>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200882:	4505                	li	a0,1
ffffffffc0200884:	7a6000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc0200888:	8a2a                	mv	s4,a0
ffffffffc020088a:	30050e63          	beqz	a0,ffffffffc0200ba6 <best_fit_check+0x38a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020088e:	40aa87b3          	sub	a5,s5,a0
ffffffffc0200892:	40a98733          	sub	a4,s3,a0
ffffffffc0200896:	0017b793          	seqz	a5,a5
ffffffffc020089a:	00173713          	seqz	a4,a4
ffffffffc020089e:	8fd9                	or	a5,a5,a4
ffffffffc02008a0:	2e079363          	bnez	a5,ffffffffc0200b86 <best_fit_check+0x36a>
ffffffffc02008a4:	2f3a8163          	beq	s5,s3,ffffffffc0200b86 <best_fit_check+0x36a>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02008a8:	000aa783          	lw	a5,0(s5)
ffffffffc02008ac:	26079d63          	bnez	a5,ffffffffc0200b26 <best_fit_check+0x30a>
ffffffffc02008b0:	0009a783          	lw	a5,0(s3)
ffffffffc02008b4:	26079963          	bnez	a5,ffffffffc0200b26 <best_fit_check+0x30a>
ffffffffc02008b8:	411c                	lw	a5,0(a0)
ffffffffc02008ba:	26079663          	bnez	a5,ffffffffc0200b26 <best_fit_check+0x30a>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02008be:	00019797          	auipc	a5,0x19
ffffffffc02008c2:	ef27b783          	ld	a5,-270(a5) # ffffffffc02197b0 <pages>
ffffffffc02008c6:	ccccd737          	lui	a4,0xccccd
ffffffffc02008ca:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcab34d5>
ffffffffc02008ce:	02071693          	slli	a3,a4,0x20
ffffffffc02008d2:	96ba                	add	a3,a3,a4
ffffffffc02008d4:	40fa8733          	sub	a4,s5,a5
ffffffffc02008d8:	870d                	srai	a4,a4,0x3
ffffffffc02008da:	02d70733          	mul	a4,a4,a3
ffffffffc02008de:	00004517          	auipc	a0,0x4
ffffffffc02008e2:	b2253503          	ld	a0,-1246(a0) # ffffffffc0204400 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02008e6:	00019697          	auipc	a3,0x19
ffffffffc02008ea:	ec26b683          	ld	a3,-318(a3) # ffffffffc02197a8 <npage>
ffffffffc02008ee:	06b2                	slli	a3,a3,0xc
ffffffffc02008f0:	972a                	add	a4,a4,a0

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc02008f2:	0732                	slli	a4,a4,0xc
ffffffffc02008f4:	26d77963          	bgeu	a4,a3,ffffffffc0200b66 <best_fit_check+0x34a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02008f8:	ccccd5b7          	lui	a1,0xccccd
ffffffffc02008fc:	ccd58593          	addi	a1,a1,-819 # ffffffffcccccccd <end+0xcab34d5>
ffffffffc0200900:	02059613          	slli	a2,a1,0x20
ffffffffc0200904:	40f98733          	sub	a4,s3,a5
ffffffffc0200908:	962e                	add	a2,a2,a1
ffffffffc020090a:	870d                	srai	a4,a4,0x3
ffffffffc020090c:	02c70733          	mul	a4,a4,a2
ffffffffc0200910:	972a                	add	a4,a4,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200912:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200914:	40d77963          	bgeu	a4,a3,ffffffffc0200d26 <best_fit_check+0x50a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200918:	40fa07b3          	sub	a5,s4,a5
ffffffffc020091c:	878d                	srai	a5,a5,0x3
ffffffffc020091e:	02c787b3          	mul	a5,a5,a2
ffffffffc0200922:	97aa                	add	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200924:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200926:	3ed7f063          	bgeu	a5,a3,ffffffffc0200d06 <best_fit_check+0x4ea>
    assert(alloc_page() == NULL);
ffffffffc020092a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020092c:	00093c03          	ld	s8,0(s2)
ffffffffc0200930:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200934:	00007b17          	auipc	s6,0x7
ffffffffc0200938:	6f4b2b03          	lw	s6,1780(s6) # ffffffffc0208028 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc020093c:	01293023          	sd	s2,0(s2)
ffffffffc0200940:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0200944:	00007797          	auipc	a5,0x7
ffffffffc0200948:	6e07a223          	sw	zero,1764(a5) # ffffffffc0208028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc020094c:	6de000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc0200950:	38051b63          	bnez	a0,ffffffffc0200ce6 <best_fit_check+0x4ca>
    free_page(p0);
ffffffffc0200954:	8556                	mv	a0,s5
ffffffffc0200956:	4585                	li	a1,1
ffffffffc0200958:	6de000ef          	jal	ffffffffc0201036 <free_pages>
    free_page(p1);
ffffffffc020095c:	854e                	mv	a0,s3
ffffffffc020095e:	4585                	li	a1,1
ffffffffc0200960:	6d6000ef          	jal	ffffffffc0201036 <free_pages>
    free_page(p2);
ffffffffc0200964:	8552                	mv	a0,s4
ffffffffc0200966:	4585                	li	a1,1
ffffffffc0200968:	6ce000ef          	jal	ffffffffc0201036 <free_pages>
    assert(nr_free == 3);
ffffffffc020096c:	00007717          	auipc	a4,0x7
ffffffffc0200970:	6bc72703          	lw	a4,1724(a4) # ffffffffc0208028 <free_area+0x10>
ffffffffc0200974:	478d                	li	a5,3
ffffffffc0200976:	34f71863          	bne	a4,a5,ffffffffc0200cc6 <best_fit_check+0x4aa>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020097a:	4505                	li	a0,1
ffffffffc020097c:	6ae000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc0200980:	89aa                	mv	s3,a0
ffffffffc0200982:	32050263          	beqz	a0,ffffffffc0200ca6 <best_fit_check+0x48a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200986:	4505                	li	a0,1
ffffffffc0200988:	6a2000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc020098c:	8aaa                	mv	s5,a0
ffffffffc020098e:	2e050c63          	beqz	a0,ffffffffc0200c86 <best_fit_check+0x46a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200992:	4505                	li	a0,1
ffffffffc0200994:	696000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc0200998:	8a2a                	mv	s4,a0
ffffffffc020099a:	2c050663          	beqz	a0,ffffffffc0200c66 <best_fit_check+0x44a>
    assert(alloc_page() == NULL);
ffffffffc020099e:	4505                	li	a0,1
ffffffffc02009a0:	68a000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc02009a4:	2a051163          	bnez	a0,ffffffffc0200c46 <best_fit_check+0x42a>
    free_page(p0);
ffffffffc02009a8:	4585                	li	a1,1
ffffffffc02009aa:	854e                	mv	a0,s3
ffffffffc02009ac:	68a000ef          	jal	ffffffffc0201036 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02009b0:	00893783          	ld	a5,8(s2)
ffffffffc02009b4:	19278963          	beq	a5,s2,ffffffffc0200b46 <best_fit_check+0x32a>
    assert((p = alloc_page()) == p0);
ffffffffc02009b8:	4505                	li	a0,1
ffffffffc02009ba:	670000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc02009be:	8caa                	mv	s9,a0
ffffffffc02009c0:	54a99363          	bne	s3,a0,ffffffffc0200f06 <best_fit_check+0x6ea>
    assert(alloc_page() == NULL);
ffffffffc02009c4:	4505                	li	a0,1
ffffffffc02009c6:	664000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc02009ca:	50051e63          	bnez	a0,ffffffffc0200ee6 <best_fit_check+0x6ca>
    assert(nr_free == 0);
ffffffffc02009ce:	00007797          	auipc	a5,0x7
ffffffffc02009d2:	65a7a783          	lw	a5,1626(a5) # ffffffffc0208028 <free_area+0x10>
ffffffffc02009d6:	4e079863          	bnez	a5,ffffffffc0200ec6 <best_fit_check+0x6aa>
    free_page(p);
ffffffffc02009da:	8566                	mv	a0,s9
ffffffffc02009dc:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02009de:	01893023          	sd	s8,0(s2)
ffffffffc02009e2:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc02009e6:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc02009ea:	64c000ef          	jal	ffffffffc0201036 <free_pages>
    free_page(p1);
ffffffffc02009ee:	8556                	mv	a0,s5
ffffffffc02009f0:	4585                	li	a1,1
ffffffffc02009f2:	644000ef          	jal	ffffffffc0201036 <free_pages>
    free_page(p2);
ffffffffc02009f6:	8552                	mv	a0,s4
ffffffffc02009f8:	4585                	li	a1,1
ffffffffc02009fa:	63c000ef          	jal	ffffffffc0201036 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02009fe:	4515                	li	a0,5
ffffffffc0200a00:	62a000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc0200a04:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200a06:	4a050063          	beqz	a0,ffffffffc0200ea6 <best_fit_check+0x68a>
    assert(!PageProperty(p0));
ffffffffc0200a0a:	651c                	ld	a5,8(a0)
ffffffffc0200a0c:	8b89                	andi	a5,a5,2
ffffffffc0200a0e:	46079c63          	bnez	a5,ffffffffc0200e86 <best_fit_check+0x66a>
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200a12:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200a14:	00093b83          	ld	s7,0(s2)
ffffffffc0200a18:	00893b03          	ld	s6,8(s2)
ffffffffc0200a1c:	01293023          	sd	s2,0(s2)
ffffffffc0200a20:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0200a24:	606000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc0200a28:	42051f63          	bnez	a0,ffffffffc0200e66 <best_fit_check+0x64a>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200a2c:	4589                	li	a1,2
ffffffffc0200a2e:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200a32:	00007c17          	auipc	s8,0x7
ffffffffc0200a36:	5f6c2c03          	lw	s8,1526(s8) # ffffffffc0208028 <free_area+0x10>
    free_pages(p0 + 4, 1);
ffffffffc0200a3a:	0a098a93          	addi	s5,s3,160
    nr_free = 0;
ffffffffc0200a3e:	00007797          	auipc	a5,0x7
ffffffffc0200a42:	5e07a523          	sw	zero,1514(a5) # ffffffffc0208028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200a46:	5f0000ef          	jal	ffffffffc0201036 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200a4a:	8556                	mv	a0,s5
ffffffffc0200a4c:	4585                	li	a1,1
ffffffffc0200a4e:	5e8000ef          	jal	ffffffffc0201036 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200a52:	4511                	li	a0,4
ffffffffc0200a54:	5d6000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc0200a58:	3e051763          	bnez	a0,ffffffffc0200e46 <best_fit_check+0x62a>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200a5c:	0309b783          	ld	a5,48(s3)
ffffffffc0200a60:	8b89                	andi	a5,a5,2
ffffffffc0200a62:	3c078263          	beqz	a5,ffffffffc0200e26 <best_fit_check+0x60a>
ffffffffc0200a66:	0389ac83          	lw	s9,56(s3)
ffffffffc0200a6a:	4789                	li	a5,2
ffffffffc0200a6c:	3afc9d63          	bne	s9,a5,ffffffffc0200e26 <best_fit_check+0x60a>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200a70:	4505                	li	a0,1
ffffffffc0200a72:	5b8000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc0200a76:	8a2a                	mv	s4,a0
ffffffffc0200a78:	38050763          	beqz	a0,ffffffffc0200e06 <best_fit_check+0x5ea>
    assert(alloc_pages(2) != NULL);
ffffffffc0200a7c:	8566                	mv	a0,s9
ffffffffc0200a7e:	5ac000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc0200a82:	36050263          	beqz	a0,ffffffffc0200de6 <best_fit_check+0x5ca>
    assert(p0 + 4 == p1);
ffffffffc0200a86:	354a9063          	bne	s5,s4,ffffffffc0200dc6 <best_fit_check+0x5aa>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200a8a:	854e                	mv	a0,s3
ffffffffc0200a8c:	4595                	li	a1,5
ffffffffc0200a8e:	5a8000ef          	jal	ffffffffc0201036 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200a92:	4515                	li	a0,5
ffffffffc0200a94:	596000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc0200a98:	89aa                	mv	s3,a0
ffffffffc0200a9a:	30050663          	beqz	a0,ffffffffc0200da6 <best_fit_check+0x58a>
    assert(alloc_page() == NULL);
ffffffffc0200a9e:	4505                	li	a0,1
ffffffffc0200aa0:	58a000ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc0200aa4:	2e051163          	bnez	a0,ffffffffc0200d86 <best_fit_check+0x56a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200aa8:	00007797          	auipc	a5,0x7
ffffffffc0200aac:	5807a783          	lw	a5,1408(a5) # ffffffffc0208028 <free_area+0x10>
ffffffffc0200ab0:	2a079b63          	bnez	a5,ffffffffc0200d66 <best_fit_check+0x54a>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200ab4:	854e                	mv	a0,s3
ffffffffc0200ab6:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0200ab8:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0200abc:	01793023          	sd	s7,0(s2)
ffffffffc0200ac0:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0200ac4:	572000ef          	jal	ffffffffc0201036 <free_pages>
    return listelm->next;
ffffffffc0200ac8:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200acc:	01278963          	beq	a5,s2,ffffffffc0200ade <best_fit_check+0x2c2>
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0200ad0:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ad4:	679c                	ld	a5,8(a5)
ffffffffc0200ad6:	34fd                	addiw	s1,s1,-1
ffffffffc0200ad8:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ada:	ff279be3          	bne	a5,s2,ffffffffc0200ad0 <best_fit_check+0x2b4>
    }
    assert(count == 0);
ffffffffc0200ade:	26049463          	bnez	s1,ffffffffc0200d46 <best_fit_check+0x52a>
    assert(total == 0);
ffffffffc0200ae2:	e075                	bnez	s0,ffffffffc0200bc6 <best_fit_check+0x3aa>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
}
ffffffffc0200ae4:	60e6                	ld	ra,88(sp)
ffffffffc0200ae6:	6446                	ld	s0,80(sp)
ffffffffc0200ae8:	64a6                	ld	s1,72(sp)
ffffffffc0200aea:	6906                	ld	s2,64(sp)
ffffffffc0200aec:	79e2                	ld	s3,56(sp)
ffffffffc0200aee:	7a42                	ld	s4,48(sp)
ffffffffc0200af0:	7aa2                	ld	s5,40(sp)
ffffffffc0200af2:	7b02                	ld	s6,32(sp)
ffffffffc0200af4:	6be2                	ld	s7,24(sp)
ffffffffc0200af6:	6c42                	ld	s8,16(sp)
ffffffffc0200af8:	6ca2                	ld	s9,8(sp)
ffffffffc0200afa:	6125                	addi	sp,sp,96
ffffffffc0200afc:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200afe:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200b00:	4401                	li	s0,0
ffffffffc0200b02:	4481                	li	s1,0
ffffffffc0200b04:	bbb9                	j	ffffffffc0200862 <best_fit_check+0x46>
        assert(PageProperty(p));
ffffffffc0200b06:	00003697          	auipc	a3,0x3
ffffffffc0200b0a:	a7a68693          	addi	a3,a3,-1414 # ffffffffc0203580 <etext+0x2ce>
ffffffffc0200b0e:	00003617          	auipc	a2,0x3
ffffffffc0200b12:	a1260613          	addi	a2,a2,-1518 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200b16:	0f100593          	li	a1,241
ffffffffc0200b1a:	00003517          	auipc	a0,0x3
ffffffffc0200b1e:	a1e50513          	addi	a0,a0,-1506 # ffffffffc0203538 <etext+0x286>
ffffffffc0200b22:	eaaff0ef          	jal	ffffffffc02001cc <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200b26:	00003697          	auipc	a3,0x3
ffffffffc0200b2a:	b1268693          	addi	a3,a3,-1262 # ffffffffc0203638 <etext+0x386>
ffffffffc0200b2e:	00003617          	auipc	a2,0x3
ffffffffc0200b32:	9f260613          	addi	a2,a2,-1550 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200b36:	0c000593          	li	a1,192
ffffffffc0200b3a:	00003517          	auipc	a0,0x3
ffffffffc0200b3e:	9fe50513          	addi	a0,a0,-1538 # ffffffffc0203538 <etext+0x286>
ffffffffc0200b42:	e8aff0ef          	jal	ffffffffc02001cc <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200b46:	00003697          	auipc	a3,0x3
ffffffffc0200b4a:	bba68693          	addi	a3,a3,-1094 # ffffffffc0203700 <etext+0x44e>
ffffffffc0200b4e:	00003617          	auipc	a2,0x3
ffffffffc0200b52:	9d260613          	addi	a2,a2,-1582 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200b56:	0db00593          	li	a1,219
ffffffffc0200b5a:	00003517          	auipc	a0,0x3
ffffffffc0200b5e:	9de50513          	addi	a0,a0,-1570 # ffffffffc0203538 <etext+0x286>
ffffffffc0200b62:	e6aff0ef          	jal	ffffffffc02001cc <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200b66:	00003697          	auipc	a3,0x3
ffffffffc0200b6a:	b1268693          	addi	a3,a3,-1262 # ffffffffc0203678 <etext+0x3c6>
ffffffffc0200b6e:	00003617          	auipc	a2,0x3
ffffffffc0200b72:	9b260613          	addi	a2,a2,-1614 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200b76:	0c200593          	li	a1,194
ffffffffc0200b7a:	00003517          	auipc	a0,0x3
ffffffffc0200b7e:	9be50513          	addi	a0,a0,-1602 # ffffffffc0203538 <etext+0x286>
ffffffffc0200b82:	e4aff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200b86:	00003697          	auipc	a3,0x3
ffffffffc0200b8a:	a8a68693          	addi	a3,a3,-1398 # ffffffffc0203610 <etext+0x35e>
ffffffffc0200b8e:	00003617          	auipc	a2,0x3
ffffffffc0200b92:	99260613          	addi	a2,a2,-1646 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200b96:	0bf00593          	li	a1,191
ffffffffc0200b9a:	00003517          	auipc	a0,0x3
ffffffffc0200b9e:	99e50513          	addi	a0,a0,-1634 # ffffffffc0203538 <etext+0x286>
ffffffffc0200ba2:	e2aff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ba6:	00003697          	auipc	a3,0x3
ffffffffc0200baa:	a4a68693          	addi	a3,a3,-1462 # ffffffffc02035f0 <etext+0x33e>
ffffffffc0200bae:	00003617          	auipc	a2,0x3
ffffffffc0200bb2:	97260613          	addi	a2,a2,-1678 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200bb6:	0bd00593          	li	a1,189
ffffffffc0200bba:	00003517          	auipc	a0,0x3
ffffffffc0200bbe:	97e50513          	addi	a0,a0,-1666 # ffffffffc0203538 <etext+0x286>
ffffffffc0200bc2:	e0aff0ef          	jal	ffffffffc02001cc <__panic>
    assert(total == 0);
ffffffffc0200bc6:	00003697          	auipc	a3,0x3
ffffffffc0200bca:	c6a68693          	addi	a3,a3,-918 # ffffffffc0203830 <etext+0x57e>
ffffffffc0200bce:	00003617          	auipc	a2,0x3
ffffffffc0200bd2:	95260613          	addi	a2,a2,-1710 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200bd6:	13300593          	li	a1,307
ffffffffc0200bda:	00003517          	auipc	a0,0x3
ffffffffc0200bde:	95e50513          	addi	a0,a0,-1698 # ffffffffc0203538 <etext+0x286>
ffffffffc0200be2:	deaff0ef          	jal	ffffffffc02001cc <__panic>
    assert(total == nr_free_pages());
ffffffffc0200be6:	00003697          	auipc	a3,0x3
ffffffffc0200bea:	9aa68693          	addi	a3,a3,-1622 # ffffffffc0203590 <etext+0x2de>
ffffffffc0200bee:	00003617          	auipc	a2,0x3
ffffffffc0200bf2:	93260613          	addi	a2,a2,-1742 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200bf6:	0f400593          	li	a1,244
ffffffffc0200bfa:	00003517          	auipc	a0,0x3
ffffffffc0200bfe:	93e50513          	addi	a0,a0,-1730 # ffffffffc0203538 <etext+0x286>
ffffffffc0200c02:	dcaff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c06:	00003697          	auipc	a3,0x3
ffffffffc0200c0a:	9ca68693          	addi	a3,a3,-1590 # ffffffffc02035d0 <etext+0x31e>
ffffffffc0200c0e:	00003617          	auipc	a2,0x3
ffffffffc0200c12:	91260613          	addi	a2,a2,-1774 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200c16:	0bc00593          	li	a1,188
ffffffffc0200c1a:	00003517          	auipc	a0,0x3
ffffffffc0200c1e:	91e50513          	addi	a0,a0,-1762 # ffffffffc0203538 <etext+0x286>
ffffffffc0200c22:	daaff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c26:	00003697          	auipc	a3,0x3
ffffffffc0200c2a:	98a68693          	addi	a3,a3,-1654 # ffffffffc02035b0 <etext+0x2fe>
ffffffffc0200c2e:	00003617          	auipc	a2,0x3
ffffffffc0200c32:	8f260613          	addi	a2,a2,-1806 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200c36:	0bb00593          	li	a1,187
ffffffffc0200c3a:	00003517          	auipc	a0,0x3
ffffffffc0200c3e:	8fe50513          	addi	a0,a0,-1794 # ffffffffc0203538 <etext+0x286>
ffffffffc0200c42:	d8aff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200c46:	00003697          	auipc	a3,0x3
ffffffffc0200c4a:	a9268693          	addi	a3,a3,-1390 # ffffffffc02036d8 <etext+0x426>
ffffffffc0200c4e:	00003617          	auipc	a2,0x3
ffffffffc0200c52:	8d260613          	addi	a2,a2,-1838 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200c56:	0d800593          	li	a1,216
ffffffffc0200c5a:	00003517          	auipc	a0,0x3
ffffffffc0200c5e:	8de50513          	addi	a0,a0,-1826 # ffffffffc0203538 <etext+0x286>
ffffffffc0200c62:	d6aff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c66:	00003697          	auipc	a3,0x3
ffffffffc0200c6a:	98a68693          	addi	a3,a3,-1654 # ffffffffc02035f0 <etext+0x33e>
ffffffffc0200c6e:	00003617          	auipc	a2,0x3
ffffffffc0200c72:	8b260613          	addi	a2,a2,-1870 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200c76:	0d600593          	li	a1,214
ffffffffc0200c7a:	00003517          	auipc	a0,0x3
ffffffffc0200c7e:	8be50513          	addi	a0,a0,-1858 # ffffffffc0203538 <etext+0x286>
ffffffffc0200c82:	d4aff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c86:	00003697          	auipc	a3,0x3
ffffffffc0200c8a:	94a68693          	addi	a3,a3,-1718 # ffffffffc02035d0 <etext+0x31e>
ffffffffc0200c8e:	00003617          	auipc	a2,0x3
ffffffffc0200c92:	89260613          	addi	a2,a2,-1902 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200c96:	0d500593          	li	a1,213
ffffffffc0200c9a:	00003517          	auipc	a0,0x3
ffffffffc0200c9e:	89e50513          	addi	a0,a0,-1890 # ffffffffc0203538 <etext+0x286>
ffffffffc0200ca2:	d2aff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ca6:	00003697          	auipc	a3,0x3
ffffffffc0200caa:	90a68693          	addi	a3,a3,-1782 # ffffffffc02035b0 <etext+0x2fe>
ffffffffc0200cae:	00003617          	auipc	a2,0x3
ffffffffc0200cb2:	87260613          	addi	a2,a2,-1934 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200cb6:	0d400593          	li	a1,212
ffffffffc0200cba:	00003517          	auipc	a0,0x3
ffffffffc0200cbe:	87e50513          	addi	a0,a0,-1922 # ffffffffc0203538 <etext+0x286>
ffffffffc0200cc2:	d0aff0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free == 3);
ffffffffc0200cc6:	00003697          	auipc	a3,0x3
ffffffffc0200cca:	a2a68693          	addi	a3,a3,-1494 # ffffffffc02036f0 <etext+0x43e>
ffffffffc0200cce:	00003617          	auipc	a2,0x3
ffffffffc0200cd2:	85260613          	addi	a2,a2,-1966 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200cd6:	0d200593          	li	a1,210
ffffffffc0200cda:	00003517          	auipc	a0,0x3
ffffffffc0200cde:	85e50513          	addi	a0,a0,-1954 # ffffffffc0203538 <etext+0x286>
ffffffffc0200ce2:	ceaff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ce6:	00003697          	auipc	a3,0x3
ffffffffc0200cea:	9f268693          	addi	a3,a3,-1550 # ffffffffc02036d8 <etext+0x426>
ffffffffc0200cee:	00003617          	auipc	a2,0x3
ffffffffc0200cf2:	83260613          	addi	a2,a2,-1998 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200cf6:	0cd00593          	li	a1,205
ffffffffc0200cfa:	00003517          	auipc	a0,0x3
ffffffffc0200cfe:	83e50513          	addi	a0,a0,-1986 # ffffffffc0203538 <etext+0x286>
ffffffffc0200d02:	ccaff0ef          	jal	ffffffffc02001cc <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d06:	00003697          	auipc	a3,0x3
ffffffffc0200d0a:	9b268693          	addi	a3,a3,-1614 # ffffffffc02036b8 <etext+0x406>
ffffffffc0200d0e:	00003617          	auipc	a2,0x3
ffffffffc0200d12:	81260613          	addi	a2,a2,-2030 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200d16:	0c400593          	li	a1,196
ffffffffc0200d1a:	00003517          	auipc	a0,0x3
ffffffffc0200d1e:	81e50513          	addi	a0,a0,-2018 # ffffffffc0203538 <etext+0x286>
ffffffffc0200d22:	caaff0ef          	jal	ffffffffc02001cc <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200d26:	00003697          	auipc	a3,0x3
ffffffffc0200d2a:	97268693          	addi	a3,a3,-1678 # ffffffffc0203698 <etext+0x3e6>
ffffffffc0200d2e:	00002617          	auipc	a2,0x2
ffffffffc0200d32:	7f260613          	addi	a2,a2,2034 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200d36:	0c300593          	li	a1,195
ffffffffc0200d3a:	00002517          	auipc	a0,0x2
ffffffffc0200d3e:	7fe50513          	addi	a0,a0,2046 # ffffffffc0203538 <etext+0x286>
ffffffffc0200d42:	c8aff0ef          	jal	ffffffffc02001cc <__panic>
    assert(count == 0);
ffffffffc0200d46:	00003697          	auipc	a3,0x3
ffffffffc0200d4a:	ada68693          	addi	a3,a3,-1318 # ffffffffc0203820 <etext+0x56e>
ffffffffc0200d4e:	00002617          	auipc	a2,0x2
ffffffffc0200d52:	7d260613          	addi	a2,a2,2002 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200d56:	13200593          	li	a1,306
ffffffffc0200d5a:	00002517          	auipc	a0,0x2
ffffffffc0200d5e:	7de50513          	addi	a0,a0,2014 # ffffffffc0203538 <etext+0x286>
ffffffffc0200d62:	c6aff0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free == 0);
ffffffffc0200d66:	00003697          	auipc	a3,0x3
ffffffffc0200d6a:	9d268693          	addi	a3,a3,-1582 # ffffffffc0203738 <etext+0x486>
ffffffffc0200d6e:	00002617          	auipc	a2,0x2
ffffffffc0200d72:	7b260613          	addi	a2,a2,1970 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200d76:	12700593          	li	a1,295
ffffffffc0200d7a:	00002517          	auipc	a0,0x2
ffffffffc0200d7e:	7be50513          	addi	a0,a0,1982 # ffffffffc0203538 <etext+0x286>
ffffffffc0200d82:	c4aff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d86:	00003697          	auipc	a3,0x3
ffffffffc0200d8a:	95268693          	addi	a3,a3,-1710 # ffffffffc02036d8 <etext+0x426>
ffffffffc0200d8e:	00002617          	auipc	a2,0x2
ffffffffc0200d92:	79260613          	addi	a2,a2,1938 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200d96:	12100593          	li	a1,289
ffffffffc0200d9a:	00002517          	auipc	a0,0x2
ffffffffc0200d9e:	79e50513          	addi	a0,a0,1950 # ffffffffc0203538 <etext+0x286>
ffffffffc0200da2:	c2aff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200da6:	00003697          	auipc	a3,0x3
ffffffffc0200daa:	a5a68693          	addi	a3,a3,-1446 # ffffffffc0203800 <etext+0x54e>
ffffffffc0200dae:	00002617          	auipc	a2,0x2
ffffffffc0200db2:	77260613          	addi	a2,a2,1906 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200db6:	12000593          	li	a1,288
ffffffffc0200dba:	00002517          	auipc	a0,0x2
ffffffffc0200dbe:	77e50513          	addi	a0,a0,1918 # ffffffffc0203538 <etext+0x286>
ffffffffc0200dc2:	c0aff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200dc6:	00003697          	auipc	a3,0x3
ffffffffc0200dca:	a2a68693          	addi	a3,a3,-1494 # ffffffffc02037f0 <etext+0x53e>
ffffffffc0200dce:	00002617          	auipc	a2,0x2
ffffffffc0200dd2:	75260613          	addi	a2,a2,1874 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200dd6:	11800593          	li	a1,280
ffffffffc0200dda:	00002517          	auipc	a0,0x2
ffffffffc0200dde:	75e50513          	addi	a0,a0,1886 # ffffffffc0203538 <etext+0x286>
ffffffffc0200de2:	beaff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(2) != NULL);
ffffffffc0200de6:	00003697          	auipc	a3,0x3
ffffffffc0200dea:	9f268693          	addi	a3,a3,-1550 # ffffffffc02037d8 <etext+0x526>
ffffffffc0200dee:	00002617          	auipc	a2,0x2
ffffffffc0200df2:	73260613          	addi	a2,a2,1842 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200df6:	11700593          	li	a1,279
ffffffffc0200dfa:	00002517          	auipc	a0,0x2
ffffffffc0200dfe:	73e50513          	addi	a0,a0,1854 # ffffffffc0203538 <etext+0x286>
ffffffffc0200e02:	bcaff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200e06:	00003697          	auipc	a3,0x3
ffffffffc0200e0a:	9b268693          	addi	a3,a3,-1614 # ffffffffc02037b8 <etext+0x506>
ffffffffc0200e0e:	00002617          	auipc	a2,0x2
ffffffffc0200e12:	71260613          	addi	a2,a2,1810 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200e16:	11600593          	li	a1,278
ffffffffc0200e1a:	00002517          	auipc	a0,0x2
ffffffffc0200e1e:	71e50513          	addi	a0,a0,1822 # ffffffffc0203538 <etext+0x286>
ffffffffc0200e22:	baaff0ef          	jal	ffffffffc02001cc <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200e26:	00003697          	auipc	a3,0x3
ffffffffc0200e2a:	96268693          	addi	a3,a3,-1694 # ffffffffc0203788 <etext+0x4d6>
ffffffffc0200e2e:	00002617          	auipc	a2,0x2
ffffffffc0200e32:	6f260613          	addi	a2,a2,1778 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200e36:	11400593          	li	a1,276
ffffffffc0200e3a:	00002517          	auipc	a0,0x2
ffffffffc0200e3e:	6fe50513          	addi	a0,a0,1790 # ffffffffc0203538 <etext+0x286>
ffffffffc0200e42:	b8aff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200e46:	00003697          	auipc	a3,0x3
ffffffffc0200e4a:	92a68693          	addi	a3,a3,-1750 # ffffffffc0203770 <etext+0x4be>
ffffffffc0200e4e:	00002617          	auipc	a2,0x2
ffffffffc0200e52:	6d260613          	addi	a2,a2,1746 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200e56:	11300593          	li	a1,275
ffffffffc0200e5a:	00002517          	auipc	a0,0x2
ffffffffc0200e5e:	6de50513          	addi	a0,a0,1758 # ffffffffc0203538 <etext+0x286>
ffffffffc0200e62:	b6aff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e66:	00003697          	auipc	a3,0x3
ffffffffc0200e6a:	87268693          	addi	a3,a3,-1934 # ffffffffc02036d8 <etext+0x426>
ffffffffc0200e6e:	00002617          	auipc	a2,0x2
ffffffffc0200e72:	6b260613          	addi	a2,a2,1714 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200e76:	10700593          	li	a1,263
ffffffffc0200e7a:	00002517          	auipc	a0,0x2
ffffffffc0200e7e:	6be50513          	addi	a0,a0,1726 # ffffffffc0203538 <etext+0x286>
ffffffffc0200e82:	b4aff0ef          	jal	ffffffffc02001cc <__panic>
    assert(!PageProperty(p0));
ffffffffc0200e86:	00003697          	auipc	a3,0x3
ffffffffc0200e8a:	8d268693          	addi	a3,a3,-1838 # ffffffffc0203758 <etext+0x4a6>
ffffffffc0200e8e:	00002617          	auipc	a2,0x2
ffffffffc0200e92:	69260613          	addi	a2,a2,1682 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200e96:	0fe00593          	li	a1,254
ffffffffc0200e9a:	00002517          	auipc	a0,0x2
ffffffffc0200e9e:	69e50513          	addi	a0,a0,1694 # ffffffffc0203538 <etext+0x286>
ffffffffc0200ea2:	b2aff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p0 != NULL);
ffffffffc0200ea6:	00003697          	auipc	a3,0x3
ffffffffc0200eaa:	8a268693          	addi	a3,a3,-1886 # ffffffffc0203748 <etext+0x496>
ffffffffc0200eae:	00002617          	auipc	a2,0x2
ffffffffc0200eb2:	67260613          	addi	a2,a2,1650 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200eb6:	0fd00593          	li	a1,253
ffffffffc0200eba:	00002517          	auipc	a0,0x2
ffffffffc0200ebe:	67e50513          	addi	a0,a0,1662 # ffffffffc0203538 <etext+0x286>
ffffffffc0200ec2:	b0aff0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free == 0);
ffffffffc0200ec6:	00003697          	auipc	a3,0x3
ffffffffc0200eca:	87268693          	addi	a3,a3,-1934 # ffffffffc0203738 <etext+0x486>
ffffffffc0200ece:	00002617          	auipc	a2,0x2
ffffffffc0200ed2:	65260613          	addi	a2,a2,1618 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200ed6:	0e100593          	li	a1,225
ffffffffc0200eda:	00002517          	auipc	a0,0x2
ffffffffc0200ede:	65e50513          	addi	a0,a0,1630 # ffffffffc0203538 <etext+0x286>
ffffffffc0200ee2:	aeaff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ee6:	00002697          	auipc	a3,0x2
ffffffffc0200eea:	7f268693          	addi	a3,a3,2034 # ffffffffc02036d8 <etext+0x426>
ffffffffc0200eee:	00002617          	auipc	a2,0x2
ffffffffc0200ef2:	63260613          	addi	a2,a2,1586 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200ef6:	0df00593          	li	a1,223
ffffffffc0200efa:	00002517          	auipc	a0,0x2
ffffffffc0200efe:	63e50513          	addi	a0,a0,1598 # ffffffffc0203538 <etext+0x286>
ffffffffc0200f02:	acaff0ef          	jal	ffffffffc02001cc <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200f06:	00003697          	auipc	a3,0x3
ffffffffc0200f0a:	81268693          	addi	a3,a3,-2030 # ffffffffc0203718 <etext+0x466>
ffffffffc0200f0e:	00002617          	auipc	a2,0x2
ffffffffc0200f12:	61260613          	addi	a2,a2,1554 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200f16:	0de00593          	li	a1,222
ffffffffc0200f1a:	00002517          	auipc	a0,0x2
ffffffffc0200f1e:	61e50513          	addi	a0,a0,1566 # ffffffffc0203538 <etext+0x286>
ffffffffc0200f22:	aaaff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200f26 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200f26:	1141                	addi	sp,sp,-16
ffffffffc0200f28:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200f2a:	cdb9                	beqz	a1,ffffffffc0200f88 <best_fit_free_pages+0x62>
    for (struct Page *p = base; p != base + n; p ++) {
ffffffffc0200f2c:	00259693          	slli	a3,a1,0x2
ffffffffc0200f30:	96ae                	add	a3,a3,a1
ffffffffc0200f32:	068e                	slli	a3,a3,0x3
ffffffffc0200f34:	96aa                	add	a3,a3,a0
ffffffffc0200f36:	87aa                	mv	a5,a0
ffffffffc0200f38:	02d50463          	beq	a0,a3,ffffffffc0200f60 <best_fit_free_pages+0x3a>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200f3c:	6798                	ld	a4,8(a5)
ffffffffc0200f3e:	8b0d                	andi	a4,a4,3
ffffffffc0200f40:	e705                	bnez	a4,ffffffffc0200f68 <best_fit_free_pages+0x42>
    for (struct Page *p = base; p != base + n; p ++) {
ffffffffc0200f42:	02878793          	addi	a5,a5,40
ffffffffc0200f46:	fed79be3          	bne	a5,a3,ffffffffc0200f3c <best_fit_free_pages+0x16>
    for (struct Page *p = base; p != base + n; p ++) {
ffffffffc0200f4a:	87aa                	mv	a5,a0
        p->flags = p->property = 0;
ffffffffc0200f4c:	0007a823          	sw	zero,16(a5)
ffffffffc0200f50:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200f54:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p != base + n; p ++) {
ffffffffc0200f58:	02878793          	addi	a5,a5,40
ffffffffc0200f5c:	fed798e3          	bne	a5,a3,ffffffffc0200f4c <best_fit_free_pages+0x26>
}
ffffffffc0200f60:	60a2                	ld	ra,8(sp)
ffffffffc0200f62:	0141                	addi	sp,sp,16
    best_fit_insert_block(base, n);
ffffffffc0200f64:	e2aff06f          	j	ffffffffc020058e <best_fit_insert_block>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200f68:	00003697          	auipc	a3,0x3
ffffffffc0200f6c:	8d868693          	addi	a3,a3,-1832 # ffffffffc0203840 <etext+0x58e>
ffffffffc0200f70:	00002617          	auipc	a2,0x2
ffffffffc0200f74:	5b060613          	addi	a2,a2,1456 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200f78:	09a00593          	li	a1,154
ffffffffc0200f7c:	00002517          	auipc	a0,0x2
ffffffffc0200f80:	5bc50513          	addi	a0,a0,1468 # ffffffffc0203538 <etext+0x286>
ffffffffc0200f84:	a48ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(n > 0);
ffffffffc0200f88:	00002697          	auipc	a3,0x2
ffffffffc0200f8c:	5f068693          	addi	a3,a3,1520 # ffffffffc0203578 <etext+0x2c6>
ffffffffc0200f90:	00002617          	auipc	a2,0x2
ffffffffc0200f94:	59060613          	addi	a2,a2,1424 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200f98:	09800593          	li	a1,152
ffffffffc0200f9c:	00002517          	auipc	a0,0x2
ffffffffc0200fa0:	59c50513          	addi	a0,a0,1436 # ffffffffc0203538 <etext+0x286>
ffffffffc0200fa4:	a28ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200fa8 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200fa8:	1141                	addi	sp,sp,-16
ffffffffc0200faa:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200fac:	cdb9                	beqz	a1,ffffffffc020100a <best_fit_init_memmap+0x62>
    for (struct Page *p = base; p != base + n; p ++) {
ffffffffc0200fae:	00259693          	slli	a3,a1,0x2
ffffffffc0200fb2:	96ae                	add	a3,a3,a1
ffffffffc0200fb4:	068e                	slli	a3,a3,0x3
ffffffffc0200fb6:	96aa                	add	a3,a3,a0
ffffffffc0200fb8:	87aa                	mv	a5,a0
ffffffffc0200fba:	02d50463          	beq	a0,a3,ffffffffc0200fe2 <best_fit_init_memmap+0x3a>
        assert(PageReserved(p));
ffffffffc0200fbe:	6798                	ld	a4,8(a5)
ffffffffc0200fc0:	8b05                	andi	a4,a4,1
ffffffffc0200fc2:	c705                	beqz	a4,ffffffffc0200fea <best_fit_init_memmap+0x42>
    for (struct Page *p = base; p != base + n; p ++) {
ffffffffc0200fc4:	02878793          	addi	a5,a5,40
ffffffffc0200fc8:	fed79be3          	bne	a5,a3,ffffffffc0200fbe <best_fit_init_memmap+0x16>
    for (struct Page *p = base; p != base + n; p ++) {
ffffffffc0200fcc:	87aa                	mv	a5,a0
        p->flags = p->property = 0;
ffffffffc0200fce:	0007a823          	sw	zero,16(a5)
ffffffffc0200fd2:	0007b423          	sd	zero,8(a5)
ffffffffc0200fd6:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p != base + n; p ++) {
ffffffffc0200fda:	02878793          	addi	a5,a5,40
ffffffffc0200fde:	fed798e3          	bne	a5,a3,ffffffffc0200fce <best_fit_init_memmap+0x26>
}
ffffffffc0200fe2:	60a2                	ld	ra,8(sp)
ffffffffc0200fe4:	0141                	addi	sp,sp,16
    best_fit_insert_block(base, n);
ffffffffc0200fe6:	da8ff06f          	j	ffffffffc020058e <best_fit_insert_block>
        assert(PageReserved(p));
ffffffffc0200fea:	00003697          	auipc	a3,0x3
ffffffffc0200fee:	87e68693          	addi	a3,a3,-1922 # ffffffffc0203868 <etext+0x5b6>
ffffffffc0200ff2:	00002617          	auipc	a2,0x2
ffffffffc0200ff6:	52e60613          	addi	a2,a2,1326 # ffffffffc0203520 <etext+0x26e>
ffffffffc0200ffa:	05b00593          	li	a1,91
ffffffffc0200ffe:	00002517          	auipc	a0,0x2
ffffffffc0201002:	53a50513          	addi	a0,a0,1338 # ffffffffc0203538 <etext+0x286>
ffffffffc0201006:	9c6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(n > 0);
ffffffffc020100a:	00002697          	auipc	a3,0x2
ffffffffc020100e:	56e68693          	addi	a3,a3,1390 # ffffffffc0203578 <etext+0x2c6>
ffffffffc0201012:	00002617          	auipc	a2,0x2
ffffffffc0201016:	50e60613          	addi	a2,a2,1294 # ffffffffc0203520 <etext+0x26e>
ffffffffc020101a:	05900593          	li	a1,89
ffffffffc020101e:	00002517          	auipc	a0,0x2
ffffffffc0201022:	51a50513          	addi	a0,a0,1306 # ffffffffc0203538 <etext+0x286>
ffffffffc0201026:	9a6ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc020102a <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc020102a:	00018797          	auipc	a5,0x18
ffffffffc020102e:	75e7b783          	ld	a5,1886(a5) # ffffffffc0219788 <pmm_manager>
ffffffffc0201032:	6f9c                	ld	a5,24(a5)
ffffffffc0201034:	8782                	jr	a5

ffffffffc0201036 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0201036:	00018797          	auipc	a5,0x18
ffffffffc020103a:	7527b783          	ld	a5,1874(a5) # ffffffffc0219788 <pmm_manager>
ffffffffc020103e:	739c                	ld	a5,32(a5)
ffffffffc0201040:	8782                	jr	a5

ffffffffc0201042 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0201042:	00018797          	auipc	a5,0x18
ffffffffc0201046:	7467b783          	ld	a5,1862(a5) # ffffffffc0219788 <pmm_manager>
ffffffffc020104a:	779c                	ld	a5,40(a5)
ffffffffc020104c:	8782                	jr	a5

ffffffffc020104e <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020104e:	00003797          	auipc	a5,0x3
ffffffffc0201052:	1aa78793          	addi	a5,a5,426 # ffffffffc02041f8 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201056:	638c                	ld	a1,0(a5)
            (unsigned long)freemem_pa, (unsigned long)mem_end,
            (unsigned long)nr_free_pages());
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201058:	7139                	addi	sp,sp,-64
ffffffffc020105a:	fc06                	sd	ra,56(sp)
ffffffffc020105c:	f822                	sd	s0,48(sp)
ffffffffc020105e:	f426                	sd	s1,40(sp)
ffffffffc0201060:	f04a                	sd	s2,32(sp)
ffffffffc0201062:	ec4e                	sd	s3,24(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201064:	00018497          	auipc	s1,0x18
ffffffffc0201068:	72448493          	addi	s1,s1,1828 # ffffffffc0219788 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020106c:	00003517          	auipc	a0,0x3
ffffffffc0201070:	82450513          	addi	a0,a0,-2012 # ffffffffc0203890 <etext+0x5de>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201074:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201076:	8d6ff0ef          	jal	ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc020107a:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020107c:	00018917          	auipc	s2,0x18
ffffffffc0201080:	72490913          	addi	s2,s2,1828 # ffffffffc02197a0 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201084:	679c                	ld	a5,8(a5)
ffffffffc0201086:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201088:	57f5                	li	a5,-3
ffffffffc020108a:	07fa                	slli	a5,a5,0x1e
ffffffffc020108c:	00f93023          	sd	a5,0(s2)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201090:	cceff0ef          	jal	ffffffffc020055e <get_memory_base>
ffffffffc0201094:	842a                	mv	s0,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0201096:	cd2ff0ef          	jal	ffffffffc0200568 <get_memory_size>
    if (__builtin_add_overflow(mem_begin, mem_size, &mem_end)) {
ffffffffc020109a:	00a40733          	add	a4,s0,a0
ffffffffc020109e:	22876c63          	bltu	a4,s0,ffffffffc02012d6 <pmm_init+0x288>
    npage = PPN(mem_end);
ffffffffc02010a2:	00c75593          	srli	a1,a4,0xc
ffffffffc02010a6:	00018797          	auipc	a5,0x18
ffffffffc02010aa:	70b7b123          	sd	a1,1794(a5) # ffffffffc02197a8 <npage>
    if (npage <= nbase) {
ffffffffc02010ae:	000808b7          	lui	a7,0x80
ffffffffc02010b2:	20b8f463          	bgeu	a7,a1,ffffffffc02012ba <pmm_init+0x26c>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02010b6:	76fd                	lui	a3,0xfffff
ffffffffc02010b8:	00019817          	auipc	a6,0x19
ffffffffc02010bc:	73f80813          	addi	a6,a6,1855 # ffffffffc021a7f7 <end+0xfff>
ffffffffc02010c0:	00259613          	slli	a2,a1,0x2
ffffffffc02010c4:	00d87833          	and	a6,a6,a3
ffffffffc02010c8:	962e                	add	a2,a2,a1
ffffffffc02010ca:	fec006b7          	lui	a3,0xfec00
ffffffffc02010ce:	96c2                	add	a3,a3,a6
ffffffffc02010d0:	060e                	slli	a2,a2,0x3
ffffffffc02010d2:	00018797          	auipc	a5,0x18
ffffffffc02010d6:	6d07bf23          	sd	a6,1758(a5) # ffffffffc02197b0 <pages>
ffffffffc02010da:	9636                	add	a2,a2,a3
    size_t n = npage - nbase;
ffffffffc02010dc:	411588b3          	sub	a7,a1,a7
ffffffffc02010e0:	87c2                	mv	a5,a6
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02010e2:	00018517          	auipc	a0,0x18
ffffffffc02010e6:	71650513          	addi	a0,a0,1814 # ffffffffc02197f8 <end>
        pages[i].flags = (1UL << PG_reserved);
ffffffffc02010ea:	4685                	li	a3,1
ffffffffc02010ec:	e794                	sd	a3,8(a5)
        pages[i].property = 0;
ffffffffc02010ee:	0007a823          	sw	zero,16(a5)
ffffffffc02010f2:	0007a023          	sw	zero,0(a5)
    for (size_t i = 0; i < n; i ++) {
ffffffffc02010f6:	02878793          	addi	a5,a5,40
ffffffffc02010fa:	fef619e3          	bne	a2,a5,ffffffffc02010ec <pmm_init+0x9e>
    size_t pages_bytes = n * sizeof(struct Page);
ffffffffc02010fe:	00289793          	slli	a5,a7,0x2
ffffffffc0201102:	97c6                	add	a5,a5,a7
ffffffffc0201104:	078e                	slli	a5,a5,0x3
    if (pages_va > (uintptr_t)-1 - pages_bytes) {
ffffffffc0201106:	010786b3          	add	a3,a5,a6
ffffffffc020110a:	22f6ea63          	bltu	a3,a5,ffffffffc020133e <pmm_init+0x2f0>
    uintptr_t freemem_va = ROUNDUP(array_end_va, PGSIZE);
ffffffffc020110e:	6885                	lui	a7,0x1
ffffffffc0201110:	fff88e13          	addi	t3,a7,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0201114:	01c687b3          	add	a5,a3,t3
ffffffffc0201118:	737d                	lui	t1,0xfffff
ffffffffc020111a:	0067f7b3          	and	a5,a5,t1
    if (freemem_va < array_end_va) {
ffffffffc020111e:	20d7e463          	bltu	a5,a3,ffffffffc0201326 <pmm_init+0x2d8>
    uintptr_t freemem_pa = PADDR(freemem_va);
ffffffffc0201122:	c02006b7          	lui	a3,0xc0200
ffffffffc0201126:	1ed7e363          	bltu	a5,a3,ffffffffc020130c <pmm_init+0x2be>
    uintptr_t bootstack_end_pa = PADDR((uintptr_t)bootstacktop);
ffffffffc020112a:	00006617          	auipc	a2,0x6
ffffffffc020112e:	ed660613          	addi	a2,a2,-298 # ffffffffc0207000 <boot_page_table_sv39>
ffffffffc0201132:	1cd66063          	bltu	a2,a3,ffffffffc02012f2 <pmm_init+0x2a4>
    uintptr_t pt_end_pa = PADDR((uintptr_t)boot_page_table_sv39) + PGSIZE;
ffffffffc0201136:	00006997          	auipc	s3,0x6
ffffffffc020113a:	eca98993          	addi	s3,s3,-310 # ffffffffc0207000 <boot_page_table_sv39>
ffffffffc020113e:	16d9e163          	bltu	s3,a3,ffffffffc02012a0 <pmm_init+0x252>
    uintptr_t kern_end_pa = PADDR((uintptr_t)end);
ffffffffc0201142:	12d56f63          	bltu	a0,a3,ffffffffc0201280 <pmm_init+0x232>
    uintptr_t freemem_pa = PADDR(freemem_va);
ffffffffc0201146:	00093683          	ld	a3,0(s2)
    uintptr_t bootstack_end_pa = PADDR((uintptr_t)bootstacktop);
ffffffffc020114a:	00006617          	auipc	a2,0x6
ffffffffc020114e:	eb660613          	addi	a2,a2,-330 # ffffffffc0207000 <boot_page_table_sv39>
    uintptr_t freemem_pa = PADDR(freemem_va);
ffffffffc0201152:	8f95                	sub	a5,a5,a3
    uintptr_t bootstack_end_pa = PADDR((uintptr_t)bootstacktop);
ffffffffc0201154:	8e15                	sub	a2,a2,a3
    uintptr_t kern_end_pa = PADDR((uintptr_t)end);
ffffffffc0201156:	8d15                	sub	a0,a0,a3
    uintptr_t pt_end_pa = PADDR((uintptr_t)boot_page_table_sv39) + PGSIZE;
ffffffffc0201158:	40d986b3          	sub	a3,s3,a3
ffffffffc020115c:	98b6                	add	a7,a7,a3
    if (bootstack_end_pa > freemem_pa) {
ffffffffc020115e:	00c7f563          	bgeu	a5,a2,ffffffffc0201168 <pmm_init+0x11a>
        freemem_pa = ROUNDUP(bootstack_end_pa, PGSIZE);
ffffffffc0201162:	9672                	add	a2,a2,t3
ffffffffc0201164:	006677b3          	and	a5,a2,t1
    if (pt_end_pa > freemem_pa) {
ffffffffc0201168:	0117f763          	bgeu	a5,a7,ffffffffc0201176 <pmm_init+0x128>
        freemem_pa = ROUNDUP(pt_end_pa, PGSIZE);
ffffffffc020116c:	6789                	lui	a5,0x2
ffffffffc020116e:	17fd                	addi	a5,a5,-1 # 1fff <kern_entry-0xffffffffc01fe001>
ffffffffc0201170:	96be                	add	a3,a3,a5
ffffffffc0201172:	77fd                	lui	a5,0xfffff
ffffffffc0201174:	8ff5                	and	a5,a5,a3
    if (kern_end_pa > freemem_pa) {
ffffffffc0201176:	00a7f763          	bgeu	a5,a0,ffffffffc0201184 <pmm_init+0x136>
        freemem_pa = ROUNDUP(kern_end_pa, PGSIZE);
ffffffffc020117a:	6785                	lui	a5,0x1
ffffffffc020117c:	17fd                	addi	a5,a5,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc020117e:	953e                	add	a0,a0,a5
ffffffffc0201180:	77fd                	lui	a5,0xfffff
ffffffffc0201182:	8fe9                	and	a5,a5,a0
    uintptr_t mem_begin_aligned = (uintptr_t)ROUNDUP(mem_begin, PGSIZE);
ffffffffc0201184:	6685                	lui	a3,0x1
ffffffffc0201186:	16fd                	addi	a3,a3,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0201188:	96a2                	add	a3,a3,s0
    if (freemem_pa < mem_begin_aligned) {
ffffffffc020118a:	767d                	lui	a2,0xfffff
ffffffffc020118c:	00c6f433          	and	s0,a3,a2
ffffffffc0201190:	08f46363          	bltu	s0,a5,ffffffffc0201216 <pmm_init+0x1c8>
    if (freemem_pa < DRAM_BASE) {
ffffffffc0201194:	800007b7          	lui	a5,0x80000
ffffffffc0201198:	fff7c793          	not	a5,a5
ffffffffc020119c:	0c87f563          	bgeu	a5,s0,ffffffffc0201266 <pmm_init+0x218>
    uint64_t mem_end_aligned = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02011a0:	77fd                	lui	a5,0xfffff
ffffffffc02011a2:	8ff9                	and	a5,a5,a4
    if (freemem_pa < mem_end_aligned) {
ffffffffc02011a4:	06f46b63          	bltu	s0,a5,ffffffffc020121a <pmm_init+0x1cc>
    return pmm_manager->nr_free_pages();
ffffffffc02011a8:	609c                	ld	a5,0(s1)
ffffffffc02011aa:	e43a                	sd	a4,8(sp)
ffffffffc02011ac:	e02e                	sd	a1,0(sp)
ffffffffc02011ae:	779c                	ld	a5,40(a5)
ffffffffc02011b0:	9782                	jalr	a5
    cprintf("page_init: npage=%lu nbase=%lu freemem=%lx mem_end=%lx nr_free=%lu\n",
ffffffffc02011b2:	6722                	ld	a4,8(sp)
ffffffffc02011b4:	6582                	ld	a1,0(sp)
ffffffffc02011b6:	86a2                	mv	a3,s0
ffffffffc02011b8:	00080637          	lui	a2,0x80
    return pmm_manager->nr_free_pages();
ffffffffc02011bc:	87aa                	mv	a5,a0
    cprintf("page_init: npage=%lu nbase=%lu freemem=%lx mem_end=%lx nr_free=%lu\n",
ffffffffc02011be:	00003517          	auipc	a0,0x3
ffffffffc02011c2:	82250513          	addi	a0,a0,-2014 # ffffffffc02039e0 <etext+0x72e>
ffffffffc02011c6:	f87fe0ef          	jal	ffffffffc020014c <cprintf>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02011ca:	609c                	ld	a5,0(s1)
ffffffffc02011cc:	7b9c                	ld	a5,48(a5)
ffffffffc02011ce:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02011d0:	00003517          	auipc	a0,0x3
ffffffffc02011d4:	85850513          	addi	a0,a0,-1960 # ffffffffc0203a28 <etext+0x776>
ffffffffc02011d8:	f75fe0ef          	jal	ffffffffc020014c <cprintf>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011dc:	00093783          	ld	a5,0(s2)
}
ffffffffc02011e0:	7442                	ld	s0,48(sp)
ffffffffc02011e2:	70e2                	ld	ra,56(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02011e4:	40f987b3          	sub	a5,s3,a5
}
ffffffffc02011e8:	74a2                	ld	s1,40(sp)
ffffffffc02011ea:	7902                	ld	s2,32(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02011ec:	00018717          	auipc	a4,0x18
ffffffffc02011f0:	5af73223          	sd	a5,1444(a4) # ffffffffc0219790 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02011f4:	863e                	mv	a2,a5
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02011f6:	00018797          	auipc	a5,0x18
ffffffffc02011fa:	5b37b123          	sd	s3,1442(a5) # ffffffffc0219798 <satp_virtual>
}
ffffffffc02011fe:	69e2                	ld	s3,24(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201200:	00006597          	auipc	a1,0x6
ffffffffc0201204:	e0058593          	addi	a1,a1,-512 # ffffffffc0207000 <boot_page_table_sv39>
ffffffffc0201208:	00003517          	auipc	a0,0x3
ffffffffc020120c:	84050513          	addi	a0,a0,-1984 # ffffffffc0203a48 <etext+0x796>
}
ffffffffc0201210:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201212:	f3bfe06f          	j	ffffffffc020014c <cprintf>
    if (freemem_pa < mem_begin_aligned) {
ffffffffc0201216:	843e                	mv	s0,a5
ffffffffc0201218:	bfb5                	j	ffffffffc0201194 <pmm_init+0x146>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc020121a:	00c45613          	srli	a2,s0,0xc
ffffffffc020121e:	02b67863          	bgeu	a2,a1,ffffffffc020124e <pmm_init+0x200>
        size_t free_n = (size_t)((mem_end_aligned - freemem_pa) >> PGSHIFT);
ffffffffc0201222:	8f81                	sub	a5,a5,s0
ffffffffc0201224:	83b1                	srli	a5,a5,0xc
        if (free_n > 0) {
ffffffffc0201226:	d3c9                	beqz	a5,ffffffffc02011a8 <pmm_init+0x15a>
    pmm_manager->init_memmap(base, n);
ffffffffc0201228:	608c                	ld	a1,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020122a:	fff80537          	lui	a0,0xfff80
ffffffffc020122e:	962a                	add	a2,a2,a0
ffffffffc0201230:	00261513          	slli	a0,a2,0x2
ffffffffc0201234:	9532                	add	a0,a0,a2
ffffffffc0201236:	6990                	ld	a2,16(a1)
ffffffffc0201238:	050e                	slli	a0,a0,0x3
ffffffffc020123a:	85be                	mv	a1,a5
ffffffffc020123c:	9542                	add	a0,a0,a6
ffffffffc020123e:	e03a                	sd	a4,0(sp)
ffffffffc0201240:	9602                	jalr	a2
    cprintf("page_init: npage=%lu nbase=%lu freemem=%lx mem_end=%lx nr_free=%lu\n",
ffffffffc0201242:	00018597          	auipc	a1,0x18
ffffffffc0201246:	5665b583          	ld	a1,1382(a1) # ffffffffc02197a8 <npage>
ffffffffc020124a:	6702                	ld	a4,0(sp)
}
ffffffffc020124c:	bfb1                	j	ffffffffc02011a8 <pmm_init+0x15a>
        panic("pa2page called with invalid pa");
ffffffffc020124e:	00002617          	auipc	a2,0x2
ffffffffc0201252:	76260613          	addi	a2,a2,1890 # ffffffffc02039b0 <etext+0x6fe>
ffffffffc0201256:	06a00593          	li	a1,106
ffffffffc020125a:	00002517          	auipc	a0,0x2
ffffffffc020125e:	77650513          	addi	a0,a0,1910 # ffffffffc02039d0 <etext+0x71e>
ffffffffc0201262:	f6bfe0ef          	jal	ffffffffc02001cc <__panic>
        panic("page_init: freemem %lx below DRAM_BASE\n", (unsigned long)freemem_pa);
ffffffffc0201266:	86a2                	mv	a3,s0
ffffffffc0201268:	00002617          	auipc	a2,0x2
ffffffffc020126c:	72060613          	addi	a2,a2,1824 # ffffffffc0203988 <etext+0x6d6>
ffffffffc0201270:	09f00593          	li	a1,159
ffffffffc0201274:	00002517          	auipc	a0,0x2
ffffffffc0201278:	66c50513          	addi	a0,a0,1644 # ffffffffc02038e0 <etext+0x62e>
ffffffffc020127c:	f51fe0ef          	jal	ffffffffc02001cc <__panic>
    uintptr_t kern_end_pa = PADDR((uintptr_t)end);
ffffffffc0201280:	00018697          	auipc	a3,0x18
ffffffffc0201284:	57868693          	addi	a3,a3,1400 # ffffffffc02197f8 <end>
ffffffffc0201288:	00002617          	auipc	a2,0x2
ffffffffc020128c:	6d860613          	addi	a2,a2,1752 # ffffffffc0203960 <etext+0x6ae>
ffffffffc0201290:	08a00593          	li	a1,138
ffffffffc0201294:	00002517          	auipc	a0,0x2
ffffffffc0201298:	64c50513          	addi	a0,a0,1612 # ffffffffc02038e0 <etext+0x62e>
ffffffffc020129c:	f31fe0ef          	jal	ffffffffc02001cc <__panic>
    uintptr_t pt_end_pa = PADDR((uintptr_t)boot_page_table_sv39) + PGSIZE;
ffffffffc02012a0:	86ce                	mv	a3,s3
ffffffffc02012a2:	00002617          	auipc	a2,0x2
ffffffffc02012a6:	6be60613          	addi	a2,a2,1726 # ffffffffc0203960 <etext+0x6ae>
ffffffffc02012aa:	08900593          	li	a1,137
ffffffffc02012ae:	00002517          	auipc	a0,0x2
ffffffffc02012b2:	63250513          	addi	a0,a0,1586 # ffffffffc02038e0 <etext+0x62e>
ffffffffc02012b6:	f17fe0ef          	jal	ffffffffc02001cc <__panic>
        panic("page_init: npage %lu <= nbase %lu\n", (unsigned long)npage, (unsigned long)nbase);
ffffffffc02012ba:	86ae                	mv	a3,a1
ffffffffc02012bc:	8746                	mv	a4,a7
ffffffffc02012be:	00002617          	auipc	a2,0x2
ffffffffc02012c2:	63260613          	addi	a2,a2,1586 # ffffffffc02038f0 <etext+0x63e>
ffffffffc02012c6:	05b00593          	li	a1,91
ffffffffc02012ca:	00002517          	auipc	a0,0x2
ffffffffc02012ce:	61650513          	addi	a0,a0,1558 # ffffffffc02038e0 <etext+0x62e>
ffffffffc02012d2:	efbfe0ef          	jal	ffffffffc02001cc <__panic>
        panic("page_init: memory range overflow (base %lx size %lx)\n", mem_begin, mem_size);
ffffffffc02012d6:	872a                	mv	a4,a0
ffffffffc02012d8:	86a2                	mv	a3,s0
ffffffffc02012da:	00002617          	auipc	a2,0x2
ffffffffc02012de:	5ce60613          	addi	a2,a2,1486 # ffffffffc02038a8 <etext+0x5f6>
ffffffffc02012e2:	05400593          	li	a1,84
ffffffffc02012e6:	00002517          	auipc	a0,0x2
ffffffffc02012ea:	5fa50513          	addi	a0,a0,1530 # ffffffffc02038e0 <etext+0x62e>
ffffffffc02012ee:	edffe0ef          	jal	ffffffffc02001cc <__panic>
    uintptr_t bootstack_end_pa = PADDR((uintptr_t)bootstacktop);
ffffffffc02012f2:	86b2                	mv	a3,a2
ffffffffc02012f4:	08800593          	li	a1,136
ffffffffc02012f8:	00002617          	auipc	a2,0x2
ffffffffc02012fc:	66860613          	addi	a2,a2,1640 # ffffffffc0203960 <etext+0x6ae>
ffffffffc0201300:	00002517          	auipc	a0,0x2
ffffffffc0201304:	5e050513          	addi	a0,a0,1504 # ffffffffc02038e0 <etext+0x62e>
ffffffffc0201308:	ec5fe0ef          	jal	ffffffffc02001cc <__panic>
    uintptr_t freemem_pa = PADDR(freemem_va);
ffffffffc020130c:	86be                	mv	a3,a5
ffffffffc020130e:	00002617          	auipc	a2,0x2
ffffffffc0201312:	65260613          	addi	a2,a2,1618 # ffffffffc0203960 <etext+0x6ae>
ffffffffc0201316:	08100593          	li	a1,129
ffffffffc020131a:	00002517          	auipc	a0,0x2
ffffffffc020131e:	5c650513          	addi	a0,a0,1478 # ffffffffc02038e0 <etext+0x62e>
ffffffffc0201322:	eabfe0ef          	jal	ffffffffc02001cc <__panic>
        panic("page_init: freemem_va overflow\n");
ffffffffc0201326:	00002617          	auipc	a2,0x2
ffffffffc020132a:	61a60613          	addi	a2,a2,1562 # ffffffffc0203940 <etext+0x68e>
ffffffffc020132e:	07d00593          	li	a1,125
ffffffffc0201332:	00002517          	auipc	a0,0x2
ffffffffc0201336:	5ae50513          	addi	a0,a0,1454 # ffffffffc02038e0 <etext+0x62e>
ffffffffc020133a:	e93fe0ef          	jal	ffffffffc02001cc <__panic>
        panic("page_init: Page array end overflow\n");
ffffffffc020133e:	00002617          	auipc	a2,0x2
ffffffffc0201342:	5da60613          	addi	a2,a2,1498 # ffffffffc0203918 <etext+0x666>
ffffffffc0201346:	07700593          	li	a1,119
ffffffffc020134a:	00002517          	auipc	a0,0x2
ffffffffc020134e:	59650513          	addi	a0,a0,1430 # ffffffffc02038e0 <etext+0x62e>
ffffffffc0201352:	e7bfe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0201356 <slub_pages_alloc>:
    /* entry.S 保存的启动 hart 硬件 ID（单核环境下为 0，但来源是硬件而非常量） */
    return (unsigned int)boot_hartid;
}

static inline void slub_port_local_lock(slub_port_flags_t *flags) {
    unsigned long s = read_csr(sstatus);
ffffffffc0201356:	100026f3          	csrr	a3,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc020135a:	8a89                	andi	a3,a3,2
    if (*flags) {
ffffffffc020135c:	c299                	beqz	a3,ffffffffc0201362 <slub_pages_alloc+0xc>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc020135e:	100177f3          	csrrci	a5,sstatus,2
    }
    __sync_synchronize();
ffffffffc0201362:	0330000f          	fence	rw,rw
static inline void slub_port_spin_lock(slub_spinlock_t *lock,
                                       slub_port_flags_t *flags) {
    /* 关本地中断：防止“同核中断里再取同一把锁”的自旋死锁；
     * 多核互斥完全由下面的原子操作提供。 */
    slub_port_local_lock(flags);
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0201366:	00018717          	auipc	a4,0x18
ffffffffc020136a:	47a70713          	addi	a4,a4,1146 # ffffffffc02197e0 <slub_pmm_lock>
ffffffffc020136e:	4785                	li	a5,1
ffffffffc0201370:	0cf727af          	amoswap.w.aq	a5,a5,(a4)
ffffffffc0201374:	2781                	sext.w	a5,a5
ffffffffc0201376:	ffe5                	bnez	a5,ffffffffc020136e <slub_pages_alloc+0x18>
        /* 自旋等待；锁序保证不会出现持锁自等待 */
    }
    __sync_synchronize(); /* acquire */
ffffffffc0201378:	0330000f          	fence	rw,rw
static slub_page_t *slub_pages_alloc(size_t npages) {
    slub_page_t *base;
    slub_port_flags_t f;

    slub_port_spin_lock(&slub_pmm_lock, &f);
    if (slub_fault_left != 0) {
ffffffffc020137c:	00018797          	auipc	a5,0x18
ffffffffc0201380:	4447b783          	ld	a5,1092(a5) # ffffffffc02197c0 <slub_fault_left>
ffffffffc0201384:	eb8d                	bnez	a5,ffffffffc02013b6 <slub_pages_alloc+0x60>
static slub_page_t *slub_pages_alloc(size_t npages) {
ffffffffc0201386:	1101                	addi	sp,sp,-32
ffffffffc0201388:	e436                	sd	a3,8(sp)
ffffffffc020138a:	ec06                	sd	ra,24(sp)
    slub_port_local_unlock(flags);
}

static inline slub_page_t *slub_port_pages_alloc(size_t npages) {
    /* 调用方（slub.c）持有 slub_pmm_lock：底层 best-fit/buddy 均非线程安全 */
    return alloc_pages(npages);
ffffffffc020138c:	c9fff0ef          	jal	ffffffffc020102a <alloc_pages>
ffffffffc0201390:	66a2                	ld	a3,8(sp)
ffffffffc0201392:	00018717          	auipc	a4,0x18
ffffffffc0201396:	44e70713          	addi	a4,a4,1102 # ffffffffc02197e0 <slub_pmm_lock>
    __sync_synchronize(); /* release */
ffffffffc020139a:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc020139e:	0310000f          	fence	rw,w
ffffffffc02013a2:	00072023          	sw	zero,0(a4)
    __sync_synchronize();
ffffffffc02013a6:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02013aa:	c299                	beqz	a3,ffffffffc02013b0 <slub_pages_alloc+0x5a>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc02013ac:	100167f3          	csrrsi	a5,sstatus,2
    } else {
        base = slub_port_pages_alloc(npages);
    }
    slub_port_spin_unlock(&slub_pmm_lock, &f);
    return base;
}
ffffffffc02013b0:	60e2                	ld	ra,24(sp)
ffffffffc02013b2:	6105                	addi	sp,sp,32
ffffffffc02013b4:	8082                	ret
        slub_fault_hit_cnt++;
ffffffffc02013b6:	00018617          	auipc	a2,0x18
ffffffffc02013ba:	40263603          	ld	a2,1026(a2) # ffffffffc02197b8 <slub_fault_hit_cnt>
        slub_fault_left--;
ffffffffc02013be:	17fd                	addi	a5,a5,-1
ffffffffc02013c0:	00018597          	auipc	a1,0x18
ffffffffc02013c4:	40f5b023          	sd	a5,1024(a1) # ffffffffc02197c0 <slub_fault_left>
        slub_fault_hit_cnt++;
ffffffffc02013c8:	00160793          	addi	a5,a2,1
ffffffffc02013cc:	00018617          	auipc	a2,0x18
ffffffffc02013d0:	3ef63623          	sd	a5,1004(a2) # ffffffffc02197b8 <slub_fault_hit_cnt>
        base = NULL;
ffffffffc02013d4:	4501                	li	a0,0
    __sync_synchronize(); /* release */
ffffffffc02013d6:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc02013da:	0310000f          	fence	rw,w
ffffffffc02013de:	00072023          	sw	zero,0(a4)
    __sync_synchronize();
ffffffffc02013e2:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02013e6:	c681                	beqz	a3,ffffffffc02013ee <slub_pages_alloc+0x98>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc02013e8:	100167f3          	csrrsi	a5,sstatus,2
    return base;
ffffffffc02013ec:	8082                	ret
}
ffffffffc02013ee:	8082                	ret

ffffffffc02013f0 <slub_slab_destroy>:
static void slub_slab_destroy(struct slub_cache *c, struct slub_slab *s) {
    slub_page_t *pages = s->pages;   /* 先取出，描述符回池后可能被复用 */
    unsigned int npages = s->npages;
    slub_port_flags_t f;

    if (s->inuse != 0) {
ffffffffc02013f0:	4d98                	lw	a4,24(a1)
static void slub_slab_destroy(struct slub_cache *c, struct slub_slab *s) {
ffffffffc02013f2:	1101                	addi	sp,sp,-32
ffffffffc02013f4:	ec06                	sd	ra,24(sp)
ffffffffc02013f6:	e822                	sd	s0,16(sp)
ffffffffc02013f8:	e426                	sd	s1,8(sp)
    if (s->inuse != 0) {
ffffffffc02013fa:	18071963          	bnez	a4,ffffffffc020158c <slub_slab_destroy+0x19c>
ffffffffc02013fe:	8e2a                	mv	t3,a0
    unsigned int npages = s->npages;
ffffffffc0201400:	0105af03          	lw	t5,16(a1)
    slub_page_t *pages = s->pages;   /* 先取出，描述符回池后可能被复用 */
ffffffffc0201404:	6588                	ld	a0,8(a1)
    unsigned long s = read_csr(sstatus);
ffffffffc0201406:	10002ef3          	csrr	t4,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc020140a:	002efe93          	andi	t4,t4,2
    if (*flags) {
ffffffffc020140e:	140e9f63          	bnez	t4,ffffffffc020156c <slub_slab_destroy+0x17c>
    __sync_synchronize();
ffffffffc0201412:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0201416:	00018897          	auipc	a7,0x18
ffffffffc020141a:	3d288893          	addi	a7,a7,978 # ffffffffc02197e8 <slub_index_lock>
ffffffffc020141e:	4785                	li	a5,1
ffffffffc0201420:	0cf8a7af          	amoswap.w.aq	a5,a5,(a7)
ffffffffc0201424:	2781                	sext.w	a5,a5
ffffffffc0201426:	ffe5                	bnez	a5,ffffffffc020141e <slub_slab_destroy+0x2e>
    __sync_synchronize(); /* acquire */
ffffffffc0201428:	0330000f          	fence	rw,rw
    unsigned int lo = 0, hi = slub_index_nr, mid, i;
ffffffffc020142c:	00018f97          	auipc	t6,0x18
ffffffffc0201430:	3c0faf83          	lw	t6,960(t6) # ffffffffc02197ec <slub_index_nr>
        if (slub_index[mid]->base < s->base)
ffffffffc0201434:	00007317          	auipc	t1,0x7
ffffffffc0201438:	bfc30313          	addi	t1,t1,-1028 # ffffffffc0208030 <slub_index>
    unsigned int lo = 0, hi = slub_index_nr, mid, i;
ffffffffc020143c:	867e                	mv	a2,t6
    while (lo < hi) {
ffffffffc020143e:	02c7f663          	bgeu	a5,a2,ffffffffc020146a <slub_slab_destroy+0x7a>
        mid = lo + (hi - lo) / 2;
ffffffffc0201442:	40f6073b          	subw	a4,a2,a5
ffffffffc0201446:	0017571b          	srliw	a4,a4,0x1
ffffffffc020144a:	9f3d                	addw	a4,a4,a5
        if (slub_index[mid]->base < s->base)
ffffffffc020144c:	02071813          	slli	a6,a4,0x20
ffffffffc0201450:	01d85693          	srli	a3,a6,0x1d
ffffffffc0201454:	969a                	add	a3,a3,t1
ffffffffc0201456:	0006b803          	ld	a6,0(a3)
ffffffffc020145a:	6194                	ld	a3,0(a1)
ffffffffc020145c:	00083803          	ld	a6,0(a6)
ffffffffc0201460:	10d86063          	bltu	a6,a3,ffffffffc0201560 <slub_slab_destroy+0x170>
            hi = mid;
ffffffffc0201464:	863a                	mv	a2,a4
    while (lo < hi) {
ffffffffc0201466:	fcc7eee3          	bltu	a5,a2,ffffffffc0201442 <slub_slab_destroy+0x52>
    if (lo >= slub_index_nr || slub_index[lo] != s) {
ffffffffc020146a:	11f7f463          	bgeu	a5,t6,ffffffffc0201572 <slub_slab_destroy+0x182>
ffffffffc020146e:	02079713          	slli	a4,a5,0x20
ffffffffc0201472:	9301                	srli	a4,a4,0x20
ffffffffc0201474:	00007317          	auipc	t1,0x7
ffffffffc0201478:	bbc30313          	addi	t1,t1,-1092 # ffffffffc0208030 <slub_index>
ffffffffc020147c:	00371693          	slli	a3,a4,0x3
ffffffffc0201480:	969a                	add	a3,a3,t1
ffffffffc0201482:	6294                	ld	a3,0(a3)
ffffffffc0201484:	0ed59763          	bne	a1,a3,ffffffffc0201572 <slub_slab_destroy+0x182>
    for (i = lo; i + 1 < slub_index_nr; i++) slub_index[i] = slub_index[i + 1];
ffffffffc0201488:	2785                	addiw	a5,a5,1
ffffffffc020148a:	ffff881b          	addiw	a6,t6,-1
ffffffffc020148e:	03f7f563          	bgeu	a5,t6,ffffffffc02014b8 <slub_slab_destroy+0xc8>
ffffffffc0201492:	02079613          	slli	a2,a5,0x20
ffffffffc0201496:	01d65693          	srli	a3,a2,0x1d
ffffffffc020149a:	ffff881b          	addiw	a6,t6,-1
ffffffffc020149e:	969a                	add	a3,a3,t1
ffffffffc02014a0:	a029                	j	ffffffffc02014aa <slub_slab_destroy+0xba>
ffffffffc02014a2:	02079713          	slli	a4,a5,0x20
ffffffffc02014a6:	9301                	srli	a4,a4,0x20
ffffffffc02014a8:	2785                	addiw	a5,a5,1
ffffffffc02014aa:	6290                	ld	a2,0(a3)
ffffffffc02014ac:	070e                	slli	a4,a4,0x3
ffffffffc02014ae:	971a                	add	a4,a4,t1
ffffffffc02014b0:	e310                	sd	a2,0(a4)
ffffffffc02014b2:	06a1                	addi	a3,a3,8
ffffffffc02014b4:	fef817e3          	bne	a6,a5,ffffffffc02014a2 <slub_slab_destroy+0xb2>
    }
    slub_port_spin_lock(&slub_index_lock, &f);
    slub_index_remove_locked(s);
    s->state = 0;
    s->freelist = NULL;
    s->next = slub_pool_free;
ffffffffc02014b8:	00018797          	auipc	a5,0x18
ffffffffc02014bc:	3387b783          	ld	a5,824(a5) # ffffffffc02197f0 <slub_pool_free>
    slub_index_nr--;
ffffffffc02014c0:	00018717          	auipc	a4,0x18
ffffffffc02014c4:	33072623          	sw	a6,812(a4) # ffffffffc02197ec <slub_index_nr>
    s->state = 0;
ffffffffc02014c8:	00058ea3          	sb	zero,29(a1)
    s->next = slub_pool_free;
ffffffffc02014cc:	f59c                	sd	a5,40(a1)
    s->freelist = NULL;
ffffffffc02014ce:	0205b023          	sd	zero,32(a1)
    slub_pool_free = s;
ffffffffc02014d2:	00018797          	auipc	a5,0x18
ffffffffc02014d6:	30b7bf23          	sd	a1,798(a5) # ffffffffc02197f0 <slub_pool_free>
    __sync_synchronize(); /* release */
ffffffffc02014da:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc02014de:	0310000f          	fence	rw,w
ffffffffc02014e2:	0008a023          	sw	zero,0(a7)
    __sync_synchronize();
ffffffffc02014e6:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02014ea:	000e8463          	beqz	t4,ffffffffc02014f2 <slub_slab_destroy+0x102>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc02014ee:	100167f3          	csrrsi	a5,sstatus,2
    slub_port_spin_unlock(&slub_index_lock, &f);

    c->nr_slabs--;
ffffffffc02014f2:	034e2683          	lw	a3,52(t3)
    c->nr_slab_pages -= c->slab_pages;
ffffffffc02014f6:	038e2703          	lw	a4,56(t3)
    c->stat_slab_free++;
ffffffffc02014fa:	060e3783          	ld	a5,96(t3)
    c->nr_slab_pages -= c->slab_pages;
ffffffffc02014fe:	010e2603          	lw	a2,16(t3)
    c->nr_slabs--;
ffffffffc0201502:	36fd                	addiw	a3,a3,-1
    c->stat_slab_free++;
ffffffffc0201504:	0785                	addi	a5,a5,1
    c->nr_slab_pages -= c->slab_pages;
ffffffffc0201506:	9f11                	subw	a4,a4,a2
    slub_pages_free(pages, npages);
ffffffffc0201508:	020f1593          	slli	a1,t5,0x20
ffffffffc020150c:	9181                	srli	a1,a1,0x20
    c->nr_slabs--;
ffffffffc020150e:	02de2a23          	sw	a3,52(t3)
    c->nr_slab_pages -= c->slab_pages;
ffffffffc0201512:	02ee2c23          	sw	a4,56(t3)
    c->stat_slab_free++;
ffffffffc0201516:	06fe3023          	sd	a5,96(t3)
    unsigned long s = read_csr(sstatus);
ffffffffc020151a:	100024f3          	csrr	s1,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc020151e:	8889                	andi	s1,s1,2
    if (*flags) {
ffffffffc0201520:	e0b9                	bnez	s1,ffffffffc0201566 <slub_slab_destroy+0x176>
    __sync_synchronize();
ffffffffc0201522:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0201526:	00018417          	auipc	s0,0x18
ffffffffc020152a:	2ba40413          	addi	s0,s0,698 # ffffffffc02197e0 <slub_pmm_lock>
ffffffffc020152e:	4785                	li	a5,1
ffffffffc0201530:	0cf427af          	amoswap.w.aq	a5,a5,(s0)
ffffffffc0201534:	2781                	sext.w	a5,a5
ffffffffc0201536:	ffe5                	bnez	a5,ffffffffc020152e <slub_slab_destroy+0x13e>
    __sync_synchronize(); /* acquire */
ffffffffc0201538:	0330000f          	fence	rw,rw
}

static inline void slub_port_pages_free(slub_page_t *base, size_t npages) {
    /* npages 必须是当初分配时的原始请求值（buddy 断言 property==n） */
    free_pages(base, npages);
ffffffffc020153c:	afbff0ef          	jal	ffffffffc0201036 <free_pages>
    __sync_synchronize(); /* release */
ffffffffc0201540:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0201544:	0310000f          	fence	rw,w
ffffffffc0201548:	00042023          	sw	zero,0(s0)
    __sync_synchronize();
ffffffffc020154c:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0201550:	c099                	beqz	s1,ffffffffc0201556 <slub_slab_destroy+0x166>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0201552:	100167f3          	csrrsi	a5,sstatus,2
}
ffffffffc0201556:	60e2                	ld	ra,24(sp)
ffffffffc0201558:	6442                	ld	s0,16(sp)
ffffffffc020155a:	64a2                	ld	s1,8(sp)
ffffffffc020155c:	6105                	addi	sp,sp,32
ffffffffc020155e:	8082                	ret
            lo = mid + 1;
ffffffffc0201560:	0017079b          	addiw	a5,a4,1
ffffffffc0201564:	bde9                	j	ffffffffc020143e <slub_slab_destroy+0x4e>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0201566:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020156a:	bf65                	j	ffffffffc0201522 <slub_slab_destroy+0x132>
ffffffffc020156c:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0201570:	b54d                	j	ffffffffc0201412 <slub_slab_destroy+0x22>
        slub_port_panic("slub: slab %lx is not registered",
ffffffffc0201572:	6194                	ld	a3,0(a1)
ffffffffc0201574:	00002617          	auipc	a2,0x2
ffffffffc0201578:	55460613          	addi	a2,a2,1364 # ffffffffc0203ac8 <etext+0x816>
ffffffffc020157c:	13f00593          	li	a1,319
ffffffffc0201580:	00002517          	auipc	a0,0x2
ffffffffc0201584:	53850513          	addi	a0,a0,1336 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0201588:	c45fe0ef          	jal	ffffffffc02001cc <__panic>
        slub_port_panic("slub: destroy slab %lx with %lu objects in use",
ffffffffc020158c:	6194                	ld	a3,0(a1)
ffffffffc020158e:	1702                	slli	a4,a4,0x20
ffffffffc0201590:	9301                	srli	a4,a4,0x20
ffffffffc0201592:	00002617          	auipc	a2,0x2
ffffffffc0201596:	4f660613          	addi	a2,a2,1270 # ffffffffc0203a88 <etext+0x7d6>
ffffffffc020159a:	19900593          	li	a1,409
ffffffffc020159e:	00002517          	auipc	a0,0x2
ffffffffc02015a2:	51a50513          	addi	a0,a0,1306 # ffffffffc0203ab8 <etext+0x806>
ffffffffc02015a6:	c27fe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02015aa <slub_put_objects>:

#define SLUB_PUT_ALL 0  /* sheaf -> barn -> slab 全级联 */
#define SLUB_PUT_SLAB 1 /* 只回 slab（slub_shrink 用） */

static void slub_put_objects(unsigned int cls, void **objs, unsigned int n,
                             int target) {
ffffffffc02015aa:	7119                	addi	sp,sp,-128
ffffffffc02015ac:	f862                	sd	s8,48(sp)
ffffffffc02015ae:	f466                	sd	s9,40(sp)
ffffffffc02015b0:	02051c13          	slli	s8,a0,0x20
ffffffffc02015b4:	fc86                	sd	ra,120(sp)
ffffffffc02015b6:	f8a2                	sd	s0,112(sp)
ffffffffc02015b8:	f4a6                	sd	s1,104(sp)
ffffffffc02015ba:	8caa                	mv	s9,a0
    struct slub_cache *c = &slub_caches[cls];
ffffffffc02015bc:	020c5c13          	srli	s8,s8,0x20
    slub_port_flags_t f;
    unsigned int i = 0;

    if (target == SLUB_PUT_ALL) {
ffffffffc02015c0:	28069463          	bnez	a3,ffffffffc0201848 <slub_put_objects+0x29e>
    if (cpu >= SLUB_NCPUS) {
ffffffffc02015c4:	00007797          	auipc	a5,0x7
ffffffffc02015c8:	a3c7a783          	lw	a5,-1476(a5) # ffffffffc0208000 <boot_hartid>
ffffffffc02015cc:	40079763          	bnez	a5,ffffffffc02019da <slub_put_objects+0x430>
    unsigned long s = read_csr(sstatus);
ffffffffc02015d0:	10002ef3          	csrr	t4,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc02015d4:	002efe93          	andi	t4,t4,2
    if (*flags) {
ffffffffc02015d8:	000e8463          	beqz	t4,ffffffffc02015e0 <slub_put_objects+0x36>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc02015dc:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc02015e0:	0330000f          	fence	rw,rw
    if (n > sf->cap - sf->size) n = sf->cap - sf->size;
ffffffffc02015e4:	00018f17          	auipc	t5,0x18
ffffffffc02015e8:	b8cf0f13          	addi	t5,t5,-1140 # ffffffffc0219170 <slub_cc>
ffffffffc02015ec:	005c1793          	slli	a5,s8,0x5
ffffffffc02015f0:	97fa                	add	a5,a5,t5
ffffffffc02015f2:	0087a383          	lw	t2,8(a5)
ffffffffc02015f6:	47dc                	lw	a5,12(a5)
ffffffffc02015f8:	407787bb          	subw	a5,a5,t2
ffffffffc02015fc:	88be                	mv	a7,a5
ffffffffc02015fe:	00f67363          	bgeu	a2,a5,ffffffffc0201604 <slub_put_objects+0x5a>
ffffffffc0201602:	88b2                	mv	a7,a2
ffffffffc0201604:	00088e1b          	sext.w	t3,a7
    for (i = 0; i < n; i++) sf->objs[sf->size + i] = objs[i];
ffffffffc0201608:	020e0663          	beqz	t3,ffffffffc0201634 <slub_put_objects+0x8a>
ffffffffc020160c:	005c1313          	slli	t1,s8,0x5
ffffffffc0201610:	011388bb          	addw	a7,t2,a7
ffffffffc0201614:	937a                	add	t1,t1,t5
ffffffffc0201616:	86ae                	mv	a3,a1
ffffffffc0201618:	879e                	mv	a5,t2
ffffffffc020161a:	00033703          	ld	a4,0(t1)
ffffffffc020161e:	6288                	ld	a0,0(a3)
ffffffffc0201620:	02079f93          	slli	t6,a5,0x20
ffffffffc0201624:	01dfd813          	srli	a6,t6,0x1d
ffffffffc0201628:	9742                	add	a4,a4,a6
ffffffffc020162a:	2785                	addiw	a5,a5,1
ffffffffc020162c:	e308                	sd	a0,0(a4)
ffffffffc020162e:	06a1                	addi	a3,a3,8
ffffffffc0201630:	ff1795e3          	bne	a5,a7,ffffffffc020161a <slub_put_objects+0x70>
    sf->size += n;
ffffffffc0201634:	005c1793          	slli	a5,s8,0x5
ffffffffc0201638:	97fa                	add	a5,a5,t5
    if (n > sf->cap - sf->size) n = sf->cap - sf->size;
ffffffffc020163a:	4fd8                	lw	a4,28(a5)
ffffffffc020163c:	0187a283          	lw	t0,24(a5)
    sf->size += n;
ffffffffc0201640:	01c383bb          	addw	t2,t2,t3
ffffffffc0201644:	0077a423          	sw	t2,8(a5)
    if (n > sf->cap - sf->size) n = sf->cap - sf->size;
ffffffffc0201648:	405707bb          	subw	a5,a4,t0
        struct slub_cpu_cache *cc = &slub_cc[slub_cpu()][cls];

        slub_port_local_lock(&f);
        i += slub_sheaf_push(&cc->main, objs + i, n - i);
        i += slub_sheaf_push(&cc->spare, objs + i, n - i);
ffffffffc020164c:	41c6073b          	subw	a4,a2,t3
    if (n > sf->cap - sf->size) n = sf->cap - sf->size;
ffffffffc0201650:	88be                	mv	a7,a5
ffffffffc0201652:	00f77363          	bgeu	a4,a5,ffffffffc0201658 <slub_put_objects+0xae>
ffffffffc0201656:	88ba                	mv	a7,a4
ffffffffc0201658:	0008839b          	sext.w	t2,a7
    for (i = 0; i < n; i++) sf->objs[sf->size + i] = objs[i];
ffffffffc020165c:	02038a63          	beqz	t2,ffffffffc0201690 <slub_put_objects+0xe6>
ffffffffc0201660:	020e1793          	slli	a5,t3,0x20
ffffffffc0201664:	01d7d693          	srli	a3,a5,0x1d
ffffffffc0201668:	005c1313          	slli	t1,s8,0x5
ffffffffc020166c:	011288bb          	addw	a7,t0,a7
ffffffffc0201670:	96ae                	add	a3,a3,a1
ffffffffc0201672:	937a                	add	t1,t1,t5
        i += slub_sheaf_push(&cc->spare, objs + i, n - i);
ffffffffc0201674:	8796                	mv	a5,t0
    for (i = 0; i < n; i++) sf->objs[sf->size + i] = objs[i];
ffffffffc0201676:	01033703          	ld	a4,16(t1)
ffffffffc020167a:	6288                	ld	a0,0(a3)
ffffffffc020167c:	02079f93          	slli	t6,a5,0x20
ffffffffc0201680:	01dfd813          	srli	a6,t6,0x1d
ffffffffc0201684:	9742                	add	a4,a4,a6
ffffffffc0201686:	2785                	addiw	a5,a5,1
ffffffffc0201688:	e308                	sd	a0,0(a4)
ffffffffc020168a:	06a1                	addi	a3,a3,8
ffffffffc020168c:	ff1795e3          	bne	a5,a7,ffffffffc0201676 <slub_put_objects+0xcc>
    sf->size += n;
ffffffffc0201690:	005c1793          	slli	a5,s8,0x5
ffffffffc0201694:	007282bb          	addw	t0,t0,t2
ffffffffc0201698:	97fa                	add	a5,a5,t5
ffffffffc020169a:	0057ac23          	sw	t0,24(a5)
        i += slub_sheaf_push(&cc->spare, objs + i, n - i);
ffffffffc020169e:	01c3873b          	addw	a4,t2,t3
    __sync_synchronize();
ffffffffc02016a2:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02016a6:	000e8463          	beqz	t4,ffffffffc02016ae <slub_put_objects+0x104>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc02016aa:	100167f3          	csrrsi	a5,sstatus,2
        slub_port_local_unlock(&f);
        if (i == n) return;
ffffffffc02016ae:	26e60563          	beq	a2,a4,ffffffffc0201918 <slub_put_objects+0x36e>

        i += slub_barn_put(cls, objs + i, n - i); /* 批量拷贝后已释放本地锁 */
ffffffffc02016b2:	40e6083b          	subw	a6,a2,a4
    unsigned long s = read_csr(sstatus);
ffffffffc02016b6:	10002ff3          	csrr	t6,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc02016ba:	002fff93          	andi	t6,t6,2
    if (*flags) {
ffffffffc02016be:	2e0f9e63          	bnez	t6,ffffffffc02019ba <slub_put_objects+0x410>
    __sync_synchronize();
ffffffffc02016c2:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc02016c6:	002c1513          	slli	a0,s8,0x2
ffffffffc02016ca:	9562                	add	a0,a0,s8
ffffffffc02016cc:	050e                	slli	a0,a0,0x3
ffffffffc02016ce:	00018f17          	auipc	t5,0x18
ffffffffc02016d2:	ba2f0f13          	addi	t5,t5,-1118 # ffffffffc0219270 <slub_barns>
ffffffffc02016d6:	957a                	add	a0,a0,t5
ffffffffc02016d8:	4785                	li	a5,1
ffffffffc02016da:	0cf527af          	amoswap.w.aq	a5,a5,(a0)
ffffffffc02016de:	2781                	sext.w	a5,a5
ffffffffc02016e0:	ffe5                	bnez	a5,ffffffffc02016d8 <slub_put_objects+0x12e>
    __sync_synchronize(); /* acquire */
ffffffffc02016e2:	0330000f          	fence	rw,rw
    i = b->cap - b->size;
ffffffffc02016e6:	002c1693          	slli	a3,s8,0x2
ffffffffc02016ea:	96e2                	add	a3,a3,s8
ffffffffc02016ec:	068e                	slli	a3,a3,0x3
ffffffffc02016ee:	96fa                	add	a3,a3,t5
ffffffffc02016f0:	4a9c                	lw	a5,16(a3)
ffffffffc02016f2:	4ad4                	lw	a3,20(a3)
ffffffffc02016f4:	9e9d                	subw	a3,a3,a5
    if (i > n) i = n;
ffffffffc02016f6:	8e36                	mv	t3,a3
ffffffffc02016f8:	2ad86f63          	bltu	a6,a3,ffffffffc02019b6 <slub_put_objects+0x40c>
        i += slub_barn_put(cls, objs + i, n - i); /* 批量拷贝后已释放本地锁 */
ffffffffc02016fc:	01c704bb          	addw	s1,a4,t3
    if (i > n) i = n;
ffffffffc0201700:	000e041b          	sext.w	s0,t3
        i += slub_barn_put(cls, objs + i, n - i); /* 批量拷贝后已释放本地锁 */
ffffffffc0201704:	8826                	mv	a6,s1
    for (k = 0; k < i; k++) b->objs[b->size + k] = objs[k];
ffffffffc0201706:	2a040d63          	beqz	s0,ffffffffc02019c0 <slub_put_objects+0x416>
ffffffffc020170a:	002c1393          	slli	t2,s8,0x2
ffffffffc020170e:	02071693          	slli	a3,a4,0x20
ffffffffc0201712:	93e2                	add	t2,t2,s8
ffffffffc0201714:	01d6d713          	srli	a4,a3,0x1d
ffffffffc0201718:	00339e93          	slli	t4,t2,0x3
ffffffffc020171c:	00e586b3          	add	a3,a1,a4
ffffffffc0201720:	01c78e3b          	addw	t3,a5,t3
ffffffffc0201724:	9efa                	add	t4,t4,t5
ffffffffc0201726:	008eb703          	ld	a4,8(t4)
ffffffffc020172a:	0006b883          	ld	a7,0(a3)
ffffffffc020172e:	02079293          	slli	t0,a5,0x20
ffffffffc0201732:	01d2d313          	srli	t1,t0,0x1d
ffffffffc0201736:	971a                	add	a4,a4,t1
ffffffffc0201738:	2785                	addiw	a5,a5,1
ffffffffc020173a:	01173023          	sd	a7,0(a4)
ffffffffc020173e:	06a1                	addi	a3,a3,8
ffffffffc0201740:	fefe13e3          	bne	t3,a5,ffffffffc0201726 <slub_put_objects+0x17c>
    b->size += i;
ffffffffc0201744:	038e                	slli	t2,t2,0x3
ffffffffc0201746:	9f1e                	add	t5,t5,t2
    if (i != 0) b->stat_put += i;
ffffffffc0201748:	020f3783          	ld	a5,32(t5)
ffffffffc020174c:	1402                	slli	s0,s0,0x20
ffffffffc020174e:	9001                	srli	s0,s0,0x20
ffffffffc0201750:	97a2                	add	a5,a5,s0
    b->size += i;
ffffffffc0201752:	01cf2823          	sw	t3,16(t5)
    if (i != 0) b->stat_put += i;
ffffffffc0201756:	02ff3023          	sd	a5,32(t5)
    __sync_synchronize(); /* release */
ffffffffc020175a:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc020175e:	0310000f          	fence	rw,w
ffffffffc0201762:	00052023          	sw	zero,0(a0)
    __sync_synchronize();
ffffffffc0201766:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc020176a:	260f9563          	bnez	t6,ffffffffc02019d4 <slub_put_objects+0x42a>
        if (i == n) return;
ffffffffc020176e:	1a960563          	beq	a2,s1,ffffffffc0201918 <slub_put_objects+0x36e>
ffffffffc0201772:	f06a                	sd	s10,32(sp)
ffffffffc0201774:	004c1d13          	slli	s10,s8,0x4
ffffffffc0201778:	418d0d33          	sub	s10,s10,s8
ffffffffc020177c:	e0da                	sd	s6,64(sp)
ffffffffc020177e:	ec6e                	sd	s11,24(sp)
ffffffffc0201780:	0d0e                	slli	s10,s10,0x3
    unsigned long s = read_csr(sstatus);
ffffffffc0201782:	10002473          	csrr	s0,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0201786:	8809                	andi	s0,s0,2
    if (*flags) {
ffffffffc0201788:	ec69                	bnez	s0,ffffffffc0201862 <slub_put_objects+0x2b8>
    __sync_synchronize();
ffffffffc020178a:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc020178e:	00018d97          	auipc	s11,0x18
ffffffffc0201792:	c22d8d93          	addi	s11,s11,-990 # ffffffffc02193b0 <slub_caches>
ffffffffc0201796:	014d0b13          	addi	s6,s10,20
ffffffffc020179a:	9b6e                	add	s6,s6,s11
ffffffffc020179c:	4785                	li	a5,1
ffffffffc020179e:	0cfb27af          	amoswap.w.aq	a5,a5,(s6)
ffffffffc02017a2:	2781                	sext.w	a5,a5
ffffffffc02017a4:	ffe5                	bnez	a5,ffffffffc020179c <slub_put_objects+0x1f2>
    __sync_synchronize(); /* acquire */
ffffffffc02017a6:	0330000f          	fence	rw,rw
    }

    slub_port_spin_lock(&c->lock, &f);
    for (; i < n; i++) slub_slab_release_obj(c, cls, objs[i]);
ffffffffc02017aa:	14c87b63          	bgeu	a6,a2,ffffffffc0201900 <slub_put_objects+0x356>
ffffffffc02017ae:	e4d6                	sd	s5,72(sp)
ffffffffc02017b0:	fff60a9b          	addiw	s5,a2,-1
ffffffffc02017b4:	410a8abb          	subw	s5,s5,a6
ffffffffc02017b8:	1a82                	slli	s5,s5,0x20
ffffffffc02017ba:	1802                	slli	a6,a6,0x20
ffffffffc02017bc:	02085813          	srli	a6,a6,0x20
ffffffffc02017c0:	020ada93          	srli	s5,s5,0x20
ffffffffc02017c4:	9ac2                	add	s5,s5,a6
    if (((uintptr_t)obj - s->base) % c->objsize != 0) {
ffffffffc02017c6:	004c1493          	slli	s1,s8,0x4
ffffffffc02017ca:	00858793          	addi	a5,a1,8
ffffffffc02017ce:	418484b3          	sub	s1,s1,s8
ffffffffc02017d2:	0a8e                	slli	s5,s5,0x3
ffffffffc02017d4:	ecce                	sd	s3,88(sp)
ffffffffc02017d6:	080e                	slli	a6,a6,0x3
ffffffffc02017d8:	9abe                	add	s5,s5,a5
ffffffffc02017da:	00349993          	slli	s3,s1,0x3
    struct slub_cache *c = &slub_caches[cls];
ffffffffc02017de:	01ad87b3          	add	a5,s11,s10
ffffffffc02017e2:	f0ca                	sd	s2,96(sp)
ffffffffc02017e4:	e8d2                	sd	s4,80(sp)
ffffffffc02017e6:	fc5e                	sd	s7,56(sp)
ffffffffc02017e8:	01058a33          	add	s4,a1,a6
    if (((uintptr_t)obj - s->base) % c->objsize != 0) {
ffffffffc02017ec:	99ee                	add	s3,s3,s11
    struct slub_cache *c = &slub_caches[cls];
ffffffffc02017ee:	e43e                	sd	a5,8(sp)
        s = slub_index[mid];
ffffffffc02017f0:	00007917          	auipc	s2,0x7
ffffffffc02017f4:	84090913          	addi	s2,s2,-1984 # ffffffffc0208030 <slub_index>
    if (s->state == SLUB_SLAB_EMPTY) {
ffffffffc02017f8:	4b8d                	li	s7,3
    for (; i < n; i++) slub_slab_release_obj(c, cls, objs[i]);
ffffffffc02017fa:	000a3683          	ld	a3,0(s4)
    unsigned int lo = 0, hi = slub_index_nr, mid;
ffffffffc02017fe:	00018817          	auipc	a6,0x18
ffffffffc0201802:	fee82803          	lw	a6,-18(a6) # ffffffffc02197ec <slub_index_nr>
ffffffffc0201806:	4501                	li	a0,0
    while (lo < hi) {
ffffffffc0201808:	03057363          	bgeu	a0,a6,ffffffffc020182e <slub_put_objects+0x284>
        mid = lo + (hi - lo) / 2;
ffffffffc020180c:	40a807bb          	subw	a5,a6,a0
ffffffffc0201810:	0017d79b          	srliw	a5,a5,0x1
ffffffffc0201814:	9fa9                	addw	a5,a5,a0
        s = slub_index[mid];
ffffffffc0201816:	02079593          	slli	a1,a5,0x20
ffffffffc020181a:	01d5d613          	srli	a2,a1,0x1d
ffffffffc020181e:	964a                	add	a2,a2,s2
ffffffffc0201820:	620c                	ld	a1,0(a2)
        if (a < s->base) {
ffffffffc0201822:	6190                	ld	a2,0(a1)
ffffffffc0201824:	04c6f263          	bgeu	a3,a2,ffffffffc0201868 <slub_put_objects+0x2be>
            hi = mid;
ffffffffc0201828:	883e                	mv	a6,a5
    while (lo < hi) {
ffffffffc020182a:	ff0561e3          	bltu	a0,a6,ffffffffc020180c <slub_put_objects+0x262>
        slub_port_panic("slub: object %lx does not belong to class %lu",
ffffffffc020182e:	8762                	mv	a4,s8
ffffffffc0201830:	00002617          	auipc	a2,0x2
ffffffffc0201834:	30860613          	addi	a2,a2,776 # ffffffffc0203b38 <etext+0x886>
ffffffffc0201838:	21c00593          	li	a1,540
ffffffffc020183c:	00002517          	auipc	a0,0x2
ffffffffc0201840:	27c50513          	addi	a0,a0,636 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0201844:	989fe0ef          	jal	ffffffffc02001cc <__panic>
ffffffffc0201848:	f06a                	sd	s10,32(sp)
ffffffffc020184a:	004c1d13          	slli	s10,s8,0x4
ffffffffc020184e:	418d0d33          	sub	s10,s10,s8
ffffffffc0201852:	e0da                	sd	s6,64(sp)
ffffffffc0201854:	ec6e                	sd	s11,24(sp)
    unsigned int i = 0;
ffffffffc0201856:	4801                	li	a6,0
ffffffffc0201858:	0d0e                	slli	s10,s10,0x3
    unsigned long s = read_csr(sstatus);
ffffffffc020185a:	10002473          	csrr	s0,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc020185e:	8809                	andi	s0,s0,2
    if (*flags) {
ffffffffc0201860:	d40d                	beqz	s0,ffffffffc020178a <slub_put_objects+0x1e0>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0201862:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0201866:	b715                	j	ffffffffc020178a <slub_put_objects+0x1e0>
        } else if (a >= s->base + (uintptr_t)s->npages * SLUB_PAGE_SIZE) {
ffffffffc0201868:	0105e503          	lwu	a0,16(a1)
ffffffffc020186c:	0532                	slli	a0,a0,0xc
ffffffffc020186e:	9532                	add	a0,a0,a2
ffffffffc0201870:	00a6e563          	bltu	a3,a0,ffffffffc020187a <slub_put_objects+0x2d0>
            lo = mid + 1;
ffffffffc0201874:	0017851b          	addiw	a0,a5,1
ffffffffc0201878:	bf41                	j	ffffffffc0201808 <slub_put_objects+0x25e>
    if (s == NULL || s->cls != cls) {
ffffffffc020187a:	01c5c783          	lbu	a5,28(a1)
ffffffffc020187e:	fb9798e3          	bne	a5,s9,ffffffffc020182e <slub_put_objects+0x284>
    if (((uintptr_t)obj - s->base) % c->objsize != 0) {
ffffffffc0201882:	0009b703          	ld	a4,0(s3)
ffffffffc0201886:	40c687b3          	sub	a5,a3,a2
ffffffffc020188a:	02e7f7b3          	remu	a5,a5,a4
ffffffffc020188e:	16079f63          	bnez	a5,ffffffffc0201a0c <slub_put_objects+0x462>
    if (s->state == SLUB_SLAB_EMPTY) {
ffffffffc0201892:	01d5c703          	lbu	a4,29(a1)
ffffffffc0201896:	19770763          	beq	a4,s7,ffffffffc0201a24 <slub_put_objects+0x47a>
    s->inuse--;
ffffffffc020189a:	4d9c                	lw	a5,24(a1)
    *(void **)obj = s->freelist; /* 侵入式空闲链 */
ffffffffc020189c:	7188                	ld	a0,32(a1)
    s->inuse--;
ffffffffc020189e:	37fd                	addiw	a5,a5,-1
    *(void **)obj = s->freelist; /* 侵入式空闲链 */
ffffffffc02018a0:	e288                	sd	a0,0(a3)
    s->freelist = obj;
ffffffffc02018a2:	f194                	sd	a3,32(a1)
    s->inuse--;
ffffffffc02018a4:	cd9c                	sw	a5,24(a1)
    if (s->inuse == 0) {
ffffffffc02018a6:	e3c1                	bnez	a5,ffffffffc0201926 <slub_put_objects+0x37c>
        if (s->state == SLUB_SLAB_PARTIAL) {
ffffffffc02018a8:	4789                	li	a5,2
ffffffffc02018aa:	0af70863          	beq	a4,a5,ffffffffc020195a <slub_put_objects+0x3b0>
        } else if (s->state == SLUB_SLAB_FULL) {
ffffffffc02018ae:	4785                	li	a5,1
ffffffffc02018b0:	00f71763          	bne	a4,a5,ffffffffc02018be <slub_put_objects+0x314>
            c->nr_full--;
ffffffffc02018b4:	0309a783          	lw	a5,48(s3)
ffffffffc02018b8:	37fd                	addiw	a5,a5,-1
ffffffffc02018ba:	02f9a823          	sw	a5,48(s3)
        s->state = SLUB_SLAB_EMPTY;
ffffffffc02018be:	01758ea3          	sb	s7,29(a1)
        if (c->nr_empty < SLUB_EMPTY_KEEP) {
ffffffffc02018c2:	02c9a783          	lw	a5,44(s3)
ffffffffc02018c6:	4705                	li	a4,1
ffffffffc02018c8:	08f76563          	bltu	a4,a5,ffffffffc0201952 <slub_put_objects+0x3a8>
            s->next = c->empty;
ffffffffc02018cc:	0209b703          	ld	a4,32(s3)
            c->nr_empty++;
ffffffffc02018d0:	2785                	addiw	a5,a5,1
            s->next = c->empty;
ffffffffc02018d2:	f598                	sd	a4,40(a1)
            c->nr_empty++;
ffffffffc02018d4:	02f9a623          	sw	a5,44(s3)
            c->empty = s;
ffffffffc02018d8:	02b9b023          	sd	a1,32(s3)
    c->inuse_objs--;
ffffffffc02018dc:	0409b703          	ld	a4,64(s3)
    c->stat_flush++;
ffffffffc02018e0:	0509b783          	ld	a5,80(s3)
    for (; i < n; i++) slub_slab_release_obj(c, cls, objs[i]);
ffffffffc02018e4:	0a21                	addi	s4,s4,8
    c->inuse_objs--;
ffffffffc02018e6:	177d                	addi	a4,a4,-1
    c->stat_flush++;
ffffffffc02018e8:	0785                	addi	a5,a5,1
    c->inuse_objs--;
ffffffffc02018ea:	04e9b023          	sd	a4,64(s3)
    c->stat_flush++;
ffffffffc02018ee:	04f9b823          	sd	a5,80(s3)
    for (; i < n; i++) slub_slab_release_obj(c, cls, objs[i]);
ffffffffc02018f2:	f14a94e3          	bne	s5,s4,ffffffffc02017fa <slub_put_objects+0x250>
ffffffffc02018f6:	7906                	ld	s2,96(sp)
ffffffffc02018f8:	69e6                	ld	s3,88(sp)
ffffffffc02018fa:	6a46                	ld	s4,80(sp)
ffffffffc02018fc:	6aa6                	ld	s5,72(sp)
ffffffffc02018fe:	7be2                	ld	s7,56(sp)
    __sync_synchronize(); /* release */
ffffffffc0201900:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0201904:	0310000f          	fence	rw,w
ffffffffc0201908:	000b2023          	sw	zero,0(s6)
    __sync_synchronize();
ffffffffc020190c:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0201910:	e045                	bnez	s0,ffffffffc02019b0 <slub_put_objects+0x406>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0201912:	6b06                	ld	s6,64(sp)
ffffffffc0201914:	7d02                	ld	s10,32(sp)
ffffffffc0201916:	6de2                	ld	s11,24(sp)
    slub_port_spin_unlock(&c->lock, &f);
}
ffffffffc0201918:	70e6                	ld	ra,120(sp)
ffffffffc020191a:	7446                	ld	s0,112(sp)
ffffffffc020191c:	74a6                	ld	s1,104(sp)
ffffffffc020191e:	7c42                	ld	s8,48(sp)
ffffffffc0201920:	7ca2                	ld	s9,40(sp)
ffffffffc0201922:	6109                	addi	sp,sp,128
ffffffffc0201924:	8082                	ret
    } else if (was_full) {
ffffffffc0201926:	4785                	li	a5,1
ffffffffc0201928:	faf71ae3          	bne	a4,a5,ffffffffc02018dc <slub_put_objects+0x332>
        s->state = SLUB_SLAB_PARTIAL;
ffffffffc020192c:	4789                	li	a5,2
ffffffffc020192e:	00f58ea3          	sb	a5,29(a1)
        s->next = c->partial;
ffffffffc0201932:	0189b783          	ld	a5,24(s3)
        c->nr_partial++;
ffffffffc0201936:	0289a703          	lw	a4,40(s3)
        s->next = c->partial;
ffffffffc020193a:	f59c                	sd	a5,40(a1)
        c->nr_full--;
ffffffffc020193c:	0309a783          	lw	a5,48(s3)
        c->nr_partial++;
ffffffffc0201940:	2705                	addiw	a4,a4,1
        c->partial = s;
ffffffffc0201942:	00b9bc23          	sd	a1,24(s3)
        c->nr_full--;
ffffffffc0201946:	37fd                	addiw	a5,a5,-1
        c->nr_partial++;
ffffffffc0201948:	02e9a423          	sw	a4,40(s3)
        c->nr_full--;
ffffffffc020194c:	02f9a823          	sw	a5,48(s3)
ffffffffc0201950:	b771                	j	ffffffffc02018dc <slub_put_objects+0x332>
            slub_slab_destroy(c, s);
ffffffffc0201952:	6522                	ld	a0,8(sp)
ffffffffc0201954:	a9dff0ef          	jal	ffffffffc02013f0 <slub_slab_destroy>
ffffffffc0201958:	b751                	j	ffffffffc02018dc <slub_put_objects+0x332>
    struct slub_slab **pp = &c->partial;
ffffffffc020195a:	00349793          	slli	a5,s1,0x3
ffffffffc020195e:	97ee                	add	a5,a5,s11
    while (*pp != NULL && *pp != s) pp = &(*pp)->next;
ffffffffc0201960:	6f9c                	ld	a5,24(a5)
ffffffffc0201962:	cb99                	beqz	a5,ffffffffc0201978 <slub_put_objects+0x3ce>
    struct slub_slab **pp = &c->partial;
ffffffffc0201964:	018d0713          	addi	a4,s10,24
ffffffffc0201968:	976e                	add	a4,a4,s11
    while (*pp != NULL && *pp != s) pp = &(*pp)->next;
ffffffffc020196a:	631c                	ld	a5,0(a4)
ffffffffc020196c:	02f58363          	beq	a1,a5,ffffffffc0201992 <slub_put_objects+0x3e8>
ffffffffc0201970:	02878713          	addi	a4,a5,40
ffffffffc0201974:	779c                	ld	a5,40(a5)
ffffffffc0201976:	fbfd                	bnez	a5,ffffffffc020196c <slub_put_objects+0x3c2>
        slub_port_panic("slub: partial slab %lx is not linked",
ffffffffc0201978:	86b2                	mv	a3,a2
ffffffffc020197a:	18a00593          	li	a1,394
ffffffffc020197e:	00002617          	auipc	a2,0x2
ffffffffc0201982:	24a60613          	addi	a2,a2,586 # ffffffffc0203bc8 <etext+0x916>
ffffffffc0201986:	00002517          	auipc	a0,0x2
ffffffffc020198a:	13250513          	addi	a0,a0,306 # ffffffffc0203ab8 <etext+0x806>
ffffffffc020198e:	83ffe0ef          	jal	ffffffffc02001cc <__panic>
    c->nr_partial--;
ffffffffc0201992:	004c1793          	slli	a5,s8,0x4
ffffffffc0201996:	418787b3          	sub	a5,a5,s8
ffffffffc020199a:	078e                	slli	a5,a5,0x3
    *pp = s->next;
ffffffffc020199c:	7590                	ld	a2,40(a1)
    c->nr_partial--;
ffffffffc020199e:	97ee                	add	a5,a5,s11
ffffffffc02019a0:	5794                	lw	a3,40(a5)
    *pp = s->next;
ffffffffc02019a2:	e310                	sd	a2,0(a4)
    s->next = NULL;
ffffffffc02019a4:	0205b423          	sd	zero,40(a1)
    c->nr_partial--;
ffffffffc02019a8:	fff6871b          	addiw	a4,a3,-1
ffffffffc02019ac:	d798                	sw	a4,40(a5)
}
ffffffffc02019ae:	bf01                	j	ffffffffc02018be <slub_put_objects+0x314>
ffffffffc02019b0:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02019b4:	bfb9                	j	ffffffffc0201912 <slub_put_objects+0x368>
    if (i > n) i = n;
ffffffffc02019b6:	8e42                	mv	t3,a6
ffffffffc02019b8:	b391                	j	ffffffffc02016fc <slub_put_objects+0x152>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc02019ba:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02019be:	b311                	j	ffffffffc02016c2 <slub_put_objects+0x118>
    __sync_synchronize(); /* release */
ffffffffc02019c0:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc02019c4:	0310000f          	fence	rw,w
ffffffffc02019c8:	00052023          	sw	zero,0(a0)
    __sync_synchronize();
ffffffffc02019cc:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02019d0:	da0f81e3          	beqz	t6,ffffffffc0201772 <slub_put_objects+0x1c8>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc02019d4:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02019d8:	bb59                	j	ffffffffc020176e <slub_put_objects+0x1c4>
        slub_port_panic("slub: cpu id %lu >= SLUB_NCPUS %d (build with a "
ffffffffc02019da:	00006697          	auipc	a3,0x6
ffffffffc02019de:	6266e683          	lwu	a3,1574(a3) # ffffffffc0208000 <boot_hartid>
ffffffffc02019e2:	4705                	li	a4,1
ffffffffc02019e4:	00002617          	auipc	a2,0x2
ffffffffc02019e8:	10c60613          	addi	a2,a2,268 # ffffffffc0203af0 <etext+0x83e>
ffffffffc02019ec:	0dd00593          	li	a1,221
ffffffffc02019f0:	00002517          	auipc	a0,0x2
ffffffffc02019f4:	0c850513          	addi	a0,a0,200 # ffffffffc0203ab8 <etext+0x806>
ffffffffc02019f8:	f0ca                	sd	s2,96(sp)
ffffffffc02019fa:	ecce                	sd	s3,88(sp)
ffffffffc02019fc:	e8d2                	sd	s4,80(sp)
ffffffffc02019fe:	e4d6                	sd	s5,72(sp)
ffffffffc0201a00:	e0da                	sd	s6,64(sp)
ffffffffc0201a02:	fc5e                	sd	s7,56(sp)
ffffffffc0201a04:	f06a                	sd	s10,32(sp)
ffffffffc0201a06:	ec6e                	sd	s11,24(sp)
ffffffffc0201a08:	fc4fe0ef          	jal	ffffffffc02001cc <__panic>
        slub_port_panic("slub: object %lx is not at a slot boundary",
ffffffffc0201a0c:	00002617          	auipc	a2,0x2
ffffffffc0201a10:	15c60613          	addi	a2,a2,348 # ffffffffc0203b68 <etext+0x8b6>
ffffffffc0201a14:	22000593          	li	a1,544
ffffffffc0201a18:	00002517          	auipc	a0,0x2
ffffffffc0201a1c:	0a050513          	addi	a0,a0,160 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0201a20:	facfe0ef          	jal	ffffffffc02001cc <__panic>
        slub_port_panic("slub: object %lx comes from an empty slab",
ffffffffc0201a24:	00002617          	auipc	a2,0x2
ffffffffc0201a28:	17460613          	addi	a2,a2,372 # ffffffffc0203b98 <etext+0x8e6>
ffffffffc0201a2c:	22400593          	li	a1,548
ffffffffc0201a30:	00002517          	auipc	a0,0x2
ffffffffc0201a34:	08850513          	addi	a0,a0,136 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0201a38:	f94fe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0201a3c <slub_alloc_small>:
    if (cpu >= SLUB_NCPUS) {
ffffffffc0201a3c:	00006797          	auipc	a5,0x6
ffffffffc0201a40:	5c47a783          	lw	a5,1476(a5) # ffffffffc0208000 <boot_hartid>

/* ------------------------- 分配 ------------------------- */

static void *slub_alloc_small(unsigned int cls) {
ffffffffc0201a44:	7165                	addi	sp,sp,-400
ffffffffc0201a46:	e706                	sd	ra,392(sp)
ffffffffc0201a48:	e322                	sd	s0,384(sp)
    if (cpu >= SLUB_NCPUS) {
ffffffffc0201a4a:	6a079963          	bnez	a5,ffffffffc02020fc <slub_alloc_small+0x6c0>
ffffffffc0201a4e:	8e2a                	mv	t3,a0
    unsigned long s = read_csr(sstatus);
ffffffffc0201a50:	100026f3          	csrr	a3,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0201a54:	8a89                	andi	a3,a3,2
    if (*flags) {
ffffffffc0201a56:	c299                	beqz	a3,ffffffffc0201a5c <slub_alloc_small+0x20>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0201a58:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0201a5c:	0330000f          	fence	rw,rw
    unsigned int n;
    void *result;

    /* 快路径：本地 main/spare sheaf，仅本地临界区，不碰全局锁 */
    slub_port_local_lock(&f);
    if (slub_cc[cpu][cls].main.size != 0) {
ffffffffc0201a60:	020e1313          	slli	t1,t3,0x20
ffffffffc0201a64:	02035313          	srli	t1,t1,0x20
ffffffffc0201a68:	00531713          	slli	a4,t1,0x5
ffffffffc0201a6c:	00017797          	auipc	a5,0x17
ffffffffc0201a70:	70478793          	addi	a5,a5,1796 # ffffffffc0219170 <slub_cc>
ffffffffc0201a74:	97ba                	add	a5,a5,a4
ffffffffc0201a76:	4798                	lw	a4,8(a5)
ffffffffc0201a78:	2c071263          	bnez	a4,ffffffffc0201d3c <slub_alloc_small+0x300>
        slub_cs[cpu][cls].alloc_fast++;
        slub_cs[cpu][cls].user++;
        slub_port_local_unlock(&f);
        return result;
    }
    if (slub_cc[cpu][cls].spare.size != 0) {
ffffffffc0201a7c:	4f98                	lw	a4,24(a5)
ffffffffc0201a7e:	24071363          	bnez	a4,ffffffffc0201cc4 <slub_alloc_small+0x288>
    __sync_synchronize();
ffffffffc0201a82:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0201a86:	c299                	beqz	a3,ffffffffc0201a8c <slub_alloc_small+0x50>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0201a88:	100167f3          	csrrsi	a5,sstatus,2
        return result;
    }
    slub_port_local_unlock(&f);

    /* 慢路径 1：批量从共享 barn 取（barn 锁） */
    n = slub_barn_take(cls, batch, c->sheaf_cap);
ffffffffc0201a8c:	00431793          	slli	a5,t1,0x4
ffffffffc0201a90:	406787b3          	sub	a5,a5,t1
ffffffffc0201a94:	00018f97          	auipc	t6,0x18
ffffffffc0201a98:	91cf8f93          	addi	t6,t6,-1764 # ffffffffc02193b0 <slub_caches>
ffffffffc0201a9c:	078e                	slli	a5,a5,0x3
ffffffffc0201a9e:	97fe                	add	a5,a5,t6
ffffffffc0201aa0:	4790                	lw	a2,8(a5)
    unsigned long s = read_csr(sstatus);
ffffffffc0201aa2:	10002f73          	csrr	t5,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0201aa6:	002f7f13          	andi	t5,t5,2
    if (*flags) {
ffffffffc0201aaa:	100f1463          	bnez	t5,ffffffffc0201bb2 <slub_alloc_small+0x176>
    __sync_synchronize();
ffffffffc0201aae:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0201ab2:	00231693          	slli	a3,t1,0x2
ffffffffc0201ab6:	969a                	add	a3,a3,t1
ffffffffc0201ab8:	068e                	slli	a3,a3,0x3
ffffffffc0201aba:	00017e97          	auipc	t4,0x17
ffffffffc0201abe:	7b6e8e93          	addi	t4,t4,1974 # ffffffffc0219270 <slub_barns>
ffffffffc0201ac2:	96f6                	add	a3,a3,t4
ffffffffc0201ac4:	4785                	li	a5,1
ffffffffc0201ac6:	0cf6a7af          	amoswap.w.aq	a5,a5,(a3)
ffffffffc0201aca:	2781                	sext.w	a5,a5
ffffffffc0201acc:	ffe5                	bnez	a5,ffffffffc0201ac4 <slub_alloc_small+0x88>
    __sync_synchronize(); /* acquire */
ffffffffc0201ace:	0330000f          	fence	rw,rw
    n = b->size;
ffffffffc0201ad2:	00231793          	slli	a5,t1,0x2
ffffffffc0201ad6:	979a                	add	a5,a5,t1
ffffffffc0201ad8:	078e                	slli	a5,a5,0x3
ffffffffc0201ada:	97f6                	add	a5,a5,t4
ffffffffc0201adc:	4b88                	lw	a0,16(a5)
    if (n > want) n = want;
ffffffffc0201ade:	8732                	mv	a4,a2
ffffffffc0201ae0:	0cc56463          	bltu	a0,a2,ffffffffc0201ba8 <slub_alloc_small+0x16c>
ffffffffc0201ae4:	0007061b          	sext.w	a2,a4
    for (k = 0; k < n; k++) out[k] = b->objs[b->size - n + k];
ffffffffc0201ae8:	ca61                	beqz	a2,ffffffffc0201bb8 <slub_alloc_small+0x17c>
ffffffffc0201aea:	00231793          	slli	a5,t1,0x2
ffffffffc0201aee:	979a                	add	a5,a5,t1
ffffffffc0201af0:	078e                	slli	a5,a5,0x3
ffffffffc0201af2:	97f6                	add	a5,a5,t4
ffffffffc0201af4:	40e50fbb          	subw	t6,a0,a4
ffffffffc0201af8:	0087b803          	ld	a6,8(a5)
ffffffffc0201afc:	008c                	addi	a1,sp,64
ffffffffc0201afe:	87fe                	mv	a5,t6
ffffffffc0201b00:	02079893          	slli	a7,a5,0x20
ffffffffc0201b04:	01d8d713          	srli	a4,a7,0x1d
ffffffffc0201b08:	9742                	add	a4,a4,a6
ffffffffc0201b0a:	6318                	ld	a4,0(a4)
ffffffffc0201b0c:	2785                	addiw	a5,a5,1
ffffffffc0201b0e:	05a1                	addi	a1,a1,8
ffffffffc0201b10:	fee5bc23          	sd	a4,-8(a1)
ffffffffc0201b14:	fef516e3          	bne	a0,a5,ffffffffc0201b00 <slub_alloc_small+0xc4>
    b->size -= n;
ffffffffc0201b18:	00231793          	slli	a5,t1,0x2
ffffffffc0201b1c:	979a                	add	a5,a5,t1
ffffffffc0201b1e:	078e                	slli	a5,a5,0x3
ffffffffc0201b20:	9ebe                	add	t4,t4,a5
    if (n != 0) b->stat_get += n;
ffffffffc0201b22:	018eb783          	ld	a5,24(t4)
ffffffffc0201b26:	02061713          	slli	a4,a2,0x20
ffffffffc0201b2a:	9301                	srli	a4,a4,0x20
ffffffffc0201b2c:	97ba                	add	a5,a5,a4
    b->size -= n;
ffffffffc0201b2e:	01fea823          	sw	t6,16(t4)
    if (n != 0) b->stat_get += n;
ffffffffc0201b32:	00febc23          	sd	a5,24(t4)
    __sync_synchronize(); /* release */
ffffffffc0201b36:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0201b3a:	0310000f          	fence	rw,w
ffffffffc0201b3e:	0006a023          	sw	zero,0(a3)
    __sync_synchronize();
ffffffffc0201b42:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0201b46:	000f0463          	beqz	t5,ffffffffc0201b4e <slub_alloc_small+0x112>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0201b4a:	100167f3          	csrrsi	a5,sstatus,2
    /* 慢路径 2：slab 层补充（cache 锁，可能新建 slab 走页分配器） */
    if (n == 0) n = slub_slab_refill(cls, batch, c->sheaf_cap);
    if (n == 0) return NULL;

    result = batch[0];
    if (n > 1) slub_put_objects(cls, batch + 1, n - 1, SLUB_PUT_ALL);
ffffffffc0201b4e:	4785                	li	a5,1
    result = batch[0];
ffffffffc0201b50:	6406                	ld	s0,64(sp)
    if (n > 1) slub_put_objects(cls, batch + 1, n - 1, SLUB_PUT_ALL);
ffffffffc0201b52:	00f60a63          	beq	a2,a5,ffffffffc0201b66 <slub_alloc_small+0x12a>
ffffffffc0201b56:	367d                	addiw	a2,a2,-1
ffffffffc0201b58:	8572                	mv	a0,t3
ffffffffc0201b5a:	4681                	li	a3,0
ffffffffc0201b5c:	00ac                	addi	a1,sp,72
ffffffffc0201b5e:	e41a                	sd	t1,8(sp)
ffffffffc0201b60:	a4bff0ef          	jal	ffffffffc02015aa <slub_put_objects>
ffffffffc0201b64:	6322                	ld	t1,8(sp)
    unsigned long s = read_csr(sstatus);
ffffffffc0201b66:	100027f3          	csrr	a5,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0201b6a:	8b89                	andi	a5,a5,2
    if (*flags) {
ffffffffc0201b6c:	1a078063          	beqz	a5,ffffffffc0201d0c <slub_alloc_small+0x2d0>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0201b70:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0201b74:	0330000f          	fence	rw,rw

    slub_port_local_lock(&f);
    slub_cs[cpu][cls].alloc_slow++;
ffffffffc0201b78:	00231713          	slli	a4,t1,0x2
ffffffffc0201b7c:	971a                	add	a4,a4,t1
ffffffffc0201b7e:	070e                	slli	a4,a4,0x3
ffffffffc0201b80:	00017797          	auipc	a5,0x17
ffffffffc0201b84:	4b078793          	addi	a5,a5,1200 # ffffffffc0219030 <slub_cs>
ffffffffc0201b88:	97ba                	add	a5,a5,a4
ffffffffc0201b8a:	6794                	ld	a3,8(a5)
    slub_cs[cpu][cls].user++;
ffffffffc0201b8c:	7398                	ld	a4,32(a5)
    slub_cs[cpu][cls].alloc_slow++;
ffffffffc0201b8e:	0685                	addi	a3,a3,1
    slub_cs[cpu][cls].user++;
ffffffffc0201b90:	0705                	addi	a4,a4,1
    slub_cs[cpu][cls].alloc_slow++;
ffffffffc0201b92:	e794                	sd	a3,8(a5)
    slub_cs[cpu][cls].user++;
ffffffffc0201b94:	f398                	sd	a4,32(a5)
    __sync_synchronize();
ffffffffc0201b96:	0330000f          	fence	rw,rw
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0201b9a:	100167f3          	csrrsi	a5,sstatus,2
    slub_port_local_unlock(&f);
    return result;
}
ffffffffc0201b9e:	60ba                	ld	ra,392(sp)
ffffffffc0201ba0:	8522                	mv	a0,s0
ffffffffc0201ba2:	641a                	ld	s0,384(sp)
ffffffffc0201ba4:	6159                	addi	sp,sp,400
ffffffffc0201ba6:	8082                	ret
    if (n > want) n = want;
ffffffffc0201ba8:	872a                	mv	a4,a0
ffffffffc0201baa:	0007061b          	sext.w	a2,a4
    for (k = 0; k < n; k++) out[k] = b->objs[b->size - n + k];
ffffffffc0201bae:	fe15                	bnez	a2,ffffffffc0201aea <slub_alloc_small+0xae>
ffffffffc0201bb0:	a021                	j	ffffffffc0201bb8 <slub_alloc_small+0x17c>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0201bb2:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0201bb6:	bde5                	j	ffffffffc0201aae <slub_alloc_small+0x72>
ffffffffc0201bb8:	eed6                	sd	s5,344(sp)
    __sync_synchronize(); /* release */
ffffffffc0201bba:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0201bbe:	0310000f          	fence	rw,w
ffffffffc0201bc2:	0006a023          	sw	zero,0(a3)
    __sync_synchronize();
ffffffffc0201bc6:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0201bca:	180f1f63          	bnez	t5,ffffffffc0201d68 <slub_alloc_small+0x32c>
    if (n == 0) n = slub_slab_refill(cls, batch, c->sheaf_cap);
ffffffffc0201bce:	00431793          	slli	a5,t1,0x4
ffffffffc0201bd2:	406787b3          	sub	a5,a5,t1
ffffffffc0201bd6:	078e                	slli	a5,a5,0x3
ffffffffc0201bd8:	97fe                	add	a5,a5,t6
ffffffffc0201bda:	0087a803          	lw	a6,8(a5)
    unsigned long s = read_csr(sstatus);
ffffffffc0201bde:	100027f3          	csrr	a5,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0201be2:	8b89                	andi	a5,a5,2
ffffffffc0201be4:	8abe                	mv	s5,a5
    if (*flags) {
ffffffffc0201be6:	c399                	beqz	a5,ffffffffc0201bec <slub_alloc_small+0x1b0>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0201be8:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0201bec:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0201bf0:	00431e93          	slli	t4,t1,0x4
ffffffffc0201bf4:	406e8eb3          	sub	t4,t4,t1
ffffffffc0201bf8:	0e8e                	slli	t4,t4,0x3
ffffffffc0201bfa:	0ed1                	addi	t4,t4,20
ffffffffc0201bfc:	9efe                	add	t4,t4,t6
ffffffffc0201bfe:	4605                	li	a2,1
ffffffffc0201c00:	0ccea62f          	amoswap.w.aq	a2,a2,(t4)
ffffffffc0201c04:	2601                	sext.w	a2,a2
ffffffffc0201c06:	fe65                	bnez	a2,ffffffffc0201bfe <slub_alloc_small+0x1c2>
    __sync_synchronize(); /* acquire */
ffffffffc0201c08:	0330000f          	fence	rw,rw
    while (got < want) {
ffffffffc0201c0c:	4c080b63          	beqz	a6,ffffffffc02020e2 <slub_alloc_small+0x6a6>
        if (c->partial != NULL) {
ffffffffc0201c10:	00431793          	slli	a5,t1,0x4
ffffffffc0201c14:	406787b3          	sub	a5,a5,t1
ffffffffc0201c18:	00379893          	slli	a7,a5,0x3
ffffffffc0201c1c:	eada                	sd	s6,336(sp)
ffffffffc0201c1e:	98fe                	add	a7,a7,t6
ffffffffc0201c20:	8b3e                	mv	s6,a5
            s->state = SLUB_SLAB_PARTIAL;
ffffffffc0201c22:	4289                	li	t0,2
ffffffffc0201c24:	04010f13          	addi	t5,sp,64
        if (c->partial != NULL) {
ffffffffc0201c28:	0188b703          	ld	a4,24(a7)
ffffffffc0201c2c:	22070d63          	beqz	a4,ffffffffc0201e66 <slub_alloc_small+0x42a>
            c->partial = s->next;
ffffffffc0201c30:	7714                	ld	a3,40(a4)
            c->nr_partial--;
ffffffffc0201c32:	0288a783          	lw	a5,40(a7)
            c->partial = s->next;
ffffffffc0201c36:	00d8bc23          	sd	a3,24(a7)
            s->next = NULL;
ffffffffc0201c3a:	02073423          	sd	zero,40(a4)
            c->nr_partial--;
ffffffffc0201c3e:	37fd                	addiw	a5,a5,-1
ffffffffc0201c40:	02f8a423          	sw	a5,40(a7)
        if (s->freelist == NULL) {
ffffffffc0201c44:	731c                	ld	a5,32(a4)
        while (got < want && s->freelist != NULL) {
ffffffffc0201c46:	25067063          	bgeu	a2,a6,ffffffffc0201e86 <slub_alloc_small+0x44a>
ffffffffc0201c4a:	02061693          	slli	a3,a2,0x20
ffffffffc0201c4e:	01d6d593          	srli	a1,a3,0x1d
ffffffffc0201c52:	95fa                	add	a1,a1,t5
ffffffffc0201c54:	cf91                	beqz	a5,ffffffffc0201c70 <slub_alloc_small+0x234>
            s->inuse++;
ffffffffc0201c56:	4f14                	lw	a3,24(a4)
            s->freelist = *(void **)obj;
ffffffffc0201c58:	6388                	ld	a0,0(a5)
            out[got++] = obj;
ffffffffc0201c5a:	e19c                	sd	a5,0(a1)
            s->inuse++;
ffffffffc0201c5c:	0016879b          	addiw	a5,a3,1
            s->freelist = *(void **)obj;
ffffffffc0201c60:	f308                	sd	a0,32(a4)
            out[got++] = obj;
ffffffffc0201c62:	2605                	addiw	a2,a2,1
            s->inuse++;
ffffffffc0201c64:	cf1c                	sw	a5,24(a4)
        while (got < want && s->freelist != NULL) {
ffffffffc0201c66:	05a1                	addi	a1,a1,8
ffffffffc0201c68:	10c80363          	beq	a6,a2,ffffffffc0201d6e <slub_alloc_small+0x332>
ffffffffc0201c6c:	87aa                	mv	a5,a0
ffffffffc0201c6e:	f7e5                	bnez	a5,ffffffffc0201c56 <slub_alloc_small+0x21a>
            s->state = SLUB_SLAB_FULL;
ffffffffc0201c70:	4785                	li	a5,1
ffffffffc0201c72:	00f70ea3          	sb	a5,29(a4)
            c->nr_full++;
ffffffffc0201c76:	0308a783          	lw	a5,48(a7)
ffffffffc0201c7a:	2785                	addiw	a5,a5,1
ffffffffc0201c7c:	02f8a823          	sw	a5,48(a7)
    while (got < want) {
ffffffffc0201c80:	fb0664e3          	bltu	a2,a6,ffffffffc0201c28 <slub_alloc_small+0x1ec>
    c->inuse_objs += got;
ffffffffc0201c84:	00431793          	slli	a5,t1,0x4
ffffffffc0201c88:	406787b3          	sub	a5,a5,t1
ffffffffc0201c8c:	078e                	slli	a5,a5,0x3
ffffffffc0201c8e:	9fbe                	add	t6,t6,a5
ffffffffc0201c90:	040fb683          	ld	a3,64(t6)
    c->stat_refill += got;
ffffffffc0201c94:	048fb703          	ld	a4,72(t6)
    c->inuse_objs += got;
ffffffffc0201c98:	02061793          	slli	a5,a2,0x20
ffffffffc0201c9c:	9381                	srli	a5,a5,0x20
ffffffffc0201c9e:	96be                	add	a3,a3,a5
    c->stat_refill += got;
ffffffffc0201ca0:	97ba                	add	a5,a5,a4
    c->inuse_objs += got;
ffffffffc0201ca2:	04dfb023          	sd	a3,64(t6)
    c->stat_refill += got;
ffffffffc0201ca6:	04ffb423          	sd	a5,72(t6)
    __sync_synchronize(); /* release */
ffffffffc0201caa:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0201cae:	0310000f          	fence	rw,w
ffffffffc0201cb2:	000ea023          	sw	zero,0(t4)
    __sync_synchronize();
ffffffffc0201cb6:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0201cba:	180a9e63          	bnez	s5,ffffffffc0201e56 <slub_alloc_small+0x41a>
ffffffffc0201cbe:	6af6                	ld	s5,344(sp)
ffffffffc0201cc0:	6b56                	ld	s6,336(sp)
ffffffffc0201cc2:	b571                	j	ffffffffc0201b4e <slub_alloc_small+0x112>
        slub_cs[cpu][cls].alloc_fast++;
ffffffffc0201cc4:	00231593          	slli	a1,t1,0x2
ffffffffc0201cc8:	959a                	add	a1,a1,t1
ffffffffc0201cca:	058e                	slli	a1,a1,0x3
ffffffffc0201ccc:	00017617          	auipc	a2,0x17
ffffffffc0201cd0:	36460613          	addi	a2,a2,868 # ffffffffc0219030 <slub_cs>
ffffffffc0201cd4:	962e                	add	a2,a2,a1
ffffffffc0201cd6:	00063803          	ld	a6,0(a2)
        slub_cs[cpu][cls].user++;
ffffffffc0201cda:	7208                	ld	a0,32(a2)
        result = slub_cc[cpu][cls].spare.objs[--slub_cc[cpu][cls].spare.size];
ffffffffc0201cdc:	377d                	addiw	a4,a4,-1
ffffffffc0201cde:	6b8c                	ld	a1,16(a5)
ffffffffc0201ce0:	02071313          	slli	t1,a4,0x20
ffffffffc0201ce4:	01d35893          	srli	a7,t1,0x1d
        slub_cs[cpu][cls].alloc_fast++;
ffffffffc0201ce8:	0805                	addi	a6,a6,1
        slub_cs[cpu][cls].user++;
ffffffffc0201cea:	0505                	addi	a0,a0,1
        result = slub_cc[cpu][cls].spare.objs[--slub_cc[cpu][cls].spare.size];
ffffffffc0201cec:	cf98                	sw	a4,24(a5)
ffffffffc0201cee:	011587b3          	add	a5,a1,a7
        slub_cs[cpu][cls].alloc_fast++;
ffffffffc0201cf2:	01063023          	sd	a6,0(a2)
        slub_cs[cpu][cls].user++;
ffffffffc0201cf6:	f208                	sd	a0,32(a2)
        result = slub_cc[cpu][cls].spare.objs[--slub_cc[cpu][cls].spare.size];
ffffffffc0201cf8:	6380                	ld	s0,0(a5)
    __sync_synchronize();
ffffffffc0201cfa:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0201cfe:	e8069ee3          	bnez	a3,ffffffffc0201b9a <slub_alloc_small+0x15e>
}
ffffffffc0201d02:	60ba                	ld	ra,392(sp)
ffffffffc0201d04:	8522                	mv	a0,s0
ffffffffc0201d06:	641a                	ld	s0,384(sp)
ffffffffc0201d08:	6159                	addi	sp,sp,400
ffffffffc0201d0a:	8082                	ret
    __sync_synchronize();
ffffffffc0201d0c:	0330000f          	fence	rw,rw
    slub_cs[cpu][cls].alloc_slow++;
ffffffffc0201d10:	00231713          	slli	a4,t1,0x2
ffffffffc0201d14:	971a                	add	a4,a4,t1
ffffffffc0201d16:	070e                	slli	a4,a4,0x3
ffffffffc0201d18:	00017797          	auipc	a5,0x17
ffffffffc0201d1c:	31878793          	addi	a5,a5,792 # ffffffffc0219030 <slub_cs>
ffffffffc0201d20:	97ba                	add	a5,a5,a4
ffffffffc0201d22:	6794                	ld	a3,8(a5)
    slub_cs[cpu][cls].user++;
ffffffffc0201d24:	7398                	ld	a4,32(a5)
    slub_cs[cpu][cls].alloc_slow++;
ffffffffc0201d26:	0685                	addi	a3,a3,1
    slub_cs[cpu][cls].user++;
ffffffffc0201d28:	0705                	addi	a4,a4,1
    slub_cs[cpu][cls].alloc_slow++;
ffffffffc0201d2a:	e794                	sd	a3,8(a5)
    slub_cs[cpu][cls].user++;
ffffffffc0201d2c:	f398                	sd	a4,32(a5)
    __sync_synchronize();
ffffffffc0201d2e:	0330000f          	fence	rw,rw
}
ffffffffc0201d32:	60ba                	ld	ra,392(sp)
ffffffffc0201d34:	8522                	mv	a0,s0
ffffffffc0201d36:	641a                	ld	s0,384(sp)
ffffffffc0201d38:	6159                	addi	sp,sp,400
ffffffffc0201d3a:	8082                	ret
        slub_cs[cpu][cls].alloc_fast++;
ffffffffc0201d3c:	00231593          	slli	a1,t1,0x2
ffffffffc0201d40:	959a                	add	a1,a1,t1
ffffffffc0201d42:	058e                	slli	a1,a1,0x3
ffffffffc0201d44:	00017617          	auipc	a2,0x17
ffffffffc0201d48:	2ec60613          	addi	a2,a2,748 # ffffffffc0219030 <slub_cs>
ffffffffc0201d4c:	962e                	add	a2,a2,a1
ffffffffc0201d4e:	00063803          	ld	a6,0(a2)
        slub_cs[cpu][cls].user++;
ffffffffc0201d52:	7208                	ld	a0,32(a2)
        result = slub_cc[cpu][cls].main.objs[--slub_cc[cpu][cls].main.size];
ffffffffc0201d54:	377d                	addiw	a4,a4,-1
ffffffffc0201d56:	02071313          	slli	t1,a4,0x20
ffffffffc0201d5a:	638c                	ld	a1,0(a5)
ffffffffc0201d5c:	01d35893          	srli	a7,t1,0x1d
        slub_cs[cpu][cls].alloc_fast++;
ffffffffc0201d60:	0805                	addi	a6,a6,1
        slub_cs[cpu][cls].user++;
ffffffffc0201d62:	0505                	addi	a0,a0,1
        result = slub_cc[cpu][cls].main.objs[--slub_cc[cpu][cls].main.size];
ffffffffc0201d64:	c798                	sw	a4,8(a5)
ffffffffc0201d66:	b761                	j	ffffffffc0201cee <slub_alloc_small+0x2b2>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0201d68:	100167f3          	csrrsi	a5,sstatus,2
    if (n == 0) n = slub_slab_refill(cls, batch, c->sheaf_cap);
ffffffffc0201d6c:	b58d                	j	ffffffffc0201bce <slub_alloc_small+0x192>
        if (s->freelist == NULL) {
ffffffffc0201d6e:	d109                	beqz	a0,ffffffffc0201c70 <slub_alloc_small+0x234>
            s->state = SLUB_SLAB_PARTIAL;
ffffffffc0201d70:	00570ea3          	sb	t0,29(a4)
            c->nr_partial++;
ffffffffc0201d74:	0288a783          	lw	a5,40(a7)
            s->next = c->partial;
ffffffffc0201d78:	0188b683          	ld	a3,24(a7)
            c->nr_partial++;
ffffffffc0201d7c:	2785                	addiw	a5,a5,1
            s->next = c->partial;
ffffffffc0201d7e:	f714                	sd	a3,40(a4)
            c->partial = s;
ffffffffc0201d80:	00e8bc23          	sd	a4,24(a7)
            c->nr_partial++;
ffffffffc0201d84:	02f8a423          	sw	a5,40(a7)
    while (got < want) {
ffffffffc0201d88:	eb0660e3          	bltu	a2,a6,ffffffffc0201c28 <slub_alloc_small+0x1ec>
ffffffffc0201d8c:	bde5                	j	ffffffffc0201c84 <slub_alloc_small+0x248>
    __sync_synchronize(); /* release */
ffffffffc0201d8e:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0201d92:	0310000f          	fence	rw,w
ffffffffc0201d96:	0005a023          	sw	zero,0(a1)
    __sync_synchronize();
ffffffffc0201d9a:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0201d9e:	c299                	beqz	a3,ffffffffc0201da4 <slub_alloc_small+0x368>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0201da0:	100167f3          	csrrsi	a5,sstatus,2
        slub_pages_free(pages, c->slab_pages);
ffffffffc0201da4:	00431793          	slli	a5,t1,0x4
ffffffffc0201da8:	406787b3          	sub	a5,a5,t1
ffffffffc0201dac:	078e                	slli	a5,a5,0x3
ffffffffc0201dae:	97fe                	add	a5,a5,t6
ffffffffc0201db0:	0107e583          	lwu	a1,16(a5)
    unsigned long s = read_csr(sstatus);
ffffffffc0201db4:	10002473          	csrr	s0,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0201db8:	8809                	andi	s0,s0,2
    if (*flags) {
ffffffffc0201dba:	c019                	beqz	s0,ffffffffc0201dc0 <slub_alloc_small+0x384>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0201dbc:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0201dc0:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0201dc4:	00018497          	auipc	s1,0x18
ffffffffc0201dc8:	a1c48493          	addi	s1,s1,-1508 # ffffffffc02197e0 <slub_pmm_lock>
ffffffffc0201dcc:	4785                	li	a5,1
ffffffffc0201dce:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
ffffffffc0201dd2:	2781                	sext.w	a5,a5
ffffffffc0201dd4:	ffe5                	bnez	a5,ffffffffc0201dcc <slub_alloc_small+0x390>
ffffffffc0201dd6:	f072                	sd	t3,32(sp)
ffffffffc0201dd8:	ec1a                	sd	t1,24(sp)
ffffffffc0201dda:	e876                	sd	t4,16(sp)
ffffffffc0201ddc:	e432                	sd	a2,8(sp)
    __sync_synchronize(); /* acquire */
ffffffffc0201dde:	0330000f          	fence	rw,rw
    free_pages(base, npages);
ffffffffc0201de2:	8552                	mv	a0,s4
ffffffffc0201de4:	a52ff0ef          	jal	ffffffffc0201036 <free_pages>
    __sync_synchronize(); /* release */
ffffffffc0201de8:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0201dec:	0310000f          	fence	rw,w
ffffffffc0201df0:	0004a023          	sw	zero,0(s1)
    __sync_synchronize();
ffffffffc0201df4:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0201df8:	00017f97          	auipc	t6,0x17
ffffffffc0201dfc:	5b8f8f93          	addi	t6,t6,1464 # ffffffffc02193b0 <slub_caches>
ffffffffc0201e00:	6622                	ld	a2,8(sp)
ffffffffc0201e02:	6ec2                	ld	t4,16(sp)
ffffffffc0201e04:	6362                	ld	t1,24(sp)
ffffffffc0201e06:	7e02                	ld	t3,32(sp)
ffffffffc0201e08:	c019                	beqz	s0,ffffffffc0201e0e <slub_alloc_small+0x3d2>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0201e0a:	100167f3          	csrrsi	a5,sstatus,2
        c->stat_desc_fail++;
ffffffffc0201e0e:	00431793          	slli	a5,t1,0x4
ffffffffc0201e12:	406787b3          	sub	a5,a5,t1
ffffffffc0201e16:	078e                	slli	a5,a5,0x3
ffffffffc0201e18:	97fe                	add	a5,a5,t6
ffffffffc0201e1a:	7bb8                	ld	a4,112(a5)
ffffffffc0201e1c:	74f6                	ld	s1,376(sp)
ffffffffc0201e1e:	0705                	addi	a4,a4,1
ffffffffc0201e20:	fbb8                	sd	a4,112(a5)
    c->inuse_objs += got;
ffffffffc0201e22:	00431793          	slli	a5,t1,0x4
ffffffffc0201e26:	406787b3          	sub	a5,a5,t1
ffffffffc0201e2a:	078e                	slli	a5,a5,0x3
ffffffffc0201e2c:	97fe                	add	a5,a5,t6
ffffffffc0201e2e:	63ac                	ld	a1,64(a5)
    c->stat_refill += got;
ffffffffc0201e30:	67b4                	ld	a3,72(a5)
    c->inuse_objs += got;
ffffffffc0201e32:	02061713          	slli	a4,a2,0x20
ffffffffc0201e36:	9301                	srli	a4,a4,0x20
ffffffffc0201e38:	95ba                	add	a1,a1,a4
    c->stat_refill += got;
ffffffffc0201e3a:	9736                	add	a4,a4,a3
    c->inuse_objs += got;
ffffffffc0201e3c:	e3ac                	sd	a1,64(a5)
    c->stat_refill += got;
ffffffffc0201e3e:	e7b8                	sd	a4,72(a5)
    __sync_synchronize(); /* release */
ffffffffc0201e40:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0201e44:	0310000f          	fence	rw,w
ffffffffc0201e48:	000ea023          	sw	zero,0(t4)
    __sync_synchronize();
ffffffffc0201e4c:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0201e50:	7a16                	ld	s4,352(sp)
ffffffffc0201e52:	000a8463          	beqz	s5,ffffffffc0201e5a <slub_alloc_small+0x41e>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0201e56:	100167f3          	csrrsi	a5,sstatus,2
    if (n == 0) return NULL;
ffffffffc0201e5a:	e60612e3          	bnez	a2,ffffffffc0201cbe <slub_alloc_small+0x282>
ffffffffc0201e5e:	6b56                	ld	s6,336(sp)
ffffffffc0201e60:	6af6                	ld	s5,344(sp)
ffffffffc0201e62:	4401                	li	s0,0
ffffffffc0201e64:	bb2d                	j	ffffffffc0201b9e <slub_alloc_small+0x162>
        } else if (c->empty != NULL) {
ffffffffc0201e66:	0208b703          	ld	a4,32(a7)
ffffffffc0201e6a:	cf05                	beqz	a4,ffffffffc0201ea2 <slub_alloc_small+0x466>
            c->empty = s->next;
ffffffffc0201e6c:	7714                	ld	a3,40(a4)
            c->nr_empty--;
ffffffffc0201e6e:	02c8a783          	lw	a5,44(a7)
            c->empty = s->next;
ffffffffc0201e72:	02d8b023          	sd	a3,32(a7)
            c->nr_empty--;
ffffffffc0201e76:	37fd                	addiw	a5,a5,-1
            s->next = NULL;
ffffffffc0201e78:	02073423          	sd	zero,40(a4)
            c->nr_empty--;
ffffffffc0201e7c:	02f8a623          	sw	a5,44(a7)
        if (s->freelist == NULL) {
ffffffffc0201e80:	731c                	ld	a5,32(a4)
        while (got < want && s->freelist != NULL) {
ffffffffc0201e82:	dd0664e3          	bltu	a2,a6,ffffffffc0201c4a <slub_alloc_small+0x20e>
        if (s->freelist == NULL) {
ffffffffc0201e86:	ee0795e3          	bnez	a5,ffffffffc0201d70 <slub_alloc_small+0x334>
            c->nr_full++;
ffffffffc0201e8a:	07800793          	li	a5,120
ffffffffc0201e8e:	02f307b3          	mul	a5,t1,a5
            s->state = SLUB_SLAB_FULL;
ffffffffc0201e92:	4685                	li	a3,1
ffffffffc0201e94:	00d70ea3          	sb	a3,29(a4)
            c->nr_full++;
ffffffffc0201e98:	97fe                	add	a5,a5,t6
ffffffffc0201e9a:	5b98                	lw	a4,48(a5)
ffffffffc0201e9c:	2705                	addiw	a4,a4,1
ffffffffc0201e9e:	db98                	sw	a4,48(a5)
    while (got < want) {
ffffffffc0201ea0:	b3d5                	j	ffffffffc0201c84 <slub_alloc_small+0x248>
    pages = slub_pages_alloc(c->slab_pages);
ffffffffc0201ea2:	003b1413          	slli	s0,s6,0x3
ffffffffc0201ea6:	947e                	add	s0,s0,t6
ffffffffc0201ea8:	01046503          	lwu	a0,16(s0)
ffffffffc0201eac:	f2d2                	sd	s4,352(sp)
ffffffffc0201eae:	fc72                	sd	t3,56(sp)
ffffffffc0201eb0:	f81a                	sd	t1,48(sp)
ffffffffc0201eb2:	f446                	sd	a7,40(sp)
ffffffffc0201eb4:	f076                	sd	t4,32(sp)
ffffffffc0201eb6:	ec32                	sd	a2,24(sp)
ffffffffc0201eb8:	e83a                	sd	a4,16(sp)
ffffffffc0201eba:	e442                	sd	a6,8(sp)
ffffffffc0201ebc:	c9aff0ef          	jal	ffffffffc0201356 <slub_pages_alloc>
    if (pages == NULL) {
ffffffffc0201ec0:	6822                	ld	a6,8(sp)
ffffffffc0201ec2:	6742                	ld	a4,16(sp)
ffffffffc0201ec4:	6662                	ld	a2,24(sp)
ffffffffc0201ec6:	7e82                	ld	t4,32(sp)
ffffffffc0201ec8:	78a2                	ld	a7,40(sp)
ffffffffc0201eca:	7342                	ld	t1,48(sp)
ffffffffc0201ecc:	7e62                	ld	t3,56(sp)
    pages = slub_pages_alloc(c->slab_pages);
ffffffffc0201ece:	8a2a                	mv	s4,a0
    if (pages == NULL) {
ffffffffc0201ed0:	00017f97          	auipc	t6,0x17
ffffffffc0201ed4:	4e0f8f93          	addi	t6,t6,1248 # ffffffffc02193b0 <slub_caches>
ffffffffc0201ed8:	4289                	li	t0,2
ffffffffc0201eda:	04010f13          	addi	t5,sp,64
ffffffffc0201ede:	1e050e63          	beqz	a0,ffffffffc02020da <slub_alloc_small+0x69e>
ffffffffc0201ee2:	fea6                	sd	s1,376(sp)
    unsigned long s = read_csr(sstatus);
ffffffffc0201ee4:	100026f3          	csrr	a3,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0201ee8:	8a89                	andi	a3,a3,2
    if (*flags) {
ffffffffc0201eea:	c299                	beqz	a3,ffffffffc0201ef0 <slub_alloc_small+0x4b4>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0201eec:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0201ef0:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0201ef4:	00018597          	auipc	a1,0x18
ffffffffc0201ef8:	8f458593          	addi	a1,a1,-1804 # ffffffffc02197e8 <slub_index_lock>
ffffffffc0201efc:	4785                	li	a5,1
ffffffffc0201efe:	0cf5a7af          	amoswap.w.aq	a5,a5,(a1)
ffffffffc0201f02:	2781                	sext.w	a5,a5
ffffffffc0201f04:	ffe5                	bnez	a5,ffffffffc0201efc <slub_alloc_small+0x4c0>
    __sync_synchronize(); /* acquire */
ffffffffc0201f06:	0330000f          	fence	rw,rw
    s = slub_pool_free;
ffffffffc0201f0a:	00018517          	auipc	a0,0x18
ffffffffc0201f0e:	8e653503          	ld	a0,-1818(a0) # ffffffffc02197f0 <slub_pool_free>
    if (s != NULL) slub_pool_free = s->next;
ffffffffc0201f12:	e6050ee3          	beqz	a0,ffffffffc0201d8e <slub_alloc_small+0x352>
ffffffffc0201f16:	7500                	ld	s0,40(a0)
ffffffffc0201f18:	faca                	sd	s2,368(sp)
ffffffffc0201f1a:	f6ce                	sd	s3,360(sp)
ffffffffc0201f1c:	e6de                	sd	s7,328(sp)
ffffffffc0201f1e:	00018497          	auipc	s1,0x18
ffffffffc0201f22:	8c84b923          	sd	s0,-1838(s1) # ffffffffc02197f0 <slub_pool_free>
    __sync_synchronize(); /* release */
ffffffffc0201f26:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0201f2a:	0310000f          	fence	rw,w
ffffffffc0201f2e:	0005a023          	sw	zero,0(a1)
    __sync_synchronize();
ffffffffc0201f32:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0201f36:	18069f63          	bnez	a3,ffffffffc02020d4 <slub_alloc_small+0x698>
    cap = (unsigned int)((c->slab_pages * SLUB_PAGE_SIZE) / c->objsize);
ffffffffc0201f3a:	00431693          	slli	a3,t1,0x4
ffffffffc0201f3e:	406686b3          	sub	a3,a3,t1
ffffffffc0201f42:	068e                	slli	a3,a3,0x3
ffffffffc0201f44:	96fe                	add	a3,a3,t6
ffffffffc0201f46:	4a80                	lw	s0,16(a3)
ffffffffc0201f48:	6284                	ld	s1,0(a3)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201f4a:	ccccd6b7          	lui	a3,0xccccd
ffffffffc0201f4e:	00c4191b          	slliw	s2,s0,0xc
ffffffffc0201f52:	1902                	slli	s2,s2,0x20
ffffffffc0201f54:	02095913          	srli	s2,s2,0x20
    s->npages = c->slab_pages;
ffffffffc0201f58:	c900                	sw	s0,16(a0)
    cap = (unsigned int)((c->slab_pages * SLUB_PAGE_SIZE) / c->objsize);
ffffffffc0201f5a:	02995433          	divu	s0,s2,s1
ffffffffc0201f5e:	ccd68693          	addi	a3,a3,-819 # ffffffffcccccccd <end+0xcab34d5>
ffffffffc0201f62:	02069393          	slli	t2,a3,0x20
ffffffffc0201f66:	00d389b3          	add	s3,t2,a3
ffffffffc0201f6a:	00018697          	auipc	a3,0x18
ffffffffc0201f6e:	8466b683          	ld	a3,-1978(a3) # ffffffffc02197b0 <pages>
    s->pages = pages;
ffffffffc0201f72:	01453423          	sd	s4,8(a0)
}

static inline void *slub_port_page_kva(slub_page_t *base) {
    /* 按真实映射关系访问物理页：VA = PA + va_pa_offset（勿解引用物理地址） */
    return (void *)(page2pa(base) + va_pa_offset);
ffffffffc0201f76:	00018397          	auipc	t2,0x18
ffffffffc0201f7a:	82a3b383          	ld	t2,-2006(t2) # ffffffffc02197a0 <va_pa_offset>
ffffffffc0201f7e:	40da06b3          	sub	a3,s4,a3
ffffffffc0201f82:	868d                	srai	a3,a3,0x3
ffffffffc0201f84:	00002a17          	auipc	s4,0x2
ffffffffc0201f88:	47ca3a03          	ld	s4,1148(s4) # ffffffffc0204400 <nbase>
    s->inuse = 0;
ffffffffc0201f8c:	00052c23          	sw	zero,24(a0)
    s->cls = (unsigned char)cls;
ffffffffc0201f90:	01c50e23          	sb	t3,28(a0)
    s->next = NULL;
ffffffffc0201f94:	02053423          	sd	zero,40(a0)
    s->freelist = NULL;
ffffffffc0201f98:	02053023          	sd	zero,32(a0)
ffffffffc0201f9c:	033686b3          	mul	a3,a3,s3
    cap = (unsigned int)((c->slab_pages * SLUB_PAGE_SIZE) / c->objsize);
ffffffffc0201fa0:	2401                	sext.w	s0,s0
    s->state = SLUB_SLAB_EMPTY; /* 尚未入链，由 refill 决定 PARTIAL/FULL */
ffffffffc0201fa2:	498d                	li	s3,3
    s->capacity = cap;
ffffffffc0201fa4:	c940                	sw	s0,20(a0)
    s->state = SLUB_SLAB_EMPTY; /* 尚未入链，由 refill 决定 PARTIAL/FULL */
ffffffffc0201fa6:	01350ea3          	sb	s3,29(a0)
ffffffffc0201faa:	96d2                	add	a3,a3,s4
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fac:	06b2                	slli	a3,a3,0xc
ffffffffc0201fae:	969e                	add	a3,a3,t2
    s->base = kva;
ffffffffc0201fb0:	e114                	sd	a3,0(a0)
    for (i = 0; i < cap; i++) {
ffffffffc0201fb2:	00996963          	bltu	s2,s1,ffffffffc0201fc4 <slub_alloc_small+0x588>
        *(void **)obj = s->freelist;
ffffffffc0201fb6:	e298                	sd	a4,0(a3)
    for (i = 0; i < cap; i++) {
ffffffffc0201fb8:	2785                	addiw	a5,a5,1
        void *obj = (void *)(kva + (uintptr_t)i * c->objsize);
ffffffffc0201fba:	8736                	mv	a4,a3
    for (i = 0; i < cap; i++) {
ffffffffc0201fbc:	96a6                	add	a3,a3,s1
ffffffffc0201fbe:	fef41ce3          	bne	s0,a5,ffffffffc0201fb6 <slub_alloc_small+0x57a>
ffffffffc0201fc2:	f118                	sd	a4,32(a0)
    unsigned long s = read_csr(sstatus);
ffffffffc0201fc4:	100027f3          	csrr	a5,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0201fc8:	8b89                	andi	a5,a5,2
ffffffffc0201fca:	8bbe                	mv	s7,a5
    if (*flags) {
ffffffffc0201fcc:	c399                	beqz	a5,ffffffffc0201fd2 <slub_alloc_small+0x596>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0201fce:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0201fd2:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc0201fd6:	4705                	li	a4,1
ffffffffc0201fd8:	0ce5a72f          	amoswap.w.aq	a4,a4,(a1)
ffffffffc0201fdc:	2701                	sext.w	a4,a4
ffffffffc0201fde:	ff65                	bnez	a4,ffffffffc0201fd6 <slub_alloc_small+0x59a>
    __sync_synchronize(); /* acquire */
ffffffffc0201fe0:	0330000f          	fence	rw,rw
    unsigned int lo = 0, hi = slub_index_nr, mid, i;
ffffffffc0201fe4:	00018697          	auipc	a3,0x18
ffffffffc0201fe8:	8086a683          	lw	a3,-2040(a3) # ffffffffc02197ec <slub_index_nr>
    if (slub_index_nr >= SLUB_MAX_SLABS) {
ffffffffc0201fec:	3ff00793          	li	a5,1023
    unsigned int lo = 0, hi = slub_index_nr, mid, i;
ffffffffc0201ff0:	8a36                	mv	s4,a3
    if (slub_index_nr >= SLUB_MAX_SLABS) {
ffffffffc0201ff2:	12d7ed63          	bltu	a5,a3,ffffffffc020212c <slub_alloc_small+0x6f0>
    unsigned int lo = 0, hi = slub_index_nr, mid, i;
ffffffffc0201ff6:	8936                	mv	s2,a3
ffffffffc0201ff8:	00006497          	auipc	s1,0x6
ffffffffc0201ffc:	03848493          	addi	s1,s1,56 # ffffffffc0208030 <slub_index>
    while (lo < hi) {
ffffffffc0202000:	03277463          	bgeu	a4,s2,ffffffffc0202028 <slub_alloc_small+0x5ec>
        mid = lo + (hi - lo) / 2;
ffffffffc0202004:	40e907bb          	subw	a5,s2,a4
ffffffffc0202008:	0017d79b          	srliw	a5,a5,0x1
ffffffffc020200c:	9fb9                	addw	a5,a5,a4
        if (slub_index[mid]->base < s->base)
ffffffffc020200e:	02079413          	slli	s0,a5,0x20
ffffffffc0202012:	01d45693          	srli	a3,s0,0x1d
ffffffffc0202016:	96a6                	add	a3,a3,s1
ffffffffc0202018:	6280                	ld	s0,0(a3)
ffffffffc020201a:	6114                	ld	a3,0(a0)
ffffffffc020201c:	6000                	ld	s0,0(s0)
ffffffffc020201e:	0ad46863          	bltu	s0,a3,ffffffffc02020ce <slub_alloc_small+0x692>
            hi = mid;
ffffffffc0202022:	893e                	mv	s2,a5
    while (lo < hi) {
ffffffffc0202024:	ff2760e3          	bltu	a4,s2,ffffffffc0202004 <slub_alloc_small+0x5c8>
    for (i = slub_index_nr; i > lo; i--) slub_index[i] = slub_index[i - 1];
ffffffffc0202028:	05477463          	bgeu	a4,s4,ffffffffc0202070 <slub_alloc_small+0x634>
ffffffffc020202c:	fffa079b          	addiw	a5,s4,-1
ffffffffc0202030:	40e7843b          	subw	s0,a5,a4
ffffffffc0202034:	1402                	slli	s0,s0,0x20
ffffffffc0202036:	1782                	slli	a5,a5,0x20
ffffffffc0202038:	9381                	srli	a5,a5,0x20
ffffffffc020203a:	9001                	srli	s0,s0,0x20
ffffffffc020203c:	020a1913          	slli	s2,s4,0x20
ffffffffc0202040:	40878433          	sub	s0,a5,s0
ffffffffc0202044:	00006697          	auipc	a3,0x6
ffffffffc0202048:	fe468693          	addi	a3,a3,-28 # ffffffffc0208028 <free_area+0x10>
ffffffffc020204c:	01d95393          	srli	t2,s2,0x1d
ffffffffc0202050:	040e                	slli	s0,s0,0x3
ffffffffc0202052:	00379913          	slli	s2,a5,0x3
ffffffffc0202056:	9436                	add	s0,s0,a3
ffffffffc0202058:	012487b3          	add	a5,s1,s2
ffffffffc020205c:	0007b983          	ld	s3,0(a5)
ffffffffc0202060:	412786b3          	sub	a3,a5,s2
ffffffffc0202064:	969e                	add	a3,a3,t2
ffffffffc0202066:	0136b023          	sd	s3,0(a3)
ffffffffc020206a:	17e1                	addi	a5,a5,-8
ffffffffc020206c:	fe8798e3          	bne	a5,s0,ffffffffc020205c <slub_alloc_small+0x620>
    slub_index[lo] = s;
ffffffffc0202070:	02071693          	slli	a3,a4,0x20
ffffffffc0202074:	01d6d793          	srli	a5,a3,0x1d
ffffffffc0202078:	97a6                	add	a5,a5,s1
    slub_index_nr++;
ffffffffc020207a:	001a071b          	addiw	a4,s4,1
    slub_index[lo] = s;
ffffffffc020207e:	e388                	sd	a0,0(a5)
    slub_index_nr++;
ffffffffc0202080:	00017797          	auipc	a5,0x17
ffffffffc0202084:	76e7a623          	sw	a4,1900(a5) # ffffffffc02197ec <slub_index_nr>
    __sync_synchronize(); /* release */
ffffffffc0202088:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc020208c:	0310000f          	fence	rw,w
ffffffffc0202090:	0005a023          	sw	zero,0(a1)
    __sync_synchronize();
ffffffffc0202094:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0202098:	000b8463          	beqz	s7,ffffffffc02020a0 <slub_alloc_small+0x664>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc020209c:	100167f3          	csrrsi	a5,sstatus,2
    c->nr_slabs++;
ffffffffc02020a0:	00431793          	slli	a5,t1,0x4
ffffffffc02020a4:	406787b3          	sub	a5,a5,t1
ffffffffc02020a8:	078e                	slli	a5,a5,0x3
ffffffffc02020aa:	97fe                	add	a5,a5,t6
ffffffffc02020ac:	5bd4                	lw	a3,52(a5)
    c->nr_slab_pages += c->slab_pages;
ffffffffc02020ae:	5f80                	lw	s0,56(a5)
ffffffffc02020b0:	4b8c                	lw	a1,16(a5)
    c->nr_slabs++;
ffffffffc02020b2:	2685                	addiw	a3,a3,1
ffffffffc02020b4:	dbd4                	sw	a3,52(a5)
    c->stat_slab_new++;
ffffffffc02020b6:	6fb4                	ld	a3,88(a5)
    c->nr_slab_pages += c->slab_pages;
ffffffffc02020b8:	9da1                	addw	a1,a1,s0
ffffffffc02020ba:	74f6                	ld	s1,376(sp)
    c->stat_slab_new++;
ffffffffc02020bc:	0685                	addi	a3,a3,1
ffffffffc02020be:	7956                	ld	s2,368(sp)
ffffffffc02020c0:	79b6                	ld	s3,360(sp)
ffffffffc02020c2:	7a16                	ld	s4,352(sp)
ffffffffc02020c4:	6bb6                	ld	s7,328(sp)
            s = slub_slab_create(c, cls);
ffffffffc02020c6:	872a                	mv	a4,a0
    c->nr_slab_pages += c->slab_pages;
ffffffffc02020c8:	df8c                	sw	a1,56(a5)
    c->stat_slab_new++;
ffffffffc02020ca:	efb4                	sd	a3,88(a5)
            if (s == NULL) break; /* 页耗尽 / 描述符耗尽 */
ffffffffc02020cc:	bea5                	j	ffffffffc0201c44 <slub_alloc_small+0x208>
            lo = mid + 1;
ffffffffc02020ce:	0017871b          	addiw	a4,a5,1
ffffffffc02020d2:	b73d                	j	ffffffffc0202000 <slub_alloc_small+0x5c4>
ffffffffc02020d4:	100166f3          	csrrsi	a3,sstatus,2
    if (s == NULL) {
ffffffffc02020d8:	b58d                	j	ffffffffc0201f3a <slub_alloc_small+0x4fe>
        c->stat_page_fail++;
ffffffffc02020da:	743c                	ld	a5,104(s0)
ffffffffc02020dc:	0785                	addi	a5,a5,1
ffffffffc02020de:	f43c                	sd	a5,104(s0)
            if (s == NULL) break; /* 页耗尽 / 描述符耗尽 */
ffffffffc02020e0:	b389                	j	ffffffffc0201e22 <slub_alloc_small+0x3e6>
    __sync_synchronize(); /* release */
ffffffffc02020e2:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc02020e6:	0310000f          	fence	rw,w
ffffffffc02020ea:	000ea023          	sw	zero,0(t4)
    __sync_synchronize();
ffffffffc02020ee:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02020f2:	d60a87e3          	beqz	s5,ffffffffc0201e60 <slub_alloc_small+0x424>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc02020f6:	100167f3          	csrrsi	a5,sstatus,2
    if (n == 0) return NULL;
ffffffffc02020fa:	b39d                	j	ffffffffc0201e60 <slub_alloc_small+0x424>
        slub_port_panic("slub: cpu id %lu >= SLUB_NCPUS %d (build with a "
ffffffffc02020fc:	00006697          	auipc	a3,0x6
ffffffffc0202100:	f046e683          	lwu	a3,-252(a3) # ffffffffc0208000 <boot_hartid>
ffffffffc0202104:	4705                	li	a4,1
ffffffffc0202106:	00002617          	auipc	a2,0x2
ffffffffc020210a:	9ea60613          	addi	a2,a2,-1558 # ffffffffc0203af0 <etext+0x83e>
ffffffffc020210e:	0dd00593          	li	a1,221
ffffffffc0202112:	00002517          	auipc	a0,0x2
ffffffffc0202116:	9a650513          	addi	a0,a0,-1626 # ffffffffc0203ab8 <etext+0x806>
ffffffffc020211a:	fea6                	sd	s1,376(sp)
ffffffffc020211c:	faca                	sd	s2,368(sp)
ffffffffc020211e:	f6ce                	sd	s3,360(sp)
ffffffffc0202120:	f2d2                	sd	s4,352(sp)
ffffffffc0202122:	eed6                	sd	s5,344(sp)
ffffffffc0202124:	eada                	sd	s6,336(sp)
ffffffffc0202126:	e6de                	sd	s7,328(sp)
ffffffffc0202128:	8a4fe0ef          	jal	ffffffffc02001cc <__panic>
        slub_port_panic("slub: slab registry overflow");
ffffffffc020212c:	00002617          	auipc	a2,0x2
ffffffffc0202130:	ac460613          	addi	a2,a2,-1340 # ffffffffc0203bf0 <etext+0x93e>
ffffffffc0202134:	12600593          	li	a1,294
ffffffffc0202138:	00002517          	auipc	a0,0x2
ffffffffc020213c:	98050513          	addi	a0,a0,-1664 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0202140:	88cfe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0202144 <slub_shrink.part.0>:
/*
 * 回收空闲内存：排空每 CPU sheaf 与共享 barn -> 归还空 slab 的页。
 * 前提：所有调用者静止（无并发 kmalloc/kfree，无对象正在跨 CPU 传递）。
 * 不释放仍被用户持有的对象；大对象保持不动（它们由用户持有）。
 */
void slub_shrink(void) {
ffffffffc0202144:	714d                	addi	sp,sp,-336
ffffffffc0202146:	e2a2                	sd	s0,320(sp)
ffffffffc0202148:	fe26                	sd	s1,312(sp)
ffffffffc020214a:	fa4a                	sd	s2,304(sp)
ffffffffc020214c:	f64e                	sd	s3,296(sp)
ffffffffc020214e:	f252                	sd	s4,288(sp)
ffffffffc0202150:	ee56                	sd	s5,280(sp)
ffffffffc0202152:	e686                	sd	ra,328(sp)
ffffffffc0202154:	e65e                	sd	s7,264(sp)
ffffffffc0202156:	e262                	sd	s8,256(sp)
ffffffffc0202158:	00017417          	auipc	s0,0x17
ffffffffc020215c:	25840413          	addi	s0,s0,600 # ffffffffc02193b0 <slub_caches>
ffffffffc0202160:	00017a17          	auipc	s4,0x17
ffffffffc0202164:	110a0a13          	addi	s4,s4,272 # ffffffffc0219270 <slub_barns>
ffffffffc0202168:	00017a97          	auipc	s5,0x17
ffffffffc020216c:	008a8a93          	addi	s5,s5,8 # ffffffffc0219170 <slub_cc>
    unsigned int cls, cpu;

    if (slub_inited == 0) return;

    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
ffffffffc0202170:	4481                	li	s1,0
        /* 2) 共享 barn -> slab 层（分批，不经过 barn） */
        for (;;) {
            unsigned int k;
            slub_port_spin_lock(&b->lock, &f);
            k = b->size;
            if (k > SLUB_SHEAF_MAX_CAP) k = SLUB_SHEAF_MAX_CAP;
ffffffffc0202172:	02000913          	li	s2,32
    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
ffffffffc0202176:	49a1                	li	s3,8
    unsigned long s = read_csr(sstatus);
ffffffffc0202178:	10002573          	csrr	a0,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc020217c:	8909                	andi	a0,a0,2
    if (*flags) {
ffffffffc020217e:	10051d63          	bnez	a0,ffffffffc0202298 <slub_shrink.part.0+0x154>
    __sync_synchronize();
ffffffffc0202182:	0330000f          	fence	rw,rw
    unsigned int n = sf->size, i;
ffffffffc0202186:	008aa603          	lw	a2,8(s5)
    for (i = 0; i < n; i++) out[i] = sf->objs[i];
ffffffffc020218a:	1c060763          	beqz	a2,ffffffffc0202358 <slub_shrink.part.0+0x214>
ffffffffc020218e:	000ab783          	ld	a5,0(s5)
ffffffffc0202192:	02061713          	slli	a4,a2,0x20
ffffffffc0202196:	01d75593          	srli	a1,a4,0x1d
ffffffffc020219a:	95be                	add	a1,a1,a5
ffffffffc020219c:	870a                	mv	a4,sp
ffffffffc020219e:	6394                	ld	a3,0(a5)
ffffffffc02021a0:	07a1                	addi	a5,a5,8
ffffffffc02021a2:	0721                	addi	a4,a4,8
ffffffffc02021a4:	fed73c23          	sd	a3,-8(a4)
ffffffffc02021a8:	feb79be3          	bne	a5,a1,ffffffffc020219e <slub_shrink.part.0+0x5a>
    sf->size = 0;
ffffffffc02021ac:	000aa423          	sw	zero,8(s5)
    __sync_synchronize();
ffffffffc02021b0:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02021b4:	c119                	beqz	a0,ffffffffc02021ba <slub_shrink.part.0+0x76>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc02021b6:	100167f3          	csrrsi	a5,sstatus,2
            if (n != 0) slub_put_objects(cls, batch, n, SLUB_PUT_SLAB);
ffffffffc02021ba:	4685                	li	a3,1
ffffffffc02021bc:	858a                	mv	a1,sp
ffffffffc02021be:	8526                	mv	a0,s1
ffffffffc02021c0:	beaff0ef          	jal	ffffffffc02015aa <slub_put_objects>
    unsigned long s = read_csr(sstatus);
ffffffffc02021c4:	10002573          	csrr	a0,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc02021c8:	8909                	andi	a0,a0,2
    if (*flags) {
ffffffffc02021ca:	e95d                	bnez	a0,ffffffffc0202280 <slub_shrink.part.0+0x13c>
    __sync_synchronize();
ffffffffc02021cc:	0330000f          	fence	rw,rw
    unsigned int n = sf->size, i;
ffffffffc02021d0:	018aa603          	lw	a2,24(s5)
    for (i = 0; i < n; i++) out[i] = sf->objs[i];
ffffffffc02021d4:	18060563          	beqz	a2,ffffffffc020235e <slub_shrink.part.0+0x21a>
ffffffffc02021d8:	010ab783          	ld	a5,16(s5)
ffffffffc02021dc:	02061713          	slli	a4,a2,0x20
ffffffffc02021e0:	01d75593          	srli	a1,a4,0x1d
ffffffffc02021e4:	95be                	add	a1,a1,a5
ffffffffc02021e6:	870a                	mv	a4,sp
ffffffffc02021e8:	6394                	ld	a3,0(a5)
ffffffffc02021ea:	07a1                	addi	a5,a5,8
ffffffffc02021ec:	0721                	addi	a4,a4,8
ffffffffc02021ee:	fed73c23          	sd	a3,-8(a4)
ffffffffc02021f2:	feb79be3          	bne	a5,a1,ffffffffc02021e8 <slub_shrink.part.0+0xa4>
    sf->size = 0;
ffffffffc02021f6:	000aac23          	sw	zero,24(s5)
    __sync_synchronize();
ffffffffc02021fa:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02021fe:	ed35                	bnez	a0,ffffffffc020227a <slub_shrink.part.0+0x136>
            if (n != 0) slub_put_objects(cls, batch, n, SLUB_PUT_SLAB);
ffffffffc0202200:	4685                	li	a3,1
ffffffffc0202202:	858a                	mv	a1,sp
ffffffffc0202204:	8526                	mv	a0,s1
ffffffffc0202206:	ba4ff0ef          	jal	ffffffffc02015aa <slub_put_objects>
    unsigned long s = read_csr(sstatus);
ffffffffc020220a:	100028f3          	csrr	a7,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc020220e:	0028f893          	andi	a7,a7,2
    if (*flags) {
ffffffffc0202212:	00088463          	beqz	a7,ffffffffc020221a <slub_shrink.part.0+0xd6>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0202216:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc020221a:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc020221e:	4785                	li	a5,1
ffffffffc0202220:	0cfa27af          	amoswap.w.aq	a5,a5,(s4)
ffffffffc0202224:	2781                	sext.w	a5,a5
ffffffffc0202226:	ffe5                	bnez	a5,ffffffffc020221e <slub_shrink.part.0+0xda>
    __sync_synchronize(); /* acquire */
ffffffffc0202228:	0330000f          	fence	rw,rw
            k = b->size;
ffffffffc020222c:	010a2583          	lw	a1,16(s4)
            for (n = 0; n < k; n++) batch[n] = b->objs[b->size - k + n];
ffffffffc0202230:	c1c9                	beqz	a1,ffffffffc02022b2 <slub_shrink.part.0+0x16e>
            if (k > SLUB_SHEAF_MAX_CAP) k = SLUB_SHEAF_MAX_CAP;
ffffffffc0202232:	0005861b          	sext.w	a2,a1
ffffffffc0202236:	00b97463          	bgeu	s2,a1,ffffffffc020223e <slub_shrink.part.0+0xfa>
ffffffffc020223a:	02000613          	li	a2,32
            for (n = 0; n < k; n++) batch[n] = b->objs[b->size - k + n];
ffffffffc020223e:	008a3503          	ld	a0,8(s4)
            b->size -= k;
ffffffffc0202242:	9d91                	subw	a1,a1,a2
ffffffffc0202244:	868a                	mv	a3,sp
            for (n = 0; n < k; n++) batch[n] = b->objs[b->size - k + n];
ffffffffc0202246:	00b7873b          	addw	a4,a5,a1
ffffffffc020224a:	02071813          	slli	a6,a4,0x20
ffffffffc020224e:	01d85713          	srli	a4,a6,0x1d
ffffffffc0202252:	972a                	add	a4,a4,a0
ffffffffc0202254:	6318                	ld	a4,0(a4)
ffffffffc0202256:	2785                	addiw	a5,a5,1
ffffffffc0202258:	06a1                	addi	a3,a3,8
ffffffffc020225a:	fee6bc23          	sd	a4,-8(a3)
ffffffffc020225e:	fec7e4e3          	bltu	a5,a2,ffffffffc0202246 <slub_shrink.part.0+0x102>
            b->size -= k;
ffffffffc0202262:	00ba2823          	sw	a1,16(s4)
    __sync_synchronize(); /* release */
ffffffffc0202266:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc020226a:	0310000f          	fence	rw,w
ffffffffc020226e:	000a2023          	sw	zero,0(s4)
    __sync_synchronize();
ffffffffc0202272:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0202276:	f80885e3          	beqz	a7,ffffffffc0202200 <slub_shrink.part.0+0xbc>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc020227a:	100167f3          	csrrsi	a5,sstatus,2
            if (n != 0) slub_put_objects(cls, batch, n, SLUB_PUT_SLAB);
ffffffffc020227e:	b749                	j	ffffffffc0202200 <slub_shrink.part.0+0xbc>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0202280:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc0202284:	0330000f          	fence	rw,rw
    unsigned int n = sf->size, i;
ffffffffc0202288:	018aa603          	lw	a2,24(s5)
    for (i = 0; i < n; i++) out[i] = sf->objs[i];
ffffffffc020228c:	f631                	bnez	a2,ffffffffc02021d8 <slub_shrink.part.0+0x94>
    __sync_synchronize();
ffffffffc020228e:	0330000f          	fence	rw,rw
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0202292:	100167f3          	csrrsi	a5,sstatus,2
            if (n != 0) slub_put_objects(cls, batch, n, SLUB_PUT_SLAB);
ffffffffc0202296:	bf95                	j	ffffffffc020220a <slub_shrink.part.0+0xc6>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc0202298:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc020229c:	0330000f          	fence	rw,rw
    unsigned int n = sf->size, i;
ffffffffc02022a0:	008aa603          	lw	a2,8(s5)
    for (i = 0; i < n; i++) out[i] = sf->objs[i];
ffffffffc02022a4:	ee0615e3          	bnez	a2,ffffffffc020218e <slub_shrink.part.0+0x4a>
    __sync_synchronize();
ffffffffc02022a8:	0330000f          	fence	rw,rw
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc02022ac:	100167f3          	csrrsi	a5,sstatus,2
            if (n != 0) slub_put_objects(cls, batch, n, SLUB_PUT_SLAB);
ffffffffc02022b0:	bf11                	j	ffffffffc02021c4 <slub_shrink.part.0+0x80>
    __sync_synchronize(); /* release */
ffffffffc02022b2:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc02022b6:	0310000f          	fence	rw,w
ffffffffc02022ba:	000a2023          	sw	zero,0(s4)
    __sync_synchronize();
ffffffffc02022be:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02022c2:	00088463          	beqz	a7,ffffffffc02022ca <slub_shrink.part.0+0x186>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc02022c6:	100167f3          	csrrsi	a5,sstatus,2
    unsigned long s = read_csr(sstatus);
ffffffffc02022ca:	10002c73          	csrr	s8,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc02022ce:	002c7c13          	andi	s8,s8,2
    if (*flags) {
ffffffffc02022d2:	000c0463          	beqz	s8,ffffffffc02022da <slub_shrink.part.0+0x196>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc02022d6:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc02022da:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc02022de:	01440b93          	addi	s7,s0,20
ffffffffc02022e2:	4785                	li	a5,1
ffffffffc02022e4:	0cfba7af          	amoswap.w.aq	a5,a5,(s7)
ffffffffc02022e8:	2781                	sext.w	a5,a5
ffffffffc02022ea:	ffe5                	bnez	a5,ffffffffc02022e2 <slub_shrink.part.0+0x19e>
    __sync_synchronize(); /* acquire */
ffffffffc02022ec:	0330000f          	fence	rw,rw

        /* 3) 归还所有空 slab；partial 链上的 slab 必然有活跃对象 */
        slub_port_spin_lock(&c->lock, &f);
        {
            struct slub_slab *s;
            for (s = c->partial; s != NULL; s = s->next) {
ffffffffc02022f0:	6c1c                	ld	a5,24(s0)
ffffffffc02022f2:	c38d                	beqz	a5,ffffffffc0202314 <slub_shrink.part.0+0x1d0>
                slub_port_assert(s->inuse > 0);
ffffffffc02022f4:	4f98                	lw	a4,24(a5)
ffffffffc02022f6:	c73d                	beqz	a4,ffffffffc0202364 <slub_shrink.part.0+0x220>
            for (s = c->partial; s != NULL; s = s->next) {
ffffffffc02022f8:	779c                	ld	a5,40(a5)
ffffffffc02022fa:	ffed                	bnez	a5,ffffffffc02022f4 <slub_shrink.part.0+0x1b0>
            }
        }
        while (c->empty != NULL) {
ffffffffc02022fc:	700c                	ld	a1,32(s0)
ffffffffc02022fe:	cd89                	beqz	a1,ffffffffc0202318 <slub_shrink.part.0+0x1d4>
            struct slub_slab *s = c->empty;
            c->empty = s->next;
ffffffffc0202300:	7598                	ld	a4,40(a1)
            s->next = NULL;
            c->nr_empty--;
ffffffffc0202302:	545c                	lw	a5,44(s0)
            slub_slab_destroy(c, s);
ffffffffc0202304:	8522                	mv	a0,s0
            c->empty = s->next;
ffffffffc0202306:	f018                	sd	a4,32(s0)
            s->next = NULL;
ffffffffc0202308:	0205b423          	sd	zero,40(a1)
            c->nr_empty--;
ffffffffc020230c:	37fd                	addiw	a5,a5,-1
ffffffffc020230e:	d45c                	sw	a5,44(s0)
            slub_slab_destroy(c, s);
ffffffffc0202310:	8e0ff0ef          	jal	ffffffffc02013f0 <slub_slab_destroy>
        while (c->empty != NULL) {
ffffffffc0202314:	700c                	ld	a1,32(s0)
ffffffffc0202316:	f5ed                	bnez	a1,ffffffffc0202300 <slub_shrink.part.0+0x1bc>
    __sync_synchronize(); /* release */
ffffffffc0202318:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc020231c:	0310000f          	fence	rw,w
ffffffffc0202320:	000ba023          	sw	zero,0(s7)
    __sync_synchronize();
ffffffffc0202324:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0202328:	000c0463          	beqz	s8,ffffffffc0202330 <slub_shrink.part.0+0x1ec>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc020232c:	100167f3          	csrrsi	a5,sstatus,2
    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
ffffffffc0202330:	2485                	addiw	s1,s1,1
ffffffffc0202332:	07840413          	addi	s0,s0,120
ffffffffc0202336:	028a0a13          	addi	s4,s4,40
ffffffffc020233a:	020a8a93          	addi	s5,s5,32
ffffffffc020233e:	e3349de3          	bne	s1,s3,ffffffffc0202178 <slub_shrink.part.0+0x34>
        }
        slub_port_spin_unlock(&c->lock, &f);
    }
}
ffffffffc0202342:	60b6                	ld	ra,328(sp)
ffffffffc0202344:	6416                	ld	s0,320(sp)
ffffffffc0202346:	74f2                	ld	s1,312(sp)
ffffffffc0202348:	7952                	ld	s2,304(sp)
ffffffffc020234a:	79b2                	ld	s3,296(sp)
ffffffffc020234c:	7a12                	ld	s4,288(sp)
ffffffffc020234e:	6af2                	ld	s5,280(sp)
ffffffffc0202350:	6bb2                	ld	s7,264(sp)
ffffffffc0202352:	6c12                	ld	s8,256(sp)
ffffffffc0202354:	6171                	addi	sp,sp,336
ffffffffc0202356:	8082                	ret
    __sync_synchronize();
ffffffffc0202358:	0330000f          	fence	rw,rw
            if (n != 0) slub_put_objects(cls, batch, n, SLUB_PUT_SLAB);
ffffffffc020235c:	b5a5                	j	ffffffffc02021c4 <slub_shrink.part.0+0x80>
ffffffffc020235e:	0330000f          	fence	rw,rw
            if (n != 0) slub_put_objects(cls, batch, n, SLUB_PUT_SLAB);
ffffffffc0202362:	b565                	j	ffffffffc020220a <slub_shrink.part.0+0xc6>
                slub_port_assert(s->inuse > 0);
ffffffffc0202364:	00002697          	auipc	a3,0x2
ffffffffc0202368:	8ac68693          	addi	a3,a3,-1876 # ffffffffc0203c10 <etext+0x95e>
ffffffffc020236c:	00001617          	auipc	a2,0x1
ffffffffc0202370:	1b460613          	addi	a2,a2,436 # ffffffffc0203520 <etext+0x26e>
ffffffffc0202374:	34a00593          	li	a1,842
ffffffffc0202378:	00001517          	auipc	a0,0x1
ffffffffc020237c:	74050513          	addi	a0,a0,1856 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0202380:	ea5a                	sd	s6,272(sp)
ffffffffc0202382:	e4bfd0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0202386 <kmalloc>:
    if (size == 0) return NULL;
ffffffffc0202386:	10050f63          	beqz	a0,ffffffffc02024a4 <kmalloc+0x11e>
    if (slub_inited == 0) {
ffffffffc020238a:	00017797          	auipc	a5,0x17
ffffffffc020238e:	44e7a783          	lw	a5,1102(a5) # ffffffffc02197d8 <slub_inited>
void *kmalloc(size_t size) {
ffffffffc0202392:	1101                	addi	sp,sp,-32
ffffffffc0202394:	ec06                	sd	ra,24(sp)
ffffffffc0202396:	872a                	mv	a4,a0
    if (slub_inited == 0) {
ffffffffc0202398:	10078863          	beqz	a5,ffffffffc02024a8 <kmalloc+0x122>
    if (size == 0 || size > SLUB_MAX_SMALL_SIZE) return -1;
ffffffffc020239c:	fff50793          	addi	a5,a0,-1
ffffffffc02023a0:	7ff00693          	li	a3,2047
ffffffffc02023a4:	0ef6e863          	bltu	a3,a5,ffffffffc0202494 <kmalloc+0x10e>
ffffffffc02023a8:	00002797          	auipc	a5,0x2
ffffffffc02023ac:	e8878793          	addi	a5,a5,-376 # ffffffffc0204230 <slub_sizes>
    for (cls = 0; cls < (int)SLUB_NCLASSES; cls++) {
ffffffffc02023b0:	4501                	li	a0,0
ffffffffc02023b2:	4621                	li	a2,8
        if (size <= slub_sizes[cls]) return cls;
ffffffffc02023b4:	6394                	ld	a3,0(a5)
ffffffffc02023b6:	0ce6f563          	bgeu	a3,a4,ffffffffc0202480 <kmalloc+0xfa>
    for (cls = 0; cls < (int)SLUB_NCLASSES; cls++) {
ffffffffc02023ba:	2505                	addiw	a0,a0,1
ffffffffc02023bc:	07a1                	addi	a5,a5,8
ffffffffc02023be:	fec51be3          	bne	a0,a2,ffffffffc02023b4 <kmalloc+0x2e>
    npages = (bytes + SLUB_PAGE_SIZE - 1) / SLUB_PAGE_SIZE; /* 无乘法 */
ffffffffc02023c2:	6785                	lui	a5,0x1
ffffffffc02023c4:	07fd                	addi	a5,a5,31 # 101f <kern_entry-0xffffffffc01fefe1>
ffffffffc02023c6:	973e                	add	a4,a4,a5
ffffffffc02023c8:	8331                	srli	a4,a4,0xc
    base = slub_pages_alloc(npages);
ffffffffc02023ca:	853a                	mv	a0,a4
ffffffffc02023cc:	e43a                	sd	a4,8(sp)
ffffffffc02023ce:	f89fe0ef          	jal	ffffffffc0201356 <slub_pages_alloc>
    if (base == NULL) return NULL;
ffffffffc02023d2:	c569                	beqz	a0,ffffffffc020249c <kmalloc+0x116>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02023d4:	00017697          	auipc	a3,0x17
ffffffffc02023d8:	3dc6b683          	ld	a3,988(a3) # ffffffffc02197b0 <pages>
ffffffffc02023dc:	ccccd7b7          	lui	a5,0xccccd
ffffffffc02023e0:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcab34d5>
ffffffffc02023e4:	02079613          	slli	a2,a5,0x20
ffffffffc02023e8:	40d506b3          	sub	a3,a0,a3
ffffffffc02023ec:	97b2                	add	a5,a5,a2
ffffffffc02023ee:	868d                	srai	a3,a3,0x3
ffffffffc02023f0:	02f686b3          	mul	a3,a3,a5
ffffffffc02023f4:	00002597          	auipc	a1,0x2
ffffffffc02023f8:	00c5b583          	ld	a1,12(a1) # ffffffffc0204400 <nbase>
    return (void *)(page2pa(base) + va_pa_offset);
ffffffffc02023fc:	00017617          	auipc	a2,0x17
ffffffffc0202400:	3a463603          	ld	a2,932(a2) # ffffffffc02197a0 <va_pa_offset>
    h->magic = SLUB_MAGIC_LARGE;
ffffffffc0202404:	00002797          	auipc	a5,0x2
ffffffffc0202408:	0047b783          	ld	a5,4(a5) # ffffffffc0204408 <nbase+0x8>
    h->npages = npages;
ffffffffc020240c:	6722                	ld	a4,8(sp)
ffffffffc020240e:	96ae                	add	a3,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0202410:	06b2                	slli	a3,a3,0xc
ffffffffc0202412:	96b2                	add	a3,a3,a2
    h->base = base;
ffffffffc0202414:	e688                	sd	a0,8(a3)
    h->npages = npages;
ffffffffc0202416:	ea98                	sd	a4,16(a3)
    h->pad = 0;
ffffffffc0202418:	0006bc23          	sd	zero,24(a3)
    h->magic = SLUB_MAGIC_LARGE;
ffffffffc020241c:	e29c                	sd	a5,0(a3)
    unsigned long s = read_csr(sstatus);
ffffffffc020241e:	100025f3          	csrr	a1,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc0202422:	8989                	andi	a1,a1,2
    if (*flags) {
ffffffffc0202424:	e5ad                	bnez	a1,ffffffffc020248e <kmalloc+0x108>
    __sync_synchronize();
ffffffffc0202426:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc020242a:	00017617          	auipc	a2,0x17
ffffffffc020242e:	3b660613          	addi	a2,a2,950 # ffffffffc02197e0 <slub_pmm_lock>
ffffffffc0202432:	4785                	li	a5,1
ffffffffc0202434:	0cf627af          	amoswap.w.aq	a5,a5,(a2)
ffffffffc0202438:	2781                	sext.w	a5,a5
ffffffffc020243a:	ffe5                	bnez	a5,ffffffffc0202432 <kmalloc+0xac>
    __sync_synchronize(); /* acquire */
ffffffffc020243c:	0330000f          	fence	rw,rw
    slub_large_pages += npages;
ffffffffc0202440:	00017517          	auipc	a0,0x17
ffffffffc0202444:	38853503          	ld	a0,904(a0) # ffffffffc02197c8 <slub_large_pages>
    slub_large_user++;
ffffffffc0202448:	00017797          	auipc	a5,0x17
ffffffffc020244c:	3887b783          	ld	a5,904(a5) # ffffffffc02197d0 <slub_large_user>
    slub_large_pages += npages;
ffffffffc0202450:	972a                	add	a4,a4,a0
    slub_large_user++;
ffffffffc0202452:	0785                	addi	a5,a5,1
    slub_large_pages += npages;
ffffffffc0202454:	00017517          	auipc	a0,0x17
ffffffffc0202458:	36e53a23          	sd	a4,884(a0) # ffffffffc02197c8 <slub_large_pages>
    slub_large_user++;
ffffffffc020245c:	00017717          	auipc	a4,0x17
ffffffffc0202460:	36f73a23          	sd	a5,884(a4) # ffffffffc02197d0 <slub_large_user>
    __sync_synchronize(); /* release */
ffffffffc0202464:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc0202468:	0310000f          	fence	rw,w
ffffffffc020246c:	00062023          	sw	zero,0(a2)
    __sync_synchronize();
ffffffffc0202470:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0202474:	e991                	bnez	a1,ffffffffc0202488 <kmalloc+0x102>
}
ffffffffc0202476:	60e2                	ld	ra,24(sp)
    return (char *)h + SLUB_LARGE_HDR_SIZE; /* 页对齐 + 32 => 16 对齐 */
ffffffffc0202478:	02068513          	addi	a0,a3,32
}
ffffffffc020247c:	6105                	addi	sp,sp,32
ffffffffc020247e:	8082                	ret
ffffffffc0202480:	60e2                	ld	ra,24(sp)
ffffffffc0202482:	6105                	addi	sp,sp,32
    if (cls >= 0) return slub_alloc_small((unsigned int)cls);
ffffffffc0202484:	db8ff06f          	j	ffffffffc0201a3c <slub_alloc_small>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0202488:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020248c:	b7ed                	j	ffffffffc0202476 <kmalloc+0xf0>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc020248e:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0202492:	bf51                	j	ffffffffc0202426 <kmalloc+0xa0>
    if (size > SIZE_MAX - SLUB_LARGE_HDR_SIZE) return NULL;
ffffffffc0202494:	77fd                	lui	a5,0xfffff
ffffffffc0202496:	1781                	addi	a5,a5,-32 # ffffffffffffefe0 <end+0x3fde57e8>
ffffffffc0202498:	f2a7f5e3          	bgeu	a5,a0,ffffffffc02023c2 <kmalloc+0x3c>
}
ffffffffc020249c:	60e2                	ld	ra,24(sp)
    if (size == 0) return NULL;
ffffffffc020249e:	4501                	li	a0,0
}
ffffffffc02024a0:	6105                	addi	sp,sp,32
ffffffffc02024a2:	8082                	ret
    if (size == 0) return NULL;
ffffffffc02024a4:	4501                	li	a0,0
}
ffffffffc02024a6:	8082                	ret
        slub_port_panic("slub: kmalloc before slub_init");
ffffffffc02024a8:	00001617          	auipc	a2,0x1
ffffffffc02024ac:	77860613          	addi	a2,a2,1912 # ffffffffc0203c20 <etext+0x96e>
ffffffffc02024b0:	2b200593          	li	a1,690
ffffffffc02024b4:	00001517          	auipc	a0,0x1
ffffffffc02024b8:	60450513          	addi	a0,a0,1540 # ffffffffc0203ab8 <etext+0x806>
ffffffffc02024bc:	d11fd0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02024c0 <kfree>:
    if (ptr == NULL) return; /* 契约：无操作 */
ffffffffc02024c0:	24050d63          	beqz	a0,ffffffffc020271a <kfree+0x25a>
    if (slub_inited == 0) {
ffffffffc02024c4:	00017797          	auipc	a5,0x17
ffffffffc02024c8:	3147a783          	lw	a5,788(a5) # ffffffffc02197d8 <slub_inited>
void kfree(void *ptr) {
ffffffffc02024cc:	7179                	addi	sp,sp,-48
ffffffffc02024ce:	f406                	sd	ra,40(sp)
ffffffffc02024d0:	86aa                	mv	a3,a0
    if (slub_inited == 0) {
ffffffffc02024d2:	2a078363          	beqz	a5,ffffffffc0202778 <kfree+0x2b8>
    if (((uintptr_t)ptr & (SLUB_MIN_ALIGN - 1)) != 0) {
ffffffffc02024d6:	00f57793          	andi	a5,a0,15
ffffffffc02024da:	28079263          	bnez	a5,ffffffffc020275e <kfree+0x29e>
    unsigned int lo = 0, hi = slub_index_nr, mid;
ffffffffc02024de:	00017597          	auipc	a1,0x17
ffffffffc02024e2:	30e5a583          	lw	a1,782(a1) # ffffffffc02197ec <slub_index_nr>
ffffffffc02024e6:	4601                	li	a2,0
        s = slub_index[mid];
ffffffffc02024e8:	00006517          	auipc	a0,0x6
ffffffffc02024ec:	b4850513          	addi	a0,a0,-1208 # ffffffffc0208030 <slub_index>
    while (lo < hi) {
ffffffffc02024f0:	02b67563          	bgeu	a2,a1,ffffffffc020251a <kfree+0x5a>
        mid = lo + (hi - lo) / 2;
ffffffffc02024f4:	40c587bb          	subw	a5,a1,a2
ffffffffc02024f8:	0017d79b          	srliw	a5,a5,0x1
ffffffffc02024fc:	9fb1                	addw	a5,a5,a2
        s = slub_index[mid];
ffffffffc02024fe:	02079813          	slli	a6,a5,0x20
ffffffffc0202502:	01d85713          	srli	a4,a6,0x1d
ffffffffc0202506:	972a                	add	a4,a4,a0
ffffffffc0202508:	00073803          	ld	a6,0(a4)
        if (a < s->base) {
ffffffffc020250c:	00083703          	ld	a4,0(a6)
ffffffffc0202510:	04e6f663          	bgeu	a3,a4,ffffffffc020255c <kfree+0x9c>
            hi = mid;
ffffffffc0202514:	85be                	mv	a1,a5
    while (lo < hi) {
ffffffffc0202516:	fcb66fe3          	bltu	a2,a1,ffffffffc02024f4 <kfree+0x34>
static inline size_t slub_port_nr_free_pages(void) {
    return nr_free_pages();
}

static inline void *slub_port_ram_low(void) {
    return (void *)(nbase * (size_t)PGSIZE + va_pa_offset);
ffffffffc020251a:	00002817          	auipc	a6,0x2
ffffffffc020251e:	ee683803          	ld	a6,-282(a6) # ffffffffc0204400 <nbase>
ffffffffc0202522:	00017717          	auipc	a4,0x17
ffffffffc0202526:	27e73703          	ld	a4,638(a4) # ffffffffc02197a0 <va_pa_offset>
ffffffffc020252a:	00c81793          	slli	a5,a6,0xc
ffffffffc020252e:	97ba                	add	a5,a5,a4
    return a >= (uintptr_t)slub_port_ram_low() &&
ffffffffc0202530:	00f6ea63          	bltu	a3,a5,ffffffffc0202544 <kfree+0x84>
}

static inline void *slub_port_ram_high(void) {
    return (void *)(npage * (size_t)PGSIZE + va_pa_offset);
ffffffffc0202534:	00017617          	auipc	a2,0x17
ffffffffc0202538:	27463603          	ld	a2,628(a2) # ffffffffc02197a8 <npage>
ffffffffc020253c:	0632                	slli	a2,a2,0xc
ffffffffc020253e:	963a                	add	a2,a2,a4
ffffffffc0202540:	10c6e263          	bltu	a3,a2,ffffffffc0202644 <kfree+0x184>
        slub_port_panic("slub: kfree(%lx): pointer outside RAM",
ffffffffc0202544:	00001617          	auipc	a2,0x1
ffffffffc0202548:	77460613          	addi	a2,a2,1908 # ffffffffc0203cb8 <etext+0xa06>
ffffffffc020254c:	31200593          	li	a1,786
ffffffffc0202550:	00001517          	auipc	a0,0x1
ffffffffc0202554:	56850513          	addi	a0,a0,1384 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0202558:	c75fd0ef          	jal	ffffffffc02001cc <__panic>
        } else if (a >= s->base + (uintptr_t)s->npages * SLUB_PAGE_SIZE) {
ffffffffc020255c:	01086603          	lwu	a2,16(a6)
ffffffffc0202560:	0632                	slli	a2,a2,0xc
ffffffffc0202562:	963a                	add	a2,a2,a4
ffffffffc0202564:	00c6e563          	bltu	a3,a2,ffffffffc020256e <kfree+0xae>
            lo = mid + 1;
ffffffffc0202568:	0017861b          	addiw	a2,a5,1
ffffffffc020256c:	b751                	j	ffffffffc02024f0 <kfree+0x30>
        unsigned int cls = s->cls;
ffffffffc020256e:	01c84503          	lbu	a0,28(a6)
        if (((uintptr_t)ptr - s->base) % slub_caches[cls].objsize != 0) {
ffffffffc0202572:	00017597          	auipc	a1,0x17
ffffffffc0202576:	e3e58593          	addi	a1,a1,-450 # ffffffffc02193b0 <slub_caches>
ffffffffc020257a:	40e68733          	sub	a4,a3,a4
ffffffffc020257e:	02051793          	slli	a5,a0,0x20
ffffffffc0202582:	9381                	srli	a5,a5,0x20
ffffffffc0202584:	00479613          	slli	a2,a5,0x4
ffffffffc0202588:	8e1d                	sub	a2,a2,a5
ffffffffc020258a:	060e                	slli	a2,a2,0x3
ffffffffc020258c:	962e                	add	a2,a2,a1
ffffffffc020258e:	6210                	ld	a2,0(a2)
ffffffffc0202590:	02c77733          	remu	a4,a4,a2
ffffffffc0202594:	20071f63          	bnez	a4,ffffffffc02027b2 <kfree+0x2f2>
    if (cpu >= SLUB_NCPUS) {
ffffffffc0202598:	00006717          	auipc	a4,0x6
ffffffffc020259c:	a6872703          	lw	a4,-1432(a4) # ffffffffc0208000 <boot_hartid>
ffffffffc02025a0:	ec36                	sd	a3,24(sp)
ffffffffc02025a2:	1e071763          	bnez	a4,ffffffffc0202790 <kfree+0x2d0>
    unsigned long s = read_csr(sstatus);
ffffffffc02025a6:	100028f3          	csrr	a7,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc02025aa:	0028f893          	andi	a7,a7,2
    if (*flags) {
ffffffffc02025ae:	00088463          	beqz	a7,ffffffffc02025b6 <kfree+0xf6>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc02025b2:	10017773          	csrrci	a4,sstatus,2
    __sync_synchronize();
ffffffffc02025b6:	0330000f          	fence	rw,rw
    slub_cs[cpu][cls].user--;
ffffffffc02025ba:	00279713          	slli	a4,a5,0x2
ffffffffc02025be:	973e                	add	a4,a4,a5
ffffffffc02025c0:	070e                	slli	a4,a4,0x3
ffffffffc02025c2:	00017697          	auipc	a3,0x17
ffffffffc02025c6:	a6e68693          	addi	a3,a3,-1426 # ffffffffc0219030 <slub_cs>
ffffffffc02025ca:	96ba                	add	a3,a3,a4
ffffffffc02025cc:	7290                	ld	a2,32(a3)
    if (slub_cc[cpu][cls].main.size < slub_cc[cpu][cls].main.cap) {
ffffffffc02025ce:	00017717          	auipc	a4,0x17
ffffffffc02025d2:	ba270713          	addi	a4,a4,-1118 # ffffffffc0219170 <slub_cc>
ffffffffc02025d6:	0796                	slli	a5,a5,0x5
ffffffffc02025d8:	97ba                	add	a5,a5,a4
ffffffffc02025da:	478c                	lw	a1,8(a5)
ffffffffc02025dc:	00c7a803          	lw	a6,12(a5)
    slub_cs[cpu][cls].user--;
ffffffffc02025e0:	fff60713          	addi	a4,a2,-1
ffffffffc02025e4:	f298                	sd	a4,32(a3)
    if (slub_cc[cpu][cls].main.size < slub_cc[cpu][cls].main.cap) {
ffffffffc02025e6:	0305e863          	bltu	a1,a6,ffffffffc0202616 <kfree+0x156>
    if (slub_cc[cpu][cls].spare.size < slub_cc[cpu][cls].spare.cap) {
ffffffffc02025ea:	4f98                	lw	a4,24(a5)
ffffffffc02025ec:	4fd0                	lw	a2,28(a5)
ffffffffc02025ee:	12c76763          	bltu	a4,a2,ffffffffc020271c <kfree+0x25c>
    slub_cs[cpu][cls].free_slow++;
ffffffffc02025f2:	6e9c                	ld	a5,24(a3)
ffffffffc02025f4:	0785                	addi	a5,a5,1
ffffffffc02025f6:	ee9c                	sd	a5,24(a3)
    __sync_synchronize();
ffffffffc02025f8:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc02025fc:	00089a63          	bnez	a7,ffffffffc0202610 <kfree+0x150>
    slub_put_objects(cls, &ptr, 1, SLUB_PUT_ALL);
ffffffffc0202600:	4681                	li	a3,0
ffffffffc0202602:	4605                	li	a2,1
ffffffffc0202604:	082c                	addi	a1,sp,24
ffffffffc0202606:	fa5fe0ef          	jal	ffffffffc02015aa <slub_put_objects>
}
ffffffffc020260a:	70a2                	ld	ra,40(sp)
ffffffffc020260c:	6145                	addi	sp,sp,48
ffffffffc020260e:	8082                	ret
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0202610:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0202614:	b7f5                	j	ffffffffc0202600 <kfree+0x140>
        slub_cc[cpu][cls].main.objs[slub_cc[cpu][cls].main.size++] = ptr;
ffffffffc0202616:	6390                	ld	a2,0(a5)
        slub_cs[cpu][cls].free_fast++;
ffffffffc0202618:	6a98                	ld	a4,16(a3)
        slub_cc[cpu][cls].main.objs[slub_cc[cpu][cls].main.size++] = ptr;
ffffffffc020261a:	6562                	ld	a0,24(sp)
ffffffffc020261c:	02059313          	slli	t1,a1,0x20
ffffffffc0202620:	01d35813          	srli	a6,t1,0x1d
ffffffffc0202624:	2585                	addiw	a1,a1,1
ffffffffc0202626:	c78c                	sw	a1,8(a5)
ffffffffc0202628:	9642                	add	a2,a2,a6
        slub_cs[cpu][cls].free_fast++;
ffffffffc020262a:	00170793          	addi	a5,a4,1
        slub_cc[cpu][cls].main.objs[slub_cc[cpu][cls].main.size++] = ptr;
ffffffffc020262e:	e208                	sd	a0,0(a2)
        slub_cs[cpu][cls].free_fast++;
ffffffffc0202630:	ea9c                	sd	a5,16(a3)
    __sync_synchronize();
ffffffffc0202632:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc0202636:	fc088ae3          	beqz	a7,ffffffffc020260a <kfree+0x14a>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc020263a:	100167f3          	csrrsi	a5,sstatus,2
}
ffffffffc020263e:	70a2                	ld	ra,40(sp)
ffffffffc0202640:	6145                	addi	sp,sp,48
ffffffffc0202642:	8082                	ret
        (uintptr_t)ptr < (uintptr_t)slub_port_ram_low() + SLUB_LARGE_HDR_SIZE) {
ffffffffc0202644:	02078793          	addi	a5,a5,32
    if (!slub_ptr_in_ram(ptr) ||
ffffffffc0202648:	eef6eee3          	bltu	a3,a5,ffffffffc0202544 <kfree+0x84>
    if (h->magic != SLUB_MAGIC_LARGE) {
ffffffffc020264c:	29a637b7          	lui	a5,0x29a63
ffffffffc0202650:	aa178793          	addi	a5,a5,-1375 # 29a62aa1 <kern_entry-0xffffffff9679d55f>
ffffffffc0202654:	4c524637          	lui	a2,0x4c524
ffffffffc0202658:	fe06b583          	ld	a1,-32(a3)
ffffffffc020265c:	1786                	slli	a5,a5,0x21
ffffffffc020265e:	74760613          	addi	a2,a2,1863 # 4c524747 <kern_entry-0xffffffff73cdb8b9>
ffffffffc0202662:	97b2                	add	a5,a5,a2
ffffffffc0202664:	0ef59163          	bne	a1,a5,ffffffffc0202746 <kfree+0x286>
    if ((uintptr_t)slub_port_page_kva(h->base) + SLUB_LARGE_HDR_SIZE != a ||
ffffffffc0202668:	fe86b503          	ld	a0,-24(a3)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020266c:	00017797          	auipc	a5,0x17
ffffffffc0202670:	1447b783          	ld	a5,324(a5) # ffffffffc02197b0 <pages>
ffffffffc0202674:	ccccd637          	lui	a2,0xccccd
ffffffffc0202678:	ccd60613          	addi	a2,a2,-819 # ffffffffcccccccd <end+0xcab34d5>
ffffffffc020267c:	02061593          	slli	a1,a2,0x20
ffffffffc0202680:	40f507b3          	sub	a5,a0,a5
ffffffffc0202684:	962e                	add	a2,a2,a1
ffffffffc0202686:	878d                	srai	a5,a5,0x3
ffffffffc0202688:	02c787b3          	mul	a5,a5,a2
ffffffffc020268c:	02070713          	addi	a4,a4,32
ffffffffc0202690:	97c2                	add	a5,a5,a6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202692:	07b2                	slli	a5,a5,0xc
ffffffffc0202694:	97ba                	add	a5,a5,a4
ffffffffc0202696:	12f69a63          	bne	a3,a5,ffffffffc02027ca <kfree+0x30a>
        h->npages == 0) {
ffffffffc020269a:	ff06b583          	ld	a1,-16(a3)
    if ((uintptr_t)slub_port_page_kva(h->base) + SLUB_LARGE_HDR_SIZE != a ||
ffffffffc020269e:	12058663          	beqz	a1,ffffffffc02027ca <kfree+0x30a>
    h->magic = 0; /* 释放后置空：重复释放会被上面的魔数检查抓到 */
ffffffffc02026a2:	fe06b023          	sd	zero,-32(a3)
    unsigned long s = read_csr(sstatus);
ffffffffc02026a6:	100026f3          	csrr	a3,sstatus
    *flags = (s & SSTATUS_SIE) != 0;
ffffffffc02026aa:	8a89                	andi	a3,a3,2
    if (*flags) {
ffffffffc02026ac:	c299                	beqz	a3,ffffffffc02026b2 <kfree+0x1f2>
        clear_csr(sstatus, SSTATUS_SIE);
ffffffffc02026ae:	100177f3          	csrrci	a5,sstatus,2
    __sync_synchronize();
ffffffffc02026b2:	0330000f          	fence	rw,rw
    while (__sync_lock_test_and_set(&lock->locked, 1) != 0) {
ffffffffc02026b6:	00017717          	auipc	a4,0x17
ffffffffc02026ba:	12a70713          	addi	a4,a4,298 # ffffffffc02197e0 <slub_pmm_lock>
ffffffffc02026be:	4785                	li	a5,1
ffffffffc02026c0:	0cf727af          	amoswap.w.aq	a5,a5,(a4)
ffffffffc02026c4:	2781                	sext.w	a5,a5
ffffffffc02026c6:	ffe5                	bnez	a5,ffffffffc02026be <kfree+0x1fe>
ffffffffc02026c8:	e436                	sd	a3,8(sp)
    __sync_synchronize(); /* acquire */
ffffffffc02026ca:	0330000f          	fence	rw,rw
    slub_large_pages -= npages;
ffffffffc02026ce:	00017617          	auipc	a2,0x17
ffffffffc02026d2:	0fa63603          	ld	a2,250(a2) # ffffffffc02197c8 <slub_large_pages>
    slub_large_user--;
ffffffffc02026d6:	00017797          	auipc	a5,0x17
ffffffffc02026da:	0fa7b783          	ld	a5,250(a5) # ffffffffc02197d0 <slub_large_user>
    slub_large_pages -= npages;
ffffffffc02026de:	8e0d                	sub	a2,a2,a1
    slub_large_user--;
ffffffffc02026e0:	17fd                	addi	a5,a5,-1
    slub_large_pages -= npages;
ffffffffc02026e2:	00017817          	auipc	a6,0x17
ffffffffc02026e6:	0ec83323          	sd	a2,230(a6) # ffffffffc02197c8 <slub_large_pages>
    slub_large_user--;
ffffffffc02026ea:	00017617          	auipc	a2,0x17
ffffffffc02026ee:	0ef63323          	sd	a5,230(a2) # ffffffffc02197d0 <slub_large_user>
    free_pages(base, npages);
ffffffffc02026f2:	945fe0ef          	jal	ffffffffc0201036 <free_pages>
    __sync_synchronize(); /* release */
ffffffffc02026f6:	0330000f          	fence	rw,rw
    __sync_lock_release(&lock->locked);
ffffffffc02026fa:	00017717          	auipc	a4,0x17
ffffffffc02026fe:	0e670713          	addi	a4,a4,230 # ffffffffc02197e0 <slub_pmm_lock>
ffffffffc0202702:	0310000f          	fence	rw,w
ffffffffc0202706:	00072023          	sw	zero,0(a4)
    __sync_synchronize();
ffffffffc020270a:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc020270e:	66a2                	ld	a3,8(sp)
ffffffffc0202710:	ee068de3          	beqz	a3,ffffffffc020260a <kfree+0x14a>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0202714:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0202718:	b71d                	j	ffffffffc020263e <kfree+0x17e>
ffffffffc020271a:	8082                	ret
        slub_cc[cpu][cls].spare.objs[slub_cc[cpu][cls].spare.size++] = ptr;
ffffffffc020271c:	6b8c                	ld	a1,16(a5)
        slub_cs[cpu][cls].free_fast++;
ffffffffc020271e:	6a90                	ld	a2,16(a3)
        slub_cc[cpu][cls].spare.objs[slub_cc[cpu][cls].spare.size++] = ptr;
ffffffffc0202720:	6562                	ld	a0,24(sp)
ffffffffc0202722:	02071313          	slli	t1,a4,0x20
ffffffffc0202726:	01d35813          	srli	a6,t1,0x1d
ffffffffc020272a:	2705                	addiw	a4,a4,1
ffffffffc020272c:	cf98                	sw	a4,24(a5)
ffffffffc020272e:	95c2                	add	a1,a1,a6
        slub_cs[cpu][cls].free_fast++;
ffffffffc0202730:	00160793          	addi	a5,a2,1
        slub_cc[cpu][cls].spare.objs[slub_cc[cpu][cls].spare.size++] = ptr;
ffffffffc0202734:	e188                	sd	a0,0(a1)
        slub_cs[cpu][cls].free_fast++;
ffffffffc0202736:	ea9c                	sd	a5,16(a3)
    __sync_synchronize();
ffffffffc0202738:	0330000f          	fence	rw,rw
    if (*flags) {
ffffffffc020273c:	ec0887e3          	beqz	a7,ffffffffc020260a <kfree+0x14a>
        set_csr(sstatus, SSTATUS_SIE);
ffffffffc0202740:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0202744:	bded                	j	ffffffffc020263e <kfree+0x17e>
        slub_port_panic("slub: kfree(%lx): no slab and no valid large header "
ffffffffc0202746:	00001617          	auipc	a2,0x1
ffffffffc020274a:	59a60613          	addi	a2,a2,1434 # ffffffffc0203ce0 <etext+0xa2e>
ffffffffc020274e:	2dd00593          	li	a1,733
ffffffffc0202752:	00001517          	auipc	a0,0x1
ffffffffc0202756:	36650513          	addi	a0,a0,870 # ffffffffc0203ab8 <etext+0x806>
ffffffffc020275a:	a73fd0ef          	jal	ffffffffc02001cc <__panic>
        slub_port_panic("slub: kfree(%lx): not %d-byte aligned",
ffffffffc020275e:	4741                	li	a4,16
ffffffffc0202760:	00001617          	auipc	a2,0x1
ffffffffc0202764:	50060613          	addi	a2,a2,1280 # ffffffffc0203c60 <etext+0x9ae>
ffffffffc0202768:	2fa00593          	li	a1,762
ffffffffc020276c:	00001517          	auipc	a0,0x1
ffffffffc0202770:	34c50513          	addi	a0,a0,844 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0202774:	a59fd0ef          	jal	ffffffffc02001cc <__panic>
        slub_port_panic("slub: kfree before slub_init");
ffffffffc0202778:	00001617          	auipc	a2,0x1
ffffffffc020277c:	4c860613          	addi	a2,a2,1224 # ffffffffc0203c40 <etext+0x98e>
ffffffffc0202780:	2f700593          	li	a1,759
ffffffffc0202784:	00001517          	auipc	a0,0x1
ffffffffc0202788:	33450513          	addi	a0,a0,820 # ffffffffc0203ab8 <etext+0x806>
ffffffffc020278c:	a41fd0ef          	jal	ffffffffc02001cc <__panic>
        slub_port_panic("slub: cpu id %lu >= SLUB_NCPUS %d (build with a "
ffffffffc0202790:	00006697          	auipc	a3,0x6
ffffffffc0202794:	8706e683          	lwu	a3,-1936(a3) # ffffffffc0208000 <boot_hartid>
ffffffffc0202798:	4705                	li	a4,1
ffffffffc020279a:	00001617          	auipc	a2,0x1
ffffffffc020279e:	35660613          	addi	a2,a2,854 # ffffffffc0203af0 <etext+0x83e>
ffffffffc02027a2:	0dd00593          	li	a1,221
ffffffffc02027a6:	00001517          	auipc	a0,0x1
ffffffffc02027aa:	31250513          	addi	a0,a0,786 # ffffffffc0203ab8 <etext+0x806>
ffffffffc02027ae:	a1ffd0ef          	jal	ffffffffc02001cc <__panic>
            slub_port_panic("slub: kfree(%lx): not a slot start of its slab",
ffffffffc02027b2:	00001617          	auipc	a2,0x1
ffffffffc02027b6:	4d660613          	addi	a2,a2,1238 # ffffffffc0203c88 <etext+0x9d6>
ffffffffc02027ba:	30800593          	li	a1,776
ffffffffc02027be:	00001517          	auipc	a0,0x1
ffffffffc02027c2:	2fa50513          	addi	a0,a0,762 # ffffffffc0203ab8 <etext+0x806>
ffffffffc02027c6:	a07fd0ef          	jal	ffffffffc02001cc <__panic>
        slub_port_panic("slub: kfree(%lx): corrupt large object header",
ffffffffc02027ca:	00001617          	auipc	a2,0x1
ffffffffc02027ce:	56e60613          	addi	a2,a2,1390 # ffffffffc0203d38 <etext+0xa86>
ffffffffc02027d2:	2e300593          	li	a1,739
ffffffffc02027d6:	00001517          	auipc	a0,0x1
ffffffffc02027da:	2e250513          	addi	a0,a0,738 # ffffffffc0203ab8 <etext+0x806>
ffffffffc02027de:	9effd0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02027e2 <slub_check_ptr>:
void slub_check_ptr(void *ptr) {
    uintptr_t a = (uintptr_t)ptr;
    struct slub_slab *s;
    unsigned int cls, cpu, i, k;

    if (ptr == NULL) return;
ffffffffc02027e2:	1a050a63          	beqz	a0,ffffffffc0202996 <slub_check_ptr+0x1b4>
void slub_check_ptr(void *ptr) {
ffffffffc02027e6:	1141                	addi	sp,sp,-16
ffffffffc02027e8:	e406                	sd	ra,8(sp)
    if ((a & (SLUB_MIN_ALIGN - 1)) != 0) {
ffffffffc02027ea:	00f57793          	andi	a5,a0,15
ffffffffc02027ee:	86aa                	mv	a3,a0
ffffffffc02027f0:	22079063          	bnez	a5,ffffffffc0202a10 <slub_check_ptr+0x22e>
    return (void *)(nbase * (size_t)PGSIZE + va_pa_offset);
ffffffffc02027f4:	00002e17          	auipc	t3,0x2
ffffffffc02027f8:	c0ce3e03          	ld	t3,-1012(t3) # ffffffffc0204400 <nbase>
ffffffffc02027fc:	00017317          	auipc	t1,0x17
ffffffffc0202800:	fa433303          	ld	t1,-92(t1) # ffffffffc02197a0 <va_pa_offset>
ffffffffc0202804:	00ce1893          	slli	a7,t3,0xc
ffffffffc0202808:	989a                	add	a7,a7,t1
    return a >= (uintptr_t)slub_port_ram_low() &&
ffffffffc020280a:	0b156763          	bltu	a0,a7,ffffffffc02028b8 <slub_check_ptr+0xd6>
    return (void *)(npage * (size_t)PGSIZE + va_pa_offset);
ffffffffc020280e:	00017797          	auipc	a5,0x17
ffffffffc0202812:	f9a7b783          	ld	a5,-102(a5) # ffffffffc02197a8 <npage>
ffffffffc0202816:	07b2                	slli	a5,a5,0xc
ffffffffc0202818:	979a                	add	a5,a5,t1
ffffffffc020281a:	08f57f63          	bgeu	a0,a5,ffffffffc02028b8 <slub_check_ptr+0xd6>
    unsigned int lo = 0, hi = slub_index_nr, mid;
ffffffffc020281e:	00017597          	auipc	a1,0x17
ffffffffc0202822:	fce5a583          	lw	a1,-50(a1) # ffffffffc02197ec <slub_index_nr>
ffffffffc0202826:	4601                	li	a2,0
        s = slub_index[mid];
ffffffffc0202828:	00006817          	auipc	a6,0x6
ffffffffc020282c:	80880813          	addi	a6,a6,-2040 # ffffffffc0208030 <slub_index>
    while (lo < hi) {
ffffffffc0202830:	02b67363          	bgeu	a2,a1,ffffffffc0202856 <slub_check_ptr+0x74>
        mid = lo + (hi - lo) / 2;
ffffffffc0202834:	40c587bb          	subw	a5,a1,a2
ffffffffc0202838:	0017d79b          	srliw	a5,a5,0x1
ffffffffc020283c:	9fb1                	addw	a5,a5,a2
        s = slub_index[mid];
ffffffffc020283e:	02079513          	slli	a0,a5,0x20
ffffffffc0202842:	01d55713          	srli	a4,a0,0x1d
ffffffffc0202846:	9742                	add	a4,a4,a6
ffffffffc0202848:	6308                	ld	a0,0(a4)
        if (a < s->base) {
ffffffffc020284a:	6118                	ld	a4,0(a0)
ffffffffc020284c:	08e6f263          	bgeu	a3,a4,ffffffffc02028d0 <slub_check_ptr+0xee>
            hi = mid;
ffffffffc0202850:	85be                	mv	a1,a5
    while (lo < hi) {
ffffffffc0202852:	feb661e3          	bltu	a2,a1,ffffffffc0202834 <slub_check_ptr+0x52>
        }
        return;
    }

    /* 不属于任何 slab：应当是大对象 */
    if (a < (uintptr_t)slub_port_ram_low() + SLUB_LARGE_HDR_SIZE) {
ffffffffc0202856:	02088893          	addi	a7,a7,32
ffffffffc020285a:	1f16e463          	bltu	a3,a7,ffffffffc0202a42 <slub_check_ptr+0x260>
                        (unsigned long)a);
    }
    {
        struct slub_large_hdr *h =
            (struct slub_large_hdr *)(a - SLUB_LARGE_HDR_SIZE);
        if (h->magic != SLUB_MAGIC_LARGE) {
ffffffffc020285e:	29a637b7          	lui	a5,0x29a63
ffffffffc0202862:	aa178793          	addi	a5,a5,-1375 # 29a62aa1 <kern_entry-0xffffffff9679d55f>
ffffffffc0202866:	4c524737          	lui	a4,0x4c524
ffffffffc020286a:	fe06b603          	ld	a2,-32(a3)
ffffffffc020286e:	1786                	slli	a5,a5,0x21
ffffffffc0202870:	74770713          	addi	a4,a4,1863 # 4c524747 <kern_entry-0xffffffff73cdb8b9>
ffffffffc0202874:	97ba                	add	a5,a5,a4
ffffffffc0202876:	16f61563          	bne	a2,a5,ffffffffc02029e0 <slub_check_ptr+0x1fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020287a:	fe86b783          	ld	a5,-24(a3)
ffffffffc020287e:	00017597          	auipc	a1,0x17
ffffffffc0202882:	f325b583          	ld	a1,-206(a1) # ffffffffc02197b0 <pages>
ffffffffc0202886:	ccccd737          	lui	a4,0xccccd
ffffffffc020288a:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcab34d5>
ffffffffc020288e:	02071613          	slli	a2,a4,0x20
ffffffffc0202892:	8f8d                	sub	a5,a5,a1
ffffffffc0202894:	9732                	add	a4,a4,a2
ffffffffc0202896:	878d                	srai	a5,a5,0x3
ffffffffc0202898:	02e787b3          	mul	a5,a5,a4
            slub_port_panic("slub: pointer %lx has neither a slab nor a valid "
                            "large header (double free or foreign pointer)",
                            (unsigned long)a);
        }
        if ((uintptr_t)slub_port_page_kva(h->base) + SLUB_LARGE_HDR_SIZE != a ||
ffffffffc020289c:	02030313          	addi	t1,t1,32
ffffffffc02028a0:	97f2                	add	a5,a5,t3
    return page2ppn(page) << PGSHIFT;
ffffffffc02028a2:	07b2                	slli	a5,a5,0xc
ffffffffc02028a4:	979a                	add	a5,a5,t1
ffffffffc02028a6:	14f69963          	bne	a3,a5,ffffffffc02029f8 <slub_check_ptr+0x216>
ffffffffc02028aa:	ff06b783          	ld	a5,-16(a3)
ffffffffc02028ae:	14078563          	beqz	a5,ffffffffc02029f8 <slub_check_ptr+0x216>
            h->npages == 0) {
            slub_port_panic("slub: large object header at %lx is inconsistent",
                            (unsigned long)a);
        }
    }
}
ffffffffc02028b2:	60a2                	ld	ra,8(sp)
ffffffffc02028b4:	0141                	addi	sp,sp,16
ffffffffc02028b6:	8082                	ret
        slub_port_panic("slub: pointer %lx is outside RAM", (unsigned long)a);
ffffffffc02028b8:	00001617          	auipc	a2,0x1
ffffffffc02028bc:	4e060613          	addi	a2,a2,1248 # ffffffffc0203d98 <etext+0xae6>
ffffffffc02028c0:	3fb00593          	li	a1,1019
ffffffffc02028c4:	00001517          	auipc	a0,0x1
ffffffffc02028c8:	1f450513          	addi	a0,a0,500 # ffffffffc0203ab8 <etext+0x806>
ffffffffc02028cc:	901fd0ef          	jal	ffffffffc02001cc <__panic>
        } else if (a >= s->base + (uintptr_t)s->npages * SLUB_PAGE_SIZE) {
ffffffffc02028d0:	01056603          	lwu	a2,16(a0)
ffffffffc02028d4:	0632                	slli	a2,a2,0xc
ffffffffc02028d6:	963a                	add	a2,a2,a4
ffffffffc02028d8:	00c6e563          	bltu	a3,a2,ffffffffc02028e2 <slub_check_ptr+0x100>
            lo = mid + 1;
ffffffffc02028dc:	0017861b          	addiw	a2,a5,1
ffffffffc02028e0:	bf81                	j	ffffffffc0202830 <slub_check_ptr+0x4e>
        if ((a - s->base) % slub_caches[cls].objsize != 0) {
ffffffffc02028e2:	01c54583          	lbu	a1,28(a0)
ffffffffc02028e6:	00017617          	auipc	a2,0x17
ffffffffc02028ea:	aca60613          	addi	a2,a2,-1334 # ffffffffc02193b0 <slub_caches>
ffffffffc02028ee:	40e68733          	sub	a4,a3,a4
ffffffffc02028f2:	00459793          	slli	a5,a1,0x4
ffffffffc02028f6:	8f8d                	sub	a5,a5,a1
ffffffffc02028f8:	078e                	slli	a5,a5,0x3
ffffffffc02028fa:	97b2                	add	a5,a5,a2
ffffffffc02028fc:	639c                	ld	a5,0(a5)
ffffffffc02028fe:	02f77733          	remu	a4,a4,a5
ffffffffc0202902:	12071463          	bnez	a4,ffffffffc0202a2a <slub_check_ptr+0x248>
                for (i = 0; i < sf[k]->size; i++) {
ffffffffc0202906:	00017817          	auipc	a6,0x17
ffffffffc020290a:	86a80813          	addi	a6,a6,-1942 # ffffffffc0219170 <slub_cc>
ffffffffc020290e:	00559793          	slli	a5,a1,0x5
ffffffffc0202912:	97c2                	add	a5,a5,a6
ffffffffc0202914:	4790                	lw	a2,8(a5)
ffffffffc0202916:	ce09                	beqz	a2,ffffffffc0202930 <slub_check_ptr+0x14e>
ffffffffc0202918:	639c                	ld	a5,0(a5)
ffffffffc020291a:	02061713          	slli	a4,a2,0x20
ffffffffc020291e:	01d75613          	srli	a2,a4,0x1d
ffffffffc0202922:	963e                	add	a2,a2,a5
                    if (sf[k]->objs[i] == ptr) {
ffffffffc0202924:	6398                	ld	a4,0(a5)
ffffffffc0202926:	06e68963          	beq	a3,a4,ffffffffc0202998 <slub_check_ptr+0x1b6>
                for (i = 0; i < sf[k]->size; i++) {
ffffffffc020292a:	07a1                	addi	a5,a5,8
ffffffffc020292c:	fef61ce3          	bne	a2,a5,ffffffffc0202924 <slub_check_ptr+0x142>
ffffffffc0202930:	00559793          	slli	a5,a1,0x5
ffffffffc0202934:	983e                	add	a6,a6,a5
ffffffffc0202936:	01882603          	lw	a2,24(a6)
ffffffffc020293a:	ce11                	beqz	a2,ffffffffc0202956 <slub_check_ptr+0x174>
ffffffffc020293c:	01083783          	ld	a5,16(a6)
ffffffffc0202940:	02061713          	slli	a4,a2,0x20
ffffffffc0202944:	01d75613          	srli	a2,a4,0x1d
ffffffffc0202948:	963e                	add	a2,a2,a5
                    if (sf[k]->objs[i] == ptr) {
ffffffffc020294a:	6398                	ld	a4,0(a5)
ffffffffc020294c:	04e68663          	beq	a3,a4,ffffffffc0202998 <slub_check_ptr+0x1b6>
                for (i = 0; i < sf[k]->size; i++) {
ffffffffc0202950:	07a1                	addi	a5,a5,8
ffffffffc0202952:	fef61ce3          	bne	a2,a5,ffffffffc020294a <slub_check_ptr+0x168>
        for (i = 0; i < slub_barns[cls].size; i++) {
ffffffffc0202956:	00259793          	slli	a5,a1,0x2
ffffffffc020295a:	97ae                	add	a5,a5,a1
ffffffffc020295c:	078e                	slli	a5,a5,0x3
ffffffffc020295e:	00017717          	auipc	a4,0x17
ffffffffc0202962:	91270713          	addi	a4,a4,-1774 # ffffffffc0219270 <slub_barns>
ffffffffc0202966:	97ba                	add	a5,a5,a4
ffffffffc0202968:	4b90                	lw	a2,16(a5)
ffffffffc020296a:	ce09                	beqz	a2,ffffffffc0202984 <slub_check_ptr+0x1a2>
ffffffffc020296c:	679c                	ld	a5,8(a5)
ffffffffc020296e:	02061713          	slli	a4,a2,0x20
ffffffffc0202972:	01d75613          	srli	a2,a4,0x1d
ffffffffc0202976:	963e                	add	a2,a2,a5
            if (slub_barns[cls].objs[i] == ptr) {
ffffffffc0202978:	6398                	ld	a4,0(a5)
ffffffffc020297a:	04d70763          	beq	a4,a3,ffffffffc02029c8 <slub_check_ptr+0x1e6>
        for (i = 0; i < slub_barns[cls].size; i++) {
ffffffffc020297e:	07a1                	addi	a5,a5,8
ffffffffc0202980:	fec79ce3          	bne	a5,a2,ffffffffc0202978 <slub_check_ptr+0x196>
            for (o = s->freelist; o != NULL; o = *(void **)o) {
ffffffffc0202984:	711c                	ld	a5,32(a0)
ffffffffc0202986:	d795                	beqz	a5,ffffffffc02028b2 <slub_check_ptr+0xd0>
                if (o == ptr) {
ffffffffc0202988:	02f68463          	beq	a3,a5,ffffffffc02029b0 <slub_check_ptr+0x1ce>
            for (o = s->freelist; o != NULL; o = *(void **)o) {
ffffffffc020298c:	639c                	ld	a5,0(a5)
ffffffffc020298e:	ffed                	bnez	a5,ffffffffc0202988 <slub_check_ptr+0x1a6>
}
ffffffffc0202990:	60a2                	ld	ra,8(sp)
ffffffffc0202992:	0141                	addi	sp,sp,16
ffffffffc0202994:	8082                	ret
ffffffffc0202996:	8082                	ret
                        slub_port_panic("slub: double free of %lx (still in a "
ffffffffc0202998:	00001617          	auipc	a2,0x1
ffffffffc020299c:	45060613          	addi	a2,a2,1104 # ffffffffc0203de8 <etext+0xb36>
ffffffffc02029a0:	40d00593          	li	a1,1037
ffffffffc02029a4:	00001517          	auipc	a0,0x1
ffffffffc02029a8:	11450513          	addi	a0,a0,276 # ffffffffc0203ab8 <etext+0x806>
ffffffffc02029ac:	821fd0ef          	jal	ffffffffc02001cc <__panic>
                    slub_port_panic("slub: double free of %lx (already on the "
ffffffffc02029b0:	00001617          	auipc	a2,0x1
ffffffffc02029b4:	49860613          	addi	a2,a2,1176 # ffffffffc0203e48 <etext+0xb96>
ffffffffc02029b8:	41e00593          	li	a1,1054
ffffffffc02029bc:	00001517          	auipc	a0,0x1
ffffffffc02029c0:	0fc50513          	addi	a0,a0,252 # ffffffffc0203ab8 <etext+0x806>
ffffffffc02029c4:	809fd0ef          	jal	ffffffffc02001cc <__panic>
                slub_port_panic("slub: double free of %lx (still in the barn)",
ffffffffc02029c8:	00001617          	auipc	a2,0x1
ffffffffc02029cc:	45060613          	addi	a2,a2,1104 # ffffffffc0203e18 <etext+0xb66>
ffffffffc02029d0:	41600593          	li	a1,1046
ffffffffc02029d4:	00001517          	auipc	a0,0x1
ffffffffc02029d8:	0e450513          	addi	a0,a0,228 # ffffffffc0203ab8 <etext+0x806>
ffffffffc02029dc:	ff0fd0ef          	jal	ffffffffc02001cc <__panic>
            slub_port_panic("slub: pointer %lx has neither a slab nor a valid "
ffffffffc02029e0:	00001617          	auipc	a2,0x1
ffffffffc02029e4:	4d060613          	addi	a2,a2,1232 # ffffffffc0203eb0 <etext+0xbfe>
ffffffffc02029e8:	43000593          	li	a1,1072
ffffffffc02029ec:	00001517          	auipc	a0,0x1
ffffffffc02029f0:	0cc50513          	addi	a0,a0,204 # ffffffffc0203ab8 <etext+0x806>
ffffffffc02029f4:	fd8fd0ef          	jal	ffffffffc02001cc <__panic>
            slub_port_panic("slub: large object header at %lx is inconsistent",
ffffffffc02029f8:	00001617          	auipc	a2,0x1
ffffffffc02029fc:	51860613          	addi	a2,a2,1304 # ffffffffc0203f10 <etext+0xc5e>
ffffffffc0202a00:	43600593          	li	a1,1078
ffffffffc0202a04:	00001517          	auipc	a0,0x1
ffffffffc0202a08:	0b450513          	addi	a0,a0,180 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0202a0c:	fc0fd0ef          	jal	ffffffffc02001cc <__panic>
        slub_port_panic("slub: pointer %lx is not %d-byte aligned",
ffffffffc0202a10:	4741                	li	a4,16
ffffffffc0202a12:	00001617          	auipc	a2,0x1
ffffffffc0202a16:	35660613          	addi	a2,a2,854 # ffffffffc0203d68 <etext+0xab6>
ffffffffc0202a1a:	3f700593          	li	a1,1015
ffffffffc0202a1e:	00001517          	auipc	a0,0x1
ffffffffc0202a22:	09a50513          	addi	a0,a0,154 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0202a26:	fa6fd0ef          	jal	ffffffffc02001cc <__panic>
            slub_port_panic("slub: pointer %lx is not a slot start",
ffffffffc0202a2a:	00001617          	auipc	a2,0x1
ffffffffc0202a2e:	39660613          	addi	a2,a2,918 # ffffffffc0203dc0 <etext+0xb0e>
ffffffffc0202a32:	40200593          	li	a1,1026
ffffffffc0202a36:	00001517          	auipc	a0,0x1
ffffffffc0202a3a:	08250513          	addi	a0,a0,130 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0202a3e:	f8efd0ef          	jal	ffffffffc02001cc <__panic>
        slub_port_panic("slub: pointer %lx is too low to carry a header",
ffffffffc0202a42:	00001617          	auipc	a2,0x1
ffffffffc0202a46:	43e60613          	addi	a2,a2,1086 # ffffffffc0203e80 <etext+0xbce>
ffffffffc0202a4a:	42900593          	li	a1,1065
ffffffffc0202a4e:	00001517          	auipc	a0,0x1
ffffffffc0202a52:	06a50513          	addi	a0,a0,106 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0202a56:	f76fd0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0202a5a <slub_init>:
    kfree(p);

    slub_port_printf("slub_smoke: 8 classes + large alloc/write/free OK\n");
}

void slub_init(void) {
ffffffffc0202a5a:	715d                	addi	sp,sp,-80
ffffffffc0202a5c:	f44e                	sd	s3,40(sp)
    unsigned int cls, cpu, i;

    if (slub_inited != 0) return;
ffffffffc0202a5e:	00017997          	auipc	s3,0x17
ffffffffc0202a62:	d7a9a983          	lw	s3,-646(s3) # ffffffffc02197d8 <slub_inited>
void slub_init(void) {
ffffffffc0202a66:	e486                	sd	ra,72(sp)
    if (slub_inited != 0) return;
ffffffffc0202a68:	00098663          	beqz	s3,ffffffffc0202a74 <slub_init+0x1a>
    slub_port_printf("slub_init: %d classes, %d cpus, fixed overhead %lu "
                     "bytes, nr_free_pages %lu\n",
                     (int)SLUB_NCLASSES, (int)SLUB_NCPUS,
                     (unsigned long)slub_fixed_overhead(),
                     (unsigned long)slub_port_nr_free_pages());
}
ffffffffc0202a6c:	60a6                	ld	ra,72(sp)
ffffffffc0202a6e:	79a2                	ld	s3,40(sp)
ffffffffc0202a70:	6161                	addi	sp,sp,80
ffffffffc0202a72:	8082                	ret
ffffffffc0202a74:	e0a2                	sd	s0,64(sp)
ffffffffc0202a76:	fc26                	sd	s1,56(sp)
ffffffffc0202a78:	f84a                	sd	s2,48(sp)
ffffffffc0202a7a:	f052                	sd	s4,32(sp)
ffffffffc0202a7c:	ec56                	sd	s5,24(sp)
ffffffffc0202a7e:	e85a                	sd	s6,16(sp)
    lock->locked = 0;
ffffffffc0202a80:	00017797          	auipc	a5,0x17
ffffffffc0202a84:	d607a423          	sw	zero,-664(a5) # ffffffffc02197e8 <slub_index_lock>
    __sync_synchronize();
ffffffffc0202a88:	0330000f          	fence	rw,rw
    lock->locked = 0;
ffffffffc0202a8c:	00017797          	auipc	a5,0x17
ffffffffc0202a90:	d407aa23          	sw	zero,-684(a5) # ffffffffc02197e0 <slub_pmm_lock>
    __sync_synchronize();
ffffffffc0202a94:	0330000f          	fence	rw,rw
        slub_pool[i].state = 0;
ffffffffc0202a98:	00007797          	auipc	a5,0x7
ffffffffc0202a9c:	5a078aa3          	sb	zero,1461(a5) # ffffffffc020a04d <slub_pool+0x1d>
        slub_pool[i].next = (i + 1 < SLUB_MAX_SLABS) ? &slub_pool[i + 1] : NULL;
ffffffffc0202aa0:	00007797          	auipc	a5,0x7
ffffffffc0202aa4:	5c078793          	addi	a5,a5,1472 # ffffffffc020a060 <slub_pool+0x30>
ffffffffc0202aa8:	00013717          	auipc	a4,0x13
ffffffffc0202aac:	58870713          	addi	a4,a4,1416 # ffffffffc0216030 <slub_barn_store>
ffffffffc0202ab0:	fef7bc23          	sd	a5,-8(a5)
        slub_pool[i].state = 0;
ffffffffc0202ab4:	00078ea3          	sb	zero,29(a5)
        slub_pool[i].next = (i + 1 < SLUB_MAX_SLABS) ? &slub_pool[i + 1] : NULL;
ffffffffc0202ab8:	03078793          	addi	a5,a5,48
ffffffffc0202abc:	fee79ae3          	bne	a5,a4,ffffffffc0202ab0 <slub_init+0x56>
ffffffffc0202ac0:	00007797          	auipc	a5,0x7
ffffffffc0202ac4:	57078793          	addi	a5,a5,1392 # ffffffffc020a030 <slub_pool>
    slub_pool_free = &slub_pool[0];
ffffffffc0202ac8:	00017717          	auipc	a4,0x17
ffffffffc0202acc:	d2f73423          	sd	a5,-728(a4) # ffffffffc02197f0 <slub_pool_free>
ffffffffc0202ad0:	00001917          	auipc	s2,0x1
ffffffffc0202ad4:	76090913          	addi	s2,s2,1888 # ffffffffc0204230 <slub_sizes>
ffffffffc0202ad8:	00017e97          	auipc	t4,0x17
ffffffffc0202adc:	8d8e8e93          	addi	t4,t4,-1832 # ffffffffc02193b0 <slub_caches>
ffffffffc0202ae0:	00016e17          	auipc	t3,0x16
ffffffffc0202ae4:	790e0e13          	addi	t3,t3,1936 # ffffffffc0219270 <slub_barns>
            (unsigned int)((sheaf_cap * slub_sizes[cls] + SLUB_PAGE_SIZE - 1) /
ffffffffc0202ae8:	6505                	lui	a0,0x1
        slub_pool[i].next = (i + 1 < SLUB_MAX_SLABS) ? &slub_pool[i + 1] : NULL;
ffffffffc0202aea:	00013797          	auipc	a5,0x13
ffffffffc0202aee:	5207bf23          	sd	zero,1342(a5) # ffffffffc0216028 <slub_pool+0xbff8>
    slub_index_nr = 0;
ffffffffc0202af2:	00017797          	auipc	a5,0x17
ffffffffc0202af6:	ce07ad23          	sw	zero,-774(a5) # ffffffffc02197ec <slub_index_nr>
ffffffffc0202afa:	8fca                	mv	t6,s2
ffffffffc0202afc:	87f6                	mv	a5,t4
ffffffffc0202afe:	85f2                	mv	a1,t3
            (unsigned int)((sheaf_cap * slub_sizes[cls] + SLUB_PAGE_SIZE - 1) /
ffffffffc0202b00:	157d                	addi	a0,a0,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0202b02:	00013f17          	auipc	t5,0x13
ffffffffc0202b06:	52ef0f13          	addi	t5,t5,1326 # ffffffffc0216030 <slub_barn_store>
ffffffffc0202b0a:	00015317          	auipc	t1,0x15
ffffffffc0202b0e:	52630313          	addi	t1,t1,1318 # ffffffffc0218030 <slub_sheaf_store>
ffffffffc0202b12:	00016717          	auipc	a4,0x16
ffffffffc0202b16:	65e70713          	addi	a4,a4,1630 # ffffffffc0219170 <slub_cc>
ffffffffc0202b1a:	00016617          	auipc	a2,0x16
ffffffffc0202b1e:	51660613          	addi	a2,a2,1302 # ffffffffc0219030 <slub_cs>
    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
ffffffffc0202b22:	4481                	li	s1,0
            (slub_sizes[cls] <= 256) ? SLUB_SHEAF_MAX_CAP : 16;
ffffffffc0202b24:	10000413          	li	s0,256
        slub_port_assert(slab_pages >= 1 && slab_pages <= SLUB_MAX_SLAB_PAGES);
ffffffffc0202b28:	43bd                	li	t2,15
ffffffffc0202b2a:	a209                	j	ffffffffc0202c2c <slub_init+0x1d2>
            (slub_sizes[cls] <= 256) ? SLUB_SHEAF_MAX_CAP : 16;
ffffffffc0202b2c:	02000813          	li	a6,32
        unsigned int sheaf_cap =
ffffffffc0202b30:	82c2                	mv	t0,a6
            (slub_sizes[cls] <= 256) ? SLUB_SHEAF_MAX_CAP : 16;
ffffffffc0202b32:	08000a13          	li	s4,128
            (unsigned int)((sheaf_cap * slub_sizes[cls] + SLUB_PAGE_SIZE - 1) /
ffffffffc0202b36:	030b08b3          	mul	a7,s6,a6
ffffffffc0202b3a:	98aa                	add	a7,a7,a0
ffffffffc0202b3c:	00c8d893          	srli	a7,a7,0xc
        slub_port_assert(slab_pages >= 1 && slab_pages <= SLUB_MAX_SLAB_PAGES);
ffffffffc0202b40:	fff8869b          	addiw	a3,a7,-1
ffffffffc0202b44:	26d3e363          	bltu	t2,a3,ffffffffc0202daa <slub_init+0x350>
        slub_port_assert(slab_pages * SLUB_PAGE_SIZE / slub_sizes[cls] >=
ffffffffc0202b48:	00c8969b          	slliw	a3,a7,0xc
ffffffffc0202b4c:	1682                	slli	a3,a3,0x20
ffffffffc0202b4e:	9281                	srli	a3,a3,0x20
ffffffffc0202b50:	0366d6b3          	divu	a3,a3,s6
ffffffffc0202b54:	2d06e163          	bltu	a3,a6,ffffffffc0202e16 <slub_init+0x3bc>
    lock->locked = 0;
ffffffffc0202b58:	02049a93          	slli	s5,s1,0x20
ffffffffc0202b5c:	020ada93          	srli	s5,s5,0x20
ffffffffc0202b60:	004a9693          	slli	a3,s5,0x4
ffffffffc0202b64:	415686b3          	sub	a3,a3,s5
ffffffffc0202b68:	068e                	slli	a3,a3,0x3
        c->objsize = slub_sizes[cls];
ffffffffc0202b6a:	0167b023          	sd	s6,0(a5)
        c->sheaf_cap = sheaf_cap;
ffffffffc0202b6e:	0057a423          	sw	t0,8(a5)
        c->barn_cap = barn_cap;
ffffffffc0202b72:	0147a623          	sw	s4,12(a5)
        c->slab_pages = slab_pages;
ffffffffc0202b76:	0117a823          	sw	a7,16(a5)
ffffffffc0202b7a:	96f6                	add	a3,a3,t4
ffffffffc0202b7c:	0006aa23          	sw	zero,20(a3)
    __sync_synchronize();
ffffffffc0202b80:	0330000f          	fence	rw,rw
    lock->locked = 0;
ffffffffc0202b84:	002a9893          	slli	a7,s5,0x2
ffffffffc0202b88:	98d6                	add	a7,a7,s5
ffffffffc0202b8a:	088e                	slli	a7,a7,0x3
ffffffffc0202b8c:	98f2                	add	a7,a7,t3
        c->partial = NULL;
ffffffffc0202b8e:	0007bc23          	sd	zero,24(a5)
        c->empty = NULL;
ffffffffc0202b92:	0207b023          	sd	zero,32(a5)
        c->nr_slabs = c->nr_slab_pages = 0;
ffffffffc0202b96:	0207ac23          	sw	zero,56(a5)
        c->nr_partial = c->nr_empty = c->nr_full = 0;
ffffffffc0202b9a:	0207b423          	sd	zero,40(a5)
ffffffffc0202b9e:	0207b823          	sd	zero,48(a5)
        c->inuse_objs = 0;
ffffffffc0202ba2:	0407b023          	sd	zero,64(a5)
        c->stat_refill = c->stat_flush = 0;
ffffffffc0202ba6:	0407b823          	sd	zero,80(a5)
ffffffffc0202baa:	0407b423          	sd	zero,72(a5)
        c->stat_slab_new = c->stat_slab_free = 0;
ffffffffc0202bae:	0607b023          	sd	zero,96(a5)
ffffffffc0202bb2:	0407bc23          	sd	zero,88(a5)
        c->stat_page_fail = c->stat_desc_fail = 0;
ffffffffc0202bb6:	0607b823          	sd	zero,112(a5)
ffffffffc0202bba:	0607b423          	sd	zero,104(a5)
ffffffffc0202bbe:	0008a023          	sw	zero,0(a7)
    __sync_synchronize();
ffffffffc0202bc2:	0330000f          	fence	rw,rw
            slub_cc[cpu][cls].spare.objs = slub_sheaf_store[cpu][cls] + sheaf_cap;
ffffffffc0202bc6:	080e                	slli	a6,a6,0x3
ffffffffc0202bc8:	981a                	add	a6,a6,t1
        slub_barns[cls].objs = slub_barn_store[cls];
ffffffffc0202bca:	01e5b423          	sd	t5,8(a1)
            slub_cc[cpu][cls].main.objs = slub_sheaf_store[cpu][cls];
ffffffffc0202bce:	00673023          	sd	t1,0(a4)
            slub_cc[cpu][cls].spare.objs = slub_sheaf_store[cpu][cls] + sheaf_cap;
ffffffffc0202bd2:	01073823          	sd	a6,16(a4)
        slub_barns[cls].size = 0;
ffffffffc0202bd6:	0005a823          	sw	zero,16(a1)
        slub_barns[cls].cap = barn_cap;
ffffffffc0202bda:	0145aa23          	sw	s4,20(a1)
        slub_barns[cls].stat_get = 0;
ffffffffc0202bde:	0005bc23          	sd	zero,24(a1)
        slub_barns[cls].stat_put = 0;
ffffffffc0202be2:	0205b023          	sd	zero,32(a1)
            slub_cc[cpu][cls].main.size = 0;
ffffffffc0202be6:	00072423          	sw	zero,8(a4)
            slub_cc[cpu][cls].main.cap = sheaf_cap;
ffffffffc0202bea:	00572623          	sw	t0,12(a4)
            slub_cc[cpu][cls].spare.size = 0;
ffffffffc0202bee:	00072c23          	sw	zero,24(a4)
            slub_cc[cpu][cls].spare.cap = sheaf_cap;
ffffffffc0202bf2:	00572e23          	sw	t0,28(a4)
            slub_cs[cpu][cls].alloc_fast = 0;
ffffffffc0202bf6:	00063023          	sd	zero,0(a2)
            slub_cs[cpu][cls].alloc_slow = 0;
ffffffffc0202bfa:	00063423          	sd	zero,8(a2)
            slub_cs[cpu][cls].free_fast = 0;
ffffffffc0202bfe:	00063823          	sd	zero,16(a2)
            slub_cs[cpu][cls].free_slow = 0;
ffffffffc0202c02:	00063c23          	sd	zero,24(a2)
            slub_cs[cpu][cls].user = 0;
ffffffffc0202c06:	02063023          	sd	zero,32(a2)
    for (cls = 0; cls < SLUB_NCLASSES; cls++) {
ffffffffc0202c0a:	46a1                	li	a3,8
ffffffffc0202c0c:	2485                	addiw	s1,s1,1
ffffffffc0202c0e:	9fb6                	add	t6,t6,a3
ffffffffc0202c10:	07878793          	addi	a5,a5,120
ffffffffc0202c14:	400f0f13          	addi	t5,t5,1024
ffffffffc0202c18:	02858593          	addi	a1,a1,40
ffffffffc0202c1c:	20030313          	addi	t1,t1,512
ffffffffc0202c20:	02070713          	addi	a4,a4,32
ffffffffc0202c24:	02860613          	addi	a2,a2,40
ffffffffc0202c28:	00d48b63          	beq	s1,a3,ffffffffc0202c3e <slub_init+0x1e4>
            (slub_sizes[cls] <= 256) ? SLUB_SHEAF_MAX_CAP : 16;
ffffffffc0202c2c:	000fbb03          	ld	s6,0(t6)
ffffffffc0202c30:	ef647ee3          	bgeu	s0,s6,ffffffffc0202b2c <slub_init+0xd2>
ffffffffc0202c34:	4841                	li	a6,16
        unsigned int sheaf_cap =
ffffffffc0202c36:	82c2                	mv	t0,a6
ffffffffc0202c38:	04000a13          	li	s4,64
ffffffffc0202c3c:	bded                	j	ffffffffc0202b36 <slub_init+0xdc>
    slub_inited = 1;
ffffffffc0202c3e:	4785                	li	a5,1
    slub_large_user = 0;
ffffffffc0202c40:	00017717          	auipc	a4,0x17
ffffffffc0202c44:	b8073823          	sd	zero,-1136(a4) # ffffffffc02197d0 <slub_large_user>
    slub_large_pages = 0;
ffffffffc0202c48:	00017717          	auipc	a4,0x17
ffffffffc0202c4c:	b8073023          	sd	zero,-1152(a4) # ffffffffc02197c8 <slub_large_pages>
    slub_fault_left = 0;
ffffffffc0202c50:	00017717          	auipc	a4,0x17
ffffffffc0202c54:	b6073823          	sd	zero,-1168(a4) # ffffffffc02197c0 <slub_fault_left>
    slub_fault_hit_cnt = 0;
ffffffffc0202c58:	00017717          	auipc	a4,0x17
ffffffffc0202c5c:	b6073023          	sd	zero,-1184(a4) # ffffffffc02197b8 <slub_fault_hit_cnt>
    slub_inited = 1;
ffffffffc0202c60:	00017717          	auipc	a4,0x17
ffffffffc0202c64:	b6f72c23          	sw	a5,-1160(a4) # ffffffffc02197d8 <slub_inited>
        sz = slub_sizes[cls];
ffffffffc0202c68:	00093403          	ld	s0,0(s2)
        p = kmalloc(sz);
ffffffffc0202c6c:	8522                	mv	a0,s0
ffffffffc0202c6e:	f18ff0ef          	jal	ffffffffc0202386 <kmalloc>
ffffffffc0202c72:	8a2a                	mv	s4,a0
        if (p == NULL) {
ffffffffc0202c74:	16050763          	beqz	a0,ffffffffc0202de2 <slub_init+0x388>
        if (((uintptr_t)p & (SLUB_MIN_ALIGN - 1)) != 0) {
ffffffffc0202c78:	00f57713          	andi	a4,a0,15
ffffffffc0202c7c:	87aa                	mv	a5,a0
ffffffffc0202c7e:	16071f63          	bnez	a4,ffffffffc0202dfc <slub_init+0x3a2>
        for (i = 0; i < sz; i++) p[i] = (unsigned char)(0x40 + cls + i);
ffffffffc0202c82:	c815                	beqz	s0,ffffffffc0202cb6 <slub_init+0x25c>
ffffffffc0202c84:	0409881b          	addiw	a6,s3,64
ffffffffc0202c88:	008505b3          	add	a1,a0,s0
ffffffffc0202c8c:	40a8083b          	subw	a6,a6,a0
ffffffffc0202c90:	872a                	mv	a4,a0
ffffffffc0202c92:	0107063b          	addw	a2,a4,a6
ffffffffc0202c96:	00c70023          	sb	a2,0(a4)
ffffffffc0202c9a:	0705                	addi	a4,a4,1
ffffffffc0202c9c:	feb71be3          	bne	a4,a1,ffffffffc0202c92 <slub_init+0x238>
            if (p[i] != (unsigned char)(0x40 + cls + i)) {
ffffffffc0202ca0:	0007c603          	lbu	a2,0(a5)
ffffffffc0202ca4:	0107873b          	addw	a4,a5,a6
ffffffffc0202ca8:	0ff77713          	zext.b	a4,a4
ffffffffc0202cac:	0ae61a63          	bne	a2,a4,ffffffffc0202d60 <slub_init+0x306>
        for (i = 0; i < sz; i++) {
ffffffffc0202cb0:	0785                	addi	a5,a5,1
ffffffffc0202cb2:	feb797e3          	bne	a5,a1,ffffffffc0202ca0 <slub_init+0x246>
        slub_check_ptr(p); /* 调试检查接口：活对象应通过校验 */
ffffffffc0202cb6:	8552                	mv	a0,s4
ffffffffc0202cb8:	b2bff0ef          	jal	ffffffffc02027e2 <slub_check_ptr>
        kfree(p);
ffffffffc0202cbc:	8552                	mv	a0,s4
    for (cls = 0; cls < (int)SLUB_NCLASSES; cls++) {
ffffffffc0202cbe:	2985                	addiw	s3,s3,1
        kfree(p);
ffffffffc0202cc0:	801ff0ef          	jal	ffffffffc02024c0 <kfree>
    for (cls = 0; cls < (int)SLUB_NCLASSES; cls++) {
ffffffffc0202cc4:	0921                	addi	s2,s2,8
ffffffffc0202cc6:	fa9991e3          	bne	s3,s1,ffffffffc0202c68 <slub_init+0x20e>
    p = kmalloc(SLUB_MAX_SMALL_SIZE + 1);
ffffffffc0202cca:	6505                	lui	a0,0x1
ffffffffc0202ccc:	80150513          	addi	a0,a0,-2047 # 801 <kern_entry-0xffffffffc01ff7ff>
ffffffffc0202cd0:	eb6ff0ef          	jal	ffffffffc0202386 <kmalloc>
    if (p == NULL) {
ffffffffc0202cd4:	0e050b63          	beqz	a0,ffffffffc0202dca <slub_init+0x370>
    if (((uintptr_t)p & (SLUB_MIN_ALIGN - 1)) != 0) {
ffffffffc0202cd8:	00f57793          	andi	a5,a0,15
ffffffffc0202cdc:	872a                	mv	a4,a0
ffffffffc0202cde:	ebd5                	bnez	a5,ffffffffc0202d92 <slub_init+0x338>
ffffffffc0202ce0:	7ff50613          	addi	a2,a0,2047
ffffffffc0202ce4:	0609                	addi	a2,a2,2
ffffffffc0202ce6:	87aa                	mv	a5,a0
ffffffffc0202ce8:	4681                	li	a3,0
    for (i = 0; i < SLUB_MAX_SMALL_SIZE + 1; i++) p[i] = (unsigned char)(i * 3);
ffffffffc0202cea:	00d78023          	sb	a3,0(a5)
ffffffffc0202cee:	0785                	addi	a5,a5,1
ffffffffc0202cf0:	268d                	addiw	a3,a3,3
ffffffffc0202cf2:	fec79ce3          	bne	a5,a2,ffffffffc0202cea <slub_init+0x290>
ffffffffc0202cf6:	4781                	li	a5,0
        if (p[i] != (unsigned char)(i * 3)) {
ffffffffc0202cf8:	00074683          	lbu	a3,0(a4)
ffffffffc0202cfc:	06f69f63          	bne	a3,a5,ffffffffc0202d7a <slub_init+0x320>
    for (i = 0; i < SLUB_MAX_SMALL_SIZE + 1; i++) {
ffffffffc0202d00:	278d                	addiw	a5,a5,3
ffffffffc0202d02:	0705                	addi	a4,a4,1
ffffffffc0202d04:	0ff7f793          	zext.b	a5,a5
ffffffffc0202d08:	fec718e3          	bne	a4,a2,ffffffffc0202cf8 <slub_init+0x29e>
    slub_check_ptr(p);
ffffffffc0202d0c:	e42a                	sd	a0,8(sp)
ffffffffc0202d0e:	ad5ff0ef          	jal	ffffffffc02027e2 <slub_check_ptr>
    kfree(p);
ffffffffc0202d12:	6522                	ld	a0,8(sp)
ffffffffc0202d14:	facff0ef          	jal	ffffffffc02024c0 <kfree>
    slub_port_printf("slub_smoke: 8 classes + large alloc/write/free OK\n");
ffffffffc0202d18:	00001517          	auipc	a0,0x1
ffffffffc0202d1c:	38050513          	addi	a0,a0,896 # ffffffffc0204098 <etext+0xde6>
ffffffffc0202d20:	c2cfd0ef          	jal	ffffffffc020014c <cprintf>
    if (slub_inited == 0) return;
ffffffffc0202d24:	00017797          	auipc	a5,0x17
ffffffffc0202d28:	ab47a783          	lw	a5,-1356(a5) # ffffffffc02197d8 <slub_inited>
ffffffffc0202d2c:	c399                	beqz	a5,ffffffffc0202d32 <slub_init+0x2d8>
ffffffffc0202d2e:	c16ff0ef          	jal	ffffffffc0202144 <slub_shrink.part.0>
    return nr_free_pages();
ffffffffc0202d32:	b10fe0ef          	jal	ffffffffc0201042 <nr_free_pages>
    slub_port_printf("slub_init: %d classes, %d cpus, fixed overhead %lu "
ffffffffc0202d36:	6406                	ld	s0,64(sp)
ffffffffc0202d38:	74e2                	ld	s1,56(sp)
ffffffffc0202d3a:	7942                	ld	s2,48(sp)
ffffffffc0202d3c:	7a02                	ld	s4,32(sp)
ffffffffc0202d3e:	6ae2                	ld	s5,24(sp)
ffffffffc0202d40:	6b42                	ld	s6,16(sp)
}
ffffffffc0202d42:	60a6                	ld	ra,72(sp)
ffffffffc0202d44:	79a2                	ld	s3,40(sp)
    slub_port_printf("slub_init: %d classes, %d cpus, fixed overhead %lu "
ffffffffc0202d46:	66c5                	lui	a3,0x11
ffffffffc0202d48:	872a                	mv	a4,a0
ffffffffc0202d4a:	7b868693          	addi	a3,a3,1976 # 117b8 <kern_entry-0xffffffffc01ee848>
ffffffffc0202d4e:	4605                	li	a2,1
ffffffffc0202d50:	45a1                	li	a1,8
ffffffffc0202d52:	00001517          	auipc	a0,0x1
ffffffffc0202d56:	37e50513          	addi	a0,a0,894 # ffffffffc02040d0 <etext+0xe1e>
}
ffffffffc0202d5a:	6161                	addi	sp,sp,80
    slub_port_printf("slub_init: %d classes, %d cpus, fixed overhead %lu "
ffffffffc0202d5c:	bf0fd06f          	j	ffffffffc020014c <cprintf>
                slub_port_panic("slub_smoke: class %d data mismatch", cls);
ffffffffc0202d60:	86ce                	mv	a3,s3
ffffffffc0202d62:	00001617          	auipc	a2,0x1
ffffffffc0202d66:	29660613          	addi	a2,a2,662 # ffffffffc0203ff8 <etext+0xd46>
ffffffffc0202d6a:	45600593          	li	a1,1110
ffffffffc0202d6e:	00001517          	auipc	a0,0x1
ffffffffc0202d72:	d4a50513          	addi	a0,a0,-694 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0202d76:	c56fd0ef          	jal	ffffffffc02001cc <__panic>
            slub_port_panic("slub_smoke: large object data mismatch");
ffffffffc0202d7a:	00001617          	auipc	a2,0x1
ffffffffc0202d7e:	2f660613          	addi	a2,a2,758 # ffffffffc0204070 <etext+0xdbe>
ffffffffc0202d82:	46800593          	li	a1,1128
ffffffffc0202d86:	00001517          	auipc	a0,0x1
ffffffffc0202d8a:	d3250513          	addi	a0,a0,-718 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0202d8e:	c3efd0ef          	jal	ffffffffc02001cc <__panic>
        slub_port_panic("slub_smoke: large alignment violated");
ffffffffc0202d92:	00001617          	auipc	a2,0x1
ffffffffc0202d96:	2b660613          	addi	a2,a2,694 # ffffffffc0204048 <etext+0xd96>
ffffffffc0202d9a:	46300593          	li	a1,1123
ffffffffc0202d9e:	00001517          	auipc	a0,0x1
ffffffffc0202da2:	d1a50513          	addi	a0,a0,-742 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0202da6:	c26fd0ef          	jal	ffffffffc02001cc <__panic>
        slub_port_assert(slab_pages >= 1 && slab_pages <= SLUB_MAX_SLAB_PAGES);
ffffffffc0202daa:	00001697          	auipc	a3,0x1
ffffffffc0202dae:	19e68693          	addi	a3,a3,414 # ffffffffc0203f48 <etext+0xc96>
ffffffffc0202db2:	00000617          	auipc	a2,0x0
ffffffffc0202db6:	76e60613          	addi	a2,a2,1902 # ffffffffc0203520 <etext+0x26e>
ffffffffc0202dba:	48c00593          	li	a1,1164
ffffffffc0202dbe:	00001517          	auipc	a0,0x1
ffffffffc0202dc2:	cfa50513          	addi	a0,a0,-774 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0202dc6:	c06fd0ef          	jal	ffffffffc02001cc <__panic>
        slub_port_panic("slub_smoke: large allocation failed");
ffffffffc0202dca:	00001617          	auipc	a2,0x1
ffffffffc0202dce:	25660613          	addi	a2,a2,598 # ffffffffc0204020 <etext+0xd6e>
ffffffffc0202dd2:	46000593          	li	a1,1120
ffffffffc0202dd6:	00001517          	auipc	a0,0x1
ffffffffc0202dda:	ce250513          	addi	a0,a0,-798 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0202dde:	beefd0ef          	jal	ffffffffc02001cc <__panic>
            slub_port_panic("slub_smoke: class %d allocation failed", cls);
ffffffffc0202de2:	86ce                	mv	a3,s3
ffffffffc0202de4:	00001617          	auipc	a2,0x1
ffffffffc0202de8:	1c460613          	addi	a2,a2,452 # ffffffffc0203fa8 <etext+0xcf6>
ffffffffc0202dec:	44e00593          	li	a1,1102
ffffffffc0202df0:	00001517          	auipc	a0,0x1
ffffffffc0202df4:	cc850513          	addi	a0,a0,-824 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0202df8:	bd4fd0ef          	jal	ffffffffc02001cc <__panic>
            slub_port_panic("slub_smoke: class %d alignment violated", cls);
ffffffffc0202dfc:	86ce                	mv	a3,s3
ffffffffc0202dfe:	00001617          	auipc	a2,0x1
ffffffffc0202e02:	1d260613          	addi	a2,a2,466 # ffffffffc0203fd0 <etext+0xd1e>
ffffffffc0202e06:	45100593          	li	a1,1105
ffffffffc0202e0a:	00001517          	auipc	a0,0x1
ffffffffc0202e0e:	cae50513          	addi	a0,a0,-850 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0202e12:	bbafd0ef          	jal	ffffffffc02001cc <__panic>
        slub_port_assert(slab_pages * SLUB_PAGE_SIZE / slub_sizes[cls] >=
ffffffffc0202e16:	00001697          	auipc	a3,0x1
ffffffffc0202e1a:	15a68693          	addi	a3,a3,346 # ffffffffc0203f70 <etext+0xcbe>
ffffffffc0202e1e:	00000617          	auipc	a2,0x0
ffffffffc0202e22:	70260613          	addi	a2,a2,1794 # ffffffffc0203520 <etext+0x26e>
ffffffffc0202e26:	48e00593          	li	a1,1166
ffffffffc0202e2a:	00001517          	auipc	a0,0x1
ffffffffc0202e2e:	c8e50513          	addi	a0,a0,-882 # ffffffffc0203ab8 <etext+0x806>
ffffffffc0202e32:	b9afd0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0202e36 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202e36:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0202e38:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202e3c:	f022                	sd	s0,32(sp)
ffffffffc0202e3e:	ec26                	sd	s1,24(sp)
ffffffffc0202e40:	e84a                	sd	s2,16(sp)
ffffffffc0202e42:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0202e44:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202e48:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc0202e4a:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0202e4e:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202e52:	84aa                	mv	s1,a0
ffffffffc0202e54:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc0202e56:	03067d63          	bgeu	a2,a6,ffffffffc0202e90 <printnum+0x5a>
ffffffffc0202e5a:	e44e                	sd	s3,8(sp)
ffffffffc0202e5c:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0202e5e:	4785                	li	a5,1
ffffffffc0202e60:	00e7d763          	bge	a5,a4,ffffffffc0202e6e <printnum+0x38>
            putch(padc, putdat);
ffffffffc0202e64:	85ca                	mv	a1,s2
ffffffffc0202e66:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0202e68:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0202e6a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0202e6c:	fc65                	bnez	s0,ffffffffc0202e64 <printnum+0x2e>
ffffffffc0202e6e:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202e70:	00001797          	auipc	a5,0x1
ffffffffc0202e74:	2b078793          	addi	a5,a5,688 # ffffffffc0204120 <etext+0xe6e>
ffffffffc0202e78:	97d2                	add	a5,a5,s4
}
ffffffffc0202e7a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202e7c:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0202e80:	70a2                	ld	ra,40(sp)
ffffffffc0202e82:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202e84:	85ca                	mv	a1,s2
ffffffffc0202e86:	87a6                	mv	a5,s1
}
ffffffffc0202e88:	6942                	ld	s2,16(sp)
ffffffffc0202e8a:	64e2                	ld	s1,24(sp)
ffffffffc0202e8c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202e8e:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0202e90:	03065633          	divu	a2,a2,a6
ffffffffc0202e94:	8722                	mv	a4,s0
ffffffffc0202e96:	fa1ff0ef          	jal	ffffffffc0202e36 <printnum>
ffffffffc0202e9a:	bfd9                	j	ffffffffc0202e70 <printnum+0x3a>

ffffffffc0202e9c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0202e9c:	7119                	addi	sp,sp,-128
ffffffffc0202e9e:	f4a6                	sd	s1,104(sp)
ffffffffc0202ea0:	f0ca                	sd	s2,96(sp)
ffffffffc0202ea2:	ecce                	sd	s3,88(sp)
ffffffffc0202ea4:	e8d2                	sd	s4,80(sp)
ffffffffc0202ea6:	e4d6                	sd	s5,72(sp)
ffffffffc0202ea8:	e0da                	sd	s6,64(sp)
ffffffffc0202eaa:	f862                	sd	s8,48(sp)
ffffffffc0202eac:	fc86                	sd	ra,120(sp)
ffffffffc0202eae:	f8a2                	sd	s0,112(sp)
ffffffffc0202eb0:	fc5e                	sd	s7,56(sp)
ffffffffc0202eb2:	f466                	sd	s9,40(sp)
ffffffffc0202eb4:	f06a                	sd	s10,32(sp)
ffffffffc0202eb6:	ec6e                	sd	s11,24(sp)
ffffffffc0202eb8:	84aa                	mv	s1,a0
ffffffffc0202eba:	8c32                	mv	s8,a2
ffffffffc0202ebc:	8a36                	mv	s4,a3
ffffffffc0202ebe:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202ec0:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202ec4:	05500b13          	li	s6,85
ffffffffc0202ec8:	00001a97          	auipc	s5,0x1
ffffffffc0202ecc:	3a8a8a93          	addi	s5,s5,936 # ffffffffc0204270 <slub_sizes+0x40>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202ed0:	000c4503          	lbu	a0,0(s8)
ffffffffc0202ed4:	001c0413          	addi	s0,s8,1
ffffffffc0202ed8:	01350a63          	beq	a0,s3,ffffffffc0202eec <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0202edc:	cd0d                	beqz	a0,ffffffffc0202f16 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0202ede:	85ca                	mv	a1,s2
ffffffffc0202ee0:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202ee2:	00044503          	lbu	a0,0(s0)
ffffffffc0202ee6:	0405                	addi	s0,s0,1
ffffffffc0202ee8:	ff351ae3          	bne	a0,s3,ffffffffc0202edc <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0202eec:	5cfd                	li	s9,-1
ffffffffc0202eee:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0202ef0:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0202ef4:	4b81                	li	s7,0
ffffffffc0202ef6:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202ef8:	00044683          	lbu	a3,0(s0)
ffffffffc0202efc:	00140c13          	addi	s8,s0,1
ffffffffc0202f00:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0202f04:	0ff5f593          	zext.b	a1,a1
ffffffffc0202f08:	02bb6663          	bltu	s6,a1,ffffffffc0202f34 <vprintfmt+0x98>
ffffffffc0202f0c:	058a                	slli	a1,a1,0x2
ffffffffc0202f0e:	95d6                	add	a1,a1,s5
ffffffffc0202f10:	4198                	lw	a4,0(a1)
ffffffffc0202f12:	9756                	add	a4,a4,s5
ffffffffc0202f14:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0202f16:	70e6                	ld	ra,120(sp)
ffffffffc0202f18:	7446                	ld	s0,112(sp)
ffffffffc0202f1a:	74a6                	ld	s1,104(sp)
ffffffffc0202f1c:	7906                	ld	s2,96(sp)
ffffffffc0202f1e:	69e6                	ld	s3,88(sp)
ffffffffc0202f20:	6a46                	ld	s4,80(sp)
ffffffffc0202f22:	6aa6                	ld	s5,72(sp)
ffffffffc0202f24:	6b06                	ld	s6,64(sp)
ffffffffc0202f26:	7be2                	ld	s7,56(sp)
ffffffffc0202f28:	7c42                	ld	s8,48(sp)
ffffffffc0202f2a:	7ca2                	ld	s9,40(sp)
ffffffffc0202f2c:	7d02                	ld	s10,32(sp)
ffffffffc0202f2e:	6de2                	ld	s11,24(sp)
ffffffffc0202f30:	6109                	addi	sp,sp,128
ffffffffc0202f32:	8082                	ret
            putch('%', putdat);
ffffffffc0202f34:	85ca                	mv	a1,s2
ffffffffc0202f36:	02500513          	li	a0,37
ffffffffc0202f3a:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0202f3c:	fff44783          	lbu	a5,-1(s0)
ffffffffc0202f40:	02500713          	li	a4,37
ffffffffc0202f44:	8c22                	mv	s8,s0
ffffffffc0202f46:	f8e785e3          	beq	a5,a4,ffffffffc0202ed0 <vprintfmt+0x34>
ffffffffc0202f4a:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0202f4e:	1c7d                	addi	s8,s8,-1
ffffffffc0202f50:	fee79de3          	bne	a5,a4,ffffffffc0202f4a <vprintfmt+0xae>
ffffffffc0202f54:	bfb5                	j	ffffffffc0202ed0 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0202f56:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0202f5a:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0202f5c:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0202f60:	fd06071b          	addiw	a4,a2,-48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202f64:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc0202f66:	02e56363          	bltu	a0,a4,ffffffffc0202f8c <vprintfmt+0xf0>
                precision = precision * 10 + ch - '0';
ffffffffc0202f6a:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0202f6e:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0202f72:	0197073b          	addw	a4,a4,s9
ffffffffc0202f76:	0017171b          	slliw	a4,a4,0x1
ffffffffc0202f7a:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0202f7c:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0202f80:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0202f82:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0202f86:	8636                	mv	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0202f88:	feb571e3          	bgeu	a0,a1,ffffffffc0202f6a <vprintfmt+0xce>
            if (width < 0)
ffffffffc0202f8c:	f60d56e3          	bgez	s10,ffffffffc0202ef8 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0202f90:	8d66                	mv	s10,s9
ffffffffc0202f92:	5cfd                	li	s9,-1
ffffffffc0202f94:	b795                	j	ffffffffc0202ef8 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202f96:	8db6                	mv	s11,a3
ffffffffc0202f98:	8462                	mv	s0,s8
ffffffffc0202f9a:	bfb9                	j	ffffffffc0202ef8 <vprintfmt+0x5c>
ffffffffc0202f9c:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0202f9e:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0202fa0:	bfa1                	j	ffffffffc0202ef8 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0202fa2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202fa4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0202fa8:	00f74463          	blt	a4,a5,ffffffffc0202fb0 <vprintfmt+0x114>
    else if (lflag) {
ffffffffc0202fac:	1a078763          	beqz	a5,ffffffffc020315a <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc0202fb0:	000a3603          	ld	a2,0(s4)
ffffffffc0202fb4:	46c1                	li	a3,16
ffffffffc0202fb6:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0202fb8:	000d879b          	sext.w	a5,s11
ffffffffc0202fbc:	876a                	mv	a4,s10
ffffffffc0202fbe:	85ca                	mv	a1,s2
ffffffffc0202fc0:	8526                	mv	a0,s1
ffffffffc0202fc2:	e75ff0ef          	jal	ffffffffc0202e36 <printnum>
            break;
ffffffffc0202fc6:	b729                	j	ffffffffc0202ed0 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0202fc8:	000a2503          	lw	a0,0(s4)
ffffffffc0202fcc:	85ca                	mv	a1,s2
ffffffffc0202fce:	0a21                	addi	s4,s4,8
ffffffffc0202fd0:	9482                	jalr	s1
            break;
ffffffffc0202fd2:	bdfd                	j	ffffffffc0202ed0 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0202fd4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202fd6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0202fda:	00f74463          	blt	a4,a5,ffffffffc0202fe2 <vprintfmt+0x146>
    else if (lflag) {
ffffffffc0202fde:	16078963          	beqz	a5,ffffffffc0203150 <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc0202fe2:	000a3603          	ld	a2,0(s4)
ffffffffc0202fe6:	46a9                	li	a3,10
ffffffffc0202fe8:	8a2e                	mv	s4,a1
ffffffffc0202fea:	b7f9                	j	ffffffffc0202fb8 <vprintfmt+0x11c>
            putch('0', putdat);
ffffffffc0202fec:	85ca                	mv	a1,s2
ffffffffc0202fee:	03000513          	li	a0,48
ffffffffc0202ff2:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0202ff4:	85ca                	mv	a1,s2
ffffffffc0202ff6:	07800513          	li	a0,120
ffffffffc0202ffa:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0202ffc:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0203000:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203002:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203004:	bf55                	j	ffffffffc0202fb8 <vprintfmt+0x11c>
            putch(ch, putdat);
ffffffffc0203006:	85ca                	mv	a1,s2
ffffffffc0203008:	02500513          	li	a0,37
ffffffffc020300c:	9482                	jalr	s1
            break;
ffffffffc020300e:	b5c9                	j	ffffffffc0202ed0 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0203010:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203014:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0203016:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0203018:	bf95                	j	ffffffffc0202f8c <vprintfmt+0xf0>
    if (lflag >= 2) {
ffffffffc020301a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020301c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203020:	00f74463          	blt	a4,a5,ffffffffc0203028 <vprintfmt+0x18c>
    else if (lflag) {
ffffffffc0203024:	12078163          	beqz	a5,ffffffffc0203146 <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc0203028:	000a3603          	ld	a2,0(s4)
ffffffffc020302c:	46a1                	li	a3,8
ffffffffc020302e:	8a2e                	mv	s4,a1
ffffffffc0203030:	b761                	j	ffffffffc0202fb8 <vprintfmt+0x11c>
            if (width < 0)
ffffffffc0203032:	876a                	mv	a4,s10
ffffffffc0203034:	000d5363          	bgez	s10,ffffffffc020303a <vprintfmt+0x19e>
ffffffffc0203038:	4701                	li	a4,0
ffffffffc020303a:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020303e:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0203040:	bd65                	j	ffffffffc0202ef8 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0203042:	000d841b          	sext.w	s0,s11
ffffffffc0203046:	fd340793          	addi	a5,s0,-45
ffffffffc020304a:	00f037b3          	snez	a5,a5
ffffffffc020304e:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203052:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0203056:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203058:	008a0793          	addi	a5,s4,8
ffffffffc020305c:	e43e                	sd	a5,8(sp)
ffffffffc020305e:	100d8c63          	beqz	s11,ffffffffc0203176 <vprintfmt+0x2da>
            if (width > 0 && padc != '-') {
ffffffffc0203062:	12071363          	bnez	a4,ffffffffc0203188 <vprintfmt+0x2ec>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203066:	000dc783          	lbu	a5,0(s11)
ffffffffc020306a:	0007851b          	sext.w	a0,a5
ffffffffc020306e:	c78d                	beqz	a5,ffffffffc0203098 <vprintfmt+0x1fc>
ffffffffc0203070:	0d85                	addi	s11,s11,1
ffffffffc0203072:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203074:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203078:	000cc563          	bltz	s9,ffffffffc0203082 <vprintfmt+0x1e6>
ffffffffc020307c:	3cfd                	addiw	s9,s9,-1
ffffffffc020307e:	008c8d63          	beq	s9,s0,ffffffffc0203098 <vprintfmt+0x1fc>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203082:	020b9663          	bnez	s7,ffffffffc02030ae <vprintfmt+0x212>
                    putch(ch, putdat);
ffffffffc0203086:	85ca                	mv	a1,s2
ffffffffc0203088:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020308a:	000dc783          	lbu	a5,0(s11)
ffffffffc020308e:	0d85                	addi	s11,s11,1
ffffffffc0203090:	3d7d                	addiw	s10,s10,-1
ffffffffc0203092:	0007851b          	sext.w	a0,a5
ffffffffc0203096:	f3ed                	bnez	a5,ffffffffc0203078 <vprintfmt+0x1dc>
            for (; width > 0; width --) {
ffffffffc0203098:	01a05963          	blez	s10,ffffffffc02030aa <vprintfmt+0x20e>
                putch(' ', putdat);
ffffffffc020309c:	85ca                	mv	a1,s2
ffffffffc020309e:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc02030a2:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc02030a4:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc02030a6:	fe0d1be3          	bnez	s10,ffffffffc020309c <vprintfmt+0x200>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02030aa:	6a22                	ld	s4,8(sp)
ffffffffc02030ac:	b515                	j	ffffffffc0202ed0 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02030ae:	3781                	addiw	a5,a5,-32
ffffffffc02030b0:	fcfa7be3          	bgeu	s4,a5,ffffffffc0203086 <vprintfmt+0x1ea>
                    putch('?', putdat);
ffffffffc02030b4:	03f00513          	li	a0,63
ffffffffc02030b8:	85ca                	mv	a1,s2
ffffffffc02030ba:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02030bc:	000dc783          	lbu	a5,0(s11)
ffffffffc02030c0:	0d85                	addi	s11,s11,1
ffffffffc02030c2:	3d7d                	addiw	s10,s10,-1
ffffffffc02030c4:	0007851b          	sext.w	a0,a5
ffffffffc02030c8:	dbe1                	beqz	a5,ffffffffc0203098 <vprintfmt+0x1fc>
ffffffffc02030ca:	fa0cd9e3          	bgez	s9,ffffffffc020307c <vprintfmt+0x1e0>
ffffffffc02030ce:	b7c5                	j	ffffffffc02030ae <vprintfmt+0x212>
            if (err < 0) {
ffffffffc02030d0:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02030d4:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc02030d6:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02030d8:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc02030dc:	8fb9                	xor	a5,a5,a4
ffffffffc02030de:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02030e2:	02d64563          	blt	a2,a3,ffffffffc020310c <vprintfmt+0x270>
ffffffffc02030e6:	00001797          	auipc	a5,0x1
ffffffffc02030ea:	2e278793          	addi	a5,a5,738 # ffffffffc02043c8 <error_string>
ffffffffc02030ee:	00369713          	slli	a4,a3,0x3
ffffffffc02030f2:	97ba                	add	a5,a5,a4
ffffffffc02030f4:	639c                	ld	a5,0(a5)
ffffffffc02030f6:	cb99                	beqz	a5,ffffffffc020310c <vprintfmt+0x270>
                printfmt(putch, putdat, "%s", p);
ffffffffc02030f8:	86be                	mv	a3,a5
ffffffffc02030fa:	00001617          	auipc	a2,0x1
ffffffffc02030fe:	05660613          	addi	a2,a2,86 # ffffffffc0204150 <etext+0xe9e>
ffffffffc0203102:	85ca                	mv	a1,s2
ffffffffc0203104:	8526                	mv	a0,s1
ffffffffc0203106:	0d4000ef          	jal	ffffffffc02031da <printfmt>
ffffffffc020310a:	b3d9                	j	ffffffffc0202ed0 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020310c:	00001617          	auipc	a2,0x1
ffffffffc0203110:	03460613          	addi	a2,a2,52 # ffffffffc0204140 <etext+0xe8e>
ffffffffc0203114:	85ca                	mv	a1,s2
ffffffffc0203116:	8526                	mv	a0,s1
ffffffffc0203118:	0c2000ef          	jal	ffffffffc02031da <printfmt>
ffffffffc020311c:	bb55                	j	ffffffffc0202ed0 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc020311e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203120:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0203124:	00f74363          	blt	a4,a5,ffffffffc020312a <vprintfmt+0x28e>
    else if (lflag) {
ffffffffc0203128:	cf81                	beqz	a5,ffffffffc0203140 <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc020312a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020312e:	02044b63          	bltz	s0,ffffffffc0203164 <vprintfmt+0x2c8>
            num = getint(&ap, lflag);
ffffffffc0203132:	8622                	mv	a2,s0
ffffffffc0203134:	8a5e                	mv	s4,s7
ffffffffc0203136:	46a9                	li	a3,10
ffffffffc0203138:	b541                	j	ffffffffc0202fb8 <vprintfmt+0x11c>
            lflag ++;
ffffffffc020313a:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020313c:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020313e:	bb6d                	j	ffffffffc0202ef8 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0203140:	000a2403          	lw	s0,0(s4)
ffffffffc0203144:	b7ed                	j	ffffffffc020312e <vprintfmt+0x292>
        return va_arg(*ap, unsigned int);
ffffffffc0203146:	000a6603          	lwu	a2,0(s4)
ffffffffc020314a:	46a1                	li	a3,8
ffffffffc020314c:	8a2e                	mv	s4,a1
ffffffffc020314e:	b5ad                	j	ffffffffc0202fb8 <vprintfmt+0x11c>
ffffffffc0203150:	000a6603          	lwu	a2,0(s4)
ffffffffc0203154:	46a9                	li	a3,10
ffffffffc0203156:	8a2e                	mv	s4,a1
ffffffffc0203158:	b585                	j	ffffffffc0202fb8 <vprintfmt+0x11c>
ffffffffc020315a:	000a6603          	lwu	a2,0(s4)
ffffffffc020315e:	46c1                	li	a3,16
ffffffffc0203160:	8a2e                	mv	s4,a1
ffffffffc0203162:	bd99                	j	ffffffffc0202fb8 <vprintfmt+0x11c>
                putch('-', putdat);
ffffffffc0203164:	85ca                	mv	a1,s2
ffffffffc0203166:	02d00513          	li	a0,45
ffffffffc020316a:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc020316c:	40800633          	neg	a2,s0
ffffffffc0203170:	8a5e                	mv	s4,s7
ffffffffc0203172:	46a9                	li	a3,10
ffffffffc0203174:	b591                	j	ffffffffc0202fb8 <vprintfmt+0x11c>
            if (width > 0 && padc != '-') {
ffffffffc0203176:	ef1d                	bnez	a4,ffffffffc02031b4 <vprintfmt+0x318>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203178:	02800793          	li	a5,40
ffffffffc020317c:	853e                	mv	a0,a5
ffffffffc020317e:	00001d97          	auipc	s11,0x1
ffffffffc0203182:	fbbd8d93          	addi	s11,s11,-69 # ffffffffc0204139 <etext+0xe87>
ffffffffc0203186:	b5f5                	j	ffffffffc0203072 <vprintfmt+0x1d6>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203188:	85e6                	mv	a1,s9
ffffffffc020318a:	856e                	mv	a0,s11
ffffffffc020318c:	0a0000ef          	jal	ffffffffc020322c <strnlen>
ffffffffc0203190:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0203194:	01a05863          	blez	s10,ffffffffc02031a4 <vprintfmt+0x308>
                    putch(padc, putdat);
ffffffffc0203198:	85ca                	mv	a1,s2
ffffffffc020319a:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020319c:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc020319e:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02031a0:	fe0d1ce3          	bnez	s10,ffffffffc0203198 <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02031a4:	000dc783          	lbu	a5,0(s11)
ffffffffc02031a8:	0007851b          	sext.w	a0,a5
ffffffffc02031ac:	ec0792e3          	bnez	a5,ffffffffc0203070 <vprintfmt+0x1d4>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02031b0:	6a22                	ld	s4,8(sp)
ffffffffc02031b2:	bb39                	j	ffffffffc0202ed0 <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02031b4:	85e6                	mv	a1,s9
ffffffffc02031b6:	00001517          	auipc	a0,0x1
ffffffffc02031ba:	f8250513          	addi	a0,a0,-126 # ffffffffc0204138 <etext+0xe86>
ffffffffc02031be:	06e000ef          	jal	ffffffffc020322c <strnlen>
ffffffffc02031c2:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02031c6:	02800793          	li	a5,40
                p = "(null)";
ffffffffc02031ca:	00001d97          	auipc	s11,0x1
ffffffffc02031ce:	f6ed8d93          	addi	s11,s11,-146 # ffffffffc0204138 <etext+0xe86>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02031d2:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02031d4:	fda042e3          	bgtz	s10,ffffffffc0203198 <vprintfmt+0x2fc>
ffffffffc02031d8:	bd61                	j	ffffffffc0203070 <vprintfmt+0x1d4>

ffffffffc02031da <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02031da:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02031dc:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02031e0:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02031e2:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02031e4:	ec06                	sd	ra,24(sp)
ffffffffc02031e6:	f83a                	sd	a4,48(sp)
ffffffffc02031e8:	fc3e                	sd	a5,56(sp)
ffffffffc02031ea:	e0c2                	sd	a6,64(sp)
ffffffffc02031ec:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02031ee:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02031f0:	cadff0ef          	jal	ffffffffc0202e9c <vprintfmt>
}
ffffffffc02031f4:	60e2                	ld	ra,24(sp)
ffffffffc02031f6:	6161                	addi	sp,sp,80
ffffffffc02031f8:	8082                	ret

ffffffffc02031fa <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02031fa:	00005717          	auipc	a4,0x5
ffffffffc02031fe:	e1673703          	ld	a4,-490(a4) # ffffffffc0208010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0203202:	4781                	li	a5,0
ffffffffc0203204:	88ba                	mv	a7,a4
ffffffffc0203206:	852a                	mv	a0,a0
ffffffffc0203208:	85be                	mv	a1,a5
ffffffffc020320a:	863e                	mv	a2,a5
ffffffffc020320c:	00000073          	ecall
ffffffffc0203210:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0203212:	8082                	ret

ffffffffc0203214 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203214:	00054783          	lbu	a5,0(a0)
ffffffffc0203218:	cb81                	beqz	a5,ffffffffc0203228 <strlen+0x14>
    size_t cnt = 0;
ffffffffc020321a:	4781                	li	a5,0
        cnt ++;
ffffffffc020321c:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc020321e:	00f50733          	add	a4,a0,a5
ffffffffc0203222:	00074703          	lbu	a4,0(a4)
ffffffffc0203226:	fb7d                	bnez	a4,ffffffffc020321c <strlen+0x8>
    }
    return cnt;
}
ffffffffc0203228:	853e                	mv	a0,a5
ffffffffc020322a:	8082                	ret

ffffffffc020322c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020322c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020322e:	e589                	bnez	a1,ffffffffc0203238 <strnlen+0xc>
ffffffffc0203230:	a811                	j	ffffffffc0203244 <strnlen+0x18>
        cnt ++;
ffffffffc0203232:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203234:	00f58863          	beq	a1,a5,ffffffffc0203244 <strnlen+0x18>
ffffffffc0203238:	00f50733          	add	a4,a0,a5
ffffffffc020323c:	00074703          	lbu	a4,0(a4)
ffffffffc0203240:	fb6d                	bnez	a4,ffffffffc0203232 <strnlen+0x6>
ffffffffc0203242:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203244:	852e                	mv	a0,a1
ffffffffc0203246:	8082                	ret

ffffffffc0203248 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203248:	00054783          	lbu	a5,0(a0)
ffffffffc020324c:	e791                	bnez	a5,ffffffffc0203258 <strcmp+0x10>
ffffffffc020324e:	a015                	j	ffffffffc0203272 <strcmp+0x2a>
ffffffffc0203250:	00054783          	lbu	a5,0(a0)
ffffffffc0203254:	cb91                	beqz	a5,ffffffffc0203268 <strcmp+0x20>
ffffffffc0203256:	0585                	addi	a1,a1,1
ffffffffc0203258:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc020325c:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020325e:	fef709e3          	beq	a4,a5,ffffffffc0203250 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203262:	40e7853b          	subw	a0,a5,a4
ffffffffc0203266:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203268:	0015c703          	lbu	a4,1(a1)
}
ffffffffc020326c:	40e7853b          	subw	a0,a5,a4
ffffffffc0203270:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203272:	0005c703          	lbu	a4,0(a1)
ffffffffc0203276:	b7f5                	j	ffffffffc0203262 <strcmp+0x1a>

ffffffffc0203278 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203278:	ce01                	beqz	a2,ffffffffc0203290 <strncmp+0x18>
ffffffffc020327a:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc020327e:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203280:	cb91                	beqz	a5,ffffffffc0203294 <strncmp+0x1c>
ffffffffc0203282:	0005c703          	lbu	a4,0(a1)
ffffffffc0203286:	00f71763          	bne	a4,a5,ffffffffc0203294 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc020328a:	0505                	addi	a0,a0,1
ffffffffc020328c:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020328e:	f675                	bnez	a2,ffffffffc020327a <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203290:	4501                	li	a0,0
ffffffffc0203292:	8082                	ret
ffffffffc0203294:	00054503          	lbu	a0,0(a0)
ffffffffc0203298:	0005c783          	lbu	a5,0(a1)
ffffffffc020329c:	9d1d                	subw	a0,a0,a5
}
ffffffffc020329e:	8082                	ret

ffffffffc02032a0 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02032a0:	ca01                	beqz	a2,ffffffffc02032b0 <memset+0x10>
ffffffffc02032a2:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02032a4:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02032a6:	0785                	addi	a5,a5,1
ffffffffc02032a8:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02032ac:	fef61de3          	bne	a2,a5,ffffffffc02032a6 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02032b0:	8082                	ret
