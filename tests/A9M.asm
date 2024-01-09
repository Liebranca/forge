; ---   *   ---   *   ---
; get importer

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.inc' A9M

library.import

; ---   *   ---   *   ---
; the bit ;>

A9M.read

; ---   *   ---   *   ---
