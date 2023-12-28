; ---   *   ---   *   ---
; PESO SMX COMMON
; Galactic unrolls
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
  use '.hed' peso::branch

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.smX.common

  VERSION   v0.00.4b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  smX.CDEREF = $CDEF

; ---   *   ---   *   ---
; GBL

  define smX.REG.ar
  define smX.REG.br
  define smX.REG.cr
  define smX.REG.dr

; ---   *   ---   *   ---
; ^pass value

macro smX.mov dst,value& {
  smX.REG.#dst equ value

}

; ---   *   ---   *   ---
; ^clear

macro smX.cl dst {
  smX.REG.#dst equ

}

; ---   *   ---   *   ---
; ^invoke macro

macro smX.call name {smX.#name}

; ---   *   ---   *   ---
; ~an idea we might revisit later

macro OBJ.new dst,type,args& {

  ; generate id
  local uid
  uid.new uid,type,global

  ; ^pass [id,args] to cstruc
  match id , uid \{

    type#.new id
    id\#.onew args

    dst equ id

  \}

}

; ---   *   ---   *   ---
; declares a footer generator
; specific to an operation

macro smX.decl_foot fam,[op] {

  forward match any , op \{
    List.new smX.#fam#.\#op\#.foot
    smX.smX.#fam#.\#op\#.has_foot equ 1

  \}

}

; ---   *   ---   *   ---
; ^append footer if present

macro smX.paste_foot op {

  match =1 , op#.has_foot \{
    op#.foot
    op#.foot.clear

  \}

}

; ---   *   ---   *   ---
; maps i64 to [zxy]mm
; quite foolish, but useful

macro smX.sized_reg dst,name,size {

  if sizeof.#size < $10
    i_sized_reg dst,name,size

  else

    local xname
    xname equ name

    smX.i2xmap xname
    match any , xname \{
      x_sized_reg dst,any,size

    \}

  end if

}

; ---   *   ---   *   ---
; ^this is why it's foolish,
;
; here's what the mapping
; looks like:
;
; * a__,b__,c__,d__  => _0,_1,_2,_3
; * di_,si_,r8_,r9_  => _4,_5,_6,_7
; * r10,r11,r12,r13  => _8,_9,10,11
; * r14,r15,bp_,sp_  => 12,13,14,15
;
;
; it means segfaults gallore
; if used mindlessly!

define smX.i2xmap_i \
  a  ,b  ,c  ,d  ,\
  di ,si ,r8 ,r9 ,\
  r10,r11,r12,r13,\
  r14,r15,bp ,sp

macro smX.i2xmap name {

  local idex
  idex equ 'I'

  match list , smX.i2xmap_i \{
    tokin idex,name,list

  \}

  match any , idex \{
    name equ any

  \}

}

; ---   *   ---   *   ---
; generic jmptable maker

macro smX.gen_tab crux,size,\
  entry,entry.len,eob,op,args& {

  ; make id for table
  local id
  uid.new id,smX,local dotless

  ; generate symbol list
  macro inner.get_branch dst,len,[n] \{

    forward
      List.push dst,len => name2\#b\#n
      len equ len+1

  \}


  ; ^place symbols
  macro inner.push_tab name2,[n] \{

    forward

      .\#name2\#.b\#n:
        crux op,n,args
        eob

  \}


  ; get arg list for inner
  local branch
  local branch.len
  local branch.flat
  local entry.flat

  branch      equ
  branch.len  equ 0
  branch.flat equ
  entry.flat  equ
  List.cflatten \
    entry,entry.len,entry.flat


  ; exec all
  match any list , id entry.flat \{

    ; get symbols
    inner.get_branch branch,branch.len,list
    List.cflatten branch,branch.len,branch.flat

    ; ^make table
    match tab , branch.flat \\{
      hybtab size,tab

    \\}

    ; ^spawn entries
    inner.push_tab any,list

  \}

}

; ---   *   ---   *   ---
