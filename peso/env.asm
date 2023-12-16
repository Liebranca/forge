; ---   *   ---   *   ---
; PESO ENV
; I'm talking to you!
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

  use '.inc' OS
  use '.hed' peso::constr
  use '.hed' peso::memcmp

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.env

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; make key for environ lookup

macro env.keygen name {

  match pre , SEG.name \{

    segptr name         dq $00
    segptr name#.length dd $00

    segptr name#.key    db "ARPATH"
    segptr name#.klen   dd $-pre\#.#name#.key

    MAM.malign unit

  \}

}

; ---   *   ---   *   ---
; ^lookup shorthand

macro env.getv name {

  mov qword [rdi+env.lkp.base],\
    env.state.#name

  mov qword [rdi+env.lkp.key],\
    env.state.#name#.key

  mov qword [rdi+env.lkp.length],\
    env.state.#name#.length

  mov qword [rdi+env.lkp.klen],\
    env.state.#name#.klen


  call env.get

}

; ---   *   ---   *   ---
; ^relevant struc

reg.new env.lkp,public

  my .base   dq $00
  my .key    dq $00

  my .length dq $00
  my .klen   dq $00

reg.end

; ---   *   ---   *   ---
; ROM

ROMSEG env.CON,public

  .MASK_Z0 dq $7F7F7F7F7F7F7F7F
  .MASK_Z1 dq $0101010101010101
  .MASK_Z2 dq $8080808080808080

; ---   *   ---   *   ---
; GBL

RAMSEG env.state,public

  segptr argc dq $00
  segptr argv dq $00
  segptr envp dq $00

  env.keygen ARPATH

; ---   *   ---   *   ---
; proc argc,argv,envp

EXESEG

proc.new env.nit,public

  proc.enter

  ; get argc
  mov rax,qword [rdi]
  mov rsi,rax
  mov qword [env.state.argc],rax

  ; ^point to beg of argv
  mov rax,qword [rdi+sizeof.qword]
  mov rdi,rax
  mov qword [env.state.argv],rax

  ; ^get addrof envp
  call cstr.skip
  mov  qword [env.state.envp],rax


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; get environ

proc.new env.get,public

proc.lis env.lkp dst  r11
proc.stk qword   path

  proc.enter

  ; save passed struc
  mov @dst,rdi

  ; get begof buff
  mov rax,qword [env.state.envp]
  mov qword [@path],rax


  ; compare entry to key
  .go_next:

    mov  rdi,qword [@dst.key]
    mov  rsi,qword [@path]
    mov  r8,qword [@dst.klen]
    mov  r8d,dword [r8]

    mov  r9w,smX.CDEREF
    mov  r10w,smX.CDEREF

    call memeq

  ; ^passed
  test rax,rax
  jz   .found


  ; ^nope, go next
  mov  rdi,qword [@path]
  mov  rsi,$01

  call cstr.skip
  mov  qword [@path],rdi


  ; ^errchk endof buff
  mov  al,byte [rdi]
  test al,al

  jnz  .go_next

  ; ^fail, throw errme
  constr.throw FATAL,\
    "Cannot find passed ENV"


  ; ^all OK, var found
  .found:

    inc  rsi
    mov  rax,qword [@dst.base]
    mov  qword [rax],rsi
    mov  rdi,rsi

    call cstr.length

    mov  rdx,[@dst.length]
    mov  dword [rdx],eax


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; gives 0 or 1+nullidex

proc.new cstr.ziw,public
macro cstr.ziw.inline {

  proc.enter
  xor rcx,rcx

  ; convert 00 to 80 && 01-7E to 00 ;>
  xor rsi,qword [env.CON.MASK_Z0]
  add rsi,qword [env.CON.MASK_Z1]
  and rsi,qword [env.CON.MASK_Z2]

  je  .ziw_skip

  ; get first null byte (80)+1
  bsf rcx,rsi
  shr rcx,$03
  inc rcx


  ; cleanup
  .ziw_skip:
  proc.leave

}

  ; ^invoke and give
  inline cstr.ziw
  ret

; ---   *   ---   *   ---
; length of cstr if chars
; are in 00-7E range, else bogus

proc.new cstr.length,public
proc.cpr rdi,rsi

  proc.enter
  xor rax,rax

  .top:

    ; get null in qword
    mov    rsi,qword [rdi]
    inline cstr.ziw

    ; ^end reached
    test  rcx,rcx
    jnz   .bot

    ; ^else increase
    add   rax,8
    add   rdi,8
    jmp   .top

  ; sum final length
  .bot:
    dec   rcx
    sub   rdi,rax
    add   rax,rcx


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; walk cstr buff

proc.new cstr.skip,public

  proc.enter

  ; get N strings skipped
  .top:
    test rsi,rsi
    jz   .skip

  ; ^walk next string
  call cstr.length

  dec  rsi
  lea  rdi,[rdi+rax+1]
  jmp  .top


  ; cleanup and give
  .skip:
    mov rax,rdi

  proc.leave
  ret

; ---   *   ---   *   ---
; footer

constr.new public env.path.MEM,"/.mem/"
constr.new public env.path.CACHE,"/.cache/"

; ---   *   ---   *   ---
