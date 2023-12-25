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
; info

  TITLE     peso.sfield

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; cstruc

macro sfield.new base,field,v= {

  define base#.#field#._back base#.#field
  define base#.#field v

  ; lis undo
  macro base#.#field#.del \{
    sfield.del base,field

  \}

  ; lis getter
  macro base#.#field#.get dst \{
    sfield.get dst,base,field

  \}

  ; lis setter
  macro base#.#field#.set src \{
    sfield.set base,field,src

  \}

  ; lis push
  macro base#.#field#.push src \{
    sfield.push base,field,src

  \}

  ; lis unshift
  macro base#.#field#.unshift src \{
    sfield.unshift base,field,src

  \}

}

; ---   *   ---   *   ---
; ^dstruc

macro sfield.del base,field {
  base#.#field equ base#.#field#._back
  restore base#.#field#._back

}

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
    dst equ name\#.#field

  \}

}

macro sfield.set base,field,src {

  match name,base \{
    name\#.#field equ src

  \}

}

; ---   *   ---   *   ---
