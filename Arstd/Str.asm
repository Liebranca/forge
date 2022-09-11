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

imp
  use '.inc' OS
  use '.inc' Peso::Proc

end_imp ARPATH '/forge/'

; ---   *   ---   *   ---
; info

  TITLE     Arstd.Str

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---

segment readable writeable
  mem Mem

; ---   *   ---   *   ---

segment executable

clan string

proc alloc

  push rbx

  mov rbx,rdi
  mov rdx,rsi

  wed Mem
  xmac nit
  xmac alloc,rbx,rdx

  pop rbx

end_proc ret

end_clan

; ---   *   ---   *   ---
