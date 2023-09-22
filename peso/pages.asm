; ---   *   ---   *   ---
; PESO PAGES
; Hands you BIG mem ;>
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'
  use '.asm' Arstd::UInt

import

; ---   *   ---   *   ---
; info

  TITLE     peso.pages

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; cstruc

segment readable executable
align $10

pages.new:

  ; [0] rdi is size in bytes
  ; get N*page from that
  call pages.align

  ; ^set page*N
  mov rsi,rax

  ; linux boilerpaste
  mov rdi,$00
  mov rdx,$03
  mov r10,$22
  mov r8,-1
  mov r9,$00

  ; ^call mmap
  mov rax,$09

  syscall
  ret


; ---   *   ---   *   ---
; ^dstruc

pages.free:

  ; N pages to N*page
  shl rsi,12

  ; ^call munmap
  mov rax,$0B

  syscall
  ret


; ---   *   ---   *   ---
; division by 4096 rounded up

pages.align:

  ; scale by page size
  mov rcx,12

  ; round-up division
  ; then apply scale
  UInt.urdivp2.inline
  shl rax,12


  ret

; ---   *   ---   *   ---
