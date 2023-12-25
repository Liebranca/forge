; ---   *   ---   *   ---
; PESO SMX I64
; Old school registers
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
  use '.hed' peso::smX::common

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.smX.i64

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; make operand

macro smX.i64.new_arg name,rv,offv,modev {
  define $#r#name    rv
  define $#off#name  offv
  define $#mode#name modev

}

; ---   *   ---   *   ---
; ^undo

macro smX.i64.del_arg name {
  restore $#r#name
  restore $#off#name
  restore $#mode#name

}

; ---   *   ---   *   ---
; ~

macro _ {

  smX.i64.new_arg X=rax $10 m

  $rX    = rax
  $offX  = $10
  $modeX = m


  smX.i64.del_arg X

}

; ---   *   ---   *   ---
; load [?dst],[?src]

macro smX.i64.ld size,\
  rX,offX,modeX,\
  rY,offY,modeY,\
  rZ {

  local dst
  dst equ rY

  ; need deref?
  match =m , modeY \{
    mov rZ,size [rY+offY]
    dst equ rZ

  \}

  ; ^copy
  smX.i64.ld_switch \
    size,modeX,rX,offX,dst

}

; ---   *   ---   *   ---
; ^pick op based on mode

macro smX.i64.ld_switch size,mode,dst,off,src {

  ; [dst] <= src
  match =m , mode \{
    mov size [dst+off],src

  \}

  ; ^dst <= src
  match =r , mode \\{
    mov dst,src

  \}

}

; ---   *   ---   *   ---
; clear [A]

macro smX.i64.clm size,step,_nullarg& {
  mov size [rdi],$00

}

; ---   *   ---   *   ---
; clear A

macro smX.i64.clr size,step,_nullarg& {
  xor rdi,rdi

}

; ---   *   ---   *   ---
; ^[A] eq [B]

macro smX.i64.eqmm size,step,_nullarg& {

  ; get src
  local rX
  i_sized_reg rX,si,size

  ; get dst
  local rY
  i_sized_reg rY,di,size

  ; get scratch
  local rZ
  i_sized_reg rZ,b,size


  ; deref
  mov rX,size [rsi]
  mov rY,size [rdi]

  ; ^compare values
  mov rZ,rX
  xor rZ,rY

  ; ^go next
  add rdi,step
  add rsi,step
  sub r8d,step

}

; ---   *   ---   *   ---
; generate X-sized op

macro smX.i64.walk op,size,args& {

  local step
  step equ sizeof.#size

  ; paste op [args]
  op size,step,args

  smX.paste_footer op

}

; ---   *   ---   *   ---
; ^table generator ice

macro smX.i64.tab op,eob,args& {

  ; list possible sizes
  local entry
  local entry.len

  List.from entry,entry.len,\
    byte,word,dword,qword

  ; ^make elem for each
  smX.gen_tab \
    smX.i64.walk,byte,\
    entry,entry.len,\
    eob,smX.i64.#op,args

}

; ---   *   ---   *   ---
