; ---   *   ---   *   ---
; A9M VCRYPT
; Spooky stuff (virtualized!)
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.vcrypt

  VERSION   v0.00.7b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  vcrypt.ASCII_MIN = $2020202020202020
  vcrypt.ASCII_MAX = $5F005F005F005F00

; ---   *   ---   *   ---
; get chunk-sized hash

macro vcrypt.xorkey src,size {

  match id , src \{

    ; clear
    $xor ar,ar
    $xor br,br

    ; walk in N-sized steps
    $urdivp2 cr,id\#.len,sizep2.#size
    $repeat  cr,sizeof.#size

      ; get next chunk
      $mov dr,size [src+cr]

      ; ^add encoding offset
      $sub dr,vcrypt.ASCII_MIN and sizebm.#size
      $add dr,br

      $xor br,vcrypt.ASCII_MAX and sizebm.#size

      ; ^xor to accum
      $xor ar,dr
      $and ar,sizebm.#size

    end repeat

  \}

}

; ---   *   ---   *   ---
; ^clamp to N-bits

macro vcrypt.rotcap bits {

  ; get mask,imask
  $mov br,(1 shl bits)-1
  $mov cr,br
  $not cr

  ; iter
  while 1

    $mov dr,ar

    ; get [low,high]
    $and ar,br
    $and dr,cr

    ; ^shift high to low
    $shr dr,bits
    $xor ar,dr

    ; ^stop when value fits in N-bits
    $break on ar <= br

  end while

}

; ---   *   ---   *   ---
; ^wraps

macro vcrypt.hash src,chunk {
  vcrypt.xorkey src,chunk
  vcrypt.rotcap bits

}

; ---   *   ---   *   ---
