; ---   *   ---   *   ---
; OS
; Get me out of here
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     OS

  VERSION   v0.00.5b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  SYS.exit.id=$3C

; ---   *   ---   *   ---
; terminate

macro exit code=0 {

  push code

  ; run 'atexit' queue
  MAM.atexit

  ; kill
  pop rdi
  mov rax,SYS.exit.id

  syscall

}

; ---   *   ---   *   ---
