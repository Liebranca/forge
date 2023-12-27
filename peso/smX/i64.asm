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
  use '.inc' peso::smX::op
  use '.inc' peso::smX::scope

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.smX.i64

  VERSION   v0.00.7b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  define i64.REGISTERS \
    a,b,c,d,\
    di,si,r8,r9,\
    r10,r11,r12,r13,\
    r14,r15

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

macro i64.mem.onew id,args& {

  ; set attrs
  match sz md =+ rX , args \{

    id#.mode.set md
    id#.size.set sz

    i64.mem.set_loc id,rX

  \}

  ; ^lis methods
  swan.batlis id,i64.mem,\
    set_size,set_loc,\
    set_mode,set_repl,\
    set_off,add_off

}

; ---   *   ---   *   ---
; ^ctx wraps

macro i64.mem.alloc dst,args& {
  smX.scope.alloc dst,i64,args

}

macro i64.mem.free dst,args& {
  smX.scope.free i64,args

}

macro i64.mem.free_back dst,args& {
  smX.scope.free_back i64,args

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
; cstruc shorthand ;>

macro i64.memarg dst,src {

  ; unpack arg
  local proto
  local repl

  commacut proto,smX.REG.#src
  commacut repl,smX.REG.#src


  ; ^proc arg0
  match attrs =+ name , proto \{
    i64.mem.alloc dst,attrs,name

  \}

  ; ^proc arg1
  match x id , repl dst \{
    id\#.set_repl x

  \}

}

; ---   *   ---   *   ---
; load [?dst] <= [?src]

macro smX.i64.ld {

  ; unpack args
  local A
  local B

  i64.memarg A,ar
  i64.memarg B,br

  ; ^build op
  local op
  i64.mov op,A,B


  ; run through steps
  macro inner [step] \{

    forward

      match UA UB , A B \\{
        UA\\#.set_size step
        UB\\#.set_size step

      \\}

      smX.op.batrun run,op

      match UA UB , A B \\{
        UA\\#.add_off sizeof.\#step
        UB\\#.add_off sizeof.\#step

      \\}

  \}

  ; ^exec
  match list , smX.REG.cr \{
    inner list

  \}

  ; cleanup
  match %O UA UB , op A B \{

    smX.op.odel %O

    i64.mem.free UA
    i64.mem.free UB

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
