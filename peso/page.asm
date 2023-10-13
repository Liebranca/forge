; ---   *   ---   *   ---
; PESO PAGE
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

library ARPATH '/forge/'
  use '.inc' peso::proc

import

; ---   *   ---   *   ---
; info

  TITLE     peso.page

  VERSION   v0.00.5b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; cstruc

proc.new page.new

  push r11

  ; [0] rdi is size in bytes
  ; get N*page from that
  page.align

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
  pop r11

  ret


; ---   *   ---   *   ---
; ^dstruc

proc.new page.free
macro page.free.inline {

  ; N pages to N*page
  shl rsi,sizep2.page

  ; ^call munmap
  mov rax,$0B

  syscall

}

  ; ^invoke
  inline page.free

  ret

; ---   *   ---   *   ---
