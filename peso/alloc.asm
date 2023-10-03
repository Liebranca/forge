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
  use '.inc' peso::constr
  use '.asm' peso::page
  use '.asm' peso::stk

import

; ---   *   ---   *   ---
; info

  TITLE     peso.alloc

  VERSION   v0.00.3b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

unit.salign r,w

reg.new alloc.tab

  my .list  dq $00
  my .free  dq $00

  my .bidex dq $00
  my .avail dq $00

reg.end

reg.ice alloc.tab alloc.main

; ---   *   ---   *   ---
; base cstruc

unit.salign r,x

proc.new alloc

alloc.sigt.new

proc.lis alloc.tab self  alloc.main
proc.lis qword     req   rbx
proc.lis qword     total rcx

  proc.enter



;  ; ^calculate unused and store
;  mov @total,@p2size
;  sub @total,@req
;
;  mov qword [@self.avail],@total
;
;  ; get size in units and give
;  shr @p2size,sizep2.page


  proc.leave
  ret

; ---   *   ---   *   ---
; ^make new tab entry if needed

proc.new alloc.chktab

proc.lis qword     req  rdi
proc.lis alloc.tab self alloc.main

macro alloc.chktab.inline {

  proc.enter

;  ; check current block
;  mov rbx,qword [@self.avail]
;  cmp rbx,@req
;  jge .skip
;
;  ; ^make new
;
;  ; cleanup and give
;  .skip:
  proc.leave

}

  ; ^invoke
  inline alloc.chktab
  ret

; ---   *   ---   *   ---
; pad size to cache line

macro alloc.req.align dst {

  local ok
  ok equ 1

  ; get value not already in rdi
  match =rdi,dst \{
    ok equ 0

  \}

  match =1,ok \{
    mov rdi,dst

  \}


  ; ^paste in
  dpline line.align
  mov    dst,rax

}

; ---   *   ---   *   ---
; make new seg

proc.new alloc.new_seg

proc.arg qword     bsize rdi
proc.lis qword     req   r8
proc.lis qword     mask  r9
proc.lis alloc.tab self  alloc.main

  proc.enter

  ; get at least N bytes
  push @bsize
  call page.new

  pop  @req
  push rsi
  push rax

  ; get N lines taken
  alloc.req.align @req


  ; grow table
  mov  rdi,qword [@self.list]
  mov  rdx,qword [rdi+stk.top]
  mov  rsi,$02

  call stk.push

  ; ^save base addr and size
  pop  rbx
  pop  @bsize
  mov  qword [rax+$00],rbx
  mov  qword [rax+$08],@bsize

  sub  @bsize,@req

  ; ^save Q loc and avail
  mov rdi,qword [@self.free]
  mov rdx,qword [rdi+stk.top]

  mov qword [rax+$10],rdx
  mov qword [rax+$18],@bsize


  ; ^compare new avail to old
  mov  rax,qword [@self.avail]
  cmp  @bsize,rax
  jle  .skip

  ; ^reset
  mov qword [@self.avail],@bsize
  mov qword [@self.bidex],rdx


  .skip:
  push rbx


  ; get top of Q
  mov    rdi,qword [@self.free]
  inline stk.view_top


  ; ^save alloc mask
  xor rdx,rdx
  .bitmask:

    ; map size to bitmask
    push rax

    mov  rdi,@req

    call alloc.qmask
    mov  @mask,rax

    pop  rax


    ; ^write to Q
    mov qword [rax+rdx],@mask
    add rdx,$08

    ; ^rept
    sub @req,sizeof.page
    cmp @req,$00
    jg  .bitmask


  ; ^adjust top of Q
  mov    rdi,rdx
  inline unit.urdiv

  mov    rdi,qword [@self.free]
  add    qword [rdi+stk.top],rax

  ; give addr
  pop rax


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; maps requested size to bitmask

proc.new alloc.qmask
proc.arg qword req rdi

  proc.enter

  ; get occupied blocks
  mov rax,@req
  shr rax,sizep2.line

  ; ^make bitmask
  lea rcx,[rax-$01]
  mov rbx,$01
  shl rbx,cl
  lea rax,[rbx+rbx-$01]

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; look for N sized block

proc.new alloc.fit_seg
proc.lis alloc.tab self alloc.main

  proc.enter
  alloc.req.align rdi

  ; get tab and free slots in r8,r9
  push rdi
  call alloc.rd_tab

  ; map size to bitmask
  pop  rdi

  call alloc.qmask
  mov  rdi,rax

  ; ^find free slot
  mov  rsi,qword [r9]
  call alloc.qmask_fit

  ; ^throw fail
  mov rcx,rax
  cmp rcx,$3F
  jle .found

  mov rax,$00
  jmp .skip

  ; ^else overwrite
  .found:
    shl rdi,cl
    add qword [r9],rdi


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; idex into table

proc.new alloc.rd_tab
proc.lis alloc.tab self alloc.main

  proc.enter

  ; get Nth entry in table
  shl    rsi,$01
  mov    rdi,qword [@self.list]

  inline stk.view

  mov    r8,rax

  ; ^get free slots for entry
  mov    rsi,qword [r8+$10]
  mov    rdi,qword [@self.free]

  inline stk.view

  mov    r9,rax


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; get N free bits

proc.new alloc.qmask_fit
proc.cpr r8

  proc.enter

  ; reset mask
  xor rcx,rcx
  xor rdx,rdx
  .top:

    ; find first free bit
    not    rsi
    bsf    r8,rsi

    cmovnz rcx,r8

    ; ^shift to start of free space
    not rsi
    shr rsi,cl
    add rdx,rcx

    ; ^compare free to requested
    mov rax,rdi
    and rax,rsi
    jz  .skip


  ; ^get bits to shift if no fit
  .body:

    ; find last occupied bit
    bsr r8,rax
    inc r8
    mov rcx,r8

    ; ^shift it out
    shr rsi,cl
    add rdx,rcx

    jmp .top


  ; ^set out
  .skip:
    mov rax,rdx


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; allocator cstruc

proc.new alloc.new
proc.lis alloc.tab self alloc.main

  proc.enter

  ; ^renit chk
  mov rbx,qword [@self.list]
  or  rbx,$00
  jnz .throw

  ; get one page
  mov  rdi,sizeof.page
  call page.new

  ; ^store base ptrs
  shr rsi,$01
  lea rbx,[rax+rsi]
  mov qword [@self.list],rax
  mov qword [@self.free],rbx

  ; ^make partition
  mov qword [rax+stk.top],$00
  mov qword [rbx+stk.top],$00
  mov qword [rax+stk.size],sizeof.page shr $01
  mov qword [rbx+stk.size],sizeof.page shr $01

  ; errme
  jmp .skip
  .throw:

    constr.new alloc.throw_renit,\
      "FATAL: allocator renit"

    constr.sow alloc.throw_renit
    exit -1


  ; cleanup and give
  .skip:
  proc.leave
  ret


; ---   *   ---   *   ---
; ^dstruc

proc.new alloc.del
proc.lis alloc.tab self alloc.main

  proc.enter

  ; load addr
  mov rdi,qword [@self.list]


  ; get table is empty
  .top:

    mov rsi,qword [@self.list]
    mov rsi,qword [rsi+stk.top]
    or  rsi,$00
    jz  .free

    ; ^pop from table
    mov  rsi,$01
    call stk.pop

    ; ^free seg
    push rdi

    mov  rdi,qword [rax+$00]
    mov  rsi,qword [rax+$08]

    call page.free


    ; ^repeat
    pop rdi
    jmp .top


  ; terminate the allocator itself
  .free:

    mov rsi,rdi
    mov rsi,qword [rdi+stk.size]
    shl rsi,$01

    ; ^free
    call page.free


  ; cleanup
  proc.leave
  ret

; ---   *   ---   *   ---
