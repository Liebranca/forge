; ---   *   ---   *   ---
; PESO CASK
; It's all take and give
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

  TITLE     peso.cask

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; base struc

reg.new cask,public

  my .cnt    dd $00
  my .ezy    dd $00
  my .masksz dd $00
  my .buffsz dd $00

  my .mask dq $00
  my .buff dq $00

reg.end

; ---   *   ---   *   ---
; ^cstruc

EXESEG

proc.new cask.new,public
proc.cpr rbx

proc.lis cask self rbx

proc.stk dword masksz
proc.stk dword buffsz
proc.stk dword cnt
proc.stk dword ezy

  proc.enter

  ; save tmp
  mov  dword [@ezy],edi
  mov  dword [@cnt],esi


  ; get mask size (1/64 elems)
  mov rdi,rsi
  line.urdiv

  mov dword [@masksz],eax

  ; get buffer size (ezy*cnt)
  mov  edi,dword [@ezy]
  imul rdi,rsi

  mov  dword [@buffsz],edi


  ; ^make container
  lea  edi,[edi+sizeof.cask+eax*8]

  call alloc
  mov  @self,rax

  ; ^fill out struc
  mov eax,dword [@cnt]
  mov ecx,dword [@ezy]
  mov edx,dword [@masksz]
  mov r8d,dword [@buffsz]

  mov dword [@self.cnt],eax
  mov dword [@self.ezy],ecx
  mov dword [@self.masksz],edx
  mov dword [@self.buffsz],r8d

  ; ^get ptrs
  lea rax,[@self+sizeof.cask]
  lea rcx,[@self+sizeof.cask+rdx*8]

  mov qword [@self.mask],rax
  mov qword [@self.buff],rcx


  ; reset out
  mov rax,rbx

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^dstruc lising

define cask.del free
macro cask.bdel TS {

  match type self , TS \{

    mov  rdi,self
    mov  rsi,type\#.del

    call cask.batcall

  \}

}

; ---   *   ---   *   ---
; goes through an iceptr cask
; and calls the passed method
; for each occupied slot

proc.new cask.batcall,public

proc.cpr rbx

proc.lis cask  self rbx

proc.stk dword cnt
proc.stk qword fn

  proc.enter

  ; save tmp
  mov @self,rdi
  mov qword [@fn],rsi
  mov dword [@cnt],$00

  ; get mask
  mov r11,qword [@self.mask]

  ; ^walk
  xor ecx,ecx
  .go_next:

    ; get next elem
    mov ecx,dword [@cnt]
    inc dword [@cnt]

    ; ^cap hit?
    cmp ecx,dword [@self.cnt]
    je  .skip


    ; get mask bit set
    mov rax,qword [r11]
    shr rax,cl

    ; ^skip unset
    and al,$01
    jz  .go_next


    ; ^else call method
    mov  rdi,[@self.buff]
    mov  rdi,qword [rdi+rcx*8]
    mov  rax,qword [@fn]

    call rax
    jmp  .go_next


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; occupy free slot

proc.new cask.give,public
proc.cpr rbx

proc.lis cask  self rbx
proc.stk qword elem

  proc.enter

  ; save tmp
  mov @self,rdi
  mov qword [@elem],rsi

  ; occupy get next slot
  call cask.get_slot
  or   qword [r11],rax


  ; ^write to buff+pos
  xor  r10w,r10w

  mov  rdi,qword [@self.buff]
  mov  rsi,qword [@elem]
  mov  r8d,dword [@self.ezy]

  imul ecx,r8d
  lea  rdi,[rdi+rcx]

  call memcpy


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^release

proc.new cask.take,public
proc.cpr rbx

proc.lis cask  self rbx
proc.stk qword dst

  proc.enter

  ; save tmp
  mov @self,rdi
  mov qword [@dst],rsi


  ; get (mask slot,bit) from idex
  call cask.idex_to_bit

  ; ^unset bit @ idex
  mov rax,$01
  shl rax,cl
  not rax
  and qword [r11],rax


  ; have dst?
  mov  rdi,qword [@dst]
  test rdi,rdi
  jz   @f

  ; ^get value @ idex
  mov  rdi,qword [@dst]
  call cask.read

  ; ^else nope
  @@:


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^just read

proc.new cask.view,public
proc.cpr rbx

proc.lis cask  self rbx
proc.stk qword dst

  proc.enter

  ; save tmp
  mov @self,rdi
  mov qword [@dst],rsi


  ; get (mask slot,bit) from idex
  call cask.idex_to_bit

  ; ^get value @ idex
  mov  rdi,qword [@dst]
  call cask.read


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; map idex to (mask slot,bit)

proc.new cask.idex_to_bit

proc.lis cask  self rbx
proc.stk dword idex

  proc.enter

  ; save tmp
  mov dword [@idex],edx

  ; idex < bounds?
  cmp edx,dword [@self.cnt]
  jl  @f

  ; ^nope, die
  constr.throw FATAL,"OOB CASK READ",$0A


  @@:


  ; get mask slot
  mov edi,edx
  line.urdiv

  dec rax
  mov r11,qword [@self.mask]
  lea r11,[r11+rax*8]

  ; ^get bit idex
  shl rax,sizep2.line

  mov edx,dword [@idex]
  mov ecx,edx
  sub ecx,eax


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; read [buff+pos] into [dst]

proc.new cask.read
proc.lis cask self rbx

  proc.enter

  ; get pos
  mov  r8d,dword [@self.ezy]
  imul edx,r8d

  ; ^read [buff+pos]
  mov  rsi,qword [@self.buff]
  lea  rsi,[rsi+rdx]
  mov  r10w,smX.CDEREF

  call memcpy


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; get next free slot

proc.new cask.get_slot

proc.lis cask self rbx

proc.stk dword cnt
proc.stk dword cap

  proc.enter

  ; save tmp
  mov r11,qword [@self.mask]
  mov dword [@cnt],$00
  mov dword [@cap],$00
  xor rcx,rcx


  ; try next mask slot
  .go_next:

    mov  rsi,qword [r11+rcx*8]
    mov  rdi,$01

    call mpart.fit


  ; ^slot full?
  cmp al,$3F
  jle .chk_bounds

  add dword [@cap],$40

  ; ^have next slot?
  inc dword [@cnt]
  mov ecx,dword [@cnt]
  cmp ecx,dword [@self.masksz]

  jl  .go_next
  jmp .throw


  ; mask slot < bounds?
  .chk_bounds:

    add dword [@cap],eax
    mov ecx,dword [@self.cnt]
    cmp dword [@cap],ecx

    jl  .skip


  ; ^nope to either check, die
  .throw: constr.throw FATAL,\
    "FULL CASK",$0A


  ; reset out
  .skip:

    mov ecx,dword [@cnt]
    lea r11,[r11+rcx*8]

    mov ecx,eax
    mov eax,$01
    shl rax,cl

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
