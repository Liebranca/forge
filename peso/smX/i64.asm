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
  use '.asm' peso::smX::op

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.smX.i64

  VERSION   v0.00.6b
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
;
;
; TODO:
;
; * save and load from stack
;   when we run out of registers

macro smX.i64.get_mem dst,args,which= {

  match scp , i64.cscope \{

    ; get registers left
    local have
    have equ

    rept scp\#.avail.m_len \\{have equ 1\\}


    ; ^got scratch
    match any,have \\{

      ; get register
      local rX
      smX.i64.pick_mem scp,alloc,rX,which

      ; ^mark in use
      smX.i64.new_mem dst,args+rX
      scp\#.mems.push dst

    \\}


    ; ^none avail, move to stack
    match , have \\{
      out@err "NYI stack mem @ i64.scope"

    \\}

  \}

}

; ---   *   ---   *   ---
; ^release mem from top
;
; optionally: release a
; specific mem, much slower!

macro smX.i64.free_mem which= {

  match scp , i64.cscope \{

    ; get register
    local rX
    smX.i64.pick_mem scp,free,rX,which


    ; ^give back to pool
    match any , rX \\{
      scp\#.avail.unshift any\\#.name
      any\\#.del

    \\}

  \}

}

; ---   *   ---   *   ---
; picks register from avail

macro smX.i64.pick_mem scp,mode,rX,which= {

  rX equ

  ; take from scope
  match =alloc , mode \{

    ; no name passed
    match , which \\{
      scp#.avail.shift rX

    \\}

    ; ^name passed, hold on...
    match any , which \\{
      scp#.avail.pluck rX,any

    \\}

  \}

  ; ^give back!
  match =free , mode \{

    ; no name passed
    match , which \\{
      scp#.mems.pop rX

    \\}

    ; ^name passed, hold on...
    match any , which \\{
      scp#.mems.pluck rX,any

    \\}

  \}

}

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
