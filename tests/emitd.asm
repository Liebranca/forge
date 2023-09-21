format ELF64 executable 3

; ---   *   ---   *   ---
; testing code generated
; by AR/peso ;>

entry _start

; ---   *   ---   *   ---
; get importer

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.asm' peso::file

import

; ---   *   ---   *   ---

align $10
label non


; --- *   ---   *   ---

segment readable executable
align $10
label .crux


  mov  rbx,17
  mov  r11,36
  lea  rax,[rbx+r11]
  imul rax,2
  mov  rbx,rax


ret

; --- *   ---   *   ---
; cruxwraps

align $10
_start:
  call non.crux
  exit

; ---   *   ---   *   ---
