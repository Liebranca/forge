format ELF64

; ---   *   ---   *   ---
; deps

  include '%ARPATH%/forge/Worg.inc'
  arch '%ARPATH%/forge/OS.inc'

; ---   *   ---   *   ---

%St

  dq a ?
  db ws0 ?

  dq b ?
  db ws1 ?

  dq c ?
  db ws2 ?

  dq d ?
  dw nl ?

^St Log_Unit

; ---   *   ---   *   ---

section '.text' executable
  public _start

_start:

  enter 8,1
  define log_unit rbp-8

  Mem.nit mem
  Mem.alloc Log_Unit lu @ rbp-8

  mov rdi,$1122334455667788
  mov rsi,qword [log_unit]
  call qword_str

  mov rdi,$99AABBCCDDEEFF00
  mov rsi,qword [log_unit]
  add rsi,18
  call qword_str

  mov rsi,qword [log_unit]
  mov word [rsi+Log_Unit.nl],$000A

  restore log_unit

  write 1,rsi,sizeof.Log_Unit
  Mem.del mem

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

  ; ^assign byte from nyb
  shl rbx,cl
  or rax,rbx
  add cl,$08

; ---   *   ---   *   ---
; ^repeat

  xor rbx,rbx
  mov bl,dil

  ; second nyb
  shr bl,$04
  mov bl,[HEX_TAB+rbx]

  ; ^assign
  shl rbx,cl
  or rax,rbx
  add cl,$08

; ---   *   ---   *   ---
; up counters && shift source

  inc byte [cnt]
  shr rdi,$08

  ; move on half qword
  cmp cl,$40
  jne .tail

  mov [rsi],rax
  mov byte [rsi+Log_Unit.ws0],$20
  add rsi,Log_Unit.b

  xor cl,cl
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

; ---   *   ---   *   ---

section '.rodata'
  HEX_TAB db "0123456789ABCDEF"

; ---   *   ---   *   ---
