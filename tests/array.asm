; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.hed' peso::array

library.import

; ---   *   ---   *   ---
; test struc

RAMSEG

reg.new tstruc

  my .a dq $00
  my .b dq $00

reg.end

; ---   *   ---   *   ---
; array of strucs

EXESEG

proc.new struc_test

proc.stk array  ar
proc.stk tstruc scratch

  proc.enter

  ; get mem
  mov  rdi,sizeof.tstruc
  mov  rsi,$20
  lea  rdx,[@ar]

  call array.new

  ; make test buff
  mov qword [@scratch.a],$2424
  mov qword [@scratch.b],$2525

  ; add to end
  lea  rdi,[@ar]
  lea  rsi,[@scratch]

  call array.push


  ; mod test buff
  mov qword [@scratch.a],$2121
  mov qword [@scratch.b],$2323

  ; add to beg
  lea  rdi,[@ar]
  lea  rsi,[@scratch]

  call array.unshift


  ; clear test buff
  mov qword [@scratch.a],$0000
  mov qword [@scratch.b],$0000

  ; remove from beg
  lea  rdi,[@ar]
  lea  rsi,[@scratch]

  call array.shift


  ; add to end
  lea  rdi,[@ar]
  lea  rsi,[@scratch]

  call array.push


  ; clear test buff
  mov qword [@scratch.a],$0000
  mov qword [@scratch.b],$0000

  ; ^remove
  lea  rdi,[@ar]
  lea  rsi,[@scratch]

  call array.pop

  ; release
  lea  rdi,[@ar]
  mov  sil,$01

  call array.del


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; array of primitives

proc.new prim_test
proc.stk qword ar

  proc.enter

  ; get mem
  mov  rdi,4
  mov  rsi,$20
  xor  rdx,rdx

  call array.new

  ; ^save tmp
  mov qword [@ar],rax


  ; add to end
  mov  rdi,qword [@ar]
  mov  rsi,$25252424

  call array.push

  ; ^add to beg
  mov  rdi,qword [@ar]
  mov  rsi,$23232121

  call array.unshift


  ; remove from beg
  mov  rdi,qword [@ar]
  call array.shift

  ; ^add to end
  mov  rdi,qword [@ar]
  mov  rsi,rax

  call array.push

  ; ^remove end
  mov  rdi,qword [@ar]
  call array.pop


  ; release
  mov  rdi,qword [@ar]
  xor  rsi,rsi

  call array.del


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^entry

proc.new crux,public

  proc.enter

  call struc_test

  ; cleanup and give
  proc.leave
  exit

; ---   *   ---   *   ---
