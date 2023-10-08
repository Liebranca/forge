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

  VERSION   v0.00.9b
  AUTHOR    'IBN-3DILA'


  alloc.debug=1

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
  my .dbout dq $00

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

  ; ^clear search
  mov qword [@ctx.ptr],$00


  ; get N lines taken
  mov qword [@ctx.req],rdi

  ; fetch block
  call alloc.get_stab
  call alloc.get_blk

  ; ^save tmp
  mov qword [@ctx.out],rax


  ; get slot in hashtable
  mov  rdi,rax
  mov  rsi,$01
  call alloc.hash_entry

  ; get [size,lvl,pos]
  mov rcx,qword [@ctx.lvl]
  add rcx,6

  mov rbx,qword [@ctx.req]
  shr rbx,cl
  shl rbx,3

  sub rcx,6
  or  rbx,rcx
  shl rbx,6
  or  rbx,qword [@ctx.pos]

  ; get idex of elem
  push rbx

  mov  rbx,qword [@ctx.stab]
  mov  rcx,qword [@ctx.elem]

  sub  rcx,rbx
  sub  rcx,sizeof.stk

  shr  rcx,5
  pop  rbx

  shl  rbx,16
  or   rbx,rcx


  ; ^write meta
  mov qword [rax+$08],rbx

  ; reset out
  mov rax,qword [@ctx.out]


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^dstruc

proc.new free

proc.lis alloc.tab self alloc.main
proc.stk alloc.req ctx

  proc.enter

  ; load struc addr
  lea  r11,[@ctx]

  ; ^save tmp
  mov qword [@ctx.out],rdi


  ; get slot in hashtable
  mov  rsi,$00
  call alloc.hash_entry

  ; ^read meta
  mov  rax,qword [rax+$08]
  push rax

  ; get stab
  shr rax,$16
  and rax,$07

  lea rcx,[rax+6]
  lea rax,[@self.l0+rax*8]
  mov rax,qword [rax]

  ; ^save tmp
  sub rcx,6
  mov qword [@ctx.stab],rax
  mov qword [@ctx.lvl],rcx

  ; get elem
  mov rbx,rax
  pop rax

  mov rdx,rax

  and rdx,$FFFF
  shl rdx,1

  add rdx,sizeof.stk
  add rbx,rdx

  ; ^save
  mov qword [@ctx.elem],rbx

  ; get size and pos
  mov rbx,rax
  mov rdx,rax

  shr rdx,$10
  shr rbx,$19

  and rdx,$3F
  and rbx,$07

  mov qword [@ctx.pos],rdx
  mov qword [@ctx.req],rbx


  ; map block size to bitmask
  mov  rdi,qword [@ctx.req]
  mov  rcx,qword [@ctx.lvl]

  add  rcx,6
  shl  rdi,cl
  sub  rcx,6
  mov  rsi,rcx

  call mpart.qmask

  ; ^mark chunks as free
  mov rcx,qword [@ctx.pos]
  mov rbx,qword [@ctx.elem]

  shl rax,cl
  not rax

  and qword [rbx+alloc.chain.mask],rax


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; map blk addr to idex

proc.new alloc.hash_blk
proc.arg alloc.req ctx r11

  proc.enter

  push  rdi

HASH_BITS=0

  mov   rsi,$08+HASH_BITS
  mov   rdx,$08+HASH_BITS+1
  mov   cl,$4-HASH_BITS

  call hash


  pop  r15
  push rax

  ; SCRATCH

    constr.new alloc.dbout_00,\
      "0000000000000000",$20

    constr.new alloc.dbout_01,\
      "0000000000000000",$0A

    lea  rdi,[alloc.dbout_00]
    lea  rdi,[rdi+alloc.dbout_00.length-2]

    mov  rsi,rax

    call alloc._dbout
    constr.sow alloc.dbout_00


    lea  rdi,[alloc.dbout_00]
    lea  rdi,[rdi+alloc.dbout_00.length-2]

    mov  rsi,r15
    call alloc._dbout


    constr.sow alloc.dbout_00


    lea  rdi,[alloc.dbout_01]
    lea  rdi,[rdi+alloc.dbout_01.length-2]

    mov  rax,qword [@ctx.elem]
    mov  rsi,qword [rax+alloc.chain.mask]

    call alloc._dbout


    constr.sow alloc.dbout_01
    call reap

  ; END SCRATCH

  pop  rax


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
  mov   rsi,qword [rdi+stk.top]
  shr   rsi,1
  dec   rsi

  mov   rdx,qword [@ctx.ptr]
  inc   qword [@ctx.ptr]


  ; end search on X < offset
  cmp   rdx,rsi
  jg    .exhaust

  sub   rsi,rdx
  jmp   .found


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

    ; nevermind this
    if alloc.debug
      constr.new alloc.new_blkme,\
        "____________",$0A,$0A,"NEW BLK",$0A

      constr.sow alloc.new_blkme
      call reap

    end if

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
    call alloc.blk_update


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; save allocated block to
; hashtable

proc.new alloc.hash_entry

proc.lis alloc.tab self alloc.main
proc.arg alloc.req ctx  r11
proc.stk qword     id

  proc.enter


  ; get block id
  push rdi

  mov  rdi,qword [@ctx.out]
  mov  rsi,$20

  call crypt.xorkey

  ; ^save tmp
  mov qword [@id],rax

  ; get idex for hash
  pop  rdi
  call alloc.hash_blk


  ; reset counter
  xor r8,r8

  ; check for collision
  .hash_retry:

    ; get table and idex+offset
    mov rbx,qword [@self.lX]
    lea rdx,[rax+r8]

    ; ^clamp idex
    mov  rcx,$08+HASH_BITS
    mov  rdi,$01
    shl  rdi,cl
    dec  rdi

    ; ^scale up
    and  rdx,rdi
    shl  rdx,$04


    ; no entry at this position
    mov  rcx,qword [rbx+rdx]
    or   rcx,$00
    jz   .hash_ok

    ; existing entry, check id
    cmp  rcx,qword [@id]
    je   .hash_ok


  ; primitive collision handling
  ; we'll try to improve this later
  .hash_col:

    ; nevermind this
    if alloc.debug

      push r8
      push rax

      constr.new alloc.hash_colme,\
        "^COLLIDED",$0A

      constr.sow alloc.hash_colme
      call reap


      pop  rax
      pop  r8

    end if


    ; do up to N retries, else throw
    inc  r8
    cmp  r8,$10

    jl   .hash_retry
    jmp  .throw


  ; ^spot found, stop here
  .hash_ok:

    ; nevermind this
    if alloc.debug
      add qword [@self.dbout],1

    end if

    ; id of block when allocating
    ; clear if freeing
    mov    rcx,qword [@id]
    or     rsi,$00
    cmovnz rsi,rcx

    ; ^write to table
    lea rax,[rbx+rdx]
    mov qword [rax],rsi

    jmp .skip


  ; ^errme
  .throw:

    constr.new alloc.throw_hashcol,\
      "Unsolvable collision. Total blocks: ",\
      " 0000000000000000",$0A

    lea  rdi,[alloc.throw_hashcol]
    lea  rdi,[rdi+alloc.throw_hashcol.length-2]

    mov  rsi,qword [@self.dbout]
    call alloc._dbout

    constr.errout alloc.throw_hashcol,FATAL


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; debug method, nevermind this

proc.new alloc._dbout

  proc.enter

  mov rcx,$00

  .top:

    mov rbx,rsi
    xor dl,dl

    and bl,$0F
    cmp bl,$0A
    jl  .skip

    mov dl,$07


  .skip:

    add bl,$30
    add bl,dl

    mov byte [rdi],bl
    shr rsi,$04

    dec rdi
    inc rcx
    cmp rcx,$10
    jl  .top


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

proc.new alloc.blk_update
proc.arg alloc.req ctx r11

  proc.enter

  ; set block offset
  mov rcx,qword [@ctx.pos]

  ; ^get offset scaled up
  mov rbx,qword [@ctx.req]

  mov rdx,rcx
  shl rdx,sizep2.line

  ; ^get size scaled down
  mov rsi,qword [@ctx.lvl]
  add rcx,6
  shr rsi,cl


  ; ^overwrite old values
  mov rax,qword [@ctx.elem]
  or  qword [rax+alloc.chain.mask],rdi
  sub qword [rax+alloc.chain.avail],rsi

  ; TODO: calc max alloc for block

  mov qword [@ctx.pos],rdx

  ; set out to base+offset
  mov rax,qword [rax+alloc.chain.buff]
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
  shl  rdi,HASH_BITS

  call page.new

  ; ^store
  mov qword [@self.lX],rax


  ; errme
  jmp .skip
  .throw:

    constr.new alloc.throw_renit,\
      "Allocator renit",$0A

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
    mov  rsi,$10

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
