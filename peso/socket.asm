; ---   *   ---   *   ---
; SOCKET
; Talks to the clouds
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
  use '.hed' peso::bin

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.socket

  VERSION   v0.00.3b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

SYS.socket:

  .id      = $29

  ; domain
  .unix    = $01
  .inet    = $02
  .inet6   = $0A

  ; type
  .stream  = $01
  .dgram   = $02
  .raw     = $03

  ; O, POSIX!
  .addrsz  = $77
  .sunsz   = $6E
  .sinsz   = $10
  .sin6sz  = $1C


  ; further calls
  SYS.connect.id = $2A
  SYS.accept.id  = $2B
  SYS.bind.id    = $31
  SYS.listen.id  = $32

; ---   *   ---   *   ---
; base struc

reg.new socket,public
reg.beq bin
  my .addrsz dd $00
  my .addr   db SYS.socket.addrsz dup $00

reg.end

; ---   *   ---   *   ---
; ^cstruc

EXESEG

proc.new socket.unix.new,public
proc.lis socket self rax

  proc.enter

  ; get mem
  mov  rdi,sizeof.socket
  call alloc

  ; fill out struc
  mov dword [@self.addrsz],SYS.socket.sunsz
  mov word [@self.addr],SYS.socket.unix

  ; ^save tmp
  push @self


  ; get fd
  mov rdi,SYS.socket.unix
  mov rsi,SYS.socket.stream
  xor rdx,rdx

  mov rax,SYS.socket.id
  syscall

  ; ^errchk
  cmp rax,$00
  jge @f

  ; ^errme
  constr.throw FATAL,\
    "Failed to create new socket",$0A


  @@:


  ; ^fd is valid, save to struc
  mov ecx,eax
  pop @self

  mov dword [@self.fd],ecx

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^dstruc lis

socket.close = bin.close
socket.del   = bin.del

; ---   *   ---   *   ---
; set sockpath and connect/bind

proc.new socket.unix.open,public

proc.lis socket     self rdi
proc.lis array.head path rsi

  proc.enter

  ; save tmp
  push rax
  push @self

  ; copy path
  lea  rdi,[@self.addr+$02]
  mov  r8d,dword [@path.top]
  mov  rsi,qword [@path.buff]
  mov  r10w,smX.CDEREF

  call memcpy


  ; ^make conx
  pop @self
  lea rsi,[@self.addr]
  mov edx,dword [@self.addrsz]
  mov edi,dword [@self.fd]

  pop rax
  syscall

  ; ^errchk
  test rax,rax
  jz   @f

  constr.throw FATAL,\
    "Failed to open unix socket",$0A


  @@:

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^client

proc.new socket.unix.connect,public
macro socket.unix.connect.inline {

  proc.enter

  ; make syscalls
  mov  rax,SYS.connect.id
  call socket.unix.open

  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline socket.unix.connect
  ret

; ---   *   ---   *   ---
; ^server-side

proc.new socket.unix.bind,public
macro socket.unix.bind.inline {

  proc.enter

  ; make syscalls
  mov  rax,SYS.bind.id
  call socket.unix.open

  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline socket.unix.bind
  ret

; ---   *   ---   *   ---
; r/w aliases

socket.write  = bin.write
socket.read   = bin.read
socket.dread  = bin.dread
socket.dwrite = bin.dwrite

; ---   *   ---   *   ---
