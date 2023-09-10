format ELF64 executable 3

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

lib ARPATH '/forge/'
  use '.inc' OS

import

; ---   *   ---   *   ---

segment readable writeable
align $10

  tc     Termios
  tc_old Termios

; ---   *   ---   *   ---

segment readable executable
align $10

entry _start
_start:

  get_term STDIN,tc
  cpy_term tc_old,tc

  raw_term STDIN,tc
  set_term STDIN,tc_old

exit

; ---   *   ---   *   ---
