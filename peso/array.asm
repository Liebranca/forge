; ---   *   ---   *   ---
; PESO ARRAY
; A barrel of things
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
  use '.inc' peso::alloc_h

import

; ---   *   ---   *   ---
; info

  TITLE     peso.array

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; header struc

reg.new array.head

  my .ezy dd $00
  my .cap dd $00

  my .top dd $00

reg.end

; ---   *   ---   *   ---
; cstruc

unit.salign r,x

proc.new array.new
proc.lis array.head self rax

  proc.enter

  ; save tmp
  push rdi
  push rsi

  ; get ezy * cap
  mov  rax,rdi
  imul rsi
  add  rax,sizeof.array.head

  ; ^make ice
  alloc rsi

  ; restore tmp
  pop rsi
  pop rdi

  ; nit
  mov dword [@self.ezy],edi
  mov dword [@self.cap],esi
  mov dword [@self.top],$00


  ; reset out
  add rax,sizeof.array.head

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^dstruc

proc.new array.del
proc.lis array.head self rdi

  proc.enter

  ; seek to beg
  sub @self,sizeof.array.head

  ; ^release
  free @self


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; add element at end

proc.new array.push
proc.lis array.head self rdi

  proc.enter

  ; seek to beg
  sub @self,sizeof.array.head

  ; ^get top
  xor rax,rax
  mov eax,dword [@self.top]
  lea rax,[rax+@self+sizeof.array.head]

  ; ^set value
  push @self

  mov  edx,dword [@self.ezy]
  mov  rdi,rax

  call array.set

  ; ^grow by elem size
  pop @self

  mov eax,dword [@self.ezy]
  add dword [@self.top],eax


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^generic set

proc.new array.set

  proc.enter

  ; get size is prim
  cmp edx,$10
  jl  .set_prim


  ; struc setter
  .set_struc:
    call array.memcpy
    jmp  .skip


  ; prim setter
  .set_prim:

    ; fork to lower or highest
    cmp edx,sizeof.dword
    jl  .set_word
    jg  .set_qword

    ; ^do and end
    mov dword [rdi],esi
    jmp .skip

  ; ^lower
  .set_word:

    ; fork to lowest
    cmp edx,sizeof.word
    jl  .set_byte

    ; ^do and end
    mov word [rdi],si
    jmp .skip


  ; ^highest, no cmp
  .set_qword:
    mov qword [rdi],rsi
    jmp .skip

  ; ^lowest, no cmp
  .set_byte:
    mov byte [rdi],sil


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; ^deref struc and copy

proc.new array.memcpy

  proc.enter


  ; see if bytes left
  .chk_size:
    or edx,$00
    jz .skip

  ; ^write unit-sized chunks
  .cpy:

    ; read src,write dst
    movdqa xmm0,xword [rsi]
    movdqa xword [rdi],xmm0

    ; go next
    add rdi,$10
    add rsi,$10
    sub edx,$10

    jmp .chk_size


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
