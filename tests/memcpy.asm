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
  use '.asm' peso::file
  use '.asm' peso::memcpy

library.import

; ---   *   ---   *   ---
; the bit

EXESEG

proc.new crux
proc.stk xword dst
proc.stk xword src

  proc.enter

  lea  rdi,[@dst]
  lea  rsi,[@src]
  mov  r8d,$70

  call memcpy.set_struc


  ; cleanup and give
  proc.leave
  exit

; ---   *   ---   *   ---
; footer

MAM.foot

; ---   *   ---   *   ---
