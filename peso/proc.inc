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

;  use '.inc' peso::reg
;  use '.inc' peso::switch

;  use '.inc' Arstd::IO

import

; ---   *   ---   *   ---
; info

  TITLE     peso.proc

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define proc@current

  define proc@current_depth 0
  define proc@name_stack
  define proc@name_stack_top 0

  define switch@jmp_labels
  define switch@label_cnt 0

  define proc@args_order \
    rdi : rsi : rdx : rcx : r8  :& r9

; ---   *   ---   *   ---

macro proc@$fnret dst {

  genlabel dst,.CR,\
    switch@jmp_labels,switch@label_cnt,1

}

; ---   *   ---   *   ---

macro proc@$make_list cur {

  define cur#@var_list
  define cur#@var_sz 0

  define cur#@arg_list
  define cur#@arg_cnt 0

}

macro proc@$grow_list cur,name,size {
  List@$unshift cur#@var_list,name
  symcnt cur#@var_sz,+size

}

; ---   *   ---   *   ---
; quick namespace open/close
; might make a more refined system later

macro CLAN name {
  proc@current equ name
  proc@current_depth equ 0

  proc@name_stack equ
  List@$push proc@name_stack,name
  proc@name_stack_top equ 1

  name#:

}

macro END_CLAN {
  proc@current equ
  proc@current_depth equ 0
  proc@name_stack equ
  proc@name_stack_top equ 0

}

; ---   *   ---   *   ---
; aggregate to current namespace

macro proc@$enter name {

  status equ 0

  match ,proc@current \{
    label name at $

    proc@current equ name
    status equ 1

  \}

; ---   *   ---   *   ---

  match =0 any,status proc@current \{
    label any\#.\#name at $
    proc@current equ any\#.\#name

  \}

  match any,proc@current \{
    proc@$make_list any

  \}

  List@$push proc@name_stack,name
  symcnt proc@name_stack_top

}

; ---   *   ---   *   ---
; ^substract

macro proc@$leave use_key,is_clan=0 {

  match ,proc@current \{
    out@err 'No current procedure'

  \}

  local name
  List@$pop proc@name_stack,name
  symcnt proc@name_stack_top,-1

  name equ
  List@$flatten proc@name_stack,\
    proc@name_stack_top,name

; ---   *   ---   *   ---

  local status
  proc@current equ

  rept proc@name_stack_top {

    status equ 0

    match any next,name \\{
      stirr7 proc@current,.,any
      name equ next

      status equ 1

    \\}

    match =0 any,status name \\{
      stirr7 proc@current,.,any
      name equ

    \\}

  \}

  symcnt proc@current_depth,-1

  match =1 =0,use_key is_clan \{
    leave

  \}

  match =0 =0,use_key is_clan \{
    pop rbp

  \}

}

; ---   *   ---   *   ---

macro proc@$ret use_key {
  proc@$leave use_key
  ret

}

; ---   *   ---   *   ---

macro proc@$ins_on_args dst,iv {

  match ins value,iv \{
    ins dst,value

  \}

}

; ---   *   ---   *   ---
; that is the question

macro proc@$mov_or_lea dst,src {

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

macro proc@$call name,[args] {

  common
    local order
    local stack_args_list
    local stack_args_sz
    local next

    order equ proc@args_order
    stack_args_sz equ 0

  forward

    match any,args \{
      List@$shift order,next

      ; registers avail
      match r,next \\{

        local status
        status equ 0

        match value =|> iv,args \\\{

          proc@$mov_or_lea r,value
          proc@$ins_on_args r,iv
          status equ 1

        \\\}

        match =0,status \\\{
          proc@$mov_or_lea r,args

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
    List@$shift proc@bytecnt,n

}

; ---   *   ---   *   ---

macro proc@$get_varoffset cur,dst {

  match num,cur#@var_sz \{
    dst equ num

  \}

}

macro proc@$set_varoffset cur,v {
  cur#@var_sz equ v

}

macro proc@$catvar cur,name,value {
  define %#cur#.#name %#cur#.#name
  %#cur#.#name equ value

}

macro proc@$align_to size {

  match any,proc@current \{

    local off
    local diff
    local status

    status equ 0
    proc@$get_varoffset any,off

    match =0,off \\{
      status equ 1

    \\}

    match =0,status \\{

      local do
      do equ (off) mod size

      rept do \\\{
        off equ 0+((off+size) and (-size))

      \\\}

      proc@$set_varoffset any,off

    \\}

  \}

}

; ---   *   ---   *   ---
; declare in current namespace

macro proc@$var type,name {

  match any,proc@current \{

    match ,sizeof.\#type \\{
      out@err 'Unrecognized type:',type

    \\}

    size equ sizeof.\#type
    size equ size

; ---   *   ---   *   ---

    local off

    proc@$align_to size
    proc@$get_varoffset any,off

    proc@$catvar any,name,rbp-(off+size)
    %\#name equ rbp-(off+size)

    proc@$grow_list any,name,size

  \}

}

; ---   *   ---   *   ---
; aliases do/undo

macro proc@$enable_keyw {

  irp type, byte,word,dword,qword \{
    macro type name \\{proc@$var type,name\\}

  \}

  macro call name,args& \{

    proc@$call name,args

; if you can't use call, this will do
;
;    local cr
;    proc@$fnret cr
;    push cr
;    jmp name
;    label cr
;
; however, it's more and longer instructions

    call name

  \}

}

macro proc@$disable_keyw {
  irp type, byte,word,dword,qword \{
    purge type

  \}

  purge call

}

; ---   *   ---   *   ---

macro proc@$def_open name,type=nihil {

  align $10

  proc@$enter name
  match any,proc@current \{

    push rbp
    mov rbp,rsp

    any\#_beg=$+3
    sub sp,word 0

    symcnt proc@current_depth

  \}

}

; ---   *   ---   *   ---

macro proc@$def_close at_end {

  local status

  ; a hack: rewrite src for sub sp
  ; with stack frame size
  match any,proc@current \{

    local off

    off equ 0
    status equ 1

    proc@$get_varoffset any,off
    store word off at any\#_beg

    match =0,off \{
      status equ 0

    \}

  \}

  proc@$#at_end status

}

; ---   *   ---   *   ---

proc fix npaste\
  proc@$enable_keyw,\
  proc@$def_open

end_proc fix npaste\
  proc@$disable_keyw,\
  proc@$def_close

; ---   *   ---   *   ---
