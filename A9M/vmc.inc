; ---   *   ---   *   ---
; A9M VMC
; Phantom machine!
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
  use '.inc' A9M::vmem
  use '.inc' A9M::vreg

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.vmc

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  ; incomplete list, see below
  define A9M.REGISTERS \
    ar,br,cr,dr,\
    er,fr,gr,hr,\
    sp,sb


  ; the Arcane 9 would set this to
  ; addrof caller; won't work here!
  define vmc.REG.xp

  ; ^likewise, addrof callee
  define vmc.REG.xs

  ; ^addrof active instance
  define vmc.REG.ice

  ; ^addof input buffer
  define vmc.REG.ctx

; ---   *   ---   *   ---
; bat-decl for registers

macro vmc._decl_reg [name] {
  forward szmy qword name

}

; ---   *   ---   *   ---
; ^base struc

vreg.new ANIMA
match __list , A9M.REGISTERS {
  vmc._decl_reg __list

}

vreg.end

; ---   *   ---   *   ---
; ^dbout wraps

macro ANIMA.prich {
  ANIMA.prich vmc.REG

}

; ---   *   ---   *   ---
; GBL

  define    vmc.REG
  ANIMA.new vmc.REG

  ; for use by instructions
  vmc._tmp_0=0
  vmc._tmp_1=0
  vmc._tmp_2=0
  vmc._tmp_3=0

  ; ^for use by decoder
  vmc._tmp_4=0

; ---   *   ---   *   ---
; determine type of operand

macro vmc.decode A,B,mode {

  local ok
  ok equ 0

  ; run checks
  vmc.decode.reg   ok,A,B,mode
  vmc.decode.ptr   ok,A,B,mode
  vmc.decode.attr  ok,A,B,mode
  vmc.decode.struc ok,A,B,mode
  vmc.decode.mem   ok,A,B,mode

  vmc.decode.imm   ok,A,B

}

; ---   *   ---   *   ---
; is src a register?

macro vmc.decode.reg ok,A,B,mode {

  match list , A9M.REGISTERS \{

    tokin ok,B,list
    match =1 , ok \\{
      vmc.decode.reg.inner A,B,mode

    \\}

  \}

}

; ---   *   ---   *   ---
; ^yes

macro vmc.decode.reg.inner A,B,mode {

  ; load value from register
  match =read , mode \{
    ANIMA.#B#.get A,vmc.REG

  \}

  ; ^write value to register
  match =write , mode \{
    ANIMA.#B#.set vmc.REG,A

  \}

  ; ^unary operator
  match =uop op , mode \{
    ANIMA.#B#.\#op vmc.REG

  \}

  ; ^unary operator
  match =bop op , mode \{
    ANIMA.#B#.\#op vmc.REG,A

  \}

}

; ---   *   ---   *   ---
; is src a pointer?

macro vmc.decode.ptr ok,A,B,mode {

  match =0 =ptr id , ok B \{
    A  equ id
    ok equ 1

  \}

}

; ---   *   ---   *   ---
; is src a pointer to struc?

macro vmc.decode.struc ok,A,B,mode {

  match =0 =% id , ok B \{
    A  equ id\%origin
    ok equ 1

  \}

}

; ---   *   ---   *   ---
; is src a memory fetch?

macro vmc.decode.mem ok,A,B,mode {

  match =0 =[ id =] , ok B \{
    vmc.decode.mem.inner A,mode,qword,id
    ok equ 1

  \}

  match =0 size =[ id =] , ok B \{
    vmc.decode.mem.inner A,mode,size,id
    ok equ 1

  \}

}

; ---   *   ---   *   ---
; ^yes

macro vmc.decode.mem.inner A,mode,size,id {

  local ok
  ok equ 0

  ; deref base+offset
  match base op off , id \{
    vmc.decode.mem.inner_off_0 off,op

    match =read , mode \\{
      vmem.get A,base,vmc._tmp_4,size

    \\}

    match =write , mode \\{
      vmem.set base,A,vmc._tmp_4,size

    \\}

    ok equ 1

  \}

  ; ^deref base addr
  match =0 , ok \{

    match =read , mode \\{
      vmem.get A,id,$00,size

    \\}

    match =write , mode \\{
      vmem.set id,A,$00,size

    \\}

  \}

}

; ---   *   ---   *   ---
; ^innards

macro vmc.decode.mem.inner_off_0 N,op {

  local ok
  ok equ 0

  vmc._tmp_4=0
  vmc._tmp_5=0

  match A op2 B , N \{

    vmc.decode.reg ok,vmc._tmp_4,A,read
    vmc.decode.imm ok,vmc._tmp_4,A

    vmc.decode.reg ok,vmc._tmp_5,B,read
    vmc.decode.imm ok,vmc._tmp_5,B

    vmc._tmp_4=vmc._tmp_4 op2 vmc._tmp_5

    ok equ 1

  \}

  match =0 , ok \{
    vmc.decode.reg ok,vmc._tmp_4,N,read
    vmc.decode.imm ok,vmc._tmp_4,N

  \}

  vmc._tmp_4=0 op vmc._tmp_4

}

; ---   *   ---   *   ---
; is src a struc attr?

macro vmc.decode.attr ok,A,B,mode {

  match =0 =% =[ id tag =] , ok B \{

    match type , id\#%type \\{
      vmc.decode.attr.inner A,mode,id,type,tag

    \\}

    ok equ 1

  \}

}

; ---   *   ---   *   ---
; ^yes

macro vmc.decode.attr.inner A,mode,id,type,tag {

  match =read , mode \{
    type#.\#tag\#.get A,id

  \}

  match =write , mode \{
    type#.\#tag\#.set id,A

  \}

}

; ---   *   ---   *   ---
; is src an immediate?

macro vmc.decode.imm ok,A,B {

  match =0 , ok \{
    A=B
    ok equ 1

  \}

}

; ---   *   ---   *   ---
; [?dst] <= [?src]

macro $mov dst,src {

  local value
  value equ vmc._tmp_0

  vmc.decode value,src,read
  vmc.decode value,dst,write

}

; ---   *   ---   *   ---
; generirc operator "factory"

macro vmc._gen_op type,[name] {

  forward

    ; unary
    match =u , type \{
      macro $\#name dst \\{
        vmc.decode _,dst,type#op name

      \\}

    \}


    ; ^binary
    match =b , type \{

      macro $\#name dst,src \\{

        local value
        value equ vmc._tmp_0

        vmc.decode value,src,read
        vmc.decode value,dst,type#op name

      \\}

    \}

}

; ---   *   ---   *   ---
; ^bat-run

match __list , vmem.uops_list {
  vmc._gen_op u,__list

}

match __list , vmem.bops_list {
  vmc._gen_op b,__list

}

; ---   *   ---   *   ---
; nit the stack!

library ARPATH '/forge/'
  use '.inc' A9M::vstk

library.import


define   vmc.STK
define   vmc.STK.frame_sz

vmem.new vmc.STK,blk A9M.STACK_SZ

$mov     sp,A9M.STACK_SZ

; ---   *   ---   *   ---
