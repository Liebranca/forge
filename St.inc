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

; pastes comma separated as lines
macro npaste [line] {forward line}

; comma cats constants (taken from manual ;>)
macro append list,item {

  match any,list \{list equ list ',' item\}
  match ,list \{list equ item\}

}

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

        local cnt

        ; increment
        cnt equ St.elem_cnt
        cnt equ cnt+1

        ; capture
        append St.list,name type value

        ; paste in virtual decl
        dotcat base,name
        catted type value

        ; save counter
        St.elem_cnt equ cnt

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
; entry point

macro St.make name {

  ; accumulate to
  define St.list
  define St.elem_cnt 0

  ; generate virtual instance
  St.nit name
  name name

; ---   *   ---   *   ---
; make struct instantiable

  local list
  list equ St.list

  local cnt
  cnt equ St.elem_cnt

  ; redefine
  restruc name
  struc name \{

    ; start of instance
    . = $

    ; walk the elems
    rept cnt \\{

      local status
      status equ 0

      ; match up to ',' and go to next
      match name type value comma next,list \\\{

        dotcat .,name
        catted type value

        list equ next
        status equ 1

      \\\}

      ; no ','
      match =0 name type value,status list \\\{

        dotcat .,name
        catted type value

        list equ

      \\\}

; ---   *   ---   *   ---

    \\}

  \}

  ; remove globals
  restore St.elem_cnt
  restore St.list

}

; ---   *   ---   *   ---
; generator header and tail

%St fix macro St.nit name {\
  npaste struc name \{virtual at 0,\
    first=$,__fields_beg name

^St fix npaste __fields_end,sizeof.#name=$-first,\
  end virtual,\}}\
  St.make

; ---   *   ---   *   ---
