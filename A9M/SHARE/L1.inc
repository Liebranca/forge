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

  VERSION   v0.00.1b
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
; base struc

vreg.new A9M.L1.head

  ; 3-bit type
  ; 1-bit repl
  ; 4-bit fam
  szmy byte TRF

  ; 8-bit sub-id
  szmy byte SID

  ; 4-bit curly
  ; 4-bit parens
  szmy byte CP

  ; 2-bit brak
  ; 6-bit len
  szmy byte BL

vreg.end
sizeof.A9M.L1.head=$04

; ---   *   ---   *   ---
; ^single ice

define          A9M.L1.ctx
A9M.L1.head.new A9M.L1.ctx

; ---   *   ---   *   ---
