format ELF64 executable 3
entry _start

; ---   *   ---   *   ---
; get importer

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.asm' peso::array

import

; ---   *   ---   *   ---
; crux

alloc.debug=0

unit.salign r,x

proc.new _start
proc.stk qword ar

  proc.enter
  call alloc.new

  ; get mem
  mov  rdi,$04
  mov  rsi,$30

  call array.new

  ; ^save tmp
  mov qword [@ar],rax


  ; write
  mov  rdi,qword [@ar]
  mov  rsi,$000A2424

  call array.push

  ; ^read
  mov  rdi,qword [@ar]
  call array.pop


  ; release
  mov rdi,qword [@ar]
  call array.del


  ; cleanup and give
  call alloc.del

  proc.leave
  exit

; ---   *   ---   *   ---
; footer

alloc.seg

; ---   *   ---   *   ---
