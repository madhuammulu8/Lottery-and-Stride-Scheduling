
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8a013103          	ld	sp,-1888(sp) # 800088a0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	cac78793          	addi	a5,a5,-852 # 80005d10 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	440080e7          	jalr	1088(ra) # 8000256c <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f9e080e7          	jalr	-98(ra) # 80002172 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	306080e7          	jalr	774(ra) # 80002516 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	2d0080e7          	jalr	720(ra) # 800025c2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	eb8080e7          	jalr	-328(ra) # 800022fe <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	2a078793          	addi	a5,a5,672 # 80021718 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	a5e080e7          	jalr	-1442(ra) # 800022fe <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	846080e7          	jalr	-1978(ra) # 80002172 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	8e0080e7          	jalr	-1824(ra) # 800027b4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	e74080e7          	jalr	-396(ra) # 80005d50 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	086080e7          	jalr	134(ra) # 80001f6a <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	840080e7          	jalr	-1984(ra) # 8000278c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	860080e7          	jalr	-1952(ra) # 800027b4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	dde080e7          	jalr	-546(ra) # 80005d3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	dec080e7          	jalr	-532(ra) # 80005d50 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	fd0080e7          	jalr	-48(ra) # 80002f3c <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	660080e7          	jalr	1632(ra) # 800035d4 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	60a080e7          	jalr	1546(ra) # 80004586 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	eee080e7          	jalr	-274(ra) # 80005e72 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d02080e7          	jalr	-766(ra) # 80001c8e <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	c62a0a13          	addi	s4,s4,-926 # 800174d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	17848493          	addi	s1,s1,376
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00016997          	auipc	s3,0x16
    8000193e:	b9698993          	addi	s3,s3,-1130 # 800174d0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	878d                	srai	a5,a5,0x3
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	17848493          	addi	s1,s1,376
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first) {
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e507a783          	lw	a5,-432(a5) # 80008850 <first.1695>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	dc2080e7          	jalr	-574(ra) # 800027cc <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	e207ab23          	sw	zero,-458(a5) # 80008850 <first.1695>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	b30080e7          	jalr	-1232(ra) # 80003554 <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
allocpid() {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	86690913          	addi	s2,s2,-1946 # 800112a0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	e0c78793          	addi	a5,a5,-500 # 80008858 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	05893683          	ld	a3,88(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6e:	6d28                	ld	a0,88(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7e:	68a8                	ld	a0,80(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	64ac                	ld	a1,72(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b90:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b9c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc6:	00010497          	auipc	s1,0x10
    80001bca:	b0a48493          	addi	s1,s1,-1270 # 800116d0 <proc>
    80001bce:	00016917          	auipc	s2,0x16
    80001bd2:	90290913          	addi	s2,s2,-1790 # 800174d0 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001be0:	4c9c                	lw	a5,24(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bee:	17848493          	addi	s1,s1,376
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a8a1                	j	80001c50 <allocproc+0x96>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  p->tickets = 10;
    80001c08:	47a9                	li	a5,10
    80001c0a:	16f4a423          	sw	a5,360(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	ee6080e7          	jalr	-282(ra) # 80000af4 <kalloc>
    80001c16:	892a                	mv	s2,a0
    80001c18:	eca8                	sd	a0,88(s1)
    80001c1a:	c131                	beqz	a0,80001c5e <allocproc+0xa4>
  p->pagetable = proc_pagetable(p);
    80001c1c:	8526                	mv	a0,s1
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	e56080e7          	jalr	-426(ra) # 80001a74 <proc_pagetable>
    80001c26:	892a                	mv	s2,a0
    80001c28:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c2a:	c531                	beqz	a0,80001c76 <allocproc+0xbc>
  memset(&p->context, 0, sizeof(p->context));
    80001c2c:	07000613          	li	a2,112
    80001c30:	4581                	li	a1,0
    80001c32:	06048513          	addi	a0,s1,96
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	0aa080e7          	jalr	170(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c3e:	00000797          	auipc	a5,0x0
    80001c42:	daa78793          	addi	a5,a5,-598 # 800019e8 <forkret>
    80001c46:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c48:	60bc                	ld	a5,64(s1)
    80001c4a:	6705                	lui	a4,0x1
    80001c4c:	97ba                	add	a5,a5,a4
    80001c4e:	f4bc                	sd	a5,104(s1)
}
    80001c50:	8526                	mv	a0,s1
    80001c52:	60e2                	ld	ra,24(sp)
    80001c54:	6442                	ld	s0,16(sp)
    80001c56:	64a2                	ld	s1,8(sp)
    80001c58:	6902                	ld	s2,0(sp)
    80001c5a:	6105                	addi	sp,sp,32
    80001c5c:	8082                	ret
    freeproc(p);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	00000097          	auipc	ra,0x0
    80001c64:	f02080e7          	jalr	-254(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	02e080e7          	jalr	46(ra) # 80000c98 <release>
    return 0;
    80001c72:	84ca                	mv	s1,s2
    80001c74:	bff1                	j	80001c50 <allocproc+0x96>
    freeproc(p);
    80001c76:	8526                	mv	a0,s1
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	eea080e7          	jalr	-278(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c80:	8526                	mv	a0,s1
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	016080e7          	jalr	22(ra) # 80000c98 <release>
    return 0;
    80001c8a:	84ca                	mv	s1,s2
    80001c8c:	b7d1                	j	80001c50 <allocproc+0x96>

0000000080001c8e <userinit>:
{
    80001c8e:	1101                	addi	sp,sp,-32
    80001c90:	ec06                	sd	ra,24(sp)
    80001c92:	e822                	sd	s0,16(sp)
    80001c94:	e426                	sd	s1,8(sp)
    80001c96:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c98:	00000097          	auipc	ra,0x0
    80001c9c:	f22080e7          	jalr	-222(ra) # 80001bba <allocproc>
    80001ca0:	84aa                	mv	s1,a0
  initproc = p;
    80001ca2:	00007797          	auipc	a5,0x7
    80001ca6:	38a7b723          	sd	a0,910(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001caa:	03400613          	li	a2,52
    80001cae:	00007597          	auipc	a1,0x7
    80001cb2:	bb258593          	addi	a1,a1,-1102 # 80008860 <initcode>
    80001cb6:	6928                	ld	a0,80(a0)
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	6b0080e7          	jalr	1712(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cc0:	6785                	lui	a5,0x1
    80001cc2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cc4:	6cb8                	ld	a4,88(s1)
    80001cc6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cca:	6cb8                	ld	a4,88(s1)
    80001ccc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cce:	4641                	li	a2,16
    80001cd0:	00006597          	auipc	a1,0x6
    80001cd4:	53058593          	addi	a1,a1,1328 # 80008200 <digits+0x1c0>
    80001cd8:	15848513          	addi	a0,s1,344
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	156080e7          	jalr	342(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001ce4:	00006517          	auipc	a0,0x6
    80001ce8:	52c50513          	addi	a0,a0,1324 # 80008210 <digits+0x1d0>
    80001cec:	00002097          	auipc	ra,0x2
    80001cf0:	296080e7          	jalr	662(ra) # 80003f82 <namei>
    80001cf4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cf8:	478d                	li	a5,3
    80001cfa:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cfc:	8526                	mv	a0,s1
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	f9a080e7          	jalr	-102(ra) # 80000c98 <release>
}
    80001d06:	60e2                	ld	ra,24(sp)
    80001d08:	6442                	ld	s0,16(sp)
    80001d0a:	64a2                	ld	s1,8(sp)
    80001d0c:	6105                	addi	sp,sp,32
    80001d0e:	8082                	ret

0000000080001d10 <growproc>:
{
    80001d10:	1101                	addi	sp,sp,-32
    80001d12:	ec06                	sd	ra,24(sp)
    80001d14:	e822                	sd	s0,16(sp)
    80001d16:	e426                	sd	s1,8(sp)
    80001d18:	e04a                	sd	s2,0(sp)
    80001d1a:	1000                	addi	s0,sp,32
    80001d1c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d1e:	00000097          	auipc	ra,0x0
    80001d22:	c92080e7          	jalr	-878(ra) # 800019b0 <myproc>
    80001d26:	892a                	mv	s2,a0
  sz = p->sz;
    80001d28:	652c                	ld	a1,72(a0)
    80001d2a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d2e:	00904f63          	bgtz	s1,80001d4c <growproc+0x3c>
  } else if(n < 0){
    80001d32:	0204cc63          	bltz	s1,80001d6a <growproc+0x5a>
  p->sz = sz;
    80001d36:	1602                	slli	a2,a2,0x20
    80001d38:	9201                	srli	a2,a2,0x20
    80001d3a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d3e:	4501                	li	a0,0
}
    80001d40:	60e2                	ld	ra,24(sp)
    80001d42:	6442                	ld	s0,16(sp)
    80001d44:	64a2                	ld	s1,8(sp)
    80001d46:	6902                	ld	s2,0(sp)
    80001d48:	6105                	addi	sp,sp,32
    80001d4a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d4c:	9e25                	addw	a2,a2,s1
    80001d4e:	1602                	slli	a2,a2,0x20
    80001d50:	9201                	srli	a2,a2,0x20
    80001d52:	1582                	slli	a1,a1,0x20
    80001d54:	9181                	srli	a1,a1,0x20
    80001d56:	6928                	ld	a0,80(a0)
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	6ca080e7          	jalr	1738(ra) # 80001422 <uvmalloc>
    80001d60:	0005061b          	sext.w	a2,a0
    80001d64:	fa69                	bnez	a2,80001d36 <growproc+0x26>
      return -1;
    80001d66:	557d                	li	a0,-1
    80001d68:	bfe1                	j	80001d40 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d6a:	9e25                	addw	a2,a2,s1
    80001d6c:	1602                	slli	a2,a2,0x20
    80001d6e:	9201                	srli	a2,a2,0x20
    80001d70:	1582                	slli	a1,a1,0x20
    80001d72:	9181                	srli	a1,a1,0x20
    80001d74:	6928                	ld	a0,80(a0)
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	664080e7          	jalr	1636(ra) # 800013da <uvmdealloc>
    80001d7e:	0005061b          	sext.w	a2,a0
    80001d82:	bf55                	j	80001d36 <growproc+0x26>

0000000080001d84 <fork>:
{
    80001d84:	7179                	addi	sp,sp,-48
    80001d86:	f406                	sd	ra,40(sp)
    80001d88:	f022                	sd	s0,32(sp)
    80001d8a:	ec26                	sd	s1,24(sp)
    80001d8c:	e84a                	sd	s2,16(sp)
    80001d8e:	e44e                	sd	s3,8(sp)
    80001d90:	e052                	sd	s4,0(sp)
    80001d92:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d94:	00000097          	auipc	ra,0x0
    80001d98:	c1c080e7          	jalr	-996(ra) # 800019b0 <myproc>
    80001d9c:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d9e:	00000097          	auipc	ra,0x0
    80001da2:	e1c080e7          	jalr	-484(ra) # 80001bba <allocproc>
    80001da6:	10050b63          	beqz	a0,80001ebc <fork+0x138>
    80001daa:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dac:	04893603          	ld	a2,72(s2)
    80001db0:	692c                	ld	a1,80(a0)
    80001db2:	05093503          	ld	a0,80(s2)
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	7b8080e7          	jalr	1976(ra) # 8000156e <uvmcopy>
    80001dbe:	04054663          	bltz	a0,80001e0a <fork+0x86>
  np->sz = p->sz;
    80001dc2:	04893783          	ld	a5,72(s2)
    80001dc6:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dca:	05893683          	ld	a3,88(s2)
    80001dce:	87b6                	mv	a5,a3
    80001dd0:	0589b703          	ld	a4,88(s3)
    80001dd4:	12068693          	addi	a3,a3,288
    80001dd8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ddc:	6788                	ld	a0,8(a5)
    80001dde:	6b8c                	ld	a1,16(a5)
    80001de0:	6f90                	ld	a2,24(a5)
    80001de2:	01073023          	sd	a6,0(a4)
    80001de6:	e708                	sd	a0,8(a4)
    80001de8:	eb0c                	sd	a1,16(a4)
    80001dea:	ef10                	sd	a2,24(a4)
    80001dec:	02078793          	addi	a5,a5,32
    80001df0:	02070713          	addi	a4,a4,32
    80001df4:	fed792e3          	bne	a5,a3,80001dd8 <fork+0x54>
  np->trapframe->a0 = 0;
    80001df8:	0589b783          	ld	a5,88(s3)
    80001dfc:	0607b823          	sd	zero,112(a5)
    80001e00:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e04:	15000a13          	li	s4,336
    80001e08:	a03d                	j	80001e36 <fork+0xb2>
    freeproc(np);
    80001e0a:	854e                	mv	a0,s3
    80001e0c:	00000097          	auipc	ra,0x0
    80001e10:	d56080e7          	jalr	-682(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e14:	854e                	mv	a0,s3
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	e82080e7          	jalr	-382(ra) # 80000c98 <release>
    return -1;
    80001e1e:	5a7d                	li	s4,-1
    80001e20:	a069                	j	80001eaa <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e22:	00002097          	auipc	ra,0x2
    80001e26:	7f6080e7          	jalr	2038(ra) # 80004618 <filedup>
    80001e2a:	009987b3          	add	a5,s3,s1
    80001e2e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e30:	04a1                	addi	s1,s1,8
    80001e32:	01448763          	beq	s1,s4,80001e40 <fork+0xbc>
    if(p->ofile[i])
    80001e36:	009907b3          	add	a5,s2,s1
    80001e3a:	6388                	ld	a0,0(a5)
    80001e3c:	f17d                	bnez	a0,80001e22 <fork+0x9e>
    80001e3e:	bfcd                	j	80001e30 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e40:	15093503          	ld	a0,336(s2)
    80001e44:	00002097          	auipc	ra,0x2
    80001e48:	94a080e7          	jalr	-1718(ra) # 8000378e <idup>
    80001e4c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e50:	4641                	li	a2,16
    80001e52:	15890593          	addi	a1,s2,344
    80001e56:	15898513          	addi	a0,s3,344
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	fd8080e7          	jalr	-40(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e62:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e66:	854e                	mv	a0,s3
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e30080e7          	jalr	-464(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e70:	0000f497          	auipc	s1,0xf
    80001e74:	44848493          	addi	s1,s1,1096 # 800112b8 <wait_lock>
    80001e78:	8526                	mv	a0,s1
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	d6a080e7          	jalr	-662(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e82:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	e10080e7          	jalr	-496(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001e90:	854e                	mv	a0,s3
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	d52080e7          	jalr	-686(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001e9a:	478d                	li	a5,3
    80001e9c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ea0:	854e                	mv	a0,s3
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	df6080e7          	jalr	-522(ra) # 80000c98 <release>
}
    80001eaa:	8552                	mv	a0,s4
    80001eac:	70a2                	ld	ra,40(sp)
    80001eae:	7402                	ld	s0,32(sp)
    80001eb0:	64e2                	ld	s1,24(sp)
    80001eb2:	6942                	ld	s2,16(sp)
    80001eb4:	69a2                	ld	s3,8(sp)
    80001eb6:	6a02                	ld	s4,0(sp)
    80001eb8:	6145                	addi	sp,sp,48
    80001eba:	8082                	ret
    return -1;
    80001ebc:	5a7d                	li	s4,-1
    80001ebe:	b7f5                	j	80001eaa <fork+0x126>

0000000080001ec0 <total_tickets_value>:
    int total_tickets_value(){
    80001ec0:	7179                	addi	sp,sp,-48
    80001ec2:	f406                	sd	ra,40(sp)
    80001ec4:	f022                	sd	s0,32(sp)
    80001ec6:	ec26                	sd	s1,24(sp)
    80001ec8:	e84a                	sd	s2,16(sp)
    80001eca:	e44e                	sd	s3,8(sp)
    80001ecc:	e052                	sd	s4,0(sp)
    80001ece:	1800                	addi	s0,sp,48
      int totaltickets = 0;
    80001ed0:	4a01                	li	s4,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ed2:	0000f497          	auipc	s1,0xf
    80001ed6:	7fe48493          	addi	s1,s1,2046 # 800116d0 <proc>
      if(p->state == RUNNABLE) {
    80001eda:	498d                	li	s3,3
    for(p = proc; p < &proc[NPROC]; p++) {
    80001edc:	00015917          	auipc	s2,0x15
    80001ee0:	5f490913          	addi	s2,s2,1524 # 800174d0 <tickslock>
    80001ee4:	a811                	j	80001ef8 <total_tickets_value+0x38>
      release(&p->lock);
    80001ee6:	8526                	mv	a0,s1
    80001ee8:	fffff097          	auipc	ra,0xfffff
    80001eec:	db0080e7          	jalr	-592(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ef0:	17848493          	addi	s1,s1,376
    80001ef4:	01248f63          	beq	s1,s2,80001f12 <total_tickets_value+0x52>
      acquire(&p->lock);
    80001ef8:	8526                	mv	a0,s1
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	cea080e7          	jalr	-790(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001f02:	4c9c                	lw	a5,24(s1)
    80001f04:	ff3791e3          	bne	a5,s3,80001ee6 <total_tickets_value+0x26>
        totaltickets += p->tickets;
    80001f08:	1684a783          	lw	a5,360(s1)
    80001f0c:	01478a3b          	addw	s4,a5,s4
    80001f10:	bfd9                	j	80001ee6 <total_tickets_value+0x26>
    }
    80001f12:	8552                	mv	a0,s4
    80001f14:	70a2                	ld	ra,40(sp)
    80001f16:	7402                	ld	s0,32(sp)
    80001f18:	64e2                	ld	s1,24(sp)
    80001f1a:	6942                	ld	s2,16(sp)
    80001f1c:	69a2                	ld	s3,8(sp)
    80001f1e:	6a02                	ld	s4,0(sp)
    80001f20:	6145                	addi	sp,sp,48
    80001f22:	8082                	ret

0000000080001f24 <rand_generator>:
{ 
    80001f24:	1141                	addi	sp,sp,-16
    80001f26:	e422                	sd	s0,8(sp)
    80001f28:	0800                	addi	s0,sp,16
  bit = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5)) & 1; 
    80001f2a:	00007717          	auipc	a4,0x7
    80001f2e:	92a70713          	addi	a4,a4,-1750 # 80008854 <lfsr>
    80001f32:	00075503          	lhu	a0,0(a4)
    80001f36:	0025579b          	srliw	a5,a0,0x2
    80001f3a:	0035569b          	srliw	a3,a0,0x3
    80001f3e:	8fb5                	xor	a5,a5,a3
    80001f40:	8fa9                	xor	a5,a5,a0
    80001f42:	0055569b          	srliw	a3,a0,0x5
    80001f46:	8fb5                	xor	a5,a5,a3
    80001f48:	8b85                	andi	a5,a5,1
    80001f4a:	00007697          	auipc	a3,0x7
    80001f4e:	0cf69f23          	sh	a5,222(a3) # 80009028 <bit>
  return lfsr = (lfsr >> 1) | (bit << 15); 
    80001f52:	0015551b          	srliw	a0,a0,0x1
    80001f56:	00f7979b          	slliw	a5,a5,0xf
    80001f5a:	8d5d                	or	a0,a0,a5
    80001f5c:	1542                	slli	a0,a0,0x30
    80001f5e:	9141                	srli	a0,a0,0x30
    80001f60:	00a71023          	sh	a0,0(a4)
} 
    80001f64:	6422                	ld	s0,8(sp)
    80001f66:	0141                	addi	sp,sp,16
    80001f68:	8082                	ret

0000000080001f6a <scheduler>:
{
    80001f6a:	711d                	addi	sp,sp,-96
    80001f6c:	ec86                	sd	ra,88(sp)
    80001f6e:	e8a2                	sd	s0,80(sp)
    80001f70:	e4a6                	sd	s1,72(sp)
    80001f72:	e0ca                	sd	s2,64(sp)
    80001f74:	fc4e                	sd	s3,56(sp)
    80001f76:	f852                	sd	s4,48(sp)
    80001f78:	f456                	sd	s5,40(sp)
    80001f7a:	f05a                	sd	s6,32(sp)
    80001f7c:	ec5e                	sd	s7,24(sp)
    80001f7e:	e862                	sd	s8,16(sp)
    80001f80:	e466                	sd	s9,8(sp)
    80001f82:	1080                	addi	s0,sp,96
    80001f84:	8792                	mv	a5,tp
  int id = r_tp();
    80001f86:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f88:	00779c13          	slli	s8,a5,0x7
    80001f8c:	0000f717          	auipc	a4,0xf
    80001f90:	31470713          	addi	a4,a4,788 # 800112a0 <pid_lock>
    80001f94:	9762                	add	a4,a4,s8
    80001f96:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f9a:	0000f717          	auipc	a4,0xf
    80001f9e:	33e70713          	addi	a4,a4,830 # 800112d8 <cpus+0x8>
    80001fa2:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80001fa4:	4a0d                	li	s4,3
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fa6:	00015b17          	auipc	s6,0x15
    80001faa:	52ab0b13          	addi	s6,s6,1322 # 800174d0 <tickslock>
    int temp =0;
    80001fae:	4b81                	li	s7,0
        p->state = RUNNING;
    80001fb0:	4c91                	li	s9,4
        c->proc = p;
    80001fb2:	079e                	slli	a5,a5,0x7
    80001fb4:	0000fa97          	auipc	s5,0xf
    80001fb8:	2eca8a93          	addi	s5,s5,748 # 800112a0 <pid_lock>
    80001fbc:	9abe                	add	s5,s5,a5
    80001fbe:	a0ad                	j	80002028 <scheduler+0xbe>
          release(&p->lock);
    80001fc0:	8526                	mv	a0,s1
    80001fc2:	fffff097          	auipc	ra,0xfffff
    80001fc6:	cd6080e7          	jalr	-810(ra) # 80000c98 <release>
          continue;
    80001fca:	a031                	j	80001fd6 <scheduler+0x6c>
      release(&p->lock);
    80001fcc:	8526                	mv	a0,s1
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	cca080e7          	jalr	-822(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fd6:	17848493          	addi	s1,s1,376
    80001fda:	05648763          	beq	s1,s6,80002028 <scheduler+0xbe>
      acquire(&p->lock);
    80001fde:	8526                	mv	a0,s1
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	c04080e7          	jalr	-1020(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001fe8:	4c9c                	lw	a5,24(s1)
    80001fea:	ff4791e3          	bne	a5,s4,80001fcc <scheduler+0x62>
        temp += p->tickets;
    80001fee:	1684a783          	lw	a5,360(s1)
    80001ff2:	0127893b          	addw	s2,a5,s2
        if(temp < lottery) {
    80001ff6:	fd3945e3          	blt	s2,s3,80001fc0 <scheduler+0x56>
        p->state = RUNNING;
    80001ffa:	0194ac23          	sw	s9,24(s1)
        c->proc = p;
    80001ffe:	029ab823          	sd	s1,48(s5)
        p->tickscount += 1;
    80002002:	16c4a783          	lw	a5,364(s1)
    80002006:	2785                	addiw	a5,a5,1
    80002008:	16f4a623          	sw	a5,364(s1)
        swtch(&c->context, &p->context);
    8000200c:	06048593          	addi	a1,s1,96
    80002010:	8562                	mv	a0,s8
    80002012:	00000097          	auipc	ra,0x0
    80002016:	710080e7          	jalr	1808(ra) # 80002722 <swtch>
        c->proc = 0;
    8000201a:	020ab823          	sd	zero,48(s5)
        release(&p->lock);
    8000201e:	8526                	mv	a0,s1
    80002020:	fffff097          	auipc	ra,0xfffff
    80002024:	c78080e7          	jalr	-904(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002028:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000202c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002030:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002034:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002038:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000203c:	10079073          	csrw	sstatus,a5
    int ticket_count = total_tickets_value();
    80002040:	00000097          	auipc	ra,0x0
    80002044:	e80080e7          	jalr	-384(ra) # 80001ec0 <total_tickets_value>
    int lottery = rand_generator(ticket_count);
    80002048:	00000097          	auipc	ra,0x0
    8000204c:	edc080e7          	jalr	-292(ra) # 80001f24 <rand_generator>
    80002050:	0005099b          	sext.w	s3,a0
    int temp =0;
    80002054:	895e                	mv	s2,s7
    for(p = proc; p < &proc[NPROC]; p++) {
    80002056:	0000f497          	auipc	s1,0xf
    8000205a:	67a48493          	addi	s1,s1,1658 # 800116d0 <proc>
    8000205e:	b741                	j	80001fde <scheduler+0x74>

0000000080002060 <sched>:
{
    80002060:	7179                	addi	sp,sp,-48
    80002062:	f406                	sd	ra,40(sp)
    80002064:	f022                	sd	s0,32(sp)
    80002066:	ec26                	sd	s1,24(sp)
    80002068:	e84a                	sd	s2,16(sp)
    8000206a:	e44e                	sd	s3,8(sp)
    8000206c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	942080e7          	jalr	-1726(ra) # 800019b0 <myproc>
    80002076:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	af2080e7          	jalr	-1294(ra) # 80000b6a <holding>
    80002080:	c93d                	beqz	a0,800020f6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002082:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002084:	2781                	sext.w	a5,a5
    80002086:	079e                	slli	a5,a5,0x7
    80002088:	0000f717          	auipc	a4,0xf
    8000208c:	21870713          	addi	a4,a4,536 # 800112a0 <pid_lock>
    80002090:	97ba                	add	a5,a5,a4
    80002092:	0a87a703          	lw	a4,168(a5)
    80002096:	4785                	li	a5,1
    80002098:	06f71763          	bne	a4,a5,80002106 <sched+0xa6>
  if(p->state == RUNNING)
    8000209c:	4c98                	lw	a4,24(s1)
    8000209e:	4791                	li	a5,4
    800020a0:	06f70b63          	beq	a4,a5,80002116 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020a4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020a8:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020aa:	efb5                	bnez	a5,80002126 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ac:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020ae:	0000f917          	auipc	s2,0xf
    800020b2:	1f290913          	addi	s2,s2,498 # 800112a0 <pid_lock>
    800020b6:	2781                	sext.w	a5,a5
    800020b8:	079e                	slli	a5,a5,0x7
    800020ba:	97ca                	add	a5,a5,s2
    800020bc:	0ac7a983          	lw	s3,172(a5)
    800020c0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020c2:	2781                	sext.w	a5,a5
    800020c4:	079e                	slli	a5,a5,0x7
    800020c6:	0000f597          	auipc	a1,0xf
    800020ca:	21258593          	addi	a1,a1,530 # 800112d8 <cpus+0x8>
    800020ce:	95be                	add	a1,a1,a5
    800020d0:	06048513          	addi	a0,s1,96
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	64e080e7          	jalr	1614(ra) # 80002722 <swtch>
    800020dc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020de:	2781                	sext.w	a5,a5
    800020e0:	079e                	slli	a5,a5,0x7
    800020e2:	97ca                	add	a5,a5,s2
    800020e4:	0b37a623          	sw	s3,172(a5)
}
    800020e8:	70a2                	ld	ra,40(sp)
    800020ea:	7402                	ld	s0,32(sp)
    800020ec:	64e2                	ld	s1,24(sp)
    800020ee:	6942                	ld	s2,16(sp)
    800020f0:	69a2                	ld	s3,8(sp)
    800020f2:	6145                	addi	sp,sp,48
    800020f4:	8082                	ret
    panic("sched p->lock");
    800020f6:	00006517          	auipc	a0,0x6
    800020fa:	12250513          	addi	a0,a0,290 # 80008218 <digits+0x1d8>
    800020fe:	ffffe097          	auipc	ra,0xffffe
    80002102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    panic("sched locks");
    80002106:	00006517          	auipc	a0,0x6
    8000210a:	12250513          	addi	a0,a0,290 # 80008228 <digits+0x1e8>
    8000210e:	ffffe097          	auipc	ra,0xffffe
    80002112:	430080e7          	jalr	1072(ra) # 8000053e <panic>
    panic("sched running");
    80002116:	00006517          	auipc	a0,0x6
    8000211a:	12250513          	addi	a0,a0,290 # 80008238 <digits+0x1f8>
    8000211e:	ffffe097          	auipc	ra,0xffffe
    80002122:	420080e7          	jalr	1056(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002126:	00006517          	auipc	a0,0x6
    8000212a:	12250513          	addi	a0,a0,290 # 80008248 <digits+0x208>
    8000212e:	ffffe097          	auipc	ra,0xffffe
    80002132:	410080e7          	jalr	1040(ra) # 8000053e <panic>

0000000080002136 <yield>:
{
    80002136:	1101                	addi	sp,sp,-32
    80002138:	ec06                	sd	ra,24(sp)
    8000213a:	e822                	sd	s0,16(sp)
    8000213c:	e426                	sd	s1,8(sp)
    8000213e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002140:	00000097          	auipc	ra,0x0
    80002144:	870080e7          	jalr	-1936(ra) # 800019b0 <myproc>
    80002148:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	a9a080e7          	jalr	-1382(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002152:	478d                	li	a5,3
    80002154:	cc9c                	sw	a5,24(s1)
  sched();
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	f0a080e7          	jalr	-246(ra) # 80002060 <sched>
  release(&p->lock);
    8000215e:	8526                	mv	a0,s1
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	b38080e7          	jalr	-1224(ra) # 80000c98 <release>
}
    80002168:	60e2                	ld	ra,24(sp)
    8000216a:	6442                	ld	s0,16(sp)
    8000216c:	64a2                	ld	s1,8(sp)
    8000216e:	6105                	addi	sp,sp,32
    80002170:	8082                	ret

0000000080002172 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002172:	7179                	addi	sp,sp,-48
    80002174:	f406                	sd	ra,40(sp)
    80002176:	f022                	sd	s0,32(sp)
    80002178:	ec26                	sd	s1,24(sp)
    8000217a:	e84a                	sd	s2,16(sp)
    8000217c:	e44e                	sd	s3,8(sp)
    8000217e:	1800                	addi	s0,sp,48
    80002180:	89aa                	mv	s3,a0
    80002182:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002184:	00000097          	auipc	ra,0x0
    80002188:	82c080e7          	jalr	-2004(ra) # 800019b0 <myproc>
    8000218c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	a56080e7          	jalr	-1450(ra) # 80000be4 <acquire>
  release(lk);
    80002196:	854a                	mv	a0,s2
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	b00080e7          	jalr	-1280(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800021a0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021a4:	4789                	li	a5,2
    800021a6:	cc9c                	sw	a5,24(s1)

  sched();
    800021a8:	00000097          	auipc	ra,0x0
    800021ac:	eb8080e7          	jalr	-328(ra) # 80002060 <sched>

  // Tidy up.
  p->chan = 0;
    800021b0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021b4:	8526                	mv	a0,s1
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	ae2080e7          	jalr	-1310(ra) # 80000c98 <release>
  acquire(lk);
    800021be:	854a                	mv	a0,s2
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	a24080e7          	jalr	-1500(ra) # 80000be4 <acquire>
}
    800021c8:	70a2                	ld	ra,40(sp)
    800021ca:	7402                	ld	s0,32(sp)
    800021cc:	64e2                	ld	s1,24(sp)
    800021ce:	6942                	ld	s2,16(sp)
    800021d0:	69a2                	ld	s3,8(sp)
    800021d2:	6145                	addi	sp,sp,48
    800021d4:	8082                	ret

00000000800021d6 <wait>:
{
    800021d6:	715d                	addi	sp,sp,-80
    800021d8:	e486                	sd	ra,72(sp)
    800021da:	e0a2                	sd	s0,64(sp)
    800021dc:	fc26                	sd	s1,56(sp)
    800021de:	f84a                	sd	s2,48(sp)
    800021e0:	f44e                	sd	s3,40(sp)
    800021e2:	f052                	sd	s4,32(sp)
    800021e4:	ec56                	sd	s5,24(sp)
    800021e6:	e85a                	sd	s6,16(sp)
    800021e8:	e45e                	sd	s7,8(sp)
    800021ea:	e062                	sd	s8,0(sp)
    800021ec:	0880                	addi	s0,sp,80
    800021ee:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	7c0080e7          	jalr	1984(ra) # 800019b0 <myproc>
    800021f8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021fa:	0000f517          	auipc	a0,0xf
    800021fe:	0be50513          	addi	a0,a0,190 # 800112b8 <wait_lock>
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	9e2080e7          	jalr	-1566(ra) # 80000be4 <acquire>
    havekids = 0;
    8000220a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000220c:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000220e:	00015997          	auipc	s3,0x15
    80002212:	2c298993          	addi	s3,s3,706 # 800174d0 <tickslock>
        havekids = 1;
    80002216:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002218:	0000fc17          	auipc	s8,0xf
    8000221c:	0a0c0c13          	addi	s8,s8,160 # 800112b8 <wait_lock>
    havekids = 0;
    80002220:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002222:	0000f497          	auipc	s1,0xf
    80002226:	4ae48493          	addi	s1,s1,1198 # 800116d0 <proc>
    8000222a:	a0bd                	j	80002298 <wait+0xc2>
          pid = np->pid;
    8000222c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002230:	000b0e63          	beqz	s6,8000224c <wait+0x76>
    80002234:	4691                	li	a3,4
    80002236:	02c48613          	addi	a2,s1,44
    8000223a:	85da                	mv	a1,s6
    8000223c:	05093503          	ld	a0,80(s2)
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	432080e7          	jalr	1074(ra) # 80001672 <copyout>
    80002248:	02054563          	bltz	a0,80002272 <wait+0x9c>
          freeproc(np);
    8000224c:	8526                	mv	a0,s1
    8000224e:	00000097          	auipc	ra,0x0
    80002252:	914080e7          	jalr	-1772(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002256:	8526                	mv	a0,s1
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	a40080e7          	jalr	-1472(ra) # 80000c98 <release>
          release(&wait_lock);
    80002260:	0000f517          	auipc	a0,0xf
    80002264:	05850513          	addi	a0,a0,88 # 800112b8 <wait_lock>
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	a30080e7          	jalr	-1488(ra) # 80000c98 <release>
          return pid;
    80002270:	a09d                	j	800022d6 <wait+0x100>
            release(&np->lock);
    80002272:	8526                	mv	a0,s1
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	a24080e7          	jalr	-1500(ra) # 80000c98 <release>
            release(&wait_lock);
    8000227c:	0000f517          	auipc	a0,0xf
    80002280:	03c50513          	addi	a0,a0,60 # 800112b8 <wait_lock>
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	a14080e7          	jalr	-1516(ra) # 80000c98 <release>
            return -1;
    8000228c:	59fd                	li	s3,-1
    8000228e:	a0a1                	j	800022d6 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002290:	17848493          	addi	s1,s1,376
    80002294:	03348463          	beq	s1,s3,800022bc <wait+0xe6>
      if(np->parent == p){
    80002298:	7c9c                	ld	a5,56(s1)
    8000229a:	ff279be3          	bne	a5,s2,80002290 <wait+0xba>
        acquire(&np->lock);
    8000229e:	8526                	mv	a0,s1
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	944080e7          	jalr	-1724(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800022a8:	4c9c                	lw	a5,24(s1)
    800022aa:	f94781e3          	beq	a5,s4,8000222c <wait+0x56>
        release(&np->lock);
    800022ae:	8526                	mv	a0,s1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	9e8080e7          	jalr	-1560(ra) # 80000c98 <release>
        havekids = 1;
    800022b8:	8756                	mv	a4,s5
    800022ba:	bfd9                	j	80002290 <wait+0xba>
    if(!havekids || p->killed){
    800022bc:	c701                	beqz	a4,800022c4 <wait+0xee>
    800022be:	02892783          	lw	a5,40(s2)
    800022c2:	c79d                	beqz	a5,800022f0 <wait+0x11a>
      release(&wait_lock);
    800022c4:	0000f517          	auipc	a0,0xf
    800022c8:	ff450513          	addi	a0,a0,-12 # 800112b8 <wait_lock>
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	9cc080e7          	jalr	-1588(ra) # 80000c98 <release>
      return -1;
    800022d4:	59fd                	li	s3,-1
}
    800022d6:	854e                	mv	a0,s3
    800022d8:	60a6                	ld	ra,72(sp)
    800022da:	6406                	ld	s0,64(sp)
    800022dc:	74e2                	ld	s1,56(sp)
    800022de:	7942                	ld	s2,48(sp)
    800022e0:	79a2                	ld	s3,40(sp)
    800022e2:	7a02                	ld	s4,32(sp)
    800022e4:	6ae2                	ld	s5,24(sp)
    800022e6:	6b42                	ld	s6,16(sp)
    800022e8:	6ba2                	ld	s7,8(sp)
    800022ea:	6c02                	ld	s8,0(sp)
    800022ec:	6161                	addi	sp,sp,80
    800022ee:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022f0:	85e2                	mv	a1,s8
    800022f2:	854a                	mv	a0,s2
    800022f4:	00000097          	auipc	ra,0x0
    800022f8:	e7e080e7          	jalr	-386(ra) # 80002172 <sleep>
    havekids = 0;
    800022fc:	b715                	j	80002220 <wait+0x4a>

00000000800022fe <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800022fe:	7139                	addi	sp,sp,-64
    80002300:	fc06                	sd	ra,56(sp)
    80002302:	f822                	sd	s0,48(sp)
    80002304:	f426                	sd	s1,40(sp)
    80002306:	f04a                	sd	s2,32(sp)
    80002308:	ec4e                	sd	s3,24(sp)
    8000230a:	e852                	sd	s4,16(sp)
    8000230c:	e456                	sd	s5,8(sp)
    8000230e:	0080                	addi	s0,sp,64
    80002310:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002312:	0000f497          	auipc	s1,0xf
    80002316:	3be48493          	addi	s1,s1,958 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000231a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000231c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000231e:	00015917          	auipc	s2,0x15
    80002322:	1b290913          	addi	s2,s2,434 # 800174d0 <tickslock>
    80002326:	a821                	j	8000233e <wakeup+0x40>
        p->state = RUNNABLE;
    80002328:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000232c:	8526                	mv	a0,s1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	96a080e7          	jalr	-1686(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002336:	17848493          	addi	s1,s1,376
    8000233a:	03248463          	beq	s1,s2,80002362 <wakeup+0x64>
    if(p != myproc()){
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	672080e7          	jalr	1650(ra) # 800019b0 <myproc>
    80002346:	fea488e3          	beq	s1,a0,80002336 <wakeup+0x38>
      acquire(&p->lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	898080e7          	jalr	-1896(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002354:	4c9c                	lw	a5,24(s1)
    80002356:	fd379be3          	bne	a5,s3,8000232c <wakeup+0x2e>
    8000235a:	709c                	ld	a5,32(s1)
    8000235c:	fd4798e3          	bne	a5,s4,8000232c <wakeup+0x2e>
    80002360:	b7e1                	j	80002328 <wakeup+0x2a>
    }
  }
}
    80002362:	70e2                	ld	ra,56(sp)
    80002364:	7442                	ld	s0,48(sp)
    80002366:	74a2                	ld	s1,40(sp)
    80002368:	7902                	ld	s2,32(sp)
    8000236a:	69e2                	ld	s3,24(sp)
    8000236c:	6a42                	ld	s4,16(sp)
    8000236e:	6aa2                	ld	s5,8(sp)
    80002370:	6121                	addi	sp,sp,64
    80002372:	8082                	ret

0000000080002374 <reparent>:
{
    80002374:	7179                	addi	sp,sp,-48
    80002376:	f406                	sd	ra,40(sp)
    80002378:	f022                	sd	s0,32(sp)
    8000237a:	ec26                	sd	s1,24(sp)
    8000237c:	e84a                	sd	s2,16(sp)
    8000237e:	e44e                	sd	s3,8(sp)
    80002380:	e052                	sd	s4,0(sp)
    80002382:	1800                	addi	s0,sp,48
    80002384:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002386:	0000f497          	auipc	s1,0xf
    8000238a:	34a48493          	addi	s1,s1,842 # 800116d0 <proc>
      pp->parent = initproc;
    8000238e:	00007a17          	auipc	s4,0x7
    80002392:	ca2a0a13          	addi	s4,s4,-862 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002396:	00015997          	auipc	s3,0x15
    8000239a:	13a98993          	addi	s3,s3,314 # 800174d0 <tickslock>
    8000239e:	a029                	j	800023a8 <reparent+0x34>
    800023a0:	17848493          	addi	s1,s1,376
    800023a4:	01348d63          	beq	s1,s3,800023be <reparent+0x4a>
    if(pp->parent == p){
    800023a8:	7c9c                	ld	a5,56(s1)
    800023aa:	ff279be3          	bne	a5,s2,800023a0 <reparent+0x2c>
      pp->parent = initproc;
    800023ae:	000a3503          	ld	a0,0(s4)
    800023b2:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800023b4:	00000097          	auipc	ra,0x0
    800023b8:	f4a080e7          	jalr	-182(ra) # 800022fe <wakeup>
    800023bc:	b7d5                	j	800023a0 <reparent+0x2c>
}
    800023be:	70a2                	ld	ra,40(sp)
    800023c0:	7402                	ld	s0,32(sp)
    800023c2:	64e2                	ld	s1,24(sp)
    800023c4:	6942                	ld	s2,16(sp)
    800023c6:	69a2                	ld	s3,8(sp)
    800023c8:	6a02                	ld	s4,0(sp)
    800023ca:	6145                	addi	sp,sp,48
    800023cc:	8082                	ret

00000000800023ce <exit>:
{
    800023ce:	7179                	addi	sp,sp,-48
    800023d0:	f406                	sd	ra,40(sp)
    800023d2:	f022                	sd	s0,32(sp)
    800023d4:	ec26                	sd	s1,24(sp)
    800023d6:	e84a                	sd	s2,16(sp)
    800023d8:	e44e                	sd	s3,8(sp)
    800023da:	e052                	sd	s4,0(sp)
    800023dc:	1800                	addi	s0,sp,48
    800023de:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	5d0080e7          	jalr	1488(ra) # 800019b0 <myproc>
    800023e8:	89aa                	mv	s3,a0
  if(p == initproc)
    800023ea:	00007797          	auipc	a5,0x7
    800023ee:	c467b783          	ld	a5,-954(a5) # 80009030 <initproc>
    800023f2:	0d050493          	addi	s1,a0,208
    800023f6:	15050913          	addi	s2,a0,336
    800023fa:	02a79363          	bne	a5,a0,80002420 <exit+0x52>
    panic("init exiting");
    800023fe:	00006517          	auipc	a0,0x6
    80002402:	e6250513          	addi	a0,a0,-414 # 80008260 <digits+0x220>
    80002406:	ffffe097          	auipc	ra,0xffffe
    8000240a:	138080e7          	jalr	312(ra) # 8000053e <panic>
      fileclose(f);
    8000240e:	00002097          	auipc	ra,0x2
    80002412:	25c080e7          	jalr	604(ra) # 8000466a <fileclose>
      p->ofile[fd] = 0;
    80002416:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000241a:	04a1                	addi	s1,s1,8
    8000241c:	01248563          	beq	s1,s2,80002426 <exit+0x58>
    if(p->ofile[fd]){
    80002420:	6088                	ld	a0,0(s1)
    80002422:	f575                	bnez	a0,8000240e <exit+0x40>
    80002424:	bfdd                	j	8000241a <exit+0x4c>
  begin_op();
    80002426:	00002097          	auipc	ra,0x2
    8000242a:	d78080e7          	jalr	-648(ra) # 8000419e <begin_op>
  iput(p->cwd);
    8000242e:	1509b503          	ld	a0,336(s3)
    80002432:	00001097          	auipc	ra,0x1
    80002436:	554080e7          	jalr	1364(ra) # 80003986 <iput>
  end_op();
    8000243a:	00002097          	auipc	ra,0x2
    8000243e:	de4080e7          	jalr	-540(ra) # 8000421e <end_op>
  p->cwd = 0;
    80002442:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002446:	0000f497          	auipc	s1,0xf
    8000244a:	e7248493          	addi	s1,s1,-398 # 800112b8 <wait_lock>
    8000244e:	8526                	mv	a0,s1
    80002450:	ffffe097          	auipc	ra,0xffffe
    80002454:	794080e7          	jalr	1940(ra) # 80000be4 <acquire>
  reparent(p);
    80002458:	854e                	mv	a0,s3
    8000245a:	00000097          	auipc	ra,0x0
    8000245e:	f1a080e7          	jalr	-230(ra) # 80002374 <reparent>
  wakeup(p->parent);
    80002462:	0389b503          	ld	a0,56(s3)
    80002466:	00000097          	auipc	ra,0x0
    8000246a:	e98080e7          	jalr	-360(ra) # 800022fe <wakeup>
  acquire(&p->lock);
    8000246e:	854e                	mv	a0,s3
    80002470:	ffffe097          	auipc	ra,0xffffe
    80002474:	774080e7          	jalr	1908(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002478:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000247c:	4795                	li	a5,5
    8000247e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002482:	8526                	mv	a0,s1
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	814080e7          	jalr	-2028(ra) # 80000c98 <release>
  sched();
    8000248c:	00000097          	auipc	ra,0x0
    80002490:	bd4080e7          	jalr	-1068(ra) # 80002060 <sched>
  panic("zombie exit");
    80002494:	00006517          	auipc	a0,0x6
    80002498:	ddc50513          	addi	a0,a0,-548 # 80008270 <digits+0x230>
    8000249c:	ffffe097          	auipc	ra,0xffffe
    800024a0:	0a2080e7          	jalr	162(ra) # 8000053e <panic>

00000000800024a4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024a4:	7179                	addi	sp,sp,-48
    800024a6:	f406                	sd	ra,40(sp)
    800024a8:	f022                	sd	s0,32(sp)
    800024aa:	ec26                	sd	s1,24(sp)
    800024ac:	e84a                	sd	s2,16(sp)
    800024ae:	e44e                	sd	s3,8(sp)
    800024b0:	1800                	addi	s0,sp,48
    800024b2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024b4:	0000f497          	auipc	s1,0xf
    800024b8:	21c48493          	addi	s1,s1,540 # 800116d0 <proc>
    800024bc:	00015997          	auipc	s3,0x15
    800024c0:	01498993          	addi	s3,s3,20 # 800174d0 <tickslock>
    acquire(&p->lock);
    800024c4:	8526                	mv	a0,s1
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	71e080e7          	jalr	1822(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800024ce:	589c                	lw	a5,48(s1)
    800024d0:	01278d63          	beq	a5,s2,800024ea <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024d4:	8526                	mv	a0,s1
    800024d6:	ffffe097          	auipc	ra,0xffffe
    800024da:	7c2080e7          	jalr	1986(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024de:	17848493          	addi	s1,s1,376
    800024e2:	ff3491e3          	bne	s1,s3,800024c4 <kill+0x20>
  }
  return -1;
    800024e6:	557d                	li	a0,-1
    800024e8:	a829                	j	80002502 <kill+0x5e>
      p->killed = 1;
    800024ea:	4785                	li	a5,1
    800024ec:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800024ee:	4c98                	lw	a4,24(s1)
    800024f0:	4789                	li	a5,2
    800024f2:	00f70f63          	beq	a4,a5,80002510 <kill+0x6c>
      release(&p->lock);
    800024f6:	8526                	mv	a0,s1
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	7a0080e7          	jalr	1952(ra) # 80000c98 <release>
      return 0;
    80002500:	4501                	li	a0,0
}
    80002502:	70a2                	ld	ra,40(sp)
    80002504:	7402                	ld	s0,32(sp)
    80002506:	64e2                	ld	s1,24(sp)
    80002508:	6942                	ld	s2,16(sp)
    8000250a:	69a2                	ld	s3,8(sp)
    8000250c:	6145                	addi	sp,sp,48
    8000250e:	8082                	ret
        p->state = RUNNABLE;
    80002510:	478d                	li	a5,3
    80002512:	cc9c                	sw	a5,24(s1)
    80002514:	b7cd                	j	800024f6 <kill+0x52>

0000000080002516 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002516:	7179                	addi	sp,sp,-48
    80002518:	f406                	sd	ra,40(sp)
    8000251a:	f022                	sd	s0,32(sp)
    8000251c:	ec26                	sd	s1,24(sp)
    8000251e:	e84a                	sd	s2,16(sp)
    80002520:	e44e                	sd	s3,8(sp)
    80002522:	e052                	sd	s4,0(sp)
    80002524:	1800                	addi	s0,sp,48
    80002526:	84aa                	mv	s1,a0
    80002528:	892e                	mv	s2,a1
    8000252a:	89b2                	mv	s3,a2
    8000252c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	482080e7          	jalr	1154(ra) # 800019b0 <myproc>
  if(user_dst){
    80002536:	c08d                	beqz	s1,80002558 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002538:	86d2                	mv	a3,s4
    8000253a:	864e                	mv	a2,s3
    8000253c:	85ca                	mv	a1,s2
    8000253e:	6928                	ld	a0,80(a0)
    80002540:	fffff097          	auipc	ra,0xfffff
    80002544:	132080e7          	jalr	306(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002548:	70a2                	ld	ra,40(sp)
    8000254a:	7402                	ld	s0,32(sp)
    8000254c:	64e2                	ld	s1,24(sp)
    8000254e:	6942                	ld	s2,16(sp)
    80002550:	69a2                	ld	s3,8(sp)
    80002552:	6a02                	ld	s4,0(sp)
    80002554:	6145                	addi	sp,sp,48
    80002556:	8082                	ret
    memmove((char *)dst, src, len);
    80002558:	000a061b          	sext.w	a2,s4
    8000255c:	85ce                	mv	a1,s3
    8000255e:	854a                	mv	a0,s2
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	7e0080e7          	jalr	2016(ra) # 80000d40 <memmove>
    return 0;
    80002568:	8526                	mv	a0,s1
    8000256a:	bff9                	j	80002548 <either_copyout+0x32>

000000008000256c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000256c:	7179                	addi	sp,sp,-48
    8000256e:	f406                	sd	ra,40(sp)
    80002570:	f022                	sd	s0,32(sp)
    80002572:	ec26                	sd	s1,24(sp)
    80002574:	e84a                	sd	s2,16(sp)
    80002576:	e44e                	sd	s3,8(sp)
    80002578:	e052                	sd	s4,0(sp)
    8000257a:	1800                	addi	s0,sp,48
    8000257c:	892a                	mv	s2,a0
    8000257e:	84ae                	mv	s1,a1
    80002580:	89b2                	mv	s3,a2
    80002582:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002584:	fffff097          	auipc	ra,0xfffff
    80002588:	42c080e7          	jalr	1068(ra) # 800019b0 <myproc>
  if(user_src){
    8000258c:	c08d                	beqz	s1,800025ae <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000258e:	86d2                	mv	a3,s4
    80002590:	864e                	mv	a2,s3
    80002592:	85ca                	mv	a1,s2
    80002594:	6928                	ld	a0,80(a0)
    80002596:	fffff097          	auipc	ra,0xfffff
    8000259a:	168080e7          	jalr	360(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000259e:	70a2                	ld	ra,40(sp)
    800025a0:	7402                	ld	s0,32(sp)
    800025a2:	64e2                	ld	s1,24(sp)
    800025a4:	6942                	ld	s2,16(sp)
    800025a6:	69a2                	ld	s3,8(sp)
    800025a8:	6a02                	ld	s4,0(sp)
    800025aa:	6145                	addi	sp,sp,48
    800025ac:	8082                	ret
    memmove(dst, (char*)src, len);
    800025ae:	000a061b          	sext.w	a2,s4
    800025b2:	85ce                	mv	a1,s3
    800025b4:	854a                	mv	a0,s2
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	78a080e7          	jalr	1930(ra) # 80000d40 <memmove>
    return 0;
    800025be:	8526                	mv	a0,s1
    800025c0:	bff9                	j	8000259e <either_copyin+0x32>

00000000800025c2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025c2:	715d                	addi	sp,sp,-80
    800025c4:	e486                	sd	ra,72(sp)
    800025c6:	e0a2                	sd	s0,64(sp)
    800025c8:	fc26                	sd	s1,56(sp)
    800025ca:	f84a                	sd	s2,48(sp)
    800025cc:	f44e                	sd	s3,40(sp)
    800025ce:	f052                	sd	s4,32(sp)
    800025d0:	ec56                	sd	s5,24(sp)
    800025d2:	e85a                	sd	s6,16(sp)
    800025d4:	e45e                	sd	s7,8(sp)
    800025d6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025d8:	00006517          	auipc	a0,0x6
    800025dc:	af050513          	addi	a0,a0,-1296 # 800080c8 <digits+0x88>
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	fa8080e7          	jalr	-88(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025e8:	0000f497          	auipc	s1,0xf
    800025ec:	24048493          	addi	s1,s1,576 # 80011828 <proc+0x158>
    800025f0:	00015917          	auipc	s2,0x15
    800025f4:	03890913          	addi	s2,s2,56 # 80017628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025fa:	00006997          	auipc	s3,0x6
    800025fe:	c8698993          	addi	s3,s3,-890 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002602:	00006a97          	auipc	s5,0x6
    80002606:	c86a8a93          	addi	s5,s5,-890 # 80008288 <digits+0x248>
    printf("\n");
    8000260a:	00006a17          	auipc	s4,0x6
    8000260e:	abea0a13          	addi	s4,s4,-1346 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002612:	00006b97          	auipc	s7,0x6
    80002616:	cdeb8b93          	addi	s7,s7,-802 # 800082f0 <states.1732>
    8000261a:	a00d                	j	8000263c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000261c:	ed86a583          	lw	a1,-296(a3)
    80002620:	8556                	mv	a0,s5
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	f66080e7          	jalr	-154(ra) # 80000588 <printf>
    printf("\n");
    8000262a:	8552                	mv	a0,s4
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	f5c080e7          	jalr	-164(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002634:	17848493          	addi	s1,s1,376
    80002638:	03248163          	beq	s1,s2,8000265a <procdump+0x98>
    if(p->state == UNUSED)
    8000263c:	86a6                	mv	a3,s1
    8000263e:	ec04a783          	lw	a5,-320(s1)
    80002642:	dbed                	beqz	a5,80002634 <procdump+0x72>
      state = "???";
    80002644:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002646:	fcfb6be3          	bltu	s6,a5,8000261c <procdump+0x5a>
    8000264a:	1782                	slli	a5,a5,0x20
    8000264c:	9381                	srli	a5,a5,0x20
    8000264e:	078e                	slli	a5,a5,0x3
    80002650:	97de                	add	a5,a5,s7
    80002652:	6390                	ld	a2,0(a5)
    80002654:	f661                	bnez	a2,8000261c <procdump+0x5a>
      state = "???";
    80002656:	864e                	mv	a2,s3
    80002658:	b7d1                	j	8000261c <procdump+0x5a>
  }
}
    8000265a:	60a6                	ld	ra,72(sp)
    8000265c:	6406                	ld	s0,64(sp)
    8000265e:	74e2                	ld	s1,56(sp)
    80002660:	7942                	ld	s2,48(sp)
    80002662:	79a2                	ld	s3,40(sp)
    80002664:	7a02                	ld	s4,32(sp)
    80002666:	6ae2                	ld	s5,24(sp)
    80002668:	6b42                	ld	s6,16(sp)
    8000266a:	6ba2                	ld	s7,8(sp)
    8000266c:	6161                	addi	sp,sp,80
    8000266e:	8082                	ret

0000000080002670 <sched_tickets>:

//set tickets
void sched_tickets(int num_tickets) {
    80002670:	1101                	addi	sp,sp,-32
    80002672:	ec06                	sd	ra,24(sp)
    80002674:	e822                	sd	s0,16(sp)
    80002676:	e426                	sd	s1,8(sp)
    80002678:	1000                	addi	s0,sp,32
    8000267a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000267c:	fffff097          	auipc	ra,0xfffff
    80002680:	334080e7          	jalr	820(ra) # 800019b0 <myproc>
  p->tickets = num_tickets;
    80002684:	16952423          	sw	s1,360(a0)
  p->stride_val = 5000/p->tickets;
    80002688:	6785                	lui	a5,0x1
    8000268a:	3887879b          	addiw	a5,a5,904
    8000268e:	0297c7bb          	divw	a5,a5,s1
    80002692:	16f52823          	sw	a5,368(a0)
  p->current_stride += p->stride_val;
    80002696:	17452703          	lw	a4,372(a0)
    8000269a:	9fb9                	addw	a5,a5,a4
    8000269c:	16f52a23          	sw	a5,372(a0)
}
    800026a0:	60e2                	ld	ra,24(sp)
    800026a2:	6442                	ld	s0,16(sp)
    800026a4:	64a2                	ld	s1,8(sp)
    800026a6:	6105                	addi	sp,sp,32
    800026a8:	8082                	ret

00000000800026aa <sched_statistics>:

//Display number of times processes has scheduled to run

void sched_statistics(void) {
    800026aa:	7179                	addi	sp,sp,-48
    800026ac:	f406                	sd	ra,40(sp)
    800026ae:	f022                	sd	s0,32(sp)
    800026b0:	ec26                	sd	s1,24(sp)
    800026b2:	e84a                	sd	s2,16(sp)
    800026b4:	e44e                	sd	s3,8(sp)
    800026b6:	1800                	addi	s0,sp,48
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    800026b8:	0000f497          	auipc	s1,0xf
    800026bc:	01848493          	addi	s1,s1,24 # 800116d0 <proc>
    if(p->state !=UNUSED)
     {
      printf("%s : %s %d tickets = %d ticks = %d\n", myproc()->name,p->name, p->pid,p->tickets, p->tickscount);
    800026c0:	00006997          	auipc	s3,0x6
    800026c4:	bd898993          	addi	s3,s3,-1064 # 80008298 <digits+0x258>
  for(p = proc; p < &proc[NPROC]; p++){
    800026c8:	00015917          	auipc	s2,0x15
    800026cc:	e0890913          	addi	s2,s2,-504 # 800174d0 <tickslock>
    800026d0:	a03d                	j	800026fe <sched_statistics+0x54>
      printf("%s : %s %d tickets = %d ticks = %d\n", myproc()->name,p->name, p->pid,p->tickets, p->tickscount);
    800026d2:	fffff097          	auipc	ra,0xfffff
    800026d6:	2de080e7          	jalr	734(ra) # 800019b0 <myproc>
    800026da:	16c4a783          	lw	a5,364(s1)
    800026de:	1684a703          	lw	a4,360(s1)
    800026e2:	5894                	lw	a3,48(s1)
    800026e4:	15848613          	addi	a2,s1,344
    800026e8:	15850593          	addi	a1,a0,344
    800026ec:	854e                	mv	a0,s3
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	e9a080e7          	jalr	-358(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026f6:	17848493          	addi	s1,s1,376
    800026fa:	01248563          	beq	s1,s2,80002704 <sched_statistics+0x5a>
    if(p->state !=UNUSED)
    800026fe:	4c9c                	lw	a5,24(s1)
    80002700:	dbfd                	beqz	a5,800026f6 <sched_statistics+0x4c>
    80002702:	bfc1                	j	800026d2 <sched_statistics+0x28>
    }
  }
  printf("\n\n");
    80002704:	00006517          	auipc	a0,0x6
    80002708:	bbc50513          	addi	a0,a0,-1092 # 800082c0 <digits+0x280>
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	e7c080e7          	jalr	-388(ra) # 80000588 <printf>
}
    80002714:	70a2                	ld	ra,40(sp)
    80002716:	7402                	ld	s0,32(sp)
    80002718:	64e2                	ld	s1,24(sp)
    8000271a:	6942                	ld	s2,16(sp)
    8000271c:	69a2                	ld	s3,8(sp)
    8000271e:	6145                	addi	sp,sp,48
    80002720:	8082                	ret

0000000080002722 <swtch>:
    80002722:	00153023          	sd	ra,0(a0)
    80002726:	00253423          	sd	sp,8(a0)
    8000272a:	e900                	sd	s0,16(a0)
    8000272c:	ed04                	sd	s1,24(a0)
    8000272e:	03253023          	sd	s2,32(a0)
    80002732:	03353423          	sd	s3,40(a0)
    80002736:	03453823          	sd	s4,48(a0)
    8000273a:	03553c23          	sd	s5,56(a0)
    8000273e:	05653023          	sd	s6,64(a0)
    80002742:	05753423          	sd	s7,72(a0)
    80002746:	05853823          	sd	s8,80(a0)
    8000274a:	05953c23          	sd	s9,88(a0)
    8000274e:	07a53023          	sd	s10,96(a0)
    80002752:	07b53423          	sd	s11,104(a0)
    80002756:	0005b083          	ld	ra,0(a1)
    8000275a:	0085b103          	ld	sp,8(a1)
    8000275e:	6980                	ld	s0,16(a1)
    80002760:	6d84                	ld	s1,24(a1)
    80002762:	0205b903          	ld	s2,32(a1)
    80002766:	0285b983          	ld	s3,40(a1)
    8000276a:	0305ba03          	ld	s4,48(a1)
    8000276e:	0385ba83          	ld	s5,56(a1)
    80002772:	0405bb03          	ld	s6,64(a1)
    80002776:	0485bb83          	ld	s7,72(a1)
    8000277a:	0505bc03          	ld	s8,80(a1)
    8000277e:	0585bc83          	ld	s9,88(a1)
    80002782:	0605bd03          	ld	s10,96(a1)
    80002786:	0685bd83          	ld	s11,104(a1)
    8000278a:	8082                	ret

000000008000278c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000278c:	1141                	addi	sp,sp,-16
    8000278e:	e406                	sd	ra,8(sp)
    80002790:	e022                	sd	s0,0(sp)
    80002792:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002794:	00006597          	auipc	a1,0x6
    80002798:	b8c58593          	addi	a1,a1,-1140 # 80008320 <states.1732+0x30>
    8000279c:	00015517          	auipc	a0,0x15
    800027a0:	d3450513          	addi	a0,a0,-716 # 800174d0 <tickslock>
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	3b0080e7          	jalr	944(ra) # 80000b54 <initlock>
}
    800027ac:	60a2                	ld	ra,8(sp)
    800027ae:	6402                	ld	s0,0(sp)
    800027b0:	0141                	addi	sp,sp,16
    800027b2:	8082                	ret

00000000800027b4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027b4:	1141                	addi	sp,sp,-16
    800027b6:	e422                	sd	s0,8(sp)
    800027b8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027ba:	00003797          	auipc	a5,0x3
    800027be:	4c678793          	addi	a5,a5,1222 # 80005c80 <kernelvec>
    800027c2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027c6:	6422                	ld	s0,8(sp)
    800027c8:	0141                	addi	sp,sp,16
    800027ca:	8082                	ret

00000000800027cc <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027cc:	1141                	addi	sp,sp,-16
    800027ce:	e406                	sd	ra,8(sp)
    800027d0:	e022                	sd	s0,0(sp)
    800027d2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027d4:	fffff097          	auipc	ra,0xfffff
    800027d8:	1dc080e7          	jalr	476(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027dc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027e0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027e2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800027e6:	00005617          	auipc	a2,0x5
    800027ea:	81a60613          	addi	a2,a2,-2022 # 80007000 <_trampoline>
    800027ee:	00005697          	auipc	a3,0x5
    800027f2:	81268693          	addi	a3,a3,-2030 # 80007000 <_trampoline>
    800027f6:	8e91                	sub	a3,a3,a2
    800027f8:	040007b7          	lui	a5,0x4000
    800027fc:	17fd                	addi	a5,a5,-1
    800027fe:	07b2                	slli	a5,a5,0xc
    80002800:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002802:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002806:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002808:	180026f3          	csrr	a3,satp
    8000280c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000280e:	6d38                	ld	a4,88(a0)
    80002810:	6134                	ld	a3,64(a0)
    80002812:	6585                	lui	a1,0x1
    80002814:	96ae                	add	a3,a3,a1
    80002816:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002818:	6d38                	ld	a4,88(a0)
    8000281a:	00000697          	auipc	a3,0x0
    8000281e:	13868693          	addi	a3,a3,312 # 80002952 <usertrap>
    80002822:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002824:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002826:	8692                	mv	a3,tp
    80002828:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000282a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000282e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002832:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002836:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000283a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000283c:	6f18                	ld	a4,24(a4)
    8000283e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002842:	692c                	ld	a1,80(a0)
    80002844:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002846:	00005717          	auipc	a4,0x5
    8000284a:	84a70713          	addi	a4,a4,-1974 # 80007090 <userret>
    8000284e:	8f11                	sub	a4,a4,a2
    80002850:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002852:	577d                	li	a4,-1
    80002854:	177e                	slli	a4,a4,0x3f
    80002856:	8dd9                	or	a1,a1,a4
    80002858:	02000537          	lui	a0,0x2000
    8000285c:	157d                	addi	a0,a0,-1
    8000285e:	0536                	slli	a0,a0,0xd
    80002860:	9782                	jalr	a5
}
    80002862:	60a2                	ld	ra,8(sp)
    80002864:	6402                	ld	s0,0(sp)
    80002866:	0141                	addi	sp,sp,16
    80002868:	8082                	ret

000000008000286a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000286a:	1101                	addi	sp,sp,-32
    8000286c:	ec06                	sd	ra,24(sp)
    8000286e:	e822                	sd	s0,16(sp)
    80002870:	e426                	sd	s1,8(sp)
    80002872:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002874:	00015497          	auipc	s1,0x15
    80002878:	c5c48493          	addi	s1,s1,-932 # 800174d0 <tickslock>
    8000287c:	8526                	mv	a0,s1
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	366080e7          	jalr	870(ra) # 80000be4 <acquire>
  ticks++;
    80002886:	00006517          	auipc	a0,0x6
    8000288a:	7b250513          	addi	a0,a0,1970 # 80009038 <ticks>
    8000288e:	411c                	lw	a5,0(a0)
    80002890:	2785                	addiw	a5,a5,1
    80002892:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002894:	00000097          	auipc	ra,0x0
    80002898:	a6a080e7          	jalr	-1430(ra) # 800022fe <wakeup>
  release(&tickslock);
    8000289c:	8526                	mv	a0,s1
    8000289e:	ffffe097          	auipc	ra,0xffffe
    800028a2:	3fa080e7          	jalr	1018(ra) # 80000c98 <release>
}
    800028a6:	60e2                	ld	ra,24(sp)
    800028a8:	6442                	ld	s0,16(sp)
    800028aa:	64a2                	ld	s1,8(sp)
    800028ac:	6105                	addi	sp,sp,32
    800028ae:	8082                	ret

00000000800028b0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028b0:	1101                	addi	sp,sp,-32
    800028b2:	ec06                	sd	ra,24(sp)
    800028b4:	e822                	sd	s0,16(sp)
    800028b6:	e426                	sd	s1,8(sp)
    800028b8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ba:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028be:	00074d63          	bltz	a4,800028d8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028c2:	57fd                	li	a5,-1
    800028c4:	17fe                	slli	a5,a5,0x3f
    800028c6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028c8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028ca:	06f70363          	beq	a4,a5,80002930 <devintr+0x80>
  }
}
    800028ce:	60e2                	ld	ra,24(sp)
    800028d0:	6442                	ld	s0,16(sp)
    800028d2:	64a2                	ld	s1,8(sp)
    800028d4:	6105                	addi	sp,sp,32
    800028d6:	8082                	ret
     (scause & 0xff) == 9){
    800028d8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028dc:	46a5                	li	a3,9
    800028de:	fed792e3          	bne	a5,a3,800028c2 <devintr+0x12>
    int irq = plic_claim();
    800028e2:	00003097          	auipc	ra,0x3
    800028e6:	4a6080e7          	jalr	1190(ra) # 80005d88 <plic_claim>
    800028ea:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028ec:	47a9                	li	a5,10
    800028ee:	02f50763          	beq	a0,a5,8000291c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028f2:	4785                	li	a5,1
    800028f4:	02f50963          	beq	a0,a5,80002926 <devintr+0x76>
    return 1;
    800028f8:	4505                	li	a0,1
    } else if(irq){
    800028fa:	d8f1                	beqz	s1,800028ce <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028fc:	85a6                	mv	a1,s1
    800028fe:	00006517          	auipc	a0,0x6
    80002902:	a2a50513          	addi	a0,a0,-1494 # 80008328 <states.1732+0x38>
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	c82080e7          	jalr	-894(ra) # 80000588 <printf>
      plic_complete(irq);
    8000290e:	8526                	mv	a0,s1
    80002910:	00003097          	auipc	ra,0x3
    80002914:	49c080e7          	jalr	1180(ra) # 80005dac <plic_complete>
    return 1;
    80002918:	4505                	li	a0,1
    8000291a:	bf55                	j	800028ce <devintr+0x1e>
      uartintr();
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	08c080e7          	jalr	140(ra) # 800009a8 <uartintr>
    80002924:	b7ed                	j	8000290e <devintr+0x5e>
      virtio_disk_intr();
    80002926:	00004097          	auipc	ra,0x4
    8000292a:	966080e7          	jalr	-1690(ra) # 8000628c <virtio_disk_intr>
    8000292e:	b7c5                	j	8000290e <devintr+0x5e>
    if(cpuid() == 0){
    80002930:	fffff097          	auipc	ra,0xfffff
    80002934:	054080e7          	jalr	84(ra) # 80001984 <cpuid>
    80002938:	c901                	beqz	a0,80002948 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000293a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000293e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002940:	14479073          	csrw	sip,a5
    return 2;
    80002944:	4509                	li	a0,2
    80002946:	b761                	j	800028ce <devintr+0x1e>
      clockintr();
    80002948:	00000097          	auipc	ra,0x0
    8000294c:	f22080e7          	jalr	-222(ra) # 8000286a <clockintr>
    80002950:	b7ed                	j	8000293a <devintr+0x8a>

0000000080002952 <usertrap>:
{
    80002952:	1101                	addi	sp,sp,-32
    80002954:	ec06                	sd	ra,24(sp)
    80002956:	e822                	sd	s0,16(sp)
    80002958:	e426                	sd	s1,8(sp)
    8000295a:	e04a                	sd	s2,0(sp)
    8000295c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000295e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002962:	1007f793          	andi	a5,a5,256
    80002966:	e3ad                	bnez	a5,800029c8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002968:	00003797          	auipc	a5,0x3
    8000296c:	31878793          	addi	a5,a5,792 # 80005c80 <kernelvec>
    80002970:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002974:	fffff097          	auipc	ra,0xfffff
    80002978:	03c080e7          	jalr	60(ra) # 800019b0 <myproc>
    8000297c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000297e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002980:	14102773          	csrr	a4,sepc
    80002984:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002986:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000298a:	47a1                	li	a5,8
    8000298c:	04f71c63          	bne	a4,a5,800029e4 <usertrap+0x92>
    if(p->killed)
    80002990:	551c                	lw	a5,40(a0)
    80002992:	e3b9                	bnez	a5,800029d8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002994:	6cb8                	ld	a4,88(s1)
    80002996:	6f1c                	ld	a5,24(a4)
    80002998:	0791                	addi	a5,a5,4
    8000299a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000299c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029a0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029a4:	10079073          	csrw	sstatus,a5
    syscall();
    800029a8:	00000097          	auipc	ra,0x0
    800029ac:	2e0080e7          	jalr	736(ra) # 80002c88 <syscall>
  if(p->killed)
    800029b0:	549c                	lw	a5,40(s1)
    800029b2:	ebc1                	bnez	a5,80002a42 <usertrap+0xf0>
  usertrapret();
    800029b4:	00000097          	auipc	ra,0x0
    800029b8:	e18080e7          	jalr	-488(ra) # 800027cc <usertrapret>
}
    800029bc:	60e2                	ld	ra,24(sp)
    800029be:	6442                	ld	s0,16(sp)
    800029c0:	64a2                	ld	s1,8(sp)
    800029c2:	6902                	ld	s2,0(sp)
    800029c4:	6105                	addi	sp,sp,32
    800029c6:	8082                	ret
    panic("usertrap: not from user mode");
    800029c8:	00006517          	auipc	a0,0x6
    800029cc:	98050513          	addi	a0,a0,-1664 # 80008348 <states.1732+0x58>
    800029d0:	ffffe097          	auipc	ra,0xffffe
    800029d4:	b6e080e7          	jalr	-1170(ra) # 8000053e <panic>
      exit(-1);
    800029d8:	557d                	li	a0,-1
    800029da:	00000097          	auipc	ra,0x0
    800029de:	9f4080e7          	jalr	-1548(ra) # 800023ce <exit>
    800029e2:	bf4d                	j	80002994 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800029e4:	00000097          	auipc	ra,0x0
    800029e8:	ecc080e7          	jalr	-308(ra) # 800028b0 <devintr>
    800029ec:	892a                	mv	s2,a0
    800029ee:	c501                	beqz	a0,800029f6 <usertrap+0xa4>
  if(p->killed)
    800029f0:	549c                	lw	a5,40(s1)
    800029f2:	c3a1                	beqz	a5,80002a32 <usertrap+0xe0>
    800029f4:	a815                	j	80002a28 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029f6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029fa:	5890                	lw	a2,48(s1)
    800029fc:	00006517          	auipc	a0,0x6
    80002a00:	96c50513          	addi	a0,a0,-1684 # 80008368 <states.1732+0x78>
    80002a04:	ffffe097          	auipc	ra,0xffffe
    80002a08:	b84080e7          	jalr	-1148(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a0c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a10:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a14:	00006517          	auipc	a0,0x6
    80002a18:	98450513          	addi	a0,a0,-1660 # 80008398 <states.1732+0xa8>
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	b6c080e7          	jalr	-1172(ra) # 80000588 <printf>
    p->killed = 1;
    80002a24:	4785                	li	a5,1
    80002a26:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a28:	557d                	li	a0,-1
    80002a2a:	00000097          	auipc	ra,0x0
    80002a2e:	9a4080e7          	jalr	-1628(ra) # 800023ce <exit>
  if(which_dev == 2)
    80002a32:	4789                	li	a5,2
    80002a34:	f8f910e3          	bne	s2,a5,800029b4 <usertrap+0x62>
    yield();
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	6fe080e7          	jalr	1790(ra) # 80002136 <yield>
    80002a40:	bf95                	j	800029b4 <usertrap+0x62>
  int which_dev = 0;
    80002a42:	4901                	li	s2,0
    80002a44:	b7d5                	j	80002a28 <usertrap+0xd6>

0000000080002a46 <kerneltrap>:
{
    80002a46:	7179                	addi	sp,sp,-48
    80002a48:	f406                	sd	ra,40(sp)
    80002a4a:	f022                	sd	s0,32(sp)
    80002a4c:	ec26                	sd	s1,24(sp)
    80002a4e:	e84a                	sd	s2,16(sp)
    80002a50:	e44e                	sd	s3,8(sp)
    80002a52:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a54:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a58:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a5c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a60:	1004f793          	andi	a5,s1,256
    80002a64:	cb85                	beqz	a5,80002a94 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a66:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a6a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a6c:	ef85                	bnez	a5,80002aa4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a6e:	00000097          	auipc	ra,0x0
    80002a72:	e42080e7          	jalr	-446(ra) # 800028b0 <devintr>
    80002a76:	cd1d                	beqz	a0,80002ab4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a78:	4789                	li	a5,2
    80002a7a:	06f50a63          	beq	a0,a5,80002aee <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a7e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a82:	10049073          	csrw	sstatus,s1
}
    80002a86:	70a2                	ld	ra,40(sp)
    80002a88:	7402                	ld	s0,32(sp)
    80002a8a:	64e2                	ld	s1,24(sp)
    80002a8c:	6942                	ld	s2,16(sp)
    80002a8e:	69a2                	ld	s3,8(sp)
    80002a90:	6145                	addi	sp,sp,48
    80002a92:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a94:	00006517          	auipc	a0,0x6
    80002a98:	92450513          	addi	a0,a0,-1756 # 800083b8 <states.1732+0xc8>
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	aa2080e7          	jalr	-1374(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002aa4:	00006517          	auipc	a0,0x6
    80002aa8:	93c50513          	addi	a0,a0,-1732 # 800083e0 <states.1732+0xf0>
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	a92080e7          	jalr	-1390(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002ab4:	85ce                	mv	a1,s3
    80002ab6:	00006517          	auipc	a0,0x6
    80002aba:	94a50513          	addi	a0,a0,-1718 # 80008400 <states.1732+0x110>
    80002abe:	ffffe097          	auipc	ra,0xffffe
    80002ac2:	aca080e7          	jalr	-1334(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ac6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002aca:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ace:	00006517          	auipc	a0,0x6
    80002ad2:	94250513          	addi	a0,a0,-1726 # 80008410 <states.1732+0x120>
    80002ad6:	ffffe097          	auipc	ra,0xffffe
    80002ada:	ab2080e7          	jalr	-1358(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002ade:	00006517          	auipc	a0,0x6
    80002ae2:	94a50513          	addi	a0,a0,-1718 # 80008428 <states.1732+0x138>
    80002ae6:	ffffe097          	auipc	ra,0xffffe
    80002aea:	a58080e7          	jalr	-1448(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002aee:	fffff097          	auipc	ra,0xfffff
    80002af2:	ec2080e7          	jalr	-318(ra) # 800019b0 <myproc>
    80002af6:	d541                	beqz	a0,80002a7e <kerneltrap+0x38>
    80002af8:	fffff097          	auipc	ra,0xfffff
    80002afc:	eb8080e7          	jalr	-328(ra) # 800019b0 <myproc>
    80002b00:	4d18                	lw	a4,24(a0)
    80002b02:	4791                	li	a5,4
    80002b04:	f6f71de3          	bne	a4,a5,80002a7e <kerneltrap+0x38>
    yield();
    80002b08:	fffff097          	auipc	ra,0xfffff
    80002b0c:	62e080e7          	jalr	1582(ra) # 80002136 <yield>
    80002b10:	b7bd                	j	80002a7e <kerneltrap+0x38>

0000000080002b12 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b12:	1101                	addi	sp,sp,-32
    80002b14:	ec06                	sd	ra,24(sp)
    80002b16:	e822                	sd	s0,16(sp)
    80002b18:	e426                	sd	s1,8(sp)
    80002b1a:	1000                	addi	s0,sp,32
    80002b1c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b1e:	fffff097          	auipc	ra,0xfffff
    80002b22:	e92080e7          	jalr	-366(ra) # 800019b0 <myproc>
  switch (n) {
    80002b26:	4795                	li	a5,5
    80002b28:	0497e163          	bltu	a5,s1,80002b6a <argraw+0x58>
    80002b2c:	048a                	slli	s1,s1,0x2
    80002b2e:	00006717          	auipc	a4,0x6
    80002b32:	93270713          	addi	a4,a4,-1742 # 80008460 <states.1732+0x170>
    80002b36:	94ba                	add	s1,s1,a4
    80002b38:	409c                	lw	a5,0(s1)
    80002b3a:	97ba                	add	a5,a5,a4
    80002b3c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b3e:	6d3c                	ld	a5,88(a0)
    80002b40:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b42:	60e2                	ld	ra,24(sp)
    80002b44:	6442                	ld	s0,16(sp)
    80002b46:	64a2                	ld	s1,8(sp)
    80002b48:	6105                	addi	sp,sp,32
    80002b4a:	8082                	ret
    return p->trapframe->a1;
    80002b4c:	6d3c                	ld	a5,88(a0)
    80002b4e:	7fa8                	ld	a0,120(a5)
    80002b50:	bfcd                	j	80002b42 <argraw+0x30>
    return p->trapframe->a2;
    80002b52:	6d3c                	ld	a5,88(a0)
    80002b54:	63c8                	ld	a0,128(a5)
    80002b56:	b7f5                	j	80002b42 <argraw+0x30>
    return p->trapframe->a3;
    80002b58:	6d3c                	ld	a5,88(a0)
    80002b5a:	67c8                	ld	a0,136(a5)
    80002b5c:	b7dd                	j	80002b42 <argraw+0x30>
    return p->trapframe->a4;
    80002b5e:	6d3c                	ld	a5,88(a0)
    80002b60:	6bc8                	ld	a0,144(a5)
    80002b62:	b7c5                	j	80002b42 <argraw+0x30>
    return p->trapframe->a5;
    80002b64:	6d3c                	ld	a5,88(a0)
    80002b66:	6fc8                	ld	a0,152(a5)
    80002b68:	bfe9                	j	80002b42 <argraw+0x30>
  panic("argraw");
    80002b6a:	00006517          	auipc	a0,0x6
    80002b6e:	8ce50513          	addi	a0,a0,-1842 # 80008438 <states.1732+0x148>
    80002b72:	ffffe097          	auipc	ra,0xffffe
    80002b76:	9cc080e7          	jalr	-1588(ra) # 8000053e <panic>

0000000080002b7a <fetchaddr>:
{
    80002b7a:	1101                	addi	sp,sp,-32
    80002b7c:	ec06                	sd	ra,24(sp)
    80002b7e:	e822                	sd	s0,16(sp)
    80002b80:	e426                	sd	s1,8(sp)
    80002b82:	e04a                	sd	s2,0(sp)
    80002b84:	1000                	addi	s0,sp,32
    80002b86:	84aa                	mv	s1,a0
    80002b88:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b8a:	fffff097          	auipc	ra,0xfffff
    80002b8e:	e26080e7          	jalr	-474(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b92:	653c                	ld	a5,72(a0)
    80002b94:	02f4f863          	bgeu	s1,a5,80002bc4 <fetchaddr+0x4a>
    80002b98:	00848713          	addi	a4,s1,8
    80002b9c:	02e7e663          	bltu	a5,a4,80002bc8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ba0:	46a1                	li	a3,8
    80002ba2:	8626                	mv	a2,s1
    80002ba4:	85ca                	mv	a1,s2
    80002ba6:	6928                	ld	a0,80(a0)
    80002ba8:	fffff097          	auipc	ra,0xfffff
    80002bac:	b56080e7          	jalr	-1194(ra) # 800016fe <copyin>
    80002bb0:	00a03533          	snez	a0,a0
    80002bb4:	40a00533          	neg	a0,a0
}
    80002bb8:	60e2                	ld	ra,24(sp)
    80002bba:	6442                	ld	s0,16(sp)
    80002bbc:	64a2                	ld	s1,8(sp)
    80002bbe:	6902                	ld	s2,0(sp)
    80002bc0:	6105                	addi	sp,sp,32
    80002bc2:	8082                	ret
    return -1;
    80002bc4:	557d                	li	a0,-1
    80002bc6:	bfcd                	j	80002bb8 <fetchaddr+0x3e>
    80002bc8:	557d                	li	a0,-1
    80002bca:	b7fd                	j	80002bb8 <fetchaddr+0x3e>

0000000080002bcc <fetchstr>:
{
    80002bcc:	7179                	addi	sp,sp,-48
    80002bce:	f406                	sd	ra,40(sp)
    80002bd0:	f022                	sd	s0,32(sp)
    80002bd2:	ec26                	sd	s1,24(sp)
    80002bd4:	e84a                	sd	s2,16(sp)
    80002bd6:	e44e                	sd	s3,8(sp)
    80002bd8:	1800                	addi	s0,sp,48
    80002bda:	892a                	mv	s2,a0
    80002bdc:	84ae                	mv	s1,a1
    80002bde:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	dd0080e7          	jalr	-560(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002be8:	86ce                	mv	a3,s3
    80002bea:	864a                	mv	a2,s2
    80002bec:	85a6                	mv	a1,s1
    80002bee:	6928                	ld	a0,80(a0)
    80002bf0:	fffff097          	auipc	ra,0xfffff
    80002bf4:	b9a080e7          	jalr	-1126(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002bf8:	00054763          	bltz	a0,80002c06 <fetchstr+0x3a>
  return strlen(buf);
    80002bfc:	8526                	mv	a0,s1
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	266080e7          	jalr	614(ra) # 80000e64 <strlen>
}
    80002c06:	70a2                	ld	ra,40(sp)
    80002c08:	7402                	ld	s0,32(sp)
    80002c0a:	64e2                	ld	s1,24(sp)
    80002c0c:	6942                	ld	s2,16(sp)
    80002c0e:	69a2                	ld	s3,8(sp)
    80002c10:	6145                	addi	sp,sp,48
    80002c12:	8082                	ret

0000000080002c14 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c14:	1101                	addi	sp,sp,-32
    80002c16:	ec06                	sd	ra,24(sp)
    80002c18:	e822                	sd	s0,16(sp)
    80002c1a:	e426                	sd	s1,8(sp)
    80002c1c:	1000                	addi	s0,sp,32
    80002c1e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c20:	00000097          	auipc	ra,0x0
    80002c24:	ef2080e7          	jalr	-270(ra) # 80002b12 <argraw>
    80002c28:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c2a:	4501                	li	a0,0
    80002c2c:	60e2                	ld	ra,24(sp)
    80002c2e:	6442                	ld	s0,16(sp)
    80002c30:	64a2                	ld	s1,8(sp)
    80002c32:	6105                	addi	sp,sp,32
    80002c34:	8082                	ret

0000000080002c36 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c36:	1101                	addi	sp,sp,-32
    80002c38:	ec06                	sd	ra,24(sp)
    80002c3a:	e822                	sd	s0,16(sp)
    80002c3c:	e426                	sd	s1,8(sp)
    80002c3e:	1000                	addi	s0,sp,32
    80002c40:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c42:	00000097          	auipc	ra,0x0
    80002c46:	ed0080e7          	jalr	-304(ra) # 80002b12 <argraw>
    80002c4a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c4c:	4501                	li	a0,0
    80002c4e:	60e2                	ld	ra,24(sp)
    80002c50:	6442                	ld	s0,16(sp)
    80002c52:	64a2                	ld	s1,8(sp)
    80002c54:	6105                	addi	sp,sp,32
    80002c56:	8082                	ret

0000000080002c58 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c58:	1101                	addi	sp,sp,-32
    80002c5a:	ec06                	sd	ra,24(sp)
    80002c5c:	e822                	sd	s0,16(sp)
    80002c5e:	e426                	sd	s1,8(sp)
    80002c60:	e04a                	sd	s2,0(sp)
    80002c62:	1000                	addi	s0,sp,32
    80002c64:	84ae                	mv	s1,a1
    80002c66:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	eaa080e7          	jalr	-342(ra) # 80002b12 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c70:	864a                	mv	a2,s2
    80002c72:	85a6                	mv	a1,s1
    80002c74:	00000097          	auipc	ra,0x0
    80002c78:	f58080e7          	jalr	-168(ra) # 80002bcc <fetchstr>
}
    80002c7c:	60e2                	ld	ra,24(sp)
    80002c7e:	6442                	ld	s0,16(sp)
    80002c80:	64a2                	ld	s1,8(sp)
    80002c82:	6902                	ld	s2,0(sp)
    80002c84:	6105                	addi	sp,sp,32
    80002c86:	8082                	ret

0000000080002c88 <syscall>:
[SYS_sched_statistics]    sys_sched_statistics,// LAB2: Entry added that set as an function pointer to our system call 
};

void
syscall(void)
{
    80002c88:	1101                	addi	sp,sp,-32
    80002c8a:	ec06                	sd	ra,24(sp)
    80002c8c:	e822                	sd	s0,16(sp)
    80002c8e:	e426                	sd	s1,8(sp)
    80002c90:	e04a                	sd	s2,0(sp)
    80002c92:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	d1c080e7          	jalr	-740(ra) # 800019b0 <myproc>
    80002c9c:	84aa                	mv	s1,a0
  num = p->trapframe->a7;
    80002c9e:	05853903          	ld	s2,88(a0)
    80002ca2:	0a893783          	ld	a5,168(s2)
    80002ca6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002caa:	37fd                	addiw	a5,a5,-1
    80002cac:	4759                	li	a4,22
    80002cae:	00f76f63          	bltu	a4,a5,80002ccc <syscall+0x44>
    80002cb2:	00369713          	slli	a4,a3,0x3
    80002cb6:	00005797          	auipc	a5,0x5
    80002cba:	7c278793          	addi	a5,a5,1986 # 80008478 <syscalls>
    80002cbe:	97ba                	add	a5,a5,a4
    80002cc0:	639c                	ld	a5,0(a5)
    80002cc2:	c789                	beqz	a5,80002ccc <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();    
    80002cc4:	9782                	jalr	a5
    80002cc6:	06a93823          	sd	a0,112(s2)
    80002cca:	a839                	j	80002ce8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ccc:	15848613          	addi	a2,s1,344
    80002cd0:	588c                	lw	a1,48(s1)
    80002cd2:	00005517          	auipc	a0,0x5
    80002cd6:	76e50513          	addi	a0,a0,1902 # 80008440 <states.1732+0x150>
    80002cda:	ffffe097          	auipc	ra,0xffffe
    80002cde:	8ae080e7          	jalr	-1874(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ce2:	6cbc                	ld	a5,88(s1)
    80002ce4:	577d                	li	a4,-1
    80002ce6:	fbb8                	sd	a4,112(a5)
  }
}
    80002ce8:	60e2                	ld	ra,24(sp)
    80002cea:	6442                	ld	s0,16(sp)
    80002cec:	64a2                	ld	s1,8(sp)
    80002cee:	6902                	ld	s2,0(sp)
    80002cf0:	6105                	addi	sp,sp,32
    80002cf2:	8082                	ret

0000000080002cf4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cf4:	1101                	addi	sp,sp,-32
    80002cf6:	ec06                	sd	ra,24(sp)
    80002cf8:	e822                	sd	s0,16(sp)
    80002cfa:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002cfc:	fec40593          	addi	a1,s0,-20
    80002d00:	4501                	li	a0,0
    80002d02:	00000097          	auipc	ra,0x0
    80002d06:	f12080e7          	jalr	-238(ra) # 80002c14 <argint>
    return -1;
    80002d0a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d0c:	00054963          	bltz	a0,80002d1e <sys_exit+0x2a>
  exit(n);
    80002d10:	fec42503          	lw	a0,-20(s0)
    80002d14:	fffff097          	auipc	ra,0xfffff
    80002d18:	6ba080e7          	jalr	1722(ra) # 800023ce <exit>
  return 0;  // not reached
    80002d1c:	4781                	li	a5,0
}
    80002d1e:	853e                	mv	a0,a5
    80002d20:	60e2                	ld	ra,24(sp)
    80002d22:	6442                	ld	s0,16(sp)
    80002d24:	6105                	addi	sp,sp,32
    80002d26:	8082                	ret

0000000080002d28 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d28:	1141                	addi	sp,sp,-16
    80002d2a:	e406                	sd	ra,8(sp)
    80002d2c:	e022                	sd	s0,0(sp)
    80002d2e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	c80080e7          	jalr	-896(ra) # 800019b0 <myproc>
}
    80002d38:	5908                	lw	a0,48(a0)
    80002d3a:	60a2                	ld	ra,8(sp)
    80002d3c:	6402                	ld	s0,0(sp)
    80002d3e:	0141                	addi	sp,sp,16
    80002d40:	8082                	ret

0000000080002d42 <sys_fork>:

uint64
sys_fork(void)
{
    80002d42:	1141                	addi	sp,sp,-16
    80002d44:	e406                	sd	ra,8(sp)
    80002d46:	e022                	sd	s0,0(sp)
    80002d48:	0800                	addi	s0,sp,16
  return fork();
    80002d4a:	fffff097          	auipc	ra,0xfffff
    80002d4e:	03a080e7          	jalr	58(ra) # 80001d84 <fork>
}
    80002d52:	60a2                	ld	ra,8(sp)
    80002d54:	6402                	ld	s0,0(sp)
    80002d56:	0141                	addi	sp,sp,16
    80002d58:	8082                	ret

0000000080002d5a <sys_wait>:

uint64
sys_wait(void)
{
    80002d5a:	1101                	addi	sp,sp,-32
    80002d5c:	ec06                	sd	ra,24(sp)
    80002d5e:	e822                	sd	s0,16(sp)
    80002d60:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d62:	fe840593          	addi	a1,s0,-24
    80002d66:	4501                	li	a0,0
    80002d68:	00000097          	auipc	ra,0x0
    80002d6c:	ece080e7          	jalr	-306(ra) # 80002c36 <argaddr>
    80002d70:	87aa                	mv	a5,a0
    return -1;
    80002d72:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d74:	0007c863          	bltz	a5,80002d84 <sys_wait+0x2a>
  return wait(p);
    80002d78:	fe843503          	ld	a0,-24(s0)
    80002d7c:	fffff097          	auipc	ra,0xfffff
    80002d80:	45a080e7          	jalr	1114(ra) # 800021d6 <wait>
}
    80002d84:	60e2                	ld	ra,24(sp)
    80002d86:	6442                	ld	s0,16(sp)
    80002d88:	6105                	addi	sp,sp,32
    80002d8a:	8082                	ret

0000000080002d8c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d8c:	7179                	addi	sp,sp,-48
    80002d8e:	f406                	sd	ra,40(sp)
    80002d90:	f022                	sd	s0,32(sp)
    80002d92:	ec26                	sd	s1,24(sp)
    80002d94:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d96:	fdc40593          	addi	a1,s0,-36
    80002d9a:	4501                	li	a0,0
    80002d9c:	00000097          	auipc	ra,0x0
    80002da0:	e78080e7          	jalr	-392(ra) # 80002c14 <argint>
    80002da4:	87aa                	mv	a5,a0
    return -1;
    80002da6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002da8:	0207c063          	bltz	a5,80002dc8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002dac:	fffff097          	auipc	ra,0xfffff
    80002db0:	c04080e7          	jalr	-1020(ra) # 800019b0 <myproc>
    80002db4:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002db6:	fdc42503          	lw	a0,-36(s0)
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	f56080e7          	jalr	-170(ra) # 80001d10 <growproc>
    80002dc2:	00054863          	bltz	a0,80002dd2 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002dc6:	8526                	mv	a0,s1
}
    80002dc8:	70a2                	ld	ra,40(sp)
    80002dca:	7402                	ld	s0,32(sp)
    80002dcc:	64e2                	ld	s1,24(sp)
    80002dce:	6145                	addi	sp,sp,48
    80002dd0:	8082                	ret
    return -1;
    80002dd2:	557d                	li	a0,-1
    80002dd4:	bfd5                	j	80002dc8 <sys_sbrk+0x3c>

0000000080002dd6 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dd6:	7139                	addi	sp,sp,-64
    80002dd8:	fc06                	sd	ra,56(sp)
    80002dda:	f822                	sd	s0,48(sp)
    80002ddc:	f426                	sd	s1,40(sp)
    80002dde:	f04a                	sd	s2,32(sp)
    80002de0:	ec4e                	sd	s3,24(sp)
    80002de2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002de4:	fcc40593          	addi	a1,s0,-52
    80002de8:	4501                	li	a0,0
    80002dea:	00000097          	auipc	ra,0x0
    80002dee:	e2a080e7          	jalr	-470(ra) # 80002c14 <argint>
    return -1;
    80002df2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002df4:	06054563          	bltz	a0,80002e5e <sys_sleep+0x88>
  acquire(&tickslock);
    80002df8:	00014517          	auipc	a0,0x14
    80002dfc:	6d850513          	addi	a0,a0,1752 # 800174d0 <tickslock>
    80002e00:	ffffe097          	auipc	ra,0xffffe
    80002e04:	de4080e7          	jalr	-540(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002e08:	00006917          	auipc	s2,0x6
    80002e0c:	23092903          	lw	s2,560(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80002e10:	fcc42783          	lw	a5,-52(s0)
    80002e14:	cf85                	beqz	a5,80002e4c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e16:	00014997          	auipc	s3,0x14
    80002e1a:	6ba98993          	addi	s3,s3,1722 # 800174d0 <tickslock>
    80002e1e:	00006497          	auipc	s1,0x6
    80002e22:	21a48493          	addi	s1,s1,538 # 80009038 <ticks>
    if(myproc()->killed){
    80002e26:	fffff097          	auipc	ra,0xfffff
    80002e2a:	b8a080e7          	jalr	-1142(ra) # 800019b0 <myproc>
    80002e2e:	551c                	lw	a5,40(a0)
    80002e30:	ef9d                	bnez	a5,80002e6e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e32:	85ce                	mv	a1,s3
    80002e34:	8526                	mv	a0,s1
    80002e36:	fffff097          	auipc	ra,0xfffff
    80002e3a:	33c080e7          	jalr	828(ra) # 80002172 <sleep>
  while(ticks - ticks0 < n){
    80002e3e:	409c                	lw	a5,0(s1)
    80002e40:	412787bb          	subw	a5,a5,s2
    80002e44:	fcc42703          	lw	a4,-52(s0)
    80002e48:	fce7efe3          	bltu	a5,a4,80002e26 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e4c:	00014517          	auipc	a0,0x14
    80002e50:	68450513          	addi	a0,a0,1668 # 800174d0 <tickslock>
    80002e54:	ffffe097          	auipc	ra,0xffffe
    80002e58:	e44080e7          	jalr	-444(ra) # 80000c98 <release>
  return 0;
    80002e5c:	4781                	li	a5,0
}
    80002e5e:	853e                	mv	a0,a5
    80002e60:	70e2                	ld	ra,56(sp)
    80002e62:	7442                	ld	s0,48(sp)
    80002e64:	74a2                	ld	s1,40(sp)
    80002e66:	7902                	ld	s2,32(sp)
    80002e68:	69e2                	ld	s3,24(sp)
    80002e6a:	6121                	addi	sp,sp,64
    80002e6c:	8082                	ret
      release(&tickslock);
    80002e6e:	00014517          	auipc	a0,0x14
    80002e72:	66250513          	addi	a0,a0,1634 # 800174d0 <tickslock>
    80002e76:	ffffe097          	auipc	ra,0xffffe
    80002e7a:	e22080e7          	jalr	-478(ra) # 80000c98 <release>
      return -1;
    80002e7e:	57fd                	li	a5,-1
    80002e80:	bff9                	j	80002e5e <sys_sleep+0x88>

0000000080002e82 <sys_kill>:

uint64
sys_kill(void)
{
    80002e82:	1101                	addi	sp,sp,-32
    80002e84:	ec06                	sd	ra,24(sp)
    80002e86:	e822                	sd	s0,16(sp)
    80002e88:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e8a:	fec40593          	addi	a1,s0,-20
    80002e8e:	4501                	li	a0,0
    80002e90:	00000097          	auipc	ra,0x0
    80002e94:	d84080e7          	jalr	-636(ra) # 80002c14 <argint>
    80002e98:	87aa                	mv	a5,a0
    return -1;
    80002e9a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e9c:	0007c863          	bltz	a5,80002eac <sys_kill+0x2a>
  return kill(pid);
    80002ea0:	fec42503          	lw	a0,-20(s0)
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	600080e7          	jalr	1536(ra) # 800024a4 <kill>
}
    80002eac:	60e2                	ld	ra,24(sp)
    80002eae:	6442                	ld	s0,16(sp)
    80002eb0:	6105                	addi	sp,sp,32
    80002eb2:	8082                	ret

0000000080002eb4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002eb4:	1101                	addi	sp,sp,-32
    80002eb6:	ec06                	sd	ra,24(sp)
    80002eb8:	e822                	sd	s0,16(sp)
    80002eba:	e426                	sd	s1,8(sp)
    80002ebc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ebe:	00014517          	auipc	a0,0x14
    80002ec2:	61250513          	addi	a0,a0,1554 # 800174d0 <tickslock>
    80002ec6:	ffffe097          	auipc	ra,0xffffe
    80002eca:	d1e080e7          	jalr	-738(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002ece:	00006497          	auipc	s1,0x6
    80002ed2:	16a4a483          	lw	s1,362(s1) # 80009038 <ticks>
  release(&tickslock);
    80002ed6:	00014517          	auipc	a0,0x14
    80002eda:	5fa50513          	addi	a0,a0,1530 # 800174d0 <tickslock>
    80002ede:	ffffe097          	auipc	ra,0xffffe
    80002ee2:	dba080e7          	jalr	-582(ra) # 80000c98 <release>
  return xticks;
}
    80002ee6:	02049513          	slli	a0,s1,0x20
    80002eea:	9101                	srli	a0,a0,0x20
    80002eec:	60e2                	ld	ra,24(sp)
    80002eee:	6442                	ld	s0,16(sp)
    80002ef0:	64a2                	ld	s1,8(sp)
    80002ef2:	6105                	addi	sp,sp,32
    80002ef4:	8082                	ret

0000000080002ef6 <sys_sched_tickets>:
// LAB2 :: Process related system call functions are created here and

//Here system call sets the caller process's ticket value to the given parameter
uint64
sys_sched_tickets(void)
{
    80002ef6:	1101                	addi	sp,sp,-32
    80002ef8:	ec06                	sd	ra,24(sp)
    80002efa:	e822                	sd	s0,16(sp)
    80002efc:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002efe:	fec40593          	addi	a1,s0,-20
    80002f02:	4501                	li	a0,0
    80002f04:	00000097          	auipc	ra,0x0
    80002f08:	d10080e7          	jalr	-752(ra) # 80002c14 <argint>
  sched_tickets(n);
    80002f0c:	fec42503          	lw	a0,-20(s0)
    80002f10:	fffff097          	auipc	ra,0xfffff
    80002f14:	760080e7          	jalr	1888(ra) # 80002670 <sched_tickets>
  return 0;
}
    80002f18:	4501                	li	a0,0
    80002f1a:	60e2                	ld	ra,24(sp)
    80002f1c:	6442                	ld	s0,16(sp)
    80002f1e:	6105                	addi	sp,sp,32
    80002f20:	8082                	ret

0000000080002f22 <sys_sched_statistics>:

//system call that prints theeach process pid,name in parenthesis, ticket value, number of times it has been scheudled to run 
uint64
sys_sched_statistics(void)
{
    80002f22:	1141                	addi	sp,sp,-16
    80002f24:	e406                	sd	ra,8(sp)
    80002f26:	e022                	sd	s0,0(sp)
    80002f28:	0800                	addi	s0,sp,16
  sched_statistics();
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	780080e7          	jalr	1920(ra) # 800026aa <sched_statistics>
  return 0;
    80002f32:	4501                	li	a0,0
    80002f34:	60a2                	ld	ra,8(sp)
    80002f36:	6402                	ld	s0,0(sp)
    80002f38:	0141                	addi	sp,sp,16
    80002f3a:	8082                	ret

0000000080002f3c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f3c:	7179                	addi	sp,sp,-48
    80002f3e:	f406                	sd	ra,40(sp)
    80002f40:	f022                	sd	s0,32(sp)
    80002f42:	ec26                	sd	s1,24(sp)
    80002f44:	e84a                	sd	s2,16(sp)
    80002f46:	e44e                	sd	s3,8(sp)
    80002f48:	e052                	sd	s4,0(sp)
    80002f4a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f4c:	00005597          	auipc	a1,0x5
    80002f50:	5ec58593          	addi	a1,a1,1516 # 80008538 <syscalls+0xc0>
    80002f54:	00014517          	auipc	a0,0x14
    80002f58:	59450513          	addi	a0,a0,1428 # 800174e8 <bcache>
    80002f5c:	ffffe097          	auipc	ra,0xffffe
    80002f60:	bf8080e7          	jalr	-1032(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f64:	0001c797          	auipc	a5,0x1c
    80002f68:	58478793          	addi	a5,a5,1412 # 8001f4e8 <bcache+0x8000>
    80002f6c:	0001c717          	auipc	a4,0x1c
    80002f70:	7e470713          	addi	a4,a4,2020 # 8001f750 <bcache+0x8268>
    80002f74:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f78:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f7c:	00014497          	auipc	s1,0x14
    80002f80:	58448493          	addi	s1,s1,1412 # 80017500 <bcache+0x18>
    b->next = bcache.head.next;
    80002f84:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f86:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f88:	00005a17          	auipc	s4,0x5
    80002f8c:	5b8a0a13          	addi	s4,s4,1464 # 80008540 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f90:	2b893783          	ld	a5,696(s2)
    80002f94:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f96:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f9a:	85d2                	mv	a1,s4
    80002f9c:	01048513          	addi	a0,s1,16
    80002fa0:	00001097          	auipc	ra,0x1
    80002fa4:	4bc080e7          	jalr	1212(ra) # 8000445c <initsleeplock>
    bcache.head.next->prev = b;
    80002fa8:	2b893783          	ld	a5,696(s2)
    80002fac:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fae:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fb2:	45848493          	addi	s1,s1,1112
    80002fb6:	fd349de3          	bne	s1,s3,80002f90 <binit+0x54>
  }
}
    80002fba:	70a2                	ld	ra,40(sp)
    80002fbc:	7402                	ld	s0,32(sp)
    80002fbe:	64e2                	ld	s1,24(sp)
    80002fc0:	6942                	ld	s2,16(sp)
    80002fc2:	69a2                	ld	s3,8(sp)
    80002fc4:	6a02                	ld	s4,0(sp)
    80002fc6:	6145                	addi	sp,sp,48
    80002fc8:	8082                	ret

0000000080002fca <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fca:	7179                	addi	sp,sp,-48
    80002fcc:	f406                	sd	ra,40(sp)
    80002fce:	f022                	sd	s0,32(sp)
    80002fd0:	ec26                	sd	s1,24(sp)
    80002fd2:	e84a                	sd	s2,16(sp)
    80002fd4:	e44e                	sd	s3,8(sp)
    80002fd6:	1800                	addi	s0,sp,48
    80002fd8:	89aa                	mv	s3,a0
    80002fda:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fdc:	00014517          	auipc	a0,0x14
    80002fe0:	50c50513          	addi	a0,a0,1292 # 800174e8 <bcache>
    80002fe4:	ffffe097          	auipc	ra,0xffffe
    80002fe8:	c00080e7          	jalr	-1024(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fec:	0001c497          	auipc	s1,0x1c
    80002ff0:	7b44b483          	ld	s1,1972(s1) # 8001f7a0 <bcache+0x82b8>
    80002ff4:	0001c797          	auipc	a5,0x1c
    80002ff8:	75c78793          	addi	a5,a5,1884 # 8001f750 <bcache+0x8268>
    80002ffc:	02f48f63          	beq	s1,a5,8000303a <bread+0x70>
    80003000:	873e                	mv	a4,a5
    80003002:	a021                	j	8000300a <bread+0x40>
    80003004:	68a4                	ld	s1,80(s1)
    80003006:	02e48a63          	beq	s1,a4,8000303a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000300a:	449c                	lw	a5,8(s1)
    8000300c:	ff379ce3          	bne	a5,s3,80003004 <bread+0x3a>
    80003010:	44dc                	lw	a5,12(s1)
    80003012:	ff2799e3          	bne	a5,s2,80003004 <bread+0x3a>
      b->refcnt++;
    80003016:	40bc                	lw	a5,64(s1)
    80003018:	2785                	addiw	a5,a5,1
    8000301a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000301c:	00014517          	auipc	a0,0x14
    80003020:	4cc50513          	addi	a0,a0,1228 # 800174e8 <bcache>
    80003024:	ffffe097          	auipc	ra,0xffffe
    80003028:	c74080e7          	jalr	-908(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000302c:	01048513          	addi	a0,s1,16
    80003030:	00001097          	auipc	ra,0x1
    80003034:	466080e7          	jalr	1126(ra) # 80004496 <acquiresleep>
      return b;
    80003038:	a8b9                	j	80003096 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000303a:	0001c497          	auipc	s1,0x1c
    8000303e:	75e4b483          	ld	s1,1886(s1) # 8001f798 <bcache+0x82b0>
    80003042:	0001c797          	auipc	a5,0x1c
    80003046:	70e78793          	addi	a5,a5,1806 # 8001f750 <bcache+0x8268>
    8000304a:	00f48863          	beq	s1,a5,8000305a <bread+0x90>
    8000304e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003050:	40bc                	lw	a5,64(s1)
    80003052:	cf81                	beqz	a5,8000306a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003054:	64a4                	ld	s1,72(s1)
    80003056:	fee49de3          	bne	s1,a4,80003050 <bread+0x86>
  panic("bget: no buffers");
    8000305a:	00005517          	auipc	a0,0x5
    8000305e:	4ee50513          	addi	a0,a0,1262 # 80008548 <syscalls+0xd0>
    80003062:	ffffd097          	auipc	ra,0xffffd
    80003066:	4dc080e7          	jalr	1244(ra) # 8000053e <panic>
      b->dev = dev;
    8000306a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000306e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003072:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003076:	4785                	li	a5,1
    80003078:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000307a:	00014517          	auipc	a0,0x14
    8000307e:	46e50513          	addi	a0,a0,1134 # 800174e8 <bcache>
    80003082:	ffffe097          	auipc	ra,0xffffe
    80003086:	c16080e7          	jalr	-1002(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000308a:	01048513          	addi	a0,s1,16
    8000308e:	00001097          	auipc	ra,0x1
    80003092:	408080e7          	jalr	1032(ra) # 80004496 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003096:	409c                	lw	a5,0(s1)
    80003098:	cb89                	beqz	a5,800030aa <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000309a:	8526                	mv	a0,s1
    8000309c:	70a2                	ld	ra,40(sp)
    8000309e:	7402                	ld	s0,32(sp)
    800030a0:	64e2                	ld	s1,24(sp)
    800030a2:	6942                	ld	s2,16(sp)
    800030a4:	69a2                	ld	s3,8(sp)
    800030a6:	6145                	addi	sp,sp,48
    800030a8:	8082                	ret
    virtio_disk_rw(b, 0);
    800030aa:	4581                	li	a1,0
    800030ac:	8526                	mv	a0,s1
    800030ae:	00003097          	auipc	ra,0x3
    800030b2:	f08080e7          	jalr	-248(ra) # 80005fb6 <virtio_disk_rw>
    b->valid = 1;
    800030b6:	4785                	li	a5,1
    800030b8:	c09c                	sw	a5,0(s1)
  return b;
    800030ba:	b7c5                	j	8000309a <bread+0xd0>

00000000800030bc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030bc:	1101                	addi	sp,sp,-32
    800030be:	ec06                	sd	ra,24(sp)
    800030c0:	e822                	sd	s0,16(sp)
    800030c2:	e426                	sd	s1,8(sp)
    800030c4:	1000                	addi	s0,sp,32
    800030c6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030c8:	0541                	addi	a0,a0,16
    800030ca:	00001097          	auipc	ra,0x1
    800030ce:	466080e7          	jalr	1126(ra) # 80004530 <holdingsleep>
    800030d2:	cd01                	beqz	a0,800030ea <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030d4:	4585                	li	a1,1
    800030d6:	8526                	mv	a0,s1
    800030d8:	00003097          	auipc	ra,0x3
    800030dc:	ede080e7          	jalr	-290(ra) # 80005fb6 <virtio_disk_rw>
}
    800030e0:	60e2                	ld	ra,24(sp)
    800030e2:	6442                	ld	s0,16(sp)
    800030e4:	64a2                	ld	s1,8(sp)
    800030e6:	6105                	addi	sp,sp,32
    800030e8:	8082                	ret
    panic("bwrite");
    800030ea:	00005517          	auipc	a0,0x5
    800030ee:	47650513          	addi	a0,a0,1142 # 80008560 <syscalls+0xe8>
    800030f2:	ffffd097          	auipc	ra,0xffffd
    800030f6:	44c080e7          	jalr	1100(ra) # 8000053e <panic>

00000000800030fa <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030fa:	1101                	addi	sp,sp,-32
    800030fc:	ec06                	sd	ra,24(sp)
    800030fe:	e822                	sd	s0,16(sp)
    80003100:	e426                	sd	s1,8(sp)
    80003102:	e04a                	sd	s2,0(sp)
    80003104:	1000                	addi	s0,sp,32
    80003106:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003108:	01050913          	addi	s2,a0,16
    8000310c:	854a                	mv	a0,s2
    8000310e:	00001097          	auipc	ra,0x1
    80003112:	422080e7          	jalr	1058(ra) # 80004530 <holdingsleep>
    80003116:	c92d                	beqz	a0,80003188 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003118:	854a                	mv	a0,s2
    8000311a:	00001097          	auipc	ra,0x1
    8000311e:	3d2080e7          	jalr	978(ra) # 800044ec <releasesleep>

  acquire(&bcache.lock);
    80003122:	00014517          	auipc	a0,0x14
    80003126:	3c650513          	addi	a0,a0,966 # 800174e8 <bcache>
    8000312a:	ffffe097          	auipc	ra,0xffffe
    8000312e:	aba080e7          	jalr	-1350(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003132:	40bc                	lw	a5,64(s1)
    80003134:	37fd                	addiw	a5,a5,-1
    80003136:	0007871b          	sext.w	a4,a5
    8000313a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000313c:	eb05                	bnez	a4,8000316c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000313e:	68bc                	ld	a5,80(s1)
    80003140:	64b8                	ld	a4,72(s1)
    80003142:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003144:	64bc                	ld	a5,72(s1)
    80003146:	68b8                	ld	a4,80(s1)
    80003148:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000314a:	0001c797          	auipc	a5,0x1c
    8000314e:	39e78793          	addi	a5,a5,926 # 8001f4e8 <bcache+0x8000>
    80003152:	2b87b703          	ld	a4,696(a5)
    80003156:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003158:	0001c717          	auipc	a4,0x1c
    8000315c:	5f870713          	addi	a4,a4,1528 # 8001f750 <bcache+0x8268>
    80003160:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003162:	2b87b703          	ld	a4,696(a5)
    80003166:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003168:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000316c:	00014517          	auipc	a0,0x14
    80003170:	37c50513          	addi	a0,a0,892 # 800174e8 <bcache>
    80003174:	ffffe097          	auipc	ra,0xffffe
    80003178:	b24080e7          	jalr	-1244(ra) # 80000c98 <release>
}
    8000317c:	60e2                	ld	ra,24(sp)
    8000317e:	6442                	ld	s0,16(sp)
    80003180:	64a2                	ld	s1,8(sp)
    80003182:	6902                	ld	s2,0(sp)
    80003184:	6105                	addi	sp,sp,32
    80003186:	8082                	ret
    panic("brelse");
    80003188:	00005517          	auipc	a0,0x5
    8000318c:	3e050513          	addi	a0,a0,992 # 80008568 <syscalls+0xf0>
    80003190:	ffffd097          	auipc	ra,0xffffd
    80003194:	3ae080e7          	jalr	942(ra) # 8000053e <panic>

0000000080003198 <bpin>:

void
bpin(struct buf *b) {
    80003198:	1101                	addi	sp,sp,-32
    8000319a:	ec06                	sd	ra,24(sp)
    8000319c:	e822                	sd	s0,16(sp)
    8000319e:	e426                	sd	s1,8(sp)
    800031a0:	1000                	addi	s0,sp,32
    800031a2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031a4:	00014517          	auipc	a0,0x14
    800031a8:	34450513          	addi	a0,a0,836 # 800174e8 <bcache>
    800031ac:	ffffe097          	auipc	ra,0xffffe
    800031b0:	a38080e7          	jalr	-1480(ra) # 80000be4 <acquire>
  b->refcnt++;
    800031b4:	40bc                	lw	a5,64(s1)
    800031b6:	2785                	addiw	a5,a5,1
    800031b8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031ba:	00014517          	auipc	a0,0x14
    800031be:	32e50513          	addi	a0,a0,814 # 800174e8 <bcache>
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	ad6080e7          	jalr	-1322(ra) # 80000c98 <release>
}
    800031ca:	60e2                	ld	ra,24(sp)
    800031cc:	6442                	ld	s0,16(sp)
    800031ce:	64a2                	ld	s1,8(sp)
    800031d0:	6105                	addi	sp,sp,32
    800031d2:	8082                	ret

00000000800031d4 <bunpin>:

void
bunpin(struct buf *b) {
    800031d4:	1101                	addi	sp,sp,-32
    800031d6:	ec06                	sd	ra,24(sp)
    800031d8:	e822                	sd	s0,16(sp)
    800031da:	e426                	sd	s1,8(sp)
    800031dc:	1000                	addi	s0,sp,32
    800031de:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031e0:	00014517          	auipc	a0,0x14
    800031e4:	30850513          	addi	a0,a0,776 # 800174e8 <bcache>
    800031e8:	ffffe097          	auipc	ra,0xffffe
    800031ec:	9fc080e7          	jalr	-1540(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031f0:	40bc                	lw	a5,64(s1)
    800031f2:	37fd                	addiw	a5,a5,-1
    800031f4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031f6:	00014517          	auipc	a0,0x14
    800031fa:	2f250513          	addi	a0,a0,754 # 800174e8 <bcache>
    800031fe:	ffffe097          	auipc	ra,0xffffe
    80003202:	a9a080e7          	jalr	-1382(ra) # 80000c98 <release>
}
    80003206:	60e2                	ld	ra,24(sp)
    80003208:	6442                	ld	s0,16(sp)
    8000320a:	64a2                	ld	s1,8(sp)
    8000320c:	6105                	addi	sp,sp,32
    8000320e:	8082                	ret

0000000080003210 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003210:	1101                	addi	sp,sp,-32
    80003212:	ec06                	sd	ra,24(sp)
    80003214:	e822                	sd	s0,16(sp)
    80003216:	e426                	sd	s1,8(sp)
    80003218:	e04a                	sd	s2,0(sp)
    8000321a:	1000                	addi	s0,sp,32
    8000321c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000321e:	00d5d59b          	srliw	a1,a1,0xd
    80003222:	0001d797          	auipc	a5,0x1d
    80003226:	9a27a783          	lw	a5,-1630(a5) # 8001fbc4 <sb+0x1c>
    8000322a:	9dbd                	addw	a1,a1,a5
    8000322c:	00000097          	auipc	ra,0x0
    80003230:	d9e080e7          	jalr	-610(ra) # 80002fca <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003234:	0074f713          	andi	a4,s1,7
    80003238:	4785                	li	a5,1
    8000323a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000323e:	14ce                	slli	s1,s1,0x33
    80003240:	90d9                	srli	s1,s1,0x36
    80003242:	00950733          	add	a4,a0,s1
    80003246:	05874703          	lbu	a4,88(a4)
    8000324a:	00e7f6b3          	and	a3,a5,a4
    8000324e:	c69d                	beqz	a3,8000327c <bfree+0x6c>
    80003250:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003252:	94aa                	add	s1,s1,a0
    80003254:	fff7c793          	not	a5,a5
    80003258:	8ff9                	and	a5,a5,a4
    8000325a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000325e:	00001097          	auipc	ra,0x1
    80003262:	118080e7          	jalr	280(ra) # 80004376 <log_write>
  brelse(bp);
    80003266:	854a                	mv	a0,s2
    80003268:	00000097          	auipc	ra,0x0
    8000326c:	e92080e7          	jalr	-366(ra) # 800030fa <brelse>
}
    80003270:	60e2                	ld	ra,24(sp)
    80003272:	6442                	ld	s0,16(sp)
    80003274:	64a2                	ld	s1,8(sp)
    80003276:	6902                	ld	s2,0(sp)
    80003278:	6105                	addi	sp,sp,32
    8000327a:	8082                	ret
    panic("freeing free block");
    8000327c:	00005517          	auipc	a0,0x5
    80003280:	2f450513          	addi	a0,a0,756 # 80008570 <syscalls+0xf8>
    80003284:	ffffd097          	auipc	ra,0xffffd
    80003288:	2ba080e7          	jalr	698(ra) # 8000053e <panic>

000000008000328c <balloc>:
{
    8000328c:	711d                	addi	sp,sp,-96
    8000328e:	ec86                	sd	ra,88(sp)
    80003290:	e8a2                	sd	s0,80(sp)
    80003292:	e4a6                	sd	s1,72(sp)
    80003294:	e0ca                	sd	s2,64(sp)
    80003296:	fc4e                	sd	s3,56(sp)
    80003298:	f852                	sd	s4,48(sp)
    8000329a:	f456                	sd	s5,40(sp)
    8000329c:	f05a                	sd	s6,32(sp)
    8000329e:	ec5e                	sd	s7,24(sp)
    800032a0:	e862                	sd	s8,16(sp)
    800032a2:	e466                	sd	s9,8(sp)
    800032a4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032a6:	0001d797          	auipc	a5,0x1d
    800032aa:	9067a783          	lw	a5,-1786(a5) # 8001fbac <sb+0x4>
    800032ae:	cbd1                	beqz	a5,80003342 <balloc+0xb6>
    800032b0:	8baa                	mv	s7,a0
    800032b2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032b4:	0001db17          	auipc	s6,0x1d
    800032b8:	8f4b0b13          	addi	s6,s6,-1804 # 8001fba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032bc:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032be:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032c0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032c2:	6c89                	lui	s9,0x2
    800032c4:	a831                	j	800032e0 <balloc+0x54>
    brelse(bp);
    800032c6:	854a                	mv	a0,s2
    800032c8:	00000097          	auipc	ra,0x0
    800032cc:	e32080e7          	jalr	-462(ra) # 800030fa <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032d0:	015c87bb          	addw	a5,s9,s5
    800032d4:	00078a9b          	sext.w	s5,a5
    800032d8:	004b2703          	lw	a4,4(s6)
    800032dc:	06eaf363          	bgeu	s5,a4,80003342 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032e0:	41fad79b          	sraiw	a5,s5,0x1f
    800032e4:	0137d79b          	srliw	a5,a5,0x13
    800032e8:	015787bb          	addw	a5,a5,s5
    800032ec:	40d7d79b          	sraiw	a5,a5,0xd
    800032f0:	01cb2583          	lw	a1,28(s6)
    800032f4:	9dbd                	addw	a1,a1,a5
    800032f6:	855e                	mv	a0,s7
    800032f8:	00000097          	auipc	ra,0x0
    800032fc:	cd2080e7          	jalr	-814(ra) # 80002fca <bread>
    80003300:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003302:	004b2503          	lw	a0,4(s6)
    80003306:	000a849b          	sext.w	s1,s5
    8000330a:	8662                	mv	a2,s8
    8000330c:	faa4fde3          	bgeu	s1,a0,800032c6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003310:	41f6579b          	sraiw	a5,a2,0x1f
    80003314:	01d7d69b          	srliw	a3,a5,0x1d
    80003318:	00c6873b          	addw	a4,a3,a2
    8000331c:	00777793          	andi	a5,a4,7
    80003320:	9f95                	subw	a5,a5,a3
    80003322:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003326:	4037571b          	sraiw	a4,a4,0x3
    8000332a:	00e906b3          	add	a3,s2,a4
    8000332e:	0586c683          	lbu	a3,88(a3)
    80003332:	00d7f5b3          	and	a1,a5,a3
    80003336:	cd91                	beqz	a1,80003352 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003338:	2605                	addiw	a2,a2,1
    8000333a:	2485                	addiw	s1,s1,1
    8000333c:	fd4618e3          	bne	a2,s4,8000330c <balloc+0x80>
    80003340:	b759                	j	800032c6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003342:	00005517          	auipc	a0,0x5
    80003346:	24650513          	addi	a0,a0,582 # 80008588 <syscalls+0x110>
    8000334a:	ffffd097          	auipc	ra,0xffffd
    8000334e:	1f4080e7          	jalr	500(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003352:	974a                	add	a4,a4,s2
    80003354:	8fd5                	or	a5,a5,a3
    80003356:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000335a:	854a                	mv	a0,s2
    8000335c:	00001097          	auipc	ra,0x1
    80003360:	01a080e7          	jalr	26(ra) # 80004376 <log_write>
        brelse(bp);
    80003364:	854a                	mv	a0,s2
    80003366:	00000097          	auipc	ra,0x0
    8000336a:	d94080e7          	jalr	-620(ra) # 800030fa <brelse>
  bp = bread(dev, bno);
    8000336e:	85a6                	mv	a1,s1
    80003370:	855e                	mv	a0,s7
    80003372:	00000097          	auipc	ra,0x0
    80003376:	c58080e7          	jalr	-936(ra) # 80002fca <bread>
    8000337a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000337c:	40000613          	li	a2,1024
    80003380:	4581                	li	a1,0
    80003382:	05850513          	addi	a0,a0,88
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	95a080e7          	jalr	-1702(ra) # 80000ce0 <memset>
  log_write(bp);
    8000338e:	854a                	mv	a0,s2
    80003390:	00001097          	auipc	ra,0x1
    80003394:	fe6080e7          	jalr	-26(ra) # 80004376 <log_write>
  brelse(bp);
    80003398:	854a                	mv	a0,s2
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	d60080e7          	jalr	-672(ra) # 800030fa <brelse>
}
    800033a2:	8526                	mv	a0,s1
    800033a4:	60e6                	ld	ra,88(sp)
    800033a6:	6446                	ld	s0,80(sp)
    800033a8:	64a6                	ld	s1,72(sp)
    800033aa:	6906                	ld	s2,64(sp)
    800033ac:	79e2                	ld	s3,56(sp)
    800033ae:	7a42                	ld	s4,48(sp)
    800033b0:	7aa2                	ld	s5,40(sp)
    800033b2:	7b02                	ld	s6,32(sp)
    800033b4:	6be2                	ld	s7,24(sp)
    800033b6:	6c42                	ld	s8,16(sp)
    800033b8:	6ca2                	ld	s9,8(sp)
    800033ba:	6125                	addi	sp,sp,96
    800033bc:	8082                	ret

00000000800033be <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033be:	7179                	addi	sp,sp,-48
    800033c0:	f406                	sd	ra,40(sp)
    800033c2:	f022                	sd	s0,32(sp)
    800033c4:	ec26                	sd	s1,24(sp)
    800033c6:	e84a                	sd	s2,16(sp)
    800033c8:	e44e                	sd	s3,8(sp)
    800033ca:	e052                	sd	s4,0(sp)
    800033cc:	1800                	addi	s0,sp,48
    800033ce:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033d0:	47ad                	li	a5,11
    800033d2:	04b7fe63          	bgeu	a5,a1,8000342e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033d6:	ff45849b          	addiw	s1,a1,-12
    800033da:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033de:	0ff00793          	li	a5,255
    800033e2:	0ae7e363          	bltu	a5,a4,80003488 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033e6:	08052583          	lw	a1,128(a0)
    800033ea:	c5ad                	beqz	a1,80003454 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033ec:	00092503          	lw	a0,0(s2)
    800033f0:	00000097          	auipc	ra,0x0
    800033f4:	bda080e7          	jalr	-1062(ra) # 80002fca <bread>
    800033f8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033fa:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033fe:	02049593          	slli	a1,s1,0x20
    80003402:	9181                	srli	a1,a1,0x20
    80003404:	058a                	slli	a1,a1,0x2
    80003406:	00b784b3          	add	s1,a5,a1
    8000340a:	0004a983          	lw	s3,0(s1)
    8000340e:	04098d63          	beqz	s3,80003468 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003412:	8552                	mv	a0,s4
    80003414:	00000097          	auipc	ra,0x0
    80003418:	ce6080e7          	jalr	-794(ra) # 800030fa <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000341c:	854e                	mv	a0,s3
    8000341e:	70a2                	ld	ra,40(sp)
    80003420:	7402                	ld	s0,32(sp)
    80003422:	64e2                	ld	s1,24(sp)
    80003424:	6942                	ld	s2,16(sp)
    80003426:	69a2                	ld	s3,8(sp)
    80003428:	6a02                	ld	s4,0(sp)
    8000342a:	6145                	addi	sp,sp,48
    8000342c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000342e:	02059493          	slli	s1,a1,0x20
    80003432:	9081                	srli	s1,s1,0x20
    80003434:	048a                	slli	s1,s1,0x2
    80003436:	94aa                	add	s1,s1,a0
    80003438:	0504a983          	lw	s3,80(s1)
    8000343c:	fe0990e3          	bnez	s3,8000341c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003440:	4108                	lw	a0,0(a0)
    80003442:	00000097          	auipc	ra,0x0
    80003446:	e4a080e7          	jalr	-438(ra) # 8000328c <balloc>
    8000344a:	0005099b          	sext.w	s3,a0
    8000344e:	0534a823          	sw	s3,80(s1)
    80003452:	b7e9                	j	8000341c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003454:	4108                	lw	a0,0(a0)
    80003456:	00000097          	auipc	ra,0x0
    8000345a:	e36080e7          	jalr	-458(ra) # 8000328c <balloc>
    8000345e:	0005059b          	sext.w	a1,a0
    80003462:	08b92023          	sw	a1,128(s2)
    80003466:	b759                	j	800033ec <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003468:	00092503          	lw	a0,0(s2)
    8000346c:	00000097          	auipc	ra,0x0
    80003470:	e20080e7          	jalr	-480(ra) # 8000328c <balloc>
    80003474:	0005099b          	sext.w	s3,a0
    80003478:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000347c:	8552                	mv	a0,s4
    8000347e:	00001097          	auipc	ra,0x1
    80003482:	ef8080e7          	jalr	-264(ra) # 80004376 <log_write>
    80003486:	b771                	j	80003412 <bmap+0x54>
  panic("bmap: out of range");
    80003488:	00005517          	auipc	a0,0x5
    8000348c:	11850513          	addi	a0,a0,280 # 800085a0 <syscalls+0x128>
    80003490:	ffffd097          	auipc	ra,0xffffd
    80003494:	0ae080e7          	jalr	174(ra) # 8000053e <panic>

0000000080003498 <iget>:
{
    80003498:	7179                	addi	sp,sp,-48
    8000349a:	f406                	sd	ra,40(sp)
    8000349c:	f022                	sd	s0,32(sp)
    8000349e:	ec26                	sd	s1,24(sp)
    800034a0:	e84a                	sd	s2,16(sp)
    800034a2:	e44e                	sd	s3,8(sp)
    800034a4:	e052                	sd	s4,0(sp)
    800034a6:	1800                	addi	s0,sp,48
    800034a8:	89aa                	mv	s3,a0
    800034aa:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034ac:	0001c517          	auipc	a0,0x1c
    800034b0:	71c50513          	addi	a0,a0,1820 # 8001fbc8 <itable>
    800034b4:	ffffd097          	auipc	ra,0xffffd
    800034b8:	730080e7          	jalr	1840(ra) # 80000be4 <acquire>
  empty = 0;
    800034bc:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034be:	0001c497          	auipc	s1,0x1c
    800034c2:	72248493          	addi	s1,s1,1826 # 8001fbe0 <itable+0x18>
    800034c6:	0001e697          	auipc	a3,0x1e
    800034ca:	1aa68693          	addi	a3,a3,426 # 80021670 <log>
    800034ce:	a039                	j	800034dc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034d0:	02090b63          	beqz	s2,80003506 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034d4:	08848493          	addi	s1,s1,136
    800034d8:	02d48a63          	beq	s1,a3,8000350c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034dc:	449c                	lw	a5,8(s1)
    800034de:	fef059e3          	blez	a5,800034d0 <iget+0x38>
    800034e2:	4098                	lw	a4,0(s1)
    800034e4:	ff3716e3          	bne	a4,s3,800034d0 <iget+0x38>
    800034e8:	40d8                	lw	a4,4(s1)
    800034ea:	ff4713e3          	bne	a4,s4,800034d0 <iget+0x38>
      ip->ref++;
    800034ee:	2785                	addiw	a5,a5,1
    800034f0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034f2:	0001c517          	auipc	a0,0x1c
    800034f6:	6d650513          	addi	a0,a0,1750 # 8001fbc8 <itable>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	79e080e7          	jalr	1950(ra) # 80000c98 <release>
      return ip;
    80003502:	8926                	mv	s2,s1
    80003504:	a03d                	j	80003532 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003506:	f7f9                	bnez	a5,800034d4 <iget+0x3c>
    80003508:	8926                	mv	s2,s1
    8000350a:	b7e9                	j	800034d4 <iget+0x3c>
  if(empty == 0)
    8000350c:	02090c63          	beqz	s2,80003544 <iget+0xac>
  ip->dev = dev;
    80003510:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003514:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003518:	4785                	li	a5,1
    8000351a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000351e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003522:	0001c517          	auipc	a0,0x1c
    80003526:	6a650513          	addi	a0,a0,1702 # 8001fbc8 <itable>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	76e080e7          	jalr	1902(ra) # 80000c98 <release>
}
    80003532:	854a                	mv	a0,s2
    80003534:	70a2                	ld	ra,40(sp)
    80003536:	7402                	ld	s0,32(sp)
    80003538:	64e2                	ld	s1,24(sp)
    8000353a:	6942                	ld	s2,16(sp)
    8000353c:	69a2                	ld	s3,8(sp)
    8000353e:	6a02                	ld	s4,0(sp)
    80003540:	6145                	addi	sp,sp,48
    80003542:	8082                	ret
    panic("iget: no inodes");
    80003544:	00005517          	auipc	a0,0x5
    80003548:	07450513          	addi	a0,a0,116 # 800085b8 <syscalls+0x140>
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	ff2080e7          	jalr	-14(ra) # 8000053e <panic>

0000000080003554 <fsinit>:
fsinit(int dev) {
    80003554:	7179                	addi	sp,sp,-48
    80003556:	f406                	sd	ra,40(sp)
    80003558:	f022                	sd	s0,32(sp)
    8000355a:	ec26                	sd	s1,24(sp)
    8000355c:	e84a                	sd	s2,16(sp)
    8000355e:	e44e                	sd	s3,8(sp)
    80003560:	1800                	addi	s0,sp,48
    80003562:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003564:	4585                	li	a1,1
    80003566:	00000097          	auipc	ra,0x0
    8000356a:	a64080e7          	jalr	-1436(ra) # 80002fca <bread>
    8000356e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003570:	0001c997          	auipc	s3,0x1c
    80003574:	63898993          	addi	s3,s3,1592 # 8001fba8 <sb>
    80003578:	02000613          	li	a2,32
    8000357c:	05850593          	addi	a1,a0,88
    80003580:	854e                	mv	a0,s3
    80003582:	ffffd097          	auipc	ra,0xffffd
    80003586:	7be080e7          	jalr	1982(ra) # 80000d40 <memmove>
  brelse(bp);
    8000358a:	8526                	mv	a0,s1
    8000358c:	00000097          	auipc	ra,0x0
    80003590:	b6e080e7          	jalr	-1170(ra) # 800030fa <brelse>
  if(sb.magic != FSMAGIC)
    80003594:	0009a703          	lw	a4,0(s3)
    80003598:	102037b7          	lui	a5,0x10203
    8000359c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035a0:	02f71263          	bne	a4,a5,800035c4 <fsinit+0x70>
  initlog(dev, &sb);
    800035a4:	0001c597          	auipc	a1,0x1c
    800035a8:	60458593          	addi	a1,a1,1540 # 8001fba8 <sb>
    800035ac:	854a                	mv	a0,s2
    800035ae:	00001097          	auipc	ra,0x1
    800035b2:	b4c080e7          	jalr	-1204(ra) # 800040fa <initlog>
}
    800035b6:	70a2                	ld	ra,40(sp)
    800035b8:	7402                	ld	s0,32(sp)
    800035ba:	64e2                	ld	s1,24(sp)
    800035bc:	6942                	ld	s2,16(sp)
    800035be:	69a2                	ld	s3,8(sp)
    800035c0:	6145                	addi	sp,sp,48
    800035c2:	8082                	ret
    panic("invalid file system");
    800035c4:	00005517          	auipc	a0,0x5
    800035c8:	00450513          	addi	a0,a0,4 # 800085c8 <syscalls+0x150>
    800035cc:	ffffd097          	auipc	ra,0xffffd
    800035d0:	f72080e7          	jalr	-142(ra) # 8000053e <panic>

00000000800035d4 <iinit>:
{
    800035d4:	7179                	addi	sp,sp,-48
    800035d6:	f406                	sd	ra,40(sp)
    800035d8:	f022                	sd	s0,32(sp)
    800035da:	ec26                	sd	s1,24(sp)
    800035dc:	e84a                	sd	s2,16(sp)
    800035de:	e44e                	sd	s3,8(sp)
    800035e0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035e2:	00005597          	auipc	a1,0x5
    800035e6:	ffe58593          	addi	a1,a1,-2 # 800085e0 <syscalls+0x168>
    800035ea:	0001c517          	auipc	a0,0x1c
    800035ee:	5de50513          	addi	a0,a0,1502 # 8001fbc8 <itable>
    800035f2:	ffffd097          	auipc	ra,0xffffd
    800035f6:	562080e7          	jalr	1378(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035fa:	0001c497          	auipc	s1,0x1c
    800035fe:	5f648493          	addi	s1,s1,1526 # 8001fbf0 <itable+0x28>
    80003602:	0001e997          	auipc	s3,0x1e
    80003606:	07e98993          	addi	s3,s3,126 # 80021680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000360a:	00005917          	auipc	s2,0x5
    8000360e:	fde90913          	addi	s2,s2,-34 # 800085e8 <syscalls+0x170>
    80003612:	85ca                	mv	a1,s2
    80003614:	8526                	mv	a0,s1
    80003616:	00001097          	auipc	ra,0x1
    8000361a:	e46080e7          	jalr	-442(ra) # 8000445c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000361e:	08848493          	addi	s1,s1,136
    80003622:	ff3498e3          	bne	s1,s3,80003612 <iinit+0x3e>
}
    80003626:	70a2                	ld	ra,40(sp)
    80003628:	7402                	ld	s0,32(sp)
    8000362a:	64e2                	ld	s1,24(sp)
    8000362c:	6942                	ld	s2,16(sp)
    8000362e:	69a2                	ld	s3,8(sp)
    80003630:	6145                	addi	sp,sp,48
    80003632:	8082                	ret

0000000080003634 <ialloc>:
{
    80003634:	715d                	addi	sp,sp,-80
    80003636:	e486                	sd	ra,72(sp)
    80003638:	e0a2                	sd	s0,64(sp)
    8000363a:	fc26                	sd	s1,56(sp)
    8000363c:	f84a                	sd	s2,48(sp)
    8000363e:	f44e                	sd	s3,40(sp)
    80003640:	f052                	sd	s4,32(sp)
    80003642:	ec56                	sd	s5,24(sp)
    80003644:	e85a                	sd	s6,16(sp)
    80003646:	e45e                	sd	s7,8(sp)
    80003648:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000364a:	0001c717          	auipc	a4,0x1c
    8000364e:	56a72703          	lw	a4,1386(a4) # 8001fbb4 <sb+0xc>
    80003652:	4785                	li	a5,1
    80003654:	04e7fa63          	bgeu	a5,a4,800036a8 <ialloc+0x74>
    80003658:	8aaa                	mv	s5,a0
    8000365a:	8bae                	mv	s7,a1
    8000365c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000365e:	0001ca17          	auipc	s4,0x1c
    80003662:	54aa0a13          	addi	s4,s4,1354 # 8001fba8 <sb>
    80003666:	00048b1b          	sext.w	s6,s1
    8000366a:	0044d593          	srli	a1,s1,0x4
    8000366e:	018a2783          	lw	a5,24(s4)
    80003672:	9dbd                	addw	a1,a1,a5
    80003674:	8556                	mv	a0,s5
    80003676:	00000097          	auipc	ra,0x0
    8000367a:	954080e7          	jalr	-1708(ra) # 80002fca <bread>
    8000367e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003680:	05850993          	addi	s3,a0,88
    80003684:	00f4f793          	andi	a5,s1,15
    80003688:	079a                	slli	a5,a5,0x6
    8000368a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000368c:	00099783          	lh	a5,0(s3)
    80003690:	c785                	beqz	a5,800036b8 <ialloc+0x84>
    brelse(bp);
    80003692:	00000097          	auipc	ra,0x0
    80003696:	a68080e7          	jalr	-1432(ra) # 800030fa <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000369a:	0485                	addi	s1,s1,1
    8000369c:	00ca2703          	lw	a4,12(s4)
    800036a0:	0004879b          	sext.w	a5,s1
    800036a4:	fce7e1e3          	bltu	a5,a4,80003666 <ialloc+0x32>
  panic("ialloc: no inodes");
    800036a8:	00005517          	auipc	a0,0x5
    800036ac:	f4850513          	addi	a0,a0,-184 # 800085f0 <syscalls+0x178>
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	e8e080e7          	jalr	-370(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800036b8:	04000613          	li	a2,64
    800036bc:	4581                	li	a1,0
    800036be:	854e                	mv	a0,s3
    800036c0:	ffffd097          	auipc	ra,0xffffd
    800036c4:	620080e7          	jalr	1568(ra) # 80000ce0 <memset>
      dip->type = type;
    800036c8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036cc:	854a                	mv	a0,s2
    800036ce:	00001097          	auipc	ra,0x1
    800036d2:	ca8080e7          	jalr	-856(ra) # 80004376 <log_write>
      brelse(bp);
    800036d6:	854a                	mv	a0,s2
    800036d8:	00000097          	auipc	ra,0x0
    800036dc:	a22080e7          	jalr	-1502(ra) # 800030fa <brelse>
      return iget(dev, inum);
    800036e0:	85da                	mv	a1,s6
    800036e2:	8556                	mv	a0,s5
    800036e4:	00000097          	auipc	ra,0x0
    800036e8:	db4080e7          	jalr	-588(ra) # 80003498 <iget>
}
    800036ec:	60a6                	ld	ra,72(sp)
    800036ee:	6406                	ld	s0,64(sp)
    800036f0:	74e2                	ld	s1,56(sp)
    800036f2:	7942                	ld	s2,48(sp)
    800036f4:	79a2                	ld	s3,40(sp)
    800036f6:	7a02                	ld	s4,32(sp)
    800036f8:	6ae2                	ld	s5,24(sp)
    800036fa:	6b42                	ld	s6,16(sp)
    800036fc:	6ba2                	ld	s7,8(sp)
    800036fe:	6161                	addi	sp,sp,80
    80003700:	8082                	ret

0000000080003702 <iupdate>:
{
    80003702:	1101                	addi	sp,sp,-32
    80003704:	ec06                	sd	ra,24(sp)
    80003706:	e822                	sd	s0,16(sp)
    80003708:	e426                	sd	s1,8(sp)
    8000370a:	e04a                	sd	s2,0(sp)
    8000370c:	1000                	addi	s0,sp,32
    8000370e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003710:	415c                	lw	a5,4(a0)
    80003712:	0047d79b          	srliw	a5,a5,0x4
    80003716:	0001c597          	auipc	a1,0x1c
    8000371a:	4aa5a583          	lw	a1,1194(a1) # 8001fbc0 <sb+0x18>
    8000371e:	9dbd                	addw	a1,a1,a5
    80003720:	4108                	lw	a0,0(a0)
    80003722:	00000097          	auipc	ra,0x0
    80003726:	8a8080e7          	jalr	-1880(ra) # 80002fca <bread>
    8000372a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000372c:	05850793          	addi	a5,a0,88
    80003730:	40c8                	lw	a0,4(s1)
    80003732:	893d                	andi	a0,a0,15
    80003734:	051a                	slli	a0,a0,0x6
    80003736:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003738:	04449703          	lh	a4,68(s1)
    8000373c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003740:	04649703          	lh	a4,70(s1)
    80003744:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003748:	04849703          	lh	a4,72(s1)
    8000374c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003750:	04a49703          	lh	a4,74(s1)
    80003754:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003758:	44f8                	lw	a4,76(s1)
    8000375a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000375c:	03400613          	li	a2,52
    80003760:	05048593          	addi	a1,s1,80
    80003764:	0531                	addi	a0,a0,12
    80003766:	ffffd097          	auipc	ra,0xffffd
    8000376a:	5da080e7          	jalr	1498(ra) # 80000d40 <memmove>
  log_write(bp);
    8000376e:	854a                	mv	a0,s2
    80003770:	00001097          	auipc	ra,0x1
    80003774:	c06080e7          	jalr	-1018(ra) # 80004376 <log_write>
  brelse(bp);
    80003778:	854a                	mv	a0,s2
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	980080e7          	jalr	-1664(ra) # 800030fa <brelse>
}
    80003782:	60e2                	ld	ra,24(sp)
    80003784:	6442                	ld	s0,16(sp)
    80003786:	64a2                	ld	s1,8(sp)
    80003788:	6902                	ld	s2,0(sp)
    8000378a:	6105                	addi	sp,sp,32
    8000378c:	8082                	ret

000000008000378e <idup>:
{
    8000378e:	1101                	addi	sp,sp,-32
    80003790:	ec06                	sd	ra,24(sp)
    80003792:	e822                	sd	s0,16(sp)
    80003794:	e426                	sd	s1,8(sp)
    80003796:	1000                	addi	s0,sp,32
    80003798:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000379a:	0001c517          	auipc	a0,0x1c
    8000379e:	42e50513          	addi	a0,a0,1070 # 8001fbc8 <itable>
    800037a2:	ffffd097          	auipc	ra,0xffffd
    800037a6:	442080e7          	jalr	1090(ra) # 80000be4 <acquire>
  ip->ref++;
    800037aa:	449c                	lw	a5,8(s1)
    800037ac:	2785                	addiw	a5,a5,1
    800037ae:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037b0:	0001c517          	auipc	a0,0x1c
    800037b4:	41850513          	addi	a0,a0,1048 # 8001fbc8 <itable>
    800037b8:	ffffd097          	auipc	ra,0xffffd
    800037bc:	4e0080e7          	jalr	1248(ra) # 80000c98 <release>
}
    800037c0:	8526                	mv	a0,s1
    800037c2:	60e2                	ld	ra,24(sp)
    800037c4:	6442                	ld	s0,16(sp)
    800037c6:	64a2                	ld	s1,8(sp)
    800037c8:	6105                	addi	sp,sp,32
    800037ca:	8082                	ret

00000000800037cc <ilock>:
{
    800037cc:	1101                	addi	sp,sp,-32
    800037ce:	ec06                	sd	ra,24(sp)
    800037d0:	e822                	sd	s0,16(sp)
    800037d2:	e426                	sd	s1,8(sp)
    800037d4:	e04a                	sd	s2,0(sp)
    800037d6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037d8:	c115                	beqz	a0,800037fc <ilock+0x30>
    800037da:	84aa                	mv	s1,a0
    800037dc:	451c                	lw	a5,8(a0)
    800037de:	00f05f63          	blez	a5,800037fc <ilock+0x30>
  acquiresleep(&ip->lock);
    800037e2:	0541                	addi	a0,a0,16
    800037e4:	00001097          	auipc	ra,0x1
    800037e8:	cb2080e7          	jalr	-846(ra) # 80004496 <acquiresleep>
  if(ip->valid == 0){
    800037ec:	40bc                	lw	a5,64(s1)
    800037ee:	cf99                	beqz	a5,8000380c <ilock+0x40>
}
    800037f0:	60e2                	ld	ra,24(sp)
    800037f2:	6442                	ld	s0,16(sp)
    800037f4:	64a2                	ld	s1,8(sp)
    800037f6:	6902                	ld	s2,0(sp)
    800037f8:	6105                	addi	sp,sp,32
    800037fa:	8082                	ret
    panic("ilock");
    800037fc:	00005517          	auipc	a0,0x5
    80003800:	e0c50513          	addi	a0,a0,-500 # 80008608 <syscalls+0x190>
    80003804:	ffffd097          	auipc	ra,0xffffd
    80003808:	d3a080e7          	jalr	-710(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000380c:	40dc                	lw	a5,4(s1)
    8000380e:	0047d79b          	srliw	a5,a5,0x4
    80003812:	0001c597          	auipc	a1,0x1c
    80003816:	3ae5a583          	lw	a1,942(a1) # 8001fbc0 <sb+0x18>
    8000381a:	9dbd                	addw	a1,a1,a5
    8000381c:	4088                	lw	a0,0(s1)
    8000381e:	fffff097          	auipc	ra,0xfffff
    80003822:	7ac080e7          	jalr	1964(ra) # 80002fca <bread>
    80003826:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003828:	05850593          	addi	a1,a0,88
    8000382c:	40dc                	lw	a5,4(s1)
    8000382e:	8bbd                	andi	a5,a5,15
    80003830:	079a                	slli	a5,a5,0x6
    80003832:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003834:	00059783          	lh	a5,0(a1)
    80003838:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000383c:	00259783          	lh	a5,2(a1)
    80003840:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003844:	00459783          	lh	a5,4(a1)
    80003848:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000384c:	00659783          	lh	a5,6(a1)
    80003850:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003854:	459c                	lw	a5,8(a1)
    80003856:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003858:	03400613          	li	a2,52
    8000385c:	05b1                	addi	a1,a1,12
    8000385e:	05048513          	addi	a0,s1,80
    80003862:	ffffd097          	auipc	ra,0xffffd
    80003866:	4de080e7          	jalr	1246(ra) # 80000d40 <memmove>
    brelse(bp);
    8000386a:	854a                	mv	a0,s2
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	88e080e7          	jalr	-1906(ra) # 800030fa <brelse>
    ip->valid = 1;
    80003874:	4785                	li	a5,1
    80003876:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003878:	04449783          	lh	a5,68(s1)
    8000387c:	fbb5                	bnez	a5,800037f0 <ilock+0x24>
      panic("ilock: no type");
    8000387e:	00005517          	auipc	a0,0x5
    80003882:	d9250513          	addi	a0,a0,-622 # 80008610 <syscalls+0x198>
    80003886:	ffffd097          	auipc	ra,0xffffd
    8000388a:	cb8080e7          	jalr	-840(ra) # 8000053e <panic>

000000008000388e <iunlock>:
{
    8000388e:	1101                	addi	sp,sp,-32
    80003890:	ec06                	sd	ra,24(sp)
    80003892:	e822                	sd	s0,16(sp)
    80003894:	e426                	sd	s1,8(sp)
    80003896:	e04a                	sd	s2,0(sp)
    80003898:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000389a:	c905                	beqz	a0,800038ca <iunlock+0x3c>
    8000389c:	84aa                	mv	s1,a0
    8000389e:	01050913          	addi	s2,a0,16
    800038a2:	854a                	mv	a0,s2
    800038a4:	00001097          	auipc	ra,0x1
    800038a8:	c8c080e7          	jalr	-884(ra) # 80004530 <holdingsleep>
    800038ac:	cd19                	beqz	a0,800038ca <iunlock+0x3c>
    800038ae:	449c                	lw	a5,8(s1)
    800038b0:	00f05d63          	blez	a5,800038ca <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038b4:	854a                	mv	a0,s2
    800038b6:	00001097          	auipc	ra,0x1
    800038ba:	c36080e7          	jalr	-970(ra) # 800044ec <releasesleep>
}
    800038be:	60e2                	ld	ra,24(sp)
    800038c0:	6442                	ld	s0,16(sp)
    800038c2:	64a2                	ld	s1,8(sp)
    800038c4:	6902                	ld	s2,0(sp)
    800038c6:	6105                	addi	sp,sp,32
    800038c8:	8082                	ret
    panic("iunlock");
    800038ca:	00005517          	auipc	a0,0x5
    800038ce:	d5650513          	addi	a0,a0,-682 # 80008620 <syscalls+0x1a8>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	c6c080e7          	jalr	-916(ra) # 8000053e <panic>

00000000800038da <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038da:	7179                	addi	sp,sp,-48
    800038dc:	f406                	sd	ra,40(sp)
    800038de:	f022                	sd	s0,32(sp)
    800038e0:	ec26                	sd	s1,24(sp)
    800038e2:	e84a                	sd	s2,16(sp)
    800038e4:	e44e                	sd	s3,8(sp)
    800038e6:	e052                	sd	s4,0(sp)
    800038e8:	1800                	addi	s0,sp,48
    800038ea:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038ec:	05050493          	addi	s1,a0,80
    800038f0:	08050913          	addi	s2,a0,128
    800038f4:	a021                	j	800038fc <itrunc+0x22>
    800038f6:	0491                	addi	s1,s1,4
    800038f8:	01248d63          	beq	s1,s2,80003912 <itrunc+0x38>
    if(ip->addrs[i]){
    800038fc:	408c                	lw	a1,0(s1)
    800038fe:	dde5                	beqz	a1,800038f6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003900:	0009a503          	lw	a0,0(s3)
    80003904:	00000097          	auipc	ra,0x0
    80003908:	90c080e7          	jalr	-1780(ra) # 80003210 <bfree>
      ip->addrs[i] = 0;
    8000390c:	0004a023          	sw	zero,0(s1)
    80003910:	b7dd                	j	800038f6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003912:	0809a583          	lw	a1,128(s3)
    80003916:	e185                	bnez	a1,80003936 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003918:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000391c:	854e                	mv	a0,s3
    8000391e:	00000097          	auipc	ra,0x0
    80003922:	de4080e7          	jalr	-540(ra) # 80003702 <iupdate>
}
    80003926:	70a2                	ld	ra,40(sp)
    80003928:	7402                	ld	s0,32(sp)
    8000392a:	64e2                	ld	s1,24(sp)
    8000392c:	6942                	ld	s2,16(sp)
    8000392e:	69a2                	ld	s3,8(sp)
    80003930:	6a02                	ld	s4,0(sp)
    80003932:	6145                	addi	sp,sp,48
    80003934:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003936:	0009a503          	lw	a0,0(s3)
    8000393a:	fffff097          	auipc	ra,0xfffff
    8000393e:	690080e7          	jalr	1680(ra) # 80002fca <bread>
    80003942:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003944:	05850493          	addi	s1,a0,88
    80003948:	45850913          	addi	s2,a0,1112
    8000394c:	a811                	j	80003960 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000394e:	0009a503          	lw	a0,0(s3)
    80003952:	00000097          	auipc	ra,0x0
    80003956:	8be080e7          	jalr	-1858(ra) # 80003210 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000395a:	0491                	addi	s1,s1,4
    8000395c:	01248563          	beq	s1,s2,80003966 <itrunc+0x8c>
      if(a[j])
    80003960:	408c                	lw	a1,0(s1)
    80003962:	dde5                	beqz	a1,8000395a <itrunc+0x80>
    80003964:	b7ed                	j	8000394e <itrunc+0x74>
    brelse(bp);
    80003966:	8552                	mv	a0,s4
    80003968:	fffff097          	auipc	ra,0xfffff
    8000396c:	792080e7          	jalr	1938(ra) # 800030fa <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003970:	0809a583          	lw	a1,128(s3)
    80003974:	0009a503          	lw	a0,0(s3)
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	898080e7          	jalr	-1896(ra) # 80003210 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003980:	0809a023          	sw	zero,128(s3)
    80003984:	bf51                	j	80003918 <itrunc+0x3e>

0000000080003986 <iput>:
{
    80003986:	1101                	addi	sp,sp,-32
    80003988:	ec06                	sd	ra,24(sp)
    8000398a:	e822                	sd	s0,16(sp)
    8000398c:	e426                	sd	s1,8(sp)
    8000398e:	e04a                	sd	s2,0(sp)
    80003990:	1000                	addi	s0,sp,32
    80003992:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003994:	0001c517          	auipc	a0,0x1c
    80003998:	23450513          	addi	a0,a0,564 # 8001fbc8 <itable>
    8000399c:	ffffd097          	auipc	ra,0xffffd
    800039a0:	248080e7          	jalr	584(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039a4:	4498                	lw	a4,8(s1)
    800039a6:	4785                	li	a5,1
    800039a8:	02f70363          	beq	a4,a5,800039ce <iput+0x48>
  ip->ref--;
    800039ac:	449c                	lw	a5,8(s1)
    800039ae:	37fd                	addiw	a5,a5,-1
    800039b0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039b2:	0001c517          	auipc	a0,0x1c
    800039b6:	21650513          	addi	a0,a0,534 # 8001fbc8 <itable>
    800039ba:	ffffd097          	auipc	ra,0xffffd
    800039be:	2de080e7          	jalr	734(ra) # 80000c98 <release>
}
    800039c2:	60e2                	ld	ra,24(sp)
    800039c4:	6442                	ld	s0,16(sp)
    800039c6:	64a2                	ld	s1,8(sp)
    800039c8:	6902                	ld	s2,0(sp)
    800039ca:	6105                	addi	sp,sp,32
    800039cc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039ce:	40bc                	lw	a5,64(s1)
    800039d0:	dff1                	beqz	a5,800039ac <iput+0x26>
    800039d2:	04a49783          	lh	a5,74(s1)
    800039d6:	fbf9                	bnez	a5,800039ac <iput+0x26>
    acquiresleep(&ip->lock);
    800039d8:	01048913          	addi	s2,s1,16
    800039dc:	854a                	mv	a0,s2
    800039de:	00001097          	auipc	ra,0x1
    800039e2:	ab8080e7          	jalr	-1352(ra) # 80004496 <acquiresleep>
    release(&itable.lock);
    800039e6:	0001c517          	auipc	a0,0x1c
    800039ea:	1e250513          	addi	a0,a0,482 # 8001fbc8 <itable>
    800039ee:	ffffd097          	auipc	ra,0xffffd
    800039f2:	2aa080e7          	jalr	682(ra) # 80000c98 <release>
    itrunc(ip);
    800039f6:	8526                	mv	a0,s1
    800039f8:	00000097          	auipc	ra,0x0
    800039fc:	ee2080e7          	jalr	-286(ra) # 800038da <itrunc>
    ip->type = 0;
    80003a00:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a04:	8526                	mv	a0,s1
    80003a06:	00000097          	auipc	ra,0x0
    80003a0a:	cfc080e7          	jalr	-772(ra) # 80003702 <iupdate>
    ip->valid = 0;
    80003a0e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a12:	854a                	mv	a0,s2
    80003a14:	00001097          	auipc	ra,0x1
    80003a18:	ad8080e7          	jalr	-1320(ra) # 800044ec <releasesleep>
    acquire(&itable.lock);
    80003a1c:	0001c517          	auipc	a0,0x1c
    80003a20:	1ac50513          	addi	a0,a0,428 # 8001fbc8 <itable>
    80003a24:	ffffd097          	auipc	ra,0xffffd
    80003a28:	1c0080e7          	jalr	448(ra) # 80000be4 <acquire>
    80003a2c:	b741                	j	800039ac <iput+0x26>

0000000080003a2e <iunlockput>:
{
    80003a2e:	1101                	addi	sp,sp,-32
    80003a30:	ec06                	sd	ra,24(sp)
    80003a32:	e822                	sd	s0,16(sp)
    80003a34:	e426                	sd	s1,8(sp)
    80003a36:	1000                	addi	s0,sp,32
    80003a38:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a3a:	00000097          	auipc	ra,0x0
    80003a3e:	e54080e7          	jalr	-428(ra) # 8000388e <iunlock>
  iput(ip);
    80003a42:	8526                	mv	a0,s1
    80003a44:	00000097          	auipc	ra,0x0
    80003a48:	f42080e7          	jalr	-190(ra) # 80003986 <iput>
}
    80003a4c:	60e2                	ld	ra,24(sp)
    80003a4e:	6442                	ld	s0,16(sp)
    80003a50:	64a2                	ld	s1,8(sp)
    80003a52:	6105                	addi	sp,sp,32
    80003a54:	8082                	ret

0000000080003a56 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a56:	1141                	addi	sp,sp,-16
    80003a58:	e422                	sd	s0,8(sp)
    80003a5a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a5c:	411c                	lw	a5,0(a0)
    80003a5e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a60:	415c                	lw	a5,4(a0)
    80003a62:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a64:	04451783          	lh	a5,68(a0)
    80003a68:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a6c:	04a51783          	lh	a5,74(a0)
    80003a70:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a74:	04c56783          	lwu	a5,76(a0)
    80003a78:	e99c                	sd	a5,16(a1)
}
    80003a7a:	6422                	ld	s0,8(sp)
    80003a7c:	0141                	addi	sp,sp,16
    80003a7e:	8082                	ret

0000000080003a80 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a80:	457c                	lw	a5,76(a0)
    80003a82:	0ed7e963          	bltu	a5,a3,80003b74 <readi+0xf4>
{
    80003a86:	7159                	addi	sp,sp,-112
    80003a88:	f486                	sd	ra,104(sp)
    80003a8a:	f0a2                	sd	s0,96(sp)
    80003a8c:	eca6                	sd	s1,88(sp)
    80003a8e:	e8ca                	sd	s2,80(sp)
    80003a90:	e4ce                	sd	s3,72(sp)
    80003a92:	e0d2                	sd	s4,64(sp)
    80003a94:	fc56                	sd	s5,56(sp)
    80003a96:	f85a                	sd	s6,48(sp)
    80003a98:	f45e                	sd	s7,40(sp)
    80003a9a:	f062                	sd	s8,32(sp)
    80003a9c:	ec66                	sd	s9,24(sp)
    80003a9e:	e86a                	sd	s10,16(sp)
    80003aa0:	e46e                	sd	s11,8(sp)
    80003aa2:	1880                	addi	s0,sp,112
    80003aa4:	8baa                	mv	s7,a0
    80003aa6:	8c2e                	mv	s8,a1
    80003aa8:	8ab2                	mv	s5,a2
    80003aaa:	84b6                	mv	s1,a3
    80003aac:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003aae:	9f35                	addw	a4,a4,a3
    return 0;
    80003ab0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ab2:	0ad76063          	bltu	a4,a3,80003b52 <readi+0xd2>
  if(off + n > ip->size)
    80003ab6:	00e7f463          	bgeu	a5,a4,80003abe <readi+0x3e>
    n = ip->size - off;
    80003aba:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003abe:	0a0b0963          	beqz	s6,80003b70 <readi+0xf0>
    80003ac2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ac8:	5cfd                	li	s9,-1
    80003aca:	a82d                	j	80003b04 <readi+0x84>
    80003acc:	020a1d93          	slli	s11,s4,0x20
    80003ad0:	020ddd93          	srli	s11,s11,0x20
    80003ad4:	05890613          	addi	a2,s2,88
    80003ad8:	86ee                	mv	a3,s11
    80003ada:	963a                	add	a2,a2,a4
    80003adc:	85d6                	mv	a1,s5
    80003ade:	8562                	mv	a0,s8
    80003ae0:	fffff097          	auipc	ra,0xfffff
    80003ae4:	a36080e7          	jalr	-1482(ra) # 80002516 <either_copyout>
    80003ae8:	05950d63          	beq	a0,s9,80003b42 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003aec:	854a                	mv	a0,s2
    80003aee:	fffff097          	auipc	ra,0xfffff
    80003af2:	60c080e7          	jalr	1548(ra) # 800030fa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003af6:	013a09bb          	addw	s3,s4,s3
    80003afa:	009a04bb          	addw	s1,s4,s1
    80003afe:	9aee                	add	s5,s5,s11
    80003b00:	0569f763          	bgeu	s3,s6,80003b4e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b04:	000ba903          	lw	s2,0(s7)
    80003b08:	00a4d59b          	srliw	a1,s1,0xa
    80003b0c:	855e                	mv	a0,s7
    80003b0e:	00000097          	auipc	ra,0x0
    80003b12:	8b0080e7          	jalr	-1872(ra) # 800033be <bmap>
    80003b16:	0005059b          	sext.w	a1,a0
    80003b1a:	854a                	mv	a0,s2
    80003b1c:	fffff097          	auipc	ra,0xfffff
    80003b20:	4ae080e7          	jalr	1198(ra) # 80002fca <bread>
    80003b24:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b26:	3ff4f713          	andi	a4,s1,1023
    80003b2a:	40ed07bb          	subw	a5,s10,a4
    80003b2e:	413b06bb          	subw	a3,s6,s3
    80003b32:	8a3e                	mv	s4,a5
    80003b34:	2781                	sext.w	a5,a5
    80003b36:	0006861b          	sext.w	a2,a3
    80003b3a:	f8f679e3          	bgeu	a2,a5,80003acc <readi+0x4c>
    80003b3e:	8a36                	mv	s4,a3
    80003b40:	b771                	j	80003acc <readi+0x4c>
      brelse(bp);
    80003b42:	854a                	mv	a0,s2
    80003b44:	fffff097          	auipc	ra,0xfffff
    80003b48:	5b6080e7          	jalr	1462(ra) # 800030fa <brelse>
      tot = -1;
    80003b4c:	59fd                	li	s3,-1
  }
  return tot;
    80003b4e:	0009851b          	sext.w	a0,s3
}
    80003b52:	70a6                	ld	ra,104(sp)
    80003b54:	7406                	ld	s0,96(sp)
    80003b56:	64e6                	ld	s1,88(sp)
    80003b58:	6946                	ld	s2,80(sp)
    80003b5a:	69a6                	ld	s3,72(sp)
    80003b5c:	6a06                	ld	s4,64(sp)
    80003b5e:	7ae2                	ld	s5,56(sp)
    80003b60:	7b42                	ld	s6,48(sp)
    80003b62:	7ba2                	ld	s7,40(sp)
    80003b64:	7c02                	ld	s8,32(sp)
    80003b66:	6ce2                	ld	s9,24(sp)
    80003b68:	6d42                	ld	s10,16(sp)
    80003b6a:	6da2                	ld	s11,8(sp)
    80003b6c:	6165                	addi	sp,sp,112
    80003b6e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b70:	89da                	mv	s3,s6
    80003b72:	bff1                	j	80003b4e <readi+0xce>
    return 0;
    80003b74:	4501                	li	a0,0
}
    80003b76:	8082                	ret

0000000080003b78 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b78:	457c                	lw	a5,76(a0)
    80003b7a:	10d7e863          	bltu	a5,a3,80003c8a <writei+0x112>
{
    80003b7e:	7159                	addi	sp,sp,-112
    80003b80:	f486                	sd	ra,104(sp)
    80003b82:	f0a2                	sd	s0,96(sp)
    80003b84:	eca6                	sd	s1,88(sp)
    80003b86:	e8ca                	sd	s2,80(sp)
    80003b88:	e4ce                	sd	s3,72(sp)
    80003b8a:	e0d2                	sd	s4,64(sp)
    80003b8c:	fc56                	sd	s5,56(sp)
    80003b8e:	f85a                	sd	s6,48(sp)
    80003b90:	f45e                	sd	s7,40(sp)
    80003b92:	f062                	sd	s8,32(sp)
    80003b94:	ec66                	sd	s9,24(sp)
    80003b96:	e86a                	sd	s10,16(sp)
    80003b98:	e46e                	sd	s11,8(sp)
    80003b9a:	1880                	addi	s0,sp,112
    80003b9c:	8b2a                	mv	s6,a0
    80003b9e:	8c2e                	mv	s8,a1
    80003ba0:	8ab2                	mv	s5,a2
    80003ba2:	8936                	mv	s2,a3
    80003ba4:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ba6:	00e687bb          	addw	a5,a3,a4
    80003baa:	0ed7e263          	bltu	a5,a3,80003c8e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bae:	00043737          	lui	a4,0x43
    80003bb2:	0ef76063          	bltu	a4,a5,80003c92 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bb6:	0c0b8863          	beqz	s7,80003c86 <writei+0x10e>
    80003bba:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bbc:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bc0:	5cfd                	li	s9,-1
    80003bc2:	a091                	j	80003c06 <writei+0x8e>
    80003bc4:	02099d93          	slli	s11,s3,0x20
    80003bc8:	020ddd93          	srli	s11,s11,0x20
    80003bcc:	05848513          	addi	a0,s1,88
    80003bd0:	86ee                	mv	a3,s11
    80003bd2:	8656                	mv	a2,s5
    80003bd4:	85e2                	mv	a1,s8
    80003bd6:	953a                	add	a0,a0,a4
    80003bd8:	fffff097          	auipc	ra,0xfffff
    80003bdc:	994080e7          	jalr	-1644(ra) # 8000256c <either_copyin>
    80003be0:	07950263          	beq	a0,s9,80003c44 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003be4:	8526                	mv	a0,s1
    80003be6:	00000097          	auipc	ra,0x0
    80003bea:	790080e7          	jalr	1936(ra) # 80004376 <log_write>
    brelse(bp);
    80003bee:	8526                	mv	a0,s1
    80003bf0:	fffff097          	auipc	ra,0xfffff
    80003bf4:	50a080e7          	jalr	1290(ra) # 800030fa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bf8:	01498a3b          	addw	s4,s3,s4
    80003bfc:	0129893b          	addw	s2,s3,s2
    80003c00:	9aee                	add	s5,s5,s11
    80003c02:	057a7663          	bgeu	s4,s7,80003c4e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c06:	000b2483          	lw	s1,0(s6)
    80003c0a:	00a9559b          	srliw	a1,s2,0xa
    80003c0e:	855a                	mv	a0,s6
    80003c10:	fffff097          	auipc	ra,0xfffff
    80003c14:	7ae080e7          	jalr	1966(ra) # 800033be <bmap>
    80003c18:	0005059b          	sext.w	a1,a0
    80003c1c:	8526                	mv	a0,s1
    80003c1e:	fffff097          	auipc	ra,0xfffff
    80003c22:	3ac080e7          	jalr	940(ra) # 80002fca <bread>
    80003c26:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c28:	3ff97713          	andi	a4,s2,1023
    80003c2c:	40ed07bb          	subw	a5,s10,a4
    80003c30:	414b86bb          	subw	a3,s7,s4
    80003c34:	89be                	mv	s3,a5
    80003c36:	2781                	sext.w	a5,a5
    80003c38:	0006861b          	sext.w	a2,a3
    80003c3c:	f8f674e3          	bgeu	a2,a5,80003bc4 <writei+0x4c>
    80003c40:	89b6                	mv	s3,a3
    80003c42:	b749                	j	80003bc4 <writei+0x4c>
      brelse(bp);
    80003c44:	8526                	mv	a0,s1
    80003c46:	fffff097          	auipc	ra,0xfffff
    80003c4a:	4b4080e7          	jalr	1204(ra) # 800030fa <brelse>
  }

  if(off > ip->size)
    80003c4e:	04cb2783          	lw	a5,76(s6)
    80003c52:	0127f463          	bgeu	a5,s2,80003c5a <writei+0xe2>
    ip->size = off;
    80003c56:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c5a:	855a                	mv	a0,s6
    80003c5c:	00000097          	auipc	ra,0x0
    80003c60:	aa6080e7          	jalr	-1370(ra) # 80003702 <iupdate>

  return tot;
    80003c64:	000a051b          	sext.w	a0,s4
}
    80003c68:	70a6                	ld	ra,104(sp)
    80003c6a:	7406                	ld	s0,96(sp)
    80003c6c:	64e6                	ld	s1,88(sp)
    80003c6e:	6946                	ld	s2,80(sp)
    80003c70:	69a6                	ld	s3,72(sp)
    80003c72:	6a06                	ld	s4,64(sp)
    80003c74:	7ae2                	ld	s5,56(sp)
    80003c76:	7b42                	ld	s6,48(sp)
    80003c78:	7ba2                	ld	s7,40(sp)
    80003c7a:	7c02                	ld	s8,32(sp)
    80003c7c:	6ce2                	ld	s9,24(sp)
    80003c7e:	6d42                	ld	s10,16(sp)
    80003c80:	6da2                	ld	s11,8(sp)
    80003c82:	6165                	addi	sp,sp,112
    80003c84:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c86:	8a5e                	mv	s4,s7
    80003c88:	bfc9                	j	80003c5a <writei+0xe2>
    return -1;
    80003c8a:	557d                	li	a0,-1
}
    80003c8c:	8082                	ret
    return -1;
    80003c8e:	557d                	li	a0,-1
    80003c90:	bfe1                	j	80003c68 <writei+0xf0>
    return -1;
    80003c92:	557d                	li	a0,-1
    80003c94:	bfd1                	j	80003c68 <writei+0xf0>

0000000080003c96 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c96:	1141                	addi	sp,sp,-16
    80003c98:	e406                	sd	ra,8(sp)
    80003c9a:	e022                	sd	s0,0(sp)
    80003c9c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c9e:	4639                	li	a2,14
    80003ca0:	ffffd097          	auipc	ra,0xffffd
    80003ca4:	118080e7          	jalr	280(ra) # 80000db8 <strncmp>
}
    80003ca8:	60a2                	ld	ra,8(sp)
    80003caa:	6402                	ld	s0,0(sp)
    80003cac:	0141                	addi	sp,sp,16
    80003cae:	8082                	ret

0000000080003cb0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cb0:	7139                	addi	sp,sp,-64
    80003cb2:	fc06                	sd	ra,56(sp)
    80003cb4:	f822                	sd	s0,48(sp)
    80003cb6:	f426                	sd	s1,40(sp)
    80003cb8:	f04a                	sd	s2,32(sp)
    80003cba:	ec4e                	sd	s3,24(sp)
    80003cbc:	e852                	sd	s4,16(sp)
    80003cbe:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cc0:	04451703          	lh	a4,68(a0)
    80003cc4:	4785                	li	a5,1
    80003cc6:	00f71a63          	bne	a4,a5,80003cda <dirlookup+0x2a>
    80003cca:	892a                	mv	s2,a0
    80003ccc:	89ae                	mv	s3,a1
    80003cce:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cd0:	457c                	lw	a5,76(a0)
    80003cd2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cd4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cd6:	e79d                	bnez	a5,80003d04 <dirlookup+0x54>
    80003cd8:	a8a5                	j	80003d50 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cda:	00005517          	auipc	a0,0x5
    80003cde:	94e50513          	addi	a0,a0,-1714 # 80008628 <syscalls+0x1b0>
    80003ce2:	ffffd097          	auipc	ra,0xffffd
    80003ce6:	85c080e7          	jalr	-1956(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003cea:	00005517          	auipc	a0,0x5
    80003cee:	95650513          	addi	a0,a0,-1706 # 80008640 <syscalls+0x1c8>
    80003cf2:	ffffd097          	auipc	ra,0xffffd
    80003cf6:	84c080e7          	jalr	-1972(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cfa:	24c1                	addiw	s1,s1,16
    80003cfc:	04c92783          	lw	a5,76(s2)
    80003d00:	04f4f763          	bgeu	s1,a5,80003d4e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d04:	4741                	li	a4,16
    80003d06:	86a6                	mv	a3,s1
    80003d08:	fc040613          	addi	a2,s0,-64
    80003d0c:	4581                	li	a1,0
    80003d0e:	854a                	mv	a0,s2
    80003d10:	00000097          	auipc	ra,0x0
    80003d14:	d70080e7          	jalr	-656(ra) # 80003a80 <readi>
    80003d18:	47c1                	li	a5,16
    80003d1a:	fcf518e3          	bne	a0,a5,80003cea <dirlookup+0x3a>
    if(de.inum == 0)
    80003d1e:	fc045783          	lhu	a5,-64(s0)
    80003d22:	dfe1                	beqz	a5,80003cfa <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d24:	fc240593          	addi	a1,s0,-62
    80003d28:	854e                	mv	a0,s3
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	f6c080e7          	jalr	-148(ra) # 80003c96 <namecmp>
    80003d32:	f561                	bnez	a0,80003cfa <dirlookup+0x4a>
      if(poff)
    80003d34:	000a0463          	beqz	s4,80003d3c <dirlookup+0x8c>
        *poff = off;
    80003d38:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d3c:	fc045583          	lhu	a1,-64(s0)
    80003d40:	00092503          	lw	a0,0(s2)
    80003d44:	fffff097          	auipc	ra,0xfffff
    80003d48:	754080e7          	jalr	1876(ra) # 80003498 <iget>
    80003d4c:	a011                	j	80003d50 <dirlookup+0xa0>
  return 0;
    80003d4e:	4501                	li	a0,0
}
    80003d50:	70e2                	ld	ra,56(sp)
    80003d52:	7442                	ld	s0,48(sp)
    80003d54:	74a2                	ld	s1,40(sp)
    80003d56:	7902                	ld	s2,32(sp)
    80003d58:	69e2                	ld	s3,24(sp)
    80003d5a:	6a42                	ld	s4,16(sp)
    80003d5c:	6121                	addi	sp,sp,64
    80003d5e:	8082                	ret

0000000080003d60 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d60:	711d                	addi	sp,sp,-96
    80003d62:	ec86                	sd	ra,88(sp)
    80003d64:	e8a2                	sd	s0,80(sp)
    80003d66:	e4a6                	sd	s1,72(sp)
    80003d68:	e0ca                	sd	s2,64(sp)
    80003d6a:	fc4e                	sd	s3,56(sp)
    80003d6c:	f852                	sd	s4,48(sp)
    80003d6e:	f456                	sd	s5,40(sp)
    80003d70:	f05a                	sd	s6,32(sp)
    80003d72:	ec5e                	sd	s7,24(sp)
    80003d74:	e862                	sd	s8,16(sp)
    80003d76:	e466                	sd	s9,8(sp)
    80003d78:	1080                	addi	s0,sp,96
    80003d7a:	84aa                	mv	s1,a0
    80003d7c:	8b2e                	mv	s6,a1
    80003d7e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d80:	00054703          	lbu	a4,0(a0)
    80003d84:	02f00793          	li	a5,47
    80003d88:	02f70363          	beq	a4,a5,80003dae <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d8c:	ffffe097          	auipc	ra,0xffffe
    80003d90:	c24080e7          	jalr	-988(ra) # 800019b0 <myproc>
    80003d94:	15053503          	ld	a0,336(a0)
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	9f6080e7          	jalr	-1546(ra) # 8000378e <idup>
    80003da0:	89aa                	mv	s3,a0
  while(*path == '/')
    80003da2:	02f00913          	li	s2,47
  len = path - s;
    80003da6:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003da8:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003daa:	4c05                	li	s8,1
    80003dac:	a865                	j	80003e64 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003dae:	4585                	li	a1,1
    80003db0:	4505                	li	a0,1
    80003db2:	fffff097          	auipc	ra,0xfffff
    80003db6:	6e6080e7          	jalr	1766(ra) # 80003498 <iget>
    80003dba:	89aa                	mv	s3,a0
    80003dbc:	b7dd                	j	80003da2 <namex+0x42>
      iunlockput(ip);
    80003dbe:	854e                	mv	a0,s3
    80003dc0:	00000097          	auipc	ra,0x0
    80003dc4:	c6e080e7          	jalr	-914(ra) # 80003a2e <iunlockput>
      return 0;
    80003dc8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dca:	854e                	mv	a0,s3
    80003dcc:	60e6                	ld	ra,88(sp)
    80003dce:	6446                	ld	s0,80(sp)
    80003dd0:	64a6                	ld	s1,72(sp)
    80003dd2:	6906                	ld	s2,64(sp)
    80003dd4:	79e2                	ld	s3,56(sp)
    80003dd6:	7a42                	ld	s4,48(sp)
    80003dd8:	7aa2                	ld	s5,40(sp)
    80003dda:	7b02                	ld	s6,32(sp)
    80003ddc:	6be2                	ld	s7,24(sp)
    80003dde:	6c42                	ld	s8,16(sp)
    80003de0:	6ca2                	ld	s9,8(sp)
    80003de2:	6125                	addi	sp,sp,96
    80003de4:	8082                	ret
      iunlock(ip);
    80003de6:	854e                	mv	a0,s3
    80003de8:	00000097          	auipc	ra,0x0
    80003dec:	aa6080e7          	jalr	-1370(ra) # 8000388e <iunlock>
      return ip;
    80003df0:	bfe9                	j	80003dca <namex+0x6a>
      iunlockput(ip);
    80003df2:	854e                	mv	a0,s3
    80003df4:	00000097          	auipc	ra,0x0
    80003df8:	c3a080e7          	jalr	-966(ra) # 80003a2e <iunlockput>
      return 0;
    80003dfc:	89d2                	mv	s3,s4
    80003dfe:	b7f1                	j	80003dca <namex+0x6a>
  len = path - s;
    80003e00:	40b48633          	sub	a2,s1,a1
    80003e04:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e08:	094cd463          	bge	s9,s4,80003e90 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e0c:	4639                	li	a2,14
    80003e0e:	8556                	mv	a0,s5
    80003e10:	ffffd097          	auipc	ra,0xffffd
    80003e14:	f30080e7          	jalr	-208(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003e18:	0004c783          	lbu	a5,0(s1)
    80003e1c:	01279763          	bne	a5,s2,80003e2a <namex+0xca>
    path++;
    80003e20:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e22:	0004c783          	lbu	a5,0(s1)
    80003e26:	ff278de3          	beq	a5,s2,80003e20 <namex+0xc0>
    ilock(ip);
    80003e2a:	854e                	mv	a0,s3
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	9a0080e7          	jalr	-1632(ra) # 800037cc <ilock>
    if(ip->type != T_DIR){
    80003e34:	04499783          	lh	a5,68(s3)
    80003e38:	f98793e3          	bne	a5,s8,80003dbe <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e3c:	000b0563          	beqz	s6,80003e46 <namex+0xe6>
    80003e40:	0004c783          	lbu	a5,0(s1)
    80003e44:	d3cd                	beqz	a5,80003de6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e46:	865e                	mv	a2,s7
    80003e48:	85d6                	mv	a1,s5
    80003e4a:	854e                	mv	a0,s3
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	e64080e7          	jalr	-412(ra) # 80003cb0 <dirlookup>
    80003e54:	8a2a                	mv	s4,a0
    80003e56:	dd51                	beqz	a0,80003df2 <namex+0x92>
    iunlockput(ip);
    80003e58:	854e                	mv	a0,s3
    80003e5a:	00000097          	auipc	ra,0x0
    80003e5e:	bd4080e7          	jalr	-1068(ra) # 80003a2e <iunlockput>
    ip = next;
    80003e62:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e64:	0004c783          	lbu	a5,0(s1)
    80003e68:	05279763          	bne	a5,s2,80003eb6 <namex+0x156>
    path++;
    80003e6c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e6e:	0004c783          	lbu	a5,0(s1)
    80003e72:	ff278de3          	beq	a5,s2,80003e6c <namex+0x10c>
  if(*path == 0)
    80003e76:	c79d                	beqz	a5,80003ea4 <namex+0x144>
    path++;
    80003e78:	85a6                	mv	a1,s1
  len = path - s;
    80003e7a:	8a5e                	mv	s4,s7
    80003e7c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e7e:	01278963          	beq	a5,s2,80003e90 <namex+0x130>
    80003e82:	dfbd                	beqz	a5,80003e00 <namex+0xa0>
    path++;
    80003e84:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e86:	0004c783          	lbu	a5,0(s1)
    80003e8a:	ff279ce3          	bne	a5,s2,80003e82 <namex+0x122>
    80003e8e:	bf8d                	j	80003e00 <namex+0xa0>
    memmove(name, s, len);
    80003e90:	2601                	sext.w	a2,a2
    80003e92:	8556                	mv	a0,s5
    80003e94:	ffffd097          	auipc	ra,0xffffd
    80003e98:	eac080e7          	jalr	-340(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003e9c:	9a56                	add	s4,s4,s5
    80003e9e:	000a0023          	sb	zero,0(s4)
    80003ea2:	bf9d                	j	80003e18 <namex+0xb8>
  if(nameiparent){
    80003ea4:	f20b03e3          	beqz	s6,80003dca <namex+0x6a>
    iput(ip);
    80003ea8:	854e                	mv	a0,s3
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	adc080e7          	jalr	-1316(ra) # 80003986 <iput>
    return 0;
    80003eb2:	4981                	li	s3,0
    80003eb4:	bf19                	j	80003dca <namex+0x6a>
  if(*path == 0)
    80003eb6:	d7fd                	beqz	a5,80003ea4 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003eb8:	0004c783          	lbu	a5,0(s1)
    80003ebc:	85a6                	mv	a1,s1
    80003ebe:	b7d1                	j	80003e82 <namex+0x122>

0000000080003ec0 <dirlink>:
{
    80003ec0:	7139                	addi	sp,sp,-64
    80003ec2:	fc06                	sd	ra,56(sp)
    80003ec4:	f822                	sd	s0,48(sp)
    80003ec6:	f426                	sd	s1,40(sp)
    80003ec8:	f04a                	sd	s2,32(sp)
    80003eca:	ec4e                	sd	s3,24(sp)
    80003ecc:	e852                	sd	s4,16(sp)
    80003ece:	0080                	addi	s0,sp,64
    80003ed0:	892a                	mv	s2,a0
    80003ed2:	8a2e                	mv	s4,a1
    80003ed4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ed6:	4601                	li	a2,0
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	dd8080e7          	jalr	-552(ra) # 80003cb0 <dirlookup>
    80003ee0:	e93d                	bnez	a0,80003f56 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee2:	04c92483          	lw	s1,76(s2)
    80003ee6:	c49d                	beqz	s1,80003f14 <dirlink+0x54>
    80003ee8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eea:	4741                	li	a4,16
    80003eec:	86a6                	mv	a3,s1
    80003eee:	fc040613          	addi	a2,s0,-64
    80003ef2:	4581                	li	a1,0
    80003ef4:	854a                	mv	a0,s2
    80003ef6:	00000097          	auipc	ra,0x0
    80003efa:	b8a080e7          	jalr	-1142(ra) # 80003a80 <readi>
    80003efe:	47c1                	li	a5,16
    80003f00:	06f51163          	bne	a0,a5,80003f62 <dirlink+0xa2>
    if(de.inum == 0)
    80003f04:	fc045783          	lhu	a5,-64(s0)
    80003f08:	c791                	beqz	a5,80003f14 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f0a:	24c1                	addiw	s1,s1,16
    80003f0c:	04c92783          	lw	a5,76(s2)
    80003f10:	fcf4ede3          	bltu	s1,a5,80003eea <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f14:	4639                	li	a2,14
    80003f16:	85d2                	mv	a1,s4
    80003f18:	fc240513          	addi	a0,s0,-62
    80003f1c:	ffffd097          	auipc	ra,0xffffd
    80003f20:	ed8080e7          	jalr	-296(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003f24:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f28:	4741                	li	a4,16
    80003f2a:	86a6                	mv	a3,s1
    80003f2c:	fc040613          	addi	a2,s0,-64
    80003f30:	4581                	li	a1,0
    80003f32:	854a                	mv	a0,s2
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	c44080e7          	jalr	-956(ra) # 80003b78 <writei>
    80003f3c:	872a                	mv	a4,a0
    80003f3e:	47c1                	li	a5,16
  return 0;
    80003f40:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f42:	02f71863          	bne	a4,a5,80003f72 <dirlink+0xb2>
}
    80003f46:	70e2                	ld	ra,56(sp)
    80003f48:	7442                	ld	s0,48(sp)
    80003f4a:	74a2                	ld	s1,40(sp)
    80003f4c:	7902                	ld	s2,32(sp)
    80003f4e:	69e2                	ld	s3,24(sp)
    80003f50:	6a42                	ld	s4,16(sp)
    80003f52:	6121                	addi	sp,sp,64
    80003f54:	8082                	ret
    iput(ip);
    80003f56:	00000097          	auipc	ra,0x0
    80003f5a:	a30080e7          	jalr	-1488(ra) # 80003986 <iput>
    return -1;
    80003f5e:	557d                	li	a0,-1
    80003f60:	b7dd                	j	80003f46 <dirlink+0x86>
      panic("dirlink read");
    80003f62:	00004517          	auipc	a0,0x4
    80003f66:	6ee50513          	addi	a0,a0,1774 # 80008650 <syscalls+0x1d8>
    80003f6a:	ffffc097          	auipc	ra,0xffffc
    80003f6e:	5d4080e7          	jalr	1492(ra) # 8000053e <panic>
    panic("dirlink");
    80003f72:	00004517          	auipc	a0,0x4
    80003f76:	7ee50513          	addi	a0,a0,2030 # 80008760 <syscalls+0x2e8>
    80003f7a:	ffffc097          	auipc	ra,0xffffc
    80003f7e:	5c4080e7          	jalr	1476(ra) # 8000053e <panic>

0000000080003f82 <namei>:

struct inode*
namei(char *path)
{
    80003f82:	1101                	addi	sp,sp,-32
    80003f84:	ec06                	sd	ra,24(sp)
    80003f86:	e822                	sd	s0,16(sp)
    80003f88:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f8a:	fe040613          	addi	a2,s0,-32
    80003f8e:	4581                	li	a1,0
    80003f90:	00000097          	auipc	ra,0x0
    80003f94:	dd0080e7          	jalr	-560(ra) # 80003d60 <namex>
}
    80003f98:	60e2                	ld	ra,24(sp)
    80003f9a:	6442                	ld	s0,16(sp)
    80003f9c:	6105                	addi	sp,sp,32
    80003f9e:	8082                	ret

0000000080003fa0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fa0:	1141                	addi	sp,sp,-16
    80003fa2:	e406                	sd	ra,8(sp)
    80003fa4:	e022                	sd	s0,0(sp)
    80003fa6:	0800                	addi	s0,sp,16
    80003fa8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003faa:	4585                	li	a1,1
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	db4080e7          	jalr	-588(ra) # 80003d60 <namex>
}
    80003fb4:	60a2                	ld	ra,8(sp)
    80003fb6:	6402                	ld	s0,0(sp)
    80003fb8:	0141                	addi	sp,sp,16
    80003fba:	8082                	ret

0000000080003fbc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fbc:	1101                	addi	sp,sp,-32
    80003fbe:	ec06                	sd	ra,24(sp)
    80003fc0:	e822                	sd	s0,16(sp)
    80003fc2:	e426                	sd	s1,8(sp)
    80003fc4:	e04a                	sd	s2,0(sp)
    80003fc6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fc8:	0001d917          	auipc	s2,0x1d
    80003fcc:	6a890913          	addi	s2,s2,1704 # 80021670 <log>
    80003fd0:	01892583          	lw	a1,24(s2)
    80003fd4:	02892503          	lw	a0,40(s2)
    80003fd8:	fffff097          	auipc	ra,0xfffff
    80003fdc:	ff2080e7          	jalr	-14(ra) # 80002fca <bread>
    80003fe0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fe2:	02c92683          	lw	a3,44(s2)
    80003fe6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fe8:	02d05763          	blez	a3,80004016 <write_head+0x5a>
    80003fec:	0001d797          	auipc	a5,0x1d
    80003ff0:	6b478793          	addi	a5,a5,1716 # 800216a0 <log+0x30>
    80003ff4:	05c50713          	addi	a4,a0,92
    80003ff8:	36fd                	addiw	a3,a3,-1
    80003ffa:	1682                	slli	a3,a3,0x20
    80003ffc:	9281                	srli	a3,a3,0x20
    80003ffe:	068a                	slli	a3,a3,0x2
    80004000:	0001d617          	auipc	a2,0x1d
    80004004:	6a460613          	addi	a2,a2,1700 # 800216a4 <log+0x34>
    80004008:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000400a:	4390                	lw	a2,0(a5)
    8000400c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000400e:	0791                	addi	a5,a5,4
    80004010:	0711                	addi	a4,a4,4
    80004012:	fed79ce3          	bne	a5,a3,8000400a <write_head+0x4e>
  }
  bwrite(buf);
    80004016:	8526                	mv	a0,s1
    80004018:	fffff097          	auipc	ra,0xfffff
    8000401c:	0a4080e7          	jalr	164(ra) # 800030bc <bwrite>
  brelse(buf);
    80004020:	8526                	mv	a0,s1
    80004022:	fffff097          	auipc	ra,0xfffff
    80004026:	0d8080e7          	jalr	216(ra) # 800030fa <brelse>
}
    8000402a:	60e2                	ld	ra,24(sp)
    8000402c:	6442                	ld	s0,16(sp)
    8000402e:	64a2                	ld	s1,8(sp)
    80004030:	6902                	ld	s2,0(sp)
    80004032:	6105                	addi	sp,sp,32
    80004034:	8082                	ret

0000000080004036 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004036:	0001d797          	auipc	a5,0x1d
    8000403a:	6667a783          	lw	a5,1638(a5) # 8002169c <log+0x2c>
    8000403e:	0af05d63          	blez	a5,800040f8 <install_trans+0xc2>
{
    80004042:	7139                	addi	sp,sp,-64
    80004044:	fc06                	sd	ra,56(sp)
    80004046:	f822                	sd	s0,48(sp)
    80004048:	f426                	sd	s1,40(sp)
    8000404a:	f04a                	sd	s2,32(sp)
    8000404c:	ec4e                	sd	s3,24(sp)
    8000404e:	e852                	sd	s4,16(sp)
    80004050:	e456                	sd	s5,8(sp)
    80004052:	e05a                	sd	s6,0(sp)
    80004054:	0080                	addi	s0,sp,64
    80004056:	8b2a                	mv	s6,a0
    80004058:	0001da97          	auipc	s5,0x1d
    8000405c:	648a8a93          	addi	s5,s5,1608 # 800216a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004060:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004062:	0001d997          	auipc	s3,0x1d
    80004066:	60e98993          	addi	s3,s3,1550 # 80021670 <log>
    8000406a:	a035                	j	80004096 <install_trans+0x60>
      bunpin(dbuf);
    8000406c:	8526                	mv	a0,s1
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	166080e7          	jalr	358(ra) # 800031d4 <bunpin>
    brelse(lbuf);
    80004076:	854a                	mv	a0,s2
    80004078:	fffff097          	auipc	ra,0xfffff
    8000407c:	082080e7          	jalr	130(ra) # 800030fa <brelse>
    brelse(dbuf);
    80004080:	8526                	mv	a0,s1
    80004082:	fffff097          	auipc	ra,0xfffff
    80004086:	078080e7          	jalr	120(ra) # 800030fa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000408a:	2a05                	addiw	s4,s4,1
    8000408c:	0a91                	addi	s5,s5,4
    8000408e:	02c9a783          	lw	a5,44(s3)
    80004092:	04fa5963          	bge	s4,a5,800040e4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004096:	0189a583          	lw	a1,24(s3)
    8000409a:	014585bb          	addw	a1,a1,s4
    8000409e:	2585                	addiw	a1,a1,1
    800040a0:	0289a503          	lw	a0,40(s3)
    800040a4:	fffff097          	auipc	ra,0xfffff
    800040a8:	f26080e7          	jalr	-218(ra) # 80002fca <bread>
    800040ac:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040ae:	000aa583          	lw	a1,0(s5)
    800040b2:	0289a503          	lw	a0,40(s3)
    800040b6:	fffff097          	auipc	ra,0xfffff
    800040ba:	f14080e7          	jalr	-236(ra) # 80002fca <bread>
    800040be:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040c0:	40000613          	li	a2,1024
    800040c4:	05890593          	addi	a1,s2,88
    800040c8:	05850513          	addi	a0,a0,88
    800040cc:	ffffd097          	auipc	ra,0xffffd
    800040d0:	c74080e7          	jalr	-908(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040d4:	8526                	mv	a0,s1
    800040d6:	fffff097          	auipc	ra,0xfffff
    800040da:	fe6080e7          	jalr	-26(ra) # 800030bc <bwrite>
    if(recovering == 0)
    800040de:	f80b1ce3          	bnez	s6,80004076 <install_trans+0x40>
    800040e2:	b769                	j	8000406c <install_trans+0x36>
}
    800040e4:	70e2                	ld	ra,56(sp)
    800040e6:	7442                	ld	s0,48(sp)
    800040e8:	74a2                	ld	s1,40(sp)
    800040ea:	7902                	ld	s2,32(sp)
    800040ec:	69e2                	ld	s3,24(sp)
    800040ee:	6a42                	ld	s4,16(sp)
    800040f0:	6aa2                	ld	s5,8(sp)
    800040f2:	6b02                	ld	s6,0(sp)
    800040f4:	6121                	addi	sp,sp,64
    800040f6:	8082                	ret
    800040f8:	8082                	ret

00000000800040fa <initlog>:
{
    800040fa:	7179                	addi	sp,sp,-48
    800040fc:	f406                	sd	ra,40(sp)
    800040fe:	f022                	sd	s0,32(sp)
    80004100:	ec26                	sd	s1,24(sp)
    80004102:	e84a                	sd	s2,16(sp)
    80004104:	e44e                	sd	s3,8(sp)
    80004106:	1800                	addi	s0,sp,48
    80004108:	892a                	mv	s2,a0
    8000410a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000410c:	0001d497          	auipc	s1,0x1d
    80004110:	56448493          	addi	s1,s1,1380 # 80021670 <log>
    80004114:	00004597          	auipc	a1,0x4
    80004118:	54c58593          	addi	a1,a1,1356 # 80008660 <syscalls+0x1e8>
    8000411c:	8526                	mv	a0,s1
    8000411e:	ffffd097          	auipc	ra,0xffffd
    80004122:	a36080e7          	jalr	-1482(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004126:	0149a583          	lw	a1,20(s3)
    8000412a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000412c:	0109a783          	lw	a5,16(s3)
    80004130:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004132:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004136:	854a                	mv	a0,s2
    80004138:	fffff097          	auipc	ra,0xfffff
    8000413c:	e92080e7          	jalr	-366(ra) # 80002fca <bread>
  log.lh.n = lh->n;
    80004140:	4d3c                	lw	a5,88(a0)
    80004142:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004144:	02f05563          	blez	a5,8000416e <initlog+0x74>
    80004148:	05c50713          	addi	a4,a0,92
    8000414c:	0001d697          	auipc	a3,0x1d
    80004150:	55468693          	addi	a3,a3,1364 # 800216a0 <log+0x30>
    80004154:	37fd                	addiw	a5,a5,-1
    80004156:	1782                	slli	a5,a5,0x20
    80004158:	9381                	srli	a5,a5,0x20
    8000415a:	078a                	slli	a5,a5,0x2
    8000415c:	06050613          	addi	a2,a0,96
    80004160:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004162:	4310                	lw	a2,0(a4)
    80004164:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004166:	0711                	addi	a4,a4,4
    80004168:	0691                	addi	a3,a3,4
    8000416a:	fef71ce3          	bne	a4,a5,80004162 <initlog+0x68>
  brelse(buf);
    8000416e:	fffff097          	auipc	ra,0xfffff
    80004172:	f8c080e7          	jalr	-116(ra) # 800030fa <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004176:	4505                	li	a0,1
    80004178:	00000097          	auipc	ra,0x0
    8000417c:	ebe080e7          	jalr	-322(ra) # 80004036 <install_trans>
  log.lh.n = 0;
    80004180:	0001d797          	auipc	a5,0x1d
    80004184:	5007ae23          	sw	zero,1308(a5) # 8002169c <log+0x2c>
  write_head(); // clear the log
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	e34080e7          	jalr	-460(ra) # 80003fbc <write_head>
}
    80004190:	70a2                	ld	ra,40(sp)
    80004192:	7402                	ld	s0,32(sp)
    80004194:	64e2                	ld	s1,24(sp)
    80004196:	6942                	ld	s2,16(sp)
    80004198:	69a2                	ld	s3,8(sp)
    8000419a:	6145                	addi	sp,sp,48
    8000419c:	8082                	ret

000000008000419e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000419e:	1101                	addi	sp,sp,-32
    800041a0:	ec06                	sd	ra,24(sp)
    800041a2:	e822                	sd	s0,16(sp)
    800041a4:	e426                	sd	s1,8(sp)
    800041a6:	e04a                	sd	s2,0(sp)
    800041a8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041aa:	0001d517          	auipc	a0,0x1d
    800041ae:	4c650513          	addi	a0,a0,1222 # 80021670 <log>
    800041b2:	ffffd097          	auipc	ra,0xffffd
    800041b6:	a32080e7          	jalr	-1486(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800041ba:	0001d497          	auipc	s1,0x1d
    800041be:	4b648493          	addi	s1,s1,1206 # 80021670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041c2:	4979                	li	s2,30
    800041c4:	a039                	j	800041d2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041c6:	85a6                	mv	a1,s1
    800041c8:	8526                	mv	a0,s1
    800041ca:	ffffe097          	auipc	ra,0xffffe
    800041ce:	fa8080e7          	jalr	-88(ra) # 80002172 <sleep>
    if(log.committing){
    800041d2:	50dc                	lw	a5,36(s1)
    800041d4:	fbed                	bnez	a5,800041c6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041d6:	509c                	lw	a5,32(s1)
    800041d8:	0017871b          	addiw	a4,a5,1
    800041dc:	0007069b          	sext.w	a3,a4
    800041e0:	0027179b          	slliw	a5,a4,0x2
    800041e4:	9fb9                	addw	a5,a5,a4
    800041e6:	0017979b          	slliw	a5,a5,0x1
    800041ea:	54d8                	lw	a4,44(s1)
    800041ec:	9fb9                	addw	a5,a5,a4
    800041ee:	00f95963          	bge	s2,a5,80004200 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041f2:	85a6                	mv	a1,s1
    800041f4:	8526                	mv	a0,s1
    800041f6:	ffffe097          	auipc	ra,0xffffe
    800041fa:	f7c080e7          	jalr	-132(ra) # 80002172 <sleep>
    800041fe:	bfd1                	j	800041d2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004200:	0001d517          	auipc	a0,0x1d
    80004204:	47050513          	addi	a0,a0,1136 # 80021670 <log>
    80004208:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000420a:	ffffd097          	auipc	ra,0xffffd
    8000420e:	a8e080e7          	jalr	-1394(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004212:	60e2                	ld	ra,24(sp)
    80004214:	6442                	ld	s0,16(sp)
    80004216:	64a2                	ld	s1,8(sp)
    80004218:	6902                	ld	s2,0(sp)
    8000421a:	6105                	addi	sp,sp,32
    8000421c:	8082                	ret

000000008000421e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000421e:	7139                	addi	sp,sp,-64
    80004220:	fc06                	sd	ra,56(sp)
    80004222:	f822                	sd	s0,48(sp)
    80004224:	f426                	sd	s1,40(sp)
    80004226:	f04a                	sd	s2,32(sp)
    80004228:	ec4e                	sd	s3,24(sp)
    8000422a:	e852                	sd	s4,16(sp)
    8000422c:	e456                	sd	s5,8(sp)
    8000422e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004230:	0001d497          	auipc	s1,0x1d
    80004234:	44048493          	addi	s1,s1,1088 # 80021670 <log>
    80004238:	8526                	mv	a0,s1
    8000423a:	ffffd097          	auipc	ra,0xffffd
    8000423e:	9aa080e7          	jalr	-1622(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004242:	509c                	lw	a5,32(s1)
    80004244:	37fd                	addiw	a5,a5,-1
    80004246:	0007891b          	sext.w	s2,a5
    8000424a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000424c:	50dc                	lw	a5,36(s1)
    8000424e:	efb9                	bnez	a5,800042ac <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004250:	06091663          	bnez	s2,800042bc <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004254:	0001d497          	auipc	s1,0x1d
    80004258:	41c48493          	addi	s1,s1,1052 # 80021670 <log>
    8000425c:	4785                	li	a5,1
    8000425e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004260:	8526                	mv	a0,s1
    80004262:	ffffd097          	auipc	ra,0xffffd
    80004266:	a36080e7          	jalr	-1482(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000426a:	54dc                	lw	a5,44(s1)
    8000426c:	06f04763          	bgtz	a5,800042da <end_op+0xbc>
    acquire(&log.lock);
    80004270:	0001d497          	auipc	s1,0x1d
    80004274:	40048493          	addi	s1,s1,1024 # 80021670 <log>
    80004278:	8526                	mv	a0,s1
    8000427a:	ffffd097          	auipc	ra,0xffffd
    8000427e:	96a080e7          	jalr	-1686(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004282:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004286:	8526                	mv	a0,s1
    80004288:	ffffe097          	auipc	ra,0xffffe
    8000428c:	076080e7          	jalr	118(ra) # 800022fe <wakeup>
    release(&log.lock);
    80004290:	8526                	mv	a0,s1
    80004292:	ffffd097          	auipc	ra,0xffffd
    80004296:	a06080e7          	jalr	-1530(ra) # 80000c98 <release>
}
    8000429a:	70e2                	ld	ra,56(sp)
    8000429c:	7442                	ld	s0,48(sp)
    8000429e:	74a2                	ld	s1,40(sp)
    800042a0:	7902                	ld	s2,32(sp)
    800042a2:	69e2                	ld	s3,24(sp)
    800042a4:	6a42                	ld	s4,16(sp)
    800042a6:	6aa2                	ld	s5,8(sp)
    800042a8:	6121                	addi	sp,sp,64
    800042aa:	8082                	ret
    panic("log.committing");
    800042ac:	00004517          	auipc	a0,0x4
    800042b0:	3bc50513          	addi	a0,a0,956 # 80008668 <syscalls+0x1f0>
    800042b4:	ffffc097          	auipc	ra,0xffffc
    800042b8:	28a080e7          	jalr	650(ra) # 8000053e <panic>
    wakeup(&log);
    800042bc:	0001d497          	auipc	s1,0x1d
    800042c0:	3b448493          	addi	s1,s1,948 # 80021670 <log>
    800042c4:	8526                	mv	a0,s1
    800042c6:	ffffe097          	auipc	ra,0xffffe
    800042ca:	038080e7          	jalr	56(ra) # 800022fe <wakeup>
  release(&log.lock);
    800042ce:	8526                	mv	a0,s1
    800042d0:	ffffd097          	auipc	ra,0xffffd
    800042d4:	9c8080e7          	jalr	-1592(ra) # 80000c98 <release>
  if(do_commit){
    800042d8:	b7c9                	j	8000429a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042da:	0001da97          	auipc	s5,0x1d
    800042de:	3c6a8a93          	addi	s5,s5,966 # 800216a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042e2:	0001da17          	auipc	s4,0x1d
    800042e6:	38ea0a13          	addi	s4,s4,910 # 80021670 <log>
    800042ea:	018a2583          	lw	a1,24(s4)
    800042ee:	012585bb          	addw	a1,a1,s2
    800042f2:	2585                	addiw	a1,a1,1
    800042f4:	028a2503          	lw	a0,40(s4)
    800042f8:	fffff097          	auipc	ra,0xfffff
    800042fc:	cd2080e7          	jalr	-814(ra) # 80002fca <bread>
    80004300:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004302:	000aa583          	lw	a1,0(s5)
    80004306:	028a2503          	lw	a0,40(s4)
    8000430a:	fffff097          	auipc	ra,0xfffff
    8000430e:	cc0080e7          	jalr	-832(ra) # 80002fca <bread>
    80004312:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004314:	40000613          	li	a2,1024
    80004318:	05850593          	addi	a1,a0,88
    8000431c:	05848513          	addi	a0,s1,88
    80004320:	ffffd097          	auipc	ra,0xffffd
    80004324:	a20080e7          	jalr	-1504(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004328:	8526                	mv	a0,s1
    8000432a:	fffff097          	auipc	ra,0xfffff
    8000432e:	d92080e7          	jalr	-622(ra) # 800030bc <bwrite>
    brelse(from);
    80004332:	854e                	mv	a0,s3
    80004334:	fffff097          	auipc	ra,0xfffff
    80004338:	dc6080e7          	jalr	-570(ra) # 800030fa <brelse>
    brelse(to);
    8000433c:	8526                	mv	a0,s1
    8000433e:	fffff097          	auipc	ra,0xfffff
    80004342:	dbc080e7          	jalr	-580(ra) # 800030fa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004346:	2905                	addiw	s2,s2,1
    80004348:	0a91                	addi	s5,s5,4
    8000434a:	02ca2783          	lw	a5,44(s4)
    8000434e:	f8f94ee3          	blt	s2,a5,800042ea <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004352:	00000097          	auipc	ra,0x0
    80004356:	c6a080e7          	jalr	-918(ra) # 80003fbc <write_head>
    install_trans(0); // Now install writes to home locations
    8000435a:	4501                	li	a0,0
    8000435c:	00000097          	auipc	ra,0x0
    80004360:	cda080e7          	jalr	-806(ra) # 80004036 <install_trans>
    log.lh.n = 0;
    80004364:	0001d797          	auipc	a5,0x1d
    80004368:	3207ac23          	sw	zero,824(a5) # 8002169c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000436c:	00000097          	auipc	ra,0x0
    80004370:	c50080e7          	jalr	-944(ra) # 80003fbc <write_head>
    80004374:	bdf5                	j	80004270 <end_op+0x52>

0000000080004376 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004376:	1101                	addi	sp,sp,-32
    80004378:	ec06                	sd	ra,24(sp)
    8000437a:	e822                	sd	s0,16(sp)
    8000437c:	e426                	sd	s1,8(sp)
    8000437e:	e04a                	sd	s2,0(sp)
    80004380:	1000                	addi	s0,sp,32
    80004382:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004384:	0001d917          	auipc	s2,0x1d
    80004388:	2ec90913          	addi	s2,s2,748 # 80021670 <log>
    8000438c:	854a                	mv	a0,s2
    8000438e:	ffffd097          	auipc	ra,0xffffd
    80004392:	856080e7          	jalr	-1962(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004396:	02c92603          	lw	a2,44(s2)
    8000439a:	47f5                	li	a5,29
    8000439c:	06c7c563          	blt	a5,a2,80004406 <log_write+0x90>
    800043a0:	0001d797          	auipc	a5,0x1d
    800043a4:	2ec7a783          	lw	a5,748(a5) # 8002168c <log+0x1c>
    800043a8:	37fd                	addiw	a5,a5,-1
    800043aa:	04f65e63          	bge	a2,a5,80004406 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043ae:	0001d797          	auipc	a5,0x1d
    800043b2:	2e27a783          	lw	a5,738(a5) # 80021690 <log+0x20>
    800043b6:	06f05063          	blez	a5,80004416 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043ba:	4781                	li	a5,0
    800043bc:	06c05563          	blez	a2,80004426 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043c0:	44cc                	lw	a1,12(s1)
    800043c2:	0001d717          	auipc	a4,0x1d
    800043c6:	2de70713          	addi	a4,a4,734 # 800216a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043ca:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043cc:	4314                	lw	a3,0(a4)
    800043ce:	04b68c63          	beq	a3,a1,80004426 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043d2:	2785                	addiw	a5,a5,1
    800043d4:	0711                	addi	a4,a4,4
    800043d6:	fef61be3          	bne	a2,a5,800043cc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043da:	0621                	addi	a2,a2,8
    800043dc:	060a                	slli	a2,a2,0x2
    800043de:	0001d797          	auipc	a5,0x1d
    800043e2:	29278793          	addi	a5,a5,658 # 80021670 <log>
    800043e6:	963e                	add	a2,a2,a5
    800043e8:	44dc                	lw	a5,12(s1)
    800043ea:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043ec:	8526                	mv	a0,s1
    800043ee:	fffff097          	auipc	ra,0xfffff
    800043f2:	daa080e7          	jalr	-598(ra) # 80003198 <bpin>
    log.lh.n++;
    800043f6:	0001d717          	auipc	a4,0x1d
    800043fa:	27a70713          	addi	a4,a4,634 # 80021670 <log>
    800043fe:	575c                	lw	a5,44(a4)
    80004400:	2785                	addiw	a5,a5,1
    80004402:	d75c                	sw	a5,44(a4)
    80004404:	a835                	j	80004440 <log_write+0xca>
    panic("too big a transaction");
    80004406:	00004517          	auipc	a0,0x4
    8000440a:	27250513          	addi	a0,a0,626 # 80008678 <syscalls+0x200>
    8000440e:	ffffc097          	auipc	ra,0xffffc
    80004412:	130080e7          	jalr	304(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004416:	00004517          	auipc	a0,0x4
    8000441a:	27a50513          	addi	a0,a0,634 # 80008690 <syscalls+0x218>
    8000441e:	ffffc097          	auipc	ra,0xffffc
    80004422:	120080e7          	jalr	288(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004426:	00878713          	addi	a4,a5,8
    8000442a:	00271693          	slli	a3,a4,0x2
    8000442e:	0001d717          	auipc	a4,0x1d
    80004432:	24270713          	addi	a4,a4,578 # 80021670 <log>
    80004436:	9736                	add	a4,a4,a3
    80004438:	44d4                	lw	a3,12(s1)
    8000443a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000443c:	faf608e3          	beq	a2,a5,800043ec <log_write+0x76>
  }
  release(&log.lock);
    80004440:	0001d517          	auipc	a0,0x1d
    80004444:	23050513          	addi	a0,a0,560 # 80021670 <log>
    80004448:	ffffd097          	auipc	ra,0xffffd
    8000444c:	850080e7          	jalr	-1968(ra) # 80000c98 <release>
}
    80004450:	60e2                	ld	ra,24(sp)
    80004452:	6442                	ld	s0,16(sp)
    80004454:	64a2                	ld	s1,8(sp)
    80004456:	6902                	ld	s2,0(sp)
    80004458:	6105                	addi	sp,sp,32
    8000445a:	8082                	ret

000000008000445c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000445c:	1101                	addi	sp,sp,-32
    8000445e:	ec06                	sd	ra,24(sp)
    80004460:	e822                	sd	s0,16(sp)
    80004462:	e426                	sd	s1,8(sp)
    80004464:	e04a                	sd	s2,0(sp)
    80004466:	1000                	addi	s0,sp,32
    80004468:	84aa                	mv	s1,a0
    8000446a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000446c:	00004597          	auipc	a1,0x4
    80004470:	24458593          	addi	a1,a1,580 # 800086b0 <syscalls+0x238>
    80004474:	0521                	addi	a0,a0,8
    80004476:	ffffc097          	auipc	ra,0xffffc
    8000447a:	6de080e7          	jalr	1758(ra) # 80000b54 <initlock>
  lk->name = name;
    8000447e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004482:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004486:	0204a423          	sw	zero,40(s1)
}
    8000448a:	60e2                	ld	ra,24(sp)
    8000448c:	6442                	ld	s0,16(sp)
    8000448e:	64a2                	ld	s1,8(sp)
    80004490:	6902                	ld	s2,0(sp)
    80004492:	6105                	addi	sp,sp,32
    80004494:	8082                	ret

0000000080004496 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004496:	1101                	addi	sp,sp,-32
    80004498:	ec06                	sd	ra,24(sp)
    8000449a:	e822                	sd	s0,16(sp)
    8000449c:	e426                	sd	s1,8(sp)
    8000449e:	e04a                	sd	s2,0(sp)
    800044a0:	1000                	addi	s0,sp,32
    800044a2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044a4:	00850913          	addi	s2,a0,8
    800044a8:	854a                	mv	a0,s2
    800044aa:	ffffc097          	auipc	ra,0xffffc
    800044ae:	73a080e7          	jalr	1850(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800044b2:	409c                	lw	a5,0(s1)
    800044b4:	cb89                	beqz	a5,800044c6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044b6:	85ca                	mv	a1,s2
    800044b8:	8526                	mv	a0,s1
    800044ba:	ffffe097          	auipc	ra,0xffffe
    800044be:	cb8080e7          	jalr	-840(ra) # 80002172 <sleep>
  while (lk->locked) {
    800044c2:	409c                	lw	a5,0(s1)
    800044c4:	fbed                	bnez	a5,800044b6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044c6:	4785                	li	a5,1
    800044c8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044ca:	ffffd097          	auipc	ra,0xffffd
    800044ce:	4e6080e7          	jalr	1254(ra) # 800019b0 <myproc>
    800044d2:	591c                	lw	a5,48(a0)
    800044d4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044d6:	854a                	mv	a0,s2
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	7c0080e7          	jalr	1984(ra) # 80000c98 <release>
}
    800044e0:	60e2                	ld	ra,24(sp)
    800044e2:	6442                	ld	s0,16(sp)
    800044e4:	64a2                	ld	s1,8(sp)
    800044e6:	6902                	ld	s2,0(sp)
    800044e8:	6105                	addi	sp,sp,32
    800044ea:	8082                	ret

00000000800044ec <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044ec:	1101                	addi	sp,sp,-32
    800044ee:	ec06                	sd	ra,24(sp)
    800044f0:	e822                	sd	s0,16(sp)
    800044f2:	e426                	sd	s1,8(sp)
    800044f4:	e04a                	sd	s2,0(sp)
    800044f6:	1000                	addi	s0,sp,32
    800044f8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044fa:	00850913          	addi	s2,a0,8
    800044fe:	854a                	mv	a0,s2
    80004500:	ffffc097          	auipc	ra,0xffffc
    80004504:	6e4080e7          	jalr	1764(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004508:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000450c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004510:	8526                	mv	a0,s1
    80004512:	ffffe097          	auipc	ra,0xffffe
    80004516:	dec080e7          	jalr	-532(ra) # 800022fe <wakeup>
  release(&lk->lk);
    8000451a:	854a                	mv	a0,s2
    8000451c:	ffffc097          	auipc	ra,0xffffc
    80004520:	77c080e7          	jalr	1916(ra) # 80000c98 <release>
}
    80004524:	60e2                	ld	ra,24(sp)
    80004526:	6442                	ld	s0,16(sp)
    80004528:	64a2                	ld	s1,8(sp)
    8000452a:	6902                	ld	s2,0(sp)
    8000452c:	6105                	addi	sp,sp,32
    8000452e:	8082                	ret

0000000080004530 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004530:	7179                	addi	sp,sp,-48
    80004532:	f406                	sd	ra,40(sp)
    80004534:	f022                	sd	s0,32(sp)
    80004536:	ec26                	sd	s1,24(sp)
    80004538:	e84a                	sd	s2,16(sp)
    8000453a:	e44e                	sd	s3,8(sp)
    8000453c:	1800                	addi	s0,sp,48
    8000453e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004540:	00850913          	addi	s2,a0,8
    80004544:	854a                	mv	a0,s2
    80004546:	ffffc097          	auipc	ra,0xffffc
    8000454a:	69e080e7          	jalr	1694(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000454e:	409c                	lw	a5,0(s1)
    80004550:	ef99                	bnez	a5,8000456e <holdingsleep+0x3e>
    80004552:	4481                	li	s1,0
  release(&lk->lk);
    80004554:	854a                	mv	a0,s2
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	742080e7          	jalr	1858(ra) # 80000c98 <release>
  return r;
}
    8000455e:	8526                	mv	a0,s1
    80004560:	70a2                	ld	ra,40(sp)
    80004562:	7402                	ld	s0,32(sp)
    80004564:	64e2                	ld	s1,24(sp)
    80004566:	6942                	ld	s2,16(sp)
    80004568:	69a2                	ld	s3,8(sp)
    8000456a:	6145                	addi	sp,sp,48
    8000456c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000456e:	0284a983          	lw	s3,40(s1)
    80004572:	ffffd097          	auipc	ra,0xffffd
    80004576:	43e080e7          	jalr	1086(ra) # 800019b0 <myproc>
    8000457a:	5904                	lw	s1,48(a0)
    8000457c:	413484b3          	sub	s1,s1,s3
    80004580:	0014b493          	seqz	s1,s1
    80004584:	bfc1                	j	80004554 <holdingsleep+0x24>

0000000080004586 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004586:	1141                	addi	sp,sp,-16
    80004588:	e406                	sd	ra,8(sp)
    8000458a:	e022                	sd	s0,0(sp)
    8000458c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000458e:	00004597          	auipc	a1,0x4
    80004592:	13258593          	addi	a1,a1,306 # 800086c0 <syscalls+0x248>
    80004596:	0001d517          	auipc	a0,0x1d
    8000459a:	22250513          	addi	a0,a0,546 # 800217b8 <ftable>
    8000459e:	ffffc097          	auipc	ra,0xffffc
    800045a2:	5b6080e7          	jalr	1462(ra) # 80000b54 <initlock>
}
    800045a6:	60a2                	ld	ra,8(sp)
    800045a8:	6402                	ld	s0,0(sp)
    800045aa:	0141                	addi	sp,sp,16
    800045ac:	8082                	ret

00000000800045ae <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045ae:	1101                	addi	sp,sp,-32
    800045b0:	ec06                	sd	ra,24(sp)
    800045b2:	e822                	sd	s0,16(sp)
    800045b4:	e426                	sd	s1,8(sp)
    800045b6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045b8:	0001d517          	auipc	a0,0x1d
    800045bc:	20050513          	addi	a0,a0,512 # 800217b8 <ftable>
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	624080e7          	jalr	1572(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045c8:	0001d497          	auipc	s1,0x1d
    800045cc:	20848493          	addi	s1,s1,520 # 800217d0 <ftable+0x18>
    800045d0:	0001e717          	auipc	a4,0x1e
    800045d4:	1a070713          	addi	a4,a4,416 # 80022770 <ftable+0xfb8>
    if(f->ref == 0){
    800045d8:	40dc                	lw	a5,4(s1)
    800045da:	cf99                	beqz	a5,800045f8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045dc:	02848493          	addi	s1,s1,40
    800045e0:	fee49ce3          	bne	s1,a4,800045d8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045e4:	0001d517          	auipc	a0,0x1d
    800045e8:	1d450513          	addi	a0,a0,468 # 800217b8 <ftable>
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	6ac080e7          	jalr	1708(ra) # 80000c98 <release>
  return 0;
    800045f4:	4481                	li	s1,0
    800045f6:	a819                	j	8000460c <filealloc+0x5e>
      f->ref = 1;
    800045f8:	4785                	li	a5,1
    800045fa:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045fc:	0001d517          	auipc	a0,0x1d
    80004600:	1bc50513          	addi	a0,a0,444 # 800217b8 <ftable>
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	694080e7          	jalr	1684(ra) # 80000c98 <release>
}
    8000460c:	8526                	mv	a0,s1
    8000460e:	60e2                	ld	ra,24(sp)
    80004610:	6442                	ld	s0,16(sp)
    80004612:	64a2                	ld	s1,8(sp)
    80004614:	6105                	addi	sp,sp,32
    80004616:	8082                	ret

0000000080004618 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004618:	1101                	addi	sp,sp,-32
    8000461a:	ec06                	sd	ra,24(sp)
    8000461c:	e822                	sd	s0,16(sp)
    8000461e:	e426                	sd	s1,8(sp)
    80004620:	1000                	addi	s0,sp,32
    80004622:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004624:	0001d517          	auipc	a0,0x1d
    80004628:	19450513          	addi	a0,a0,404 # 800217b8 <ftable>
    8000462c:	ffffc097          	auipc	ra,0xffffc
    80004630:	5b8080e7          	jalr	1464(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004634:	40dc                	lw	a5,4(s1)
    80004636:	02f05263          	blez	a5,8000465a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000463a:	2785                	addiw	a5,a5,1
    8000463c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000463e:	0001d517          	auipc	a0,0x1d
    80004642:	17a50513          	addi	a0,a0,378 # 800217b8 <ftable>
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	652080e7          	jalr	1618(ra) # 80000c98 <release>
  return f;
}
    8000464e:	8526                	mv	a0,s1
    80004650:	60e2                	ld	ra,24(sp)
    80004652:	6442                	ld	s0,16(sp)
    80004654:	64a2                	ld	s1,8(sp)
    80004656:	6105                	addi	sp,sp,32
    80004658:	8082                	ret
    panic("filedup");
    8000465a:	00004517          	auipc	a0,0x4
    8000465e:	06e50513          	addi	a0,a0,110 # 800086c8 <syscalls+0x250>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	edc080e7          	jalr	-292(ra) # 8000053e <panic>

000000008000466a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000466a:	7139                	addi	sp,sp,-64
    8000466c:	fc06                	sd	ra,56(sp)
    8000466e:	f822                	sd	s0,48(sp)
    80004670:	f426                	sd	s1,40(sp)
    80004672:	f04a                	sd	s2,32(sp)
    80004674:	ec4e                	sd	s3,24(sp)
    80004676:	e852                	sd	s4,16(sp)
    80004678:	e456                	sd	s5,8(sp)
    8000467a:	0080                	addi	s0,sp,64
    8000467c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000467e:	0001d517          	auipc	a0,0x1d
    80004682:	13a50513          	addi	a0,a0,314 # 800217b8 <ftable>
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	55e080e7          	jalr	1374(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000468e:	40dc                	lw	a5,4(s1)
    80004690:	06f05163          	blez	a5,800046f2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004694:	37fd                	addiw	a5,a5,-1
    80004696:	0007871b          	sext.w	a4,a5
    8000469a:	c0dc                	sw	a5,4(s1)
    8000469c:	06e04363          	bgtz	a4,80004702 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046a0:	0004a903          	lw	s2,0(s1)
    800046a4:	0094ca83          	lbu	s5,9(s1)
    800046a8:	0104ba03          	ld	s4,16(s1)
    800046ac:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046b0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046b4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046b8:	0001d517          	auipc	a0,0x1d
    800046bc:	10050513          	addi	a0,a0,256 # 800217b8 <ftable>
    800046c0:	ffffc097          	auipc	ra,0xffffc
    800046c4:	5d8080e7          	jalr	1496(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800046c8:	4785                	li	a5,1
    800046ca:	04f90d63          	beq	s2,a5,80004724 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046ce:	3979                	addiw	s2,s2,-2
    800046d0:	4785                	li	a5,1
    800046d2:	0527e063          	bltu	a5,s2,80004712 <fileclose+0xa8>
    begin_op();
    800046d6:	00000097          	auipc	ra,0x0
    800046da:	ac8080e7          	jalr	-1336(ra) # 8000419e <begin_op>
    iput(ff.ip);
    800046de:	854e                	mv	a0,s3
    800046e0:	fffff097          	auipc	ra,0xfffff
    800046e4:	2a6080e7          	jalr	678(ra) # 80003986 <iput>
    end_op();
    800046e8:	00000097          	auipc	ra,0x0
    800046ec:	b36080e7          	jalr	-1226(ra) # 8000421e <end_op>
    800046f0:	a00d                	j	80004712 <fileclose+0xa8>
    panic("fileclose");
    800046f2:	00004517          	auipc	a0,0x4
    800046f6:	fde50513          	addi	a0,a0,-34 # 800086d0 <syscalls+0x258>
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	e44080e7          	jalr	-444(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004702:	0001d517          	auipc	a0,0x1d
    80004706:	0b650513          	addi	a0,a0,182 # 800217b8 <ftable>
    8000470a:	ffffc097          	auipc	ra,0xffffc
    8000470e:	58e080e7          	jalr	1422(ra) # 80000c98 <release>
  }
}
    80004712:	70e2                	ld	ra,56(sp)
    80004714:	7442                	ld	s0,48(sp)
    80004716:	74a2                	ld	s1,40(sp)
    80004718:	7902                	ld	s2,32(sp)
    8000471a:	69e2                	ld	s3,24(sp)
    8000471c:	6a42                	ld	s4,16(sp)
    8000471e:	6aa2                	ld	s5,8(sp)
    80004720:	6121                	addi	sp,sp,64
    80004722:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004724:	85d6                	mv	a1,s5
    80004726:	8552                	mv	a0,s4
    80004728:	00000097          	auipc	ra,0x0
    8000472c:	34c080e7          	jalr	844(ra) # 80004a74 <pipeclose>
    80004730:	b7cd                	j	80004712 <fileclose+0xa8>

0000000080004732 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004732:	715d                	addi	sp,sp,-80
    80004734:	e486                	sd	ra,72(sp)
    80004736:	e0a2                	sd	s0,64(sp)
    80004738:	fc26                	sd	s1,56(sp)
    8000473a:	f84a                	sd	s2,48(sp)
    8000473c:	f44e                	sd	s3,40(sp)
    8000473e:	0880                	addi	s0,sp,80
    80004740:	84aa                	mv	s1,a0
    80004742:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004744:	ffffd097          	auipc	ra,0xffffd
    80004748:	26c080e7          	jalr	620(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000474c:	409c                	lw	a5,0(s1)
    8000474e:	37f9                	addiw	a5,a5,-2
    80004750:	4705                	li	a4,1
    80004752:	04f76763          	bltu	a4,a5,800047a0 <filestat+0x6e>
    80004756:	892a                	mv	s2,a0
    ilock(f->ip);
    80004758:	6c88                	ld	a0,24(s1)
    8000475a:	fffff097          	auipc	ra,0xfffff
    8000475e:	072080e7          	jalr	114(ra) # 800037cc <ilock>
    stati(f->ip, &st);
    80004762:	fb840593          	addi	a1,s0,-72
    80004766:	6c88                	ld	a0,24(s1)
    80004768:	fffff097          	auipc	ra,0xfffff
    8000476c:	2ee080e7          	jalr	750(ra) # 80003a56 <stati>
    iunlock(f->ip);
    80004770:	6c88                	ld	a0,24(s1)
    80004772:	fffff097          	auipc	ra,0xfffff
    80004776:	11c080e7          	jalr	284(ra) # 8000388e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000477a:	46e1                	li	a3,24
    8000477c:	fb840613          	addi	a2,s0,-72
    80004780:	85ce                	mv	a1,s3
    80004782:	05093503          	ld	a0,80(s2)
    80004786:	ffffd097          	auipc	ra,0xffffd
    8000478a:	eec080e7          	jalr	-276(ra) # 80001672 <copyout>
    8000478e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004792:	60a6                	ld	ra,72(sp)
    80004794:	6406                	ld	s0,64(sp)
    80004796:	74e2                	ld	s1,56(sp)
    80004798:	7942                	ld	s2,48(sp)
    8000479a:	79a2                	ld	s3,40(sp)
    8000479c:	6161                	addi	sp,sp,80
    8000479e:	8082                	ret
  return -1;
    800047a0:	557d                	li	a0,-1
    800047a2:	bfc5                	j	80004792 <filestat+0x60>

00000000800047a4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047a4:	7179                	addi	sp,sp,-48
    800047a6:	f406                	sd	ra,40(sp)
    800047a8:	f022                	sd	s0,32(sp)
    800047aa:	ec26                	sd	s1,24(sp)
    800047ac:	e84a                	sd	s2,16(sp)
    800047ae:	e44e                	sd	s3,8(sp)
    800047b0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047b2:	00854783          	lbu	a5,8(a0)
    800047b6:	c3d5                	beqz	a5,8000485a <fileread+0xb6>
    800047b8:	84aa                	mv	s1,a0
    800047ba:	89ae                	mv	s3,a1
    800047bc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047be:	411c                	lw	a5,0(a0)
    800047c0:	4705                	li	a4,1
    800047c2:	04e78963          	beq	a5,a4,80004814 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047c6:	470d                	li	a4,3
    800047c8:	04e78d63          	beq	a5,a4,80004822 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047cc:	4709                	li	a4,2
    800047ce:	06e79e63          	bne	a5,a4,8000484a <fileread+0xa6>
    ilock(f->ip);
    800047d2:	6d08                	ld	a0,24(a0)
    800047d4:	fffff097          	auipc	ra,0xfffff
    800047d8:	ff8080e7          	jalr	-8(ra) # 800037cc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047dc:	874a                	mv	a4,s2
    800047de:	5094                	lw	a3,32(s1)
    800047e0:	864e                	mv	a2,s3
    800047e2:	4585                	li	a1,1
    800047e4:	6c88                	ld	a0,24(s1)
    800047e6:	fffff097          	auipc	ra,0xfffff
    800047ea:	29a080e7          	jalr	666(ra) # 80003a80 <readi>
    800047ee:	892a                	mv	s2,a0
    800047f0:	00a05563          	blez	a0,800047fa <fileread+0x56>
      f->off += r;
    800047f4:	509c                	lw	a5,32(s1)
    800047f6:	9fa9                	addw	a5,a5,a0
    800047f8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047fa:	6c88                	ld	a0,24(s1)
    800047fc:	fffff097          	auipc	ra,0xfffff
    80004800:	092080e7          	jalr	146(ra) # 8000388e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004804:	854a                	mv	a0,s2
    80004806:	70a2                	ld	ra,40(sp)
    80004808:	7402                	ld	s0,32(sp)
    8000480a:	64e2                	ld	s1,24(sp)
    8000480c:	6942                	ld	s2,16(sp)
    8000480e:	69a2                	ld	s3,8(sp)
    80004810:	6145                	addi	sp,sp,48
    80004812:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004814:	6908                	ld	a0,16(a0)
    80004816:	00000097          	auipc	ra,0x0
    8000481a:	3c8080e7          	jalr	968(ra) # 80004bde <piperead>
    8000481e:	892a                	mv	s2,a0
    80004820:	b7d5                	j	80004804 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004822:	02451783          	lh	a5,36(a0)
    80004826:	03079693          	slli	a3,a5,0x30
    8000482a:	92c1                	srli	a3,a3,0x30
    8000482c:	4725                	li	a4,9
    8000482e:	02d76863          	bltu	a4,a3,8000485e <fileread+0xba>
    80004832:	0792                	slli	a5,a5,0x4
    80004834:	0001d717          	auipc	a4,0x1d
    80004838:	ee470713          	addi	a4,a4,-284 # 80021718 <devsw>
    8000483c:	97ba                	add	a5,a5,a4
    8000483e:	639c                	ld	a5,0(a5)
    80004840:	c38d                	beqz	a5,80004862 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004842:	4505                	li	a0,1
    80004844:	9782                	jalr	a5
    80004846:	892a                	mv	s2,a0
    80004848:	bf75                	j	80004804 <fileread+0x60>
    panic("fileread");
    8000484a:	00004517          	auipc	a0,0x4
    8000484e:	e9650513          	addi	a0,a0,-362 # 800086e0 <syscalls+0x268>
    80004852:	ffffc097          	auipc	ra,0xffffc
    80004856:	cec080e7          	jalr	-788(ra) # 8000053e <panic>
    return -1;
    8000485a:	597d                	li	s2,-1
    8000485c:	b765                	j	80004804 <fileread+0x60>
      return -1;
    8000485e:	597d                	li	s2,-1
    80004860:	b755                	j	80004804 <fileread+0x60>
    80004862:	597d                	li	s2,-1
    80004864:	b745                	j	80004804 <fileread+0x60>

0000000080004866 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004866:	715d                	addi	sp,sp,-80
    80004868:	e486                	sd	ra,72(sp)
    8000486a:	e0a2                	sd	s0,64(sp)
    8000486c:	fc26                	sd	s1,56(sp)
    8000486e:	f84a                	sd	s2,48(sp)
    80004870:	f44e                	sd	s3,40(sp)
    80004872:	f052                	sd	s4,32(sp)
    80004874:	ec56                	sd	s5,24(sp)
    80004876:	e85a                	sd	s6,16(sp)
    80004878:	e45e                	sd	s7,8(sp)
    8000487a:	e062                	sd	s8,0(sp)
    8000487c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000487e:	00954783          	lbu	a5,9(a0)
    80004882:	10078663          	beqz	a5,8000498e <filewrite+0x128>
    80004886:	892a                	mv	s2,a0
    80004888:	8aae                	mv	s5,a1
    8000488a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000488c:	411c                	lw	a5,0(a0)
    8000488e:	4705                	li	a4,1
    80004890:	02e78263          	beq	a5,a4,800048b4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004894:	470d                	li	a4,3
    80004896:	02e78663          	beq	a5,a4,800048c2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000489a:	4709                	li	a4,2
    8000489c:	0ee79163          	bne	a5,a4,8000497e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048a0:	0ac05d63          	blez	a2,8000495a <filewrite+0xf4>
    int i = 0;
    800048a4:	4981                	li	s3,0
    800048a6:	6b05                	lui	s6,0x1
    800048a8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048ac:	6b85                	lui	s7,0x1
    800048ae:	c00b8b9b          	addiw	s7,s7,-1024
    800048b2:	a861                	j	8000494a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048b4:	6908                	ld	a0,16(a0)
    800048b6:	00000097          	auipc	ra,0x0
    800048ba:	22e080e7          	jalr	558(ra) # 80004ae4 <pipewrite>
    800048be:	8a2a                	mv	s4,a0
    800048c0:	a045                	j	80004960 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048c2:	02451783          	lh	a5,36(a0)
    800048c6:	03079693          	slli	a3,a5,0x30
    800048ca:	92c1                	srli	a3,a3,0x30
    800048cc:	4725                	li	a4,9
    800048ce:	0cd76263          	bltu	a4,a3,80004992 <filewrite+0x12c>
    800048d2:	0792                	slli	a5,a5,0x4
    800048d4:	0001d717          	auipc	a4,0x1d
    800048d8:	e4470713          	addi	a4,a4,-444 # 80021718 <devsw>
    800048dc:	97ba                	add	a5,a5,a4
    800048de:	679c                	ld	a5,8(a5)
    800048e0:	cbdd                	beqz	a5,80004996 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048e2:	4505                	li	a0,1
    800048e4:	9782                	jalr	a5
    800048e6:	8a2a                	mv	s4,a0
    800048e8:	a8a5                	j	80004960 <filewrite+0xfa>
    800048ea:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048ee:	00000097          	auipc	ra,0x0
    800048f2:	8b0080e7          	jalr	-1872(ra) # 8000419e <begin_op>
      ilock(f->ip);
    800048f6:	01893503          	ld	a0,24(s2)
    800048fa:	fffff097          	auipc	ra,0xfffff
    800048fe:	ed2080e7          	jalr	-302(ra) # 800037cc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004902:	8762                	mv	a4,s8
    80004904:	02092683          	lw	a3,32(s2)
    80004908:	01598633          	add	a2,s3,s5
    8000490c:	4585                	li	a1,1
    8000490e:	01893503          	ld	a0,24(s2)
    80004912:	fffff097          	auipc	ra,0xfffff
    80004916:	266080e7          	jalr	614(ra) # 80003b78 <writei>
    8000491a:	84aa                	mv	s1,a0
    8000491c:	00a05763          	blez	a0,8000492a <filewrite+0xc4>
        f->off += r;
    80004920:	02092783          	lw	a5,32(s2)
    80004924:	9fa9                	addw	a5,a5,a0
    80004926:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000492a:	01893503          	ld	a0,24(s2)
    8000492e:	fffff097          	auipc	ra,0xfffff
    80004932:	f60080e7          	jalr	-160(ra) # 8000388e <iunlock>
      end_op();
    80004936:	00000097          	auipc	ra,0x0
    8000493a:	8e8080e7          	jalr	-1816(ra) # 8000421e <end_op>

      if(r != n1){
    8000493e:	009c1f63          	bne	s8,s1,8000495c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004942:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004946:	0149db63          	bge	s3,s4,8000495c <filewrite+0xf6>
      int n1 = n - i;
    8000494a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000494e:	84be                	mv	s1,a5
    80004950:	2781                	sext.w	a5,a5
    80004952:	f8fb5ce3          	bge	s6,a5,800048ea <filewrite+0x84>
    80004956:	84de                	mv	s1,s7
    80004958:	bf49                	j	800048ea <filewrite+0x84>
    int i = 0;
    8000495a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000495c:	013a1f63          	bne	s4,s3,8000497a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004960:	8552                	mv	a0,s4
    80004962:	60a6                	ld	ra,72(sp)
    80004964:	6406                	ld	s0,64(sp)
    80004966:	74e2                	ld	s1,56(sp)
    80004968:	7942                	ld	s2,48(sp)
    8000496a:	79a2                	ld	s3,40(sp)
    8000496c:	7a02                	ld	s4,32(sp)
    8000496e:	6ae2                	ld	s5,24(sp)
    80004970:	6b42                	ld	s6,16(sp)
    80004972:	6ba2                	ld	s7,8(sp)
    80004974:	6c02                	ld	s8,0(sp)
    80004976:	6161                	addi	sp,sp,80
    80004978:	8082                	ret
    ret = (i == n ? n : -1);
    8000497a:	5a7d                	li	s4,-1
    8000497c:	b7d5                	j	80004960 <filewrite+0xfa>
    panic("filewrite");
    8000497e:	00004517          	auipc	a0,0x4
    80004982:	d7250513          	addi	a0,a0,-654 # 800086f0 <syscalls+0x278>
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	bb8080e7          	jalr	-1096(ra) # 8000053e <panic>
    return -1;
    8000498e:	5a7d                	li	s4,-1
    80004990:	bfc1                	j	80004960 <filewrite+0xfa>
      return -1;
    80004992:	5a7d                	li	s4,-1
    80004994:	b7f1                	j	80004960 <filewrite+0xfa>
    80004996:	5a7d                	li	s4,-1
    80004998:	b7e1                	j	80004960 <filewrite+0xfa>

000000008000499a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000499a:	7179                	addi	sp,sp,-48
    8000499c:	f406                	sd	ra,40(sp)
    8000499e:	f022                	sd	s0,32(sp)
    800049a0:	ec26                	sd	s1,24(sp)
    800049a2:	e84a                	sd	s2,16(sp)
    800049a4:	e44e                	sd	s3,8(sp)
    800049a6:	e052                	sd	s4,0(sp)
    800049a8:	1800                	addi	s0,sp,48
    800049aa:	84aa                	mv	s1,a0
    800049ac:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049ae:	0005b023          	sd	zero,0(a1)
    800049b2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049b6:	00000097          	auipc	ra,0x0
    800049ba:	bf8080e7          	jalr	-1032(ra) # 800045ae <filealloc>
    800049be:	e088                	sd	a0,0(s1)
    800049c0:	c551                	beqz	a0,80004a4c <pipealloc+0xb2>
    800049c2:	00000097          	auipc	ra,0x0
    800049c6:	bec080e7          	jalr	-1044(ra) # 800045ae <filealloc>
    800049ca:	00aa3023          	sd	a0,0(s4)
    800049ce:	c92d                	beqz	a0,80004a40 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	124080e7          	jalr	292(ra) # 80000af4 <kalloc>
    800049d8:	892a                	mv	s2,a0
    800049da:	c125                	beqz	a0,80004a3a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049dc:	4985                	li	s3,1
    800049de:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049e2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049e6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049ea:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049ee:	00004597          	auipc	a1,0x4
    800049f2:	d1258593          	addi	a1,a1,-750 # 80008700 <syscalls+0x288>
    800049f6:	ffffc097          	auipc	ra,0xffffc
    800049fa:	15e080e7          	jalr	350(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800049fe:	609c                	ld	a5,0(s1)
    80004a00:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a04:	609c                	ld	a5,0(s1)
    80004a06:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a0a:	609c                	ld	a5,0(s1)
    80004a0c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a10:	609c                	ld	a5,0(s1)
    80004a12:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a16:	000a3783          	ld	a5,0(s4)
    80004a1a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a1e:	000a3783          	ld	a5,0(s4)
    80004a22:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a26:	000a3783          	ld	a5,0(s4)
    80004a2a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a2e:	000a3783          	ld	a5,0(s4)
    80004a32:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a36:	4501                	li	a0,0
    80004a38:	a025                	j	80004a60 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a3a:	6088                	ld	a0,0(s1)
    80004a3c:	e501                	bnez	a0,80004a44 <pipealloc+0xaa>
    80004a3e:	a039                	j	80004a4c <pipealloc+0xb2>
    80004a40:	6088                	ld	a0,0(s1)
    80004a42:	c51d                	beqz	a0,80004a70 <pipealloc+0xd6>
    fileclose(*f0);
    80004a44:	00000097          	auipc	ra,0x0
    80004a48:	c26080e7          	jalr	-986(ra) # 8000466a <fileclose>
  if(*f1)
    80004a4c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a50:	557d                	li	a0,-1
  if(*f1)
    80004a52:	c799                	beqz	a5,80004a60 <pipealloc+0xc6>
    fileclose(*f1);
    80004a54:	853e                	mv	a0,a5
    80004a56:	00000097          	auipc	ra,0x0
    80004a5a:	c14080e7          	jalr	-1004(ra) # 8000466a <fileclose>
  return -1;
    80004a5e:	557d                	li	a0,-1
}
    80004a60:	70a2                	ld	ra,40(sp)
    80004a62:	7402                	ld	s0,32(sp)
    80004a64:	64e2                	ld	s1,24(sp)
    80004a66:	6942                	ld	s2,16(sp)
    80004a68:	69a2                	ld	s3,8(sp)
    80004a6a:	6a02                	ld	s4,0(sp)
    80004a6c:	6145                	addi	sp,sp,48
    80004a6e:	8082                	ret
  return -1;
    80004a70:	557d                	li	a0,-1
    80004a72:	b7fd                	j	80004a60 <pipealloc+0xc6>

0000000080004a74 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a74:	1101                	addi	sp,sp,-32
    80004a76:	ec06                	sd	ra,24(sp)
    80004a78:	e822                	sd	s0,16(sp)
    80004a7a:	e426                	sd	s1,8(sp)
    80004a7c:	e04a                	sd	s2,0(sp)
    80004a7e:	1000                	addi	s0,sp,32
    80004a80:	84aa                	mv	s1,a0
    80004a82:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	160080e7          	jalr	352(ra) # 80000be4 <acquire>
  if(writable){
    80004a8c:	02090d63          	beqz	s2,80004ac6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a90:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a94:	21848513          	addi	a0,s1,536
    80004a98:	ffffe097          	auipc	ra,0xffffe
    80004a9c:	866080e7          	jalr	-1946(ra) # 800022fe <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004aa0:	2204b783          	ld	a5,544(s1)
    80004aa4:	eb95                	bnez	a5,80004ad8 <pipeclose+0x64>
    release(&pi->lock);
    80004aa6:	8526                	mv	a0,s1
    80004aa8:	ffffc097          	auipc	ra,0xffffc
    80004aac:	1f0080e7          	jalr	496(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004ab0:	8526                	mv	a0,s1
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	f46080e7          	jalr	-186(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004aba:	60e2                	ld	ra,24(sp)
    80004abc:	6442                	ld	s0,16(sp)
    80004abe:	64a2                	ld	s1,8(sp)
    80004ac0:	6902                	ld	s2,0(sp)
    80004ac2:	6105                	addi	sp,sp,32
    80004ac4:	8082                	ret
    pi->readopen = 0;
    80004ac6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004aca:	21c48513          	addi	a0,s1,540
    80004ace:	ffffe097          	auipc	ra,0xffffe
    80004ad2:	830080e7          	jalr	-2000(ra) # 800022fe <wakeup>
    80004ad6:	b7e9                	j	80004aa0 <pipeclose+0x2c>
    release(&pi->lock);
    80004ad8:	8526                	mv	a0,s1
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	1be080e7          	jalr	446(ra) # 80000c98 <release>
}
    80004ae2:	bfe1                	j	80004aba <pipeclose+0x46>

0000000080004ae4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ae4:	7159                	addi	sp,sp,-112
    80004ae6:	f486                	sd	ra,104(sp)
    80004ae8:	f0a2                	sd	s0,96(sp)
    80004aea:	eca6                	sd	s1,88(sp)
    80004aec:	e8ca                	sd	s2,80(sp)
    80004aee:	e4ce                	sd	s3,72(sp)
    80004af0:	e0d2                	sd	s4,64(sp)
    80004af2:	fc56                	sd	s5,56(sp)
    80004af4:	f85a                	sd	s6,48(sp)
    80004af6:	f45e                	sd	s7,40(sp)
    80004af8:	f062                	sd	s8,32(sp)
    80004afa:	ec66                	sd	s9,24(sp)
    80004afc:	1880                	addi	s0,sp,112
    80004afe:	84aa                	mv	s1,a0
    80004b00:	8aae                	mv	s5,a1
    80004b02:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b04:	ffffd097          	auipc	ra,0xffffd
    80004b08:	eac080e7          	jalr	-340(ra) # 800019b0 <myproc>
    80004b0c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b0e:	8526                	mv	a0,s1
    80004b10:	ffffc097          	auipc	ra,0xffffc
    80004b14:	0d4080e7          	jalr	212(ra) # 80000be4 <acquire>
  while(i < n){
    80004b18:	0d405163          	blez	s4,80004bda <pipewrite+0xf6>
    80004b1c:	8ba6                	mv	s7,s1
  int i = 0;
    80004b1e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b20:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b22:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b26:	21c48c13          	addi	s8,s1,540
    80004b2a:	a08d                	j	80004b8c <pipewrite+0xa8>
      release(&pi->lock);
    80004b2c:	8526                	mv	a0,s1
    80004b2e:	ffffc097          	auipc	ra,0xffffc
    80004b32:	16a080e7          	jalr	362(ra) # 80000c98 <release>
      return -1;
    80004b36:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b38:	854a                	mv	a0,s2
    80004b3a:	70a6                	ld	ra,104(sp)
    80004b3c:	7406                	ld	s0,96(sp)
    80004b3e:	64e6                	ld	s1,88(sp)
    80004b40:	6946                	ld	s2,80(sp)
    80004b42:	69a6                	ld	s3,72(sp)
    80004b44:	6a06                	ld	s4,64(sp)
    80004b46:	7ae2                	ld	s5,56(sp)
    80004b48:	7b42                	ld	s6,48(sp)
    80004b4a:	7ba2                	ld	s7,40(sp)
    80004b4c:	7c02                	ld	s8,32(sp)
    80004b4e:	6ce2                	ld	s9,24(sp)
    80004b50:	6165                	addi	sp,sp,112
    80004b52:	8082                	ret
      wakeup(&pi->nread);
    80004b54:	8566                	mv	a0,s9
    80004b56:	ffffd097          	auipc	ra,0xffffd
    80004b5a:	7a8080e7          	jalr	1960(ra) # 800022fe <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b5e:	85de                	mv	a1,s7
    80004b60:	8562                	mv	a0,s8
    80004b62:	ffffd097          	auipc	ra,0xffffd
    80004b66:	610080e7          	jalr	1552(ra) # 80002172 <sleep>
    80004b6a:	a839                	j	80004b88 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b6c:	21c4a783          	lw	a5,540(s1)
    80004b70:	0017871b          	addiw	a4,a5,1
    80004b74:	20e4ae23          	sw	a4,540(s1)
    80004b78:	1ff7f793          	andi	a5,a5,511
    80004b7c:	97a6                	add	a5,a5,s1
    80004b7e:	f9f44703          	lbu	a4,-97(s0)
    80004b82:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b86:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b88:	03495d63          	bge	s2,s4,80004bc2 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004b8c:	2204a783          	lw	a5,544(s1)
    80004b90:	dfd1                	beqz	a5,80004b2c <pipewrite+0x48>
    80004b92:	0289a783          	lw	a5,40(s3)
    80004b96:	fbd9                	bnez	a5,80004b2c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b98:	2184a783          	lw	a5,536(s1)
    80004b9c:	21c4a703          	lw	a4,540(s1)
    80004ba0:	2007879b          	addiw	a5,a5,512
    80004ba4:	faf708e3          	beq	a4,a5,80004b54 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ba8:	4685                	li	a3,1
    80004baa:	01590633          	add	a2,s2,s5
    80004bae:	f9f40593          	addi	a1,s0,-97
    80004bb2:	0509b503          	ld	a0,80(s3)
    80004bb6:	ffffd097          	auipc	ra,0xffffd
    80004bba:	b48080e7          	jalr	-1208(ra) # 800016fe <copyin>
    80004bbe:	fb6517e3          	bne	a0,s6,80004b6c <pipewrite+0x88>
  wakeup(&pi->nread);
    80004bc2:	21848513          	addi	a0,s1,536
    80004bc6:	ffffd097          	auipc	ra,0xffffd
    80004bca:	738080e7          	jalr	1848(ra) # 800022fe <wakeup>
  release(&pi->lock);
    80004bce:	8526                	mv	a0,s1
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	0c8080e7          	jalr	200(ra) # 80000c98 <release>
  return i;
    80004bd8:	b785                	j	80004b38 <pipewrite+0x54>
  int i = 0;
    80004bda:	4901                	li	s2,0
    80004bdc:	b7dd                	j	80004bc2 <pipewrite+0xde>

0000000080004bde <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bde:	715d                	addi	sp,sp,-80
    80004be0:	e486                	sd	ra,72(sp)
    80004be2:	e0a2                	sd	s0,64(sp)
    80004be4:	fc26                	sd	s1,56(sp)
    80004be6:	f84a                	sd	s2,48(sp)
    80004be8:	f44e                	sd	s3,40(sp)
    80004bea:	f052                	sd	s4,32(sp)
    80004bec:	ec56                	sd	s5,24(sp)
    80004bee:	e85a                	sd	s6,16(sp)
    80004bf0:	0880                	addi	s0,sp,80
    80004bf2:	84aa                	mv	s1,a0
    80004bf4:	892e                	mv	s2,a1
    80004bf6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bf8:	ffffd097          	auipc	ra,0xffffd
    80004bfc:	db8080e7          	jalr	-584(ra) # 800019b0 <myproc>
    80004c00:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c02:	8b26                	mv	s6,s1
    80004c04:	8526                	mv	a0,s1
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	fde080e7          	jalr	-34(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c0e:	2184a703          	lw	a4,536(s1)
    80004c12:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c16:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c1a:	02f71463          	bne	a4,a5,80004c42 <piperead+0x64>
    80004c1e:	2244a783          	lw	a5,548(s1)
    80004c22:	c385                	beqz	a5,80004c42 <piperead+0x64>
    if(pr->killed){
    80004c24:	028a2783          	lw	a5,40(s4)
    80004c28:	ebc1                	bnez	a5,80004cb8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c2a:	85da                	mv	a1,s6
    80004c2c:	854e                	mv	a0,s3
    80004c2e:	ffffd097          	auipc	ra,0xffffd
    80004c32:	544080e7          	jalr	1348(ra) # 80002172 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c36:	2184a703          	lw	a4,536(s1)
    80004c3a:	21c4a783          	lw	a5,540(s1)
    80004c3e:	fef700e3          	beq	a4,a5,80004c1e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c42:	09505263          	blez	s5,80004cc6 <piperead+0xe8>
    80004c46:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c48:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c4a:	2184a783          	lw	a5,536(s1)
    80004c4e:	21c4a703          	lw	a4,540(s1)
    80004c52:	02f70d63          	beq	a4,a5,80004c8c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c56:	0017871b          	addiw	a4,a5,1
    80004c5a:	20e4ac23          	sw	a4,536(s1)
    80004c5e:	1ff7f793          	andi	a5,a5,511
    80004c62:	97a6                	add	a5,a5,s1
    80004c64:	0187c783          	lbu	a5,24(a5)
    80004c68:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c6c:	4685                	li	a3,1
    80004c6e:	fbf40613          	addi	a2,s0,-65
    80004c72:	85ca                	mv	a1,s2
    80004c74:	050a3503          	ld	a0,80(s4)
    80004c78:	ffffd097          	auipc	ra,0xffffd
    80004c7c:	9fa080e7          	jalr	-1542(ra) # 80001672 <copyout>
    80004c80:	01650663          	beq	a0,s6,80004c8c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c84:	2985                	addiw	s3,s3,1
    80004c86:	0905                	addi	s2,s2,1
    80004c88:	fd3a91e3          	bne	s5,s3,80004c4a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c8c:	21c48513          	addi	a0,s1,540
    80004c90:	ffffd097          	auipc	ra,0xffffd
    80004c94:	66e080e7          	jalr	1646(ra) # 800022fe <wakeup>
  release(&pi->lock);
    80004c98:	8526                	mv	a0,s1
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	ffe080e7          	jalr	-2(ra) # 80000c98 <release>
  return i;
}
    80004ca2:	854e                	mv	a0,s3
    80004ca4:	60a6                	ld	ra,72(sp)
    80004ca6:	6406                	ld	s0,64(sp)
    80004ca8:	74e2                	ld	s1,56(sp)
    80004caa:	7942                	ld	s2,48(sp)
    80004cac:	79a2                	ld	s3,40(sp)
    80004cae:	7a02                	ld	s4,32(sp)
    80004cb0:	6ae2                	ld	s5,24(sp)
    80004cb2:	6b42                	ld	s6,16(sp)
    80004cb4:	6161                	addi	sp,sp,80
    80004cb6:	8082                	ret
      release(&pi->lock);
    80004cb8:	8526                	mv	a0,s1
    80004cba:	ffffc097          	auipc	ra,0xffffc
    80004cbe:	fde080e7          	jalr	-34(ra) # 80000c98 <release>
      return -1;
    80004cc2:	59fd                	li	s3,-1
    80004cc4:	bff9                	j	80004ca2 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cc6:	4981                	li	s3,0
    80004cc8:	b7d1                	j	80004c8c <piperead+0xae>

0000000080004cca <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cca:	df010113          	addi	sp,sp,-528
    80004cce:	20113423          	sd	ra,520(sp)
    80004cd2:	20813023          	sd	s0,512(sp)
    80004cd6:	ffa6                	sd	s1,504(sp)
    80004cd8:	fbca                	sd	s2,496(sp)
    80004cda:	f7ce                	sd	s3,488(sp)
    80004cdc:	f3d2                	sd	s4,480(sp)
    80004cde:	efd6                	sd	s5,472(sp)
    80004ce0:	ebda                	sd	s6,464(sp)
    80004ce2:	e7de                	sd	s7,456(sp)
    80004ce4:	e3e2                	sd	s8,448(sp)
    80004ce6:	ff66                	sd	s9,440(sp)
    80004ce8:	fb6a                	sd	s10,432(sp)
    80004cea:	f76e                	sd	s11,424(sp)
    80004cec:	0c00                	addi	s0,sp,528
    80004cee:	84aa                	mv	s1,a0
    80004cf0:	dea43c23          	sd	a0,-520(s0)
    80004cf4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cf8:	ffffd097          	auipc	ra,0xffffd
    80004cfc:	cb8080e7          	jalr	-840(ra) # 800019b0 <myproc>
    80004d00:	892a                	mv	s2,a0

  begin_op();
    80004d02:	fffff097          	auipc	ra,0xfffff
    80004d06:	49c080e7          	jalr	1180(ra) # 8000419e <begin_op>

  if((ip = namei(path)) == 0){
    80004d0a:	8526                	mv	a0,s1
    80004d0c:	fffff097          	auipc	ra,0xfffff
    80004d10:	276080e7          	jalr	630(ra) # 80003f82 <namei>
    80004d14:	c92d                	beqz	a0,80004d86 <exec+0xbc>
    80004d16:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	ab4080e7          	jalr	-1356(ra) # 800037cc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d20:	04000713          	li	a4,64
    80004d24:	4681                	li	a3,0
    80004d26:	e5040613          	addi	a2,s0,-432
    80004d2a:	4581                	li	a1,0
    80004d2c:	8526                	mv	a0,s1
    80004d2e:	fffff097          	auipc	ra,0xfffff
    80004d32:	d52080e7          	jalr	-686(ra) # 80003a80 <readi>
    80004d36:	04000793          	li	a5,64
    80004d3a:	00f51a63          	bne	a0,a5,80004d4e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d3e:	e5042703          	lw	a4,-432(s0)
    80004d42:	464c47b7          	lui	a5,0x464c4
    80004d46:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d4a:	04f70463          	beq	a4,a5,80004d92 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d4e:	8526                	mv	a0,s1
    80004d50:	fffff097          	auipc	ra,0xfffff
    80004d54:	cde080e7          	jalr	-802(ra) # 80003a2e <iunlockput>
    end_op();
    80004d58:	fffff097          	auipc	ra,0xfffff
    80004d5c:	4c6080e7          	jalr	1222(ra) # 8000421e <end_op>
  }
  return -1;
    80004d60:	557d                	li	a0,-1
}
    80004d62:	20813083          	ld	ra,520(sp)
    80004d66:	20013403          	ld	s0,512(sp)
    80004d6a:	74fe                	ld	s1,504(sp)
    80004d6c:	795e                	ld	s2,496(sp)
    80004d6e:	79be                	ld	s3,488(sp)
    80004d70:	7a1e                	ld	s4,480(sp)
    80004d72:	6afe                	ld	s5,472(sp)
    80004d74:	6b5e                	ld	s6,464(sp)
    80004d76:	6bbe                	ld	s7,456(sp)
    80004d78:	6c1e                	ld	s8,448(sp)
    80004d7a:	7cfa                	ld	s9,440(sp)
    80004d7c:	7d5a                	ld	s10,432(sp)
    80004d7e:	7dba                	ld	s11,424(sp)
    80004d80:	21010113          	addi	sp,sp,528
    80004d84:	8082                	ret
    end_op();
    80004d86:	fffff097          	auipc	ra,0xfffff
    80004d8a:	498080e7          	jalr	1176(ra) # 8000421e <end_op>
    return -1;
    80004d8e:	557d                	li	a0,-1
    80004d90:	bfc9                	j	80004d62 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d92:	854a                	mv	a0,s2
    80004d94:	ffffd097          	auipc	ra,0xffffd
    80004d98:	ce0080e7          	jalr	-800(ra) # 80001a74 <proc_pagetable>
    80004d9c:	8baa                	mv	s7,a0
    80004d9e:	d945                	beqz	a0,80004d4e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004da0:	e7042983          	lw	s3,-400(s0)
    80004da4:	e8845783          	lhu	a5,-376(s0)
    80004da8:	c7ad                	beqz	a5,80004e12 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004daa:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dac:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004dae:	6c85                	lui	s9,0x1
    80004db0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004db4:	def43823          	sd	a5,-528(s0)
    80004db8:	a42d                	j	80004fe2 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dba:	00004517          	auipc	a0,0x4
    80004dbe:	94e50513          	addi	a0,a0,-1714 # 80008708 <syscalls+0x290>
    80004dc2:	ffffb097          	auipc	ra,0xffffb
    80004dc6:	77c080e7          	jalr	1916(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dca:	8756                	mv	a4,s5
    80004dcc:	012d86bb          	addw	a3,s11,s2
    80004dd0:	4581                	li	a1,0
    80004dd2:	8526                	mv	a0,s1
    80004dd4:	fffff097          	auipc	ra,0xfffff
    80004dd8:	cac080e7          	jalr	-852(ra) # 80003a80 <readi>
    80004ddc:	2501                	sext.w	a0,a0
    80004dde:	1aaa9963          	bne	s5,a0,80004f90 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004de2:	6785                	lui	a5,0x1
    80004de4:	0127893b          	addw	s2,a5,s2
    80004de8:	77fd                	lui	a5,0xfffff
    80004dea:	01478a3b          	addw	s4,a5,s4
    80004dee:	1f897163          	bgeu	s2,s8,80004fd0 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004df2:	02091593          	slli	a1,s2,0x20
    80004df6:	9181                	srli	a1,a1,0x20
    80004df8:	95ea                	add	a1,a1,s10
    80004dfa:	855e                	mv	a0,s7
    80004dfc:	ffffc097          	auipc	ra,0xffffc
    80004e00:	272080e7          	jalr	626(ra) # 8000106e <walkaddr>
    80004e04:	862a                	mv	a2,a0
    if(pa == 0)
    80004e06:	d955                	beqz	a0,80004dba <exec+0xf0>
      n = PGSIZE;
    80004e08:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e0a:	fd9a70e3          	bgeu	s4,s9,80004dca <exec+0x100>
      n = sz - i;
    80004e0e:	8ad2                	mv	s5,s4
    80004e10:	bf6d                	j	80004dca <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e12:	4901                	li	s2,0
  iunlockput(ip);
    80004e14:	8526                	mv	a0,s1
    80004e16:	fffff097          	auipc	ra,0xfffff
    80004e1a:	c18080e7          	jalr	-1000(ra) # 80003a2e <iunlockput>
  end_op();
    80004e1e:	fffff097          	auipc	ra,0xfffff
    80004e22:	400080e7          	jalr	1024(ra) # 8000421e <end_op>
  p = myproc();
    80004e26:	ffffd097          	auipc	ra,0xffffd
    80004e2a:	b8a080e7          	jalr	-1142(ra) # 800019b0 <myproc>
    80004e2e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e30:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e34:	6785                	lui	a5,0x1
    80004e36:	17fd                	addi	a5,a5,-1
    80004e38:	993e                	add	s2,s2,a5
    80004e3a:	757d                	lui	a0,0xfffff
    80004e3c:	00a977b3          	and	a5,s2,a0
    80004e40:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e44:	6609                	lui	a2,0x2
    80004e46:	963e                	add	a2,a2,a5
    80004e48:	85be                	mv	a1,a5
    80004e4a:	855e                	mv	a0,s7
    80004e4c:	ffffc097          	auipc	ra,0xffffc
    80004e50:	5d6080e7          	jalr	1494(ra) # 80001422 <uvmalloc>
    80004e54:	8b2a                	mv	s6,a0
  ip = 0;
    80004e56:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e58:	12050c63          	beqz	a0,80004f90 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e5c:	75f9                	lui	a1,0xffffe
    80004e5e:	95aa                	add	a1,a1,a0
    80004e60:	855e                	mv	a0,s7
    80004e62:	ffffc097          	auipc	ra,0xffffc
    80004e66:	7de080e7          	jalr	2014(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e6a:	7c7d                	lui	s8,0xfffff
    80004e6c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e6e:	e0043783          	ld	a5,-512(s0)
    80004e72:	6388                	ld	a0,0(a5)
    80004e74:	c535                	beqz	a0,80004ee0 <exec+0x216>
    80004e76:	e9040993          	addi	s3,s0,-368
    80004e7a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e7e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e80:	ffffc097          	auipc	ra,0xffffc
    80004e84:	fe4080e7          	jalr	-28(ra) # 80000e64 <strlen>
    80004e88:	2505                	addiw	a0,a0,1
    80004e8a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e8e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e92:	13896363          	bltu	s2,s8,80004fb8 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e96:	e0043d83          	ld	s11,-512(s0)
    80004e9a:	000dba03          	ld	s4,0(s11)
    80004e9e:	8552                	mv	a0,s4
    80004ea0:	ffffc097          	auipc	ra,0xffffc
    80004ea4:	fc4080e7          	jalr	-60(ra) # 80000e64 <strlen>
    80004ea8:	0015069b          	addiw	a3,a0,1
    80004eac:	8652                	mv	a2,s4
    80004eae:	85ca                	mv	a1,s2
    80004eb0:	855e                	mv	a0,s7
    80004eb2:	ffffc097          	auipc	ra,0xffffc
    80004eb6:	7c0080e7          	jalr	1984(ra) # 80001672 <copyout>
    80004eba:	10054363          	bltz	a0,80004fc0 <exec+0x2f6>
    ustack[argc] = sp;
    80004ebe:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ec2:	0485                	addi	s1,s1,1
    80004ec4:	008d8793          	addi	a5,s11,8
    80004ec8:	e0f43023          	sd	a5,-512(s0)
    80004ecc:	008db503          	ld	a0,8(s11)
    80004ed0:	c911                	beqz	a0,80004ee4 <exec+0x21a>
    if(argc >= MAXARG)
    80004ed2:	09a1                	addi	s3,s3,8
    80004ed4:	fb3c96e3          	bne	s9,s3,80004e80 <exec+0x1b6>
  sz = sz1;
    80004ed8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004edc:	4481                	li	s1,0
    80004ede:	a84d                	j	80004f90 <exec+0x2c6>
  sp = sz;
    80004ee0:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ee2:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ee4:	00349793          	slli	a5,s1,0x3
    80004ee8:	f9040713          	addi	a4,s0,-112
    80004eec:	97ba                	add	a5,a5,a4
    80004eee:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004ef2:	00148693          	addi	a3,s1,1
    80004ef6:	068e                	slli	a3,a3,0x3
    80004ef8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004efc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f00:	01897663          	bgeu	s2,s8,80004f0c <exec+0x242>
  sz = sz1;
    80004f04:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f08:	4481                	li	s1,0
    80004f0a:	a059                	j	80004f90 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f0c:	e9040613          	addi	a2,s0,-368
    80004f10:	85ca                	mv	a1,s2
    80004f12:	855e                	mv	a0,s7
    80004f14:	ffffc097          	auipc	ra,0xffffc
    80004f18:	75e080e7          	jalr	1886(ra) # 80001672 <copyout>
    80004f1c:	0a054663          	bltz	a0,80004fc8 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f20:	058ab783          	ld	a5,88(s5)
    80004f24:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f28:	df843783          	ld	a5,-520(s0)
    80004f2c:	0007c703          	lbu	a4,0(a5)
    80004f30:	cf11                	beqz	a4,80004f4c <exec+0x282>
    80004f32:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f34:	02f00693          	li	a3,47
    80004f38:	a039                	j	80004f46 <exec+0x27c>
      last = s+1;
    80004f3a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f3e:	0785                	addi	a5,a5,1
    80004f40:	fff7c703          	lbu	a4,-1(a5)
    80004f44:	c701                	beqz	a4,80004f4c <exec+0x282>
    if(*s == '/')
    80004f46:	fed71ce3          	bne	a4,a3,80004f3e <exec+0x274>
    80004f4a:	bfc5                	j	80004f3a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f4c:	4641                	li	a2,16
    80004f4e:	df843583          	ld	a1,-520(s0)
    80004f52:	158a8513          	addi	a0,s5,344
    80004f56:	ffffc097          	auipc	ra,0xffffc
    80004f5a:	edc080e7          	jalr	-292(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f5e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f62:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f66:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f6a:	058ab783          	ld	a5,88(s5)
    80004f6e:	e6843703          	ld	a4,-408(s0)
    80004f72:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f74:	058ab783          	ld	a5,88(s5)
    80004f78:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f7c:	85ea                	mv	a1,s10
    80004f7e:	ffffd097          	auipc	ra,0xffffd
    80004f82:	b92080e7          	jalr	-1134(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f86:	0004851b          	sext.w	a0,s1
    80004f8a:	bbe1                	j	80004d62 <exec+0x98>
    80004f8c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f90:	e0843583          	ld	a1,-504(s0)
    80004f94:	855e                	mv	a0,s7
    80004f96:	ffffd097          	auipc	ra,0xffffd
    80004f9a:	b7a080e7          	jalr	-1158(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80004f9e:	da0498e3          	bnez	s1,80004d4e <exec+0x84>
  return -1;
    80004fa2:	557d                	li	a0,-1
    80004fa4:	bb7d                	j	80004d62 <exec+0x98>
    80004fa6:	e1243423          	sd	s2,-504(s0)
    80004faa:	b7dd                	j	80004f90 <exec+0x2c6>
    80004fac:	e1243423          	sd	s2,-504(s0)
    80004fb0:	b7c5                	j	80004f90 <exec+0x2c6>
    80004fb2:	e1243423          	sd	s2,-504(s0)
    80004fb6:	bfe9                	j	80004f90 <exec+0x2c6>
  sz = sz1;
    80004fb8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fbc:	4481                	li	s1,0
    80004fbe:	bfc9                	j	80004f90 <exec+0x2c6>
  sz = sz1;
    80004fc0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc4:	4481                	li	s1,0
    80004fc6:	b7e9                	j	80004f90 <exec+0x2c6>
  sz = sz1;
    80004fc8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fcc:	4481                	li	s1,0
    80004fce:	b7c9                	j	80004f90 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fd0:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fd4:	2b05                	addiw	s6,s6,1
    80004fd6:	0389899b          	addiw	s3,s3,56
    80004fda:	e8845783          	lhu	a5,-376(s0)
    80004fde:	e2fb5be3          	bge	s6,a5,80004e14 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fe2:	2981                	sext.w	s3,s3
    80004fe4:	03800713          	li	a4,56
    80004fe8:	86ce                	mv	a3,s3
    80004fea:	e1840613          	addi	a2,s0,-488
    80004fee:	4581                	li	a1,0
    80004ff0:	8526                	mv	a0,s1
    80004ff2:	fffff097          	auipc	ra,0xfffff
    80004ff6:	a8e080e7          	jalr	-1394(ra) # 80003a80 <readi>
    80004ffa:	03800793          	li	a5,56
    80004ffe:	f8f517e3          	bne	a0,a5,80004f8c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005002:	e1842783          	lw	a5,-488(s0)
    80005006:	4705                	li	a4,1
    80005008:	fce796e3          	bne	a5,a4,80004fd4 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000500c:	e4043603          	ld	a2,-448(s0)
    80005010:	e3843783          	ld	a5,-456(s0)
    80005014:	f8f669e3          	bltu	a2,a5,80004fa6 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005018:	e2843783          	ld	a5,-472(s0)
    8000501c:	963e                	add	a2,a2,a5
    8000501e:	f8f667e3          	bltu	a2,a5,80004fac <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005022:	85ca                	mv	a1,s2
    80005024:	855e                	mv	a0,s7
    80005026:	ffffc097          	auipc	ra,0xffffc
    8000502a:	3fc080e7          	jalr	1020(ra) # 80001422 <uvmalloc>
    8000502e:	e0a43423          	sd	a0,-504(s0)
    80005032:	d141                	beqz	a0,80004fb2 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005034:	e2843d03          	ld	s10,-472(s0)
    80005038:	df043783          	ld	a5,-528(s0)
    8000503c:	00fd77b3          	and	a5,s10,a5
    80005040:	fba1                	bnez	a5,80004f90 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005042:	e2042d83          	lw	s11,-480(s0)
    80005046:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000504a:	f80c03e3          	beqz	s8,80004fd0 <exec+0x306>
    8000504e:	8a62                	mv	s4,s8
    80005050:	4901                	li	s2,0
    80005052:	b345                	j	80004df2 <exec+0x128>

0000000080005054 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005054:	7179                	addi	sp,sp,-48
    80005056:	f406                	sd	ra,40(sp)
    80005058:	f022                	sd	s0,32(sp)
    8000505a:	ec26                	sd	s1,24(sp)
    8000505c:	e84a                	sd	s2,16(sp)
    8000505e:	1800                	addi	s0,sp,48
    80005060:	892e                	mv	s2,a1
    80005062:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005064:	fdc40593          	addi	a1,s0,-36
    80005068:	ffffe097          	auipc	ra,0xffffe
    8000506c:	bac080e7          	jalr	-1108(ra) # 80002c14 <argint>
    80005070:	04054063          	bltz	a0,800050b0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005074:	fdc42703          	lw	a4,-36(s0)
    80005078:	47bd                	li	a5,15
    8000507a:	02e7ed63          	bltu	a5,a4,800050b4 <argfd+0x60>
    8000507e:	ffffd097          	auipc	ra,0xffffd
    80005082:	932080e7          	jalr	-1742(ra) # 800019b0 <myproc>
    80005086:	fdc42703          	lw	a4,-36(s0)
    8000508a:	01a70793          	addi	a5,a4,26
    8000508e:	078e                	slli	a5,a5,0x3
    80005090:	953e                	add	a0,a0,a5
    80005092:	611c                	ld	a5,0(a0)
    80005094:	c395                	beqz	a5,800050b8 <argfd+0x64>
    return -1;
  if(pfd)
    80005096:	00090463          	beqz	s2,8000509e <argfd+0x4a>
    *pfd = fd;
    8000509a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000509e:	4501                	li	a0,0
  if(pf)
    800050a0:	c091                	beqz	s1,800050a4 <argfd+0x50>
    *pf = f;
    800050a2:	e09c                	sd	a5,0(s1)
}
    800050a4:	70a2                	ld	ra,40(sp)
    800050a6:	7402                	ld	s0,32(sp)
    800050a8:	64e2                	ld	s1,24(sp)
    800050aa:	6942                	ld	s2,16(sp)
    800050ac:	6145                	addi	sp,sp,48
    800050ae:	8082                	ret
    return -1;
    800050b0:	557d                	li	a0,-1
    800050b2:	bfcd                	j	800050a4 <argfd+0x50>
    return -1;
    800050b4:	557d                	li	a0,-1
    800050b6:	b7fd                	j	800050a4 <argfd+0x50>
    800050b8:	557d                	li	a0,-1
    800050ba:	b7ed                	j	800050a4 <argfd+0x50>

00000000800050bc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050bc:	1101                	addi	sp,sp,-32
    800050be:	ec06                	sd	ra,24(sp)
    800050c0:	e822                	sd	s0,16(sp)
    800050c2:	e426                	sd	s1,8(sp)
    800050c4:	1000                	addi	s0,sp,32
    800050c6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050c8:	ffffd097          	auipc	ra,0xffffd
    800050cc:	8e8080e7          	jalr	-1816(ra) # 800019b0 <myproc>
    800050d0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050d2:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800050d6:	4501                	li	a0,0
    800050d8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050da:	6398                	ld	a4,0(a5)
    800050dc:	cb19                	beqz	a4,800050f2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050de:	2505                	addiw	a0,a0,1
    800050e0:	07a1                	addi	a5,a5,8
    800050e2:	fed51ce3          	bne	a0,a3,800050da <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050e6:	557d                	li	a0,-1
}
    800050e8:	60e2                	ld	ra,24(sp)
    800050ea:	6442                	ld	s0,16(sp)
    800050ec:	64a2                	ld	s1,8(sp)
    800050ee:	6105                	addi	sp,sp,32
    800050f0:	8082                	ret
      p->ofile[fd] = f;
    800050f2:	01a50793          	addi	a5,a0,26
    800050f6:	078e                	slli	a5,a5,0x3
    800050f8:	963e                	add	a2,a2,a5
    800050fa:	e204                	sd	s1,0(a2)
      return fd;
    800050fc:	b7f5                	j	800050e8 <fdalloc+0x2c>

00000000800050fe <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050fe:	715d                	addi	sp,sp,-80
    80005100:	e486                	sd	ra,72(sp)
    80005102:	e0a2                	sd	s0,64(sp)
    80005104:	fc26                	sd	s1,56(sp)
    80005106:	f84a                	sd	s2,48(sp)
    80005108:	f44e                	sd	s3,40(sp)
    8000510a:	f052                	sd	s4,32(sp)
    8000510c:	ec56                	sd	s5,24(sp)
    8000510e:	0880                	addi	s0,sp,80
    80005110:	89ae                	mv	s3,a1
    80005112:	8ab2                	mv	s5,a2
    80005114:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005116:	fb040593          	addi	a1,s0,-80
    8000511a:	fffff097          	auipc	ra,0xfffff
    8000511e:	e86080e7          	jalr	-378(ra) # 80003fa0 <nameiparent>
    80005122:	892a                	mv	s2,a0
    80005124:	12050f63          	beqz	a0,80005262 <create+0x164>
    return 0;

  ilock(dp);
    80005128:	ffffe097          	auipc	ra,0xffffe
    8000512c:	6a4080e7          	jalr	1700(ra) # 800037cc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005130:	4601                	li	a2,0
    80005132:	fb040593          	addi	a1,s0,-80
    80005136:	854a                	mv	a0,s2
    80005138:	fffff097          	auipc	ra,0xfffff
    8000513c:	b78080e7          	jalr	-1160(ra) # 80003cb0 <dirlookup>
    80005140:	84aa                	mv	s1,a0
    80005142:	c921                	beqz	a0,80005192 <create+0x94>
    iunlockput(dp);
    80005144:	854a                	mv	a0,s2
    80005146:	fffff097          	auipc	ra,0xfffff
    8000514a:	8e8080e7          	jalr	-1816(ra) # 80003a2e <iunlockput>
    ilock(ip);
    8000514e:	8526                	mv	a0,s1
    80005150:	ffffe097          	auipc	ra,0xffffe
    80005154:	67c080e7          	jalr	1660(ra) # 800037cc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005158:	2981                	sext.w	s3,s3
    8000515a:	4789                	li	a5,2
    8000515c:	02f99463          	bne	s3,a5,80005184 <create+0x86>
    80005160:	0444d783          	lhu	a5,68(s1)
    80005164:	37f9                	addiw	a5,a5,-2
    80005166:	17c2                	slli	a5,a5,0x30
    80005168:	93c1                	srli	a5,a5,0x30
    8000516a:	4705                	li	a4,1
    8000516c:	00f76c63          	bltu	a4,a5,80005184 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005170:	8526                	mv	a0,s1
    80005172:	60a6                	ld	ra,72(sp)
    80005174:	6406                	ld	s0,64(sp)
    80005176:	74e2                	ld	s1,56(sp)
    80005178:	7942                	ld	s2,48(sp)
    8000517a:	79a2                	ld	s3,40(sp)
    8000517c:	7a02                	ld	s4,32(sp)
    8000517e:	6ae2                	ld	s5,24(sp)
    80005180:	6161                	addi	sp,sp,80
    80005182:	8082                	ret
    iunlockput(ip);
    80005184:	8526                	mv	a0,s1
    80005186:	fffff097          	auipc	ra,0xfffff
    8000518a:	8a8080e7          	jalr	-1880(ra) # 80003a2e <iunlockput>
    return 0;
    8000518e:	4481                	li	s1,0
    80005190:	b7c5                	j	80005170 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005192:	85ce                	mv	a1,s3
    80005194:	00092503          	lw	a0,0(s2)
    80005198:	ffffe097          	auipc	ra,0xffffe
    8000519c:	49c080e7          	jalr	1180(ra) # 80003634 <ialloc>
    800051a0:	84aa                	mv	s1,a0
    800051a2:	c529                	beqz	a0,800051ec <create+0xee>
  ilock(ip);
    800051a4:	ffffe097          	auipc	ra,0xffffe
    800051a8:	628080e7          	jalr	1576(ra) # 800037cc <ilock>
  ip->major = major;
    800051ac:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051b0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051b4:	4785                	li	a5,1
    800051b6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051ba:	8526                	mv	a0,s1
    800051bc:	ffffe097          	auipc	ra,0xffffe
    800051c0:	546080e7          	jalr	1350(ra) # 80003702 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051c4:	2981                	sext.w	s3,s3
    800051c6:	4785                	li	a5,1
    800051c8:	02f98a63          	beq	s3,a5,800051fc <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051cc:	40d0                	lw	a2,4(s1)
    800051ce:	fb040593          	addi	a1,s0,-80
    800051d2:	854a                	mv	a0,s2
    800051d4:	fffff097          	auipc	ra,0xfffff
    800051d8:	cec080e7          	jalr	-788(ra) # 80003ec0 <dirlink>
    800051dc:	06054b63          	bltz	a0,80005252 <create+0x154>
  iunlockput(dp);
    800051e0:	854a                	mv	a0,s2
    800051e2:	fffff097          	auipc	ra,0xfffff
    800051e6:	84c080e7          	jalr	-1972(ra) # 80003a2e <iunlockput>
  return ip;
    800051ea:	b759                	j	80005170 <create+0x72>
    panic("create: ialloc");
    800051ec:	00003517          	auipc	a0,0x3
    800051f0:	53c50513          	addi	a0,a0,1340 # 80008728 <syscalls+0x2b0>
    800051f4:	ffffb097          	auipc	ra,0xffffb
    800051f8:	34a080e7          	jalr	842(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800051fc:	04a95783          	lhu	a5,74(s2)
    80005200:	2785                	addiw	a5,a5,1
    80005202:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005206:	854a                	mv	a0,s2
    80005208:	ffffe097          	auipc	ra,0xffffe
    8000520c:	4fa080e7          	jalr	1274(ra) # 80003702 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005210:	40d0                	lw	a2,4(s1)
    80005212:	00003597          	auipc	a1,0x3
    80005216:	52658593          	addi	a1,a1,1318 # 80008738 <syscalls+0x2c0>
    8000521a:	8526                	mv	a0,s1
    8000521c:	fffff097          	auipc	ra,0xfffff
    80005220:	ca4080e7          	jalr	-860(ra) # 80003ec0 <dirlink>
    80005224:	00054f63          	bltz	a0,80005242 <create+0x144>
    80005228:	00492603          	lw	a2,4(s2)
    8000522c:	00003597          	auipc	a1,0x3
    80005230:	51458593          	addi	a1,a1,1300 # 80008740 <syscalls+0x2c8>
    80005234:	8526                	mv	a0,s1
    80005236:	fffff097          	auipc	ra,0xfffff
    8000523a:	c8a080e7          	jalr	-886(ra) # 80003ec0 <dirlink>
    8000523e:	f80557e3          	bgez	a0,800051cc <create+0xce>
      panic("create dots");
    80005242:	00003517          	auipc	a0,0x3
    80005246:	50650513          	addi	a0,a0,1286 # 80008748 <syscalls+0x2d0>
    8000524a:	ffffb097          	auipc	ra,0xffffb
    8000524e:	2f4080e7          	jalr	756(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005252:	00003517          	auipc	a0,0x3
    80005256:	50650513          	addi	a0,a0,1286 # 80008758 <syscalls+0x2e0>
    8000525a:	ffffb097          	auipc	ra,0xffffb
    8000525e:	2e4080e7          	jalr	740(ra) # 8000053e <panic>
    return 0;
    80005262:	84aa                	mv	s1,a0
    80005264:	b731                	j	80005170 <create+0x72>

0000000080005266 <sys_dup>:
{
    80005266:	7179                	addi	sp,sp,-48
    80005268:	f406                	sd	ra,40(sp)
    8000526a:	f022                	sd	s0,32(sp)
    8000526c:	ec26                	sd	s1,24(sp)
    8000526e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005270:	fd840613          	addi	a2,s0,-40
    80005274:	4581                	li	a1,0
    80005276:	4501                	li	a0,0
    80005278:	00000097          	auipc	ra,0x0
    8000527c:	ddc080e7          	jalr	-548(ra) # 80005054 <argfd>
    return -1;
    80005280:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005282:	02054363          	bltz	a0,800052a8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005286:	fd843503          	ld	a0,-40(s0)
    8000528a:	00000097          	auipc	ra,0x0
    8000528e:	e32080e7          	jalr	-462(ra) # 800050bc <fdalloc>
    80005292:	84aa                	mv	s1,a0
    return -1;
    80005294:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005296:	00054963          	bltz	a0,800052a8 <sys_dup+0x42>
  filedup(f);
    8000529a:	fd843503          	ld	a0,-40(s0)
    8000529e:	fffff097          	auipc	ra,0xfffff
    800052a2:	37a080e7          	jalr	890(ra) # 80004618 <filedup>
  return fd;
    800052a6:	87a6                	mv	a5,s1
}
    800052a8:	853e                	mv	a0,a5
    800052aa:	70a2                	ld	ra,40(sp)
    800052ac:	7402                	ld	s0,32(sp)
    800052ae:	64e2                	ld	s1,24(sp)
    800052b0:	6145                	addi	sp,sp,48
    800052b2:	8082                	ret

00000000800052b4 <sys_read>:
{
    800052b4:	7179                	addi	sp,sp,-48
    800052b6:	f406                	sd	ra,40(sp)
    800052b8:	f022                	sd	s0,32(sp)
    800052ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052bc:	fe840613          	addi	a2,s0,-24
    800052c0:	4581                	li	a1,0
    800052c2:	4501                	li	a0,0
    800052c4:	00000097          	auipc	ra,0x0
    800052c8:	d90080e7          	jalr	-624(ra) # 80005054 <argfd>
    return -1;
    800052cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ce:	04054163          	bltz	a0,80005310 <sys_read+0x5c>
    800052d2:	fe440593          	addi	a1,s0,-28
    800052d6:	4509                	li	a0,2
    800052d8:	ffffe097          	auipc	ra,0xffffe
    800052dc:	93c080e7          	jalr	-1732(ra) # 80002c14 <argint>
    return -1;
    800052e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e2:	02054763          	bltz	a0,80005310 <sys_read+0x5c>
    800052e6:	fd840593          	addi	a1,s0,-40
    800052ea:	4505                	li	a0,1
    800052ec:	ffffe097          	auipc	ra,0xffffe
    800052f0:	94a080e7          	jalr	-1718(ra) # 80002c36 <argaddr>
    return -1;
    800052f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f6:	00054d63          	bltz	a0,80005310 <sys_read+0x5c>
  return fileread(f, p, n);
    800052fa:	fe442603          	lw	a2,-28(s0)
    800052fe:	fd843583          	ld	a1,-40(s0)
    80005302:	fe843503          	ld	a0,-24(s0)
    80005306:	fffff097          	auipc	ra,0xfffff
    8000530a:	49e080e7          	jalr	1182(ra) # 800047a4 <fileread>
    8000530e:	87aa                	mv	a5,a0
}
    80005310:	853e                	mv	a0,a5
    80005312:	70a2                	ld	ra,40(sp)
    80005314:	7402                	ld	s0,32(sp)
    80005316:	6145                	addi	sp,sp,48
    80005318:	8082                	ret

000000008000531a <sys_write>:
{
    8000531a:	7179                	addi	sp,sp,-48
    8000531c:	f406                	sd	ra,40(sp)
    8000531e:	f022                	sd	s0,32(sp)
    80005320:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005322:	fe840613          	addi	a2,s0,-24
    80005326:	4581                	li	a1,0
    80005328:	4501                	li	a0,0
    8000532a:	00000097          	auipc	ra,0x0
    8000532e:	d2a080e7          	jalr	-726(ra) # 80005054 <argfd>
    return -1;
    80005332:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005334:	04054163          	bltz	a0,80005376 <sys_write+0x5c>
    80005338:	fe440593          	addi	a1,s0,-28
    8000533c:	4509                	li	a0,2
    8000533e:	ffffe097          	auipc	ra,0xffffe
    80005342:	8d6080e7          	jalr	-1834(ra) # 80002c14 <argint>
    return -1;
    80005346:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005348:	02054763          	bltz	a0,80005376 <sys_write+0x5c>
    8000534c:	fd840593          	addi	a1,s0,-40
    80005350:	4505                	li	a0,1
    80005352:	ffffe097          	auipc	ra,0xffffe
    80005356:	8e4080e7          	jalr	-1820(ra) # 80002c36 <argaddr>
    return -1;
    8000535a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000535c:	00054d63          	bltz	a0,80005376 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005360:	fe442603          	lw	a2,-28(s0)
    80005364:	fd843583          	ld	a1,-40(s0)
    80005368:	fe843503          	ld	a0,-24(s0)
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	4fa080e7          	jalr	1274(ra) # 80004866 <filewrite>
    80005374:	87aa                	mv	a5,a0
}
    80005376:	853e                	mv	a0,a5
    80005378:	70a2                	ld	ra,40(sp)
    8000537a:	7402                	ld	s0,32(sp)
    8000537c:	6145                	addi	sp,sp,48
    8000537e:	8082                	ret

0000000080005380 <sys_close>:
{
    80005380:	1101                	addi	sp,sp,-32
    80005382:	ec06                	sd	ra,24(sp)
    80005384:	e822                	sd	s0,16(sp)
    80005386:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005388:	fe040613          	addi	a2,s0,-32
    8000538c:	fec40593          	addi	a1,s0,-20
    80005390:	4501                	li	a0,0
    80005392:	00000097          	auipc	ra,0x0
    80005396:	cc2080e7          	jalr	-830(ra) # 80005054 <argfd>
    return -1;
    8000539a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000539c:	02054463          	bltz	a0,800053c4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053a0:	ffffc097          	auipc	ra,0xffffc
    800053a4:	610080e7          	jalr	1552(ra) # 800019b0 <myproc>
    800053a8:	fec42783          	lw	a5,-20(s0)
    800053ac:	07e9                	addi	a5,a5,26
    800053ae:	078e                	slli	a5,a5,0x3
    800053b0:	97aa                	add	a5,a5,a0
    800053b2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053b6:	fe043503          	ld	a0,-32(s0)
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	2b0080e7          	jalr	688(ra) # 8000466a <fileclose>
  return 0;
    800053c2:	4781                	li	a5,0
}
    800053c4:	853e                	mv	a0,a5
    800053c6:	60e2                	ld	ra,24(sp)
    800053c8:	6442                	ld	s0,16(sp)
    800053ca:	6105                	addi	sp,sp,32
    800053cc:	8082                	ret

00000000800053ce <sys_fstat>:
{
    800053ce:	1101                	addi	sp,sp,-32
    800053d0:	ec06                	sd	ra,24(sp)
    800053d2:	e822                	sd	s0,16(sp)
    800053d4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053d6:	fe840613          	addi	a2,s0,-24
    800053da:	4581                	li	a1,0
    800053dc:	4501                	li	a0,0
    800053de:	00000097          	auipc	ra,0x0
    800053e2:	c76080e7          	jalr	-906(ra) # 80005054 <argfd>
    return -1;
    800053e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053e8:	02054563          	bltz	a0,80005412 <sys_fstat+0x44>
    800053ec:	fe040593          	addi	a1,s0,-32
    800053f0:	4505                	li	a0,1
    800053f2:	ffffe097          	auipc	ra,0xffffe
    800053f6:	844080e7          	jalr	-1980(ra) # 80002c36 <argaddr>
    return -1;
    800053fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053fc:	00054b63          	bltz	a0,80005412 <sys_fstat+0x44>
  return filestat(f, st);
    80005400:	fe043583          	ld	a1,-32(s0)
    80005404:	fe843503          	ld	a0,-24(s0)
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	32a080e7          	jalr	810(ra) # 80004732 <filestat>
    80005410:	87aa                	mv	a5,a0
}
    80005412:	853e                	mv	a0,a5
    80005414:	60e2                	ld	ra,24(sp)
    80005416:	6442                	ld	s0,16(sp)
    80005418:	6105                	addi	sp,sp,32
    8000541a:	8082                	ret

000000008000541c <sys_link>:
{
    8000541c:	7169                	addi	sp,sp,-304
    8000541e:	f606                	sd	ra,296(sp)
    80005420:	f222                	sd	s0,288(sp)
    80005422:	ee26                	sd	s1,280(sp)
    80005424:	ea4a                	sd	s2,272(sp)
    80005426:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005428:	08000613          	li	a2,128
    8000542c:	ed040593          	addi	a1,s0,-304
    80005430:	4501                	li	a0,0
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	826080e7          	jalr	-2010(ra) # 80002c58 <argstr>
    return -1;
    8000543a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000543c:	10054e63          	bltz	a0,80005558 <sys_link+0x13c>
    80005440:	08000613          	li	a2,128
    80005444:	f5040593          	addi	a1,s0,-176
    80005448:	4505                	li	a0,1
    8000544a:	ffffe097          	auipc	ra,0xffffe
    8000544e:	80e080e7          	jalr	-2034(ra) # 80002c58 <argstr>
    return -1;
    80005452:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005454:	10054263          	bltz	a0,80005558 <sys_link+0x13c>
  begin_op();
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	d46080e7          	jalr	-698(ra) # 8000419e <begin_op>
  if((ip = namei(old)) == 0){
    80005460:	ed040513          	addi	a0,s0,-304
    80005464:	fffff097          	auipc	ra,0xfffff
    80005468:	b1e080e7          	jalr	-1250(ra) # 80003f82 <namei>
    8000546c:	84aa                	mv	s1,a0
    8000546e:	c551                	beqz	a0,800054fa <sys_link+0xde>
  ilock(ip);
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	35c080e7          	jalr	860(ra) # 800037cc <ilock>
  if(ip->type == T_DIR){
    80005478:	04449703          	lh	a4,68(s1)
    8000547c:	4785                	li	a5,1
    8000547e:	08f70463          	beq	a4,a5,80005506 <sys_link+0xea>
  ip->nlink++;
    80005482:	04a4d783          	lhu	a5,74(s1)
    80005486:	2785                	addiw	a5,a5,1
    80005488:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000548c:	8526                	mv	a0,s1
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	274080e7          	jalr	628(ra) # 80003702 <iupdate>
  iunlock(ip);
    80005496:	8526                	mv	a0,s1
    80005498:	ffffe097          	auipc	ra,0xffffe
    8000549c:	3f6080e7          	jalr	1014(ra) # 8000388e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054a0:	fd040593          	addi	a1,s0,-48
    800054a4:	f5040513          	addi	a0,s0,-176
    800054a8:	fffff097          	auipc	ra,0xfffff
    800054ac:	af8080e7          	jalr	-1288(ra) # 80003fa0 <nameiparent>
    800054b0:	892a                	mv	s2,a0
    800054b2:	c935                	beqz	a0,80005526 <sys_link+0x10a>
  ilock(dp);
    800054b4:	ffffe097          	auipc	ra,0xffffe
    800054b8:	318080e7          	jalr	792(ra) # 800037cc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054bc:	00092703          	lw	a4,0(s2)
    800054c0:	409c                	lw	a5,0(s1)
    800054c2:	04f71d63          	bne	a4,a5,8000551c <sys_link+0x100>
    800054c6:	40d0                	lw	a2,4(s1)
    800054c8:	fd040593          	addi	a1,s0,-48
    800054cc:	854a                	mv	a0,s2
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	9f2080e7          	jalr	-1550(ra) # 80003ec0 <dirlink>
    800054d6:	04054363          	bltz	a0,8000551c <sys_link+0x100>
  iunlockput(dp);
    800054da:	854a                	mv	a0,s2
    800054dc:	ffffe097          	auipc	ra,0xffffe
    800054e0:	552080e7          	jalr	1362(ra) # 80003a2e <iunlockput>
  iput(ip);
    800054e4:	8526                	mv	a0,s1
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	4a0080e7          	jalr	1184(ra) # 80003986 <iput>
  end_op();
    800054ee:	fffff097          	auipc	ra,0xfffff
    800054f2:	d30080e7          	jalr	-720(ra) # 8000421e <end_op>
  return 0;
    800054f6:	4781                	li	a5,0
    800054f8:	a085                	j	80005558 <sys_link+0x13c>
    end_op();
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	d24080e7          	jalr	-732(ra) # 8000421e <end_op>
    return -1;
    80005502:	57fd                	li	a5,-1
    80005504:	a891                	j	80005558 <sys_link+0x13c>
    iunlockput(ip);
    80005506:	8526                	mv	a0,s1
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	526080e7          	jalr	1318(ra) # 80003a2e <iunlockput>
    end_op();
    80005510:	fffff097          	auipc	ra,0xfffff
    80005514:	d0e080e7          	jalr	-754(ra) # 8000421e <end_op>
    return -1;
    80005518:	57fd                	li	a5,-1
    8000551a:	a83d                	j	80005558 <sys_link+0x13c>
    iunlockput(dp);
    8000551c:	854a                	mv	a0,s2
    8000551e:	ffffe097          	auipc	ra,0xffffe
    80005522:	510080e7          	jalr	1296(ra) # 80003a2e <iunlockput>
  ilock(ip);
    80005526:	8526                	mv	a0,s1
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	2a4080e7          	jalr	676(ra) # 800037cc <ilock>
  ip->nlink--;
    80005530:	04a4d783          	lhu	a5,74(s1)
    80005534:	37fd                	addiw	a5,a5,-1
    80005536:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000553a:	8526                	mv	a0,s1
    8000553c:	ffffe097          	auipc	ra,0xffffe
    80005540:	1c6080e7          	jalr	454(ra) # 80003702 <iupdate>
  iunlockput(ip);
    80005544:	8526                	mv	a0,s1
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	4e8080e7          	jalr	1256(ra) # 80003a2e <iunlockput>
  end_op();
    8000554e:	fffff097          	auipc	ra,0xfffff
    80005552:	cd0080e7          	jalr	-816(ra) # 8000421e <end_op>
  return -1;
    80005556:	57fd                	li	a5,-1
}
    80005558:	853e                	mv	a0,a5
    8000555a:	70b2                	ld	ra,296(sp)
    8000555c:	7412                	ld	s0,288(sp)
    8000555e:	64f2                	ld	s1,280(sp)
    80005560:	6952                	ld	s2,272(sp)
    80005562:	6155                	addi	sp,sp,304
    80005564:	8082                	ret

0000000080005566 <sys_unlink>:
{
    80005566:	7151                	addi	sp,sp,-240
    80005568:	f586                	sd	ra,232(sp)
    8000556a:	f1a2                	sd	s0,224(sp)
    8000556c:	eda6                	sd	s1,216(sp)
    8000556e:	e9ca                	sd	s2,208(sp)
    80005570:	e5ce                	sd	s3,200(sp)
    80005572:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005574:	08000613          	li	a2,128
    80005578:	f3040593          	addi	a1,s0,-208
    8000557c:	4501                	li	a0,0
    8000557e:	ffffd097          	auipc	ra,0xffffd
    80005582:	6da080e7          	jalr	1754(ra) # 80002c58 <argstr>
    80005586:	18054163          	bltz	a0,80005708 <sys_unlink+0x1a2>
  begin_op();
    8000558a:	fffff097          	auipc	ra,0xfffff
    8000558e:	c14080e7          	jalr	-1004(ra) # 8000419e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005592:	fb040593          	addi	a1,s0,-80
    80005596:	f3040513          	addi	a0,s0,-208
    8000559a:	fffff097          	auipc	ra,0xfffff
    8000559e:	a06080e7          	jalr	-1530(ra) # 80003fa0 <nameiparent>
    800055a2:	84aa                	mv	s1,a0
    800055a4:	c979                	beqz	a0,8000567a <sys_unlink+0x114>
  ilock(dp);
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	226080e7          	jalr	550(ra) # 800037cc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055ae:	00003597          	auipc	a1,0x3
    800055b2:	18a58593          	addi	a1,a1,394 # 80008738 <syscalls+0x2c0>
    800055b6:	fb040513          	addi	a0,s0,-80
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	6dc080e7          	jalr	1756(ra) # 80003c96 <namecmp>
    800055c2:	14050a63          	beqz	a0,80005716 <sys_unlink+0x1b0>
    800055c6:	00003597          	auipc	a1,0x3
    800055ca:	17a58593          	addi	a1,a1,378 # 80008740 <syscalls+0x2c8>
    800055ce:	fb040513          	addi	a0,s0,-80
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	6c4080e7          	jalr	1732(ra) # 80003c96 <namecmp>
    800055da:	12050e63          	beqz	a0,80005716 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055de:	f2c40613          	addi	a2,s0,-212
    800055e2:	fb040593          	addi	a1,s0,-80
    800055e6:	8526                	mv	a0,s1
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	6c8080e7          	jalr	1736(ra) # 80003cb0 <dirlookup>
    800055f0:	892a                	mv	s2,a0
    800055f2:	12050263          	beqz	a0,80005716 <sys_unlink+0x1b0>
  ilock(ip);
    800055f6:	ffffe097          	auipc	ra,0xffffe
    800055fa:	1d6080e7          	jalr	470(ra) # 800037cc <ilock>
  if(ip->nlink < 1)
    800055fe:	04a91783          	lh	a5,74(s2)
    80005602:	08f05263          	blez	a5,80005686 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005606:	04491703          	lh	a4,68(s2)
    8000560a:	4785                	li	a5,1
    8000560c:	08f70563          	beq	a4,a5,80005696 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005610:	4641                	li	a2,16
    80005612:	4581                	li	a1,0
    80005614:	fc040513          	addi	a0,s0,-64
    80005618:	ffffb097          	auipc	ra,0xffffb
    8000561c:	6c8080e7          	jalr	1736(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005620:	4741                	li	a4,16
    80005622:	f2c42683          	lw	a3,-212(s0)
    80005626:	fc040613          	addi	a2,s0,-64
    8000562a:	4581                	li	a1,0
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	54a080e7          	jalr	1354(ra) # 80003b78 <writei>
    80005636:	47c1                	li	a5,16
    80005638:	0af51563          	bne	a0,a5,800056e2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000563c:	04491703          	lh	a4,68(s2)
    80005640:	4785                	li	a5,1
    80005642:	0af70863          	beq	a4,a5,800056f2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005646:	8526                	mv	a0,s1
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	3e6080e7          	jalr	998(ra) # 80003a2e <iunlockput>
  ip->nlink--;
    80005650:	04a95783          	lhu	a5,74(s2)
    80005654:	37fd                	addiw	a5,a5,-1
    80005656:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000565a:	854a                	mv	a0,s2
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	0a6080e7          	jalr	166(ra) # 80003702 <iupdate>
  iunlockput(ip);
    80005664:	854a                	mv	a0,s2
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	3c8080e7          	jalr	968(ra) # 80003a2e <iunlockput>
  end_op();
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	bb0080e7          	jalr	-1104(ra) # 8000421e <end_op>
  return 0;
    80005676:	4501                	li	a0,0
    80005678:	a84d                	j	8000572a <sys_unlink+0x1c4>
    end_op();
    8000567a:	fffff097          	auipc	ra,0xfffff
    8000567e:	ba4080e7          	jalr	-1116(ra) # 8000421e <end_op>
    return -1;
    80005682:	557d                	li	a0,-1
    80005684:	a05d                	j	8000572a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005686:	00003517          	auipc	a0,0x3
    8000568a:	0e250513          	addi	a0,a0,226 # 80008768 <syscalls+0x2f0>
    8000568e:	ffffb097          	auipc	ra,0xffffb
    80005692:	eb0080e7          	jalr	-336(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005696:	04c92703          	lw	a4,76(s2)
    8000569a:	02000793          	li	a5,32
    8000569e:	f6e7f9e3          	bgeu	a5,a4,80005610 <sys_unlink+0xaa>
    800056a2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056a6:	4741                	li	a4,16
    800056a8:	86ce                	mv	a3,s3
    800056aa:	f1840613          	addi	a2,s0,-232
    800056ae:	4581                	li	a1,0
    800056b0:	854a                	mv	a0,s2
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	3ce080e7          	jalr	974(ra) # 80003a80 <readi>
    800056ba:	47c1                	li	a5,16
    800056bc:	00f51b63          	bne	a0,a5,800056d2 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056c0:	f1845783          	lhu	a5,-232(s0)
    800056c4:	e7a1                	bnez	a5,8000570c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056c6:	29c1                	addiw	s3,s3,16
    800056c8:	04c92783          	lw	a5,76(s2)
    800056cc:	fcf9ede3          	bltu	s3,a5,800056a6 <sys_unlink+0x140>
    800056d0:	b781                	j	80005610 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056d2:	00003517          	auipc	a0,0x3
    800056d6:	0ae50513          	addi	a0,a0,174 # 80008780 <syscalls+0x308>
    800056da:	ffffb097          	auipc	ra,0xffffb
    800056de:	e64080e7          	jalr	-412(ra) # 8000053e <panic>
    panic("unlink: writei");
    800056e2:	00003517          	auipc	a0,0x3
    800056e6:	0b650513          	addi	a0,a0,182 # 80008798 <syscalls+0x320>
    800056ea:	ffffb097          	auipc	ra,0xffffb
    800056ee:	e54080e7          	jalr	-428(ra) # 8000053e <panic>
    dp->nlink--;
    800056f2:	04a4d783          	lhu	a5,74(s1)
    800056f6:	37fd                	addiw	a5,a5,-1
    800056f8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056fc:	8526                	mv	a0,s1
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	004080e7          	jalr	4(ra) # 80003702 <iupdate>
    80005706:	b781                	j	80005646 <sys_unlink+0xe0>
    return -1;
    80005708:	557d                	li	a0,-1
    8000570a:	a005                	j	8000572a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000570c:	854a                	mv	a0,s2
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	320080e7          	jalr	800(ra) # 80003a2e <iunlockput>
  iunlockput(dp);
    80005716:	8526                	mv	a0,s1
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	316080e7          	jalr	790(ra) # 80003a2e <iunlockput>
  end_op();
    80005720:	fffff097          	auipc	ra,0xfffff
    80005724:	afe080e7          	jalr	-1282(ra) # 8000421e <end_op>
  return -1;
    80005728:	557d                	li	a0,-1
}
    8000572a:	70ae                	ld	ra,232(sp)
    8000572c:	740e                	ld	s0,224(sp)
    8000572e:	64ee                	ld	s1,216(sp)
    80005730:	694e                	ld	s2,208(sp)
    80005732:	69ae                	ld	s3,200(sp)
    80005734:	616d                	addi	sp,sp,240
    80005736:	8082                	ret

0000000080005738 <sys_open>:

uint64
sys_open(void)
{
    80005738:	7131                	addi	sp,sp,-192
    8000573a:	fd06                	sd	ra,184(sp)
    8000573c:	f922                	sd	s0,176(sp)
    8000573e:	f526                	sd	s1,168(sp)
    80005740:	f14a                	sd	s2,160(sp)
    80005742:	ed4e                	sd	s3,152(sp)
    80005744:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005746:	08000613          	li	a2,128
    8000574a:	f5040593          	addi	a1,s0,-176
    8000574e:	4501                	li	a0,0
    80005750:	ffffd097          	auipc	ra,0xffffd
    80005754:	508080e7          	jalr	1288(ra) # 80002c58 <argstr>
    return -1;
    80005758:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000575a:	0c054163          	bltz	a0,8000581c <sys_open+0xe4>
    8000575e:	f4c40593          	addi	a1,s0,-180
    80005762:	4505                	li	a0,1
    80005764:	ffffd097          	auipc	ra,0xffffd
    80005768:	4b0080e7          	jalr	1200(ra) # 80002c14 <argint>
    8000576c:	0a054863          	bltz	a0,8000581c <sys_open+0xe4>

  begin_op();
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	a2e080e7          	jalr	-1490(ra) # 8000419e <begin_op>

  if(omode & O_CREATE){
    80005778:	f4c42783          	lw	a5,-180(s0)
    8000577c:	2007f793          	andi	a5,a5,512
    80005780:	cbdd                	beqz	a5,80005836 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005782:	4681                	li	a3,0
    80005784:	4601                	li	a2,0
    80005786:	4589                	li	a1,2
    80005788:	f5040513          	addi	a0,s0,-176
    8000578c:	00000097          	auipc	ra,0x0
    80005790:	972080e7          	jalr	-1678(ra) # 800050fe <create>
    80005794:	892a                	mv	s2,a0
    if(ip == 0){
    80005796:	c959                	beqz	a0,8000582c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005798:	04491703          	lh	a4,68(s2)
    8000579c:	478d                	li	a5,3
    8000579e:	00f71763          	bne	a4,a5,800057ac <sys_open+0x74>
    800057a2:	04695703          	lhu	a4,70(s2)
    800057a6:	47a5                	li	a5,9
    800057a8:	0ce7ec63          	bltu	a5,a4,80005880 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	e02080e7          	jalr	-510(ra) # 800045ae <filealloc>
    800057b4:	89aa                	mv	s3,a0
    800057b6:	10050263          	beqz	a0,800058ba <sys_open+0x182>
    800057ba:	00000097          	auipc	ra,0x0
    800057be:	902080e7          	jalr	-1790(ra) # 800050bc <fdalloc>
    800057c2:	84aa                	mv	s1,a0
    800057c4:	0e054663          	bltz	a0,800058b0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057c8:	04491703          	lh	a4,68(s2)
    800057cc:	478d                	li	a5,3
    800057ce:	0cf70463          	beq	a4,a5,80005896 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057d2:	4789                	li	a5,2
    800057d4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057d8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057dc:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057e0:	f4c42783          	lw	a5,-180(s0)
    800057e4:	0017c713          	xori	a4,a5,1
    800057e8:	8b05                	andi	a4,a4,1
    800057ea:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057ee:	0037f713          	andi	a4,a5,3
    800057f2:	00e03733          	snez	a4,a4
    800057f6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057fa:	4007f793          	andi	a5,a5,1024
    800057fe:	c791                	beqz	a5,8000580a <sys_open+0xd2>
    80005800:	04491703          	lh	a4,68(s2)
    80005804:	4789                	li	a5,2
    80005806:	08f70f63          	beq	a4,a5,800058a4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000580a:	854a                	mv	a0,s2
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	082080e7          	jalr	130(ra) # 8000388e <iunlock>
  end_op();
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	a0a080e7          	jalr	-1526(ra) # 8000421e <end_op>

  return fd;
}
    8000581c:	8526                	mv	a0,s1
    8000581e:	70ea                	ld	ra,184(sp)
    80005820:	744a                	ld	s0,176(sp)
    80005822:	74aa                	ld	s1,168(sp)
    80005824:	790a                	ld	s2,160(sp)
    80005826:	69ea                	ld	s3,152(sp)
    80005828:	6129                	addi	sp,sp,192
    8000582a:	8082                	ret
      end_op();
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	9f2080e7          	jalr	-1550(ra) # 8000421e <end_op>
      return -1;
    80005834:	b7e5                	j	8000581c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005836:	f5040513          	addi	a0,s0,-176
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	748080e7          	jalr	1864(ra) # 80003f82 <namei>
    80005842:	892a                	mv	s2,a0
    80005844:	c905                	beqz	a0,80005874 <sys_open+0x13c>
    ilock(ip);
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	f86080e7          	jalr	-122(ra) # 800037cc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000584e:	04491703          	lh	a4,68(s2)
    80005852:	4785                	li	a5,1
    80005854:	f4f712e3          	bne	a4,a5,80005798 <sys_open+0x60>
    80005858:	f4c42783          	lw	a5,-180(s0)
    8000585c:	dba1                	beqz	a5,800057ac <sys_open+0x74>
      iunlockput(ip);
    8000585e:	854a                	mv	a0,s2
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	1ce080e7          	jalr	462(ra) # 80003a2e <iunlockput>
      end_op();
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	9b6080e7          	jalr	-1610(ra) # 8000421e <end_op>
      return -1;
    80005870:	54fd                	li	s1,-1
    80005872:	b76d                	j	8000581c <sys_open+0xe4>
      end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	9aa080e7          	jalr	-1622(ra) # 8000421e <end_op>
      return -1;
    8000587c:	54fd                	li	s1,-1
    8000587e:	bf79                	j	8000581c <sys_open+0xe4>
    iunlockput(ip);
    80005880:	854a                	mv	a0,s2
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	1ac080e7          	jalr	428(ra) # 80003a2e <iunlockput>
    end_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	994080e7          	jalr	-1644(ra) # 8000421e <end_op>
    return -1;
    80005892:	54fd                	li	s1,-1
    80005894:	b761                	j	8000581c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005896:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000589a:	04691783          	lh	a5,70(s2)
    8000589e:	02f99223          	sh	a5,36(s3)
    800058a2:	bf2d                	j	800057dc <sys_open+0xa4>
    itrunc(ip);
    800058a4:	854a                	mv	a0,s2
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	034080e7          	jalr	52(ra) # 800038da <itrunc>
    800058ae:	bfb1                	j	8000580a <sys_open+0xd2>
      fileclose(f);
    800058b0:	854e                	mv	a0,s3
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	db8080e7          	jalr	-584(ra) # 8000466a <fileclose>
    iunlockput(ip);
    800058ba:	854a                	mv	a0,s2
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	172080e7          	jalr	370(ra) # 80003a2e <iunlockput>
    end_op();
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	95a080e7          	jalr	-1702(ra) # 8000421e <end_op>
    return -1;
    800058cc:	54fd                	li	s1,-1
    800058ce:	b7b9                	j	8000581c <sys_open+0xe4>

00000000800058d0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058d0:	7175                	addi	sp,sp,-144
    800058d2:	e506                	sd	ra,136(sp)
    800058d4:	e122                	sd	s0,128(sp)
    800058d6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	8c6080e7          	jalr	-1850(ra) # 8000419e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058e0:	08000613          	li	a2,128
    800058e4:	f7040593          	addi	a1,s0,-144
    800058e8:	4501                	li	a0,0
    800058ea:	ffffd097          	auipc	ra,0xffffd
    800058ee:	36e080e7          	jalr	878(ra) # 80002c58 <argstr>
    800058f2:	02054963          	bltz	a0,80005924 <sys_mkdir+0x54>
    800058f6:	4681                	li	a3,0
    800058f8:	4601                	li	a2,0
    800058fa:	4585                	li	a1,1
    800058fc:	f7040513          	addi	a0,s0,-144
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	7fe080e7          	jalr	2046(ra) # 800050fe <create>
    80005908:	cd11                	beqz	a0,80005924 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000590a:	ffffe097          	auipc	ra,0xffffe
    8000590e:	124080e7          	jalr	292(ra) # 80003a2e <iunlockput>
  end_op();
    80005912:	fffff097          	auipc	ra,0xfffff
    80005916:	90c080e7          	jalr	-1780(ra) # 8000421e <end_op>
  return 0;
    8000591a:	4501                	li	a0,0
}
    8000591c:	60aa                	ld	ra,136(sp)
    8000591e:	640a                	ld	s0,128(sp)
    80005920:	6149                	addi	sp,sp,144
    80005922:	8082                	ret
    end_op();
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	8fa080e7          	jalr	-1798(ra) # 8000421e <end_op>
    return -1;
    8000592c:	557d                	li	a0,-1
    8000592e:	b7fd                	j	8000591c <sys_mkdir+0x4c>

0000000080005930 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005930:	7135                	addi	sp,sp,-160
    80005932:	ed06                	sd	ra,152(sp)
    80005934:	e922                	sd	s0,144(sp)
    80005936:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	866080e7          	jalr	-1946(ra) # 8000419e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005940:	08000613          	li	a2,128
    80005944:	f7040593          	addi	a1,s0,-144
    80005948:	4501                	li	a0,0
    8000594a:	ffffd097          	auipc	ra,0xffffd
    8000594e:	30e080e7          	jalr	782(ra) # 80002c58 <argstr>
    80005952:	04054a63          	bltz	a0,800059a6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005956:	f6c40593          	addi	a1,s0,-148
    8000595a:	4505                	li	a0,1
    8000595c:	ffffd097          	auipc	ra,0xffffd
    80005960:	2b8080e7          	jalr	696(ra) # 80002c14 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005964:	04054163          	bltz	a0,800059a6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005968:	f6840593          	addi	a1,s0,-152
    8000596c:	4509                	li	a0,2
    8000596e:	ffffd097          	auipc	ra,0xffffd
    80005972:	2a6080e7          	jalr	678(ra) # 80002c14 <argint>
     argint(1, &major) < 0 ||
    80005976:	02054863          	bltz	a0,800059a6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000597a:	f6841683          	lh	a3,-152(s0)
    8000597e:	f6c41603          	lh	a2,-148(s0)
    80005982:	458d                	li	a1,3
    80005984:	f7040513          	addi	a0,s0,-144
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	776080e7          	jalr	1910(ra) # 800050fe <create>
     argint(2, &minor) < 0 ||
    80005990:	c919                	beqz	a0,800059a6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	09c080e7          	jalr	156(ra) # 80003a2e <iunlockput>
  end_op();
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	884080e7          	jalr	-1916(ra) # 8000421e <end_op>
  return 0;
    800059a2:	4501                	li	a0,0
    800059a4:	a031                	j	800059b0 <sys_mknod+0x80>
    end_op();
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	878080e7          	jalr	-1928(ra) # 8000421e <end_op>
    return -1;
    800059ae:	557d                	li	a0,-1
}
    800059b0:	60ea                	ld	ra,152(sp)
    800059b2:	644a                	ld	s0,144(sp)
    800059b4:	610d                	addi	sp,sp,160
    800059b6:	8082                	ret

00000000800059b8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059b8:	7135                	addi	sp,sp,-160
    800059ba:	ed06                	sd	ra,152(sp)
    800059bc:	e922                	sd	s0,144(sp)
    800059be:	e526                	sd	s1,136(sp)
    800059c0:	e14a                	sd	s2,128(sp)
    800059c2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059c4:	ffffc097          	auipc	ra,0xffffc
    800059c8:	fec080e7          	jalr	-20(ra) # 800019b0 <myproc>
    800059cc:	892a                	mv	s2,a0
  
  begin_op();
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	7d0080e7          	jalr	2000(ra) # 8000419e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059d6:	08000613          	li	a2,128
    800059da:	f6040593          	addi	a1,s0,-160
    800059de:	4501                	li	a0,0
    800059e0:	ffffd097          	auipc	ra,0xffffd
    800059e4:	278080e7          	jalr	632(ra) # 80002c58 <argstr>
    800059e8:	04054b63          	bltz	a0,80005a3e <sys_chdir+0x86>
    800059ec:	f6040513          	addi	a0,s0,-160
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	592080e7          	jalr	1426(ra) # 80003f82 <namei>
    800059f8:	84aa                	mv	s1,a0
    800059fa:	c131                	beqz	a0,80005a3e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	dd0080e7          	jalr	-560(ra) # 800037cc <ilock>
  if(ip->type != T_DIR){
    80005a04:	04449703          	lh	a4,68(s1)
    80005a08:	4785                	li	a5,1
    80005a0a:	04f71063          	bne	a4,a5,80005a4a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a0e:	8526                	mv	a0,s1
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	e7e080e7          	jalr	-386(ra) # 8000388e <iunlock>
  iput(p->cwd);
    80005a18:	15093503          	ld	a0,336(s2)
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	f6a080e7          	jalr	-150(ra) # 80003986 <iput>
  end_op();
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	7fa080e7          	jalr	2042(ra) # 8000421e <end_op>
  p->cwd = ip;
    80005a2c:	14993823          	sd	s1,336(s2)
  return 0;
    80005a30:	4501                	li	a0,0
}
    80005a32:	60ea                	ld	ra,152(sp)
    80005a34:	644a                	ld	s0,144(sp)
    80005a36:	64aa                	ld	s1,136(sp)
    80005a38:	690a                	ld	s2,128(sp)
    80005a3a:	610d                	addi	sp,sp,160
    80005a3c:	8082                	ret
    end_op();
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	7e0080e7          	jalr	2016(ra) # 8000421e <end_op>
    return -1;
    80005a46:	557d                	li	a0,-1
    80005a48:	b7ed                	j	80005a32 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a4a:	8526                	mv	a0,s1
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	fe2080e7          	jalr	-30(ra) # 80003a2e <iunlockput>
    end_op();
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	7ca080e7          	jalr	1994(ra) # 8000421e <end_op>
    return -1;
    80005a5c:	557d                	li	a0,-1
    80005a5e:	bfd1                	j	80005a32 <sys_chdir+0x7a>

0000000080005a60 <sys_exec>:

uint64
sys_exec(void)
{
    80005a60:	7145                	addi	sp,sp,-464
    80005a62:	e786                	sd	ra,456(sp)
    80005a64:	e3a2                	sd	s0,448(sp)
    80005a66:	ff26                	sd	s1,440(sp)
    80005a68:	fb4a                	sd	s2,432(sp)
    80005a6a:	f74e                	sd	s3,424(sp)
    80005a6c:	f352                	sd	s4,416(sp)
    80005a6e:	ef56                	sd	s5,408(sp)
    80005a70:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a72:	08000613          	li	a2,128
    80005a76:	f4040593          	addi	a1,s0,-192
    80005a7a:	4501                	li	a0,0
    80005a7c:	ffffd097          	auipc	ra,0xffffd
    80005a80:	1dc080e7          	jalr	476(ra) # 80002c58 <argstr>
    return -1;
    80005a84:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a86:	0c054a63          	bltz	a0,80005b5a <sys_exec+0xfa>
    80005a8a:	e3840593          	addi	a1,s0,-456
    80005a8e:	4505                	li	a0,1
    80005a90:	ffffd097          	auipc	ra,0xffffd
    80005a94:	1a6080e7          	jalr	422(ra) # 80002c36 <argaddr>
    80005a98:	0c054163          	bltz	a0,80005b5a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a9c:	10000613          	li	a2,256
    80005aa0:	4581                	li	a1,0
    80005aa2:	e4040513          	addi	a0,s0,-448
    80005aa6:	ffffb097          	auipc	ra,0xffffb
    80005aaa:	23a080e7          	jalr	570(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005aae:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ab2:	89a6                	mv	s3,s1
    80005ab4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ab6:	02000a13          	li	s4,32
    80005aba:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005abe:	00391513          	slli	a0,s2,0x3
    80005ac2:	e3040593          	addi	a1,s0,-464
    80005ac6:	e3843783          	ld	a5,-456(s0)
    80005aca:	953e                	add	a0,a0,a5
    80005acc:	ffffd097          	auipc	ra,0xffffd
    80005ad0:	0ae080e7          	jalr	174(ra) # 80002b7a <fetchaddr>
    80005ad4:	02054a63          	bltz	a0,80005b08 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ad8:	e3043783          	ld	a5,-464(s0)
    80005adc:	c3b9                	beqz	a5,80005b22 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ade:	ffffb097          	auipc	ra,0xffffb
    80005ae2:	016080e7          	jalr	22(ra) # 80000af4 <kalloc>
    80005ae6:	85aa                	mv	a1,a0
    80005ae8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005aec:	cd11                	beqz	a0,80005b08 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005aee:	6605                	lui	a2,0x1
    80005af0:	e3043503          	ld	a0,-464(s0)
    80005af4:	ffffd097          	auipc	ra,0xffffd
    80005af8:	0d8080e7          	jalr	216(ra) # 80002bcc <fetchstr>
    80005afc:	00054663          	bltz	a0,80005b08 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b00:	0905                	addi	s2,s2,1
    80005b02:	09a1                	addi	s3,s3,8
    80005b04:	fb491be3          	bne	s2,s4,80005aba <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b08:	10048913          	addi	s2,s1,256
    80005b0c:	6088                	ld	a0,0(s1)
    80005b0e:	c529                	beqz	a0,80005b58 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b10:	ffffb097          	auipc	ra,0xffffb
    80005b14:	ee8080e7          	jalr	-280(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b18:	04a1                	addi	s1,s1,8
    80005b1a:	ff2499e3          	bne	s1,s2,80005b0c <sys_exec+0xac>
  return -1;
    80005b1e:	597d                	li	s2,-1
    80005b20:	a82d                	j	80005b5a <sys_exec+0xfa>
      argv[i] = 0;
    80005b22:	0a8e                	slli	s5,s5,0x3
    80005b24:	fc040793          	addi	a5,s0,-64
    80005b28:	9abe                	add	s5,s5,a5
    80005b2a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b2e:	e4040593          	addi	a1,s0,-448
    80005b32:	f4040513          	addi	a0,s0,-192
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	194080e7          	jalr	404(ra) # 80004cca <exec>
    80005b3e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b40:	10048993          	addi	s3,s1,256
    80005b44:	6088                	ld	a0,0(s1)
    80005b46:	c911                	beqz	a0,80005b5a <sys_exec+0xfa>
    kfree(argv[i]);
    80005b48:	ffffb097          	auipc	ra,0xffffb
    80005b4c:	eb0080e7          	jalr	-336(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b50:	04a1                	addi	s1,s1,8
    80005b52:	ff3499e3          	bne	s1,s3,80005b44 <sys_exec+0xe4>
    80005b56:	a011                	j	80005b5a <sys_exec+0xfa>
  return -1;
    80005b58:	597d                	li	s2,-1
}
    80005b5a:	854a                	mv	a0,s2
    80005b5c:	60be                	ld	ra,456(sp)
    80005b5e:	641e                	ld	s0,448(sp)
    80005b60:	74fa                	ld	s1,440(sp)
    80005b62:	795a                	ld	s2,432(sp)
    80005b64:	79ba                	ld	s3,424(sp)
    80005b66:	7a1a                	ld	s4,416(sp)
    80005b68:	6afa                	ld	s5,408(sp)
    80005b6a:	6179                	addi	sp,sp,464
    80005b6c:	8082                	ret

0000000080005b6e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b6e:	7139                	addi	sp,sp,-64
    80005b70:	fc06                	sd	ra,56(sp)
    80005b72:	f822                	sd	s0,48(sp)
    80005b74:	f426                	sd	s1,40(sp)
    80005b76:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b78:	ffffc097          	auipc	ra,0xffffc
    80005b7c:	e38080e7          	jalr	-456(ra) # 800019b0 <myproc>
    80005b80:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b82:	fd840593          	addi	a1,s0,-40
    80005b86:	4501                	li	a0,0
    80005b88:	ffffd097          	auipc	ra,0xffffd
    80005b8c:	0ae080e7          	jalr	174(ra) # 80002c36 <argaddr>
    return -1;
    80005b90:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b92:	0e054063          	bltz	a0,80005c72 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b96:	fc840593          	addi	a1,s0,-56
    80005b9a:	fd040513          	addi	a0,s0,-48
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	dfc080e7          	jalr	-516(ra) # 8000499a <pipealloc>
    return -1;
    80005ba6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ba8:	0c054563          	bltz	a0,80005c72 <sys_pipe+0x104>
  fd0 = -1;
    80005bac:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bb0:	fd043503          	ld	a0,-48(s0)
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	508080e7          	jalr	1288(ra) # 800050bc <fdalloc>
    80005bbc:	fca42223          	sw	a0,-60(s0)
    80005bc0:	08054c63          	bltz	a0,80005c58 <sys_pipe+0xea>
    80005bc4:	fc843503          	ld	a0,-56(s0)
    80005bc8:	fffff097          	auipc	ra,0xfffff
    80005bcc:	4f4080e7          	jalr	1268(ra) # 800050bc <fdalloc>
    80005bd0:	fca42023          	sw	a0,-64(s0)
    80005bd4:	06054863          	bltz	a0,80005c44 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bd8:	4691                	li	a3,4
    80005bda:	fc440613          	addi	a2,s0,-60
    80005bde:	fd843583          	ld	a1,-40(s0)
    80005be2:	68a8                	ld	a0,80(s1)
    80005be4:	ffffc097          	auipc	ra,0xffffc
    80005be8:	a8e080e7          	jalr	-1394(ra) # 80001672 <copyout>
    80005bec:	02054063          	bltz	a0,80005c0c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bf0:	4691                	li	a3,4
    80005bf2:	fc040613          	addi	a2,s0,-64
    80005bf6:	fd843583          	ld	a1,-40(s0)
    80005bfa:	0591                	addi	a1,a1,4
    80005bfc:	68a8                	ld	a0,80(s1)
    80005bfe:	ffffc097          	auipc	ra,0xffffc
    80005c02:	a74080e7          	jalr	-1420(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c06:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c08:	06055563          	bgez	a0,80005c72 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c0c:	fc442783          	lw	a5,-60(s0)
    80005c10:	07e9                	addi	a5,a5,26
    80005c12:	078e                	slli	a5,a5,0x3
    80005c14:	97a6                	add	a5,a5,s1
    80005c16:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c1a:	fc042503          	lw	a0,-64(s0)
    80005c1e:	0569                	addi	a0,a0,26
    80005c20:	050e                	slli	a0,a0,0x3
    80005c22:	9526                	add	a0,a0,s1
    80005c24:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c28:	fd043503          	ld	a0,-48(s0)
    80005c2c:	fffff097          	auipc	ra,0xfffff
    80005c30:	a3e080e7          	jalr	-1474(ra) # 8000466a <fileclose>
    fileclose(wf);
    80005c34:	fc843503          	ld	a0,-56(s0)
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	a32080e7          	jalr	-1486(ra) # 8000466a <fileclose>
    return -1;
    80005c40:	57fd                	li	a5,-1
    80005c42:	a805                	j	80005c72 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c44:	fc442783          	lw	a5,-60(s0)
    80005c48:	0007c863          	bltz	a5,80005c58 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c4c:	01a78513          	addi	a0,a5,26
    80005c50:	050e                	slli	a0,a0,0x3
    80005c52:	9526                	add	a0,a0,s1
    80005c54:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c58:	fd043503          	ld	a0,-48(s0)
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	a0e080e7          	jalr	-1522(ra) # 8000466a <fileclose>
    fileclose(wf);
    80005c64:	fc843503          	ld	a0,-56(s0)
    80005c68:	fffff097          	auipc	ra,0xfffff
    80005c6c:	a02080e7          	jalr	-1534(ra) # 8000466a <fileclose>
    return -1;
    80005c70:	57fd                	li	a5,-1
}
    80005c72:	853e                	mv	a0,a5
    80005c74:	70e2                	ld	ra,56(sp)
    80005c76:	7442                	ld	s0,48(sp)
    80005c78:	74a2                	ld	s1,40(sp)
    80005c7a:	6121                	addi	sp,sp,64
    80005c7c:	8082                	ret
	...

0000000080005c80 <kernelvec>:
    80005c80:	7111                	addi	sp,sp,-256
    80005c82:	e006                	sd	ra,0(sp)
    80005c84:	e40a                	sd	sp,8(sp)
    80005c86:	e80e                	sd	gp,16(sp)
    80005c88:	ec12                	sd	tp,24(sp)
    80005c8a:	f016                	sd	t0,32(sp)
    80005c8c:	f41a                	sd	t1,40(sp)
    80005c8e:	f81e                	sd	t2,48(sp)
    80005c90:	fc22                	sd	s0,56(sp)
    80005c92:	e0a6                	sd	s1,64(sp)
    80005c94:	e4aa                	sd	a0,72(sp)
    80005c96:	e8ae                	sd	a1,80(sp)
    80005c98:	ecb2                	sd	a2,88(sp)
    80005c9a:	f0b6                	sd	a3,96(sp)
    80005c9c:	f4ba                	sd	a4,104(sp)
    80005c9e:	f8be                	sd	a5,112(sp)
    80005ca0:	fcc2                	sd	a6,120(sp)
    80005ca2:	e146                	sd	a7,128(sp)
    80005ca4:	e54a                	sd	s2,136(sp)
    80005ca6:	e94e                	sd	s3,144(sp)
    80005ca8:	ed52                	sd	s4,152(sp)
    80005caa:	f156                	sd	s5,160(sp)
    80005cac:	f55a                	sd	s6,168(sp)
    80005cae:	f95e                	sd	s7,176(sp)
    80005cb0:	fd62                	sd	s8,184(sp)
    80005cb2:	e1e6                	sd	s9,192(sp)
    80005cb4:	e5ea                	sd	s10,200(sp)
    80005cb6:	e9ee                	sd	s11,208(sp)
    80005cb8:	edf2                	sd	t3,216(sp)
    80005cba:	f1f6                	sd	t4,224(sp)
    80005cbc:	f5fa                	sd	t5,232(sp)
    80005cbe:	f9fe                	sd	t6,240(sp)
    80005cc0:	d87fc0ef          	jal	ra,80002a46 <kerneltrap>
    80005cc4:	6082                	ld	ra,0(sp)
    80005cc6:	6122                	ld	sp,8(sp)
    80005cc8:	61c2                	ld	gp,16(sp)
    80005cca:	7282                	ld	t0,32(sp)
    80005ccc:	7322                	ld	t1,40(sp)
    80005cce:	73c2                	ld	t2,48(sp)
    80005cd0:	7462                	ld	s0,56(sp)
    80005cd2:	6486                	ld	s1,64(sp)
    80005cd4:	6526                	ld	a0,72(sp)
    80005cd6:	65c6                	ld	a1,80(sp)
    80005cd8:	6666                	ld	a2,88(sp)
    80005cda:	7686                	ld	a3,96(sp)
    80005cdc:	7726                	ld	a4,104(sp)
    80005cde:	77c6                	ld	a5,112(sp)
    80005ce0:	7866                	ld	a6,120(sp)
    80005ce2:	688a                	ld	a7,128(sp)
    80005ce4:	692a                	ld	s2,136(sp)
    80005ce6:	69ca                	ld	s3,144(sp)
    80005ce8:	6a6a                	ld	s4,152(sp)
    80005cea:	7a8a                	ld	s5,160(sp)
    80005cec:	7b2a                	ld	s6,168(sp)
    80005cee:	7bca                	ld	s7,176(sp)
    80005cf0:	7c6a                	ld	s8,184(sp)
    80005cf2:	6c8e                	ld	s9,192(sp)
    80005cf4:	6d2e                	ld	s10,200(sp)
    80005cf6:	6dce                	ld	s11,208(sp)
    80005cf8:	6e6e                	ld	t3,216(sp)
    80005cfa:	7e8e                	ld	t4,224(sp)
    80005cfc:	7f2e                	ld	t5,232(sp)
    80005cfe:	7fce                	ld	t6,240(sp)
    80005d00:	6111                	addi	sp,sp,256
    80005d02:	10200073          	sret
    80005d06:	00000013          	nop
    80005d0a:	00000013          	nop
    80005d0e:	0001                	nop

0000000080005d10 <timervec>:
    80005d10:	34051573          	csrrw	a0,mscratch,a0
    80005d14:	e10c                	sd	a1,0(a0)
    80005d16:	e510                	sd	a2,8(a0)
    80005d18:	e914                	sd	a3,16(a0)
    80005d1a:	6d0c                	ld	a1,24(a0)
    80005d1c:	7110                	ld	a2,32(a0)
    80005d1e:	6194                	ld	a3,0(a1)
    80005d20:	96b2                	add	a3,a3,a2
    80005d22:	e194                	sd	a3,0(a1)
    80005d24:	4589                	li	a1,2
    80005d26:	14459073          	csrw	sip,a1
    80005d2a:	6914                	ld	a3,16(a0)
    80005d2c:	6510                	ld	a2,8(a0)
    80005d2e:	610c                	ld	a1,0(a0)
    80005d30:	34051573          	csrrw	a0,mscratch,a0
    80005d34:	30200073          	mret
	...

0000000080005d3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d3a:	1141                	addi	sp,sp,-16
    80005d3c:	e422                	sd	s0,8(sp)
    80005d3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d40:	0c0007b7          	lui	a5,0xc000
    80005d44:	4705                	li	a4,1
    80005d46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d48:	c3d8                	sw	a4,4(a5)
}
    80005d4a:	6422                	ld	s0,8(sp)
    80005d4c:	0141                	addi	sp,sp,16
    80005d4e:	8082                	ret

0000000080005d50 <plicinithart>:

void
plicinithart(void)
{
    80005d50:	1141                	addi	sp,sp,-16
    80005d52:	e406                	sd	ra,8(sp)
    80005d54:	e022                	sd	s0,0(sp)
    80005d56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d58:	ffffc097          	auipc	ra,0xffffc
    80005d5c:	c2c080e7          	jalr	-980(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d60:	0085171b          	slliw	a4,a0,0x8
    80005d64:	0c0027b7          	lui	a5,0xc002
    80005d68:	97ba                	add	a5,a5,a4
    80005d6a:	40200713          	li	a4,1026
    80005d6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d72:	00d5151b          	slliw	a0,a0,0xd
    80005d76:	0c2017b7          	lui	a5,0xc201
    80005d7a:	953e                	add	a0,a0,a5
    80005d7c:	00052023          	sw	zero,0(a0)
}
    80005d80:	60a2                	ld	ra,8(sp)
    80005d82:	6402                	ld	s0,0(sp)
    80005d84:	0141                	addi	sp,sp,16
    80005d86:	8082                	ret

0000000080005d88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d88:	1141                	addi	sp,sp,-16
    80005d8a:	e406                	sd	ra,8(sp)
    80005d8c:	e022                	sd	s0,0(sp)
    80005d8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d90:	ffffc097          	auipc	ra,0xffffc
    80005d94:	bf4080e7          	jalr	-1036(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d98:	00d5179b          	slliw	a5,a0,0xd
    80005d9c:	0c201537          	lui	a0,0xc201
    80005da0:	953e                	add	a0,a0,a5
  return irq;
}
    80005da2:	4148                	lw	a0,4(a0)
    80005da4:	60a2                	ld	ra,8(sp)
    80005da6:	6402                	ld	s0,0(sp)
    80005da8:	0141                	addi	sp,sp,16
    80005daa:	8082                	ret

0000000080005dac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dac:	1101                	addi	sp,sp,-32
    80005dae:	ec06                	sd	ra,24(sp)
    80005db0:	e822                	sd	s0,16(sp)
    80005db2:	e426                	sd	s1,8(sp)
    80005db4:	1000                	addi	s0,sp,32
    80005db6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	bcc080e7          	jalr	-1076(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005dc0:	00d5151b          	slliw	a0,a0,0xd
    80005dc4:	0c2017b7          	lui	a5,0xc201
    80005dc8:	97aa                	add	a5,a5,a0
    80005dca:	c3c4                	sw	s1,4(a5)
}
    80005dcc:	60e2                	ld	ra,24(sp)
    80005dce:	6442                	ld	s0,16(sp)
    80005dd0:	64a2                	ld	s1,8(sp)
    80005dd2:	6105                	addi	sp,sp,32
    80005dd4:	8082                	ret

0000000080005dd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005dd6:	1141                	addi	sp,sp,-16
    80005dd8:	e406                	sd	ra,8(sp)
    80005dda:	e022                	sd	s0,0(sp)
    80005ddc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dde:	479d                	li	a5,7
    80005de0:	06a7c963          	blt	a5,a0,80005e52 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005de4:	0001d797          	auipc	a5,0x1d
    80005de8:	21c78793          	addi	a5,a5,540 # 80023000 <disk>
    80005dec:	00a78733          	add	a4,a5,a0
    80005df0:	6789                	lui	a5,0x2
    80005df2:	97ba                	add	a5,a5,a4
    80005df4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005df8:	e7ad                	bnez	a5,80005e62 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005dfa:	00451793          	slli	a5,a0,0x4
    80005dfe:	0001f717          	auipc	a4,0x1f
    80005e02:	20270713          	addi	a4,a4,514 # 80025000 <disk+0x2000>
    80005e06:	6314                	ld	a3,0(a4)
    80005e08:	96be                	add	a3,a3,a5
    80005e0a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e0e:	6314                	ld	a3,0(a4)
    80005e10:	96be                	add	a3,a3,a5
    80005e12:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e16:	6314                	ld	a3,0(a4)
    80005e18:	96be                	add	a3,a3,a5
    80005e1a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e1e:	6318                	ld	a4,0(a4)
    80005e20:	97ba                	add	a5,a5,a4
    80005e22:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e26:	0001d797          	auipc	a5,0x1d
    80005e2a:	1da78793          	addi	a5,a5,474 # 80023000 <disk>
    80005e2e:	97aa                	add	a5,a5,a0
    80005e30:	6509                	lui	a0,0x2
    80005e32:	953e                	add	a0,a0,a5
    80005e34:	4785                	li	a5,1
    80005e36:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e3a:	0001f517          	auipc	a0,0x1f
    80005e3e:	1de50513          	addi	a0,a0,478 # 80025018 <disk+0x2018>
    80005e42:	ffffc097          	auipc	ra,0xffffc
    80005e46:	4bc080e7          	jalr	1212(ra) # 800022fe <wakeup>
}
    80005e4a:	60a2                	ld	ra,8(sp)
    80005e4c:	6402                	ld	s0,0(sp)
    80005e4e:	0141                	addi	sp,sp,16
    80005e50:	8082                	ret
    panic("free_desc 1");
    80005e52:	00003517          	auipc	a0,0x3
    80005e56:	95650513          	addi	a0,a0,-1706 # 800087a8 <syscalls+0x330>
    80005e5a:	ffffa097          	auipc	ra,0xffffa
    80005e5e:	6e4080e7          	jalr	1764(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005e62:	00003517          	auipc	a0,0x3
    80005e66:	95650513          	addi	a0,a0,-1706 # 800087b8 <syscalls+0x340>
    80005e6a:	ffffa097          	auipc	ra,0xffffa
    80005e6e:	6d4080e7          	jalr	1748(ra) # 8000053e <panic>

0000000080005e72 <virtio_disk_init>:
{
    80005e72:	1101                	addi	sp,sp,-32
    80005e74:	ec06                	sd	ra,24(sp)
    80005e76:	e822                	sd	s0,16(sp)
    80005e78:	e426                	sd	s1,8(sp)
    80005e7a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e7c:	00003597          	auipc	a1,0x3
    80005e80:	94c58593          	addi	a1,a1,-1716 # 800087c8 <syscalls+0x350>
    80005e84:	0001f517          	auipc	a0,0x1f
    80005e88:	2a450513          	addi	a0,a0,676 # 80025128 <disk+0x2128>
    80005e8c:	ffffb097          	auipc	ra,0xffffb
    80005e90:	cc8080e7          	jalr	-824(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e94:	100017b7          	lui	a5,0x10001
    80005e98:	4398                	lw	a4,0(a5)
    80005e9a:	2701                	sext.w	a4,a4
    80005e9c:	747277b7          	lui	a5,0x74727
    80005ea0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ea4:	0ef71163          	bne	a4,a5,80005f86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ea8:	100017b7          	lui	a5,0x10001
    80005eac:	43dc                	lw	a5,4(a5)
    80005eae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eb0:	4705                	li	a4,1
    80005eb2:	0ce79a63          	bne	a5,a4,80005f86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eb6:	100017b7          	lui	a5,0x10001
    80005eba:	479c                	lw	a5,8(a5)
    80005ebc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ebe:	4709                	li	a4,2
    80005ec0:	0ce79363          	bne	a5,a4,80005f86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005ec4:	100017b7          	lui	a5,0x10001
    80005ec8:	47d8                	lw	a4,12(a5)
    80005eca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ecc:	554d47b7          	lui	a5,0x554d4
    80005ed0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005ed4:	0af71963          	bne	a4,a5,80005f86 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed8:	100017b7          	lui	a5,0x10001
    80005edc:	4705                	li	a4,1
    80005ede:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ee0:	470d                	li	a4,3
    80005ee2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ee4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ee6:	c7ffe737          	lui	a4,0xc7ffe
    80005eea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005eee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ef0:	2701                	sext.w	a4,a4
    80005ef2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ef4:	472d                	li	a4,11
    80005ef6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ef8:	473d                	li	a4,15
    80005efa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005efc:	6705                	lui	a4,0x1
    80005efe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f00:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f04:	5bdc                	lw	a5,52(a5)
    80005f06:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f08:	c7d9                	beqz	a5,80005f96 <virtio_disk_init+0x124>
  if(max < NUM)
    80005f0a:	471d                	li	a4,7
    80005f0c:	08f77d63          	bgeu	a4,a5,80005fa6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f10:	100014b7          	lui	s1,0x10001
    80005f14:	47a1                	li	a5,8
    80005f16:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f18:	6609                	lui	a2,0x2
    80005f1a:	4581                	li	a1,0
    80005f1c:	0001d517          	auipc	a0,0x1d
    80005f20:	0e450513          	addi	a0,a0,228 # 80023000 <disk>
    80005f24:	ffffb097          	auipc	ra,0xffffb
    80005f28:	dbc080e7          	jalr	-580(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f2c:	0001d717          	auipc	a4,0x1d
    80005f30:	0d470713          	addi	a4,a4,212 # 80023000 <disk>
    80005f34:	00c75793          	srli	a5,a4,0xc
    80005f38:	2781                	sext.w	a5,a5
    80005f3a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f3c:	0001f797          	auipc	a5,0x1f
    80005f40:	0c478793          	addi	a5,a5,196 # 80025000 <disk+0x2000>
    80005f44:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005f46:	0001d717          	auipc	a4,0x1d
    80005f4a:	13a70713          	addi	a4,a4,314 # 80023080 <disk+0x80>
    80005f4e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005f50:	0001e717          	auipc	a4,0x1e
    80005f54:	0b070713          	addi	a4,a4,176 # 80024000 <disk+0x1000>
    80005f58:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f5a:	4705                	li	a4,1
    80005f5c:	00e78c23          	sb	a4,24(a5)
    80005f60:	00e78ca3          	sb	a4,25(a5)
    80005f64:	00e78d23          	sb	a4,26(a5)
    80005f68:	00e78da3          	sb	a4,27(a5)
    80005f6c:	00e78e23          	sb	a4,28(a5)
    80005f70:	00e78ea3          	sb	a4,29(a5)
    80005f74:	00e78f23          	sb	a4,30(a5)
    80005f78:	00e78fa3          	sb	a4,31(a5)
}
    80005f7c:	60e2                	ld	ra,24(sp)
    80005f7e:	6442                	ld	s0,16(sp)
    80005f80:	64a2                	ld	s1,8(sp)
    80005f82:	6105                	addi	sp,sp,32
    80005f84:	8082                	ret
    panic("could not find virtio disk");
    80005f86:	00003517          	auipc	a0,0x3
    80005f8a:	85250513          	addi	a0,a0,-1966 # 800087d8 <syscalls+0x360>
    80005f8e:	ffffa097          	auipc	ra,0xffffa
    80005f92:	5b0080e7          	jalr	1456(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005f96:	00003517          	auipc	a0,0x3
    80005f9a:	86250513          	addi	a0,a0,-1950 # 800087f8 <syscalls+0x380>
    80005f9e:	ffffa097          	auipc	ra,0xffffa
    80005fa2:	5a0080e7          	jalr	1440(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005fa6:	00003517          	auipc	a0,0x3
    80005faa:	87250513          	addi	a0,a0,-1934 # 80008818 <syscalls+0x3a0>
    80005fae:	ffffa097          	auipc	ra,0xffffa
    80005fb2:	590080e7          	jalr	1424(ra) # 8000053e <panic>

0000000080005fb6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fb6:	7159                	addi	sp,sp,-112
    80005fb8:	f486                	sd	ra,104(sp)
    80005fba:	f0a2                	sd	s0,96(sp)
    80005fbc:	eca6                	sd	s1,88(sp)
    80005fbe:	e8ca                	sd	s2,80(sp)
    80005fc0:	e4ce                	sd	s3,72(sp)
    80005fc2:	e0d2                	sd	s4,64(sp)
    80005fc4:	fc56                	sd	s5,56(sp)
    80005fc6:	f85a                	sd	s6,48(sp)
    80005fc8:	f45e                	sd	s7,40(sp)
    80005fca:	f062                	sd	s8,32(sp)
    80005fcc:	ec66                	sd	s9,24(sp)
    80005fce:	e86a                	sd	s10,16(sp)
    80005fd0:	1880                	addi	s0,sp,112
    80005fd2:	892a                	mv	s2,a0
    80005fd4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fd6:	00c52c83          	lw	s9,12(a0)
    80005fda:	001c9c9b          	slliw	s9,s9,0x1
    80005fde:	1c82                	slli	s9,s9,0x20
    80005fe0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fe4:	0001f517          	auipc	a0,0x1f
    80005fe8:	14450513          	addi	a0,a0,324 # 80025128 <disk+0x2128>
    80005fec:	ffffb097          	auipc	ra,0xffffb
    80005ff0:	bf8080e7          	jalr	-1032(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005ff4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005ff6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005ff8:	0001db97          	auipc	s7,0x1d
    80005ffc:	008b8b93          	addi	s7,s7,8 # 80023000 <disk>
    80006000:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006002:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006004:	8a4e                	mv	s4,s3
    80006006:	a051                	j	8000608a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006008:	00fb86b3          	add	a3,s7,a5
    8000600c:	96da                	add	a3,a3,s6
    8000600e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006012:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006014:	0207c563          	bltz	a5,8000603e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006018:	2485                	addiw	s1,s1,1
    8000601a:	0711                	addi	a4,a4,4
    8000601c:	25548063          	beq	s1,s5,8000625c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006020:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006022:	0001f697          	auipc	a3,0x1f
    80006026:	ff668693          	addi	a3,a3,-10 # 80025018 <disk+0x2018>
    8000602a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000602c:	0006c583          	lbu	a1,0(a3)
    80006030:	fde1                	bnez	a1,80006008 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006032:	2785                	addiw	a5,a5,1
    80006034:	0685                	addi	a3,a3,1
    80006036:	ff879be3          	bne	a5,s8,8000602c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000603a:	57fd                	li	a5,-1
    8000603c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000603e:	02905a63          	blez	s1,80006072 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006042:	f9042503          	lw	a0,-112(s0)
    80006046:	00000097          	auipc	ra,0x0
    8000604a:	d90080e7          	jalr	-624(ra) # 80005dd6 <free_desc>
      for(int j = 0; j < i; j++)
    8000604e:	4785                	li	a5,1
    80006050:	0297d163          	bge	a5,s1,80006072 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006054:	f9442503          	lw	a0,-108(s0)
    80006058:	00000097          	auipc	ra,0x0
    8000605c:	d7e080e7          	jalr	-642(ra) # 80005dd6 <free_desc>
      for(int j = 0; j < i; j++)
    80006060:	4789                	li	a5,2
    80006062:	0097d863          	bge	a5,s1,80006072 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006066:	f9842503          	lw	a0,-104(s0)
    8000606a:	00000097          	auipc	ra,0x0
    8000606e:	d6c080e7          	jalr	-660(ra) # 80005dd6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006072:	0001f597          	auipc	a1,0x1f
    80006076:	0b658593          	addi	a1,a1,182 # 80025128 <disk+0x2128>
    8000607a:	0001f517          	auipc	a0,0x1f
    8000607e:	f9e50513          	addi	a0,a0,-98 # 80025018 <disk+0x2018>
    80006082:	ffffc097          	auipc	ra,0xffffc
    80006086:	0f0080e7          	jalr	240(ra) # 80002172 <sleep>
  for(int i = 0; i < 3; i++){
    8000608a:	f9040713          	addi	a4,s0,-112
    8000608e:	84ce                	mv	s1,s3
    80006090:	bf41                	j	80006020 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006092:	20058713          	addi	a4,a1,512
    80006096:	00471693          	slli	a3,a4,0x4
    8000609a:	0001d717          	auipc	a4,0x1d
    8000609e:	f6670713          	addi	a4,a4,-154 # 80023000 <disk>
    800060a2:	9736                	add	a4,a4,a3
    800060a4:	4685                	li	a3,1
    800060a6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800060aa:	20058713          	addi	a4,a1,512
    800060ae:	00471693          	slli	a3,a4,0x4
    800060b2:	0001d717          	auipc	a4,0x1d
    800060b6:	f4e70713          	addi	a4,a4,-178 # 80023000 <disk>
    800060ba:	9736                	add	a4,a4,a3
    800060bc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800060c0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800060c4:	7679                	lui	a2,0xffffe
    800060c6:	963e                	add	a2,a2,a5
    800060c8:	0001f697          	auipc	a3,0x1f
    800060cc:	f3868693          	addi	a3,a3,-200 # 80025000 <disk+0x2000>
    800060d0:	6298                	ld	a4,0(a3)
    800060d2:	9732                	add	a4,a4,a2
    800060d4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060d6:	6298                	ld	a4,0(a3)
    800060d8:	9732                	add	a4,a4,a2
    800060da:	4541                	li	a0,16
    800060dc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060de:	6298                	ld	a4,0(a3)
    800060e0:	9732                	add	a4,a4,a2
    800060e2:	4505                	li	a0,1
    800060e4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800060e8:	f9442703          	lw	a4,-108(s0)
    800060ec:	6288                	ld	a0,0(a3)
    800060ee:	962a                	add	a2,a2,a0
    800060f0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060f4:	0712                	slli	a4,a4,0x4
    800060f6:	6290                	ld	a2,0(a3)
    800060f8:	963a                	add	a2,a2,a4
    800060fa:	05890513          	addi	a0,s2,88
    800060fe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006100:	6294                	ld	a3,0(a3)
    80006102:	96ba                	add	a3,a3,a4
    80006104:	40000613          	li	a2,1024
    80006108:	c690                	sw	a2,8(a3)
  if(write)
    8000610a:	140d0063          	beqz	s10,8000624a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000610e:	0001f697          	auipc	a3,0x1f
    80006112:	ef26b683          	ld	a3,-270(a3) # 80025000 <disk+0x2000>
    80006116:	96ba                	add	a3,a3,a4
    80006118:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000611c:	0001d817          	auipc	a6,0x1d
    80006120:	ee480813          	addi	a6,a6,-284 # 80023000 <disk>
    80006124:	0001f517          	auipc	a0,0x1f
    80006128:	edc50513          	addi	a0,a0,-292 # 80025000 <disk+0x2000>
    8000612c:	6114                	ld	a3,0(a0)
    8000612e:	96ba                	add	a3,a3,a4
    80006130:	00c6d603          	lhu	a2,12(a3)
    80006134:	00166613          	ori	a2,a2,1
    80006138:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000613c:	f9842683          	lw	a3,-104(s0)
    80006140:	6110                	ld	a2,0(a0)
    80006142:	9732                	add	a4,a4,a2
    80006144:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006148:	20058613          	addi	a2,a1,512
    8000614c:	0612                	slli	a2,a2,0x4
    8000614e:	9642                	add	a2,a2,a6
    80006150:	577d                	li	a4,-1
    80006152:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006156:	00469713          	slli	a4,a3,0x4
    8000615a:	6114                	ld	a3,0(a0)
    8000615c:	96ba                	add	a3,a3,a4
    8000615e:	03078793          	addi	a5,a5,48
    80006162:	97c2                	add	a5,a5,a6
    80006164:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006166:	611c                	ld	a5,0(a0)
    80006168:	97ba                	add	a5,a5,a4
    8000616a:	4685                	li	a3,1
    8000616c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000616e:	611c                	ld	a5,0(a0)
    80006170:	97ba                	add	a5,a5,a4
    80006172:	4809                	li	a6,2
    80006174:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006178:	611c                	ld	a5,0(a0)
    8000617a:	973e                	add	a4,a4,a5
    8000617c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006180:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006184:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006188:	6518                	ld	a4,8(a0)
    8000618a:	00275783          	lhu	a5,2(a4)
    8000618e:	8b9d                	andi	a5,a5,7
    80006190:	0786                	slli	a5,a5,0x1
    80006192:	97ba                	add	a5,a5,a4
    80006194:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006198:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000619c:	6518                	ld	a4,8(a0)
    8000619e:	00275783          	lhu	a5,2(a4)
    800061a2:	2785                	addiw	a5,a5,1
    800061a4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061a8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061ac:	100017b7          	lui	a5,0x10001
    800061b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061b4:	00492703          	lw	a4,4(s2)
    800061b8:	4785                	li	a5,1
    800061ba:	02f71163          	bne	a4,a5,800061dc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800061be:	0001f997          	auipc	s3,0x1f
    800061c2:	f6a98993          	addi	s3,s3,-150 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800061c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061c8:	85ce                	mv	a1,s3
    800061ca:	854a                	mv	a0,s2
    800061cc:	ffffc097          	auipc	ra,0xffffc
    800061d0:	fa6080e7          	jalr	-90(ra) # 80002172 <sleep>
  while(b->disk == 1) {
    800061d4:	00492783          	lw	a5,4(s2)
    800061d8:	fe9788e3          	beq	a5,s1,800061c8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800061dc:	f9042903          	lw	s2,-112(s0)
    800061e0:	20090793          	addi	a5,s2,512
    800061e4:	00479713          	slli	a4,a5,0x4
    800061e8:	0001d797          	auipc	a5,0x1d
    800061ec:	e1878793          	addi	a5,a5,-488 # 80023000 <disk>
    800061f0:	97ba                	add	a5,a5,a4
    800061f2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800061f6:	0001f997          	auipc	s3,0x1f
    800061fa:	e0a98993          	addi	s3,s3,-502 # 80025000 <disk+0x2000>
    800061fe:	00491713          	slli	a4,s2,0x4
    80006202:	0009b783          	ld	a5,0(s3)
    80006206:	97ba                	add	a5,a5,a4
    80006208:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000620c:	854a                	mv	a0,s2
    8000620e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006212:	00000097          	auipc	ra,0x0
    80006216:	bc4080e7          	jalr	-1084(ra) # 80005dd6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000621a:	8885                	andi	s1,s1,1
    8000621c:	f0ed                	bnez	s1,800061fe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000621e:	0001f517          	auipc	a0,0x1f
    80006222:	f0a50513          	addi	a0,a0,-246 # 80025128 <disk+0x2128>
    80006226:	ffffb097          	auipc	ra,0xffffb
    8000622a:	a72080e7          	jalr	-1422(ra) # 80000c98 <release>
}
    8000622e:	70a6                	ld	ra,104(sp)
    80006230:	7406                	ld	s0,96(sp)
    80006232:	64e6                	ld	s1,88(sp)
    80006234:	6946                	ld	s2,80(sp)
    80006236:	69a6                	ld	s3,72(sp)
    80006238:	6a06                	ld	s4,64(sp)
    8000623a:	7ae2                	ld	s5,56(sp)
    8000623c:	7b42                	ld	s6,48(sp)
    8000623e:	7ba2                	ld	s7,40(sp)
    80006240:	7c02                	ld	s8,32(sp)
    80006242:	6ce2                	ld	s9,24(sp)
    80006244:	6d42                	ld	s10,16(sp)
    80006246:	6165                	addi	sp,sp,112
    80006248:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000624a:	0001f697          	auipc	a3,0x1f
    8000624e:	db66b683          	ld	a3,-586(a3) # 80025000 <disk+0x2000>
    80006252:	96ba                	add	a3,a3,a4
    80006254:	4609                	li	a2,2
    80006256:	00c69623          	sh	a2,12(a3)
    8000625a:	b5c9                	j	8000611c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000625c:	f9042583          	lw	a1,-112(s0)
    80006260:	20058793          	addi	a5,a1,512
    80006264:	0792                	slli	a5,a5,0x4
    80006266:	0001d517          	auipc	a0,0x1d
    8000626a:	e4250513          	addi	a0,a0,-446 # 800230a8 <disk+0xa8>
    8000626e:	953e                	add	a0,a0,a5
  if(write)
    80006270:	e20d11e3          	bnez	s10,80006092 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006274:	20058713          	addi	a4,a1,512
    80006278:	00471693          	slli	a3,a4,0x4
    8000627c:	0001d717          	auipc	a4,0x1d
    80006280:	d8470713          	addi	a4,a4,-636 # 80023000 <disk>
    80006284:	9736                	add	a4,a4,a3
    80006286:	0a072423          	sw	zero,168(a4)
    8000628a:	b505                	j	800060aa <virtio_disk_rw+0xf4>

000000008000628c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000628c:	1101                	addi	sp,sp,-32
    8000628e:	ec06                	sd	ra,24(sp)
    80006290:	e822                	sd	s0,16(sp)
    80006292:	e426                	sd	s1,8(sp)
    80006294:	e04a                	sd	s2,0(sp)
    80006296:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006298:	0001f517          	auipc	a0,0x1f
    8000629c:	e9050513          	addi	a0,a0,-368 # 80025128 <disk+0x2128>
    800062a0:	ffffb097          	auipc	ra,0xffffb
    800062a4:	944080e7          	jalr	-1724(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062a8:	10001737          	lui	a4,0x10001
    800062ac:	533c                	lw	a5,96(a4)
    800062ae:	8b8d                	andi	a5,a5,3
    800062b0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062b2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062b6:	0001f797          	auipc	a5,0x1f
    800062ba:	d4a78793          	addi	a5,a5,-694 # 80025000 <disk+0x2000>
    800062be:	6b94                	ld	a3,16(a5)
    800062c0:	0207d703          	lhu	a4,32(a5)
    800062c4:	0026d783          	lhu	a5,2(a3)
    800062c8:	06f70163          	beq	a4,a5,8000632a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062cc:	0001d917          	auipc	s2,0x1d
    800062d0:	d3490913          	addi	s2,s2,-716 # 80023000 <disk>
    800062d4:	0001f497          	auipc	s1,0x1f
    800062d8:	d2c48493          	addi	s1,s1,-724 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800062dc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062e0:	6898                	ld	a4,16(s1)
    800062e2:	0204d783          	lhu	a5,32(s1)
    800062e6:	8b9d                	andi	a5,a5,7
    800062e8:	078e                	slli	a5,a5,0x3
    800062ea:	97ba                	add	a5,a5,a4
    800062ec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062ee:	20078713          	addi	a4,a5,512
    800062f2:	0712                	slli	a4,a4,0x4
    800062f4:	974a                	add	a4,a4,s2
    800062f6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800062fa:	e731                	bnez	a4,80006346 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062fc:	20078793          	addi	a5,a5,512
    80006300:	0792                	slli	a5,a5,0x4
    80006302:	97ca                	add	a5,a5,s2
    80006304:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006306:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000630a:	ffffc097          	auipc	ra,0xffffc
    8000630e:	ff4080e7          	jalr	-12(ra) # 800022fe <wakeup>

    disk.used_idx += 1;
    80006312:	0204d783          	lhu	a5,32(s1)
    80006316:	2785                	addiw	a5,a5,1
    80006318:	17c2                	slli	a5,a5,0x30
    8000631a:	93c1                	srli	a5,a5,0x30
    8000631c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006320:	6898                	ld	a4,16(s1)
    80006322:	00275703          	lhu	a4,2(a4)
    80006326:	faf71be3          	bne	a4,a5,800062dc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000632a:	0001f517          	auipc	a0,0x1f
    8000632e:	dfe50513          	addi	a0,a0,-514 # 80025128 <disk+0x2128>
    80006332:	ffffb097          	auipc	ra,0xffffb
    80006336:	966080e7          	jalr	-1690(ra) # 80000c98 <release>
}
    8000633a:	60e2                	ld	ra,24(sp)
    8000633c:	6442                	ld	s0,16(sp)
    8000633e:	64a2                	ld	s1,8(sp)
    80006340:	6902                	ld	s2,0(sp)
    80006342:	6105                	addi	sp,sp,32
    80006344:	8082                	ret
      panic("virtio_disk_intr status");
    80006346:	00002517          	auipc	a0,0x2
    8000634a:	4f250513          	addi	a0,a0,1266 # 80008838 <syscalls+0x3c0>
    8000634e:	ffffa097          	auipc	ra,0xffffa
    80006352:	1f0080e7          	jalr	496(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
