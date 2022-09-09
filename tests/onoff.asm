;format ELF64 executable
;entry _start

use64

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

imp
  use '.inc' OS
  use '.inc' Peso::Switch

end_imp ARPATH '/forge/'

; ---   *   ---   *   ---

_start:

  sub sp,word $10

exit

; ---   *   ---   *   ---
