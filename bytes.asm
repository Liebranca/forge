format ELF64

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Worg
  include '%ARPATH%/forge/Worg.inc'

end if

%Worg
  use '.inc' OS
  use '.inc' Arstd:IO
  use '.inc' Peso:Proc

^Worg ARPATH '/forge/'

; ---   *   ---   *   ---
; info

  TITLE     bytes

  VERSION   v0.00.3b
  AUTHOR    'IBN-3DILA'

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

section '.data' writeable
  mem Mem

; ---   *   ---   *   ---

section '.rodata'
  HEX_TAB db "0123456789ABCDEF"

; ---   *   ---   *   ---

section '.text' executable
  public _start

Proc@$enter _start

  enter 8,1

  Proc@$var qword ptr

  Mem@$nit
  Mem@$alloc Log_Unit %ptr

  mov rdi,$1122334455667788
  mov rsi,[%_start.ptr]
  call qword_str

  mov rdi,$99AABBCCDDEEFF00
  mov rsi,[rbp-8]
  add rsi,18
  call qword_str

  mov rsi,[rbp-8]
  mov word [rsi+Log_Unit.nl],$000A

  restore log_unit

  write 1,rsi,sizeof.Log_Unit

  Mem@$del
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
