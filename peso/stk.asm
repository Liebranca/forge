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

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'
  use '.asm' peso::page
  use '.inc' peso::proc

import

; ---   *   ---   *   ---
; info

  TITLE     peso.stk

  VERSION   v0.00.4b
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

proc.new inline stk.new

  ; get hed+buff mem
  add  rdi,sizeof.stk
  call page.new

  ; ^nit hed
  shr rsi,sizep2.page

  mov qword [rax+stk.size],rsi
  mov qword [rax+stk.top],$00


proc.end


; ---   *   ---   *   ---
; ^dstruc

proc.new inline stk.del

  ; [0] rdi is base addr
  ; so load just the size
  xor rsi,rsi
  mov esi,dword [rdi+stk.size]

  ; ^free
  call page.free


proc.end

; ---   *   ---   *   ---
; get buff at base+hed
; then get offset

macro stk.get_base {
  xor rbx,rbx
  lea rax,[rdi+sizeof.stk]
  mov ebx,dword [rdi+stk.top]

}

; ---   *   ---   *   ---
; grow stack

proc.new stk.push

  stk.get_base

  ; ^get base+hed+offset
  shl rbx,4
  lea rax,[rax+rbx]

  ; ^reset top
  shr rbx,4
  add ebx,esi
  mov dword [rdi+stk.top],ebx


proc.end

; ---   *   ---   *   ---
; ^undo

proc.new stk.pop

  stk.get_base

  ; ^reset top
  sub ebx,esi
  mov dword [rdi+stk.top],ebx

  ; ^read base+hed+offset
  shl rbx,4
  lea rax,[rax+rbx]


proc.end


; ---   *   ---   *   ---
; get elem at idex

proc.new inline stk.view

  ; scale up idex to unit
  shl rsi,4

  ; ^get base+offset
  lea rax,[rdi+sizeof.stk]


proc.end


; ---   *   ---   *   ---
