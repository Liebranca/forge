; ---   *   ---   *   ---
; PESO FILE
; Sow buffio!
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
  use '.inc' OS

import

; ---   *   ---   *   ---
; info

  TITLE     peso.file

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

segment readable writeable
align $10

buffio:

  define BUFFIO_SZ   $1000
  define BUFFIO_REPT $0200

  .fto   dw $01
  .avail dw BUFFIO_SZ

  .ptr   dw $00
  .ct    db BUFFIO_SZ dup $00


; ---   *   ---   *   ---
; set fhandle

segment readable executable
align $10

fto:

  push rbx


  ; get current fh eq passed
  xor rbx,rbx
  mov bx,word [buffio.fto]

  cmp rbx,rdi
  je .skip


  call reap
  mov word [buffio.fto],di


  ; cleanup
  .skip:
    pop rbx
    ret

; ---   *   ---   *   ---
; ^issue write

sow:

  push rbx
  push rcx
  push rdx


  ; flush on full buff
  .top:

    mov   rdx,$00
    mov   dx,word [buffio.avail]

    cmp   dx,$08
    jge   .pre_walk
    call  reap

    mov   dx,BUFFIO_SZ


  ; offset into buff
  .pre_walk:

    xor   rcx,rcx

    cmp   rsi,rdx
    cmovl rdx,rsi

    lea   rbx,[buffio.ct]
    mov   cx,word [buffio.ptr]
    add   rbx,rcx

    cmp   dx,$00
    jle   .top


  ; ^walk in qword-sized chunks
  .walk:

    ; write to buff
    mov rax,[rdi]
    mov qword [rbx],rax

    ; go next chunk
    add rdi,$08
    add rbx,$08

    ; check end-of
    add cx,$08
    sub dx,$08

    cmp dx,$00
    jg  .walk


  ; ^adjust buff meta
  .post_walk:

    sub word [buffio.avail],cx
    mov word [buffio.ptr],cx

    sub rsi,rcx

    or  rsi,$00
    jg  .top


  ; cleanup
  pop rdx
  pop rcx
  pop rbx

  ret


; ---   *   ---   *   ---
; ^write, then empty used buff

reap:

  push rdi
  push rsi
  push rdx


  ; clear registers
  mov rdi,$00
  mov rdx,$00

  ; ^commit buffer to file
  mov di,word [buffio.fto]
  mov rsi,buffio.ct
  mov dx,word [buffio.ptr]

  mov rax,SYS_WRITE
  syscall


  ; ^wipe N chunks
  repeat BUFFIO_REPT
    mov qword [rsi],$00
    add rsi,$08

  end repeat


  ; ^reset meta
  mov word [buffio.avail],BUFFIO_SZ
  mov word [buffio.ptr],$0000


  ; cleanup
  pop rdx
  pop rsi
  pop rdi

  ret


; ---   *   ---   *   ---
