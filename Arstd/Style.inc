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

  VERSION   v0.01.3b
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
; ^map to data decl

macro i_sized_data dst,size {
  i_rX_proto dst,size,db,dw,dd,dq

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
; get memreq of lkptab

macro lkptab.get_req name,size,[item] {

  ; find [beg,end] in args
  common

    name#._v.dA  = $FFFF
    name#._v.dB  = $0000

    name#._v.def = $00

  ; ^walk args
  forward

    local ok
    ok equ 0

    ; item is default case
    match =def ===> value , item \{
      name#._v.def = value
      ok equ 1

    \}

    ; item is [key,value]
    match =0 key ===> value , ok item \{
      name#._v.n = key
      ok equ 1

    \}

    ; ^item is plain idex
    match =0 key , ok item \{
      name#._v.n = key

    \}


    ; get new [beg,end]
    if name#._v.n < name#._v.dA
      name#._v.dA = name#._v.n

    end if

    if name#._v.n > name#._v.dB
      name#._v.dB = name#._v.n

    end if

}

; ---   *   ---   *   ---
; similar to jmptab
; gets idex from value

macro lkptab name,size,[item] {

  ; spawn table
  common

    ; get size-variant of A register
    local rX
    i_sized_reg rX,a,size

    ; get ROM size
    local step
    local len
    local y

    lkptab.get_req name,size,item

    step equ sizeof.#size
    len  equ name#._v.dB-name#._v.dA+1

    y equ 0


    ; make getter
    macro name#.fet z,bounded= \{

      match any,bounded \\{

        ; save tmp
        push r15
        push r14

        ; ^clear
        xor r15b,r15b
        mov r14b,$01

        ; get clamping needed
        cmp   z,name#._v.dB
        cmovg r15d,r14d
        cmp   z,name#._v.dA
        cmovl r15d,r14d

        ; ^give default value if so
        mov    r14d,name#._v.def
        test   r15b,r15b
        cmovnz z,r14d

        ; restore tmp
        pop r14
        pop r15

        ; skip fetch if clamped
        jnz name#._bounded

      \\}

      ; unbounded fetch is 1400% better
      mov rX,size [((z)*step+name)\
        -(name#._v.dA*step)]

      name#._bounded:

    \}

    ; clairvoyance [see hybtab]
    if defined name#.jmp_CVY
      name#.jmp

    end if


    ; reserve N bytes
    local dX
    i_sized_data dX,size

    name#:
      dX len dup name#._v.def


  ; insert values in ROM
  forward

    local x
    local dy
    local ok

    ok equ 0

    ; write nothing for default case
    match =def ===> value , item \{
      x  equ
      ok equ 1

    \}

    ; write special value
    match =0 key ===> value , ok item \{
      x  equ ((key)*step)-(name#._v.dA*step)
      dy equ value
      ok equ 1

    \}

    ; ^write plain idex
    match =0 key , ok item \{
      x  equ ((key)*step)-(name#._v.dA*step)
      dy equ y

    \}

    match any,x \{
      store size dy at name+x
      y equ y+1

    \}

}

lkptab.bounded = 0

; ---   *   ---   *   ---
; ^jmp-lkp hybrid

macro hybtab name,size,[item] {

  ; make new list for args
  common

    local list
    local len

    list equ
    len  equ 0


  ; ^modify args and write to list
  forward

    local ok
    ok equ 0

    ; get [base to F] distance
    match key ===> value , item \{

      List.push list,key => value-name

      ok  equ 1
      len equ len+1

    \}

    ; ^no F, no good
    match =0 key , ok item \{
      out@err 'Value-less key',key,\
      'in jmptab ',name,

    \}


  ; ^use args to make lkptab
  common

    ; clairvoyance [see lkptab]
    macro name#.jmp \{

      if lkptab.bounded = 1
        name#.fet eax,bounded

      else
        name#.fet eax

      end if


      lea rax,[name+rax]
      jmp rax

    \}

    define name#.jmp_CVY 1

    ; get modified arg list
    local flat
    flat equ

    List.cflatten list,len,flat

    ; ^spawn ROM
    match any,flat \{
      lkptab name,size,any

    \}

    restore name#.jmp_CVY

}

; ---   *   ---   *   ---
; ^lets you define branches
; as you code them

macro branchtab name,bounded?= {

; ---   *   ---   *   ---
; NOTE:
;
; bounds-checked table fetches
; are beyond terrible in terms
; of codesize when compared to
; an unbounded fetch, which is a
; single instruction
;
; because of this, boundschecks
; are never on by default
;
; i advice you only use this feature
; when all alternatives suck harder

  ._v.bt.#name#.bounded=0

  match =bounded , bounded? \{
    ._v.bt.#name#.bounded=1

  \}

; ---   *   ---   *   ---
; NOTE:
;
; by the grace of God, this
; method of byte-castling
; from virtual data was
; made clear to me from
; a single glance.
;
; * force the entirety of the
;   code to be defined within
;   a virtual block starting at $00
;
; * take note of start offset for each
;   branch, ie keep an array of labels
;
; * calculate the size of the virtual block,
;   as well as the "promised" beg of real,
;   then use that to adjust the offsets
;   so they point to real addresses
;
; * paste the lkp-jmp hybrid table from
;   the array of labels [see hybtab]
;
; * paste the virtual data into the file,
;   by way of load and declare, repeat
;   times size of block


  ; begin a virtual block
  List.new ._v.bt.#name#.keys

  virtual at $00
  ._v.bt.#name#._vmem::


  ; adds new entry to table
  macro name#.branch vk \{

    match value ===> key , vk \\{

      ; [key,value] eqv for table
      ._v.bt.#name#.keys.push vk

      ; take virtual offset
      key = $

    \\}

  \}


  ; ^terminate table
  macro name#.end \{


    ; get byte count
    ._v.bt.#name#._vmem.size=$
    end virtual

    ; ^get size of table entry
    local size

    if $FF < ._v.bt.#name#._vmem.size
      size equ word

    else
      size equ byte

    end if


    ; get jmptab branches
    local list
    ._v.bt.#name#.keys.cflatten list

    ; ^re-calculate labels
    macro recalc_offset [item] \\{

      ; virtual offset + start of real memory
      match value ===> key , item \\\{
        key = ._v.bt.#name#._rmem.base + key

      \\\}

    \\}


    ; ^adjust labels and paste table
    match any args, size list \\{
      recalc_offset args

      lkptab.bounded=._v.bt.#name#.bounded
      hybtab .#name,any,args

      lkptab.bounded=0

    \\}


    ; ^paste ct of vmem
    ._v.bt.#name#._rmem.base=$
    repeat ._v.bt.#name#._vmem.size

      load ._v.bt.lb from \
        ._v.bt.#name#._vmem:%-1

      db ._v.bt.lb

    end repeat

  \}

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
