; ---   *   ---   *   ---
; PESO RE
; Not so regular
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
  use '.asm' peso::string

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.re

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  ; types
  re.SUB  = $00
  re.RNG  = $01
  re.KLS  = $02

  re.TYPE = $03

  ; ^specs
  re.NEG  = $04
  re.FLAG = $04

; ---   *   ---   *   ---
; pattern struc

reg.new re.pat

  my .data dq $00

  my .min  dw $00
  my .max  dw $00

  my .type db $00

reg.end

; ---   *   ---   *   ---
; ^cstruc

proc.new re.new_pat
proc.lis re.pat self rdi

macro re.new_pat.inline {

  proc.enter

  ; fill out struc
  mov qword [@self.data],rsi
  mov word [@self.min],r8w
  mov word [@self.max],r9w
  mov byte [@self.type],dl

  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline re.new_pat
  ret

; ---   *   ---   *   ---
; match op siggy

macro re.sigt.match_pat {
  proc.lis re.pat     self rdi
  proc.lis array.head sref rsi

}

; ---   *   ---   *   ---
; ^attempt (sub)pattern match

proc.new re.match_pat
re.sigt.match_pat

  proc.enter

  ; get branch
  xor rdx,rdx
  mov dl,byte [@self.type]
  and dl,re.TYPE

  ; ^make tab
  jmptab .lvl_00,byte,\
    .sub,.rng,.kls

  ; ^land
  .sub:
    mov rax,re.match_sub
    jmp .tail

  .rng:
    mov rax,re.match_rng
    jmp .tail

  .kls:
    mov rax,re.match_kls


  ; ^exec
  .tail:
    call rax
    xor  rax,$01

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^substr mode

proc.new re.match_sub
re.sigt.match_pat

proc.stk word cnt
proc.stk word out

  proc.enter

  ; clear stk
  mov word [@out],$00
  mov word [@cnt],$00


  ; compare substr to src
  .repeat:
  push @self

  mov  rdi,qword [@self.data]
  mov  rdi,qword [rdi]
  mov  r9d,dword [rdi+array.head.top]

  xor  r8,r8
  mov  r8w,word [@cnt]
  imul r8w,r9w

  call string.eq_n
  xor  al,$01

  ; ^chk result
  pop @self


  ; get specs
  mov dl,byte [@self.type]
  and dl,re.FLAG

  ; ^flip on negative pattern
  mov   cl,$00
  cmp   dl,re.NEG
  cmove cx,dx

  shr   cl,$02
  xor   al,cl

  ; end on fail
  or word [@out],ax
  or ax,$00
  jz .skip


  ; chk cnt to [min,max]
  mov cx,word [@cnt]
  add cx,ax
  mov word [@cnt],cx

  ; ^repeat on less than either
  mov dx,word [@self.min]
  cmp cx,dx
  jl  .repeat

  mov dx,word [@self.max]
  cmp cx,dx
  jl  .repeat


  ; fail on less than min
  .skip:

    xor    ax,ax
    mov    dx,word [@cnt]
    mov    cx,word [@self.min]

    cmp    dx,cx
    cmovge ax,word [@out]


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^character range (placeholder)

proc.new re.match_rng
re.sigt.match_pat

  proc.enter

  xor rax,rax

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^character class (placeholder)

proc.new re.match_kls
re.sigt.match_pat

  proc.enter

  xor rax,rax

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
