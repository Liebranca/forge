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

  use '.asm' peso::mpart

import

; ---   *   ---   *   ---
; crux

unit.salign r,x
proc.new _start

  proc.enter

  mov  rdi,$03
  mov  rsi,$0F

  call mpart.fit

  proc.leave
  exit

; ---   *   ---   *   ---
