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
proc.stk qword s1

  proc.enter

  ; make container
  bin.from qword [@f0],"./hihi"

  ; ^make file if it doesn't exist
  mov    rdi,rax
  mov    rsi,SYS.open.write
  xor    rdx,rdx

  inline bin.open_new


  ; make junk data
  string.from $1B,$5B,"34;1m$$$$",\
    $1B,$5B,"0m",$0A

  mov qword [@s0],rax

  ; ^cat string at end
  mov    rdi,qword [@f0]
  mov    rsi,qword [@s0]

  inline bin.append


  ; close file
  mov  rdi,qword [@f0]
  call bin.close

  ; ^re-open for read
  mov    rdi,qword [@f0]
  mov    rsi,SYS.open.read
  xor    rdx,rdx

  inline bin.open

  ; make buff
  mov  rdi,$01
  mov  rsi,$30
  xor  r8,r8
  xor  rdx,rdx

  call string.new
  mov  qword [@s1],rax

  ; ^read to
  mov  rdi,qword [@f0]
  mov  rsi,rax
  mov  rdx,$10
  mov  r10w,SYS.read.over

  call bin.read


  ; close and free
  mov  rdi,qword [@f0]
  call bin.del

  string.bdel \
    qword [@s0],\
    qword [@s1]


  ; cleanup and give
  proc.leave
  exit

; ---   *   ---   *   ---
; footer

constr ROM

; ---   *   ---   *   ---
