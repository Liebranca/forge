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
; info

  TITLE     A9M.vmc

  VERSION   v0.01.0b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  vmc.debug = 0

; ---   *   ---   *   ---
; load bits

library ARPATH '/forge/'

  use '.inc' A9M::vmc::registers

  use '.inc' A9M::vmc::decode
  use '.inc' A9M::vmc::logic

  use '.inc' A9M::vmc::isbasic
  use '.inc' A9M::vmc::stack
  use '.inc' A9M::vmc::call

  use '.inc' A9M::vmc::msbin

library.import

; ---   *   ---   *   ---
; rounded-up division by
; a power of 2

macro $urdivp2 dst,src,N {

  local w0
  local w1

  w0=0
  w1=0

  vmc.decode    w0,src,read
  vmc.decode    w1,N,read

  vuint.urdivp2 w0,w0,w1
  vmc.decode    w0,dst,write

}

; ---   *   ---   *   ---
