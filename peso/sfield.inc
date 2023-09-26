; ---   *   ---   *   ---
; S(UB)FIELD
; get this dot something
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
; info

  TITLE     peso.sfield

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; add element to end of list

macro sfield.push base,field,src {

  local list

  match name,base \{
    list equ name\#.\#field

  \}

  match prev,list \{
    list equ prev,src

  \}

  match ,list \{
    list equ src

  \}

  sfield.set base,field,list

}

; ---   *   ---   *   ---
; ^same thing in reverse

macro sfield.unshift base,field,src {

  local list

  match name,base \{
    list equ name\#.\#field

  \}

  match prev,list \{
    list equ src,prev

  \}

  match ,list \{
    list equ src

  \}

  sfield.set base,field,list

}

; ---   *   ---   *   ---
; ^get/set subfield

macro sfield.get dst,base,field {

  match name,base \{
    dst=name\#.#field

  \}

}

macro sfield.set base,field,src {

  match name,base \{
    name\#.#field equ src

  \}

}

; ---   *   ---   *   ---
