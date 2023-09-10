format ELF64 executable 3

; ---   *   ---   *   ---
; testing code generated
; by AR/peso ;>

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

; ---   *   ---   *   ---

library ARPATH '/forge/'

  use '.asm' Arstd::String
  use '.inc' OS

import

  entry     _start

; ---   *   ---   *   ---

segment readable writeable

buffio:

  db $00 dup 32
  .len=$-buffio

; ---   *   ---   *   ---

segment readable executable

align $10
non:

align $10
.crux:

  push rbp
  mov  rbp,rsp
  sub  rsp,8

  mov dword [buffio],$000A24
  write 1,buffio,3


leave
ret


; ---   *   ---   *   ---

_start:

  call non.crux
  exit

; ---   *   ---   *   ---
