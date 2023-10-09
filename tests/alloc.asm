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
  use '.inc' peso::alloc_h

import

; ---   *   ---   *   ---
; crux

unit.salign r,x

proc.new _start

proc.stk qword p0
proc.stk qword p1
proc.stk qword p2

  proc.enter

  call alloc.new

  ; get block 0
  alloc $100
  mov   qword [@p0],rax

  mov  rdi,$100
  call alloc.crux

  ; get block 1
  alloc $100
  mov   qword [@p1],rax


  ; free block 0
  free qword [@p0]

  ; ^re-use space for block 2
  alloc $100
  mov   qword [@p2],rax


  ; ^free all
  free qword [@p2]
  free qword [@p1]


  call alloc.del

  proc.leave
  exit

; ---   *   ---   *   ---
; footer

alloc.seg

; ---   *   ---   *   ---
