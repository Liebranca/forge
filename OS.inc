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

  VERSION   v0.00.3b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define SYS_WRITE  $01
  define SYS_EXIT   $3C

  define STDIN      $00
  define STDOUT     $01
  define STDERR     $02

; ---   *   ---   *   ---
; terminate

macro exit code=0 {

  ; run 'atexit' queue
  call alloc.del

  ; kill
  mov rdi,code
  mov rax,SYS_EXIT

  syscall

}

; ---   *   ---   *   ---
; push bytes

macro write f*,msg*,len* {

  mov rdi,f
  lea rsi,[msg]
  mov rdx,len

  mov rax,SYS_WRITE

  syscall

}

; ---   *   ---   *   ---
