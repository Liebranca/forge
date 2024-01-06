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

  VERSION   v0.00.4b
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

  define    vmc.ARGV

  ; for use by instructions
  vmc._tmp_0=0
  vmc._tmp_1=0
  vmc._tmp_2=0
  vmc._tmp_3=0

  ; ^for use by decoder
  vmc._tmp_4=0
  vmc._tmp_5=0
  vmc._tmp_6=0
  vmc._tmp_7=0

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
    vmc.decode.ptr.inner A,id,mode
    ok equ 1

  \}

}

; ---   *   ---   *   ---
; ^yes

macro vmc.decode.ptr.inner A,id,mode {

  ; is id a named ptr? (fake regs ;>)
  local ok
  tokin ok,id,ice,ctx

  match =1 , ok \{

    match =read , mode \\{
      A equ vmc.REG.#id

    \\}

    match =write , mode \\{
      vmc.REG.#id equ A

    \\}

  \}


  ; ^nope, regular id
  match =0 , ok \{

    match =read , mode \\{
      A equ id

    \\}

    match =write , mode \\{
      id equ A

    \\}

  \}

}

; ---   *   ---   *   ---
; is src a pointer to struc?

macro vmc.decode.struc ok,A,B,mode {

  match =0 =% =ice , ok B \{

    match id , vmc.REG.ice \\{
      A  equ id\%origin
      ok equ 1

    \\}

  \}

  match =0 =% id , ok B \{
    A  equ id\%origin
    ok equ 1

  \}

}

; ---   *   ---   *   ---
; is src a memory fetch?

macro vmc.decode.mem ok,A,B,mode {

  match =0 =[ id =] , ok B \{
    vmc.decode.mem.inner A,mode,word,id
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
    vmc.decode.attr.inner A,mode,id,tag
    ok equ 1

  \}

}

; ---   *   ---   *   ---
; ^yes

macro vmc.decode.attr.inner A,mode,id,tag {

  local lis
  lis equ id

  ; is id a named ptr? (fake regs ;>)
  local ok
  tokin ok,id,ice,ctx

  match =1 , ok \{
    lis equ vmc.REG.#id

  \}


  ; deref by macro!
  match btr , lis \{

    match type , btr\#%type \\{

      match =read , mode \\\{
        type\\#.#tag#.get A,btr

      \\\}

      match =write , mode \\\{
        type\\#.#tag#.set btr,A

      \\\}

    \\}

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
; cats to argv
; used by call!

macro $pass [item] {

  forward

    local    X
    vmc.bget X,item

    commacat vmc.ARGV,X

}

; ---   *   ---   *   ---
; ^here we go...

macro $call fn {

  local ok
  ok equ 0

  ; setup the F "addresses" ;>
  vmc.REG.xp equ vmc.REG.xs
  vmc.REG.xs equ fn


  ; have args, pass and clear
  match list , vmc.ARGV \{

    fn list
    ok equ 1

    vmc.ARGV equ

  \}

  ; argless
  match =0 , ok \{fn\}


  ; remember who you are, simba!
  restore vmc.REG.xs
  restore vmc.REG.xp

}

; ---   *   ---   *   ---
; when you want to decode a
; value for a call

macro vmc.bget dst,src {

  local value

  match id , value \{
    vmc.decode id,src,read
    dst equ id

  \}

}

; ---   *   ---   *   ---
; rounded-up division by
; a power of 2

macro $urdivp2 dst,src,N {

  vmc.decode vmc._tmp_0,src,read
  vmc.decode vmc._tmp_1,N,read

  vuint.urdivp2 vmc._tmp_0,\
    vmc._tmp_0,vmc._tmp_1

  vmc.decode vmc._tmp_0,dst,write

}

; ---   *   ---   *   ---
; kind of a for!

macro $repeat src,step= {

  vmc.decode vmc._tmp_0,src,read
  repeat vmc._tmp_0

  match any , step \{$mov src,(%-1)*step\}

}

; ---   *   ---   *   ---
; breaks down simple expressions

macro vmc.decode.logical dst,EXPR {

  local prefix
  local expr

  prefix equ
  expr   equ EXPR

  match =~ =( inner =) , expr \{
    prefix equ ~
    expr   equ inner

  \}

  match A op? B? , expr \{

    local op
    local B

    op equ op?
    B  equ B?

    match == any , B? \\{
      op equ op =
      B  equ any

    \\}

    dst equ A,op,B

  \}

  dst equ prefix (dst)

}

; ---   *   ---   *   ---
; ^shorthand

macro $logic fn,EXPR {

  local vars
  vmc.decode.logical vars,EXPR

  match prefix =( X =, op =, Y =) , vars \{
    fn prefix,X,op,Y

  \}

}

; ---   *   ---   *   ---
; kind of an if ;>

macro $on EXPR,mode=if {

  ; do on [EXPR]
  macro inner pre,X,op,Y \{

    vmc.decode vmc._tmp_0,X,read
    vmc.decode vmc._tmp_1,Y,read

    mode prefix (vmc._tmp_0 op vmc._tmp_1)

  \}

  ; ^run
  $logic inner,EXPR

}

; ---   *   ---   *   ---
; ^repeated!

macro $while EXPR {
  $on EXPR,while

}

; ---   *   ---   *   ---
; stop!

macro $break EXPR {

  local ok
  ok equ 0

  ; conditional break
  match =on expr , EXPR \{

    $on EXPR
      break

    end if
    ok equ 1

  \}

  ; ^no condition
  match =0 , ok \{
    break

  \}

}

; ---   *   ---   *   ---
; operator icef*ck

macro vmc._gen_op type,[name] {

  forward

    ; unary
    match =u , type \{

      macro $\#name dst \\{
        vmc.decode vmc._tmp_0,dst,type#op name

      \\}

    \}


    ; ^binary
    match =b , type \{

      macro $\#name dst,src \\{
        vmc.decode vmc._tmp_0,src,read
        vmc.decode vmc._tmp_0,dst,type#op name

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

define   vmc.STK.args

define   vmc.STK.frame_sz      0
define   vmc.STK.frame_sz.back 0

define   vmc.STK.frame_vars
define   vmc.STK.frame_vars.back

define   vmc.STK.frame_set

vmem.new vmc.STK,blk A9M.STACK_SZ

$mov     sp,A9M.STACK_SZ

; ---   *   ---   *   ---
