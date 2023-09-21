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

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

segment readable writeable
align $10

buffio:

  define BUFFIO_SZ   $100
  define BUFFIO_REPT $10


  ; ^pool
  .ct    db BUFFIO_SZ dup $00


  ; ^keep
  .fto   dw $01
  .avail dw BUFFIO_SZ

  .ptr   dw $00


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

  push rdi
  push rsi

  push rbx
  push rcx
  push rdx


  ; flush on full buff
  .top:

    mov   rdx,$00
    mov   dx,word [buffio.avail]

    cmp   dx,$10
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


  ; ^walk in xword-sized chunks
  .walk:

    ; write to buff
    movdqa xmm0,xword [rdi]
    movdqa xword [rbx],xmm0

    ; go next chunk
    add rdi,$10
    add rbx,$10

    ; check end-of
    add cx,$10
    sub dx,$10

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

  pop rsi
  pop rdi

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


  ; ^wipe pool
  pxor xmm0,xmm0

  repeat BUFFIO_REPT
    movdqa xword [rsi],xmm0
    add    rsi,$10

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
