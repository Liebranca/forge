; ---   *   ---   *   ---
; PESO SWAN
; Meta struc
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

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.swan

  VERSION   v0.00.3b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define hier.cswan

  swan.debug=0

; ---   *   ---   *   ---
; cstruc

macro swan.new base {

  hier.cswan equ base
  sfield.new base,fields

  macro base#.new _name,_args& \{
    swan.ice base,_name,_args

  \}

  macro base#.del _name \{
    swan.del base,_name

  \}

}

; ---   *   ---   *   ---
; ^add field

macro swan.attr name,defval=null {

  match base , hier.cswan \{
    base\#.fields.push name=defval

  \}

}

; ---   *   ---   *   ---
; end cstruc

macro swan.end {

  if swan.debug

    match base , hier.cswan \{
      swan.prich base

    \}

  end if

  hier.cswan equ

}

; ---   *   ---   *   ---
; make copy

macro swan.ice base,name,[item] {

  ; defnit
  common
    swan.copy_fields name,base

  ; ^pass args
  forward match field ===> value , item \{
    name\#.\#field\#.set value

  \}

  ; ^further sugar
  common

    ; lis dbout
    macro name#.prich \{
      swan.prich base,name

    \}

    macro name#.del \{
      swan.del base,name

    \}

    if swan.debug
      display 'NEW ',`base,$20,`name,$0A

    end if

}

; ---   *   ---   *   ---
; ^set default values for ice

macro swan.copy_fields name,base {

  ; walk fields and set
  macro inner [item] \{

    forward match field == value , item \\{
      sfield.new name,field,value

    \\}

  \}

  ; ^run
  match list , base#.fields \{
    inner list

  \}

}

; ---   *   ---   *   ---
; icepick

macro swan.del base,name {

  ; walk fields and dstruc
  macro inner [item] \{

    forward match field == value , item \\{
      name#.\\#field\\#.del

    \\}

  \}

  ; ^run
  match list , base#.fields \{
    inner list

  \}

  if swan.debug
    display 'DEL ',`base,$20,`name,$0A

  end if

}

; ---   *   ---   *   ---
; make aliases for a batch
; of macro wrappers

macro swan.batlis name,base,[item] {

  forward macro name#.#item args& \{
    base#.#item name,args

  \}

}

; ---   *   ---   *   ---
; dbout

macro swan.prich base,ice= {

  ; walk fields
  macro inner [item] \{

    forward match name == value , item \\{

      ; give fields of base
      match , ice \\\{
        display $00,'  ',\\`name,':',\\`value,$0A

      \\\}

      ; ^give fields of ice
      match any , ice \\\{

        match v , ice#.\\#name \\\\{
          display $00,'  ',\\`name,':',\\\\`v,$0A

        \\\\}

      \\\}

    \\}

  \}


  ; give name of base
  match , ice \{
    display $0A,'swan ',`base,$0A

  \}

  ; ^give name of ice
  match any , ice \{
    display $0A,`base,' ',`ice,$0A

  \}


  ; run
  match list , base#.fields \{
    inner list

  \}

  display $0A

}

; ---   *   ---   *   ---
