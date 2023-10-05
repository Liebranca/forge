; ---   *   ---   *   ---
; PESO CRYPT
; Spooky stuff
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

  TITLE     peso.crypt

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; get N-bits hash

unit.salign r,x
proc.new crypt.xorkey

  proc.enter

  ; clear
  xor rax,rax
  xor rbx,rbx

  ; get mask
  mov rdx,1
  mov rcx,rsi
  shl rdx,cl
  dec rdx


  ; ^word-mash
  .top:

    ; get N bit chunk
    mov rbx,rdi
    and rbx,rdx

    ; ^xor with accum and go next
    xor rax,rbx
    shr rdi,cl


    ; rept on X > 0
    cmp rdi,$00
    jg  .top


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; iterative clamp

proc.new crypt.rotcap

  proc.enter

  ; get mask
  mov rdx,1
  mov rcx,rsi
  shl rdx,cl
  dec rdx

  ; ^inverted
  mov rsi,rdx
  not rsi


  ; ^iter
  mov rax,rdi
  .top:

    ; squash upper
    mov rbx,rax

    and rax,rdx
    and rbx,rsi
    shr rbx,cl

    ; add diff
    add rax,rbx

    ; rept on X > limit
    cmp rax,rdx
    jg  .top


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; X to idex

proc.new hash

  proc.enter


  ; rotating here is for cases
  ; where the first few bits
  ; are always zero; makes it
  ; all smaller if so
  ror rdi,cl

  ; ^get N-bits key
  push rdx
  call crypt.xorkey

  ; ^clamp result
  mov  rdi,rax
  pop  rsi

  call crypt.rotcap


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
