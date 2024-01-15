; ---   *   ---   *   ---
; A9M VMC MSBIN
; Binary macro instructions
; volume I
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.vmc.msbin

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; get sized part of src
; then shift it out

macro $cons dst,cmd {

  match size src , cmd \{

    ; unpack args
    local bits
    local mask
    vmc.bitop_get_bm size,bits,mask

    ; get elem
    $mov dst,src
    $and dst,mask

    ; ^shift it out
    $shr src,bits

  \}

}

; ---   *   ---   *   ---
; or N sized elems together

macro vmc._comb_proto dst,total,cmd {

  match size src , cmd \{

    ; unpack args
    local bits
    local mask
    vmc.bitop_get_bm size,bits,mask

    ; get tmp
    local value
    value = 0

    ; get elem
    $mov value,src

    $and value,mask
    $shl value,total

    ; ^join with dst
    $or dst,value


    ; go next
    total = total+bits

  \}

}

; ---   *   ---   *   ---
; ^ice

macro $combf dst,[cmd] {

  common

    ; count number of bits catted
    local total
    total = 0

    ; clear dst
    $xor dst,dst

  forward vmc._comb_proto dst,total,cmd

}

; ---   *   ---   *   ---
; ^same thing in reverse

macro $combr dst,[cmd] {

  common
    local total
    total = 0
    $xor dst,dst

  reverse vmc._comb_proto dst,total,cmd

}

; ---   *   ---   *   ---
; byte-wise reversal

macro $breverse dst,size=$10 {

  ; unpack arg
  local bits
  local mask
  vmc.bitop_get_bm size,bits,mask

  ; get step
  local shift
  shift = bits - $08

  ; tmp
  local res
  local elem
  res  = 0
  elem = 0


  ; do the byte castling ;>
  repeat bits/8

    ; put first elem last
    $mov elem,dst
    $and elem,$FF
    $shl elem,shift

    ; ^join to result
    $or  res,elem

    ; ^get next
    $shr dst,$08
    shift = shift - $08

  end repeat


  ; replace dst with result
  $mov dst,res

}

; ---   *   ---   *   ---
; get [bits,mask] for operations
; dealing with bit-size such

macro vmc.bitop_get_bm size,bits,mask {

  ; named size passed
  if sizeof.#size
    bits = sizeof.#size * 8

  ; ^number of bits passed
  else
    bits = size

  end if

  ; get longlong proof mask
  $bones mask,bits

}

; ---   *   ---   *   ---
