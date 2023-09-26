format ELF64 executable 3
entry _start

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'
  use '.inc' OS
  use '.inc' peso::proc

import

; ---   *   ---   *   ---

unit.salign r,x

proc.new _start
proc.var unit u16

proc.enter

  mov word [u16],$2424


proc.leave
exit

; ---   *   ---   *   ---
