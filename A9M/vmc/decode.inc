; ---   *   ---   *   ---
; A9M VMC DECODE
; Fetch me this
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
  use '.inc' A9M::vrecurse

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.vmc.decode

  VERSION   v0.00.2a
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; determine type of operand
; then execute micro

macro vmc.decode A,B,mode {

  local ok
  ok equ 0

  ; run checks
  vmc.decode.reg   ok,A,B,mode
  vmc.decode.ptr   ok,A,B,mode
  vmc.decode.attr  ok,A,B,mode
  vmc.decode.struc ok,A,B,mode
  vmc.decode.mem   ok,A,B,mode

  vmc.decode.imm   ok,A,B,mode

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

  match =0 =lit id , ok B \{

    match =read , mode \\{
      A equ id

    \\}

    ok equ 1

  \}

  match =0 =ptr id , ok B \{
    vmc.decode.ptr.inner A,mode,id
    ok equ 1

  \}

}

; ---   *   ---   *   ---
; ^yes

macro vmc.decode.ptr.inner A,mode,id {

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

  match =0 =% id , ok B \{
    vmc.decode.struc.inner A,mode,id
    ok equ 1

  \}

}

; ---   *   ---   *   ---
; ^yes

macro vmc.decode.struc.inner A,mode,id {

  ; deref by macro!
  match btr , id \{

    match =read , mode \\{
      A equ btr\#%origin

    \\}

    match =write , mode \\{
      btr\#%origin equ A

    \\}

    match =bop op , mode \\{
      vmem.\\#op base,A,$00,size

    \\}

    match =uop op , mode \\{
      vmem.\\#op base,$00,size

    \\}

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

  ; deref CAS(?+addr) by default
  local ok
  local base
  local expr
  local addr

  ok   equ 0
  base equ vmc.CAS
  expr equ id

  addr = 0


  ; ^get addr is segment-relative
  match seg =: any , id \{
    base equ seg
    expr equ any

  \}


  ; get addr from expr
  match any , expr \{
    vmc.decode.calc addr,any

  \}


  ; now deref
  match =read , mode \{
    vmem.get A,base,addr,size

  \}

  match =write , mode \{
    vmem.set base,A,addr,size

  \}

  match =uop op , mode \{
    vmem.\#op base,addr,size

  \}

  match =bop op , mode \{
    vmem.\#op base,A,addr,size

  \}

}

; ---   *   ---   *   ---
; solves operations from
; right to left

$RECURSIVE vmc.decode.calc,dst,X

  macro vmc.decode.calc dst,X \{

    local ok
    ok equ 0

    local w0
    local w1

    w0=0
    w1=0


    ; expr is operation
    match lh op rh , X \\{

      ; get left hand
      vmc.decode.reg ownok,w0,lh,read
      vmc.decode.imm ownok,w0,lh,read

      ; get right hand by recursing
      vmc.decode.calc w1,rh

      ; get result
      dst=w0 op w1

      ok equ 1

    \\}


    ; ^expr is a plain value
    match =0 , ok \\{
      vmc.decode.reg ok,w0,X,read
      vmc.decode.imm ok,w0,X

      dst = w0

    \\}

  \}

$RECURSIVE.end

; ---   *   ---   *   ---
; special-case decode for lea ;>

macro vmc.decode.addr dst,src {

  local ok
  local base
  local expr
  local addr

  ok equ 0
  addr=0

  ; get addr is segment-relative
  match =[ seg =: any =] , src \{
    base equ seg
    expr equ any
    ok   equ 1

  \}

  ; ^nope, plain addr
  match =0 =[ any =] , ok src \{
    base equ vmc.CAS
    expr equ any

  \}


  ; get addr from expr
  match any , expr \{
    vmc.decode.calc addr,any

  \}

  ; ^now get base+addr
  match id , base \{
    dst=id\#.beg+addr

  \}

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


  ; deref by macro!
  match btr , id \{

    match type , btr\#%type \\{

      match =read , mode \\\{
        type\\#.#tag#.get A,btr

      \\\}

      match =write , mode \\\{
        type\\#.#tag#.set btr,A

      \\\}

      match =uop op , mode \\\{
        type\\#.#tag#.\\\#op btr

      \\\}

      match =bop op , mode \\\{
        type\\#.#tag#.\\\#op btr,A

      \\\}

    \\}

  \}

}

; ---   *   ---   *   ---
; is src an immediate?

macro vmc.decode.imm ok,A,B,mode=read {

  match =0 , ok \{

    match =read , mode \\{
      A=B

    \\}

    ; this one you shouldn't do
    match =write , mode \\{
      B=A

    \\}


    ; these you REALLY shouldn't
    match =violation4 dst src , mode B A \\{
      dst equ src

    \\}

    match =violation5 dst src , mode A B \\{
      dst equ src

    \\}


    ; ^oww-well, wat the hell! ;>
    match =uop op , mode \\{
      vmem.\\#op\\#.inner B

    \\}

    match =bop op , mode \\{
      vmem.\\#op\\#.inner B,A

    \\}

    ok equ 1

  \}

}

; ---   *   ---   *   ---
