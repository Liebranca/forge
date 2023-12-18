; ---   *   ---   *   ---
; PESO SHMEM
; Sharing is fun!
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
  use '.hed' peso::socket
  use '.hed' peso::lock

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.shmem

  VERSION   v0.00.4b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; base struc

reg.new shmem,public
reg.beq bin
  my .buff dq $00
  my .lock dq $00

reg.end

; ---   *   ---   *   ---
; server-side cstruc

EXESEG

proc.new shmem.new,public

proc.lis string path rdi
proc.stk qword  size

  proc.enter

  ; save tmp
  push @path

  ; align size to page
  mov rdi,rsi
  page.align

  mov qword [@size],rax


  ; make container
  mov  rdi,sizeof.shmem
  call alloc

  ; make diskback
  pop  rsi
  mov  rdi,rax
  mov  rdx,qword [@size]

  call shmem.open_new


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; server-side open

proc.new shmem.open_new

proc.lis shmem  self rdi
proc.lis string path rsi

  proc.enter

  ; save tmp
  push @self
  push rdx


  ; make diskback
  mov    rdx,SYS.open.flow
  inline bin.open_new

  ; ^fit to size
  pop    rsi
  pop    @self

  inline bin.trunc


  ; ^map to mem
  call shmem.map

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^server-side dstruc

proc.new shmem.del,public

proc.lis shmem self rdi
proc.stk qword self_sv

  proc.enter

  ; save tmp
  mov qword [@self_sv],@self

  ; free mem
  mov    esi,dword [@self.fsz]
  mov    rdi,qword [@self.lock]
  shr    esi,sizep2.page

  inline page.free


  ; ^free container
  mov    @self,qword [@self_sv]
  inline bin.unlink

  mov    @self,qword [@self_sv]
  call   free


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; client-side cstruc

proc.new shmem.open,public
proc.lis string path rdi

  proc.enter

  ; save tmp
  push @path


  ; make container
  mov  rdi,sizeof.shmem
  call alloc

  ; make diskback
  pop  rsi
  mov  rdi,rax
  mov  rdx,SYS.open.flow
  xor  r8,r8

  inline bin.open


  ; ^map to mem
  call shmem.map

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; client-side dstruc

proc.new shmem.close,public
proc.lis shmem self rdi

  proc.enter

  ; save tmp
  push @self

  ; free mem
  mov    esi,dword [@self.fsz]
  mov    rdi,qword [@self.lock]
  shr    esi,sizep2.page

  inline page.free


  ; ^free container
  pop  @self
  call free


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; universal map diskback to mem

proc.new shmem.map
proc.lis shmem self rdi

  proc.enter

  ; save tmp
  push @self


  ; get mem
  mov esi,dword [@self.fsz]
  mov r8d,dword [@self.fd]

  mov rdx,SYS.mmap.proto_rw
  mov r10,SYS.mmap.shared
  mov rax,SYS.mmap.id

  xor rdi,rdi
  xor r9,r9

  syscall


  ; ^save to ice
  pop @self
  mov qword [@self.lock],rax

  add rax,sizeof.dword
  mov qword [@self.buff],rax

  ; ^reset out
  xchg rax,rdi


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; universal sugar

macro shmem._gen_methods name {

  ; locking shorthand
  macro name#.lock \{
    mov  rdi,qword [name]
    mov  rdi,qword [rdi+shmem.lock]

    call peso.lock

  \}

  ; ^undo
  macro name#.unlock \{
    mov  rdi,qword [name]
    mov  rdi,qword [rdi+shmem.lock]

    call peso.unlock

  \}

}

; ---   *   ---   *   ---
; server-side cstruc sugar

macro server.shmem SVN,fpath& {

  local dst

  match size VN , SVN \{

    ; promise symbols to RAM
    bin._from2 dst,VN,fpath

    match name , dst \\{

      ; ^make ice and back
      mov  rdi,qword [name\\#.path]
      mov  rsi,size

      call shmem.new
      mov  qword [dst],rax

      ; ^prepare undo
      macro name\\#.free \\\{
        mov  rdi,qword [name]
        call shmem.del

        mov  rdi,qword [name\\#.path]
        call string.del

      \\\}

      shmem._gen_methods name

    \\}

  \}

}

; ---   *   ---   *   ---
; ^client-side

macro client.shmem VN,fpath& {

  local dst

  ; promise symbols to RAM
  bin._from2 dst,VN,fpath

  match name , dst \{

    ; ^make ice and back
    mov  rdi,qword [name\#.path]

    call shmem.open
    mov  qword [dst],rax

    ; ^prepare undo
    macro name\#.free \\{
      mov  rdi,qword [name]
      call shmem.close

      mov  rdi,qword [name\#.path]
      call string.del

    \\}

    shmem._gen_methods name

  \}

}

; ---   *   ---   *   ---
