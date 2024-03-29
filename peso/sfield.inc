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

  VERSION   v0.00.4b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; new/del protos

macro VAR.new name,v= {

  match any , name \{
    define name#._back any

  \}

  define name v

}

macro VAR.del name {
  name equ name#._back
  restore name#._back

}

; ---   *   ---   *   ---
; cstruc

macro sfield.new base,field,v= {

  VAR.new base#.#field,v

  local subc
  subc equ 0

  ; ^subclass Arstd::List
  match =list , v \{

    List.new base#.#field,0

    ; lis undo
    macro base#.#field#.del \\{
      List.del   base#.#field
      sfield.del base,field

    \\}

    subc equ 1

  \}

  ; ^no subclass
  match =0 , subc \{

    ; lis methods
    macro base#.#field#.del \\{
      sfield.del base,field

    \\}

    macro base#.#field#.get _dst \\{
      sfield.get _dst,base,field

    \\}

    macro base#.#field#.set _src \\{
      sfield.set base,field,_src

    \\}

    macro base#.#field#.push _src \\{
      sfield.push base,field,_src

    \\}

    macro base#.#field#.unshift _src \\{
      sfield.unshift base,field,_src

    \\}

  \}

}

; ---   *   ---   *   ---
; ^dstruc

macro sfield.del base,field {
  VAR.del base#.#field

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
