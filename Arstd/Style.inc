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

  VERSION   v0.00.7b
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

  MAM.atexit.push call reap

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
