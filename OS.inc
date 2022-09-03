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

if ~ defined loaded?Worg
  include '%ARPATH%/forge/Worg.inc'

end if

%Worg
  use '.inc' St

^Worg ARPATH '/forge/'

; ---   *   ---   *   ---
; info

  TITLE     OS

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; globs

  define SYS_WRITE  $01
  define SYS_BRK    $0C
  define SYS_EXIT   $3C

  define STDOUT     $01

; ---   *   ---   *   ---
; types

  %St

    dq top  ?
    dq sz   ?

  ^St Mem

; ---   *   ---   *   ---

macro exit exit_code=0 {

  leave

  mov rdi,exit_code
  mov rax,SYS_EXIT

  syscall

}

; ---   *   ---   *   ---

macro write f*,msg*,len* {

  mov rdi,f
  mov rsi,msg
  mov rdx,len

  mov rax,SYS_WRITE

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

macro Mem@$alloc TP {

  match self vt pt,Mem@self TP \{

    mov rax,qword [self\#.top]
    mov [pt],rax

    brk self,sizeof.\#vt

  \}

}

; ---   *   ---   *   ---
