; ---   *   ---   *   ---
; REG
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

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'
  use '.inc' Arstd::IO

import

; ---   *   ---   *   ---

  TITLE     peso.reg

  VERSION   v0.01.0a
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define reg@curkls

  define reg@t_sz_db $01
  define reg@t_sz_dw $02
  define reg@t_sz_dd $04
  define reg@t_sz_dq $08

  define sizeof.byte  $01
  define sizeof.word  $02
  define sizeof.dword $04
  define sizeof.qword $08
  define sizeof.xword $10
  define sizeof.yword $20
  define sizeof.zword $40

; ---   *   ---   *   ---

macro reg@$align_to type {

  local size
  size equ reg@t_sz_#type

  local status
  local off

  status equ 0
  off equ reg@offset

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

  reg@offset equ (off)+size

}

; ---   *   ---   *   ---

macro reg@$tail_pad type {

  local size
  size equ sizeof.#type

  local status
  local off

  off equ reg@offset

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

        reg@$align_to type

        ; increment
        symcnt reg@elem_cnt

        ; capture
        List@$push reg@list,name type value

        ; paste in virtual decl
        local catted
        catted equ base

        stirr7 catted,.,name
        catted type value

        status equ 1

      \\\}

      ; anon
      match =0 value,status x \\\{
        symcnt reg@elem_cnt
        List@$push reg@list,type value

        type value
        local off
        off equ reg@offset+1

        reg@offset equ off

      \\\}

    \\}

  \}

}

; ---   *   ---   *   ---
; ^removes the wrappers

macro __fields_end {

  reg@$tail_pad xword

  irp type, db,dw,dd,dq \{
    purge type

  \}

}

; ---   *   ---   *   ---

macro reg@$elem_paste inst,list,cnt {

  rept cnt \{

    local status
    local elem

    List@$shift list,elem
    status equ 0

    ; labeled
    match n type value,elem \\{

      local catted
      catted equ inst

      stirr7 catted,.,n
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

macro reg@$make name {

  ; accumulate to
  define reg@list
  define reg@elem_cnt 0
  define reg@offset 0
  define reg@name_of name

  ; runtime access
  define name#@self
  define name#@other

  ; generate virtual instance
  reg@$nit name
  name name

  define reg#@#name#@#elem_list
  reg#@#name#@#elem_list equ reg@list

  define reg#@#name#@#elem_cnt
  reg#@#name#@#elem_cnt equ reg@elem_cnt

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
    list equ reg#@#name#@#elem_list

    local cnt
    cnt equ reg#@#name#@#elem_cnt

    ; start of instance
    . = $

    ; walk the elems
    reg@$elem_paste .,list,cnt

    ; refsym to new instance
    name#@$self .

  \}

  ; repeat definition
  struc virtual_#name addr \{

    local list
    list equ reg#@#name#@#elem_list

    local cnt
    cnt equ reg#@#name#@#elem_cnt

    ; start of instance
    virtual at addr
    . = addr

    ; walk the elems
    reg@$elem_paste .,list,cnt

    ; refsym to new instance
    name#@$self .

    end virtual

  \}

}

; ---   *   ---   *   ---
; generator header/tail

reg fix macro reg@$nit name {\
  npaste struc name \{virtual at 0,\
    first=$,__fields_beg name

end_reg fix npaste __fields_end,\
  sizeof.#name=$-first,\
  end virtual,\}}\
  reg@$make

; ---   *   ---   *   ---

macro wed ni {

  local status
  status equ 0

  match name ins,ni \{
    reg@curkls equ name
    match any,reg@curkls \\{
      any\#@$self ins

    \\}

    status equ 1

  \}

  match =0,status \{
    reg@curkls equ ni

  \}

}

; ---   *   ---   *   ---

macro xmac name,args& {

  match any,reg@curkls \{
    any\#@$#name args

  \}

}

; ---   *   ---   *   ---
