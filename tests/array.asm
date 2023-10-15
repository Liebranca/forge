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
  use '.asm' peso::array

library.import

; ---   *   ---   *   ---
; crux

EXESEG

proc.new crux
proc.stk qword ar

  proc.enter

  ; get mem
  mov  rdi,$04
  mov  rsi,$30

  call array.new

  ; ^save tmp
  mov qword [@ar],rax


  ; add to end
  mov  rdi,qword [@ar]
  mov  rsi,$24242424

  call array.push

  ; add to end
  mov  rdi,qword [@ar]
  mov  rsi,$21212121

  call array.push

  ; add to beg
  mov   rdi,qword [@ar]
  mov   rsi,$000A2525

  call  array.unshift


  ; remove from end
  mov  rdi,qword [@ar]
  call array.pop


  ; release
  mov rdi,qword [@ar]
  call array.del


  ; cleanup and give
  proc.leave
  exit

; ---   *   ---   *   ---
; footer

MAM.foot

; ---   *   ---   *   ---
