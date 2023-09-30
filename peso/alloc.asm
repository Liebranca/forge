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

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

unit.salign r,w

reg.new alloc.tab

  my .list  dq $00
  my .free  dq $00

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
; make new seg

proc.new alloc.new_seg

proc.arg qword     bsize rdi
proc.lis qword     req   r8
proc.lis alloc.tab self  alloc.main

  proc.enter

  ; get at least N bytes
  push @bsize
  call page.new

  pop  @req
  push rsi
  push rax

  ; pad size to units
  mov    rdi,@req
  inline unit.align

  mov    @req,rax


  ; grow table
  mov  rdi,qword [@self.list]
  mov  rsi,1

  call stk.push

  ; ^save base addr
  pop rbx
  pop @bsize
  mov qword [rax+0],rbx
  mov qword [rax+8],@bsize


  ; get free space
  push   rbx
  cmp   @bsize,@req
  jl    .skip

  ; ^grow table
  push @bsize
  mov  rdi,qword [@self.free]
  mov  rsi,1

  call stk.push

  ; ^save addr of free
  pop  @bsize
  pop  rbx

  add  rbx,@req
  mov  qword [rax+0],rbx
  mov  qword [rax+8],@bsize

  sub  rbx,@req
  push rbx

  ; give addr
  .skip:
    pop rax


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; get avail space in seg

proc.new alloc.chk_seg

proc.arg qword     req   rdi
proc.arg qword     idex  rsi

proc.lis alloc.tab self  alloc.main
proc.lis stk       seg   rbx

  proc.enter

  ; get size in units
  inline unit.align
  mov    @req,rax

  ; idex into seg array
  push   @req

  mov    rdi,qword [@self.list]
  inline stk.view

  ; ^store taken
  pop @req
  mov @seg,rax


  ; get avail
  mov rax,qword [@seg.size]
  mov rcx,qword [@seg.top]

  sub rax,rcx

  ; ^compare avail to requested
  mov   rcx,$00
  cmp   rax,@req
  cmovl rax,rcx


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
  shr rsi,1
  lea rbx,[rax+rsi]
  mov qword [@self.list],rax
  mov qword [@self.free],rbx

  ; ^make partition
  mov qword [rax+stk.top],$00
  mov qword [rbx+stk.top],$00
  mov qword [rax+stk.size],sizeof.page shr 1
  mov qword [rbx+stk.size],sizeof.page shr 1

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

    mov  rdi,qword [rax+0]
    mov  rsi,qword [rax+8]

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
