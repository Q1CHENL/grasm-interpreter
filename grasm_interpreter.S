.intel_syntax noprefix
.global grasm_interpreter
.text

//Signature: uint64_t grasm_interpreter(struct grasm_state* state, size_t len, uint8_t prog[len]);
//struct grasm_state { uint64_t ip, acc, r0, r1, r2, r3, r4, r5, r6, r7; }; 64-bit registers
//rdi: state
//rsi: len
//rdx: prog address

//All instructions ---> prog
//prog contains e.g. 0x01 (00 00 00 01) for stop

//The number of instructions ---> len
//state is just the current state of the program/system

//example: add 0x01234567 ->    20        67     45 23 01 00 00 00 00 ---> is passed byte by byte on prog
//                           00010000  01100111 ......
//                             add        0x1234567


grasm_interpreter:
//mov rax, qword ptr [0]
  //e.g only one instruction add in prog
  push r12
  push r13
  push r14
  push r15
  push rbx

  
  mov r14, rsi //len to r14
  mov r15, rdi //state to r15
  mov rbx, rdx //prog to rbx
  //add r14, qword ptr [r15] //set r14 to final address indicated by len
  //Out-of-Bounds-Zugriff
  
  
  execute_next:
  xor r11, r11
  mov r11b, byte ptr [rbx] 
  mov r13, qword ptr [r15]//test
  cmp qword ptr [r15], r14
  jge end
  //jge out_of_bound_access
  
  mov r12,  qword ptr [r15] //load ip to r12 
  mov r11b, 10//test
  mov r11b, byte ptr [rbx + r12]//test
  mov r13b, byte ptr [rbx + r12] //load the program(encoding) into r13b
  mov r11b, byte ptr [rbx + 1]//test

  //cmp r13b, 0x11
  //je test
  
  
  //compare the value of r13b?
  //STOP
  cmp r13b, 0x01
  je stop

  //NOP
  cmp r13b, 0x0f
  je noop

  //SET
  cmp r13b, 0x10  
  je set
  cmp r13b, 0x18
  je set_rx

  //CPY
  cmp r13b, 0x11  
  je cpy_rx
  cmp r13b, 0x19
  je cpy_rx_ry

  //ADD  
  cmp r13b, 0x20
  je add_
  cmp r13b, 0x21
  je add_rx
  cmp r13b, 0x28
  je add_rx_imm
  cmp r13b, 0x29
  je add_rx_ry

  //SUB  
  cmp r13b, 0x22
  je sub_
  cmp r13b, 0x23
  je sub_rx
  cmp r13b, 0x2a
  je sub_rx_imm
  cmp r13b, 0x2b
  je sub_rx_ry

  //MUL
  cmp r13b, 0x24
  je mul_
  cmp r13b, 0x25
  je mul_rx
  cmp r13b, 0x2c
  je mul_rx_imm
  cmp r13b, 0x2d
  je mul_rx_ry

  //XCHG
  cmp r13b, 0x26
  je xchg_rx
  cmp r13b, 0x2e
  je xchg_rx_ry

  //AND
  cmp r13b, 0x30
  je and_
  cmp r13b, 0x31
  je and_rx_imm
  cmp r13b, 0x32
  je and_rx
  cmp r13b, 0x33
  je and_rx_ry

  //OR
  cmp r13b, 0x34
  je or_
  cmp r13b, 0x35
  je or_rx_imm
  cmp r13b, 0x36
  je or_rx
  cmp r13b, 0x37
  je or_rx_ry

  //XOR
  cmp r13b, 0x38
  je  xor_
  cmp r13b, 0x39
  je xor_rx_imm
  cmp r13b, 0x3a
  je xor_rx
  cmp r13b, 0x3b
  je xor_rx_ry

  //NOT
  cmp r13b, 0x3c
  je not_
  cmp r13b, 0x3d
  je not_rx
  cmp r13b, 0x3e
  je not_rx_ry

  //CMP
  cmp r13b, 0x40
  je cmp_rx_imm
  cmp r13b, 0x41
  je cmp_rx_ry
  
  //TST
  cmp r13b, 0x42
  je tst_rx_imm
  cmp r13b, 0x43
  je tst_rx_ry

  //SHR
  cmp r13b, 0x50
  je shr_
  cmp r13b, 0x51
  je shr_rx_imm
  cmp r13b, 0x52
  je shr_rx
  cmp r13b, 0x53
  je shr_rx_ry

  //SHL
  cmp r13b, 0x54
  je shl_
  cmp r13b, 0x55
  je shl_rx_imm
  cmp r13b, 0x56
  je shl_rx
  cmp r13b, 0x57
  je shl_rx_ry

  //LD
  cmp r13b, 0x60
  je ld_
  cmp r13b, 0x61
  je ld_rx_imm
  cmp r13b, 0x62
  je ld_rx
  cmp r13b, 0x63
  je ld_rx_ry  

  //ST
  cmp r13b, 0x64
  je st_
  cmp r13b, 0x65
  je st_rx_imm
  cmp r13b, 0x66
  je st_rx
  cmp r13b, 0x67
  je st_rx_ry  

  //GO
  cmp r13b, 0x70
  je go_
  cmp r13b, 0x71
  je go_rx

  //GR
  cmp r13b, 0x72
  je gr_

  //J(R)Z
  cmp r13b, 0x73
  je jz_
  cmp r13b, 0x74
  je jz_rx
  cmp r13b, 0x75
  je jrz_

  //ECALL
  cmp r13b, 0x80
  je ecall_
  cmp r13b, 0x81
  je ecall_rx

  //opcode unknown or incomplete  
  op_unknown_incomplete:
  mov rax, -1
  jmp end_stack
  ret

  stop:
  inc qword ptr [r15]
  jmp end

  noop:
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next
  

  set: //set	uint64_t	0x10 <imm>	ac = imm
  inc qword ptr [r15] //inc ip to get the 8 byte immediate

  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load 8 bytes immediate from ip
  //bswap rax //convert little endian to big endian
  mov qword ptr [r15 + 8], rax //store the immediate to acc
  add qword ptr [r15], 8 //inc ip for executing next instruction
  jmp execute_next //do i need to set ip here?

  set_rx: //set rX	uint64_t	0x18 <0X> <imm>	rX = imm
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load 1 byte register to r9
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load 8 bytes from ip to rax
  //bswap rax
  
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  //Fehler Behandlung: if X of rX <0 or >7
  cmp r9b, 7
  jg out_of_bound_access_two_args
  cmp r9b, 0
  jl out_of_bound_access_two_args

  add r9, 2 // e.g. for r0: [r15 + 8*2]
  mov qword ptr [r15 + r9*8], rax //store the immediate to rX
  add qword ptr [r15], 8 //inc ip for executing next instruction
  jmp execute_next

  cpy_rx: //cpy rX	--	0x11 <0X>	ac = rX
  //cmp r14, 3
  //je test
  inc qword ptr [r15] //inc ip to get the 1 byte register
  
  cmp qword ptr [r15], r14
  jge cpy_rx_incomplete

  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the register to r9

  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  //Fehler Behandlung: if X of rX <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  add r9, 2
  mov rax, [r15 + r9*8] //load the value of rX to rax
  mov qword ptr [r15 + 8], rax //store the value in rX to acc
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next

  cpy_rx_incomplete:
  dec qword ptr [r15]
  jmp op_unknown_incomplete
 
  

  //   set: //set	uint64_t	0x10 <imm>	ac = imm
  // inc qword ptr [r15] //inc ip to get the 8 byte immediate
  // cmp qword ptr [r15], r14
  // jge out_of_bound_access
  // mov r8, qword ptr [r15] //load the value of ip to r8
  // add qword ptr [r15], 8 //inc ip for executing next instruction
  // cmp qword ptr [r15], r14
  // jge out_of_bound_access
  // mov rax, qword ptr [rbx + r8] //load 8 bytes from ip
  // bswap rax //convert little endian to big endian
  // mov qword ptr [r15 + 8], rax //store the immediate to acc
  // jmp execute_next //do i need to set ip here?
  

  cpy_rx_ry: //cpy rX rY	--	0x19 <XY>	rX = rY
  xor r10, r10
  inc qword ptr [r15] //inc ip to get the 2 register in 1 byte
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 2 registers <XY> to r9b
  mov r10b, r9b //store register X to r10b

  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  shr r10b, 4 //only keep low 4 bit, high 4 bit is "don't care"
  and r10b, 0x0f
  //Fehler Behandlung: if X of rX <0 or >7
  cmp r10b, 7
  jg out_of_bound_access
  cmp r10b, 0
  jl out_of_bound_access

  add r10b, 2
  add r9b, 2
  mov r13, qword ptr [r15 + r9*8]//TEST
  mov rax, qword ptr [r15 + r9*8] //mov content of rY to rax
  mov [r15 + r10*8], rax //mov rX, which is in rax, to rX
  mov r13, qword ptr [r15 + r10*8]//TEST
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next 



  add_: //add	uint64_t	0x20 <imm>	ac += imm
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the immediate to rax
  //bswap rax //convert little endian to big endian
  add qword ptr [r15 + 8], rax //store the immediate to acc
  add qword ptr [r15], 8 //inc ip for executing next instruction
  jmp execute_next


  add_rx: //add rX	--	0x21 <0X>	ac += rX
  inc qword ptr [r15] //inc ip to get the 1 byte register <0X>
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the register <0X> to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"

  //Fehler Behandlung: if X of rX <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  add r9b, 2
  mov rax, qword ptr [r15 + r9*8] //mov content of rX to rax
  add qword ptr [r15 + 8], rax //add value of rX to acc
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next


  add_rx_imm: //add rX	uint64_t	0x28 <0X> <imm>	rX += imm
  inc qword ptr [r15] //inc ip to get the 1 byte register <0X>
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the register <0X> to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load value of ip to r8
  mov rax, qword ptr [rbx + r8] //load 8 byte immediate to rax
  //bswap rax //convert little endian to big endian  
  
  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access_two_args
  cmp r9b, 0
  jl out_of_bound_access_two_args

  add r9b, 2
  add qword ptr [r15 + r9*8], rax
  add qword ptr [r15], 8 //add 8 to ip for executing next instruction
  jmp execute_next


  add_rx_ry: //add rX rY	--	0x29 <XY>	rX += rY
  xor r10, r10
  inc qword ptr [r15] //inc ip to get the 2 register in 1 byte
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 2 registers <XY> to r9
  xor r10, r10 //clear r10 preparing to hold register X 
  mov r10b, r9b //store register X to r10b

  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  shr r10b, 4 //only keep low 4 bit, high 4 bit is "don't care"
  and r10b, 0x0f
  //Fehler Behandlung: if X of rX <0 or >7
  cmp r10b, 7
  jg out_of_bound_access
  cmp r10b, 0
  jl out_of_bound_access

  add r10b, 2
  add r9b, 2
  mov rax, qword ptr [r15 + r9*8] //mov content of rY to rax
  add qword ptr [r15 + r10*8], rax //add rY, which is in rax, to rX
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next 



  sub_: //sub	uint64_t	0x22 <imm>	ac -= imm
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian
  sub qword ptr [r15 + 8], rax //sub rax from acc
  add qword ptr [r15], 8 //add 8 to ip for executing next instruction
  jmp execute_next


  sub_rx: //sub rX	--	0x23 <0X>	ac -= rX
  inc qword ptr [r15] //inc ip to get the 1 byte register <0X>
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the register <0X> to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"

  //Fehler Behandlung: if X of rX <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  add r9b, 2
  mov rax, qword ptr [r15 + r9*8] //mov content of rX to rax
  sub qword ptr [r15 + 8], rax //sub value of rX from acc
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next


  sub_rx_imm: //sub rX	uint64_t	0x2a <0X> <imm>	rX -= imm
  mov r13, qword ptr [r15 + 24]//test
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 1 byte register to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access_two_args
  cmp r9b, 0
  jl out_of_bound_access_two_args

  add r9b, 2
  mov r13, qword ptr [r15 + r9*8]//TEST
  sub qword ptr [r15 + r9*8], rax
  mov r13, qword ptr [r15 + r9*8]//TEST
  add qword ptr [r15], 8 //add 8 to ip for executing next instruction
  jmp execute_next


  sub_rx_ry: //sub rX rY	--	0x2b <XY>	rX -= rY
  xor r10, r10
  inc qword ptr [r15] //inc ip to get the 2 register in 1 byte
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 2 registers <XY> to r9
  xor r10, r10 //clear r10 preparing to hold register X 
  mov r10b, r9b //store register X to r10b

  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  shr r10b, 4 //only keep low 4 bit, high 4 bit is "don't care"
  and r10b, 0x0f
  //Fehler Behandlung: if X of rX <0 or >7
  cmp r10b, 7
  jg out_of_bound_access
  cmp r10b, 0
  jl out_of_bound_access

  add r10b, 2
  add r9b, 2
  mov rax, qword ptr [r15 + r9*8] //mov content of rY to rax
  sub qword ptr [r15 + r10*8], rax //sub rY, which is in rax, from rX
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next 



  mul_: //mul	uint64_t	0x24 <imm>	ac *= imm
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian
  mul qword ptr [r15 + 8] //multiply by immediate
  mov qword ptr [r15 + 8], rax //store result to acc
  add qword ptr [r15], 8 //inc ip for executing next instruction
  cmp qword ptr [r15], r14
  jge out_of_bound_access_8_byte
  jmp execute_next


  mul_rx: //mul rX	--	0x25 <0X>	ac *= rX
  inc qword ptr [r15] //inc ip to get the 1 byte register <0X>
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the register <0X> to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"

  //Fehler Behandlung: if X of rX <0 or >7
  cmp r9, 7
  jg out_of_bound_access
  cmp r9, 0
  jl out_of_bound_access

  add r9, 2
  mov rax, qword ptr [r15 + r9*8] //mov content of rX to rax
  mul qword ptr [r15 + 8] // rX * acc
  mov qword ptr [r15 + 8], rax //store result to acc
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next
  
  mul_rx_imm: //mul rX	uint64_t	0x2c <0X> <imm>	rX *= imm
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 1 byte register to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9, 7
  jg out_of_bound_access_two_args
  cmp r9, 0
  jl out_of_bound_access_two_args

  add r9, 2
  mul qword ptr [r15 + r9*8] //rX * imm
  mov qword ptr [r15 + r9*8], rax //store the result to rX
  add qword ptr [r15], 8 //add 8 to ip for executing next instruction
  jmp execute_next


  mul_rx_ry: //mul rX rY	--	0x2d <XY>	rX *= rY
  xor r10, r10 //clear r10 preparing to hold register X 
  inc qword ptr [r15] //inc ip to get the 2 register in 1 byte
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 2 registers <XY> to r9
  
  mov r10b, r9b //store register X to r10b

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  shr r10b, 4 //only keep low 4 bit, high 4 bit is "don't care"
  and r10b, 0x0f
  //Fehler Behandlung: if X of rX <0 or >7
  cmp r10b, 7
  jg out_of_bound_access
  cmp r10b, 0
  jl out_of_bound_access

  add r10, 2
  add r9, 2
  mov rax, qword ptr [r15 + r9*8] //mov content of rY to rax

  mov r13, qword ptr [r15 + r10*8] //move rX to r13 //TEST

  mul qword ptr [r15 + r10*8] //rX * rY
  mov qword ptr [r15 + r10*8], rax //store result to rX
  mov r13, qword ptr [r15 + r10*8] //move rX to r13 //TEST

  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next 



  xchg_rx: //xchg rX	--	0x26 <0X>	tmp = ac; ac = rX; rX = tmp
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the registers <0X> to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9, 7
  jg out_of_bound_access
  cmp r9, 0
  jl out_of_bound_access

  add r9, 2
  mov rax, qword ptr [r15 + r9*8] //move value of rX to rax  
  xchg rax, qword ptr [r15 + 8] //exchange value of rX and acc
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next


  xchg_rx_ry: //xchg rX rY	--	0x2e <XY>	tmp = rX; rX = rY; rY = tmp
  xor r9, r9
  xor r10, r10
  inc qword ptr [r15] //inc ip to get the 2 register in 1 byte
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov r9b, byte ptr [rbx + r8] //load the 2 registers <XY> to r9
  xor r10, r10 //clear r10 preparing to hold register X 
  mov r10b, r9b //store register X to r10b
  
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  shr r10b, 4
  //Fehler Behandlung: if X of rX <0 or >7
  cmp r10b, 7
  jg out_of_bound_access
  cmp r10b, 0
  jl out_of_bound_access

  add r10, 2
  add r9, 2
  mov rax, qword ptr [r15 + r9*8] //mov content of rY to rax
  xchg rax, qword ptr [r15 + r10*8] //exchange rX and rY
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next 
  


  and_: //and	uint64_t	0x30 <imm>	ac &= imm
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian
  and qword ptr [r15 + 8], rax //and acc with immediate
  add qword ptr [r15], 8 //add 8 to ip for executing next instruction
  jmp execute_next


  and_rx: //and rX	--	0x32 <0X>	ac &= rX
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the registers <0X> to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9, 7
  jg out_of_bound_access
  cmp r9, 0
  jl out_of_bound_access

  add r9, 2
  mov rax, qword ptr [r15 + r9*8] //move value of rX to rax  
  and qword ptr [r15 + 8], rax //rX AND acc
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next


  and_rx_imm: //and rX	uint64_t	0x31 <0X> <imm>	rX &= imm
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 1 byte register to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9, 7
  jg out_of_bound_access_two_args
  cmp r9, 0
  jl out_of_bound_access_two_args

  add r9, 2
  and qword ptr [r15 + r9*8], rax //rX AND immediate
  add qword ptr [r15], 8 //add 8 to ip for executing next instruction
  jmp execute_next


  and_rx_ry: //and rX rY	--	0x33 <XY>	rX &= rY
  xor r9, r9
  xor r10, r10
  inc qword ptr [r15] //inc ip to get the 2 register in 1 byte
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov r9b, byte ptr [rbx + r8] //load the 2 registers <XY> to r9
  xor r10, r10 //clear r10 preparing to hold register X 
  mov r10b, r9b //store register X to r10b

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  //Fehler Behandlung: if X of rX <0 or >7
  cmp r10b, 7
  jg out_of_bound_access
  cmp r10b, 0
  jl out_of_bound_access

  add r10, 2
  add r9, 2
  mov rax, qword ptr [r15 + r9*8] //move content of rY to rax
  and qword ptr [r15 + r10*8], rax //rX AND rY
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next 




  or_: //or	uint64_t	0x34 <imm>	ac |= imm
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian
  or qword ptr [r15 + 8], rax //acc OR immediate
  add qword ptr [r15], 8 //inc ip for executing next instruction
  jmp execute_next


  or_rx_imm: //or rX	uint64_t	0x35 <0X> <imm>	rX |= imm
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 1 byte register to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9, 7
  jg out_of_bound_access_two_args
  cmp r9, 0
  jl out_of_bound_access_two_args

  add r9, 2
  or qword ptr [r15 + r9*8], rax //rX OR immediate
  add qword ptr [r15], 8 //add 8 to ip for executing next instruction
  jmp execute_next


  or_rx: //or rX	--	0x36 <0X>	ac |= rX
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the registers <0X> to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9, 7
  jg out_of_bound_access
  cmp r9, 0
  jl out_of_bound_access

  add r9, 2
  mov rax, qword ptr [r15 + r9*8] //move value of rX to rax  
  or qword ptr [r15 + 8], rax //rX OR acc
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next


  or_rx_ry: //or rX rY	--	0x37 <XY>	rX |= rY
  xor r9, r9
  xor r10, r10
  inc qword ptr [r15] //inc ip to get the 2 register in 1 byte
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov r9b, byte ptr [rbx + r8] //load the 2 registers <XY> to r9
  xor r10, r10 //clear r10 preparing to hold register X 
  mov r10b, r9b //store register X to r10b

  and r9b, 0x0f
  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  shr r10b, 4
  //Fehler Behandlung: if X of rX <0 or >7
  cmp r10b, 7
  jg out_of_bound_access
  cmp r10b, 0
  jl out_of_bound_access

  add r10, 2
  add r9, 2
  mov rax, qword ptr [r15 + r9*8] //move content of rY to rax
  or qword ptr [r15 + r10*8], rax //rX OR rY
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next 



  xor_: //or	uint64_t	0x34 <imm>	ac |= imm
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian
  xor qword ptr [r15 + 8], rax //acc OR immediate
  add qword ptr [r15], 8 //inc ip for executing next instruction
  jmp execute_next


  xor_rx_imm: //xor rX	uint64_t	0x39 <0X> <imm>	rX ^= imm
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 1 byte register to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9, 7
  jg out_of_bound_access_two_args
  cmp r9, 0
  jl out_of_bound_access_two_args

  add r9, 2
  xor qword ptr [r15 + r9*8], rax //rX OR immediate
  add qword ptr [r15], 8 //add 8 to ip for executing next instruction
  jmp execute_next


  xor_rx: //xor rX	--	0x3a <0X>	ac ^= rX
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the registers <0X> to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9, 7
  jg out_of_bound_access
  cmp r9, 0
  jl out_of_bound_access

  add r9, 2
  mov rax, qword ptr [r15 + r9*8] //move value of rX to rax  
  xor qword ptr [r15 + 8], rax //rX OR acc
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next


  xor_rx_ry: //xor rX rY	--	0x3b <XY>	rX ^= rY
  xor r9, r9
  xor r10, r10
  inc qword ptr [r15] //inc ip to get the 2 register in 1 byte
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov r9b, byte ptr [rbx + r8] //load the 2 registers <XY> to r9
  xor r10, r10 //clear r10 preparing to hold register X 
  mov r10b, r9b //store register X to r10b

  and r9b, 0x0f 
  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  shr r10b, 4
  //Fehler Behandlung: if X of rX <0 or >7
  cmp r10b, 7
  jg out_of_bound_access
  cmp r10b, 0
  jl out_of_bound_access

  add r10, 2
  add r9, 2
  mov rax, qword ptr [r15 + r9*8] //move content of rY to rax
  xor qword ptr [r15 + r10*8], rax //rX OR rY
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next 



  not_: //not	--	0x3c	ac = ~ac
  inc qword ptr [r15] //inc ip to get the next instruction
  not qword ptr [r15 + 8] // NOT acc
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next


  not_rx: //not rX	--	0x3d <0X>	ac = ~rX
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the registers <0X> to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  add r9b, 2
  mov rax, qword ptr [r15 + r9*8] //move value of rX to rax
  not rax  
  mov qword ptr [r15 + 8], rax // acc = not rax
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next


  not_rx_ry: //not rX rY	--	0x3e <XY>	rX = ~rY
  xor r9, r9
  xor r10, r10
  inc qword ptr [r15] //inc ip to get the 2 register in 1 byte
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov r9b, byte ptr [rbx + r8] //load the 2 registers <XY> to r9
  xor r10, r10 //clear r10 preparing to hold register X 
  mov r10b, r9b //store register X to r10b

  and r9b, 0x0f
  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  shr r10b, 4
  //Fehler Behandlung: if X of rX <0 or >7
  cmp r10b, 7
  jg out_of_bound_access
  cmp r10b, 0
  jl out_of_bound_access

  add r10b, 2
  add r9b, 2
  mov rax, qword ptr [r15 + r9*8] //move content of rY to rax
  not rax
  mov qword ptr [r15 + r10*8], rax //rX = NOT rY
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next 



  cmp_rx_imm: //cmp rX	uint64_t	0x40 <0X> <imm>	ac = rX - imm
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 1 byte register to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access_two_args
  cmp r9b, 0
  jl out_of_bound_access_two_args

  add r9b, 2
  mov r13, qword ptr [r15 + r9*8] //save rX tmp
  sub qword ptr [r15 + r9*8], rax //substract immediate from rX
  mov rax, qword ptr [r15 + r9*8] //move the difference to rax
  mov qword ptr [r15 + r9*8], r13
  mov qword ptr [r15 + 8], rax //store result to acc
  add qword ptr [r15], 8 //add 8 to ip for executing next instruction
  jmp execute_next


  cmp_rx_ry: //cmp rX rY	--	0x41 <XY>	ac = rX - rY
  xor r9, r9
  xor r10, r10
  inc qword ptr [r15] //inc ip to get the 2 register in 1 byte
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov r9b, byte ptr [rbx + r8] //load the 2 registers <XY> to r9
  xor r10, r10 //clear r10 preparing to hold register X 
  mov r10b, r9b //store register X to r10b

  and r9b, 0x0f
  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  shr r10b, 4
  //Fehler Behandlung: if X of rX <0 or >7
  cmp r10b, 7
  jg out_of_bound_access
  cmp r10b, 0
  jl out_of_bound_access

  add r10b, 2
  add r9b, 2
  mov rax, qword ptr [r15 + r10*8] //move content of rX to rax
  sub rax, qword ptr [r15 + r9*8] //rax = rX - rY
  mov qword ptr [r15 + 8], rax //store result to acc
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next 



  tst_rx_imm: //tst rX	uint64_t	0x42 <0X> <imm>	ac = rX & imm
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 1 byte register to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access_two_args
  cmp r9b, 0
  jl out_of_bound_access_two_args

  add r9b, 2
  mov r13, qword ptr [r15 + r9*8] //save rX to r13
  and rax, r13 //rX = rX AND imm
  // mov rax, qword ptr [r15 + r9*8] //move the result to rax
  mov qword ptr [r15 + 8], rax //store result to acc
  add qword ptr [r15], 8 //add 8 to ip for executing next instruction
  jmp execute_next


  tst_rx_ry: //tst rX rY	--	0x43 <XY>	ac = rX & rY
  xor r9, r9
  xor r10, r10
  inc qword ptr [r15] //inc ip to get the 2 register in 1 byte
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov r9b, byte ptr [rbx + r8] //load the 2 registers <XY> to r9
  xor r10, r10 //clear r10 preparing to hold register X 
  mov r10b, r9b //store register X to r10b

  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  shr r10b, 4
  //Fehler Behandlung: if X of rX <0 or >7
  cmp r10b, 7
  jg out_of_bound_access
  cmp r10b, 0
  jl out_of_bound_access

  add r10b, 2
  add r9b, 2
  mov rax, qword ptr [r15 + r10*8] //move content of rX to rax
  and rax, qword ptr [r15 + r9*8] //rax = rX AND rY
  mov qword ptr [r15 + 8], rax //store result to acc
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next



  shr_: //shr	uint8_t	0x50 <imm>	ac >>= imm
  mov r13, qword ptr [r15] //test
  inc qword ptr [r15] //inc ip to get the 2 byte immediate
  mov r13, qword ptr [r15] //test

  mov r8, qword ptr [r15] //load the value of ip to r8
  mov al, byte ptr [rbx + r8] //load the 1 byte immediate to rax
  and al, 0x3f
  //bswap rax //convert little endian to big endian
  xor r9b, r9b //counter
  shr_loop:
  cmp r9b, al
  jge shr_loop_end
  shr qword ptr [r15 + 8], 1
  inc r9b
  jmp shr_loop
  shr_loop_end:
  mov r13, qword ptr [r15] //test
  inc qword ptr [r15] //add 1 to ip for executing next instruction
  mov r13, qword ptr [r15] //test
  jmp execute_next


  shr_rx_imm: //shr rX	uint8_t	0x51 <0X> <imm>	rX >>= imm
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 1 byte register to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  inc qword ptr [r15] //inc ip to get the 2 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov al, byte ptr [rbx + r8] //load the 1 byte immediate to rax
  and al, 0x3f
  //bswap rax //convert little endian to big endian --> no need for one byte!?

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access_two_args
  cmp r9b, 0
  jl out_of_bound_access_two_args

  add r9b, 2
  xor r11b, r11b //counter
  shr_rx_imm_loop:
  cmp r11b, al
  jge shr_rx_imm_loop_end
  shr qword ptr [r15 + r9*8], 1
  inc r11b
  jmp shr_rx_imm_loop
  shr_rx_imm_loop_end:
  inc qword ptr [r15]//inc ip for executing next instruction
  jmp execute_next


  shr_rx: //shr rX	--	0x52 <0X>	ac >>= rX
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the registers <0X> to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  add r9b, 2
  mov rax, qword ptr [r15 + r9*8] //move value of rX to rax  
  and rax, 0x000000000000003f  
  xor r11b, r11b //counter
  shr_rx_loop:
  cmp r11b, al
  jge shr_rx_loop_end
  shr qword ptr [r15 + 8], 1
  inc r11b
  jmp shr_rx_loop
  shr_rx_loop_end:
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next


  shr_rx_ry: //shr rX rY	--	0x53 <XY>	rX >>= rY
  inc qword ptr [r15] //inc ip to get the 2 register in 1 byte
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 2 registers <XY> to r9
  xor r10, r10 //clear r10 preparing to hold register X 
  mov r10b, r9b //store register X to r10b

  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access


  shr r10b, 4 //only keep low 4 bit, high 4 bit is "don't care"
  //Fehler Behandlung: if X of rX <0 or >7
  cmp r10b, 7
  jg out_of_bound_access
  cmp r10b, 0
  jl out_of_bound_access

  add r10, 2
  add r9, 2
  mov rax, qword ptr [r15 + r9*8] //move content of rY to rax
  and rax, 0x000000000000003f
  xor r11b, r11b //counter
  shr_rx_ry_loop:
  cmp r11b, al
  jge shr_rx_ry_loop_end
  shr qword ptr [r15 + r10*8], 1
  inc r11b
  jmp shr_rx_ry_loop
  shr_rx_ry_loop_end:
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next 



  shl_: //shr	uint8_t	0x50 <imm>	ac <<= imm
  inc qword ptr [r15] //inc ip to get the 2 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov al, byte ptr [rbx + r8] //load the 1 byte immediate to rax
  //bswap rax //convert little endian to big endian
  and al, 0x3f
  xor r11b, r11b //counter
  shl_loop:
  cmp r11b, al
  jge shl_loop_end
  shl qword ptr [r15 + 8], 1
  inc r11b
  jmp shl_loop
  shl_loop_end:
  inc qword ptr [r15] //add 8 to ip for executing next instruction
  jmp execute_next


  shl_rx_imm: //shr rX	uint8_t	0x51 <0X> <imm>	rX <<= imm
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 1 byte register to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  inc qword ptr [r15] //inc ip to get the 2 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov al, byte ptr [rbx + r8] //load the 1 byte immediate to rax
  //bswap rax //convert little endian to big endian
  and al, 0x3f

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access_two_args
  cmp r9b, 0
  jl out_of_bound_access_two_args

  add r9b, 2
  xor r11b, r11b //counter
  shl_rx_imm_loop:
  cmp r11b, al
  jge shl_rx_imm_loop_end
  shl qword ptr [r15 + r9*8], 1
  inc r11b
  jmp shl_rx_imm_loop
  shl_rx_imm_loop_end:
  inc qword ptr [r15] //add 8 to ip for executing next instruction
  jmp execute_next


  shl_rx: //shr rX	--	0x52 <0X>	ac <<= rX
  xor r9, r9
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov r9b, byte ptr [rbx + r8] //load the registers <0X> to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  add r9b, 2
  mov rax, qword ptr [r15 + r9*8] //move value of rX to rax  
  and rax, 0x000000000000003f
  xor r11b, r11b //counter
  shl_rx_loop:
  cmp r11b, al
  jge shl_rx_loop_end
  shl qword ptr [r15 + r9*8], 1
  inc r11b
  jmp shl_rx_loop
  shl_rx_loop_end:
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next


  shl_rx_ry: //shr rX rY	--	0x53 <XY>	rX <<= rY
  xor r9, r9
  xor r10, r10
  inc qword ptr [r15] //inc ip to get the 2 register in 1 byte
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov r9b, byte ptr [rbx + r8] //load the 2 registers <XY> to r9
  mov r10b, r9b //store register X to r10b

  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access


  shr r10b, 4 //only keep low 4 bit, high 4 bit is "don't care"
  //Fehler Behandlung: if X of rX <0 or >7
  cmp r10b, 7
  jg out_of_bound_access
  cmp r10b, 0
  jl out_of_bound_access

  add r10b, 2
  add r9b, 2
  mov rax, qword ptr [r15 + r9*8] //move content of rY to rax
  and rax, 0x000000000000003f
  xor r11b, r11b //counter
  shl_rx_ry_loop:
  cmp r11b, al
  jge shl_rx_ry_loop_end
  shl qword ptr [r15 + r10*8], 1
  inc r11b
  jmp shl_rx_ry_loop
  shl_rx_ry_loop_end:
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next 



  ld_: //ld	uintptr_t	0x60 <imm>	ac = [imm]
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian
  mov r9, qword ptr [rax] // load data at imm to r9
  mov qword ptr [r15 + 8], r9 //acc = [imm] 
  add qword ptr [r15], 8 //add 8 to ip for executing next instruction
  jmp execute_next


  ld_rx_imm: //ld rX	uintptr_t	0x61 <0X> <imm>	rX = [imm]
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 1 byte register to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian
  mov rcx, qword ptr [rax] // move data at imm to rcx
  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9, 7
  jg out_of_bound_access_two_args
  cmp r9, 0
  jl out_of_bound_access_two_args
    
  add r9, 2
  mov qword ptr [r15 + r9*8], rcx //rX = [imm]
  add qword ptr [r15], 8 //add 8 to ip for executing next instruction
  jmp execute_next


  ld_rx: //ld rX	--	0x62 <0X>	ac = [rX]
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the registers <0X> to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9, 7
  jg out_of_bound_access
  cmp r9, 0
  jl out_of_bound_access

  add r9, 2
  mov rax, qword ptr [r15 + r9*8] //move value of rX to rax  
  mov rcx, qword ptr [rax] //move data at [rX]
  mov qword ptr [r15 + 8], rcx // acc = [rX]
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next


  ld_rx_ry: //ld rX rY	--	0x63 <XY>	rX = [rY]
  inc qword ptr [r15] //inc ip to get the 2 register in 1 byte
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 2 registers <XY> to r9
  xor r10, r10 //clear r10 preparing to hold register X 
  mov r10b, r9b //store register X to r10b

  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  shr r10b, 4 //only keep low 4 bit, high 4 bit is "don't care"
  //Fehler Behandlung: if X of rX <0 or >7
  cmp r10b, 7
  jg out_of_bound_access
  cmp r10b, 0
  jl out_of_bound_access

  add r10, 2
  add r9, 2
  mov rax, qword ptr [r15 + r9*8] //move content of rY to rax
  mov rcx, qword ptr [rax] //move data at rY to rcx
  mov qword ptr [r15 + r10*8], rcx //rX = [rY]
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next 



  st_: //st	uintptr_t	0x64 <imm>	[imm] = ac
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian
  mov r9, qword ptr [r15 + 8] // load acc to r9
  mov [rax], r9 //[imm] = acc 
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next


  st_rx_imm: //st rX	uintptr_t	0x65 <0X> <imm>	[imm] = rX
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 1 byte register to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  
    
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9, 7
  jg out_of_bound_access_two_args
  cmp r9, 0
  jl out_of_bound_access_two_args
  //bswap rax //convert little endian to big endian
  add r9, 2
  mov rcx, qword ptr [r15 + r9*8] // move rX to rcx
  mov [rax], rcx //rX = [imm]
  add qword ptr [r15], 8 //add 8 to ip for executing next instruction
  jmp execute_next


  st_rx: //st rX	--	0x66 <0X>	[rX] = ac
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the registers <0X> to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9, 7
  jg out_of_bound_access
  cmp r9, 0
  jl out_of_bound_access

  add r9, 2
  mov rax, qword ptr [r15 + r9*8] //move value of rX to rax  
  mov rcx, qword ptr [r15 + 8] //move acc to rcx
  mov [rax], rcx // [rX] = acc
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next


  st_rx_ry: //st rX rY	--	0x67 <XY>	[rX] = rY
  inc qword ptr [r15] //inc ip to get the 2 register in 1 byte
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the 2 registers <XY> to r9
  xor r10, r10 //clear r10 preparing to hold register X 
  mov r10b, r9b //store register X to r10b

  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  shr r10b, 4 //only keep low 4 bit, high 4 bit is "don't care"
  //Fehler Behandlung: if X of rX <0 or >7
  cmp r10b, 7
  jg out_of_bound_access
  cmp r10b, 0
  jl out_of_bound_access

  add r10, 2
  add r9, 2
  mov rax, qword ptr [r15 + r9*8] //move content of rY to rax
  mov rcx, qword ptr [r15 + r10*8] //move rX to rcx
  mov [rcx], rax //[rX] = rY
  inc qword ptr [r15] //inc ip for executing next instruction
  jmp execute_next 



  go_: //go	uintptr_t	0x70 <imm>	ip = <imm>
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian
  mov qword ptr [r15], rax //set ip to immediate
  jmp execute_next


  go_rx: //go rX	--	0x71 <0X>	ip = rX
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the registers <0X> to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9, 7
  jg out_of_bound_access
  cmp r9, 0
  jl out_of_bound_access

  add r9, 2
  mov rax, qword ptr [r15 + r9*8] //move value of rX to rax  
  mov qword ptr [r15], rax //set ip to rX
  jmp execute_next



  gr_: //gr	int16_t	0x72 <imm>	ip = ip + <imm>
  inc qword ptr [r15] //inc ip to get the 2 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  //mov rax, 0x1111111111110000
  mov ax, word ptr [rbx + r8] //load the 2 byte immediate to rax
  cwde
  cdqe
  //bswap rax //convert little endian to big endian
  //sar rax, 32
  add qword ptr [r15], rax //add immediate to ip
  dec qword ptr [r15]
  mov r13, qword ptr [r15] //test
  jmp execute_next



  jz_: //jz	uintptr_t	0x73 <imm>	ip = ac == 0 ? <imm> : ip + sizeof(jz)
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov rax, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian
  cmp qword ptr [r15 + 8], 0 //compare acc with 0
  jne ac_not_zero_jz_
  mov qword ptr [r15], rax //add immediate to ip
  jmp execute_next
  ac_not_zero_jz_:
  add qword ptr [r15], 9 //add 8 to ip for executing next instruction
  dec qword ptr [r15]
  jmp execute_next


  jz_rx: //jz rX	--	0x74 <0X>	ip = ac == 0 ? rX : ip + sizeof(jz)
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the registers <0X> to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9b, 7
  jg out_of_bound_access
  cmp r9b, 0
  jl out_of_bound_access

  add r9b, 2
  mov rax, qword ptr [r15 + r9*8] //move value of rX to rax  
  cmp qword ptr [r15 + 8], 0 //compare acc with 0
  jne ac_not_zero_jz_rx
  mov qword ptr [r15], rax //add rX to ip
  jmp execute_next
  ac_not_zero_jz_rx:
  add qword ptr [r15], 2 //add 2 to ip for executing next instruction
  dec qword ptr [r15]
  jmp execute_next

  jrz_: //jrz	int16_t	0x75 <imm>	ip = ac == 0 ? ip + <imm> : ip + sizeof(jrz)
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov ax, word ptr [rbx + r8] //load the 2 byte immediate to rax
  //bswap rax //convert little endian to big endian
  //sar rax, 32
  cmp qword ptr [r15 + 8], 0 //compare acc with 0

  jne ac_not_zero_jrz_
  add qword ptr [r15], rax //add immediate to ip
  dec qword ptr [r15]
  jmp execute_next

  ac_not_zero_jrz_:
  add qword ptr [r15], 3 //add 3 to ip for executing next instruction
  dec qword ptr [r15]
  jmp execute_next


  
  ecall_: //ecall	uintptr_t	0x80 <imm>	ac = <imm>(r0, .., r5)
  inc qword ptr [r15] //inc ip to get the 8 byte immediate
  mov r8, qword ptr [r15] //load the value of ip to r8
  mov r11, qword ptr [rbx + r8] //load the 8 byte immediate to rax
  //bswap rax //convert little endian to big endian
  //Parameters
  mov rdi, qword ptr [r15 + 16] //move r0 to r15
  mov rsi, qword ptr [r15 + 24] //move r1 to rsi
  mov rdx, qword ptr [r15 + 32] //move r2 to rdx
  mov rcx, qword ptr [r15 + 40] //move r3 to rcx
  mov r8,  qword ptr [r15 + 48] //move r4 to r8
  mov r9,  qword ptr [r15 + 56] //move r5 to r9
  call r11 //call the external function
  mov qword ptr [r15 + 8], rax //move the return value to acc
  add qword ptr [r15], 8 //add 8 to ip for executing next instruction
  jmp execute_next


  ecall_rx: //ecall rX	--	0x81 <0X>	ac = rX(r0, .., r5)
  inc qword ptr [r15] //inc ip to get the 1 byte register
  mov r8, qword ptr [r15] //load the value of ip to r8
  xor r9, r9
  mov r9b, byte ptr [rbx + r8] //load the registers <0X> to r9
  and r9b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"

  //Fehler Behandlung: if Y of rY <0 or >7
  cmp r9, 7
  jg out_of_bound_access
  cmp r9, 0
  jl out_of_bound_access

  add r9, 2
  mov r11, qword ptr [r15 + r9*8] //move value of rX to rax  
  //Paramters
  mov rdi, qword ptr [r15 + 16] //move r0 to r15
  mov rsi, qword ptr [r15 + 24] //move r1 to rsi
  mov rdx, qword ptr [r15 + 32] //move r2 to rdx
  mov rcx, qword ptr [r15 + 40] //move r3 to rcx
  mov r8,  qword ptr [r15 + 48] //move r4 to r8
  mov r9,  qword ptr [r15 + 56] //move r5 to r9
  call r11 //call the external function
  mov qword ptr [r15 + 8], rax //move the return value to acc
  inc qword ptr [r15] //inc ip for executing next instruction  
  jmp execute_next

  end:
  mov rax, 0
  end_stack:
  pop rbx
  pop r15
  pop r14
  pop r13
  pop r12
  ret 

  out_of_bound_access:
  dec qword ptr [r15]
  mov rax, -2
  pop rbx
  pop r15
  pop r14
  pop r13
  pop r12
  ret
  
  out_of_bound_access_8_byte:
  sub qword ptr [r15], 8
  mov rax, -1
  pop rbx
  pop r15
  pop r14
  pop r13
  pop r12
  ret
  
  out_of_bound_access_two_args:
  sub qword ptr [r15], 2
  mov rax, -2
  pop rbx
  pop r15
  pop r14
  pop r13
  pop r12
  ret
  
single_invalid:
mov rax, qword ptr [0]

two_len:
mov r12,  qword ptr [r15] //load ip to r12 
mov r13b, byte ptr [rbx + r12] //load the program(encoding) into r13b
cmp r13b, 0x11
je single_invalid
jmp execute_next

test:
mov rax, qword ptr [0]

  //TODO

  //detect incomplete instrcution
  //REMOVE TESTS
  //Bei mehreren "gleichzeitig" auftretenden Fehlern hat -1 Präzedenz vor -2.
  