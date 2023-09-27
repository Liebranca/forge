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

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'
  use '.asm' peso::unit

import

; ---   *   ---   *   ---
; info

  TITLE     peso.page

  VERSION   v0.00.3b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  define sizeof.page $1000
  define sizep2.page $0C

; ---   *   ---   *   ---
; division by 4096 rounded up

unit.salign r,x

proc.new page.align
macro page.align.inline {

  ; scale by page size
  mov rcx,sizep2.page

  ; round-up division
  ; then apply scale
  inline UInt.urdivp2
  shl    rax,sizep2.page

}

  ; ^invoke
  inline page.align

  ret

; ---   *   ---   *   ---
; cstruc

proc.new page.new

  ; [0] rdi is size in bytes
  ; get N*page from that
  inline page.align

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
