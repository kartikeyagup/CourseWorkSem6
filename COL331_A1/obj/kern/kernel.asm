
obj/kern/kernel:     file format elf32-i386


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
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 10 11 00       	mov    $0x111000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 62 00 00 00       	call   f01000a0 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	cprintf("entering test_backtrace %d\n", x);
f0100046:	8b 45 08             	mov    0x8(%ebp),%eax
f0100049:	89 44 24 04          	mov    %eax,0x4(%esp)
f010004d:	c7 04 24 00 21 10 f0 	movl   $0xf0102100,(%esp)
f0100054:	e8 9e 0c 00 00       	call   f0100cf7 <cprintf>
	if (x > 0)
f0100059:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010005d:	7e 10                	jle    f010006f <test_backtrace+0x2f>
		test_backtrace(x-1);
f010005f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100062:	83 e8 01             	sub    $0x1,%eax
f0100065:	89 04 24             	mov    %eax,(%esp)
f0100068:	e8 d3 ff ff ff       	call   f0100040 <test_backtrace>
f010006d:	eb 1c                	jmp    f010008b <test_backtrace+0x4b>
	else
		mon_backtrace(0, 0, 0);
f010006f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100076:	00 
f0100077:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007e:	00 
f010007f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100086:	e8 6b 0a 00 00       	call   f0100af6 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f010008b:	8b 45 08             	mov    0x8(%ebp),%eax
f010008e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100092:	c7 04 24 1c 21 10 f0 	movl   $0xf010211c,(%esp)
f0100099:	e8 59 0c 00 00       	call   f0100cf7 <cprintf>
}
f010009e:	c9                   	leave  
f010009f:	c3                   	ret    

f01000a0 <i386_init>:

void
i386_init(void)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a6:	ba 84 2b 11 f0       	mov    $0xf0112b84,%edx
f01000ab:	b8 28 25 11 f0       	mov    $0xf0112528,%eax
f01000b0:	29 c2                	sub    %eax,%edx
f01000b2:	89 d0                	mov    %edx,%eax
f01000b4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000bf:	00 
f01000c0:	c7 04 24 28 25 11 f0 	movl   $0xf0112528,(%esp)
f01000c7:	e8 3f 1a 00 00       	call   f0101b0b <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cc:	e8 75 08 00 00       	call   f0100946 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d1:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d8:	00 
f01000d9:	c7 04 24 37 21 10 f0 	movl   $0xf0102137,(%esp)
f01000e0:	e8 12 0c 00 00       	call   f0100cf7 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000e5:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000ec:	e8 4f ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000f1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f8:	e8 5c 0b 00 00       	call   f0100c59 <monitor>
f01000fd:	eb f2                	jmp    f01000f1 <i386_init+0x51>

f01000ff <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000ff:	55                   	push   %ebp
f0100100:	89 e5                	mov    %esp,%ebp
f0100102:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	if (panicstr)
f0100105:	a1 80 2b 11 f0       	mov    0xf0112b80,%eax
f010010a:	85 c0                	test   %eax,%eax
f010010c:	74 02                	je     f0100110 <_panic+0x11>
		goto dead;
f010010e:	eb 48                	jmp    f0100158 <_panic+0x59>
	panicstr = fmt;
f0100110:	8b 45 10             	mov    0x10(%ebp),%eax
f0100113:	a3 80 2b 11 f0       	mov    %eax,0xf0112b80

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100118:	fa                   	cli    
f0100119:	fc                   	cld    

	va_start(ap, fmt);
f010011a:	8d 45 14             	lea    0x14(%ebp),%eax
f010011d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
f0100120:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100123:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100127:	8b 45 08             	mov    0x8(%ebp),%eax
f010012a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010012e:	c7 04 24 52 21 10 f0 	movl   $0xf0102152,(%esp)
f0100135:	e8 bd 0b 00 00       	call   f0100cf7 <cprintf>
	vcprintf(fmt, ap);
f010013a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010013d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100141:	8b 45 10             	mov    0x10(%ebp),%eax
f0100144:	89 04 24             	mov    %eax,(%esp)
f0100147:	e8 78 0b 00 00       	call   f0100cc4 <vcprintf>
	cprintf("\n");
f010014c:	c7 04 24 6a 21 10 f0 	movl   $0xf010216a,(%esp)
f0100153:	e8 9f 0b 00 00       	call   f0100cf7 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100158:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010015f:	e8 f5 0a 00 00       	call   f0100c59 <monitor>
f0100164:	eb f2                	jmp    f0100158 <_panic+0x59>

f0100166 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100166:	55                   	push   %ebp
f0100167:	89 e5                	mov    %esp,%ebp
f0100169:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
f010016c:	8d 45 14             	lea    0x14(%ebp),%eax
f010016f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
f0100172:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100175:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100179:	8b 45 08             	mov    0x8(%ebp),%eax
f010017c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100180:	c7 04 24 6c 21 10 f0 	movl   $0xf010216c,(%esp)
f0100187:	e8 6b 0b 00 00       	call   f0100cf7 <cprintf>
	vcprintf(fmt, ap);
f010018c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010018f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100193:	8b 45 10             	mov    0x10(%ebp),%eax
f0100196:	89 04 24             	mov    %eax,(%esp)
f0100199:	e8 26 0b 00 00       	call   f0100cc4 <vcprintf>
	cprintf("\n");
f010019e:	c7 04 24 6a 21 10 f0 	movl   $0xf010216a,(%esp)
f01001a5:	e8 4d 0b 00 00       	call   f0100cf7 <cprintf>
	va_end(ap);
}
f01001aa:	c9                   	leave  
f01001ab:	c3                   	ret    

f01001ac <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001ac:	55                   	push   %ebp
f01001ad:	89 e5                	mov    %esp,%ebp
f01001af:	83 ec 20             	sub    $0x20,%esp
f01001b2:	c7 45 fc 84 00 00 00 	movl   $0x84,-0x4(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001b9:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01001bc:	89 c2                	mov    %eax,%edx
f01001be:	ec                   	in     (%dx),%al
f01001bf:	88 45 fb             	mov    %al,-0x5(%ebp)
f01001c2:	c7 45 f4 84 00 00 00 	movl   $0x84,-0xc(%ebp)
f01001c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01001cc:	89 c2                	mov    %eax,%edx
f01001ce:	ec                   	in     (%dx),%al
f01001cf:	88 45 f3             	mov    %al,-0xd(%ebp)
f01001d2:	c7 45 ec 84 00 00 00 	movl   $0x84,-0x14(%ebp)
f01001d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01001dc:	89 c2                	mov    %eax,%edx
f01001de:	ec                   	in     (%dx),%al
f01001df:	88 45 eb             	mov    %al,-0x15(%ebp)
f01001e2:	c7 45 e4 84 00 00 00 	movl   $0x84,-0x1c(%ebp)
f01001e9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01001ec:	89 c2                	mov    %eax,%edx
f01001ee:	ec                   	in     (%dx),%al
f01001ef:	88 45 e3             	mov    %al,-0x1d(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001f2:	c9                   	leave  
f01001f3:	c3                   	ret    

f01001f4 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001f4:	55                   	push   %ebp
f01001f5:	89 e5                	mov    %esp,%ebp
f01001f7:	83 ec 10             	sub    $0x10,%esp
f01001fa:	c7 45 fc fd 03 00 00 	movl   $0x3fd,-0x4(%ebp)
f0100201:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100204:	89 c2                	mov    %eax,%edx
f0100206:	ec                   	in     (%dx),%al
f0100207:	88 45 fb             	mov    %al,-0x5(%ebp)
	return data;
f010020a:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010020e:	0f b6 c0             	movzbl %al,%eax
f0100211:	83 e0 01             	and    $0x1,%eax
f0100214:	85 c0                	test   %eax,%eax
f0100216:	75 07                	jne    f010021f <serial_proc_data+0x2b>
		return -1;
f0100218:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010021d:	eb 17                	jmp    f0100236 <serial_proc_data+0x42>
f010021f:	c7 45 f4 f8 03 00 00 	movl   $0x3f8,-0xc(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100226:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100229:	89 c2                	mov    %eax,%edx
f010022b:	ec                   	in     (%dx),%al
f010022c:	88 45 f3             	mov    %al,-0xd(%ebp)
	return data;
f010022f:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
	return inb(COM1+COM_RX);
f0100233:	0f b6 c0             	movzbl %al,%eax
}
f0100236:	c9                   	leave  
f0100237:	c3                   	ret    

f0100238 <serial_intr>:

void
serial_intr(void)
{
f0100238:	55                   	push   %ebp
f0100239:	89 e5                	mov    %esp,%ebp
f010023b:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
f010023e:	0f b6 05 40 25 11 f0 	movzbl 0xf0112540,%eax
f0100245:	84 c0                	test   %al,%al
f0100247:	74 0c                	je     f0100255 <serial_intr+0x1d>
		cons_intr(serial_proc_data);
f0100249:	c7 04 24 f4 01 10 f0 	movl   $0xf01001f4,(%esp)
f0100250:	e8 1f 06 00 00       	call   f0100874 <cons_intr>
}
f0100255:	c9                   	leave  
f0100256:	c3                   	ret    

f0100257 <serial_putc>:

static void
serial_putc(int c)
{
f0100257:	55                   	push   %ebp
f0100258:	89 e5                	mov    %esp,%ebp
f010025a:	83 ec 20             	sub    $0x20,%esp
	int i;

	for (i = 0;
f010025d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0100264:	eb 09                	jmp    f010026f <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100266:	e8 41 ff ff ff       	call   f01001ac <delay>
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f010026b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f010026f:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100276:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100279:	89 c2                	mov    %eax,%edx
f010027b:	ec                   	in     (%dx),%al
f010027c:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
f010027f:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100283:	0f b6 c0             	movzbl %al,%eax
f0100286:	83 e0 20             	and    $0x20,%eax
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100289:	85 c0                	test   %eax,%eax
f010028b:	75 09                	jne    f0100296 <serial_putc+0x3f>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010028d:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
f0100294:	7e d0                	jle    f0100266 <serial_putc+0xf>
	     i++)
		delay();

	outb(COM1+COM_TX, c);
f0100296:	8b 45 08             	mov    0x8(%ebp),%eax
f0100299:	0f b6 c0             	movzbl %al,%eax
f010029c:	c7 45 f0 f8 03 00 00 	movl   $0x3f8,-0x10(%ebp)
f01002a3:	88 45 ef             	mov    %al,-0x11(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002a6:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
f01002aa:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01002ad:	ee                   	out    %al,(%dx)
    /*outb(0x378+2, 0x08|0x04|0x01);*/
    /*outb(0x378+2, 0x08);*/
    /*outb()*/
	//printf to shell using serial interface. code to follow

}
f01002ae:	c9                   	leave  
f01002af:	c3                   	ret    

f01002b0 <serial_init>:

static void
serial_init(void)
{
f01002b0:	55                   	push   %ebp
f01002b1:	89 e5                	mov    %esp,%ebp
f01002b3:	83 ec 50             	sub    $0x50,%esp
f01002b6:	c7 45 fc fa 03 00 00 	movl   $0x3fa,-0x4(%ebp)
f01002bd:	c6 45 fb 00          	movb   $0x0,-0x5(%ebp)
f01002c1:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
f01002c5:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01002c8:	ee                   	out    %al,(%dx)
f01002c9:	c7 45 f4 fb 03 00 00 	movl   $0x3fb,-0xc(%ebp)
f01002d0:	c6 45 f3 80          	movb   $0x80,-0xd(%ebp)
f01002d4:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01002d8:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01002db:	ee                   	out    %al,(%dx)
f01002dc:	c7 45 ec f8 03 00 00 	movl   $0x3f8,-0x14(%ebp)
f01002e3:	c6 45 eb 0c          	movb   $0xc,-0x15(%ebp)
f01002e7:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
f01002eb:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01002ee:	ee                   	out    %al,(%dx)
f01002ef:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
f01002f6:	c6 45 e3 00          	movb   $0x0,-0x1d(%ebp)
f01002fa:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f01002fe:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100301:	ee                   	out    %al,(%dx)
f0100302:	c7 45 dc fb 03 00 00 	movl   $0x3fb,-0x24(%ebp)
f0100309:	c6 45 db 03          	movb   $0x3,-0x25(%ebp)
f010030d:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
f0100311:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100314:	ee                   	out    %al,(%dx)
f0100315:	c7 45 d4 fc 03 00 00 	movl   $0x3fc,-0x2c(%ebp)
f010031c:	c6 45 d3 00          	movb   $0x0,-0x2d(%ebp)
f0100320:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
f0100324:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100327:	ee                   	out    %al,(%dx)
f0100328:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
f010032f:	c6 45 cb 01          	movb   $0x1,-0x35(%ebp)
f0100333:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
f0100337:	8b 55 cc             	mov    -0x34(%ebp),%edx
f010033a:	ee                   	out    %al,(%dx)
f010033b:	c7 45 c4 fd 03 00 00 	movl   $0x3fd,-0x3c(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100342:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100345:	89 c2                	mov    %eax,%edx
f0100347:	ec                   	in     (%dx),%al
f0100348:	88 45 c3             	mov    %al,-0x3d(%ebp)
	return data;
f010034b:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010034f:	3c ff                	cmp    $0xff,%al
f0100351:	0f 95 c0             	setne  %al
f0100354:	a2 40 25 11 f0       	mov    %al,0xf0112540
f0100359:	c7 45 bc fa 03 00 00 	movl   $0x3fa,-0x44(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100360:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0100363:	89 c2                	mov    %eax,%edx
f0100365:	ec                   	in     (%dx),%al
f0100366:	88 45 bb             	mov    %al,-0x45(%ebp)
f0100369:	c7 45 b4 f8 03 00 00 	movl   $0x3f8,-0x4c(%ebp)
f0100370:	8b 45 b4             	mov    -0x4c(%ebp),%eax
f0100373:	89 c2                	mov    %eax,%edx
f0100375:	ec                   	in     (%dx),%al
f0100376:	88 45 b3             	mov    %al,-0x4d(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

}
f0100379:	c9                   	leave  
f010037a:	c3                   	ret    

f010037b <lpt_putc>:
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
f010037b:	55                   	push   %ebp
f010037c:	89 e5                	mov    %esp,%ebp
f010037e:	83 ec 30             	sub    $0x30,%esp
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100381:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0100388:	eb 09                	jmp    f0100393 <lpt_putc+0x18>
		delay();
f010038a:	e8 1d fe ff ff       	call   f01001ac <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010038f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f0100393:	c7 45 f8 79 03 00 00 	movl   $0x379,-0x8(%ebp)
f010039a:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010039d:	89 c2                	mov    %eax,%edx
f010039f:	ec                   	in     (%dx),%al
f01003a0:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
f01003a3:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
f01003a7:	84 c0                	test   %al,%al
f01003a9:	78 09                	js     f01003b4 <lpt_putc+0x39>
f01003ab:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
f01003b2:	7e d6                	jle    f010038a <lpt_putc+0xf>
		delay();
	outb(0x378+0, c);
f01003b4:	8b 45 08             	mov    0x8(%ebp),%eax
f01003b7:	0f b6 c0             	movzbl %al,%eax
f01003ba:	c7 45 f0 78 03 00 00 	movl   $0x378,-0x10(%ebp)
f01003c1:	88 45 ef             	mov    %al,-0x11(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003c4:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
f01003c8:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01003cb:	ee                   	out    %al,(%dx)
f01003cc:	c7 45 e8 7a 03 00 00 	movl   $0x37a,-0x18(%ebp)
f01003d3:	c6 45 e7 0d          	movb   $0xd,-0x19(%ebp)
f01003d7:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f01003db:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01003de:	ee                   	out    %al,(%dx)
f01003df:	c7 45 e0 7a 03 00 00 	movl   $0x37a,-0x20(%ebp)
f01003e6:	c6 45 df 08          	movb   $0x8,-0x21(%ebp)
f01003ea:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
f01003ee:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01003f1:	ee                   	out    %al,(%dx)
	outb(0x378+2, 0x08|0x04|0x01);
	outb(0x378+2, 0x08);
}
f01003f2:	c9                   	leave  
f01003f3:	c3                   	ret    

f01003f4 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
f01003f4:	55                   	push   %ebp
f01003f5:	89 e5                	mov    %esp,%ebp
f01003f7:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01003fa:	c7 45 fc 00 80 0b f0 	movl   $0xf00b8000,-0x4(%ebp)
	was = *cp;
f0100401:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100404:	0f b7 00             	movzwl (%eax),%eax
f0100407:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
	*cp = (uint16_t) 0xA55A;
f010040b:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010040e:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
f0100413:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100416:	0f b7 00             	movzwl (%eax),%eax
f0100419:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010041d:	74 13                	je     f0100432 <cga_init+0x3e>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010041f:	c7 45 fc 00 00 0b f0 	movl   $0xf00b0000,-0x4(%ebp)
		addr_6845 = MONO_BASE;
f0100426:	c7 05 44 25 11 f0 b4 	movl   $0x3b4,0xf0112544
f010042d:	03 00 00 
f0100430:	eb 14                	jmp    f0100446 <cga_init+0x52>
	} else {
		*cp = was;
f0100432:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100435:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
f0100439:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
f010043c:	c7 05 44 25 11 f0 d4 	movl   $0x3d4,0xf0112544
f0100443:	03 00 00 
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100446:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f010044b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010044e:	c6 45 ef 0e          	movb   $0xe,-0x11(%ebp)
f0100452:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
f0100456:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100459:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010045a:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f010045f:	83 c0 01             	add    $0x1,%eax
f0100462:	89 45 e8             	mov    %eax,-0x18(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100465:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100468:	89 c2                	mov    %eax,%edx
f010046a:	ec                   	in     (%dx),%al
f010046b:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
f010046e:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100472:	0f b6 c0             	movzbl %al,%eax
f0100475:	c1 e0 08             	shl    $0x8,%eax
f0100478:	89 45 f4             	mov    %eax,-0xc(%ebp)
	outb(addr_6845, 15);
f010047b:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f0100480:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100483:	c6 45 df 0f          	movb   $0xf,-0x21(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100487:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
f010048b:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010048e:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
f010048f:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f0100494:	83 c0 01             	add    $0x1,%eax
f0100497:	89 45 d8             	mov    %eax,-0x28(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010049a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010049d:	89 c2                	mov    %eax,%edx
f010049f:	ec                   	in     (%dx),%al
f01004a0:	88 45 d7             	mov    %al,-0x29(%ebp)
	return data;
f01004a3:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
f01004a7:	0f b6 c0             	movzbl %al,%eax
f01004aa:	09 45 f4             	or     %eax,-0xc(%ebp)

	crt_buf = (uint16_t*) cp;
f01004ad:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01004b0:	a3 48 25 11 f0       	mov    %eax,0xf0112548
	crt_pos = pos;
f01004b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01004b8:	66 a3 4c 25 11 f0    	mov    %ax,0xf011254c
}
f01004be:	c9                   	leave  
f01004bf:	c3                   	ret    

f01004c0 <cga_putc>:



static void
cga_putc(int c)
{
f01004c0:	55                   	push   %ebp
f01004c1:	89 e5                	mov    %esp,%ebp
f01004c3:	53                   	push   %ebx
f01004c4:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01004ca:	b0 00                	mov    $0x0,%al
f01004cc:	85 c0                	test   %eax,%eax
f01004ce:	75 07                	jne    f01004d7 <cga_putc+0x17>
		c |= 0x0700;
f01004d0:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
f01004d7:	8b 45 08             	mov    0x8(%ebp),%eax
f01004da:	0f b6 c0             	movzbl %al,%eax
f01004dd:	83 f8 09             	cmp    $0x9,%eax
f01004e0:	0f 84 ac 00 00 00    	je     f0100592 <cga_putc+0xd2>
f01004e6:	83 f8 09             	cmp    $0x9,%eax
f01004e9:	7f 0a                	jg     f01004f5 <cga_putc+0x35>
f01004eb:	83 f8 08             	cmp    $0x8,%eax
f01004ee:	74 14                	je     f0100504 <cga_putc+0x44>
f01004f0:	e9 db 00 00 00       	jmp    f01005d0 <cga_putc+0x110>
f01004f5:	83 f8 0a             	cmp    $0xa,%eax
f01004f8:	74 4e                	je     f0100548 <cga_putc+0x88>
f01004fa:	83 f8 0d             	cmp    $0xd,%eax
f01004fd:	74 59                	je     f0100558 <cga_putc+0x98>
f01004ff:	e9 cc 00 00 00       	jmp    f01005d0 <cga_putc+0x110>
	case '\b':
		if (crt_pos > 0) {
f0100504:	0f b7 05 4c 25 11 f0 	movzwl 0xf011254c,%eax
f010050b:	66 85 c0             	test   %ax,%ax
f010050e:	74 33                	je     f0100543 <cga_putc+0x83>
			crt_pos--;
f0100510:	0f b7 05 4c 25 11 f0 	movzwl 0xf011254c,%eax
f0100517:	83 e8 01             	sub    $0x1,%eax
f010051a:	66 a3 4c 25 11 f0    	mov    %ax,0xf011254c
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100520:	a1 48 25 11 f0       	mov    0xf0112548,%eax
f0100525:	0f b7 15 4c 25 11 f0 	movzwl 0xf011254c,%edx
f010052c:	0f b7 d2             	movzwl %dx,%edx
f010052f:	01 d2                	add    %edx,%edx
f0100531:	01 c2                	add    %eax,%edx
f0100533:	8b 45 08             	mov    0x8(%ebp),%eax
f0100536:	b0 00                	mov    $0x0,%al
f0100538:	83 c8 20             	or     $0x20,%eax
f010053b:	66 89 02             	mov    %ax,(%edx)
		}
		break;
f010053e:	e9 b3 00 00 00       	jmp    f01005f6 <cga_putc+0x136>
f0100543:	e9 ae 00 00 00       	jmp    f01005f6 <cga_putc+0x136>
	case '\n':
		crt_pos += CRT_COLS;
f0100548:	0f b7 05 4c 25 11 f0 	movzwl 0xf011254c,%eax
f010054f:	83 c0 50             	add    $0x50,%eax
f0100552:	66 a3 4c 25 11 f0    	mov    %ax,0xf011254c
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100558:	0f b7 1d 4c 25 11 f0 	movzwl 0xf011254c,%ebx
f010055f:	0f b7 0d 4c 25 11 f0 	movzwl 0xf011254c,%ecx
f0100566:	0f b7 c1             	movzwl %cx,%eax
f0100569:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010056f:	c1 e8 10             	shr    $0x10,%eax
f0100572:	89 c2                	mov    %eax,%edx
f0100574:	66 c1 ea 06          	shr    $0x6,%dx
f0100578:	89 d0                	mov    %edx,%eax
f010057a:	c1 e0 02             	shl    $0x2,%eax
f010057d:	01 d0                	add    %edx,%eax
f010057f:	c1 e0 04             	shl    $0x4,%eax
f0100582:	29 c1                	sub    %eax,%ecx
f0100584:	89 ca                	mov    %ecx,%edx
f0100586:	89 d8                	mov    %ebx,%eax
f0100588:	29 d0                	sub    %edx,%eax
f010058a:	66 a3 4c 25 11 f0    	mov    %ax,0xf011254c
		break;
f0100590:	eb 64                	jmp    f01005f6 <cga_putc+0x136>
	case '\t':
		cons_putc(' ');
f0100592:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100599:	e8 7f 03 00 00       	call   f010091d <cons_putc>
		cons_putc(' ');
f010059e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01005a5:	e8 73 03 00 00       	call   f010091d <cons_putc>
		cons_putc(' ');
f01005aa:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01005b1:	e8 67 03 00 00       	call   f010091d <cons_putc>
		cons_putc(' ');
f01005b6:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01005bd:	e8 5b 03 00 00       	call   f010091d <cons_putc>
		cons_putc(' ');
f01005c2:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01005c9:	e8 4f 03 00 00       	call   f010091d <cons_putc>
		break;
f01005ce:	eb 26                	jmp    f01005f6 <cga_putc+0x136>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01005d0:	8b 0d 48 25 11 f0    	mov    0xf0112548,%ecx
f01005d6:	0f b7 05 4c 25 11 f0 	movzwl 0xf011254c,%eax
f01005dd:	8d 50 01             	lea    0x1(%eax),%edx
f01005e0:	66 89 15 4c 25 11 f0 	mov    %dx,0xf011254c
f01005e7:	0f b7 c0             	movzwl %ax,%eax
f01005ea:	01 c0                	add    %eax,%eax
f01005ec:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f01005ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01005f2:	66 89 02             	mov    %ax,(%edx)
		break;
f01005f5:	90                   	nop
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005f6:	0f b7 05 4c 25 11 f0 	movzwl 0xf011254c,%eax
f01005fd:	66 3d cf 07          	cmp    $0x7cf,%ax
f0100601:	76 5b                	jbe    f010065e <cga_putc+0x19e>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100603:	a1 48 25 11 f0       	mov    0xf0112548,%eax
f0100608:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010060e:	a1 48 25 11 f0       	mov    0xf0112548,%eax
f0100613:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010061a:	00 
f010061b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010061f:	89 04 24             	mov    %eax,(%esp)
f0100622:	e8 52 15 00 00       	call   f0101b79 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100627:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
f010062e:	eb 15                	jmp    f0100645 <cga_putc+0x185>
			crt_buf[i] = 0x0700 | ' ';
f0100630:	a1 48 25 11 f0       	mov    0xf0112548,%eax
f0100635:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100638:	01 d2                	add    %edx,%edx
f010063a:	01 d0                	add    %edx,%eax
f010063c:	66 c7 00 20 07       	movw   $0x720,(%eax)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100641:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
f0100645:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
f010064c:	7e e2                	jle    f0100630 <cga_putc+0x170>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010064e:	0f b7 05 4c 25 11 f0 	movzwl 0xf011254c,%eax
f0100655:	83 e8 50             	sub    $0x50,%eax
f0100658:	66 a3 4c 25 11 f0    	mov    %ax,0xf011254c
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010065e:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f0100663:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100666:	c6 45 ef 0e          	movb   $0xe,-0x11(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010066a:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
f010066e:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100671:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100672:	0f b7 05 4c 25 11 f0 	movzwl 0xf011254c,%eax
f0100679:	66 c1 e8 08          	shr    $0x8,%ax
f010067d:	0f b6 c0             	movzbl %al,%eax
f0100680:	8b 15 44 25 11 f0    	mov    0xf0112544,%edx
f0100686:	83 c2 01             	add    $0x1,%edx
f0100689:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010068c:	88 45 e7             	mov    %al,-0x19(%ebp)
f010068f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100693:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100696:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
f0100697:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f010069c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010069f:	c6 45 df 0f          	movb   $0xf,-0x21(%ebp)
f01006a3:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
f01006a7:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01006aa:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
f01006ab:	0f b7 05 4c 25 11 f0 	movzwl 0xf011254c,%eax
f01006b2:	0f b6 c0             	movzbl %al,%eax
f01006b5:	8b 15 44 25 11 f0    	mov    0xf0112544,%edx
f01006bb:	83 c2 01             	add    $0x1,%edx
f01006be:	89 55 d8             	mov    %edx,-0x28(%ebp)
f01006c1:	88 45 d7             	mov    %al,-0x29(%ebp)
f01006c4:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
f01006c8:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01006cb:	ee                   	out    %al,(%dx)
}
f01006cc:	83 c4 44             	add    $0x44,%esp
f01006cf:	5b                   	pop    %ebx
f01006d0:	5d                   	pop    %ebp
f01006d1:	c3                   	ret    

f01006d2 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01006d2:	55                   	push   %ebp
f01006d3:	89 e5                	mov    %esp,%ebp
f01006d5:	83 ec 38             	sub    $0x38,%esp
f01006d8:	c7 45 ec 64 00 00 00 	movl   $0x64,-0x14(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006df:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01006e2:	89 c2                	mov    %eax,%edx
f01006e4:	ec                   	in     (%dx),%al
f01006e5:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
f01006e8:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01006ec:	0f b6 c0             	movzbl %al,%eax
f01006ef:	83 e0 01             	and    $0x1,%eax
f01006f2:	85 c0                	test   %eax,%eax
f01006f4:	75 0a                	jne    f0100700 <kbd_proc_data+0x2e>
		return -1;
f01006f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01006fb:	e9 59 01 00 00       	jmp    f0100859 <kbd_proc_data+0x187>
f0100700:	c7 45 e4 60 00 00 00 	movl   $0x60,-0x1c(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100707:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010070a:	89 c2                	mov    %eax,%edx
f010070c:	ec                   	in     (%dx),%al
f010070d:	88 45 e3             	mov    %al,-0x1d(%ebp)
	return data;
f0100710:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax

	data = inb(KBDATAP);
f0100714:	88 45 f3             	mov    %al,-0xd(%ebp)

	if (data == 0xE0) {
f0100717:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
f010071b:	75 17                	jne    f0100734 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
f010071d:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f0100722:	83 c8 40             	or     $0x40,%eax
f0100725:	a3 68 27 11 f0       	mov    %eax,0xf0112768
		return 0;
f010072a:	b8 00 00 00 00       	mov    $0x0,%eax
f010072f:	e9 25 01 00 00       	jmp    f0100859 <kbd_proc_data+0x187>
	} else if (data & 0x80) {
f0100734:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100738:	84 c0                	test   %al,%al
f010073a:	79 47                	jns    f0100783 <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010073c:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f0100741:	83 e0 40             	and    $0x40,%eax
f0100744:	85 c0                	test   %eax,%eax
f0100746:	75 09                	jne    f0100751 <kbd_proc_data+0x7f>
f0100748:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f010074c:	83 e0 7f             	and    $0x7f,%eax
f010074f:	eb 04                	jmp    f0100755 <kbd_proc_data+0x83>
f0100751:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100755:	88 45 f3             	mov    %al,-0xd(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
f0100758:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f010075c:	0f b6 80 00 20 11 f0 	movzbl -0xfeee000(%eax),%eax
f0100763:	83 c8 40             	or     $0x40,%eax
f0100766:	0f b6 c0             	movzbl %al,%eax
f0100769:	f7 d0                	not    %eax
f010076b:	89 c2                	mov    %eax,%edx
f010076d:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f0100772:	21 d0                	and    %edx,%eax
f0100774:	a3 68 27 11 f0       	mov    %eax,0xf0112768
		return 0;
f0100779:	b8 00 00 00 00       	mov    $0x0,%eax
f010077e:	e9 d6 00 00 00       	jmp    f0100859 <kbd_proc_data+0x187>
	} else if (shift & E0ESC) {
f0100783:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f0100788:	83 e0 40             	and    $0x40,%eax
f010078b:	85 c0                	test   %eax,%eax
f010078d:	74 11                	je     f01007a0 <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010078f:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
		shift &= ~E0ESC;
f0100793:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f0100798:	83 e0 bf             	and    $0xffffffbf,%eax
f010079b:	a3 68 27 11 f0       	mov    %eax,0xf0112768
	}

	shift |= shiftcode[data];
f01007a0:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01007a4:	0f b6 80 00 20 11 f0 	movzbl -0xfeee000(%eax),%eax
f01007ab:	0f b6 d0             	movzbl %al,%edx
f01007ae:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f01007b3:	09 d0                	or     %edx,%eax
f01007b5:	a3 68 27 11 f0       	mov    %eax,0xf0112768
	shift ^= togglecode[data];
f01007ba:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01007be:	0f b6 80 00 21 11 f0 	movzbl -0xfeedf00(%eax),%eax
f01007c5:	0f b6 d0             	movzbl %al,%edx
f01007c8:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f01007cd:	31 d0                	xor    %edx,%eax
f01007cf:	a3 68 27 11 f0       	mov    %eax,0xf0112768

	c = charcode[shift & (CTL | SHIFT)][data];
f01007d4:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f01007d9:	83 e0 03             	and    $0x3,%eax
f01007dc:	8b 14 85 00 25 11 f0 	mov    -0xfeedb00(,%eax,4),%edx
f01007e3:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01007e7:	01 d0                	add    %edx,%eax
f01007e9:	0f b6 00             	movzbl (%eax),%eax
f01007ec:	0f b6 c0             	movzbl %al,%eax
f01007ef:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (shift & CAPSLOCK) {
f01007f2:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f01007f7:	83 e0 08             	and    $0x8,%eax
f01007fa:	85 c0                	test   %eax,%eax
f01007fc:	74 22                	je     f0100820 <kbd_proc_data+0x14e>
		if ('a' <= c && c <= 'z')
f01007fe:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
f0100802:	7e 0c                	jle    f0100810 <kbd_proc_data+0x13e>
f0100804:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
f0100808:	7f 06                	jg     f0100810 <kbd_proc_data+0x13e>
			c += 'A' - 'a';
f010080a:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
f010080e:	eb 10                	jmp    f0100820 <kbd_proc_data+0x14e>
		else if ('A' <= c && c <= 'Z')
f0100810:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
f0100814:	7e 0a                	jle    f0100820 <kbd_proc_data+0x14e>
f0100816:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
f010081a:	7f 04                	jg     f0100820 <kbd_proc_data+0x14e>
			c += 'a' - 'A';
f010081c:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100820:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f0100825:	f7 d0                	not    %eax
f0100827:	83 e0 06             	and    $0x6,%eax
f010082a:	85 c0                	test   %eax,%eax
f010082c:	75 28                	jne    f0100856 <kbd_proc_data+0x184>
f010082e:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
f0100835:	75 1f                	jne    f0100856 <kbd_proc_data+0x184>
		cprintf("Rebooting!\n");
f0100837:	c7 04 24 86 21 10 f0 	movl   $0xf0102186,(%esp)
f010083e:	e8 b4 04 00 00       	call   f0100cf7 <cprintf>
f0100843:	c7 45 dc 92 00 00 00 	movl   $0x92,-0x24(%ebp)
f010084a:	c6 45 db 03          	movb   $0x3,-0x25(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010084e:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
f0100852:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100855:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100856:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0100859:	c9                   	leave  
f010085a:	c3                   	ret    

f010085b <kbd_intr>:

void
kbd_intr(void)
{
f010085b:	55                   	push   %ebp
f010085c:	89 e5                	mov    %esp,%ebp
f010085e:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
f0100861:	c7 04 24 d2 06 10 f0 	movl   $0xf01006d2,(%esp)
f0100868:	e8 07 00 00 00       	call   f0100874 <cons_intr>
}
f010086d:	c9                   	leave  
f010086e:	c3                   	ret    

f010086f <kbd_init>:

static void
kbd_init(void)
{
f010086f:	55                   	push   %ebp
f0100870:	89 e5                	mov    %esp,%ebp
}
f0100872:	5d                   	pop    %ebp
f0100873:	c3                   	ret    

f0100874 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100874:	55                   	push   %ebp
f0100875:	89 e5                	mov    %esp,%ebp
f0100877:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = (*proc)()) != -1) {
f010087a:	eb 35                	jmp    f01008b1 <cons_intr+0x3d>
		if (c == 0)
f010087c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100880:	75 02                	jne    f0100884 <cons_intr+0x10>
			continue;
f0100882:	eb 2d                	jmp    f01008b1 <cons_intr+0x3d>
		cons.buf[cons.wpos++] = c;
f0100884:	a1 64 27 11 f0       	mov    0xf0112764,%eax
f0100889:	8d 50 01             	lea    0x1(%eax),%edx
f010088c:	89 15 64 27 11 f0    	mov    %edx,0xf0112764
f0100892:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100895:	88 90 60 25 11 f0    	mov    %dl,-0xfeedaa0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010089b:	a1 64 27 11 f0       	mov    0xf0112764,%eax
f01008a0:	3d 00 02 00 00       	cmp    $0x200,%eax
f01008a5:	75 0a                	jne    f01008b1 <cons_intr+0x3d>
			cons.wpos = 0;
f01008a7:	c7 05 64 27 11 f0 00 	movl   $0x0,0xf0112764
f01008ae:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01008b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01008b4:	ff d0                	call   *%eax
f01008b6:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01008b9:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
f01008bd:	75 bd                	jne    f010087c <cons_intr+0x8>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01008bf:	c9                   	leave  
f01008c0:	c3                   	ret    

f01008c1 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01008c1:	55                   	push   %ebp
f01008c2:	89 e5                	mov    %esp,%ebp
f01008c4:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01008c7:	e8 6c f9 ff ff       	call   f0100238 <serial_intr>
	kbd_intr();
f01008cc:	e8 8a ff ff ff       	call   f010085b <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01008d1:	8b 15 60 27 11 f0    	mov    0xf0112760,%edx
f01008d7:	a1 64 27 11 f0       	mov    0xf0112764,%eax
f01008dc:	39 c2                	cmp    %eax,%edx
f01008de:	74 36                	je     f0100916 <cons_getc+0x55>
		c = cons.buf[cons.rpos++];
f01008e0:	a1 60 27 11 f0       	mov    0xf0112760,%eax
f01008e5:	8d 50 01             	lea    0x1(%eax),%edx
f01008e8:	89 15 60 27 11 f0    	mov    %edx,0xf0112760
f01008ee:	0f b6 80 60 25 11 f0 	movzbl -0xfeedaa0(%eax),%eax
f01008f5:	0f b6 c0             	movzbl %al,%eax
f01008f8:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if (cons.rpos == CONSBUFSIZE)
f01008fb:	a1 60 27 11 f0       	mov    0xf0112760,%eax
f0100900:	3d 00 02 00 00       	cmp    $0x200,%eax
f0100905:	75 0a                	jne    f0100911 <cons_getc+0x50>
			cons.rpos = 0;
f0100907:	c7 05 60 27 11 f0 00 	movl   $0x0,0xf0112760
f010090e:	00 00 00 
		return c;
f0100911:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100914:	eb 05                	jmp    f010091b <cons_getc+0x5a>
	}
	return 0;
f0100916:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010091b:	c9                   	leave  
f010091c:	c3                   	ret    

f010091d <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
f010091d:	55                   	push   %ebp
f010091e:	89 e5                	mov    %esp,%ebp
f0100920:	83 ec 18             	sub    $0x18,%esp
	serial_putc(c);
f0100923:	8b 45 08             	mov    0x8(%ebp),%eax
f0100926:	89 04 24             	mov    %eax,(%esp)
f0100929:	e8 29 f9 ff ff       	call   f0100257 <serial_putc>
	lpt_putc(c);
f010092e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100931:	89 04 24             	mov    %eax,(%esp)
f0100934:	e8 42 fa ff ff       	call   f010037b <lpt_putc>
	cga_putc(c);
f0100939:	8b 45 08             	mov    0x8(%ebp),%eax
f010093c:	89 04 24             	mov    %eax,(%esp)
f010093f:	e8 7c fb ff ff       	call   f01004c0 <cga_putc>
}
f0100944:	c9                   	leave  
f0100945:	c3                   	ret    

f0100946 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100946:	55                   	push   %ebp
f0100947:	89 e5                	mov    %esp,%ebp
f0100949:	83 ec 18             	sub    $0x18,%esp
	cga_init();
f010094c:	e8 a3 fa ff ff       	call   f01003f4 <cga_init>
	kbd_init();
f0100951:	e8 19 ff ff ff       	call   f010086f <kbd_init>
	serial_init();
f0100956:	e8 55 f9 ff ff       	call   f01002b0 <serial_init>

	if (!serial_exists)
f010095b:	0f b6 05 40 25 11 f0 	movzbl 0xf0112540,%eax
f0100962:	83 f0 01             	xor    $0x1,%eax
f0100965:	84 c0                	test   %al,%al
f0100967:	74 0c                	je     f0100975 <cons_init+0x2f>
		cprintf("Serial port does not exist!\n");
f0100969:	c7 04 24 92 21 10 f0 	movl   $0xf0102192,(%esp)
f0100970:	e8 82 03 00 00       	call   f0100cf7 <cprintf>
}
f0100975:	c9                   	leave  
f0100976:	c3                   	ret    

f0100977 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100977:	55                   	push   %ebp
f0100978:	89 e5                	mov    %esp,%ebp
f010097a:	83 ec 18             	sub    $0x18,%esp
	cons_putc(c);
f010097d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100980:	89 04 24             	mov    %eax,(%esp)
f0100983:	e8 95 ff ff ff       	call   f010091d <cons_putc>
}
f0100988:	c9                   	leave  
f0100989:	c3                   	ret    

f010098a <getchar>:

int
getchar(void)
{
f010098a:	55                   	push   %ebp
f010098b:	89 e5                	mov    %esp,%ebp
f010098d:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100990:	e8 2c ff ff ff       	call   f01008c1 <cons_getc>
f0100995:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100998:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f010099c:	74 f2                	je     f0100990 <getchar+0x6>
		/* do nothing */;
	return c;
f010099e:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01009a1:	c9                   	leave  
f01009a2:	c3                   	ret    

f01009a3 <iscons>:

int
iscons(int fdnum)
{
f01009a3:	55                   	push   %ebp
f01009a4:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
f01009a6:	b8 01 00 00 00       	mov    $0x1,%eax
}
f01009ab:	5d                   	pop    %ebp
f01009ac:	c3                   	ret    

f01009ad <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01009ad:	55                   	push   %ebp
f01009ae:	89 e5                	mov    %esp,%ebp
f01009b0:	83 ec 28             	sub    $0x28,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f01009b3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f01009ba:	eb 3e                	jmp    f01009fa <mon_help+0x4d>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01009bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01009bf:	89 d0                	mov    %edx,%eax
f01009c1:	01 c0                	add    %eax,%eax
f01009c3:	01 d0                	add    %edx,%eax
f01009c5:	c1 e0 02             	shl    $0x2,%eax
f01009c8:	05 14 25 11 f0       	add    $0xf0112514,%eax
f01009cd:	8b 08                	mov    (%eax),%ecx
f01009cf:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01009d2:	89 d0                	mov    %edx,%eax
f01009d4:	01 c0                	add    %eax,%eax
f01009d6:	01 d0                	add    %edx,%eax
f01009d8:	c1 e0 02             	shl    $0x2,%eax
f01009db:	05 10 25 11 f0       	add    $0xf0112510,%eax
f01009e0:	8b 00                	mov    (%eax),%eax
f01009e2:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01009e6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009ea:	c7 04 24 01 22 10 f0 	movl   $0xf0102201,(%esp)
f01009f1:	e8 01 03 00 00       	call   f0100cf7 <cprintf>
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f01009f6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
f01009fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009fd:	83 f8 01             	cmp    $0x1,%eax
f0100a00:	76 ba                	jbe    f01009bc <mon_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
f0100a02:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100a07:	c9                   	leave  
f0100a08:	c3                   	ret    

f0100a09 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100a09:	55                   	push   %ebp
f0100a0a:	89 e5                	mov    %esp,%ebp
f0100a0c:	83 ec 28             	sub    $0x28,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100a0f:	c7 04 24 0a 22 10 f0 	movl   $0xf010220a,(%esp)
f0100a16:	e8 dc 02 00 00       	call   f0100cf7 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100a1b:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100a22:	00 
f0100a23:	c7 04 24 24 22 10 f0 	movl   $0xf0102224,(%esp)
f0100a2a:	e8 c8 02 00 00       	call   f0100cf7 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100a2f:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100a36:	00 
f0100a37:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100a3e:	f0 
f0100a3f:	c7 04 24 4c 22 10 f0 	movl   $0xf010224c,(%esp)
f0100a46:	e8 ac 02 00 00       	call   f0100cf7 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100a4b:	c7 44 24 08 e7 20 10 	movl   $0x1020e7,0x8(%esp)
f0100a52:	00 
f0100a53:	c7 44 24 04 e7 20 10 	movl   $0xf01020e7,0x4(%esp)
f0100a5a:	f0 
f0100a5b:	c7 04 24 70 22 10 f0 	movl   $0xf0102270,(%esp)
f0100a62:	e8 90 02 00 00       	call   f0100cf7 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100a67:	c7 44 24 08 28 25 11 	movl   $0x112528,0x8(%esp)
f0100a6e:	00 
f0100a6f:	c7 44 24 04 28 25 11 	movl   $0xf0112528,0x4(%esp)
f0100a76:	f0 
f0100a77:	c7 04 24 94 22 10 f0 	movl   $0xf0102294,(%esp)
f0100a7e:	e8 74 02 00 00       	call   f0100cf7 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100a83:	c7 44 24 08 84 2b 11 	movl   $0x112b84,0x8(%esp)
f0100a8a:	00 
f0100a8b:	c7 44 24 04 84 2b 11 	movl   $0xf0112b84,0x4(%esp)
f0100a92:	f0 
f0100a93:	c7 04 24 b8 22 10 f0 	movl   $0xf01022b8,(%esp)
f0100a9a:	e8 58 02 00 00       	call   f0100cf7 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100a9f:	c7 45 f4 00 04 00 00 	movl   $0x400,-0xc(%ebp)
f0100aa6:	b8 0c 00 10 f0       	mov    $0xf010000c,%eax
f0100aab:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100aae:	29 c2                	sub    %eax,%edx
f0100ab0:	b8 84 2b 11 f0       	mov    $0xf0112b84,%eax
f0100ab5:	83 e8 01             	sub    $0x1,%eax
f0100ab8:	01 d0                	add    %edx,%eax
f0100aba:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100abd:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ac0:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ac5:	f7 75 f4             	divl   -0xc(%ebp)
f0100ac8:	89 d0                	mov    %edx,%eax
f0100aca:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100acd:	29 c2                	sub    %eax,%edx
f0100acf:	89 d0                	mov    %edx,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100ad1:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100ad7:	85 c0                	test   %eax,%eax
f0100ad9:	0f 48 c2             	cmovs  %edx,%eax
f0100adc:	c1 f8 0a             	sar    $0xa,%eax
f0100adf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ae3:	c7 04 24 dc 22 10 f0 	movl   $0xf01022dc,(%esp)
f0100aea:	e8 08 02 00 00       	call   f0100cf7 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
f0100aef:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100af4:	c9                   	leave  
f0100af5:	c3                   	ret    

f0100af6 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100af6:	55                   	push   %ebp
f0100af7:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
f0100af9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100afe:	5d                   	pop    %ebp
f0100aff:	c3                   	ret    

f0100b00 <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f0100b00:	55                   	push   %ebp
f0100b01:	89 e5                	mov    %esp,%ebp
f0100b03:	83 ec 68             	sub    $0x68,%esp
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100b06:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	argv[argc] = 0;
f0100b0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b10:	c7 44 85 b0 00 00 00 	movl   $0x0,-0x50(%ebp,%eax,4)
f0100b17:	00 
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100b18:	eb 0c                	jmp    f0100b26 <runcmd+0x26>
			*buf++ = 0;
f0100b1a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b1d:	8d 50 01             	lea    0x1(%eax),%edx
f0100b20:	89 55 08             	mov    %edx,0x8(%ebp)
f0100b23:	c6 00 00             	movb   $0x0,(%eax)
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100b26:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b29:	0f b6 00             	movzbl (%eax),%eax
f0100b2c:	84 c0                	test   %al,%al
f0100b2e:	74 1d                	je     f0100b4d <runcmd+0x4d>
f0100b30:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b33:	0f b6 00             	movzbl (%eax),%eax
f0100b36:	0f be c0             	movsbl %al,%eax
f0100b39:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b3d:	c7 04 24 06 23 10 f0 	movl   $0xf0102306,(%esp)
f0100b44:	e8 61 0f 00 00       	call   f0101aaa <strchr>
f0100b49:	85 c0                	test   %eax,%eax
f0100b4b:	75 cd                	jne    f0100b1a <runcmd+0x1a>
			*buf++ = 0;
		if (*buf == 0)
f0100b4d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b50:	0f b6 00             	movzbl (%eax),%eax
f0100b53:	84 c0                	test   %al,%al
f0100b55:	75 14                	jne    f0100b6b <runcmd+0x6b>
			break;
f0100b57:	90                   	nop
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;
f0100b58:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b5b:	c7 44 85 b0 00 00 00 	movl   $0x0,-0x50(%ebp,%eax,4)
f0100b62:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100b63:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100b67:	75 70                	jne    f0100bd9 <runcmd+0xd9>
f0100b69:	eb 67                	jmp    f0100bd2 <runcmd+0xd2>
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100b6b:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
f0100b6f:	75 1e                	jne    f0100b8f <runcmd+0x8f>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100b71:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100b78:	00 
f0100b79:	c7 04 24 0b 23 10 f0 	movl   $0xf010230b,(%esp)
f0100b80:	e8 72 01 00 00       	call   f0100cf7 <cprintf>
			return 0;
f0100b85:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b8a:	e9 c8 00 00 00       	jmp    f0100c57 <runcmd+0x157>
		}
		argv[argc++] = buf;
f0100b8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b92:	8d 50 01             	lea    0x1(%eax),%edx
f0100b95:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0100b98:	8b 55 08             	mov    0x8(%ebp),%edx
f0100b9b:	89 54 85 b0          	mov    %edx,-0x50(%ebp,%eax,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100b9f:	eb 04                	jmp    f0100ba5 <runcmd+0xa5>
			buf++;
f0100ba1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100ba5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ba8:	0f b6 00             	movzbl (%eax),%eax
f0100bab:	84 c0                	test   %al,%al
f0100bad:	74 1d                	je     f0100bcc <runcmd+0xcc>
f0100baf:	8b 45 08             	mov    0x8(%ebp),%eax
f0100bb2:	0f b6 00             	movzbl (%eax),%eax
f0100bb5:	0f be c0             	movsbl %al,%eax
f0100bb8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bbc:	c7 04 24 06 23 10 f0 	movl   $0xf0102306,(%esp)
f0100bc3:	e8 e2 0e 00 00       	call   f0101aaa <strchr>
f0100bc8:	85 c0                	test   %eax,%eax
f0100bca:	74 d5                	je     f0100ba1 <runcmd+0xa1>
			buf++;
	}
f0100bcc:	90                   	nop
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100bcd:	e9 54 ff ff ff       	jmp    f0100b26 <runcmd+0x26>
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
f0100bd2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bd7:	eb 7e                	jmp    f0100c57 <runcmd+0x157>
	for (i = 0; i < NCOMMANDS; i++) {
f0100bd9:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f0100be0:	eb 55                	jmp    f0100c37 <runcmd+0x137>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100be2:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100be5:	89 d0                	mov    %edx,%eax
f0100be7:	01 c0                	add    %eax,%eax
f0100be9:	01 d0                	add    %edx,%eax
f0100beb:	c1 e0 02             	shl    $0x2,%eax
f0100bee:	05 10 25 11 f0       	add    $0xf0112510,%eax
f0100bf3:	8b 10                	mov    (%eax),%edx
f0100bf5:	8b 45 b0             	mov    -0x50(%ebp),%eax
f0100bf8:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100bfc:	89 04 24             	mov    %eax,(%esp)
f0100bff:	e8 11 0e 00 00       	call   f0101a15 <strcmp>
f0100c04:	85 c0                	test   %eax,%eax
f0100c06:	75 2b                	jne    f0100c33 <runcmd+0x133>
			return commands[i].func(argc, argv, tf);
f0100c08:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100c0b:	89 d0                	mov    %edx,%eax
f0100c0d:	01 c0                	add    %eax,%eax
f0100c0f:	01 d0                	add    %edx,%eax
f0100c11:	c1 e0 02             	shl    $0x2,%eax
f0100c14:	05 18 25 11 f0       	add    $0xf0112518,%eax
f0100c19:	8b 00                	mov    (%eax),%eax
f0100c1b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c1e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100c22:	8d 55 b0             	lea    -0x50(%ebp),%edx
f0100c25:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c29:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100c2c:	89 14 24             	mov    %edx,(%esp)
f0100c2f:	ff d0                	call   *%eax
f0100c31:	eb 24                	jmp    f0100c57 <runcmd+0x157>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100c33:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
f0100c37:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100c3a:	83 f8 01             	cmp    $0x1,%eax
f0100c3d:	76 a3                	jbe    f0100be2 <runcmd+0xe2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100c3f:	8b 45 b0             	mov    -0x50(%ebp),%eax
f0100c42:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c46:	c7 04 24 28 23 10 f0 	movl   $0xf0102328,(%esp)
f0100c4d:	e8 a5 00 00 00       	call   f0100cf7 <cprintf>
	return 0;
f0100c52:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c57:	c9                   	leave  
f0100c58:	c3                   	ret    

f0100c59 <monitor>:

void
monitor(struct Trapframe *tf)
{
f0100c59:	55                   	push   %ebp
f0100c5a:	89 e5                	mov    %esp,%ebp
f0100c5c:	83 ec 28             	sub    $0x28,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100c5f:	c7 04 24 40 23 10 f0 	movl   $0xf0102340,(%esp)
f0100c66:	e8 8c 00 00 00       	call   f0100cf7 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100c6b:	c7 04 24 64 23 10 f0 	movl   $0xf0102364,(%esp)
f0100c72:	e8 80 00 00 00       	call   f0100cf7 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100c77:	c7 04 24 89 23 10 f0 	movl   $0xf0102389,(%esp)
f0100c7e:	e8 51 0b 00 00       	call   f01017d4 <readline>
f0100c83:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if (buf != NULL)
f0100c86:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100c8a:	74 18                	je     f0100ca4 <monitor+0x4b>
			if (runcmd(buf, tf) < 0)
f0100c8c:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c8f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c93:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100c96:	89 04 24             	mov    %eax,(%esp)
f0100c99:	e8 62 fe ff ff       	call   f0100b00 <runcmd>
f0100c9e:	85 c0                	test   %eax,%eax
f0100ca0:	79 02                	jns    f0100ca4 <monitor+0x4b>
				break;
f0100ca2:	eb 02                	jmp    f0100ca6 <monitor+0x4d>
	}
f0100ca4:	eb d1                	jmp    f0100c77 <monitor+0x1e>
}
f0100ca6:	c9                   	leave  
f0100ca7:	c3                   	ret    

f0100ca8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100ca8:	55                   	push   %ebp
f0100ca9:	89 e5                	mov    %esp,%ebp
f0100cab:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100cae:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cb1:	89 04 24             	mov    %eax,(%esp)
f0100cb4:	e8 be fc ff ff       	call   f0100977 <cputchar>
	*cnt++;
f0100cb9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100cbc:	83 c0 04             	add    $0x4,%eax
f0100cbf:	89 45 0c             	mov    %eax,0xc(%ebp)
}
f0100cc2:	c9                   	leave  
f0100cc3:	c3                   	ret    

f0100cc4 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100cc4:	55                   	push   %ebp
f0100cc5:	89 e5                	mov    %esp,%ebp
f0100cc7:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100cca:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100cd1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100cd4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cd8:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cdb:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cdf:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100ce2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ce6:	c7 04 24 a8 0c 10 f0 	movl   $0xf0100ca8,(%esp)
f0100ced:	e8 df 05 00 00       	call   f01012d1 <vprintfmt>
	return cnt;
f0100cf2:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0100cf5:	c9                   	leave  
f0100cf6:	c3                   	ret    

f0100cf7 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100cf7:	55                   	push   %ebp
f0100cf8:	89 e5                	mov    %esp,%ebp
f0100cfa:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100cfd:	8d 45 0c             	lea    0xc(%ebp),%eax
f0100d00:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
f0100d03:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100d06:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d0a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d0d:	89 04 24             	mov    %eax,(%esp)
f0100d10:	e8 af ff ff ff       	call   f0100cc4 <vcprintf>
f0100d15:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
f0100d18:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0100d1b:	c9                   	leave  
f0100d1c:	c3                   	ret    

f0100d1d <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100d1d:	55                   	push   %ebp
f0100d1e:	89 e5                	mov    %esp,%ebp
f0100d20:	83 ec 20             	sub    $0x20,%esp
	int l = *region_left, r = *region_right, any_matches = 0;
f0100d23:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d26:	8b 00                	mov    (%eax),%eax
f0100d28:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0100d2b:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d2e:	8b 00                	mov    (%eax),%eax
f0100d30:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0100d33:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	while (l <= r) {
f0100d3a:	e9 d2 00 00 00       	jmp    f0100e11 <stab_binsearch+0xf4>
		int true_m = (l + r) / 2, m = true_m;
f0100d3f:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100d42:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100d45:	01 d0                	add    %edx,%eax
f0100d47:	89 c2                	mov    %eax,%edx
f0100d49:	c1 ea 1f             	shr    $0x1f,%edx
f0100d4c:	01 d0                	add    %edx,%eax
f0100d4e:	d1 f8                	sar    %eax
f0100d50:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100d53:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100d56:	89 45 f0             	mov    %eax,-0x10(%ebp)

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100d59:	eb 04                	jmp    f0100d5f <stab_binsearch+0x42>
			m--;
f0100d5b:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100d5f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100d62:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0100d65:	7c 1f                	jl     f0100d86 <stab_binsearch+0x69>
f0100d67:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100d6a:	89 d0                	mov    %edx,%eax
f0100d6c:	01 c0                	add    %eax,%eax
f0100d6e:	01 d0                	add    %edx,%eax
f0100d70:	c1 e0 02             	shl    $0x2,%eax
f0100d73:	89 c2                	mov    %eax,%edx
f0100d75:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d78:	01 d0                	add    %edx,%eax
f0100d7a:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f0100d7e:	0f b6 c0             	movzbl %al,%eax
f0100d81:	3b 45 14             	cmp    0x14(%ebp),%eax
f0100d84:	75 d5                	jne    f0100d5b <stab_binsearch+0x3e>
			m--;
		if (m < l) {	// no match in [l, m]
f0100d86:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100d89:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0100d8c:	7d 0b                	jge    f0100d99 <stab_binsearch+0x7c>
			l = true_m + 1;
f0100d8e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100d91:	83 c0 01             	add    $0x1,%eax
f0100d94:	89 45 fc             	mov    %eax,-0x4(%ebp)
			continue;
f0100d97:	eb 78                	jmp    f0100e11 <stab_binsearch+0xf4>
		}

		// actual binary search
		any_matches = 1;
f0100d99:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
		if (stabs[m].n_value < addr) {
f0100da0:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100da3:	89 d0                	mov    %edx,%eax
f0100da5:	01 c0                	add    %eax,%eax
f0100da7:	01 d0                	add    %edx,%eax
f0100da9:	c1 e0 02             	shl    $0x2,%eax
f0100dac:	89 c2                	mov    %eax,%edx
f0100dae:	8b 45 08             	mov    0x8(%ebp),%eax
f0100db1:	01 d0                	add    %edx,%eax
f0100db3:	8b 40 08             	mov    0x8(%eax),%eax
f0100db6:	3b 45 18             	cmp    0x18(%ebp),%eax
f0100db9:	73 13                	jae    f0100dce <stab_binsearch+0xb1>
			*region_left = m;
f0100dbb:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100dbe:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100dc1:	89 10                	mov    %edx,(%eax)
			l = true_m + 1;
f0100dc3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100dc6:	83 c0 01             	add    $0x1,%eax
f0100dc9:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0100dcc:	eb 43                	jmp    f0100e11 <stab_binsearch+0xf4>
		} else if (stabs[m].n_value > addr) {
f0100dce:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100dd1:	89 d0                	mov    %edx,%eax
f0100dd3:	01 c0                	add    %eax,%eax
f0100dd5:	01 d0                	add    %edx,%eax
f0100dd7:	c1 e0 02             	shl    $0x2,%eax
f0100dda:	89 c2                	mov    %eax,%edx
f0100ddc:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ddf:	01 d0                	add    %edx,%eax
f0100de1:	8b 40 08             	mov    0x8(%eax),%eax
f0100de4:	3b 45 18             	cmp    0x18(%ebp),%eax
f0100de7:	76 16                	jbe    f0100dff <stab_binsearch+0xe2>
			*region_right = m - 1;
f0100de9:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100dec:	8d 50 ff             	lea    -0x1(%eax),%edx
f0100def:	8b 45 10             	mov    0x10(%ebp),%eax
f0100df2:	89 10                	mov    %edx,(%eax)
			r = m - 1;
f0100df4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100df7:	83 e8 01             	sub    $0x1,%eax
f0100dfa:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0100dfd:	eb 12                	jmp    f0100e11 <stab_binsearch+0xf4>
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100dff:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e02:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100e05:	89 10                	mov    %edx,(%eax)
			l = m;
f0100e07:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100e0a:	89 45 fc             	mov    %eax,-0x4(%ebp)
			addr++;
f0100e0d:	83 45 18 01          	addl   $0x1,0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100e11:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100e14:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f0100e17:	0f 8e 22 ff ff ff    	jle    f0100d3f <stab_binsearch+0x22>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100e1d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100e21:	75 0f                	jne    f0100e32 <stab_binsearch+0x115>
		*region_right = *region_left - 1;
f0100e23:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e26:	8b 00                	mov    (%eax),%eax
f0100e28:	8d 50 ff             	lea    -0x1(%eax),%edx
f0100e2b:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e2e:	89 10                	mov    %edx,(%eax)
f0100e30:	eb 3f                	jmp    f0100e71 <stab_binsearch+0x154>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100e32:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e35:	8b 00                	mov    (%eax),%eax
f0100e37:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0100e3a:	eb 04                	jmp    f0100e40 <stab_binsearch+0x123>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100e3c:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100e40:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e43:	8b 00                	mov    (%eax),%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100e45:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0100e48:	7d 1f                	jge    f0100e69 <stab_binsearch+0x14c>
		     l > *region_left && stabs[l].n_type != type;
f0100e4a:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100e4d:	89 d0                	mov    %edx,%eax
f0100e4f:	01 c0                	add    %eax,%eax
f0100e51:	01 d0                	add    %edx,%eax
f0100e53:	c1 e0 02             	shl    $0x2,%eax
f0100e56:	89 c2                	mov    %eax,%edx
f0100e58:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e5b:	01 d0                	add    %edx,%eax
f0100e5d:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f0100e61:	0f b6 c0             	movzbl %al,%eax
f0100e64:	3b 45 14             	cmp    0x14(%ebp),%eax
f0100e67:	75 d3                	jne    f0100e3c <stab_binsearch+0x11f>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100e69:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e6c:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100e6f:	89 10                	mov    %edx,(%eax)
	}
}
f0100e71:	c9                   	leave  
f0100e72:	c3                   	ret    

f0100e73 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100e73:	55                   	push   %ebp
f0100e74:	89 e5                	mov    %esp,%ebp
f0100e76:	83 ec 58             	sub    $0x58,%esp
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100e79:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e7c:	c7 00 8d 23 10 f0    	movl   $0xf010238d,(%eax)
	info->eip_line = 0;
f0100e82:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e85:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	info->eip_fn_name = "<unknown>";
f0100e8c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e8f:	c7 40 08 8d 23 10 f0 	movl   $0xf010238d,0x8(%eax)
	info->eip_fn_namelen = 9;
f0100e96:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e99:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
	info->eip_fn_addr = addr;
f0100ea0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ea3:	8b 55 08             	mov    0x8(%ebp),%edx
f0100ea6:	89 50 10             	mov    %edx,0x10(%eax)
	info->eip_fn_narg = 0;
f0100ea9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100eac:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100eb3:	81 7d 08 ff ff 7f ef 	cmpl   $0xef7fffff,0x8(%ebp)
f0100eba:	76 26                	jbe    f0100ee2 <debuginfo_eip+0x6f>
		stabs = __STAB_BEGIN__;
f0100ebc:	c7 45 f0 f0 25 10 f0 	movl   $0xf01025f0,-0x10(%ebp)
		stab_end = __STAB_END__;
f0100ec3:	c7 45 ec 40 66 10 f0 	movl   $0xf0106640,-0x14(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0100eca:	c7 45 e8 41 66 10 f0 	movl   $0xf0106641,-0x18(%ebp)
		stabstr_end = __STABSTR_END__;
f0100ed1:	c7 45 e4 a4 7f 10 f0 	movl   $0xf0107fa4,-0x1c(%ebp)
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ed8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100edb:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f0100ede:	76 2b                	jbe    f0100f0b <debuginfo_eip+0x98>
f0100ee0:	eb 1c                	jmp    f0100efe <debuginfo_eip+0x8b>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100ee2:	c7 44 24 08 97 23 10 	movl   $0xf0102397,0x8(%esp)
f0100ee9:	f0 
f0100eea:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100ef1:	00 
f0100ef2:	c7 04 24 a4 23 10 f0 	movl   $0xf01023a4,(%esp)
f0100ef9:	e8 01 f2 ff ff       	call   f01000ff <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100efe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f01:	83 e8 01             	sub    $0x1,%eax
f0100f04:	0f b6 00             	movzbl (%eax),%eax
f0100f07:	84 c0                	test   %al,%al
f0100f09:	74 0a                	je     f0100f15 <debuginfo_eip+0xa2>
		return -1;
f0100f0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100f10:	e9 46 02 00 00       	jmp    f010115b <debuginfo_eip+0x2e8>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100f15:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100f1c:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0100f1f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f22:	29 c2                	sub    %eax,%edx
f0100f24:	89 d0                	mov    %edx,%eax
f0100f26:	c1 f8 02             	sar    $0x2,%eax
f0100f29:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100f2f:	83 e8 01             	sub    $0x1,%eax
f0100f32:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100f35:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f38:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100f3c:	c7 44 24 0c 64 00 00 	movl   $0x64,0xc(%esp)
f0100f43:	00 
f0100f44:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0100f47:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f4b:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0100f4e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f52:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f55:	89 04 24             	mov    %eax,(%esp)
f0100f58:	e8 c0 fd ff ff       	call   f0100d1d <stab_binsearch>
	if (lfile == 0)
f0100f5d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100f60:	85 c0                	test   %eax,%eax
f0100f62:	75 0a                	jne    f0100f6e <debuginfo_eip+0xfb>
		return -1;
f0100f64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100f69:	e9 ed 01 00 00       	jmp    f010115b <debuginfo_eip+0x2e8>

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100f6e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100f71:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	rfun = rfile;
f0100f74:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f77:	89 45 d0             	mov    %eax,-0x30(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100f7a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f7d:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100f81:	c7 44 24 0c 24 00 00 	movl   $0x24,0xc(%esp)
f0100f88:	00 
f0100f89:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100f8c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f90:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0100f93:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f97:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f9a:	89 04 24             	mov    %eax,(%esp)
f0100f9d:	e8 7b fd ff ff       	call   f0100d1d <stab_binsearch>

	if (lfun <= rfun) {
f0100fa2:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100fa5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100fa8:	39 c2                	cmp    %eax,%edx
f0100faa:	7f 7c                	jg     f0101028 <debuginfo_eip+0x1b5>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100fac:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100faf:	89 c2                	mov    %eax,%edx
f0100fb1:	89 d0                	mov    %edx,%eax
f0100fb3:	01 c0                	add    %eax,%eax
f0100fb5:	01 d0                	add    %edx,%eax
f0100fb7:	c1 e0 02             	shl    $0x2,%eax
f0100fba:	89 c2                	mov    %eax,%edx
f0100fbc:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100fbf:	01 d0                	add    %edx,%eax
f0100fc1:	8b 10                	mov    (%eax),%edx
f0100fc3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100fc6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100fc9:	29 c1                	sub    %eax,%ecx
f0100fcb:	89 c8                	mov    %ecx,%eax
f0100fcd:	39 c2                	cmp    %eax,%edx
f0100fcf:	73 22                	jae    f0100ff3 <debuginfo_eip+0x180>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100fd1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100fd4:	89 c2                	mov    %eax,%edx
f0100fd6:	89 d0                	mov    %edx,%eax
f0100fd8:	01 c0                	add    %eax,%eax
f0100fda:	01 d0                	add    %edx,%eax
f0100fdc:	c1 e0 02             	shl    $0x2,%eax
f0100fdf:	89 c2                	mov    %eax,%edx
f0100fe1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100fe4:	01 d0                	add    %edx,%eax
f0100fe6:	8b 10                	mov    (%eax),%edx
f0100fe8:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100feb:	01 c2                	add    %eax,%edx
f0100fed:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ff0:	89 50 08             	mov    %edx,0x8(%eax)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100ff3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ff6:	89 c2                	mov    %eax,%edx
f0100ff8:	89 d0                	mov    %edx,%eax
f0100ffa:	01 c0                	add    %eax,%eax
f0100ffc:	01 d0                	add    %edx,%eax
f0100ffe:	c1 e0 02             	shl    $0x2,%eax
f0101001:	89 c2                	mov    %eax,%edx
f0101003:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101006:	01 d0                	add    %edx,%eax
f0101008:	8b 50 08             	mov    0x8(%eax),%edx
f010100b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010100e:	89 50 10             	mov    %edx,0x10(%eax)
		addr -= info->eip_fn_addr;
f0101011:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101014:	8b 40 10             	mov    0x10(%eax),%eax
f0101017:	29 45 08             	sub    %eax,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f010101a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010101d:	89 45 f4             	mov    %eax,-0xc(%ebp)
		rline = rfun;
f0101020:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101023:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101026:	eb 15                	jmp    f010103d <debuginfo_eip+0x1ca>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0101028:	8b 45 0c             	mov    0xc(%ebp),%eax
f010102b:	8b 55 08             	mov    0x8(%ebp),%edx
f010102e:	89 50 10             	mov    %edx,0x10(%eax)
		lline = lfile;
f0101031:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101034:	89 45 f4             	mov    %eax,-0xc(%ebp)
		rline = rfile;
f0101037:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010103a:	89 45 e0             	mov    %eax,-0x20(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010103d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101040:	8b 40 08             	mov    0x8(%eax),%eax
f0101043:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f010104a:	00 
f010104b:	89 04 24             	mov    %eax,(%esp)
f010104e:	e8 8a 0a 00 00       	call   f0101add <strfind>
f0101053:	89 c2                	mov    %eax,%edx
f0101055:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101058:	8b 40 08             	mov    0x8(%eax),%eax
f010105b:	29 c2                	sub    %eax,%edx
f010105d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101060:	89 50 0c             	mov    %edx,0xc(%eax)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101063:	eb 04                	jmp    f0101069 <debuginfo_eip+0x1f6>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0101065:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101069:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010106c:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f010106f:	7c 50                	jl     f01010c1 <debuginfo_eip+0x24e>
	       && stabs[lline].n_type != N_SOL
f0101071:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101074:	89 d0                	mov    %edx,%eax
f0101076:	01 c0                	add    %eax,%eax
f0101078:	01 d0                	add    %edx,%eax
f010107a:	c1 e0 02             	shl    $0x2,%eax
f010107d:	89 c2                	mov    %eax,%edx
f010107f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101082:	01 d0                	add    %edx,%eax
f0101084:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f0101088:	3c 84                	cmp    $0x84,%al
f010108a:	74 35                	je     f01010c1 <debuginfo_eip+0x24e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010108c:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010108f:	89 d0                	mov    %edx,%eax
f0101091:	01 c0                	add    %eax,%eax
f0101093:	01 d0                	add    %edx,%eax
f0101095:	c1 e0 02             	shl    $0x2,%eax
f0101098:	89 c2                	mov    %eax,%edx
f010109a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010109d:	01 d0                	add    %edx,%eax
f010109f:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f01010a3:	3c 64                	cmp    $0x64,%al
f01010a5:	75 be                	jne    f0101065 <debuginfo_eip+0x1f2>
f01010a7:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01010aa:	89 d0                	mov    %edx,%eax
f01010ac:	01 c0                	add    %eax,%eax
f01010ae:	01 d0                	add    %edx,%eax
f01010b0:	c1 e0 02             	shl    $0x2,%eax
f01010b3:	89 c2                	mov    %eax,%edx
f01010b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01010b8:	01 d0                	add    %edx,%eax
f01010ba:	8b 40 08             	mov    0x8(%eax),%eax
f01010bd:	85 c0                	test   %eax,%eax
f01010bf:	74 a4                	je     f0101065 <debuginfo_eip+0x1f2>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01010c1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010c4:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f01010c7:	7c 42                	jl     f010110b <debuginfo_eip+0x298>
f01010c9:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01010cc:	89 d0                	mov    %edx,%eax
f01010ce:	01 c0                	add    %eax,%eax
f01010d0:	01 d0                	add    %edx,%eax
f01010d2:	c1 e0 02             	shl    $0x2,%eax
f01010d5:	89 c2                	mov    %eax,%edx
f01010d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01010da:	01 d0                	add    %edx,%eax
f01010dc:	8b 10                	mov    (%eax),%edx
f01010de:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01010e1:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01010e4:	29 c1                	sub    %eax,%ecx
f01010e6:	89 c8                	mov    %ecx,%eax
f01010e8:	39 c2                	cmp    %eax,%edx
f01010ea:	73 1f                	jae    f010110b <debuginfo_eip+0x298>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01010ec:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01010ef:	89 d0                	mov    %edx,%eax
f01010f1:	01 c0                	add    %eax,%eax
f01010f3:	01 d0                	add    %edx,%eax
f01010f5:	c1 e0 02             	shl    $0x2,%eax
f01010f8:	89 c2                	mov    %eax,%edx
f01010fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01010fd:	01 d0                	add    %edx,%eax
f01010ff:	8b 10                	mov    (%eax),%edx
f0101101:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101104:	01 c2                	add    %eax,%edx
f0101106:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101109:	89 10                	mov    %edx,(%eax)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010110b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010110e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101111:	39 c2                	cmp    %eax,%edx
f0101113:	7d 41                	jge    f0101156 <debuginfo_eip+0x2e3>
		for (lline = lfun + 1;
f0101115:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101118:	83 c0 01             	add    $0x1,%eax
f010111b:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010111e:	eb 13                	jmp    f0101133 <debuginfo_eip+0x2c0>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0101120:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101123:	8b 40 14             	mov    0x14(%eax),%eax
f0101126:	8d 50 01             	lea    0x1(%eax),%edx
f0101129:	8b 45 0c             	mov    0xc(%ebp),%eax
f010112c:	89 50 14             	mov    %edx,0x14(%eax)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f010112f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101133:	8b 45 d0             	mov    -0x30(%ebp),%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0101136:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f0101139:	7d 1b                	jge    f0101156 <debuginfo_eip+0x2e3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010113b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010113e:	89 d0                	mov    %edx,%eax
f0101140:	01 c0                	add    %eax,%eax
f0101142:	01 d0                	add    %edx,%eax
f0101144:	c1 e0 02             	shl    $0x2,%eax
f0101147:	89 c2                	mov    %eax,%edx
f0101149:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010114c:	01 d0                	add    %edx,%eax
f010114e:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f0101152:	3c a0                	cmp    $0xa0,%al
f0101154:	74 ca                	je     f0101120 <debuginfo_eip+0x2ad>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101156:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010115b:	c9                   	leave  
f010115c:	c3                   	ret    

f010115d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010115d:	55                   	push   %ebp
f010115e:	89 e5                	mov    %esp,%ebp
f0101160:	53                   	push   %ebx
f0101161:	83 ec 34             	sub    $0x34,%esp
f0101164:	8b 45 10             	mov    0x10(%ebp),%eax
f0101167:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010116a:	8b 45 14             	mov    0x14(%ebp),%eax
f010116d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101170:	8b 45 18             	mov    0x18(%ebp),%eax
f0101173:	ba 00 00 00 00       	mov    $0x0,%edx
f0101178:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f010117b:	77 72                	ja     f01011ef <printnum+0x92>
f010117d:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f0101180:	72 05                	jb     f0101187 <printnum+0x2a>
f0101182:	3b 45 f0             	cmp    -0x10(%ebp),%eax
f0101185:	77 68                	ja     f01011ef <printnum+0x92>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0101187:	8b 45 1c             	mov    0x1c(%ebp),%eax
f010118a:	8d 58 ff             	lea    -0x1(%eax),%ebx
f010118d:	8b 45 18             	mov    0x18(%ebp),%eax
f0101190:	ba 00 00 00 00       	mov    $0x0,%edx
f0101195:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101199:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010119d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01011a0:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01011a3:	89 04 24             	mov    %eax,(%esp)
f01011a6:	89 54 24 04          	mov    %edx,0x4(%esp)
f01011aa:	e8 b1 0c 00 00       	call   f0101e60 <__udivdi3>
f01011af:	8b 4d 20             	mov    0x20(%ebp),%ecx
f01011b2:	89 4c 24 18          	mov    %ecx,0x18(%esp)
f01011b6:	89 5c 24 14          	mov    %ebx,0x14(%esp)
f01011ba:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01011bd:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01011c1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011c5:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01011c9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01011d3:	89 04 24             	mov    %eax,(%esp)
f01011d6:	e8 82 ff ff ff       	call   f010115d <printnum>
f01011db:	eb 1c                	jmp    f01011f9 <printnum+0x9c>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01011dd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011e4:	8b 45 20             	mov    0x20(%ebp),%eax
f01011e7:	89 04 24             	mov    %eax,(%esp)
f01011ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01011ed:	ff d0                	call   *%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01011ef:	83 6d 1c 01          	subl   $0x1,0x1c(%ebp)
f01011f3:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
f01011f7:	7f e4                	jg     f01011dd <printnum+0x80>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01011f9:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01011fc:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101201:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101204:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101207:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010120b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010120f:	89 04 24             	mov    %eax,(%esp)
f0101212:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101216:	e8 75 0d 00 00       	call   f0101f90 <__umoddi3>
f010121b:	05 60 24 10 f0       	add    $0xf0102460,%eax
f0101220:	0f b6 00             	movzbl (%eax),%eax
f0101223:	0f be c0             	movsbl %al,%eax
f0101226:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101229:	89 54 24 04          	mov    %edx,0x4(%esp)
f010122d:	89 04 24             	mov    %eax,(%esp)
f0101230:	8b 45 08             	mov    0x8(%ebp),%eax
f0101233:	ff d0                	call   *%eax
}
f0101235:	83 c4 34             	add    $0x34,%esp
f0101238:	5b                   	pop    %ebx
f0101239:	5d                   	pop    %ebp
f010123a:	c3                   	ret    

f010123b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010123b:	55                   	push   %ebp
f010123c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010123e:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f0101242:	7e 14                	jle    f0101258 <getuint+0x1d>
		return va_arg(*ap, unsigned long long);
f0101244:	8b 45 08             	mov    0x8(%ebp),%eax
f0101247:	8b 00                	mov    (%eax),%eax
f0101249:	8d 48 08             	lea    0x8(%eax),%ecx
f010124c:	8b 55 08             	mov    0x8(%ebp),%edx
f010124f:	89 0a                	mov    %ecx,(%edx)
f0101251:	8b 50 04             	mov    0x4(%eax),%edx
f0101254:	8b 00                	mov    (%eax),%eax
f0101256:	eb 30                	jmp    f0101288 <getuint+0x4d>
	else if (lflag)
f0101258:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010125c:	74 16                	je     f0101274 <getuint+0x39>
		return va_arg(*ap, unsigned long);
f010125e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101261:	8b 00                	mov    (%eax),%eax
f0101263:	8d 48 04             	lea    0x4(%eax),%ecx
f0101266:	8b 55 08             	mov    0x8(%ebp),%edx
f0101269:	89 0a                	mov    %ecx,(%edx)
f010126b:	8b 00                	mov    (%eax),%eax
f010126d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101272:	eb 14                	jmp    f0101288 <getuint+0x4d>
	else
		return va_arg(*ap, unsigned int);
f0101274:	8b 45 08             	mov    0x8(%ebp),%eax
f0101277:	8b 00                	mov    (%eax),%eax
f0101279:	8d 48 04             	lea    0x4(%eax),%ecx
f010127c:	8b 55 08             	mov    0x8(%ebp),%edx
f010127f:	89 0a                	mov    %ecx,(%edx)
f0101281:	8b 00                	mov    (%eax),%eax
f0101283:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0101288:	5d                   	pop    %ebp
f0101289:	c3                   	ret    

f010128a <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f010128a:	55                   	push   %ebp
f010128b:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010128d:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f0101291:	7e 14                	jle    f01012a7 <getint+0x1d>
		return va_arg(*ap, long long);
f0101293:	8b 45 08             	mov    0x8(%ebp),%eax
f0101296:	8b 00                	mov    (%eax),%eax
f0101298:	8d 48 08             	lea    0x8(%eax),%ecx
f010129b:	8b 55 08             	mov    0x8(%ebp),%edx
f010129e:	89 0a                	mov    %ecx,(%edx)
f01012a0:	8b 50 04             	mov    0x4(%eax),%edx
f01012a3:	8b 00                	mov    (%eax),%eax
f01012a5:	eb 28                	jmp    f01012cf <getint+0x45>
	else if (lflag)
f01012a7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01012ab:	74 12                	je     f01012bf <getint+0x35>
		return va_arg(*ap, long);
f01012ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01012b0:	8b 00                	mov    (%eax),%eax
f01012b2:	8d 48 04             	lea    0x4(%eax),%ecx
f01012b5:	8b 55 08             	mov    0x8(%ebp),%edx
f01012b8:	89 0a                	mov    %ecx,(%edx)
f01012ba:	8b 00                	mov    (%eax),%eax
f01012bc:	99                   	cltd   
f01012bd:	eb 10                	jmp    f01012cf <getint+0x45>
	else
		return va_arg(*ap, int);
f01012bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01012c2:	8b 00                	mov    (%eax),%eax
f01012c4:	8d 48 04             	lea    0x4(%eax),%ecx
f01012c7:	8b 55 08             	mov    0x8(%ebp),%edx
f01012ca:	89 0a                	mov    %ecx,(%edx)
f01012cc:	8b 00                	mov    (%eax),%eax
f01012ce:	99                   	cltd   
}
f01012cf:	5d                   	pop    %ebp
f01012d0:	c3                   	ret    

f01012d1 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01012d1:	55                   	push   %ebp
f01012d2:	89 e5                	mov    %esp,%ebp
f01012d4:	56                   	push   %esi
f01012d5:	53                   	push   %ebx
f01012d6:	83 ec 40             	sub    $0x40,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01012d9:	eb 18                	jmp    f01012f3 <vprintfmt+0x22>
			if (ch == '\0')
f01012db:	85 db                	test   %ebx,%ebx
f01012dd:	75 05                	jne    f01012e4 <vprintfmt+0x13>
				return;
f01012df:	e9 f2 03 00 00       	jmp    f01016d6 <vprintfmt+0x405>
			putch(ch, putdat);
f01012e4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012eb:	89 1c 24             	mov    %ebx,(%esp)
f01012ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01012f1:	ff d0                	call   *%eax
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01012f3:	8b 45 10             	mov    0x10(%ebp),%eax
f01012f6:	8d 50 01             	lea    0x1(%eax),%edx
f01012f9:	89 55 10             	mov    %edx,0x10(%ebp)
f01012fc:	0f b6 00             	movzbl (%eax),%eax
f01012ff:	0f b6 d8             	movzbl %al,%ebx
f0101302:	83 fb 25             	cmp    $0x25,%ebx
f0101305:	75 d4                	jne    f01012db <vprintfmt+0xa>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		padc = ' ';
f0101307:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
		width = -1;
f010130b:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
		precision = -1;
f0101312:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0101319:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
		altflag = 0;
f0101320:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101327:	8b 45 10             	mov    0x10(%ebp),%eax
f010132a:	8d 50 01             	lea    0x1(%eax),%edx
f010132d:	89 55 10             	mov    %edx,0x10(%ebp)
f0101330:	0f b6 00             	movzbl (%eax),%eax
f0101333:	0f b6 d8             	movzbl %al,%ebx
f0101336:	8d 43 dd             	lea    -0x23(%ebx),%eax
f0101339:	83 f8 55             	cmp    $0x55,%eax
f010133c:	0f 87 63 03 00 00    	ja     f01016a5 <vprintfmt+0x3d4>
f0101342:	8b 04 85 84 24 10 f0 	mov    -0xfefdb7c(,%eax,4),%eax
f0101349:	ff e0                	jmp    *%eax

		// flag to pad on the right
		case '-':
			padc = '-';
f010134b:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
			goto reswitch;
f010134f:	eb d6                	jmp    f0101327 <vprintfmt+0x56>

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101351:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
			goto reswitch;
f0101355:	eb d0                	jmp    f0101327 <vprintfmt+0x56>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101357:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
				precision = precision * 10 + ch - '0';
f010135e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101361:	89 d0                	mov    %edx,%eax
f0101363:	c1 e0 02             	shl    $0x2,%eax
f0101366:	01 d0                	add    %edx,%eax
f0101368:	01 c0                	add    %eax,%eax
f010136a:	01 d8                	add    %ebx,%eax
f010136c:	83 e8 30             	sub    $0x30,%eax
f010136f:	89 45 e0             	mov    %eax,-0x20(%ebp)
				ch = *fmt;
f0101372:	8b 45 10             	mov    0x10(%ebp),%eax
f0101375:	0f b6 00             	movzbl (%eax),%eax
f0101378:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
f010137b:	83 fb 2f             	cmp    $0x2f,%ebx
f010137e:	7e 0b                	jle    f010138b <vprintfmt+0xba>
f0101380:	83 fb 39             	cmp    $0x39,%ebx
f0101383:	7f 06                	jg     f010138b <vprintfmt+0xba>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101385:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0101389:	eb d3                	jmp    f010135e <vprintfmt+0x8d>
			goto process_precision;
f010138b:	eb 33                	jmp    f01013c0 <vprintfmt+0xef>

		case '*':
			precision = va_arg(ap, int);
f010138d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101390:	8d 50 04             	lea    0x4(%eax),%edx
f0101393:	89 55 14             	mov    %edx,0x14(%ebp)
f0101396:	8b 00                	mov    (%eax),%eax
f0101398:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto process_precision;
f010139b:	eb 23                	jmp    f01013c0 <vprintfmt+0xef>

		case '.':
			if (width < 0)
f010139d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01013a1:	79 0c                	jns    f01013af <vprintfmt+0xde>
				width = 0;
f01013a3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			goto reswitch;
f01013aa:	e9 78 ff ff ff       	jmp    f0101327 <vprintfmt+0x56>
f01013af:	e9 73 ff ff ff       	jmp    f0101327 <vprintfmt+0x56>

		case '#':
			altflag = 1;
f01013b4:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f01013bb:	e9 67 ff ff ff       	jmp    f0101327 <vprintfmt+0x56>

		process_precision:
			if (width < 0)
f01013c0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01013c4:	79 12                	jns    f01013d8 <vprintfmt+0x107>
				width = precision, precision = -1;
f01013c6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01013c9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01013cc:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
			goto reswitch;
f01013d3:	e9 4f ff ff ff       	jmp    f0101327 <vprintfmt+0x56>
f01013d8:	e9 4a ff ff ff       	jmp    f0101327 <vprintfmt+0x56>

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01013dd:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
			goto reswitch;
f01013e1:	e9 41 ff ff ff       	jmp    f0101327 <vprintfmt+0x56>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01013e6:	8b 45 14             	mov    0x14(%ebp),%eax
f01013e9:	8d 50 04             	lea    0x4(%eax),%edx
f01013ec:	89 55 14             	mov    %edx,0x14(%ebp)
f01013ef:	8b 00                	mov    (%eax),%eax
f01013f1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013f4:	89 54 24 04          	mov    %edx,0x4(%esp)
f01013f8:	89 04 24             	mov    %eax,(%esp)
f01013fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01013fe:	ff d0                	call   *%eax
			break;
f0101400:	e9 cb 02 00 00       	jmp    f01016d0 <vprintfmt+0x3ff>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101405:	8b 45 14             	mov    0x14(%ebp),%eax
f0101408:	8d 50 04             	lea    0x4(%eax),%edx
f010140b:	89 55 14             	mov    %edx,0x14(%ebp)
f010140e:	8b 18                	mov    (%eax),%ebx
			if (err < 0)
f0101410:	85 db                	test   %ebx,%ebx
f0101412:	79 02                	jns    f0101416 <vprintfmt+0x145>
				err = -err;
f0101414:	f7 db                	neg    %ebx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101416:	83 fb 07             	cmp    $0x7,%ebx
f0101419:	7f 0b                	jg     f0101426 <vprintfmt+0x155>
f010141b:	8b 34 9d 40 24 10 f0 	mov    -0xfefdbc0(,%ebx,4),%esi
f0101422:	85 f6                	test   %esi,%esi
f0101424:	75 23                	jne    f0101449 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f0101426:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010142a:	c7 44 24 08 71 24 10 	movl   $0xf0102471,0x8(%esp)
f0101431:	f0 
f0101432:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101435:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101439:	8b 45 08             	mov    0x8(%ebp),%eax
f010143c:	89 04 24             	mov    %eax,(%esp)
f010143f:	e8 99 02 00 00       	call   f01016dd <printfmt>
			else
				printfmt(putch, putdat, "%s", p);
			break;
f0101444:	e9 87 02 00 00       	jmp    f01016d0 <vprintfmt+0x3ff>
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f0101449:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010144d:	c7 44 24 08 7a 24 10 	movl   $0xf010247a,0x8(%esp)
f0101454:	f0 
f0101455:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101458:	89 44 24 04          	mov    %eax,0x4(%esp)
f010145c:	8b 45 08             	mov    0x8(%ebp),%eax
f010145f:	89 04 24             	mov    %eax,(%esp)
f0101462:	e8 76 02 00 00       	call   f01016dd <printfmt>
			break;
f0101467:	e9 64 02 00 00       	jmp    f01016d0 <vprintfmt+0x3ff>

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010146c:	8b 45 14             	mov    0x14(%ebp),%eax
f010146f:	8d 50 04             	lea    0x4(%eax),%edx
f0101472:	89 55 14             	mov    %edx,0x14(%ebp)
f0101475:	8b 30                	mov    (%eax),%esi
f0101477:	85 f6                	test   %esi,%esi
f0101479:	75 05                	jne    f0101480 <vprintfmt+0x1af>
				p = "(null)";
f010147b:	be 7d 24 10 f0       	mov    $0xf010247d,%esi
			if (width > 0 && padc != '-')
f0101480:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101484:	7e 37                	jle    f01014bd <vprintfmt+0x1ec>
f0101486:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
f010148a:	74 31                	je     f01014bd <vprintfmt+0x1ec>
				for (width -= strnlen(p, precision); width > 0; width--)
f010148c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010148f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101493:	89 34 24             	mov    %esi,(%esp)
f0101496:	e8 54 04 00 00       	call   f01018ef <strnlen>
f010149b:	29 45 e4             	sub    %eax,-0x1c(%ebp)
f010149e:	eb 17                	jmp    f01014b7 <vprintfmt+0x1e6>
					putch(padc, putdat);
f01014a0:	0f be 45 db          	movsbl -0x25(%ebp),%eax
f01014a4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014a7:	89 54 24 04          	mov    %edx,0x4(%esp)
f01014ab:	89 04 24             	mov    %eax,(%esp)
f01014ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01014b1:	ff d0                	call   *%eax
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01014b3:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f01014b7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01014bb:	7f e3                	jg     f01014a0 <vprintfmt+0x1cf>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01014bd:	eb 38                	jmp    f01014f7 <vprintfmt+0x226>
				if (altflag && (ch < ' ' || ch > '~'))
f01014bf:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01014c3:	74 1f                	je     f01014e4 <vprintfmt+0x213>
f01014c5:	83 fb 1f             	cmp    $0x1f,%ebx
f01014c8:	7e 05                	jle    f01014cf <vprintfmt+0x1fe>
f01014ca:	83 fb 7e             	cmp    $0x7e,%ebx
f01014cd:	7e 15                	jle    f01014e4 <vprintfmt+0x213>
					putch('?', putdat);
f01014cf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014d2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014d6:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01014dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e0:	ff d0                	call   *%eax
f01014e2:	eb 0f                	jmp    f01014f3 <vprintfmt+0x222>
				else
					putch(ch, putdat);
f01014e4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014eb:	89 1c 24             	mov    %ebx,(%esp)
f01014ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01014f1:	ff d0                	call   *%eax
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01014f3:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f01014f7:	89 f0                	mov    %esi,%eax
f01014f9:	8d 70 01             	lea    0x1(%eax),%esi
f01014fc:	0f b6 00             	movzbl (%eax),%eax
f01014ff:	0f be d8             	movsbl %al,%ebx
f0101502:	85 db                	test   %ebx,%ebx
f0101504:	74 10                	je     f0101516 <vprintfmt+0x245>
f0101506:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010150a:	78 b3                	js     f01014bf <vprintfmt+0x1ee>
f010150c:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0101510:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101514:	79 a9                	jns    f01014bf <vprintfmt+0x1ee>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101516:	eb 17                	jmp    f010152f <vprintfmt+0x25e>
				putch(' ', putdat);
f0101518:	8b 45 0c             	mov    0xc(%ebp),%eax
f010151b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010151f:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101526:	8b 45 08             	mov    0x8(%ebp),%eax
f0101529:	ff d0                	call   *%eax
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010152b:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f010152f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101533:	7f e3                	jg     f0101518 <vprintfmt+0x247>
				putch(' ', putdat);
			break;
f0101535:	e9 96 01 00 00       	jmp    f01016d0 <vprintfmt+0x3ff>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010153a:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010153d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101541:	8d 45 14             	lea    0x14(%ebp),%eax
f0101544:	89 04 24             	mov    %eax,(%esp)
f0101547:	e8 3e fd ff ff       	call   f010128a <getint>
f010154c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010154f:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((long long) num < 0) {
f0101552:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101555:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101558:	85 d2                	test   %edx,%edx
f010155a:	79 26                	jns    f0101582 <vprintfmt+0x2b1>
				putch('-', putdat);
f010155c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010155f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101563:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010156a:	8b 45 08             	mov    0x8(%ebp),%eax
f010156d:	ff d0                	call   *%eax
				num = -(long long) num;
f010156f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101572:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101575:	f7 d8                	neg    %eax
f0101577:	83 d2 00             	adc    $0x0,%edx
f010157a:	f7 da                	neg    %edx
f010157c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010157f:	89 55 f4             	mov    %edx,-0xc(%ebp)
			}
			base = 10;
f0101582:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f0101589:	e9 ce 00 00 00       	jmp    f010165c <vprintfmt+0x38b>

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010158e:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101591:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101595:	8d 45 14             	lea    0x14(%ebp),%eax
f0101598:	89 04 24             	mov    %eax,(%esp)
f010159b:	e8 9b fc ff ff       	call   f010123b <getuint>
f01015a0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01015a3:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 10;
f01015a6:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f01015ad:	e9 aa 00 00 00       	jmp    f010165c <vprintfmt+0x38b>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('0', putdat);
f01015b2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015b5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015b9:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01015c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01015c3:	ff d0                	call   *%eax
			putch('o', putdat);
f01015c5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015cc:	c7 04 24 6f 00 00 00 	movl   $0x6f,(%esp)
f01015d3:	8b 45 08             	mov    0x8(%ebp),%eax
f01015d6:	ff d0                	call   *%eax
			/*putch('X', putdat);*/
			num = getuint(&ap, lflag);
f01015d8:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01015db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015df:	8d 45 14             	lea    0x14(%ebp),%eax
f01015e2:	89 04 24             	mov    %eax,(%esp)
f01015e5:	e8 51 fc ff ff       	call   f010123b <getuint>
f01015ea:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01015ed:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 8;
f01015f0:	c7 45 ec 08 00 00 00 	movl   $0x8,-0x14(%ebp)
			goto number;
f01015f7:	eb 63                	jmp    f010165c <vprintfmt+0x38b>

		// pointer
		case 'p':
			putch('0', putdat);
f01015f9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101600:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101607:	8b 45 08             	mov    0x8(%ebp),%eax
f010160a:	ff d0                	call   *%eax
			putch('x', putdat);
f010160c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010160f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101613:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010161a:	8b 45 08             	mov    0x8(%ebp),%eax
f010161d:	ff d0                	call   *%eax
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010161f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101622:	8d 50 04             	lea    0x4(%eax),%edx
f0101625:	89 55 14             	mov    %edx,0x14(%ebp)
f0101628:	8b 00                	mov    (%eax),%eax

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010162a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010162d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101634:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
			goto number;
f010163b:	eb 1f                	jmp    f010165c <vprintfmt+0x38b>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010163d:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101640:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101644:	8d 45 14             	lea    0x14(%ebp),%eax
f0101647:	89 04 24             	mov    %eax,(%esp)
f010164a:	e8 ec fb ff ff       	call   f010123b <getuint>
f010164f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101652:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 16;
f0101655:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
		number:
			printnum(putch, putdat, num, base, width, padc);
f010165c:	0f be 55 db          	movsbl -0x25(%ebp),%edx
f0101660:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101663:	89 54 24 18          	mov    %edx,0x18(%esp)
f0101667:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010166a:	89 54 24 14          	mov    %edx,0x14(%esp)
f010166e:	89 44 24 10          	mov    %eax,0x10(%esp)
f0101672:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101675:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101678:	89 44 24 08          	mov    %eax,0x8(%esp)
f010167c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101680:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101683:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101687:	8b 45 08             	mov    0x8(%ebp),%eax
f010168a:	89 04 24             	mov    %eax,(%esp)
f010168d:	e8 cb fa ff ff       	call   f010115d <printnum>
			break;
f0101692:	eb 3c                	jmp    f01016d0 <vprintfmt+0x3ff>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101694:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101697:	89 44 24 04          	mov    %eax,0x4(%esp)
f010169b:	89 1c 24             	mov    %ebx,(%esp)
f010169e:	8b 45 08             	mov    0x8(%ebp),%eax
f01016a1:	ff d0                	call   *%eax
			break;
f01016a3:	eb 2b                	jmp    f01016d0 <vprintfmt+0x3ff>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01016a5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016a8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016ac:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01016b3:	8b 45 08             	mov    0x8(%ebp),%eax
f01016b6:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
f01016b8:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f01016bc:	eb 04                	jmp    f01016c2 <vprintfmt+0x3f1>
f01016be:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f01016c2:	8b 45 10             	mov    0x10(%ebp),%eax
f01016c5:	83 e8 01             	sub    $0x1,%eax
f01016c8:	0f b6 00             	movzbl (%eax),%eax
f01016cb:	3c 25                	cmp    $0x25,%al
f01016cd:	75 ef                	jne    f01016be <vprintfmt+0x3ed>
				/* do nothing */;
			break;
f01016cf:	90                   	nop
		}
	}
f01016d0:	90                   	nop
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01016d1:	e9 1d fc ff ff       	jmp    f01012f3 <vprintfmt+0x22>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f01016d6:	83 c4 40             	add    $0x40,%esp
f01016d9:	5b                   	pop    %ebx
f01016da:	5e                   	pop    %esi
f01016db:	5d                   	pop    %ebp
f01016dc:	c3                   	ret    

f01016dd <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01016dd:	55                   	push   %ebp
f01016de:	89 e5                	mov    %esp,%ebp
f01016e0:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
f01016e3:	8d 45 14             	lea    0x14(%ebp),%eax
f01016e6:	89 45 f4             	mov    %eax,-0xc(%ebp)
	vprintfmt(putch, putdat, fmt, ap);
f01016e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01016ec:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016f0:	8b 45 10             	mov    0x10(%ebp),%eax
f01016f3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01016f7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016fa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101701:	89 04 24             	mov    %eax,(%esp)
f0101704:	e8 c8 fb ff ff       	call   f01012d1 <vprintfmt>
	va_end(ap);
}
f0101709:	c9                   	leave  
f010170a:	c3                   	ret    

f010170b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010170b:	55                   	push   %ebp
f010170c:	89 e5                	mov    %esp,%ebp
	b->cnt++;
f010170e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101711:	8b 40 08             	mov    0x8(%eax),%eax
f0101714:	8d 50 01             	lea    0x1(%eax),%edx
f0101717:	8b 45 0c             	mov    0xc(%ebp),%eax
f010171a:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
f010171d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101720:	8b 10                	mov    (%eax),%edx
f0101722:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101725:	8b 40 04             	mov    0x4(%eax),%eax
f0101728:	39 c2                	cmp    %eax,%edx
f010172a:	73 12                	jae    f010173e <sprintputch+0x33>
		*b->buf++ = ch;
f010172c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010172f:	8b 00                	mov    (%eax),%eax
f0101731:	8d 48 01             	lea    0x1(%eax),%ecx
f0101734:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101737:	89 0a                	mov    %ecx,(%edx)
f0101739:	8b 55 08             	mov    0x8(%ebp),%edx
f010173c:	88 10                	mov    %dl,(%eax)
}
f010173e:	5d                   	pop    %ebp
f010173f:	c3                   	ret    

f0101740 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101740:	55                   	push   %ebp
f0101741:	89 e5                	mov    %esp,%ebp
f0101743:	83 ec 28             	sub    $0x28,%esp
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101746:	8b 45 08             	mov    0x8(%ebp),%eax
f0101749:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010174c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010174f:	8d 50 ff             	lea    -0x1(%eax),%edx
f0101752:	8b 45 08             	mov    0x8(%ebp),%eax
f0101755:	01 d0                	add    %edx,%eax
f0101757:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010175a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101761:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0101765:	74 06                	je     f010176d <vsnprintf+0x2d>
f0101767:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010176b:	7f 07                	jg     f0101774 <vsnprintf+0x34>
		return -E_INVAL;
f010176d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101772:	eb 2a                	jmp    f010179e <vsnprintf+0x5e>

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101774:	8b 45 14             	mov    0x14(%ebp),%eax
f0101777:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010177b:	8b 45 10             	mov    0x10(%ebp),%eax
f010177e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101782:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101785:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101789:	c7 04 24 0b 17 10 f0 	movl   $0xf010170b,(%esp)
f0101790:	e8 3c fb ff ff       	call   f01012d1 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101795:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101798:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010179b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f010179e:	c9                   	leave  
f010179f:	c3                   	ret    

f01017a0 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01017a0:	55                   	push   %ebp
f01017a1:	89 e5                	mov    %esp,%ebp
f01017a3:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01017a6:	8d 45 14             	lea    0x14(%ebp),%eax
f01017a9:	89 45 f0             	mov    %eax,-0x10(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
f01017ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01017af:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01017b3:	8b 45 10             	mov    0x10(%ebp),%eax
f01017b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01017ba:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01017c1:	8b 45 08             	mov    0x8(%ebp),%eax
f01017c4:	89 04 24             	mov    %eax,(%esp)
f01017c7:	e8 74 ff ff ff       	call   f0101740 <vsnprintf>
f01017cc:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return rc;
f01017cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01017d2:	c9                   	leave  
f01017d3:	c3                   	ret    

f01017d4 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01017d4:	55                   	push   %ebp
f01017d5:	89 e5                	mov    %esp,%ebp
f01017d7:	83 ec 28             	sub    $0x28,%esp
	int i, c, echoing;

	if (prompt != NULL)
f01017da:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01017de:	74 13                	je     f01017f3 <readline+0x1f>
		cprintf("%s", prompt);
f01017e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01017e3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01017e7:	c7 04 24 dc 25 10 f0 	movl   $0xf01025dc,(%esp)
f01017ee:	e8 04 f5 ff ff       	call   f0100cf7 <cprintf>

	i = 0;
f01017f3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	echoing = iscons(0);
f01017fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101801:	e8 9d f1 ff ff       	call   f01009a3 <iscons>
f0101806:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while (1) {
		c = getchar();
f0101809:	e8 7c f1 ff ff       	call   f010098a <getchar>
f010180e:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (c < 0) {
f0101811:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0101815:	79 1d                	jns    f0101834 <readline+0x60>
			cprintf("read error: %e\n", c);
f0101817:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010181a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010181e:	c7 04 24 df 25 10 f0 	movl   $0xf01025df,(%esp)
f0101825:	e8 cd f4 ff ff       	call   f0100cf7 <cprintf>
			return NULL;
f010182a:	b8 00 00 00 00       	mov    $0x0,%eax
f010182f:	e9 93 00 00 00       	jmp    f01018c7 <readline+0xf3>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101834:	83 7d ec 08          	cmpl   $0x8,-0x14(%ebp)
f0101838:	74 06                	je     f0101840 <readline+0x6c>
f010183a:	83 7d ec 7f          	cmpl   $0x7f,-0x14(%ebp)
f010183e:	75 1e                	jne    f010185e <readline+0x8a>
f0101840:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0101844:	7e 18                	jle    f010185e <readline+0x8a>
			if (echoing)
f0101846:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f010184a:	74 0c                	je     f0101858 <readline+0x84>
				cputchar('\b');
f010184c:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0101853:	e8 1f f1 ff ff       	call   f0100977 <cputchar>
			i--;
f0101858:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
f010185c:	eb 64                	jmp    f01018c2 <readline+0xee>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010185e:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%ebp)
f0101862:	7e 2e                	jle    f0101892 <readline+0xbe>
f0101864:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
f010186b:	7f 25                	jg     f0101892 <readline+0xbe>
			if (echoing)
f010186d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0101871:	74 0b                	je     f010187e <readline+0xaa>
				cputchar(c);
f0101873:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101876:	89 04 24             	mov    %eax,(%esp)
f0101879:	e8 f9 f0 ff ff       	call   f0100977 <cputchar>
			buf[i++] = c;
f010187e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101881:	8d 50 01             	lea    0x1(%eax),%edx
f0101884:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101887:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010188a:	88 90 80 27 11 f0    	mov    %dl,-0xfeed880(%eax)
f0101890:	eb 30                	jmp    f01018c2 <readline+0xee>
		} else if (c == '\n' || c == '\r') {
f0101892:	83 7d ec 0a          	cmpl   $0xa,-0x14(%ebp)
f0101896:	74 06                	je     f010189e <readline+0xca>
f0101898:	83 7d ec 0d          	cmpl   $0xd,-0x14(%ebp)
f010189c:	75 24                	jne    f01018c2 <readline+0xee>
			if (echoing)
f010189e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f01018a2:	74 0c                	je     f01018b0 <readline+0xdc>
				cputchar('\n');
f01018a4:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01018ab:	e8 c7 f0 ff ff       	call   f0100977 <cputchar>
			buf[i] = 0;
f01018b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01018b3:	05 80 27 11 f0       	add    $0xf0112780,%eax
f01018b8:	c6 00 00             	movb   $0x0,(%eax)
			return buf;
f01018bb:	b8 80 27 11 f0       	mov    $0xf0112780,%eax
f01018c0:	eb 05                	jmp    f01018c7 <readline+0xf3>
		}
	}
f01018c2:	e9 42 ff ff ff       	jmp    f0101809 <readline+0x35>
}
f01018c7:	c9                   	leave  
f01018c8:	c3                   	ret    

f01018c9 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01018c9:	55                   	push   %ebp
f01018ca:	89 e5                	mov    %esp,%ebp
f01018cc:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
f01018cf:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f01018d6:	eb 08                	jmp    f01018e0 <strlen+0x17>
		n++;
f01018d8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01018dc:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f01018e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01018e3:	0f b6 00             	movzbl (%eax),%eax
f01018e6:	84 c0                	test   %al,%al
f01018e8:	75 ee                	jne    f01018d8 <strlen+0xf>
		n++;
	return n;
f01018ea:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f01018ed:	c9                   	leave  
f01018ee:	c3                   	ret    

f01018ef <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01018ef:	55                   	push   %ebp
f01018f0:	89 e5                	mov    %esp,%ebp
f01018f2:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01018f5:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f01018fc:	eb 0c                	jmp    f010190a <strnlen+0x1b>
		n++;
f01018fe:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101902:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101906:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
f010190a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010190e:	74 0a                	je     f010191a <strnlen+0x2b>
f0101910:	8b 45 08             	mov    0x8(%ebp),%eax
f0101913:	0f b6 00             	movzbl (%eax),%eax
f0101916:	84 c0                	test   %al,%al
f0101918:	75 e4                	jne    f01018fe <strnlen+0xf>
		n++;
	return n;
f010191a:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f010191d:	c9                   	leave  
f010191e:	c3                   	ret    

f010191f <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010191f:	55                   	push   %ebp
f0101920:	89 e5                	mov    %esp,%ebp
f0101922:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
f0101925:	8b 45 08             	mov    0x8(%ebp),%eax
f0101928:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
f010192b:	90                   	nop
f010192c:	8b 45 08             	mov    0x8(%ebp),%eax
f010192f:	8d 50 01             	lea    0x1(%eax),%edx
f0101932:	89 55 08             	mov    %edx,0x8(%ebp)
f0101935:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101938:	8d 4a 01             	lea    0x1(%edx),%ecx
f010193b:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f010193e:	0f b6 12             	movzbl (%edx),%edx
f0101941:	88 10                	mov    %dl,(%eax)
f0101943:	0f b6 00             	movzbl (%eax),%eax
f0101946:	84 c0                	test   %al,%al
f0101948:	75 e2                	jne    f010192c <strcpy+0xd>
		/* do nothing */;
	return ret;
f010194a:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f010194d:	c9                   	leave  
f010194e:	c3                   	ret    

f010194f <strcat>:

char *
strcat(char *dst, const char *src)
{
f010194f:	55                   	push   %ebp
f0101950:	89 e5                	mov    %esp,%ebp
f0101952:	83 ec 18             	sub    $0x18,%esp
	int len = strlen(dst);
f0101955:	8b 45 08             	mov    0x8(%ebp),%eax
f0101958:	89 04 24             	mov    %eax,(%esp)
f010195b:	e8 69 ff ff ff       	call   f01018c9 <strlen>
f0101960:	89 45 fc             	mov    %eax,-0x4(%ebp)
	strcpy(dst + len, src);
f0101963:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0101966:	8b 45 08             	mov    0x8(%ebp),%eax
f0101969:	01 c2                	add    %eax,%edx
f010196b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010196e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101972:	89 14 24             	mov    %edx,(%esp)
f0101975:	e8 a5 ff ff ff       	call   f010191f <strcpy>
	return dst;
f010197a:	8b 45 08             	mov    0x8(%ebp),%eax
}
f010197d:	c9                   	leave  
f010197e:	c3                   	ret    

f010197f <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010197f:	55                   	push   %ebp
f0101980:	89 e5                	mov    %esp,%ebp
f0101982:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
f0101985:	8b 45 08             	mov    0x8(%ebp),%eax
f0101988:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
f010198b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0101992:	eb 23                	jmp    f01019b7 <strncpy+0x38>
		*dst++ = *src;
f0101994:	8b 45 08             	mov    0x8(%ebp),%eax
f0101997:	8d 50 01             	lea    0x1(%eax),%edx
f010199a:	89 55 08             	mov    %edx,0x8(%ebp)
f010199d:	8b 55 0c             	mov    0xc(%ebp),%edx
f01019a0:	0f b6 12             	movzbl (%edx),%edx
f01019a3:	88 10                	mov    %dl,(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
f01019a5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01019a8:	0f b6 00             	movzbl (%eax),%eax
f01019ab:	84 c0                	test   %al,%al
f01019ad:	74 04                	je     f01019b3 <strncpy+0x34>
			src++;
f01019af:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01019b3:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f01019b7:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01019ba:	3b 45 10             	cmp    0x10(%ebp),%eax
f01019bd:	72 d5                	jb     f0101994 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
f01019bf:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f01019c2:	c9                   	leave  
f01019c3:	c3                   	ret    

f01019c4 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01019c4:	55                   	push   %ebp
f01019c5:	89 e5                	mov    %esp,%ebp
f01019c7:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
f01019ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01019cd:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
f01019d0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01019d4:	74 33                	je     f0101a09 <strlcpy+0x45>
		while (--size > 0 && *src != '\0')
f01019d6:	eb 17                	jmp    f01019ef <strlcpy+0x2b>
			*dst++ = *src++;
f01019d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01019db:	8d 50 01             	lea    0x1(%eax),%edx
f01019de:	89 55 08             	mov    %edx,0x8(%ebp)
f01019e1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01019e4:	8d 4a 01             	lea    0x1(%edx),%ecx
f01019e7:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f01019ea:	0f b6 12             	movzbl (%edx),%edx
f01019ed:	88 10                	mov    %dl,(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01019ef:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f01019f3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01019f7:	74 0a                	je     f0101a03 <strlcpy+0x3f>
f01019f9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01019fc:	0f b6 00             	movzbl (%eax),%eax
f01019ff:	84 c0                	test   %al,%al
f0101a01:	75 d5                	jne    f01019d8 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
f0101a03:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a06:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101a09:	8b 55 08             	mov    0x8(%ebp),%edx
f0101a0c:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101a0f:	29 c2                	sub    %eax,%edx
f0101a11:	89 d0                	mov    %edx,%eax
}
f0101a13:	c9                   	leave  
f0101a14:	c3                   	ret    

f0101a15 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101a15:	55                   	push   %ebp
f0101a16:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
f0101a18:	eb 08                	jmp    f0101a22 <strcmp+0xd>
		p++, q++;
f0101a1a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101a1e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101a22:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a25:	0f b6 00             	movzbl (%eax),%eax
f0101a28:	84 c0                	test   %al,%al
f0101a2a:	74 10                	je     f0101a3c <strcmp+0x27>
f0101a2c:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a2f:	0f b6 10             	movzbl (%eax),%edx
f0101a32:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a35:	0f b6 00             	movzbl (%eax),%eax
f0101a38:	38 c2                	cmp    %al,%dl
f0101a3a:	74 de                	je     f0101a1a <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101a3c:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a3f:	0f b6 00             	movzbl (%eax),%eax
f0101a42:	0f b6 d0             	movzbl %al,%edx
f0101a45:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a48:	0f b6 00             	movzbl (%eax),%eax
f0101a4b:	0f b6 c0             	movzbl %al,%eax
f0101a4e:	29 c2                	sub    %eax,%edx
f0101a50:	89 d0                	mov    %edx,%eax
}
f0101a52:	5d                   	pop    %ebp
f0101a53:	c3                   	ret    

f0101a54 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101a54:	55                   	push   %ebp
f0101a55:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
f0101a57:	eb 0c                	jmp    f0101a65 <strncmp+0x11>
		n--, p++, q++;
f0101a59:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f0101a5d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101a61:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101a65:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101a69:	74 1a                	je     f0101a85 <strncmp+0x31>
f0101a6b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a6e:	0f b6 00             	movzbl (%eax),%eax
f0101a71:	84 c0                	test   %al,%al
f0101a73:	74 10                	je     f0101a85 <strncmp+0x31>
f0101a75:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a78:	0f b6 10             	movzbl (%eax),%edx
f0101a7b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a7e:	0f b6 00             	movzbl (%eax),%eax
f0101a81:	38 c2                	cmp    %al,%dl
f0101a83:	74 d4                	je     f0101a59 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
f0101a85:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101a89:	75 07                	jne    f0101a92 <strncmp+0x3e>
		return 0;
f0101a8b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a90:	eb 16                	jmp    f0101aa8 <strncmp+0x54>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101a92:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a95:	0f b6 00             	movzbl (%eax),%eax
f0101a98:	0f b6 d0             	movzbl %al,%edx
f0101a9b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a9e:	0f b6 00             	movzbl (%eax),%eax
f0101aa1:	0f b6 c0             	movzbl %al,%eax
f0101aa4:	29 c2                	sub    %eax,%edx
f0101aa6:	89 d0                	mov    %edx,%eax
}
f0101aa8:	5d                   	pop    %ebp
f0101aa9:	c3                   	ret    

f0101aaa <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101aaa:	55                   	push   %ebp
f0101aab:	89 e5                	mov    %esp,%ebp
f0101aad:	83 ec 04             	sub    $0x4,%esp
f0101ab0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101ab3:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f0101ab6:	eb 14                	jmp    f0101acc <strchr+0x22>
		if (*s == c)
f0101ab8:	8b 45 08             	mov    0x8(%ebp),%eax
f0101abb:	0f b6 00             	movzbl (%eax),%eax
f0101abe:	3a 45 fc             	cmp    -0x4(%ebp),%al
f0101ac1:	75 05                	jne    f0101ac8 <strchr+0x1e>
			return (char *) s;
f0101ac3:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ac6:	eb 13                	jmp    f0101adb <strchr+0x31>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101ac8:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101acc:	8b 45 08             	mov    0x8(%ebp),%eax
f0101acf:	0f b6 00             	movzbl (%eax),%eax
f0101ad2:	84 c0                	test   %al,%al
f0101ad4:	75 e2                	jne    f0101ab8 <strchr+0xe>
		if (*s == c)
			return (char *) s;
	return 0;
f0101ad6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101adb:	c9                   	leave  
f0101adc:	c3                   	ret    

f0101add <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101add:	55                   	push   %ebp
f0101ade:	89 e5                	mov    %esp,%ebp
f0101ae0:	83 ec 04             	sub    $0x4,%esp
f0101ae3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101ae6:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f0101ae9:	eb 11                	jmp    f0101afc <strfind+0x1f>
		if (*s == c)
f0101aeb:	8b 45 08             	mov    0x8(%ebp),%eax
f0101aee:	0f b6 00             	movzbl (%eax),%eax
f0101af1:	3a 45 fc             	cmp    -0x4(%ebp),%al
f0101af4:	75 02                	jne    f0101af8 <strfind+0x1b>
			break;
f0101af6:	eb 0e                	jmp    f0101b06 <strfind+0x29>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101af8:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101afc:	8b 45 08             	mov    0x8(%ebp),%eax
f0101aff:	0f b6 00             	movzbl (%eax),%eax
f0101b02:	84 c0                	test   %al,%al
f0101b04:	75 e5                	jne    f0101aeb <strfind+0xe>
		if (*s == c)
			break;
	return (char *) s;
f0101b06:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0101b09:	c9                   	leave  
f0101b0a:	c3                   	ret    

f0101b0b <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101b0b:	55                   	push   %ebp
f0101b0c:	89 e5                	mov    %esp,%ebp
f0101b0e:	57                   	push   %edi
	char *p;

	if (n == 0)
f0101b0f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101b13:	75 05                	jne    f0101b1a <memset+0xf>
		return v;
f0101b15:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b18:	eb 5c                	jmp    f0101b76 <memset+0x6b>
	if ((int)v%4 == 0 && n%4 == 0) {
f0101b1a:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b1d:	83 e0 03             	and    $0x3,%eax
f0101b20:	85 c0                	test   %eax,%eax
f0101b22:	75 41                	jne    f0101b65 <memset+0x5a>
f0101b24:	8b 45 10             	mov    0x10(%ebp),%eax
f0101b27:	83 e0 03             	and    $0x3,%eax
f0101b2a:	85 c0                	test   %eax,%eax
f0101b2c:	75 37                	jne    f0101b65 <memset+0x5a>
		c &= 0xFF;
f0101b2e:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101b35:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b38:	c1 e0 18             	shl    $0x18,%eax
f0101b3b:	89 c2                	mov    %eax,%edx
f0101b3d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b40:	c1 e0 10             	shl    $0x10,%eax
f0101b43:	09 c2                	or     %eax,%edx
f0101b45:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b48:	c1 e0 08             	shl    $0x8,%eax
f0101b4b:	09 d0                	or     %edx,%eax
f0101b4d:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101b50:	8b 45 10             	mov    0x10(%ebp),%eax
f0101b53:	c1 e8 02             	shr    $0x2,%eax
f0101b56:	89 c1                	mov    %eax,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101b58:	8b 55 08             	mov    0x8(%ebp),%edx
f0101b5b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b5e:	89 d7                	mov    %edx,%edi
f0101b60:	fc                   	cld    
f0101b61:	f3 ab                	rep stos %eax,%es:(%edi)
f0101b63:	eb 0e                	jmp    f0101b73 <memset+0x68>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101b65:	8b 55 08             	mov    0x8(%ebp),%edx
f0101b68:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b6b:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101b6e:	89 d7                	mov    %edx,%edi
f0101b70:	fc                   	cld    
f0101b71:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
f0101b73:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0101b76:	5f                   	pop    %edi
f0101b77:	5d                   	pop    %ebp
f0101b78:	c3                   	ret    

f0101b79 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101b79:	55                   	push   %ebp
f0101b7a:	89 e5                	mov    %esp,%ebp
f0101b7c:	57                   	push   %edi
f0101b7d:	56                   	push   %esi
f0101b7e:	53                   	push   %ebx
f0101b7f:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;

	s = src;
f0101b82:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b85:	89 45 f0             	mov    %eax,-0x10(%ebp)
	d = dst;
f0101b88:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b8b:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (s < d && s + n > d) {
f0101b8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101b91:	3b 45 ec             	cmp    -0x14(%ebp),%eax
f0101b94:	73 6d                	jae    f0101c03 <memmove+0x8a>
f0101b96:	8b 45 10             	mov    0x10(%ebp),%eax
f0101b99:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101b9c:	01 d0                	add    %edx,%eax
f0101b9e:	3b 45 ec             	cmp    -0x14(%ebp),%eax
f0101ba1:	76 60                	jbe    f0101c03 <memmove+0x8a>
		s += n;
f0101ba3:	8b 45 10             	mov    0x10(%ebp),%eax
f0101ba6:	01 45 f0             	add    %eax,-0x10(%ebp)
		d += n;
f0101ba9:	8b 45 10             	mov    0x10(%ebp),%eax
f0101bac:	01 45 ec             	add    %eax,-0x14(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101baf:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101bb2:	83 e0 03             	and    $0x3,%eax
f0101bb5:	85 c0                	test   %eax,%eax
f0101bb7:	75 2f                	jne    f0101be8 <memmove+0x6f>
f0101bb9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101bbc:	83 e0 03             	and    $0x3,%eax
f0101bbf:	85 c0                	test   %eax,%eax
f0101bc1:	75 25                	jne    f0101be8 <memmove+0x6f>
f0101bc3:	8b 45 10             	mov    0x10(%ebp),%eax
f0101bc6:	83 e0 03             	and    $0x3,%eax
f0101bc9:	85 c0                	test   %eax,%eax
f0101bcb:	75 1b                	jne    f0101be8 <memmove+0x6f>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101bcd:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101bd0:	83 e8 04             	sub    $0x4,%eax
f0101bd3:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101bd6:	83 ea 04             	sub    $0x4,%edx
f0101bd9:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101bdc:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101bdf:	89 c7                	mov    %eax,%edi
f0101be1:	89 d6                	mov    %edx,%esi
f0101be3:	fd                   	std    
f0101be4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101be6:	eb 18                	jmp    f0101c00 <memmove+0x87>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101be8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101beb:	8d 50 ff             	lea    -0x1(%eax),%edx
f0101bee:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101bf1:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101bf4:	8b 45 10             	mov    0x10(%ebp),%eax
f0101bf7:	89 d7                	mov    %edx,%edi
f0101bf9:	89 de                	mov    %ebx,%esi
f0101bfb:	89 c1                	mov    %eax,%ecx
f0101bfd:	fd                   	std    
f0101bfe:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101c00:	fc                   	cld    
f0101c01:	eb 45                	jmp    f0101c48 <memmove+0xcf>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101c03:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101c06:	83 e0 03             	and    $0x3,%eax
f0101c09:	85 c0                	test   %eax,%eax
f0101c0b:	75 2b                	jne    f0101c38 <memmove+0xbf>
f0101c0d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101c10:	83 e0 03             	and    $0x3,%eax
f0101c13:	85 c0                	test   %eax,%eax
f0101c15:	75 21                	jne    f0101c38 <memmove+0xbf>
f0101c17:	8b 45 10             	mov    0x10(%ebp),%eax
f0101c1a:	83 e0 03             	and    $0x3,%eax
f0101c1d:	85 c0                	test   %eax,%eax
f0101c1f:	75 17                	jne    f0101c38 <memmove+0xbf>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101c21:	8b 45 10             	mov    0x10(%ebp),%eax
f0101c24:	c1 e8 02             	shr    $0x2,%eax
f0101c27:	89 c1                	mov    %eax,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101c29:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101c2c:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101c2f:	89 c7                	mov    %eax,%edi
f0101c31:	89 d6                	mov    %edx,%esi
f0101c33:	fc                   	cld    
f0101c34:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101c36:	eb 10                	jmp    f0101c48 <memmove+0xcf>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101c38:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101c3b:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101c3e:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101c41:	89 c7                	mov    %eax,%edi
f0101c43:	89 d6                	mov    %edx,%esi
f0101c45:	fc                   	cld    
f0101c46:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
f0101c48:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0101c4b:	83 c4 10             	add    $0x10,%esp
f0101c4e:	5b                   	pop    %ebx
f0101c4f:	5e                   	pop    %esi
f0101c50:	5f                   	pop    %edi
f0101c51:	5d                   	pop    %ebp
f0101c52:	c3                   	ret    

f0101c53 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101c53:	55                   	push   %ebp
f0101c54:	89 e5                	mov    %esp,%ebp
f0101c56:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101c59:	8b 45 10             	mov    0x10(%ebp),%eax
f0101c5c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101c60:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101c63:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101c67:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c6a:	89 04 24             	mov    %eax,(%esp)
f0101c6d:	e8 07 ff ff ff       	call   f0101b79 <memmove>
}
f0101c72:	c9                   	leave  
f0101c73:	c3                   	ret    

f0101c74 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101c74:	55                   	push   %ebp
f0101c75:	89 e5                	mov    %esp,%ebp
f0101c77:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
f0101c7a:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c7d:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
f0101c80:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101c83:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
f0101c86:	eb 30                	jmp    f0101cb8 <memcmp+0x44>
		if (*s1 != *s2)
f0101c88:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101c8b:	0f b6 10             	movzbl (%eax),%edx
f0101c8e:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101c91:	0f b6 00             	movzbl (%eax),%eax
f0101c94:	38 c2                	cmp    %al,%dl
f0101c96:	74 18                	je     f0101cb0 <memcmp+0x3c>
			return (int) *s1 - (int) *s2;
f0101c98:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101c9b:	0f b6 00             	movzbl (%eax),%eax
f0101c9e:	0f b6 d0             	movzbl %al,%edx
f0101ca1:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101ca4:	0f b6 00             	movzbl (%eax),%eax
f0101ca7:	0f b6 c0             	movzbl %al,%eax
f0101caa:	29 c2                	sub    %eax,%edx
f0101cac:	89 d0                	mov    %edx,%eax
f0101cae:	eb 1a                	jmp    f0101cca <memcmp+0x56>
		s1++, s2++;
f0101cb0:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f0101cb4:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101cb8:	8b 45 10             	mov    0x10(%ebp),%eax
f0101cbb:	8d 50 ff             	lea    -0x1(%eax),%edx
f0101cbe:	89 55 10             	mov    %edx,0x10(%ebp)
f0101cc1:	85 c0                	test   %eax,%eax
f0101cc3:	75 c3                	jne    f0101c88 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101cc5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101cca:	c9                   	leave  
f0101ccb:	c3                   	ret    

f0101ccc <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101ccc:	55                   	push   %ebp
f0101ccd:	89 e5                	mov    %esp,%ebp
f0101ccf:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
f0101cd2:	8b 45 10             	mov    0x10(%ebp),%eax
f0101cd5:	8b 55 08             	mov    0x8(%ebp),%edx
f0101cd8:	01 d0                	add    %edx,%eax
f0101cda:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
f0101cdd:	eb 13                	jmp    f0101cf2 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101cdf:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ce2:	0f b6 10             	movzbl (%eax),%edx
f0101ce5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101ce8:	38 c2                	cmp    %al,%dl
f0101cea:	75 02                	jne    f0101cee <memfind+0x22>
			break;
f0101cec:	eb 0c                	jmp    f0101cfa <memfind+0x2e>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101cee:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101cf2:	8b 45 08             	mov    0x8(%ebp),%eax
f0101cf5:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0101cf8:	72 e5                	jb     f0101cdf <memfind+0x13>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
f0101cfa:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0101cfd:	c9                   	leave  
f0101cfe:	c3                   	ret    

f0101cff <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101cff:	55                   	push   %ebp
f0101d00:	89 e5                	mov    %esp,%ebp
f0101d02:	83 ec 10             	sub    $0x10,%esp
	int neg = 0;
f0101d05:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	long val = 0;
f0101d0c:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101d13:	eb 04                	jmp    f0101d19 <strtol+0x1a>
		s++;
f0101d15:	83 45 08 01          	addl   $0x1,0x8(%ebp)
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101d19:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d1c:	0f b6 00             	movzbl (%eax),%eax
f0101d1f:	3c 20                	cmp    $0x20,%al
f0101d21:	74 f2                	je     f0101d15 <strtol+0x16>
f0101d23:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d26:	0f b6 00             	movzbl (%eax),%eax
f0101d29:	3c 09                	cmp    $0x9,%al
f0101d2b:	74 e8                	je     f0101d15 <strtol+0x16>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101d2d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d30:	0f b6 00             	movzbl (%eax),%eax
f0101d33:	3c 2b                	cmp    $0x2b,%al
f0101d35:	75 06                	jne    f0101d3d <strtol+0x3e>
		s++;
f0101d37:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101d3b:	eb 15                	jmp    f0101d52 <strtol+0x53>
	else if (*s == '-')
f0101d3d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d40:	0f b6 00             	movzbl (%eax),%eax
f0101d43:	3c 2d                	cmp    $0x2d,%al
f0101d45:	75 0b                	jne    f0101d52 <strtol+0x53>
		s++, neg = 1;
f0101d47:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101d4b:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101d52:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101d56:	74 06                	je     f0101d5e <strtol+0x5f>
f0101d58:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
f0101d5c:	75 24                	jne    f0101d82 <strtol+0x83>
f0101d5e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d61:	0f b6 00             	movzbl (%eax),%eax
f0101d64:	3c 30                	cmp    $0x30,%al
f0101d66:	75 1a                	jne    f0101d82 <strtol+0x83>
f0101d68:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d6b:	83 c0 01             	add    $0x1,%eax
f0101d6e:	0f b6 00             	movzbl (%eax),%eax
f0101d71:	3c 78                	cmp    $0x78,%al
f0101d73:	75 0d                	jne    f0101d82 <strtol+0x83>
		s += 2, base = 16;
f0101d75:	83 45 08 02          	addl   $0x2,0x8(%ebp)
f0101d79:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
f0101d80:	eb 2a                	jmp    f0101dac <strtol+0xad>
	else if (base == 0 && s[0] == '0')
f0101d82:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101d86:	75 17                	jne    f0101d9f <strtol+0xa0>
f0101d88:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d8b:	0f b6 00             	movzbl (%eax),%eax
f0101d8e:	3c 30                	cmp    $0x30,%al
f0101d90:	75 0d                	jne    f0101d9f <strtol+0xa0>
		s++, base = 8;
f0101d92:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101d96:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
f0101d9d:	eb 0d                	jmp    f0101dac <strtol+0xad>
	else if (base == 0)
f0101d9f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101da3:	75 07                	jne    f0101dac <strtol+0xad>
		base = 10;
f0101da5:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101dac:	8b 45 08             	mov    0x8(%ebp),%eax
f0101daf:	0f b6 00             	movzbl (%eax),%eax
f0101db2:	3c 2f                	cmp    $0x2f,%al
f0101db4:	7e 1b                	jle    f0101dd1 <strtol+0xd2>
f0101db6:	8b 45 08             	mov    0x8(%ebp),%eax
f0101db9:	0f b6 00             	movzbl (%eax),%eax
f0101dbc:	3c 39                	cmp    $0x39,%al
f0101dbe:	7f 11                	jg     f0101dd1 <strtol+0xd2>
			dig = *s - '0';
f0101dc0:	8b 45 08             	mov    0x8(%ebp),%eax
f0101dc3:	0f b6 00             	movzbl (%eax),%eax
f0101dc6:	0f be c0             	movsbl %al,%eax
f0101dc9:	83 e8 30             	sub    $0x30,%eax
f0101dcc:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101dcf:	eb 48                	jmp    f0101e19 <strtol+0x11a>
		else if (*s >= 'a' && *s <= 'z')
f0101dd1:	8b 45 08             	mov    0x8(%ebp),%eax
f0101dd4:	0f b6 00             	movzbl (%eax),%eax
f0101dd7:	3c 60                	cmp    $0x60,%al
f0101dd9:	7e 1b                	jle    f0101df6 <strtol+0xf7>
f0101ddb:	8b 45 08             	mov    0x8(%ebp),%eax
f0101dde:	0f b6 00             	movzbl (%eax),%eax
f0101de1:	3c 7a                	cmp    $0x7a,%al
f0101de3:	7f 11                	jg     f0101df6 <strtol+0xf7>
			dig = *s - 'a' + 10;
f0101de5:	8b 45 08             	mov    0x8(%ebp),%eax
f0101de8:	0f b6 00             	movzbl (%eax),%eax
f0101deb:	0f be c0             	movsbl %al,%eax
f0101dee:	83 e8 57             	sub    $0x57,%eax
f0101df1:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101df4:	eb 23                	jmp    f0101e19 <strtol+0x11a>
		else if (*s >= 'A' && *s <= 'Z')
f0101df6:	8b 45 08             	mov    0x8(%ebp),%eax
f0101df9:	0f b6 00             	movzbl (%eax),%eax
f0101dfc:	3c 40                	cmp    $0x40,%al
f0101dfe:	7e 3d                	jle    f0101e3d <strtol+0x13e>
f0101e00:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e03:	0f b6 00             	movzbl (%eax),%eax
f0101e06:	3c 5a                	cmp    $0x5a,%al
f0101e08:	7f 33                	jg     f0101e3d <strtol+0x13e>
			dig = *s - 'A' + 10;
f0101e0a:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e0d:	0f b6 00             	movzbl (%eax),%eax
f0101e10:	0f be c0             	movsbl %al,%eax
f0101e13:	83 e8 37             	sub    $0x37,%eax
f0101e16:	89 45 f4             	mov    %eax,-0xc(%ebp)
		else
			break;
		if (dig >= base)
f0101e19:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101e1c:	3b 45 10             	cmp    0x10(%ebp),%eax
f0101e1f:	7c 02                	jl     f0101e23 <strtol+0x124>
			break;
f0101e21:	eb 1a                	jmp    f0101e3d <strtol+0x13e>
		s++, val = (val * base) + dig;
f0101e23:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101e27:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101e2a:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101e2e:	89 c2                	mov    %eax,%edx
f0101e30:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101e33:	01 d0                	add    %edx,%eax
f0101e35:	89 45 f8             	mov    %eax,-0x8(%ebp)
		// we don't properly detect overflow!
	}
f0101e38:	e9 6f ff ff ff       	jmp    f0101dac <strtol+0xad>

	if (endptr)
f0101e3d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101e41:	74 08                	je     f0101e4b <strtol+0x14c>
		*endptr = (char *) s;
f0101e43:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101e46:	8b 55 08             	mov    0x8(%ebp),%edx
f0101e49:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f0101e4b:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f0101e4f:	74 07                	je     f0101e58 <strtol+0x159>
f0101e51:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101e54:	f7 d8                	neg    %eax
f0101e56:	eb 03                	jmp    f0101e5b <strtol+0x15c>
f0101e58:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0101e5b:	c9                   	leave  
f0101e5c:	c3                   	ret    
f0101e5d:	66 90                	xchg   %ax,%ax
f0101e5f:	90                   	nop

f0101e60 <__udivdi3>:
f0101e60:	55                   	push   %ebp
f0101e61:	57                   	push   %edi
f0101e62:	56                   	push   %esi
f0101e63:	83 ec 0c             	sub    $0xc,%esp
f0101e66:	8b 44 24 28          	mov    0x28(%esp),%eax
f0101e6a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0101e6e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101e72:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101e76:	85 c0                	test   %eax,%eax
f0101e78:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101e7c:	89 ea                	mov    %ebp,%edx
f0101e7e:	89 0c 24             	mov    %ecx,(%esp)
f0101e81:	75 2d                	jne    f0101eb0 <__udivdi3+0x50>
f0101e83:	39 e9                	cmp    %ebp,%ecx
f0101e85:	77 61                	ja     f0101ee8 <__udivdi3+0x88>
f0101e87:	85 c9                	test   %ecx,%ecx
f0101e89:	89 ce                	mov    %ecx,%esi
f0101e8b:	75 0b                	jne    f0101e98 <__udivdi3+0x38>
f0101e8d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101e92:	31 d2                	xor    %edx,%edx
f0101e94:	f7 f1                	div    %ecx
f0101e96:	89 c6                	mov    %eax,%esi
f0101e98:	31 d2                	xor    %edx,%edx
f0101e9a:	89 e8                	mov    %ebp,%eax
f0101e9c:	f7 f6                	div    %esi
f0101e9e:	89 c5                	mov    %eax,%ebp
f0101ea0:	89 f8                	mov    %edi,%eax
f0101ea2:	f7 f6                	div    %esi
f0101ea4:	89 ea                	mov    %ebp,%edx
f0101ea6:	83 c4 0c             	add    $0xc,%esp
f0101ea9:	5e                   	pop    %esi
f0101eaa:	5f                   	pop    %edi
f0101eab:	5d                   	pop    %ebp
f0101eac:	c3                   	ret    
f0101ead:	8d 76 00             	lea    0x0(%esi),%esi
f0101eb0:	39 e8                	cmp    %ebp,%eax
f0101eb2:	77 24                	ja     f0101ed8 <__udivdi3+0x78>
f0101eb4:	0f bd e8             	bsr    %eax,%ebp
f0101eb7:	83 f5 1f             	xor    $0x1f,%ebp
f0101eba:	75 3c                	jne    f0101ef8 <__udivdi3+0x98>
f0101ebc:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101ec0:	39 34 24             	cmp    %esi,(%esp)
f0101ec3:	0f 86 9f 00 00 00    	jbe    f0101f68 <__udivdi3+0x108>
f0101ec9:	39 d0                	cmp    %edx,%eax
f0101ecb:	0f 82 97 00 00 00    	jb     f0101f68 <__udivdi3+0x108>
f0101ed1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101ed8:	31 d2                	xor    %edx,%edx
f0101eda:	31 c0                	xor    %eax,%eax
f0101edc:	83 c4 0c             	add    $0xc,%esp
f0101edf:	5e                   	pop    %esi
f0101ee0:	5f                   	pop    %edi
f0101ee1:	5d                   	pop    %ebp
f0101ee2:	c3                   	ret    
f0101ee3:	90                   	nop
f0101ee4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ee8:	89 f8                	mov    %edi,%eax
f0101eea:	f7 f1                	div    %ecx
f0101eec:	31 d2                	xor    %edx,%edx
f0101eee:	83 c4 0c             	add    $0xc,%esp
f0101ef1:	5e                   	pop    %esi
f0101ef2:	5f                   	pop    %edi
f0101ef3:	5d                   	pop    %ebp
f0101ef4:	c3                   	ret    
f0101ef5:	8d 76 00             	lea    0x0(%esi),%esi
f0101ef8:	89 e9                	mov    %ebp,%ecx
f0101efa:	8b 3c 24             	mov    (%esp),%edi
f0101efd:	d3 e0                	shl    %cl,%eax
f0101eff:	89 c6                	mov    %eax,%esi
f0101f01:	b8 20 00 00 00       	mov    $0x20,%eax
f0101f06:	29 e8                	sub    %ebp,%eax
f0101f08:	89 c1                	mov    %eax,%ecx
f0101f0a:	d3 ef                	shr    %cl,%edi
f0101f0c:	89 e9                	mov    %ebp,%ecx
f0101f0e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101f12:	8b 3c 24             	mov    (%esp),%edi
f0101f15:	09 74 24 08          	or     %esi,0x8(%esp)
f0101f19:	89 d6                	mov    %edx,%esi
f0101f1b:	d3 e7                	shl    %cl,%edi
f0101f1d:	89 c1                	mov    %eax,%ecx
f0101f1f:	89 3c 24             	mov    %edi,(%esp)
f0101f22:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101f26:	d3 ee                	shr    %cl,%esi
f0101f28:	89 e9                	mov    %ebp,%ecx
f0101f2a:	d3 e2                	shl    %cl,%edx
f0101f2c:	89 c1                	mov    %eax,%ecx
f0101f2e:	d3 ef                	shr    %cl,%edi
f0101f30:	09 d7                	or     %edx,%edi
f0101f32:	89 f2                	mov    %esi,%edx
f0101f34:	89 f8                	mov    %edi,%eax
f0101f36:	f7 74 24 08          	divl   0x8(%esp)
f0101f3a:	89 d6                	mov    %edx,%esi
f0101f3c:	89 c7                	mov    %eax,%edi
f0101f3e:	f7 24 24             	mull   (%esp)
f0101f41:	39 d6                	cmp    %edx,%esi
f0101f43:	89 14 24             	mov    %edx,(%esp)
f0101f46:	72 30                	jb     f0101f78 <__udivdi3+0x118>
f0101f48:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101f4c:	89 e9                	mov    %ebp,%ecx
f0101f4e:	d3 e2                	shl    %cl,%edx
f0101f50:	39 c2                	cmp    %eax,%edx
f0101f52:	73 05                	jae    f0101f59 <__udivdi3+0xf9>
f0101f54:	3b 34 24             	cmp    (%esp),%esi
f0101f57:	74 1f                	je     f0101f78 <__udivdi3+0x118>
f0101f59:	89 f8                	mov    %edi,%eax
f0101f5b:	31 d2                	xor    %edx,%edx
f0101f5d:	e9 7a ff ff ff       	jmp    f0101edc <__udivdi3+0x7c>
f0101f62:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101f68:	31 d2                	xor    %edx,%edx
f0101f6a:	b8 01 00 00 00       	mov    $0x1,%eax
f0101f6f:	e9 68 ff ff ff       	jmp    f0101edc <__udivdi3+0x7c>
f0101f74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101f78:	8d 47 ff             	lea    -0x1(%edi),%eax
f0101f7b:	31 d2                	xor    %edx,%edx
f0101f7d:	83 c4 0c             	add    $0xc,%esp
f0101f80:	5e                   	pop    %esi
f0101f81:	5f                   	pop    %edi
f0101f82:	5d                   	pop    %ebp
f0101f83:	c3                   	ret    
f0101f84:	66 90                	xchg   %ax,%ax
f0101f86:	66 90                	xchg   %ax,%ax
f0101f88:	66 90                	xchg   %ax,%ax
f0101f8a:	66 90                	xchg   %ax,%ax
f0101f8c:	66 90                	xchg   %ax,%ax
f0101f8e:	66 90                	xchg   %ax,%ax

f0101f90 <__umoddi3>:
f0101f90:	55                   	push   %ebp
f0101f91:	57                   	push   %edi
f0101f92:	56                   	push   %esi
f0101f93:	83 ec 14             	sub    $0x14,%esp
f0101f96:	8b 44 24 28          	mov    0x28(%esp),%eax
f0101f9a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101f9e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101fa2:	89 c7                	mov    %eax,%edi
f0101fa4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101fa8:	8b 44 24 30          	mov    0x30(%esp),%eax
f0101fac:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101fb0:	89 34 24             	mov    %esi,(%esp)
f0101fb3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101fb7:	85 c0                	test   %eax,%eax
f0101fb9:	89 c2                	mov    %eax,%edx
f0101fbb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101fbf:	75 17                	jne    f0101fd8 <__umoddi3+0x48>
f0101fc1:	39 fe                	cmp    %edi,%esi
f0101fc3:	76 4b                	jbe    f0102010 <__umoddi3+0x80>
f0101fc5:	89 c8                	mov    %ecx,%eax
f0101fc7:	89 fa                	mov    %edi,%edx
f0101fc9:	f7 f6                	div    %esi
f0101fcb:	89 d0                	mov    %edx,%eax
f0101fcd:	31 d2                	xor    %edx,%edx
f0101fcf:	83 c4 14             	add    $0x14,%esp
f0101fd2:	5e                   	pop    %esi
f0101fd3:	5f                   	pop    %edi
f0101fd4:	5d                   	pop    %ebp
f0101fd5:	c3                   	ret    
f0101fd6:	66 90                	xchg   %ax,%ax
f0101fd8:	39 f8                	cmp    %edi,%eax
f0101fda:	77 54                	ja     f0102030 <__umoddi3+0xa0>
f0101fdc:	0f bd e8             	bsr    %eax,%ebp
f0101fdf:	83 f5 1f             	xor    $0x1f,%ebp
f0101fe2:	75 5c                	jne    f0102040 <__umoddi3+0xb0>
f0101fe4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101fe8:	39 3c 24             	cmp    %edi,(%esp)
f0101feb:	0f 87 e7 00 00 00    	ja     f01020d8 <__umoddi3+0x148>
f0101ff1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101ff5:	29 f1                	sub    %esi,%ecx
f0101ff7:	19 c7                	sbb    %eax,%edi
f0101ff9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101ffd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102001:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102005:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0102009:	83 c4 14             	add    $0x14,%esp
f010200c:	5e                   	pop    %esi
f010200d:	5f                   	pop    %edi
f010200e:	5d                   	pop    %ebp
f010200f:	c3                   	ret    
f0102010:	85 f6                	test   %esi,%esi
f0102012:	89 f5                	mov    %esi,%ebp
f0102014:	75 0b                	jne    f0102021 <__umoddi3+0x91>
f0102016:	b8 01 00 00 00       	mov    $0x1,%eax
f010201b:	31 d2                	xor    %edx,%edx
f010201d:	f7 f6                	div    %esi
f010201f:	89 c5                	mov    %eax,%ebp
f0102021:	8b 44 24 04          	mov    0x4(%esp),%eax
f0102025:	31 d2                	xor    %edx,%edx
f0102027:	f7 f5                	div    %ebp
f0102029:	89 c8                	mov    %ecx,%eax
f010202b:	f7 f5                	div    %ebp
f010202d:	eb 9c                	jmp    f0101fcb <__umoddi3+0x3b>
f010202f:	90                   	nop
f0102030:	89 c8                	mov    %ecx,%eax
f0102032:	89 fa                	mov    %edi,%edx
f0102034:	83 c4 14             	add    $0x14,%esp
f0102037:	5e                   	pop    %esi
f0102038:	5f                   	pop    %edi
f0102039:	5d                   	pop    %ebp
f010203a:	c3                   	ret    
f010203b:	90                   	nop
f010203c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102040:	8b 04 24             	mov    (%esp),%eax
f0102043:	be 20 00 00 00       	mov    $0x20,%esi
f0102048:	89 e9                	mov    %ebp,%ecx
f010204a:	29 ee                	sub    %ebp,%esi
f010204c:	d3 e2                	shl    %cl,%edx
f010204e:	89 f1                	mov    %esi,%ecx
f0102050:	d3 e8                	shr    %cl,%eax
f0102052:	89 e9                	mov    %ebp,%ecx
f0102054:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102058:	8b 04 24             	mov    (%esp),%eax
f010205b:	09 54 24 04          	or     %edx,0x4(%esp)
f010205f:	89 fa                	mov    %edi,%edx
f0102061:	d3 e0                	shl    %cl,%eax
f0102063:	89 f1                	mov    %esi,%ecx
f0102065:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102069:	8b 44 24 10          	mov    0x10(%esp),%eax
f010206d:	d3 ea                	shr    %cl,%edx
f010206f:	89 e9                	mov    %ebp,%ecx
f0102071:	d3 e7                	shl    %cl,%edi
f0102073:	89 f1                	mov    %esi,%ecx
f0102075:	d3 e8                	shr    %cl,%eax
f0102077:	89 e9                	mov    %ebp,%ecx
f0102079:	09 f8                	or     %edi,%eax
f010207b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010207f:	f7 74 24 04          	divl   0x4(%esp)
f0102083:	d3 e7                	shl    %cl,%edi
f0102085:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102089:	89 d7                	mov    %edx,%edi
f010208b:	f7 64 24 08          	mull   0x8(%esp)
f010208f:	39 d7                	cmp    %edx,%edi
f0102091:	89 c1                	mov    %eax,%ecx
f0102093:	89 14 24             	mov    %edx,(%esp)
f0102096:	72 2c                	jb     f01020c4 <__umoddi3+0x134>
f0102098:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010209c:	72 22                	jb     f01020c0 <__umoddi3+0x130>
f010209e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01020a2:	29 c8                	sub    %ecx,%eax
f01020a4:	19 d7                	sbb    %edx,%edi
f01020a6:	89 e9                	mov    %ebp,%ecx
f01020a8:	89 fa                	mov    %edi,%edx
f01020aa:	d3 e8                	shr    %cl,%eax
f01020ac:	89 f1                	mov    %esi,%ecx
f01020ae:	d3 e2                	shl    %cl,%edx
f01020b0:	89 e9                	mov    %ebp,%ecx
f01020b2:	d3 ef                	shr    %cl,%edi
f01020b4:	09 d0                	or     %edx,%eax
f01020b6:	89 fa                	mov    %edi,%edx
f01020b8:	83 c4 14             	add    $0x14,%esp
f01020bb:	5e                   	pop    %esi
f01020bc:	5f                   	pop    %edi
f01020bd:	5d                   	pop    %ebp
f01020be:	c3                   	ret    
f01020bf:	90                   	nop
f01020c0:	39 d7                	cmp    %edx,%edi
f01020c2:	75 da                	jne    f010209e <__umoddi3+0x10e>
f01020c4:	8b 14 24             	mov    (%esp),%edx
f01020c7:	89 c1                	mov    %eax,%ecx
f01020c9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01020cd:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01020d1:	eb cb                	jmp    f010209e <__umoddi3+0x10e>
f01020d3:	90                   	nop
f01020d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01020d8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01020dc:	0f 82 0f ff ff ff    	jb     f0101ff1 <__umoddi3+0x61>
f01020e2:	e9 1a ff ff ff       	jmp    f0102001 <__umoddi3+0x71>
