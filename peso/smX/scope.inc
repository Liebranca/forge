; ---   *   ---   *   ---
; PESO SMX SCOPE
; Nesting a ton
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

  use '.inc' peso::proc
  use '.inc' peso::swan

  use '.asm' peso::smX::common

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.smX.scope

  VERSION   v0.00.5b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  define i64.REGISTERS \
    a  , b ,c  ,d  ,\
    di ,si ,r8 ,r9 ,\
    r10,r11,r12,r13,\
    r14,r15,bp ,sp

  define avx.REGISTERS \
    0 ,1 ,2 ,3 ,\
    4 ,5 ,6 ,7 ,\
    8 ,9 ,10,11,\
    12,13,14,15

; ---   *   ---   *   ---
; GBL

  define hier.cscope

; ---   *   ---   *   ---
; ctx struc

swan.new smX.scope

swan.attr i64.avail,list
swan.attr i64.unav,list
swan.attr i64.mems,list

swan.attr avx.avail,list
swan.attr avx.unav,list
swan.attr avx.mems,list

swan.end

; ---   *   ---   *   ---
; ^cstruc

macro smX.scope.onew id,_nullarg& {

  smX.scope.get_regs id,i64,smX.REG.ar
  smX.scope.get_regs id,avx,smX.REG.br

}

; ---   *   ---   *   ---
; ^sugar

macro smX.scope.open {
  OBJ.new hier.cscope,smX.scope

}

; ---   *   ---   *   ---
; build list of avail registers

macro smX.scope.get_regs id,type,unav& {

  ; walk proto
  macro inner [rX] \{

    forward

      ; get rX is used
      local ok
      ok equ 0

      match list , unav \\{
        tokin ok,rX,list

      \\}


      ; ^push to unav if so
      match =1 , ok \\{
        id#.#type#.unav.push rX

      \\}

      ; ^else push to avail
      match =0 , ok \\{
        id#.#type#.avail.push rX

      \\}

  \}

  ; ^run
  match list , i64.REGISTERS \{
    inner list

  \}

}

; ---   *   ---   *   ---
; dstruc

macro smX.scope.odel id {

  ; release mems
  rept id#.i64.mems.m_len \{
    smX.scope.free i64

  \}

  rept id#.avx.mems.m_len \{
    smX.scope.free avx

  \}


  ; release container
  id#.del

}

; ---   *   ---   *   ---
; ^sugar

macro smX.scope.close {

  match id , hier.cscope \{
    smX.scope.odel id

  \}

  restore hier.cscope

}

; ---   *   ---   *   ---
; big wraps

macro smX.scope_wrap {

  ; unpack args
  local     i64_unav
  local     avx_unav
  local     do_paste

  mach.mmov i64_unav,ar
  mach.mmov avx_unav,br
  mach.mmov do_paste,cr


  ; get codeblk
  local     buffar

  mach.cl   ar
  mach.mov  br,smX.codegen

  mach.call (mach.List.new)
  mach.mmov buffar,ar

  ; ^make active
  match id , buffar \{
    cline.set_dst id

  \}


  ; ^beg codegen
  mach.wed  smX
  mach.mov  ar,i64_unav
  mach.mov  br,avx_unav

  mach.call scope.open


  ; [INSERT SUB]
  ; ~


  ; ^end codegen
  mach.call scope.close
  mach.unwed

  ; give codeblk
  match id , buffar \{

    ; ^conditionally paste now
    match =1 , do_paste \\{
      id

    \\}

    ; ^give regardless
    mach.mov ar,id

  \}

}

; ---   *   ---   *   ---
; get unused register
;
;
; TODO:
;
; * save and load from stack
;   when we run out of registers

macro smX.scope.alloc dst,type,args,which= {

  match id , hier.cscope \{

    ; get registers left
    local have
    have equ

    rept id\#.#type#.avail.m_len \\{
      have equ 1

    \\}

    ; ^got scratch
    match any,have \\{

      ; get register
      local rX
      local cmd
      local ok

      smX.scope.pick_mem \
        id,type,alloc,rX,which


      ok  equ 0

      match any , rX \\\{
        cmd equ byte r=\\\#any\\\#+$00

      \\\}


      ; twisted op.get_mem format!
      match size type == name =+ off , args \\\{
        cmd equ size type=name+off
        ok equ 1

      \\\}

      ; ^regular
      match =0 size type =+ off , ok args \\\{
        cmd equ size type=rX+off
        ok  equ 1

      \\\}


      ; ^mark in use
      OBJ.new dst,smX.mem,cmd
      id\#.#type#.mems.push dst

    \\}


    ; ^none avail, move to stack
    match , have \\{
      out@err "NYI stack mem @ smX.scope"

    \\}

  \}

}

; ---   *   ---   *   ---
; ^release mem from top
;
; optionally: release a
; specific mem, much slower!

macro smX.scope.free_proto type,order,which= {

  match id , hier.cscope \{

    ; get register
    local rX

    smX.scope.pick_mem \
      id,type,free,rX,which


    ; ^give back to pool
    match any , rX \\{
      id\#.#type#.avail.#order any\\#.name
      any\\#.del

    \\}

  \}

}

; ---   *   ---   *   ---
; ^iceof

macro smX.scope.free type,which= {
  smX.scope.free_proto type,unshift,which

}

macro smX.scope.free_back type,which= {
  smX.scope.free_proto type,push,which

}

; ---   *   ---   *   ---
; picks register from avail

macro smX.scope.pick_mem id,type,mode,rX,which= {

  rX equ

  ; take from scope
  match =alloc , mode \{

    ; no name passed
    match , which \\{
      id#.#type#.avail.shift rX

    \\}

    ; ^name passed, hold on...
    match any , which \\{
      id#.#type#.avail.pluck rX,any

    \\}

  \}

  ; ^give back!
  match =free , mode \{

    ; no name passed
    match , which \\{
      id#.#type#.mems.pop rX

    \\}

    ; ^name passed, hold on...
    match any , which \\{
      id#.#type#.mems.pluck rX,any

    \\}

  \}

}

; ---   *   ---   *   ---
