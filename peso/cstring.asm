; ---   *   ---   *   ---
; C STRINGS
; Go charstar!
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
  use '.hed' peso::io

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.cstring

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

ROMSEG cstring.CON,public

  .MASK_Z0 dq $7F7F7F7F7F7F7F7F
  .MASK_Z1 dq $0101010101010101
  .MASK_Z2 dq $8080808080808080

; ---   *   ---   *   ---
; gives 0 or 1+nullidex

proc.new cstring.ziw,public
macro cstring.ziw.inline {

  proc.enter
  xor rcx,rcx

  ; convert 00 to 80 && 01-7E to 00 ;>
  xor rsi,qword [cstring.CON.MASK_Z0]
  add rsi,qword [cstring.CON.MASK_Z1]
  and rsi,qword [cstring.CON.MASK_Z2]

  je  .ziw_skip

  ; get first null byte (80)+1
  bsf rcx,rsi
  shr rcx,$03
  inc rcx


  ; cleanup
  .ziw_skip:
  proc.leave

}

  ; ^invoke and give
  inline cstring.ziw
  ret

; ---   *   ---   *   ---
; length of cstr if chars
; are in 00-7E range, else bogus

proc.new cstring.length,public
proc.cpr rdi,rsi

  proc.enter
  xor rax,rax

  .top:

    ; get null in qword
    mov    rsi,qword [rdi]
    inline cstring.ziw

    ; ^end reached
    test  rcx,rcx
    jnz   .bot

    ; ^else increase
    add   rax,8
    add   rdi,8
    jmp   .top

  ; sum final length
  .bot:
    dec   rcx
    sub   rdi,rax
    add   rax,rcx


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; walk cstr buff

proc.new cstring.skip,public

  proc.enter

  ; get N strings skipped
  .top:
    test rsi,rsi
    jz   .skip

  ; ^walk next string
  call cstring.length

  dec  rsi
  lea  rdi,[rdi+rax+1]
  jmp  .top


  ; cleanup and give
  .skip:
    mov rax,rdi

  proc.leave
  ret

; ---   *   ---   *   ---
; shorthand

proc.new cstring.sow
macro cstring.sow.inline {

  proc.enter

  call cstring.length
  mov  rsi,rax

  call sow


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline cstring.sow
  ret

; ---   *   ---   *   ---
