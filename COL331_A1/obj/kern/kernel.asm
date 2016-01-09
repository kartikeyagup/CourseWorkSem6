
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
f010004d:	c7 04 24 e0 20 10 f0 	movl   $0xf01020e0,(%esp)
f0100054:	e8 86 0c 00 00       	call   f0100cdf <cprintf>
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
f0100086:	e8 53 0a 00 00       	call   f0100ade <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f010008b:	8b 45 08             	mov    0x8(%ebp),%eax
f010008e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100092:	c7 04 24 fc 20 10 f0 	movl   $0xf01020fc,(%esp)
f0100099:	e8 41 0c 00 00       	call   f0100cdf <cprintf>
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
f01000c7:	e8 1e 1a 00 00       	call   f0101aea <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cc:	e8 5d 08 00 00       	call   f010092e <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d1:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d8:	00 
f01000d9:	c7 04 24 17 21 10 f0 	movl   $0xf0102117,(%esp)
f01000e0:	e8 fa 0b 00 00       	call   f0100cdf <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000e5:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000ec:	e8 4f ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000f1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f8:	e8 44 0b 00 00       	call   f0100c41 <monitor>
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
f010012e:	c7 04 24 32 21 10 f0 	movl   $0xf0102132,(%esp)
f0100135:	e8 a5 0b 00 00       	call   f0100cdf <cprintf>
	vcprintf(fmt, ap);
f010013a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010013d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100141:	8b 45 10             	mov    0x10(%ebp),%eax
f0100144:	89 04 24             	mov    %eax,(%esp)
f0100147:	e8 60 0b 00 00       	call   f0100cac <vcprintf>
	cprintf("\n");
f010014c:	c7 04 24 4a 21 10 f0 	movl   $0xf010214a,(%esp)
f0100153:	e8 87 0b 00 00       	call   f0100cdf <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100158:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010015f:	e8 dd 0a 00 00       	call   f0100c41 <monitor>
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
f0100180:	c7 04 24 4c 21 10 f0 	movl   $0xf010214c,(%esp)
f0100187:	e8 53 0b 00 00       	call   f0100cdf <cprintf>
	vcprintf(fmt, ap);
f010018c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010018f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100193:	8b 45 10             	mov    0x10(%ebp),%eax
f0100196:	89 04 24             	mov    %eax,(%esp)
f0100199:	e8 0e 0b 00 00       	call   f0100cac <vcprintf>
	cprintf("\n");
f010019e:	c7 04 24 4a 21 10 f0 	movl   $0xf010214a,(%esp)
f01001a5:	e8 35 0b 00 00       	call   f0100cdf <cprintf>
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
f0100250:	e8 07 06 00 00       	call   f010085c <cons_intr>
}
f0100255:	c9                   	leave  
f0100256:	c3                   	ret    

f0100257 <serial_putc>:

static void
serial_putc(int c)
{
f0100257:	55                   	push   %ebp
f0100258:	89 e5                	mov    %esp,%ebp
f010025a:	83 ec 10             	sub    $0x10,%esp
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

	//printf to shell using serial interface. code to follow

}
f0100296:	c9                   	leave  
f0100297:	c3                   	ret    

f0100298 <serial_init>:

static void
serial_init(void)
{
f0100298:	55                   	push   %ebp
f0100299:	89 e5                	mov    %esp,%ebp
f010029b:	83 ec 50             	sub    $0x50,%esp
f010029e:	c7 45 fc fa 03 00 00 	movl   $0x3fa,-0x4(%ebp)
f01002a5:	c6 45 fb 00          	movb   $0x0,-0x5(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002a9:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
f01002ad:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01002b0:	ee                   	out    %al,(%dx)
f01002b1:	c7 45 f4 fb 03 00 00 	movl   $0x3fb,-0xc(%ebp)
f01002b8:	c6 45 f3 80          	movb   $0x80,-0xd(%ebp)
f01002bc:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01002c0:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01002c3:	ee                   	out    %al,(%dx)
f01002c4:	c7 45 ec f8 03 00 00 	movl   $0x3f8,-0x14(%ebp)
f01002cb:	c6 45 eb 0c          	movb   $0xc,-0x15(%ebp)
f01002cf:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
f01002d3:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01002d6:	ee                   	out    %al,(%dx)
f01002d7:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
f01002de:	c6 45 e3 00          	movb   $0x0,-0x1d(%ebp)
f01002e2:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f01002e6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01002e9:	ee                   	out    %al,(%dx)
f01002ea:	c7 45 dc fb 03 00 00 	movl   $0x3fb,-0x24(%ebp)
f01002f1:	c6 45 db 03          	movb   $0x3,-0x25(%ebp)
f01002f5:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
f01002f9:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01002fc:	ee                   	out    %al,(%dx)
f01002fd:	c7 45 d4 fc 03 00 00 	movl   $0x3fc,-0x2c(%ebp)
f0100304:	c6 45 d3 00          	movb   $0x0,-0x2d(%ebp)
f0100308:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
f010030c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010030f:	ee                   	out    %al,(%dx)
f0100310:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
f0100317:	c6 45 cb 01          	movb   $0x1,-0x35(%ebp)
f010031b:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
f010031f:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0100322:	ee                   	out    %al,(%dx)
f0100323:	c7 45 c4 fd 03 00 00 	movl   $0x3fd,-0x3c(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010032a:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010032d:	89 c2                	mov    %eax,%edx
f010032f:	ec                   	in     (%dx),%al
f0100330:	88 45 c3             	mov    %al,-0x3d(%ebp)
	return data;
f0100333:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100337:	3c ff                	cmp    $0xff,%al
f0100339:	0f 95 c0             	setne  %al
f010033c:	a2 40 25 11 f0       	mov    %al,0xf0112540
f0100341:	c7 45 bc fa 03 00 00 	movl   $0x3fa,-0x44(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100348:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010034b:	89 c2                	mov    %eax,%edx
f010034d:	ec                   	in     (%dx),%al
f010034e:	88 45 bb             	mov    %al,-0x45(%ebp)
f0100351:	c7 45 b4 f8 03 00 00 	movl   $0x3f8,-0x4c(%ebp)
f0100358:	8b 45 b4             	mov    -0x4c(%ebp),%eax
f010035b:	89 c2                	mov    %eax,%edx
f010035d:	ec                   	in     (%dx),%al
f010035e:	88 45 b3             	mov    %al,-0x4d(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

}
f0100361:	c9                   	leave  
f0100362:	c3                   	ret    

f0100363 <lpt_putc>:
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
f0100363:	55                   	push   %ebp
f0100364:	89 e5                	mov    %esp,%ebp
f0100366:	83 ec 30             	sub    $0x30,%esp
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100369:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0100370:	eb 09                	jmp    f010037b <lpt_putc+0x18>
		delay();
f0100372:	e8 35 fe ff ff       	call   f01001ac <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100377:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f010037b:	c7 45 f8 79 03 00 00 	movl   $0x379,-0x8(%ebp)
f0100382:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100385:	89 c2                	mov    %eax,%edx
f0100387:	ec                   	in     (%dx),%al
f0100388:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
f010038b:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
f010038f:	84 c0                	test   %al,%al
f0100391:	78 09                	js     f010039c <lpt_putc+0x39>
f0100393:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
f010039a:	7e d6                	jle    f0100372 <lpt_putc+0xf>
		delay();
	outb(0x378+0, c);
f010039c:	8b 45 08             	mov    0x8(%ebp),%eax
f010039f:	0f b6 c0             	movzbl %al,%eax
f01003a2:	c7 45 f0 78 03 00 00 	movl   $0x378,-0x10(%ebp)
f01003a9:	88 45 ef             	mov    %al,-0x11(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003ac:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
f01003b0:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01003b3:	ee                   	out    %al,(%dx)
f01003b4:	c7 45 e8 7a 03 00 00 	movl   $0x37a,-0x18(%ebp)
f01003bb:	c6 45 e7 0d          	movb   $0xd,-0x19(%ebp)
f01003bf:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f01003c3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01003c6:	ee                   	out    %al,(%dx)
f01003c7:	c7 45 e0 7a 03 00 00 	movl   $0x37a,-0x20(%ebp)
f01003ce:	c6 45 df 08          	movb   $0x8,-0x21(%ebp)
f01003d2:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
f01003d6:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01003d9:	ee                   	out    %al,(%dx)
	outb(0x378+2, 0x08|0x04|0x01);
	outb(0x378+2, 0x08);
}
f01003da:	c9                   	leave  
f01003db:	c3                   	ret    

f01003dc <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
f01003dc:	55                   	push   %ebp
f01003dd:	89 e5                	mov    %esp,%ebp
f01003df:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01003e2:	c7 45 fc 00 80 0b f0 	movl   $0xf00b8000,-0x4(%ebp)
	was = *cp;
f01003e9:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01003ec:	0f b7 00             	movzwl (%eax),%eax
f01003ef:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
	*cp = (uint16_t) 0xA55A;
f01003f3:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01003f6:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
f01003fb:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01003fe:	0f b7 00             	movzwl (%eax),%eax
f0100401:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100405:	74 13                	je     f010041a <cga_init+0x3e>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100407:	c7 45 fc 00 00 0b f0 	movl   $0xf00b0000,-0x4(%ebp)
		addr_6845 = MONO_BASE;
f010040e:	c7 05 44 25 11 f0 b4 	movl   $0x3b4,0xf0112544
f0100415:	03 00 00 
f0100418:	eb 14                	jmp    f010042e <cga_init+0x52>
	} else {
		*cp = was;
f010041a:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010041d:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
f0100421:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
f0100424:	c7 05 44 25 11 f0 d4 	movl   $0x3d4,0xf0112544
f010042b:	03 00 00 
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010042e:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f0100433:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100436:	c6 45 ef 0e          	movb   $0xe,-0x11(%ebp)
f010043a:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
f010043e:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100441:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100442:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f0100447:	83 c0 01             	add    $0x1,%eax
f010044a:	89 45 e8             	mov    %eax,-0x18(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010044d:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100450:	89 c2                	mov    %eax,%edx
f0100452:	ec                   	in     (%dx),%al
f0100453:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
f0100456:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010045a:	0f b6 c0             	movzbl %al,%eax
f010045d:	c1 e0 08             	shl    $0x8,%eax
f0100460:	89 45 f4             	mov    %eax,-0xc(%ebp)
	outb(addr_6845, 15);
f0100463:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f0100468:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010046b:	c6 45 df 0f          	movb   $0xf,-0x21(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010046f:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
f0100473:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100476:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
f0100477:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f010047c:	83 c0 01             	add    $0x1,%eax
f010047f:	89 45 d8             	mov    %eax,-0x28(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100482:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100485:	89 c2                	mov    %eax,%edx
f0100487:	ec                   	in     (%dx),%al
f0100488:	88 45 d7             	mov    %al,-0x29(%ebp)
	return data;
f010048b:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
f010048f:	0f b6 c0             	movzbl %al,%eax
f0100492:	09 45 f4             	or     %eax,-0xc(%ebp)

	crt_buf = (uint16_t*) cp;
f0100495:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100498:	a3 48 25 11 f0       	mov    %eax,0xf0112548
	crt_pos = pos;
f010049d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01004a0:	66 a3 4c 25 11 f0    	mov    %ax,0xf011254c
}
f01004a6:	c9                   	leave  
f01004a7:	c3                   	ret    

f01004a8 <cga_putc>:



static void
cga_putc(int c)
{
f01004a8:	55                   	push   %ebp
f01004a9:	89 e5                	mov    %esp,%ebp
f01004ab:	53                   	push   %ebx
f01004ac:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004af:	8b 45 08             	mov    0x8(%ebp),%eax
f01004b2:	b0 00                	mov    $0x0,%al
f01004b4:	85 c0                	test   %eax,%eax
f01004b6:	75 07                	jne    f01004bf <cga_putc+0x17>
		c |= 0x0700;
f01004b8:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
f01004bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01004c2:	0f b6 c0             	movzbl %al,%eax
f01004c5:	83 f8 09             	cmp    $0x9,%eax
f01004c8:	0f 84 ac 00 00 00    	je     f010057a <cga_putc+0xd2>
f01004ce:	83 f8 09             	cmp    $0x9,%eax
f01004d1:	7f 0a                	jg     f01004dd <cga_putc+0x35>
f01004d3:	83 f8 08             	cmp    $0x8,%eax
f01004d6:	74 14                	je     f01004ec <cga_putc+0x44>
f01004d8:	e9 db 00 00 00       	jmp    f01005b8 <cga_putc+0x110>
f01004dd:	83 f8 0a             	cmp    $0xa,%eax
f01004e0:	74 4e                	je     f0100530 <cga_putc+0x88>
f01004e2:	83 f8 0d             	cmp    $0xd,%eax
f01004e5:	74 59                	je     f0100540 <cga_putc+0x98>
f01004e7:	e9 cc 00 00 00       	jmp    f01005b8 <cga_putc+0x110>
	case '\b':
		if (crt_pos > 0) {
f01004ec:	0f b7 05 4c 25 11 f0 	movzwl 0xf011254c,%eax
f01004f3:	66 85 c0             	test   %ax,%ax
f01004f6:	74 33                	je     f010052b <cga_putc+0x83>
			crt_pos--;
f01004f8:	0f b7 05 4c 25 11 f0 	movzwl 0xf011254c,%eax
f01004ff:	83 e8 01             	sub    $0x1,%eax
f0100502:	66 a3 4c 25 11 f0    	mov    %ax,0xf011254c
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100508:	a1 48 25 11 f0       	mov    0xf0112548,%eax
f010050d:	0f b7 15 4c 25 11 f0 	movzwl 0xf011254c,%edx
f0100514:	0f b7 d2             	movzwl %dx,%edx
f0100517:	01 d2                	add    %edx,%edx
f0100519:	01 c2                	add    %eax,%edx
f010051b:	8b 45 08             	mov    0x8(%ebp),%eax
f010051e:	b0 00                	mov    $0x0,%al
f0100520:	83 c8 20             	or     $0x20,%eax
f0100523:	66 89 02             	mov    %ax,(%edx)
		}
		break;
f0100526:	e9 b3 00 00 00       	jmp    f01005de <cga_putc+0x136>
f010052b:	e9 ae 00 00 00       	jmp    f01005de <cga_putc+0x136>
	case '\n':
		crt_pos += CRT_COLS;
f0100530:	0f b7 05 4c 25 11 f0 	movzwl 0xf011254c,%eax
f0100537:	83 c0 50             	add    $0x50,%eax
f010053a:	66 a3 4c 25 11 f0    	mov    %ax,0xf011254c
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100540:	0f b7 1d 4c 25 11 f0 	movzwl 0xf011254c,%ebx
f0100547:	0f b7 0d 4c 25 11 f0 	movzwl 0xf011254c,%ecx
f010054e:	0f b7 c1             	movzwl %cx,%eax
f0100551:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100557:	c1 e8 10             	shr    $0x10,%eax
f010055a:	89 c2                	mov    %eax,%edx
f010055c:	66 c1 ea 06          	shr    $0x6,%dx
f0100560:	89 d0                	mov    %edx,%eax
f0100562:	c1 e0 02             	shl    $0x2,%eax
f0100565:	01 d0                	add    %edx,%eax
f0100567:	c1 e0 04             	shl    $0x4,%eax
f010056a:	29 c1                	sub    %eax,%ecx
f010056c:	89 ca                	mov    %ecx,%edx
f010056e:	89 d8                	mov    %ebx,%eax
f0100570:	29 d0                	sub    %edx,%eax
f0100572:	66 a3 4c 25 11 f0    	mov    %ax,0xf011254c
		break;
f0100578:	eb 64                	jmp    f01005de <cga_putc+0x136>
	case '\t':
		cons_putc(' ');
f010057a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100581:	e8 7f 03 00 00       	call   f0100905 <cons_putc>
		cons_putc(' ');
f0100586:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010058d:	e8 73 03 00 00       	call   f0100905 <cons_putc>
		cons_putc(' ');
f0100592:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100599:	e8 67 03 00 00       	call   f0100905 <cons_putc>
		cons_putc(' ');
f010059e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01005a5:	e8 5b 03 00 00       	call   f0100905 <cons_putc>
		cons_putc(' ');
f01005aa:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01005b1:	e8 4f 03 00 00       	call   f0100905 <cons_putc>
		break;
f01005b6:	eb 26                	jmp    f01005de <cga_putc+0x136>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01005b8:	8b 0d 48 25 11 f0    	mov    0xf0112548,%ecx
f01005be:	0f b7 05 4c 25 11 f0 	movzwl 0xf011254c,%eax
f01005c5:	8d 50 01             	lea    0x1(%eax),%edx
f01005c8:	66 89 15 4c 25 11 f0 	mov    %dx,0xf011254c
f01005cf:	0f b7 c0             	movzwl %ax,%eax
f01005d2:	01 c0                	add    %eax,%eax
f01005d4:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f01005d7:	8b 45 08             	mov    0x8(%ebp),%eax
f01005da:	66 89 02             	mov    %ax,(%edx)
		break;
f01005dd:	90                   	nop
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005de:	0f b7 05 4c 25 11 f0 	movzwl 0xf011254c,%eax
f01005e5:	66 3d cf 07          	cmp    $0x7cf,%ax
f01005e9:	76 5b                	jbe    f0100646 <cga_putc+0x19e>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005eb:	a1 48 25 11 f0       	mov    0xf0112548,%eax
f01005f0:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005f6:	a1 48 25 11 f0       	mov    0xf0112548,%eax
f01005fb:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100602:	00 
f0100603:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100607:	89 04 24             	mov    %eax,(%esp)
f010060a:	e8 49 15 00 00       	call   f0101b58 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010060f:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
f0100616:	eb 15                	jmp    f010062d <cga_putc+0x185>
			crt_buf[i] = 0x0700 | ' ';
f0100618:	a1 48 25 11 f0       	mov    0xf0112548,%eax
f010061d:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100620:	01 d2                	add    %edx,%edx
f0100622:	01 d0                	add    %edx,%eax
f0100624:	66 c7 00 20 07       	movw   $0x720,(%eax)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100629:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
f010062d:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
f0100634:	7e e2                	jle    f0100618 <cga_putc+0x170>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100636:	0f b7 05 4c 25 11 f0 	movzwl 0xf011254c,%eax
f010063d:	83 e8 50             	sub    $0x50,%eax
f0100640:	66 a3 4c 25 11 f0    	mov    %ax,0xf011254c
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100646:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f010064b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010064e:	c6 45 ef 0e          	movb   $0xe,-0x11(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100652:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
f0100656:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100659:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010065a:	0f b7 05 4c 25 11 f0 	movzwl 0xf011254c,%eax
f0100661:	66 c1 e8 08          	shr    $0x8,%ax
f0100665:	0f b6 c0             	movzbl %al,%eax
f0100668:	8b 15 44 25 11 f0    	mov    0xf0112544,%edx
f010066e:	83 c2 01             	add    $0x1,%edx
f0100671:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100674:	88 45 e7             	mov    %al,-0x19(%ebp)
f0100677:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010067b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010067e:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
f010067f:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f0100684:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100687:	c6 45 df 0f          	movb   $0xf,-0x21(%ebp)
f010068b:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
f010068f:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100692:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
f0100693:	0f b7 05 4c 25 11 f0 	movzwl 0xf011254c,%eax
f010069a:	0f b6 c0             	movzbl %al,%eax
f010069d:	8b 15 44 25 11 f0    	mov    0xf0112544,%edx
f01006a3:	83 c2 01             	add    $0x1,%edx
f01006a6:	89 55 d8             	mov    %edx,-0x28(%ebp)
f01006a9:	88 45 d7             	mov    %al,-0x29(%ebp)
f01006ac:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
f01006b0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01006b3:	ee                   	out    %al,(%dx)
}
f01006b4:	83 c4 44             	add    $0x44,%esp
f01006b7:	5b                   	pop    %ebx
f01006b8:	5d                   	pop    %ebp
f01006b9:	c3                   	ret    

f01006ba <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01006ba:	55                   	push   %ebp
f01006bb:	89 e5                	mov    %esp,%ebp
f01006bd:	83 ec 38             	sub    $0x38,%esp
f01006c0:	c7 45 ec 64 00 00 00 	movl   $0x64,-0x14(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01006ca:	89 c2                	mov    %eax,%edx
f01006cc:	ec                   	in     (%dx),%al
f01006cd:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
f01006d0:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01006d4:	0f b6 c0             	movzbl %al,%eax
f01006d7:	83 e0 01             	and    $0x1,%eax
f01006da:	85 c0                	test   %eax,%eax
f01006dc:	75 0a                	jne    f01006e8 <kbd_proc_data+0x2e>
		return -1;
f01006de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01006e3:	e9 59 01 00 00       	jmp    f0100841 <kbd_proc_data+0x187>
f01006e8:	c7 45 e4 60 00 00 00 	movl   $0x60,-0x1c(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01006f2:	89 c2                	mov    %eax,%edx
f01006f4:	ec                   	in     (%dx),%al
f01006f5:	88 45 e3             	mov    %al,-0x1d(%ebp)
	return data;
f01006f8:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax

	data = inb(KBDATAP);
f01006fc:	88 45 f3             	mov    %al,-0xd(%ebp)

	if (data == 0xE0) {
f01006ff:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
f0100703:	75 17                	jne    f010071c <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
f0100705:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f010070a:	83 c8 40             	or     $0x40,%eax
f010070d:	a3 68 27 11 f0       	mov    %eax,0xf0112768
		return 0;
f0100712:	b8 00 00 00 00       	mov    $0x0,%eax
f0100717:	e9 25 01 00 00       	jmp    f0100841 <kbd_proc_data+0x187>
	} else if (data & 0x80) {
f010071c:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100720:	84 c0                	test   %al,%al
f0100722:	79 47                	jns    f010076b <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100724:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f0100729:	83 e0 40             	and    $0x40,%eax
f010072c:	85 c0                	test   %eax,%eax
f010072e:	75 09                	jne    f0100739 <kbd_proc_data+0x7f>
f0100730:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100734:	83 e0 7f             	and    $0x7f,%eax
f0100737:	eb 04                	jmp    f010073d <kbd_proc_data+0x83>
f0100739:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f010073d:	88 45 f3             	mov    %al,-0xd(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
f0100740:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100744:	0f b6 80 00 20 11 f0 	movzbl -0xfeee000(%eax),%eax
f010074b:	83 c8 40             	or     $0x40,%eax
f010074e:	0f b6 c0             	movzbl %al,%eax
f0100751:	f7 d0                	not    %eax
f0100753:	89 c2                	mov    %eax,%edx
f0100755:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f010075a:	21 d0                	and    %edx,%eax
f010075c:	a3 68 27 11 f0       	mov    %eax,0xf0112768
		return 0;
f0100761:	b8 00 00 00 00       	mov    $0x0,%eax
f0100766:	e9 d6 00 00 00       	jmp    f0100841 <kbd_proc_data+0x187>
	} else if (shift & E0ESC) {
f010076b:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f0100770:	83 e0 40             	and    $0x40,%eax
f0100773:	85 c0                	test   %eax,%eax
f0100775:	74 11                	je     f0100788 <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100777:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
		shift &= ~E0ESC;
f010077b:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f0100780:	83 e0 bf             	and    $0xffffffbf,%eax
f0100783:	a3 68 27 11 f0       	mov    %eax,0xf0112768
	}

	shift |= shiftcode[data];
f0100788:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f010078c:	0f b6 80 00 20 11 f0 	movzbl -0xfeee000(%eax),%eax
f0100793:	0f b6 d0             	movzbl %al,%edx
f0100796:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f010079b:	09 d0                	or     %edx,%eax
f010079d:	a3 68 27 11 f0       	mov    %eax,0xf0112768
	shift ^= togglecode[data];
f01007a2:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01007a6:	0f b6 80 00 21 11 f0 	movzbl -0xfeedf00(%eax),%eax
f01007ad:	0f b6 d0             	movzbl %al,%edx
f01007b0:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f01007b5:	31 d0                	xor    %edx,%eax
f01007b7:	a3 68 27 11 f0       	mov    %eax,0xf0112768

	c = charcode[shift & (CTL | SHIFT)][data];
f01007bc:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f01007c1:	83 e0 03             	and    $0x3,%eax
f01007c4:	8b 14 85 00 25 11 f0 	mov    -0xfeedb00(,%eax,4),%edx
f01007cb:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01007cf:	01 d0                	add    %edx,%eax
f01007d1:	0f b6 00             	movzbl (%eax),%eax
f01007d4:	0f b6 c0             	movzbl %al,%eax
f01007d7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (shift & CAPSLOCK) {
f01007da:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f01007df:	83 e0 08             	and    $0x8,%eax
f01007e2:	85 c0                	test   %eax,%eax
f01007e4:	74 22                	je     f0100808 <kbd_proc_data+0x14e>
		if ('a' <= c && c <= 'z')
f01007e6:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
f01007ea:	7e 0c                	jle    f01007f8 <kbd_proc_data+0x13e>
f01007ec:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
f01007f0:	7f 06                	jg     f01007f8 <kbd_proc_data+0x13e>
			c += 'A' - 'a';
f01007f2:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
f01007f6:	eb 10                	jmp    f0100808 <kbd_proc_data+0x14e>
		else if ('A' <= c && c <= 'Z')
f01007f8:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
f01007fc:	7e 0a                	jle    f0100808 <kbd_proc_data+0x14e>
f01007fe:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
f0100802:	7f 04                	jg     f0100808 <kbd_proc_data+0x14e>
			c += 'a' - 'A';
f0100804:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100808:	a1 68 27 11 f0       	mov    0xf0112768,%eax
f010080d:	f7 d0                	not    %eax
f010080f:	83 e0 06             	and    $0x6,%eax
f0100812:	85 c0                	test   %eax,%eax
f0100814:	75 28                	jne    f010083e <kbd_proc_data+0x184>
f0100816:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
f010081d:	75 1f                	jne    f010083e <kbd_proc_data+0x184>
		cprintf("Rebooting!\n");
f010081f:	c7 04 24 66 21 10 f0 	movl   $0xf0102166,(%esp)
f0100826:	e8 b4 04 00 00       	call   f0100cdf <cprintf>
f010082b:	c7 45 dc 92 00 00 00 	movl   $0x92,-0x24(%ebp)
f0100832:	c6 45 db 03          	movb   $0x3,-0x25(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100836:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
f010083a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010083d:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010083e:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0100841:	c9                   	leave  
f0100842:	c3                   	ret    

f0100843 <kbd_intr>:

void
kbd_intr(void)
{
f0100843:	55                   	push   %ebp
f0100844:	89 e5                	mov    %esp,%ebp
f0100846:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
f0100849:	c7 04 24 ba 06 10 f0 	movl   $0xf01006ba,(%esp)
f0100850:	e8 07 00 00 00       	call   f010085c <cons_intr>
}
f0100855:	c9                   	leave  
f0100856:	c3                   	ret    

f0100857 <kbd_init>:

static void
kbd_init(void)
{
f0100857:	55                   	push   %ebp
f0100858:	89 e5                	mov    %esp,%ebp
}
f010085a:	5d                   	pop    %ebp
f010085b:	c3                   	ret    

f010085c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010085c:	55                   	push   %ebp
f010085d:	89 e5                	mov    %esp,%ebp
f010085f:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = (*proc)()) != -1) {
f0100862:	eb 35                	jmp    f0100899 <cons_intr+0x3d>
		if (c == 0)
f0100864:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100868:	75 02                	jne    f010086c <cons_intr+0x10>
			continue;
f010086a:	eb 2d                	jmp    f0100899 <cons_intr+0x3d>
		cons.buf[cons.wpos++] = c;
f010086c:	a1 64 27 11 f0       	mov    0xf0112764,%eax
f0100871:	8d 50 01             	lea    0x1(%eax),%edx
f0100874:	89 15 64 27 11 f0    	mov    %edx,0xf0112764
f010087a:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010087d:	88 90 60 25 11 f0    	mov    %dl,-0xfeedaa0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f0100883:	a1 64 27 11 f0       	mov    0xf0112764,%eax
f0100888:	3d 00 02 00 00       	cmp    $0x200,%eax
f010088d:	75 0a                	jne    f0100899 <cons_intr+0x3d>
			cons.wpos = 0;
f010088f:	c7 05 64 27 11 f0 00 	movl   $0x0,0xf0112764
f0100896:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100899:	8b 45 08             	mov    0x8(%ebp),%eax
f010089c:	ff d0                	call   *%eax
f010089e:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01008a1:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
f01008a5:	75 bd                	jne    f0100864 <cons_intr+0x8>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01008a7:	c9                   	leave  
f01008a8:	c3                   	ret    

f01008a9 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01008a9:	55                   	push   %ebp
f01008aa:	89 e5                	mov    %esp,%ebp
f01008ac:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01008af:	e8 84 f9 ff ff       	call   f0100238 <serial_intr>
	kbd_intr();
f01008b4:	e8 8a ff ff ff       	call   f0100843 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01008b9:	8b 15 60 27 11 f0    	mov    0xf0112760,%edx
f01008bf:	a1 64 27 11 f0       	mov    0xf0112764,%eax
f01008c4:	39 c2                	cmp    %eax,%edx
f01008c6:	74 36                	je     f01008fe <cons_getc+0x55>
		c = cons.buf[cons.rpos++];
f01008c8:	a1 60 27 11 f0       	mov    0xf0112760,%eax
f01008cd:	8d 50 01             	lea    0x1(%eax),%edx
f01008d0:	89 15 60 27 11 f0    	mov    %edx,0xf0112760
f01008d6:	0f b6 80 60 25 11 f0 	movzbl -0xfeedaa0(%eax),%eax
f01008dd:	0f b6 c0             	movzbl %al,%eax
f01008e0:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if (cons.rpos == CONSBUFSIZE)
f01008e3:	a1 60 27 11 f0       	mov    0xf0112760,%eax
f01008e8:	3d 00 02 00 00       	cmp    $0x200,%eax
f01008ed:	75 0a                	jne    f01008f9 <cons_getc+0x50>
			cons.rpos = 0;
f01008ef:	c7 05 60 27 11 f0 00 	movl   $0x0,0xf0112760
f01008f6:	00 00 00 
		return c;
f01008f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01008fc:	eb 05                	jmp    f0100903 <cons_getc+0x5a>
	}
	return 0;
f01008fe:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100903:	c9                   	leave  
f0100904:	c3                   	ret    

f0100905 <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
f0100905:	55                   	push   %ebp
f0100906:	89 e5                	mov    %esp,%ebp
f0100908:	83 ec 18             	sub    $0x18,%esp
	serial_putc(c);
f010090b:	8b 45 08             	mov    0x8(%ebp),%eax
f010090e:	89 04 24             	mov    %eax,(%esp)
f0100911:	e8 41 f9 ff ff       	call   f0100257 <serial_putc>
	lpt_putc(c);
f0100916:	8b 45 08             	mov    0x8(%ebp),%eax
f0100919:	89 04 24             	mov    %eax,(%esp)
f010091c:	e8 42 fa ff ff       	call   f0100363 <lpt_putc>
	cga_putc(c);
f0100921:	8b 45 08             	mov    0x8(%ebp),%eax
f0100924:	89 04 24             	mov    %eax,(%esp)
f0100927:	e8 7c fb ff ff       	call   f01004a8 <cga_putc>
}
f010092c:	c9                   	leave  
f010092d:	c3                   	ret    

f010092e <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010092e:	55                   	push   %ebp
f010092f:	89 e5                	mov    %esp,%ebp
f0100931:	83 ec 18             	sub    $0x18,%esp
	cga_init();
f0100934:	e8 a3 fa ff ff       	call   f01003dc <cga_init>
	kbd_init();
f0100939:	e8 19 ff ff ff       	call   f0100857 <kbd_init>
	serial_init();
f010093e:	e8 55 f9 ff ff       	call   f0100298 <serial_init>

	if (!serial_exists)
f0100943:	0f b6 05 40 25 11 f0 	movzbl 0xf0112540,%eax
f010094a:	83 f0 01             	xor    $0x1,%eax
f010094d:	84 c0                	test   %al,%al
f010094f:	74 0c                	je     f010095d <cons_init+0x2f>
		cprintf("Serial port does not exist!\n");
f0100951:	c7 04 24 72 21 10 f0 	movl   $0xf0102172,(%esp)
f0100958:	e8 82 03 00 00       	call   f0100cdf <cprintf>
}
f010095d:	c9                   	leave  
f010095e:	c3                   	ret    

f010095f <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010095f:	55                   	push   %ebp
f0100960:	89 e5                	mov    %esp,%ebp
f0100962:	83 ec 18             	sub    $0x18,%esp
	cons_putc(c);
f0100965:	8b 45 08             	mov    0x8(%ebp),%eax
f0100968:	89 04 24             	mov    %eax,(%esp)
f010096b:	e8 95 ff ff ff       	call   f0100905 <cons_putc>
}
f0100970:	c9                   	leave  
f0100971:	c3                   	ret    

f0100972 <getchar>:

int
getchar(void)
{
f0100972:	55                   	push   %ebp
f0100973:	89 e5                	mov    %esp,%ebp
f0100975:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100978:	e8 2c ff ff ff       	call   f01008a9 <cons_getc>
f010097d:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100980:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100984:	74 f2                	je     f0100978 <getchar+0x6>
		/* do nothing */;
	return c;
f0100986:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0100989:	c9                   	leave  
f010098a:	c3                   	ret    

f010098b <iscons>:

int
iscons(int fdnum)
{
f010098b:	55                   	push   %ebp
f010098c:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
f010098e:	b8 01 00 00 00       	mov    $0x1,%eax
}
f0100993:	5d                   	pop    %ebp
f0100994:	c3                   	ret    

f0100995 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100995:	55                   	push   %ebp
f0100996:	89 e5                	mov    %esp,%ebp
f0100998:	83 ec 28             	sub    $0x28,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f010099b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f01009a2:	eb 3e                	jmp    f01009e2 <mon_help+0x4d>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01009a4:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01009a7:	89 d0                	mov    %edx,%eax
f01009a9:	01 c0                	add    %eax,%eax
f01009ab:	01 d0                	add    %edx,%eax
f01009ad:	c1 e0 02             	shl    $0x2,%eax
f01009b0:	05 14 25 11 f0       	add    $0xf0112514,%eax
f01009b5:	8b 08                	mov    (%eax),%ecx
f01009b7:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01009ba:	89 d0                	mov    %edx,%eax
f01009bc:	01 c0                	add    %eax,%eax
f01009be:	01 d0                	add    %edx,%eax
f01009c0:	c1 e0 02             	shl    $0x2,%eax
f01009c3:	05 10 25 11 f0       	add    $0xf0112510,%eax
f01009c8:	8b 00                	mov    (%eax),%eax
f01009ca:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01009ce:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009d2:	c7 04 24 e1 21 10 f0 	movl   $0xf01021e1,(%esp)
f01009d9:	e8 01 03 00 00       	call   f0100cdf <cprintf>
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f01009de:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
f01009e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009e5:	83 f8 01             	cmp    $0x1,%eax
f01009e8:	76 ba                	jbe    f01009a4 <mon_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
f01009ea:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01009ef:	c9                   	leave  
f01009f0:	c3                   	ret    

f01009f1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01009f1:	55                   	push   %ebp
f01009f2:	89 e5                	mov    %esp,%ebp
f01009f4:	83 ec 28             	sub    $0x28,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01009f7:	c7 04 24 ea 21 10 f0 	movl   $0xf01021ea,(%esp)
f01009fe:	e8 dc 02 00 00       	call   f0100cdf <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100a03:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100a0a:	00 
f0100a0b:	c7 04 24 04 22 10 f0 	movl   $0xf0102204,(%esp)
f0100a12:	e8 c8 02 00 00       	call   f0100cdf <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100a17:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100a1e:	00 
f0100a1f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100a26:	f0 
f0100a27:	c7 04 24 2c 22 10 f0 	movl   $0xf010222c,(%esp)
f0100a2e:	e8 ac 02 00 00       	call   f0100cdf <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100a33:	c7 44 24 08 c7 20 10 	movl   $0x1020c7,0x8(%esp)
f0100a3a:	00 
f0100a3b:	c7 44 24 04 c7 20 10 	movl   $0xf01020c7,0x4(%esp)
f0100a42:	f0 
f0100a43:	c7 04 24 50 22 10 f0 	movl   $0xf0102250,(%esp)
f0100a4a:	e8 90 02 00 00       	call   f0100cdf <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100a4f:	c7 44 24 08 28 25 11 	movl   $0x112528,0x8(%esp)
f0100a56:	00 
f0100a57:	c7 44 24 04 28 25 11 	movl   $0xf0112528,0x4(%esp)
f0100a5e:	f0 
f0100a5f:	c7 04 24 74 22 10 f0 	movl   $0xf0102274,(%esp)
f0100a66:	e8 74 02 00 00       	call   f0100cdf <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100a6b:	c7 44 24 08 84 2b 11 	movl   $0x112b84,0x8(%esp)
f0100a72:	00 
f0100a73:	c7 44 24 04 84 2b 11 	movl   $0xf0112b84,0x4(%esp)
f0100a7a:	f0 
f0100a7b:	c7 04 24 98 22 10 f0 	movl   $0xf0102298,(%esp)
f0100a82:	e8 58 02 00 00       	call   f0100cdf <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100a87:	c7 45 f4 00 04 00 00 	movl   $0x400,-0xc(%ebp)
f0100a8e:	b8 0c 00 10 f0       	mov    $0xf010000c,%eax
f0100a93:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100a96:	29 c2                	sub    %eax,%edx
f0100a98:	b8 84 2b 11 f0       	mov    $0xf0112b84,%eax
f0100a9d:	83 e8 01             	sub    $0x1,%eax
f0100aa0:	01 d0                	add    %edx,%eax
f0100aa2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100aa5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100aa8:	ba 00 00 00 00       	mov    $0x0,%edx
f0100aad:	f7 75 f4             	divl   -0xc(%ebp)
f0100ab0:	89 d0                	mov    %edx,%eax
f0100ab2:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100ab5:	29 c2                	sub    %eax,%edx
f0100ab7:	89 d0                	mov    %edx,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100ab9:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100abf:	85 c0                	test   %eax,%eax
f0100ac1:	0f 48 c2             	cmovs  %edx,%eax
f0100ac4:	c1 f8 0a             	sar    $0xa,%eax
f0100ac7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100acb:	c7 04 24 bc 22 10 f0 	movl   $0xf01022bc,(%esp)
f0100ad2:	e8 08 02 00 00       	call   f0100cdf <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
f0100ad7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100adc:	c9                   	leave  
f0100add:	c3                   	ret    

f0100ade <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100ade:	55                   	push   %ebp
f0100adf:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
f0100ae1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100ae6:	5d                   	pop    %ebp
f0100ae7:	c3                   	ret    

f0100ae8 <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f0100ae8:	55                   	push   %ebp
f0100ae9:	89 e5                	mov    %esp,%ebp
f0100aeb:	83 ec 68             	sub    $0x68,%esp
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100aee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	argv[argc] = 0;
f0100af5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100af8:	c7 44 85 b0 00 00 00 	movl   $0x0,-0x50(%ebp,%eax,4)
f0100aff:	00 
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100b00:	eb 0c                	jmp    f0100b0e <runcmd+0x26>
			*buf++ = 0;
f0100b02:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b05:	8d 50 01             	lea    0x1(%eax),%edx
f0100b08:	89 55 08             	mov    %edx,0x8(%ebp)
f0100b0b:	c6 00 00             	movb   $0x0,(%eax)
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100b0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b11:	0f b6 00             	movzbl (%eax),%eax
f0100b14:	84 c0                	test   %al,%al
f0100b16:	74 1d                	je     f0100b35 <runcmd+0x4d>
f0100b18:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b1b:	0f b6 00             	movzbl (%eax),%eax
f0100b1e:	0f be c0             	movsbl %al,%eax
f0100b21:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b25:	c7 04 24 e6 22 10 f0 	movl   $0xf01022e6,(%esp)
f0100b2c:	e8 58 0f 00 00       	call   f0101a89 <strchr>
f0100b31:	85 c0                	test   %eax,%eax
f0100b33:	75 cd                	jne    f0100b02 <runcmd+0x1a>
			*buf++ = 0;
		if (*buf == 0)
f0100b35:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b38:	0f b6 00             	movzbl (%eax),%eax
f0100b3b:	84 c0                	test   %al,%al
f0100b3d:	75 14                	jne    f0100b53 <runcmd+0x6b>
			break;
f0100b3f:	90                   	nop
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;
f0100b40:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b43:	c7 44 85 b0 00 00 00 	movl   $0x0,-0x50(%ebp,%eax,4)
f0100b4a:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100b4b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100b4f:	75 70                	jne    f0100bc1 <runcmd+0xd9>
f0100b51:	eb 67                	jmp    f0100bba <runcmd+0xd2>
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100b53:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
f0100b57:	75 1e                	jne    f0100b77 <runcmd+0x8f>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100b59:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100b60:	00 
f0100b61:	c7 04 24 eb 22 10 f0 	movl   $0xf01022eb,(%esp)
f0100b68:	e8 72 01 00 00       	call   f0100cdf <cprintf>
			return 0;
f0100b6d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b72:	e9 c8 00 00 00       	jmp    f0100c3f <runcmd+0x157>
		}
		argv[argc++] = buf;
f0100b77:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b7a:	8d 50 01             	lea    0x1(%eax),%edx
f0100b7d:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0100b80:	8b 55 08             	mov    0x8(%ebp),%edx
f0100b83:	89 54 85 b0          	mov    %edx,-0x50(%ebp,%eax,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100b87:	eb 04                	jmp    f0100b8d <runcmd+0xa5>
			buf++;
f0100b89:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100b8d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b90:	0f b6 00             	movzbl (%eax),%eax
f0100b93:	84 c0                	test   %al,%al
f0100b95:	74 1d                	je     f0100bb4 <runcmd+0xcc>
f0100b97:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b9a:	0f b6 00             	movzbl (%eax),%eax
f0100b9d:	0f be c0             	movsbl %al,%eax
f0100ba0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ba4:	c7 04 24 e6 22 10 f0 	movl   $0xf01022e6,(%esp)
f0100bab:	e8 d9 0e 00 00       	call   f0101a89 <strchr>
f0100bb0:	85 c0                	test   %eax,%eax
f0100bb2:	74 d5                	je     f0100b89 <runcmd+0xa1>
			buf++;
	}
f0100bb4:	90                   	nop
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100bb5:	e9 54 ff ff ff       	jmp    f0100b0e <runcmd+0x26>
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
f0100bba:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bbf:	eb 7e                	jmp    f0100c3f <runcmd+0x157>
	for (i = 0; i < NCOMMANDS; i++) {
f0100bc1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f0100bc8:	eb 55                	jmp    f0100c1f <runcmd+0x137>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100bca:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100bcd:	89 d0                	mov    %edx,%eax
f0100bcf:	01 c0                	add    %eax,%eax
f0100bd1:	01 d0                	add    %edx,%eax
f0100bd3:	c1 e0 02             	shl    $0x2,%eax
f0100bd6:	05 10 25 11 f0       	add    $0xf0112510,%eax
f0100bdb:	8b 10                	mov    (%eax),%edx
f0100bdd:	8b 45 b0             	mov    -0x50(%ebp),%eax
f0100be0:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100be4:	89 04 24             	mov    %eax,(%esp)
f0100be7:	e8 08 0e 00 00       	call   f01019f4 <strcmp>
f0100bec:	85 c0                	test   %eax,%eax
f0100bee:	75 2b                	jne    f0100c1b <runcmd+0x133>
			return commands[i].func(argc, argv, tf);
f0100bf0:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100bf3:	89 d0                	mov    %edx,%eax
f0100bf5:	01 c0                	add    %eax,%eax
f0100bf7:	01 d0                	add    %edx,%eax
f0100bf9:	c1 e0 02             	shl    $0x2,%eax
f0100bfc:	05 18 25 11 f0       	add    $0xf0112518,%eax
f0100c01:	8b 00                	mov    (%eax),%eax
f0100c03:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c06:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100c0a:	8d 55 b0             	lea    -0x50(%ebp),%edx
f0100c0d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c11:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100c14:	89 14 24             	mov    %edx,(%esp)
f0100c17:	ff d0                	call   *%eax
f0100c19:	eb 24                	jmp    f0100c3f <runcmd+0x157>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100c1b:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
f0100c1f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100c22:	83 f8 01             	cmp    $0x1,%eax
f0100c25:	76 a3                	jbe    f0100bca <runcmd+0xe2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100c27:	8b 45 b0             	mov    -0x50(%ebp),%eax
f0100c2a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c2e:	c7 04 24 08 23 10 f0 	movl   $0xf0102308,(%esp)
f0100c35:	e8 a5 00 00 00       	call   f0100cdf <cprintf>
	return 0;
f0100c3a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c3f:	c9                   	leave  
f0100c40:	c3                   	ret    

f0100c41 <monitor>:

void
monitor(struct Trapframe *tf)
{
f0100c41:	55                   	push   %ebp
f0100c42:	89 e5                	mov    %esp,%ebp
f0100c44:	83 ec 28             	sub    $0x28,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100c47:	c7 04 24 20 23 10 f0 	movl   $0xf0102320,(%esp)
f0100c4e:	e8 8c 00 00 00       	call   f0100cdf <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100c53:	c7 04 24 44 23 10 f0 	movl   $0xf0102344,(%esp)
f0100c5a:	e8 80 00 00 00       	call   f0100cdf <cprintf>


	while (1) {
		buf = readline("K> ");
f0100c5f:	c7 04 24 69 23 10 f0 	movl   $0xf0102369,(%esp)
f0100c66:	e8 48 0b 00 00       	call   f01017b3 <readline>
f0100c6b:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if (buf != NULL)
f0100c6e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100c72:	74 18                	je     f0100c8c <monitor+0x4b>
			if (runcmd(buf, tf) < 0)
f0100c74:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c77:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100c7e:	89 04 24             	mov    %eax,(%esp)
f0100c81:	e8 62 fe ff ff       	call   f0100ae8 <runcmd>
f0100c86:	85 c0                	test   %eax,%eax
f0100c88:	79 02                	jns    f0100c8c <monitor+0x4b>
				break;
f0100c8a:	eb 02                	jmp    f0100c8e <monitor+0x4d>
	}
f0100c8c:	eb d1                	jmp    f0100c5f <monitor+0x1e>
}
f0100c8e:	c9                   	leave  
f0100c8f:	c3                   	ret    

f0100c90 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100c90:	55                   	push   %ebp
f0100c91:	89 e5                	mov    %esp,%ebp
f0100c93:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100c96:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c99:	89 04 24             	mov    %eax,(%esp)
f0100c9c:	e8 be fc ff ff       	call   f010095f <cputchar>
	*cnt++;
f0100ca1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ca4:	83 c0 04             	add    $0x4,%eax
f0100ca7:	89 45 0c             	mov    %eax,0xc(%ebp)
}
f0100caa:	c9                   	leave  
f0100cab:	c3                   	ret    

f0100cac <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100cac:	55                   	push   %ebp
f0100cad:	89 e5                	mov    %esp,%ebp
f0100caf:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100cb2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100cb9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100cbc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cc0:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cc3:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cc7:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100cca:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cce:	c7 04 24 90 0c 10 f0 	movl   $0xf0100c90,(%esp)
f0100cd5:	e8 df 05 00 00       	call   f01012b9 <vprintfmt>
	return cnt;
f0100cda:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0100cdd:	c9                   	leave  
f0100cde:	c3                   	ret    

f0100cdf <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100cdf:	55                   	push   %ebp
f0100ce0:	89 e5                	mov    %esp,%ebp
f0100ce2:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100ce5:	8d 45 0c             	lea    0xc(%ebp),%eax
f0100ce8:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
f0100ceb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100cee:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cf2:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cf5:	89 04 24             	mov    %eax,(%esp)
f0100cf8:	e8 af ff ff ff       	call   f0100cac <vcprintf>
f0100cfd:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
f0100d00:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0100d03:	c9                   	leave  
f0100d04:	c3                   	ret    

f0100d05 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100d05:	55                   	push   %ebp
f0100d06:	89 e5                	mov    %esp,%ebp
f0100d08:	83 ec 20             	sub    $0x20,%esp
	int l = *region_left, r = *region_right, any_matches = 0;
f0100d0b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d0e:	8b 00                	mov    (%eax),%eax
f0100d10:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0100d13:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d16:	8b 00                	mov    (%eax),%eax
f0100d18:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0100d1b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	while (l <= r) {
f0100d22:	e9 d2 00 00 00       	jmp    f0100df9 <stab_binsearch+0xf4>
		int true_m = (l + r) / 2, m = true_m;
f0100d27:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100d2a:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100d2d:	01 d0                	add    %edx,%eax
f0100d2f:	89 c2                	mov    %eax,%edx
f0100d31:	c1 ea 1f             	shr    $0x1f,%edx
f0100d34:	01 d0                	add    %edx,%eax
f0100d36:	d1 f8                	sar    %eax
f0100d38:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100d3b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100d3e:	89 45 f0             	mov    %eax,-0x10(%ebp)

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100d41:	eb 04                	jmp    f0100d47 <stab_binsearch+0x42>
			m--;
f0100d43:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100d47:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100d4a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0100d4d:	7c 1f                	jl     f0100d6e <stab_binsearch+0x69>
f0100d4f:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100d52:	89 d0                	mov    %edx,%eax
f0100d54:	01 c0                	add    %eax,%eax
f0100d56:	01 d0                	add    %edx,%eax
f0100d58:	c1 e0 02             	shl    $0x2,%eax
f0100d5b:	89 c2                	mov    %eax,%edx
f0100d5d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d60:	01 d0                	add    %edx,%eax
f0100d62:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f0100d66:	0f b6 c0             	movzbl %al,%eax
f0100d69:	3b 45 14             	cmp    0x14(%ebp),%eax
f0100d6c:	75 d5                	jne    f0100d43 <stab_binsearch+0x3e>
			m--;
		if (m < l) {	// no match in [l, m]
f0100d6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100d71:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0100d74:	7d 0b                	jge    f0100d81 <stab_binsearch+0x7c>
			l = true_m + 1;
f0100d76:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100d79:	83 c0 01             	add    $0x1,%eax
f0100d7c:	89 45 fc             	mov    %eax,-0x4(%ebp)
			continue;
f0100d7f:	eb 78                	jmp    f0100df9 <stab_binsearch+0xf4>
		}

		// actual binary search
		any_matches = 1;
f0100d81:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
		if (stabs[m].n_value < addr) {
f0100d88:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100d8b:	89 d0                	mov    %edx,%eax
f0100d8d:	01 c0                	add    %eax,%eax
f0100d8f:	01 d0                	add    %edx,%eax
f0100d91:	c1 e0 02             	shl    $0x2,%eax
f0100d94:	89 c2                	mov    %eax,%edx
f0100d96:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d99:	01 d0                	add    %edx,%eax
f0100d9b:	8b 40 08             	mov    0x8(%eax),%eax
f0100d9e:	3b 45 18             	cmp    0x18(%ebp),%eax
f0100da1:	73 13                	jae    f0100db6 <stab_binsearch+0xb1>
			*region_left = m;
f0100da3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100da6:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100da9:	89 10                	mov    %edx,(%eax)
			l = true_m + 1;
f0100dab:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100dae:	83 c0 01             	add    $0x1,%eax
f0100db1:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0100db4:	eb 43                	jmp    f0100df9 <stab_binsearch+0xf4>
		} else if (stabs[m].n_value > addr) {
f0100db6:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100db9:	89 d0                	mov    %edx,%eax
f0100dbb:	01 c0                	add    %eax,%eax
f0100dbd:	01 d0                	add    %edx,%eax
f0100dbf:	c1 e0 02             	shl    $0x2,%eax
f0100dc2:	89 c2                	mov    %eax,%edx
f0100dc4:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dc7:	01 d0                	add    %edx,%eax
f0100dc9:	8b 40 08             	mov    0x8(%eax),%eax
f0100dcc:	3b 45 18             	cmp    0x18(%ebp),%eax
f0100dcf:	76 16                	jbe    f0100de7 <stab_binsearch+0xe2>
			*region_right = m - 1;
f0100dd1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100dd4:	8d 50 ff             	lea    -0x1(%eax),%edx
f0100dd7:	8b 45 10             	mov    0x10(%ebp),%eax
f0100dda:	89 10                	mov    %edx,(%eax)
			r = m - 1;
f0100ddc:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ddf:	83 e8 01             	sub    $0x1,%eax
f0100de2:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0100de5:	eb 12                	jmp    f0100df9 <stab_binsearch+0xf4>
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100de7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100dea:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100ded:	89 10                	mov    %edx,(%eax)
			l = m;
f0100def:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100df2:	89 45 fc             	mov    %eax,-0x4(%ebp)
			addr++;
f0100df5:	83 45 18 01          	addl   $0x1,0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100df9:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100dfc:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f0100dff:	0f 8e 22 ff ff ff    	jle    f0100d27 <stab_binsearch+0x22>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100e05:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100e09:	75 0f                	jne    f0100e1a <stab_binsearch+0x115>
		*region_right = *region_left - 1;
f0100e0b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e0e:	8b 00                	mov    (%eax),%eax
f0100e10:	8d 50 ff             	lea    -0x1(%eax),%edx
f0100e13:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e16:	89 10                	mov    %edx,(%eax)
f0100e18:	eb 3f                	jmp    f0100e59 <stab_binsearch+0x154>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100e1a:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e1d:	8b 00                	mov    (%eax),%eax
f0100e1f:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0100e22:	eb 04                	jmp    f0100e28 <stab_binsearch+0x123>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100e24:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100e28:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e2b:	8b 00                	mov    (%eax),%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100e2d:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0100e30:	7d 1f                	jge    f0100e51 <stab_binsearch+0x14c>
		     l > *region_left && stabs[l].n_type != type;
f0100e32:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100e35:	89 d0                	mov    %edx,%eax
f0100e37:	01 c0                	add    %eax,%eax
f0100e39:	01 d0                	add    %edx,%eax
f0100e3b:	c1 e0 02             	shl    $0x2,%eax
f0100e3e:	89 c2                	mov    %eax,%edx
f0100e40:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e43:	01 d0                	add    %edx,%eax
f0100e45:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f0100e49:	0f b6 c0             	movzbl %al,%eax
f0100e4c:	3b 45 14             	cmp    0x14(%ebp),%eax
f0100e4f:	75 d3                	jne    f0100e24 <stab_binsearch+0x11f>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100e51:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e54:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100e57:	89 10                	mov    %edx,(%eax)
	}
}
f0100e59:	c9                   	leave  
f0100e5a:	c3                   	ret    

f0100e5b <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100e5b:	55                   	push   %ebp
f0100e5c:	89 e5                	mov    %esp,%ebp
f0100e5e:	83 ec 58             	sub    $0x58,%esp
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100e61:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e64:	c7 00 6d 23 10 f0    	movl   $0xf010236d,(%eax)
	info->eip_line = 0;
f0100e6a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e6d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	info->eip_fn_name = "<unknown>";
f0100e74:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e77:	c7 40 08 6d 23 10 f0 	movl   $0xf010236d,0x8(%eax)
	info->eip_fn_namelen = 9;
f0100e7e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e81:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
	info->eip_fn_addr = addr;
f0100e88:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e8b:	8b 55 08             	mov    0x8(%ebp),%edx
f0100e8e:	89 50 10             	mov    %edx,0x10(%eax)
	info->eip_fn_narg = 0;
f0100e91:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e94:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100e9b:	81 7d 08 ff ff 7f ef 	cmpl   $0xef7fffff,0x8(%ebp)
f0100ea2:	76 26                	jbe    f0100eca <debuginfo_eip+0x6f>
		stabs = __STAB_BEGIN__;
f0100ea4:	c7 45 f0 d0 25 10 f0 	movl   $0xf01025d0,-0x10(%ebp)
		stab_end = __STAB_END__;
f0100eab:	c7 45 ec e4 65 10 f0 	movl   $0xf01065e4,-0x14(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0100eb2:	c7 45 e8 e5 65 10 f0 	movl   $0xf01065e5,-0x18(%ebp)
		stabstr_end = __STABSTR_END__;
f0100eb9:	c7 45 e4 48 7f 10 f0 	movl   $0xf0107f48,-0x1c(%ebp)
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ec0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ec3:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f0100ec6:	76 2b                	jbe    f0100ef3 <debuginfo_eip+0x98>
f0100ec8:	eb 1c                	jmp    f0100ee6 <debuginfo_eip+0x8b>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100eca:	c7 44 24 08 77 23 10 	movl   $0xf0102377,0x8(%esp)
f0100ed1:	f0 
f0100ed2:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100ed9:	00 
f0100eda:	c7 04 24 84 23 10 f0 	movl   $0xf0102384,(%esp)
f0100ee1:	e8 19 f2 ff ff       	call   f01000ff <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ee6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ee9:	83 e8 01             	sub    $0x1,%eax
f0100eec:	0f b6 00             	movzbl (%eax),%eax
f0100eef:	84 c0                	test   %al,%al
f0100ef1:	74 0a                	je     f0100efd <debuginfo_eip+0xa2>
		return -1;
f0100ef3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ef8:	e9 46 02 00 00       	jmp    f0101143 <debuginfo_eip+0x2e8>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100efd:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100f04:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0100f07:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f0a:	29 c2                	sub    %eax,%edx
f0100f0c:	89 d0                	mov    %edx,%eax
f0100f0e:	c1 f8 02             	sar    $0x2,%eax
f0100f11:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100f17:	83 e8 01             	sub    $0x1,%eax
f0100f1a:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100f1d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f20:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100f24:	c7 44 24 0c 64 00 00 	movl   $0x64,0xc(%esp)
f0100f2b:	00 
f0100f2c:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0100f2f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f33:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0100f36:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f3d:	89 04 24             	mov    %eax,(%esp)
f0100f40:	e8 c0 fd ff ff       	call   f0100d05 <stab_binsearch>
	if (lfile == 0)
f0100f45:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100f48:	85 c0                	test   %eax,%eax
f0100f4a:	75 0a                	jne    f0100f56 <debuginfo_eip+0xfb>
		return -1;
f0100f4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100f51:	e9 ed 01 00 00       	jmp    f0101143 <debuginfo_eip+0x2e8>

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100f56:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100f59:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	rfun = rfile;
f0100f5c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f5f:	89 45 d0             	mov    %eax,-0x30(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100f62:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f65:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100f69:	c7 44 24 0c 24 00 00 	movl   $0x24,0xc(%esp)
f0100f70:	00 
f0100f71:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100f74:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f78:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0100f7b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f82:	89 04 24             	mov    %eax,(%esp)
f0100f85:	e8 7b fd ff ff       	call   f0100d05 <stab_binsearch>

	if (lfun <= rfun) {
f0100f8a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100f8d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f90:	39 c2                	cmp    %eax,%edx
f0100f92:	7f 7c                	jg     f0101010 <debuginfo_eip+0x1b5>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100f94:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f97:	89 c2                	mov    %eax,%edx
f0100f99:	89 d0                	mov    %edx,%eax
f0100f9b:	01 c0                	add    %eax,%eax
f0100f9d:	01 d0                	add    %edx,%eax
f0100f9f:	c1 e0 02             	shl    $0x2,%eax
f0100fa2:	89 c2                	mov    %eax,%edx
f0100fa4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100fa7:	01 d0                	add    %edx,%eax
f0100fa9:	8b 10                	mov    (%eax),%edx
f0100fab:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100fae:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100fb1:	29 c1                	sub    %eax,%ecx
f0100fb3:	89 c8                	mov    %ecx,%eax
f0100fb5:	39 c2                	cmp    %eax,%edx
f0100fb7:	73 22                	jae    f0100fdb <debuginfo_eip+0x180>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100fb9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100fbc:	89 c2                	mov    %eax,%edx
f0100fbe:	89 d0                	mov    %edx,%eax
f0100fc0:	01 c0                	add    %eax,%eax
f0100fc2:	01 d0                	add    %edx,%eax
f0100fc4:	c1 e0 02             	shl    $0x2,%eax
f0100fc7:	89 c2                	mov    %eax,%edx
f0100fc9:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100fcc:	01 d0                	add    %edx,%eax
f0100fce:	8b 10                	mov    (%eax),%edx
f0100fd0:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100fd3:	01 c2                	add    %eax,%edx
f0100fd5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fd8:	89 50 08             	mov    %edx,0x8(%eax)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100fdb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100fde:	89 c2                	mov    %eax,%edx
f0100fe0:	89 d0                	mov    %edx,%eax
f0100fe2:	01 c0                	add    %eax,%eax
f0100fe4:	01 d0                	add    %edx,%eax
f0100fe6:	c1 e0 02             	shl    $0x2,%eax
f0100fe9:	89 c2                	mov    %eax,%edx
f0100feb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100fee:	01 d0                	add    %edx,%eax
f0100ff0:	8b 50 08             	mov    0x8(%eax),%edx
f0100ff3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ff6:	89 50 10             	mov    %edx,0x10(%eax)
		addr -= info->eip_fn_addr;
f0100ff9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ffc:	8b 40 10             	mov    0x10(%eax),%eax
f0100fff:	29 45 08             	sub    %eax,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f0101002:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101005:	89 45 f4             	mov    %eax,-0xc(%ebp)
		rline = rfun;
f0101008:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010100b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010100e:	eb 15                	jmp    f0101025 <debuginfo_eip+0x1ca>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0101010:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101013:	8b 55 08             	mov    0x8(%ebp),%edx
f0101016:	89 50 10             	mov    %edx,0x10(%eax)
		lline = lfile;
f0101019:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010101c:	89 45 f4             	mov    %eax,-0xc(%ebp)
		rline = rfile;
f010101f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101022:	89 45 e0             	mov    %eax,-0x20(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101025:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101028:	8b 40 08             	mov    0x8(%eax),%eax
f010102b:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0101032:	00 
f0101033:	89 04 24             	mov    %eax,(%esp)
f0101036:	e8 81 0a 00 00       	call   f0101abc <strfind>
f010103b:	89 c2                	mov    %eax,%edx
f010103d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101040:	8b 40 08             	mov    0x8(%eax),%eax
f0101043:	29 c2                	sub    %eax,%edx
f0101045:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101048:	89 50 0c             	mov    %edx,0xc(%eax)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010104b:	eb 04                	jmp    f0101051 <debuginfo_eip+0x1f6>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010104d:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101051:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101054:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f0101057:	7c 50                	jl     f01010a9 <debuginfo_eip+0x24e>
	       && stabs[lline].n_type != N_SOL
f0101059:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010105c:	89 d0                	mov    %edx,%eax
f010105e:	01 c0                	add    %eax,%eax
f0101060:	01 d0                	add    %edx,%eax
f0101062:	c1 e0 02             	shl    $0x2,%eax
f0101065:	89 c2                	mov    %eax,%edx
f0101067:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010106a:	01 d0                	add    %edx,%eax
f010106c:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f0101070:	3c 84                	cmp    $0x84,%al
f0101072:	74 35                	je     f01010a9 <debuginfo_eip+0x24e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101074:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101077:	89 d0                	mov    %edx,%eax
f0101079:	01 c0                	add    %eax,%eax
f010107b:	01 d0                	add    %edx,%eax
f010107d:	c1 e0 02             	shl    $0x2,%eax
f0101080:	89 c2                	mov    %eax,%edx
f0101082:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101085:	01 d0                	add    %edx,%eax
f0101087:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f010108b:	3c 64                	cmp    $0x64,%al
f010108d:	75 be                	jne    f010104d <debuginfo_eip+0x1f2>
f010108f:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101092:	89 d0                	mov    %edx,%eax
f0101094:	01 c0                	add    %eax,%eax
f0101096:	01 d0                	add    %edx,%eax
f0101098:	c1 e0 02             	shl    $0x2,%eax
f010109b:	89 c2                	mov    %eax,%edx
f010109d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01010a0:	01 d0                	add    %edx,%eax
f01010a2:	8b 40 08             	mov    0x8(%eax),%eax
f01010a5:	85 c0                	test   %eax,%eax
f01010a7:	74 a4                	je     f010104d <debuginfo_eip+0x1f2>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01010a9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010ac:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f01010af:	7c 42                	jl     f01010f3 <debuginfo_eip+0x298>
f01010b1:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01010b4:	89 d0                	mov    %edx,%eax
f01010b6:	01 c0                	add    %eax,%eax
f01010b8:	01 d0                	add    %edx,%eax
f01010ba:	c1 e0 02             	shl    $0x2,%eax
f01010bd:	89 c2                	mov    %eax,%edx
f01010bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01010c2:	01 d0                	add    %edx,%eax
f01010c4:	8b 10                	mov    (%eax),%edx
f01010c6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01010c9:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01010cc:	29 c1                	sub    %eax,%ecx
f01010ce:	89 c8                	mov    %ecx,%eax
f01010d0:	39 c2                	cmp    %eax,%edx
f01010d2:	73 1f                	jae    f01010f3 <debuginfo_eip+0x298>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01010d4:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01010d7:	89 d0                	mov    %edx,%eax
f01010d9:	01 c0                	add    %eax,%eax
f01010db:	01 d0                	add    %edx,%eax
f01010dd:	c1 e0 02             	shl    $0x2,%eax
f01010e0:	89 c2                	mov    %eax,%edx
f01010e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01010e5:	01 d0                	add    %edx,%eax
f01010e7:	8b 10                	mov    (%eax),%edx
f01010e9:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01010ec:	01 c2                	add    %eax,%edx
f01010ee:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010f1:	89 10                	mov    %edx,(%eax)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01010f3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01010f6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01010f9:	39 c2                	cmp    %eax,%edx
f01010fb:	7d 41                	jge    f010113e <debuginfo_eip+0x2e3>
		for (lline = lfun + 1;
f01010fd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101100:	83 c0 01             	add    $0x1,%eax
f0101103:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101106:	eb 13                	jmp    f010111b <debuginfo_eip+0x2c0>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0101108:	8b 45 0c             	mov    0xc(%ebp),%eax
f010110b:	8b 40 14             	mov    0x14(%eax),%eax
f010110e:	8d 50 01             	lea    0x1(%eax),%edx
f0101111:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101114:	89 50 14             	mov    %edx,0x14(%eax)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0101117:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010111b:	8b 45 d0             	mov    -0x30(%ebp),%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010111e:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f0101121:	7d 1b                	jge    f010113e <debuginfo_eip+0x2e3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101123:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101126:	89 d0                	mov    %edx,%eax
f0101128:	01 c0                	add    %eax,%eax
f010112a:	01 d0                	add    %edx,%eax
f010112c:	c1 e0 02             	shl    $0x2,%eax
f010112f:	89 c2                	mov    %eax,%edx
f0101131:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101134:	01 d0                	add    %edx,%eax
f0101136:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f010113a:	3c a0                	cmp    $0xa0,%al
f010113c:	74 ca                	je     f0101108 <debuginfo_eip+0x2ad>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010113e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101143:	c9                   	leave  
f0101144:	c3                   	ret    

f0101145 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101145:	55                   	push   %ebp
f0101146:	89 e5                	mov    %esp,%ebp
f0101148:	53                   	push   %ebx
f0101149:	83 ec 34             	sub    $0x34,%esp
f010114c:	8b 45 10             	mov    0x10(%ebp),%eax
f010114f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101152:	8b 45 14             	mov    0x14(%ebp),%eax
f0101155:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101158:	8b 45 18             	mov    0x18(%ebp),%eax
f010115b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101160:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f0101163:	77 72                	ja     f01011d7 <printnum+0x92>
f0101165:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f0101168:	72 05                	jb     f010116f <printnum+0x2a>
f010116a:	3b 45 f0             	cmp    -0x10(%ebp),%eax
f010116d:	77 68                	ja     f01011d7 <printnum+0x92>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010116f:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0101172:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0101175:	8b 45 18             	mov    0x18(%ebp),%eax
f0101178:	ba 00 00 00 00       	mov    $0x0,%edx
f010117d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101181:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101185:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101188:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010118b:	89 04 24             	mov    %eax,(%esp)
f010118e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101192:	e8 a9 0c 00 00       	call   f0101e40 <__udivdi3>
f0101197:	8b 4d 20             	mov    0x20(%ebp),%ecx
f010119a:	89 4c 24 18          	mov    %ecx,0x18(%esp)
f010119e:	89 5c 24 14          	mov    %ebx,0x14(%esp)
f01011a2:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01011a5:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01011a9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011ad:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01011b1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01011bb:	89 04 24             	mov    %eax,(%esp)
f01011be:	e8 82 ff ff ff       	call   f0101145 <printnum>
f01011c3:	eb 1c                	jmp    f01011e1 <printnum+0x9c>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01011c5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011cc:	8b 45 20             	mov    0x20(%ebp),%eax
f01011cf:	89 04 24             	mov    %eax,(%esp)
f01011d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01011d5:	ff d0                	call   *%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01011d7:	83 6d 1c 01          	subl   $0x1,0x1c(%ebp)
f01011db:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
f01011df:	7f e4                	jg     f01011c5 <printnum+0x80>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01011e1:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01011e4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01011ec:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01011ef:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01011f3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01011f7:	89 04 24             	mov    %eax,(%esp)
f01011fa:	89 54 24 04          	mov    %edx,0x4(%esp)
f01011fe:	e8 6d 0d 00 00       	call   f0101f70 <__umoddi3>
f0101203:	05 40 24 10 f0       	add    $0xf0102440,%eax
f0101208:	0f b6 00             	movzbl (%eax),%eax
f010120b:	0f be c0             	movsbl %al,%eax
f010120e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101211:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101215:	89 04 24             	mov    %eax,(%esp)
f0101218:	8b 45 08             	mov    0x8(%ebp),%eax
f010121b:	ff d0                	call   *%eax
}
f010121d:	83 c4 34             	add    $0x34,%esp
f0101220:	5b                   	pop    %ebx
f0101221:	5d                   	pop    %ebp
f0101222:	c3                   	ret    

f0101223 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0101223:	55                   	push   %ebp
f0101224:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101226:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f010122a:	7e 14                	jle    f0101240 <getuint+0x1d>
		return va_arg(*ap, unsigned long long);
f010122c:	8b 45 08             	mov    0x8(%ebp),%eax
f010122f:	8b 00                	mov    (%eax),%eax
f0101231:	8d 48 08             	lea    0x8(%eax),%ecx
f0101234:	8b 55 08             	mov    0x8(%ebp),%edx
f0101237:	89 0a                	mov    %ecx,(%edx)
f0101239:	8b 50 04             	mov    0x4(%eax),%edx
f010123c:	8b 00                	mov    (%eax),%eax
f010123e:	eb 30                	jmp    f0101270 <getuint+0x4d>
	else if (lflag)
f0101240:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101244:	74 16                	je     f010125c <getuint+0x39>
		return va_arg(*ap, unsigned long);
f0101246:	8b 45 08             	mov    0x8(%ebp),%eax
f0101249:	8b 00                	mov    (%eax),%eax
f010124b:	8d 48 04             	lea    0x4(%eax),%ecx
f010124e:	8b 55 08             	mov    0x8(%ebp),%edx
f0101251:	89 0a                	mov    %ecx,(%edx)
f0101253:	8b 00                	mov    (%eax),%eax
f0101255:	ba 00 00 00 00       	mov    $0x0,%edx
f010125a:	eb 14                	jmp    f0101270 <getuint+0x4d>
	else
		return va_arg(*ap, unsigned int);
f010125c:	8b 45 08             	mov    0x8(%ebp),%eax
f010125f:	8b 00                	mov    (%eax),%eax
f0101261:	8d 48 04             	lea    0x4(%eax),%ecx
f0101264:	8b 55 08             	mov    0x8(%ebp),%edx
f0101267:	89 0a                	mov    %ecx,(%edx)
f0101269:	8b 00                	mov    (%eax),%eax
f010126b:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0101270:	5d                   	pop    %ebp
f0101271:	c3                   	ret    

f0101272 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0101272:	55                   	push   %ebp
f0101273:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101275:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f0101279:	7e 14                	jle    f010128f <getint+0x1d>
		return va_arg(*ap, long long);
f010127b:	8b 45 08             	mov    0x8(%ebp),%eax
f010127e:	8b 00                	mov    (%eax),%eax
f0101280:	8d 48 08             	lea    0x8(%eax),%ecx
f0101283:	8b 55 08             	mov    0x8(%ebp),%edx
f0101286:	89 0a                	mov    %ecx,(%edx)
f0101288:	8b 50 04             	mov    0x4(%eax),%edx
f010128b:	8b 00                	mov    (%eax),%eax
f010128d:	eb 28                	jmp    f01012b7 <getint+0x45>
	else if (lflag)
f010128f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101293:	74 12                	je     f01012a7 <getint+0x35>
		return va_arg(*ap, long);
f0101295:	8b 45 08             	mov    0x8(%ebp),%eax
f0101298:	8b 00                	mov    (%eax),%eax
f010129a:	8d 48 04             	lea    0x4(%eax),%ecx
f010129d:	8b 55 08             	mov    0x8(%ebp),%edx
f01012a0:	89 0a                	mov    %ecx,(%edx)
f01012a2:	8b 00                	mov    (%eax),%eax
f01012a4:	99                   	cltd   
f01012a5:	eb 10                	jmp    f01012b7 <getint+0x45>
	else
		return va_arg(*ap, int);
f01012a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01012aa:	8b 00                	mov    (%eax),%eax
f01012ac:	8d 48 04             	lea    0x4(%eax),%ecx
f01012af:	8b 55 08             	mov    0x8(%ebp),%edx
f01012b2:	89 0a                	mov    %ecx,(%edx)
f01012b4:	8b 00                	mov    (%eax),%eax
f01012b6:	99                   	cltd   
}
f01012b7:	5d                   	pop    %ebp
f01012b8:	c3                   	ret    

f01012b9 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01012b9:	55                   	push   %ebp
f01012ba:	89 e5                	mov    %esp,%ebp
f01012bc:	56                   	push   %esi
f01012bd:	53                   	push   %ebx
f01012be:	83 ec 40             	sub    $0x40,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01012c1:	eb 18                	jmp    f01012db <vprintfmt+0x22>
			if (ch == '\0')
f01012c3:	85 db                	test   %ebx,%ebx
f01012c5:	75 05                	jne    f01012cc <vprintfmt+0x13>
				return;
f01012c7:	e9 e9 03 00 00       	jmp    f01016b5 <vprintfmt+0x3fc>
			putch(ch, putdat);
f01012cc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012cf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012d3:	89 1c 24             	mov    %ebx,(%esp)
f01012d6:	8b 45 08             	mov    0x8(%ebp),%eax
f01012d9:	ff d0                	call   *%eax
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01012db:	8b 45 10             	mov    0x10(%ebp),%eax
f01012de:	8d 50 01             	lea    0x1(%eax),%edx
f01012e1:	89 55 10             	mov    %edx,0x10(%ebp)
f01012e4:	0f b6 00             	movzbl (%eax),%eax
f01012e7:	0f b6 d8             	movzbl %al,%ebx
f01012ea:	83 fb 25             	cmp    $0x25,%ebx
f01012ed:	75 d4                	jne    f01012c3 <vprintfmt+0xa>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		padc = ' ';
f01012ef:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
		width = -1;
f01012f3:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
		precision = -1;
f01012fa:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0101301:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
		altflag = 0;
f0101308:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010130f:	8b 45 10             	mov    0x10(%ebp),%eax
f0101312:	8d 50 01             	lea    0x1(%eax),%edx
f0101315:	89 55 10             	mov    %edx,0x10(%ebp)
f0101318:	0f b6 00             	movzbl (%eax),%eax
f010131b:	0f b6 d8             	movzbl %al,%ebx
f010131e:	8d 43 dd             	lea    -0x23(%ebx),%eax
f0101321:	83 f8 55             	cmp    $0x55,%eax
f0101324:	0f 87 5a 03 00 00    	ja     f0101684 <vprintfmt+0x3cb>
f010132a:	8b 04 85 64 24 10 f0 	mov    -0xfefdb9c(,%eax,4),%eax
f0101331:	ff e0                	jmp    *%eax

		// flag to pad on the right
		case '-':
			padc = '-';
f0101333:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
			goto reswitch;
f0101337:	eb d6                	jmp    f010130f <vprintfmt+0x56>

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101339:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
			goto reswitch;
f010133d:	eb d0                	jmp    f010130f <vprintfmt+0x56>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010133f:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
				precision = precision * 10 + ch - '0';
f0101346:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101349:	89 d0                	mov    %edx,%eax
f010134b:	c1 e0 02             	shl    $0x2,%eax
f010134e:	01 d0                	add    %edx,%eax
f0101350:	01 c0                	add    %eax,%eax
f0101352:	01 d8                	add    %ebx,%eax
f0101354:	83 e8 30             	sub    $0x30,%eax
f0101357:	89 45 e0             	mov    %eax,-0x20(%ebp)
				ch = *fmt;
f010135a:	8b 45 10             	mov    0x10(%ebp),%eax
f010135d:	0f b6 00             	movzbl (%eax),%eax
f0101360:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
f0101363:	83 fb 2f             	cmp    $0x2f,%ebx
f0101366:	7e 0b                	jle    f0101373 <vprintfmt+0xba>
f0101368:	83 fb 39             	cmp    $0x39,%ebx
f010136b:	7f 06                	jg     f0101373 <vprintfmt+0xba>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010136d:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0101371:	eb d3                	jmp    f0101346 <vprintfmt+0x8d>
			goto process_precision;
f0101373:	eb 33                	jmp    f01013a8 <vprintfmt+0xef>

		case '*':
			precision = va_arg(ap, int);
f0101375:	8b 45 14             	mov    0x14(%ebp),%eax
f0101378:	8d 50 04             	lea    0x4(%eax),%edx
f010137b:	89 55 14             	mov    %edx,0x14(%ebp)
f010137e:	8b 00                	mov    (%eax),%eax
f0101380:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto process_precision;
f0101383:	eb 23                	jmp    f01013a8 <vprintfmt+0xef>

		case '.':
			if (width < 0)
f0101385:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101389:	79 0c                	jns    f0101397 <vprintfmt+0xde>
				width = 0;
f010138b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			goto reswitch;
f0101392:	e9 78 ff ff ff       	jmp    f010130f <vprintfmt+0x56>
f0101397:	e9 73 ff ff ff       	jmp    f010130f <vprintfmt+0x56>

		case '#':
			altflag = 1;
f010139c:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f01013a3:	e9 67 ff ff ff       	jmp    f010130f <vprintfmt+0x56>

		process_precision:
			if (width < 0)
f01013a8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01013ac:	79 12                	jns    f01013c0 <vprintfmt+0x107>
				width = precision, precision = -1;
f01013ae:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01013b1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01013b4:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
			goto reswitch;
f01013bb:	e9 4f ff ff ff       	jmp    f010130f <vprintfmt+0x56>
f01013c0:	e9 4a ff ff ff       	jmp    f010130f <vprintfmt+0x56>

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01013c5:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
			goto reswitch;
f01013c9:	e9 41 ff ff ff       	jmp    f010130f <vprintfmt+0x56>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01013ce:	8b 45 14             	mov    0x14(%ebp),%eax
f01013d1:	8d 50 04             	lea    0x4(%eax),%edx
f01013d4:	89 55 14             	mov    %edx,0x14(%ebp)
f01013d7:	8b 00                	mov    (%eax),%eax
f01013d9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013dc:	89 54 24 04          	mov    %edx,0x4(%esp)
f01013e0:	89 04 24             	mov    %eax,(%esp)
f01013e3:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e6:	ff d0                	call   *%eax
			break;
f01013e8:	e9 c2 02 00 00       	jmp    f01016af <vprintfmt+0x3f6>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01013ed:	8b 45 14             	mov    0x14(%ebp),%eax
f01013f0:	8d 50 04             	lea    0x4(%eax),%edx
f01013f3:	89 55 14             	mov    %edx,0x14(%ebp)
f01013f6:	8b 18                	mov    (%eax),%ebx
			if (err < 0)
f01013f8:	85 db                	test   %ebx,%ebx
f01013fa:	79 02                	jns    f01013fe <vprintfmt+0x145>
				err = -err;
f01013fc:	f7 db                	neg    %ebx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01013fe:	83 fb 07             	cmp    $0x7,%ebx
f0101401:	7f 0b                	jg     f010140e <vprintfmt+0x155>
f0101403:	8b 34 9d 20 24 10 f0 	mov    -0xfefdbe0(,%ebx,4),%esi
f010140a:	85 f6                	test   %esi,%esi
f010140c:	75 23                	jne    f0101431 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f010140e:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101412:	c7 44 24 08 51 24 10 	movl   $0xf0102451,0x8(%esp)
f0101419:	f0 
f010141a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010141d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101421:	8b 45 08             	mov    0x8(%ebp),%eax
f0101424:	89 04 24             	mov    %eax,(%esp)
f0101427:	e8 90 02 00 00       	call   f01016bc <printfmt>
			else
				printfmt(putch, putdat, "%s", p);
			break;
f010142c:	e9 7e 02 00 00       	jmp    f01016af <vprintfmt+0x3f6>
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f0101431:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101435:	c7 44 24 08 5a 24 10 	movl   $0xf010245a,0x8(%esp)
f010143c:	f0 
f010143d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101440:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101444:	8b 45 08             	mov    0x8(%ebp),%eax
f0101447:	89 04 24             	mov    %eax,(%esp)
f010144a:	e8 6d 02 00 00       	call   f01016bc <printfmt>
			break;
f010144f:	e9 5b 02 00 00       	jmp    f01016af <vprintfmt+0x3f6>

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101454:	8b 45 14             	mov    0x14(%ebp),%eax
f0101457:	8d 50 04             	lea    0x4(%eax),%edx
f010145a:	89 55 14             	mov    %edx,0x14(%ebp)
f010145d:	8b 30                	mov    (%eax),%esi
f010145f:	85 f6                	test   %esi,%esi
f0101461:	75 05                	jne    f0101468 <vprintfmt+0x1af>
				p = "(null)";
f0101463:	be 5d 24 10 f0       	mov    $0xf010245d,%esi
			if (width > 0 && padc != '-')
f0101468:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010146c:	7e 37                	jle    f01014a5 <vprintfmt+0x1ec>
f010146e:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
f0101472:	74 31                	je     f01014a5 <vprintfmt+0x1ec>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101474:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101477:	89 44 24 04          	mov    %eax,0x4(%esp)
f010147b:	89 34 24             	mov    %esi,(%esp)
f010147e:	e8 4b 04 00 00       	call   f01018ce <strnlen>
f0101483:	29 45 e4             	sub    %eax,-0x1c(%ebp)
f0101486:	eb 17                	jmp    f010149f <vprintfmt+0x1e6>
					putch(padc, putdat);
f0101488:	0f be 45 db          	movsbl -0x25(%ebp),%eax
f010148c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010148f:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101493:	89 04 24             	mov    %eax,(%esp)
f0101496:	8b 45 08             	mov    0x8(%ebp),%eax
f0101499:	ff d0                	call   *%eax
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010149b:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f010149f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01014a3:	7f e3                	jg     f0101488 <vprintfmt+0x1cf>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01014a5:	eb 38                	jmp    f01014df <vprintfmt+0x226>
				if (altflag && (ch < ' ' || ch > '~'))
f01014a7:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01014ab:	74 1f                	je     f01014cc <vprintfmt+0x213>
f01014ad:	83 fb 1f             	cmp    $0x1f,%ebx
f01014b0:	7e 05                	jle    f01014b7 <vprintfmt+0x1fe>
f01014b2:	83 fb 7e             	cmp    $0x7e,%ebx
f01014b5:	7e 15                	jle    f01014cc <vprintfmt+0x213>
					putch('?', putdat);
f01014b7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014be:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01014c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01014c8:	ff d0                	call   *%eax
f01014ca:	eb 0f                	jmp    f01014db <vprintfmt+0x222>
				else
					putch(ch, putdat);
f01014cc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014cf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014d3:	89 1c 24             	mov    %ebx,(%esp)
f01014d6:	8b 45 08             	mov    0x8(%ebp),%eax
f01014d9:	ff d0                	call   *%eax
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01014db:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f01014df:	89 f0                	mov    %esi,%eax
f01014e1:	8d 70 01             	lea    0x1(%eax),%esi
f01014e4:	0f b6 00             	movzbl (%eax),%eax
f01014e7:	0f be d8             	movsbl %al,%ebx
f01014ea:	85 db                	test   %ebx,%ebx
f01014ec:	74 10                	je     f01014fe <vprintfmt+0x245>
f01014ee:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01014f2:	78 b3                	js     f01014a7 <vprintfmt+0x1ee>
f01014f4:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f01014f8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01014fc:	79 a9                	jns    f01014a7 <vprintfmt+0x1ee>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01014fe:	eb 17                	jmp    f0101517 <vprintfmt+0x25e>
				putch(' ', putdat);
f0101500:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101503:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101507:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010150e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101511:	ff d0                	call   *%eax
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101513:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0101517:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010151b:	7f e3                	jg     f0101500 <vprintfmt+0x247>
				putch(' ', putdat);
			break;
f010151d:	e9 8d 01 00 00       	jmp    f01016af <vprintfmt+0x3f6>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101522:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101525:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101529:	8d 45 14             	lea    0x14(%ebp),%eax
f010152c:	89 04 24             	mov    %eax,(%esp)
f010152f:	e8 3e fd ff ff       	call   f0101272 <getint>
f0101534:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101537:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((long long) num < 0) {
f010153a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010153d:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101540:	85 d2                	test   %edx,%edx
f0101542:	79 26                	jns    f010156a <vprintfmt+0x2b1>
				putch('-', putdat);
f0101544:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101547:	89 44 24 04          	mov    %eax,0x4(%esp)
f010154b:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101552:	8b 45 08             	mov    0x8(%ebp),%eax
f0101555:	ff d0                	call   *%eax
				num = -(long long) num;
f0101557:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010155a:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010155d:	f7 d8                	neg    %eax
f010155f:	83 d2 00             	adc    $0x0,%edx
f0101562:	f7 da                	neg    %edx
f0101564:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101567:	89 55 f4             	mov    %edx,-0xc(%ebp)
			}
			base = 10;
f010156a:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f0101571:	e9 c5 00 00 00       	jmp    f010163b <vprintfmt+0x382>

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101576:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101579:	89 44 24 04          	mov    %eax,0x4(%esp)
f010157d:	8d 45 14             	lea    0x14(%ebp),%eax
f0101580:	89 04 24             	mov    %eax,(%esp)
f0101583:	e8 9b fc ff ff       	call   f0101223 <getuint>
f0101588:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010158b:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 10;
f010158e:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f0101595:	e9 a1 00 00 00       	jmp    f010163b <vprintfmt+0x382>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f010159a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010159d:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015a1:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01015a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01015ab:	ff d0                	call   *%eax
			putch('X', putdat);
f01015ad:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015b0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015b4:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01015bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01015be:	ff d0                	call   *%eax
			putch('X', putdat);
f01015c0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015c3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015c7:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01015ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01015d1:	ff d0                	call   *%eax
			break;
f01015d3:	e9 d7 00 00 00       	jmp    f01016af <vprintfmt+0x3f6>

		// pointer
		case 'p':
			putch('0', putdat);
f01015d8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015df:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01015e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e9:	ff d0                	call   *%eax
			putch('x', putdat);
f01015eb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015f2:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01015f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01015fc:	ff d0                	call   *%eax
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01015fe:	8b 45 14             	mov    0x14(%ebp),%eax
f0101601:	8d 50 04             	lea    0x4(%eax),%edx
f0101604:	89 55 14             	mov    %edx,0x14(%ebp)
f0101607:	8b 00                	mov    (%eax),%eax

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101609:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010160c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101613:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
			goto number;
f010161a:	eb 1f                	jmp    f010163b <vprintfmt+0x382>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010161c:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010161f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101623:	8d 45 14             	lea    0x14(%ebp),%eax
f0101626:	89 04 24             	mov    %eax,(%esp)
f0101629:	e8 f5 fb ff ff       	call   f0101223 <getuint>
f010162e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101631:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 16;
f0101634:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
		number:
			printnum(putch, putdat, num, base, width, padc);
f010163b:	0f be 55 db          	movsbl -0x25(%ebp),%edx
f010163f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101642:	89 54 24 18          	mov    %edx,0x18(%esp)
f0101646:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101649:	89 54 24 14          	mov    %edx,0x14(%esp)
f010164d:	89 44 24 10          	mov    %eax,0x10(%esp)
f0101651:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101654:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101657:	89 44 24 08          	mov    %eax,0x8(%esp)
f010165b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010165f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101662:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101666:	8b 45 08             	mov    0x8(%ebp),%eax
f0101669:	89 04 24             	mov    %eax,(%esp)
f010166c:	e8 d4 fa ff ff       	call   f0101145 <printnum>
			break;
f0101671:	eb 3c                	jmp    f01016af <vprintfmt+0x3f6>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101673:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101676:	89 44 24 04          	mov    %eax,0x4(%esp)
f010167a:	89 1c 24             	mov    %ebx,(%esp)
f010167d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101680:	ff d0                	call   *%eax
			break;
f0101682:	eb 2b                	jmp    f01016af <vprintfmt+0x3f6>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101684:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101687:	89 44 24 04          	mov    %eax,0x4(%esp)
f010168b:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101692:	8b 45 08             	mov    0x8(%ebp),%eax
f0101695:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101697:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f010169b:	eb 04                	jmp    f01016a1 <vprintfmt+0x3e8>
f010169d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f01016a1:	8b 45 10             	mov    0x10(%ebp),%eax
f01016a4:	83 e8 01             	sub    $0x1,%eax
f01016a7:	0f b6 00             	movzbl (%eax),%eax
f01016aa:	3c 25                	cmp    $0x25,%al
f01016ac:	75 ef                	jne    f010169d <vprintfmt+0x3e4>
				/* do nothing */;
			break;
f01016ae:	90                   	nop
		}
	}
f01016af:	90                   	nop
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01016b0:	e9 26 fc ff ff       	jmp    f01012db <vprintfmt+0x22>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f01016b5:	83 c4 40             	add    $0x40,%esp
f01016b8:	5b                   	pop    %ebx
f01016b9:	5e                   	pop    %esi
f01016ba:	5d                   	pop    %ebp
f01016bb:	c3                   	ret    

f01016bc <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01016bc:	55                   	push   %ebp
f01016bd:	89 e5                	mov    %esp,%ebp
f01016bf:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
f01016c2:	8d 45 14             	lea    0x14(%ebp),%eax
f01016c5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	vprintfmt(putch, putdat, fmt, ap);
f01016c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01016cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016cf:	8b 45 10             	mov    0x10(%ebp),%eax
f01016d2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01016d6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016d9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01016e0:	89 04 24             	mov    %eax,(%esp)
f01016e3:	e8 d1 fb ff ff       	call   f01012b9 <vprintfmt>
	va_end(ap);
}
f01016e8:	c9                   	leave  
f01016e9:	c3                   	ret    

f01016ea <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01016ea:	55                   	push   %ebp
f01016eb:	89 e5                	mov    %esp,%ebp
	b->cnt++;
f01016ed:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016f0:	8b 40 08             	mov    0x8(%eax),%eax
f01016f3:	8d 50 01             	lea    0x1(%eax),%edx
f01016f6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016f9:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
f01016fc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016ff:	8b 10                	mov    (%eax),%edx
f0101701:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101704:	8b 40 04             	mov    0x4(%eax),%eax
f0101707:	39 c2                	cmp    %eax,%edx
f0101709:	73 12                	jae    f010171d <sprintputch+0x33>
		*b->buf++ = ch;
f010170b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010170e:	8b 00                	mov    (%eax),%eax
f0101710:	8d 48 01             	lea    0x1(%eax),%ecx
f0101713:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101716:	89 0a                	mov    %ecx,(%edx)
f0101718:	8b 55 08             	mov    0x8(%ebp),%edx
f010171b:	88 10                	mov    %dl,(%eax)
}
f010171d:	5d                   	pop    %ebp
f010171e:	c3                   	ret    

f010171f <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010171f:	55                   	push   %ebp
f0101720:	89 e5                	mov    %esp,%ebp
f0101722:	83 ec 28             	sub    $0x28,%esp
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101725:	8b 45 08             	mov    0x8(%ebp),%eax
f0101728:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010172b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010172e:	8d 50 ff             	lea    -0x1(%eax),%edx
f0101731:	8b 45 08             	mov    0x8(%ebp),%eax
f0101734:	01 d0                	add    %edx,%eax
f0101736:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101739:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101740:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0101744:	74 06                	je     f010174c <vsnprintf+0x2d>
f0101746:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010174a:	7f 07                	jg     f0101753 <vsnprintf+0x34>
		return -E_INVAL;
f010174c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101751:	eb 2a                	jmp    f010177d <vsnprintf+0x5e>

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101753:	8b 45 14             	mov    0x14(%ebp),%eax
f0101756:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010175a:	8b 45 10             	mov    0x10(%ebp),%eax
f010175d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101761:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101764:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101768:	c7 04 24 ea 16 10 f0 	movl   $0xf01016ea,(%esp)
f010176f:	e8 45 fb ff ff       	call   f01012b9 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101774:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101777:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010177a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f010177d:	c9                   	leave  
f010177e:	c3                   	ret    

f010177f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010177f:	55                   	push   %ebp
f0101780:	89 e5                	mov    %esp,%ebp
f0101782:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101785:	8d 45 14             	lea    0x14(%ebp),%eax
f0101788:	89 45 f0             	mov    %eax,-0x10(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
f010178b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010178e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101792:	8b 45 10             	mov    0x10(%ebp),%eax
f0101795:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101799:	8b 45 0c             	mov    0xc(%ebp),%eax
f010179c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01017a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01017a3:	89 04 24             	mov    %eax,(%esp)
f01017a6:	e8 74 ff ff ff       	call   f010171f <vsnprintf>
f01017ab:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return rc;
f01017ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01017b1:	c9                   	leave  
f01017b2:	c3                   	ret    

f01017b3 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01017b3:	55                   	push   %ebp
f01017b4:	89 e5                	mov    %esp,%ebp
f01017b6:	83 ec 28             	sub    $0x28,%esp
	int i, c, echoing;

	if (prompt != NULL)
f01017b9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01017bd:	74 13                	je     f01017d2 <readline+0x1f>
		cprintf("%s", prompt);
f01017bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01017c2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01017c6:	c7 04 24 bc 25 10 f0 	movl   $0xf01025bc,(%esp)
f01017cd:	e8 0d f5 ff ff       	call   f0100cdf <cprintf>

	i = 0;
f01017d2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	echoing = iscons(0);
f01017d9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017e0:	e8 a6 f1 ff ff       	call   f010098b <iscons>
f01017e5:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while (1) {
		c = getchar();
f01017e8:	e8 85 f1 ff ff       	call   f0100972 <getchar>
f01017ed:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (c < 0) {
f01017f0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01017f4:	79 1d                	jns    f0101813 <readline+0x60>
			cprintf("read error: %e\n", c);
f01017f6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01017f9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01017fd:	c7 04 24 bf 25 10 f0 	movl   $0xf01025bf,(%esp)
f0101804:	e8 d6 f4 ff ff       	call   f0100cdf <cprintf>
			return NULL;
f0101809:	b8 00 00 00 00       	mov    $0x0,%eax
f010180e:	e9 93 00 00 00       	jmp    f01018a6 <readline+0xf3>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101813:	83 7d ec 08          	cmpl   $0x8,-0x14(%ebp)
f0101817:	74 06                	je     f010181f <readline+0x6c>
f0101819:	83 7d ec 7f          	cmpl   $0x7f,-0x14(%ebp)
f010181d:	75 1e                	jne    f010183d <readline+0x8a>
f010181f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0101823:	7e 18                	jle    f010183d <readline+0x8a>
			if (echoing)
f0101825:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0101829:	74 0c                	je     f0101837 <readline+0x84>
				cputchar('\b');
f010182b:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0101832:	e8 28 f1 ff ff       	call   f010095f <cputchar>
			i--;
f0101837:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
f010183b:	eb 64                	jmp    f01018a1 <readline+0xee>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010183d:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%ebp)
f0101841:	7e 2e                	jle    f0101871 <readline+0xbe>
f0101843:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
f010184a:	7f 25                	jg     f0101871 <readline+0xbe>
			if (echoing)
f010184c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0101850:	74 0b                	je     f010185d <readline+0xaa>
				cputchar(c);
f0101852:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101855:	89 04 24             	mov    %eax,(%esp)
f0101858:	e8 02 f1 ff ff       	call   f010095f <cputchar>
			buf[i++] = c;
f010185d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101860:	8d 50 01             	lea    0x1(%eax),%edx
f0101863:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101866:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101869:	88 90 80 27 11 f0    	mov    %dl,-0xfeed880(%eax)
f010186f:	eb 30                	jmp    f01018a1 <readline+0xee>
		} else if (c == '\n' || c == '\r') {
f0101871:	83 7d ec 0a          	cmpl   $0xa,-0x14(%ebp)
f0101875:	74 06                	je     f010187d <readline+0xca>
f0101877:	83 7d ec 0d          	cmpl   $0xd,-0x14(%ebp)
f010187b:	75 24                	jne    f01018a1 <readline+0xee>
			if (echoing)
f010187d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0101881:	74 0c                	je     f010188f <readline+0xdc>
				cputchar('\n');
f0101883:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f010188a:	e8 d0 f0 ff ff       	call   f010095f <cputchar>
			buf[i] = 0;
f010188f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101892:	05 80 27 11 f0       	add    $0xf0112780,%eax
f0101897:	c6 00 00             	movb   $0x0,(%eax)
			return buf;
f010189a:	b8 80 27 11 f0       	mov    $0xf0112780,%eax
f010189f:	eb 05                	jmp    f01018a6 <readline+0xf3>
		}
	}
f01018a1:	e9 42 ff ff ff       	jmp    f01017e8 <readline+0x35>
}
f01018a6:	c9                   	leave  
f01018a7:	c3                   	ret    

f01018a8 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01018a8:	55                   	push   %ebp
f01018a9:	89 e5                	mov    %esp,%ebp
f01018ab:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
f01018ae:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f01018b5:	eb 08                	jmp    f01018bf <strlen+0x17>
		n++;
f01018b7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01018bb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f01018bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01018c2:	0f b6 00             	movzbl (%eax),%eax
f01018c5:	84 c0                	test   %al,%al
f01018c7:	75 ee                	jne    f01018b7 <strlen+0xf>
		n++;
	return n;
f01018c9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f01018cc:	c9                   	leave  
f01018cd:	c3                   	ret    

f01018ce <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01018ce:	55                   	push   %ebp
f01018cf:	89 e5                	mov    %esp,%ebp
f01018d1:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01018d4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f01018db:	eb 0c                	jmp    f01018e9 <strnlen+0x1b>
		n++;
f01018dd:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01018e1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f01018e5:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
f01018e9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01018ed:	74 0a                	je     f01018f9 <strnlen+0x2b>
f01018ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01018f2:	0f b6 00             	movzbl (%eax),%eax
f01018f5:	84 c0                	test   %al,%al
f01018f7:	75 e4                	jne    f01018dd <strnlen+0xf>
		n++;
	return n;
f01018f9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f01018fc:	c9                   	leave  
f01018fd:	c3                   	ret    

f01018fe <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01018fe:	55                   	push   %ebp
f01018ff:	89 e5                	mov    %esp,%ebp
f0101901:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
f0101904:	8b 45 08             	mov    0x8(%ebp),%eax
f0101907:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
f010190a:	90                   	nop
f010190b:	8b 45 08             	mov    0x8(%ebp),%eax
f010190e:	8d 50 01             	lea    0x1(%eax),%edx
f0101911:	89 55 08             	mov    %edx,0x8(%ebp)
f0101914:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101917:	8d 4a 01             	lea    0x1(%edx),%ecx
f010191a:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f010191d:	0f b6 12             	movzbl (%edx),%edx
f0101920:	88 10                	mov    %dl,(%eax)
f0101922:	0f b6 00             	movzbl (%eax),%eax
f0101925:	84 c0                	test   %al,%al
f0101927:	75 e2                	jne    f010190b <strcpy+0xd>
		/* do nothing */;
	return ret;
f0101929:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f010192c:	c9                   	leave  
f010192d:	c3                   	ret    

f010192e <strcat>:

char *
strcat(char *dst, const char *src)
{
f010192e:	55                   	push   %ebp
f010192f:	89 e5                	mov    %esp,%ebp
f0101931:	83 ec 18             	sub    $0x18,%esp
	int len = strlen(dst);
f0101934:	8b 45 08             	mov    0x8(%ebp),%eax
f0101937:	89 04 24             	mov    %eax,(%esp)
f010193a:	e8 69 ff ff ff       	call   f01018a8 <strlen>
f010193f:	89 45 fc             	mov    %eax,-0x4(%ebp)
	strcpy(dst + len, src);
f0101942:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0101945:	8b 45 08             	mov    0x8(%ebp),%eax
f0101948:	01 c2                	add    %eax,%edx
f010194a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010194d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101951:	89 14 24             	mov    %edx,(%esp)
f0101954:	e8 a5 ff ff ff       	call   f01018fe <strcpy>
	return dst;
f0101959:	8b 45 08             	mov    0x8(%ebp),%eax
}
f010195c:	c9                   	leave  
f010195d:	c3                   	ret    

f010195e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010195e:	55                   	push   %ebp
f010195f:	89 e5                	mov    %esp,%ebp
f0101961:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
f0101964:	8b 45 08             	mov    0x8(%ebp),%eax
f0101967:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
f010196a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0101971:	eb 23                	jmp    f0101996 <strncpy+0x38>
		*dst++ = *src;
f0101973:	8b 45 08             	mov    0x8(%ebp),%eax
f0101976:	8d 50 01             	lea    0x1(%eax),%edx
f0101979:	89 55 08             	mov    %edx,0x8(%ebp)
f010197c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010197f:	0f b6 12             	movzbl (%edx),%edx
f0101982:	88 10                	mov    %dl,(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
f0101984:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101987:	0f b6 00             	movzbl (%eax),%eax
f010198a:	84 c0                	test   %al,%al
f010198c:	74 04                	je     f0101992 <strncpy+0x34>
			src++;
f010198e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101992:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f0101996:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101999:	3b 45 10             	cmp    0x10(%ebp),%eax
f010199c:	72 d5                	jb     f0101973 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
f010199e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f01019a1:	c9                   	leave  
f01019a2:	c3                   	ret    

f01019a3 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01019a3:	55                   	push   %ebp
f01019a4:	89 e5                	mov    %esp,%ebp
f01019a6:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
f01019a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01019ac:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
f01019af:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01019b3:	74 33                	je     f01019e8 <strlcpy+0x45>
		while (--size > 0 && *src != '\0')
f01019b5:	eb 17                	jmp    f01019ce <strlcpy+0x2b>
			*dst++ = *src++;
f01019b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01019ba:	8d 50 01             	lea    0x1(%eax),%edx
f01019bd:	89 55 08             	mov    %edx,0x8(%ebp)
f01019c0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01019c3:	8d 4a 01             	lea    0x1(%edx),%ecx
f01019c6:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f01019c9:	0f b6 12             	movzbl (%edx),%edx
f01019cc:	88 10                	mov    %dl,(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01019ce:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f01019d2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01019d6:	74 0a                	je     f01019e2 <strlcpy+0x3f>
f01019d8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01019db:	0f b6 00             	movzbl (%eax),%eax
f01019de:	84 c0                	test   %al,%al
f01019e0:	75 d5                	jne    f01019b7 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
f01019e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01019e5:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01019e8:	8b 55 08             	mov    0x8(%ebp),%edx
f01019eb:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01019ee:	29 c2                	sub    %eax,%edx
f01019f0:	89 d0                	mov    %edx,%eax
}
f01019f2:	c9                   	leave  
f01019f3:	c3                   	ret    

f01019f4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01019f4:	55                   	push   %ebp
f01019f5:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
f01019f7:	eb 08                	jmp    f0101a01 <strcmp+0xd>
		p++, q++;
f01019f9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f01019fd:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101a01:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a04:	0f b6 00             	movzbl (%eax),%eax
f0101a07:	84 c0                	test   %al,%al
f0101a09:	74 10                	je     f0101a1b <strcmp+0x27>
f0101a0b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a0e:	0f b6 10             	movzbl (%eax),%edx
f0101a11:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a14:	0f b6 00             	movzbl (%eax),%eax
f0101a17:	38 c2                	cmp    %al,%dl
f0101a19:	74 de                	je     f01019f9 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101a1b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a1e:	0f b6 00             	movzbl (%eax),%eax
f0101a21:	0f b6 d0             	movzbl %al,%edx
f0101a24:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a27:	0f b6 00             	movzbl (%eax),%eax
f0101a2a:	0f b6 c0             	movzbl %al,%eax
f0101a2d:	29 c2                	sub    %eax,%edx
f0101a2f:	89 d0                	mov    %edx,%eax
}
f0101a31:	5d                   	pop    %ebp
f0101a32:	c3                   	ret    

f0101a33 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101a33:	55                   	push   %ebp
f0101a34:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
f0101a36:	eb 0c                	jmp    f0101a44 <strncmp+0x11>
		n--, p++, q++;
f0101a38:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f0101a3c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101a40:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101a44:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101a48:	74 1a                	je     f0101a64 <strncmp+0x31>
f0101a4a:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a4d:	0f b6 00             	movzbl (%eax),%eax
f0101a50:	84 c0                	test   %al,%al
f0101a52:	74 10                	je     f0101a64 <strncmp+0x31>
f0101a54:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a57:	0f b6 10             	movzbl (%eax),%edx
f0101a5a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a5d:	0f b6 00             	movzbl (%eax),%eax
f0101a60:	38 c2                	cmp    %al,%dl
f0101a62:	74 d4                	je     f0101a38 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
f0101a64:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101a68:	75 07                	jne    f0101a71 <strncmp+0x3e>
		return 0;
f0101a6a:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a6f:	eb 16                	jmp    f0101a87 <strncmp+0x54>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101a71:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a74:	0f b6 00             	movzbl (%eax),%eax
f0101a77:	0f b6 d0             	movzbl %al,%edx
f0101a7a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a7d:	0f b6 00             	movzbl (%eax),%eax
f0101a80:	0f b6 c0             	movzbl %al,%eax
f0101a83:	29 c2                	sub    %eax,%edx
f0101a85:	89 d0                	mov    %edx,%eax
}
f0101a87:	5d                   	pop    %ebp
f0101a88:	c3                   	ret    

f0101a89 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101a89:	55                   	push   %ebp
f0101a8a:	89 e5                	mov    %esp,%ebp
f0101a8c:	83 ec 04             	sub    $0x4,%esp
f0101a8f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a92:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f0101a95:	eb 14                	jmp    f0101aab <strchr+0x22>
		if (*s == c)
f0101a97:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a9a:	0f b6 00             	movzbl (%eax),%eax
f0101a9d:	3a 45 fc             	cmp    -0x4(%ebp),%al
f0101aa0:	75 05                	jne    f0101aa7 <strchr+0x1e>
			return (char *) s;
f0101aa2:	8b 45 08             	mov    0x8(%ebp),%eax
f0101aa5:	eb 13                	jmp    f0101aba <strchr+0x31>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101aa7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101aab:	8b 45 08             	mov    0x8(%ebp),%eax
f0101aae:	0f b6 00             	movzbl (%eax),%eax
f0101ab1:	84 c0                	test   %al,%al
f0101ab3:	75 e2                	jne    f0101a97 <strchr+0xe>
		if (*s == c)
			return (char *) s;
	return 0;
f0101ab5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101aba:	c9                   	leave  
f0101abb:	c3                   	ret    

f0101abc <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101abc:	55                   	push   %ebp
f0101abd:	89 e5                	mov    %esp,%ebp
f0101abf:	83 ec 04             	sub    $0x4,%esp
f0101ac2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101ac5:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f0101ac8:	eb 11                	jmp    f0101adb <strfind+0x1f>
		if (*s == c)
f0101aca:	8b 45 08             	mov    0x8(%ebp),%eax
f0101acd:	0f b6 00             	movzbl (%eax),%eax
f0101ad0:	3a 45 fc             	cmp    -0x4(%ebp),%al
f0101ad3:	75 02                	jne    f0101ad7 <strfind+0x1b>
			break;
f0101ad5:	eb 0e                	jmp    f0101ae5 <strfind+0x29>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101ad7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101adb:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ade:	0f b6 00             	movzbl (%eax),%eax
f0101ae1:	84 c0                	test   %al,%al
f0101ae3:	75 e5                	jne    f0101aca <strfind+0xe>
		if (*s == c)
			break;
	return (char *) s;
f0101ae5:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0101ae8:	c9                   	leave  
f0101ae9:	c3                   	ret    

f0101aea <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101aea:	55                   	push   %ebp
f0101aeb:	89 e5                	mov    %esp,%ebp
f0101aed:	57                   	push   %edi
	char *p;

	if (n == 0)
f0101aee:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101af2:	75 05                	jne    f0101af9 <memset+0xf>
		return v;
f0101af4:	8b 45 08             	mov    0x8(%ebp),%eax
f0101af7:	eb 5c                	jmp    f0101b55 <memset+0x6b>
	if ((int)v%4 == 0 && n%4 == 0) {
f0101af9:	8b 45 08             	mov    0x8(%ebp),%eax
f0101afc:	83 e0 03             	and    $0x3,%eax
f0101aff:	85 c0                	test   %eax,%eax
f0101b01:	75 41                	jne    f0101b44 <memset+0x5a>
f0101b03:	8b 45 10             	mov    0x10(%ebp),%eax
f0101b06:	83 e0 03             	and    $0x3,%eax
f0101b09:	85 c0                	test   %eax,%eax
f0101b0b:	75 37                	jne    f0101b44 <memset+0x5a>
		c &= 0xFF;
f0101b0d:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101b14:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b17:	c1 e0 18             	shl    $0x18,%eax
f0101b1a:	89 c2                	mov    %eax,%edx
f0101b1c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b1f:	c1 e0 10             	shl    $0x10,%eax
f0101b22:	09 c2                	or     %eax,%edx
f0101b24:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b27:	c1 e0 08             	shl    $0x8,%eax
f0101b2a:	09 d0                	or     %edx,%eax
f0101b2c:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101b2f:	8b 45 10             	mov    0x10(%ebp),%eax
f0101b32:	c1 e8 02             	shr    $0x2,%eax
f0101b35:	89 c1                	mov    %eax,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101b37:	8b 55 08             	mov    0x8(%ebp),%edx
f0101b3a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b3d:	89 d7                	mov    %edx,%edi
f0101b3f:	fc                   	cld    
f0101b40:	f3 ab                	rep stos %eax,%es:(%edi)
f0101b42:	eb 0e                	jmp    f0101b52 <memset+0x68>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101b44:	8b 55 08             	mov    0x8(%ebp),%edx
f0101b47:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b4a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101b4d:	89 d7                	mov    %edx,%edi
f0101b4f:	fc                   	cld    
f0101b50:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
f0101b52:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0101b55:	5f                   	pop    %edi
f0101b56:	5d                   	pop    %ebp
f0101b57:	c3                   	ret    

f0101b58 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101b58:	55                   	push   %ebp
f0101b59:	89 e5                	mov    %esp,%ebp
f0101b5b:	57                   	push   %edi
f0101b5c:	56                   	push   %esi
f0101b5d:	53                   	push   %ebx
f0101b5e:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;

	s = src;
f0101b61:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b64:	89 45 f0             	mov    %eax,-0x10(%ebp)
	d = dst;
f0101b67:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b6a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (s < d && s + n > d) {
f0101b6d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101b70:	3b 45 ec             	cmp    -0x14(%ebp),%eax
f0101b73:	73 6d                	jae    f0101be2 <memmove+0x8a>
f0101b75:	8b 45 10             	mov    0x10(%ebp),%eax
f0101b78:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101b7b:	01 d0                	add    %edx,%eax
f0101b7d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
f0101b80:	76 60                	jbe    f0101be2 <memmove+0x8a>
		s += n;
f0101b82:	8b 45 10             	mov    0x10(%ebp),%eax
f0101b85:	01 45 f0             	add    %eax,-0x10(%ebp)
		d += n;
f0101b88:	8b 45 10             	mov    0x10(%ebp),%eax
f0101b8b:	01 45 ec             	add    %eax,-0x14(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101b8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101b91:	83 e0 03             	and    $0x3,%eax
f0101b94:	85 c0                	test   %eax,%eax
f0101b96:	75 2f                	jne    f0101bc7 <memmove+0x6f>
f0101b98:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101b9b:	83 e0 03             	and    $0x3,%eax
f0101b9e:	85 c0                	test   %eax,%eax
f0101ba0:	75 25                	jne    f0101bc7 <memmove+0x6f>
f0101ba2:	8b 45 10             	mov    0x10(%ebp),%eax
f0101ba5:	83 e0 03             	and    $0x3,%eax
f0101ba8:	85 c0                	test   %eax,%eax
f0101baa:	75 1b                	jne    f0101bc7 <memmove+0x6f>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101bac:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101baf:	83 e8 04             	sub    $0x4,%eax
f0101bb2:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101bb5:	83 ea 04             	sub    $0x4,%edx
f0101bb8:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101bbb:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101bbe:	89 c7                	mov    %eax,%edi
f0101bc0:	89 d6                	mov    %edx,%esi
f0101bc2:	fd                   	std    
f0101bc3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101bc5:	eb 18                	jmp    f0101bdf <memmove+0x87>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101bc7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101bca:	8d 50 ff             	lea    -0x1(%eax),%edx
f0101bcd:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101bd0:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101bd3:	8b 45 10             	mov    0x10(%ebp),%eax
f0101bd6:	89 d7                	mov    %edx,%edi
f0101bd8:	89 de                	mov    %ebx,%esi
f0101bda:	89 c1                	mov    %eax,%ecx
f0101bdc:	fd                   	std    
f0101bdd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101bdf:	fc                   	cld    
f0101be0:	eb 45                	jmp    f0101c27 <memmove+0xcf>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101be2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101be5:	83 e0 03             	and    $0x3,%eax
f0101be8:	85 c0                	test   %eax,%eax
f0101bea:	75 2b                	jne    f0101c17 <memmove+0xbf>
f0101bec:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101bef:	83 e0 03             	and    $0x3,%eax
f0101bf2:	85 c0                	test   %eax,%eax
f0101bf4:	75 21                	jne    f0101c17 <memmove+0xbf>
f0101bf6:	8b 45 10             	mov    0x10(%ebp),%eax
f0101bf9:	83 e0 03             	and    $0x3,%eax
f0101bfc:	85 c0                	test   %eax,%eax
f0101bfe:	75 17                	jne    f0101c17 <memmove+0xbf>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101c00:	8b 45 10             	mov    0x10(%ebp),%eax
f0101c03:	c1 e8 02             	shr    $0x2,%eax
f0101c06:	89 c1                	mov    %eax,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101c08:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101c0b:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101c0e:	89 c7                	mov    %eax,%edi
f0101c10:	89 d6                	mov    %edx,%esi
f0101c12:	fc                   	cld    
f0101c13:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101c15:	eb 10                	jmp    f0101c27 <memmove+0xcf>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101c17:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101c1a:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101c1d:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101c20:	89 c7                	mov    %eax,%edi
f0101c22:	89 d6                	mov    %edx,%esi
f0101c24:	fc                   	cld    
f0101c25:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
f0101c27:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0101c2a:	83 c4 10             	add    $0x10,%esp
f0101c2d:	5b                   	pop    %ebx
f0101c2e:	5e                   	pop    %esi
f0101c2f:	5f                   	pop    %edi
f0101c30:	5d                   	pop    %ebp
f0101c31:	c3                   	ret    

f0101c32 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101c32:	55                   	push   %ebp
f0101c33:	89 e5                	mov    %esp,%ebp
f0101c35:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101c38:	8b 45 10             	mov    0x10(%ebp),%eax
f0101c3b:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101c3f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101c42:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101c46:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c49:	89 04 24             	mov    %eax,(%esp)
f0101c4c:	e8 07 ff ff ff       	call   f0101b58 <memmove>
}
f0101c51:	c9                   	leave  
f0101c52:	c3                   	ret    

f0101c53 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101c53:	55                   	push   %ebp
f0101c54:	89 e5                	mov    %esp,%ebp
f0101c56:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
f0101c59:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c5c:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
f0101c5f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101c62:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
f0101c65:	eb 30                	jmp    f0101c97 <memcmp+0x44>
		if (*s1 != *s2)
f0101c67:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101c6a:	0f b6 10             	movzbl (%eax),%edx
f0101c6d:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101c70:	0f b6 00             	movzbl (%eax),%eax
f0101c73:	38 c2                	cmp    %al,%dl
f0101c75:	74 18                	je     f0101c8f <memcmp+0x3c>
			return (int) *s1 - (int) *s2;
f0101c77:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101c7a:	0f b6 00             	movzbl (%eax),%eax
f0101c7d:	0f b6 d0             	movzbl %al,%edx
f0101c80:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101c83:	0f b6 00             	movzbl (%eax),%eax
f0101c86:	0f b6 c0             	movzbl %al,%eax
f0101c89:	29 c2                	sub    %eax,%edx
f0101c8b:	89 d0                	mov    %edx,%eax
f0101c8d:	eb 1a                	jmp    f0101ca9 <memcmp+0x56>
		s1++, s2++;
f0101c8f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f0101c93:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101c97:	8b 45 10             	mov    0x10(%ebp),%eax
f0101c9a:	8d 50 ff             	lea    -0x1(%eax),%edx
f0101c9d:	89 55 10             	mov    %edx,0x10(%ebp)
f0101ca0:	85 c0                	test   %eax,%eax
f0101ca2:	75 c3                	jne    f0101c67 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101ca4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101ca9:	c9                   	leave  
f0101caa:	c3                   	ret    

f0101cab <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101cab:	55                   	push   %ebp
f0101cac:	89 e5                	mov    %esp,%ebp
f0101cae:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
f0101cb1:	8b 45 10             	mov    0x10(%ebp),%eax
f0101cb4:	8b 55 08             	mov    0x8(%ebp),%edx
f0101cb7:	01 d0                	add    %edx,%eax
f0101cb9:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
f0101cbc:	eb 13                	jmp    f0101cd1 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101cbe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101cc1:	0f b6 10             	movzbl (%eax),%edx
f0101cc4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101cc7:	38 c2                	cmp    %al,%dl
f0101cc9:	75 02                	jne    f0101ccd <memfind+0x22>
			break;
f0101ccb:	eb 0c                	jmp    f0101cd9 <memfind+0x2e>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101ccd:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101cd1:	8b 45 08             	mov    0x8(%ebp),%eax
f0101cd4:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0101cd7:	72 e5                	jb     f0101cbe <memfind+0x13>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
f0101cd9:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0101cdc:	c9                   	leave  
f0101cdd:	c3                   	ret    

f0101cde <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101cde:	55                   	push   %ebp
f0101cdf:	89 e5                	mov    %esp,%ebp
f0101ce1:	83 ec 10             	sub    $0x10,%esp
	int neg = 0;
f0101ce4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	long val = 0;
f0101ceb:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101cf2:	eb 04                	jmp    f0101cf8 <strtol+0x1a>
		s++;
f0101cf4:	83 45 08 01          	addl   $0x1,0x8(%ebp)
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101cf8:	8b 45 08             	mov    0x8(%ebp),%eax
f0101cfb:	0f b6 00             	movzbl (%eax),%eax
f0101cfe:	3c 20                	cmp    $0x20,%al
f0101d00:	74 f2                	je     f0101cf4 <strtol+0x16>
f0101d02:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d05:	0f b6 00             	movzbl (%eax),%eax
f0101d08:	3c 09                	cmp    $0x9,%al
f0101d0a:	74 e8                	je     f0101cf4 <strtol+0x16>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101d0c:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d0f:	0f b6 00             	movzbl (%eax),%eax
f0101d12:	3c 2b                	cmp    $0x2b,%al
f0101d14:	75 06                	jne    f0101d1c <strtol+0x3e>
		s++;
f0101d16:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101d1a:	eb 15                	jmp    f0101d31 <strtol+0x53>
	else if (*s == '-')
f0101d1c:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d1f:	0f b6 00             	movzbl (%eax),%eax
f0101d22:	3c 2d                	cmp    $0x2d,%al
f0101d24:	75 0b                	jne    f0101d31 <strtol+0x53>
		s++, neg = 1;
f0101d26:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101d2a:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101d31:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101d35:	74 06                	je     f0101d3d <strtol+0x5f>
f0101d37:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
f0101d3b:	75 24                	jne    f0101d61 <strtol+0x83>
f0101d3d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d40:	0f b6 00             	movzbl (%eax),%eax
f0101d43:	3c 30                	cmp    $0x30,%al
f0101d45:	75 1a                	jne    f0101d61 <strtol+0x83>
f0101d47:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d4a:	83 c0 01             	add    $0x1,%eax
f0101d4d:	0f b6 00             	movzbl (%eax),%eax
f0101d50:	3c 78                	cmp    $0x78,%al
f0101d52:	75 0d                	jne    f0101d61 <strtol+0x83>
		s += 2, base = 16;
f0101d54:	83 45 08 02          	addl   $0x2,0x8(%ebp)
f0101d58:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
f0101d5f:	eb 2a                	jmp    f0101d8b <strtol+0xad>
	else if (base == 0 && s[0] == '0')
f0101d61:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101d65:	75 17                	jne    f0101d7e <strtol+0xa0>
f0101d67:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d6a:	0f b6 00             	movzbl (%eax),%eax
f0101d6d:	3c 30                	cmp    $0x30,%al
f0101d6f:	75 0d                	jne    f0101d7e <strtol+0xa0>
		s++, base = 8;
f0101d71:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101d75:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
f0101d7c:	eb 0d                	jmp    f0101d8b <strtol+0xad>
	else if (base == 0)
f0101d7e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101d82:	75 07                	jne    f0101d8b <strtol+0xad>
		base = 10;
f0101d84:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101d8b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d8e:	0f b6 00             	movzbl (%eax),%eax
f0101d91:	3c 2f                	cmp    $0x2f,%al
f0101d93:	7e 1b                	jle    f0101db0 <strtol+0xd2>
f0101d95:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d98:	0f b6 00             	movzbl (%eax),%eax
f0101d9b:	3c 39                	cmp    $0x39,%al
f0101d9d:	7f 11                	jg     f0101db0 <strtol+0xd2>
			dig = *s - '0';
f0101d9f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101da2:	0f b6 00             	movzbl (%eax),%eax
f0101da5:	0f be c0             	movsbl %al,%eax
f0101da8:	83 e8 30             	sub    $0x30,%eax
f0101dab:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101dae:	eb 48                	jmp    f0101df8 <strtol+0x11a>
		else if (*s >= 'a' && *s <= 'z')
f0101db0:	8b 45 08             	mov    0x8(%ebp),%eax
f0101db3:	0f b6 00             	movzbl (%eax),%eax
f0101db6:	3c 60                	cmp    $0x60,%al
f0101db8:	7e 1b                	jle    f0101dd5 <strtol+0xf7>
f0101dba:	8b 45 08             	mov    0x8(%ebp),%eax
f0101dbd:	0f b6 00             	movzbl (%eax),%eax
f0101dc0:	3c 7a                	cmp    $0x7a,%al
f0101dc2:	7f 11                	jg     f0101dd5 <strtol+0xf7>
			dig = *s - 'a' + 10;
f0101dc4:	8b 45 08             	mov    0x8(%ebp),%eax
f0101dc7:	0f b6 00             	movzbl (%eax),%eax
f0101dca:	0f be c0             	movsbl %al,%eax
f0101dcd:	83 e8 57             	sub    $0x57,%eax
f0101dd0:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101dd3:	eb 23                	jmp    f0101df8 <strtol+0x11a>
		else if (*s >= 'A' && *s <= 'Z')
f0101dd5:	8b 45 08             	mov    0x8(%ebp),%eax
f0101dd8:	0f b6 00             	movzbl (%eax),%eax
f0101ddb:	3c 40                	cmp    $0x40,%al
f0101ddd:	7e 3d                	jle    f0101e1c <strtol+0x13e>
f0101ddf:	8b 45 08             	mov    0x8(%ebp),%eax
f0101de2:	0f b6 00             	movzbl (%eax),%eax
f0101de5:	3c 5a                	cmp    $0x5a,%al
f0101de7:	7f 33                	jg     f0101e1c <strtol+0x13e>
			dig = *s - 'A' + 10;
f0101de9:	8b 45 08             	mov    0x8(%ebp),%eax
f0101dec:	0f b6 00             	movzbl (%eax),%eax
f0101def:	0f be c0             	movsbl %al,%eax
f0101df2:	83 e8 37             	sub    $0x37,%eax
f0101df5:	89 45 f4             	mov    %eax,-0xc(%ebp)
		else
			break;
		if (dig >= base)
f0101df8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101dfb:	3b 45 10             	cmp    0x10(%ebp),%eax
f0101dfe:	7c 02                	jl     f0101e02 <strtol+0x124>
			break;
f0101e00:	eb 1a                	jmp    f0101e1c <strtol+0x13e>
		s++, val = (val * base) + dig;
f0101e02:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0101e06:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101e09:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101e0d:	89 c2                	mov    %eax,%edx
f0101e0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101e12:	01 d0                	add    %edx,%eax
f0101e14:	89 45 f8             	mov    %eax,-0x8(%ebp)
		// we don't properly detect overflow!
	}
f0101e17:	e9 6f ff ff ff       	jmp    f0101d8b <strtol+0xad>

	if (endptr)
f0101e1c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101e20:	74 08                	je     f0101e2a <strtol+0x14c>
		*endptr = (char *) s;
f0101e22:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101e25:	8b 55 08             	mov    0x8(%ebp),%edx
f0101e28:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f0101e2a:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f0101e2e:	74 07                	je     f0101e37 <strtol+0x159>
f0101e30:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101e33:	f7 d8                	neg    %eax
f0101e35:	eb 03                	jmp    f0101e3a <strtol+0x15c>
f0101e37:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0101e3a:	c9                   	leave  
f0101e3b:	c3                   	ret    
f0101e3c:	66 90                	xchg   %ax,%ax
f0101e3e:	66 90                	xchg   %ax,%ax

f0101e40 <__udivdi3>:
f0101e40:	55                   	push   %ebp
f0101e41:	57                   	push   %edi
f0101e42:	56                   	push   %esi
f0101e43:	83 ec 0c             	sub    $0xc,%esp
f0101e46:	8b 44 24 28          	mov    0x28(%esp),%eax
f0101e4a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0101e4e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101e52:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101e56:	85 c0                	test   %eax,%eax
f0101e58:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101e5c:	89 ea                	mov    %ebp,%edx
f0101e5e:	89 0c 24             	mov    %ecx,(%esp)
f0101e61:	75 2d                	jne    f0101e90 <__udivdi3+0x50>
f0101e63:	39 e9                	cmp    %ebp,%ecx
f0101e65:	77 61                	ja     f0101ec8 <__udivdi3+0x88>
f0101e67:	85 c9                	test   %ecx,%ecx
f0101e69:	89 ce                	mov    %ecx,%esi
f0101e6b:	75 0b                	jne    f0101e78 <__udivdi3+0x38>
f0101e6d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101e72:	31 d2                	xor    %edx,%edx
f0101e74:	f7 f1                	div    %ecx
f0101e76:	89 c6                	mov    %eax,%esi
f0101e78:	31 d2                	xor    %edx,%edx
f0101e7a:	89 e8                	mov    %ebp,%eax
f0101e7c:	f7 f6                	div    %esi
f0101e7e:	89 c5                	mov    %eax,%ebp
f0101e80:	89 f8                	mov    %edi,%eax
f0101e82:	f7 f6                	div    %esi
f0101e84:	89 ea                	mov    %ebp,%edx
f0101e86:	83 c4 0c             	add    $0xc,%esp
f0101e89:	5e                   	pop    %esi
f0101e8a:	5f                   	pop    %edi
f0101e8b:	5d                   	pop    %ebp
f0101e8c:	c3                   	ret    
f0101e8d:	8d 76 00             	lea    0x0(%esi),%esi
f0101e90:	39 e8                	cmp    %ebp,%eax
f0101e92:	77 24                	ja     f0101eb8 <__udivdi3+0x78>
f0101e94:	0f bd e8             	bsr    %eax,%ebp
f0101e97:	83 f5 1f             	xor    $0x1f,%ebp
f0101e9a:	75 3c                	jne    f0101ed8 <__udivdi3+0x98>
f0101e9c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101ea0:	39 34 24             	cmp    %esi,(%esp)
f0101ea3:	0f 86 9f 00 00 00    	jbe    f0101f48 <__udivdi3+0x108>
f0101ea9:	39 d0                	cmp    %edx,%eax
f0101eab:	0f 82 97 00 00 00    	jb     f0101f48 <__udivdi3+0x108>
f0101eb1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101eb8:	31 d2                	xor    %edx,%edx
f0101eba:	31 c0                	xor    %eax,%eax
f0101ebc:	83 c4 0c             	add    $0xc,%esp
f0101ebf:	5e                   	pop    %esi
f0101ec0:	5f                   	pop    %edi
f0101ec1:	5d                   	pop    %ebp
f0101ec2:	c3                   	ret    
f0101ec3:	90                   	nop
f0101ec4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ec8:	89 f8                	mov    %edi,%eax
f0101eca:	f7 f1                	div    %ecx
f0101ecc:	31 d2                	xor    %edx,%edx
f0101ece:	83 c4 0c             	add    $0xc,%esp
f0101ed1:	5e                   	pop    %esi
f0101ed2:	5f                   	pop    %edi
f0101ed3:	5d                   	pop    %ebp
f0101ed4:	c3                   	ret    
f0101ed5:	8d 76 00             	lea    0x0(%esi),%esi
f0101ed8:	89 e9                	mov    %ebp,%ecx
f0101eda:	8b 3c 24             	mov    (%esp),%edi
f0101edd:	d3 e0                	shl    %cl,%eax
f0101edf:	89 c6                	mov    %eax,%esi
f0101ee1:	b8 20 00 00 00       	mov    $0x20,%eax
f0101ee6:	29 e8                	sub    %ebp,%eax
f0101ee8:	89 c1                	mov    %eax,%ecx
f0101eea:	d3 ef                	shr    %cl,%edi
f0101eec:	89 e9                	mov    %ebp,%ecx
f0101eee:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101ef2:	8b 3c 24             	mov    (%esp),%edi
f0101ef5:	09 74 24 08          	or     %esi,0x8(%esp)
f0101ef9:	89 d6                	mov    %edx,%esi
f0101efb:	d3 e7                	shl    %cl,%edi
f0101efd:	89 c1                	mov    %eax,%ecx
f0101eff:	89 3c 24             	mov    %edi,(%esp)
f0101f02:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101f06:	d3 ee                	shr    %cl,%esi
f0101f08:	89 e9                	mov    %ebp,%ecx
f0101f0a:	d3 e2                	shl    %cl,%edx
f0101f0c:	89 c1                	mov    %eax,%ecx
f0101f0e:	d3 ef                	shr    %cl,%edi
f0101f10:	09 d7                	or     %edx,%edi
f0101f12:	89 f2                	mov    %esi,%edx
f0101f14:	89 f8                	mov    %edi,%eax
f0101f16:	f7 74 24 08          	divl   0x8(%esp)
f0101f1a:	89 d6                	mov    %edx,%esi
f0101f1c:	89 c7                	mov    %eax,%edi
f0101f1e:	f7 24 24             	mull   (%esp)
f0101f21:	39 d6                	cmp    %edx,%esi
f0101f23:	89 14 24             	mov    %edx,(%esp)
f0101f26:	72 30                	jb     f0101f58 <__udivdi3+0x118>
f0101f28:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101f2c:	89 e9                	mov    %ebp,%ecx
f0101f2e:	d3 e2                	shl    %cl,%edx
f0101f30:	39 c2                	cmp    %eax,%edx
f0101f32:	73 05                	jae    f0101f39 <__udivdi3+0xf9>
f0101f34:	3b 34 24             	cmp    (%esp),%esi
f0101f37:	74 1f                	je     f0101f58 <__udivdi3+0x118>
f0101f39:	89 f8                	mov    %edi,%eax
f0101f3b:	31 d2                	xor    %edx,%edx
f0101f3d:	e9 7a ff ff ff       	jmp    f0101ebc <__udivdi3+0x7c>
f0101f42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101f48:	31 d2                	xor    %edx,%edx
f0101f4a:	b8 01 00 00 00       	mov    $0x1,%eax
f0101f4f:	e9 68 ff ff ff       	jmp    f0101ebc <__udivdi3+0x7c>
f0101f54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101f58:	8d 47 ff             	lea    -0x1(%edi),%eax
f0101f5b:	31 d2                	xor    %edx,%edx
f0101f5d:	83 c4 0c             	add    $0xc,%esp
f0101f60:	5e                   	pop    %esi
f0101f61:	5f                   	pop    %edi
f0101f62:	5d                   	pop    %ebp
f0101f63:	c3                   	ret    
f0101f64:	66 90                	xchg   %ax,%ax
f0101f66:	66 90                	xchg   %ax,%ax
f0101f68:	66 90                	xchg   %ax,%ax
f0101f6a:	66 90                	xchg   %ax,%ax
f0101f6c:	66 90                	xchg   %ax,%ax
f0101f6e:	66 90                	xchg   %ax,%ax

f0101f70 <__umoddi3>:
f0101f70:	55                   	push   %ebp
f0101f71:	57                   	push   %edi
f0101f72:	56                   	push   %esi
f0101f73:	83 ec 14             	sub    $0x14,%esp
f0101f76:	8b 44 24 28          	mov    0x28(%esp),%eax
f0101f7a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101f7e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101f82:	89 c7                	mov    %eax,%edi
f0101f84:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101f88:	8b 44 24 30          	mov    0x30(%esp),%eax
f0101f8c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101f90:	89 34 24             	mov    %esi,(%esp)
f0101f93:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101f97:	85 c0                	test   %eax,%eax
f0101f99:	89 c2                	mov    %eax,%edx
f0101f9b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101f9f:	75 17                	jne    f0101fb8 <__umoddi3+0x48>
f0101fa1:	39 fe                	cmp    %edi,%esi
f0101fa3:	76 4b                	jbe    f0101ff0 <__umoddi3+0x80>
f0101fa5:	89 c8                	mov    %ecx,%eax
f0101fa7:	89 fa                	mov    %edi,%edx
f0101fa9:	f7 f6                	div    %esi
f0101fab:	89 d0                	mov    %edx,%eax
f0101fad:	31 d2                	xor    %edx,%edx
f0101faf:	83 c4 14             	add    $0x14,%esp
f0101fb2:	5e                   	pop    %esi
f0101fb3:	5f                   	pop    %edi
f0101fb4:	5d                   	pop    %ebp
f0101fb5:	c3                   	ret    
f0101fb6:	66 90                	xchg   %ax,%ax
f0101fb8:	39 f8                	cmp    %edi,%eax
f0101fba:	77 54                	ja     f0102010 <__umoddi3+0xa0>
f0101fbc:	0f bd e8             	bsr    %eax,%ebp
f0101fbf:	83 f5 1f             	xor    $0x1f,%ebp
f0101fc2:	75 5c                	jne    f0102020 <__umoddi3+0xb0>
f0101fc4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101fc8:	39 3c 24             	cmp    %edi,(%esp)
f0101fcb:	0f 87 e7 00 00 00    	ja     f01020b8 <__umoddi3+0x148>
f0101fd1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101fd5:	29 f1                	sub    %esi,%ecx
f0101fd7:	19 c7                	sbb    %eax,%edi
f0101fd9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101fdd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101fe1:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101fe5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101fe9:	83 c4 14             	add    $0x14,%esp
f0101fec:	5e                   	pop    %esi
f0101fed:	5f                   	pop    %edi
f0101fee:	5d                   	pop    %ebp
f0101fef:	c3                   	ret    
f0101ff0:	85 f6                	test   %esi,%esi
f0101ff2:	89 f5                	mov    %esi,%ebp
f0101ff4:	75 0b                	jne    f0102001 <__umoddi3+0x91>
f0101ff6:	b8 01 00 00 00       	mov    $0x1,%eax
f0101ffb:	31 d2                	xor    %edx,%edx
f0101ffd:	f7 f6                	div    %esi
f0101fff:	89 c5                	mov    %eax,%ebp
f0102001:	8b 44 24 04          	mov    0x4(%esp),%eax
f0102005:	31 d2                	xor    %edx,%edx
f0102007:	f7 f5                	div    %ebp
f0102009:	89 c8                	mov    %ecx,%eax
f010200b:	f7 f5                	div    %ebp
f010200d:	eb 9c                	jmp    f0101fab <__umoddi3+0x3b>
f010200f:	90                   	nop
f0102010:	89 c8                	mov    %ecx,%eax
f0102012:	89 fa                	mov    %edi,%edx
f0102014:	83 c4 14             	add    $0x14,%esp
f0102017:	5e                   	pop    %esi
f0102018:	5f                   	pop    %edi
f0102019:	5d                   	pop    %ebp
f010201a:	c3                   	ret    
f010201b:	90                   	nop
f010201c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102020:	8b 04 24             	mov    (%esp),%eax
f0102023:	be 20 00 00 00       	mov    $0x20,%esi
f0102028:	89 e9                	mov    %ebp,%ecx
f010202a:	29 ee                	sub    %ebp,%esi
f010202c:	d3 e2                	shl    %cl,%edx
f010202e:	89 f1                	mov    %esi,%ecx
f0102030:	d3 e8                	shr    %cl,%eax
f0102032:	89 e9                	mov    %ebp,%ecx
f0102034:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102038:	8b 04 24             	mov    (%esp),%eax
f010203b:	09 54 24 04          	or     %edx,0x4(%esp)
f010203f:	89 fa                	mov    %edi,%edx
f0102041:	d3 e0                	shl    %cl,%eax
f0102043:	89 f1                	mov    %esi,%ecx
f0102045:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102049:	8b 44 24 10          	mov    0x10(%esp),%eax
f010204d:	d3 ea                	shr    %cl,%edx
f010204f:	89 e9                	mov    %ebp,%ecx
f0102051:	d3 e7                	shl    %cl,%edi
f0102053:	89 f1                	mov    %esi,%ecx
f0102055:	d3 e8                	shr    %cl,%eax
f0102057:	89 e9                	mov    %ebp,%ecx
f0102059:	09 f8                	or     %edi,%eax
f010205b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010205f:	f7 74 24 04          	divl   0x4(%esp)
f0102063:	d3 e7                	shl    %cl,%edi
f0102065:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102069:	89 d7                	mov    %edx,%edi
f010206b:	f7 64 24 08          	mull   0x8(%esp)
f010206f:	39 d7                	cmp    %edx,%edi
f0102071:	89 c1                	mov    %eax,%ecx
f0102073:	89 14 24             	mov    %edx,(%esp)
f0102076:	72 2c                	jb     f01020a4 <__umoddi3+0x134>
f0102078:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010207c:	72 22                	jb     f01020a0 <__umoddi3+0x130>
f010207e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0102082:	29 c8                	sub    %ecx,%eax
f0102084:	19 d7                	sbb    %edx,%edi
f0102086:	89 e9                	mov    %ebp,%ecx
f0102088:	89 fa                	mov    %edi,%edx
f010208a:	d3 e8                	shr    %cl,%eax
f010208c:	89 f1                	mov    %esi,%ecx
f010208e:	d3 e2                	shl    %cl,%edx
f0102090:	89 e9                	mov    %ebp,%ecx
f0102092:	d3 ef                	shr    %cl,%edi
f0102094:	09 d0                	or     %edx,%eax
f0102096:	89 fa                	mov    %edi,%edx
f0102098:	83 c4 14             	add    $0x14,%esp
f010209b:	5e                   	pop    %esi
f010209c:	5f                   	pop    %edi
f010209d:	5d                   	pop    %ebp
f010209e:	c3                   	ret    
f010209f:	90                   	nop
f01020a0:	39 d7                	cmp    %edx,%edi
f01020a2:	75 da                	jne    f010207e <__umoddi3+0x10e>
f01020a4:	8b 14 24             	mov    (%esp),%edx
f01020a7:	89 c1                	mov    %eax,%ecx
f01020a9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01020ad:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01020b1:	eb cb                	jmp    f010207e <__umoddi3+0x10e>
f01020b3:	90                   	nop
f01020b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01020b8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01020bc:	0f 82 0f ff ff ff    	jb     f0101fd1 <__umoddi3+0x61>
f01020c2:	e9 1a ff ff ff       	jmp    f0101fe1 <__umoddi3+0x71>
