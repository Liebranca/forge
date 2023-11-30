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

  VERSION   v0.00.3b
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
; ^further calls

SYS.lseek:

  .id  = $08

  ; mode
  .set = $00
  .cur = $01
  .end = $02

; ---   *   ---   *   ---
; base struc

reg.new bin,public

  my .fd    dd $00
  my .flags dd $00

  my .state dd $00

  my .hsz   dd $00
  my .fsz   dd $00
  my .ptr   dd $00

  my .path  dq $00
  my .sig   dq $00

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
  and dword [rax+bin.state],$00
  and dword [rax+bin.ptr],$00
  and dword [rax+bin.hsz],$00
  and dword [rax+bin.fsz],$00
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

    ; calc filesize, no stat
    call bin._get_fsz


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
; adjust ptr, guts v

proc.new bin._seek
proc.lis bin self rdi

macro bin._seek.inline {

  proc.enter

  ; save tmp
  push @self

  ; move ptr
  mov edi,[@self.fd]
  mov rax,SYS.lseek.id

  syscall

  ; ^save value
  pop @self
  mov dword [@self.ptr],eax


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline bin._seek
  ret

; ---   *   ---   *   ---
; ^iface iceof
; seek from cur

proc.new bin.seek
proc.lis bin self rdi

macro bin.seek.inline {

  proc.enter

  ; offset eq cur+esi
  mov    rdx,SYS.lseek.cur
  dpline bin._seek


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline bin.seek
  ret

; ---   *   ---   *   ---
; ^seek to beg

proc.new bin.rewind,public
proc.lis bin self rdi

macro bin.rewind.inline {

  proc.enter

  ; offset eq 0+esi+(header size)
  add    esi,dword [@self.hsz]
  mov    rdx,SYS.lseek.set

  dpline bin._seek


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline bin.rewind
  ret

; ---   *   ---   *   ---
; ^seek to end

proc.new bin.fastfwd,public
proc.lis bin self rdi

macro bin.fastfwd.inline {

  proc.enter

  ; offset eq end-esi
  neg    rsi
  mov    rdx,SYS.lseek.end

  dpline bin._seek


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline bin.fastfwd
  ret

; ---   *   ---   *   ---
; ^get size of file, guts v

proc.new bin._get_fsz
proc.lis bin self rdi

  proc.enter

  xor    rsi,rsi
  inline bin.fastfwd

  mov    dword [@self.fsz],eax
  inline bin.rewind


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^iface

proc.new bin.get_fsz,public
proc.lis bin self rdi

macro bin.get_fsz.inline {

  proc.enter
  mov eax,dword [@self.fsz]


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline bin.get_fsz
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
; update meta after write

macro bin.write_epilogue {

  ; get [step,bin]
  pop rdx
  pop @self

  ; save tmp
  push rax

  ; update ptr
  add dword [@self.ptr],edx

  ; ^get [ptr,fsz]
  mov ecx,dword [@self.ptr]
  mov eax,dword [@self.fsz]


  ; get ptr > fsz
  sub   ecx,eax
  xor   eax,eax
  cmp   ecx,$00
  cmovl edx,eax

  ; ^update fsz by diff
  add dword [@self.fsz],edx
  pop rax

}

; ---   *   ---   *   ---
; buffered write

proc.new bin.sow,public

proc.lis bin        self rdi
proc.lis array.head src  rsi

  proc.enter

  ; save tmp
  push @self
  push qword [@src.top]

  ; set file as out
  call bin.fto

  ; ^write to buffio
  mov    rdi,@src
  inline string.sow


  ; update meta
  bin.write_epilogue

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^unbuffered write

proc.new bin.write,public

proc.lis bin        self rdi
proc.lis array.head src  rsi

  proc.enter

  ; save tmp
  push @self

  ; direct syscall
  mov  edi,dword [@self.fd]
  mov  edx,dword [@src.top]
  mov  rsi,qword [@src.buff]

  push rdx
  mov  rax,SYS.write.id

  syscall


  ; update meta
  bin.write_epilogue

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^at end

proc.new bin.append,public

proc.lis bin        self rdi
proc.lis array.head src  rsi

macro bin.append.inline {

  proc.enter

  ; go to end
  push   @src
  xor    rsi,rsi

  dpline bin.fastfwd

  ; ^make write
  pop  @src
  call bin.write


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline bin.append
  ret

; ---   *   ---   *   ---
; ^buffered

proc.new bin.append_sow,public

proc.lis bin        self rdi
proc.lis array.head src  rsi

macro bin.append_sow.inline {

  proc.enter

  ; go to end
  push   @src
  xor    rsi,rsi

  dpline bin.fastfwd

  ; ^make write
  pop  @src
  call bin.sow


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline bin.append_sow
  ret

; ---   *   ---   *   ---
; footer

constr ROM

; ---   *   ---   *   --
