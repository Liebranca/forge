; ---   *   ---   *   ---
; MEMCMP
; Byte matchin
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     peso.memcmp

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.asm' peso::memcpy

library.import

; ---   *   ---   *   ---
; ^dst struc

reg.new memcmp.req

  my .l0 dq 2 dup $00
  my .l1 dq 2 dup $00
  my .l2 dq 2 dup $00
  my .l3 dq 2 dup $00
  my .l4 dq 2 dup $00
  my .l5 dq 2 dup $00
  my .l6 dq 2 dup $00
  my .l7 dq 2 dup $00

reg.end

; ---   *   ---   *   ---
; *data eq *data

proc.new memcmp

  ; get branch
  proc.enter
  call smX.get_size

; ---   *   ---   *   ---
; ^for when you want to skip
; recalculating size!

memcmp.direct:

  cmp dl,$04
  jge .is_struc

  ; i8-64 jmptab
  smX.i_tab smX.i_cmp,ret

  ; ^sse
  .is_struc:
    call memcpy.struc
    ret


  ; void
  proc.leave

; ---   *   ---   *   ---
