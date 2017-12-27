
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 69 11 f0       	mov    $0xf0116970,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 63 11 f0       	push   $0xf0116300
f0100058:	e8 e2 31 00 00       	call   f010323f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 88 04 00 00       	call   f01004ea <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 e0 36 10 f0       	push   $0xf01036e0
f010006f:	e8 80 26 00 00       	call   f01026f4 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 82 0f 00 00       	call   f0100ffb <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 11 07 00 00       	call   f0100797 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 69 11 f0 00 	cmpl   $0x0,0xf0116960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 69 11 f0    	mov    %esi,0xf0116960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 fb 36 10 f0       	push   $0xf01036fb
f01000b5:	e8 3a 26 00 00       	call   f01026f4 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 0a 26 00 00       	call   f01026ce <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 a9 3e 10 f0 	movl   $0xf0103ea9,(%esp)
f01000cb:	e8 24 26 00 00       	call   f01026f4 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 ba 06 00 00       	call   f0100797 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 13 37 10 f0       	push   $0xf0103713
f01000f7:	e8 f8 25 00 00       	call   f01026f4 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 c6 25 00 00       	call   f01026ce <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 a9 3e 10 f0 	movl   $0xf0103ea9,(%esp)
f010010f:	e8 e0 25 00 00       	call   f01026f4 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f0100159:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f0 00 00 00    	je     f010027c <kbd_proc_data+0xfe>
f010018c:	ba 60 00 00 00       	mov    $0x60,%edx
f0100191:	ec                   	in     (%dx),%al
f0100192:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100194:	3c e0                	cmp    $0xe0,%al
f0100196:	75 0d                	jne    f01001a5 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f0100198:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
		return 0;
f010019f:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001a4:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001a5:	55                   	push   %ebp
f01001a6:	89 e5                	mov    %esp,%ebp
f01001a8:	53                   	push   %ebx
f01001a9:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001ac:	84 c0                	test   %al,%al
f01001ae:	79 36                	jns    f01001e6 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b0:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001b6:	89 cb                	mov    %ecx,%ebx
f01001b8:	83 e3 40             	and    $0x40,%ebx
f01001bb:	83 e0 7f             	and    $0x7f,%eax
f01001be:	85 db                	test   %ebx,%ebx
f01001c0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001c3:	0f b6 d2             	movzbl %dl,%edx
f01001c6:	0f b6 82 80 38 10 f0 	movzbl -0xfefc780(%edx),%eax
f01001cd:	83 c8 40             	or     $0x40,%eax
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	f7 d0                	not    %eax
f01001d5:	21 c8                	and    %ecx,%eax
f01001d7:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f01001dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e1:	e9 9e 00 00 00       	jmp    f0100284 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e6:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001ec:	f6 c1 40             	test   $0x40,%cl
f01001ef:	74 0e                	je     f01001ff <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f1:	83 c8 80             	or     $0xffffff80,%eax
f01001f4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f9:	89 0d 00 63 11 f0    	mov    %ecx,0xf0116300
	}

	shift |= shiftcode[data];
f01001ff:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100202:	0f b6 82 80 38 10 f0 	movzbl -0xfefc780(%edx),%eax
f0100209:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f010020f:	0f b6 8a 80 37 10 f0 	movzbl -0xfefc880(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d 60 37 10 f0 	mov    -0xfefc8a0(,%ecx,4),%ecx
f0100229:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010022d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100230:	a8 08                	test   $0x8,%al
f0100232:	74 1b                	je     f010024f <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100234:	89 da                	mov    %ebx,%edx
f0100236:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100239:	83 f9 19             	cmp    $0x19,%ecx
f010023c:	77 05                	ja     f0100243 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f010023e:	83 eb 20             	sub    $0x20,%ebx
f0100241:	eb 0c                	jmp    f010024f <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100243:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100246:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100249:	83 fa 19             	cmp    $0x19,%edx
f010024c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010024f:	f7 d0                	not    %eax
f0100251:	a8 06                	test   $0x6,%al
f0100253:	75 2d                	jne    f0100282 <kbd_proc_data+0x104>
f0100255:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010025b:	75 25                	jne    f0100282 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f010025d:	83 ec 0c             	sub    $0xc,%esp
f0100260:	68 2d 37 10 f0       	push   $0xf010372d
f0100265:	e8 8a 24 00 00       	call   f01026f4 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010026a:	ba 92 00 00 00       	mov    $0x92,%edx
f010026f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100274:	ee                   	out    %al,(%dx)
f0100275:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100278:	89 d8                	mov    %ebx,%eax
f010027a:	eb 08                	jmp    f0100284 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010027c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100281:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100282:	89 d8                	mov    %ebx,%eax
}
f0100284:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100287:	c9                   	leave  
f0100288:	c3                   	ret    

f0100289 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100289:	55                   	push   %ebp
f010028a:	89 e5                	mov    %esp,%ebp
f010028c:	57                   	push   %edi
f010028d:	56                   	push   %esi
f010028e:	53                   	push   %ebx
f010028f:	83 ec 1c             	sub    $0x1c,%esp
f0100292:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100294:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100299:	be fd 03 00 00       	mov    $0x3fd,%esi
f010029e:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002a3:	eb 09                	jmp    f01002ae <cons_putc+0x25>
f01002a5:	89 ca                	mov    %ecx,%edx
f01002a7:	ec                   	in     (%dx),%al
f01002a8:	ec                   	in     (%dx),%al
f01002a9:	ec                   	in     (%dx),%al
f01002aa:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ab:	83 c3 01             	add    $0x1,%ebx
f01002ae:	89 f2                	mov    %esi,%edx
f01002b0:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002b1:	a8 20                	test   $0x20,%al
f01002b3:	75 08                	jne    f01002bd <cons_putc+0x34>
f01002b5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002bb:	7e e8                	jle    f01002a5 <cons_putc+0x1c>
f01002bd:	89 f8                	mov    %edi,%eax
f01002bf:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c2:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002c7:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002c8:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002cd:	be 79 03 00 00       	mov    $0x379,%esi
f01002d2:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d7:	eb 09                	jmp    f01002e2 <cons_putc+0x59>
f01002d9:	89 ca                	mov    %ecx,%edx
f01002db:	ec                   	in     (%dx),%al
f01002dc:	ec                   	in     (%dx),%al
f01002dd:	ec                   	in     (%dx),%al
f01002de:	ec                   	in     (%dx),%al
f01002df:	83 c3 01             	add    $0x1,%ebx
f01002e2:	89 f2                	mov    %esi,%edx
f01002e4:	ec                   	in     (%dx),%al
f01002e5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002eb:	7f 04                	jg     f01002f1 <cons_putc+0x68>
f01002ed:	84 c0                	test   %al,%al
f01002ef:	79 e8                	jns    f01002d9 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002f1:	ba 78 03 00 00       	mov    $0x378,%edx
f01002f6:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f01002fa:	ee                   	out    %al,(%dx)
f01002fb:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100300:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100305:	ee                   	out    %al,(%dx)
f0100306:	b8 08 00 00 00       	mov    $0x8,%eax
f010030b:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010030c:	89 fa                	mov    %edi,%edx
f010030e:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100314:	89 f8                	mov    %edi,%eax
f0100316:	80 cc 07             	or     $0x7,%ah
f0100319:	85 d2                	test   %edx,%edx
f010031b:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010031e:	89 f8                	mov    %edi,%eax
f0100320:	0f b6 c0             	movzbl %al,%eax
f0100323:	83 f8 09             	cmp    $0x9,%eax
f0100326:	74 74                	je     f010039c <cons_putc+0x113>
f0100328:	83 f8 09             	cmp    $0x9,%eax
f010032b:	7f 0a                	jg     f0100337 <cons_putc+0xae>
f010032d:	83 f8 08             	cmp    $0x8,%eax
f0100330:	74 14                	je     f0100346 <cons_putc+0xbd>
f0100332:	e9 99 00 00 00       	jmp    f01003d0 <cons_putc+0x147>
f0100337:	83 f8 0a             	cmp    $0xa,%eax
f010033a:	74 3a                	je     f0100376 <cons_putc+0xed>
f010033c:	83 f8 0d             	cmp    $0xd,%eax
f010033f:	74 3d                	je     f010037e <cons_putc+0xf5>
f0100341:	e9 8a 00 00 00       	jmp    f01003d0 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100346:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f010034d:	66 85 c0             	test   %ax,%ax
f0100350:	0f 84 e6 00 00 00    	je     f010043c <cons_putc+0x1b3>
			crt_pos--;
f0100356:	83 e8 01             	sub    $0x1,%eax
f0100359:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010035f:	0f b7 c0             	movzwl %ax,%eax
f0100362:	66 81 e7 00 ff       	and    $0xff00,%di
f0100367:	83 cf 20             	or     $0x20,%edi
f010036a:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100370:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100374:	eb 78                	jmp    f01003ee <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100376:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f010037d:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010037e:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f0100385:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010038b:	c1 e8 16             	shr    $0x16,%eax
f010038e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100391:	c1 e0 04             	shl    $0x4,%eax
f0100394:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
f010039a:	eb 52                	jmp    f01003ee <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f010039c:	b8 20 00 00 00       	mov    $0x20,%eax
f01003a1:	e8 e3 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003a6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ab:	e8 d9 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003b0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b5:	e8 cf fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003ba:	b8 20 00 00 00       	mov    $0x20,%eax
f01003bf:	e8 c5 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003c4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c9:	e8 bb fe ff ff       	call   f0100289 <cons_putc>
f01003ce:	eb 1e                	jmp    f01003ee <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003d0:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f01003d7:	8d 50 01             	lea    0x1(%eax),%edx
f01003da:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
f01003e1:	0f b7 c0             	movzwl %ax,%eax
f01003e4:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f01003ea:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003ee:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f01003f5:	cf 07 
f01003f7:	76 43                	jbe    f010043c <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01003f9:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f01003fe:	83 ec 04             	sub    $0x4,%esp
f0100401:	68 00 0f 00 00       	push   $0xf00
f0100406:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010040c:	52                   	push   %edx
f010040d:	50                   	push   %eax
f010040e:	e8 79 2e 00 00       	call   f010328c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100413:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100419:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010041f:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100425:	83 c4 10             	add    $0x10,%esp
f0100428:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010042d:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100430:	39 d0                	cmp    %edx,%eax
f0100432:	75 f4                	jne    f0100428 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100434:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f010043b:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010043c:	8b 0d 30 65 11 f0    	mov    0xf0116530,%ecx
f0100442:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100447:	89 ca                	mov    %ecx,%edx
f0100449:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010044a:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
f0100451:	8d 71 01             	lea    0x1(%ecx),%esi
f0100454:	89 d8                	mov    %ebx,%eax
f0100456:	66 c1 e8 08          	shr    $0x8,%ax
f010045a:	89 f2                	mov    %esi,%edx
f010045c:	ee                   	out    %al,(%dx)
f010045d:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100462:	89 ca                	mov    %ecx,%edx
f0100464:	ee                   	out    %al,(%dx)
f0100465:	89 d8                	mov    %ebx,%eax
f0100467:	89 f2                	mov    %esi,%edx
f0100469:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);//输出到打印机
	cga_putc(c);//输出到显示器
}
f010046a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010046d:	5b                   	pop    %ebx
f010046e:	5e                   	pop    %esi
f010046f:	5f                   	pop    %edi
f0100470:	5d                   	pop    %ebp
f0100471:	c3                   	ret    

f0100472 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100472:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f0100479:	74 11                	je     f010048c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010047b:	55                   	push   %ebp
f010047c:	89 e5                	mov    %esp,%ebp
f010047e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100481:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100486:	e8 b0 fc ff ff       	call   f010013b <cons_intr>
}
f010048b:	c9                   	leave  
f010048c:	f3 c3                	repz ret 

f010048e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010048e:	55                   	push   %ebp
f010048f:	89 e5                	mov    %esp,%ebp
f0100491:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100494:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f0100499:	e8 9d fc ff ff       	call   f010013b <cons_intr>
}
f010049e:	c9                   	leave  
f010049f:	c3                   	ret    

f01004a0 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004a0:	55                   	push   %ebp
f01004a1:	89 e5                	mov    %esp,%ebp
f01004a3:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004a6:	e8 c7 ff ff ff       	call   f0100472 <serial_intr>
	kbd_intr();
f01004ab:	e8 de ff ff ff       	call   f010048e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004b0:	a1 20 65 11 f0       	mov    0xf0116520,%eax
f01004b5:	3b 05 24 65 11 f0    	cmp    0xf0116524,%eax
f01004bb:	74 26                	je     f01004e3 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004bd:	8d 50 01             	lea    0x1(%eax),%edx
f01004c0:	89 15 20 65 11 f0    	mov    %edx,0xf0116520
f01004c6:	0f b6 88 20 63 11 f0 	movzbl -0xfee9ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004cd:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004cf:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004d5:	75 11                	jne    f01004e8 <cons_getc+0x48>
			cons.rpos = 0;
f01004d7:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
f01004de:	00 00 00 
f01004e1:	eb 05                	jmp    f01004e8 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004e8:	c9                   	leave  
f01004e9:	c3                   	ret    

f01004ea <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ea:	55                   	push   %ebp
f01004eb:	89 e5                	mov    %esp,%ebp
f01004ed:	57                   	push   %edi
f01004ee:	56                   	push   %esi
f01004ef:	53                   	push   %ebx
f01004f0:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004f3:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01004fa:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100501:	5a a5 
	if (*cp != 0xA55A) {
f0100503:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010050a:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010050e:	74 11                	je     f0100521 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100510:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
f0100517:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010051a:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010051f:	eb 16                	jmp    f0100537 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100521:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100528:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
f010052f:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100532:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100537:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
f010053d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100542:	89 fa                	mov    %edi,%edx
f0100544:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100545:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100548:	89 da                	mov    %ebx,%edx
f010054a:	ec                   	in     (%dx),%al
f010054b:	0f b6 c8             	movzbl %al,%ecx
f010054e:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100551:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100556:	89 fa                	mov    %edi,%edx
f0100558:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100559:	89 da                	mov    %ebx,%edx
f010055b:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010055c:	89 35 2c 65 11 f0    	mov    %esi,0xf011652c
	crt_pos = pos;
f0100562:	0f b6 c0             	movzbl %al,%eax
f0100565:	09 c8                	or     %ecx,%eax
f0100567:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010056d:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100572:	b8 00 00 00 00       	mov    $0x0,%eax
f0100577:	89 f2                	mov    %esi,%edx
f0100579:	ee                   	out    %al,(%dx)
f010057a:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010057f:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100584:	ee                   	out    %al,(%dx)
f0100585:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010058a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010058f:	89 da                	mov    %ebx,%edx
f0100591:	ee                   	out    %al,(%dx)
f0100592:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100597:	b8 00 00 00 00       	mov    $0x0,%eax
f010059c:	ee                   	out    %al,(%dx)
f010059d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005a2:	b8 03 00 00 00       	mov    $0x3,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b2:	ee                   	out    %al,(%dx)
f01005b3:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005b8:	b8 01 00 00 00       	mov    $0x1,%eax
f01005bd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005be:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005c3:	ec                   	in     (%dx),%al
f01005c4:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c6:	3c ff                	cmp    $0xff,%al
f01005c8:	0f 95 05 34 65 11 f0 	setne  0xf0116534
f01005cf:	89 f2                	mov    %esi,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 da                	mov    %ebx,%edx
f01005d4:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d5:	80 f9 ff             	cmp    $0xff,%cl
f01005d8:	75 10                	jne    f01005ea <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005da:	83 ec 0c             	sub    $0xc,%esp
f01005dd:	68 39 37 10 f0       	push   $0xf0103739
f01005e2:	e8 0d 21 00 00       	call   f01026f4 <cprintf>
f01005e7:	83 c4 10             	add    $0x10,%esp
}
f01005ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005ed:	5b                   	pop    %ebx
f01005ee:	5e                   	pop    %esi
f01005ef:	5f                   	pop    %edi
f01005f0:	5d                   	pop    %ebp
f01005f1:	c3                   	ret    

f01005f2 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f2:	55                   	push   %ebp
f01005f3:	89 e5                	mov    %esp,%ebp
f01005f5:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fb:	e8 89 fc ff ff       	call   f0100289 <cons_putc>
}
f0100600:	c9                   	leave  
f0100601:	c3                   	ret    

f0100602 <getchar>:

int
getchar(void)
{
f0100602:	55                   	push   %ebp
f0100603:	89 e5                	mov    %esp,%ebp
f0100605:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100608:	e8 93 fe ff ff       	call   f01004a0 <cons_getc>
f010060d:	85 c0                	test   %eax,%eax
f010060f:	74 f7                	je     f0100608 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100611:	c9                   	leave  
f0100612:	c3                   	ret    

f0100613 <iscons>:

int
iscons(int fdnum)
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100616:	b8 01 00 00 00       	mov    $0x1,%eax
f010061b:	5d                   	pop    %ebp
f010061c:	c3                   	ret    

f010061d <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010061d:	55                   	push   %ebp
f010061e:	89 e5                	mov    %esp,%ebp
f0100620:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100623:	68 80 39 10 f0       	push   $0xf0103980
f0100628:	68 9e 39 10 f0       	push   $0xf010399e
f010062d:	68 a3 39 10 f0       	push   $0xf01039a3
f0100632:	e8 bd 20 00 00       	call   f01026f4 <cprintf>
f0100637:	83 c4 0c             	add    $0xc,%esp
f010063a:	68 54 3a 10 f0       	push   $0xf0103a54
f010063f:	68 ac 39 10 f0       	push   $0xf01039ac
f0100644:	68 a3 39 10 f0       	push   $0xf01039a3
f0100649:	e8 a6 20 00 00       	call   f01026f4 <cprintf>
	return 0;
}
f010064e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100653:	c9                   	leave  
f0100654:	c3                   	ret    

f0100655 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100655:	55                   	push   %ebp
f0100656:	89 e5                	mov    %esp,%ebp
f0100658:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010065b:	68 b5 39 10 f0       	push   $0xf01039b5
f0100660:	e8 8f 20 00 00       	call   f01026f4 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100665:	83 c4 08             	add    $0x8,%esp
f0100668:	68 0c 00 10 00       	push   $0x10000c
f010066d:	68 7c 3a 10 f0       	push   $0xf0103a7c
f0100672:	e8 7d 20 00 00       	call   f01026f4 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100677:	83 c4 0c             	add    $0xc,%esp
f010067a:	68 0c 00 10 00       	push   $0x10000c
f010067f:	68 0c 00 10 f0       	push   $0xf010000c
f0100684:	68 a4 3a 10 f0       	push   $0xf0103aa4
f0100689:	e8 66 20 00 00       	call   f01026f4 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010068e:	83 c4 0c             	add    $0xc,%esp
f0100691:	68 d1 36 10 00       	push   $0x1036d1
f0100696:	68 d1 36 10 f0       	push   $0xf01036d1
f010069b:	68 c8 3a 10 f0       	push   $0xf0103ac8
f01006a0:	e8 4f 20 00 00       	call   f01026f4 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006a5:	83 c4 0c             	add    $0xc,%esp
f01006a8:	68 00 63 11 00       	push   $0x116300
f01006ad:	68 00 63 11 f0       	push   $0xf0116300
f01006b2:	68 ec 3a 10 f0       	push   $0xf0103aec
f01006b7:	e8 38 20 00 00       	call   f01026f4 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006bc:	83 c4 0c             	add    $0xc,%esp
f01006bf:	68 70 69 11 00       	push   $0x116970
f01006c4:	68 70 69 11 f0       	push   $0xf0116970
f01006c9:	68 10 3b 10 f0       	push   $0xf0103b10
f01006ce:	e8 21 20 00 00       	call   f01026f4 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006d3:	b8 6f 6d 11 f0       	mov    $0xf0116d6f,%eax
f01006d8:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006dd:	83 c4 08             	add    $0x8,%esp
f01006e0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006e5:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006eb:	85 c0                	test   %eax,%eax
f01006ed:	0f 48 c2             	cmovs  %edx,%eax
f01006f0:	c1 f8 0a             	sar    $0xa,%eax
f01006f3:	50                   	push   %eax
f01006f4:	68 34 3b 10 f0       	push   $0xf0103b34
f01006f9:	e8 f6 1f 00 00       	call   f01026f4 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01006fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0100703:	c9                   	leave  
f0100704:	c3                   	ret    

f0100705 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100705:	55                   	push   %ebp
f0100706:	89 e5                	mov    %esp,%ebp
f0100708:	57                   	push   %edi
f0100709:	56                   	push   %esi
f010070a:	53                   	push   %ebx
f010070b:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010070e:	89 ee                	mov    %ebp,%esi
	// Your code here.
	struct Eipdebuginfo info;
	uint32_t *ebp = (uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
f0100710:	68 ce 39 10 f0       	push   $0xf01039ce
f0100715:	e8 da 1f 00 00       	call   f01026f4 <cprintf>
	while (ebp) {
f010071a:	83 c4 10             	add    $0x10,%esp
f010071d:	eb 67                	jmp    f0100786 <mon_backtrace+0x81>
	    cprintf(" ebp %08x eip %08x args ", ebp, ebp[1]);
f010071f:	83 ec 04             	sub    $0x4,%esp
f0100722:	ff 76 04             	pushl  0x4(%esi)
f0100725:	56                   	push   %esi
f0100726:	68 e0 39 10 f0       	push   $0xf01039e0
f010072b:	e8 c4 1f 00 00       	call   f01026f4 <cprintf>
f0100730:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100733:	8d 7e 1c             	lea    0x1c(%esi),%edi
f0100736:	83 c4 10             	add    $0x10,%esp
	    for (int j = 2; j != 7; ++j) {
		cprintf(" %08x", ebp[j]);   
f0100739:	83 ec 08             	sub    $0x8,%esp
f010073c:	ff 33                	pushl  (%ebx)
f010073e:	68 f9 39 10 f0       	push   $0xf01039f9
f0100743:	e8 ac 1f 00 00       	call   f01026f4 <cprintf>
f0100748:	83 c3 04             	add    $0x4,%ebx
	struct Eipdebuginfo info;
	uint32_t *ebp = (uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp) {
	    cprintf(" ebp %08x eip %08x args ", ebp, ebp[1]);
	    for (int j = 2; j != 7; ++j) {
f010074b:	83 c4 10             	add    $0x10,%esp
f010074e:	39 fb                	cmp    %edi,%ebx
f0100750:	75 e7                	jne    f0100739 <mon_backtrace+0x34>
		cprintf(" %08x", ebp[j]);   
	    }
	    debuginfo_eip(ebp[1], &info);
f0100752:	83 ec 08             	sub    $0x8,%esp
f0100755:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100758:	50                   	push   %eax
f0100759:	ff 76 04             	pushl  0x4(%esi)
f010075c:	e8 9d 20 00 00       	call   f01027fe <debuginfo_eip>
    	    cprintf("\n     %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ebp[1] - info.eip_fn_addr);
f0100761:	83 c4 08             	add    $0x8,%esp
f0100764:	8b 46 04             	mov    0x4(%esi),%eax
f0100767:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010076a:	50                   	push   %eax
f010076b:	ff 75 d8             	pushl  -0x28(%ebp)
f010076e:	ff 75 dc             	pushl  -0x24(%ebp)
f0100771:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100774:	ff 75 d0             	pushl  -0x30(%ebp)
f0100777:	68 ff 39 10 f0       	push   $0xf01039ff
f010077c:	e8 73 1f 00 00       	call   f01026f4 <cprintf>
	    ebp = (uint32_t *) (*ebp);
f0100781:	8b 36                	mov    (%esi),%esi
f0100783:	83 c4 20             	add    $0x20,%esp
{
	// Your code here.
	struct Eipdebuginfo info;
	uint32_t *ebp = (uint32_t *) read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp) {
f0100786:	85 f6                	test   %esi,%esi
f0100788:	75 95                	jne    f010071f <mon_backtrace+0x1a>
    	    cprintf("\n     %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ebp[1] - info.eip_fn_addr);
	    ebp = (uint32_t *) (*ebp);
}
return 0;
	return 0;
}
f010078a:	b8 00 00 00 00       	mov    $0x0,%eax
f010078f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100792:	5b                   	pop    %ebx
f0100793:	5e                   	pop    %esi
f0100794:	5f                   	pop    %edi
f0100795:	5d                   	pop    %ebp
f0100796:	c3                   	ret    

f0100797 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100797:	55                   	push   %ebp
f0100798:	89 e5                	mov    %esp,%ebp
f010079a:	57                   	push   %edi
f010079b:	56                   	push   %esi
f010079c:	53                   	push   %ebx
f010079d:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007a0:	68 60 3b 10 f0       	push   $0xf0103b60
f01007a5:	e8 4a 1f 00 00       	call   f01026f4 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007aa:	c7 04 24 84 3b 10 f0 	movl   $0xf0103b84,(%esp)
f01007b1:	e8 3e 1f 00 00       	call   f01026f4 <cprintf>
f01007b6:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007b9:	83 ec 0c             	sub    $0xc,%esp
f01007bc:	68 15 3a 10 f0       	push   $0xf0103a15
f01007c1:	e8 22 28 00 00       	call   f0102fe8 <readline>
f01007c6:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007c8:	83 c4 10             	add    $0x10,%esp
f01007cb:	85 c0                	test   %eax,%eax
f01007cd:	74 ea                	je     f01007b9 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007cf:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007d6:	be 00 00 00 00       	mov    $0x0,%esi
f01007db:	eb 0a                	jmp    f01007e7 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007dd:	c6 03 00             	movb   $0x0,(%ebx)
f01007e0:	89 f7                	mov    %esi,%edi
f01007e2:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007e5:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007e7:	0f b6 03             	movzbl (%ebx),%eax
f01007ea:	84 c0                	test   %al,%al
f01007ec:	74 63                	je     f0100851 <monitor+0xba>
f01007ee:	83 ec 08             	sub    $0x8,%esp
f01007f1:	0f be c0             	movsbl %al,%eax
f01007f4:	50                   	push   %eax
f01007f5:	68 19 3a 10 f0       	push   $0xf0103a19
f01007fa:	e8 03 2a 00 00       	call   f0103202 <strchr>
f01007ff:	83 c4 10             	add    $0x10,%esp
f0100802:	85 c0                	test   %eax,%eax
f0100804:	75 d7                	jne    f01007dd <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100806:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100809:	74 46                	je     f0100851 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010080b:	83 fe 0f             	cmp    $0xf,%esi
f010080e:	75 14                	jne    f0100824 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100810:	83 ec 08             	sub    $0x8,%esp
f0100813:	6a 10                	push   $0x10
f0100815:	68 1e 3a 10 f0       	push   $0xf0103a1e
f010081a:	e8 d5 1e 00 00       	call   f01026f4 <cprintf>
f010081f:	83 c4 10             	add    $0x10,%esp
f0100822:	eb 95                	jmp    f01007b9 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100824:	8d 7e 01             	lea    0x1(%esi),%edi
f0100827:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010082b:	eb 03                	jmp    f0100830 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010082d:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100830:	0f b6 03             	movzbl (%ebx),%eax
f0100833:	84 c0                	test   %al,%al
f0100835:	74 ae                	je     f01007e5 <monitor+0x4e>
f0100837:	83 ec 08             	sub    $0x8,%esp
f010083a:	0f be c0             	movsbl %al,%eax
f010083d:	50                   	push   %eax
f010083e:	68 19 3a 10 f0       	push   $0xf0103a19
f0100843:	e8 ba 29 00 00       	call   f0103202 <strchr>
f0100848:	83 c4 10             	add    $0x10,%esp
f010084b:	85 c0                	test   %eax,%eax
f010084d:	74 de                	je     f010082d <monitor+0x96>
f010084f:	eb 94                	jmp    f01007e5 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100851:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100858:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100859:	85 f6                	test   %esi,%esi
f010085b:	0f 84 58 ff ff ff    	je     f01007b9 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100861:	83 ec 08             	sub    $0x8,%esp
f0100864:	68 9e 39 10 f0       	push   $0xf010399e
f0100869:	ff 75 a8             	pushl  -0x58(%ebp)
f010086c:	e8 33 29 00 00       	call   f01031a4 <strcmp>
f0100871:	83 c4 10             	add    $0x10,%esp
f0100874:	85 c0                	test   %eax,%eax
f0100876:	74 1e                	je     f0100896 <monitor+0xff>
f0100878:	83 ec 08             	sub    $0x8,%esp
f010087b:	68 ac 39 10 f0       	push   $0xf01039ac
f0100880:	ff 75 a8             	pushl  -0x58(%ebp)
f0100883:	e8 1c 29 00 00       	call   f01031a4 <strcmp>
f0100888:	83 c4 10             	add    $0x10,%esp
f010088b:	85 c0                	test   %eax,%eax
f010088d:	75 2f                	jne    f01008be <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010088f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100894:	eb 05                	jmp    f010089b <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100896:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f010089b:	83 ec 04             	sub    $0x4,%esp
f010089e:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008a1:	01 d0                	add    %edx,%eax
f01008a3:	ff 75 08             	pushl  0x8(%ebp)
f01008a6:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008a9:	51                   	push   %ecx
f01008aa:	56                   	push   %esi
f01008ab:	ff 14 85 b4 3b 10 f0 	call   *-0xfefc44c(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008b2:	83 c4 10             	add    $0x10,%esp
f01008b5:	85 c0                	test   %eax,%eax
f01008b7:	78 1d                	js     f01008d6 <monitor+0x13f>
f01008b9:	e9 fb fe ff ff       	jmp    f01007b9 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008be:	83 ec 08             	sub    $0x8,%esp
f01008c1:	ff 75 a8             	pushl  -0x58(%ebp)
f01008c4:	68 3b 3a 10 f0       	push   $0xf0103a3b
f01008c9:	e8 26 1e 00 00       	call   f01026f4 <cprintf>
f01008ce:	83 c4 10             	add    $0x10,%esp
f01008d1:	e9 e3 fe ff ff       	jmp    f01007b9 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008d6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008d9:	5b                   	pop    %ebx
f01008da:	5e                   	pop    %esi
f01008db:	5f                   	pop    %edi
f01008dc:	5d                   	pop    %ebp
f01008dd:	c3                   	ret    

f01008de <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01008de:	55                   	push   %ebp
f01008df:	89 e5                	mov    %esp,%ebp
f01008e1:	53                   	push   %ebx
f01008e2:	83 ec 04             	sub    $0x4,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008e5:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f01008ec:	75 11                	jne    f01008ff <boot_alloc+0x21>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008ee:	ba 6f 79 11 f0       	mov    $0xf011796f,%edx
f01008f3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01008f9:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f01008ff:	8b 1d 38 65 11 f0    	mov    0xf0116538,%ebx
	nextfree = ROUNDUP(nextfree+n, PGSIZE);
f0100905:	8d 94 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%edx
f010090c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100912:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	if((uint32_t)nextfree - KERNBASE > (npages*PGSIZE))
f0100918:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f010091e:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0100924:	c1 e1 0c             	shl    $0xc,%ecx
f0100927:	39 ca                	cmp    %ecx,%edx
f0100929:	76 14                	jbe    f010093f <boot_alloc+0x61>
		panic("Out of memory!\n");
f010092b:	83 ec 04             	sub    $0x4,%esp
f010092e:	68 c4 3b 10 f0       	push   $0xf0103bc4
f0100933:	6a 68                	push   $0x68
f0100935:	68 d4 3b 10 f0       	push   $0xf0103bd4
f010093a:	e8 4c f7 ff ff       	call   f010008b <_panic>
	return result;
}
f010093f:	89 d8                	mov    %ebx,%eax
f0100941:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100944:	c9                   	leave  
f0100945:	c3                   	ret    

f0100946 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100946:	89 d1                	mov    %edx,%ecx
f0100948:	c1 e9 16             	shr    $0x16,%ecx
f010094b:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010094e:	a8 01                	test   $0x1,%al
f0100950:	74 52                	je     f01009a4 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100952:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100957:	89 c1                	mov    %eax,%ecx
f0100959:	c1 e9 0c             	shr    $0xc,%ecx
f010095c:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f0100962:	72 1b                	jb     f010097f <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100964:	55                   	push   %ebp
f0100965:	89 e5                	mov    %esp,%ebp
f0100967:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010096a:	50                   	push   %eax
f010096b:	68 dc 3e 10 f0       	push   $0xf0103edc
f0100970:	68 e6 02 00 00       	push   $0x2e6
f0100975:	68 d4 3b 10 f0       	push   $0xf0103bd4
f010097a:	e8 0c f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010097f:	c1 ea 0c             	shr    $0xc,%edx
f0100982:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100988:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010098f:	89 c2                	mov    %eax,%edx
f0100991:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100994:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100999:	85 d2                	test   %edx,%edx
f010099b:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009a0:	0f 44 c2             	cmove  %edx,%eax
f01009a3:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009a4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009a9:	c3                   	ret    

f01009aa <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009aa:	55                   	push   %ebp
f01009ab:	89 e5                	mov    %esp,%ebp
f01009ad:	57                   	push   %edi
f01009ae:	56                   	push   %esi
f01009af:	53                   	push   %ebx
f01009b0:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009b3:	84 c0                	test   %al,%al
f01009b5:	0f 85 72 02 00 00    	jne    f0100c2d <check_page_free_list+0x283>
f01009bb:	e9 7f 02 00 00       	jmp    f0100c3f <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009c0:	83 ec 04             	sub    $0x4,%esp
f01009c3:	68 00 3f 10 f0       	push   $0xf0103f00
f01009c8:	68 29 02 00 00       	push   $0x229
f01009cd:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01009d2:	e8 b4 f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009d7:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009da:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009dd:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009e0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009e3:	89 c2                	mov    %eax,%edx
f01009e5:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01009eb:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009f1:	0f 95 c2             	setne  %dl
f01009f4:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01009f7:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009fb:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009fd:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a01:	8b 00                	mov    (%eax),%eax
f0100a03:	85 c0                	test   %eax,%eax
f0100a05:	75 dc                	jne    f01009e3 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a07:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a0a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a10:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a13:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a16:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a18:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a1b:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a20:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a25:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100a2b:	eb 53                	jmp    f0100a80 <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a2d:	89 d8                	mov    %ebx,%eax
f0100a2f:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100a35:	c1 f8 03             	sar    $0x3,%eax
f0100a38:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a3b:	89 c2                	mov    %eax,%edx
f0100a3d:	c1 ea 16             	shr    $0x16,%edx
f0100a40:	39 f2                	cmp    %esi,%edx
f0100a42:	73 3a                	jae    f0100a7e <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a44:	89 c2                	mov    %eax,%edx
f0100a46:	c1 ea 0c             	shr    $0xc,%edx
f0100a49:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100a4f:	72 12                	jb     f0100a63 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a51:	50                   	push   %eax
f0100a52:	68 dc 3e 10 f0       	push   $0xf0103edc
f0100a57:	6a 52                	push   $0x52
f0100a59:	68 e0 3b 10 f0       	push   $0xf0103be0
f0100a5e:	e8 28 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a63:	83 ec 04             	sub    $0x4,%esp
f0100a66:	68 80 00 00 00       	push   $0x80
f0100a6b:	68 97 00 00 00       	push   $0x97
f0100a70:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a75:	50                   	push   %eax
f0100a76:	e8 c4 27 00 00       	call   f010323f <memset>
f0100a7b:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a7e:	8b 1b                	mov    (%ebx),%ebx
f0100a80:	85 db                	test   %ebx,%ebx
f0100a82:	75 a9                	jne    f0100a2d <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a84:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a89:	e8 50 fe ff ff       	call   f01008de <boot_alloc>
f0100a8e:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a91:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a97:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
		assert(pp < pages + npages);
f0100a9d:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0100aa2:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100aa5:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aa8:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100aab:	be 00 00 00 00       	mov    $0x0,%esi
f0100ab0:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ab3:	e9 30 01 00 00       	jmp    f0100be8 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ab8:	39 ca                	cmp    %ecx,%edx
f0100aba:	73 19                	jae    f0100ad5 <check_page_free_list+0x12b>
f0100abc:	68 ee 3b 10 f0       	push   $0xf0103bee
f0100ac1:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0100ac6:	68 43 02 00 00       	push   $0x243
f0100acb:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0100ad0:	e8 b6 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100ad5:	39 fa                	cmp    %edi,%edx
f0100ad7:	72 19                	jb     f0100af2 <check_page_free_list+0x148>
f0100ad9:	68 0f 3c 10 f0       	push   $0xf0103c0f
f0100ade:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0100ae3:	68 44 02 00 00       	push   $0x244
f0100ae8:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0100aed:	e8 99 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100af2:	89 d0                	mov    %edx,%eax
f0100af4:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100af7:	a8 07                	test   $0x7,%al
f0100af9:	74 19                	je     f0100b14 <check_page_free_list+0x16a>
f0100afb:	68 24 3f 10 f0       	push   $0xf0103f24
f0100b00:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0100b05:	68 45 02 00 00       	push   $0x245
f0100b0a:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0100b0f:	e8 77 f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b14:	c1 f8 03             	sar    $0x3,%eax
f0100b17:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b1a:	85 c0                	test   %eax,%eax
f0100b1c:	75 19                	jne    f0100b37 <check_page_free_list+0x18d>
f0100b1e:	68 23 3c 10 f0       	push   $0xf0103c23
f0100b23:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0100b28:	68 48 02 00 00       	push   $0x248
f0100b2d:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0100b32:	e8 54 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b37:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b3c:	75 19                	jne    f0100b57 <check_page_free_list+0x1ad>
f0100b3e:	68 34 3c 10 f0       	push   $0xf0103c34
f0100b43:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0100b48:	68 49 02 00 00       	push   $0x249
f0100b4d:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0100b52:	e8 34 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b57:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b5c:	75 19                	jne    f0100b77 <check_page_free_list+0x1cd>
f0100b5e:	68 58 3f 10 f0       	push   $0xf0103f58
f0100b63:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0100b68:	68 4a 02 00 00       	push   $0x24a
f0100b6d:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0100b72:	e8 14 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b77:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b7c:	75 19                	jne    f0100b97 <check_page_free_list+0x1ed>
f0100b7e:	68 4d 3c 10 f0       	push   $0xf0103c4d
f0100b83:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0100b88:	68 4b 02 00 00       	push   $0x24b
f0100b8d:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0100b92:	e8 f4 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b97:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b9c:	76 3f                	jbe    f0100bdd <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b9e:	89 c3                	mov    %eax,%ebx
f0100ba0:	c1 eb 0c             	shr    $0xc,%ebx
f0100ba3:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100ba6:	77 12                	ja     f0100bba <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ba8:	50                   	push   %eax
f0100ba9:	68 dc 3e 10 f0       	push   $0xf0103edc
f0100bae:	6a 52                	push   $0x52
f0100bb0:	68 e0 3b 10 f0       	push   $0xf0103be0
f0100bb5:	e8 d1 f4 ff ff       	call   f010008b <_panic>
f0100bba:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bbf:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bc2:	76 1e                	jbe    f0100be2 <check_page_free_list+0x238>
f0100bc4:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0100bc9:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0100bce:	68 4c 02 00 00       	push   $0x24c
f0100bd3:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0100bd8:	e8 ae f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bdd:	83 c6 01             	add    $0x1,%esi
f0100be0:	eb 04                	jmp    f0100be6 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100be2:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100be6:	8b 12                	mov    (%edx),%edx
f0100be8:	85 d2                	test   %edx,%edx
f0100bea:	0f 85 c8 fe ff ff    	jne    f0100ab8 <check_page_free_list+0x10e>
f0100bf0:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100bf3:	85 f6                	test   %esi,%esi
f0100bf5:	7f 19                	jg     f0100c10 <check_page_free_list+0x266>
f0100bf7:	68 67 3c 10 f0       	push   $0xf0103c67
f0100bfc:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0100c01:	68 54 02 00 00       	push   $0x254
f0100c06:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0100c0b:	e8 7b f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c10:	85 db                	test   %ebx,%ebx
f0100c12:	7f 42                	jg     f0100c56 <check_page_free_list+0x2ac>
f0100c14:	68 79 3c 10 f0       	push   $0xf0103c79
f0100c19:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0100c1e:	68 55 02 00 00       	push   $0x255
f0100c23:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0100c28:	e8 5e f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c2d:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100c32:	85 c0                	test   %eax,%eax
f0100c34:	0f 85 9d fd ff ff    	jne    f01009d7 <check_page_free_list+0x2d>
f0100c3a:	e9 81 fd ff ff       	jmp    f01009c0 <check_page_free_list+0x16>
f0100c3f:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
f0100c46:	0f 84 74 fd ff ff    	je     f01009c0 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c4c:	be 00 04 00 00       	mov    $0x400,%esi
f0100c51:	e9 cf fd ff ff       	jmp    f0100a25 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c56:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c59:	5b                   	pop    %ebx
f0100c5a:	5e                   	pop    %esi
f0100c5b:	5f                   	pop    %edi
f0100c5c:	5d                   	pop    %ebp
f0100c5d:	c3                   	ret    

f0100c5e <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c5e:	55                   	push   %ebp
f0100c5f:	89 e5                	mov    %esp,%ebp
f0100c61:	57                   	push   %edi
f0100c62:	56                   	push   %esi
f0100c63:	53                   	push   %ebx
f0100c64:	83 ec 0c             	sub    $0xc,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	page_free_list = NULL;
f0100c67:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0100c6e:	00 00 00 

	//num_alloc：在extmem区域已经被占用的页的个数
	int num_alloc = ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;
f0100c71:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c76:	e8 63 fc ff ff       	call   f01008de <boot_alloc>
	{
	    if(i==0)
	    {
		pages[i].pp_ref = 1;
	    }    
	    else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_alloc)
f0100c7b:	8b 35 40 65 11 f0    	mov    0xf0116540,%esi
f0100c81:	05 00 00 00 10       	add    $0x10000000,%eax
f0100c86:	c1 e8 0c             	shr    $0xc,%eax
f0100c89:	8d 7c 06 60          	lea    0x60(%esi,%eax,1),%edi
	//num_alloc：在extmem区域已经被占用的页的个数
	int num_alloc = ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;
	//num_iohole：在io hole区域占用的页数
	int num_iohole = 96;

	for(i=0; i<npages; i++)
f0100c8d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100c92:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c97:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c9c:	eb 50                	jmp    f0100cee <page_init+0x90>
	{
	    if(i==0)
f0100c9e:	85 c0                	test   %eax,%eax
f0100ca0:	75 0e                	jne    f0100cb0 <page_init+0x52>
	    {
		pages[i].pp_ref = 1;
f0100ca2:	8b 15 6c 69 11 f0    	mov    0xf011696c,%edx
f0100ca8:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
f0100cae:	eb 3b                	jmp    f0100ceb <page_init+0x8d>
	    }    
	    else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_alloc)
f0100cb0:	39 f0                	cmp    %esi,%eax
f0100cb2:	72 13                	jb     f0100cc7 <page_init+0x69>
f0100cb4:	39 f8                	cmp    %edi,%eax
f0100cb6:	73 0f                	jae    f0100cc7 <page_init+0x69>
	    {
		pages[i].pp_ref = 1;
f0100cb8:	8b 15 6c 69 11 f0    	mov    0xf011696c,%edx
f0100cbe:	66 c7 44 c2 04 01 00 	movw   $0x1,0x4(%edx,%eax,8)
f0100cc5:	eb 24                	jmp    f0100ceb <page_init+0x8d>
f0100cc7:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
	    }
	    else
	    {
		pages[i].pp_ref = 0;
f0100cce:	89 d1                	mov    %edx,%ecx
f0100cd0:	03 0d 6c 69 11 f0    	add    0xf011696c,%ecx
f0100cd6:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100cdc:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100cde:	89 d3                	mov    %edx,%ebx
f0100ce0:	03 1d 6c 69 11 f0    	add    0xf011696c,%ebx
f0100ce6:	b9 01 00 00 00       	mov    $0x1,%ecx
	//num_alloc：在extmem区域已经被占用的页的个数
	int num_alloc = ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;
	//num_iohole：在io hole区域占用的页数
	int num_iohole = 96;

	for(i=0; i<npages; i++)
f0100ceb:	83 c0 01             	add    $0x1,%eax
f0100cee:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0100cf4:	72 a8                	jb     f0100c9e <page_init+0x40>
f0100cf6:	84 c9                	test   %cl,%cl
f0100cf8:	74 06                	je     f0100d00 <page_init+0xa2>
f0100cfa:	89 1d 3c 65 11 f0    	mov    %ebx,0xf011653c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	    }
	}
}
f0100d00:	83 c4 0c             	add    $0xc,%esp
f0100d03:	5b                   	pop    %ebx
f0100d04:	5e                   	pop    %esi
f0100d05:	5f                   	pop    %edi
f0100d06:	5d                   	pop    %ebp
f0100d07:	c3                   	ret    

f0100d08 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d08:	55                   	push   %ebp
f0100d09:	89 e5                	mov    %esp,%ebp
f0100d0b:	53                   	push   %ebx
f0100d0c:	83 ec 04             	sub    $0x4,%esp
	    struct PageInfo *result;
	    if (page_free_list == NULL)
f0100d0f:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100d15:	85 db                	test   %ebx,%ebx
f0100d17:	74 58                	je     f0100d71 <page_alloc+0x69>
		return NULL;

	    result= page_free_list;
	    page_free_list = result->pp_link;
f0100d19:	8b 03                	mov    (%ebx),%eax
f0100d1b:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	    result->pp_link = NULL;
f0100d20:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	    if (alloc_flags & ALLOC_ZERO)
f0100d26:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d2a:	74 45                	je     f0100d71 <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d2c:	89 d8                	mov    %ebx,%eax
f0100d2e:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100d34:	c1 f8 03             	sar    $0x3,%eax
f0100d37:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d3a:	89 c2                	mov    %eax,%edx
f0100d3c:	c1 ea 0c             	shr    $0xc,%edx
f0100d3f:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100d45:	72 12                	jb     f0100d59 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d47:	50                   	push   %eax
f0100d48:	68 dc 3e 10 f0       	push   $0xf0103edc
f0100d4d:	6a 52                	push   $0x52
f0100d4f:	68 e0 3b 10 f0       	push   $0xf0103be0
f0100d54:	e8 32 f3 ff ff       	call   f010008b <_panic>
		memset(page2kva(result), 0, PGSIZE); 
f0100d59:	83 ec 04             	sub    $0x4,%esp
f0100d5c:	68 00 10 00 00       	push   $0x1000
f0100d61:	6a 00                	push   $0x0
f0100d63:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d68:	50                   	push   %eax
f0100d69:	e8 d1 24 00 00       	call   f010323f <memset>
f0100d6e:	83 c4 10             	add    $0x10,%esp

	    return result;
}
f0100d71:	89 d8                	mov    %ebx,%eax
f0100d73:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d76:	c9                   	leave  
f0100d77:	c3                   	ret    

f0100d78 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100d78:	55                   	push   %ebp
f0100d79:	89 e5                	mov    %esp,%ebp
f0100d7b:	83 ec 08             	sub    $0x8,%esp
f0100d7e:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	assert(pp->pp_ref == 0);
f0100d81:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100d86:	74 19                	je     f0100da1 <page_free+0x29>
f0100d88:	68 8a 3c 10 f0       	push   $0xf0103c8a
f0100d8d:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0100d92:	68 40 01 00 00       	push   $0x140
f0100d97:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0100d9c:	e8 ea f2 ff ff       	call   f010008b <_panic>
	assert(pp->pp_link == NULL);
f0100da1:	83 38 00             	cmpl   $0x0,(%eax)
f0100da4:	74 19                	je     f0100dbf <page_free+0x47>
f0100da6:	68 9a 3c 10 f0       	push   $0xf0103c9a
f0100dab:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0100db0:	68 41 01 00 00       	push   $0x141
f0100db5:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0100dba:	e8 cc f2 ff ff       	call   f010008b <_panic>

	pp->pp_link = page_free_list;
f0100dbf:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100dc5:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100dc7:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
}
f0100dcc:	c9                   	leave  
f0100dcd:	c3                   	ret    

f0100dce <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100dce:	55                   	push   %ebp
f0100dcf:	89 e5                	mov    %esp,%ebp
f0100dd1:	83 ec 08             	sub    $0x8,%esp
f0100dd4:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100dd7:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100ddb:	83 e8 01             	sub    $0x1,%eax
f0100dde:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100de2:	66 85 c0             	test   %ax,%ax
f0100de5:	75 0c                	jne    f0100df3 <page_decref+0x25>
		page_free(pp);
f0100de7:	83 ec 0c             	sub    $0xc,%esp
f0100dea:	52                   	push   %edx
f0100deb:	e8 88 ff ff ff       	call   f0100d78 <page_free>
f0100df0:	83 c4 10             	add    $0x10,%esp
}
f0100df3:	c9                   	leave  
f0100df4:	c3                   	ret    

f0100df5 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100df5:	55                   	push   %ebp
f0100df6:	89 e5                	mov    %esp,%ebp
f0100df8:	56                   	push   %esi
f0100df9:	53                   	push   %ebx
f0100dfa:	8b 75 0c             	mov    0xc(%ebp),%esi
	unsigned int page_off;
      	pte_t * page_base = NULL;
      	struct PageInfo* new_page = NULL;
      
      	unsigned int dic_off = PDX(va);
      	pde_t * dic_entry_ptr = pgdir + dic_off;
f0100dfd:	89 f3                	mov    %esi,%ebx
f0100dff:	c1 eb 16             	shr    $0x16,%ebx
f0100e02:	c1 e3 02             	shl    $0x2,%ebx
f0100e05:	03 5d 08             	add    0x8(%ebp),%ebx
	
	if(!(*dic_entry_ptr & PTE_P))
f0100e08:	f6 03 01             	testb  $0x1,(%ebx)
f0100e0b:	75 2d                	jne    f0100e3a <pgdir_walk+0x45>
	{
		if(create)
f0100e0d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e11:	74 62                	je     f0100e75 <pgdir_walk+0x80>
      	     	 {
      	            new_page = page_alloc(1);
f0100e13:	83 ec 0c             	sub    $0xc,%esp
f0100e16:	6a 01                	push   $0x1
f0100e18:	e8 eb fe ff ff       	call   f0100d08 <page_alloc>
       	            if(new_page == NULL) 
f0100e1d:	83 c4 10             	add    $0x10,%esp
f0100e20:	85 c0                	test   %eax,%eax
f0100e22:	74 58                	je     f0100e7c <pgdir_walk+0x87>
			return NULL;
                    new_page->pp_ref++;
f0100e24:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
       	            *dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
f0100e29:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100e2f:	c1 f8 03             	sar    $0x3,%eax
f0100e32:	c1 e0 0c             	shl    $0xc,%eax
f0100e35:	83 c8 07             	or     $0x7,%eax
f0100e38:	89 03                	mov    %eax,(%ebx)
		}
           	else
			return NULL;      
      	}  
   
	page_off = PTX(va);
f0100e3a:	c1 ee 0c             	shr    $0xc,%esi
f0100e3d:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
f0100e43:	8b 03                	mov    (%ebx),%eax
f0100e45:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e4a:	89 c2                	mov    %eax,%edx
f0100e4c:	c1 ea 0c             	shr    $0xc,%edx
f0100e4f:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100e55:	72 15                	jb     f0100e6c <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e57:	50                   	push   %eax
f0100e58:	68 dc 3e 10 f0       	push   $0xf0103edc
f0100e5d:	68 82 01 00 00       	push   $0x182
f0100e62:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0100e67:	e8 1f f2 ff ff       	call   f010008b <_panic>
	return &page_base[page_off];
f0100e6c:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100e73:	eb 0c                	jmp    f0100e81 <pgdir_walk+0x8c>
			return NULL;
                    new_page->pp_ref++;
       	            *dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
		}
           	else
			return NULL;      
f0100e75:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e7a:	eb 05                	jmp    f0100e81 <pgdir_walk+0x8c>
	{
		if(create)
      	     	 {
      	            new_page = page_alloc(1);
       	            if(new_page == NULL) 
			return NULL;
f0100e7c:	b8 00 00 00 00       	mov    $0x0,%eax
      	}  
   
	page_off = PTX(va);
	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
	return &page_base[page_off];
}
f0100e81:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e84:	5b                   	pop    %ebx
f0100e85:	5e                   	pop    %esi
f0100e86:	5d                   	pop    %ebp
f0100e87:	c3                   	ret    

f0100e88 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100e88:	55                   	push   %ebp
f0100e89:	89 e5                	mov    %esp,%ebp
f0100e8b:	57                   	push   %edi
f0100e8c:	56                   	push   %esi
f0100e8d:	53                   	push   %ebx
f0100e8e:	83 ec 1c             	sub    $0x1c,%esp
f0100e91:	89 c7                	mov    %eax,%edi
f0100e93:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e96:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0; nadd < size; nadd += PGSIZE)
f0100e99:	bb 00 00 00 00       	mov    $0x0,%ebx
	{
		entry = pgdir_walk(pgdir,(void *)va, 1);    //Get the table entry of this page.
		*entry = (pa | perm | PTE_P);
f0100e9e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ea1:	83 c8 01             	or     $0x1,%eax
f0100ea4:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0; nadd < size; nadd += PGSIZE)
f0100ea7:	eb 1f                	jmp    f0100ec8 <boot_map_region+0x40>
	{
		entry = pgdir_walk(pgdir,(void *)va, 1);    //Get the table entry of this page.
f0100ea9:	83 ec 04             	sub    $0x4,%esp
f0100eac:	6a 01                	push   $0x1
f0100eae:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100eb1:	01 d8                	add    %ebx,%eax
f0100eb3:	50                   	push   %eax
f0100eb4:	57                   	push   %edi
f0100eb5:	e8 3b ff ff ff       	call   f0100df5 <pgdir_walk>
		*entry = (pa | perm | PTE_P);
f0100eba:	0b 75 dc             	or     -0x24(%ebp),%esi
f0100ebd:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0; nadd < size; nadd += PGSIZE)
f0100ebf:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100ec5:	83 c4 10             	add    $0x10,%esp
f0100ec8:	89 de                	mov    %ebx,%esi
f0100eca:	03 75 08             	add    0x8(%ebp),%esi
f0100ecd:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0100ed0:	77 d7                	ja     f0100ea9 <boot_map_region+0x21>
		
		pa += PGSIZE;
		va += PGSIZE;
		
	}
}
f0100ed2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ed5:	5b                   	pop    %ebx
f0100ed6:	5e                   	pop    %esi
f0100ed7:	5f                   	pop    %edi
f0100ed8:	5d                   	pop    %ebp
f0100ed9:	c3                   	ret    

f0100eda <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100eda:	55                   	push   %ebp
f0100edb:	89 e5                	mov    %esp,%ebp
f0100edd:	53                   	push   %ebx
f0100ede:	83 ec 08             	sub    $0x8,%esp
f0100ee1:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *entry = NULL;
	struct PageInfo *ret = NULL;

	entry = pgdir_walk(pgdir, va, 0);
f0100ee4:	6a 00                	push   $0x0
f0100ee6:	ff 75 0c             	pushl  0xc(%ebp)
f0100ee9:	ff 75 08             	pushl  0x8(%ebp)
f0100eec:	e8 04 ff ff ff       	call   f0100df5 <pgdir_walk>
	if(entry == NULL)
f0100ef1:	83 c4 10             	add    $0x10,%esp
f0100ef4:	85 c0                	test   %eax,%eax
f0100ef6:	74 38                	je     f0100f30 <page_lookup+0x56>
f0100ef8:	89 c1                	mov    %eax,%ecx
		return NULL;
	if(!(*entry & PTE_P))
f0100efa:	8b 10                	mov    (%eax),%edx
f0100efc:	f6 c2 01             	test   $0x1,%dl
f0100eff:	74 36                	je     f0100f37 <page_lookup+0x5d>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f01:	c1 ea 0c             	shr    $0xc,%edx
f0100f04:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100f0a:	72 14                	jb     f0100f20 <page_lookup+0x46>
		panic("pa2page called with invalid pa");
f0100f0c:	83 ec 04             	sub    $0x4,%esp
f0100f0f:	68 c4 3f 10 f0       	push   $0xf0103fc4
f0100f14:	6a 4b                	push   $0x4b
f0100f16:	68 e0 3b 10 f0       	push   $0xf0103be0
f0100f1b:	e8 6b f1 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100f20:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0100f25:	8d 04 d0             	lea    (%eax,%edx,8),%eax
        	return NULL;
    
	ret = pa2page(PTE_ADDR(*entry));
	if(pte_store != NULL)
f0100f28:	85 db                	test   %ebx,%ebx
f0100f2a:	74 10                	je     f0100f3c <page_lookup+0x62>
    	{
        	*pte_store = entry;
f0100f2c:	89 0b                	mov    %ecx,(%ebx)
f0100f2e:	eb 0c                	jmp    f0100f3c <page_lookup+0x62>
	pte_t *entry = NULL;
	struct PageInfo *ret = NULL;

	entry = pgdir_walk(pgdir, va, 0);
	if(entry == NULL)
		return NULL;
f0100f30:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f35:	eb 05                	jmp    f0100f3c <page_lookup+0x62>
	if(!(*entry & PTE_P))
        	return NULL;
f0100f37:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store != NULL)
    	{
        	*pte_store = entry;
    	}
    	return ret;
}
f0100f3c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f3f:	c9                   	leave  
f0100f40:	c3                   	ret    

f0100f41 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100f41:	55                   	push   %ebp
f0100f42:	89 e5                	mov    %esp,%ebp
f0100f44:	53                   	push   %ebx
f0100f45:	83 ec 18             	sub    $0x18,%esp
f0100f48:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	 pte_t *pte = NULL;
f0100f4b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &pte);
f0100f52:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100f55:	50                   	push   %eax
f0100f56:	53                   	push   %ebx
f0100f57:	ff 75 08             	pushl  0x8(%ebp)
f0100f5a:	e8 7b ff ff ff       	call   f0100eda <page_lookup>
	if(page == NULL) return ;    
f0100f5f:	83 c4 10             	add    $0x10,%esp
f0100f62:	85 c0                	test   %eax,%eax
f0100f64:	74 18                	je     f0100f7e <page_remove+0x3d>
    
	page_decref(page);
f0100f66:	83 ec 0c             	sub    $0xc,%esp
f0100f69:	50                   	push   %eax
f0100f6a:	e8 5f fe ff ff       	call   f0100dce <page_decref>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f6f:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
	*pte = 0;
f0100f72:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f75:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100f7b:	83 c4 10             	add    $0x10,%esp
}
f0100f7e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f81:	c9                   	leave  
f0100f82:	c3                   	ret    

f0100f83 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100f83:	55                   	push   %ebp
f0100f84:	89 e5                	mov    %esp,%ebp
f0100f86:	57                   	push   %edi
f0100f87:	56                   	push   %esi
f0100f88:	53                   	push   %ebx
f0100f89:	83 ec 10             	sub    $0x10,%esp
f0100f8c:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f8f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *entry = NULL;
	entry =  pgdir_walk(pgdir, va, 1);    //Get the mapping page of this address va.
f0100f92:	6a 01                	push   $0x1
f0100f94:	ff 75 10             	pushl  0x10(%ebp)
f0100f97:	56                   	push   %esi
f0100f98:	e8 58 fe ff ff       	call   f0100df5 <pgdir_walk>
	if(entry == NULL) return -E_NO_MEM;
f0100f9d:	83 c4 10             	add    $0x10,%esp
f0100fa0:	85 c0                	test   %eax,%eax
f0100fa2:	74 4a                	je     f0100fee <page_insert+0x6b>
f0100fa4:	89 c7                	mov    %eax,%edi

	pp->pp_ref++;
f0100fa6:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if((*entry) & PTE_P)             //If this virtual address is already mapped.
f0100fab:	f6 00 01             	testb  $0x1,(%eax)
f0100fae:	74 15                	je     f0100fc5 <page_insert+0x42>
f0100fb0:	8b 45 10             	mov    0x10(%ebp),%eax
f0100fb3:	0f 01 38             	invlpg (%eax)
	{
		tlb_invalidate(pgdir, va);
		page_remove(pgdir, va);
f0100fb6:	83 ec 08             	sub    $0x8,%esp
f0100fb9:	ff 75 10             	pushl  0x10(%ebp)
f0100fbc:	56                   	push   %esi
f0100fbd:	e8 7f ff ff ff       	call   f0100f41 <page_remove>
f0100fc2:	83 c4 10             	add    $0x10,%esp
	}
	*entry = (page2pa(pp) | perm | PTE_P);
f0100fc5:	2b 1d 6c 69 11 f0    	sub    0xf011696c,%ebx
f0100fcb:	c1 fb 03             	sar    $0x3,%ebx
f0100fce:	c1 e3 0c             	shl    $0xc,%ebx
f0100fd1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd4:	83 c8 01             	or     $0x1,%eax
f0100fd7:	09 c3                	or     %eax,%ebx
f0100fd9:	89 1f                	mov    %ebx,(%edi)
	pgdir[PDX(va)] |= perm;                  //Remember this step!
f0100fdb:	8b 45 10             	mov    0x10(%ebp),%eax
f0100fde:	c1 e8 16             	shr    $0x16,%eax
f0100fe1:	8b 55 14             	mov    0x14(%ebp),%edx
f0100fe4:	09 14 86             	or     %edx,(%esi,%eax,4)
        
    	return 0;
f0100fe7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fec:	eb 05                	jmp    f0100ff3 <page_insert+0x70>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *entry = NULL;
	entry =  pgdir_walk(pgdir, va, 1);    //Get the mapping page of this address va.
	if(entry == NULL) return -E_NO_MEM;
f0100fee:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}
	*entry = (page2pa(pp) | perm | PTE_P);
	pgdir[PDX(va)] |= perm;                  //Remember this step!
        
    	return 0;
}
f0100ff3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ff6:	5b                   	pop    %ebx
f0100ff7:	5e                   	pop    %esi
f0100ff8:	5f                   	pop    %edi
f0100ff9:	5d                   	pop    %ebp
f0100ffa:	c3                   	ret    

f0100ffb <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100ffb:	55                   	push   %ebp
f0100ffc:	89 e5                	mov    %esp,%ebp
f0100ffe:	57                   	push   %edi
f0100fff:	56                   	push   %esi
f0101000:	53                   	push   %ebx
f0101001:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101004:	6a 15                	push   $0x15
f0101006:	e8 82 16 00 00       	call   f010268d <mc146818_read>
f010100b:	89 c3                	mov    %eax,%ebx
f010100d:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101014:	e8 74 16 00 00       	call   f010268d <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101019:	c1 e0 08             	shl    $0x8,%eax
f010101c:	09 d8                	or     %ebx,%eax
f010101e:	c1 e0 0a             	shl    $0xa,%eax
f0101021:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101027:	85 c0                	test   %eax,%eax
f0101029:	0f 48 c2             	cmovs  %edx,%eax
f010102c:	c1 f8 0c             	sar    $0xc,%eax
f010102f:	a3 40 65 11 f0       	mov    %eax,0xf0116540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101034:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010103b:	e8 4d 16 00 00       	call   f010268d <mc146818_read>
f0101040:	89 c3                	mov    %eax,%ebx
f0101042:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101049:	e8 3f 16 00 00       	call   f010268d <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010104e:	c1 e0 08             	shl    $0x8,%eax
f0101051:	09 d8                	or     %ebx,%eax
f0101053:	c1 e0 0a             	shl    $0xa,%eax
f0101056:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010105c:	83 c4 10             	add    $0x10,%esp
f010105f:	85 c0                	test   %eax,%eax
f0101061:	0f 48 c2             	cmovs  %edx,%eax
f0101064:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101067:	85 c0                	test   %eax,%eax
f0101069:	74 0e                	je     f0101079 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010106b:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101071:	89 15 64 69 11 f0    	mov    %edx,0xf0116964
f0101077:	eb 0c                	jmp    f0101085 <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101079:	8b 15 40 65 11 f0    	mov    0xf0116540,%edx
f010107f:	89 15 64 69 11 f0    	mov    %edx,0xf0116964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101085:	c1 e0 0c             	shl    $0xc,%eax
f0101088:	c1 e8 0a             	shr    $0xa,%eax
f010108b:	50                   	push   %eax
f010108c:	a1 40 65 11 f0       	mov    0xf0116540,%eax
f0101091:	c1 e0 0c             	shl    $0xc,%eax
f0101094:	c1 e8 0a             	shr    $0xa,%eax
f0101097:	50                   	push   %eax
f0101098:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f010109d:	c1 e0 0c             	shl    $0xc,%eax
f01010a0:	c1 e8 0a             	shr    $0xa,%eax
f01010a3:	50                   	push   %eax
f01010a4:	68 e4 3f 10 f0       	push   $0xf0103fe4
f01010a9:	e8 46 16 00 00       	call   f01026f4 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010ae:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010b3:	e8 26 f8 ff ff       	call   f01008de <boot_alloc>
f01010b8:	a3 68 69 11 f0       	mov    %eax,0xf0116968
	memset(kern_pgdir, 0, PGSIZE);
f01010bd:	83 c4 0c             	add    $0xc,%esp
f01010c0:	68 00 10 00 00       	push   $0x1000
f01010c5:	6a 00                	push   $0x0
f01010c7:	50                   	push   %eax
f01010c8:	e8 72 21 00 00       	call   f010323f <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010cd:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010d2:	83 c4 10             	add    $0x10,%esp
f01010d5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010da:	77 15                	ja     f01010f1 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010dc:	50                   	push   %eax
f01010dd:	68 20 40 10 f0       	push   $0xf0104020
f01010e2:	68 8d 00 00 00       	push   $0x8d
f01010e7:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01010ec:	e8 9a ef ff ff       	call   f010008b <_panic>
f01010f1:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01010f7:	83 ca 05             	or     $0x5,%edx
f01010fa:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0101100:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0101105:	c1 e0 03             	shl    $0x3,%eax
f0101108:	e8 d1 f7 ff ff       	call   f01008de <boot_alloc>
f010110d:	a3 6c 69 11 f0       	mov    %eax,0xf011696c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101112:	83 ec 04             	sub    $0x4,%esp
f0101115:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f010111b:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101122:	52                   	push   %edx
f0101123:	6a 00                	push   $0x0
f0101125:	50                   	push   %eax
f0101126:	e8 14 21 00 00       	call   f010323f <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010112b:	e8 2e fb ff ff       	call   f0100c5e <page_init>

	check_page_free_list(1);
f0101130:	b8 01 00 00 00       	mov    $0x1,%eax
f0101135:	e8 70 f8 ff ff       	call   f01009aa <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010113a:	83 c4 10             	add    $0x10,%esp
f010113d:	83 3d 6c 69 11 f0 00 	cmpl   $0x0,0xf011696c
f0101144:	75 17                	jne    f010115d <mem_init+0x162>
		panic("'pages' is a null pointer!");
f0101146:	83 ec 04             	sub    $0x4,%esp
f0101149:	68 ae 3c 10 f0       	push   $0xf0103cae
f010114e:	68 66 02 00 00       	push   $0x266
f0101153:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101158:	e8 2e ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010115d:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101162:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101167:	eb 05                	jmp    f010116e <mem_init+0x173>
		++nfree;
f0101169:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010116c:	8b 00                	mov    (%eax),%eax
f010116e:	85 c0                	test   %eax,%eax
f0101170:	75 f7                	jne    f0101169 <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101172:	83 ec 0c             	sub    $0xc,%esp
f0101175:	6a 00                	push   $0x0
f0101177:	e8 8c fb ff ff       	call   f0100d08 <page_alloc>
f010117c:	89 c7                	mov    %eax,%edi
f010117e:	83 c4 10             	add    $0x10,%esp
f0101181:	85 c0                	test   %eax,%eax
f0101183:	75 19                	jne    f010119e <mem_init+0x1a3>
f0101185:	68 c9 3c 10 f0       	push   $0xf0103cc9
f010118a:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010118f:	68 6e 02 00 00       	push   $0x26e
f0101194:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101199:	e8 ed ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010119e:	83 ec 0c             	sub    $0xc,%esp
f01011a1:	6a 00                	push   $0x0
f01011a3:	e8 60 fb ff ff       	call   f0100d08 <page_alloc>
f01011a8:	89 c6                	mov    %eax,%esi
f01011aa:	83 c4 10             	add    $0x10,%esp
f01011ad:	85 c0                	test   %eax,%eax
f01011af:	75 19                	jne    f01011ca <mem_init+0x1cf>
f01011b1:	68 df 3c 10 f0       	push   $0xf0103cdf
f01011b6:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01011bb:	68 6f 02 00 00       	push   $0x26f
f01011c0:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01011c5:	e8 c1 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01011ca:	83 ec 0c             	sub    $0xc,%esp
f01011cd:	6a 00                	push   $0x0
f01011cf:	e8 34 fb ff ff       	call   f0100d08 <page_alloc>
f01011d4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01011d7:	83 c4 10             	add    $0x10,%esp
f01011da:	85 c0                	test   %eax,%eax
f01011dc:	75 19                	jne    f01011f7 <mem_init+0x1fc>
f01011de:	68 f5 3c 10 f0       	push   $0xf0103cf5
f01011e3:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01011e8:	68 70 02 00 00       	push   $0x270
f01011ed:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01011f2:	e8 94 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01011f7:	39 f7                	cmp    %esi,%edi
f01011f9:	75 19                	jne    f0101214 <mem_init+0x219>
f01011fb:	68 0b 3d 10 f0       	push   $0xf0103d0b
f0101200:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101205:	68 73 02 00 00       	push   $0x273
f010120a:	68 d4 3b 10 f0       	push   $0xf0103bd4
f010120f:	e8 77 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101214:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101217:	39 c6                	cmp    %eax,%esi
f0101219:	74 04                	je     f010121f <mem_init+0x224>
f010121b:	39 c7                	cmp    %eax,%edi
f010121d:	75 19                	jne    f0101238 <mem_init+0x23d>
f010121f:	68 44 40 10 f0       	push   $0xf0104044
f0101224:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101229:	68 74 02 00 00       	push   $0x274
f010122e:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101233:	e8 53 ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101238:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010123e:	8b 15 64 69 11 f0    	mov    0xf0116964,%edx
f0101244:	c1 e2 0c             	shl    $0xc,%edx
f0101247:	89 f8                	mov    %edi,%eax
f0101249:	29 c8                	sub    %ecx,%eax
f010124b:	c1 f8 03             	sar    $0x3,%eax
f010124e:	c1 e0 0c             	shl    $0xc,%eax
f0101251:	39 d0                	cmp    %edx,%eax
f0101253:	72 19                	jb     f010126e <mem_init+0x273>
f0101255:	68 1d 3d 10 f0       	push   $0xf0103d1d
f010125a:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010125f:	68 75 02 00 00       	push   $0x275
f0101264:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101269:	e8 1d ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010126e:	89 f0                	mov    %esi,%eax
f0101270:	29 c8                	sub    %ecx,%eax
f0101272:	c1 f8 03             	sar    $0x3,%eax
f0101275:	c1 e0 0c             	shl    $0xc,%eax
f0101278:	39 c2                	cmp    %eax,%edx
f010127a:	77 19                	ja     f0101295 <mem_init+0x29a>
f010127c:	68 3a 3d 10 f0       	push   $0xf0103d3a
f0101281:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101286:	68 76 02 00 00       	push   $0x276
f010128b:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101290:	e8 f6 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101295:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101298:	29 c8                	sub    %ecx,%eax
f010129a:	c1 f8 03             	sar    $0x3,%eax
f010129d:	c1 e0 0c             	shl    $0xc,%eax
f01012a0:	39 c2                	cmp    %eax,%edx
f01012a2:	77 19                	ja     f01012bd <mem_init+0x2c2>
f01012a4:	68 57 3d 10 f0       	push   $0xf0103d57
f01012a9:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01012ae:	68 77 02 00 00       	push   $0x277
f01012b3:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01012b8:	e8 ce ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012bd:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01012c2:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01012c5:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01012cc:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01012cf:	83 ec 0c             	sub    $0xc,%esp
f01012d2:	6a 00                	push   $0x0
f01012d4:	e8 2f fa ff ff       	call   f0100d08 <page_alloc>
f01012d9:	83 c4 10             	add    $0x10,%esp
f01012dc:	85 c0                	test   %eax,%eax
f01012de:	74 19                	je     f01012f9 <mem_init+0x2fe>
f01012e0:	68 74 3d 10 f0       	push   $0xf0103d74
f01012e5:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01012ea:	68 7e 02 00 00       	push   $0x27e
f01012ef:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01012f4:	e8 92 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01012f9:	83 ec 0c             	sub    $0xc,%esp
f01012fc:	57                   	push   %edi
f01012fd:	e8 76 fa ff ff       	call   f0100d78 <page_free>
	page_free(pp1);
f0101302:	89 34 24             	mov    %esi,(%esp)
f0101305:	e8 6e fa ff ff       	call   f0100d78 <page_free>
	page_free(pp2);
f010130a:	83 c4 04             	add    $0x4,%esp
f010130d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101310:	e8 63 fa ff ff       	call   f0100d78 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101315:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010131c:	e8 e7 f9 ff ff       	call   f0100d08 <page_alloc>
f0101321:	89 c6                	mov    %eax,%esi
f0101323:	83 c4 10             	add    $0x10,%esp
f0101326:	85 c0                	test   %eax,%eax
f0101328:	75 19                	jne    f0101343 <mem_init+0x348>
f010132a:	68 c9 3c 10 f0       	push   $0xf0103cc9
f010132f:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101334:	68 85 02 00 00       	push   $0x285
f0101339:	68 d4 3b 10 f0       	push   $0xf0103bd4
f010133e:	e8 48 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101343:	83 ec 0c             	sub    $0xc,%esp
f0101346:	6a 00                	push   $0x0
f0101348:	e8 bb f9 ff ff       	call   f0100d08 <page_alloc>
f010134d:	89 c7                	mov    %eax,%edi
f010134f:	83 c4 10             	add    $0x10,%esp
f0101352:	85 c0                	test   %eax,%eax
f0101354:	75 19                	jne    f010136f <mem_init+0x374>
f0101356:	68 df 3c 10 f0       	push   $0xf0103cdf
f010135b:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101360:	68 86 02 00 00       	push   $0x286
f0101365:	68 d4 3b 10 f0       	push   $0xf0103bd4
f010136a:	e8 1c ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010136f:	83 ec 0c             	sub    $0xc,%esp
f0101372:	6a 00                	push   $0x0
f0101374:	e8 8f f9 ff ff       	call   f0100d08 <page_alloc>
f0101379:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010137c:	83 c4 10             	add    $0x10,%esp
f010137f:	85 c0                	test   %eax,%eax
f0101381:	75 19                	jne    f010139c <mem_init+0x3a1>
f0101383:	68 f5 3c 10 f0       	push   $0xf0103cf5
f0101388:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010138d:	68 87 02 00 00       	push   $0x287
f0101392:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101397:	e8 ef ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010139c:	39 fe                	cmp    %edi,%esi
f010139e:	75 19                	jne    f01013b9 <mem_init+0x3be>
f01013a0:	68 0b 3d 10 f0       	push   $0xf0103d0b
f01013a5:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01013aa:	68 89 02 00 00       	push   $0x289
f01013af:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01013b4:	e8 d2 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013b9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013bc:	39 c7                	cmp    %eax,%edi
f01013be:	74 04                	je     f01013c4 <mem_init+0x3c9>
f01013c0:	39 c6                	cmp    %eax,%esi
f01013c2:	75 19                	jne    f01013dd <mem_init+0x3e2>
f01013c4:	68 44 40 10 f0       	push   $0xf0104044
f01013c9:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01013ce:	68 8a 02 00 00       	push   $0x28a
f01013d3:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01013d8:	e8 ae ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01013dd:	83 ec 0c             	sub    $0xc,%esp
f01013e0:	6a 00                	push   $0x0
f01013e2:	e8 21 f9 ff ff       	call   f0100d08 <page_alloc>
f01013e7:	83 c4 10             	add    $0x10,%esp
f01013ea:	85 c0                	test   %eax,%eax
f01013ec:	74 19                	je     f0101407 <mem_init+0x40c>
f01013ee:	68 74 3d 10 f0       	push   $0xf0103d74
f01013f3:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01013f8:	68 8b 02 00 00       	push   $0x28b
f01013fd:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101402:	e8 84 ec ff ff       	call   f010008b <_panic>
f0101407:	89 f0                	mov    %esi,%eax
f0101409:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010140f:	c1 f8 03             	sar    $0x3,%eax
f0101412:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101415:	89 c2                	mov    %eax,%edx
f0101417:	c1 ea 0c             	shr    $0xc,%edx
f010141a:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0101420:	72 12                	jb     f0101434 <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101422:	50                   	push   %eax
f0101423:	68 dc 3e 10 f0       	push   $0xf0103edc
f0101428:	6a 52                	push   $0x52
f010142a:	68 e0 3b 10 f0       	push   $0xf0103be0
f010142f:	e8 57 ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101434:	83 ec 04             	sub    $0x4,%esp
f0101437:	68 00 10 00 00       	push   $0x1000
f010143c:	6a 01                	push   $0x1
f010143e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101443:	50                   	push   %eax
f0101444:	e8 f6 1d 00 00       	call   f010323f <memset>
	page_free(pp0);
f0101449:	89 34 24             	mov    %esi,(%esp)
f010144c:	e8 27 f9 ff ff       	call   f0100d78 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101451:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101458:	e8 ab f8 ff ff       	call   f0100d08 <page_alloc>
f010145d:	83 c4 10             	add    $0x10,%esp
f0101460:	85 c0                	test   %eax,%eax
f0101462:	75 19                	jne    f010147d <mem_init+0x482>
f0101464:	68 83 3d 10 f0       	push   $0xf0103d83
f0101469:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010146e:	68 90 02 00 00       	push   $0x290
f0101473:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101478:	e8 0e ec ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f010147d:	39 c6                	cmp    %eax,%esi
f010147f:	74 19                	je     f010149a <mem_init+0x49f>
f0101481:	68 a1 3d 10 f0       	push   $0xf0103da1
f0101486:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010148b:	68 91 02 00 00       	push   $0x291
f0101490:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101495:	e8 f1 eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010149a:	89 f0                	mov    %esi,%eax
f010149c:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01014a2:	c1 f8 03             	sar    $0x3,%eax
f01014a5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014a8:	89 c2                	mov    %eax,%edx
f01014aa:	c1 ea 0c             	shr    $0xc,%edx
f01014ad:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01014b3:	72 12                	jb     f01014c7 <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014b5:	50                   	push   %eax
f01014b6:	68 dc 3e 10 f0       	push   $0xf0103edc
f01014bb:	6a 52                	push   $0x52
f01014bd:	68 e0 3b 10 f0       	push   $0xf0103be0
f01014c2:	e8 c4 eb ff ff       	call   f010008b <_panic>
f01014c7:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01014cd:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014d3:	80 38 00             	cmpb   $0x0,(%eax)
f01014d6:	74 19                	je     f01014f1 <mem_init+0x4f6>
f01014d8:	68 b1 3d 10 f0       	push   $0xf0103db1
f01014dd:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01014e2:	68 94 02 00 00       	push   $0x294
f01014e7:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01014ec:	e8 9a eb ff ff       	call   f010008b <_panic>
f01014f1:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01014f4:	39 d0                	cmp    %edx,%eax
f01014f6:	75 db                	jne    f01014d3 <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01014f8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014fb:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101500:	83 ec 0c             	sub    $0xc,%esp
f0101503:	56                   	push   %esi
f0101504:	e8 6f f8 ff ff       	call   f0100d78 <page_free>
	page_free(pp1);
f0101509:	89 3c 24             	mov    %edi,(%esp)
f010150c:	e8 67 f8 ff ff       	call   f0100d78 <page_free>
	page_free(pp2);
f0101511:	83 c4 04             	add    $0x4,%esp
f0101514:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101517:	e8 5c f8 ff ff       	call   f0100d78 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010151c:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101521:	83 c4 10             	add    $0x10,%esp
f0101524:	eb 05                	jmp    f010152b <mem_init+0x530>
		--nfree;
f0101526:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101529:	8b 00                	mov    (%eax),%eax
f010152b:	85 c0                	test   %eax,%eax
f010152d:	75 f7                	jne    f0101526 <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f010152f:	85 db                	test   %ebx,%ebx
f0101531:	74 19                	je     f010154c <mem_init+0x551>
f0101533:	68 bb 3d 10 f0       	push   $0xf0103dbb
f0101538:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010153d:	68 a1 02 00 00       	push   $0x2a1
f0101542:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101547:	e8 3f eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010154c:	83 ec 0c             	sub    $0xc,%esp
f010154f:	68 64 40 10 f0       	push   $0xf0104064
f0101554:	e8 9b 11 00 00       	call   f01026f4 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101559:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101560:	e8 a3 f7 ff ff       	call   f0100d08 <page_alloc>
f0101565:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101568:	83 c4 10             	add    $0x10,%esp
f010156b:	85 c0                	test   %eax,%eax
f010156d:	75 19                	jne    f0101588 <mem_init+0x58d>
f010156f:	68 c9 3c 10 f0       	push   $0xf0103cc9
f0101574:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101579:	68 fa 02 00 00       	push   $0x2fa
f010157e:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101583:	e8 03 eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101588:	83 ec 0c             	sub    $0xc,%esp
f010158b:	6a 00                	push   $0x0
f010158d:	e8 76 f7 ff ff       	call   f0100d08 <page_alloc>
f0101592:	89 c3                	mov    %eax,%ebx
f0101594:	83 c4 10             	add    $0x10,%esp
f0101597:	85 c0                	test   %eax,%eax
f0101599:	75 19                	jne    f01015b4 <mem_init+0x5b9>
f010159b:	68 df 3c 10 f0       	push   $0xf0103cdf
f01015a0:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01015a5:	68 fb 02 00 00       	push   $0x2fb
f01015aa:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01015af:	e8 d7 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01015b4:	83 ec 0c             	sub    $0xc,%esp
f01015b7:	6a 00                	push   $0x0
f01015b9:	e8 4a f7 ff ff       	call   f0100d08 <page_alloc>
f01015be:	89 c6                	mov    %eax,%esi
f01015c0:	83 c4 10             	add    $0x10,%esp
f01015c3:	85 c0                	test   %eax,%eax
f01015c5:	75 19                	jne    f01015e0 <mem_init+0x5e5>
f01015c7:	68 f5 3c 10 f0       	push   $0xf0103cf5
f01015cc:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01015d1:	68 fc 02 00 00       	push   $0x2fc
f01015d6:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01015db:	e8 ab ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015e0:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01015e3:	75 19                	jne    f01015fe <mem_init+0x603>
f01015e5:	68 0b 3d 10 f0       	push   $0xf0103d0b
f01015ea:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01015ef:	68 ff 02 00 00       	push   $0x2ff
f01015f4:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01015f9:	e8 8d ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015fe:	39 c3                	cmp    %eax,%ebx
f0101600:	74 05                	je     f0101607 <mem_init+0x60c>
f0101602:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101605:	75 19                	jne    f0101620 <mem_init+0x625>
f0101607:	68 44 40 10 f0       	push   $0xf0104044
f010160c:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101611:	68 00 03 00 00       	push   $0x300
f0101616:	68 d4 3b 10 f0       	push   $0xf0103bd4
f010161b:	e8 6b ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101620:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101625:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101628:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f010162f:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101632:	83 ec 0c             	sub    $0xc,%esp
f0101635:	6a 00                	push   $0x0
f0101637:	e8 cc f6 ff ff       	call   f0100d08 <page_alloc>
f010163c:	83 c4 10             	add    $0x10,%esp
f010163f:	85 c0                	test   %eax,%eax
f0101641:	74 19                	je     f010165c <mem_init+0x661>
f0101643:	68 74 3d 10 f0       	push   $0xf0103d74
f0101648:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010164d:	68 07 03 00 00       	push   $0x307
f0101652:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101657:	e8 2f ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010165c:	83 ec 04             	sub    $0x4,%esp
f010165f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101662:	50                   	push   %eax
f0101663:	6a 00                	push   $0x0
f0101665:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010166b:	e8 6a f8 ff ff       	call   f0100eda <page_lookup>
f0101670:	83 c4 10             	add    $0x10,%esp
f0101673:	85 c0                	test   %eax,%eax
f0101675:	74 19                	je     f0101690 <mem_init+0x695>
f0101677:	68 84 40 10 f0       	push   $0xf0104084
f010167c:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101681:	68 0a 03 00 00       	push   $0x30a
f0101686:	68 d4 3b 10 f0       	push   $0xf0103bd4
f010168b:	e8 fb e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101690:	6a 02                	push   $0x2
f0101692:	6a 00                	push   $0x0
f0101694:	53                   	push   %ebx
f0101695:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010169b:	e8 e3 f8 ff ff       	call   f0100f83 <page_insert>
f01016a0:	83 c4 10             	add    $0x10,%esp
f01016a3:	85 c0                	test   %eax,%eax
f01016a5:	78 19                	js     f01016c0 <mem_init+0x6c5>
f01016a7:	68 bc 40 10 f0       	push   $0xf01040bc
f01016ac:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01016b1:	68 0d 03 00 00       	push   $0x30d
f01016b6:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01016bb:	e8 cb e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01016c0:	83 ec 0c             	sub    $0xc,%esp
f01016c3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016c6:	e8 ad f6 ff ff       	call   f0100d78 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01016cb:	6a 02                	push   $0x2
f01016cd:	6a 00                	push   $0x0
f01016cf:	53                   	push   %ebx
f01016d0:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01016d6:	e8 a8 f8 ff ff       	call   f0100f83 <page_insert>
f01016db:	83 c4 20             	add    $0x20,%esp
f01016de:	85 c0                	test   %eax,%eax
f01016e0:	74 19                	je     f01016fb <mem_init+0x700>
f01016e2:	68 ec 40 10 f0       	push   $0xf01040ec
f01016e7:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01016ec:	68 11 03 00 00       	push   $0x311
f01016f1:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01016f6:	e8 90 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01016fb:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101701:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0101706:	89 c1                	mov    %eax,%ecx
f0101708:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010170b:	8b 17                	mov    (%edi),%edx
f010170d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101713:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101716:	29 c8                	sub    %ecx,%eax
f0101718:	c1 f8 03             	sar    $0x3,%eax
f010171b:	c1 e0 0c             	shl    $0xc,%eax
f010171e:	39 c2                	cmp    %eax,%edx
f0101720:	74 19                	je     f010173b <mem_init+0x740>
f0101722:	68 1c 41 10 f0       	push   $0xf010411c
f0101727:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010172c:	68 12 03 00 00       	push   $0x312
f0101731:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101736:	e8 50 e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010173b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101740:	89 f8                	mov    %edi,%eax
f0101742:	e8 ff f1 ff ff       	call   f0100946 <check_va2pa>
f0101747:	89 da                	mov    %ebx,%edx
f0101749:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010174c:	c1 fa 03             	sar    $0x3,%edx
f010174f:	c1 e2 0c             	shl    $0xc,%edx
f0101752:	39 d0                	cmp    %edx,%eax
f0101754:	74 19                	je     f010176f <mem_init+0x774>
f0101756:	68 44 41 10 f0       	push   $0xf0104144
f010175b:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101760:	68 13 03 00 00       	push   $0x313
f0101765:	68 d4 3b 10 f0       	push   $0xf0103bd4
f010176a:	e8 1c e9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f010176f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101774:	74 19                	je     f010178f <mem_init+0x794>
f0101776:	68 c6 3d 10 f0       	push   $0xf0103dc6
f010177b:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101780:	68 14 03 00 00       	push   $0x314
f0101785:	68 d4 3b 10 f0       	push   $0xf0103bd4
f010178a:	e8 fc e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f010178f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101792:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101797:	74 19                	je     f01017b2 <mem_init+0x7b7>
f0101799:	68 d7 3d 10 f0       	push   $0xf0103dd7
f010179e:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01017a3:	68 15 03 00 00       	push   $0x315
f01017a8:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01017ad:	e8 d9 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017b2:	6a 02                	push   $0x2
f01017b4:	68 00 10 00 00       	push   $0x1000
f01017b9:	56                   	push   %esi
f01017ba:	57                   	push   %edi
f01017bb:	e8 c3 f7 ff ff       	call   f0100f83 <page_insert>
f01017c0:	83 c4 10             	add    $0x10,%esp
f01017c3:	85 c0                	test   %eax,%eax
f01017c5:	74 19                	je     f01017e0 <mem_init+0x7e5>
f01017c7:	68 74 41 10 f0       	push   $0xf0104174
f01017cc:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01017d1:	68 18 03 00 00       	push   $0x318
f01017d6:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01017db:	e8 ab e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017e0:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017e5:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01017ea:	e8 57 f1 ff ff       	call   f0100946 <check_va2pa>
f01017ef:	89 f2                	mov    %esi,%edx
f01017f1:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01017f7:	c1 fa 03             	sar    $0x3,%edx
f01017fa:	c1 e2 0c             	shl    $0xc,%edx
f01017fd:	39 d0                	cmp    %edx,%eax
f01017ff:	74 19                	je     f010181a <mem_init+0x81f>
f0101801:	68 b0 41 10 f0       	push   $0xf01041b0
f0101806:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010180b:	68 19 03 00 00       	push   $0x319
f0101810:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101815:	e8 71 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010181a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010181f:	74 19                	je     f010183a <mem_init+0x83f>
f0101821:	68 e8 3d 10 f0       	push   $0xf0103de8
f0101826:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010182b:	68 1a 03 00 00       	push   $0x31a
f0101830:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101835:	e8 51 e8 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010183a:	83 ec 0c             	sub    $0xc,%esp
f010183d:	6a 00                	push   $0x0
f010183f:	e8 c4 f4 ff ff       	call   f0100d08 <page_alloc>
f0101844:	83 c4 10             	add    $0x10,%esp
f0101847:	85 c0                	test   %eax,%eax
f0101849:	74 19                	je     f0101864 <mem_init+0x869>
f010184b:	68 74 3d 10 f0       	push   $0xf0103d74
f0101850:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101855:	68 1d 03 00 00       	push   $0x31d
f010185a:	68 d4 3b 10 f0       	push   $0xf0103bd4
f010185f:	e8 27 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101864:	6a 02                	push   $0x2
f0101866:	68 00 10 00 00       	push   $0x1000
f010186b:	56                   	push   %esi
f010186c:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101872:	e8 0c f7 ff ff       	call   f0100f83 <page_insert>
f0101877:	83 c4 10             	add    $0x10,%esp
f010187a:	85 c0                	test   %eax,%eax
f010187c:	74 19                	je     f0101897 <mem_init+0x89c>
f010187e:	68 74 41 10 f0       	push   $0xf0104174
f0101883:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101888:	68 20 03 00 00       	push   $0x320
f010188d:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101892:	e8 f4 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101897:	ba 00 10 00 00       	mov    $0x1000,%edx
f010189c:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01018a1:	e8 a0 f0 ff ff       	call   f0100946 <check_va2pa>
f01018a6:	89 f2                	mov    %esi,%edx
f01018a8:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01018ae:	c1 fa 03             	sar    $0x3,%edx
f01018b1:	c1 e2 0c             	shl    $0xc,%edx
f01018b4:	39 d0                	cmp    %edx,%eax
f01018b6:	74 19                	je     f01018d1 <mem_init+0x8d6>
f01018b8:	68 b0 41 10 f0       	push   $0xf01041b0
f01018bd:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01018c2:	68 21 03 00 00       	push   $0x321
f01018c7:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01018cc:	e8 ba e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018d1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018d6:	74 19                	je     f01018f1 <mem_init+0x8f6>
f01018d8:	68 e8 3d 10 f0       	push   $0xf0103de8
f01018dd:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01018e2:	68 22 03 00 00       	push   $0x322
f01018e7:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01018ec:	e8 9a e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01018f1:	83 ec 0c             	sub    $0xc,%esp
f01018f4:	6a 00                	push   $0x0
f01018f6:	e8 0d f4 ff ff       	call   f0100d08 <page_alloc>
f01018fb:	83 c4 10             	add    $0x10,%esp
f01018fe:	85 c0                	test   %eax,%eax
f0101900:	74 19                	je     f010191b <mem_init+0x920>
f0101902:	68 74 3d 10 f0       	push   $0xf0103d74
f0101907:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010190c:	68 26 03 00 00       	push   $0x326
f0101911:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101916:	e8 70 e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010191b:	8b 15 68 69 11 f0    	mov    0xf0116968,%edx
f0101921:	8b 02                	mov    (%edx),%eax
f0101923:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101928:	89 c1                	mov    %eax,%ecx
f010192a:	c1 e9 0c             	shr    $0xc,%ecx
f010192d:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f0101933:	72 15                	jb     f010194a <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101935:	50                   	push   %eax
f0101936:	68 dc 3e 10 f0       	push   $0xf0103edc
f010193b:	68 29 03 00 00       	push   $0x329
f0101940:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101945:	e8 41 e7 ff ff       	call   f010008b <_panic>
f010194a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010194f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101952:	83 ec 04             	sub    $0x4,%esp
f0101955:	6a 00                	push   $0x0
f0101957:	68 00 10 00 00       	push   $0x1000
f010195c:	52                   	push   %edx
f010195d:	e8 93 f4 ff ff       	call   f0100df5 <pgdir_walk>
f0101962:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101965:	8d 51 04             	lea    0x4(%ecx),%edx
f0101968:	83 c4 10             	add    $0x10,%esp
f010196b:	39 d0                	cmp    %edx,%eax
f010196d:	74 19                	je     f0101988 <mem_init+0x98d>
f010196f:	68 e0 41 10 f0       	push   $0xf01041e0
f0101974:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101979:	68 2a 03 00 00       	push   $0x32a
f010197e:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101983:	e8 03 e7 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101988:	6a 06                	push   $0x6
f010198a:	68 00 10 00 00       	push   $0x1000
f010198f:	56                   	push   %esi
f0101990:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101996:	e8 e8 f5 ff ff       	call   f0100f83 <page_insert>
f010199b:	83 c4 10             	add    $0x10,%esp
f010199e:	85 c0                	test   %eax,%eax
f01019a0:	74 19                	je     f01019bb <mem_init+0x9c0>
f01019a2:	68 20 42 10 f0       	push   $0xf0104220
f01019a7:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01019ac:	68 2d 03 00 00       	push   $0x32d
f01019b1:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01019b6:	e8 d0 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019bb:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f01019c1:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019c6:	89 f8                	mov    %edi,%eax
f01019c8:	e8 79 ef ff ff       	call   f0100946 <check_va2pa>
f01019cd:	89 f2                	mov    %esi,%edx
f01019cf:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01019d5:	c1 fa 03             	sar    $0x3,%edx
f01019d8:	c1 e2 0c             	shl    $0xc,%edx
f01019db:	39 d0                	cmp    %edx,%eax
f01019dd:	74 19                	je     f01019f8 <mem_init+0x9fd>
f01019df:	68 b0 41 10 f0       	push   $0xf01041b0
f01019e4:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01019e9:	68 2e 03 00 00       	push   $0x32e
f01019ee:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01019f3:	e8 93 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01019f8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019fd:	74 19                	je     f0101a18 <mem_init+0xa1d>
f01019ff:	68 e8 3d 10 f0       	push   $0xf0103de8
f0101a04:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101a09:	68 2f 03 00 00       	push   $0x32f
f0101a0e:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101a13:	e8 73 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a18:	83 ec 04             	sub    $0x4,%esp
f0101a1b:	6a 00                	push   $0x0
f0101a1d:	68 00 10 00 00       	push   $0x1000
f0101a22:	57                   	push   %edi
f0101a23:	e8 cd f3 ff ff       	call   f0100df5 <pgdir_walk>
f0101a28:	83 c4 10             	add    $0x10,%esp
f0101a2b:	f6 00 04             	testb  $0x4,(%eax)
f0101a2e:	75 19                	jne    f0101a49 <mem_init+0xa4e>
f0101a30:	68 60 42 10 f0       	push   $0xf0104260
f0101a35:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101a3a:	68 30 03 00 00       	push   $0x330
f0101a3f:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101a44:	e8 42 e6 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a49:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101a4e:	f6 00 04             	testb  $0x4,(%eax)
f0101a51:	75 19                	jne    f0101a6c <mem_init+0xa71>
f0101a53:	68 f9 3d 10 f0       	push   $0xf0103df9
f0101a58:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101a5d:	68 31 03 00 00       	push   $0x331
f0101a62:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101a67:	e8 1f e6 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a6c:	6a 02                	push   $0x2
f0101a6e:	68 00 10 00 00       	push   $0x1000
f0101a73:	56                   	push   %esi
f0101a74:	50                   	push   %eax
f0101a75:	e8 09 f5 ff ff       	call   f0100f83 <page_insert>
f0101a7a:	83 c4 10             	add    $0x10,%esp
f0101a7d:	85 c0                	test   %eax,%eax
f0101a7f:	74 19                	je     f0101a9a <mem_init+0xa9f>
f0101a81:	68 74 41 10 f0       	push   $0xf0104174
f0101a86:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101a8b:	68 34 03 00 00       	push   $0x334
f0101a90:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101a95:	e8 f1 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101a9a:	83 ec 04             	sub    $0x4,%esp
f0101a9d:	6a 00                	push   $0x0
f0101a9f:	68 00 10 00 00       	push   $0x1000
f0101aa4:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101aaa:	e8 46 f3 ff ff       	call   f0100df5 <pgdir_walk>
f0101aaf:	83 c4 10             	add    $0x10,%esp
f0101ab2:	f6 00 02             	testb  $0x2,(%eax)
f0101ab5:	75 19                	jne    f0101ad0 <mem_init+0xad5>
f0101ab7:	68 94 42 10 f0       	push   $0xf0104294
f0101abc:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101ac1:	68 35 03 00 00       	push   $0x335
f0101ac6:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101acb:	e8 bb e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ad0:	83 ec 04             	sub    $0x4,%esp
f0101ad3:	6a 00                	push   $0x0
f0101ad5:	68 00 10 00 00       	push   $0x1000
f0101ada:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ae0:	e8 10 f3 ff ff       	call   f0100df5 <pgdir_walk>
f0101ae5:	83 c4 10             	add    $0x10,%esp
f0101ae8:	f6 00 04             	testb  $0x4,(%eax)
f0101aeb:	74 19                	je     f0101b06 <mem_init+0xb0b>
f0101aed:	68 c8 42 10 f0       	push   $0xf01042c8
f0101af2:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101af7:	68 36 03 00 00       	push   $0x336
f0101afc:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101b01:	e8 85 e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b06:	6a 02                	push   $0x2
f0101b08:	68 00 00 40 00       	push   $0x400000
f0101b0d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b10:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b16:	e8 68 f4 ff ff       	call   f0100f83 <page_insert>
f0101b1b:	83 c4 10             	add    $0x10,%esp
f0101b1e:	85 c0                	test   %eax,%eax
f0101b20:	78 19                	js     f0101b3b <mem_init+0xb40>
f0101b22:	68 00 43 10 f0       	push   $0xf0104300
f0101b27:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101b2c:	68 39 03 00 00       	push   $0x339
f0101b31:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101b36:	e8 50 e5 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b3b:	6a 02                	push   $0x2
f0101b3d:	68 00 10 00 00       	push   $0x1000
f0101b42:	53                   	push   %ebx
f0101b43:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b49:	e8 35 f4 ff ff       	call   f0100f83 <page_insert>
f0101b4e:	83 c4 10             	add    $0x10,%esp
f0101b51:	85 c0                	test   %eax,%eax
f0101b53:	74 19                	je     f0101b6e <mem_init+0xb73>
f0101b55:	68 38 43 10 f0       	push   $0xf0104338
f0101b5a:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101b5f:	68 3c 03 00 00       	push   $0x33c
f0101b64:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101b69:	e8 1d e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b6e:	83 ec 04             	sub    $0x4,%esp
f0101b71:	6a 00                	push   $0x0
f0101b73:	68 00 10 00 00       	push   $0x1000
f0101b78:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b7e:	e8 72 f2 ff ff       	call   f0100df5 <pgdir_walk>
f0101b83:	83 c4 10             	add    $0x10,%esp
f0101b86:	f6 00 04             	testb  $0x4,(%eax)
f0101b89:	74 19                	je     f0101ba4 <mem_init+0xba9>
f0101b8b:	68 c8 42 10 f0       	push   $0xf01042c8
f0101b90:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101b95:	68 3d 03 00 00       	push   $0x33d
f0101b9a:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101b9f:	e8 e7 e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ba4:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101baa:	ba 00 00 00 00       	mov    $0x0,%edx
f0101baf:	89 f8                	mov    %edi,%eax
f0101bb1:	e8 90 ed ff ff       	call   f0100946 <check_va2pa>
f0101bb6:	89 c1                	mov    %eax,%ecx
f0101bb8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101bbb:	89 d8                	mov    %ebx,%eax
f0101bbd:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101bc3:	c1 f8 03             	sar    $0x3,%eax
f0101bc6:	c1 e0 0c             	shl    $0xc,%eax
f0101bc9:	39 c1                	cmp    %eax,%ecx
f0101bcb:	74 19                	je     f0101be6 <mem_init+0xbeb>
f0101bcd:	68 74 43 10 f0       	push   $0xf0104374
f0101bd2:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101bd7:	68 40 03 00 00       	push   $0x340
f0101bdc:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101be1:	e8 a5 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101be6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101beb:	89 f8                	mov    %edi,%eax
f0101bed:	e8 54 ed ff ff       	call   f0100946 <check_va2pa>
f0101bf2:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101bf5:	74 19                	je     f0101c10 <mem_init+0xc15>
f0101bf7:	68 a0 43 10 f0       	push   $0xf01043a0
f0101bfc:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101c01:	68 41 03 00 00       	push   $0x341
f0101c06:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101c0b:	e8 7b e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c10:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c15:	74 19                	je     f0101c30 <mem_init+0xc35>
f0101c17:	68 0f 3e 10 f0       	push   $0xf0103e0f
f0101c1c:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101c21:	68 43 03 00 00       	push   $0x343
f0101c26:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101c2b:	e8 5b e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c30:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c35:	74 19                	je     f0101c50 <mem_init+0xc55>
f0101c37:	68 20 3e 10 f0       	push   $0xf0103e20
f0101c3c:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101c41:	68 44 03 00 00       	push   $0x344
f0101c46:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101c4b:	e8 3b e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c50:	83 ec 0c             	sub    $0xc,%esp
f0101c53:	6a 00                	push   $0x0
f0101c55:	e8 ae f0 ff ff       	call   f0100d08 <page_alloc>
f0101c5a:	83 c4 10             	add    $0x10,%esp
f0101c5d:	85 c0                	test   %eax,%eax
f0101c5f:	74 04                	je     f0101c65 <mem_init+0xc6a>
f0101c61:	39 c6                	cmp    %eax,%esi
f0101c63:	74 19                	je     f0101c7e <mem_init+0xc83>
f0101c65:	68 d0 43 10 f0       	push   $0xf01043d0
f0101c6a:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101c6f:	68 47 03 00 00       	push   $0x347
f0101c74:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101c79:	e8 0d e4 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101c7e:	83 ec 08             	sub    $0x8,%esp
f0101c81:	6a 00                	push   $0x0
f0101c83:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101c89:	e8 b3 f2 ff ff       	call   f0100f41 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101c8e:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101c94:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c99:	89 f8                	mov    %edi,%eax
f0101c9b:	e8 a6 ec ff ff       	call   f0100946 <check_va2pa>
f0101ca0:	83 c4 10             	add    $0x10,%esp
f0101ca3:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ca6:	74 19                	je     f0101cc1 <mem_init+0xcc6>
f0101ca8:	68 f4 43 10 f0       	push   $0xf01043f4
f0101cad:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101cb2:	68 4b 03 00 00       	push   $0x34b
f0101cb7:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101cbc:	e8 ca e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cc1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cc6:	89 f8                	mov    %edi,%eax
f0101cc8:	e8 79 ec ff ff       	call   f0100946 <check_va2pa>
f0101ccd:	89 da                	mov    %ebx,%edx
f0101ccf:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101cd5:	c1 fa 03             	sar    $0x3,%edx
f0101cd8:	c1 e2 0c             	shl    $0xc,%edx
f0101cdb:	39 d0                	cmp    %edx,%eax
f0101cdd:	74 19                	je     f0101cf8 <mem_init+0xcfd>
f0101cdf:	68 a0 43 10 f0       	push   $0xf01043a0
f0101ce4:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101ce9:	68 4c 03 00 00       	push   $0x34c
f0101cee:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101cf3:	e8 93 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101cf8:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101cfd:	74 19                	je     f0101d18 <mem_init+0xd1d>
f0101cff:	68 c6 3d 10 f0       	push   $0xf0103dc6
f0101d04:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101d09:	68 4d 03 00 00       	push   $0x34d
f0101d0e:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101d13:	e8 73 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d18:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d1d:	74 19                	je     f0101d38 <mem_init+0xd3d>
f0101d1f:	68 20 3e 10 f0       	push   $0xf0103e20
f0101d24:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101d29:	68 4e 03 00 00       	push   $0x34e
f0101d2e:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101d33:	e8 53 e3 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d38:	6a 00                	push   $0x0
f0101d3a:	68 00 10 00 00       	push   $0x1000
f0101d3f:	53                   	push   %ebx
f0101d40:	57                   	push   %edi
f0101d41:	e8 3d f2 ff ff       	call   f0100f83 <page_insert>
f0101d46:	83 c4 10             	add    $0x10,%esp
f0101d49:	85 c0                	test   %eax,%eax
f0101d4b:	74 19                	je     f0101d66 <mem_init+0xd6b>
f0101d4d:	68 18 44 10 f0       	push   $0xf0104418
f0101d52:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101d57:	68 51 03 00 00       	push   $0x351
f0101d5c:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101d61:	e8 25 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101d66:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d6b:	75 19                	jne    f0101d86 <mem_init+0xd8b>
f0101d6d:	68 31 3e 10 f0       	push   $0xf0103e31
f0101d72:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101d77:	68 52 03 00 00       	push   $0x352
f0101d7c:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101d81:	e8 05 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101d86:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101d89:	74 19                	je     f0101da4 <mem_init+0xda9>
f0101d8b:	68 3d 3e 10 f0       	push   $0xf0103e3d
f0101d90:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101d95:	68 53 03 00 00       	push   $0x353
f0101d9a:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101d9f:	e8 e7 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101da4:	83 ec 08             	sub    $0x8,%esp
f0101da7:	68 00 10 00 00       	push   $0x1000
f0101dac:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101db2:	e8 8a f1 ff ff       	call   f0100f41 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101db7:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101dbd:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dc2:	89 f8                	mov    %edi,%eax
f0101dc4:	e8 7d eb ff ff       	call   f0100946 <check_va2pa>
f0101dc9:	83 c4 10             	add    $0x10,%esp
f0101dcc:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dcf:	74 19                	je     f0101dea <mem_init+0xdef>
f0101dd1:	68 f4 43 10 f0       	push   $0xf01043f4
f0101dd6:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101ddb:	68 57 03 00 00       	push   $0x357
f0101de0:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101de5:	e8 a1 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101dea:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101def:	89 f8                	mov    %edi,%eax
f0101df1:	e8 50 eb ff ff       	call   f0100946 <check_va2pa>
f0101df6:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101df9:	74 19                	je     f0101e14 <mem_init+0xe19>
f0101dfb:	68 50 44 10 f0       	push   $0xf0104450
f0101e00:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101e05:	68 58 03 00 00       	push   $0x358
f0101e0a:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101e0f:	e8 77 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e14:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e19:	74 19                	je     f0101e34 <mem_init+0xe39>
f0101e1b:	68 52 3e 10 f0       	push   $0xf0103e52
f0101e20:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101e25:	68 59 03 00 00       	push   $0x359
f0101e2a:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101e2f:	e8 57 e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e34:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e39:	74 19                	je     f0101e54 <mem_init+0xe59>
f0101e3b:	68 20 3e 10 f0       	push   $0xf0103e20
f0101e40:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101e45:	68 5a 03 00 00       	push   $0x35a
f0101e4a:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101e4f:	e8 37 e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e54:	83 ec 0c             	sub    $0xc,%esp
f0101e57:	6a 00                	push   $0x0
f0101e59:	e8 aa ee ff ff       	call   f0100d08 <page_alloc>
f0101e5e:	83 c4 10             	add    $0x10,%esp
f0101e61:	39 c3                	cmp    %eax,%ebx
f0101e63:	75 04                	jne    f0101e69 <mem_init+0xe6e>
f0101e65:	85 c0                	test   %eax,%eax
f0101e67:	75 19                	jne    f0101e82 <mem_init+0xe87>
f0101e69:	68 78 44 10 f0       	push   $0xf0104478
f0101e6e:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101e73:	68 5d 03 00 00       	push   $0x35d
f0101e78:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101e7d:	e8 09 e2 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e82:	83 ec 0c             	sub    $0xc,%esp
f0101e85:	6a 00                	push   $0x0
f0101e87:	e8 7c ee ff ff       	call   f0100d08 <page_alloc>
f0101e8c:	83 c4 10             	add    $0x10,%esp
f0101e8f:	85 c0                	test   %eax,%eax
f0101e91:	74 19                	je     f0101eac <mem_init+0xeb1>
f0101e93:	68 74 3d 10 f0       	push   $0xf0103d74
f0101e98:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101e9d:	68 60 03 00 00       	push   $0x360
f0101ea2:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101ea7:	e8 df e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101eac:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0101eb2:	8b 11                	mov    (%ecx),%edx
f0101eb4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101eba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ebd:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101ec3:	c1 f8 03             	sar    $0x3,%eax
f0101ec6:	c1 e0 0c             	shl    $0xc,%eax
f0101ec9:	39 c2                	cmp    %eax,%edx
f0101ecb:	74 19                	je     f0101ee6 <mem_init+0xeeb>
f0101ecd:	68 1c 41 10 f0       	push   $0xf010411c
f0101ed2:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101ed7:	68 63 03 00 00       	push   $0x363
f0101edc:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101ee1:	e8 a5 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101ee6:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101eec:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eef:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ef4:	74 19                	je     f0101f0f <mem_init+0xf14>
f0101ef6:	68 d7 3d 10 f0       	push   $0xf0103dd7
f0101efb:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101f00:	68 65 03 00 00       	push   $0x365
f0101f05:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101f0a:	e8 7c e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f0f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f12:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f18:	83 ec 0c             	sub    $0xc,%esp
f0101f1b:	50                   	push   %eax
f0101f1c:	e8 57 ee ff ff       	call   f0100d78 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f21:	83 c4 0c             	add    $0xc,%esp
f0101f24:	6a 01                	push   $0x1
f0101f26:	68 00 10 40 00       	push   $0x401000
f0101f2b:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101f31:	e8 bf ee ff ff       	call   f0100df5 <pgdir_walk>
f0101f36:	89 c7                	mov    %eax,%edi
f0101f38:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f3b:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101f40:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f43:	8b 40 04             	mov    0x4(%eax),%eax
f0101f46:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f4b:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0101f51:	89 c2                	mov    %eax,%edx
f0101f53:	c1 ea 0c             	shr    $0xc,%edx
f0101f56:	83 c4 10             	add    $0x10,%esp
f0101f59:	39 ca                	cmp    %ecx,%edx
f0101f5b:	72 15                	jb     f0101f72 <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f5d:	50                   	push   %eax
f0101f5e:	68 dc 3e 10 f0       	push   $0xf0103edc
f0101f63:	68 6c 03 00 00       	push   $0x36c
f0101f68:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101f6d:	e8 19 e1 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f72:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f77:	39 c7                	cmp    %eax,%edi
f0101f79:	74 19                	je     f0101f94 <mem_init+0xf99>
f0101f7b:	68 63 3e 10 f0       	push   $0xf0103e63
f0101f80:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0101f85:	68 6d 03 00 00       	push   $0x36d
f0101f8a:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101f8f:	e8 f7 e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101f94:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f97:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101f9e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fa1:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fa7:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101fad:	c1 f8 03             	sar    $0x3,%eax
f0101fb0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fb3:	89 c2                	mov    %eax,%edx
f0101fb5:	c1 ea 0c             	shr    $0xc,%edx
f0101fb8:	39 d1                	cmp    %edx,%ecx
f0101fba:	77 12                	ja     f0101fce <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fbc:	50                   	push   %eax
f0101fbd:	68 dc 3e 10 f0       	push   $0xf0103edc
f0101fc2:	6a 52                	push   $0x52
f0101fc4:	68 e0 3b 10 f0       	push   $0xf0103be0
f0101fc9:	e8 bd e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101fce:	83 ec 04             	sub    $0x4,%esp
f0101fd1:	68 00 10 00 00       	push   $0x1000
f0101fd6:	68 ff 00 00 00       	push   $0xff
f0101fdb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101fe0:	50                   	push   %eax
f0101fe1:	e8 59 12 00 00       	call   f010323f <memset>
	page_free(pp0);
f0101fe6:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101fe9:	89 3c 24             	mov    %edi,(%esp)
f0101fec:	e8 87 ed ff ff       	call   f0100d78 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101ff1:	83 c4 0c             	add    $0xc,%esp
f0101ff4:	6a 01                	push   $0x1
f0101ff6:	6a 00                	push   $0x0
f0101ff8:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ffe:	e8 f2 ed ff ff       	call   f0100df5 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102003:	89 fa                	mov    %edi,%edx
f0102005:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f010200b:	c1 fa 03             	sar    $0x3,%edx
f010200e:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102011:	89 d0                	mov    %edx,%eax
f0102013:	c1 e8 0c             	shr    $0xc,%eax
f0102016:	83 c4 10             	add    $0x10,%esp
f0102019:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f010201f:	72 12                	jb     f0102033 <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102021:	52                   	push   %edx
f0102022:	68 dc 3e 10 f0       	push   $0xf0103edc
f0102027:	6a 52                	push   $0x52
f0102029:	68 e0 3b 10 f0       	push   $0xf0103be0
f010202e:	e8 58 e0 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0102033:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102039:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010203c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102042:	f6 00 01             	testb  $0x1,(%eax)
f0102045:	74 19                	je     f0102060 <mem_init+0x1065>
f0102047:	68 7b 3e 10 f0       	push   $0xf0103e7b
f010204c:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0102051:	68 77 03 00 00       	push   $0x377
f0102056:	68 d4 3b 10 f0       	push   $0xf0103bd4
f010205b:	e8 2b e0 ff ff       	call   f010008b <_panic>
f0102060:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102063:	39 d0                	cmp    %edx,%eax
f0102065:	75 db                	jne    f0102042 <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102067:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010206c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102072:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102075:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010207b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010207e:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f0102084:	83 ec 0c             	sub    $0xc,%esp
f0102087:	50                   	push   %eax
f0102088:	e8 eb ec ff ff       	call   f0100d78 <page_free>
	page_free(pp1);
f010208d:	89 1c 24             	mov    %ebx,(%esp)
f0102090:	e8 e3 ec ff ff       	call   f0100d78 <page_free>
	page_free(pp2);
f0102095:	89 34 24             	mov    %esi,(%esp)
f0102098:	e8 db ec ff ff       	call   f0100d78 <page_free>

	cprintf("check_page() succeeded!\n");
f010209d:	c7 04 24 92 3e 10 f0 	movl   $0xf0103e92,(%esp)
f01020a4:	e8 4b 06 00 00       	call   f01026f4 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01020a9:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020ae:	83 c4 10             	add    $0x10,%esp
f01020b1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020b6:	77 15                	ja     f01020cd <mem_init+0x10d2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020b8:	50                   	push   %eax
f01020b9:	68 20 40 10 f0       	push   $0xf0104020
f01020be:	68 af 00 00 00       	push   $0xaf
f01020c3:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01020c8:	e8 be df ff ff       	call   f010008b <_panic>
f01020cd:	83 ec 08             	sub    $0x8,%esp
f01020d0:	6a 04                	push   $0x4
f01020d2:	05 00 00 00 10       	add    $0x10000000,%eax
f01020d7:	50                   	push   %eax
f01020d8:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020dd:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01020e2:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01020e7:	e8 9c ed ff ff       	call   f0100e88 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020ec:	83 c4 10             	add    $0x10,%esp
f01020ef:	b8 00 c0 10 f0       	mov    $0xf010c000,%eax
f01020f4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020f9:	77 15                	ja     f0102110 <mem_init+0x1115>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020fb:	50                   	push   %eax
f01020fc:	68 20 40 10 f0       	push   $0xf0104020
f0102101:	68 bb 00 00 00       	push   $0xbb
f0102106:	68 d4 3b 10 f0       	push   $0xf0103bd4
f010210b:	e8 7b df ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102110:	83 ec 08             	sub    $0x8,%esp
f0102113:	6a 02                	push   $0x2
f0102115:	68 00 c0 10 00       	push   $0x10c000
f010211a:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010211f:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102124:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102129:	e8 5a ed ff ff       	call   f0100e88 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f010212e:	83 c4 08             	add    $0x8,%esp
f0102131:	6a 02                	push   $0x2
f0102133:	6a 00                	push   $0x0
f0102135:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010213a:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010213f:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102144:	e8 3f ed ff ff       	call   f0100e88 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102149:	8b 35 68 69 11 f0    	mov    0xf0116968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010214f:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0102154:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102157:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010215e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102163:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102166:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010216c:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010216f:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102172:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102177:	eb 55                	jmp    f01021ce <mem_init+0x11d3>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102179:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f010217f:	89 f0                	mov    %esi,%eax
f0102181:	e8 c0 e7 ff ff       	call   f0100946 <check_va2pa>
f0102186:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010218d:	77 15                	ja     f01021a4 <mem_init+0x11a9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010218f:	57                   	push   %edi
f0102190:	68 20 40 10 f0       	push   $0xf0104020
f0102195:	68 b9 02 00 00       	push   $0x2b9
f010219a:	68 d4 3b 10 f0       	push   $0xf0103bd4
f010219f:	e8 e7 de ff ff       	call   f010008b <_panic>
f01021a4:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01021ab:	39 c2                	cmp    %eax,%edx
f01021ad:	74 19                	je     f01021c8 <mem_init+0x11cd>
f01021af:	68 9c 44 10 f0       	push   $0xf010449c
f01021b4:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01021b9:	68 b9 02 00 00       	push   $0x2b9
f01021be:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01021c3:	e8 c3 de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021c8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01021ce:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01021d1:	77 a6                	ja     f0102179 <mem_init+0x117e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01021d3:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01021d6:	c1 e7 0c             	shl    $0xc,%edi
f01021d9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021de:	eb 30                	jmp    f0102210 <mem_init+0x1215>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01021e0:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01021e6:	89 f0                	mov    %esi,%eax
f01021e8:	e8 59 e7 ff ff       	call   f0100946 <check_va2pa>
f01021ed:	39 c3                	cmp    %eax,%ebx
f01021ef:	74 19                	je     f010220a <mem_init+0x120f>
f01021f1:	68 d0 44 10 f0       	push   $0xf01044d0
f01021f6:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01021fb:	68 be 02 00 00       	push   $0x2be
f0102200:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0102205:	e8 81 de ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010220a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102210:	39 fb                	cmp    %edi,%ebx
f0102212:	72 cc                	jb     f01021e0 <mem_init+0x11e5>
f0102214:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102219:	89 da                	mov    %ebx,%edx
f010221b:	89 f0                	mov    %esi,%eax
f010221d:	e8 24 e7 ff ff       	call   f0100946 <check_va2pa>
f0102222:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f0102228:	39 c2                	cmp    %eax,%edx
f010222a:	74 19                	je     f0102245 <mem_init+0x124a>
f010222c:	68 f8 44 10 f0       	push   $0xf01044f8
f0102231:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0102236:	68 c2 02 00 00       	push   $0x2c2
f010223b:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0102240:	e8 46 de ff ff       	call   f010008b <_panic>
f0102245:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010224b:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102251:	75 c6                	jne    f0102219 <mem_init+0x121e>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102253:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102258:	89 f0                	mov    %esi,%eax
f010225a:	e8 e7 e6 ff ff       	call   f0100946 <check_va2pa>
f010225f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102262:	74 51                	je     f01022b5 <mem_init+0x12ba>
f0102264:	68 40 45 10 f0       	push   $0xf0104540
f0102269:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010226e:	68 c3 02 00 00       	push   $0x2c3
f0102273:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0102278:	e8 0e de ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010227d:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102282:	72 36                	jb     f01022ba <mem_init+0x12bf>
f0102284:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102289:	76 07                	jbe    f0102292 <mem_init+0x1297>
f010228b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102290:	75 28                	jne    f01022ba <mem_init+0x12bf>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102292:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102296:	0f 85 83 00 00 00    	jne    f010231f <mem_init+0x1324>
f010229c:	68 ab 3e 10 f0       	push   $0xf0103eab
f01022a1:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01022a6:	68 cb 02 00 00       	push   $0x2cb
f01022ab:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01022b0:	e8 d6 dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022b5:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01022ba:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022bf:	76 3f                	jbe    f0102300 <mem_init+0x1305>
				assert(pgdir[i] & PTE_P);
f01022c1:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01022c4:	f6 c2 01             	test   $0x1,%dl
f01022c7:	75 19                	jne    f01022e2 <mem_init+0x12e7>
f01022c9:	68 ab 3e 10 f0       	push   $0xf0103eab
f01022ce:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01022d3:	68 cf 02 00 00       	push   $0x2cf
f01022d8:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01022dd:	e8 a9 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f01022e2:	f6 c2 02             	test   $0x2,%dl
f01022e5:	75 38                	jne    f010231f <mem_init+0x1324>
f01022e7:	68 bc 3e 10 f0       	push   $0xf0103ebc
f01022ec:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01022f1:	68 d0 02 00 00       	push   $0x2d0
f01022f6:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01022fb:	e8 8b dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102300:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102304:	74 19                	je     f010231f <mem_init+0x1324>
f0102306:	68 cd 3e 10 f0       	push   $0xf0103ecd
f010230b:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0102310:	68 d2 02 00 00       	push   $0x2d2
f0102315:	68 d4 3b 10 f0       	push   $0xf0103bd4
f010231a:	e8 6c dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010231f:	83 c0 01             	add    $0x1,%eax
f0102322:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102327:	0f 86 50 ff ff ff    	jbe    f010227d <mem_init+0x1282>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010232d:	83 ec 0c             	sub    $0xc,%esp
f0102330:	68 70 45 10 f0       	push   $0xf0104570
f0102335:	e8 ba 03 00 00       	call   f01026f4 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010233a:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010233f:	83 c4 10             	add    $0x10,%esp
f0102342:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102347:	77 15                	ja     f010235e <mem_init+0x1363>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102349:	50                   	push   %eax
f010234a:	68 20 40 10 f0       	push   $0xf0104020
f010234f:	68 cf 00 00 00       	push   $0xcf
f0102354:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0102359:	e8 2d dd ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010235e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102363:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102366:	b8 00 00 00 00       	mov    $0x0,%eax
f010236b:	e8 3a e6 ff ff       	call   f01009aa <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102370:	0f 20 c0             	mov    %cr0,%eax
f0102373:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102376:	0d 23 00 05 80       	or     $0x80050023,%eax
f010237b:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010237e:	83 ec 0c             	sub    $0xc,%esp
f0102381:	6a 00                	push   $0x0
f0102383:	e8 80 e9 ff ff       	call   f0100d08 <page_alloc>
f0102388:	89 c3                	mov    %eax,%ebx
f010238a:	83 c4 10             	add    $0x10,%esp
f010238d:	85 c0                	test   %eax,%eax
f010238f:	75 19                	jne    f01023aa <mem_init+0x13af>
f0102391:	68 c9 3c 10 f0       	push   $0xf0103cc9
f0102396:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010239b:	68 92 03 00 00       	push   $0x392
f01023a0:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01023a5:	e8 e1 dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01023aa:	83 ec 0c             	sub    $0xc,%esp
f01023ad:	6a 00                	push   $0x0
f01023af:	e8 54 e9 ff ff       	call   f0100d08 <page_alloc>
f01023b4:	89 c7                	mov    %eax,%edi
f01023b6:	83 c4 10             	add    $0x10,%esp
f01023b9:	85 c0                	test   %eax,%eax
f01023bb:	75 19                	jne    f01023d6 <mem_init+0x13db>
f01023bd:	68 df 3c 10 f0       	push   $0xf0103cdf
f01023c2:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01023c7:	68 93 03 00 00       	push   $0x393
f01023cc:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01023d1:	e8 b5 dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01023d6:	83 ec 0c             	sub    $0xc,%esp
f01023d9:	6a 00                	push   $0x0
f01023db:	e8 28 e9 ff ff       	call   f0100d08 <page_alloc>
f01023e0:	89 c6                	mov    %eax,%esi
f01023e2:	83 c4 10             	add    $0x10,%esp
f01023e5:	85 c0                	test   %eax,%eax
f01023e7:	75 19                	jne    f0102402 <mem_init+0x1407>
f01023e9:	68 f5 3c 10 f0       	push   $0xf0103cf5
f01023ee:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01023f3:	68 94 03 00 00       	push   $0x394
f01023f8:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01023fd:	e8 89 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102402:	83 ec 0c             	sub    $0xc,%esp
f0102405:	53                   	push   %ebx
f0102406:	e8 6d e9 ff ff       	call   f0100d78 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010240b:	89 f8                	mov    %edi,%eax
f010240d:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102413:	c1 f8 03             	sar    $0x3,%eax
f0102416:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102419:	89 c2                	mov    %eax,%edx
f010241b:	c1 ea 0c             	shr    $0xc,%edx
f010241e:	83 c4 10             	add    $0x10,%esp
f0102421:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102427:	72 12                	jb     f010243b <mem_init+0x1440>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102429:	50                   	push   %eax
f010242a:	68 dc 3e 10 f0       	push   $0xf0103edc
f010242f:	6a 52                	push   $0x52
f0102431:	68 e0 3b 10 f0       	push   $0xf0103be0
f0102436:	e8 50 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010243b:	83 ec 04             	sub    $0x4,%esp
f010243e:	68 00 10 00 00       	push   $0x1000
f0102443:	6a 01                	push   $0x1
f0102445:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010244a:	50                   	push   %eax
f010244b:	e8 ef 0d 00 00       	call   f010323f <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102450:	89 f0                	mov    %esi,%eax
f0102452:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102458:	c1 f8 03             	sar    $0x3,%eax
f010245b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010245e:	89 c2                	mov    %eax,%edx
f0102460:	c1 ea 0c             	shr    $0xc,%edx
f0102463:	83 c4 10             	add    $0x10,%esp
f0102466:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f010246c:	72 12                	jb     f0102480 <mem_init+0x1485>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010246e:	50                   	push   %eax
f010246f:	68 dc 3e 10 f0       	push   $0xf0103edc
f0102474:	6a 52                	push   $0x52
f0102476:	68 e0 3b 10 f0       	push   $0xf0103be0
f010247b:	e8 0b dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102480:	83 ec 04             	sub    $0x4,%esp
f0102483:	68 00 10 00 00       	push   $0x1000
f0102488:	6a 02                	push   $0x2
f010248a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010248f:	50                   	push   %eax
f0102490:	e8 aa 0d 00 00       	call   f010323f <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102495:	6a 02                	push   $0x2
f0102497:	68 00 10 00 00       	push   $0x1000
f010249c:	57                   	push   %edi
f010249d:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01024a3:	e8 db ea ff ff       	call   f0100f83 <page_insert>
	assert(pp1->pp_ref == 1);
f01024a8:	83 c4 20             	add    $0x20,%esp
f01024ab:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01024b0:	74 19                	je     f01024cb <mem_init+0x14d0>
f01024b2:	68 c6 3d 10 f0       	push   $0xf0103dc6
f01024b7:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01024bc:	68 99 03 00 00       	push   $0x399
f01024c1:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01024c6:	e8 c0 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01024cb:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01024d2:	01 01 01 
f01024d5:	74 19                	je     f01024f0 <mem_init+0x14f5>
f01024d7:	68 90 45 10 f0       	push   $0xf0104590
f01024dc:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01024e1:	68 9a 03 00 00       	push   $0x39a
f01024e6:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01024eb:	e8 9b db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01024f0:	6a 02                	push   $0x2
f01024f2:	68 00 10 00 00       	push   $0x1000
f01024f7:	56                   	push   %esi
f01024f8:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01024fe:	e8 80 ea ff ff       	call   f0100f83 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102503:	83 c4 10             	add    $0x10,%esp
f0102506:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010250d:	02 02 02 
f0102510:	74 19                	je     f010252b <mem_init+0x1530>
f0102512:	68 b4 45 10 f0       	push   $0xf01045b4
f0102517:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010251c:	68 9c 03 00 00       	push   $0x39c
f0102521:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0102526:	e8 60 db ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010252b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102530:	74 19                	je     f010254b <mem_init+0x1550>
f0102532:	68 e8 3d 10 f0       	push   $0xf0103de8
f0102537:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010253c:	68 9d 03 00 00       	push   $0x39d
f0102541:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0102546:	e8 40 db ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f010254b:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102550:	74 19                	je     f010256b <mem_init+0x1570>
f0102552:	68 52 3e 10 f0       	push   $0xf0103e52
f0102557:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010255c:	68 9e 03 00 00       	push   $0x39e
f0102561:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0102566:	e8 20 db ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010256b:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102572:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102575:	89 f0                	mov    %esi,%eax
f0102577:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010257d:	c1 f8 03             	sar    $0x3,%eax
f0102580:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102583:	89 c2                	mov    %eax,%edx
f0102585:	c1 ea 0c             	shr    $0xc,%edx
f0102588:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f010258e:	72 12                	jb     f01025a2 <mem_init+0x15a7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102590:	50                   	push   %eax
f0102591:	68 dc 3e 10 f0       	push   $0xf0103edc
f0102596:	6a 52                	push   $0x52
f0102598:	68 e0 3b 10 f0       	push   $0xf0103be0
f010259d:	e8 e9 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01025a2:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01025a9:	03 03 03 
f01025ac:	74 19                	je     f01025c7 <mem_init+0x15cc>
f01025ae:	68 d8 45 10 f0       	push   $0xf01045d8
f01025b3:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01025b8:	68 a0 03 00 00       	push   $0x3a0
f01025bd:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01025c2:	e8 c4 da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025c7:	83 ec 08             	sub    $0x8,%esp
f01025ca:	68 00 10 00 00       	push   $0x1000
f01025cf:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01025d5:	e8 67 e9 ff ff       	call   f0100f41 <page_remove>
	assert(pp2->pp_ref == 0);
f01025da:	83 c4 10             	add    $0x10,%esp
f01025dd:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025e2:	74 19                	je     f01025fd <mem_init+0x1602>
f01025e4:	68 20 3e 10 f0       	push   $0xf0103e20
f01025e9:	68 fa 3b 10 f0       	push   $0xf0103bfa
f01025ee:	68 a2 03 00 00       	push   $0x3a2
f01025f3:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01025f8:	e8 8e da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01025fd:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0102603:	8b 11                	mov    (%ecx),%edx
f0102605:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010260b:	89 d8                	mov    %ebx,%eax
f010260d:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102613:	c1 f8 03             	sar    $0x3,%eax
f0102616:	c1 e0 0c             	shl    $0xc,%eax
f0102619:	39 c2                	cmp    %eax,%edx
f010261b:	74 19                	je     f0102636 <mem_init+0x163b>
f010261d:	68 1c 41 10 f0       	push   $0xf010411c
f0102622:	68 fa 3b 10 f0       	push   $0xf0103bfa
f0102627:	68 a5 03 00 00       	push   $0x3a5
f010262c:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0102631:	e8 55 da ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0102636:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010263c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102641:	74 19                	je     f010265c <mem_init+0x1661>
f0102643:	68 d7 3d 10 f0       	push   $0xf0103dd7
f0102648:	68 fa 3b 10 f0       	push   $0xf0103bfa
f010264d:	68 a7 03 00 00       	push   $0x3a7
f0102652:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0102657:	e8 2f da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f010265c:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102662:	83 ec 0c             	sub    $0xc,%esp
f0102665:	53                   	push   %ebx
f0102666:	e8 0d e7 ff ff       	call   f0100d78 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010266b:	c7 04 24 04 46 10 f0 	movl   $0xf0104604,(%esp)
f0102672:	e8 7d 00 00 00       	call   f01026f4 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102677:	83 c4 10             	add    $0x10,%esp
f010267a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010267d:	5b                   	pop    %ebx
f010267e:	5e                   	pop    %esi
f010267f:	5f                   	pop    %edi
f0102680:	5d                   	pop    %ebp
f0102681:	c3                   	ret    

f0102682 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102682:	55                   	push   %ebp
f0102683:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102685:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102688:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010268b:	5d                   	pop    %ebp
f010268c:	c3                   	ret    

f010268d <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010268d:	55                   	push   %ebp
f010268e:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102690:	ba 70 00 00 00       	mov    $0x70,%edx
f0102695:	8b 45 08             	mov    0x8(%ebp),%eax
f0102698:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102699:	ba 71 00 00 00       	mov    $0x71,%edx
f010269e:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010269f:	0f b6 c0             	movzbl %al,%eax
}
f01026a2:	5d                   	pop    %ebp
f01026a3:	c3                   	ret    

f01026a4 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01026a4:	55                   	push   %ebp
f01026a5:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01026a7:	ba 70 00 00 00       	mov    $0x70,%edx
f01026ac:	8b 45 08             	mov    0x8(%ebp),%eax
f01026af:	ee                   	out    %al,(%dx)
f01026b0:	ba 71 00 00 00       	mov    $0x71,%edx
f01026b5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026b8:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01026b9:	5d                   	pop    %ebp
f01026ba:	c3                   	ret    

f01026bb <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01026bb:	55                   	push   %ebp
f01026bc:	89 e5                	mov    %esp,%ebp
f01026be:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01026c1:	ff 75 08             	pushl  0x8(%ebp)
f01026c4:	e8 29 df ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f01026c9:	83 c4 10             	add    $0x10,%esp
f01026cc:	c9                   	leave  
f01026cd:	c3                   	ret    

f01026ce <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01026ce:	55                   	push   %ebp
f01026cf:	89 e5                	mov    %esp,%ebp
f01026d1:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01026d4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01026db:	ff 75 0c             	pushl  0xc(%ebp)
f01026de:	ff 75 08             	pushl  0x8(%ebp)
f01026e1:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01026e4:	50                   	push   %eax
f01026e5:	68 bb 26 10 f0       	push   $0xf01026bb
f01026ea:	e8 37 04 00 00       	call   f0102b26 <vprintfmt>
	return cnt;
}
f01026ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01026f2:	c9                   	leave  
f01026f3:	c3                   	ret    

f01026f4 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01026f4:	55                   	push   %ebp
f01026f5:	89 e5                	mov    %esp,%ebp
f01026f7:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01026fa:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01026fd:	50                   	push   %eax
f01026fe:	ff 75 08             	pushl  0x8(%ebp)
f0102701:	e8 c8 ff ff ff       	call   f01026ce <vcprintf>
	va_end(ap);

	return cnt;
}
f0102706:	c9                   	leave  
f0102707:	c3                   	ret    

f0102708 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102708:	55                   	push   %ebp
f0102709:	89 e5                	mov    %esp,%ebp
f010270b:	57                   	push   %edi
f010270c:	56                   	push   %esi
f010270d:	53                   	push   %ebx
f010270e:	83 ec 14             	sub    $0x14,%esp
f0102711:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102714:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102717:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010271a:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010271d:	8b 1a                	mov    (%edx),%ebx
f010271f:	8b 01                	mov    (%ecx),%eax
f0102721:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102724:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010272b:	eb 7f                	jmp    f01027ac <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010272d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102730:	01 d8                	add    %ebx,%eax
f0102732:	89 c6                	mov    %eax,%esi
f0102734:	c1 ee 1f             	shr    $0x1f,%esi
f0102737:	01 c6                	add    %eax,%esi
f0102739:	d1 fe                	sar    %esi
f010273b:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010273e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102741:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0102744:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102746:	eb 03                	jmp    f010274b <stab_binsearch+0x43>
			m--;
f0102748:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010274b:	39 c3                	cmp    %eax,%ebx
f010274d:	7f 0d                	jg     f010275c <stab_binsearch+0x54>
f010274f:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102753:	83 ea 0c             	sub    $0xc,%edx
f0102756:	39 f9                	cmp    %edi,%ecx
f0102758:	75 ee                	jne    f0102748 <stab_binsearch+0x40>
f010275a:	eb 05                	jmp    f0102761 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010275c:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010275f:	eb 4b                	jmp    f01027ac <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102761:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102764:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102767:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010276b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010276e:	76 11                	jbe    f0102781 <stab_binsearch+0x79>
			*region_left = m;
f0102770:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102773:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102775:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102778:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010277f:	eb 2b                	jmp    f01027ac <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102781:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102784:	73 14                	jae    f010279a <stab_binsearch+0x92>
			*region_right = m - 1;
f0102786:	83 e8 01             	sub    $0x1,%eax
f0102789:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010278c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010278f:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102791:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102798:	eb 12                	jmp    f01027ac <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010279a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010279d:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010279f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01027a3:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027a5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01027ac:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01027af:	0f 8e 78 ff ff ff    	jle    f010272d <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01027b5:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01027b9:	75 0f                	jne    f01027ca <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01027bb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027be:	8b 00                	mov    (%eax),%eax
f01027c0:	83 e8 01             	sub    $0x1,%eax
f01027c3:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027c6:	89 06                	mov    %eax,(%esi)
f01027c8:	eb 2c                	jmp    f01027f6 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027ca:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027cd:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01027cf:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027d2:	8b 0e                	mov    (%esi),%ecx
f01027d4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027d7:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01027da:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027dd:	eb 03                	jmp    f01027e2 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01027df:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027e2:	39 c8                	cmp    %ecx,%eax
f01027e4:	7e 0b                	jle    f01027f1 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01027e6:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01027ea:	83 ea 0c             	sub    $0xc,%edx
f01027ed:	39 df                	cmp    %ebx,%edi
f01027ef:	75 ee                	jne    f01027df <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01027f1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027f4:	89 06                	mov    %eax,(%esi)
	}
}
f01027f6:	83 c4 14             	add    $0x14,%esp
f01027f9:	5b                   	pop    %ebx
f01027fa:	5e                   	pop    %esi
f01027fb:	5f                   	pop    %edi
f01027fc:	5d                   	pop    %ebp
f01027fd:	c3                   	ret    

f01027fe <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01027fe:	55                   	push   %ebp
f01027ff:	89 e5                	mov    %esp,%ebp
f0102801:	57                   	push   %edi
f0102802:	56                   	push   %esi
f0102803:	53                   	push   %ebx
f0102804:	83 ec 3c             	sub    $0x3c,%esp
f0102807:	8b 75 08             	mov    0x8(%ebp),%esi
f010280a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010280d:	c7 03 30 46 10 f0    	movl   $0xf0104630,(%ebx)
	info->eip_line = 0;
f0102813:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010281a:	c7 43 08 30 46 10 f0 	movl   $0xf0104630,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102821:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102828:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010282b:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102832:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102838:	76 11                	jbe    f010284b <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010283a:	b8 83 be 10 f0       	mov    $0xf010be83,%eax
f010283f:	3d cd a0 10 f0       	cmp    $0xf010a0cd,%eax
f0102844:	77 19                	ja     f010285f <debuginfo_eip+0x61>
f0102846:	e9 c9 01 00 00       	jmp    f0102a14 <debuginfo_eip+0x216>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f010284b:	83 ec 04             	sub    $0x4,%esp
f010284e:	68 3a 46 10 f0       	push   $0xf010463a
f0102853:	6a 7f                	push   $0x7f
f0102855:	68 47 46 10 f0       	push   $0xf0104647
f010285a:	e8 2c d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010285f:	80 3d 82 be 10 f0 00 	cmpb   $0x0,0xf010be82
f0102866:	0f 85 af 01 00 00    	jne    f0102a1b <debuginfo_eip+0x21d>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010286c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102873:	b8 cc a0 10 f0       	mov    $0xf010a0cc,%eax
f0102878:	2d 70 48 10 f0       	sub    $0xf0104870,%eax
f010287d:	c1 f8 02             	sar    $0x2,%eax
f0102880:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102886:	83 e8 01             	sub    $0x1,%eax
f0102889:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010288c:	83 ec 08             	sub    $0x8,%esp
f010288f:	56                   	push   %esi
f0102890:	6a 64                	push   $0x64
f0102892:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102895:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102898:	b8 70 48 10 f0       	mov    $0xf0104870,%eax
f010289d:	e8 66 fe ff ff       	call   f0102708 <stab_binsearch>
	if (lfile == 0)
f01028a2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01028a5:	83 c4 10             	add    $0x10,%esp
f01028a8:	85 c0                	test   %eax,%eax
f01028aa:	0f 84 72 01 00 00    	je     f0102a22 <debuginfo_eip+0x224>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01028b0:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01028b3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01028b6:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01028b9:	83 ec 08             	sub    $0x8,%esp
f01028bc:	56                   	push   %esi
f01028bd:	6a 24                	push   $0x24
f01028bf:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01028c2:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01028c5:	b8 70 48 10 f0       	mov    $0xf0104870,%eax
f01028ca:	e8 39 fe ff ff       	call   f0102708 <stab_binsearch>

	if (lfun <= rfun) {
f01028cf:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01028d2:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01028d5:	83 c4 10             	add    $0x10,%esp
f01028d8:	39 d0                	cmp    %edx,%eax
f01028da:	7f 40                	jg     f010291c <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01028dc:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01028df:	c1 e1 02             	shl    $0x2,%ecx
f01028e2:	8d b9 70 48 10 f0    	lea    -0xfefb790(%ecx),%edi
f01028e8:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01028eb:	8b b9 70 48 10 f0    	mov    -0xfefb790(%ecx),%edi
f01028f1:	b9 83 be 10 f0       	mov    $0xf010be83,%ecx
f01028f6:	81 e9 cd a0 10 f0    	sub    $0xf010a0cd,%ecx
f01028fc:	39 cf                	cmp    %ecx,%edi
f01028fe:	73 09                	jae    f0102909 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102900:	81 c7 cd a0 10 f0    	add    $0xf010a0cd,%edi
f0102906:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102909:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010290c:	8b 4f 08             	mov    0x8(%edi),%ecx
f010290f:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102912:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102914:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102917:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010291a:	eb 0f                	jmp    f010292b <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010291c:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010291f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102922:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102925:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102928:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010292b:	83 ec 08             	sub    $0x8,%esp
f010292e:	6a 3a                	push   $0x3a
f0102930:	ff 73 08             	pushl  0x8(%ebx)
f0102933:	e8 eb 08 00 00       	call   f0103223 <strfind>
f0102938:	2b 43 08             	sub    0x8(%ebx),%eax
f010293b:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	info->eip_file = stabstr + stabs[lfile].n_strx;
f010293e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102941:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102944:	8b 04 85 70 48 10 f0 	mov    -0xfefb790(,%eax,4),%eax
f010294b:	05 cd a0 10 f0       	add    $0xf010a0cd,%eax
f0102950:	89 03                	mov    %eax,(%ebx)

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102952:	83 c4 08             	add    $0x8,%esp
f0102955:	56                   	push   %esi
f0102956:	6a 44                	push   $0x44
f0102958:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010295b:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010295e:	b8 70 48 10 f0       	mov    $0xf0104870,%eax
f0102963:	e8 a0 fd ff ff       	call   f0102708 <stab_binsearch>
	if (lline > rline) {
f0102968:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010296b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010296e:	83 c4 10             	add    $0x10,%esp
f0102971:	39 d0                	cmp    %edx,%eax
f0102973:	0f 8f b0 00 00 00    	jg     f0102a29 <debuginfo_eip+0x22b>
	    return -1;
	} else {
	    info->eip_line = stabs[rline].n_desc;
f0102979:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010297c:	0f b7 14 95 76 48 10 	movzwl -0xfefb78a(,%edx,4),%edx
f0102983:	f0 
f0102984:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102987:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010298a:	89 c2                	mov    %eax,%edx
f010298c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010298f:	8d 04 85 70 48 10 f0 	lea    -0xfefb790(,%eax,4),%eax
f0102996:	eb 06                	jmp    f010299e <debuginfo_eip+0x1a0>
f0102998:	83 ea 01             	sub    $0x1,%edx
f010299b:	83 e8 0c             	sub    $0xc,%eax
f010299e:	39 d7                	cmp    %edx,%edi
f01029a0:	7f 34                	jg     f01029d6 <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f01029a2:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01029a6:	80 f9 84             	cmp    $0x84,%cl
f01029a9:	74 0b                	je     f01029b6 <debuginfo_eip+0x1b8>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01029ab:	80 f9 64             	cmp    $0x64,%cl
f01029ae:	75 e8                	jne    f0102998 <debuginfo_eip+0x19a>
f01029b0:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01029b4:	74 e2                	je     f0102998 <debuginfo_eip+0x19a>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01029b6:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01029b9:	8b 14 85 70 48 10 f0 	mov    -0xfefb790(,%eax,4),%edx
f01029c0:	b8 83 be 10 f0       	mov    $0xf010be83,%eax
f01029c5:	2d cd a0 10 f0       	sub    $0xf010a0cd,%eax
f01029ca:	39 c2                	cmp    %eax,%edx
f01029cc:	73 08                	jae    f01029d6 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01029ce:	81 c2 cd a0 10 f0    	add    $0xf010a0cd,%edx
f01029d4:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029d6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01029d9:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029dc:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029e1:	39 f2                	cmp    %esi,%edx
f01029e3:	7d 50                	jge    f0102a35 <debuginfo_eip+0x237>
		for (lline = lfun + 1;
f01029e5:	83 c2 01             	add    $0x1,%edx
f01029e8:	89 d0                	mov    %edx,%eax
f01029ea:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01029ed:	8d 14 95 70 48 10 f0 	lea    -0xfefb790(,%edx,4),%edx
f01029f4:	eb 04                	jmp    f01029fa <debuginfo_eip+0x1fc>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01029f6:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01029fa:	39 c6                	cmp    %eax,%esi
f01029fc:	7e 32                	jle    f0102a30 <debuginfo_eip+0x232>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01029fe:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102a02:	83 c0 01             	add    $0x1,%eax
f0102a05:	83 c2 0c             	add    $0xc,%edx
f0102a08:	80 f9 a0             	cmp    $0xa0,%cl
f0102a0b:	74 e9                	je     f01029f6 <debuginfo_eip+0x1f8>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a0d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a12:	eb 21                	jmp    f0102a35 <debuginfo_eip+0x237>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a14:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a19:	eb 1a                	jmp    f0102a35 <debuginfo_eip+0x237>
f0102a1b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a20:	eb 13                	jmp    f0102a35 <debuginfo_eip+0x237>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a22:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a27:	eb 0c                	jmp    f0102a35 <debuginfo_eip+0x237>
	// Your code here.
	info->eip_file = stabstr + stabs[lfile].n_strx;

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline > rline) {
	    return -1;
f0102a29:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a2e:	eb 05                	jmp    f0102a35 <debuginfo_eip+0x237>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a30:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a35:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a38:	5b                   	pop    %ebx
f0102a39:	5e                   	pop    %esi
f0102a3a:	5f                   	pop    %edi
f0102a3b:	5d                   	pop    %ebp
f0102a3c:	c3                   	ret    

f0102a3d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a3d:	55                   	push   %ebp
f0102a3e:	89 e5                	mov    %esp,%ebp
f0102a40:	57                   	push   %edi
f0102a41:	56                   	push   %esi
f0102a42:	53                   	push   %ebx
f0102a43:	83 ec 1c             	sub    $0x1c,%esp
f0102a46:	89 c7                	mov    %eax,%edi
f0102a48:	89 d6                	mov    %edx,%esi
f0102a4a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a4d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a50:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102a53:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102a56:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102a59:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a5e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102a61:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102a64:	39 d3                	cmp    %edx,%ebx
f0102a66:	72 05                	jb     f0102a6d <printnum+0x30>
f0102a68:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102a6b:	77 45                	ja     f0102ab2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102a6d:	83 ec 0c             	sub    $0xc,%esp
f0102a70:	ff 75 18             	pushl  0x18(%ebp)
f0102a73:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a76:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102a79:	53                   	push   %ebx
f0102a7a:	ff 75 10             	pushl  0x10(%ebp)
f0102a7d:	83 ec 08             	sub    $0x8,%esp
f0102a80:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a83:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a86:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a89:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a8c:	e8 bf 09 00 00       	call   f0103450 <__udivdi3>
f0102a91:	83 c4 18             	add    $0x18,%esp
f0102a94:	52                   	push   %edx
f0102a95:	50                   	push   %eax
f0102a96:	89 f2                	mov    %esi,%edx
f0102a98:	89 f8                	mov    %edi,%eax
f0102a9a:	e8 9e ff ff ff       	call   f0102a3d <printnum>
f0102a9f:	83 c4 20             	add    $0x20,%esp
f0102aa2:	eb 18                	jmp    f0102abc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102aa4:	83 ec 08             	sub    $0x8,%esp
f0102aa7:	56                   	push   %esi
f0102aa8:	ff 75 18             	pushl  0x18(%ebp)
f0102aab:	ff d7                	call   *%edi
f0102aad:	83 c4 10             	add    $0x10,%esp
f0102ab0:	eb 03                	jmp    f0102ab5 <printnum+0x78>
f0102ab2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102ab5:	83 eb 01             	sub    $0x1,%ebx
f0102ab8:	85 db                	test   %ebx,%ebx
f0102aba:	7f e8                	jg     f0102aa4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102abc:	83 ec 08             	sub    $0x8,%esp
f0102abf:	56                   	push   %esi
f0102ac0:	83 ec 04             	sub    $0x4,%esp
f0102ac3:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102ac6:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ac9:	ff 75 dc             	pushl  -0x24(%ebp)
f0102acc:	ff 75 d8             	pushl  -0x28(%ebp)
f0102acf:	e8 ac 0a 00 00       	call   f0103580 <__umoddi3>
f0102ad4:	83 c4 14             	add    $0x14,%esp
f0102ad7:	0f be 80 55 46 10 f0 	movsbl -0xfefb9ab(%eax),%eax
f0102ade:	50                   	push   %eax
f0102adf:	ff d7                	call   *%edi
}
f0102ae1:	83 c4 10             	add    $0x10,%esp
f0102ae4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ae7:	5b                   	pop    %ebx
f0102ae8:	5e                   	pop    %esi
f0102ae9:	5f                   	pop    %edi
f0102aea:	5d                   	pop    %ebp
f0102aeb:	c3                   	ret    

f0102aec <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102aec:	55                   	push   %ebp
f0102aed:	89 e5                	mov    %esp,%ebp
f0102aef:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102af2:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102af6:	8b 10                	mov    (%eax),%edx
f0102af8:	3b 50 04             	cmp    0x4(%eax),%edx
f0102afb:	73 0a                	jae    f0102b07 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102afd:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b00:	89 08                	mov    %ecx,(%eax)
f0102b02:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b05:	88 02                	mov    %al,(%edx)
}
f0102b07:	5d                   	pop    %ebp
f0102b08:	c3                   	ret    

f0102b09 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b09:	55                   	push   %ebp
f0102b0a:	89 e5                	mov    %esp,%ebp
f0102b0c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b0f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b12:	50                   	push   %eax
f0102b13:	ff 75 10             	pushl  0x10(%ebp)
f0102b16:	ff 75 0c             	pushl  0xc(%ebp)
f0102b19:	ff 75 08             	pushl  0x8(%ebp)
f0102b1c:	e8 05 00 00 00       	call   f0102b26 <vprintfmt>
	va_end(ap);
}
f0102b21:	83 c4 10             	add    $0x10,%esp
f0102b24:	c9                   	leave  
f0102b25:	c3                   	ret    

f0102b26 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102b26:	55                   	push   %ebp
f0102b27:	89 e5                	mov    %esp,%ebp
f0102b29:	57                   	push   %edi
f0102b2a:	56                   	push   %esi
f0102b2b:	53                   	push   %ebx
f0102b2c:	83 ec 2c             	sub    $0x2c,%esp
f0102b2f:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b32:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b35:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102b38:	eb 12                	jmp    f0102b4c <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102b3a:	85 c0                	test   %eax,%eax
f0102b3c:	0f 84 36 04 00 00    	je     f0102f78 <vprintfmt+0x452>
				return;
			putch(ch, putdat);
f0102b42:	83 ec 08             	sub    $0x8,%esp
f0102b45:	53                   	push   %ebx
f0102b46:	50                   	push   %eax
f0102b47:	ff d6                	call   *%esi
f0102b49:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102b4c:	83 c7 01             	add    $0x1,%edi
f0102b4f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102b53:	83 f8 25             	cmp    $0x25,%eax
f0102b56:	75 e2                	jne    f0102b3a <vprintfmt+0x14>
f0102b58:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102b5c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102b63:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b6a:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102b71:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102b76:	eb 07                	jmp    f0102b7f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b78:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102b7b:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b7f:	8d 47 01             	lea    0x1(%edi),%eax
f0102b82:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102b85:	0f b6 07             	movzbl (%edi),%eax
f0102b88:	0f b6 d0             	movzbl %al,%edx
f0102b8b:	83 e8 23             	sub    $0x23,%eax
f0102b8e:	3c 55                	cmp    $0x55,%al
f0102b90:	0f 87 c7 03 00 00    	ja     f0102f5d <vprintfmt+0x437>
f0102b96:	0f b6 c0             	movzbl %al,%eax
f0102b99:	ff 24 85 e0 46 10 f0 	jmp    *-0xfefb920(,%eax,4)
f0102ba0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102ba3:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102ba7:	eb d6                	jmp    f0102b7f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ba9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bac:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bb1:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102bb4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102bb7:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0102bbb:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102bbe:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102bc1:	83 f9 09             	cmp    $0x9,%ecx
f0102bc4:	77 3f                	ja     f0102c05 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102bc6:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102bc9:	eb e9                	jmp    f0102bb4 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102bcb:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bce:	8b 00                	mov    (%eax),%eax
f0102bd0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102bd3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bd6:	8d 40 04             	lea    0x4(%eax),%eax
f0102bd9:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bdc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102bdf:	eb 2a                	jmp    f0102c0b <vprintfmt+0xe5>
f0102be1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102be4:	85 c0                	test   %eax,%eax
f0102be6:	ba 00 00 00 00       	mov    $0x0,%edx
f0102beb:	0f 49 d0             	cmovns %eax,%edx
f0102bee:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bf1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bf4:	eb 89                	jmp    f0102b7f <vprintfmt+0x59>
f0102bf6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102bf9:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c00:	e9 7a ff ff ff       	jmp    f0102b7f <vprintfmt+0x59>
f0102c05:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102c08:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c0b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c0f:	0f 89 6a ff ff ff    	jns    f0102b7f <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c15:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c18:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c1b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c22:	e9 58 ff ff ff       	jmp    f0102b7f <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102c27:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c2a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102c2d:	e9 4d ff ff ff       	jmp    f0102b7f <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c32:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c35:	8d 78 04             	lea    0x4(%eax),%edi
f0102c38:	83 ec 08             	sub    $0x8,%esp
f0102c3b:	53                   	push   %ebx
f0102c3c:	ff 30                	pushl  (%eax)
f0102c3e:	ff d6                	call   *%esi
			break;
f0102c40:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c43:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c46:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102c49:	e9 fe fe ff ff       	jmp    f0102b4c <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c4e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c51:	8d 78 04             	lea    0x4(%eax),%edi
f0102c54:	8b 00                	mov    (%eax),%eax
f0102c56:	99                   	cltd   
f0102c57:	31 d0                	xor    %edx,%eax
f0102c59:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102c5b:	83 f8 07             	cmp    $0x7,%eax
f0102c5e:	7f 0b                	jg     f0102c6b <vprintfmt+0x145>
f0102c60:	8b 14 85 40 48 10 f0 	mov    -0xfefb7c0(,%eax,4),%edx
f0102c67:	85 d2                	test   %edx,%edx
f0102c69:	75 1b                	jne    f0102c86 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102c6b:	50                   	push   %eax
f0102c6c:	68 6d 46 10 f0       	push   $0xf010466d
f0102c71:	53                   	push   %ebx
f0102c72:	56                   	push   %esi
f0102c73:	e8 91 fe ff ff       	call   f0102b09 <printfmt>
f0102c78:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c7b:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c7e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102c81:	e9 c6 fe ff ff       	jmp    f0102b4c <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102c86:	52                   	push   %edx
f0102c87:	68 0c 3c 10 f0       	push   $0xf0103c0c
f0102c8c:	53                   	push   %ebx
f0102c8d:	56                   	push   %esi
f0102c8e:	e8 76 fe ff ff       	call   f0102b09 <printfmt>
f0102c93:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c96:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c99:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c9c:	e9 ab fe ff ff       	jmp    f0102b4c <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102ca1:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ca4:	83 c0 04             	add    $0x4,%eax
f0102ca7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102caa:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cad:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102caf:	85 ff                	test   %edi,%edi
f0102cb1:	b8 66 46 10 f0       	mov    $0xf0104666,%eax
f0102cb6:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102cb9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102cbd:	0f 8e 94 00 00 00    	jle    f0102d57 <vprintfmt+0x231>
f0102cc3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102cc7:	0f 84 98 00 00 00    	je     f0102d65 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102ccd:	83 ec 08             	sub    $0x8,%esp
f0102cd0:	ff 75 d0             	pushl  -0x30(%ebp)
f0102cd3:	57                   	push   %edi
f0102cd4:	e8 00 04 00 00       	call   f01030d9 <strnlen>
f0102cd9:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102cdc:	29 c1                	sub    %eax,%ecx
f0102cde:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102ce1:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102ce4:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102ce8:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102ceb:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102cee:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cf0:	eb 0f                	jmp    f0102d01 <vprintfmt+0x1db>
					putch(padc, putdat);
f0102cf2:	83 ec 08             	sub    $0x8,%esp
f0102cf5:	53                   	push   %ebx
f0102cf6:	ff 75 e0             	pushl  -0x20(%ebp)
f0102cf9:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cfb:	83 ef 01             	sub    $0x1,%edi
f0102cfe:	83 c4 10             	add    $0x10,%esp
f0102d01:	85 ff                	test   %edi,%edi
f0102d03:	7f ed                	jg     f0102cf2 <vprintfmt+0x1cc>
f0102d05:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d08:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102d0b:	85 c9                	test   %ecx,%ecx
f0102d0d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d12:	0f 49 c1             	cmovns %ecx,%eax
f0102d15:	29 c1                	sub    %eax,%ecx
f0102d17:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d1a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d1d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d20:	89 cb                	mov    %ecx,%ebx
f0102d22:	eb 4d                	jmp    f0102d71 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102d24:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102d28:	74 1b                	je     f0102d45 <vprintfmt+0x21f>
f0102d2a:	0f be c0             	movsbl %al,%eax
f0102d2d:	83 e8 20             	sub    $0x20,%eax
f0102d30:	83 f8 5e             	cmp    $0x5e,%eax
f0102d33:	76 10                	jbe    f0102d45 <vprintfmt+0x21f>
					putch('?', putdat);
f0102d35:	83 ec 08             	sub    $0x8,%esp
f0102d38:	ff 75 0c             	pushl  0xc(%ebp)
f0102d3b:	6a 3f                	push   $0x3f
f0102d3d:	ff 55 08             	call   *0x8(%ebp)
f0102d40:	83 c4 10             	add    $0x10,%esp
f0102d43:	eb 0d                	jmp    f0102d52 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102d45:	83 ec 08             	sub    $0x8,%esp
f0102d48:	ff 75 0c             	pushl  0xc(%ebp)
f0102d4b:	52                   	push   %edx
f0102d4c:	ff 55 08             	call   *0x8(%ebp)
f0102d4f:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102d52:	83 eb 01             	sub    $0x1,%ebx
f0102d55:	eb 1a                	jmp    f0102d71 <vprintfmt+0x24b>
f0102d57:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d5a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d5d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d60:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d63:	eb 0c                	jmp    f0102d71 <vprintfmt+0x24b>
f0102d65:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d68:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d6b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d6e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d71:	83 c7 01             	add    $0x1,%edi
f0102d74:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102d78:	0f be d0             	movsbl %al,%edx
f0102d7b:	85 d2                	test   %edx,%edx
f0102d7d:	74 23                	je     f0102da2 <vprintfmt+0x27c>
f0102d7f:	85 f6                	test   %esi,%esi
f0102d81:	78 a1                	js     f0102d24 <vprintfmt+0x1fe>
f0102d83:	83 ee 01             	sub    $0x1,%esi
f0102d86:	79 9c                	jns    f0102d24 <vprintfmt+0x1fe>
f0102d88:	89 df                	mov    %ebx,%edi
f0102d8a:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d8d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d90:	eb 18                	jmp    f0102daa <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102d92:	83 ec 08             	sub    $0x8,%esp
f0102d95:	53                   	push   %ebx
f0102d96:	6a 20                	push   $0x20
f0102d98:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102d9a:	83 ef 01             	sub    $0x1,%edi
f0102d9d:	83 c4 10             	add    $0x10,%esp
f0102da0:	eb 08                	jmp    f0102daa <vprintfmt+0x284>
f0102da2:	89 df                	mov    %ebx,%edi
f0102da4:	8b 75 08             	mov    0x8(%ebp),%esi
f0102da7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102daa:	85 ff                	test   %edi,%edi
f0102dac:	7f e4                	jg     f0102d92 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102dae:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102db1:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102db4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102db7:	e9 90 fd ff ff       	jmp    f0102b4c <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102dbc:	83 f9 01             	cmp    $0x1,%ecx
f0102dbf:	7e 19                	jle    f0102dda <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102dc1:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dc4:	8b 50 04             	mov    0x4(%eax),%edx
f0102dc7:	8b 00                	mov    (%eax),%eax
f0102dc9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102dcc:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102dcf:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dd2:	8d 40 08             	lea    0x8(%eax),%eax
f0102dd5:	89 45 14             	mov    %eax,0x14(%ebp)
f0102dd8:	eb 38                	jmp    f0102e12 <vprintfmt+0x2ec>
	else if (lflag)
f0102dda:	85 c9                	test   %ecx,%ecx
f0102ddc:	74 1b                	je     f0102df9 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102dde:	8b 45 14             	mov    0x14(%ebp),%eax
f0102de1:	8b 00                	mov    (%eax),%eax
f0102de3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102de6:	89 c1                	mov    %eax,%ecx
f0102de8:	c1 f9 1f             	sar    $0x1f,%ecx
f0102deb:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102dee:	8b 45 14             	mov    0x14(%ebp),%eax
f0102df1:	8d 40 04             	lea    0x4(%eax),%eax
f0102df4:	89 45 14             	mov    %eax,0x14(%ebp)
f0102df7:	eb 19                	jmp    f0102e12 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102df9:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dfc:	8b 00                	mov    (%eax),%eax
f0102dfe:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e01:	89 c1                	mov    %eax,%ecx
f0102e03:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e06:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e09:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e0c:	8d 40 04             	lea    0x4(%eax),%eax
f0102e0f:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e12:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e15:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e18:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e1d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e21:	0f 89 02 01 00 00    	jns    f0102f29 <vprintfmt+0x403>
				putch('-', putdat);
f0102e27:	83 ec 08             	sub    $0x8,%esp
f0102e2a:	53                   	push   %ebx
f0102e2b:	6a 2d                	push   $0x2d
f0102e2d:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e2f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e32:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102e35:	f7 da                	neg    %edx
f0102e37:	83 d1 00             	adc    $0x0,%ecx
f0102e3a:	f7 d9                	neg    %ecx
f0102e3c:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102e3f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102e44:	e9 e0 00 00 00       	jmp    f0102f29 <vprintfmt+0x403>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e49:	83 f9 01             	cmp    $0x1,%ecx
f0102e4c:	7e 18                	jle    f0102e66 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102e4e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e51:	8b 10                	mov    (%eax),%edx
f0102e53:	8b 48 04             	mov    0x4(%eax),%ecx
f0102e56:	8d 40 08             	lea    0x8(%eax),%eax
f0102e59:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102e5c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102e61:	e9 c3 00 00 00       	jmp    f0102f29 <vprintfmt+0x403>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102e66:	85 c9                	test   %ecx,%ecx
f0102e68:	74 1a                	je     f0102e84 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0102e6a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e6d:	8b 10                	mov    (%eax),%edx
f0102e6f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102e74:	8d 40 04             	lea    0x4(%eax),%eax
f0102e77:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102e7a:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102e7f:	e9 a5 00 00 00       	jmp    f0102f29 <vprintfmt+0x403>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102e84:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e87:	8b 10                	mov    (%eax),%edx
f0102e89:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102e8e:	8d 40 04             	lea    0x4(%eax),%eax
f0102e91:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102e94:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102e99:	e9 8b 00 00 00       	jmp    f0102f29 <vprintfmt+0x403>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			//putch('0', putdat);
			num = (unsigned long long)
f0102e9e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ea1:	8b 10                	mov    (%eax),%edx
f0102ea3:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
f0102ea8:	8d 40 04             	lea    0x4(%eax),%eax
f0102eab:	89 45 14             	mov    %eax,0x14(%ebp)
			base=8;
f0102eae:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0102eb3:	eb 74                	jmp    f0102f29 <vprintfmt+0x403>

		// pointer
		case 'p':
			putch('0', putdat);
f0102eb5:	83 ec 08             	sub    $0x8,%esp
f0102eb8:	53                   	push   %ebx
f0102eb9:	6a 30                	push   $0x30
f0102ebb:	ff d6                	call   *%esi
			putch('x', putdat);
f0102ebd:	83 c4 08             	add    $0x8,%esp
f0102ec0:	53                   	push   %ebx
f0102ec1:	6a 78                	push   $0x78
f0102ec3:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102ec5:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ec8:	8b 10                	mov    (%eax),%edx
f0102eca:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102ecf:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102ed2:	8d 40 04             	lea    0x4(%eax),%eax
f0102ed5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102ed8:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0102edd:	eb 4a                	jmp    f0102f29 <vprintfmt+0x403>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102edf:	83 f9 01             	cmp    $0x1,%ecx
f0102ee2:	7e 15                	jle    f0102ef9 <vprintfmt+0x3d3>
		return va_arg(*ap, unsigned long long);
f0102ee4:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ee7:	8b 10                	mov    (%eax),%edx
f0102ee9:	8b 48 04             	mov    0x4(%eax),%ecx
f0102eec:	8d 40 08             	lea    0x8(%eax),%eax
f0102eef:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102ef2:	b8 10 00 00 00       	mov    $0x10,%eax
f0102ef7:	eb 30                	jmp    f0102f29 <vprintfmt+0x403>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102ef9:	85 c9                	test   %ecx,%ecx
f0102efb:	74 17                	je     f0102f14 <vprintfmt+0x3ee>
		return va_arg(*ap, unsigned long);
f0102efd:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f00:	8b 10                	mov    (%eax),%edx
f0102f02:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f07:	8d 40 04             	lea    0x4(%eax),%eax
f0102f0a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f0d:	b8 10 00 00 00       	mov    $0x10,%eax
f0102f12:	eb 15                	jmp    f0102f29 <vprintfmt+0x403>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102f14:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f17:	8b 10                	mov    (%eax),%edx
f0102f19:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f1e:	8d 40 04             	lea    0x4(%eax),%eax
f0102f21:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102f24:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102f29:	83 ec 0c             	sub    $0xc,%esp
f0102f2c:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102f30:	57                   	push   %edi
f0102f31:	ff 75 e0             	pushl  -0x20(%ebp)
f0102f34:	50                   	push   %eax
f0102f35:	51                   	push   %ecx
f0102f36:	52                   	push   %edx
f0102f37:	89 da                	mov    %ebx,%edx
f0102f39:	89 f0                	mov    %esi,%eax
f0102f3b:	e8 fd fa ff ff       	call   f0102a3d <printnum>
			break;
f0102f40:	83 c4 20             	add    $0x20,%esp
f0102f43:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f46:	e9 01 fc ff ff       	jmp    f0102b4c <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102f4b:	83 ec 08             	sub    $0x8,%esp
f0102f4e:	53                   	push   %ebx
f0102f4f:	52                   	push   %edx
f0102f50:	ff d6                	call   *%esi
			break;
f0102f52:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102f55:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102f58:	e9 ef fb ff ff       	jmp    f0102b4c <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102f5d:	83 ec 08             	sub    $0x8,%esp
f0102f60:	53                   	push   %ebx
f0102f61:	6a 25                	push   $0x25
f0102f63:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102f65:	83 c4 10             	add    $0x10,%esp
f0102f68:	eb 03                	jmp    f0102f6d <vprintfmt+0x447>
f0102f6a:	83 ef 01             	sub    $0x1,%edi
f0102f6d:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102f71:	75 f7                	jne    f0102f6a <vprintfmt+0x444>
f0102f73:	e9 d4 fb ff ff       	jmp    f0102b4c <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102f78:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f7b:	5b                   	pop    %ebx
f0102f7c:	5e                   	pop    %esi
f0102f7d:	5f                   	pop    %edi
f0102f7e:	5d                   	pop    %ebp
f0102f7f:	c3                   	ret    

f0102f80 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102f80:	55                   	push   %ebp
f0102f81:	89 e5                	mov    %esp,%ebp
f0102f83:	83 ec 18             	sub    $0x18,%esp
f0102f86:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f89:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102f8c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f8f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102f93:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f96:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102f9d:	85 c0                	test   %eax,%eax
f0102f9f:	74 26                	je     f0102fc7 <vsnprintf+0x47>
f0102fa1:	85 d2                	test   %edx,%edx
f0102fa3:	7e 22                	jle    f0102fc7 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102fa5:	ff 75 14             	pushl  0x14(%ebp)
f0102fa8:	ff 75 10             	pushl  0x10(%ebp)
f0102fab:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102fae:	50                   	push   %eax
f0102faf:	68 ec 2a 10 f0       	push   $0xf0102aec
f0102fb4:	e8 6d fb ff ff       	call   f0102b26 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102fb9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102fbc:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102fbf:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102fc2:	83 c4 10             	add    $0x10,%esp
f0102fc5:	eb 05                	jmp    f0102fcc <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102fc7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102fcc:	c9                   	leave  
f0102fcd:	c3                   	ret    

f0102fce <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102fce:	55                   	push   %ebp
f0102fcf:	89 e5                	mov    %esp,%ebp
f0102fd1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102fd4:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102fd7:	50                   	push   %eax
f0102fd8:	ff 75 10             	pushl  0x10(%ebp)
f0102fdb:	ff 75 0c             	pushl  0xc(%ebp)
f0102fde:	ff 75 08             	pushl  0x8(%ebp)
f0102fe1:	e8 9a ff ff ff       	call   f0102f80 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102fe6:	c9                   	leave  
f0102fe7:	c3                   	ret    

f0102fe8 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102fe8:	55                   	push   %ebp
f0102fe9:	89 e5                	mov    %esp,%ebp
f0102feb:	57                   	push   %edi
f0102fec:	56                   	push   %esi
f0102fed:	53                   	push   %ebx
f0102fee:	83 ec 0c             	sub    $0xc,%esp
f0102ff1:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102ff4:	85 c0                	test   %eax,%eax
f0102ff6:	74 11                	je     f0103009 <readline+0x21>
		cprintf("%s", prompt);
f0102ff8:	83 ec 08             	sub    $0x8,%esp
f0102ffb:	50                   	push   %eax
f0102ffc:	68 0c 3c 10 f0       	push   $0xf0103c0c
f0103001:	e8 ee f6 ff ff       	call   f01026f4 <cprintf>
f0103006:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103009:	83 ec 0c             	sub    $0xc,%esp
f010300c:	6a 00                	push   $0x0
f010300e:	e8 00 d6 ff ff       	call   f0100613 <iscons>
f0103013:	89 c7                	mov    %eax,%edi
f0103015:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103018:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010301d:	e8 e0 d5 ff ff       	call   f0100602 <getchar>
f0103022:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103024:	85 c0                	test   %eax,%eax
f0103026:	79 18                	jns    f0103040 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103028:	83 ec 08             	sub    $0x8,%esp
f010302b:	50                   	push   %eax
f010302c:	68 60 48 10 f0       	push   $0xf0104860
f0103031:	e8 be f6 ff ff       	call   f01026f4 <cprintf>
			return NULL;
f0103036:	83 c4 10             	add    $0x10,%esp
f0103039:	b8 00 00 00 00       	mov    $0x0,%eax
f010303e:	eb 79                	jmp    f01030b9 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103040:	83 f8 08             	cmp    $0x8,%eax
f0103043:	0f 94 c2             	sete   %dl
f0103046:	83 f8 7f             	cmp    $0x7f,%eax
f0103049:	0f 94 c0             	sete   %al
f010304c:	08 c2                	or     %al,%dl
f010304e:	74 1a                	je     f010306a <readline+0x82>
f0103050:	85 f6                	test   %esi,%esi
f0103052:	7e 16                	jle    f010306a <readline+0x82>
			if (echoing)
f0103054:	85 ff                	test   %edi,%edi
f0103056:	74 0d                	je     f0103065 <readline+0x7d>
				cputchar('\b');
f0103058:	83 ec 0c             	sub    $0xc,%esp
f010305b:	6a 08                	push   $0x8
f010305d:	e8 90 d5 ff ff       	call   f01005f2 <cputchar>
f0103062:	83 c4 10             	add    $0x10,%esp
			i--;
f0103065:	83 ee 01             	sub    $0x1,%esi
f0103068:	eb b3                	jmp    f010301d <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010306a:	83 fb 1f             	cmp    $0x1f,%ebx
f010306d:	7e 23                	jle    f0103092 <readline+0xaa>
f010306f:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103075:	7f 1b                	jg     f0103092 <readline+0xaa>
			if (echoing)
f0103077:	85 ff                	test   %edi,%edi
f0103079:	74 0c                	je     f0103087 <readline+0x9f>
				cputchar(c);
f010307b:	83 ec 0c             	sub    $0xc,%esp
f010307e:	53                   	push   %ebx
f010307f:	e8 6e d5 ff ff       	call   f01005f2 <cputchar>
f0103084:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103087:	88 9e 60 65 11 f0    	mov    %bl,-0xfee9aa0(%esi)
f010308d:	8d 76 01             	lea    0x1(%esi),%esi
f0103090:	eb 8b                	jmp    f010301d <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103092:	83 fb 0a             	cmp    $0xa,%ebx
f0103095:	74 05                	je     f010309c <readline+0xb4>
f0103097:	83 fb 0d             	cmp    $0xd,%ebx
f010309a:	75 81                	jne    f010301d <readline+0x35>
			if (echoing)
f010309c:	85 ff                	test   %edi,%edi
f010309e:	74 0d                	je     f01030ad <readline+0xc5>
				cputchar('\n');
f01030a0:	83 ec 0c             	sub    $0xc,%esp
f01030a3:	6a 0a                	push   $0xa
f01030a5:	e8 48 d5 ff ff       	call   f01005f2 <cputchar>
f01030aa:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01030ad:	c6 86 60 65 11 f0 00 	movb   $0x0,-0xfee9aa0(%esi)
			return buf;
f01030b4:	b8 60 65 11 f0       	mov    $0xf0116560,%eax
		}
	}
}
f01030b9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030bc:	5b                   	pop    %ebx
f01030bd:	5e                   	pop    %esi
f01030be:	5f                   	pop    %edi
f01030bf:	5d                   	pop    %ebp
f01030c0:	c3                   	ret    

f01030c1 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01030c1:	55                   	push   %ebp
f01030c2:	89 e5                	mov    %esp,%ebp
f01030c4:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01030c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01030cc:	eb 03                	jmp    f01030d1 <strlen+0x10>
		n++;
f01030ce:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01030d1:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01030d5:	75 f7                	jne    f01030ce <strlen+0xd>
		n++;
	return n;
}
f01030d7:	5d                   	pop    %ebp
f01030d8:	c3                   	ret    

f01030d9 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01030d9:	55                   	push   %ebp
f01030da:	89 e5                	mov    %esp,%ebp
f01030dc:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01030df:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030e2:	ba 00 00 00 00       	mov    $0x0,%edx
f01030e7:	eb 03                	jmp    f01030ec <strnlen+0x13>
		n++;
f01030e9:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030ec:	39 c2                	cmp    %eax,%edx
f01030ee:	74 08                	je     f01030f8 <strnlen+0x1f>
f01030f0:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01030f4:	75 f3                	jne    f01030e9 <strnlen+0x10>
f01030f6:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01030f8:	5d                   	pop    %ebp
f01030f9:	c3                   	ret    

f01030fa <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01030fa:	55                   	push   %ebp
f01030fb:	89 e5                	mov    %esp,%ebp
f01030fd:	53                   	push   %ebx
f01030fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103101:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103104:	89 c2                	mov    %eax,%edx
f0103106:	83 c2 01             	add    $0x1,%edx
f0103109:	83 c1 01             	add    $0x1,%ecx
f010310c:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103110:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103113:	84 db                	test   %bl,%bl
f0103115:	75 ef                	jne    f0103106 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103117:	5b                   	pop    %ebx
f0103118:	5d                   	pop    %ebp
f0103119:	c3                   	ret    

f010311a <strcat>:

char *
strcat(char *dst, const char *src)
{
f010311a:	55                   	push   %ebp
f010311b:	89 e5                	mov    %esp,%ebp
f010311d:	53                   	push   %ebx
f010311e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103121:	53                   	push   %ebx
f0103122:	e8 9a ff ff ff       	call   f01030c1 <strlen>
f0103127:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010312a:	ff 75 0c             	pushl  0xc(%ebp)
f010312d:	01 d8                	add    %ebx,%eax
f010312f:	50                   	push   %eax
f0103130:	e8 c5 ff ff ff       	call   f01030fa <strcpy>
	return dst;
}
f0103135:	89 d8                	mov    %ebx,%eax
f0103137:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010313a:	c9                   	leave  
f010313b:	c3                   	ret    

f010313c <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010313c:	55                   	push   %ebp
f010313d:	89 e5                	mov    %esp,%ebp
f010313f:	56                   	push   %esi
f0103140:	53                   	push   %ebx
f0103141:	8b 75 08             	mov    0x8(%ebp),%esi
f0103144:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103147:	89 f3                	mov    %esi,%ebx
f0103149:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010314c:	89 f2                	mov    %esi,%edx
f010314e:	eb 0f                	jmp    f010315f <strncpy+0x23>
		*dst++ = *src;
f0103150:	83 c2 01             	add    $0x1,%edx
f0103153:	0f b6 01             	movzbl (%ecx),%eax
f0103156:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103159:	80 39 01             	cmpb   $0x1,(%ecx)
f010315c:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010315f:	39 da                	cmp    %ebx,%edx
f0103161:	75 ed                	jne    f0103150 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103163:	89 f0                	mov    %esi,%eax
f0103165:	5b                   	pop    %ebx
f0103166:	5e                   	pop    %esi
f0103167:	5d                   	pop    %ebp
f0103168:	c3                   	ret    

f0103169 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103169:	55                   	push   %ebp
f010316a:	89 e5                	mov    %esp,%ebp
f010316c:	56                   	push   %esi
f010316d:	53                   	push   %ebx
f010316e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103171:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103174:	8b 55 10             	mov    0x10(%ebp),%edx
f0103177:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103179:	85 d2                	test   %edx,%edx
f010317b:	74 21                	je     f010319e <strlcpy+0x35>
f010317d:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103181:	89 f2                	mov    %esi,%edx
f0103183:	eb 09                	jmp    f010318e <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103185:	83 c2 01             	add    $0x1,%edx
f0103188:	83 c1 01             	add    $0x1,%ecx
f010318b:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010318e:	39 c2                	cmp    %eax,%edx
f0103190:	74 09                	je     f010319b <strlcpy+0x32>
f0103192:	0f b6 19             	movzbl (%ecx),%ebx
f0103195:	84 db                	test   %bl,%bl
f0103197:	75 ec                	jne    f0103185 <strlcpy+0x1c>
f0103199:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010319b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010319e:	29 f0                	sub    %esi,%eax
}
f01031a0:	5b                   	pop    %ebx
f01031a1:	5e                   	pop    %esi
f01031a2:	5d                   	pop    %ebp
f01031a3:	c3                   	ret    

f01031a4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01031a4:	55                   	push   %ebp
f01031a5:	89 e5                	mov    %esp,%ebp
f01031a7:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01031aa:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01031ad:	eb 06                	jmp    f01031b5 <strcmp+0x11>
		p++, q++;
f01031af:	83 c1 01             	add    $0x1,%ecx
f01031b2:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01031b5:	0f b6 01             	movzbl (%ecx),%eax
f01031b8:	84 c0                	test   %al,%al
f01031ba:	74 04                	je     f01031c0 <strcmp+0x1c>
f01031bc:	3a 02                	cmp    (%edx),%al
f01031be:	74 ef                	je     f01031af <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01031c0:	0f b6 c0             	movzbl %al,%eax
f01031c3:	0f b6 12             	movzbl (%edx),%edx
f01031c6:	29 d0                	sub    %edx,%eax
}
f01031c8:	5d                   	pop    %ebp
f01031c9:	c3                   	ret    

f01031ca <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01031ca:	55                   	push   %ebp
f01031cb:	89 e5                	mov    %esp,%ebp
f01031cd:	53                   	push   %ebx
f01031ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01031d1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031d4:	89 c3                	mov    %eax,%ebx
f01031d6:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01031d9:	eb 06                	jmp    f01031e1 <strncmp+0x17>
		n--, p++, q++;
f01031db:	83 c0 01             	add    $0x1,%eax
f01031de:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01031e1:	39 d8                	cmp    %ebx,%eax
f01031e3:	74 15                	je     f01031fa <strncmp+0x30>
f01031e5:	0f b6 08             	movzbl (%eax),%ecx
f01031e8:	84 c9                	test   %cl,%cl
f01031ea:	74 04                	je     f01031f0 <strncmp+0x26>
f01031ec:	3a 0a                	cmp    (%edx),%cl
f01031ee:	74 eb                	je     f01031db <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01031f0:	0f b6 00             	movzbl (%eax),%eax
f01031f3:	0f b6 12             	movzbl (%edx),%edx
f01031f6:	29 d0                	sub    %edx,%eax
f01031f8:	eb 05                	jmp    f01031ff <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01031fa:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01031ff:	5b                   	pop    %ebx
f0103200:	5d                   	pop    %ebp
f0103201:	c3                   	ret    

f0103202 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103202:	55                   	push   %ebp
f0103203:	89 e5                	mov    %esp,%ebp
f0103205:	8b 45 08             	mov    0x8(%ebp),%eax
f0103208:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010320c:	eb 07                	jmp    f0103215 <strchr+0x13>
		if (*s == c)
f010320e:	38 ca                	cmp    %cl,%dl
f0103210:	74 0f                	je     f0103221 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103212:	83 c0 01             	add    $0x1,%eax
f0103215:	0f b6 10             	movzbl (%eax),%edx
f0103218:	84 d2                	test   %dl,%dl
f010321a:	75 f2                	jne    f010320e <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010321c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103221:	5d                   	pop    %ebp
f0103222:	c3                   	ret    

f0103223 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103223:	55                   	push   %ebp
f0103224:	89 e5                	mov    %esp,%ebp
f0103226:	8b 45 08             	mov    0x8(%ebp),%eax
f0103229:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010322d:	eb 03                	jmp    f0103232 <strfind+0xf>
f010322f:	83 c0 01             	add    $0x1,%eax
f0103232:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103235:	38 ca                	cmp    %cl,%dl
f0103237:	74 04                	je     f010323d <strfind+0x1a>
f0103239:	84 d2                	test   %dl,%dl
f010323b:	75 f2                	jne    f010322f <strfind+0xc>
			break;
	return (char *) s;
}
f010323d:	5d                   	pop    %ebp
f010323e:	c3                   	ret    

f010323f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010323f:	55                   	push   %ebp
f0103240:	89 e5                	mov    %esp,%ebp
f0103242:	57                   	push   %edi
f0103243:	56                   	push   %esi
f0103244:	53                   	push   %ebx
f0103245:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103248:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010324b:	85 c9                	test   %ecx,%ecx
f010324d:	74 36                	je     f0103285 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010324f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103255:	75 28                	jne    f010327f <memset+0x40>
f0103257:	f6 c1 03             	test   $0x3,%cl
f010325a:	75 23                	jne    f010327f <memset+0x40>
		c &= 0xFF;
f010325c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103260:	89 d3                	mov    %edx,%ebx
f0103262:	c1 e3 08             	shl    $0x8,%ebx
f0103265:	89 d6                	mov    %edx,%esi
f0103267:	c1 e6 18             	shl    $0x18,%esi
f010326a:	89 d0                	mov    %edx,%eax
f010326c:	c1 e0 10             	shl    $0x10,%eax
f010326f:	09 f0                	or     %esi,%eax
f0103271:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103273:	89 d8                	mov    %ebx,%eax
f0103275:	09 d0                	or     %edx,%eax
f0103277:	c1 e9 02             	shr    $0x2,%ecx
f010327a:	fc                   	cld    
f010327b:	f3 ab                	rep stos %eax,%es:(%edi)
f010327d:	eb 06                	jmp    f0103285 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010327f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103282:	fc                   	cld    
f0103283:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103285:	89 f8                	mov    %edi,%eax
f0103287:	5b                   	pop    %ebx
f0103288:	5e                   	pop    %esi
f0103289:	5f                   	pop    %edi
f010328a:	5d                   	pop    %ebp
f010328b:	c3                   	ret    

f010328c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010328c:	55                   	push   %ebp
f010328d:	89 e5                	mov    %esp,%ebp
f010328f:	57                   	push   %edi
f0103290:	56                   	push   %esi
f0103291:	8b 45 08             	mov    0x8(%ebp),%eax
f0103294:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103297:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010329a:	39 c6                	cmp    %eax,%esi
f010329c:	73 35                	jae    f01032d3 <memmove+0x47>
f010329e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01032a1:	39 d0                	cmp    %edx,%eax
f01032a3:	73 2e                	jae    f01032d3 <memmove+0x47>
		s += n;
		d += n;
f01032a5:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032a8:	89 d6                	mov    %edx,%esi
f01032aa:	09 fe                	or     %edi,%esi
f01032ac:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01032b2:	75 13                	jne    f01032c7 <memmove+0x3b>
f01032b4:	f6 c1 03             	test   $0x3,%cl
f01032b7:	75 0e                	jne    f01032c7 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01032b9:	83 ef 04             	sub    $0x4,%edi
f01032bc:	8d 72 fc             	lea    -0x4(%edx),%esi
f01032bf:	c1 e9 02             	shr    $0x2,%ecx
f01032c2:	fd                   	std    
f01032c3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032c5:	eb 09                	jmp    f01032d0 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01032c7:	83 ef 01             	sub    $0x1,%edi
f01032ca:	8d 72 ff             	lea    -0x1(%edx),%esi
f01032cd:	fd                   	std    
f01032ce:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01032d0:	fc                   	cld    
f01032d1:	eb 1d                	jmp    f01032f0 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032d3:	89 f2                	mov    %esi,%edx
f01032d5:	09 c2                	or     %eax,%edx
f01032d7:	f6 c2 03             	test   $0x3,%dl
f01032da:	75 0f                	jne    f01032eb <memmove+0x5f>
f01032dc:	f6 c1 03             	test   $0x3,%cl
f01032df:	75 0a                	jne    f01032eb <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01032e1:	c1 e9 02             	shr    $0x2,%ecx
f01032e4:	89 c7                	mov    %eax,%edi
f01032e6:	fc                   	cld    
f01032e7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032e9:	eb 05                	jmp    f01032f0 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01032eb:	89 c7                	mov    %eax,%edi
f01032ed:	fc                   	cld    
f01032ee:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01032f0:	5e                   	pop    %esi
f01032f1:	5f                   	pop    %edi
f01032f2:	5d                   	pop    %ebp
f01032f3:	c3                   	ret    

f01032f4 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01032f4:	55                   	push   %ebp
f01032f5:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01032f7:	ff 75 10             	pushl  0x10(%ebp)
f01032fa:	ff 75 0c             	pushl  0xc(%ebp)
f01032fd:	ff 75 08             	pushl  0x8(%ebp)
f0103300:	e8 87 ff ff ff       	call   f010328c <memmove>
}
f0103305:	c9                   	leave  
f0103306:	c3                   	ret    

f0103307 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103307:	55                   	push   %ebp
f0103308:	89 e5                	mov    %esp,%ebp
f010330a:	56                   	push   %esi
f010330b:	53                   	push   %ebx
f010330c:	8b 45 08             	mov    0x8(%ebp),%eax
f010330f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103312:	89 c6                	mov    %eax,%esi
f0103314:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103317:	eb 1a                	jmp    f0103333 <memcmp+0x2c>
		if (*s1 != *s2)
f0103319:	0f b6 08             	movzbl (%eax),%ecx
f010331c:	0f b6 1a             	movzbl (%edx),%ebx
f010331f:	38 d9                	cmp    %bl,%cl
f0103321:	74 0a                	je     f010332d <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103323:	0f b6 c1             	movzbl %cl,%eax
f0103326:	0f b6 db             	movzbl %bl,%ebx
f0103329:	29 d8                	sub    %ebx,%eax
f010332b:	eb 0f                	jmp    f010333c <memcmp+0x35>
		s1++, s2++;
f010332d:	83 c0 01             	add    $0x1,%eax
f0103330:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103333:	39 f0                	cmp    %esi,%eax
f0103335:	75 e2                	jne    f0103319 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103337:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010333c:	5b                   	pop    %ebx
f010333d:	5e                   	pop    %esi
f010333e:	5d                   	pop    %ebp
f010333f:	c3                   	ret    

f0103340 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103340:	55                   	push   %ebp
f0103341:	89 e5                	mov    %esp,%ebp
f0103343:	53                   	push   %ebx
f0103344:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103347:	89 c1                	mov    %eax,%ecx
f0103349:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010334c:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103350:	eb 0a                	jmp    f010335c <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103352:	0f b6 10             	movzbl (%eax),%edx
f0103355:	39 da                	cmp    %ebx,%edx
f0103357:	74 07                	je     f0103360 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103359:	83 c0 01             	add    $0x1,%eax
f010335c:	39 c8                	cmp    %ecx,%eax
f010335e:	72 f2                	jb     f0103352 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103360:	5b                   	pop    %ebx
f0103361:	5d                   	pop    %ebp
f0103362:	c3                   	ret    

f0103363 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103363:	55                   	push   %ebp
f0103364:	89 e5                	mov    %esp,%ebp
f0103366:	57                   	push   %edi
f0103367:	56                   	push   %esi
f0103368:	53                   	push   %ebx
f0103369:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010336c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010336f:	eb 03                	jmp    f0103374 <strtol+0x11>
		s++;
f0103371:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103374:	0f b6 01             	movzbl (%ecx),%eax
f0103377:	3c 20                	cmp    $0x20,%al
f0103379:	74 f6                	je     f0103371 <strtol+0xe>
f010337b:	3c 09                	cmp    $0x9,%al
f010337d:	74 f2                	je     f0103371 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010337f:	3c 2b                	cmp    $0x2b,%al
f0103381:	75 0a                	jne    f010338d <strtol+0x2a>
		s++;
f0103383:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103386:	bf 00 00 00 00       	mov    $0x0,%edi
f010338b:	eb 11                	jmp    f010339e <strtol+0x3b>
f010338d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103392:	3c 2d                	cmp    $0x2d,%al
f0103394:	75 08                	jne    f010339e <strtol+0x3b>
		s++, neg = 1;
f0103396:	83 c1 01             	add    $0x1,%ecx
f0103399:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010339e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01033a4:	75 15                	jne    f01033bb <strtol+0x58>
f01033a6:	80 39 30             	cmpb   $0x30,(%ecx)
f01033a9:	75 10                	jne    f01033bb <strtol+0x58>
f01033ab:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01033af:	75 7c                	jne    f010342d <strtol+0xca>
		s += 2, base = 16;
f01033b1:	83 c1 02             	add    $0x2,%ecx
f01033b4:	bb 10 00 00 00       	mov    $0x10,%ebx
f01033b9:	eb 16                	jmp    f01033d1 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01033bb:	85 db                	test   %ebx,%ebx
f01033bd:	75 12                	jne    f01033d1 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01033bf:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033c4:	80 39 30             	cmpb   $0x30,(%ecx)
f01033c7:	75 08                	jne    f01033d1 <strtol+0x6e>
		s++, base = 8;
f01033c9:	83 c1 01             	add    $0x1,%ecx
f01033cc:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01033d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01033d6:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01033d9:	0f b6 11             	movzbl (%ecx),%edx
f01033dc:	8d 72 d0             	lea    -0x30(%edx),%esi
f01033df:	89 f3                	mov    %esi,%ebx
f01033e1:	80 fb 09             	cmp    $0x9,%bl
f01033e4:	77 08                	ja     f01033ee <strtol+0x8b>
			dig = *s - '0';
f01033e6:	0f be d2             	movsbl %dl,%edx
f01033e9:	83 ea 30             	sub    $0x30,%edx
f01033ec:	eb 22                	jmp    f0103410 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01033ee:	8d 72 9f             	lea    -0x61(%edx),%esi
f01033f1:	89 f3                	mov    %esi,%ebx
f01033f3:	80 fb 19             	cmp    $0x19,%bl
f01033f6:	77 08                	ja     f0103400 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01033f8:	0f be d2             	movsbl %dl,%edx
f01033fb:	83 ea 57             	sub    $0x57,%edx
f01033fe:	eb 10                	jmp    f0103410 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103400:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103403:	89 f3                	mov    %esi,%ebx
f0103405:	80 fb 19             	cmp    $0x19,%bl
f0103408:	77 16                	ja     f0103420 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010340a:	0f be d2             	movsbl %dl,%edx
f010340d:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103410:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103413:	7d 0b                	jge    f0103420 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103415:	83 c1 01             	add    $0x1,%ecx
f0103418:	0f af 45 10          	imul   0x10(%ebp),%eax
f010341c:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010341e:	eb b9                	jmp    f01033d9 <strtol+0x76>

	if (endptr)
f0103420:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103424:	74 0d                	je     f0103433 <strtol+0xd0>
		*endptr = (char *) s;
f0103426:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103429:	89 0e                	mov    %ecx,(%esi)
f010342b:	eb 06                	jmp    f0103433 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010342d:	85 db                	test   %ebx,%ebx
f010342f:	74 98                	je     f01033c9 <strtol+0x66>
f0103431:	eb 9e                	jmp    f01033d1 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103433:	89 c2                	mov    %eax,%edx
f0103435:	f7 da                	neg    %edx
f0103437:	85 ff                	test   %edi,%edi
f0103439:	0f 45 c2             	cmovne %edx,%eax
}
f010343c:	5b                   	pop    %ebx
f010343d:	5e                   	pop    %esi
f010343e:	5f                   	pop    %edi
f010343f:	5d                   	pop    %ebp
f0103440:	c3                   	ret    
f0103441:	66 90                	xchg   %ax,%ax
f0103443:	66 90                	xchg   %ax,%ax
f0103445:	66 90                	xchg   %ax,%ax
f0103447:	66 90                	xchg   %ax,%ax
f0103449:	66 90                	xchg   %ax,%ax
f010344b:	66 90                	xchg   %ax,%ax
f010344d:	66 90                	xchg   %ax,%ax
f010344f:	90                   	nop

f0103450 <__udivdi3>:
f0103450:	55                   	push   %ebp
f0103451:	57                   	push   %edi
f0103452:	56                   	push   %esi
f0103453:	53                   	push   %ebx
f0103454:	83 ec 1c             	sub    $0x1c,%esp
f0103457:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010345b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010345f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103463:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103467:	85 f6                	test   %esi,%esi
f0103469:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010346d:	89 ca                	mov    %ecx,%edx
f010346f:	89 f8                	mov    %edi,%eax
f0103471:	75 3d                	jne    f01034b0 <__udivdi3+0x60>
f0103473:	39 cf                	cmp    %ecx,%edi
f0103475:	0f 87 c5 00 00 00    	ja     f0103540 <__udivdi3+0xf0>
f010347b:	85 ff                	test   %edi,%edi
f010347d:	89 fd                	mov    %edi,%ebp
f010347f:	75 0b                	jne    f010348c <__udivdi3+0x3c>
f0103481:	b8 01 00 00 00       	mov    $0x1,%eax
f0103486:	31 d2                	xor    %edx,%edx
f0103488:	f7 f7                	div    %edi
f010348a:	89 c5                	mov    %eax,%ebp
f010348c:	89 c8                	mov    %ecx,%eax
f010348e:	31 d2                	xor    %edx,%edx
f0103490:	f7 f5                	div    %ebp
f0103492:	89 c1                	mov    %eax,%ecx
f0103494:	89 d8                	mov    %ebx,%eax
f0103496:	89 cf                	mov    %ecx,%edi
f0103498:	f7 f5                	div    %ebp
f010349a:	89 c3                	mov    %eax,%ebx
f010349c:	89 d8                	mov    %ebx,%eax
f010349e:	89 fa                	mov    %edi,%edx
f01034a0:	83 c4 1c             	add    $0x1c,%esp
f01034a3:	5b                   	pop    %ebx
f01034a4:	5e                   	pop    %esi
f01034a5:	5f                   	pop    %edi
f01034a6:	5d                   	pop    %ebp
f01034a7:	c3                   	ret    
f01034a8:	90                   	nop
f01034a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034b0:	39 ce                	cmp    %ecx,%esi
f01034b2:	77 74                	ja     f0103528 <__udivdi3+0xd8>
f01034b4:	0f bd fe             	bsr    %esi,%edi
f01034b7:	83 f7 1f             	xor    $0x1f,%edi
f01034ba:	0f 84 98 00 00 00    	je     f0103558 <__udivdi3+0x108>
f01034c0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01034c5:	89 f9                	mov    %edi,%ecx
f01034c7:	89 c5                	mov    %eax,%ebp
f01034c9:	29 fb                	sub    %edi,%ebx
f01034cb:	d3 e6                	shl    %cl,%esi
f01034cd:	89 d9                	mov    %ebx,%ecx
f01034cf:	d3 ed                	shr    %cl,%ebp
f01034d1:	89 f9                	mov    %edi,%ecx
f01034d3:	d3 e0                	shl    %cl,%eax
f01034d5:	09 ee                	or     %ebp,%esi
f01034d7:	89 d9                	mov    %ebx,%ecx
f01034d9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034dd:	89 d5                	mov    %edx,%ebp
f01034df:	8b 44 24 08          	mov    0x8(%esp),%eax
f01034e3:	d3 ed                	shr    %cl,%ebp
f01034e5:	89 f9                	mov    %edi,%ecx
f01034e7:	d3 e2                	shl    %cl,%edx
f01034e9:	89 d9                	mov    %ebx,%ecx
f01034eb:	d3 e8                	shr    %cl,%eax
f01034ed:	09 c2                	or     %eax,%edx
f01034ef:	89 d0                	mov    %edx,%eax
f01034f1:	89 ea                	mov    %ebp,%edx
f01034f3:	f7 f6                	div    %esi
f01034f5:	89 d5                	mov    %edx,%ebp
f01034f7:	89 c3                	mov    %eax,%ebx
f01034f9:	f7 64 24 0c          	mull   0xc(%esp)
f01034fd:	39 d5                	cmp    %edx,%ebp
f01034ff:	72 10                	jb     f0103511 <__udivdi3+0xc1>
f0103501:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103505:	89 f9                	mov    %edi,%ecx
f0103507:	d3 e6                	shl    %cl,%esi
f0103509:	39 c6                	cmp    %eax,%esi
f010350b:	73 07                	jae    f0103514 <__udivdi3+0xc4>
f010350d:	39 d5                	cmp    %edx,%ebp
f010350f:	75 03                	jne    f0103514 <__udivdi3+0xc4>
f0103511:	83 eb 01             	sub    $0x1,%ebx
f0103514:	31 ff                	xor    %edi,%edi
f0103516:	89 d8                	mov    %ebx,%eax
f0103518:	89 fa                	mov    %edi,%edx
f010351a:	83 c4 1c             	add    $0x1c,%esp
f010351d:	5b                   	pop    %ebx
f010351e:	5e                   	pop    %esi
f010351f:	5f                   	pop    %edi
f0103520:	5d                   	pop    %ebp
f0103521:	c3                   	ret    
f0103522:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103528:	31 ff                	xor    %edi,%edi
f010352a:	31 db                	xor    %ebx,%ebx
f010352c:	89 d8                	mov    %ebx,%eax
f010352e:	89 fa                	mov    %edi,%edx
f0103530:	83 c4 1c             	add    $0x1c,%esp
f0103533:	5b                   	pop    %ebx
f0103534:	5e                   	pop    %esi
f0103535:	5f                   	pop    %edi
f0103536:	5d                   	pop    %ebp
f0103537:	c3                   	ret    
f0103538:	90                   	nop
f0103539:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103540:	89 d8                	mov    %ebx,%eax
f0103542:	f7 f7                	div    %edi
f0103544:	31 ff                	xor    %edi,%edi
f0103546:	89 c3                	mov    %eax,%ebx
f0103548:	89 d8                	mov    %ebx,%eax
f010354a:	89 fa                	mov    %edi,%edx
f010354c:	83 c4 1c             	add    $0x1c,%esp
f010354f:	5b                   	pop    %ebx
f0103550:	5e                   	pop    %esi
f0103551:	5f                   	pop    %edi
f0103552:	5d                   	pop    %ebp
f0103553:	c3                   	ret    
f0103554:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103558:	39 ce                	cmp    %ecx,%esi
f010355a:	72 0c                	jb     f0103568 <__udivdi3+0x118>
f010355c:	31 db                	xor    %ebx,%ebx
f010355e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103562:	0f 87 34 ff ff ff    	ja     f010349c <__udivdi3+0x4c>
f0103568:	bb 01 00 00 00       	mov    $0x1,%ebx
f010356d:	e9 2a ff ff ff       	jmp    f010349c <__udivdi3+0x4c>
f0103572:	66 90                	xchg   %ax,%ax
f0103574:	66 90                	xchg   %ax,%ax
f0103576:	66 90                	xchg   %ax,%ax
f0103578:	66 90                	xchg   %ax,%ax
f010357a:	66 90                	xchg   %ax,%ax
f010357c:	66 90                	xchg   %ax,%ax
f010357e:	66 90                	xchg   %ax,%ax

f0103580 <__umoddi3>:
f0103580:	55                   	push   %ebp
f0103581:	57                   	push   %edi
f0103582:	56                   	push   %esi
f0103583:	53                   	push   %ebx
f0103584:	83 ec 1c             	sub    $0x1c,%esp
f0103587:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010358b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010358f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103593:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103597:	85 d2                	test   %edx,%edx
f0103599:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010359d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035a1:	89 f3                	mov    %esi,%ebx
f01035a3:	89 3c 24             	mov    %edi,(%esp)
f01035a6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035aa:	75 1c                	jne    f01035c8 <__umoddi3+0x48>
f01035ac:	39 f7                	cmp    %esi,%edi
f01035ae:	76 50                	jbe    f0103600 <__umoddi3+0x80>
f01035b0:	89 c8                	mov    %ecx,%eax
f01035b2:	89 f2                	mov    %esi,%edx
f01035b4:	f7 f7                	div    %edi
f01035b6:	89 d0                	mov    %edx,%eax
f01035b8:	31 d2                	xor    %edx,%edx
f01035ba:	83 c4 1c             	add    $0x1c,%esp
f01035bd:	5b                   	pop    %ebx
f01035be:	5e                   	pop    %esi
f01035bf:	5f                   	pop    %edi
f01035c0:	5d                   	pop    %ebp
f01035c1:	c3                   	ret    
f01035c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01035c8:	39 f2                	cmp    %esi,%edx
f01035ca:	89 d0                	mov    %edx,%eax
f01035cc:	77 52                	ja     f0103620 <__umoddi3+0xa0>
f01035ce:	0f bd ea             	bsr    %edx,%ebp
f01035d1:	83 f5 1f             	xor    $0x1f,%ebp
f01035d4:	75 5a                	jne    f0103630 <__umoddi3+0xb0>
f01035d6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01035da:	0f 82 e0 00 00 00    	jb     f01036c0 <__umoddi3+0x140>
f01035e0:	39 0c 24             	cmp    %ecx,(%esp)
f01035e3:	0f 86 d7 00 00 00    	jbe    f01036c0 <__umoddi3+0x140>
f01035e9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01035ed:	8b 54 24 04          	mov    0x4(%esp),%edx
f01035f1:	83 c4 1c             	add    $0x1c,%esp
f01035f4:	5b                   	pop    %ebx
f01035f5:	5e                   	pop    %esi
f01035f6:	5f                   	pop    %edi
f01035f7:	5d                   	pop    %ebp
f01035f8:	c3                   	ret    
f01035f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103600:	85 ff                	test   %edi,%edi
f0103602:	89 fd                	mov    %edi,%ebp
f0103604:	75 0b                	jne    f0103611 <__umoddi3+0x91>
f0103606:	b8 01 00 00 00       	mov    $0x1,%eax
f010360b:	31 d2                	xor    %edx,%edx
f010360d:	f7 f7                	div    %edi
f010360f:	89 c5                	mov    %eax,%ebp
f0103611:	89 f0                	mov    %esi,%eax
f0103613:	31 d2                	xor    %edx,%edx
f0103615:	f7 f5                	div    %ebp
f0103617:	89 c8                	mov    %ecx,%eax
f0103619:	f7 f5                	div    %ebp
f010361b:	89 d0                	mov    %edx,%eax
f010361d:	eb 99                	jmp    f01035b8 <__umoddi3+0x38>
f010361f:	90                   	nop
f0103620:	89 c8                	mov    %ecx,%eax
f0103622:	89 f2                	mov    %esi,%edx
f0103624:	83 c4 1c             	add    $0x1c,%esp
f0103627:	5b                   	pop    %ebx
f0103628:	5e                   	pop    %esi
f0103629:	5f                   	pop    %edi
f010362a:	5d                   	pop    %ebp
f010362b:	c3                   	ret    
f010362c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103630:	8b 34 24             	mov    (%esp),%esi
f0103633:	bf 20 00 00 00       	mov    $0x20,%edi
f0103638:	89 e9                	mov    %ebp,%ecx
f010363a:	29 ef                	sub    %ebp,%edi
f010363c:	d3 e0                	shl    %cl,%eax
f010363e:	89 f9                	mov    %edi,%ecx
f0103640:	89 f2                	mov    %esi,%edx
f0103642:	d3 ea                	shr    %cl,%edx
f0103644:	89 e9                	mov    %ebp,%ecx
f0103646:	09 c2                	or     %eax,%edx
f0103648:	89 d8                	mov    %ebx,%eax
f010364a:	89 14 24             	mov    %edx,(%esp)
f010364d:	89 f2                	mov    %esi,%edx
f010364f:	d3 e2                	shl    %cl,%edx
f0103651:	89 f9                	mov    %edi,%ecx
f0103653:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103657:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010365b:	d3 e8                	shr    %cl,%eax
f010365d:	89 e9                	mov    %ebp,%ecx
f010365f:	89 c6                	mov    %eax,%esi
f0103661:	d3 e3                	shl    %cl,%ebx
f0103663:	89 f9                	mov    %edi,%ecx
f0103665:	89 d0                	mov    %edx,%eax
f0103667:	d3 e8                	shr    %cl,%eax
f0103669:	89 e9                	mov    %ebp,%ecx
f010366b:	09 d8                	or     %ebx,%eax
f010366d:	89 d3                	mov    %edx,%ebx
f010366f:	89 f2                	mov    %esi,%edx
f0103671:	f7 34 24             	divl   (%esp)
f0103674:	89 d6                	mov    %edx,%esi
f0103676:	d3 e3                	shl    %cl,%ebx
f0103678:	f7 64 24 04          	mull   0x4(%esp)
f010367c:	39 d6                	cmp    %edx,%esi
f010367e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103682:	89 d1                	mov    %edx,%ecx
f0103684:	89 c3                	mov    %eax,%ebx
f0103686:	72 08                	jb     f0103690 <__umoddi3+0x110>
f0103688:	75 11                	jne    f010369b <__umoddi3+0x11b>
f010368a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010368e:	73 0b                	jae    f010369b <__umoddi3+0x11b>
f0103690:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103694:	1b 14 24             	sbb    (%esp),%edx
f0103697:	89 d1                	mov    %edx,%ecx
f0103699:	89 c3                	mov    %eax,%ebx
f010369b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010369f:	29 da                	sub    %ebx,%edx
f01036a1:	19 ce                	sbb    %ecx,%esi
f01036a3:	89 f9                	mov    %edi,%ecx
f01036a5:	89 f0                	mov    %esi,%eax
f01036a7:	d3 e0                	shl    %cl,%eax
f01036a9:	89 e9                	mov    %ebp,%ecx
f01036ab:	d3 ea                	shr    %cl,%edx
f01036ad:	89 e9                	mov    %ebp,%ecx
f01036af:	d3 ee                	shr    %cl,%esi
f01036b1:	09 d0                	or     %edx,%eax
f01036b3:	89 f2                	mov    %esi,%edx
f01036b5:	83 c4 1c             	add    $0x1c,%esp
f01036b8:	5b                   	pop    %ebx
f01036b9:	5e                   	pop    %esi
f01036ba:	5f                   	pop    %edi
f01036bb:	5d                   	pop    %ebp
f01036bc:	c3                   	ret    
f01036bd:	8d 76 00             	lea    0x0(%esi),%esi
f01036c0:	29 f9                	sub    %edi,%ecx
f01036c2:	19 d6                	sbb    %edx,%esi
f01036c4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01036c8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01036cc:	e9 18 ff ff ff       	jmp    f01035e9 <__umoddi3+0x69>
