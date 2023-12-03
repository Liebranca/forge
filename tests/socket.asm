; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.hed' peso::socket

library.import

; ---   *   ---   *   ---
; crux

EXESEG

proc.new crux,public

proc.stk qword path
proc.stk qword sock

  proc.enter

  ; get path
  string.from "/tmp/.X11-unix/X0"
  mov  qword [@path],rax

  ; make socket
  call socket.unix.new
  mov  qword [@sock],rax

  ; ^attempt conx
  mov  rdi,qword [@sock]
  mov  rsi,qword [@path]

  call socket.unix.connect


  ; cleanup and give
  mov  rdi,qword [@sock]
  call socket.del

  mov  rdi,qword [@path]
  call string.del

  proc.leave
  exit

; ---   *   ---   *   ---
