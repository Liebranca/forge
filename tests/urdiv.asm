format ELF64 executable 3
entry _start

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

; ---   *   ---   *   ---

library ARPATH '/forge/'

  use '.asm' Arstd::UInt
  use '.inc' OS

import

; ---   *   ---   *   ---

segment readable executable
align $10

_start:

  UInt.align $43,$10
  exit


; ---   *   ---   *   ---
