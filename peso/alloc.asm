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
  use '.asm' peso::stk

import

; ---   *   ---   *   ---
; info

  TITLE     peso.alloc

  VERSION   v0.00.5b
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
; ^ctx for alloc request

reg.new alloc.req

  my .stab dq $00
  my .buff dq $00
  my .elem dq $00

  my .req  dq $00
  my .lvl  dq $00

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
  call line.align
  mov  word [@ctx.req],ax

  ; fetch block
  call alloc.get_stab
  call alloc.get_blk


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
  lea rax,[@self.l0+rax*8]


  ; fetch subtable
  mov  rdi,rax
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
  shl   rsi,1
  dec   rsi

  ; ^cap idex at 0
  xor   rdx,rdx
  cmp   rsi,$00
  cmovl rsi,rdx

  call stk.view

  ; ^zero chk
  mov qword [@ctx.elem],rax
  mov rax,qword [rax+stk.top]
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
    pop rbx
    mov rcx,rax
    shl rdi,cl

    ; get size, scaled down
    mov rsi,qword [@ctx.req]
    mov rcx,qword [@ctx.lvl]
    add rcx,6
    shr rsi,cl

    ; update mask and sizes
    add qword [rbx+alloc.chain.mask],rdi
    sub qword [rbx+alloc.chain.avail],rsi

    ; TODO: calc max alloc for block


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
  mov rdx,qword [@ctx.req]

  ; addr && free slots
  mov qword [rax+alloc.chain.buff],rbx
  mov qword [rax+alloc.chain.mask],$00

  ; ^partition order
  mov word [rax+alloc.chain.lvl],cx

  ; ^size, scaled down
  add rcx,6
  shr rdx,cl

  mov word [rax+alloc.chain.avail],dx
  mov word [rax+alloc.chain.max],dx


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; rewrite largest block

proc.new alloc.tab_set_avail
proc.lis alloc.tab self alloc.main

  proc.enter

;  ; save Q loc and avail
;  mov rbx,qword [@self.free]
;  mov rcx,qword [rbx+stk.top]
;
;  mov qword [rdi+$10],rcx
;  mov qword [rdi+$18],rbx
;
;  ; ^compare new avail to old
;  mov rax,qword [@self.avail]
;
;  cmp rsi,rax
;  jle .skip
;
;  ; ^reset
;  mov qword [@self.avail],rsi
;  mov qword [@self.bidex],rcx
;
;
;  ; cleanup and give
;  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; map occupied lines in
; page to a bitmask

proc.new alloc.page_mask
proc.lis alloc.tab self alloc.main

  proc.enter

;  ; get top of Q
;  push   rdi
;  mov    rdi,qword [@self.free]
;
;  inline stk.view_top
;
;  mov    r9,rax
;
;  ; ^fill out
;  xor rdx,rdx
;  .top:
;
;    ; map size to bitmask
;    pop  rdi
;    call alloc.qmask
;    mov  rbx,rax
;
;    ; ^write to Q
;    mov qword [r9+rdx],rax
;    add rdx,$08
;
;    ; ^rept
;    sub  rdi,sizeof.page
;    push rdi
;    cmp  rdi,$00
;
;    jg   .top
;    pop  rdi
;
;
;  ; ^adjust top of Q
;  mov    rdi,rdx
;  inline unit.urdiv
;
;  mov    rdi,qword [@self.free]
;  add    qword [rdi+stk.top],rax


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; recycles block

;proc.new alloc.reuse_seg
;proc.lis alloc.tab self alloc.main
;
;  proc.enter
;
;
;
;  proc.leave
;  ret

; ---   *   ---   *   ---
; look for N sized block

proc.new alloc.fit_seg
proc.lis alloc.tab self alloc.main

  proc.enter

;  ; get tab and free slots in r8,r9
;  push rdi
;  mov  rdi,rsi
;
;  call alloc.rd_tab
;
;  ; map size to bitmask
;  pop  rdi
;  call alloc.qmask
;  mov  rdi,rax
;
;  ; ^find free slot
;  mov  rsi,qword [r9]
;  call alloc.qmask_fit
;
;  ; ^throw fail
;  mov rcx,rax
;  cmp rcx,$3F
;  jle .found
;
;  mov rax,$00
;  jmp .skip
;
;  ; ^else overwrite
;  .found:
;    shl rdi,cl
;    add qword [r9],rdi
;
;
;  ; cleanup and give
;  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; idex into table

proc.new alloc.rd_tab
proc.lis alloc.tab self alloc.main

  proc.enter

;  ; get Nth entry in table
;  mov    rsi,rdi
;  shl    rsi,$01
;  mov    rdi,qword [@self.list]
;
;  inline stk.view
;
;  mov    r8,rax
;
;  ; ^get free slots for entry
;  mov    rsi,qword [r8+$10]
;  mov    rdi,qword [@self.free]
;
;  inline stk.view
;
;  mov    r9,rax


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
