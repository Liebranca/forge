; ---   *   ---   *   ---
; PESO BIN
; To the trashcan!
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
  use '.hed' peso::io
  use '.hed' peso::string

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.bin

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

SYS.open:

  .id     = $02

  ; r/w flags
  .read   = $0000
  .write  = $0001
  .flow   = $0002

  ; mode flags
  .new    = $0040
  .trunc  = $0200
  .append = $0400

  ; ioctl ptsd
  .nblock = $0800

  ; disable r/w protections
  .new.mode = $180


  ; nothing further
  SYS.close.id=$03

; ---   *   ---   *   ---
; base struc

reg.new bin,public

  my .fd    dd $00
  my .flags dd $00

  my .state dd $00

  my .path  dq $00
  my .sig   dq $00

  my .ptr   dq $00

reg.end

; ---   *   ---   *   ---
; ^status flags

  bin.opened=$01

; ---   *   ---   *   ---
; cstruc

proc.new bin.new,public

  proc.enter

  ; save tmp
  push rdi

  ; ensure nullterm (cstrs be damned ;>)
  xor  rsi,rsi
  call array.push

  ; ^now get mem
  mov  rdi,sizeof.bin
  call alloc


  ; restore tmp
  pop rdi

  ; clear yet unknown values
  and qword [rax+bin.ptr],$00
  and qword [rax+bin.sig],$00

  ; ^fill out struc
  mov qword [rax+bin.path],rdi


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^sugar

macro bin.from dst,path {

  ; make dynamic from const
  string.from path

  ; ^make container
  mov  rdi,rax
  call bin.new

  ; ^save
  mov dst,rax

}

; ---   *   ---   *   ---
; throws on fail

proc.new bin.open_or_die,public
proc.lis bin self rdi

  proc.enter

  ; get/make file
  push @self

  mov  rdi,qword [@self.path]
  mov  rdi,qword [rdi+array.head.buff]
  mov  rax,SYS.open.id

  syscall


  ; ^errchk
  cmp rax,$00
  jge .fdok

  constr.throw MESS,"Cannot open file <"
  call string.sow

  constr.throw FATAL,">",$0A


  ; nothing broke ;>
  .fdok:

    ; ^copy fd
    pop @self
    mov dword [@self.fd],eax
    or  dword [@self.state],bin.opened


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^make/clear

proc.new bin.open_new,public
proc.lis bin self rdi

macro bin.open_new.inline {

  proc.enter

  ; set flags and make syscall+errchk
  or  esi,SYS.open.new or SYS.open.trunc
  mov rdx,SYS.open.new.mode
  mov dword [@self.flags],esi

  call bin.open_or_die


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline bin.open_new
  ret

; ---   *   ---   *   ---
; ^load

proc.new bin.open,public
proc.lis bin self rdi

macro bin.open.inline {

  proc.enter

  ; set flags and make syscall+errchk
  or   esi,edx
  mov  dword [@self.flags],esi

  call bin.open_or_die


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline bin.open
  ret

; ---   *   ---   *   ---
; ^selfex

proc.new bin.close,public
proc.lis bin self rdi

  proc.enter

  ; skip on file already closed
  mov  eax,dword [@self.state]
  mov  ecx,bin.opened

  test eax,ecx
  jz   @f


  ; update state flags
  not ecx
  and dword [@self.state],ecx

  ; ^close fd
  mov edi,dword [@self.fd]
  mov rax,SYS.close.id

  syscall


  ; ^cleanup and give
  @@:

  proc.leave
  ret

; ---   *   ---   *   ---
; dstruc

proc.new bin.del,public

proc.lis bin   self rdi

proc.stk qword head
proc.stk qword path

  proc.enter

  ; save tmp
  mov  rax,qword [@self.path]
  mov  qword [@head],rdi
  mov  qword [@path],rax

  ; close if opened
  call bin.close


  ; ^release string
  mov  rdi,qword [@path]
  call string.del

  ; ^release mem
  mov  rdi,qword [@head]
  call free


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; set file as write dst

proc.new bin.fto
proc.lis bin self rdi

macro bin.fto.inline {

  proc.enter

  mov  edi,[@self.fd]
  call fto

  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline bin.fto
  ret

; ---   *   ---   *   ---
; footer

constr ROM

; ---   *   ---   *   --
