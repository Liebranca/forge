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

  VERSION   v0.00.8b
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


  ; further calls
  SYS.close.id  = $03
  SYS.trunc.id  = $4C
  SYS.unlink.id = $57

; ---   *   ---   *   ---
; ^further calls

SYS.read:

  .id  = $00

  ; custom flag for bin.read
  .over = $00
  .seek = $01
  .ecat = $02
  .ucap = $04


SYS.lseek:

  .id  = $08

  ; mode
  .set = $00
  .cur = $01
  .end = $02

; ---   *   ---   *   ---
; GBL

  List.new bin.FILES

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
; clear file meta

macro bin.clear_meta src {

  and dword [src+bin.state],$00
  and dword [src+bin.ptr],$00
  and dword [src+bin.hsz],$00
  and dword [src+bin.fsz],$00

}

; ---   *   ---   *   ---
; cstruc

proc.new bin.new,public

macro bin.new.inline {

  proc.enter

  ; get mem
  mov  rdi,sizeof.bin
  call alloc

  ; ^clear signature
  ; (bin is generic so no sigchk ;>)
  mov qword [rax+bin.sig],$00


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline bin.new
  ret

; ---   *   ---   *   ---
; ^sugar

macro bin.from dst,path {

  ; make dynamic from const
  string.from path

  ; ^make container
  mov    rdi,rax
  dpline bin.new

  ; ^save
  mov dst,rax

}

; ---   *   ---   *   ---
; ^higher sugar, guts v

macro bin._from2 dst,VN,fpath& {

  local name
  local vflag

  name  equ VN
  vflag equ
  dst   equ

  match type any , VN \{
    vflag equ type
    name  equ any

  \}

  match any , name \{

    bin.FILES.push any        dq $00
    bin.FILES.push any\#.path dq $00

    MAM.sym_vflag dst,any,vflag
    MAM.sym_vflag dst,any\#.path,vflag

    ; ^save fpath to RAM
    string.fcat qword [any\#.path],fpath
    dst equ any

  \}

}

; ---   *   ---   *   ---
; ^borderline diabetes

macro bin.static VN,fpath& {

  ; promise symbols to RAM
  local dst
  bin._from2 dst,VN,fpath

  ; ^make ice and backup
  dpline bin.new
  mov    qword [dst],rax

}

; ---   *   ---   *   ---
; throws on fail

proc.new bin.open_or_die,public

proc.lis bin    self rdi
proc.lis string path rsi

proc.stk qword  path_sv
proc.stk qword  self_sv

  proc.enter

  ; save tmp
  push rdx
  push r8
  mov  qword [@self_sv],@self
  mov  qword [@self.path],@path

  ; ensure nullterm (cstrs be damned ;>)
  mov  rdi,@path
  xor  rsi,rsi

  call array.push

  ; get/make file
  pop  rdx
  pop  rsi

  mov  @self,qword [@self_sv]
  mov  rdi,qword [@self.path]
  mov  qword [@path_sv],rdi
  mov  rdi,qword [rdi+string.buff]
  mov  rax,SYS.open.id

  syscall


  ; ^errchk
  cmp rax,$00
  jge .fdok

  string.ferr FATAL,\
    "Cannot open file [",\
    string qword [@path_sv],\
    "]",$0A


  ; nothing broke ;>
  .fdok:

    ; ^copy fd
    mov @self,qword [@self_sv]
    mov dword [@self.fd],eax
    or  dword [@self.state],bin.opened

    ; calc filesize, no stat
    call bin.get_fsz


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^make/clear

proc.new bin.open_new,public

proc.lis bin    self rdi
proc.lis string path rsi

macro bin.open_new.inline {

  proc.enter
  bin.clear_meta @self

  ; set flags and make syscall+errchk
  or  edx,SYS.open.new or SYS.open.trunc
  mov r8,SYS.open.new.mode
  mov dword [@self.flags],edx

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

proc.lis bin    self rdi
proc.lis string path rsi

macro bin.open.inline {

  proc.enter
  bin.clear_meta @self

  ; set flags and make syscall+errchk
  or   edx,r8d
  mov  dword [@self.flags],edx

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
proc.lis bin self rdi

macro bin.del.inline {

  proc.enter

  ; save tmp
  push rdi

  ; close if opened
  call bin.close

  ; ^release mem
  pop  rdi
  call free


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline bin.del
  ret

; ---   *   ---   *   ---
; set file to size

proc.new bin.trunc,public
proc.lis bin self rdi

macro bin.trunc.inline {

  proc.enter

  ; set size
  push @self
  mov  rdi,qword [@self.path]
  mov  rdi,qword [rdi+string.buff]
  mov  rax,SYS.trunc.id

  syscall

  ; ^register
  pop  @self
  call bin.get_fsz


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  ret

; ---   *   ---   *   ---
; erase from disk

proc.new bin.unlink,public
proc.lis bin self rdi

macro bin.unlink.inline {

  proc.enter

  ; save tmp
  push @self

  ; close if opened
  call bin.close

  ; ^delete file
  pop @self
  mov rdi,qword [@self.path]
  mov rdi,qword [rdi+string.buff]
  mov rax,SYS.unlink.id

  syscall


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline bin.unlink
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
; recalc size of file

proc.new bin.get_fsz,public
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
; process dst options for
; bin.read

proc.new bin.reader_mode,public

proc.lis bin    self rdi
proc.lis string dst  rsi

  proc.enter

  ; skip on uncapped read
  test r10w,SYS.read.ucap
  jnz  @f

  ; ^get read cap (fsz-ptr)
  mov  ecx,dword [@self.fsz]
  sub  ecx,dword [@self.ptr]

  ; ^apply if req > cap
  cmp   edx,ecx
  cmovg edx,ecx


  ; ^clear unrelated flags
  @@:
  and r10w,not SYS.read.ucap

  ; save tmp
  push @self
  push rdx


  ; proc dst options
  xor       rax,rax
  mov       ax,r10w
  branchtab get_mode


  ; cat read bytes at end of dst
  get_mode.branch SYS.read.ecat => .ecat
    mov r8d,dword [@dst.top]
    mov ecx,edx
    jmp .apply_offset

  ; overwrite dst in full
  get_mode.branch SYS.read.over => .over
    xor r8d,r8d
    mov dword [@dst.top],$00
    mov ecx,edx
    jmp .apply_offset


  ; overwrite starting at given position
  ; adjust length accordingly
  get_mode.branch SYS.read.seek => .seek

    ; get [top,(write end)]
    mov eax,dword [@dst.top]
    add ecx,r8d

    ; ^grow on (write end) > top
    sub   ecx,eax
    xor   eax,eax
    cmp   ecx,$00
    cmovl ecx,eax

    jmp .apply_offset


  get_mode.end

  ; ^tail-of
  .apply_offset:

    ; resize buff if need
    push @dst
    push rcx
    mov  rdi,rsi
    mov  esi,r8d

    call array.resize_chk

    ; ^get buff+offset
    pop rcx
    pop @dst

    add dword [@dst.top],ecx
    mov rsi,[@dst.buff]
    add rsi,r8


  ; restore tmp
  pop rdx
  pop @self

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; read N bytes to string

proc.new bin.read,public

proc.lis bin    self rdi
proc.lis string dst  rsi

macro bin.read.inline {

  proc.enter

  ; config dst
  call bin.reader_mode

  ; ^make syscall
  mov edi,dword [@self.fd]
  mov rax,SYS.read.id

  syscall


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline bin.read
  ret

; ---   *   ---   *   ---
; ^raw version

proc.new bin.dread,public

proc.lis bin   self rdi
proc.stk qword path

  proc.enter

  ; save tmp
  push rdx
  push @self

  ; read in from [rdi.top] to [rdi.top+rdx]
  mov  edi,dword [@self.fd]
  mov  rax,SYS.read.id

  syscall


  ; ^errchk
  pop @self
  pop rdx
  cmp rax,rdx
  je  @f

  ; ^errme
  mov rax,qword [@self.path]
  mov qword [@path],rax

  string.ferr FATAL,\
    "Direct read from [",\
    string qword [@path],\
    "] failed",$0A


  @@:

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; open,read,close

proc.new orc,public

proc.lis string path rdi

proc.stk qword f0
proc.stk qword s0

  proc.enter


  ; make container
  push @path

  call bin.new
  mov  qword [@f0],rax

  ; ^open file
  mov    rdi,rax
  pop    rsi
  mov    rdx,SYS.open.read
  xor    r8,r8

  inline bin.open


  ; make dst buff
  string.blank byte
  mov qword [@s0],rax

  ; ^read to
  mov  rdi,qword [@f0]
  mov  rsi,rax
  mov  edx,$7FFFFFFF
  mov  r10w,SYS.read.over

  call bin.read

  ; ^release container
  mov    rdi,qword [@f0]
  inline bin.del


  ; reset out
  mov rax,qword [@s0]

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

proc.lis bin    self rdi
proc.lis string src  rsi

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

proc.lis bin    self rdi
proc.lis string src  rsi

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
; ^raw version

proc.new bin.dwrite,public

proc.lis bin   self rdi
proc.stk qword path

  proc.enter

  ; save tmp
  push rdx
  push @self

  ; write from [rsi] to [rsi+rdx]
  mov  edi,dword [@self.fd]
  mov  rax,SYS.write.id

  syscall


  ; ^errchk
  pop @self
  pop rdx
  cmp rax,rdx
  je  @f

  ; ^errme
  mov rax,qword [@self.path]
  mov qword [@path],rax

  string.ferr FATAL,\
    "Direct write to [",\
    string qword [@path],\
    "] failed",$0A


  @@:

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; unbuffered write at end

proc.new bin.append,public

proc.lis bin    self rdi
proc.lis string src  rsi

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

proc.lis bin    self rdi
proc.lis string src  rsi

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
; ^open,write,close

proc.new owc,public

proc.lis string path rdi
proc.lis string buff rsi

proc.stk qword f0

  proc.enter


  ; make container
  push @buff
  push @path

  call bin.new
  mov  qword [@f0],rax

  ; ^open file
  pop    rsi
  mov    rdi,rax
  mov    rdx,SYS.open.write
  xor    r8,r8

  inline bin.open_new


  ; ^write to
  pop  @buff
  call bin.write

  ; ^release container
  mov    rdi,qword [@f0]
  inline bin.del


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; footer

macro bin._gen_footer {

  match any , bin.FILES.m_list \{

    RAMSEG
    bin.FILES

  \}

}

MAM.foot.push bin._gen_footer

; ---   *   ---   *   --
