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
; deps

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

; ---   *   ---   *   ---
; info

  TITLE     OS

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; globs

  define SYS_WRITE  $01
  define SYS_EXIT   $3C

  define STDIN      $00
  define STDOUT     $01

; ---   *   ---   *   ---

macro exit exit_code=0 {

  mov rdi,exit_code
  mov rax,SYS_EXIT

  syscall

}

; ---   *   ---   *   ---

macro write f*,msg*,len* {

  mov rdi,f
  lea rsi,[msg]
  mov rdx,len

  mov rax,SYS_WRITE

  syscall

}

; ---   *   ---   *   ---
