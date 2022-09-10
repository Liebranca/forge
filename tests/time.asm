format ELF64 executable 3
entry _start

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

imp
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

reg

  dq sec   $00
  dq nan   $00

  dq prev  $00
  dq cnt   $00

end_reg Clock
clk Clock

; ---   *   ---   *   ---

segment readable executable

proc _start

  xor rcx,rcx

.top:
  push rcx
  call tick,rcx |> and 0x7
  pop rcx

  inc rcx

  cmp rcx,12*5
  jne .top

  mov byte [msg+msg_len-1],$0A
  write STDOUT,msg,msg_len
  exit

end_proc leave

; ---   *   ---   *   ---

proc tick

  byte cnt
  push rbx

  mov [%cnt],dil

  mov rax,qword [clk.prev]
  push rax

  get_time clk.sec
  mov qword [clk.prev],rax

  pop rbx

  sub rax,rbx
  mov rbx,flen

  cmp rax,rbx
  jge .skip

  sub rbx,rax
  and rbx,999999999

  usleep clk.sec,rbx

.skip:

  xor rax,rax

  mov ah,$A9
  add ah,[%cnt]
  or  al,$C6

  mov [clkchr],ax

  write STDOUT,msg,msg_len

  pop rbx

end_proc ret

; ---   *   ---   *   ---
