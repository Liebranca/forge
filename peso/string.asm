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
  use '.asm' peso::array

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.string

  VERSION   v0.00.5b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; cstruc

EXESEG

proc.new string.new
proc.lis array.head self rax

  proc.enter

  ; make ice
  push rdx
  push r8

  call array.new


  ; strcpy on src != null
  pop r8
  pop rdx

  or  rdx,$00
  jz  .skip

  ; ^cat to empty ;>
  mov  rdi,rax
  mov  rsi,rdx

  call string.cat


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; ^concatenate

proc.new string.cat

proc.stk dword total
proc.stk qword head

proc.lis array.head self  rdi
proc.lis array.head other rsi

  proc.enter

  ; chk src is raw string
  or  r8,$00
  jnz .loop_beg

  ; ^src is array wraps
  mov r8d,dword [@other.top]
  mov rsi,qword [@other.buff]


  ; save tmp
  .loop_beg:

    mov dword [@total],r8d
    mov qword [@head],rdi

    ; get bounds
    push rsi
    mov  esi,r8d

    call array.resize_chk

    pop  rsi

    ; ^use old/updated buff
    mov rax,qword [@self.top]
    mov rdi,qword [@self.buff]

    add rdi,rax


  ; iter until no chunks left
  .loop_body:

    ; get chunk size
    push rsi
    push rdi

    call string.get_chunk

    ; conditionally dereference ptr
    pop   rdi

    cmp   r9d,$10
    cmovl rsi,qword [rsi]

    ; copy one chunk
    call  memcpy.direct

    ; conditionally increase ptr
    pop   rsi

    xor   rax,rax
    cmp   r9d,$10
    cmovl eax,r9d

    add   rsi,r9


    ; go next
    sub r8d,eax
    or  r8d,$00

    jg  .loop_body


  ; grow own top
  .loop_end:

    mov r8d,dword [@total]
    mov @self,qword [@head]

    add dword [@self.top],r8d


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; generic get chunk size

proc.new string.get_chunk
proc.cpr rbx

  proc.enter

  ; select function
  call memcpy.get_size

  ; get step size
  mov ecx,edx
  mov r9d,$01
  shl r9d,cl


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; write to selected file

proc.new string.sow
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

proc.new string.color

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

proc.new string.mvcur

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

proc.new btods
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
