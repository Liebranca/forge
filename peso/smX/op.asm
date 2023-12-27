; ---   *   ---   *   ---
; PESO SMX OP
; Abstracting work itself
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
  use '.inc' peso::swan
  use '.asm' peso::smX::common

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.smX.op

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; operation struc

swan.new smX.op

swan.attr name,xor
swan.attr elems,2
swan.attr mode,i64

swan.attr elem_A,null
swan.attr elem_B,null
swan.attr elem_C,null

swan.attr elem_A_deref,null
swan.attr elem_B_deref,null
swan.attr elem_C_deref,null

swan.attr elem_A_tmp,null
swan.attr elem_B_tmp,null
swan.attr elem_C_tmp,null

swan.end

; ---   *   ---   *   ---
; ^ROM

  define smX.op.xor_elems  2
  define smX.op.or_elems   2

  define smX.op.mov_elems  2
  define smX.op.cmp_elems  2
  define smX.op.test_elems 2

; ---   *   ---   *   ---
; ^cstruc

macro smX.op.new dst,md,op,item& {

  ; generate iced
  local uid
  uid.new uid,smX.op,global

  ; ^unroll and make ice
  match id , uid \{

    smX.op.new id,\
      name  => op,\
      elems => smX.op.#op#_elems,\
      mode  => md

    dst equ id

    ; nit operands if passed
    match elems , item \{
      smX.op.set_elems id,elems

    \}

  \}

}

; ---   *   ---   *   ---
; ^assign operands

macro smX.op.set_elems %O,[item] {

  ; nit operand id
  common
    local elem
    elem equ A


  ; ^set
  forward

    ; throw on items > 3
    match =END , elem \{
      out@err "Overargs for i64.op ",`op

    \}

    match any,elem \{
      %O#.elem_\#any\#.set item

    \}

    ; ^go next
    match =C , elem \{
      elem equ END

    \}

    match =B , elem \{
      elem equ C

    \}

    match =A , elem \{
      elem equ B

    \}

}

; ---   *   ---   *   ---
; dstruc

macro smX.op.del %O {
  smX.op.bat_free_tmp %O,A,B,C
  %O#.del

}

; ---   *   ---   *   ---
; borrow a register

macro smX.op.get_tmp %O,dst,args {

  match mode , %O#.mode \{
    smX.\#mode\#.get_mem dst,args

  \}

}

; ---   *   ---   *   ---
; ^undo

macro smX.op.free_tmp %O,UDN {

  ; get tmp used
  local status
  status equ 0

  match =null,%O#.elem_#UDN#_tmp \{
    status equ 1

  \}

  ; ^yep, give back
  match =0 mode any , status \
    %O#.mode %O#.elem_#UDN#_tmp \{

    smX.\#mode\#.free_mem any
    %O#.elem_#UDN#_tmp equ null

  \}

}

; ---   *   ---   *   ---
; ^bat

macro smX.op.bat_free_tmp %O,[UDN] {
  forward smX.op.free_tmp %O,UDN

}

; ---   *   ---   *   ---
; unpacks all operands
; to make call

macro smX.op.funroll %O,fn {

  ; elems
  local UA
  local UB
  local UC

  ; ^unpack
  match A B C , \
    %O#.elem_A \
    %O#.elem_B \
    %O#.elem_C \
  \{

    UA equ A
    UB equ B
    UC equ C

  \}


  ; no operands
  match =0 , %O#.elems \{smX.op.#fn\}

  ; ^single operand
  match =1 , %O#.elems \{
    match A , UA \\{smX.op.#fn %O,A\\}

  \}

  ; ^two operands
  match =2 , %O#.elems \{
    match A B , UA UB \\{
      smX.op.#fn %O,A,B

    \\}

  \}

  ; ^three operands
  match =3 , %O#.elems \{
    match A B C , UA UB UC \\{
      smX.op.#fn %O,A,B,C

    \\}

  \}

}

; ---   *   ---   *   ---
; ^unpacks *passed* operands
; to make call

macro smX.op.unroll %O,fn,[item] {

  common
    local list
    list equ

  forward match elem , %O#.elem_#item \{
    commacat list,elem

  \}

  common match any,list \{
    smX.op.#fn %O,any

  \}

}

; ---   *   ---   *   ---
; makes variation in op call
; where fn@[UDN] args is fn args,[UDN]

macro smX.op.icecall base,[udn] {

  ; cat [UDN-0..UDN-X]
  common
    local udncat
    udncat equ +

  forward match any , udncat \{
    udncat equ any\#udn

  \}

  ; ^make base@UDN wraps
  ; with [UDN-0..UDN-X] as implicit args
  common match =+ ext , udncat \{

    macro smX.op.#base#@\#ext %O,args& \\{

      local ok
      ok equ 0

      ; need args!
      match ext2 list, ext args \\\{
        smX.op.#base %O,list,udn
        ok equ 1

      \\\}

      ; ^no args ;>
      match =0 , ok \\\{
        smX.op.#base %O,udn

      \\\}

    \\}

  \}

}

; ---   *   ---   *   ---
; conditional dereference
; of source operand

macro smX.op.need_deref? %O,UD0,UD1,UDN {

  match =m , UD1#.mode \{

    ; mem to mem, do tmpchk
    match =m , UD0#.mode \\{
      smX.op.need_repl?@#UDN %O,UD1

    \\}

    ; ^no tmp needed ;>
    match =r , UD0#.mode \\{

      cline %O#.name \
        UD0#.loc,UD1#.size [UD1#.xloc+UD1#.off]

    \\}

  \}

  ; ^rY to rX?
  match =r , UD1#.mode \{
    smX.op.deref_dst? %O,UD0,UD1

  \}

}

; ---   *   ---   *   ---
; ^iceof

smX.op.icecall need_deref?,B

; ---   *   ---   *   ---
; overwrite or use tmp?

macro smX.op.need_repl? %O,UD0,UDN {

  ; replace self
  match =1 , UD0#.repl \{

    cline mov \
      UD0#.loc,UD0#.size [UD0#.xloc+UD0#.off]

    %O#.elem_#UDN#_deref.set UD0

  \}


  ; ^get new reg
  local ok
  ok equ 0

  match =0 =null ,\
    UD0#.repl \
    %O#.elem_#UDN#_tmp \{

    local uid
    smX.op.get_tmp %O,uid,UD0#.size r

    ; ^use as tmpdst
    match id , uid \\{

      cline mov \
        id\\#.loc,\
        UD0#.size [UD0#.xloc+UD0#.off]

      %O#.elem_#UDN#_deref.set id
      %O#.elem_#UDN#_tmp.set   id

    \\}

    ok equ 1

  \}

  ; ^already have tmp ;>
  match =0 =0 id ,\
    UD0#.repl ok \
    %O#.elem_#UDN#_tmp \{

    %O#.elem_#UDN#_deref.set id
    %O#.elem_#UDN#_tmp.set   id

    cline mov \
      id\\#.loc,\
      UD0#.size [UD0#.xloc+UD0#.off]

  \}

}

; ---   *   ---   *   ---
; ^iceof

smX.op.icecall need_repl?,A
smX.op.icecall need_repl?,B

; ---   *   ---   *   ---
; overwrite dst?

macro smX.op.deref_dst? %O,UD0,UD1 {

  ; [dst] <= src
  match =m , UD0#.mode \{

    cline %O#.name \
      UD0#.size [UD0#.xloc+UD0#.off],\
      UD1#.loc

  \}

  ; ^dst <= src
  match =r , UD0#.mode \{
    cline %O#.name UD0#.loc,UD1#.loc

  \}

}

; ---   *   ---   *   ---
; [?dst] <= [?src] proto

macro smX.op.cderef %O,UDN0,UDN1 {

  local status
  status equ 0

  ; deref or solve?
  smX.op.funroll %O,need_deref?@#UDN1

  match UD1 , %O#.elem_#UDN1#_deref \{

    ; ^solved ;>
    match =null , UD1 \\{
      status equ 1

    \\}

    ; ^deref, second step needed
    match =0 UD0 , status %O#.elem_#UDN0 \\{
      smX.op.deref_dst? %O,UD0,UD1

    \\}

  \}

}

; ---   *   ---   *   ---
; ^iceof

smX.op.icecall cderef,A,B

; ---   *   ---   *   ---
; generic: ins [?dst] <= [?src]

macro smX.op.B2A mode,ins {

  ; make op ice
  macro mode#.#ins dst,UD0,UD1 \{
    smX.op.new uid,mode,ins,UD0,UD1
    dst equ uid

    ; ^lis methods
    match %O , uid \\{

      macro %O\\#.run \\\{
        smX.op.cderef@AB %O

      \\\}

    \\}


  \}

}

; ---   *   ---   *   ---
; ^iceof

smX.op.B2A i64,mov
smX.op.B2A i64,xor
smX.op.B2A i64,or

; ---   *   ---   *   ---
; run F for all items

macro smX.op.batrun fn,[item] {

  forward match %O any , item fn \{
    %O\#.\#any

  \}

}

; ---   *   ---   *   ---
