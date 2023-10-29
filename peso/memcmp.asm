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

  VERSION   v0.00.3b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.asm' peso::smX

library.import

; ---   *   ---   *   ---
; *data eq *data

proc.new memeq

  proc.enter

  push r10
  push r9
  push rbx

  xor  rbx,rbx


  ; stop at first inequality
  .chk_eq:

    mov rax,rbx
    pop rbx

    or  rax,$00
    jnz .skip_a

  ; see if bytes left
  .chk_size:
    pop r9
    pop r10

    cmp r8d,$00
    jle .skip_b

  ; get branch
  call smX.get_size

; ---   *   ---   *   ---
; ^for when you want to skip
; recalculating size!

.direct:

  ; ^branch
  push r10
  push r9
  push rbx

  cmp  dl,$04
  jge  .is_struc


  ; i8-64 jmptab
  smX.i_tab smX.i_eq,\
  jmp .chk_eq

  ; ^sse
  .is_struc:
    call memeq.struc
    jmp  .chk_eq


  ; cleanup and give
  .skip_a:
    pop r9
    pop r10

  .skip_b:
    mov    rcx,$01
    or     rax,$00
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

proc.new memeq.struc
proc.stk memeq.req dst

  ; get branch
  proc.enter
  call smX.get_alignment

; ---   *   ---   *   ---
; ^for when you want to skip
; recalculating alignment!

.direct:

  ; save tmp
  push rbx

  ; branch accto step
  mov r10d,ecx
  shr r10d,$04
  dec r10d

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
    pop rbx

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
