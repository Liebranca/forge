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

  VERSION   v0.00.4b
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
; GBL

  List.new smX.sse_eq.foot
  smX.sse_eq.has_foot equ 1

; ---   *   ---   *   ---
; sse load register, write dst

macro smX.sse_mov \
  rX,rY,offset,fdst,fsrc,_nullarg& {

  fsrc rX,xword [rsi+offset]
  fdst xword [rdi+offset],rX

}

; ---   *   ---   *   ---
; i8-64 move src to dst with a
; conditional dereference

macro smX.i_mov size,step,_nullarg& {

  ; get src
  local rX
  i_sized_reg rX,si,size

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

macro smX.sse_eq rX,rY,offset,fdst,fsrc,dst {

  ; load registers
  fdst rX,xword [rdi+offset]
  fsrc rY,xword [rsi+offset]

  ; ^chk equality
  pxor rX,rY

  ; ^Q write out
  smX.sse_eq.foot.push \
    movdqu xword [dst+offset] '\,' rX,\
    or     rbx '\,' qword [dst+offset+$00],\
    or     rbx '\,' qword [dst+offset+$08]

}

; ---   *   ---   *   ---
; ^i8-64

macro smX.i_eq size,step,_nullarg& {

  ; get src
  local rX
  i_sized_reg rX,si,size

  ; get dst
  local rY
  i_sized_reg rY,di,size

  ; get scratch
  local rZ
  i_sized_reg rZ,b,size

  ; save tmp
  push rsi
  push rdi


  ; deref src
  cmp  r10w,smX.CDEREF
  jne  @f
  mov  rX,size [rsi]

  @@:

  ; ^deref dst
  cmp  r9w,smX.CDEREF
  jne  @f
  mov  rY,size [rdi]

  @@:

  ; ^move value
  mov rZ,rX
  xor rZ,rY

  ; restore tmp
  pop rdi
  pop rsi

  ; ^re-ref
  add rdi,step
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
    xmm0,xmm8,xmm1,xmm9,\
    xmm2,xmm10,xmm3,xmm11,\
    xmm4,xmm12,xmm5,xmm13,\
    xmm6,xmm14,xmm7,xmm15

  offset equ $00


  ; ^walk register list
  rept size \{

    match rX =, rY =, next , rem \\{

      ; paste op [args]
      op rX,rY,offset,args

      ; ^go next
      offset equ offset+$10
      rem    equ next

    \\}

  \}


  ; append footer if present
  match =1 , op#.has_foot \{
    op#.foot
    op#.foot.clear

  \}

}



; ---   *   ---   *   ---
; (WIP) i8-64 save,call,restore

macro smX.i_scry F,arg& {

  ; get arg registers
  local avail
  avail equ di,si,d,r10,r8,r9

  ; build list from args
  local list
  local len

  ; ^roll
  match any,arg \{
    List.from list,len,any

  \}


  ; Qs for save/restore
  List.new smX.i_scry.setup
  List.new smX.i_scry.undo


  ; alloc registers
  rept len \{

    local elem
    local pX
    local rX

    rX equ
    pX equ

    ; get register
    match cur =, next , avail \\{

      avail equ next
      rX    equ cur

      i_sized_reg pX,cur,qword

    \\}


    ; get value
    elem equ
    List.shift list,elem

    ; ^unroll
    local ok
    ok equ 0

    ; ^handle casting+deref
    match dst =** size value , rX elem \\{

      i_sized_reg elem,dst,size
      elem equ mov elem '\,' size [value]

      ok equ 1

    \\}

    ; ^handle casting
    match =0 dst =* size value , ok rX elem \\{

      i_sized_reg elem,dst,size
      elem equ mov elem '\,' value

      ok equ 1

    \\}

    ; ^qword v
    match =0 value , ok elem \\{
      elem equ mov pX '\,' value

    \\}


    ; ^save tmp and overwrite
    match any,pX \{

      smX.i_scry.setup.unshift \
        push pX,\
        elem

      smX.i_scry.undo.push pop pX

    \}

  \}


  ; ^exec all
  smX.i_scry.setup
  call F

  smX.i_scry.undo

}

; ---   *   ---   *   ---
; alloc [register,step] from
; size keyword

macro smX.i_walk op,size,args& {

  local step
  step equ sizeof.#size

  ; paste op [args]
  op size,step,args

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
; 2-dimetional jmptable
;
; first level is alignment
; second is size of elem

macro smX.sse_tab2 op,eob,args& {

  ; individual entry
  macro item args2& \{
    mov edx,r10d
    smX.sse_tab op,foot,args2,args

  \}

  ; ^end-of for each
  macro foot \{
    pop rdx
    eob

  \}


  ; branch accto alignment
  push rdx

  jmptab .altab,word,\
    .adst_asrc,.udst_asrc,\
    .adst_usrc,.udst_usrc

  ; ^land
  .adst_asrc:
    item movdqa,movdqa

  .udst_asrc:
    item movdqu,movdqa

  .adst_usrc:
    item movdqa,movdqu

  .udst_usrc:
    item movdqu,movdqu

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
