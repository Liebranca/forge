; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.hed' peso::bin

library.import

; ---   *   ---   *   ---
; crux

EXESEG

proc.new crux,public

proc.stk qword path

proc.stk qword s0
proc.stk qword s1

  proc.enter

  ; make container
  string.from "./hihi"
  mov qword [@path],rax

  ; make junk data
  string.from $1B,$5B,"34;1m$$$$",\
    $1B,$5B,"0m",$0A

  mov qword [@s0],rax


  ; ^write to file
  mov  rdi,qword [@path]
  mov  rsi,qword [@s0]

  call owc

  ; ^read back
  mov  rdi,qword [@path]

  call orc
  mov  qword [@s1],rax


  ; cleanup and give
  string.bdel \
    qword [@path],\
    qword [@s0],\
    qword [@s1]

  proc.leave
  exit

; ---   *   ---   *   ---
