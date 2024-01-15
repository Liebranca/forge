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
; info

  TITLE     A9M.vmc.decode

  VERSION   v0.00.1a
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

  match =0 =% id , ok B \{
    vmc.decode.struc.inner A,mode,id
    ok equ 1

  \}

}

; ---   *   ---   *   ---
; ^yes

macro vmc.decode.struc.inner A,mode,id {

  local lis
  lis equ id

  ; is id a named ptr? (fake regs ;>)
  local ok
  tokin ok,id,ice,ctx

  match =1 , ok \{
    lis equ vmd.REG.#id

  \}

  ; deref by macro!
  match btr , lis \{

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

  local ok
  ok equ 0

  ; deref base+offset
  match base op off , id \{

    local res
    res=0

    vmc.decode.mem.inner_off_0 res,off,op

    match =read , mode \\{
      vmem.get A,base,res,size

    \\}

    match =write , mode \\{
      vmem.set base,A,res,size

    \\}

    match =uop ins , mode \\{
      vmem.\\#ins base,res,size

    \\}

    match =bop ins , mode \\{
      vmem.\\#ins base,A,res,size

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

    match =uop op , mode \\{
      vmem.\\#op base,$00,size

    \\}

    match =bop op , mode \\{
      vmem.\\#op base,A,$00,size

    \\}

  \}

}

; ---   *   ---   *   ---
; ^innards

macro vmc.decode.mem.inner_off_0 dst,N,op {

  local ok
  ok equ 0

  local w0
  local w1

  w0=0
  w1=1

  match A op2 B , N \{

    vmc.decode.reg ok,w0,A,read
    vmc.decode.imm ok,w0,A

    ok equ 0

    vmc.decode.reg ok,w1,B,read
    vmc.decode.imm ok,w1,B

    dst=w0 op2 w1

    ok equ 1

  \}

  match =0 , ok \{
    vmc.decode.reg ok,w0,N,read
    vmc.decode.imm ok,w0,N

    dst = w0

  \}

  dst=0 op dst

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
