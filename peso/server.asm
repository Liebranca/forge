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
; big struc used to touch
; cstruc settings

reg.new server.config,public

  ; peertab elem
  my .peer.ezy   dw $00
  my .peer.cnt   dw $00
  my .peer.outsz dd $00
  my .peer.qcap  dw $00

reg.end

; ---   *   ---   *   ---
; base struc

reg.new server,public
reg.beq netstruc

  my .peer dq $00

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
proc.stk qword config_sv

  proc.enter

  ; save tmp
  mov  qword [@config_sv],@config
  push @mempath
  push @sockpath

  ; make container
  lea  rdi,[@self]
  mov  rsi,sizeof.server
  call netstruc.alloc


  ; ^nit socket
  pop  rsi
  mov  rdi,rax

  call socket.unix.bind

  ; ^get mem
  pop  rdi
  mov  @config,qword [@config_sv]

  xor  rsi,rsi
  mov  si,word [@config.peer.ezy]
  imul si,word [@config.peer.cnt]
  shl  esi,sizep2.page

  call shmem.new
  mov  qword [rbx+server.mem],rax


  ; reset out
  mov rax,rbx

  ; cleanup and leave
  proc.leave
  ret

; ---   *   ---   *   ---
; sets config struc defaults

proc.new server.config.defaults,public
proc.lis server.config config rdi

  proc.enter

  ; peer defaults
  mov word [@config.peer.ezy],$01
  mov word [@config.peer.cnt],$04
  mov dword [@config.peer.outsz],$0F
  mov word [@config.peer.qcap],$08


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; dstruc

proc.new server.del,public
proc.lis server self rdi
proc.cpr rbx

  proc.enter

  ; save tmp
  push @self
  mov  rbx,@self


  ; remove+free mem
  mov  rdi,qword [rbx+server.mem]
  push qword [rdi+shmem.path]

  call shmem.del

  ; ^free mempath
  pop  rdi
  call string.del


  ; remove socket
  mov  rdi,qword [rbx+server.sock]
  push qword  [rdi+socket.path]
  push rdi

  call socket.unlink

  ; ^free socket
  pop  rdi
  call socket.del

  ; ^free sockpath
  pop  rdi
  call string.del


  ; free container
  pop  @self
  call free

  proc.leave
  ret

; ---   *   ---   *   ---
; ^sugar ;>

macro AR.server VN {

  netstruc.icemaker server,VN,\
    cstring qword [env.state.ARPATH],\
    constr  env.path.MEM

}

; ---   *   ---   *   ---
