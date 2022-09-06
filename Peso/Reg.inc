; ---   *   ---   *   ---
; Reg
; struct-making macros
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Worg
  include '%ARPATH%/forge/Worg.inc'

end if

; ---   *   ---   *   ---

  TITLE     Reg

  VERSION   v0.01.0a
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define Reg@t_sz_db $01
  define Reg@t_sz_dw $02
  define Reg@t_sz_dd $04
  define Reg@t_sz_dq $08

  define sizeof.byte  $01
  define sizeof.word  $02
  define sizeof.dword $04
  define sizeof.qword $08
  define sizeof.xword $10
  define sizeof.yword $20
  define sizeof.zword $40

; ---   *   ---   *   ---
; for <namespace>.elem

macro dotcat a,b {

  define catted
  catted equ a#.#b

}

; ---   *   ---   *   ---

macro Reg@$align_to type {

  local size
  size equ Reg@t_sz_#type

  local status
  local off

  status equ 0
  off equ Reg@offset

  ; dont align on zero
  match =0,off \{
    status equ 1

  \}

  ; ^else check
  match =0,status \{

    local old
    local diff
    local do

    diff equ 0
    old equ off

    do equ ((off) mod size)
    do equ (((do xor (-do)) and $7F) shr 6)

    ; compute aligned size
    rept do \\{
      off equ (0+(((off)+size) and (-size)))
      diff equ ((off)-(old))

    \\}

    ; add padding
    rept diff \\{
      db $00

    \\}

  \}

  Reg@offset equ (off)+size

}

; ---   *   ---   *   ---

macro Reg@$tail_pad type {

  local size
  size equ sizeof.#type

  local status
  local off

  off equ Reg@offset

  local old
  local diff
  local do

  diff equ 0
  old equ off

  do equ ((off) mod size)
  do equ (((do xor (-do)) and $7F) shr 6)

  ; compute aligned size
  rept do \{
    off equ (0+(((off)+size) and (-size)))
    diff equ ((off)-(old))

  \}

  ; add padding
  rept diff \{
    db $00

  \}

}

; ---   *   ---   *   ---
; generates wrappers around data declarations
;
; this makes it so one can 'capture' the arguments
;
; we use this capture to build a members list
; and make various labels from that

macro __fields_beg base {

  ; temporary overwrite!
  irp type, db,dw,dd,dq \{

    macro type x \\{

      local status
      status equ 0

      ; ^(decl) label value
      match name value,x \\\{

        Reg@$align_to type

        ; increment
        Worg@$symcnt Reg@elem_cnt

        ; capture
        List@$push Reg@list,name type value

        ; paste in virtual decl
        dotcat base,name
        catted type value

        status equ 1

      \\\}

      ; anon
      match =0 value,status x \\\{
        Worg@$symcnt Reg@elem_cnt
        List@$push Reg@list,type value

        type value
        local off
        off equ Reg@offset+1

        Reg@offset equ off

      \\\}

    \\}

  \}

}

; ---   *   ---   *   ---
; ^removes the wrappers

macro __fields_end {

  Reg@$tail_pad xword

  irp type, db,dw,dd,dq \{
    purge type

  \}

}

; ---   *   ---   *   ---

macro Reg@$elem_paste inst,list,cnt {

  rept cnt \{

    local status
    local elem

    List@$shift list,elem
    status equ 0

    ; labeled
    match n type value,elem \\{
      dotcat inst,n
      catted type value

      status equ 1

    \\}

    ; anon
    match =0 type value,status elem \\{
      type value

    \\}

  \}

}

; ---   *   ---   *   ---
; entry point

macro Reg@$make name {

  ; accumulate to
  define Reg@list
  define Reg@elem_cnt 0
  define Reg@offset 0
  define Reg@name_of name

  ; runtime access
  define name#@self
  define name#@other

  ; generate virtual instance
  Reg@$nit name
  name name

  define Reg#@#name#@#elem_list
  Reg#@#name#@#elem_list equ Reg@list

  define Reg#@#name#@#elem_cnt
  Reg#@#name#@#elem_cnt equ Reg@elem_cnt

; ---   *   ---   *   ---
; setters (!!)

  macro name#@$self instance \{
    name#@self equ instance

  \}

  macro name#@$other instance& \{
    name#@other equ instance

  \}

; ---   *   ---   *   ---
; make struct instantiable

  ; redefine
  restruc name
  struc name \{

    local list
    list equ Reg#@#name#@#elem_list

    local cnt
    cnt equ Reg#@#name#@#elem_cnt

    ; start of instance
    . = $

    ; walk the elems
    Reg@$elem_paste .,list,cnt

    ; refsym to new instance
    name#@$self .

  \}

  ; repeat definition
  struc virtual_#name addr \{

    local list
    list equ Reg#@#name#@#elem_list

    local cnt
    cnt equ Reg#@#name#@#elem_cnt

    ; start of instance
    virtual at addr
    . = addr

    ; walk the elems
    Reg@$elem_paste .,list,cnt

    ; refsym to new instance
    name#@$self .

    end virtual

  \}

}

; ---   *   ---   *   ---
; generator header/tail

reg fix macro Reg@$nit name {\
  Worg@$npaste struc name \{virtual at 0,\
    first=$,__fields_beg name

end_reg fix Worg@$npaste __fields_end,\
  sizeof.#name=$-first,\
  end virtual,\}}\
  Reg@$make

; ---   *   ---   *   ---
