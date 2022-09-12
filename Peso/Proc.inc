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

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'
  use '.inc' Peso::Reg
  use '.inc' Peso::Switch

  use '.inc' Arstd::IO

import

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

  define Switch@jmp_labels
  define Switch@label_cnt 0

  define Proc@args_order \
    rdi : rsi : rdx : rcx : r8  :& r9

; ---   *   ---   *   ---

macro Proc@$fnret dst {

  genlabel dst,.CR,\
    Switch@jmp_labels,Switch@label_cnt,1

}

; ---   *   ---   *   ---

macro Proc@$make_list cur {

  define cur#@var_list
  define cur#@var_sz 0

  define cur#@arg_list
  define cur#@arg_cnt 0

}

macro Proc@$grow_list cur,name,size {
  List@$unshift cur#@var_list,name
  symcnt cur#@var_sz,+size

}

; ---   *   ---   *   ---
; quick namespace open/close
; might make a more refined system later

macro clan name {
  Proc@current equ name
  Proc@current_depth equ 0
  Proc@name_stack equ
  Proc@name_stack_top equ 0

}

macro end_clan {
  Proc@current equ
  Proc@current_depth equ 0
  Proc@name_stack equ
  Proc@name_stack_top equ 0

}

; ---   *   ---   *   ---
; aggregate to current namespace

macro Proc@$enter name {

  status equ 0

  match ,Proc@current \{
    label name at $

    Proc@current equ name
    status equ 1

  \}

; ---   *   ---   *   ---

  match =0 any,status Proc@current \{
    label any\#.\#name at $
    Proc@current equ any\#.\#name

  \}

  match any,Proc@current \{
    Proc@$make_list any

  \}

  List@$push Proc@name_stack,name
  symcnt Proc@name_stack_top

}

; ---   *   ---   *   ---
; ^substract

macro Proc@$leave use_key,is_clan=0 {

  match ,Proc@current \{
    out@err 'No current procedure'

  \}

  local name
  List@$pop Proc@name_stack,name
  symcnt Proc@name_stack_top,-1

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

  symcnt Proc@current_depth,-1

  match =1 =0,use_key is_clan \{
    leave

  \}

  match =0 =0,use_key is_clan \{
    pop rbp

  \}

}

; ---   *   ---   *   ---

macro Proc@$ret use_key {
  Proc@$leave use_key
  ret

}

; ---   *   ---   *   ---

macro Proc@$ins_on_args dst,iv {

  match ins value,iv \{
    ins dst,value

  \}

}

; ---   *   ---   *   ---
; that is the question

macro Proc@$mov_or_lea dst,src {

  local status
  status equ 0

  match =* addr,src \{
    lea dst,addr
    status equ 1

  \}

  match =0,status \{
    mov dst,src

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

    match any,args \{
      List@$shift order,next

      ; registers avail
      match r,next \\{

        local status
        status equ 0

        match value =|> iv,args \\\{

          Proc@$mov_or_lea r,value
          Proc@$ins_on_args r,iv
          status equ 1

        \\\}

        match =0,status \\\{
          Proc@$mov_or_lea r,args

        \\\}

      \\}

      ; else push to stack
      match ,next \\{
        List@$unshift stack_args_list,args
        stack_args_sz equ stack_args_sz+1

      \\}

    \}

  common

    rept stack_args_sz \{
      List@$shift stack_args_list,next
      push next

    \}

    local n
    List@$shift Proc@bytecnt,n

}

; ---   *   ---   *   ---

macro Proc@$get_varoffset cur,dst {

  match num,cur#@var_sz \{
    dst equ num

  \}

}

macro Proc@$set_varoffset cur,v {
  cur#@var_sz equ v

}

macro Proc@$catvar cur,name,value {
  define %#cur#.#name %#cur#.#name
  %#cur#.#name equ value

}

macro Proc@$align_to size {

  match any,Proc@current \{

    local off
    local diff
    local status

    status equ 0
    Proc@$get_varoffset any,off

    match =0,off \\{
      status equ 1

    \\}

    match =0,status \\{

      local do
      do equ (off) mod size

      rept do \\\{
        off equ 0+((off+size) and (-size))

      \\\}

      Proc@$set_varoffset any,off

    \\}

  \}

}

; ---   *   ---   *   ---
; declare in current namespace

macro Proc@$var type,name {

  match any,Proc@current \{

    match ,sizeof.\#type \\{
      out@err 'Unrecognized type:',type

    \\}

    size equ sizeof.\#type
    size equ size

; ---   *   ---   *   ---

    local off

    Proc@$align_to size
    Proc@$get_varoffset any,off

    Proc@$catvar any,name,rbp-(off+size)
    %\#name equ rbp-(off+size)

    Proc@$grow_list any,name,size

  \}

}

; ---   *   ---   *   ---
; aliases do/undo

macro Proc@$enable_keyw {

  irp type, byte,word,dword,qword \{
    macro type name \\{Proc@$var type,name\\}

  \}

  macro call name,args& \{

    Proc@$call name,args

; if you can't use call, this will do
;
;    local cr
;    Proc@$fnret cr
;    push cr
;    jmp name
;    label cr
;
; however, it's more and longer instructions

    call name

  \}

}

macro Proc@$disable_keyw {
  irp type, byte,word,dword,qword \{
    purge type

  \}

  purge call

}

; ---   *   ---   *   ---

macro Proc@$def_open name,type=nihil {

  align $10

  Proc@$enter name
  match any,Proc@current \{

    push rbp
    mov rbp,rsp

    any\#_beg=$+3
    sub sp,word 0

    symcnt Proc@current_depth

  \}

}

; ---   *   ---   *   ---

macro Proc@$def_close at_end {

  local status

  ; a hack: rewrite src for sub sp
  ; with stack frame size
  match any,Proc@current \{

    local off

    off equ 0
    status equ 1

    Proc@$get_varoffset any,off
    store word off at any\#_beg

    match =0,off \{
      status equ 0

    \}

  \}

  Proc@$#at_end status

}

; ---   *   ---   *   ---

proc fix npaste\
  Proc@$enable_keyw,\
  Proc@$def_open

end_proc fix npaste\
  Proc@$disable_keyw,\
  Proc@$def_close

; ---   *   ---   *   ---
