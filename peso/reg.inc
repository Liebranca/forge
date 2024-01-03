; ---   *   ---   *   ---
; REG
; Struc maker
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

  use '.inc' Arstd::uid

  use '.inc' peso::seg
  use '.inc' peso::sfield

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.reg

  VERSION   v0.01.6a
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define hier.creg

; ---   *   ---   *   ---
; beg cstruc

macro reg.new name,vflag= {

  hier.creg equ name

  define name#.$reg 1

  define name#.$reg.fields
  define name#.$reg.fields_sz
  define name#.$reg.fields_len

  ; put definition 'on hold' ;>
  virtual at $00
  name#:

}

; ---   *   ---   *   ---
; ^add field

macro my decl {
  sfield.push hier.creg,$reg.fields,decl

}

; ---   *   ---   *   ---
; ^actually record the size
; of this field!

macro szmy decl {

  match size ND? , decl \{

    local sX
    local ct
    local id

    ; default to null
    id equ ND?
    ct equ $00

    ; passed name => data?
    match tag any , ND? \\{
      id equ tag
      ct equ any

    \\}

    ; get size as data decl
    i_sized_data sX,size

    ; ^add field
    match name , id \\{
      my .\\#name sX ct

    \\}

    sfield.push hier.creg,$reg.fields_sz,size


    ; note length of sz array
    local len

    sfield.get len,hier.creg,$reg.fields_len
    sfield.set hier.creg,$reg.fields_len,len+1

  \}

}

; ---   *   ---   *   ---
; ^add inherit

macro reg.beq type {

  ; mark start of inherited block
  my .beq.#type = $

  ; ^push fields
  macro inner [decl] \{forward my decl\}
  match lines,type#.$reg.fields \{inner lines\}

}

; ---   *   ---   *   ---
; ^end-of

macro reg.end {

  match any,hier.creg \{

    ; ^paste accum
    match lines , any\#.$reg.fields \\{
      npaste lines

    \\}

    ; get size after alignment
    MAM.malign unit

    _endof.\#any=$
    sizeof.\#any=_endof.\#any-any

  \}

  ; terminate
  end virtual

}

; ---   *   ---   *   ---
; ^make static ice

macro reg.ice tn,vflag= {

  match type name,tn \{

    MAM.calign unit
    name\#:

    ; ^re-paste accum on non-virtual
    match lines,type\#.$reg.fields \\{
      npaste lines

    \\}

    MAM.malign unit
    sizeof.\#name=$-name

    ; set public/private
    local vis
    MAM.sym_vflag vis,name,vflag

  \}

}

; ---   *   ---   *   ---
; ^tad more effed, gets name
; of each field and makes
; defines for each base+offset

macro reg.vice base,tn {

  macro inner dst,type,[line] \{

    local ok

    forward

      ok equ 1
      match =MAM.malign,line \\{
        ok equ 0

      \\}

      match =1 name any,ok line \\{
        reg.vice_cat dst,name,base,type

      \\}

  \}

  match type name,tn \{

    ; ^re-paste accum on non-virtual
    match lines,type\#.$reg.fields \\{
      inner name,type,lines

    \\}

    define name base

  \}

}

; ---   *   ---   *   ---
; ^join tokens

macro reg.vice_cat dst,name,base,type {
  define dst#name base+type#name

}

; ---   *   ---   *   ---
; highly effed
;
; do the same as vice, but
; add lines to queues

macro reg.qvice Q0,Q1,len,base,tn {

  macro inner dst,type,[line] \{

    local ok

    forward

      ok equ 1
      match =MAM.malign,line \\{
        ok equ 0

      \\}

      match =1 name any,ok line \\{
        reg.qvice_cat Q0,Q1,dst,name,base,type
        len equ len+1

      \\}

  \}

  match type name,tn \{

    ; ^re-paste accum on non-virtual
    match lines,type\#.$reg.fields \\{
      inner name,type,lines

    \\}

; bit already done somewhere else
;
;    len equ len+1
;    List.push Q0,define  name base
;    List.push Q1,restore name

  \}

}

; ---   *   ---   *   ---
; ^Q'd join tokens

macro reg.qvice_cat Q0,Q1,dst,name,base,type {
  List.push Q0,define  dst#name base+type#name
  List.push Q1,restore dst#name

}

; ---   *   ---   *   ---
