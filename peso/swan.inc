; ---   *   ---   *   ---
; PESO SWAN
; Soulof
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

  VERSION   v0.00.1b
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

  macro base#.new name,args& \{
    swan.ice base,name,args

  \}

}

; ---   *   ---   *   ---
; ^add field

macro swan.attr name,defval {

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

    if swan.debug
      name#.prich

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
