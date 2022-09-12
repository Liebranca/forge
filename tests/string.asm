format ELF64 executable 3

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

; ---   *   ---   *   ---

library ARPATH '/forge/'

  use '.asm' Arstd::Str
  use '.inc' OS

import

; ---   *   ---   *   ---
; GBL

  entry _start

; ---   *   ---   *   ---

segment readable
  msg db '$$$$$$',$0A,$00

segment readable executable

proc _start

  qword s0

  call string.alloc,8,*[%s0]

  mov rbx,[%s0]
  mov rcx,qword [msg]

  mov [rbx],rcx

  write 1,rbx,8

  wed Mem
  xmac del

  exit

end_proc leave

; ---   *   ---   *   ---
