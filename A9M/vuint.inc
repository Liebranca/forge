; ---   *   ---   *   ---
; A9M VUINT
; Virtual quantities
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
  use '.inc' Arstd::uid
  use '.inc' peso::seg

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.vuint

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; round-up divide by pow2

macro vuint.urdivp2 dst,size,ali {

  if ~ (size)
    dst = 1 shl ali

  else
    dst = size+((1 shl ali)-1)
    dst = dst shr ali

  end if

}

; ---   *   ---   *   ---
; ^align to pow2

macro vuint.align dst,size,ali {
  vuint.urdivp2 dst,size,ali
  dst = dst shl ali

}

; ---   *   ---   *   ---
