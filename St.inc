; ---   *   ---   *   ---
; ST
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

  TITLE     St

  VERSION   v0.00.2a
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; for <namespace>.elem

macro dotcat a,b {

  define catted
  catted equ a#.#b

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

      ; ^(decl) label value
      match name value,x \\\{

        ; increment
        Worg@$symcnt St@elem_cnt

        ; capture
        List@$push St@list,name type value

        ; paste in virtual decl
        dotcat base,name
        catted type value

      \\\}

    \\}

  \}

}

; ---   *   ---   *   ---
; ^removes the wrappers

macro __fields_end {

  irp type, db,dw,dd,dq \{
    purge type

  \}

}

; ---   *   ---   *   ---

macro St@$elem_paste inst,list,cnt {

  rept cnt \{

    define elem
    List@$shift list,elem

    match n type value,elem \\{

      dotcat inst,n
      catted type value

    \\}

    restore elem

  \}

}

; ---   *   ---   *   ---
; entry point

macro St@$make name {

  ; accumulate to
  define St@list
  define St@elem_cnt 0

  ; runtime access
  define name#@self
  define name#@other

  ; generate virtual instance
  St@$nit name
  name name

  define St#@#name#@#elem_list
  St#@#name#@#elem_list equ St@list

  define St#@#name#@#elem_cnt
  St#@#name#@#elem_cnt equ St@elem_cnt

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
    list equ St#@#name#@#elem_list

    local cnt
    cnt equ St#@#name#@#elem_cnt

    ; start of instance
    . = $

    ; walk the elems
    St@$elem_paste .,list,cnt

    ; refsym to new instance
    name#@$self .

  \}

  ; repeat definition
  struc virtual_#name addr \{

    local list
    list equ St#@#name#@#elem_list

    local cnt
    cnt equ St#@#name#@#elem_cnt

    ; start of instance
    virtual at addr
    . = addr

    ; walk the elems
    St@$elem_paste .,list,cnt

    ; refsym to new instance
    name#@$self .

    end virtual

  \}

}

; ---   *   ---   *   ---
; generator header/tail

%St fix macro St@$nit name {\
  Worg@$npaste struc name \{virtual at 0,\
    first=$,__fields_beg name

^St fix Worg@$npaste __fields_end,\
  sizeof.#name=$-first,\
  end virtual,\}}\
  St@$make

; ---   *   ---   *   ---