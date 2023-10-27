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

  VERSION   v0.00.6b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.asm' peso::smX

library.import

; ---   *   ---   *   ---
; struc branching proto

macro memcpy.albranch fdst,fsrc {

  mov edx,r10d

  smX.sse_tab smX.ldst,\
    jmp .go_next,fdst,fsrc

}

; ---   *   ---   *   ---
; crux

proc.new memcpy

  ; get branch
  proc.enter
  call smX.get_size

; ---   *   ---   *   ---
; ^for when you want to skip
; recalculating size!

memcpy.direct:

  cmp dl,$04
  jge .is_struc

  ; i8-64 jmptab
  smX.i_tab smX.i_mov,ret

  ; ^sse
  .is_struc:
    call memcpy.struc
    ret


  ; void
  proc.leave

; ---   *   ---   *   ---
; ^further branching accto
; size of struc

proc.new memcpy.struc

  ; get branch
  proc.enter
  call smX.get_alignment

; ---   *   ---   *   ---
; ^for when you want to skip
; recalculating alignment!

memcpy.struc.direct:

  ; branch accto step
  mov r10d,ecx
  shr r10d,$04
  dec r10d


  ; see if bytes left
  .chk_size:
    cmp r8d,ecx
    jl  .skip

  ; branch accto alignment
  push rdx

  jmptab .altab,word,\
    .adst_asrc,.udst_asrc,\
    .adst_usrc,.udst_usrc


  ; ^land
  .adst_asrc:
    memcpy.albranch movdqa,movdqa

  .udst_asrc:
    memcpy.albranch movdqu,movdqa

  .adst_usrc:
    memcpy.albranch movdqa,movdqu

  .udst_usrc:
    memcpy.albranch movdqu,movdqu


  ; ^consume
  .go_next:

    add rdi,rcx
    add rsi,rcx
    sub r8d,ecx

    pop rdx
    jmp .chk_size


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
