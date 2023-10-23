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

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.page

  VERSION   v0.00.5b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

SYS.mmap:

  .id        = $09

  .proto_r   = $01
  .proto_rw  = $03
  .proto_rx  = $05

  .anon_priv = $22

  .nofd      = -1


SYS.munmap.id=$0B

; ---   *   ---   *   ---
; cstruc

proc.new page.new
proc.cpr r11

  proc.enter

  ; [0] rdi is size in bytes
  ; get N*page from that
  page.align

  ; ^set page*N
  mov rsi,rax


  ; linux boilerpaste
  mov rdx,SYS.mmap.proto_rw
  mov r10,SYS.mmap.anon_priv
  mov r8 ,SYS.mmap.nofd

  xor rdi,rdi
  xor r9 ,r9

  ; ^call mmap
  mov rax,SYS.mmap.id
  syscall


  ; cleanup and give
  proc.leave
  ret


; ---   *   ---   *   ---
; ^dstruc

proc.new page.free
macro page.free.inline {

  proc.enter

  ; N pages to N*page
  shl rsi,sizep2.page

  ; ^call munmap
  mov rax,SYS.munmap.id
  syscall

  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline page.free
  ret

; ---   *   ---   *   ---
