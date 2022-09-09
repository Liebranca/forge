format ELF64 executable 3

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

imp

  use '.inc' OS
  use '.inc' Arstd::IO
  use '.inc' Peso::Proc

end_imp ARPATH '/forge/'

; ---   *   ---   *   ---
; info

  TITLE     bytes

  VERSION   v0.00.4b
  AUTHOR    'IBN-3DILA'

  entry     _start

; ---   *   ---   *   ---

reg

  dq a    ?
  db ws0  ?

  dq b    ?
  db ws1  ?

  dq c    ?
  db ws2  ?

  dq d    ?
  dw nl   ?

end_reg Log_Unit

; ---   *   ---   *   ---

segment readable writeable
  mem Mem

; ---   *   ---   *   ---

segment readable
  HEX_TAB db "0123456789ABCDEF"

; ---   *   ---   *   ---

segment executable

proc _start

  qword lu

  Mem@$nit
  Mem@$alloc Log_Unit %lu

  call qword_str,\
    $1122334455667788,\
    [%lu]

  call qword_str,\
    $99AABBCCDDEEFF00,\
    [%lu] |> add Log_Unit.c

  mov rsi,[%lu]
  mov word [rsi+Log_Unit.nl],$000A

  write 1,rsi,sizeof.Log_Unit

  Mem@$del
  exit

end_proc leave

; ---   *   ---   *   ---
; converts word to 16 ascii bytes
; in hexadecimal format

; rdi: src qword
; rsi: dst buff

proc qword_str

  push rbx
  xor cx,cx
  xor rbx,rbx
  xor rax,rax

  byte cnt
  mov byte [%cnt],$00
  add rsi,Log_Unit.b

; ---   *   ---   *   ---
; walk the qword

.top:

  ; first nyb
  mov bl,dil
  and bl,$0F
  or  al,[HEX_TAB+rbx]

  ; second nyb
  mov bl,dil
  shr bl,$04
  or  ah,[HEX_TAB+rbx]

; ---   *   ---   *   ---
; up counters && shift source

  shr rdi,$08
  inc cl

  ; move on half qword
  on cl == $04

    mov [rsi],rax
    mov byte [rsi+Log_Unit.ws0],$20
    sub rsi,Log_Unit.b

    xor rax,rax
    xor cl,cl
    inc ch

  off

  shl rax,$10

; ---   *   ---   *   ---

  cmp ch,2
  jl .top

; ---   *   ---   *   ---

  pop rbx

end_proc ret

; ---   *   ---   *   ---
