; ---   *   ---   *   ---
; PESO SMX MEM
; *ALL* the registers
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
  use '.inc' peso::smX::scope

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.smX.mem

  VERSION   v0.00.4b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; operand struc

swan.new smX.mem

swan.attr name,a
swan.attr loc,al
swan.attr xloc,rax
swan.attr size,byte
swan.attr off,0
swan.attr repl,0
swan.attr mode,r

swan.attr owner,null

swan.end

; ---   *   ---   *   ---
; ^cstruc

macro smX.mem.onew id,args& {

  ; set attrs
  match sz md == rX =+ off , args \{

    id#.mode.set md
    id#.size.set sz
    id#.off.set  off

    smX.mem.set_loc id,rX

  \}

  ; ^lis methods
  swan.batlis id,smX.mem,\
    set_size,set_loc,\
    set_mode,set_repl,\
    set_off,add_off

}

; ---   *   ---   *   ---
; modifies size-variant of
; used register

macro smX.mem.set_size dst,sz {

  ; get sized variant
  local rX
  match loc , dst#.name \{
    smX.sized_reg rX,loc,sz

  \}

  ; ^write field
  dst#.loc.set rX
  dst#.size.set sz

}

; ---   *   ---   *   ---
; ^modifies used register

macro smX.mem.set_loc dst,name {

  ; get largest (used for deref)
  local rX
  smX.sized_reg rX,name,qword

  ; ^write field
  dst#.xloc.set rX
  dst#.name.set name

  ; ^update ice
  match sz,dst#.size \{
    smX.mem.set_size dst,sz

  \}

}

; ---   *   ---   *   ---
; ^mere wraps

macro smX.mem.set_mode dst,value {
  dst#.mode.set value

}

macro smX.mem.set_repl dst,value {
  dst#.repl.set value

}

macro smX.mem.set_off dst,value {
  dst#.off.set value

}

; ---   *   ---   *   ---
; ^adds to current offset

macro smX.mem.add_off dst,value {

  match off , dst#.off \{
    dst#.off.set off+(value)

  \}

}

; ---   *   ---   *   ---
; cstruc shorthand ;>

macro smX.memarg dst,src {

  ; unpack arg
  local proto
  local repl

  commacut proto,smX.REG.#src
  commacut repl,smX.REG.#src


  ; ^proc arg0
  match attrs =+ name , proto \{
    smX.mem.alloc dst,attrs,name

  \}

  ; ^proc arg1
  match x id , repl dst \{
    id\#.set_repl x

  \}

}

; ---   *   ---   *   ---
; maps i64 to [zxy]mm
; quite foolish, but useful

macro smX.sized_reg dst,name,size {

  local xname
  local d16

  xname equ name

  shrsdiv d16,sizeof.#size,$04

  match =0 , d16 \{
    i_sized_reg dst,name,size

  \}

  match =1 , d16 \{
    smX.i2xmap xname

    match any , xname \\{
      x_sized_reg dst,any,size

    \\}

  \}

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

macro smX.i2xmap name {

  local idex
  idex equ 'I'

  match list , i64.REGISTERS \{
    tokin idex,name,list

  \}

  match any , idex \{
    name equ any

  \}

}

; ---   *   ---   *   ---
; ^map register type to
; size keyword

macro smX.get_mem_type dst,size {

  ; get size >= $10
  local d16

  dst equ i64
  shrsdiv d16,sizeof.\#size,$04

  ; ^switch if so
  rept d16 \{
    dst equ avx

  \}

}

; ---   *   ---   *   ---
; ^wraps for memice

macro smX.mem.get_type %M,dst {

  match size , %M#.size \{
    smX.get_mem_type dst,size

  \}

}

; ---   *   ---   *   ---
; generate alloc/free wraps

macro smX.mem._gen_alloc type {

  macro type#.mem.alloc dst,args& \{
    smX.scope.alloc dst,type,args

  \}

  macro type#.mem.free args& \{
    smX.scope.free type,args

  \}

  macro type#.mem.free_back args& \{
    smX.scope.free_back type,args

  \}

}

smX.mem._gen_alloc i64
smX.mem._gen_alloc avx

; ---   *   ---   *   ---
; ^convenience wraps
; get mem from size keyword

macro smX.mem.from_size dst,size,args& {

  local type
  local cmd
  local ok

  cmd equ
  ok  equ 0

  smX.get_mem_type type,size


  ; cat size to cstruc args
  match type == name =+ off , args \{
    cmd equ size args,name

  \}


  ; ^call cstruc
  match any list , type cmd \{
    any\#.mem.alloc dst,list
    ok equ 1

  \}

  match =0 any , ok type \{
    any\#.mem.alloc dst

  \}


  ; ^adjust size
  match , args \{

    match %M , dst \\{
      %M\\#.set_size size

    \\}

  \}

}

; ---   *   ---   *   ---
