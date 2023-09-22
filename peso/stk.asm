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

;if ~ defined loaded?Imp
;  include '%ARPATH%/forge/Imp.inc'
;
;end if
;
;library ARPATH '/forge/'
;  use '.asm' peso::pages
;
;import

; ---   *   ---   *   ---
; info

  TITLE     peso.stk

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; decl

virtual at $00

stk:

  .top  dd $00
  .size dd $00

  sizeof.stk=$-stk


end virtual

; ---   *   ---   *   ---
; ^cstruc

segment readable executable
align $10

stk.new:

  ; get hed+buff mem
  add  rdi,sizeof.stk
  call pages.new

  ; ^nit hed
  shr rsi,12

  mov dword [rax+stk.size],esi
  mov dword [rax+stk.top],$00


  ret


; ---   *   ---   *   ---
; ^dstruc

stk.del:

  ; [0] rdi is base addr
  ; so load just the size
  xor rsi,rsi
  mov esi,dword [rdi+stk.size]

  ; ^free
  call pages.free


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
  ; write [1] rsi to it
  shl rbx,4
  mov qword [rax+rbx],rsi

  ; ^reset top
  shr rbx,4
  add ebx,1
  mov dword [rdi+stk.top],ebx


  ret

; ---   *   ---   *   ---
; ^undo

stk.pop:

  ; same as previous F
  stk.get_base

  ; ^reset top
  sub ebx,1
  mov dword [rdi+stk.top],ebx

  ; ^read base+hed+offset
  shl rbx,4
  mov rax,[rax+rbx]


  ret


; ---   *   ---   *   ---
; get elem at idex

stk.view:

  ; scale up idex to unit
  shl rsi,4

  ; ^get base+offset
  lea rax,[rdi+sizeof.stk]
  mov rax,qword [rax+rsi]


  ret


; ---   *   ---   *   ---
