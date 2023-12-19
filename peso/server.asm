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
; base struc

reg.new server,public
reg.beq netstruc

reg.end

; ---   *   ---   *   ---
; cstruc

EXESEG

proc.new server.new,public
proc.cpr rbx

proc.lis string sockpath rdi
proc.lis string mempath  rsi
proc.lis qword  memsz    rdx

proc.stk qword  self

  proc.enter

  ; save tmp
  push @memsz
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
  pop  rsi

  call shmem.new
  mov  qword [rbx+server.mem],rax


  ; cleanup and leave
  proc.leave
  ret

; ---   *   ---   *   ---
; ^dstruc

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

macro AR.server VN,size {

  netstruc.icemaker server,VN,size,\
    cstring qword [env.state.ARPATH],\
    constr  env.path.MEM

}

; ---   *   ---   *   ---
