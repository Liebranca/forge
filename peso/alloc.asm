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
; info

  TITLE     peso.alloc

  VERSION   v0.01.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.asm' peso::stk

library.import

; ---   *   ---   *   ---
; GBL

RAMSEG

reg.new alloc.tab

  my .l0 dq $00
  my .l1 dq $00
  my .l2 dq $00
  my .l3 dq $00

  my .l4 dq $00
  my .l5 dq $00
  my .l6 dq $00
  my .l7 dq $00

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
  my .ptr  dq $00
  my .mask dq $00
  my .pos  dq $00

  my .out  dq $00

reg.end

; ---   *   ---   *   ---
; how free knows a block

reg.new alloc.head

  my .elem dq $00

  my .pos  dw $00
  my .req  dw $00

reg.end

; ---   *   ---   *   ---
; cstruc

EXESEG

proc.new alloc.crux

proc.lis alloc.tab self alloc.main
proc.stk alloc.req ctx

  proc.enter

  ; load struc addr
  lea r11,[@ctx]

  ; ^clear search
  mov qword [@ctx.ptr],$00


  ; get N lines taken
  add rdi,sizeof.alloc.head
  mov qword [@ctx.req],rdi

  ; fetch block
  call alloc.get_stab
  call alloc.get_blk

  ; ^save tmp
  mov qword [@ctx.out],rax


  ; write block header
  push rax
  mov  rdi,rax

  call alloc.write_head

  ; reset out
  pop rax
  add rax,sizeof.alloc.head


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^resize

proc.new alloc.realloc

proc.stk qword dst
proc.stk qword addr
proc.stk qword new_size
proc.stk qword old_size

  proc.enter

  ; save tmp
  mov qword [@addr],rdi
  mov qword [@new_size],rsi

  ; mark old block as fred
  call alloc.free
  mov  qword [@old_size],rax

  ; ^extend/get new block
  mov  rdi,qword [@new_size]

  call alloc.crux
  mov  qword [@dst],rax

  ; ^check addr changed
  mov rdi,rax
  mov rsi,qword [@addr]

  cmp rdi,rsi
  je  .skip

  ; ^copy contents if so
  mov  rdx,qword [@old_size]
  call alloc.memcpy


  ; cleanup and give
  .skip:
    mov rax,qword [@dst]

  proc.leave
  ret

; ---   *   ---   *   ---
; ^dstruc

proc.new alloc.free
proc.cpr rbx

proc.lis alloc.tab  self alloc.main
proc.stk alloc.req  ctx
proc.arg alloc.head head rdi

  proc.enter

  ; load struc addr
  lea  r11,[@ctx]

  ; ^save tmp
  mov qword [@ctx.out],@head

  ; ^seek to head
  sub @head,sizeof.alloc.head


  ; get size scaled up
  xor rax,rax
  mov ax,word [@head.req]
  shl rax,$06

  ; ^get [elem,lvl]
  mov rbx,qword [@head.elem]
  mov rsi,qword [rbx+alloc.chain.lvl]

  ; ^map block size to bitmask
  push rax
  push rsi
  push @head

  mov  rdi,rax

  call mpart.qmask


  ; ^mark chunks as free
  pop @head
  mov cx,word [@head.pos]

  shl rax,cl
  not rax

  and qword [rbx+alloc.chain.mask],rax

  ; ^update space counters
  pop rcx
  pop rax

  add cl,$06
  shr rax,cl

  add qword [rbx+alloc.chain.avail],rax
  shl rax,cl


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; write N bytes from B to A

proc.new alloc.memcpy

  proc.enter

  ; see if bytes left
  .chk_size:
    or rdx,$00
    jz .skip

  ; ^write line-sized chunks
  .cpy:

    ; read [src,src+$40]
    movdqa xmm0,xword [rsi+$00]
    movdqa xmm1,xword [rsi+$10]
    movdqa xmm2,xword [rsi+$20]
    movdqa xmm3,xword [rsi+$30]

    ; ^write to [dst,dst+$40]
    movdqa xword [rdi+$00],xmm0
    movdqa xword [rdi+$10],xmm1
    movdqa xword [rdi+$20],xmm2
    movdqa xword [rdi+$30],xmm3

    ; go next chunk
    sub rdx,$40
    add rdi,$40
    add rsi,$40

    jmp .chk_size


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; set block header, used for free

proc.new alloc.write_head

proc.arg alloc.req  ctx  r11
proc.arg alloc.head head rdi

  proc.enter

  ; get [pos,size]
  mov eax,dword [@ctx.req]
  mov cx,word [@ctx.pos]

  ; scale down size
  shr eax,$06

  ; ^write [pos,size]
  mov word [@head.req],ax
  mov word [@head.pos],cx

  ; ^write elem
  mov rdx,qword [@ctx.elem]
  mov qword [@head.elem],rdx


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
; get next element in table

proc.new alloc.get_stab_top
proc.arg alloc.req ctx r11

  proc.enter

  ; load O
  mov rdi,qword [@ctx.stab]

  ; get elem at top-offset
  mov rsi,qword [rdi+stk.top]
  shr rsi,1
  dec rsi

  mov rdx,qword [@ctx.ptr]
  inc qword [@ctx.ptr]


  ; end search on X < offset
  cmp rdx,rsi
  jg  .exhaust

  sub rsi,rdx
  jmp .found


  ; inviable, reset to top
  .exhaust:
    inc rsi
    jmp .fetch

  ; viable idex, cap at 0
  .found:
    xor   rdx,rdx
    cmp   rsi,$00
    cmovl rsi,rdx


  ; ^get elem at idex
  .fetch:
    shl  rsi,1
    call stk.view


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; give N bytes

proc.new alloc.get_blk

proc.lis alloc.tab self alloc.main
proc.arg alloc.req ctx  r11

  proc.enter

  ; search stab for elem
  .get_next:

    call alloc.get_stab_top

    ; ^zero chk
    mov qword [@ctx.elem],rax
    mov rax,qword [rax+alloc.chain.buff]
    or  rax,$00

    jnz .fit_mem


  ; ^make new entry
  .get_mem:

    ; save reference to entry
    call alloc.new_blk
    mov  qword [@ctx.elem],rax


  ; ^reuse existing
  .fit_mem:

    ; get requested will fit
    call alloc.blk_fit

    or   rax,$00
    jz   .get_next

    ; ^update on success
    call alloc.update_blk


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
; get [pos,mask] for putting
; requested block in stab elem

proc.new alloc.blk_fit
proc.arg alloc.req ctx r11

  proc.enter

  ; map block size to bitmask
  mov  rdi,qword [@ctx.req]
  mov  rsi,qword [@ctx.lvl]

  call mpart.qmask

  ; ^save tmp
  mov qword [@ctx.mask],rax


  ; fit mask in block
  mov  rdi,rax
  mov  rax,qword [@ctx.elem]
  mov  rsi,qword [rax+alloc.chain.mask]

  call mpart.fit

  ; ^fail on X > 63
  xor    rbx,rbx
  cmp    rax,$3F

  cmovge rdi,rbx


  ; ^adjust mask
  mov rcx,rax
  shl rdi,cl

  ; save tmp and give updated mask
  mov qword [@ctx.pos],rax
  mov rax,rdi


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; modify entry

proc.new alloc.update_blk

proc.arg alloc.req ctx r11
proc.cpr rbx

  proc.enter

  ; get block level
  mov rcx,qword [@ctx.lvl]

  ; ^get block offset
  mov rbx,qword [@ctx.pos]

  ; ^get size scaled down
  mov rsi,qword [@ctx.req]
  add rcx,6
  shr rsi,cl


  ; ^overwrite old values
  mov rax,qword [@ctx.elem]
  or  qword [rax+alloc.chain.mask],rdi
  sub qword [rax+alloc.chain.avail],rsi

  ; TODO: calc max alloc for block

  mov qword [@ctx.pos],rdx

  ; set out to base+(offset*scale)
  mov rax,qword [rax+alloc.chain.buff]
  shl rdx,cl
  add rax,rdx


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
; dstruc, called by exit

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
