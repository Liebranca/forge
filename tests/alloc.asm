format ELF64 executable 3
entry _start

; ---   *   ---   *   ---
; get importer

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.asm' peso::alloc

import

; ---   *   ---   *   ---
; crux

unit.salign r,x

proc.new _start
proc.stk qword it

  proc.enter

  call alloc.new

  xor rax,rax
  .top:

    mov  qword [@it],rax

    mov  rdi,$100
    call alloc

;    mov  qword [rax],$2525

    mov  rax,qword [@it]
    inc  rax

    cmp  rax,$1000
    jl   .top

  call alloc.del

  proc.leave
  exit

; ---   *   ---   *   ---
