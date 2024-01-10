; ---   *   ---   *   ---
; A9M L1:SHARED
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.SHARED.L1

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; bits

if ~ defined A9M.L1.TOKEN_SZ
  define A9M.L1.TOKEN_SZ $40

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
