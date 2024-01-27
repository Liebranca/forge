; ---   *   ---   *   ---
; A9M VMC REGISTERS
; Soul of computing
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

  TITLE     A9M.vmc.registers

  VERSION   v0.00.4b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

if ~ defined A9M.REGISTER_SZ_K
  define A9M.REGISTER_SZ_K qword

end if

match __key , A9M.REGISTER_SZ_K {
  A9M.REGISTER_SZ   = sizeof.#__key
  A9M.REGISTER_SZP2 = sizep2.#__key

}

; ---   *   ---   *   ---
; load generated

library ARPATH '/forge/'
  use '.pinc' A9M::ROM::registers

library.import

; ---   *   ---   *   ---
; bat-decl

macro vmc._decl_reg [name] {
  forward szmy A9M.REGISTER_SZ_K name

}

; ---   *   ---   *   ---
; ^make struc

vreg.new ANIMA
match __list , A9M.REGISTERS {
  vmc._decl_reg __list

}

vreg.end

; ---   *   ---   *   ---
; ^nit yourself!

macro vmc.registers.new {

  define    vmc.REG
  ANIMA.new vmc.REG,vmc.CAS at $00

  define        ANIMA.base
  vreg.get_base ANIMA.base,vmc.REG

}

; ---   *   ---   *   ---
; ^dbout wraps

macro ANIMA.prich {
  ANIMA.prich vmc.REG

}

macro ANIMA.bprich {
  display $0A,'ANIMA:'
  ANIMA.bprich vmc.REG

}

; ---   *   ---   *   ---
