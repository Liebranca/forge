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
  use '.inc' peso::sfield
  use '.inc' peso::unit

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.reg

  VERSION   v0.01.3a
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define hier.creg

; ---   *   ---   *   ---
; beg cstruc

macro reg.new name,args& {

  hier.creg equ name

  define name#.$reg 1
  define name#.$reg.fields

  define name#.$reg.args args

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
; ^end-of

macro reg.end {

  match any,hier.creg \{

    ; alignment wraps
    sfield.push hier.creg,$reg.fields,\
      unit.malign

    sfield.unshift hier.creg,$reg.fields,\
      unit.malign


    ; ^paste accum
    match lines,any\#.$reg.fields \\{
      npaste lines

    \\}

    ; get size after alignment
    sizeof.\#any=$-any

  \}

  ; terminate
  end virtual

}

; ---   *   ---   *   ---
; ^make static ice

macro reg.ice tn {

  match type name,tn \{

    unit.malign
    name\#:

    ; ^re-paste accum on non-virtual
    match lines,type\#.$reg.fields \\{
      npaste lines

    \\}

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
      match =unit.malign,line \\{
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
      match =unit.malign,line \\{
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
