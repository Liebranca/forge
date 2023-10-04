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

;  use '.asm' peso::alloc

  use '.asm' peso::alloc

import

; ---   *   ---   *   ---
; crux

unit.salign r,x
proc.new _start

  proc.enter

  mov  rdi,$200
  call alloc
  call alloc.del

  proc.leave
  exit

; ---   *   ---   *   ---
