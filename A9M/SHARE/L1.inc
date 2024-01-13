; ---   *   ---   *   ---
; A9M L1:SHARE
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.SHARE.L1

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

if ~ defined A9M.L1.TOKEN_SZ
  define A9M.L1.TOKEN_SZ $40

end if

if ~ defined A9M.L1.DEFTAB

  match __path , A9M.ROMPATH {
    define A9M.L1.DEFTAB __path#'L1.vhash'

  }

end if

; ---   *   ---   *   ---
; lexer definitions helper

macro A9M.L1.mklex_bits [item] {

  forward match name value , item \{
    A9M.L1.LEX.\#name = value

  \}

}

; ---   *   ---   *   ---
; ^the bits

  ; token classes (last bit reserved!)
  A9M.L1.mklex_bits \
    HIER $00,\
    SPEC $01,\
    PTR  $02,\
    ID   $03

  ; ^token attrs
  A9M.L1.mklex_bits \
    REPL $08

  ; ^subclass!
  rept $10 __cnt:0 {
    A9M.L1.mklex_bits \
      SPEC_#__cnt (__cnt shl 4)

  }

; ---   *   ---   *   ---
; joins bits together

macro A9M.L1.mklex name,[bit] {

  common
    A9M.L1.#name = 0

  forward

    local N
    N = A9M.L1.LEX.#bit

    A9M.L1.#name = A9M.L1.#name or N

}

; ---   *   ---   *   ---
; ^the bytes!

  A9M.L1.mklex HIER_T,HIER,REPL,SPEC_0
  A9M.L1.mklex HIER_S,SPEC,SPEC_0

  A9M.L1.mklex TYPE_S,SPEC,SPEC_1

  A9M.L1.mklex METAOP_T,HIER,SPEC_1
  A9M.L1.mklex ID_T,ID,SPEC_15

; ---   *   ---   *   ---
; base struc

vreg.new A9M.L1.head

  ; 3-bit type
  ; 1-bit repl
  ; 4-bit fam
  szmy byte TRF

  ; 8-bit sub-id
  szmy byte SID

vreg.end
sizeof.A9M.L1.head=$02

; ---   *   ---   *   ---
; ^single ice

define          A9M.L1.ctx
A9M.L1.head.new A9M.L1.ctx

; ---   *   ---   *   ---
