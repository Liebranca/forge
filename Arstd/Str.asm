; ---   *   ---   *   ---
; ARSTD STR
; They're terrible
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'
  use '.inc' Peso::Proc
  use '.asm' OS::Mem

import

; ---   *   ---   *   ---
; info

  TITLE     Arstd.Str

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---

segment readable executable

clan string

proc alloc

  push  rbx

  mov   rbx,rdi
  mov   rdx,rsi

  wed   Mem

  xmac  nit
  xmac  alloc,rbx,rdx

  pop   rbx

end_proc ret

end_clan

; ---   *   ---   *   ---
