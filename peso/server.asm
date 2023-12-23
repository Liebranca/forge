; ---   *   ---   *   ---
; PESO SERVER
; Also known as 'waiter'
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
  use '.hed' peso::netstruc

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.server

  VERSION   v0.00.4b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; big struc used to touch
; cstruc settings

reg.new server.config,public

  ; peertab elem
  my .peer.ezy    dw $00
  my .peer.cnt    dw $00

  my .peer.outqsz dw $00
  my .peer.inqsz  dw $00
  my .peer.outsz  dd $00
  my .peer.insz   dd $00

reg.end

; ---   *   ---   *   ---
; elem of peer tab

reg.new server.peer

  my .pos  dw $00
  my .pad  dw $00

  my .out  dd $00
  my .in   dd $00

  my .sock dq $00

reg.end

; ---   *   ---   *   ---
; base struc

reg.new server,public
reg.beq netstruc
reg.beq server.config

  my .peer.tab dq $00
  my .poller   dq $00

reg.end

; ---   *   ---   *   ---
; cstruc

EXESEG

proc.new server.new,public
proc.cpr rbx

proc.lis string sockpath rdi
proc.lis string mempath  rsi

proc.lis server.config config rdx
proc.stk qword self

  proc.enter

  ; save tmp
  push @mempath
  push @sockpath
  push @config

  ; make container
  lea  rdi,[@self]
  mov  rsi,sizeof.server
  call netstruc.alloc

  ; ^save config
  lea  rdi,[rbx+server.peer.ezy]
  pop  rsi
  mov  r8d,sizeof.server.config
  mov  r10w,smX.CDEREF

  call memcpy


  ; ^nit socket
  pop  rsi
  mov  rdi,qword [rbx+server.sock]

  call socket.unix.bind

  ; ^get mem
  pop  rdi

  xor  rsi,rsi
  mov  si,word [rbx+server.peer.ezy]
  imul si,word [rbx+server.peer.cnt]
  shl  esi,sizep2.page

  call shmem.new
  mov  qword [rbx+server.mem],rax


  ; make peer array
  mov  rdi,sizeof.server.peer
  xor  rsi,rsi
  mov  si,word [rbx+server.peer.cnt]

  call array.new
  mov  qword [rbx+server.peer.tab],rax


  ; make pollfd array
  mov  rdi,sizeof.pollfd
  xor  rsi,rsi
  mov  si,word [rbx+server.peer.cnt]
  inc  si

  call array.new
  mov  qword [rbx+server.poller],rax

  ; ^point first elem to self
  mov rax,qword [rax+array.head.buff]
  mov rdx,qword [rbx+server.sock]
  mov edx,dword [rdx+socket.fd]
  mov dword [rax+pollfd.fd],edx

  ; ^set events to poll
  mov word [rax+pollfd.ev],\
     SYS.poll.in \
  or SYS.poll.pri

  ; ^mark elem as pushed
  mov dword [rax+array.head.top],sizeof.pollfd


  ; reset out
  mov rax,rbx

  ; cleanup and leave
  proc.leave
  ret

; ---   *   ---   *   ---
; sets config struc defaults

proc.new server.config.defaults,public
proc.lis server.config config rdx

  proc.enter

  ; peer defaults
  mov word [@config.peer.ezy],$01
  mov word [@config.peer.cnt],$04

  mov word [@config.peer.outqsz],$08
  mov word [@config.peer.inqsz],$08

  mov dword [@config.peer.outsz],$0F
  mov dword [@config.peer.insz],$0F


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^config+cstruc sugar ;>

macro AR.server VN,opt& {

  netstruc.setconfig server,opt
  netstruc.icemaker server,VN,\
    cstring qword [env.state.ARPATH],\
    constr  env.path.MEM

}

; ---   *   ---   *   ---
; dstruc

proc.new server.del,public
proc.cpr rbx

proc.stk server.peer peer
proc.lis server self rbx

  proc.enter

  ; save tmp
  mov  @self,rdi


  ; remove+free mem
  mov  rdi,qword [@self.mem]
  push qword [rdi+shmem.path]

  call shmem.del

  ; ^free mempath
  pop  rdi
  call string.del


  ; remove socket
  mov  rdi,qword [@self.sock]
  push qword  [rdi+socket.path]
  push rdi

  call socket.unlink

  ; ^free socket
  pop  rdi
  call socket.del

  ; ^free sockpath
  pop  rdi
  call string.del


  ; free peer array
  @@:

  mov  rdi,qword [@self.peer.tab]
  mov  edx,dword [rdi+array.head.top]

  ; ^end on cap hit
  test edx,edx
  jz   @f


  ; get last elem
  lea  rsi,[@peer]
  call array.pop

  ; ^release elem
  mov  rdi,qword [@peer.sock]
  call socket.del
  jmp  @b

  @@:


  ; free pollfd array
  mov  rdi,qword [@self.poller]
  call array.del


  ; free container
  mov  rdi,@self
  call free

  proc.leave
  ret

; ---   *   ---   *   ---
; get peers are ready to talk

proc.new server.poll
proc.cpr rbx

proc.lis server self rbx
proc.stk server.peer peer

  proc.enter

  ; save tmp
  mov rbx,rdi


  ; poll the entire array
  mov    r11,qword [@self.poller]
  mov    rdx,$0A
  inline bin.poll

  ; ^event caught
  test rax,rax
  jz   .skip


  ; ^chk conx request
  mov  ax,word [r11+pollfd.rev]
  test ax,SYS.poll.in
  jz   @f

  ; ^get peer
  mov  rdi,qword [@self.sock]
  call socket.unix.accept

  ; ^fill out
  mov qword [@peer.sock],rax
;  mov 

  ; ^save to table
  mov  rdi,qword [@self.peer.tab]
  lea  rsi,[@peer]

  call array.push

  @@:


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
