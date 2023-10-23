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

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.inc' peso::proc

library.import

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
  repeat size

    ; stop if registers exhausted
    match , rem \{
      sys@err 'Oversized memcpy step'

    \}

    ; ^else proceed
    match rX =, next , rem \{

      ; ^load register, write dst
      fsrc rX,xword [rsi+offset]
      fdst xword [rdi+offset],rX

      ; ^go next
      offset equ offset+$10
      rem    equ next

    \}

  end repeat

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
    mov edx,ebx
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

  ; ^make table
  jmptab .tab,byte,\
    .is_byte,.is_word,\
    .is_dword,.is_qword,\
    .is_struc

  ; ^land
  .is_byte:
    mov byte [rdi],sil
    inc rdi
    ret

  .is_word:
    mov word [rdi],si
    add rdi,$02
    ret

  .is_dword:
    mov dword [rdi],esi
    add rdi,$04
    ret

  .is_qword:
    mov qword [rdi],rsi
    add rdi,$08
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
proc.cpr rbx

  proc.enter

  ; clamp chunk size to dline
  mov   rcx,-$10
  mov   ecx,$80
  cmp   ecx,r8d
  cmovg ecx,r8d

  ; ^unit-align
  and cl,$F0


  ; clear
  xor eax,eax
  xor edx,edx
  xor ebx,ebx

  ; get ptrs are aligned
  mov al,dil
  mov bl,sil

  and al,$0F
  and bl,$0F

  ; ^1 on dst unaligned
  mov   dl,$01
  cmp   al,$00
  cmovg eax,edx

  ; ^2 on src unaligned
  mov   dl,$02
  cmp   bl,$00
  cmovg ebx,edx

  ; ^combine
  or   al,bl
  mov  edx,eax

  ; ^get branch idex accto size
  mov  ebx,ecx
  shr  rbx,$04
  dec  rbx


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

    add  rdi,rcx
    add  rsi,rcx
    sub  r8d,ecx

    pop  rdx
    jmp  .chk_size


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
