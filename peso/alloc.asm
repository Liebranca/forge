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

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

unit.salign r,w

reg.new alloc.tab

  my .base  dq $00
  my .avail dq $00

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

  ; get at least N bytes
  mov  @req,@bsize
  call page.new

  ; ^calculate unused and store
  mov @total,@p2size
  sub @total,@req

  mov qword [@self.avail],@total

  ; get size in units and give
  shr @p2size,sizep2.page


  proc.leave
  ret

; ---   *   ---   *   ---
; ^make new tab entry if needed

proc.new alloc.chktab

proc.lis qword     req  rdi
proc.lis alloc.tab self alloc.main

macro alloc.chktab.inline {

  proc.enter

  ; check current block
  mov rbx,qword [@self.avail]
  cmp rbx,@req
  jge .skip

  ; ^make new

  ; cleanup and give
  .skip:
  proc.leave

}

  ; ^invoke
  inline alloc.chktab
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

  ; TODO: free the table too, of course ;>

  ; load addr
  mov rdi,qword [@self.list]

  ; ^get size
  mov rsi,qword [@self.list]
  mov rsi,qword [rsi+stk.size]
  shl rsi,1

  ; ^free
  call page.free

  proc.leave
  ret

; ---   *   ---   *   ---
