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
proc.stk qword   buff


  ; get environs
  mov  rdi,rsp
  call env.nit

  proc.enter

  ; get fpath
  lea rdi,[@env0]
  env.getv ARPATH

  ; connect to servo
  client.static unix public servo,\
    cstring qword [env.state.ARPATH],\
    constr  env.path.MEM,\
    "scratch-00"

  ; ^get servo mem
  client.shmem public servo.mem,\
    cstring qword [env.state.ARPATH],\
    constr  env.path.MEM,\
    "shmem-00"


  ; make read buff
  string.blank
  mov qword [@buff],rax

  ; ^read in response
  mov    rdi,qword [servo]
  mov    rsi,qword [@buff]
  mov    rdx,$08
  mov    r10w,SYS.read.over or SYS.read.ucap

  inline bin.read

  ; ^put
  mov    rdi,qword [@buff]

  inline string.sow
  call   reap


  ; ^wait for close
  mov    rdi,qword [servo.mem]
  call   shmem.lock

  mov    rdi,qword [rdi+shmem.buff]
  add    rdi,$02
  mov    rsi,$04

  call   sow
  call   reap

  mov    rdi,qword [servo.mem]
  inline shmem.unlock


  ; cleanup and give
  mov  rdi,qword [@buff]
  call string.del

  servo.mem.free 
  servo.free

  proc.leave
  exit

; ---   *   ---   *   ---
