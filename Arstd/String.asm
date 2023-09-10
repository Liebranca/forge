; ---   *   ---   *   ---
; ARSTD STR
; They're terrible
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
  use '.inc' Peso::Proc
  use '.asm' OS::Mem

import

; ---   *   ---   *   ---
; info

  TITLE     Arstd.String

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

  CLAN      String

; ---   *   ---   *   ---
; ROM

segment readable

  .MASK_Z0 dq $7F7F7F7F7F7F7F7F
  .MASK_Z1 dq $0101010101010101
  .MASK_Z2 dq $8080808080808080

; ---   *   ---   *   ---

segment readable executable

proc alloc

  push  rbx

  mov   rbx,rdi
  mov   rdx,rsi

  wed   Mem

  xmac  nit
  xmac  alloc,rbx,rdx

  pop   rbx

end_proc ret

; ---   *   ---   *   ---
; gives 0 or 1+nullidex

proc ziw

  xor rcx,rcx

  ; 00 to 80 && 01-7E to 00 ;>
  xor rsi,[String.MASK_Z0]
  add rsi,[String.MASK_Z1]
  and rsi,[String.MASK_Z2]

  ; skip if no nullterm
  je  .skip
  inc rcx

; ---   *   ---   *   ---
; find non-zero byte

.top:
  cmp sil,$80
  je .skip

  shr rsi,$08
  inc rcx

  jmp .top

; ---   *   ---   *   ---

.skip:

end_proc ret

; ---   *   ---   *   ---
; length of string if chars are in 00-7E range
; else bogus

proc length

  xor   rax,rax

; ---   *   ---   *   ---
; walk the string in 8-byte steps

.top:
  mov   rsi,[rdi]
  call  String.ziw

  ; non-zero means terminator found
  or    rcx,0
  jnz   .bot

  ; else count up and repeat
  add   rax,8
  add   rdi,8
  jmp   .top

; ---   *   ---   *   ---
; reposition strptr
; final length in rax

.bot:
  dec   rcx
  sub   rdi,rax
  add   rax,rcx

end_proc ret

; ---   *   ---   *   ---
END_CLAN
