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

define socket.close  bin.close
define socket.del    bin.del
define socket.unlink bin.unlink

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
  pop  @self
  lea  rsi,[@self.addr]
  mov  edx,dword [@self.addrsz]
  mov  edi,dword [@self.fd]

  pop  rax

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
proc.lis socket     self rdi
proc.lis array.head path rsi

macro socket.unix.connect.inline {

  proc.enter

  ; mark bin open...
  ; if it fails, we die!
  mov qword [@self.path],@path
  or  dword [@self.state],bin.opened

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

proc.lis socket     self rdi
proc.lis array.head path rsi

proc.stk qword self_sv

  proc.enter

  ; save tmp
  mov  qword [@self_sv],@self
  push rsi


  ; safety rm
  mov  qword [@self.path],@path
  call socket.unlink

  ; ^then mark bin open ;>
  or dword [@self.state],bin.opened


  ; ^open fd
  mov  @self,qword [@self_sv]
  pop  rsi
  mov  rax,SYS.bind.id

  call socket.unix.open


  ; ^mark as passive
  mov @self,qword [@self_sv]
  mov rsi,$01
  mov edi,dword [@self.fd]
  mov rax,SYS.listen.id

  syscall


  ; cleanup
  proc.leave
  ret

; ---   *   ---   *   ---
; r/w aliases

define socket.write  bin.write
define socket.read   bin.read
define socket.dread  bin.dread
define socket.dwrite bin.dwrite

; ---   *   ---   *   ---
; put server on hold

proc.new socket.unix.accept,public

proc.lis socket self rdi
proc.stk qword  peer

  proc.enter

  ; save tmp
  push @self

  ; nit mem for peer
  call socket.unix.new
  mov  qword [@peer],rax


  ; block til input
  pop @self
  mov edi,dword [@self.fd]
  xor rsi,rsi
  xor rdx,rdx

  mov rax,SYS.accept.id

  syscall

  ; ^errchk
  cmp rax,$00
  jg  @f

  constr.throw FATAL,\
    "Failed to open peer socket",$0A


  @@:


  ; cleanup and give
  mov rdi,qword [@peer]
  mov dword [rdi+socket.fd],eax
  mov rax,rdi

  proc.leave
  ret

; ---   *   ---   *   ---
