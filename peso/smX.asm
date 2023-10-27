; ---   *   ---   *   ---
; SMX
; Variable sized memory ops
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     peso.smX

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.inc' peso::proc

library.import

; ---   *   ---   *   ---
; ROM

  smX.CDEREF = $CDEF

; ---   *   ---   *   ---
; sse load register, write dst

macro smX.ldst rX,offset,fdst,fsrc {
  fsrc rX,xword [rsi+offset]
  fdst xword [rdi+offset],rX

}

; ---   *   ---   *   ---
; i8-64 move src to dst with a
; conditional dereference

macro smX.i_mov rX,rY,size,step,args& {

  ; deref
  push  rsi

  cmp r10w,smX.CDEREF
  jne @f
  mov rX,size [rsi]

  @@:

  ; ^move value
  mov size [rdi],rX
  add rdi,step

  ; ^re-ref
  pop rsi

  add rsi,step
  sub r8d,step

}

; ---   *   ---   *   ---
; sse compare equality proto

macro mmX.sse_eq rX,offset,dst,fsrc {

  ; ^load register
  fsrc rX,xword [rdi+offset]

  ; ^chk equality, write dst
  pxor   rX,xword [rsi+offset]
  movdqa xword [dst+offset],rX

  ; ^write to out
  or rax,qword [dst+offset]
  or rax,qword [dst+offset+8]

}

; ---   *   ---   *   ---
; ^i8-64

macro mmX.i_eq rX,rY,size,step,args& {

  ; deref
  push  rsi

  cmp r10w,smX.CDEREF
  jne @f
  mov rX,size [rsi]

  @@:

  ; ^move value
  mov rax,rX
  mov size [rdi],rX
  add rdi,step

  ; ^re-ref
  pop rsi

  add rsi,step
  sub r8d,step

}

; ---   *   ---   *   ---
; allocate sse registers for op

macro smX.sse_walk op,size,args& {

  ; get avail registers
  local rem
  local offset

  rem equ \
    xmm0,xmm1,xmm2,xmm3,\
    xmm4,xmm5,xmm6,xmm7

  offset equ $00


  ; ^walk register list
  rept size \{

    match rX =, next , rem \\{

      ; paste op [args]
      op rX,offset,args

      ; ^go next
      offset equ offset+$10
      rem    equ next

    \\}

  \}

}

; ---   *   ---   *   ---
; ^alloc register,step from
; size keyword

macro smX.i_walk op,size,args& {

  ; default to byte
  local rX
  local step

  rX   equ sil
  rY   equ dil
  step equ $01


  ; ^16-bit
  match =word , size \{
    rX   equ si
    rY   equ di
    step equ $02

  \}

  ; ^32-bit
  match =dword , size \{
    rX   equ esi
    rY   equ edi
    step equ $04

  \}

  ; ^64-bit
  match =qword , size \{
    rX   equ rsi
    rY   equ rdi
    step equ $08

  \}

  ; paste op [args]
  op rX,rY,size,step,args

}

; ---   *   ---   *   ---
; generic jmptable maker

macro smX.gen_tab crux,size,\
  entry,entry.len,eob,op,args& {

  ; make id for table
  local id
  proc.get_id id,smX,local


  ; generate symbol list
  macro inner.get_branch dst,len,name2,[n] \{

    forward
      List.push dst,name2\#.b\#n
      len equ len+1

  \}


  ; ^place symbols
  macro inner.push_tab name2,[n] \{

    forward

      name2\#.b\#n:
        crux op,n,args
        eob

  \}


  ; get arg list for inner
  local branch
  local branch.len
  local branch.flat
  local entry.flat

  branch      equ
  branch.len  equ 0
  branch.flat equ
  entry.flat  equ
  List.cflatten \
    entry,entry.len,entry.flat


  ; exec all
  match any list,id entry.flat \{

    ; get symbols
    inner.get_branch branch,branch.len,any,list
    List.cflatten branch,branch.len,branch.flat

    ; ^make table
    match tab , branch.flat \\{
      jmptab any,size,tab

    \\}

    ; ^spawn entries
    inner.push_tab any,list

  \}

}

; ---   *   ---   *   ---
; ^sse ice

macro smX.sse_tab op,eob,args& {

  ; list possible sizes
  local entry
  local entry.len

  List.from entry,entry.len,\
    1,2,3,4,5,6,7,8

  ; ^make elem for each
  smX.gen_tab \
    smX.sse_walk,word,\
    entry,entry.len,\
    eob,op,args

}

; ---   *   ---   *   ---
; make i8-64 jmptab

macro smX.i_tab op,eob,args& {

  ; list possible sizes
  local entry
  local entry.len

  List.from entry,entry.len,\
    byte,word,dword,qword

  ; ^make elem for each
  smX.gen_tab \
    smX.i_walk,byte,\
    entry,entry.len,\
    eob,op,args

}

; ---   *   ---   *   ---
; map size to branch

EXESEG

proc.new smX.get_size

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
; map address to step,align

proc.new smX.get_alignment

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
  mov r10b,sil

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


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
