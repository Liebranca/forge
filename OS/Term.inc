; ---   *   ---   *   ---
; TERM
; Locks you in raw mode
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

library ARPATH '/forge/'
  use '.inc' Peso::Reg

import

; ---   *   ---   *   ---
; info

  TITLE     OS.Term

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define SYS_IOCTL  $10

; ---   *   ---   *   ---
; struct copied verbatim from termios

reg
  dd c_iflag    ?
  dd c_oflag    ?
  dd c_cflag    ?
  dd c_lflag    ?

  db v_intr     ?
  db v_quit     ?
  db v_erase    ?
  db v_kill     ?

  db v_eof      ?
  db v_time     ?
  db v_min      ?
  db v_swtc     ?

  db v_start    ?
  db v_stop     ?
  db v_susp     ?
  db v_eol      ?

  db v_reprint  ?
  db v_discard  ?
  db v_werase   ?
  db v_lnext    ?
  db v_eol2     ?

end_reg Termios

; ---   *   ---   *   ---

macro get_term fd*,addr* {


  mov rdi,fd
  mov rsi,$5401 ;TCGETS
  mov rdx,addr

  mov rax,SYS_IOCTL

  syscall

}

macro set_term fd*,addr* {

  mov rdi,fd
  mov rsi,$5402 ;TCSETS
  mov rdx,addr

  mov rax,SYS_IOCTL

  syscall

}

; ---   *   ---   *   ---

macro raw_term fd*,addr* {

  ; OPOST
  oflags=not $01

  ; BRKINT | INPCK | ISTRIP | ICRNL | IXON
  iflags=not (\
    $0002 or $0020 or $0040 or $0400 or $2000\
  )

  ; ISIG | ICANON | ECHO | IEXTEN
  lflags=not($01 or $02 or $10 or $100000)

  ; CS8
  cflags=$60

  mov eax,dword [addr#.c_oflag]
  and eax,oflags
  mov dword [addr#.c_oflag],eax

  mov eax,dword [addr#.c_iflag]
  and eax,iflags
  mov dword [addr#.c_iflag],eax

  mov eax,dword [addr#.c_lflag]
  and eax,lflags
  mov dword [addr#.c_lflag],eax

  mov eax,dword [addr#.c_cflag]
  or  eax,cflags
  mov dword [addr#.c_cflag],eax

  set_term fd,addr

}

; ---   *   ---   *   ---

macro cpy_term dst*,src* {

  mov rax,qword [src#.c_iflag]
  mov qword [dst#.c_iflag],rax

  mov rax,qword [src#.c_cflag]
  mov qword [dst#.c_cflag],rax

  mov rax,qword [src#.v_intr]
  mov qword [dst#.v_intr],rax

  mov rax,qword [src#.v_start]
  mov qword [dst#.v_start],rax

  mov al,byte [src#.v_eol2]
  mov byte [dst#.v_eol2],al

}

; ---   *   ---   *   ---

macro kdmode fd*,status* {

  local mode

  ; K_XLATE
  match =0,status \{
    mode equ $01

  \}

  ; K_MEDIUMRAW
  match =1,status \{
    mode equ $02

  \}

  mov rdi,fd
  mov rsi,$4B45 ;KDSKBMODE
  mov rdx,mode

  mov rax,SYS_IOCTL

  syscall

}

; ---   *   ---   *   ---
