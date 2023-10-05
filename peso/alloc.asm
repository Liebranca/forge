; ---   *   ---   *   ---
; PESO ALLOC
; Hands you mem
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
  use '.asm' peso::mpart
  use '.asm' peso::crypt
  use '.asm' peso::stk

import

; ---   *   ---   *   ---
; info

  TITLE     peso.alloc

  VERSION   v0.00.6b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

unit.salign r,w

reg.new alloc.tab

  my .l0 dq $00
  my .l1 dq $00
  my .l2 dq $00
  my .l3 dq $00

  my .l4 dq $00
  my .l5 dq $00
  my .l6 dq $00
  my .l7 dq $00

  my .lX dq $00

reg.end

reg.ice alloc.tab alloc.main

; ---   *   ---   *   ---
; ^element for each subtable

reg.new alloc.chain

  my .buff  dq $00
  my .mask  dq $00

  my .lvl   dw $00

  my .max   dw $00
  my .avail dw $00

reg.end

; ---   *   ---   *   ---
; ^ctx for alloc requests

reg.new alloc.req

  my .stab dq $00
  my .buff dq $00
  my .elem dq $00

  my .req  dq $00
  my .lvl  dq $00

reg.end

; ---   *   ---   *   ---
; how free knows a block

reg.new alloc.head

  my .addr dq $00

  my .lvl  dw $00
  my .stab dw $00
  my .pos  dw $00
  my .size dw $00

reg.end

; ---   *   ---   *   ---
; base cstruc

unit.salign r,x

proc.new alloc

proc.lis alloc.tab self alloc.main
proc.stk alloc.req ctx

  proc.enter

  ; load struc addr
  lea r11,[@ctx]


  ; get N lines taken
  add  rdi,sizeof.alloc.head
  mov  qword [@ctx.req],rdi

  ; fetch block
  call alloc.get_stab
  call alloc.get_blk


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^dstruc

proc.new free

  proc.enter

  call alloc.hash_blk


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; map blk addr to idex

proc.new alloc.hash_blk

  proc.enter

  mov  rsi,$10
  mov  rdx,$08
  mov  cl,$04

  call hash


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; selects subtable accto
; aligned size of block

proc.new alloc.get_stab

proc.lis alloc.tab self alloc.main
proc.arg alloc.req ctx  r11

  proc.enter

  ; get subtable size
  mov  rdi,qword [@ctx.req]
  call mpart.get_level

  ; ^save tmp
  mov qword [@ctx.lvl],rax
  lea rcx,[rax+6]
  lea rax,[@self.l0+rax*8]

  ; align block size
  push rax
  mov  rdi,qword [@ctx.req]

  call UInt.urdivp2
  shl  rax,cl

  mov  qword [@ctx.req],rax


  ; fetch subtable
  pop  rdi
  call alloc.get_stk

  mov  qword [@ctx.stab],rax


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; make new seg

proc.new alloc.get_blk

proc.lis alloc.tab self alloc.main
proc.arg alloc.req ctx  r11

  proc.enter

  ; get elem
  mov   rdi,qword [@ctx.stab]
  mov   rsi,qword [rdi+stk.top]
  shr   rsi,1
  dec   rsi

  ; ^cap idex at 0
  xor   rdx,rdx
  cmp   rsi,$00
  cmovl rsi,rdx

  ; ^scale up and pass
  shl  rsi,1
  call stk.view

  ; ^zero chk
  mov qword [@ctx.elem],rax
  mov rax,qword [rdi+stk.top]
  or  rax,$00

  jnz .fit_mem


  ; make new entry
  .get_mem:
    call alloc.new_blk
    mov  qword [@ctx.elem],rax

  ; ^reuse existing
  .fit_mem:

    ; map block size to bitmask
    mov rdi,qword [@ctx.req]
    mov rsi,qword [@ctx.lvl]

    call mpart.qmask

    ; ^fit mask in block
    mov  rdi,rax
    mov  rax,qword [@ctx.elem]
    mov  rsi,qword [rax+alloc.chain.mask]

    push rax
    call mpart.fit

    ; ^update block
    pop  rbx
    mov  rcx,rax

    push rdi
    shl  rdi,cl

    mov  rdx,rcx
    shl  rdx,sizep2.line

    ; get offset scaled up
    ; then size scaled down
    mov rsi,qword [@ctx.req]
    mov rcx,qword [@ctx.lvl]

    shl rdx,cl

    add rcx,6
    shr rsi,cl

    ; update mask and sizes
    or  qword [rbx+alloc.chain.mask],rdi
    sub qword [rbx+alloc.chain.avail],rsi

    ; TODO: calc max alloc for block


    ; set out
    pop  rdi
    mov  rax,qword [@ctx.buff]
    lea  rax,[rax+rdx]

    push rax


    ; ^(test) set header
    mov  rdi,rax
    call alloc.hash_blk

    mov  rbx,qword [@self.lX]
    mov  rdx,rax
    shl  rdx,$04

    mov  rcx,qword [rbx+rdx]
    cmp  rcx,$2424
    je   .throw

    mov  qword [rbx+rdx],$2424
    jmp  .tail

  ; ^errme
  .throw:


    mov   rdi,qword [@ctx.elem]
    mov   r15,qword [rdi+alloc.chain.mask]
    shr   r15,1

    constr.new alloc.throw_hashcol,\
      "address collision at 0000000000000000",$0A

    lea rax,[alloc.throw_hashcol]
    lea rax,[rax+alloc.throw_hashcol.length-2]

; SCRATCH

  .top2:
    mov rbx,r15
    xor dl,dl

    and bl,$0F
    cmp bl,$0A
    jl  .skip2

    mov dl,$07

    .skip2:
    add bl,$30
    add bl,dl

    mov byte [rax],bl
    shr r15,$04

    dec rax
    cmp r15,$00
    jg  .top2


; END SCRATCH

    constr.errout alloc.throw_hashcol,FATAL


  .tail:
    pop rax


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; get at least N bytes

proc.new alloc.new_blk

proc.lis alloc.tab self alloc.main
proc.arg alloc.req ctx  r11


  proc.enter

  ; get N pages
  mov  cx,word [@ctx.lvl]
  add  rcx,$06
  mov  rdi,sizeof.line
  shl  rdi,cl

  call page.new
  mov  qword [@ctx.buff],rax

  ; make new element
  mov  rdi,qword [@ctx.stab]
  mov  rsi,$02

  call stk.push


  ; ^nit elem
  mov rbx,qword [@ctx.buff]
  mov rcx,qword [@ctx.lvl]

  ; addr && free slots
  mov qword [rax+alloc.chain.buff],rbx
  mov qword [rax+alloc.chain.mask],$00

  ; ^partition order
  mov word [rax+alloc.chain.lvl],cx

  ; ^total size, scaled down
  mov word [rax+alloc.chain.avail],sizeof.line
  mov word [rax+alloc.chain.max],sizeof.line


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; subtable fetch or cstruc

proc.new alloc.get_stk
proc.lis alloc.tab self alloc.main

  proc.enter

  ; renit chk
  mov rax,qword [rdi]
  or  rax,$00

  jnz .skip


  ; get one page for starters
  push rdi
  mov  rdi,sizeof.page

  call page.new

  ; ^store base and nit
  pop rdi
  mov qword [rdi],rax

  mov qword [rax+stk.top],$00
  mov qword [rax+stk.size],sizeof.page


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; cstruc

proc.new alloc.new
proc.lis alloc.tab self alloc.main

  proc.enter

  ; renit chk
  mov rax,qword [@self.lX]

  or  rax,$00
  jnz .throw


  ; get one page for starters
  mov  rdi,sizeof.page
  call page.new

  ; ^store
  mov qword [@self.lX],rax


  ; errme
  jmp .skip
  .throw:

    constr.new alloc.throw_renit,\
      "allocator renit",$0A

    constr.errout alloc.throw_renit,FATAL


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; ^dstruc

proc.new alloc.del
proc.lis alloc.tab self alloc.main

  proc.enter

  xor rdx,rdx
  .get_next:

    ; ^stop at last idex
    cmp rdx,$08
    je  .skip

    ; get subtable
    lea rax,[@self+rdx*8]
    inc rdx


  ; ^dealloc
  .del_stk:

    ; skip empty
    mov rdi,qword [rax]
    or  rdi,$00

    jz  .get_next


    ; free elements
    push rdi
    call alloc.del_stk

    ; free the stack itself
    pop  rdi
    mov  rsi,qword [rdi+stk.size]
    shr  rsi,sizep2.page

    call page.free
    jmp  .get_next


  ; cleanup and give
  .skip:

    mov  rdi,qword [@self.lX]
    mov  rsi,1

    call page.free


  proc.leave
  ret

; ---   *   ---   *   ---
; ^pop from subtable

proc.new alloc.del_stk

  ; get element
  .get_next:

    ; check empty stack
    mov rax,qword [rdi+stk.top]
    or  rax,$00

    jz  .skip


    ; ^shrink
    mov  rsi,sizeof.alloc.chain
    shr  rsi,sizep2.unit

    call stk.pop


  ; ^free
  .del_elem:

    push rdi

    mov  rsi,$01
    mov  rdi,qword [rax+alloc.chain.buff]
    mov  cx,word [rax+alloc.chain.lvl]
    shl  rsi,cl

    call page.free


    ; repeat
    pop rdi
    jmp .get_next


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; ROM II

constr.seg

; ---   *   ---   *   ---
