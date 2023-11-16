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

library ARPATH '/forge/'
  use '.inc' peso::proc

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.stk

  VERSION   v0.00.5b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; decl

reg.new stk,public
  my .top  dq $00
  my .size dq $00

reg.end

; ---   *   ---   *   ---
; std siggy for new block

macro alloc.sigt.new type& {

  proc.arg qword bsize  rdi
  proc.lis qword p2size rsi

  ; conditionally alias rax
  match any,type \{
    proc.lis type  self   rax

  \}

}

; ---   *   ---   *   ---
; get buff at base+hed
; then get offset

macro stk.get_base {
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

EXESEG

proc.new stk.push,public
stk.sigt.push

  proc.enter
  stk.get_base

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

proc.new stk.pop,public
stk.sigt.push

  proc.enter
  stk.get_base

  ; ^reset top
  sub @top,@step
  mov qword [@self.top],@top

  ; ^get base+hed+offset
  shl @top,sizep2.unit
  lea @out,[@out+@top]


  proc.leave
  ret


; ---   *   ---   *   ---
; get elem at idex

proc.new stk.view,public

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
; ^get top of stack

proc.new stk.view_top,public

proc.arg stk   self rdi
proc.lis qword idex rsi

macro stk.view_top.inline {

  proc.enter

  ; scale up idex to unit
  mov @idex,[@self.top]
  shl @idex,sizep2.unit

  ; ^get base+offset
  lea rax,[@self+sizeof.stk+@idex]

  proc.leave

}

  ; ^invoke
  inline stk.view_top
  ret


; ---   *   ---   *   ---
