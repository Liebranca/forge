; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.hed' peso::bin

library.import

; ---   *   ---   *   ---
; crux

EXESEG

proc.new crux,public

  proc.enter

  string.from "./hihi"

  mov  rdi,rax
  mov  rsi,SYS.open.write

  call bin.new


  mov  rdi,rax
  call bin.close


  ; cleanup and give
  proc.leave
  exit

; ---   *   ---   *   ---
; footer

constr ROM

; ---   *   ---   *   ---
