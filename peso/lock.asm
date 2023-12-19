; ---   *   ---   *   ---
; PESO LOCK
; Don't pick it
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

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.lock

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

SYS.futex:

  .id   = $CA

  ; ops
  .wait = $00
  .wake = $01

; ---   *   ---   *   ---
; take on free
; wait on unav

EXESEG

proc.new peso.lock,public
proc.lis qword self rdi

  proc.enter

  ; get avail
  @@:

  mov  edx,$01
  xor  eax,eax

  lock cmpxchg dword [@self],edx
  jz   @f


  ; ^unav, wait around
  mov rsi,SYS.futex.wait
  mov rax,SYS.futex.id

  xor r10,r10
  xor r8,r8
  xor r9,r9

  syscall
  jmp @b


  ; cleanup and give
  @@:

  proc.leave
  ret

; ---   *   ---   *   ---
; ^release

proc.new peso.unlock,public
proc.lis qword self rdi

  proc.enter

  ; get unav
  xor  edx,edx
  mov  eax,$01

  lock cmpxchg dword [@self],edx
  jnz  @f

  ; ^it is, wake up peer
  mov rsi,SYS.futex.wake
  mov rax,SYS.futex.id

  xor r10,r10
  xor r8,r8
  xor r9,r9

  syscall


  ; cleanup and give
  @@:

  proc.leave
  ret

; ---   *   ---   *   ---

