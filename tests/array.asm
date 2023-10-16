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
; crux

EXESEG

proc.new crux
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


  ; remove from end
  mov  rdi,qword [@ar]
  lea  rsi,[@scratch]

  call array.pop


  ; release
  mov rdi,qword [@ar]
  call array.del


  ; cleanup and give
  proc.leave
  exit

; ---   *   ---   *   ---
; footer

MAM.foot

; ---   *   ---   *   ---
