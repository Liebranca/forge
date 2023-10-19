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
; ROM

constr.new raws_00,"Hello, world!",$0A
constr.new raws_01,"Bye, world!",$0A
constr ROM

; ---   *   ---   *   ---
; raw string test

EXESEG

proc.new test_00
proc.stk qword ar

  proc.enter

  ; make ice
  mov  rdi,$01
  mov  rsi,$20

  xor  rdx,rdx
  xor  r8,r8

  call string.new
  mov  qword [@ar],rax


  ; cat A+B
  mov  rdi,qword [@ar]
  mov  rsi,raws_00
  mov  r8d,raws_00.length

  call string.cat

  ; cat A+C
  mov  rdi,qword [@ar]
  mov  rsi,raws_01
  mov  r8d,raws_01.length

  call string.cat

  ; cat A+A
  mov  rdi,qword [@ar]
  mov  rsi,qword [@ar]
  xor  r8d,r8d

  call string.cat

  ; termout
  mov    rdi,qword [@ar]
  inline string.sow

  ; ^release
  mov  rdi,qword [@ar]
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
