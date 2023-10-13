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

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; header struc

reg.new array.head

  my .mode dd $00

  my .ezy  dd $00
  my .cap  dd $00

  my .top  dd $00

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

  ; ^get idex for generic ops
  push @self
  call array.get_mode

  ; ^set
  mov  edx,eax
  pop  @self

  mov  dword [@self.mode],edx


  ; reset out
  add @self,sizeof.array.head

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^determine id for get-set

proc.new array.get_mode

  proc.enter

  ; size is prim
  cmp edi,$10
  jl  .is_prim


  ; struc setter
  .is_struc:
    mov  eax,$04
    jmp  .skip


  ; prim setter
  .is_prim:

    ; fork to lower or highest
    cmp edi,sizeof.dword
    jl  .is_word
    jg  .is_qword

    ; ^do and end
    mov eax,$02
    jmp .skip

  ; ^lower
  .is_word:

    ; fork to lowest
    cmp edx,sizeof.word
    jl  .is_byte

    ; ^do and end
    mov eax,$01
    jmp .skip


  ; ^highest, no cmp
  .is_qword:
    mov eax,$03
    jmp .skip

  ; ^lowest, no cmp
  .is_byte:
    mov eax,$00


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; ^dstruc

proc.new array.del
proc.lis array.head self rdi

  proc.enter

  ; seek to head
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

  ; seek to head
  sub @self,sizeof.array.head


  ; ^get top
  mov eax,dword [@self.top]
  lea rax,[rax+@self+sizeof.array.head]

  ; ^set value
  push @self

  mov  edx,dword [@self.mode]
  mov  r8d,dword [@self.ezy]
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
; generic set array[N]

proc.new array.set

  proc.enter


  ; load jmp addr
  mov eax,.tab
  mov dl,byte [eax+edx]
  add eax,edx

  jmp rax

  ; ^jmp table
  .tab:

    db .set_byte  - .tab
    db .set_word  - .tab
    db .set_dword - .tab
    db .set_qword - .tab

    db .set_struc - .tab


  ; ^land
  .set_byte:
    mov byte [rdi],sil
    ret

  .set_word:
    mov word [rdi],si
    ret

  .set_dword:
    mov dword [rdi],esi
    ret

  .set_qword:
    mov qword [rdi],rsi
    ret

  .set_struc:
    call array.set_struc
    ret


  ; cleanup
  proc.leave

; ---   *   ---   *   ---
; remove at end

proc.new array.pop
proc.lis array.head self rdi

  proc.enter

  ; seek to head
  sub @self,sizeof.array.head


  ; adjust top
  mov eax,dword [@self.ezy]
  sub dword [@self.top],eax

  ; ^get top
  mov eax,dword [@self.top]
  lea rax,[rax+@self+sizeof.array.head]

  ; ^get value
  mov  edx,dword [@self.mode]
  mov  r8d,dword [@self.ezy]
  mov  rdi,rsi
  mov  rsi,rax

  call array.get


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; generic get array[N]

proc.new array.get

  proc.enter


  ; load jmp addr
  mov eax,.tab
  mov dl,byte [eax+edx]
  add eax,edx

  jmp rax

  ; ^jmp table
  .tab:

    db .get_byte  - .tab
    db .get_word  - .tab
    db .get_dword - .tab
    db .get_qword - .tab

    db .get_struc - .tab


  ; ^land
  .get_byte:
    mov al,byte [rsi]
    ret

  .get_word:
    mov ax,word [rsi]
    ret

  .get_dword:
    mov eax,dword [rsi]
    ret

  .get_qword:
    mov rax,qword [rsi]
    ret

  .get_struc:
    call array.set_struc
    ret


  ; cleanup
  proc.leave

; ---   *   ---   *   ---
; deref struc and copy

proc.new array.set_struc

  proc.enter


  ; see if bytes left
  .chk_size:
    or r8d,$00
    jz .skip

  ; ^write unit-sized chunks
  .cpy:

    ; read src,write dst
    movdqa xmm0,xword [rsi]
    movdqa xword [rdi],xmm0

    ; go next
    add rdi,$10
    add rsi,$10
    sub r8d,$10

    jmp .chk_size


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
