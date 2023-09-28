; ---   *   ---   *   ---
; PESO SWITCH
; Rough conditionals
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.inc' peso::logic

import

; ---   *   ---   *   ---
; info

  TITLE     peso.switch

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define switch@name_stack
  define switch@cnt 0
  define switch@cnt_fwd 0

; ---   *   ---   *   ---
; generates .char<N> tags

macro genlabel dst,proto,list,scnt,do_inc {

  local name

  rept scnt+1 cnt:0 \{

    name equ proto

    stirr7 name,,cnt
    dst equ name

  \}

  match =1 ,do_inc \{
    List@$push list,name
    symcnt scnt

  \}

}

; ---   *   ---   *   ---
; ^wrappers

macro switch@$get_end_label dst,do_inc=0 {

  genlabel dst,.ES,\
    switch@name_stack,switch@cnt_fwd,do_inc

}

macro switch@$get_next_label dst,do_inc=0 {

  genlabel dst,.S,\
    switch@name_stack,switch@cnt,do_inc

}

; ---   *   ---   *   ---
; primitive if/elif

macro on ev {

  local name
  local next
  local c

  ; send previous to end
  match any,switch@name_stack \{

    local endt
    switch@$get_end_label endt,0

    jmp endt

  \}

  ; create new
  switch@$get_next_label name,1
  label name

  ; get next
  switch@$get_next_label next,0

  EVAL ev,c

  match any,c \{
    c equ jnz

  \}

  c next

}

; ---   *   ---   *   ---
; ^primitive else

macro off fall= {

  match any,fall \{

    local endt
    switch@$get_end_label endt,0

    jmp endt

  \}

  local name
  switch@$get_next_label name,1

  label name

  match ,fall \{end_on\}

}

; ---   *   ---   *   ---
; obligatory endof

macro end_on {

  local name

  switch@$get_end_label name,1
  label name

}

; ---   *   ---   *   ---
