; ---   *   ---   *   ---
; PROC
; Repeating patterns
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Worg
  include '%ARPATH%/forge/Worg.inc'

end if

%Worg
  use '.inc' Arstd:IO

^Worg ARPATH '/forge/'

; ---   *   ---   *   ---
; info

  TITLE     Proc

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define Proc@current
  define Proc@current_depth 0
  define Proc@name_stack
  define Proc@name_stack_top 0

  define Proc@args_order \
    rdi : rsi : rdx : rcx : r8  :& r9

  define sizeof.byte $01
  define sizeof.wide $02
  define sizeof.half $04
  define sizeof.word $08
  define sizeof.unit $10

; ---   *   ---   *   ---

macro Proc@$make_list cur {

  define cur#@var_list
  define cur#@var_sz 0

}

macro Proc@$grow_list cur,name,size {

  List@$unshift cur#@var_list,name
  Worg@$symcnt cur#@var_sz,+size

}

; ---   *   ---   *   ---
; aggregate to current namespace

macro Proc@$enter name,size=0 {

  status equ 0

  match ,Proc@current \{
    label name at $

    Proc@current equ name
    status equ 1

    match any,Proc@current \\{
      Proc@$make_list any

    \\}

  \}

; ---   *   ---   *   ---

  match =0 any,status Proc@current \{
    label any\#.\#name at $

    Proc@current equ any\#.\#name
    Proc@$make_list any

  \}

  ; debug
  match any,Proc@current \{
    out@chd any

  \}

  List@$push Proc@name_stack,name
  Worg@$symcnt Proc@name_stack_top

  enter size,Proc@current_depth
  xor spl,spl

  Worg@$symcnt Proc@current_depth

}

; ---   *   ---   *   ---
; ^substract

macro Proc@$leave {

  match ,Proc@current \{
    out@err 'No current procedure'

  \}

  local name
  List@$pop Proc@name_stack,name
  Worg@$symcnt Proc@name_stack_top,-1

  name equ
  List@$flatten Proc@name_stack,\
    Proc@name_stack_top,name

; ---   *   ---   *   ---

  local status
  Proc@current equ

  rept Proc@name_stack_top {

    status equ 0

    match any next,name \\{
      stirr7 Proc@current,.,any
      name equ next

      status equ 1

    \\}

    match =0 any,status name \\{
      stirr7 Proc@current,.,any
      name equ

    \\}

  \}

  Worg@$symcnt Proc@current_depth,-1
  leave

}

; ---   *   ---   *   ---

macro Proc@$ret {
  Proc@$leave
  ret

}

; ---   *   ---   *   ---

macro Proc@$ins_on_args dst,iv {

  match ins value,iv \{
    ins dst,value

  \}

}

; ---   *   ---   *   ---

macro Proc@$call name,[args] {

  common
    local order
    local stack_args_list
    local stack_args_sz
    local next

    order equ Proc@args_order
    stack_args_sz equ 0

  forward
    List@$shift order,next

    ; registers avail
    match r,next \{

      local status
      status equ 0

      match value =|> iv,args \\{
        mov r,value
        Proc@$ins_on_args r,iv

        status equ 1

      \\}

      match =0,status \\{
        mov r,args

      \\}

    \}

    ; else push to stack
    match ,next \{
      List@$unshift stack_args_list,args
      stack_args_sz equ stack_args_sz+1

    \}

  common

    rept stack_args_sz \{
      List@$shift stack_args_list,next
      push next

    \}

    local n
    List@$shift Proc@bytecnt,n

    call name

}

; ---   *   ---   *   ---

macro Proc@$get_varoffset cur,dst {
  dst equ cur#@var_sz

}

macro Proc@$catvar cur,name,value {
  define %#cur#.#name %#cur#.#name
  %#cur#.#name equ value

}

; ---   *   ---   *   ---
; declare in current namespace

macro Proc@$var TN {

  match type name,TN\{

    match any,Proc@current \\{

      if defined sizeof.\#type
        size equ sizeof.\#type
        size equ size

      else
        out@err 'Unrecognized type:',type

      end if

; ---   *   ---   *   ---

      local off
      off equ 0

      Proc@$get_varoffset any,off

      Proc@$catvar any,name,rbp-#size#+off
      %\#name equ rbp-size+off

      Proc@$grow_list any,name,size

    \\}

  \}

}

; ---   *   ---   *   ---
