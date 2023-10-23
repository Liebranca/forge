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

  use '.inc' OS

  use '.inc' peso::constr
  use '.asm' peso::file

library.import

; ---   *   ---   *   ---
; ROM

constr.new me,"HLOWRLD!",$0A
constr ROM

; ---   *   ---   *   ---
; the bit

EXESEG

proc.new crux

  proc.enter

  constr.sow me


  ; cleanup and give
  proc.leave
  exit

; ---   *   ---   *   ---
; footer

MAM.foot

; ---   *   ---   *   ---
