; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.hed' peso::socket
  use '.hed' peso::env

library.import

; ---   *   ---   *   ---
; crux

EXESEG

proc.new crux,public

proc.stk env.lkp env0

proc.stk qword path
proc.stk qword sock
proc.stk qword peer

  mov  rdi,rsp
  call env.nit

  proc.enter

  ; get fpath
  lea rdi,[@env0]
  env.getv ARPATH

  string.fcat qword [@path],\
    cstring qword [env.state.ARPATH],\
    constr  env.path.MEM,\
    "scratch-00"


  ; ^make socket
  call socket.unix.new
  mov  qword [@sock],rax

  ; ^attempt conx
  mov  rdi,qword [@sock]
  mov  rsi,qword [@path]

  call socket.unix.bind


  ; put server on block
  mov  rdi,qword [@sock]

  call socket.unix.accept
  mov  qword [@peer],rax

  ; ^write to peer! ;>
  mov    rdi,qword [@peer]
  inline bin.fto

  constr.new mess,"HLOWRLD!"
  constr.sow mess

  call reap


  ; ^get rid of peer
  mov  rdi,qword [@peer]
  call socket.del

  mov  rdi,stdout
  call fto

  constr.new succ,"DONE",$0A
  constr.sow succ

  call reap


  ; cleanup and give
  mov  rdi,qword [@sock]
  call socket.unlink

  mov  rdi,qword [@sock]
  call socket.del

  mov  rdi,qword [@path]
  call string.del

  proc.leave
  exit

; ---   *   ---   *   ---
