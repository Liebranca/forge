format ELF64 executable 3

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

imp
  use '.inc' OS

end_imp ARPATH '/forge/'

; ---   *   ---   *   ---

segment readable writeable
  tc Termios
  tc_old Termios

; ---   *   ---   *   ---

segment readable executable

entry _start
_start:

  get_term STDIN,tc
  cpy_term tc_old,tc

  raw_term STDIN,tc
  set_term STDIN,tc_old

exit

; ---   *   ---   *   ---
