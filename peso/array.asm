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
  use '.inc' peso::alloc

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.array

  VERSION   v0.00.4b
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

EXESEG

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
; set value + increase top

macro array.insert_proto {

  push @self

  mov  edx,dword [@self.mode]
  mov  r8d,dword [@self.ezy]
  mov  rdi,rax

  call array.set

  ; ^grow by elem size
  pop @self

  mov eax,dword [@self.ezy]
  add dword [@self.top],eax

}

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

  ; add elem and grow top
  array.insert_proto


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; generic set array[N]

proc.new array.set

  proc.enter

  ; make table
  jmptab .tab,byte,\
    .set_byte,.set_word,\
    .set_dword,.set_qword,\
    .set_struc

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

  ; make table
  jmptab .tab,byte,\
    .get_byte,.get_word,\
    .get_dword,.get_qword,\
    .get_struc

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
; add element at beg

proc.new array.unshift
proc.cpr rbx

proc.lis array.head self rdi

  proc.enter

  ; get bot
  mov rax,@self

  ; ^seek to head
  sub @self,sizeof.array.head

  ; save tmp
  push @self
  push rsi
  push rax


  ; JIC clear
  xor  rdx,rdx
  xor  r8,r8
  xor  r9,r9

  ; get [N,end,mode]
  mov  r8d,dword [@self.ezy]
  mov  r9d,dword [@self.top]
  mov  edx,dword [@self.mode]

  ; ^get [end,end-N]
  mov  rsi,rax
  add  rsi,r9
  mov  rbx,rsi
  sub  rbx,r8

  mov  rdi,rbx
  xchg rsi,rdi

  ; ^copy bytes N places right
  call array.shr


  ; restore tmp
  pop rax
  pop rsi
  pop @self

  ; ^write to beg
  array.insert_proto


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^reverse walk copy

proc.new array.shr

  proc.enter

  ; branch on ptr type
  cmp rdx,$04
  je  .loop_struc


  ; get mask size
  mov rax,$01
  mov cl,dl
  shl rax,cl

  mov rcx,rax

  ; get mask
  mov rdx,$01
  shl rcx,$03
  shl rdx,cl
  dec rdx


  .loop_prim:

    ; get first bit
    mov rax,qword [rsi]
    ror rax,cl

    ; ^get next bit
    mov rbx,rax
    shr rbx,cl

    ; ^exclude
    and rbx,rdx
    and rax,rdx

    ; ^copy
    shr rcx,$03
    mov qword [rdi],rbx
    mov qword [rdi+rcx],rax


    ; go next
    sub rdi,rcx
    sub rsi,rcx
    sub r9d,ecx
    shl rcx,$03

    ; end on beg reached
    or  r9d,$00
    jg  .loop_prim
    jmp .skip


  ; struc ptr
  .loop_struc:

    ; save tmp
    push rdi
    push rsi
    push r8

    ; ^copy B to A
    mov  r8d,r9d
    call array.set_struc

    ; ^restore
    pop  r8
    pop  rsi
    pop  rdi

    ; go next
    sub  rdi,r9
    sub  rsi,r9
    sub  r9d,r8d

    ; end on beg reached
    or   r9d,$00
    jg   .loop_struc

  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
