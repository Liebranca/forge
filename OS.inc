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

imp
  use '.inc' Peso::Reg

end_imp ARPATH '/forge/'

; ---   *   ---   *   ---
; info

  TITLE     OS

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; globs

  define SYS_WRITE  $01
  define SYS_BRK    $0C
  define SYS_SLEEP  $23
  define SYS_EXIT   $3C
  define SYS_TIME   $E4

  define STDOUT     $01

; ---   *   ---   *   ---
; types

reg

  dq top  ?
  dq sz   ?

end_reg Mem

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
; *in nanoseconds

macro get_time dst* {

  mov qword [dst],0
  mov qword [dst+8],0

  ; CLOCK_THREAD_CPUTIME_ID
  mov rdi,$03
  lea rsi,[dst]
  mov rax,SYS_TIME

  syscall

  mov rax,[dst]
  mov rbx,1000000000
  mul rbx
  add rax,[dst+8]

}

; ---   *   ---   *   ---

macro usleep src*,delta* {

  lea rdi,[clk]
  mov qword [rdi],$00
  mov qword [rdi+8],delta
  xor rsi,rsi

  mov rax,SYS_SLEEP
  syscall

}

; ---   *   ---   *   ---

macro brk m,n* {

  mov rdi,[m#.top]
  add rdi,n

  mov rax,SYS_BRK

  syscall

  mov [m#.top],rax
  add [m#.sz],n

}

macro Mem@$nit {

  match self,Mem@self \{
    brk self,0

  \}

}

macro Mem@$del {

  match self,Mem@self \{
    mov rax,[self\#.top]
    sub rax,[self\#.sz]

    brk self,rax

  \}

}

macro Mem@$alloc TP,alt=0 {

  local status
  status equ 0

  match =0 self vt pt,alt Mem@self TP \{

    mov rax,qword [self\#.top]
    mov [pt],rax

    brk self,sizeof.\#vt

    status equ 1

  \}

  match =0 self size dst,\
    status Mem@self TP alt \{

    mov rax,qword [self\#.top]
    mov [dst],rax

    brk self,size

  \}

}

; ---   *   ---   *   ---
