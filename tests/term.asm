library ARPATH '/forge/'
  use '.inc' OS
  use '.hed' OS::Term

library.import

; ---   *   ---   *   ---
; GBL

RAMSEG
  reg.ice Termios tc_main
  reg.ice Termios tc_old

; ---   *   ---   *   ---
; the bit

EXESEG

proc.new crux,public
proc.lis Termios tc  tc_main
proc.lis Termios old tc_old

  proc.enter

  mov  rdi,@tc
  mov  rsi,stdin

  call Termios.raw


  mov  rdi,@tc
  mov  rsi,stdin

  call Termios.cook


  ; cleanup and give
  proc.leave
  exit

; ---   *   ---   *   ---
