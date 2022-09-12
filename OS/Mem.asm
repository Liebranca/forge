; ---   *   ---   *   ---
; MEM
; Gimmie gimmie gimmie
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

  TITLE     OS.Mem

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define SYS_BRK    $0C

; ---   *   ---   *   ---
; incomplete

segment readable writeable

Gmem:
  .top dq ?
  .sz  dq ?

; ---   *   ---   *   ---

macro Mem@$brk n* {

  mov rdi,[Gmem.top]
  add rdi,n

  mov rax,SYS_BRK

  syscall

  mov [Gmem.top],rax
  add [Gmem.sz],n

}

; ---   *   ---   *   ---

macro Mem@$nit {
  Mem@$brk 0

}

macro Mem@$del {

  mov rax,[Gmem.top]
  sub rax,[Gmem.sz]

  Mem@$brk rax

}

; ---   *   ---   *   ---

macro Mem@$alloc TP,alt=0 {

  local status
  status equ 0

  match =0 vt pt,alt TP \{

    mov rax,qword [Gmem.top]
    mov [pt],rax

    Mem@$brk sizeof.\#vt

    status equ 1

  \}

  match =0 size dst,status TP alt \{

    mov rax,qword [Gmem.top]
    mov [dst],rax

    Mem@$brk size

  \}

}

; ---   *   ---   *   ---
