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
  use '.inc' peso::cline

  use '.inc' peso::smX::mem
  use '.inc' peso::smX::opmeta

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.smX.op

  VERSION   v0.00.7b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; operation struc

swan.new smX.op

swan.attr name,xor
swan.attr elems,2
swan.attr size,byte
swan.attr rsize,byte

swan.attr elem_A,null
swan.attr elem_B,null
swan.attr elem_C,null

swan.attr elem_A_deref,null
swan.attr elem_B_deref,null
swan.attr elem_C_deref,null

swan.attr elem_A_tmp,null
swan.attr elem_B_tmp,null
swan.attr elem_C_tmp,null

swan.attr cbuff_head,null
swan.attr cbuff_body,null
swan.attr cbuff_foot,null

swan.end

; ---   *   ---   *   ---
; ^cstruc

macro smX.op.onew id,meta,elems& {

  ; unpack args
  smX.sized_op id,meta,elems

  ; make dst buffers
  cline.new id#.cbuff_head
  cline.new id#.cbuff_foot
  cline.new id#.cbuff_body

}

; ---   *   ---   *   ---
; get size-variant of operation

macro smX.sized_op %O,meta,[elem] {

  common

    %O#.name.set  meta#.ins
    %O#.size.set  meta#.ins.size
    %O#.elems.set meta#.elem.cnt


    ; get register size
    match size , %O#.size \{

      if sizeof.\#size > $20
        %O#.rsize.set yword

      else
        %O#.rsize.set %O#.size

      end if

    \}


    local eX
    eX equ

  forward match any , elem \{

    local id
    local ok
    ok equ 0

    match type == name =+ off , elem \\{
      smX.op.get_mem %O,id,elem
      ok equ 1

    \\}

    match =0 type == name , ok elem \\{
      id equ name

    \\}


    commacat eX,id

  \}

  common match list , eX \{
    smX.op.set_elems %O,list

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

macro smX.op.odel %O {

  ; commit code
  cline.bat \
    %O#.cbuff_head,\
    %O#.cbuff_body,\
    %O#.cbuff_foot,\

  ; ^release container
  smX.op.bat_free_tmp %O,A,B,C
  smX.op.bat_free_mem %O,A,B,C

  %O#.del

}

; ---   *   ---   *   ---
; borrow a register

macro smX.op.get_tmp %O,dst,args {

  local mode
  smX.op.get_mode %O,mode

  match md , mode \{
    md\#.mem.alloc dst,args+$00

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
  match =0 any , status \
    %O#.elem_#UDN#_tmp \{

    local mode
    smX.op.get_mode %O,mode

    match md , mode \\{
      md\\#.mem.free_back any
      %O#.elem_#UDN#_tmp equ null

    \\}

  \}

}

; ---   *   ---   *   ---
; ^bat

macro smX.op.bat_free_tmp %O,[UDN] {
  forward smX.op.free_tmp %O,UDN

}

; ---   *   ---   *   ---
; ^get mode from size

macro smX.op.get_mode %O,dst {

  dst equ i64

  match size , %O#.size \{
    smX.iorx dst,size

  \}

}

; ---   *   ---   *   ---
; ^alloc mem for elem

macro smX.op.get_mem %O,dst,args& {

  local md
  smX.op.get_mode %O,md

  match mode type == which =+ off , md args \{
    mode\#.mem.alloc dst,%O#.rsize args,which

    match mem , dst \\{
      mem\\#.owner equ %O

    \\}

  \}

}

; ---   *   ---   *   ---
; ^undo

macro smX.op.free_mem %O,UDN {

  ; get tmp used
  local status
  local owned

  status equ 0
  owned  equ 0

  ; got mem?
  match =null,%O#.elem_#UDN# \{
    status equ 1

  \}

  ; ^we own mem?
  match =0 mem , status %O#.elem_#UDN \{
    tokis owned,mem\#.owner,%O

    ; ^yep, give back
    match =1 , owned \\{

      local md
      smX.op.get_mode %O,md

      match mode , md \\\{
        mode\\\#.mem.free_back mem
        %O#.elem_#UDN equ null

      \\\}

    \\}

  \}

}

; ---   *   ---   *   ---
; ^bat

macro smX.op.bat_free_mem %O,[UDN] {
  forward smX.op.free_mem %O,UDN

}

; ---   *   ---   *   ---
; unpacks all operands
; to make call

macro smX.op.gfunroll %O,fn,args& {

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
    match A , UA \\{
      fn %O,A,args

    \\}

  \}

  ; ^two operands
  match =2 , %O#.elems \{
    match A B , UA UB \\{
      fn %O,A,B,args

    \\}

  \}

  ; ^three operands
  match =3 , %O#.elems \{
    match A B C , UA UB UC \\{
      fn %O,A,B,C,args

    \\}

  \}

}

; ---   *   ---   *   ---
; ^unpacks *passed* operands
; to make call

macro smX.op.gunroll %O,fn,[item] {

  common
    local list
    list equ

  forward match elem , %O#.elem_#item \{
    commacat list,elem

  \}

  common match any,list \{
    fn %O,any

  \}

}

; ---   *   ---   *   ---
; ^wraps: cat smX.op to fn

macro smX.op.funroll %O,fn,args& {
  smX.op.gfunroll %O,smX.op.#fn,args

}

macro smX.op.funroll %O,fn,args& {
  smX.op.gunroll %O,smX.op.#fn,args

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

  local movop
  smX.op.sized_mov %O,movop

  ; replace self
  match =1 , UD0#.repl \{

    cline movop \
      UD0#.loc,UD0#.size [UD0#.xloc+UD0#.off]

    %O#.elem_#UDN#_deref.set UD0

  \}


  ; ^need new reg?
  local ok
  local tmp
  local make_tmp

  ok       equ 0
  tmp      equ
  make_tmp equ 0

  ; ^get existing or make new
  match =0 , UD0#.repl \{

    ; make new?
    match =null , %O#.elem_#UDN#_tmp \\{
      make_tmp equ 1

    \\}

    ; ^have one already?
    match =0 id , make_tmp %O#.elem_#UDN#_tmp \\{

      %O#.elem_#UDN#_deref.set id
      %O#.elem_#UDN#_tmp.set   id

      id\\#.set_size UD0#.size
      tmp equ id

    \\}

    ok equ 1

  \}


  ; ^get new and overwrite existing
  match =2 , UD0#.repl \{

    ; no freeing needed
    match =null , %O#.elem_#UDN#_tmp \\{
      make_tmp equ 1

    \\}

    ; ^free to bottom of stack
    match =0 id , make_tmp %O#.elem_#UDN#_tmp \\{
      smX.op.free_tmp %O,UDN
      make_tmp equ 1

    \\}

    ok equ 1

  \}


  ; ^get tmp
  match =1 , make_tmp \{

    local uid
    smX.op.get_tmp %O,uid,UD0#.size r

    ; ^use as tmpdst
    match id , uid \\{
      %O#.elem_#UDN#_deref.set id
      %O#.elem_#UDN#_tmp.set   id

      tmp equ id

    \\}

    ok equ 1

  \}


  ; ^add tmp code to head
  match id , tmp \{

    ; save current buffer name
    ; then switch to header
    local old
    cline.swap %O#.cbuff_head,old

    cline movop \
      id\#.loc,UD0#.size [UD0#.xloc+UD0#.off]

    ; ^restore buffer
    cline.swap old

  \}

}

; ---   *   ---   *   ---
; ^iceof

smX.op.icecall need_repl?,A
smX.op.icecall need_repl?,B

; ---   *   ---   *   ---
; placeholder

macro smX.sized_mov dst,size,ali=0 {

  dst equ mov

  match =xword , size \{
    bincho dst,ali,movdqu,movdqa

  \}

  match =yword , size \{
    bincho dst,ali,vmovdqu,vmovdqa

  \}

}

; ---   *   ---   *   ---
; ^wraps

macro smX.op.sized_mov %O,dst,ali=0 {
  smX.sized_mov dst,%O#.rsize,ali

}

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

    OBJ.new dst,smX.op,mode,ins,UD0,UD1

    ; ^lis methods
    match %O , dst \\{

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
