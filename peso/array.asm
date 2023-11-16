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
  use '.hed' peso::alloc

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.array

  VERSION   v0.00.9b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; header struc

reg.new array.head,public

  my .buff  dq $00

  my .grow  dd $00
  my .ezy   dd $00

  my .cap   dd $00
  my .top   dd $00

reg.end

; ---   *   ---   *   ---
; cstruc

EXESEG

proc.new array.new,public
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
  push rax
  mov  rdi,sizeof.array.head

  call alloc
  mov  @self,rax


  ; make buffer
  pop  rdi
  call alloc

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


  ; reset out
  mov rax,@self

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^dstruc

proc.new array.del,public
proc.lis array.head self rdi

  proc.enter

  ; release buffer
  push @self
  mov  rdi,qword [@self.buff]

  call free

  ; ^then wraps
  pop  @self
  call free


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; set value + increase top

macro array.insert_proto dst {

  push @self

  mov  r8d,dword [@self.ezy]
  mov  rdi,dst
  xor  r10w,r10w

  call memcpy

  ; ^grow by elem size
  pop @self

  mov eax,dword [@self.ezy]
  add dword [@self.top],eax

}

; ---   *   ---   *   ---
; conditionally resize array

proc.new array.resize_chk,public
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
  push @self
  mov  rdi,qword [@self.buff]
  mov  rsi,rcx

  call realloc

  ; ^save new addr
  pop @self
  mov qword [@self.buff],rax


  ; get new cap
  push @self
  mov  rdi,rax

  call alloc.get_blk_size

  ; ^store
  pop @self
  mov dword [@self.cap],eax


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; ensure array is big enough
; to hold new elem

macro array.grow_proto {

  push rsi
  mov  esi,dword [@self.ezy]

  call array.resize_chk

  pop  rsi

}

; ---   *   ---   *   ---
; push without insert

proc.new array.grow,public
proc.lis array.head self rdi

  proc.enter
  array.grow_proto

  ; get [base,elem size,end]
  mov rax,qword [@self.buff]
  mov ecx,dword [@self.ezy]
  mov edx,dword [@self.top]

  ; ^set out to new,grow end
  add rax,rdx
  add dword [@self.top],ecx


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; add element at end

proc.new array.push,public
proc.cpr rbx

proc.lis array.head self rdi

  proc.enter
  array.grow_proto

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

proc.new array.pop,public
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
  mov  r8d,dword [@self.ezy]
  mov  rdi,rsi
  mov  rsi,rax

  call array.get


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; generic get array[N]

proc.new array.get,public

  proc.enter

  ; make table
  hybtab .tab,byte,\
    $00 => .get_byte,\
    $01 => .get_word,\
    $02 => .get_dword,\
    $03 => .get_qword,\
    $04 => .get_struc

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
  ret

; ---   *   ---   *   ---
; add element at beg

proc.new array.unshift,public
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

proc.new array.shr,public
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

  ; ^grow
  mov  r10w,smX.CDEREF
  call memcpy


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; remove element at beg

proc.new array.shift,public
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

proc.new array.shl,public
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

  ; ^shrink
  mov  r10w,smX.CDEREF
  call memcpy


  proc.leave
  ret

; ---   *   ---   *   ---
