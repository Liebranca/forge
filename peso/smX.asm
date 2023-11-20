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

  VERSION   v0.00.7b
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
      List.push dst,len => name2\#.b\#n
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
      hybtab any,size,tab

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
    1,2,4,8

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
    mov eax,r10d
    smX.sse_tab op,foot,args2,args

  \}

  ; ^end-of for each
  macro foot \{
    pop rax
    eob

  \}


  ; branch accto alignment
  push rax

  hybtab .altab,word,\
    $00 => .aligned,\
    $01 => .unaligned

  ; ^land
  .aligned:
    item movdqa,movdqa

  .unaligned:
    item movdqu,movdqu

}

; ---   *   ---   *   ---
; map size to branch

EXESEG

proc.new smX.get_size,public
macro smX.get_size.inline {

  proc.enter

  mov edx,r8d

  ; cap [size >= $10] to $10
  mov    eax,$0F
  not    eax
  and    eax,edx
  mov    eax,$10
  cmovnz edx,eax

  ; ^get [0-4] idex for size
  and edx,$1F
  bsr eax,edx


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline smX.get_size
  ret

; ---   *   ---   *   ---
; map address to step,align

proc.new smX.get_alignment,public
macro smX.get_alignment.inline {

  proc.enter

  ; clamp chunk size to dline
  mov   ecx,r8d
  and   ecx,$70
  mov   eax,$80
  cmovz ecx,eax


  ; clear vars
  mov edx,$01
  mov r10b,sil
  mov al,dil

  ; get $01 if A unaligned
  and    eax,$0F
  cmovnz eax,edx

  ; ^get $02 if B unaligned
  and    r10d,$0F
  cmovnz r10d,edx

  ; ^combine
  or al,r10b


  ; branch accto step
  mov r10d,ecx
  shr r10d,$04
  bsr r10d,r10d

  ; ^adjust step
  push r10
  mov  ecx,r10d
  mov  r10d,$10
  shl  r10d,cl

  mov  ecx,r10d
  pop  r10


  ;cleanup
  proc.leave

}


  ; ^invoke and give
  inline smX.get_alignment
  ret

; ---   *   ---   *   ---
