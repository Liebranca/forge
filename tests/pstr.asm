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
  use '.asm' peso::re

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
  call string.del


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
  call string.del


  ; ^make another just for kicks
  string.from "BYEWRLD!",$0A
  mov qword [@s],rax

  mov    rdi,rax
  inline string.sow

  mov  rdi,qword [@s]
  call string.del


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^unshift/lcat

proc.new test_02
proc.stk qword s0
proc.stk qword s1

  proc.enter

  ; make strings
  string.from "$$$$"
  mov qword [@s0],rax

  string.from "%%%%"
  mov qword [@s1],rax

  ; ^join
  mov  rdi,qword [@s0]
  mov  rsi,qword [@s1]
  xor  r8,r8

  call string.lcat

  ; sneaky
  mov  rdi,qword [@s0]
  mov  rsi,$0A

  call array.unshift

  ; prich
  mov    rdi,qword [@s0]
  inline string.sow


  ; ^release
  mov  rdi,qword [@s0]
  call string.del

  mov  rdi,qword [@s1]
  call string.del

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; string cmp

proc.new test_03
proc.stk xword s0
proc.stk xword s1
proc.stk xword s2
proc.stk xword s3

  proc.enter

  ; make ice
  string.from "$$$$%%%%!!!!####"
  mov qword [@s0],rax

  string.from "$$$$%%%%!!!!####"
  mov qword [@s1],rax


  ; compare
  mov  rdi,qword [@s0]
  mov  rsi,qword [@s1]
  xor  r8,r8

  call string.eq
  call eq_dbout

  ; ^release
  mov  rdi,qword [@s0]
  call string.del

  mov  rdi,qword [@s1]
  call string.del

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; string match dbout

proc.new eq_dbout

  proc.enter

  constr.new me_00,"EQUAL",$0A
  constr.new me_01,"!EQUAL",$0A

  ; A eq B
  mov rdi,me_00
  mov rsi,me_00.length

  ; A ne B
  or  rax,$00
  je  @f

  mov rdi,me_01
  mov rsi,me_01.length


  ; ^write
  @@:call sow

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---

proc.new test_04

proc.stk qword  s0
proc.stk qword  s1
proc.stk re.pat pat

  proc.enter

  ; make ice
  string.from "$!$!",$0A
  mov qword [@s0],rax

  string.from "$!"
  mov qword [@s1],rax


  ; make pattern
  lea    rdi,[@pat]
  lea    rsi,[@s1]
  mov    r8w,$02
  mov    r9w,$04
  mov    dl,re.SUB

  inline re.new_pat

  ; ^match against
  lea rdi,qword [@pat]
  mov rsi,qword [@s0]

  call re.match_pat
  call eq_dbout

  ; release
  string.bdel \
    qword [@s1],\
    qword [@s0]

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; entry

proc.new crux
;proc.stk xword s0
;proc.stk xword s1

  proc.enter

;  call test_00
;  call test_01
;  call test_02

;  call test_03

  call test_04

  ; cleanup and give
  proc.leave
  exit

; ---   *   ---   *   ---
; footer

constr ROM
MAM.foot

; ---   *   ---   *   ---
