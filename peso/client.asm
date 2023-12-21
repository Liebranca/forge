; ---   *   ---   *   ---
; PESO CLIENT
; Gets served
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
; struc alias

reg.new client,public
reg.beq netstruc

reg.end

define client.alloc netstruc.alloc

; ---   *   ---   *   ---
; cstruc

EXESEG

proc.new client.new
proc.cpr rbx

proc.lis string sockpath rdi
proc.lis string mempath  rsi

proc.stk qword  self

  proc.enter

  ; save tmp
  push @mempath
  push @sockpath

  ; make container
  lea  rdi,[@self]
  mov  rsi,sizeof.client

  call client.alloc


  ; ^connect to socket
  pop  rdi
  call socket.unix.connect

  ; ^get mem
  pop  rdi

  call shmem.open
  mov  qword [rbx+client.mem],rax


  ; cleanup and leave
  proc.leave
  ret

; ---   *   ---   *   ---
; ^dstruc

proc.new client.del,public
proc.lis client self rdi
proc.cpr rbx

  proc.enter

  ; save tmp
  push @self
  mov  rbx,@self


  ; free mem
  mov  rdi,qword [rbx+client.mem]
  push qword [rdi+shmem.path]

  call shmem.close

  ; ^free mempath
  pop  rdi
  call string.del


  ; free socket
  mov  rdi,qword [rbx+client.sock]
  push qword  [rdi+socket.path]

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

macro AR.client VN,size {

  netstruc.icemaker client,VN,size,\
    cstring qword [env.state.ARPATH],\
    constr  env.path.MEM

}

; ---   *   ---   *   ---
