; ---   *   ---   *   ---
; PESO FILE
; Sow buffio!
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
  use '.hed' peso::bin

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.file

  VERSION   v0.00.8b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

RAMSEG

file.buff.SZ=$100

reg.new file.buff,public

  ; pool
  my .ct    db file.buff.SZ dup $00

  ; bkeep
  my .fto   dw stdout

  my .avail dd file.buff.SZ
  my .ptr   dd $00

reg.end

reg.ice file.buff buffio

; ---   *   ---   *   ---
; flush buff

EXESEG

proc.new reap,public
proc.cpr r11,rdi,rsi

macro reap.inline {

  proc.enter

  ; clear registers
  xor rdi,rdi
  xor rdx,rdx

  ; ^commit buffer to file
  mov di,word [buffio.fto]
  mov rsi,buffio.ct
  mov dx,word [buffio.ptr]

  mov rax,SYS.write.id
  syscall

  ; ^reset meta
  mov word [buffio.avail],file.buff.SZ
  mov word [buffio.ptr],$0000


  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline reap
  ret

; ---   *   ---   *   ---
; set fhandle

proc.new fto,public

  proc.enter

  ; get current fh eq passed
  xor rax,rax
  mov ax,word [buffio.fto]

  ; ^skip if so
  cmp rax,rdi
  je  @f

  ; ^else flush, then swap
  inline reap
  mov    word [buffio.fto],di


  @@:

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^issue write

proc.new sow,public

  proc.enter

  ; store total
  mov r9,rsi
  mov rsi,rdi

  ; flush on full buff
  .chk_size:

    ; get avail
    xor r8,r8
    mov r8d,dword [buffio.avail]

    ; ^clear on below chunk
    cmp    r8d,sizeof.unit
    jge    .go_next

    inline reap

    ; ^refresh avail
    mov r8w,file.buff.SZ


  ; ^write next chunk
  .go_next:

    ; use smallest length
    cmp   r9d,r8d
    cmovl r8d,r9d
    sub   r9d,r8d

    ; get buff+ptr
    xor edx,edx
    mov edx,dword [buffio.ptr]
    lea rdi,[buffio.ct+edx]

    ; adjust buff meta
    sub dword [buffio.avail],r8d
    add dword [buffio.ptr],r8d


  ; write chunks
  .cpy:

    mov r10w,smX.CDEREF
    call memcpy

    ; ^restart
    or r9d,$00
    jg .chk_size


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; write string to selected file

proc.new string.sow,public
proc.lis array.head self rdi

macro string.sow.inline {

  proc.enter

  mov  rsi,qword [@self.top]
  mov  rdi,qword [@self.buff]

  call sow

  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline string.sow
  ret

; ---   *   ---   *   ---
; ^const

macro constr.sow name {

  mov  rdi,name
  mov  rsi,name#.length

  call sow

}

; ---   *   ---   *   ---
; ^errout

macro constr.errout name,code {

  ; switch file
  mov  rdi,stderr
  call fto

  ; ^write
  constr.sow tag.#code
  constr.sow name

  match =FATAL,code \{
    call reap
    exit -1

  \}

}

; ---   *   ---   *   ---
; ^all-in-one sugar

macro constr.throw code,[ct] {

  local name

  proc.get_id name,code#_errme

  match any,name \{
    constr.new    any,ct
    constr.errout any,code

  \}

}

; ---   *   ---   *   ---
; footer

MAM.atexit.push call reap

; ---   *   ---   *   ---
