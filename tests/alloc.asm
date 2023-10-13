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
  use '.inc' peso::alloc_h

library.import

; ---   *   ---   *   ---
; crux

EXESEG non

proc.new crux
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
