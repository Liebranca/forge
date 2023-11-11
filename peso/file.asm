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
  use '.asm' peso::memcpy

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.file

  VERSION   v0.00.6b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

RAMSEG

file.buff.SZ   = $100
file.buff.REPT = file.buff.SZ shr 7

reg.new file.buff,public

  ; pool
  my .ct    db file.buff.SZ dup $00

  ; bkeep
  my .fto   dw stdout

  my .avail dd file.buff.SZ
  my .ptr   dd $00

reg.end

reg.ice file.buff buffio

; ---   *   ---   *   ---
; set fhandle

EXESEG

proc.new fto,public

  proc.enter

  ; get current fh eq passed
  xor rax,rax
  mov ax,word [buffio.fto]

  ; ^skip if so
  cmp rax,rdi
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

proc.new sow,public

  proc.enter

  ; store total
  mov r9,rsi
  mov rsi,rdi

  ; flush on full buff
  .chk_size:

    ; get avail
    xor r8,r8
    mov r8d,dword [buffio.avail]

    ; ^clear on below chunk
    cmp  r8d,sizeof.unit
    jge  .go_next
    call reap

    ; ^refresh avail
    mov r8w,file.buff.SZ


  ; ^write next chunk
  .go_next:

    ; use smallest length
    cmp   r9d,r8d
    cmovl r8d,r9d
    sub   r9d,r8d

    ; get buff+ptr
    xor edx,edx
    mov edx,dword [buffio.ptr]
    lea rdi,[buffio.ct+edx]

    ; adjust buff meta
    sub dword [buffio.avail],r8d
    add dword [buffio.ptr],r8d


  ; write chunks
  .cpy:

    mov r10w,smX.CDEREF
    call memcpy

    ; ^restart
    or r9d,$00
    jg .chk_size


  ; cleanup and give
  proc.leave
  ret


; ---   *   ---   *   ---
; ^write, then empty used buff

proc.new reap,public
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

  repeat file.buff.REPT

    movdqa xword [rsi+$00],xmm0
    movdqa xword [rsi+$10],xmm0
    movdqa xword [rsi+$20],xmm0
    movdqa xword [rsi+$30],xmm0

    movdqa xword [rsi+$40],xmm0
    movdqa xword [rsi+$50],xmm0
    movdqa xword [rsi+$60],xmm0
    movdqa xword [rsi+$70],xmm0

    add    rsi,$80

  end repeat


  ; ^reset meta
  mov word [buffio.avail],file.buff.SZ
  mov word [buffio.ptr],$0000


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; footer

MAM.atexit.push call reap

; ---   *   ---   *   ---
