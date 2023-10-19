; ---   *   ---   *   ---
; get importer

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

MAM.xmode='stat'
MAM.head

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.asm' peso::string

library.import

; ---   *   ---   *   ---
; stack string test

EXESEG

proc.new test_00
proc.stk qword ar_00
proc.stk qword ar_01

  proc.enter

  ; make ice
  mov  rdi,$01
  mov  rsi,$20

  xor  rdx,rdx
  xor  r8,r8

  call string.new
  mov  qword [@ar_00],rax

  ; ^src buff
  mov  rdi,$01
  mov  rsi,$20

  xor  rdx,rdx
  xor  r8,r8

  call string.new
  mov  qword [@ar_01],rax

  ; write to end of B
  mov  rdi,rax
  mov  rsi,$24

  call array.push

  ; ^end of A
  mov  rdi,qword [@ar_00]
  mov  rsi,$25

  call array.push

  ; cat A+B
  mov  rdi,qword [@ar_00]
  mov  rsi,qword [@ar_01]
  xor  r8d,r8d

  call string.cat


  ; ^release
  mov  rdi,qword [@ar_00]
  call array.del

  mov  rdi,qword [@ar_01]
  call array.del


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; entry

proc.new crux

  proc.enter

  call test_00

  ; cleanup and give
  proc.leave
  exit

; ---   *   ---   *   ---
; footer

MAM.foot

; ---   *   ---   *   ---
