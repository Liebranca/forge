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

  VERSION   v0.00.3b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.inc' peso::proc

library.import

; ---   *   ---   *   ---
; ROM

  memcpy.CDEREF = $CDEF

; ---   *   ---   *   ---
; load-store proto

macro memcpy.ldst fdst,fsrc,size {

  ; get avail registers
  local rem
  local offset

  rem equ \
    xmm0,xmm1,xmm2,xmm3,\
    xmm4,xmm5,xmm6,xmm7

  offset equ $00


  ; walk register list
  rept size \{

    ; stop if registers exhausted
    match , rem \\{
      sys@err 'Oversized memcpy step'

    \\}

    ; ^else proceed
    match rX =, next , rem \\{

      ; ^load register, write dst
      fsrc rX,xword [rsi+offset]
      fdst xword [rdi+offset],rX

      ; ^go next
      offset equ offset+$10
      rem    equ next

    \\}

  \}

}

; ---   *   ---   *   ---
; alignment+size branching proto

macro memcpy.albranch fdst,fsrc {

  local name

  ; make id for table
  match x y , fdst fsrc \{
    name equ .tab.\#x\#.\#y

  \}

  ; walk [1,8]
  macro inner name2,[n] \{

    forward

      name2\#.s\#n:
        memcpy.ldst fdst,fsrc,n
        jmp .go_next

  \}


  ; ^exec
  match any,name \{

    ; branch accto size
    mov edx,r10d
    jmptab any,word,\
      any\#.s1,any\#.s2,\
      any\#.s3,any\#.s4,\
      any\#.s5,any\#.s6,\
      any\#.s7,any\#.s8

    ; ^spawn movs
    inner any,1,2,3,4,5,6,7,8

  \}

}

; ---   *   ---   *   ---
; primitive copy proto

macro memcpy.prim size {

  ; default to byte
  local rX
  local step

  rX   equ sil
  rY   equ r15b

  step equ $01


  ; ^16-bit
  match =word , size \{

    rX   equ si
    rY   equ r15w

    step equ $02

  \}

  ; ^32-bit
  match =dword , size \{

    rX   equ esi
    rY   equ r15d

    step equ $04

  \}

  ; ^64-bit
  match =qword , size \{

    rX   equ rsi
    rY   equ r15

    step equ $08

  \}


  ; conditionally dereference
  push  rsi
  push  r15

  mov   rY,size [rsi]
  cmp   r10w,memcpy.CDEREF
  cmove rsi,r15

  ; ^move value
  mov size [rdi],rX
  add rdi,step

  ; ^re-reference, go next
  pop r15
  pop rsi

  add rsi,step
  sub r8d,step

}

; ---   *   ---   *   ---
; map size to branch

proc.new memcpy.get_size

  proc.enter

  ; size is prim
  cmp r8d,$10
  jl  .is_prim


  ; struc setter
  .is_struc:
    mov edx,$04
    ret


  ; prim setter
  .is_prim:

    ; fork to highest
    cmp r8d,sizeof.dword+3
    jg  .is_qword

    ; fork to lower
    cmp r8d,sizeof.dword
    jl  .is_word

    ; ^do and end
    mov edx,$02
    ret

  ; ^lower
  .is_word:

    ; fork to lowest
    cmp r8d,sizeof.word
    jl  .is_byte

    ; ^do and end
    mov edx,$01
    ret


  ; ^highest, no cmp
  .is_qword:
    mov edx,$03
    ret

  ; ^lowest, no cmp
  .is_byte:
    mov edx,$00
    ret


  ; void
  proc.leave

; ---   *   ---   *   ---
; crux

proc.new memcpy

  proc.enter

  ; get branch
  call memcpy.get_size

; ---   *   ---   *   ---
; ^for when you want to skip
; recalculating size!

memcpy.direct:

  ; ^make table
  jmptab .tab,byte,\
    .is_byte,.is_word,\
    .is_dword,.is_qword,\
    .is_struc

  ; ^land
  .is_byte:
    memcpy.prim byte
    ret

  .is_word:
    memcpy.prim word
    ret

  .is_dword:
    memcpy.prim dword
    ret

  .is_qword:
    memcpy.prim qword
    ret

  .is_struc:
    call memcpy.set_struc
    ret


  ; void
  proc.leave

; ---   *   ---   *   ---
; ^further branching accto
; size of struc

proc.new memcpy.set_struc

  proc.enter

  ; clamp chunk size to dline
  mov   ecx,$80
  cmp   ecx,r8d
  cmovg ecx,r8d

  ; ^unit-align
  and cl,$F0


  ; clear
  xor eax,eax
  xor edx,edx
  xor r10d,r10d

  ; get ptrs are aligned
  mov al,dil
  mov bl,sil

  and al,$0F
  and r10b,$0F

  ; ^1 on dst unaligned
  mov    dl,$01
  or     al,$00
  cmovnz eax,edx

  ; ^2 on src unaligned
  mov    dl,$02
  or     r10b,$00
  cmovnz r10d,edx

  ; ^combine
  or  al,r10b
  mov edx,eax

; ---   *   ---   *   ---
; ^for when you want to skip
; recalculating alignment!

memcpy.set_struc.direct:

  ; get branch idex accto size
  mov r10d,ecx
  shr r10d,$04
  dec r10d


  ; see if bytes left
  .chk_size:
    cmp r8d,ecx
    jl  .skip

  ; branch accto alignment
  .albranch:

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
