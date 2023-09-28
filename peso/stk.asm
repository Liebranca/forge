; ---   *   ---   *   ---
; PESO STK
; first in, last out
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; deps

if ~ loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'
  use '.asm' peso::page
  use '.inc' peso::proc

import

; ---   *   ---   *   ---
; info

  TITLE     peso.stk

  VERSION   v0.00.5b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; decl

reg.new stk
  my .top  dq $00
  my .size dq $00

reg.end

; ---   *   ---   *   ---
; ^cstruc

unit.salign r,x


proc.new stk.new
proc.arg qword bsize  rdi
proc.lis qword p2size rsi
proc.lis stk   self   rax

macro stk.new.inline {

  proc.enter

  ; get hed+buff mem
  add  @bsize,sizeof.stk
  call page.new

  ; ^nit hed
  shr @p2size,sizep2.page

  mov qword [@self.size],@p2size
  mov qword [@self.top],$00

  proc.leave

}

  ; ^invoke
  inline stk.new
  ret


; ---   *   ---   *   ---
; ^dstruc

proc.new stk.del
proc.arg stk self rdi

macro stk.del.inline {

  proc.enter

  ; [0] rdi is base addr
  ; so load just the size
  xor rsi,rsi
  mov rsi,qword [@self.size]

  ; ^free
  call page.free
  proc.leave

}

  ; ^invoke
  inline stk.del
  ret

; ---   *   ---   *   ---
; get buff at base+hed
; then get offset

macro stk.get_base {
  xor rbx,rbx
  lea rax,[rdi+sizeof.stk]
  mov rbx,qword [rdi+stk.top]

}

; ---   *   ---   *   ---
; signature template

macro stk.sigt.push {

  proc.arg stk   self rdi
  proc.arg qword step rsi

  proc.lis qword out  rax
  proc.lis qword top  rbx

}

; ---   *   ---   *   ---
; grow stack

proc.new stk.push
stk.sigt.push

  proc.enter
  stk.get_base

@out

  ; ^get base+hed+offset
  shl @top,sizep2.unit
  lea @out,[@out+@top]

  ; ^reset top
  shr @top,sizep2.unit
  add @top,@step

  mov qword [@self.top],@top


  proc.leave
  ret

; ---   *   ---   *   ---
; ^undo

proc.new stk.pop
stk.sigt.push

  proc.enter
  stk.get_base

  ; ^reset top
  sub @top,@step
  mov qword [@self.top],@step

  ; ^read base+hed+offset
  shl @step,sizep2.unit
  lea @out,[@out+@step]


  proc.leave
  ret


; ---   *   ---   *   ---
; get elem at idex

proc.new stk.view

proc.arg stk   self rdi
proc.arg qword idex rsi

macro stk.view.inline {

  proc.enter

  ; scale up idex to unit
  shl @idex,sizep2.unit

  ; ^get base+offset
  lea rax,[@self+sizeof.stk+@idex]

  proc.leave

}

  ; ^invoke
  inline stk.view
  ret


; ---   *   ---   *   ---
