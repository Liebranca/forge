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

  VERSION   v0.01.0b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; header struc

reg.new array,public

  my .grow  dd $00
  my .igrow dd $00

  my .ezy   dd $00
  my .cnt   dd $00

  my .cap   dd $00
  my .top   dd $00

  my .buff  dq $00

reg.end

; ---   *   ---   *   ---
; cstruc

EXESEG

proc.new array.new,public
proc.cpr rbx

proc.lis array self rbx

proc.stk dword  ezy
proc.stk dword  cnt

proc.stk dword cap
proc.stk qword head

  proc.enter

  ; save tmp
  mov dword [@ezy],edi
  mov dword [@cnt],esi
  mov qword [@head],rdx

  ; get ezy * cnt
  imul rdi,rsi
  mov  dword [@cap],edi


  ; head on stack?
  mov  rax,qword [@head]
  test rax,rax
  jnz  @f

  ; ^nope, get heap
  mov  rdi,sizeof.array
  call alloc

  @@:


  ; ^fill out head struc
  mov @self,rax
  mov edi,dword [@ezy]
  mov esi,dword [@cnt]

  mov dword [@self.ezy],edi
  mov dword [@self.cnt],esi
  mov dword [@self.top],$00

  ; ^make buffer
  mov  edi,dword [@cap]

  call alloc
  mov  qword [@self.buff],rax


  ; get buff capacity
  mov  rdi,rax
  call alloc.get_blk_size

  ; ^store
  mov dword [@self.cap],eax
  mov dword [@self.grow],eax

  ; ^get element-wise grow
  xor rdx,rdx
  mov edi,dword [@self.ezy]
  div edi

  mov dword [@self.igrow],eax


  ; reset out
  mov rax,@self

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^dstruc

proc.new array.del,public
proc.cpr rbx

proc.lis array self rbx
proc.stk byte  dyn

  proc.enter

  ; save tmp
  mov @self,rdi
  mov byte [@dyn],sil

  ; release buffer
  mov  rdi,qword [@self.buff]
  call free


  ; head on stack?
  mov  sil,byte [@dyn]
  test sil,sil
  jnz  @f

  ; ^nope, release
  mov  rdi,@self
  call free

  @@:


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; conditionally resize array

proc.new array.resize_chk,public
proc.lis array self rbx

  proc.enter

  ; get top,cap,ezy
  mov ecx,dword [@self.top]
  mov eax,dword [@self.cap]
  mov esi,dword [@self.ezy]

  ; ^skip on top+req < cap
  add ecx,esi
  cmp ecx,eax

  jle .skip


  ; get [N*cstep] growth rate
  mov edx,dword [@self.grow]

  ; ^add until req fits
  .grow:

    add ecx,edx
    cmp ecx,esi

    jl  .grow


  ; resize and save new addr
  mov  rdi,qword [@self.buff]
  mov  rsi,rcx

  call realloc
  mov  qword [@self.buff],rax


  ; get new cap
  mov  rdi,rax
  call alloc.get_blk_size

  ; ^store
  mov edx,dword [@self.igrow]
  mov dword [@self.cap],eax
  add dword [@self.cnt],edx


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; begof push/unshift

macro array.push_prologue {

  ; save tmp
  mov @self,rdi
  mov qword [@src],rsi

  ; ^boundschk
  call array.resize_chk

}

; ---   *   ---   *   ---
; add elem at end

proc.new array.push,public
proc.cpr rbx,r11

proc.lis array self rbx
proc.stk qword src

  proc.enter
  array.push_prologue

  ; put @ buff+top
  mov  r11,qword [@self.buff]
  mov  edi,dword [@self.top]
  add  rdi,r11
  mov  rsi,qword [@src]

  call array.guts.new_elem


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^add elem at beg

proc.new array.unshift,public
proc.cpr rbx,r11

proc.lis array self rbx
proc.stk qword src

  proc.enter
  array.push_prologue

  ; copy bytes N places right
  mov  r8d,dword [@self.ezy]
  call array.guts.shr

  ; ^put @ buff+0
  mov  rdi,qword [@self.buff]
  mov  rsi,qword [@src]

  call array.guts.new_elem


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; set value + increase top

proc.new array.guts.new_elem,public
proc.lis array self rbx

  proc.enter

  ; copy src
  mov  r8d,dword [@self.ezy]
  xor  r10w,r10w

  call memcpy

  ; ^grow by elem size
  mov eax,dword [@self.ezy]
  add dword [@self.top],eax


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; remove at end

proc.new array.pop,public
proc.cpr rbx,r11

proc.lis array self rbx

  proc.enter

  ; get buff
  mov r11,qword [@self.buff]


  ; adjust top
  mov eax,dword [@self.ezy]
  sub dword [@self.top],eax

  ; ^get top
  mov eax,dword [@self.top]
  add rax,r11

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
; ^reverse walk copy

proc.new array.guts.shr,public
proc.lis array self rbx

  proc.enter

  ; size of other is shift size
  ; own top is copy size
  mov edi,r8d
  mov r8d,dword [@self.top]

  ; get beg,beg+N
  mov rsi,qword [@self.buff]
  lea rdi,[rsi+rdi]


  ; ^shift N bytes to the right
  mov  r10w,smX.CDEREF
  call memcpy


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; remove element at beg

proc.new array.shift,public
proc.cpr rbx

proc.lis array self rdi

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

proc.lis array self rdi

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
