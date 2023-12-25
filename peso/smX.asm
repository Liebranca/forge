; ---   *   ---   *   ---
; PESO SMX
; The [S]ize of [M]emory
; is the [X] to solve
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

  use '.hed' peso::smX::i64
  use '.hed' peso::smX::sse

  use '.hed' peso::branch

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.smX

  VERSION   v0.00.9b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; map size to branch

EXESEG

proc.new smX.get_size,public

  proc.enter

  mov edx,r8d

  ; cap [size >= $10] to $10
  mov    eax,$0F
  not    eax
  and    eax,edx
  mov    eax,$10
  cmovnz edx,eax

  ; ^get [0-4] idex for size
  and edx,$1F
  bsr eax,edx


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; map address to step,align

proc.new smX.get_alignment,public

  proc.enter

  ; clamp chunk size to dline
  mov   ecx,r8d
  and   ecx,$70
  mov   eax,$80
  cmovz ecx,eax


  ; clear vars
  mov edx,$01
  mov r10b,sil
  mov al,dil

  ; get $01 if A unaligned
  and    eax,$0F
  cmovnz eax,edx

  ; ^get $02 if B unaligned
  and    r10d,$0F
  cmovnz r10d,edx

  ; ^combine
  or al,r10b


  ; branch accto step
  mov r10d,ecx
  shr r10d,$04
  bsr r10d,r10d

  ; ^adjust step
  push r10
  mov  ecx,r10d
  mov  r10d,$10
  shl  r10d,cl

  mov  ecx,r10d
  pop  r10


  ;cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
