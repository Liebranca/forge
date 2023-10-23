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

library ARPATH '/forge/'
  use '.inc' OS
  use '.inc' peso::proc

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.file

  VERSION   v0.00.5b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

RAMSEG

reg.new file.buff

  my .SZ   = $100
  my .REPT = $10


  ; pool
  my .ct    db .SZ dup $00

  ; bkeep
  my .fto   dw stdout
  my .avail dw .SZ

  my .ptr   dw $00

reg.end

reg.ice file.buff buffio

; ---   *   ---   *   ---
; set fhandle

EXESEG

proc.new fto
proc.cpr rbx

  proc.enter

  ; get current fh eq passed
  xor rbx,rbx
  mov bx,word [buffio.fto]

  ; ^skip if so
  cmp rbx,rdi
  je  .skip

  ; ^else flush, then swap
  call reap
  mov  word [buffio.fto],di


  ; cleanup and give
  .skip:

  proc.leave
  ret


; ---   *   ---   *   ---
; ^issue write

proc.new sow
proc.cpr rbx,rdi,rsi

  proc.enter

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
    mov dx,buffio.SZ


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
    or rsi,$00
    jg .top


  ; cleanup and give
  proc.leave
  ret


; ---   *   ---   *   ---
; ^write, then empty used buff

proc.new reap
proc.cpr r11,rdi,rsi

  proc.enter

  ; clear registers
  xor rdi,rdi
  xor rdx,rdx

  ; ^commit buffer to file
  mov di,word [buffio.fto]
  mov rsi,buffio.ct
  mov dx,word [buffio.ptr]

  mov rax,SYS.write.id
  syscall


  ; ^zero-flood
  pxor xmm0,xmm0

  repeat buffio.REPT
    movdqa xword [rsi],xmm0
    add    rsi,$10

  end repeat


  ; ^reset meta
  mov word [buffio.avail],buffio.SZ
  mov word [buffio.ptr],$0000


  ; cleanup and give
  proc.leave
  ret


; ---   *   ---   *   ---
