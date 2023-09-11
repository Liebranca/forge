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
; deps

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'
  use '.inc' peso::proc
  use '.asm' OS::Mem

import

; ---   *   ---   *   ---
; info

  TITLE     Arstd.UInt

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

  CLAN      UInt

; ---   *   ---   *   ---
; rounded-up division

segment readable executable
align $10

urdiv:

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
; ^(round n/m) times m
; ie nearest multiple of

macro UInt.align n,m {

  mov rdi,n
  mov rsi,m

  call urdiv
  mul  rsi

}

; ---   *   ---   *   ---
