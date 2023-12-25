; ---   *   ---   *   ---
; PESO SMX SSE
; Them long registers
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.hed' peso::smX::common

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.smX.sse

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

smX.decl_foot sse,\
  eqmm,eqmr,eqrm,eqrr

; ---   *   ---   *   ---
; load [dst],[src]

macro smX.sse.ldmm \
  rX,rY,offset,fdst,fsrc,_nullarg& {

  fsrc rX,xword [rsi+offset]
  fdst xword [rdi+offset],rX

}

; ---   *   ---   *   ---
; load [dst],src

macro smX.sse.ldmr rX,rY,offset,fdst,_nullarg& {
  fdst xword [rdi+offset],rX

}

; ---   *   ---   *   ---
; load dst,[src]

macro smX.sse.ldrm rX,rY,offset,fdst,_nullarg& {
  fdst rX,xword [rsi+offset]

}

; ---   *   ---   *   ---
; load dst,src

macro smX.sse.ldrr rX,rY,_nullarg& {
  movdqa rX,rY

}

; ---   *   ---   *   ---
; clear [A]

macro smX.sse.clm rX,rY,offset,fdst,_nullarg& {

  match =$00 , offset \{
    pxor xmm8,xmm8

  \}

  fdst xword [rdi+offset],xmm8

}

; ---   *   ---   *   ---
; clear A

macro smX.sse.clr rX,_nullarg& {
  pxor rX,rX

}

; ---   *   ---   *   ---
; equality footer

macro smX.sse.eqX.foot mode,rX,offset,dst {

  smX.sse.eq#mode#.foot.push \
    movdqu xword [dst+offset] '\,' rX,\
    or     rbx '\,' qword [dst+offset+$00],\
    or     rbx '\,' qword [dst+offset+$08]

}

; ---   *   ---   *   ---
; [A] eq [B]

macro smX.sse.eqmm rX,rY,offset,fdst,fsrc,dst {

  ; load registers
  fdst rX,xword [rdi+offset]
  fsrc rY,xword [rsi+offset]

  ; ^chk equality
  pxor rX,rY

  ; ^Q write out
  smX.sse.eqX.foot mm,rX,offset,dst

}

; ---   *   ---   *   ---
; [A] eq B

macro smX.sse.eqmr rX,rY,offset,fdst,fsrc,dst {

  ; load [A] to register
  fdst rX,xword [rdi+offset]

  ; ^chk equality
  pxor rX,rY

  ; ^Q write out
  smX.sse.eqX.foot mr,rX,offset,dst

}

; ---   *   ---   *   ---
; A eq [B]

macro smX.sse.eqrm rX,rY,offset,fdst,fsrc,dst {

  ; load [B] to register
  fsrc rY,xword [rsi+offset]

  ; ^chk equality
  pxor rX,rY

  ; ^Q write out
  smX.sse.eqX.foot rm,rX,offset,dst

}

; ---   *   ---   *   ---
; A eq [B]

macro smX.sse.eqrr rX,rY,offset,fdst,fsrc,dst {

  ; chk equality
  pxor rX,rY

  ; ^Q write out
  smX.sse.eqX.foot rr,rX,offset,dst

}

; ---   *   ---   *   ---
; generate X-sized op

macro smX.sse.walk op,size,args& {

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


  smX.paste_footer op

}

; ---   *   ---   *   ---
; ^table generator ice

macro smX.sse.tab op,eob,args& {

  ; list possible sizes
  local entry
  local entry.len

  List.from entry,entry.len,\
    1,2,4,8

  ; ^make elem for each
  smX.gen_tab \
    smX.sse.walk,word,\
    entry,entry.len,\
    eob,smX.sse.#op,args

}

; ---   *   ---   *   ---
; ^2-dimetional v
;
; first level is alignment
; second is size of elem

macro smX.sse.tab2d op,eob,args& {

  ; individual entry
  macro item args2& \{
    mov eax,r10d
    smX.sse.tab op,foot,args2,args

  \}

  ; ^end-of for each
  macro foot \{
    pop rax
    eob

  \}


  ; branch accto alignment
  push rax

  hybtab word,\
    $00 => .aligned,\
    $01 => .unaligned

  ; ^land
  .aligned:
    item movdqa,movdqa

  .unaligned:
    item movdqu,movdqu

}

; ---   *   ---   *   ---
