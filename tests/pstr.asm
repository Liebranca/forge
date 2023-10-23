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

constr.new raws,"TECHNICOLOR",$0A

; ---   *   ---   *   ---
; raw string test

EXESEG

proc.new test_00
proc.stk qword ar

  proc.enter

  ; make ice
  mov  rdi,$01
  mov  rsi,$40

  xor  rdx,rdx
  xor  r8,r8

  call string.new
  mov  qword [@ar],rax


  ; move cursor
  mov  rdi,qword [@ar]
  mov  si,$0310

  call string.mvcur

  ; put color
  mov  rdi,qword [@ar]
  mov  si,$002

  call string.color

  ; ^add text
  mov  rdi,qword [@ar]
  mov  rsi,raws
  mov  r8d,raws.length

  call string.cat

  ; ^remove color
  mov  rdi,qword [@ar]
  mov  rsi,$007

  call string.color


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
; make dynamic strings from ROM

proc.new test_01
proc.stk qword s

  proc.enter

  ; make string and print
  string.from "HLOWRLD!",$0A
  mov qword [@s],rax

  mov    rdi,rax
  inline string.sow

  mov  rdi,qword [@s]
  call array.del


  ; ^make another just for kicks
  string.from "BYEWRLD!",$0A
  mov qword [@s],rax

  mov    rdi,rax
  inline string.sow

  mov  rdi,qword [@s]
  call array.del


  ; cleanup and give
  proc.leave
  exit

; ---   *   ---   *   ---
; entry

proc.new crux

  proc.enter

  call test_00
  call test_01

  ; cleanup and give
  proc.leave
  exit

; ---   *   ---   *   ---
; footer

constr ROM
MAM.foot

; ---   *   ---   *   ---
