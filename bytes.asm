format ELF64

; ---   *   ---   *   ---

struc Mem {

  .top dq $00
  .sz  dq $00

}

define Mem.sz 16

; ---   *   ---   *   ---

struc Log_Unit {

  .a dq $00
  .ws0 db $20

  .b dq $00
  .ws1 db $20

  .c dq $00
  .ws2 db $20

  .d dq $00
  .ws3 word $000A

}

define Log_Unit.sz 37

; ---   *   ---   *   ---

define SYS_EXIT $3C

macro exit {

  leave

  xor rdi,rdi
  mov rax,SYS_EXIT

  syscall

}

; ---   *   ---   *   ---

define SYS_WRITE $01

macro write msg*,f* {

  mov rdi,f
  mov rsi,msg
  mov rdx,$24

  mov rax,SYS_WRITE

  syscall

}

; ---   *   ---   *   ---

define SYS_BRK 0x0C

macro brk n* {

  mov rdi,[mem.top]
  add rdi,n

  mov rax,SYS_BRK

  syscall

  mov [mem.top],rax
  add [mem.sz],n

}

macro nit_mem {brk 0}

macro del_mem {

  mov rax,[mem.top]
  sub rax,[mem.sz]
  brk rax

}

; ---   *   ---   *   ---

section '.text' executable
  public _start

_start:

  enter 8,1
  define log_unit qword [rbp-8]

  nit_mem

  mov rax,qword [mem.top]
  mov log_unit,rax

  brk Log_Unit.sz

  mov rdi,$1122334455667788
  mov rsi,log_unit
  call qword_str

  mov rdi,$99AABBCCDDEEFF00
  mov rsi,log_unit
  add rsi,18
  call qword_str

  mov word [rsi-1],$000A

  write log_unit,1
  del_mem

  exit

; ---   *   ---   *   ---
; converts word to 16 ascii bytes
; in hexadecimal format

; rdi: src qword
; rsi: dst buff

qword_str:

  push rbp
  mov rbp,rsp

  push rbx
  xor rcx,rcx
  xor rax,rax

  define cnt rbp-1
  define vsz 1

  mov byte [cnt],$00

; ---   *   ---   *   ---
; walk the word

.top:

  ; copy byte from source
  xor rbx,rbx
  mov bl,dil

  ; first nyb
  and bl,$0F

  mov bl,[HEX_TAB+rbx]
  add cl,$08

  ; ^assign byte from nyb
  shl rbx,cl
  or rax,rbx

; ---   *   ---   *   ---
; ^repeat

  xor rbx,rbx
  mov bl,dil

  ; nyb
  shr bl,$04

  mov bl,[HEX_TAB+rbx]
  add cl,$08

  ; ^assign
  shl rbx,cl
  or rax,rbx

; ---   *   ---   *   ---
; up counters && shift source

  inc byte [cnt]
  shr rdi,$08

  ; move on half qword
  cmp cl,$40
  jne .tail

  ror rax,8
  mov [rsi],rax
  mov byte [rsi+8],$20

  xor cl,cl
  add rsi,9

  xor rax,rax

; ---   *   ---   *   ---

.tail:
  cmp byte [cnt],$08
  jl .top

; ---   *   ---   *   ---

  pop rbx
  pop rbp
  ret

; ---   *   ---   *   ---

section '.data' writeable
  mem Mem

section '.rodata'
  HEX_TAB db "0123456789ABCDEF"

; ---   *   ---   *   ---
