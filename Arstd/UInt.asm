; ---   *   ---   *   ---
; ARSTD UINT
; Fixed point is fun!
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb

; ---   *   ---   *   ---
; info

  TITLE     Arstd.UInt

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; rounded-up division

segment readable executable
align $10

UInt.urdiv:

  push rcx
  push rdx

  ; calc scale
  bsr rcx,rsi

  ; scale up
  mov rax,rdi
  shl rax,cl

  ; div m
  xor rdx,rdx
  div rsi

  ; ^round up (add s-1)
  mov rdx,1
  shl rdx,cl
  dec rdx

  add rax,rdx

  ; scale down
  shr rax,cl


  ; clean
  pop rdx
  pop rcx

  ret

; ---   *   ---   *   ---
; ^quick by-pow2 v

UInt.urdivp2:
macro UInt.urdivp2.inline {

  ; [1] cx is exponent
  ; get 2^N thru shift
  mov rax,1
  shl rax,cl

  ; [0] rdi is X to align
  ; ensure non-zero
  mov   rdx,$01
  or    rdi,$00
  cmove rdi,rdx


  ; (X + (2^N)-1) >> N
  ; gives division rounded up
  lea rax,[rdi+rax-1]
  shr rax,cl

}

  ; ^invoke
  UInt.urdivp2.inline
  ret


; ---   *   ---   *   ---
; ^(round n/m) times m
; ie nearest multiple of

macro UInt.align n,m {

  mov rdi,n
  mov rsi,m

  call UInt.urdiv
  mul  rsi

}


; ---   *   ---   *   ---
