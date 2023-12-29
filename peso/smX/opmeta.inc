; ---   *   ---   *   ---
; PESO SMX OP META
; Methods of construction
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
  use '.inc' peso::swan

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.smX.opmeta

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; operation descriptor

swan.new smX.opmeta

swan.attr ins       , xor
swan.attr ins.size  , byte

swan.attr elem.cnt  , 2
swan.attr elem.type , r+r

swan.end

; ---   *   ---   *   ---
; cstruc^2

macro smX.opmeta.new {

  ; make ice
  local uid
  local rid
  rid equ

  uid.new uid,smX.opmeta,global

  match id , uid \{
    smX.opmeta.new id

  \}


  ; unpack args
  local proto
  local elems
  local lis_sv

  commacut proto,smX.REG.ar
  commacut elems,smX.REG.br


  ; ^proc arg0
  match id lis ===~ size name , uid proto \{
    id\#.ins.set      name
    id\#.ins.size.set size

    rid    equ lis\#size
    lis_sv equ lis

  \}

  ; ^proc arg1
  match id eX , uid elems \{

    local cnt
    local ful
    local type
    local typear

    ful    equ eX
    typear equ

    pluscut cnt,ful

    rept cnt \\{

      pluscut type,ful
      pluscat typear,type

      match id2 any , rid type \\\{
        rid equ id2\\\#any

      \\\}

    \\}

    id\#.elem.cnt.set  cnt
    id\#.elem.type.set typear


    ; generate entry point
    ; if it doesn't yet exist
    match lis , lis_sv \\{

      if ~ defined smX.\\#lis
        smX.opmeta.lisgen lis,cnt

      end if

    \\}

  \}


  ; save to ROM
  match name id , rid uid \{
    define name id

  \}

}

; ---   *   ---   *   ---
; ^rbld

macro smX.opget dst {

  ; get base
  local ins
  local size
  local rid
  rid equ

  commacut ins,smX.REG.ar
  commacut size,smX.REG.br

  ; ^proc arg0
  match size name , ins \{
    rid equ name\#size

  \}


  ; ^get sub-args
  local A
  local B
  local C

  commacut A,smX.REG.cr
  commacut B,smX.REG.dr
  commacut C,smX.REG.er

  smX.opmeta.get_elems rid,A,B,C


  ; build op
  match id , rid \{
    OBJ.new dst,smX.op,id,A,B,C

  \}

}

; ---   *   ---   *   ---
; ^breaks down element type
; from token format

macro smX.opmeta.get_elems dst,[item] {

  common
    local sufix
    sufix equ

  forward match type == data , item \{

    match any , sufix \\{
      sufix equ any\\#type

    \\}

    match , sufix \\{
      sufix equ type

    \\}

  \}

  common

 match id s , dst sufix \{
    dst equ id\#s

  \}

}

; ---   *   ---   *   ---
; entry point template

macro smX.opmeta.liscrux name,cnt {

  ; clear unused
  match =0 , cnt \{
    smX.cl cr
    smX.cl dr
    smX.cl er

  \}

  match =1 , cnt \{
    smX.cl dr
    smX.cl er

  \}

  match =2 , cnt \{
    smX.cl er

  \}

  ; ^add name of op to first arg
  spacecat smX.REG.ar,smX.REG.callee


  ; make op from descriptor
  local op
  smX.opget op

  ; ^give back to caller
  match id , op \{
    smX.mov ar,id

  \}

}

; ---   *   ---   *   ---
; ^entry point generator

macro smX.opmeta.lisgen name,cnt {

  macro smX.#name \{
    smX.opmeta.liscrux name,cnt

  \}

}

; ---   *   ---   *   ---
