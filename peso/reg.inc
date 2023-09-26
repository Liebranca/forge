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
; get importer

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.inc' peso::sfield
  use '.asm' peso::unit

import

; ---   *   ---   *   ---
; info

  TITLE     peso.reg

  VERSION   v0.01.1a
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define hier.creg

; ---   *   ---   *   ---
; beg cstruc

macro reg.new name {

  hier.creg equ name

  define name#.$reg.fields

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

    name\#:

    ; ^re-paste accum on non-virtual
    match lines,type\#.$reg.fields \\{
      npaste lines

    \\}

  \}

}

; ---   *   ---   *   ---
