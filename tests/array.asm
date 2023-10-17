; ---   *   ---   *   ---
; get importer

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

MAM.xmode='stat'
MAM.head

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.asm' peso::array

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
proc.stk qword  ar
proc.stk tstruc scratch

  proc.enter

  ; get mem
  mov  rdi,sizeof.tstruc
  mov  rsi,$20

  call array.new

  ; ^save tmp
  mov qword [@ar],rax

  ; make test buff
  mov qword [@scratch.a],$2424
  mov qword [@scratch.b],$2525

  ; add to end
  mov  rdi,qword [@ar]
  lea  rsi,[@scratch]

  call array.push


  ; mod test buff
  mov qword [@scratch.a],$2121
  mov qword [@scratch.b],$2323

  ; add to beg
  mov   rdi,qword [@ar]
  lea   rsi,[@scratch]

  call  array.unshift


  ; clear test buff
  mov qword [@scratch.a],$0000
  mov qword [@scratch.b],$0000

  ; remove from beg
  mov  rdi,qword [@ar]
  lea  rsi,[@scratch]

  call array.shift


  ; add to end
  mov  rdi,qword [@ar]
  lea  rsi,[@scratch]

  call array.push


  ; clear test buff
  mov qword [@scratch.a],$0000
  mov qword [@scratch.b],$0000

  ; ^remove
  mov  rdi,qword [@ar]
  lea  rsi,[@scratch]

  call array.pop

  ; release
  mov  rdi,qword [@ar]
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
  call array.del


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^entry

proc.new crux

  proc.enter

  call prim_test

  ; cleanup and give
  proc.leave
  exit

; ---   *   ---   *   ---
; footer

MAM.foot

; ---   *   ---   *   ---
