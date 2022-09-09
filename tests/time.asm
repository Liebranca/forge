format ELF64 executable 3
entry _start

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

imp
  use '.inc' OS
  use '.inc' Peso::Proc

end_imp ARPATH '/forge/'

; ---   *   ---   *   ---

segment readable writeable

  msg db 'TICK',$0A,$00
  msg_len=$-msg

  flen=80000000

reg

  dq sec   $00
  dq nan   $00

  dq prev  $00

end_reg Clock
clk Clock

; ---   *   ---   *   ---

segment readable executable

proc _start

  get_time clk.sec
  mov qword [clk.prev],rax

rept 12*5 {
  call tick

}

  exit

end_proc leave

proc tick

  push rbx
  mov rax,qword [clk.prev]
  push rax

  get_time clk.sec
  mov qword [clk.prev],rax

  pop rbx
  sub rax,rbx
  mov rbx,flen

  cmp rax,rbx
  jnl .skip

  sub rbx,rax
  and rbx,999999999
  usleep clk.sec,rbx
  write STDOUT,msg,msg_len

.skip:
  pop rbx

end_proc ret

; ---   *   ---   *   ---
