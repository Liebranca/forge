; ---   *   ---   *   ---
; PESO STRING
; Byte chains
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
  use '.hed' peso::array
  use '.hed' peso::memcmp

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.string

  VERSION   v0.00.8b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; make string from const

macro string.from ct& {

  local name

  proc.get_id name,constr

  match any,name \{

    constr.new any,ct

    mov  rdi,$01
    mov  rsi,any\#.length
    mov  rdx,any
    mov  r8,any\#.length

    call string.new

  \}

}

; ---   *   ---   *   ---
; cstruc

EXESEG

proc.new string.new,public
proc.lis array.head self rax

  proc.enter

  ; make ice
  push rdx
  push r8

  call array.new


  ; strcpy on src != null
  pop r8
  pop rdx

  push rax
  test rdx,rdx
  jz   .skip

  ; ^cat to empty ;>
  mov  rdi,rax
  mov  rsi,rdx

  call string.cat


  ; cleanup and give
  .skip:
    pop rax

  proc.leave
  ret

; ---   *   ---   *   ---
; ^dstruc alias

string.del=array.del

; ---   *   ---   *   ---
; ^bat

macro string.bdel [item] {

  forward
    mov  rdi,item
    call string.del

}

; ---   *   ---   *   ---
; array cat request

reg.new string.insert_req
  my .total dq $00
  my .head  dq $00

reg.end

; ---   *   ---   *   ---
; identify arraywraps/raw string

macro string.get_type {

  ; chk src is raw string
  test r8,r8
  jnz  @f

  ; ^src is array wraps
  mov r8d,dword [@other.top]
  mov rsi,qword [@other.buff]


  @@:

  ; save tmp
  mov dword [@ctx.total],r8d
  mov qword [@ctx.head],rdi

}

; ---   *   ---   *   ---
; common routine to cat/lcat

proc.new string.insert_prologue

proc.lis array.head self  rdi
proc.lis array.head other rsi

proc.lis string.insert_req ctx r11

  proc.enter

  ; load req
  string.get_type

  ; chk src fits in dst
  push rsi
  mov  esi,r8d

  call array.resize_chk

  pop  rsi


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; insertion+update top

macro string.insert_epilogue {

  mov  r10w,smX.CDEREF
  call memcpy

  ; grow own top
  mov r8d,dword [@ctx.total]
  mov @self,qword [@ctx.head]

  add dword [@self.top],r8d

}

; ---   *   ---   *   ---
; insert/compare proto

macro string.sigt.insert {

  proc.stk string.insert_req ctx

  proc.lis array.head self  rdi
  proc.lis array.head other rsi

}

; ---   *   ---   *   ---
; overwrite

proc.new string.set,public
proc.lis array.head self rdi

macro string.set.inline {

  proc.enter
  mov dword [@self.top],$00

  call string.cat

  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline string.set
  ret


; ---   *   ---   *   ---
; add at end

proc.new string.cat,public
string.sigt.insert

  proc.enter

  ; load struc addr
  lea r11,[@ctx]

  ; ^fill out
  call string.insert_prologue

  ; ^seek to end
  mov ecx,dword [@self.top]
  mov rdi,qword [@self.buff]
  add rdi,rcx

  ; write
  string.insert_epilogue


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^add at beg

proc.new string.lcat,public
string.sigt.insert

  proc.enter

  ; load struc addr
  lea r11,[@ctx]

  ; ^fill out
  call string.insert_prologue

  ; ^save tmp
  push r8
  push rsi
  push @self

  ; shift N bytes right
  call array.shr


  ; ^restore tmp
  pop @self
  pop rsi
  pop r8

  ; write
  mov rdi,[@self.buff]
  string.insert_epilogue


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; get A eq B

proc.new string.eq,public
string.sigt.insert

  proc.enter

  ; load req
  string.get_type


  ; chk equal length
  mov eax,dword [@self.top]
  mov rcx,$01

  ; ^on unequal, return fail
  cmp    eax,r8d
  cmovne rax,rcx
  jne    .skip


  ; run comparison
  mov  rdi,[@self.buff]
  mov  r9w,smX.CDEREF
  mov  r10w,smX.CDEREF

  call memeq


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; get N bytes of A eq B

proc.new string.eq_n,public
string.sigt.insert

  proc.enter

  ; load req
  push r9
  string.get_type


  ; chk ge length
  mov eax,dword [@self.top]
  mov rcx,$01

  ; ^on less, return fail
  cmp   r8d,eax
  cmovl rax,rcx
  jl    .skip


  ; run comparison
  pop  r8
  mov  rdi,[@self.buff]
  mov  r9w,smX.CDEREF
  mov  r10w,smX.CDEREF

  call memeq


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; write to selected file

proc.new string.sow,public
proc.lis array.head self rdi

macro string.sow.inline {

  proc.enter

  mov  rsi,qword [@self.top]
  mov  rdi,qword [@self.buff]

  call sow

  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline string.sow
  ret

; ---   *   ---   *   ---
; color request struc

reg.new via.ansi.color

  my .esc      dw $00

  my .fgc      dw $00
  my .fgc_term db $00

  my .fgd      dw $00
  my .fgd_term db $00

  my .bgc      dw $00
  my .bgc_term db $00

  my .bgd      dw $00
  my .bgd_term db $00

reg.end

; ---   *   ---   *   ---
; ^fill out

proc.new string.color,public

proc.stk via.ansi.color cmd
proc.lis array.head     self rdi

  proc.enter

  ; clear tmp
  pxor   xmm0,xmm0
  movdqa xword [@cmd],xmm0


  ; get fg,bg
  mov al,sil
  mov bl,sil

  ; ^clamp each to F
  and ax,$0F
  shr bx,$04
  and bx,$0F

  ; ^clear first byte
  shl ax,$08
  shl bx,$08

  ; ^or N,X
  or ax,$3033
  or bx,$3034

  ; ^set struc
  mov word [@cmd.fgc],ax
  mov word [@cmd.bgc],bx


  ; get bold fg,bg
  shr si,8
  mov al,sil
  mov bl,sil

  ; ^invert
  not bx
  not ax

  ; ^clamp to bool*2
  and ax,$01
  shl al,$01

  and bx,$02

  ; or N,X
  or ax,$3130
  or bx,$3530

  ; ^set struc
  mov word [@cmd.fgd],ax
  mov word [@cmd.bgd],bx


  ; set terminators
  mov byte [@cmd.fgc_term],$3B
  mov byte [@cmd.fgd_term],$3B
  mov byte [@cmd.bgc_term],$3B
  mov byte [@cmd.bgd_term],$6D
  mov word [@cmd.esc],$5B1B

  ; cat to dst
  lea  rsi,[@cmd]
  mov  r8d,sizeof.via.ansi.color

  call string.cat


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; cursor relocate struc

reg.new via.ansi.mvcur

  my .esc    dw $00

  my .y      dd $00
  my .y_term db $00

  my .x      dd $00
  my .x_term db $00

reg.end

; ---   *   ---   *   ---
; ^fill out

proc.new string.mvcur,public

proc.stk via.ansi.mvcur cmd
proc.lis array.head     self rdi

  proc.enter

  ; clear tmp
  pxor   xmm0,xmm0
  movdqa xword [@cmd],xmm0

  ; save tmp
  push rdi


  ; get x
  push rsi
  mov  rax,rsi

  ; ^clamp to byte
  and  rax,$FF

  ; ^make decimal string
  mov  rdi,rax
  lea  rsi,[@cmd.x]
  xor  r9,r9

  call btods


  ; get y
  pop rsi
  shr rsi,$08
  mov rax,rsi

  ; ^clamp to byte
  and  rax,$FF

  ; ^make decimal string
  mov  rdi,rax
  lea  rsi,[@cmd.y]
  xor  r9,r9

  call btods


  ; set terminators
  mov byte [@cmd.y_term],$3B
  mov byte [@cmd.x_term],$48
  mov word [@cmd.esc],$5B1B

  ; cat to dst
  pop  rdi
  lea  rsi,[@cmd]
  mov  r8d,sizeof.via.ansi.mvcur

  call string.cat


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; bytes to decimal string

proc.new btods,public
proc.cpr rbx

  proc.enter


  xor rcx,rcx
  .go_next:

    ; get dit
    call UInt.mod10
    mov  rbx,rax

    ; ^shr dit
    call UInt.div10
    mov  rdi,rax

    ; write tmp
    or  rbx,$30
    shl rbx,cl
    or  r8,rbx

    add rcx,8

    ; ^write dst on full tmp
    cmp rcx,$38
    jne .stop_chk

    ; select dst size
    .write_dst:

      mov    rdx,r9
      jmptab .tab,byte,\
        .write_dword,\
        .write_qword

    ; ^4
    .write_dword:

      bswap r8d

      or    dword [rsi],r8d
      xor   rcx,rcx
      xor   r8,r8

      jmp   .stop_chk

    ; ^8
    .write_qword:

      bswap r8

      or    qword [rsi],r8
      xor   rcx,rcx
      xor   r8,r8


    ; stop on empty src
    .stop_chk:
      or  rdi,$00
      jnz .go_next


  ; ^backtrack on end
  or  r8,$00
  jnz .write_dst

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
