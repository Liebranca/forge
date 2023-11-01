; ---   *   ---   *   ---
; STYLE
; The ubiquitous and oft-used
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     Arstd.Style

  VERSION   v0.00.9b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  MAM.xmode='stat'
  MAM.align=0

; ---   *   ---   *   ---
; top-level switch

macro MAM.head name=crux {

  if MAM.xmode = 'stat'
    format ELF64 executable 3
    entry  name

  else if MAM.xmode = 'obj'
    format ELF64

  end if

  List.new MAM.foot
  List.new MAM.atexit

}

; ---   *   ---   *   ---
; dude, what *is* a SECTION?!

macro MAM.segment name,type,size {

  if MAM.xmode = 'stat'
    segment type

    if MAM.align
      align size

    end if


  else if MAM.xmode = 'obj'

    if MAM.align
      section name align size

    else
      section name

    end if

  end if

}

; ---   *   ---   *   ---
; inneficient way of finding
; a symbol within a list

macro tokin dst,N,[item] {

  common
    local ok
    ok equ 0

  forward match =0 , ok \{

    ; search for literal value of
    local item2
    item2 equ =#item

    ; ^unroll
    match pat , item2 \\{

      match pat , N \\\{
        dst equ 1
        ok  equ 1

      \\\}

    \\}

  \}

}

; ---   *   ---   *   ---
; map size keyword to value

macro i_rX_proto \
  dst,size,b8,b16,b32,b64 {

  dst equ

  ; 8-bit
  match =byte , size \{
    dst equ b8

  \}

  ; ^16-bit
  match =word , size \{
    dst equ b16

  \}

  ; ^32-bit
  match =dword , size \{
    dst equ b32

  \}

  ; ^64-bit
  match =qword , size \{
    dst equ b64

  \}

}

; ---   *   ---   *   ---
; ^map to register
; (E/R) [name] (L/X)

macro i_sized_reg0 dst,name,size {
  i_rX_proto dst,size,\
    name#l,name#x,e#name#x,r#name#x

}

; ---   *   ---   *   ---
; ^(R) [name] (D/W/B)

macro i_sized_reg1 dst,name,size {
  i_rX_proto dst,size,\
    name#b,name#w,name#d,name

}

; ---   *   ---   *   ---
; ^(E/R) [name] (L)

macro i_sized_reg2 dst,name,size {
  i_rX_proto dst,size,\
    name#l,name,e#name,r#name

}

; ---   *   ---   *   ---
; ^sweetcrux

macro i_sized_reg dst,name,size {

  local ok
  ok equ 0

  ; (E/R) [name] (L/X)
  tokin ok,name,a,b,c,d
  match =1 , ok \{
    i_sized_reg0 dst,name,size
    ok equ 2

  \}

  ; (R) [name] (D/W/B)
  match =0 , ok \{
    tokin ok,name,\
      r8,r9,r10,r11,r12,r13,r14,r15

  \}

  match =1 , ok \{
    i_sized_reg1 dst,name,size
    ok equ 2

  \}

  ; (E/R) [name] (L)
  match =0 , ok \{
    tokin ok,name,di,si,bp,sp

  \}

  match =1 , ok \{
    i_sized_reg2 dst,name,size

  \}

}

; ---   *   ---   *   ---
; builds jump table

macro jmptab base,size,[item] {

  common

    local rX
    local kX
    local offset

    ; default to 8-bit tab
    rX     equ dl
    kX     equ db

    offset equ byte [eax+edx]

    ; ^optionally 16-bit
    match =word , size \{

      rX     equ dx
      kX     equ dw

      shl edx,$01
      offset equ word [eax+edx]

    \}

    ; load jmp addr
    mov eax,base
    mov rX,offset
    add eax,edx

    jmp rax

    ; ^jmp table
    base#:


  forward
    kX item - base

}

; ---   *   ---   *   ---
; ^get idex from value

macro lkptab name,size,A,B,[item] {

  common

    ; indirection
    local rX

    ; get size-variant of A register
    i_sized_reg rX,a,size

    ; ^make getter
    macro name#.fet z \{
      mov rX,size [name+z-A]

    \}

    ; clairvoyance [see hybtab]
    if defined name#.jmp_CVY
      name#.jmp

    end if


    ; get ROM size
    local step
    local len
    local y

    step equ sizeof.#size
    len  equ (B-A) * step
    y    equ 0

    ; ^reserve
    name#:
      db len dup $00


  ; insert values in ROM
  forward

    local x
    local dy
    local ok

    ok equ 0

    ; write special value
    match key ===> value , item \{
      x  equ key-A
      dy equ value
      ok equ 1

    \}

    ; ^write plain idex
    match =0 key , ok item \{
      x  equ key-A
      dy equ y

    \}

    store size dy at name+x
    y equ y+1

}

; ---   *   ---   *   ---
; ^jmp-lkp hybrid

macro hybtab base,name,size,A,B,[item] {

  common

    local list
    local len

    list equ
    len  equ 0

  forward

    local ok
    ok equ 0

    ; get [base to F] distance
    match key ===> value , item \{

      List.push list,key => value-base

      ok  equ 1
      len equ len+1

    \}

    ; ^no F, no good
    match =0 key , ok item \{
      out@err 'Value-less key in ',\
        'jmptab ',name

    \}


  common

    ; clairvoyance [see lkptab]
    macro name#.jmp \{
      name#.fet eax
      lea rax,[base+rax]
      jmp rax

    \}

    define name#.jmp_CVY 1

    ; get modified arg list
    local flat
    flat equ

    List.cflatten list,len,flat

    ; ^spawn ROM
    match any,flat \{
      lkptab name,size,A,B,any

    \}

    restore name#.jmp_CVY

}

; ---   *   ---   *   ---
; pastes comma separated as lines

macro npaste [line] {forward line}

macro npaste2 [line] {

  forward

    local elem
    local status

    status equ 0
    elem   equ line

  rept 2 \{

    status equ 0

    ; split m[,]
    match item =, next,elem \\{

      item

      elem   equ next
      status equ 1

    \\}

    ; ^single item
    match =0 any args,status elem \\{

      any args

      elem   equ
      status equ 1

    \\}

  \}

}

; ---   *   ---   *   ---
; please end my suffering

macro fnpaste list {
  macro inner [item] \{forward item\}
  match any,list \{inner any\}

}

macro fnpaste2 pro,list {
  pro
  fnpaste list

}

; ---   *   ---   *   ---
; space cats at end

macro spacecat s,token {

  match any,s \{s equ s token\}
  match ,s \{s equ token\}

}

; ---   *   ---   *   ---
; ^space cats at beg

macro r_spacecat s,token {

  match any,s \{s equ token s\}
  match ,s \{s equ token\}

}

; ---   *   ---   *   ---
; uses a symbolic constant as a counter (!!)

macro symcnt sym,value=+1 {

  local cnt

  ; increment
  cnt equ sym
  cnt equ cnt#value

  sym equ cnt

}

; ---   *   ---   *   ---
; stringify and cat

macro strfcat a,b,c {
  a equ `a#`b#`c

}

macro stircat dst,a,b,c {
  dst equ a#`b#`c

}

macro tcat dst,a,b,c {
  dst equ a#b#c

}

; ---   *   ---   *   ---
; sets a to catted a,b,c
; ignores b if a is blank

macro stirr7 a,b,c {

  match any,a \{
    a equ any\#b#c

  \}

  match ,a \{
    a equ c

  \}

}

; ---   *   ---   *   ---
; cat b to beg of a

macro prefix a,b {
  a equ b#a

}

; ---   *   ---   *   ---
