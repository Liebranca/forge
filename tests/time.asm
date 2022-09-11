format ELF64 executable 3
entry _start

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

imp
  use '.inc' OS::Clock
  use '.inc' OS

  use '.inc' Arstd::Lycon
  use '.inc' Peso::Proc

end_imp ARPATH '/forge/'

; ---   *   ---   *   ---

segment readable writeable

msg:

  db $1B,$5B,'999H'

clkchr:
  lydu $01A9
  db $00

  msg_len=$-msg
  flen=400000000

clk Clock

; ---   *   ---   *   ---

segment readable executable

proc _start

  qword cnt
  xor rcx,rcx

.top:

  xor rax,rax
  mov byte [%cnt],cl
  and byte [%cnt],$07

  push rcx
  call clock.tick,clk

  mov ah,$A9
  add ah,[%cnt]
  or  al,$C6

  mov [clkchr],ax
  write STDOUT,msg,msg_len

  pop rcx
  inc rcx
  cmp rcx,8*8
  jne .top

  mov byte [msg+msg_len-1],$0A
  write STDOUT,msg,msg_len
  exit

end_proc leave

; ---   *   ---   *   ---
