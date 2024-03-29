format ELF64 executable 3

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

; ---   *   ---   *   ---

library ARPATH '/forge/'

  use '.asm' Arstd::String
  use '.inc' OS

  use '.asm' peso::file

import

; ---   *   ---   *   ---
; GBL

  entry     _start

  BLACK   = $3030
  RED     = $3130
  GREEN   = $3230
  YELLOW  = $3330

  BLUE    = $3430
  PURPLE  = $3530
  CYAN    = $3630
  WHITE   = $3730

  BOLD    = $3130
  DIM     = $3132

; ---   *   ---   *   ---

segment readable writeable

fld0:

       db $1B,$5B
  .coy db '00'
       db $3B
  .cox db '00'
       db 'H'

       db $1B,$5B,'2K'

; ---   *   ---   *   ---

       db $1B,$5B
  .fga db '30'

       db $3B
  .fgb db '22'
       db 'm'

; ---   *   ---   *   ---

       db $1B,$5B
  .bga db '40'

       db $3B
  .bgb db '25'
       db 'm'

; ---   *   ---   *   ---

  .txt db 'Whoa!',$00

       db $1B,$5B
       db '00','m'

       db $0A,$00

; ---   *   ---   *   ---

  .len=$-fld0

; ---   *   ---   *   ---
; unrelated test

align $10
strme:

  db "SOW-BUFFIO REPEATING HLOWRLD!",$0A

align $10
  .len=$-strme

; ---   *   ---   *   ---

segment readable executable

proc set_fg

  or  di,$3

  mov word [fld0.fga],di
  mov word [fld0.fgb],si

end_proc ret

proc set_bg

  or  di,$0004
  add si,$0400

  mov word [fld0.bga],di
  mov word [fld0.bgb],si

end_proc ret

; ---   *   ---   *   ---

;proc _start

_start:

  ; print
  mov rdi,strme
  mov rsi,strme.len

  repeat 32
    call sow

  end repeat
  call reap


;  call set_fg,RED,BOLD
;  call set_bg,BLACK,BOLD

;  write 1,fld0,fld0.len

  exit

;end_proc leave

; ---   *   ---   *   ---
