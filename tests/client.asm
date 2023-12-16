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
proc.stk qword buff

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


  ; make socket
  call socket.unix.new
  mov  qword [@sock],rax

  ; ^attempt conx
  mov  rdi,qword [@sock]
  mov  rsi,qword [@path]

  call socket.unix.connect


  ; make read buff
  string.blank
  mov qword [@buff],rax

  ; ^read in response
  mov    rdi,qword [@sock]
  mov    rsi,qword [@buff]
  mov    rdx,$08
  mov    r10w,SYS.read.over or SYS.read.ucap

  inline bin.read

  ; ^put
  mov    rdi,qword [@buff]

  inline string.sow
  call   reap


  ; cleanup and give
  mov  rdi,qword [@buff]
  call string.del

  mov  rdi,qword [@sock]
  call socket.del

  mov  rdi,qword [@path]
  call string.del

  proc.leave
  exit

; ---   *   ---   *   ---
