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
; base cstruc

unit.salign r,x

proc.new alloc
proc.lis alloc.tab self alloc.main

  proc.enter

  ; get N lines taken
  alloc.req.align rdi

  ; ^look for fit
  mov rax,qword [@self.avail]

  or  rax,$00
  jz  ._make_new


  ; ^found, allocate
  mov  rsi,qword [@self.bidex]

  call alloc.fit_seg
  mov rax,qword [@self.avail]
  jmp  ._skip


  ; ^no fit, get mem
  ._make_new:
    call alloc.new_seg


  ; cleanup and give
  ._skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; make new seg

proc.new alloc.new_seg
proc.lis alloc.tab self alloc.main

  proc.enter

  ; get new table entry
  call alloc.tab_push

  ; ^check new entry is larger
  ; than current
  push rcx
  mov  rdi,rax
  mov  rsi,rbx

  call alloc.tab_set_avail

  ; ^make free slot bitmask
  mov  rdi,r10
  call alloc.page_mask

  pop rax


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; get at least N bytes

proc.new alloc.tab_push
proc.lis alloc.tab self alloc.main

  proc.enter

  ; get mem
  push rdi
  call page.new

  pop  r10
  push rsi
  push rax

  ; ^grow table
  mov  rdi,qword [@self.list]
  mov  rsi,$02

  call stk.push

  ; ^save base addr and size
  pop rbx
  pop rdi

  mov qword [rax+$00],rbx
  mov qword [rax+$08],rdi

  sub rdi,r10
  mov rcx,rbx
  mov rbx,rdi


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; rewrite largest block

proc.new alloc.tab_set_avail
proc.lis alloc.tab self alloc.main

  proc.enter

  ; save Q loc and avail
  mov rbx,qword [@self.free]
  mov rcx,qword [rbx+stk.top]

  mov qword [rdi+$10],rcx
  mov qword [rdi+$18],rbx

  ; ^compare new avail to old
  mov rax,qword [@self.avail]

  cmp rsi,rax
  jle .skip

  ; ^reset
  mov qword [@self.avail],rsi
  mov qword [@self.bidex],rcx


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; map occupied lines in
; page to a bitmask

proc.new alloc.page_mask
proc.lis alloc.tab self alloc.main

  proc.enter

  ; get top of Q
  push   rdi
  mov    rdi,qword [@self.free]

  inline stk.view_top

  mov    r9,rax

  ; ^fill out
  xor rdx,rdx
  .top:

    ; map size to bitmask
    pop  rdi
    call alloc.qmask
    mov  rbx,rax

    ; ^write to Q
    mov qword [r9+rdx],rax
    add rdx,$08

    ; ^rept
    sub  rdi,sizeof.page
    push rdi
    cmp  rdi,$00

    jg   .top
    pop  rdi


  ; ^adjust top of Q
  mov    rdi,rdx
  inline unit.urdiv

  mov    rdi,qword [@self.free]
  add    qword [rdi+stk.top],rax


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
; maps requested size to bitmask

proc.new alloc.qmask

  proc.enter

  ; get occupied blocks
  mov rax,rdi
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

  ; get tab and free slots in r8,r9
  push rdi
  mov  rdi,rsi

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
  mov    rsi,rdi
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
    mov  rsi,$02
    call stk.pop

    ; ^free seg
    push rdi

    mov  rdi,qword [rax+$00]
    mov  rsi,qword [rax+$08]
    shr  rdi,sizep2.page

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
