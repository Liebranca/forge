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

if ~ loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'
  use '.inc' OS

import

; ---   *   ---   *   ---
; info

  TITLE     peso.file

  VERSION   v0.00.4b
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
  .fto   dw STDOUT
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

  ; ^skip if so
  cmp rbx,rdi
  je .skip

  ; ^else flush, then swap
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

    ; get avail
    xor rdx,$00
    mov dx,word [buffio.avail]

    ; ^clear on below chunk
    cmp  dx,$10
    jge  .pre_walk
    call reap

    ; ^refresh avail
    mov dx,BUFFIO_SZ


  ; offset into buff
  .pre_walk:

    ; clear old offset
    xor rcx,rcx

    ; use smallest length
    cmp   si,dx
    cmovl dx,si

    ; get buff+ptr
    lea rbx,[buffio.ct]
    mov cx,word [buffio.ptr]
    add rbx,rcx

    ; stop on length exhausted
    cmp dx,$00
    jle .top


  ; ^walk in xword-sized chunks
  .walk:

    ; write to buff
    movdqa xmm0,xword [rdi]
    movdqa xword [rbx],xmm0

    ; clamp step
    mov   r8w,$10
    cmp   dx,r8w
    cmovl r8w,dx

    ; go next chunk
    add di,$10
    add bx,$10

    ; ^consume current
    add cx,$10
    sub dx,r8w
    sub si,r8w

    ; ^check end-of
    cmp dx,$10
    jge .walk


  ; ^adjust buff meta
  .post_walk:

    ; update ptr
    sub word [buffio.avail],cx
    mov word [buffio.ptr],cx

    ; repeat on pending
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
  xor rdi,rdi
  xor rdx,rdx

  ; ^commit buffer to file
  mov di,word [buffio.fto]
  mov rsi,buffio.ct
  mov dx,word [buffio.ptr]

  mov rax,SYS_WRITE
  syscall


  ; ^zero-flood
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
