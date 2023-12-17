; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.hed' peso::shmem
  use '.hed' peso::env

library.import

; ---   *   ---   *   ---
; crux

EXESEG

proc.new crux,public

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


  ; put server on block
  mov  rdi,qword [servo]

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
  servo.free

  proc.leave
  exit

; ---   *   ---   *   ---
