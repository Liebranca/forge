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

  VERSION   v0.00.2b
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
; also known as 'open' ;>

proc.new socket.unix.connect,public

proc.lis socket     self rdi
proc.lis array.head path rsi

  proc.enter

  ; save tmp
  push @self

  ; copy path
  lea  rdi,[@self.addr]
  mov  r8d,dword [@path.top]
  mov  rsi,qword [@path.buff]
  mov  r10w,smX.CDEREF

  call memcpy


  ; ^make conx
  pop @self
  lea rsi,[@self.addr]
  mov edx,dword [@self.addrsz]
  mov edi,dword [@self.fd]

  mov rax,SYS.connect.id
  syscall

  ; ^errchk
  test rax,rax
  jz   @f

  constr.throw FATAL,\
    "Failed to connect unix socket",$0A


  @@:


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; footer

constr ROM

; ---   *   ---   *   ---
