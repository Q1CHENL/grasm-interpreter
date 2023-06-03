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
  //e.g only one instruction add in prog
  push r12
  push r13
  push r14
  push r15
  push rbx
  push rbp
  sub rsp, 8
  
  mov r14, rsi //len to r14
  mov r15, rdi //state to r15
  mov rbp, rdx //prog to rbp
  
  execute_next:
  cmp qword ptr [r15], r14
  jge out_of_bound_access_or_invalid_register
  
  mov r12,  qword ptr [r15] //load ip to r12 
  mov r13b, byte ptr [rbp + r12] //load the program(encoding) into r13b
  
  //STOP
  cmp r13b, 0x01
  je stop

  //NOP
  cmp r13b, 0x0f
  je noop

  //SET
  cmp r13b, 0x10  
  je set_8_imm
  cmp r13b, 0x18
  je set_rx_8_imm

  //CPY
  cmp r13b, 0x11  
  je cpy_rx
  cmp r13b, 0x19
  je cpy_rx_ry

  //ADD  
  cmp r13b, 0x20
  je add_8_imm
  cmp r13b, 0x21
  je add_rx
  cmp r13b, 0x28
  je add_rx_8_imm
  cmp r13b, 0x29
  je add_rx_ry

  //SUB  
  cmp r13b, 0x22
  je sub_8_imm
  cmp r13b, 0x23
  je sub_rx
  cmp r13b, 0x2a
  je sub_rx_8_imm
  cmp r13b, 0x2b
  je sub_rx_ry

  //MUL
  cmp r13b, 0x24
  je mul_8_imm
  cmp r13b, 0x25
  je mul_rx
  cmp r13b, 0x2c
  je mul_rx_8_imm
  cmp r13b, 0x2d
  je mul_rx_ry

  //XCHG
  cmp r13b, 0x26
  je xchg_rx
  cmp r13b, 0x2e
  je xchg_rx_ry

  //AND
  cmp r13b, 0x30
  je and_8_imm
  cmp r13b, 0x31
  je and_rx_8_imm
  cmp r13b, 0x32
  je and_rx
  cmp r13b, 0x33
  je and_rx_ry

  //OR
  cmp r13b, 0x34
  je or_8_imm
  cmp r13b, 0x35
  je or_rx_8_imm
  cmp r13b, 0x36
  je or_rx
  cmp r13b, 0x37
  je or_rx_ry

  //XOR
  cmp r13b, 0x38
  je  xor_8_imm
  cmp r13b, 0x39
  je xor_rx_8_imm
  cmp r13b, 0x3a
  je xor_rx
  cmp r13b, 0x3b
  je xor_rx_ry

  //NOT
  cmp r13b, 0x3c
  je not_ac
  cmp r13b, 0x3d
  je not_rx
  cmp r13b, 0x3e
  je not_rx_ry

  //CMP
  cmp r13b, 0x40
  je cmp_rx_8_imm
  cmp r13b, 0x41
  je cmp_rx_ry
  
  //TST
  cmp r13b, 0x42
  je tst_rx_8_imm
  cmp r13b, 0x43
  je tst_rx_ry

  //SHR
  cmp r13b, 0x50
  je shr_1_imm
  cmp r13b, 0x51
  je shr_rx_1_imm
  cmp r13b, 0x52
  je shr_rx
  cmp r13b, 0x53
  je shr_rx_ry

  //SHL
  cmp r13b, 0x54
  je shl_1_imm
  cmp r13b, 0x55
  je shl_rx_1_imm
  cmp r13b, 0x56
  je shl_rx
  cmp r13b, 0x57
  je shl_rx_ry

  //LD
  cmp r13b, 0x60
  je ld_8_addr
  cmp r13b, 0x61
  je ld_rx_8_addr
  cmp r13b, 0x62
  je ld_rx
  cmp r13b, 0x63
  je ld_rx_ry  

  //ST
  cmp r13b, 0x64
  je st_8_addr
  cmp r13b, 0x65
  je st_rx_8_addr
  cmp r13b, 0x66
  je st_rx
  cmp r13b, 0x67
  je st_rx_ry  

  //GO
  cmp r13b, 0x70
  je go_8_addr
  cmp r13b, 0x71
  je go_rx

  //GR
  cmp r13b, 0x72
  je gr_2_addr

  //J(R)Z
  cmp r13b, 0x73
  je jz_8_addr
  cmp r13b, 0x74
  je jz_rx
  cmp r13b, 0x75
  je jrz_2_addr

  //ECALL
  cmp r13b, 0x80
  je ecall_8_addr
  cmp r13b, 0x81
  je ecall_rx


  unknown_or_incomplemte_op:
  mov rax, -1
  jmp end_stack


  out_of_bound_access_or_invalid_register:
  mov rax, -2
  jmp end_stack


  stop:
  inc qword ptr [r15]
  jmp end


  noop:
  inc qword ptr [r15] //inc ip for next op
  jmp execute_next


  set_8_imm: // set	uint64_t	0x10 <imm>	ac = imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 8 // inc ip to get 8 byte imm
  cmp rbx, r14 // check instruction complete
  jge unknown_or_incomplemte_op
  // till here instrcution is complete
  sub rbx, 7 // sub 7 to get the immediate
  mov rax, qword ptr [rbp + rbx] // load imm to rax
  mov qword ptr [r15 + 8], rax // store imm to acc
  add qword ptr [r15], 9 // increase ip to next op
  jmp execute_next


  set_rx_8_imm: // set rX	uint64_t	0x18 <0X> <imm>	rX = imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 9 // add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 8 // sub 8 to get the register
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  inc rbx
  mov rax, qword ptr [rbp + rbx] // load 8 byte imm to rax  
  add r8, 2 // e.g. for r0: [r15 + 8*2]
  mov qword ptr [r15 + r8 * 8], rax
  add qword ptr [r15], 10 // point to next op
  jmp execute_next


  cpy_rx: //cpy rX	--	0x11 <0X>	ac = rX
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  mov rax, qword ptr [r15 + r8 * 8] //load the value of rX to rax
  mov qword ptr [r15 + 8], rax //store the value in rX to acc
  add qword ptr [r15], 2 // ip points to next op
  jmp execute_next


  cpy_rx_ry: //cpy rX rY	--	0x19 <XY>	rX = rY
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  xor r9, r9
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  mov r9b, r8b //save registers to r9
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register

  shr r9b, 4
  and r9b, 0x0f
  cmp r9b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r9b, 0
  jl out_of_bound_access_or_invalid_register

  add r8b, 2 // for Y
  add r9b, 2 // for X
  mov rax, qword ptr [r15 + r8 * 8] //load Y to rax
  mov qword ptr [r15 + r9 * 8], rax //store Y to X
  add qword ptr [r15], 2 //ip points to next ip
  jmp execute_next


  add_8_imm: //add	uint64_t	0x20 <imm>	ac += imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 8// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 7
  mov rax, qword ptr [rbp + rbx] //load imm to rax
  add qword ptr [r15 + 8], rax //add imm to acc
  add qword ptr [r15], 9
  jmp execute_next


  add_rx://add rX	--	0x21 <0X>	ac += rX
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  mov rax, qword ptr [r15 + r8 * 8] //mov rx to rax
  add qword ptr [r15 + 8], rax // add rx to acc

  add qword ptr [r15], 2
  jmp execute_next  


  add_rx_8_imm: //add rX	uint64_t	0x28 <0X> <imm>	rX += imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 9// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 8
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  inc rbx // to get imm
  mov rax, qword ptr [rbp + rbx] // load 8 byte imm to rax  
  add r8, 2 // e.g. for r0: [r15 + 8*2]
  add qword ptr [r15 + r8 * 8], rax //add rx to rx

  add qword ptr [r15], 10 //ip points to next op
  jmp execute_next  


  add_rx_ry://add rX rY	--	0x29 <XY>	rX += rY
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  xor r9, r9
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  mov r9b, r8b //save registers to r9
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register

  shr r9b, 4
  and r9b, 0x0f
  cmp r9b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r9b, 0
  jl out_of_bound_access_or_invalid_register

  add r8b, 2 // for Y
  add r9b, 2 // for X
  mov rax, qword ptr [r15 + r8 * 8] //load Y to rax
  add qword ptr [r15 + r9 * 8], rax //add Y to X

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next


  sub_8_imm: //sub	uint64_t	0x22 <imm>	ac -= imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 8// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 7
  mov rax, qword ptr [rbp + rbx] //load imm to rax
  sub qword ptr [r15 + 8], rax //add imm to acc
  add qword ptr [r15], 9 //ip points to next op
  jmp execute_next


  sub_rx_8_imm://sub rX	uint64_t	0x2a <0X> <imm>	rX -= imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 9// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 8
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  inc rbx // to get imm
  mov rax, qword ptr [rbp + rbx] // load 8 byte imm to rax  
  add r8, 2 // e.g. for r0: [r15 + 8*2]
  sub qword ptr [r15 + r8 * 8], rax //sub imm from rx
  add qword ptr [r15], 10 //ip points to next op
  jmp execute_next  


  sub_rx: //sub rX	--	0x23 <0X>	ac -= rX
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  mov rax, qword ptr [r15 + r8 * 8] //mov rx to rax
  sub qword ptr [r15 + 8], rax // sub rx from acc

  add qword ptr [r15], 2
  jmp execute_next  


  sub_rx_ry: //sub rX rY	--	0x2b <XY>	rX -= rY
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  xor r9, r9
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  mov r9b, r8b //save registers to r9
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register

  shr r9b, 4
  and r9b, 0x0f
  cmp r9b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r9b, 0
  jl out_of_bound_access_or_invalid_register

  add r8b, 2 // for Y
  add r9b, 2 // for X
  mov rax, qword ptr [r15 + r8 * 8] //load Y to rax
  sub qword ptr [r15 + r9 * 8], rax //sub Y from X

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next


  mul_8_imm: //mul	uint64_t	0x24 <imm>	ac *= imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 8// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 7
  mov rax, qword ptr [rbp + rbx] //load imm to rax
  mul qword ptr [r15 + 8] //mul imm with acc
  mov qword ptr [r15 + 8], rax
  add qword ptr [r15], 9 //ip points to next op
  jmp execute_next


  mul_rx_8_imm://mul rX	uint64_t	0x2c <0X> <imm>	rX *= imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 9// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 8
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  inc rbx // to get imm
  mov rax, qword ptr [rbp + rbx] // load 8 byte imm to rax  
  add r8, 2 // e.g. for r0: [r15 + 8*2]
  mul qword ptr [r15 + r8 * 8]
  mov qword ptr [r15 + r8 * 8], rax
  add qword ptr [r15], 10 //ip points to next op
  jmp execute_next  


  mul_rx://mul rX	--	0x25 <0X>	ac *= rX
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  mov rax, qword ptr [r15 + r8 * 8] //mov rx to rax
  mul qword ptr [r15 + 8] // mul rx with acc
  mov qword ptr [r15 + 8], rax // sub rx from acc
  add qword ptr [r15], 2
  jmp execute_next  


  mul_rx_ry: //mul rX rY	--	0x2d <XY>	rX *= rY
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  xor r9, r9
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  mov r9b, r8b //save registers to r9
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register

  shr r9b, 4
  and r9b, 0x0f
  cmp r9b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r9b, 0
  jl out_of_bound_access_or_invalid_register

  add r8b, 2 // for Y
  add r9b, 2 // for X
  mov rax, qword ptr [r15 + r8 * 8] //load Y to rax
  mul qword ptr [r15 + r9 * 8] //mul x y
  mov qword ptr [r15 + r9 * 8], rax

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next


  xchg_rx://xchg rX	--	0x26 <0X>	tmp = ac; ac = rX; rX = tmp
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  mov rax, qword ptr [r15 + 8] //move acc to rax
  xchg qword ptr [r15 + r8 * 8], rax //perform xchg
  mov qword ptr [r15 + 8], rax //move rx to acc
  add qword ptr [r15], 2
  jmp execute_next  


  xchg_rx_ry: //xchg rX rY	--	0x2e <XY>	tmp = rX; rX = rY; rY = tmp
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  xor r9, r9
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  mov r9b, r8b //save registers to r9
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register

  shr r9b, 4
  and r9b, 0x0f
  cmp r9b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r9b, 0
  jl out_of_bound_access_or_invalid_register

  add r8b, 2 // for Y
  add r9b, 2 // for X
  mov rax, qword ptr [r15 + r8 * 8] //load rY to rax
  xchg qword ptr [r15 + r9 * 8], rax //xchg
  mov qword ptr [r15 + r8 * 8], rax //move x to y

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next


  and_8_imm: //and	uint64_t	0x30 <imm>	ac &= imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 8// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 7
  mov rax, qword ptr [rbp + rbx] //load imm to rax
  and qword ptr [r15 + 8], rax 
  add qword ptr [r15], 9 //ip points to next op
  jmp execute_next


  and_rx_8_imm://and rX	uint64_t	0x31 <0X> <imm>	rX &= imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 9// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 8
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  inc rbx // to get imm
  mov rax, qword ptr [rbp + rbx] // load 8 byte imm to rax  
  add r8, 2 // e.g. for r0: [r15 + 8*2]
  and qword ptr [r15 + r8 * 8], rax //and rx with imm
  add qword ptr [r15], 10 //ip points to next op
  jmp execute_next  


  and_rx: //and rX	--	0x32 <0X>	ac &= rX
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  mov rax, qword ptr [r15 + r8 * 8] //move rx to rax
  and qword ptr [r15 + 8], rax //and rx with acc
  add qword ptr [r15], 2
  jmp execute_next  


  and_rx_ry:
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  xor r9, r9
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  mov r9b, r8b //save registers to r9
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register

  shr r9b, 4
  and r9b, 0x0f
  cmp r9b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r9b, 0
  jl out_of_bound_access_or_invalid_register

  add r8b, 2 // for Y
  add r9b, 2 // for X
  mov rax, qword ptr [r15 + r8 * 8] //load rY to rax
  and qword ptr [r15 + r9 * 8], rax //and rx with ry

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next


  or_8_imm: //or	uint64_t	0x34 <imm>	ac |= imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 8// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 7
  mov rax, qword ptr [rbp + rbx] //load imm to rax
  or qword ptr [r15 + 8], rax  //or acc with imm
  add qword ptr [r15], 9 //ip points to next op
  jmp execute_next
  
  or_rx_8_imm:
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 9// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 8
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  inc rbx // to get imm
  mov rax, qword ptr [rbp + rbx] // load 8 byte imm to rax  
  add r8, 2 // e.g. for r0: [r15 + 8*2]
  or qword ptr [r15 + r8 * 8], rax //or rx with imm
  add qword ptr [r15], 10 //ip points to next op
  jmp execute_next  

  or_rx://or rX	--	0x36 <0X>	ac |= rX
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete  
  xor r8, r8
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  mov rax, qword ptr [r15 + r8 * 8] //move rx to rax
  or qword ptr [r15 + 8], rax //or rx with acc
  add qword ptr [r15], 2
  jmp execute_next  

  or_rx_ry:
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  xor r9, r9
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  mov r9b, r8b //save registers to r9
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register

  shr r9b, 4
  and r9b, 0x0f
  cmp r9b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r9b, 0
  jl out_of_bound_access_or_invalid_register

  add r8b, 2 // for Y
  add r9b, 2 // for X
  mov rax, qword ptr [r15 + r8 * 8] //load rY to rax
  or qword ptr [r15 + r9 * 8], rax //or rx with ry

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next


  xor_8_imm://xor	uint64_t	0x38 <imm>	ac ^= imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 8// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 7
  mov rax, qword ptr [rbp + rbx] //load imm to rax
  xor qword ptr [r15 + 8], rax  //xor acc with imm
  add qword ptr [r15], 9 //ip points to next op
  jmp execute_next

  xor_rx_8_imm://xor rX	uint64_t	0x39 <0X> <imm>	rX ^= imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 9// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 8
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  inc rbx // to get imm
  mov rax, qword ptr [rbp + rbx] // load 8 byte imm to rax  
  add r8, 2 // e.g. for r0: [r15 + 8*2]
  xor qword ptr [r15 + r8 * 8], rax //xor rx with imm
  add qword ptr [r15], 10 //ip points to next op
  jmp execute_next  

  xor_rx://xor rX	--	0x36 <0X>	ac |= rX
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  mov rax, qword ptr [r15 + r8 * 8] //move rx to rax
  xor qword ptr [r15 + 8], rax //xor rx with acc
  add qword ptr [r15], 2
  jmp execute_next  

  xor_rx_ry: //xor rX rY	--	0x3b <XY>	rX ^= rY
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  xor r9, r9
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  mov r9b, r8b //save registers to r9
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register

  shr r9b, 4
  and r9b, 0x0f
  cmp r9b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r9b, 0
  jl out_of_bound_access_or_invalid_register

  add r8b, 2 // for Y
  add r9b, 2 // for X
  mov rax, qword ptr [r15 + r8 * 8] //load rY to rax
  xor qword ptr [r15 + r9 * 8], rax //xor rx with ry

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next


  not_ac: //not	--	0x3c	ac = ~ac
  not qword ptr [r15 + 8] //not acc
  add qword ptr [r15], 1 //ip points to next op
  jmp execute_next

  not_rx: //not rX	--	0x3d <0X>	ac = ~rX
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  mov rax, qword ptr [r15 + r8 * 8] //move rx to rax
  not rax //and rx with acc
  mov qword ptr [r15 + 8], rax
  add qword ptr [r15], 2
  jmp execute_next  

  not_rx_ry: //not rX rY	--	0x3e <XY>	rX = ~rY
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  xor r9, r9
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  mov r9b, r8b //save registers to r9
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register

  shr r9b, 4
  and r9b, 0x0f
  cmp r9b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r9b, 0
  jl out_of_bound_access_or_invalid_register

  add r8b, 2 // for Y
  add r9b, 2 // for X
  mov rax, qword ptr [r15 + r8 * 8] //load rY to rax
  not rax
  mov qword ptr [r15 + r9 * 8], rax //rx = not ry

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next


  cmp_rx_8_imm: //uint64_t	0x40 <0X> <imm>	ac = rX - imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 9// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 8
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  inc rbx // to get imm
  add r8, 2 // e.g. for r0: [r15 + 8*2]
  mov rax, qword ptr [r15 + r8 * 8] //move rx to rax 
  sub rax, qword ptr [rbp + rbx] //sub imm from rx
  mov qword ptr [r15 + 8], rax //store diff to acc
  add qword ptr [r15], 10 //ip points to next op
  jmp execute_next  

  cmp_rx_ry: //cmp rX rY	--	0x41 <XY>	ac = rX - rY
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  xor r9, r9
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  mov r9b, r8b //save registers to r9
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register

  shr r9b, 4
  and r9b, 0x0f
  cmp r9b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r9b, 0
  jl out_of_bound_access_or_invalid_register

  add r8b, 2 // for Y
  add r9b, 2 // for X
  mov rax, qword ptr [r15 + r9 * 8] //load x to rax
  sub rax, qword ptr [r15 + r8 * 8] //sub Y from X
  mov qword ptr [r15 + 8], rax //store diff to ac

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next


  tst_rx_8_imm: //tst rX	uint64_t	0x42 <0X> <imm>	ac = rX & imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 9// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 8
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  inc rbx // to get imm
  add r8, 2 // e.g. for r0: [r15 + 8*2]
  mov rax, qword ptr [r15 + r8 * 8] //move rx to rax 
  and rax, qword ptr [rbp + rbx] //sub imm from rx
  mov qword ptr [r15 + 8], rax //store result to acc
  add qword ptr [r15], 10 //ip points to next op
  jmp execute_next  


  tst_rx_ry: //tst rX rY	--	0x43 <XY>	ac = rX & rY
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  xor r9, r9

  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  mov r9b, r8b //save registers to r9
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register

  shr r9b, 4
  and r9b, 0x0f
  cmp r9b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r9b, 0
  jl out_of_bound_access_or_invalid_register

  add r8b, 2 // for Y
  add r9b, 2 // for X
  mov rax, qword ptr [r15 + r9 * 8] //load x to rax
  and rax, qword ptr [r15 + r8 * 8] //and X Y
  mov qword ptr [r15 + 8], rax //store result to ac

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next


  shr_1_imm: //shr	uint8_t	0x50 <imm>	ac >>= imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  mov al, byte ptr [rbp + rbx]
  and al, 0x3f

  xor r10b, r10b //counter
  shr_loop:
  cmp r10b, al
  jge shr_loop_end
  shr qword ptr [r15 + 8], 1
  inc r10b
  jmp shr_loop
  shr_loop_end:
  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next  


  shr_rx_1_imm: //shr rX	uint8_t	0x51 <0X> <imm>	rX >>= imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 2// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 1
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  inc rbx
  mov al, byte ptr [rbp + rbx] //load the 1 byte immediate to al
  and al, 0x3f

  xor r10b, r10b //counter
  shr_rx_imm_loop:
  cmp r10b, al
  jge shr_rx_imm_loop_end
  shr qword ptr [r15 + r8 * 8], 1
  inc r10b
  jmp shr_rx_imm_loop
  shr_rx_imm_loop_end:

  add qword ptr [r15], 3 //ip points to next op
  jmp execute_next  


  shr_rx://shr rX	--	0x52 <0X>	ac >>= rX
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  mov rax, qword ptr [r15 + r8 * 8] //load rx to al
  and rax, 0x3f

  xor r10b, r10b //counter
  shr_rx_loop:
  cmp r10b, al
  jge shr_rx_loop_end
  shr qword ptr [r15 + 8], 1
  inc r10b
  jmp shr_rx_loop
  shr_rx_loop_end:

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next  


  shr_rx_ry: //shr rX rY	--	0x53 <XY>	rX >>= rY
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  xor r9, r9
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  mov r9b, r8b //save registers to r9
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register

  shr r9b, 4
  and r9b, 0x0f
  cmp r9b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r9b, 0
  jl out_of_bound_access_or_invalid_register

  add r8b, 2 // for Y
  add r9b, 2 // for X
  mov rax, qword ptr [r15 + r8 * 8] //load Y to rax
  and rax, 0x3f
  xor r10b, r10b //counter
  shr_rx_ry_loop:
  cmp r10b, al
  jge shr_rx_ry_loop_end
  shr qword ptr [r15 + r9 * 8], 1
  inc r10b
  jmp shr_rx_ry_loop
  shr_rx_ry_loop_end:
  
  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next


  shl_1_imm: //shl	uint8_t	0x54 <imm>	ac <<= imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  mov al, byte ptr [rbp + rbx]
  and al, 0x3f

  xor r10b, r10b //counter
  shl_loop:
  cmp r10b, al
  jge shl_loop_end
  shl qword ptr [r15 + 8], 1
  inc r10b
  jmp shl_loop
  shl_loop_end:
  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next  


  shl_rx_1_imm: //shr rX	uint8_t	0x51 <0X> <imm>	rX >>= imm
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 2// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 1
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  inc rbx
  mov al, byte ptr [rbp + rbx] //load the 1 byte immediate to al
  and al, 0x3f

  xor r10b, r10b //counter
  shl_rx_imm_loop:
  cmp r10b, al
  jge shl_rx_imm_loop_end
  shl qword ptr [r15 + r8 * 8], 1
  inc r10b
  jmp shl_rx_imm_loop
  shl_rx_imm_loop_end:

  add qword ptr [r15], 3 //ip points to next op
  jmp execute_next  


  shl_rx://shr rX	--	0x52 <0X>	ac >>= rX
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  mov rax, qword ptr [r15 + r8 * 8] //load the 1 byte immediate to al
  and rax, 0x3f

  xor r10b, r10b //counter
  shl_rx_loop:
  cmp r10b, al
  jge shl_rx_loop_end
  shl qword ptr [r15 + 8], 1
  inc r10b
  jmp shl_rx_loop
  shl_rx_loop_end:

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next  


  shl_rx_ry: //shr rX rY	--	0x53 <XY>	rX >>= rY
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  xor r9, r9
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  mov r9b, r8b //save registers to r9
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register

  shr r9b, 4
  and r9b, 0x0f
  cmp r9b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r9b, 0
  jl out_of_bound_access_or_invalid_register

  add r8b, 2 // for Y
  add r9b, 2 // for X
  mov rax, qword ptr [r15 + r8 * 8] //load Y to rax
  and rax, 0x3f
  xor r10b, r10b //counter
  shl_rx_ry_loop:
  cmp r10b, al
  jge shl_rx_ry_loop_end
  shl qword ptr [r15 + r9 * 8], 1
  inc r10b
  jmp shl_rx_ry_loop
  shl_rx_ry_loop_end:
  
  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next


  ld_8_addr: //ld	uintptr_t	0x60 <imm>	ac = [imm]
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 8// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 7
  mov rax, qword ptr [rbp + rbx] //load addr to rax
  mov rcx, qword ptr [rax] // load data rcx
  mov qword ptr [r15 + 8], rcx

  add qword ptr [r15], 9 //ip points to next op
  jmp execute_next


  ld_rx_8_addr://ld rX	uintptr_t	0x61 <0X> <imm>	rX = [imm]
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 9// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 8
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  add rbx, 1
  mov rax, qword ptr [rbp + rbx] //load the 8 byte immediate to al
  mov rcx, [rax]
  mov qword ptr [r15 + r8 * 8], rcx

  add qword ptr [r15], 10 //ip points to next op
  jmp execute_next  


  ld_rx: //ld rX	--	0x62 <0X>	ac = [rX]
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  mov rax, qword ptr [r15 + r8 * 8] //load rx to rax
  mov rcx, [rax]
  mov qword ptr [r15 + 8], rcx // store to acc

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next


  ld_rx_ry: //ld rX rY	--	0x63 <XY>	rX = [rY]
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  xor r9, r9

  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  mov r9b, r8b //save registers to r9
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register

  shr r9b, 4
  and r9b, 0x0f
  cmp r9b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r9b, 0
  jl out_of_bound_access_or_invalid_register

  add r8b, 2 // for Y
  add r9b, 2 // for X

  mov rax, qword ptr [r15 + r8 *  8] //load y to rax
  mov rcx, qword ptr [rax] //load data to rcx
  mov qword ptr [r15 + r9 *  8], rcx //store to x

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next

  
  st_8_addr: //st	uintptr_t	0x64 <imm>	[imm] = ac
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 8// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 7
  mov rax, qword ptr [r15 + 8] //load ac to rax 
  mov rcx, qword ptr [rbp + rbx] //load addr to rcx
  mov qword ptr [rcx], rax

  add qword ptr [r15], 9 //ip points to next op
  jmp execute_next


  st_rx_8_addr://st rX	uintptr_t	0x65 <0X> <imm>	[imm] = rX
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 9// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 8
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  add rbx, 1
  mov rax, qword ptr [rbp + rbx] //load the 8 addr to rax
  mov rcx, qword ptr [r15 + r8 * 8] //load x to rcx
  mov qword ptr [rax], rcx // store x to addr

  add qword ptr [r15], 10 //ip points to next op
  jmp execute_next  


  st_rx: //st rX	--	0x66 <0X>	[rX] = ac
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  mov rax, qword ptr [r15 + 8] // load acc to rax 
  mov rcx, qword ptr [r15 + r8 * 8] //load rx to rcx
  mov qword ptr [rcx], rax

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next


  st_rx_ry: //st rX rY	--	0x67 <XY>	[rX] = rY
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8
  xor r9, r9

  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  mov r9b, r8b //save registers to r9
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register

  shr r9b, 4
  and r9b, 0x0f
  cmp r9b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r9b, 0
  jl out_of_bound_access_or_invalid_register

  add r8b, 2 // for Y
  add r9b, 2 // for X

  mov rax, qword ptr [r15 + r9 *  8] //load x to rax
  mov rcx, qword ptr [r15 + r9 *  8] //load y to rcx
  mov qword ptr [rax], rcx //load data at y to rcx

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next


  go_8_addr: //go	uintptr_t	0x70 <imm>	ip = <imm>
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 8// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 7
  mov rax, qword ptr [rbp + rbx] //load addr to rax
  mov qword ptr [r15], rax
  jmp execute_next


  go_rx: //go rX	--	0x71 <0X>	ip = rX
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  mov rax, qword ptr [r15 + r8 * 8] //load rx to rax
  mov qword ptr [r15], rax //update ip
  jmp execute_next


  gr_2_addr: //gr	int16_t	0x72 <imm>	ip = ip + <imm>
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 2// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 1
  mov ax, word ptr [rbp + rbx] //load imm to rax
  cwde
  cdqe
  add qword ptr [r15], rax //add imm to ip
  jmp execute_next


  jz_8_addr: //jz	uintptr_t	0x73 <imm>	ip = ac == 0 ? <imm> : ip + sizeof(jz)
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 8// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 7
  mov rax, qword ptr [rbp + rbx] //load addr to rax
  cmp qword ptr [r15 + 8], 0
  jne ac_not_zero_jz_8_addr
  mov qword ptr [r15], rax
  jmp execute_next
  ac_not_zero_jz_8_addr:
  add qword ptr [r15], 9
  jmp execute_next


  jz_rx://jz rX	--	0x74 <0X>	ip = ac == 0 ? rX : ip + sizeof(jz)
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 1// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  cmp qword ptr [r15 + 8], 0
  jne ac_not_zero_jz_rx
  mov rax, qword ptr [r15 + r8 * 8] //load rx to rax
  mov qword ptr [r15], rax //set ip to rx
  jmp execute_next
  ac_not_zero_jz_rx:
  add qword ptr [r15], 2
  jmp execute_next


  jrz_2_addr:
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 2// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 1
  cmp qword ptr [r15 + 8], 0
  jne ac_not_zero_jrz
  xor rax, rax
  mov ax, word ptr [rbp + rbx]
  add qword ptr [r15], rax
  jmp execute_next
  ac_not_zero_jrz:
  add qword ptr [r15], 3 //ip points to next op
  jmp execute_next


  ecall_8_addr: //ecall	uintptr_t	0x80 <imm>	ac = <imm>(r0, .., r5)
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 8// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 7
  mov r10, qword ptr [rbp + rbx] //load addr to r10

  mov rdi, qword ptr [r15 + 16] //move r0 to r15
  mov rsi, qword ptr [r15 + 24] //move r1 to rsi
  mov rdx, qword ptr [r15 + 32] //move r2 to rdx
  mov rcx, qword ptr [r15 + 40] //move r3 to rcx
  mov r8,  qword ptr [r15 + 48] //move r4 to r8
  mov r9,  qword ptr [r15 + 56] //move r5 to r9
  call r10 //call the func
  mov qword ptr [r15 + 8], rax //move the return value to acc

  add qword ptr [r15], 9 //ip points to next op
  jmp execute_next


  ecall_rx: //ecall rX	--	0x81 <0X>	ac = rX(r0, .., r5)
  mov rbx, qword ptr [r15] // load ip to rbp for local usage
  add rbx, 8// add instruction len-1 to ip
  cmp rbx, r14 // check if instruction complete
  jge unknown_or_incomplemte_op
  //till here the instruction is known and complete
  sub rbx, 7

  xor r8, r8 //clear to hold register
  mov r8b, byte ptr [rbp + rbx] //load 1 byte register to r8
  and r8b, 0x0f //only keep low 4 bit, high 4 bit is "don't care"
  cmp r8b, 7
  jg out_of_bound_access_or_invalid_register
  cmp r8b, 0
  jl out_of_bound_access_or_invalid_register
  //till here register is valid(and also no out of bound)
  add r8, 2
  mov r10, qword ptr [r15 + r8 * 8] //load addr to r10

  mov rdi, qword ptr [r15 + 16] //move r0 to r15
  mov rsi, qword ptr [r15 + 24] //move r1 to rsi
  mov rdx, qword ptr [r15 + 32] //move r2 to rdx
  mov rcx, qword ptr [r15 + 40] //move r3 to rcx
  mov r8,  qword ptr [r15 + 48] //move r4 to r8
  mov r9,  qword ptr [r15 + 56] //move r5 to r9
  call r10 //call the func
  mov qword ptr [r15 + 8], rax //move the return value to acc

  add qword ptr [r15], 2 //ip points to next op
  jmp execute_next


  end:
  mov rax, 0
  end_stack:
  add rsp, 8
  pop rbp
  pop rbx
  pop r15
  pop r14
  pop r13
  pop r12
  ret 

