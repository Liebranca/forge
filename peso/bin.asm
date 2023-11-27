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
  use '.hed' peso::string

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.bin

  VERSION   v0.00.1b
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
  .new.mode = 0x180


  ; nothing further
  SYS.close.id=$03

; ---   *   ---   *   ---
; base struc

reg.new bin,public

  my .fd    dd $00
  my .flags dd $00

  my .path  dq $00
  my .sig   dq $00

  my .ptr   dq $00

reg.end

; ---   *   ---   *   ---
; cstruc

proc.new bin.open_prologue

  proc.enter

  ; save tmp
  push rdi
  push rsi

  ; ensure nullterm (cstrs be damned ;>)
  xor  rsi,rsi
  call array.push

  ; ^now get mem
  mov  rdi,sizeof.bin
  call alloc


  ; restore tmp
  pop rsi
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
; repeating bit

macro bin.open_or_die [errme] { common

  ; get/make file
  mov rdi,qword [rdi+array.head.buff]
  mov rax,SYS.open.id

  syscall

  ; ^errchk
  cmp rax,$00
  jge .fdok

  OS.throw FATAL,errme


  ; nothing broke ;>
  .fdok:

    ; ^copy fd
    mov rcx,qword [@out]
    mov dword [rcx+bin.fd],eax

    ; ^reset out
    mov rax,rcx

}

; ---   *   ---   *   ---
; ^make/clear

proc.new bin.new,public
proc.stk qword out

  proc.enter

  ; get container
  call bin.open_prologue
  mov  qword [@out],rax

  ; ^set flags
  xor rdx,rdx
  or  esi,SYS.open.new
  or  esi,SYS.open.trunc
  mov dword [rax+bin.flags],esi


  ; commit
  mov rdx,SYS.open.new.mode
  bin.open_or_die "Cannot make new file",$0A

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^load

proc.new bin.open,public
proc.stk qword out

  proc.enter

  ; save tmp
  push rdx

  ; get container
  call bin.open_prologue
  mov  qword [@out],rax

  ; ^set flags
  pop rdx

  or  esi,edx
  mov dword [rax+bin.flags],esi


  ; commit
  bin.open_or_die "Cannot open file",$0A

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^free

proc.new bin.close,public

proc.lis bin   self rdi

proc.stk qword head
proc.stk qword path

  proc.enter

  ; save tmp
  mov rax,qword [@self.path]
  mov qword [@head],rdi
  mov qword [@path],rax

  ; close fd
  mov edi,dword [@self.fd]
  mov rax,SYS.close.id

  syscall


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
; footer

constr ROM

; ---   *   ---   *   --
