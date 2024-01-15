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

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  ; incomplete list, see below
  define A9M.REGISTERS \
    ar,br,cr,dr,\
    er,fr,gr,hr,\
    sp,sb


  ; the Arcane 9 would set this to
  ; addrof caller; won't work here!
  define vmc.REG.xp

  ; ^likewise, addrof callee
  define vmc.REG.xs

  ; ^addrof active instance
  define vmc.REG.ice

  ; ^addof input buffer
  define vmc.REG.ctx

; ---   *   ---   *   ---
; bat-decl for registers

macro vmc._decl_reg [name] {
  forward szmy qword name

}

; ---   *   ---   *   ---
; ^base struc

vreg.new ANIMA
match __list , A9M.REGISTERS {
  vmc._decl_reg __list

}

vreg.end

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
; GBL

  define    vmc.REG
  ANIMA.new vmc.REG

; ---   *   ---   *   ---
