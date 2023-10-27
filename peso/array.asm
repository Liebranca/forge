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

  VERSION   v0.00.6b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; header struc

reg.new array.head

  my .buff  dq $00

  my .grow  dd $00
  my .mode  dd $00

  my .ezy   dd $00
  my .cap   dd $00

  my .top   dd $00

reg.end

; ---   *   ---   *   ---
; cstruc

EXESEG

proc.new array.new
proc.cpr rbx

proc.lis array.head self rbx

  proc.enter

  ; save tmp
  push rdi
  push rsi

  ; get ezy * cap
  mov  rax,rdi
  imul rsi

  ; make wrapper
  push  rax

  alloc sizeof.array.head
  mov   @self,rax


  ; make buffer
  pop   rsi
  alloc rsi

  ; restore tmp
  pop rsi
  pop rdi

  ; ^store
  mov qword [@self.buff],rax
  mov dword [@self.ezy],edi
  mov dword [@self.top],$00


  ; get buff capacity
  mov  rdi,rax
  call alloc.get_blk_size

  ; ^store
  mov dword [@self.cap],eax
  mov dword [@self.grow],eax


  ; get idex for generic ops
  mov  r8d,dword [@self.ezy]
  call smX.get_size

  ; ^store
  mov dword [@self.mode],edx


  ; reset out
  mov rax,@self

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^dstruc

proc.new array.del
proc.lis array.head self rdi

  proc.enter

  ; release buffer
  push @self
  free qword [@self.buff]

  ; ^then wraps
  pop  @self
  free @self


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; set value + increase top

macro array.insert_proto dst {

  push @self

  mov  edx,dword [@self.mode]
  mov  r8d,dword [@self.ezy]
  mov  rdi,dst
  xor  r10w,r10w

  call memcpy.direct

  ; ^grow by elem size
  pop @self

  mov eax,dword [@self.ezy]
  add dword [@self.top],eax

}

; ---   *   ---   *   ---
; conditionally resize array

proc.new array.resize_chk
proc.cpr rbx

proc.lis array.head self rdi

  proc.enter

  ; get top,cap
  mov ecx,dword [@self.top]
  mov eax,dword [@self.cap]

  ; ^skip on top+req < cap
  add ecx,esi
  cmp ecx,eax

  jle .skip


  ; get [N*cstep] growth rate
  mov ebx,dword [@self.grow]

  ; ^add until req fits
  .grow:

    add ecx,ebx
    cmp ecx,esi

    jl  .grow


  ; resize
  push    @self
  mov     rax,qword [@self.buff]

  realloc rax,rbx

  ; ^save new addr
  pop @self
  mov qword [@self.buff],rax


  ; get new cap
  push @self
  mov  rdi,rax

  call alloc.get_blk_size

  ; ^store
  pop @self
  mov qword [@self.cap],rax


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; add element at end

proc.new array.push
proc.cpr rbx

proc.lis array.head self rdi

  proc.enter

  ; get bounds
  push rsi
  mov  esi,dword [@self.ezy]

  call array.resize_chk

  pop  rsi


  ; get buff
  mov rbx,qword [@self.buff]

  ; ^get top
  mov eax,dword [@self.top]
  lea rax,[rbx+rax]

  ; add elem and grow top
  array.insert_proto rax


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; remove at end

proc.new array.pop
proc.cpr rbx

proc.lis array.head self rdi

  proc.enter

  ; get buff
  mov rbx,qword [@self.buff]


  ; adjust top
  mov eax,dword [@self.ezy]
  sub dword [@self.top],eax

  ; ^get top
  mov eax,dword [@self.top]
  lea rax,[rbx+rax]

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
    call memcpy.struc
    ret


  ; cleanup
  proc.leave

; ---   *   ---   *   ---
; add element at beg

proc.new array.unshift
proc.cpr rbx

proc.lis array.head self rdi

  proc.enter

  ; get bounds
  push rsi
  mov  esi,dword [@self.ezy]

  call array.resize_chk


  ; save tmp
  push @self

  ; ^copy bytes N places right
  mov  r8d,dword [@self.ezy]
  call array.shr


  ; restore tmp
  pop @self
  pop rsi

  ; ^write to beg
  array.insert_proto qword [@self.buff]


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^reverse walk copy

proc.new array.shr
proc.cpr rdi

proc.lis array.head self rdi

  proc.enter

  ; size of other is shift size
  ; own top is copy size
  mov esi,r8d
  mov r8d,dword [@self.top]

  ; get beg,beg+N
  mov rdi,qword [@self.buff]
  lea rsi,[rdi+rsi]


  ; dst eq beg+N
  ; src eq beg
  xchg rdi,rsi

  ; ^make space from beg to beg+N
  .iter:

    ; ^copy this chunk
    mov  r10w,smX.CDEREF
    call memcpy

    ; go next
    or r8d,$00
    jg .iter


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; remove element at beg

proc.new array.shift
proc.cpr rbx

proc.lis array.head self rdi

  proc.enter

  ; get bot
  mov rax,qword [@self.buff]

  ; save tmp
  push @self
  push rax


  ; adjust top
  mov r8d,dword [@self.ezy]
  sub dword [@self.top],r8d

  ; read beg
  mov  edx,dword [@self.mode]
  mov  rdi,rsi
  mov  rsi,rax

  call array.get

  ; ^restore tmp
  pop rbx
  pop @self


  ; save prim out
  push rax

  ; JIC clear
  xor rdx,rdx
  xor r8,r8
  xor r9,r9

  ; get [N,beg,mode]
  mov r8d,dword [@self.ezy]
  mov r9d,dword [@self.top]
  mov edx,dword [@self.mode]

  ; ^get [beg,beg+N]
  mov rsi,rbx
  add rsi,r8

  mov rdi,rbx

  ; ^copy bytes N places left
  call array.shl


  ; reset out
  pop rax

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^forward walk copy

proc.new array.shl

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
    rol rax,cl

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
    call memcpy.struc

    ; ^restore
    pop r8
    pop rsi
    pop rdi

    ; go next
    add rdi,r9
    add rsi,r9
    sub r9d,r8d

    ; end on beg reached
    or r9d,$00
    jg .loop_struc

  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
