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

  VERSION   v0.01.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; load core

library ARPATH '/forge/'
  use '.inc' A9M::vmc::registers
  use '.inc' A9M::vmc::stack

library.import

; ---   *   ---   *   ---
; ROM

  sizeof.vmc = sizeof.ANIMA+A9M.STACK_SZ

; ---   *   ---   *   ---
; GBL

  ; root block; all system
  ; memory cats to this
  define   vmc.NON
  vmem.new vmc.NON,blk sizeof.vmc

  ; ^[C]urrent [A]ddressing [S]pace
  ;
  ; this is here so that the user
  ; can declare their own root block
  define vmc.CAS


  ; flips prints ;>
  vmc.debug = 0

; ---   *   ---   *   ---
; load bits

library ARPATH '/forge/'

  use '.inc' A9M::vmc::decode
  use '.inc' A9M::vmc::logic

  use '.inc' A9M::vmc::isbasic
  use '.inc' A9M::vmc::isarcana
  use '.inc' A9M::vmc::call

  use '.inc' A9M::vmc::msbin

library.import

; ---   *   ---   *   ---
; nit yourself!

  $casset vmc.NON

  vmc.registers.new
  vmc.stack.new

; ---   *   ---   *   ---
