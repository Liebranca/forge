; ---   *   ---   *   ---
; A9M OPCODE
; Punching bits
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; mask generator

macro MASKOF name,bits {

  SIZE.#name = bits
  MASK.#name = (1 shl bits) - 1

}

; ---   *   ---   *   ---
; ROM

  ; opcode chunk bit-sizes
  MASKOF OPID , $01
  MASKOF RATX , $01
  MASKOF RATS , (SIZE.RATX*2)
  MASKOF SEG  , $02

  ; segment types
  SEG.ANIMA  = $00
  SEG.STACK  = $01
  SEG.ICEREL = $02
  SEG.NONREL = $03

; ---   *   ---   *   ---
; reads segment address

macro getseg dst,name {

  match id , name \{
    dst = id\#.beg

  \}

}

; ---   *   ---   *   ---
; reads operand

macro getrat dst,src,mode,cnt {

  ; memory location
  if mode = 0

    ; fetch modifiers
    local bitsz
    local scale

    bitsz = 0
    scale = 1


    ; consume segment bits
    local seg
    seg = 0

    $mash seg,src,SEG


    ; ^reading register
    if seg = SEG.ANIMA

      bitsz = $04
      scale = $08

      getseg seg,vmc.ANIMA


    ; ^reading stack or instance
    else if (seg = SEG.STACK) | (seg = SEG.ICEREL)
      bitsz = $08

      ; get begof stack
      if seg = SEG.STACK
        getseg seg,vmc.STACK

        seg   = seg + A9M.STACK_SZ
        scale = -1

      ; ^get addrof ice
      else

        match id , vmc.NON \{
          load seg word from id\#.base:$0C

        \}

      end if


    ; ^reading from parent block
    else if seg = SEG.NONREL
      bitsz = $10

    end if


    ; get encoded value
    dst = src and ((1 shl bitsz)-1)
    src = src shr bitsz

    dst = seg+(dst*scale)


    ; WATCH OUT! LEAAAAAAAAAAAAA
    ; fetch src
    if cnt = 1

      match id , vmc.NON \{
        load dst word from id\#.base:dst

      \}

    end if


  ; ^immediate
  else
    dst = src and ((1 shl $20)-1)
    src = src shr $20

  end if

}

; ---   *   ---   *   ---
; mask and shift!

macro $mash dst,src,name {
  dst = src and MASK.#name
  src = src shr SIZE.#name

}

; ---   *   ---   *   ---
; read opcode

macro ipret X {

  ; copy input
  local opcd
  opcd = X

  ; consume opid bits
  local opid
  $mash opid,opcd,OPID


  ; consume rat mode bits
  local mX
  local mY
  local mm

  $mash mm,opcd,RATS
  $mash mX,mm,RATX
  $mash mY,mm,RATX


  ; ^get both rats
  local  rX
  local  rY

  getrat rX,opcd,mX,0
  getrat rY,opcd,mY,1


  ; perform write
  match id , vmc.NON \{
    store word rY at id\#.base:rX

  \}

}

; ---   *   ---   *   ---
; Arcane 9 mov $24 to sb-1
; but in binary!
;
;            STACK
;            +------>:   /-->operand modes
;            |           |
;     .......^.......|.|.||
;            [           [
ipret 001001000000000101101b
;            ]        -]
;     .......v         v
;            |         |
;     <------+         \-->segment
;     IMM32

STACK.bprich

; ---   *   ---   *   ---
