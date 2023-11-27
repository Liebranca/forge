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

library ARPATH '/forge/'
  use '.hed' peso::alloc

library.import

; ---   *   ---   *   ---
; info

  TITLE     OS.Term

  VERSION   v0.00.3b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

SYS.ioctl:

  .id      = $10

  .tcgets  = $5401
  .tcsets  = $5402
  .tcsetsf = $5404

  ;KDSKBMODE
  .kbmode  = $4B45
  .kbxlate = $01

  ; actually medium raw
  ; but we never use the other ;>
  .kbraw   = $02

; ---   *   ---   *   ---
; struct copied verbatim from termios

reg.new Termios,public

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
  ioctl buff,fd,SYS.ioctl.tcsetsf

}

; ---   *   ---   *   ---
; the titular move

proc.new Termios.raw,public
proc.lis Termios self rdi

  ; OPOST
  .oflags=not $01

  ; BRKINT | INPCK | ISTRIP | ICRNL | IXON
  .iflags=not (\
    $0002 or $0020 or $0040 or $0400 or $2000\
  )

  ; ISIG | ICANON | ECHO | IEXTEN
  .lflags=not($01 or $02 or $10 or $100000)

  ; CS8
  .cflags=$60


  proc.enter

  ; get original
  push @self
  push rsi

  Termios.get @self,rsi


  ; ^mod flags
  pop rsi
  pop @self

  and dword [@self.c_oflag],.oflags
  and dword [@self.c_iflag],.iflags
  and dword [@self.c_lflag],.lflags
  or  dword [@self.c_cflag],.cflags

  ; ^reset
  push rsi
  Termios.set @self,rsi

  ; ^eff keyboard
  pop   rsi
  ioctl SYS.ioctl.kbraw,rsi,SYS.ioctl.kbmode


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^undo

proc.new Termios.cook,public
proc.lis Termios self rdi

  ; OPOST
  .oflags=$01

  ; BRKINT | INPCK | ISTRIP | ICRNL | IXON
  .iflags=(\
    $0002 or $0020 or $0040 or $0400 or $2000\
  )

  ; ISIG | ICANON | ECHO | IEXTEN
  .lflags=($01 or $02 or $10 or $100000)

  ; CS8
  .cflags=not $60


  proc.enter


  ; restore flags
  or  dword [@self.c_oflag],.oflags
  or  dword [@self.c_iflag],.iflags
  or  dword [@self.c_lflag],.lflags
  and dword [@self.c_cflag],.cflags

  ; ^reset
  push rsi
  Termios.set @self,rsi

  ; ^uneff keyboard
  pop   rsi
  ioctl SYS.ioctl.kbxlate,rsi,SYS.ioctl.kbmode


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; set A to B

proc.new Termios.cpy
proc.lis Termios self  rdi
proc.lis Termios other rsi

macro Termios.cpy.inline {

  proc.enter

  mov  r8d,sizeof.Termios
  mov  r10w,smX.CDEREF

  call memcpy


  ; cleanup
  proc.leave

}


  ; ^invoke and give
  inline Termios.cpy
  ret

; ---   *   ---   *   ---
