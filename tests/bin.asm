; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.hed' peso::bin

library.import

; ---   *   ---   *   ---
; crux

EXESEG

proc.new crux,public
proc.stk qword f0
proc.stk qword s0

  proc.enter

  ; make container
  bin.from qword [@f0],"./hihi"

  ; ^make file if it doesn't exist
  mov    rdi,rax
  mov    rsi,SYS.open.write
  xor    rdx,rdx

  inline bin.open


  ; make junk data
  string.from $1B,$5B,"34;1m$$$$",\
    $1B,$5B,"0m",$0A

  mov qword [@s0],rax

  ; ^set file as out
  mov    rdi,qword [@f0]
  inline bin.fto

  ; ^write string to buffio
  mov    rdi,qword [@s0]

  inline string.sow
  call   reap


  ; close and free
  mov  rdi,qword [@f0]
  call bin.del

  mov  rdi,qword [@s0]
  call string.del


  ; cleanup and give
  proc.leave
  exit

; ---   *   ---   *   ---
; footer

constr ROM

; ---   *   ---   *   ---
