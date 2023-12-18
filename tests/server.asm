; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'

  use '.hed' OS::Clock

  use '.hed' peso::shmem
  use '.hed' peso::env

library.import

; ---   *   ---   *   ---
; GBL

RAMSEG
reg.ice CLK gclk

; ---   *   ---   *   ---
; crux

EXESEG

proc.new crux,public

proc.lis CLK clk gclk

proc.stk env.lkp env0
proc.stk qword   peer


  ; get environs
  mov  rdi,rsp
  call env.nit

  proc.enter

  ; get fpath
  lea rdi,[@env0]
  env.getv ARPATH

  ; ^make servo
  server.static unix public servo,\
    cstring qword [env.state.ARPATH],\
    constr  env.path.MEM,\
    "scratch-00"

  ; ^make servo mem
  server.shmem $1000 public servo.mem,\
    cstring qword [env.state.ARPATH],\
    constr  env.path.MEM,\
    "shmem-00"


  ; put server on block
  servo.mem.lock 

  mov  rdi,qword [servo]

  call socket.unix.accept
  mov  qword [@peer],rax

  ; ^write to peer! ;>
  mov    rdi,qword [@peer]
  inline bin.fto

  string.fsow "HLOWRLD!"
  call reap


  ; ^notify tty of close
  mov  rdi,stdout
  call fto

  string.fsow $0A,\
    "SERVER SHUTDOWN [",\
    string qword [servo.path],\
    ']',$0A

  call reap


  ; ^notify peer
  mov  rdi,qword [servo.mem]
  mov  rdi,qword [rdi+shmem.buff]
  mov  dword [rdi],$0A2424

  servo.mem.unlock

  ; ^get rid of em!
  mov  rdi,qword [@peer]
  call socket.del

  ; timeout and die
  mov  rdi,@clk
  mov  rsi,$1000
  xor  rdx,rdx

  call CLK.sleep

  ; cleanup and give
  servo.mem.free
  servo.free

  proc.leave
  exit

; ---   *   ---   *   ---
