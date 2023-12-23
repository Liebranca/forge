; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.hed' peso::cask

library.import

; ---   *   ---   *   ---
; crux

EXESEG

proc.new crux,public

proc.stk qword ar
proc.stk qword have

  proc.enter

  ; make ice
  mov  rdi,$02
  mov  rsi,$08

  call cask.new
  mov  qword [@ar],rax

  ; ptr test
  mov  rdi,qword [@ar]
  mov  rsi,$DEAD
  call cask.give

  mov  rdi,qword [@ar]
  mov  rsi,$BEEF
  call cask.give


  ; ^remove elem
  mov  rdi,qword [@ar]
  lea  rsi,[@have]
  xor  rdx,rdx

  call cask.take

  ; ^insert new
  mov  rdi,qword [@ar]
  mov  rsi,$DE74
  call cask.give

  ; ^peek elem
  mov  rdi,qword [@ar]
  lea  rsi,[@have]
  xor  rdx,rdx

  call cask.view


  ; release
  mov  rdi,qword [@ar]
  call free


  ; cleanup and give
  proc.leave
  exit

; ---   *   ---   *   ---
