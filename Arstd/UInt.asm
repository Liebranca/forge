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

library ARPATH '/forge/'
  use '.inc' peso::proc

library.import

; ---   *   ---   *   ---
; info

  TITLE     Arstd.UInt

  VERSION   v0.00.4b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---

ROMSEG UInt.MAGICO
  .div10 dq $CCCCCCCCCCCCCCCD

; ---   *   ---   *   ---
; rounded-up division

EXESEG

proc.new UInt.urdiv,public
proc.cpr rcx,rdx

macro UInt.urdiv.inline {

  proc.enter

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

  ; cleanup
  proc.leave

}

  ; invoke and give
  inline UInt.urdiv
  ret

; ---   *   ---   *   ---
; ^quick by-pow2 v

proc.new UInt.urdivp2,public
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

  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline UInt.urdivp2
  ret

; ---   *   ---   *   ---
; ^as a paste-in

macro UInt.urdivp2.proto size,keep=0 {

  match =1 , keep \{push rcx\}

  mov    rcx,size
  dpline UInt.urdivp2

  match =1 , keep \{pop rcx\}

}

; ---   *   ---   *   ---
; ^with scaling up

macro UInt.align.proto size,keep=0 {
  UInt.urdivp2.proto size,keep
  shl rax,size

}

; ---   *   ---   *   ---
; ^(round n/m) times m
; ie nearest multiple of

macro UInt.align n,m {

  mov    rdi,n
  mov    rsi,m

  dpline UInt.urdiv
  mul    rsi

}

; ---   *   ---   *   ---
; division by 10
; ty gcc ;>

proc.new UInt.div10,public
macro UInt.div10.inline {

  proc.enter

  ; multiply by magic number
  mov rax,qword [UInt.MAGICO.div10]
  mul rdi

  ; ^scale down
  mov rax,rdx
  shr rax,$03

  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline UInt.div10
  ret

; ---   *   ---   *   ---
; ^modulo black magic
; also ty gcc ;>

proc.new UInt.mod10,public
macro UInt.mod10.inline {

  proc.enter

  ; divide by ten
  dpline UInt.div10
  lea    rdx,[rax+rax*4]

  ; ^get rem
  mov rax,rdi
  add rdx,rdx
  sub rax,rdx

  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline UInt.mod10
  ret

; ---   *   ---   *   ---
