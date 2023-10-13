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

  proc.enter


  ; get mem
  alloc $40
  mov   qword [@p0],rax

  ; ^write
  mov qword [rax+$80],$2424

  ; ^enlarge
  realloc qword [@p0],$0C0
  mov     qword [@p0],rax

  ; free
  free qword [@p0]


  proc.leave
  exit

; ---   *   ---   *   ---
; footer

alloc.seg

; ---   *   ---   *   ---
