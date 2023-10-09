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

proc.stk qword p0
proc.stk qword p1
proc.stk qword p2

  proc.enter

  call alloc.new

;  xor rax,rax
;  .top:
;    mov  qword [@it],rax

    ; get block 0
    mov  rdi,$100

    call alloc
    mov  qword [@p0],rax

    ; get block 1
    mov  rdi,$100

    call alloc
    mov  qword [@p1],rax


    ; free block 0
    mov  rdi,qword [@p0]
    call free

    ; ^re-use space for block 2
    mov  rdi,$100

    call alloc
    mov  qword [@p2],rax


    ; ^free all
    mov  rdi,qword [@p2]
    call free

    mov  rdi,qword [@p1]
    call free

;    mov  rax,qword [@it]
;    inc  rax
;
;    cmp  rax,$002
;    jl   .top

  call alloc.del

  proc.leave
  exit

; ---   *   ---   *   ---
