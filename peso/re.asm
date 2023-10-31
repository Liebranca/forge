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

  VERSION   v0.00.3b
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

  ; match repeat signal
  re.REMATCH = $9E4B

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

EXESEG

proc.new re.set_pat
proc.lis re.pat self rdi

macro re.set_pat.inline {

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
  inline re.set_pat
  ret

; ---   *   ---   *   ---
; ^shorthand for adding pat
; to array

macro re.new_pat src,min,max,flg {

  ; add space
  call array.grow

  ; ^write elem
  lea rsi,src

  mov qword [rax+re.pat.data],rsi
  mov word [rax+re.pat.min],min
  mov word [rax+re.pat.max],max
  mov byte [rax+re.pat.type],flg

}

; ---   *   ---   *   ---
; match ctx struc

reg.new re.status

  my .pos   dd $00
  my .avail dd $00

  my .cnt   dw $00

reg.end

; ---   *   ---   *   ---
; make pattern array

proc.new re.new
macro re.new.inline {

  proc.enter

  ; make ice
  mov  rsi,rdi
  mov  rdi,sizeof.re.pat

  call array.new

  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline re.new
  ret

; ---   *   ---   *   ---
; run through pattern array

proc.new re.match

proc.lis array.head self rdi
proc.lis re.pat     elem rdi

proc.lis array.head sref rsi

proc.stk re.status  cur
proc.stk re.status  ctx
proc.stk qword      rew

  proc.enter

  ; clear chain status
  mov ecx,dword [@sref.top]
  mov dword [@ctx.avail],ecx
  mov dword [@ctx.pos],$00
  mov word [@ctx.cnt],$00

  ; load elem struc addr
  lea r11,[@cur]

  ; load string addr
  mov rsi,qword [@sref.buff]
  mov qword [@rew],rsi


  ; get end of string
  .chk_src:

    mov edx,dword [@ctx.avail]
    cmp edx,$00

    jg  .chk_size
    jmp .skip


  ; get end of loop
  .chk_size:

    xor rdx,rdx

    mov dx,word [@ctx.cnt]
    mov ecx,dword [@self.top]

    shl rdx,$04
    cmp rdx,rcx

    je  .skip


  ; iter elems
  .go_next:

    ; clear elem status
    mov ecx,dword [@ctx.avail]
    mov dword [@cur.avail],ecx
    mov dword [@cur.pos],$00
    mov word [@cur.cnt],$00

    ; save tmp
    push @self

    ; match against elem
    xor  r9,r9
    mov  rdi,qword [@self.buff]
    mov  r9w,word [@ctx.cnt]
    shl  r9,$04
    add  rdi,r9

    call re.match_pat

    ; stop on fail
    or  ax,$00
    jne .success

    mov r9,1

  ; chk pattern specs
  .chk_match:

    xor rcx,rcx
    mov cl,byte [@elem.type]
    and cl,re.FLAG

    ; ^return len on negative pattern
    and cl,re.NEG
    shr cl,$02
    add r9,rcx

  ; skip src byte
  .step:

    add dword [@ctx.pos],r9d
    sub dword [@ctx.avail],r9d

    mov rsi,qword [@rew]
    add rsi,r9

    mov qword [@rew],rsi

    pop @self
    jmp .chk_src


  ; update chain status
  .success:

    mov ecx,dword [@cur.pos]
    add dword [@ctx.pos],ecx
    sub dword [@ctx.avail],ecx

    mov qword [@rew],rsi
    inc word [@ctx.cnt]


    ; get specs
    mov cl,byte [@elem.type]
    and cl,re.FLAG

    ; ^return len on negative pattern
    neg r9
    and cl,re.NEG
    jnz .step


    ; continue
    pop @self
    jmp .chk_src


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; match op siggy

macro re.sigt.match_pat {

  proc.lis re.pat    self rdi
  proc.lis qword     buff rsi

  proc.lis re.status ctx  r11

}

; ---   *   ---   *   ---
; ^(sub)pattern match

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

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^substr mode

proc.new re.match_sub
re.sigt.match_pat

  proc.enter

  ; compare substr to src
  .repeat:

    push @self

    mov  rdi,qword [@self.data]
    mov  rdi,qword [rdi]
    mov  r9d,dword [rdi+array.head.top]

    push r9

    xor  r8,r8
    mov  r8d,dword [@ctx.avail]

    call string.eq_n
    xor  al,$01


  ; ^chk result
  pop  r9
  pop  @self
  add  dword [@ctx.pos],r9d
  sub  dword [@ctx.avail],r9d

  call re.chk_match

  ; ^loop on signal
  cmp bx,re.REMATCH
  je  .repeat


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

proc.lis re.status ctx r11

  proc.enter

  xor rax,rax

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; chk result of match attempt

proc.new re.chk_match

proc.lis re.pat    self rdi
proc.lis re.status ctx  r11

  proc.enter

  xor bx,bx

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
  or ax,$00
  jz .skip


  ; chk cnt to [min,max]
  mov cx,word [@ctx.cnt]
  add cx,ax
  mov word [@ctx.cnt],cx

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
    mov    dx,word [@ctx.cnt]
    mov    cx,word [@self.min]

    cmp    dx,cx
    cmovge ax,dx


  ; cleanup and give
  proc.leave
  ret

  ; ^continue match
  .repeat:
    mov bx,re.REMATCH
    ret

; ---   *   ---   *   ---
