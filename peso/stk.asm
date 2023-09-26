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
  use '.asm' peso::unit
  use '.asm' peso::page

import

; ---   *   ---   *   ---
; info

  TITLE     peso.stk

  VERSION   v0.00.3b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; decl

virtual at $00

stk:

  .top  dd $00
  .size dd $00

  align sizeof.unit
  sizeof.stk=$-stk


end virtual

; ---   *   ---   *   ---
; ^cstruc

segment readable executable
align   sizeof.unit

stk.new:
macro stk.new.inline {

  ; get hed+buff mem
  add  rdi,sizeof.stk
  call page.new

  ; ^nit hed
  shr rsi,sizep2.page

  mov dword [rax+stk.size],esi
  mov dword [rax+stk.top],$00

}

  ; ^invoke
  inline stk.new

  ret


; ---   *   ---   *   ---
; ^dstruc

stk.del:
macro stk.del.inline {

  ; [0] rdi is base addr
  ; so load just the size
  xor rsi,rsi
  mov esi,dword [rdi+stk.size]

  ; ^free
  call page.free

}

  ; ^invoke
  inline stk.del


  ret


; ---   *   ---   *   ---
; grow stack

stk.push:

macro stk.get_base {

  ; get buff at base+hed
  ; then get offset
  xor rbx,rbx
  lea rax,[rdi+sizeof.stk]
  mov ebx,dword [rdi+stk.top]

}

  ; ^invoke
  stk.get_base


  ; ^get base+hed+offset
  shl rbx,4
  lea rax,[rax+rbx]

  ; ^reset top
  shr rbx,4
  add ebx,esi
  mov dword [rdi+stk.top],ebx


  ret

; ---   *   ---   *   ---
; ^undo

stk.pop:

  ; same as previous F
  stk.get_base

  ; ^reset top
  sub ebx,esi
  mov dword [rdi+stk.top],ebx

  ; ^read base+hed+offset
  shl rbx,4
  lea rax,[rax+rbx]


  ret


; ---   *   ---   *   ---
; get elem at idex

stk.view:
macro stk.view.inline {

  ; scale up idex to unit
  shl rsi,4

  ; ^get base+offset
  lea rax,[rdi+sizeof.stk]

}

  ; ^invoke
  inline stk.view


  ret


; ---   *   ---   *   ---
