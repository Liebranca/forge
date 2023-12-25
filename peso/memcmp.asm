; ---   *   ---   *   ---
; MEMCMP
; Byte matchin
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     peso.memcmp

  VERSION   v0.00.7b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.hed' peso::smX

library.import

; ---   *   ---   *   ---
; *data eq *data

proc.new memeq,public

  proc.enter

  push r10
  push r9
  push rbx

  xor  rbx,rbx


  ; stop at first inequality
  .chk_eq:

    mov  rax,rbx
    pop  rbx

    test rax,rax
    jnz  .skip_a

  ; see if bytes left
  .chk_size:
    pop r9
    pop r10

    cmp r8d,$00
    jle .skip_b


  ; get branch
  call smX.get_size


  ; ^branch
  push r10
  push r9
  push rbx

  xor  rbx,rbx
  cmp  al,$04
  jge  .is_struc


  ; i8-64 jmptab
  smX.i_tab smX.i_eq,\
  jmp .chk_eq

  ; ^sse
  .is_struc:

    call memeq.struc

    mov  rbx,rax
    jmp  .chk_eq


  ; cleanup and give
  .skip_a:
    pop r9
    pop r10

  .skip_b:
    mov    rcx,$01
    test   rax,rax
    cmovnz rax,rcx

  proc.leave
  ret

; ---   *   ---   *   ---
; ^large mem struc

reg.new memeq.req

  my .l0 dq 2 dup $00
  my .l1 dq 2 dup $00
  my .l2 dq 2 dup $00
  my .l3 dq 2 dup $00
  my .l4 dq 2 dup $00
  my .l5 dq 2 dup $00
  my .l6 dq 2 dup $00
  my .l7 dq 2 dup $00

reg.end

; ---   *   ---   *   ---
; ^large mem proc

proc.new memeq.struc,public

proc.stk memeq.req dst
proc.cpr rbx

  ; get branch
  proc.enter
  call smX.get_alignment


  ; stop at first inequality
  xor rbx,rbx
  .chk_eq:
    or  rbx,$00
    jnz .skip

  ; see if bytes left
  .chk_size:
    cmp r8d,ecx
    jl  .skip

  ; galactic unroll
  smX.sse_tab2 \
    smX.sse_eq,\
    jmp .go_next,\
    @dst

  ; ^consume
  .go_next:

    add rdi,rcx
    add rsi,rcx
    sub r8d,ecx

    jmp .chk_eq


  ; reset out
  .skip:
    mov rax,rbx

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
