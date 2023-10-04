; ---   *   ---   *   ---
; PESO MPART
; Breaks up mem
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
  use '.inc' peso::constr
  use '.asm' peso::page

import

; ---   *   ---   *   ---
; info

  TITLE     peso.mpart

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

; ---   *   ---   *   ---
; find first free bit

proc.new mpart.get_free

  proc.enter

  ; get first unset
  xor    rcx,rcx
  not    rdi
  bsf    rsi,rdi

  ; ^skip if all set
  cmovnz rcx,rsi
  mov    rax,rcx

  not    rdi

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^shift to fred

proc.new mpart.shr_free

  proc.enter

  ; get first unset
  call mpart.get_free

  ; ^shift to start of free space
  shr rdi,cl

  add rdx,rax
  mov rax,rdi


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^find last occupied bit

proc.new mpart.get_occu

  proc.enter

  ; get idex
  xor    rbx,rbx
  xor    rcx,rcx
  bsr    rsi,rdi

  ; conditional mov && add
  mov    rbx,$01
  cmovz  rbx,rcx
  cmovnz rcx,rsi

  ; ^A+(1*?A)
  add rcx,rbx


  ; cleanup and give
  mov rax,rcx

  proc.leave
  ret

; ---   *   ---   *   ---
; ^shift them out

proc.new mpart.shr_occu

  proc.enter

  ; get first set
  call mpart.get_occu

  ; ^shift it out
  shr rdi,cl
  add rdx,rax


  ; cleanup and give
  mov rax,rdi

  proc.leave
  ret

; ---   *   ---   *   ---
; get N free bits

proc.new mpart.fit

  proc.enter

  ; reset counters
  xor rdx,rdx
  .top:

    ; get next free chunk
    push rdi
    mov  rdi,rsi

    call mpart.shr_free

    mov  rsi,rax
    pop  rax

    ; ^compare to requested
    ; repeat if free chunk is too small
    and rax,rsi
    jz  .skip


  ; ^get bits to shift if no fit
  .body:

    ; skip occupied portion
    push rsi
    mov  rdi,rax

    call mpart.get_occu

    pop  rsi

    ; ^shift it out
    shr  rsi,cl
    add  rdx,rax

    jmp .top


  ; cleanup and give
  .skip:
    mov rax,rdx

  proc.leave
  ret

; ---   *   ---   *   ---
; shorthand in

macro mpart.get_level.brend sz {
  mov rax,(sizep2.#sz) - 6
  jmp .skip

}

; ---   *   ---   *   ---
; get partition level accto
; block size in rdi

proc.new mpart.get_level

  proc.enter

  ; decide path
  .sz_xline:

    ; block too small
    cmp rdi,sizeof.xline
    jl  .sz_qline

    ; ^too big
    cmp rdi,sizeof.xline * $04
    jg  .sz_yline

    ; ^just right ;>
    mpart.get_level.brend xline


  ; from here downwards
  .sz_qline:
    cmp rdi,sizeof.qline
    jl  .sz_dline

    mpart.get_level.brend qline

  ; ^from here upwards
  .sz_yline:
    cmp rdi,sizeof.yline * $04
    jg  .sz_zline

    mpart.get_level.brend yline


  ; ^either of the two lowest
  .sz_dline:

    mov    rax,sizep2.line - $06
    mov    rbx,sizep2.dline - $06

    cmp    rdi,sizeof.dline
    cmovge rax,rbx

    jmp    .skip


  ; ^either of the three highest
  .sz_zline:

    ; ^the absolute highest
    cmp rdi,sizeof.zline * $04
    jmp .sz_dpage

    ; ^either of the two pens
    mov    rax,sizep2.zline - $06
    mov    rbx,sizep2.page - $06

    cmp    rdi,sizeof.zline
    cmovge rax,rbx

    jmp    .skip


  ; biggest size
  .sz_dpage:
    cmp rdi,sizeof.dpage * $40
    jg  .throw

    mpart.get_level.brend dpage

  ; ^no fit
  .throw:

    constr.new mpart.throw_bpart,\
      "request exceeds maximum ",\
      "partition size",$0A

    constr.errout mpart.throw_bpart,FATAL


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; ROM II

constr.seg

; ---   *   ---   *   ---
