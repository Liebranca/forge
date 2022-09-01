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
    display 'oooh noeee!',$0A

  end if

  display 'heyhey',$0A

; ---   *   ---   *   ---
; globs
;
;  define SYS_WRITE $01
;  define SYS_BRK $0C
;  define SYS_EXIT $3C
;
;  define STDOUT $01
;
;; ---   *   ---   *   ---
;; types
;
;  %St
;
;    dq top ?
;    dq sz ?
;
;  ^St Mem
;
;; ---   *   ---   *   ---
;
;macro exit exit_code {
;
;  leave
;
;  mov rdi,exit_code
;  mov rax,SYS_EXIT
;
;  syscall
;
;}
;
;; ---   *   ---   *   ---
;
;macro write f*,msg*,len* {
;
;  mov rdi,f
;  mov rsi,msg
;  mov rdx,len
;
;  mov rax,SYS_WRITE
;
;  syscall
;
;}
;
;; ---   *   ---   *   ---
;
;macro brk m,n* {
;
;  mov rdi,[m.top]
;  add rdi,n
;
;  mov rax,SYS_BRK
;
;  syscall
;
;  mov [m.top],rax
;  add [m.sz],n
;
;}
;
;macro Mem.nit m {brk m,0}
;
;macro Mem.del m {
;
;  mov rax,[m.top]
;  sub rax,[m.sz]
;
;  brk m,rax
;
;}
;
;macro Mem.alloc m,TP {
;
;  match vt pt,TP \{
;
;    mov rax,qword [m.top]
;    mov qword [pt],rax
;
;    brk sizeof.#vt
;
;  \}
;
;}
;
;; ---   *   ---   *   ---
