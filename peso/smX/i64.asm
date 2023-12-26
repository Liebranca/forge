; ---   *   ---   *   ---
; PESO SMX I64
; Old school registers
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

  TITLE     peso.smX.i64

  VERSION   v0.00.4b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  define i64.REGISTERS \
    a,b,c,d,\
    di,si,r8,r9,\
    r10,r11,r12,r13,\
    r14,r15

; ---   *   ---   *   ---
; GBL

  define i64.cscope

; ---   *   ---   *   ---
; ctx struc

swan.new i64.scope

swan.attr avail,list
swan.attr unav,list
swan.attr mems,list

swan.end

; ---   *   ---   *   ---
; ^cstruc

macro smX.i64.open_scope dst,list& {

  ; generated iced
  local uid
  uid.new uid,smX.i64.scope,global

  ; ^unroll and make ice
  match id,uid \{

    i64.scope.new id
    i64.cscope equ id

    dst equ id


    ; build list of avail registers
    macro inner [rX] \\{

      forward

        ; get rX is used
        local ok
        tokin ok,rX,list

        ; ^push to unav if so
        match =1 , ok \\\{
          id\#.unav.push rX

        \\\}

        ; ^else push to avail
        match =0 , ok \\\{
          id\#.avail.push rX

        \\\}

    \\}


    ; ^run
    match any , i64.REGISTERS \\{
      inner any

    \\}

  \}

}

; ---   *   ---   *   ---
; ^dstruc

macro smX.i64.close_scope {

  match any , i64.cscope \{

    ; ^release mems
    rept any\#.mems.m_len \\{
      smX.i64.free_mem

    \\}

    ; release container
    any\#.del

  \}

  restore i64.cscope

}

; ---   *   ---   *   ---
; get unused register

macro smX.i64.get_mem dst,args {

  match scp , i64.cscope \{

    ; get registers left
    local have
    have equ

    rept scp\#.avail.m_len \\{have equ 1\\}


    ; ^got scratch
    match any,have \\{

      local name

      scp\#.avail.shift name
      smX.i64.new_mem dst,args+name

      scp\#.mems.push dst

    \\}


    ; ^TODO: none avail, move to stack
    match , have \\{
      out@err "NYI stack mem @ i64.scope"

    \\}

  \}

}

; ---   *   ---   *   ---
; ^release N mems from top

macro smX.i64.free_mem {

  match scp , i64.cscope \{

    local rX
    rX equ

    scp\#.mems.pop rX

    match any , rX \\{
      scp\#.avail.push any\\#.name
      any\\#.del

    \\}

  \}

}

; ---   *   ---   *   ---
; operation struc

swan.new i64.op
swan.attr name,xor
swan.attr elems,2

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

  define i64.op.xor_elems  2
  define i64.op.or_elems   2

  define i64.op.mov_elems  2
  define i64.op.cmp_elems  2
  define i64.op.test_elems 2

; ---   *   ---   *   ---
; ^cstruc

macro smX.i64.op.new dst,op,item& {

  ; generate iced
  local uid
  uid.new uid,smX.i64.op,global

  ; ^unroll and make ice
  match id , uid \{

    i64.op.new id,\
      name  => op,\
      elems => i64.op.#op#_elems

    dst equ id

    ; nit operands if passed
    match elems , item \{
      smX.i64.op.set_elems id,elems

    \}

  \}

}

; ---   *   ---   *   ---
; ^assign operands

macro smX.i64.op.set_elems %O,[item] {

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
; unpacks all operands
; to make call

macro i64.op.funroll %O,fn {

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
  match =0 , %O#.elems \{i64.op.#fn\}

  ; ^single operand
  match =1 , %O#.elems \{
    match A , UA \\{i64.op.#fn %O,A\\}

  \}

  ; ^two operands
  match =2 , %O#.elems \{
    match A B , UA UB \\{
      i64.op.#fn %O,A,B

    \\}

  \}

  ; ^three operands
  match =3 , %O#.elems \{
    match A B C , UA UB UC \\{
      i64.op.#fn %O,A,B,C

    \\}

  \}

}

; ---   *   ---   *   ---
; ^unpacks *passed* operands
; to make call

macro i64.op.unroll %O,fn,[item] {

  common
    local list
    list equ

  forward match elem , %O#.elem_#item \{
    commacat list,elem

  \}

  common match any,list \{
    i64.op.#fn %O,any

  \}

}

; ---   *   ---   *   ---
; makes variation in op call
; where fn@[UDN] args is fn args,[UDN]

macro i64.op.icecall base,[udn] {

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

    macro i64.op.#base#@\#ext %O,args& \\{

      local ok
      ok equ 0

      ; need args!
      match ext2 list, ext args \\\{
        i64.op.#base %O,list,udn
        ok equ 1

      \\\}

      ; ^no args ;>
      match =0 , ok \\\{
        i64.op.#base %O,udn

      \\\}

    \\}

  \}

}

; ---   *   ---   *   ---
; conditional dereference
; of source operand

macro i64.op.need_deref? %O,UD0,UD1,UDN {

  match =m , UD1#.mode \{

    ; mem to mem, do tmpchk
    match =m , UD0#.mode \\{
      i64.op.need_repl?@#UDN %O,UD1

    \\}

    ; ^no tmp needed ;>
    match =r , UD0#.mode \\{

      cline %O#.name \
        UD0#.loc,UD1#.size [UD1#.xloc+UD1#.off]

    \\}

  \}

  ; ^rY to rX?
  match =r , UD1#.mode \{
    i64.op.deref_dst? %O,UD0,UD1

  \}

}

; ---   *   ---   *   ---
; ^iceof

i64.op.icecall need_deref?,B

; ---   *   ---   *   ---
; overwrite or use tmp?

macro i64.op.need_repl? %O,UD0,UDN {

  ; replace self
  match =1 , UD0#.repl \{

    cline mov \
      UD0#.loc,UD0#.size [UD0#.xloc+UD0#.off]

    %O#.elem_#UDN#_deref.set UD0

  \}

  ; ^get new reg
  match =0 , UD0#.repl \{

    local uid
    smX.i64.get_mem uid,UD0#.size r

    ; ^use as tmpdst
    match id , uid \\{

      cline mov \
        id\\#.loc,\
        UD0#.size [UD0#.xloc+UD0#.off]

      %O#.elem_#UDN#_deref.set id
      %O#.elem_#UDN#_tmp.set   id

    \\}

  \}

}

; ---   *   ---   *   ---
; ^iceof

i64.op.icecall need_repl?,A
i64.op.icecall need_repl?,B

; ---   *   ---   *   ---
; overwrite dst?

macro i64.op.deref_dst? %O,UD0,UD1 {

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

macro i64.op.cderef %O,UDN0,UDN1 {

  local status
  status equ 0

  ; deref or solve?
  i64.op.funroll %O,need_deref?@#UDN1

  match UD1 , %O#.elem_#UDN1#_deref \{

    ; ^solved ;>
    match =null , UD1 \\{
      status equ 1

    \\}

    ; ^deref, second step needed
    match =0 UD0 , status %O#.elem_#UDN0 \\{
      i64.op.deref_dst? %O,UD0,UD1

    \\}

  \}


  ; cleanup tmp
  status equ 0
  match =null,%O#.elem_#UDN1#_tmp \{
    status equ 1

  \}

  match =0 , status \{
    smX.i64.free_mem
    %O#.elem_#UDN1#_tmp equ null

  \}

}

; ---   *   ---   *   ---
; ^iceof

i64.op.icecall cderef,A,B

; ---   *   ---   *   ---
; generic: ins [?dst] <= [?src]

macro i64.op.B2A ins {

  macro i64.#ins UD0,UD1 \{

    ; make ice
    local uid
    smX.i64.op.new uid,ins,UD0,UD1

    ; ^run and clear
    match %O , uid \\{
      i64.op.cderef@AB %O
      %O\\#.del

    \\}

  \}

}

; ---   *   ---   *   ---
; ^iceof

i64.op.B2A mov
i64.op.B2A xor
i64.op.B2A or

; ---   *   ---   *   ---
; operand struc

swan.new i64.mem

swan.attr name,a
swan.attr loc,al
swan.attr xloc,rax
swan.attr size,byte
swan.attr off,0
swan.attr repl,0
swan.attr mode,r

swan.end
; ---   *   ---   *   ---
; ^cstruc

macro smX.i64.new_mem dst,args {

  ; generate iced
  local uid
  uid.new uid,smX.i64.mem,global

  ; ^unroll and make ice
  match id sz md =+ rX , uid args \{

    i64.mem.new id,\
      name=>rX,\
      size=>sz,\
      mode=>md,\

    i64.mem.set_loc id,rX

    ; ^lis macros
    swan.batlis id,i64.mem,\
      set_size,set_loc,\
      set_mode,set_repl,\
      set_off,add_off

    dst equ id

  \}

}

; ---   *   ---   *   ---
; modifies size-variant of
; used register

macro i64.mem.set_size dst,sz {

  ; get sized variant
  local rX
  match loc , dst#.name \{
    i_sized_reg rX,loc,sz

  \}

  ; ^write field
  dst#.loc.set rX
  dst#.size.set sz

}

; ---   *   ---   *   ---
; ^modifies used register

macro i64.mem.set_loc dst,name {

  ; get largest (used for deref)
  local rX
  i_sized_reg rX,name,qword

  ; ^write field
  dst#.xloc.set rX
  dst#.name.set name

  ; ^update ice
  match sz,dst#.size \{
    i64.mem.set_size dst,sz

  \}

}

; ---   *   ---   *   ---
; ^mere wraps

macro i64.mem.set_mode dst,value {
  dst#.mode.set value

}

macro i64.mem.set_repl dst,value {
  dst#.repl.set value

}

macro i64.mem.set_off dst,value {
  dst#.off.set value

}

; ---   *   ---   *   ---
; ^adds to current offset

macro i64.mem.add_off dst,value {

  match off , dst#.off \{
    dst#.off.set off+(value)

  \}

}

; ---   *   ---   *   ---
; clear [?A]

macro smX.i64.cl A {

  ; clear size ptr A
  match =m , A#.mode \{
    cline mov A#.size [A#.xloc+A#.off],$00

  \}

  ; clear A
  match =r , A#.mode \{

    ; clear whole register
    match =1 , A#.repl \\{
      cline xor A#.xloc,A#.xloc

    \\}

    ; ^clear only sized part (byte or word)
    match =0 , A#.repl \\{
      cline xor A#.loc,A#.loc

    \\}

  \}

}

; ---   *   ---   *   ---
; generate X-sized op

macro smX.i64.walk op,size,args& {

  local step
  step equ sizeof.#size

  ; paste op [args]
  op size,step,args

  smX.paste_footer op

}

; ---   *   ---   *   ---
; ^table generator ice

macro smX.i64.tab op,eob,args& {

  ; list possible sizes
  local entry
  local entry.len

  List.from entry,entry.len,\
    byte,word,dword,qword

  ; ^make elem for each
  smX.gen_tab \
    smX.i64.walk,byte,\
    entry,entry.len,\
    eob,smX.i64.#op,args

}

; ---   *   ---   *   ---
