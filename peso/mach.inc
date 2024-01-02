; ---   *   ---   *   ---
; PESO MACH
; Recursively pimp my macros
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

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.mach

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define mach.REGISTERS \
    ar,br,cr,dr,er,fr

  define mach.caller
  define mach.callee

  define mach.modfam

; ---   *   ---   *   ---
; bat define virtual registers

macro mach.make_regs [name] {

  forward
    define mach.REG.#name
    define mach.REG.#name#._back

}

match __list , mach.REGISTERS {
  mach.make_regs __list

}

; ---   *   ---   *   ---
; counters ctl

macro mach.cnt.new name {
  define name#._cnt 0

}

macro mach.cnt._flatten name {
  rept 1 cnt:name#._cnt \{
    name#._cnt equ cnt

  \}

}

macro mach.cnt.tick name {
  name#._cnt equ name#._cnt+1
  mach.cnt._flatten name

}

; ---   *   ---   *   ---
; ^save mach state

macro mach.tie {

  macro inner [name] \{

    forward
      mach.REG.#name#._back equ \
        mach.REG.#name

  \}

  match list , mach.REGISTERS \{
    inner list

  \}

}

; ---   *   ---   *   ---
; ^restore

macro mach.untie {

  macro inner [name] \{

    forward
      mach.REG.#name equ \
        mach.REG.#name#._back

  \}

  match list , mach.REGISTERS \{
    inner list

  \}

}

; ---   *   ---   *   ---
; ^pass value

macro mach.mov dst,value& {
  mach.REG.#dst equ value

}

; ---   *   ---   *   ---
; ^reg to reg

macro mach.rmov dst,src {

  match value , mach.REG.#src \{
    mach.mov dst,value

  \}

}

; ---   *   ---   *   ---
; ^whole reg to mem

macro mach.mmov dst,src {

  match value , mach.REG.#src \{
    dst equ value

  \}

}

; ---   *   ---   *   ---
; ^cut from reg

macro mach.marg dst,src {
  commacut dst,mach.REG.#src

}

; ---   *   ---   *   ---
; ^swap

macro mach.wap A,B {

  match UA , mach.REG.#A  \{

    match UB , mach.REG.#B \{
      mach.mov A,UB
      mach.mov B,UA

    \}

  \}

}

; ---   *   ---   *   ---
; ^clear

macro mach.cl dst {
  mach.REG.#dst equ

}

; ---   *   ---   *   ---
; set/reset module family of macros
; to invoke through mach.call

macro mach.wed name {
  mach.modfam equ name

}

macro mach.unwed {
  restore mach.modfam

}

; ---   *   ---   *   ---
; ^invoke

macro mach.call name {

  local ok
  ok equ 0

  mach.REG.callee equ name

  match =( fn =) , name \{
    fn
    ok equ 1

  \}

  match =0 modfam , ok mach.modfam \{
    modfam\#.#name

  \}

  restore mach.REG.callee

}

; ---   *   ---   *   ---
; generic cstruc wraps

macro OBJ.new dst,type,args& {

  local uid
  local ok

  ok equ 0


  ; generate id for type if passed
  match any , type \{
    uid.new uid,type,global
    ok equ 1

  \}

  ; ^else use args for id
  match =0 any , ok args \{
    uid.new uid,any,global

  \}


  ; pass [id,args] to cstruc
  match id , uid \{

    ; ^run cstruc if type passed
    match any , type \\{
      type#.new id
      id\#.onew args

    \\}

    ; ^give back id
    dst equ id

  \}

}

; ---   *   ---   *   ---
; ^mach-style

macro mach.uid {

  ; unpack args
  local dst
  local args
  local type

  mach.mmov type,ar
  mach.mmov args,br


  ; ^give obj or id
  OBJ.new dst,type,args

  match id , dst \{
    mach.mov ar,id

  \}

}

; ---   *   ---   *   ---
; ^wraps for List.new
; done to avoid a circular dep

macro mach.List.new {

  ; get new iced
  local     uid

  mach.cl   ar
  mach.mov  br,List

  mach.call (mach.uid)
  mach.mmov uid,ar

  ; ^use generated id
  ; to make Arstd.List ice
  match id , uid \{
    List.new id

  \}

}

; ---   *   ---   *   ---
