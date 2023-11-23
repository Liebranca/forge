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
  use '.hed' peso::string

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.re

  VERSION   v0.01.0b
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
  my .top  dw $00

  my .min  dw $00
  my .max  dw $00

  my .type db $00

reg.end

; ---   *   ---   *   ---
; match ctx struc

reg.new re.status

  my .pos   dd $00
  my .avail dd $00

  my .cnt   dw $00
  my .min   dw $00

reg.end

; ---   *   ---   *   ---
; make pattern array

EXESEG

proc.new re.new_array
macro re.new_array.inline {

  proc.enter

  ; make ice
  mov  rsi,rdi
  mov  rdi,sizeof.re.pat

  call array.new

  ; cleanup
  proc.leave

}

  ; ^invoke and give
  inline re.new_array
  ret

; ---   *   ---   *   ---
; cstruc

proc.new re.new,public

proc.lis array.head src rdi

proc.stk qword  stash

proc.stk qword  s1
proc.stk qword  s0

proc.stk re.pat elem

  proc.enter

  ; get [buff,length]
  mov rsi,[@src.buff]
  mov r8d,[@src.top]

  ; ^save tmp
  push rsi
  push r8


  ; make container
  mov    rdi,$01
  inline re.new_array

  mov    qword [@stash],rax

  ; ^dst string for pattern data
  mov  rdi,$01
  mov  rsi,$30
  xor  r8,r8
  xor  rdx,rdx

  call string.new
  mov  qword [@s0],rax
  mov  qword [@s1],$00

  ; ^store string at array beg
  mov  rdi,qword [@stash]
  lea  rsi,[@s0]

  call array.push


  ; restore tmp
  pop r8
  pop rsi


  ; proc elem
  .go_next:

    ; read meta
    lea  rdi,[@elem]
    call re.read_meta

    ; ^read src data
    mov  rdx,qword [@s0]
    call re.read_data


    ; save pattern
    push r8
    push rsi

    mov  rdi,qword [@stash]
    lea  rsi,[@elem]

    call array.push

    ; ^repeat on bytes left
    pop  rsi
    pop  r8

    test r8d,r8d
    jnz  .go_next


  ; reset out
  mov rax,qword [@stash]

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; fill out re.pat metadata
; from string

proc.new re.read_meta
proc.lis re.pat elem rdi

  proc.enter

  ; set elem defaults
  mov word [@elem.top],$00
  mov word [@elem.min],$01
  mov word [@elem.max],$01
  mov byte [@elem.type],$00

  ; get bytes left
  .chk_size:
    test r8d,r8d
    jz   .skip


  ; ^iter until terminator
  .walk:

    ; take next byte
    xor eax,eax
    mov al,byte [rsi]

    dec r8d
    inc rsi


    ; ^branch accto value
    branchtab re.spec

    ; pattern is negative
    re.spec.branch '!' => .neg
      or  byte [@elem.type],re.NEG
      jmp .chk_size

    ; match none or once
    re.spec.branch '?' => .quest
      mov word [@elem.min],$00
      jmp .chk_size

    ; match none or any
    re.spec.branch '*' => .star
      mov word [@elem.min],$00
      mov word [@elem.max],$FFFF
      jmp .chk_size

    ; match once or any
    re.spec.branch '+' => .plus
      mov word [@elem.max],$FFFF
      jmp .chk_size


    ; pattern is value range
    re.spec.branch '#' => .rng
      or  byte [@elem.type],re.RNG
      jmp .chk_size

    ; pattern is character class
    re.spec.branch '%' => .kls
      or  byte [@elem.type],re.KLS
      jmp .chk_size


    ; terminate specifier section
    re.spec.branch '=' => .end
      jmp .skip

    ; blank entries to avoid a
    ; bounded table
    re.spec.branch $00 => .non
    re.spec.branch $FF => .non
    re.spec.branch def => .non
      jmp .chk_size

    re.spec.end


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; ^fill out string data
; used by pattern

proc.new re.read_data
proc.lis re.pat     elem rdi
proc.lis array.head dst  rdx

  proc.enter

  ; get top of dst string
  mov rax,qword [@dst.buff]
  mov ecx,dword [@dst.top]
  add rax,rcx

  mov qword [@elem.data],rax


  ; get bytes left
  xor r9w,r9w
  xor r10b,r10b
  .chk_size:
    test r8d,r8d
    jz   .skip

  ; ^iter until terminator
  .walk:

    ; take next byte
    xor eax,eax
    mov al,byte [rsi]

    dec r8d
    inc rsi

    ; set/unset escaping
    cmp  al,'\'
    jne  @f

    xor  r10b,$01
    jmp  .chk_size

    @@:

    ; ^check current byte escaped
    mov  cl,al

    test r10b,r10b
    jz   .nonscap


    ; ^proc escaped
    xor       r10b,r10b
    branchtab re.scap

    re.scap.branch 's' => .scap_ws
      mov al,$20
      jmp .insert

    re.scap.branch 'n' => .scap_nl
      mov al,$0A
      jmp .insert

    re.scap.branch '0' => .scap_null
      mov al,$00
      jmp .insert

    re.scap.branch ',' => .scap_term
      jmp .skip

    re.scap.branch def => .scap_non
      mov al,cl

    re.scap.end
    jmp .insert


    ; ^proc regular
    .nonscap:

    branchtab re.nscap
    re.nscap.branch $00 => .nscap_null
    re.nscap.branch $20 => .nscap_ws
      jmp .chk_size

    re.nscap.branch def => .nscap_non
    re.nscap.branch $FF => .nscap_non
      mov al,cl

    re.nscap.end


    ; write to data string
    .insert:

      inc  r9w

      push @elem
      push rsi
      push r8
      push @dst

      mov  rdi,rdx
      mov  sil,al

      call array.push

      pop  @dst
      pop  r8
      pop  rsi
      pop  @elem

      jmp  .chk_size


  ; cleanup and give
  .skip:
    mov word [@elem.top],r9w

  proc.leave
  ret

; ---   *   ---   *   ---
; run through pattern array

proc.new re.match,public

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

  mov ecx,dword [@self.top]
  shr ecx,$04

  mov word [@ctx.min],cx
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

    inc rdx
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
    inc  r9
    shl  r9,$04
    add  rdi,r9

    call re.match_pat

    ; stop on fail
    test ax,ax
    jne  .success

    mov  word [@ctx.cnt],$00
    mov  r9,1

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


  ; reset out
  .skip:

    mov   edi,$00

    mov   cx,word [@ctx.cnt]
    mov   dx,word [@ctx.min]

    cmp   dx,cx
    cmovl eax,edi

  ; cleanup and give
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

    ; clear
    xor r8,r8
    xor r9,r9
    xor rax,rax

    ; read up to avail bytes
    mov  r9w,word [@self.top]
    mov  rdi,qword [@self.data]
    mov  r8d,dword [@ctx.avail]

    push r9

    ; ^skip on less
    mov al,$01
    cmp r8d,r9d
    jl  @f


    ; run comparison
    mov  r8d,r9d
    mov  r9w,smX.CDEREF
    mov  r10w,smX.CDEREF

    call memeq
    jmp  .chk_match

    @@:

    add  rsi,r9


  ; ^chk result
  .chk_match:

    xor  al,$01
    pop  r9
    pop  @self

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
proc.cpr rbx

re.sigt.match_pat

  proc.enter

  ; compare char to range
  .repeat:

    ; clear
    xor rax,rax
    xor r10,r10

    ; set step
    mov r9w,word [@self.top]
    mov r8d,dword [@ctx.avail]

    ; load byte and range
    push @self

    mov  bl,byte [@buff]
    mov  rdi,qword [@self.data]
    mov  cl,byte [rdi+$00]
    mov  dl,byte [rdi+$01]

    mov  r10b,$01
    pop  @self


    ; ^chk result
    cmp    bl,dl
    cmovle eax,r10d

    and    r10b,al
    cmp    bl,cl
    cmovge eax,r10d

    call   re.chk_match

    ; ^loop on signal
    cmp bx,re.REMATCH
    je  .repeat


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


  ; go next/rewind
  mov  r8,r9
  test ax,ax
  jnz  @f

  sub  rsi,r8
  xor  r8,r8

  @@:

  add dword [@ctx.pos],r8d
  sub dword [@ctx.avail],r8d


  ; end on fail
  test ax,ax
  jz   .skip


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
