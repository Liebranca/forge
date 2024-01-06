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
; deps

library ARPATH '/forge/'
  use '.inc' A9M::vreg

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.vcrypt

  VERSION   v0.00.6b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  vcrypt.ASCII_MIN = $2020202020202020
  vcrypt.ASCII_MAX = $5F005F005F005F00

; ---   *   ---   *   ---
; get chunk-sized hash

macro vcrypt.xorkey dst,src,size {

  local mask
  local chunk
  local len
  local flip

  ; varlis
  mask  equ vcrypt.xorkey.mask
  chunk equ vcrypt.xorkey.chunk
  len   equ vcrypt.xorkey.len
  flip  equ vcrypt.xorkey.flip

  if sizeof.#size = 8
    mask=not 0

  else
    mask=(1 shl (sizeof.#size*8))-1

  end if

  dst   = 0


  ; reset ptr
  vmem.rewind src

  ; walk src
  flip=0

  match id , src \{

    ; walk in N-sized steps
    vuint.urdivp2 len,id\#.len,sizep2.#size

    ; ^xor chunks together
    repeat len

      vmem.read chunk,src,size

      chunk = chunk - (ASCII_MIN and sizebm.#size)
      chunk = chunk + (flip and sizebm.#size)
      flip  = flip xor ASCII_MAX

      dst   = dst xor (chunk and mask)

    end repeat

  \}

  ; ^re-reset
  vmem.rewind src

}

; ---   *   ---   *   ---
; ^clamp to N-bits

macro vcrypt.rotcap dst,bits {

  local mask
  local imask
  local tmp

  ; varlis
  mask  equ vcrypt.rotcap.mask
  imask equ vcrypt.rotcap.imask
  tmp   equ vcrypt.rotcap.tmp

  mask  = (1 shl bits)-1
  imask = not mask

  ; ^collapse
  while 1

    tmp = dst
    dst = dst and mask
    tmp = (tmp and imask) shr bits
    dst = dst xor tmp

    if dst <= mask
      break

    end if


  end while

}

; ---   *   ---   *   ---
; ^wraps

macro vcrypt.hash dst,src,chunk,bits {
  vcrypt.xorkey dst,src,chunk
  vcrypt.rotcap dst,bits

}

; ---   *   ---   *   ---
