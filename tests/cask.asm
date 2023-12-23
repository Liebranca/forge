; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.hed' peso::cask

library.import

; ---   *   ---   *   ---
; ROM

constr.new s0,"$$",$0A
constr.new s1,"$!",$0A

; ---   *   ---   *   ---
; crux

EXESEG

proc.new crux,public

proc.stk qword ar
proc.stk qword have

  proc.enter

  ; make ice
  mov  rdi,$08
  mov  rsi,$02

  call cask.new
  mov  qword [@ar],rax

  ; ptr test
  mov  rdi,qword [@ar]
  mov  rsi,s0
  call cask.give

  mov  rdi,qword [@ar]
  mov  rsi,s1
  call cask.give

  ; ^remove elem
  mov  rdi,qword [@ar]
  xor  rsi,rsi
  xor  rdx,rdx

  call cask.take


  ; run for each elem
  mov  rdi,qword [@ar]
  mov  rsi,elem_sow

  call cask.batcall


  ; release
  mov  rdi,qword [@ar]
  call free


  ; cleanup and give
  proc.leave
  exit

; ---   *   ---   *   ---
; test F for batrun

proc.new elem_sow

  proc.enter

  mov  rsi,$03

  call sow
  call reap

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
