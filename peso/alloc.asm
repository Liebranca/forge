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

  VERSION   v0.01.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  alloc.sentinel=$DE74

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


  my .hash_bits dq $00
  my .dbout     dq $00

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
; cstruc

unit.salign r,x

proc.new alloc.crux

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


  ; get slot in hashtab
  mov  rdi,rax
  mov  rsi,$01

  call alloc.hash_entry

  ; ^generate meta
  push rax
  call alloc.encode_meta

  ; ^write
  pop rbx
  mov qword [rbx+$08],rax

  ; reset out
  mov rax,qword [@ctx.out]


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

proc.lis alloc.tab self alloc.main
proc.stk alloc.req ctx

  proc.enter

  ; load struc addr
  lea  r11,[@ctx]

  ; ^save tmp
  mov qword [@ctx.out],rdi


  ; get slot in hashtable
  mov  rsi,alloc.sentinel
  call alloc.hash_entry

  ; ^read meta
  mov  rdi,rax
  call alloc.decode_meta


  ; get [size,lvl]
  mov  rdi,qword [@ctx.req]
  mov  rcx,qword [@ctx.lvl]

  ; ^scale up size
  add  rcx,6
  shl  rdi,cl

  push rdi
  push rcx

  ; ^map block size to bitmask
  sub  rcx,6
  mov  rsi,rcx

  call mpart.qmask


  ; ^mark chunks as free
  mov rcx,qword [@ctx.pos]
  mov rbx,qword [@ctx.elem]

  shl rax,cl
  not rax

  and qword [rbx+alloc.chain.mask],rax

  ; ^update space counters
  pop rcx
  pop rax
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
; make hashtab elem

proc.new alloc.encode_meta

proc.arg alloc.req ctx r11
proc.cpr rbx

  proc.enter

  ; get stab N
  mov rcx,qword [@ctx.lvl]
  add rcx,$06

  ; ^get size scaled down
  mov rax,qword [@ctx.req]
  shr rax,cl

  ; ^size at $19
  shl rax,$03

  ; ^lvl at $16
  sub rcx,$06
  or  rax,rcx

  ; ^pos at $10
  shl rax,$06
  or  rax,qword [@ctx.pos]


  ; get idex of elem
  mov rbx,qword [@ctx.stab]
  mov rcx,qword [@ctx.elem]

  ; ^(end-base) eq addr
  sub rcx,rbx
  sub rcx,sizeof.stk

  ; ^addr scaled down eq idex
  shr rcx,$05

  ; ^idex at $00
  shl rax,$10
  or  rax,rcx


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^retrieve

proc.new alloc.decode_meta

proc.lis alloc.tab self alloc.main
proc.arg alloc.req ctx  r11

  proc.enter


  ; fetch values
  mov rax,qword [rdi+$08]

  ; ^elem idex
  mov qword [@ctx.elem],rax
  and qword [@ctx.elem],$FFFF
  shr rax,$10

  ; ^block pos
  mov qword [@ctx.pos],rax
  and qword [@ctx.pos],$3F
  shr rax,$06

  ; ^block lvl
  mov qword [@ctx.lvl],rax
  and qword [@ctx.lvl],$07
  shr rax,$03

  ; ^block size
  mov qword [@ctx.req],rax
  and qword [@ctx.req],$07


  ; get stab
  mov rax,qword [@ctx.lvl]

  lea rax,[@self.l0+rax*8]
  mov rax,qword [rax]

  ; ^save tmp
  mov qword [@ctx.stab],rax


  ; get elem idex
  mov rbx,rax
  mov rax,qword [@ctx.elem]

  ; scale up + skip header
  shl rax,$05
  lea rax,[rbx+sizeof.stk]

  ; ^save tmp
  mov qword [@ctx.elem],rax


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; map blk addr to idex

proc.new alloc.hash_blk
proc.lis alloc.tab self alloc.main

  proc.enter

  push rdi

  mov  rdx,qword [@self.hash_bits]
  lea  rsi,[$08+rdx]
  lea  rdx,[$09+rdx]
  mov  rcx,$04
  sub  rcx,rdx
  and  rcx,$07

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


    lea  rdi,[alloc.dbout_01]
    lea  rdi,[rdi+alloc.dbout_01.length-2]

    mov  rsi,r15
    call alloc._dbout

    constr.sow alloc.dbout_01
    call reap


  ; END SCRATCH

  pop rax


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
    call alloc.update_blk


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; save allocated block to
; hashtable

proc.new alloc.hash_entry

proc.lis alloc.tab self alloc.main
proc.stk qword     id

  proc.enter

  ; save tmp
  push rsi
  mov  qword [@id],rdi


  ; get idex for hash
  .hash_beg:
    call alloc.hash_blk
    pop  rsi


  ; reset counter
  xor r8,r8

  ; check for collision
  .hash_retry:

    ; get table and idex+offset
    mov rbx,qword [@self.lX]
    lea rdx,[rax+r8]

    ; ^clamp idex
    mov rcx,$08
    add rcx,qword [@self.hash_bits]

    mov rdi,$01
    shl rdi,cl
    dec rdi

    ; ^scale up
    and rdx,rdi
    shl rdx,$04


    ; no entry at this position
    mov rcx,qword [rbx+rdx]
    or  rcx,$00
    jz  .hash_ok

    ; existing entry, check id
    cmp rcx,qword [@id]
    je  .hash_ok

    ; ^skip to sentinel handler
    cmp rcx,alloc.sentinel
    je  .hash_sentinel

    ; ^skip to collision handler
    jmp .hash_col


  ; ^keep sentinels on search
  ; but skip on insert
  .hash_sentinel:
    cmp rsi,alloc.sentinel
    jne .hash_ok


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
    cmp    rsi,alloc.sentinel
    cmovne rsi,rcx

    ; ^write to table
    lea rax,[rbx+rdx]
    mov qword [rax],rsi

    jmp .skip


  ; ^errme
  .throw:

    ; resize table if allowed
    if alloc.hash_dynamic

      push rsi
      call alloc.hashtab_resize

      pop  rsi
      jmp  .hash_beg

    ; ^else abort
    else

      constr.new alloc.throw_hashcol,\
        "Unsolvable collision. Total blocks: ",\
        " 0000000000000000",$0A

      lea  rdi,[alloc.throw_hashcol]
      lea  rdi,[rdi+alloc.throw_hashcol.length-2]

      mov  rsi,qword [@self.dbout]
      call alloc._dbout

      constr.errout alloc.throw_hashcol,FATAL

    end if


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
; cstruc

proc.new alloc.new
proc.lis alloc.tab self alloc.main

  proc.enter

  ; renit chk
  mov rax,qword [@self.lX]

  or  rax,$00
  jnz .throw


  ; get (1 << hash bits) pages
  mov  rdi,sizeof.page
  shl  rdi,alloc.hash_bits

  call page.new
  mov  qword [@self.hash_bits],alloc.hash_bits

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
; ^resize

proc.new alloc.hashtab_resize

proc.lis alloc.tab self alloc.main
proc.stk qword     old

  proc.enter

  ; save tmp
  mov rax,qword [@self.lX]
  mov qword [@old],rax

  ; get bigger buff
  inc  qword [@self.hash_bits]
  mov  rdi,sizeof.page
  mov  rcx,qword [@self.hash_bits]
  shl  rdi,cl

  call page.new
  mov  qword [@self.lX],rax


  ; rehash whole table (!!)
  mov  rdi,rax
  call alloc.hashtab_rehash

  ; ^free previous
  mov  rdi,qword [@old]
  mov  rcx,qword [@self.hash_bits]
  mov  rsi,1
  shl  rsi,cl

  call page.free


  ; reset out
  mov rax,qword [@self.lX]

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^reallocs block headers

proc.new alloc.hashtab_rehash

proc.lis alloc.tab self alloc.main

proc.stk qword src
proc.stk qword cnt

  proc.enter

  ; save tmp
  mov qword [@src],rdi

  ; get total size
  mov rdx,sizeof.page
  mov rcx,qword [@self.hash_bits]
  dec rcx
  shl rdx,cl

  mov qword [@cnt],rdx

  ; ^get remain
  .chk_size:
    or qword [@cnt],$00
    jz .skip

  ; ^realloc block meta
  .cpy:

    ; get addr
    mov rax,qword [@src]
    mov rax,qword [rax]

    ; do nothing if zero or sentinel
    cmp rax,alloc.sentinel

    jl  .go_next
    je  .go_next


    ; else rehash
    mov  rdi,rax
    mov  rsi,$01

    call alloc.hash_entry

    ; ^copy meta
    mov rbx,qword [@src]
    mov rbx,qword [rbx+$08]

    mov qword [rax+$08],rbx


  ; consume
  .go_next:
    add qword [@src],$10
    sub qword [@cnt],$10

    jmp .chk_size


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


  .skip:

    ; free (1 << hash bits) pages
    mov  rdi,qword [@self.lX]
    mov  rcx,qword [@self.hash_bits]
    mov  rsi,1
    shl  rsi,cl

    call page.free


  ; cleanup and give
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
; footer

constr.seg

; ---   *   ---   *   ---
