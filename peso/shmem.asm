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

  use '.hed' OS::Clock
  use '.hed' peso::socket

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.shmem

  VERSION   v0.00.3b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; base struc

reg.new shmem,public
reg.beq bin
  my .buff   dq $00

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
  mov    rdi,qword [@self.buff]
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
  mov    rdi,qword [@self.buff]
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
  mov qword [@self.buff],rax

  ; ^reset out
  xchg rax,rdi


  ; cleanup and give
  proc.leave
  ret

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

  \}

}

; ---   *   ---   *   ---
; lock memory

proc.new shmem.lock,public

proc.lis shmem self rdi
proc.stk CLK   clk


  proc.enter

  ; get mem in use
  @@:

  mov  rax,qword [@self.buff]
  mov  ax,word [rax]
  test ax,ax

  jz   @f

  ; ^it is, wait around
  push @self
  mov  rdi,qword [@clk]
  mov  rsi,$0A
  xor  rdx,rdx

  call CLK.sleep
  pop  @self

  jmp  @b


  ; ^restrict until call to unlock
  @@:

  mov  rax,qword [@self.buff]
  lock inc word [rax]


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^iv

proc.new shmem.unlock,public
proc.lis shmem self rdi

macro shmem.unlock.inline {

  proc.enter

  mov  rax,qword [@self.buff]
  lock dec word [rax]


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline shmem.unlock
  ret

; ---   *   ---   *   ---
