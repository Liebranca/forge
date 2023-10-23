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
  use '.inc' peso::reg
  use '.inc' peso::alloc

library.import

; ---   *   ---   *   ---
; info

  TITLE     OS.Term

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

SYS.ioctl:

  .id     = $10

  .tcgets = $5401
  .tcsets = $5402

; ---   *   ---   *   ---
; struct copied verbatim from termios

reg.new Termios

  my .c_iflag   dd $00
  my .c_oflag   dd $00
  my .c_cflag   dd $00
  my .c_lflag   dd $00

  my .v_intr    db $00
  my .v_quit    db $00
  my .v_erase   db $00
  my .v_kill    db $00

  my .v_eof     db $00
  my .v_time    db $00
  my .v_min     db $00
  my .v_swtc    db $00

  my .v_start   db $00
  my .v_stop    db $00
  my .v_susp    db $00
  my .v_eol     db $00

  my .v_reprint db $00
  my .v_discard db $00
  my .v_werase  db $00
  my .v_lnext   db $00
  my .v_eol2    db $00

reg.end

; ---   *   ---   *   ---
; syscall proto

macro ioctl buff,fd,mode {

  mov rdx,buff
  mov rdi,fd
  mov rsi,mode

  mov rax,SYS.ioctl.id
  syscall

}

; ---   *   ---   *   ---
; ^ice-of

macro Termios.get buff,fd {
  ioctl buff,fd,SYS.ioctl.tcgets

}

macro Termios.set buff,fd {
  ioctl buff,fd,SYS.ioctl.tcsets

}

; ---   *   ---   *   ---
; the titular move

proc.new Termios.raw
proc.lis Termios self rdi

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


  proc.enter

  ; mod flags
  and dword [@self.c_oflag],oflags
  and dword [@self.c_iflag],iflags
  and dword [@self.c_lflag],lflags
  or  dword [@self.c_cflag],cflags

  ; ^syscall
  Termios.set fd,@buff


  ; cleanup and give
  proc.leave
  ret

}

; ---   *   ---   *   ---
; set A to B

proc.new Termios.cpy
proc.lis Termios self  rdi
proc.lis Termios other rsi

  proc.enter


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


  ; cleanup and give
  proc.leave
  ret

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
