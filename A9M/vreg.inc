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

  VERSION   v0.00.3b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; decl wraps

macro vreg.new name,nullarg& {
  reg.new name

}

; ---   *   ---   *   ---
; ^closer

macro vreg.end {

  match name , hier.creg \{

    ; lis cstruc
    macro name\#.new dst,seg= \\{
      vreg.ice dst,name,seg

    \\}

    ; lis get/set
    local fields
    vreg.get_fields fields,name

    ; ^run lisser
    match list , fields \\{
      vreg.lisattr name,list

    \\}


    ; lis dbout
    macro name\#.prich src,parshow=1 \\{
      vreg.prich src,parshow

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
; ^run unary op on attr

macro vreg.uop dst,op,field {

  match id , dst \{

    vmem.#op id\#%origin,\
      id\#field,id\#field#.size

  \}

}

; ---   *   ---   *   ---
; ^binary

macro vreg.bop dst,src,op,field {

  match id , dst \{

    vmem.#op id\#%origin,src,\
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

    vreg.lisops type,size,tag

  \}

}

; ---   *   ---   *   ---
; ^aliases binary/unary ops

macro vreg.lisops type,size,tag {

  ; ^unary sig
  macro u_inner [op] \{

    forward macro type#tag#.\#op dst \\{
      vreg.uop dst,op,tag

    \\}
  \}

  match list , vmem.uops_list \{
    u_inner list

  \}


  ; ^binary sig
  macro b_inner [op] \{

    forward macro type#tag#.\#op dst,src \\{
      vreg.bop dst,src,op,tag

    \\}

  \}

  match list , vmem.bops_list \{
    b_inner list

  \}

}

; ---   *   ---   *   ---
; make vmem with size of struc
; then cast vmem to struc

macro vreg.ice dst,type,seg= {

  ; cat to existing buffer
  ; if addr passed
  match addr , seg \{
    vmem.seg dst,addr,blk sizeof.#type

  \}

  ; ^else make new buffer
  match , seg \{
    vmem.new dst,blk sizeof.#type

  \}


  ; ^typecast vmem ptr
  match id , dst \{
    vreg.cast dst,id type

  \}

}

; ---   *   ---   *   ---
; struc typecast on virtual memory

macro vreg.cast dst,PT {

  ; walk fields
  macro inner lis,lis_t,[item] \{

    forward match size tag , item \\{

      lis\\#tag = lis_t\\#tag

      sizeof.\#lis\\#tag\\#.size=sizeof.\\#size

      define lis\\#tag\\#.size size

    \\}

  \}

  ; ^run
  match par type , PT \{

    local fields
    vreg.get_fields fields,type

    ; make new lis
    local uid
    uid.new uid,type\#%vcast,npglobal

    ; ^make lis.[X],lis.[X].size
    match name list , uid fields \\{
      inner name,type,list

      ; save parent id and overwrite dst
      define name\\#%origin par
      define name\\#%type   type
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

macro vreg.prich src,parshow=1 {

  match id , src \{
    vmem.prich id\#%origin,parshow

  \}

}

; ---   *   ---   *   ---
