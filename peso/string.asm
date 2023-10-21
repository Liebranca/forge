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

  VERSION   v0.00.3b
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

    mov rax,qword [@self.top]
    mov rdi,qword [@self.buff]

    add rdi,rax


  ; iter until no chunks left
  .loop_body:

    ; get chunk size
    push rsi
    push rdi

    call string.get_chunk
    mov  edx,eax

    ; conditionally dereference ptr
    pop   rdi

    cmp   r9d,$10
    cmovl rsi,qword [rsi]

    ; copy one chunk
    call  array.set

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
  mov  edi,r8d
  call array.get_mode


  ; get step size
  mov ecx,eax
  mov r9d,$01
  shl r9d,cl

  ; ^check size >= unit
  mov ebx,$05
  cmp r9d,$10

  ; ^mark unit as unaligned struc
  cmovge eax,ebx


  ; cleanup and give
  .skip:

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

reg.new via.ansic

  my .esc      dw $0000

  my .fgc      dw $0000
  my .fgc_term db $00

  my .fgd      dw $0000
  my .fgd_term db $00

  my .bgc      dw $0000
  my .bgc_term db $00

  my .bgd      dw $0000
  my .bgd_term db $00

reg.end

; ---   *   ---   *   ---
; ^fill out

proc.new string.ansic

proc.stk via.ansic  cmd
proc.lis array.head self rdi

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
  mov  r8d,sizeof.via.ansic

  call string.cat


  ; cleanup and live
  proc.leave
  ret

; ---   *   ---   *   ---
