; ---   *   ---   *   ---
; A9M VREG
; Strucs on virtual memory
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
  use '.inc' peso::reg
  use '.inc' A9M::vmem

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.vreg

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; decl wraps

macro vreg.new name,nullarg& {
  reg.new name

}

; ---   *   ---   *   ---
; ^closer
;
; TODO:
;
; * wraps for vmem.seg

macro vreg.end {

  match name , hier.creg \{

    ; lis cstruc
    macro name\#.new dst \\{
      vreg.ice dst,name

    \\}

    ; lis get/set
    local fields
    vreg.get_fields fields,name

    ; ^run lisser
    match list , fields \\{
      vreg.lisattr name,list

    \\}


    ; lis dbout
    macro name\#.prich src \\{
      vreg.prich src

    \\}

  \}

  reg.end

}

; ---   *   ---   *   ---ç
; generic setattr

macro vreg.set dst,field,value {

  match id , dst \{
    vmem.set id\#%origin,value,\
      id\#field,id\#field#.size

  \}

}

; ---   *   ---   *   ---ç
; ^getattr

macro vreg.get dst,src,field {

  match id , src \{
    vmem.get dst,id\#%origin,\
      id\#field,id\#field#.size

  \}

}

; ---   *   ---   *   ---
; ^canefield

macro vreg.lisattr type,[item] {

  forward match size tag , item \{

    macro type\#tag\#.set dst,value \\{
      vreg.set dst,tag,value

    \\}

    macro type\#tag\#.get dst,src \\{
      vreg.get dst,src,tag

    \\}

  \}

}

; ---   *   ---   *   ---
; ^make vmem with size of struc
; then cast vmem to struc

macro vreg.ice dst,type {

  vmem.new dst,blk sizeof.#type

  match id , dst \{
    vreg.cast dst,id=>type id\#.beg

  \}

}

; ---   *   ---   *   ---
; virtual type-cast

macro vreg.cast dst,PTA {

  ; walk fields
  macro inner lis,lis_t,base,[item] \{

    forward match size tag , item \\{
      lis\\#tag = (base+lis_t\\#tag)
      define lis\\#tag\\#.size size

    \\}

  \}

  ; ^run
  match par ===> type addr , PTA \{

    local fields
    vreg.get_fields fields,type

    ; make new lis
    local uid
    uid.new uid,type\#%vcast,npglobal

    ; ^make lis.[X],lis.[X].size
    match name list , uid fields \\{
      inner name,type,addr,list

      ; save parent id and overwrite dst
      define name\\#%origin par
      dst equ name

    \\}

  \}

}

; ---   *   ---   *   ---
; ^gets [name => size] array

macro vreg.get_fields dst,type {

  local decl
  local size

  decl equ type#.$reg.fields
  size equ type#.$reg.fields_sz

  dst equ

  rept type#.$reg.fields_len \{

    local d
    local s

    commacut d,decl
    commacut s,size

    match name any , d \\{
      d equ name

    \\}

    commacat dst,s d

  \}

}

; ---   *   ---   *   ---
; dbout wraps

macro vreg.prich src {

  match id , src \{
    vmem.prich id\#%origin

  \}

}

; ---   *   ---   *   ---
