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

  use '.hed' peso::cstring
  use '.hed' peso::constr
  use '.hed' peso::memcmp

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.env

  VERSION   v0.00.3b
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
  call cstring.skip
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

  call cstring.skip
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

    call cstring.length

    mov  rdx,[@dst.length]
    mov  dword [rdx],eax


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; footer

constr.new public env.path.MEM,"/.mem/"
constr.new public env.path.CACHE,"/.cache/"

; ---   *   ---   *   ---
