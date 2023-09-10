format ELF64 executable 3
entry _start

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'

  use '.asm' OS::Clock
  use '.inc' OS

  use '.inc' Arstd::Lycon

import

; ---   *   ---   *   ---

segment readable writeable
align $10

msg:
  db $1B,$5B,'999H'

clkchr:
  lydu $01A9
  db $00

  msg_len=$-msg
  flen=400000000


clk CLK

; ---   *   ---   *   ---

segment readable executable
align $10

proc _start

  qword cnt
  xor rcx,rcx

.top:

  ; sprite frame
  mov byte [%cnt],cl
  and byte [%cnt],$07

  ; go to next
  push rcx
  call Clock.tick,clk

  ; fetch sprite
  xor rax,rax
  mov ah,$A9
  add ah,[%cnt]
  or  al,$C6

  ; draw
  mov [clkchr],ax
  write STDOUT,msg,msg_len

  pop rcx

  ; up the counter
  inc rcx
  cmp rcx,8*8
  jne .top

; ---   *   ---   *   ---
; slap a newline at end

  mov byte [msg+msg_len-1],$0A
  write STDOUT,msg,msg_len
  exit


end_proc leave

; ---   *   ---   *   ---
