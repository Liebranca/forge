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

macro npaste [line] {forward line}

macro __fields_beg base {

  irp type, db,dw,dd,dq \{
    macro type x \\{

      match name value,x \\\{
        name type value

      \\\}

    \\}

  \}

}

macro __fields_end {

  irp type, db,dw,dd,dq \{
    purge type

  \}

}

; ---   *   ---   *   ---

macro St.make x {
  St.nit x
  x x
}

%St fix macro St.nit name {\
  npaste struc name \{virtual at 0,\
    first=$,__fields_beg name,

^St fix npaste __fields_end,sizeof.#name=$-first,\
  end virtual,\}}\
  St.make

; ---   *   ---   *   ---
