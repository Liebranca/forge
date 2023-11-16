; ---   *   ---   *   ---
; MEMCPY
; Byte shufflin
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     peso.memcpy

  VERSION   v0.01.0b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.hed' peso::smX

library.import

; ---   *   ---   *   ---
; crux

proc.new memcpy,public

  proc.enter
  push r10

  ; see if bytes left
  .chk_size:
    pop r10

    cmp r8d,$00
    jle .skip

  ; get branch
  inline smX.get_size

  push r10
  cmp  al,$04
  jge  .is_struc


  ; i8-64 jmptab
  smX.i_tab smX.i_mov,\
  jmp .chk_size

  ; ^sse
  .is_struc:
    call memcpy.struc
    jmp  .chk_size


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; ^further branching accto
; size of struc

proc.new memcpy.struc,public

  ; get branch
  proc.enter
  inline smX.get_alignment

  ; ^branch accto step
  mov r10d,ecx
  shr r10d,$04
  dec r10d


  ; see if bytes left
  .chk_size:
    cmp r8d,ecx
    jl  .skip

  ; galactic unroll
  smX.sse_tab2 \
    smX.sse_mov,\
    jmp .go_next

  ; ^consume
  .go_next:

    add rdi,rcx
    add rsi,rcx
    sub r8d,ecx

    jmp .chk_size


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
