format ELF64

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

section '.data' writeable align $10
  mem Mem

; ---   *   ---   *   ---

section '.rodata' align $10
  HEX_TAB db "0123456789ABCDEF"

; ---   *   ---   *   ---

section '.text' executable align $10
  public _start

; ---   *   ---   *   ---

proc _start

  Proc@$var word ptr

  Mem@$nit
  Mem@$alloc Log_Unit %ptr

  Proc@$call word_str,\
    $1122334455667788,\
    [%ptr]

  Proc@$call word_str,\
    $99AABBCCDDEEFF00,\
    [%ptr] |> add Log_Unit.c

  mov rsi,[%ptr]
  mov word [rsi+Log_Unit.nl],$000A

  write 1,rsi,sizeof.Log_Unit

  Mem@$del
  exit

end_proc leave

; ---   *   ---   *   ---
; converts word to 16 ascii bytes
; in hexadecimal format

; rdi: src word
; rsi: dst buff

proc word_str

  push rbx
  xor rcx,rcx
  xor rax,rax

  Proc@$var byte cnt

  mov byte [%cnt],$00

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

  inc byte [%cnt]
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
  cmp byte [%cnt],$08
  jl .top

; ---   *   ---   *   ---

  pop rbx

end_proc ret

; ---   *   ---   *   ---
