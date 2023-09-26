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
; get importer

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
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

  define name#.fields

  virtual at $00
  name#:

}

; ---   *   ---   *   ---
; ^add field

macro my decl {

  local name

  match any,hier.creg \{

    match prev,any\#.fields \\{
      any\#.fields equ any\#.fields,decl

    \\}

    match ,any\#.fields \\{
      any\#.fields equ decl

    \\}

  \}

}

; ---   *   ---   *   ---
; ^end

macro reg.end {

  match any,hier.creg \{

    match lines,any\#.fields \\{
      npaste lines

    \\}

    unit.malign
    sizeof.\#any=$-any

  \}

  end virtual
  hier.creg equ

}

; ---   *   ---   *   ---
; ^make static ice

macro reg.ice tn {

  match type name,tn \{

    unit.malign

    name:
    match lines,type\#.fields \\{
      npaste lines

    \\}

  \}

}

; ---   *   ---   *   ---
