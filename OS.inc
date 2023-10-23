; ---   *   ---   *   ---
; OS
; bunch o syscalls ;>
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

  VERSION   v0.00.4b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  SYS.write.id = $01
  SYS.exit.id  = $3C

  stdin  = $00
  stdout = $01
  stderr = $02

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
; push bytes

macro write f*,msg*,len* {

  mov rdi,f
  lea rsi,[msg]
  mov rdx,len

  mov rax,SYS.write.id

  syscall

}

; ---   *   ---   *   ---
