; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'

  use '.inc' OS
  use '.asm' peso::branch

library.import

; ---   *   ---   *   ---
; crux

EXESEG

proc.new crux,public

  proc.enter

  mov al,$FE
  branch.tab byte

  branch $FE => here
    xor ax,ax
    jmp .skip

  branch $FF => there
    xor bx,bx


  branch.end


  ; cleanup and give
  .skip:

  proc.leave
  exit

; ---   *   ---   *   ---
