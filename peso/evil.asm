; ---   *   ---   *   ---
; PESO EVIL
; Debugness
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
  use '.inc' peso::constr

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.evil

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; string match dbout

EXESEG

proc.new dbout.bool,public

  proc.enter

  constr.new me_00,"1",$0A
  constr.new me_01,"0",$0A

  ; A eq B
  mov rdi,me_00
  mov rsi,me_00.length

  ; A ne B
  or  rax,$00
  jnz @f

  mov rdi,me_01
  mov rsi,me_01.length


  ; ^write
  @@:call sow

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; footer

constr ROM
MAM.avto

; ---   *   ---   *   ---
