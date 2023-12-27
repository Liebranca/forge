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

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define hier.cscope

; ---   *   ---   *   ---
; pre-ROM

  define i64.REGISTERS
  define sse.REGISTERS

; ---   *   ---   *   ---
; ctx struc

swan.new smX.scope

swan.attr i64.avail,list
swan.attr i64.unav,list
swan.attr i64.mems,list

swan.attr sse.avail,list
swan.attr sse.unav,list
swan.attr sse.mems,list

swan.attr code.head,list
swan.attr code.body,list

swan.end

; ---   *   ---   *   ---
; ^cstruc

macro smX.scope.onew id,_nullarg& {
  smX.scope.get_regs id,i64,smX.REG.ar
  smX.scope.get_regs id,sse,smX.REG.br

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

      tokin ok,rX,unav


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
  match list , type#.REGISTERS \{
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

  rept id#.sse.mems.m_len \{
    smX.scope.free sse

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

      smX.scope.pick_mem \
        id,type,alloc,rX,which


      ; ^mark in use
      OBJ.new dst,type#.mem,args+rX
      id\#.#type#.mems.push dst

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

macro smX.scope.free type,which= {

  match id , hier.cscope \{

    ; get register
    local rX

    smX.scope.pick_mem \
      id,type,free,rX,which


    ; ^give back to pool
    match any , rX \\{
      id\#.#type#.avail.unshift any\\#.name
      any\\#.del

    \\}

  \}

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
