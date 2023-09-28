; ---   *   ---   *   ---
; PESO LOGIC
; So expressive!
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb

; ---   *   ---   *   ---
; deps

if ~ loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'
  use '.inc' Arstd::IO

import

; ---   *   ---   *   ---
; info

  TITLE     peso.logic

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define logic@stack
  define logic@stack_ptr 0

; ---   *   ---   *   ---

macro logic@$oppy c,a,b {

  local lhand
  local rhand
  local status

  lhand equ a
  rhand equ b
  status equ 0

  match any,rhand \{

    bmath lhand,a
    bmath rhand,b

    List@$push logic@stack,cmp lhand,rhand
    symcnt logic@stack_ptr

    status equ 1

  \}

  match =0,status \{

    bmath lhand,lhand
    umath lhand,c

    status equ 1

  \}

}

; ---   *   ---   *   ---
; ()

macro parens_block dst,ev {

  local status
  status equ 0

  match =0 outerL =( inner =) outerR,status ev \{
    dst equ inner
    status equ 1

  \}

  match =0 outerL =( inner =),status ev \{
    dst equ inner
    status equ 1

  \}

  match =0 =( inner =) outerR,status ev \{
    dst equ inner
    status equ 1

  \}

  match =0 =( inner =),status ev \{
    dst equ inner
    status equ 1

  \}

}

; ---   *   ---   *   ---
; !==

macro equality ev,c {

  local status

  local lhand
  local rhand

  status equ 0

  ; equals
  match =0 a == == b,status ev \{

    c equ jne
    lhand equ a
    rhand equ b

    status equ 1

  \}

  ; not equals
  match =0 a =! == b,status ev \{

    c equ je
    lhand equ a
    rhand equ b

    status equ 1

  \}

; ---   *   ---   *   ---

  match =1,status \{
    logic@$oppy c,lhand,rhand

  \}

  match =0,status \{
    leorge ev,c

  \}

}

; ---   *   ---   *   ---
; <=>

macro leorge ev,c {

  local status

  local lhand
  local rhand

  status equ 0

  ; greater than or equals
  match =0 a => == b,status ev \{

    c equ jl
    lhand equ a
    rhand equ b

    status equ 1

  \}

  ; greater than
  match =0 a => b,status ev \{

    c equ jle
    lhand equ a
    rhand equ b

    status equ 1

  \}

  ; less than or equals
  match =0 a =< == b,status ev \{

    c equ jg
    lhand equ a
    rhand equ b

    status equ 1

  \}

  ; less than
  match =0 a =< b,status ev \{

    c equ jge
    lhand equ a
    rhand equ b

    status equ 1

  \}

; ---   *   ---   *   ---

  match =1,status \{
    logic@$oppy c,lhand,rhand

  \}

  match =0,status \{
    logic@$oppy c,ev

  \}

}

; ---   *   ---   *   ---
; !?~

macro umath ev,c {

  local status
  status equ 0

  ; is zero
  match =0 =! a,status ev \{

    List@$push logic@stack,or a,0
    symcnt logic@stack_ptr

    c equ jnz

    status equ 1

  \}

  ; is non-zero
  match =0 =? a,status ev \{

    List@$push logic@stack,or a,0
    symcnt logic@stack_ptr

    c equ jz

    status equ 1

  \}

  ; negated
  match =0 =~ a,status ev \{

    List@$push logic@stack,not a
    symcnt logic@stack_ptr

    status equ 1

  \}

}

; ---   *   ---   *   ---
; +-*/

macro bmath l,ev {

  local status
  status equ 0

  ; addition
;  match =0 a =+ b,status ev \{
;
;    List@$push logic@stack,add a,b
;    symcnt logic@stack_ptr
;
;    l equ a
;
;    status equ 1
;
;  \}

  match =0 a =& b,status ev \{

    List@$push logic@stack,and a,b
    symcnt logic@stack_ptr

    l equ a

    status equ 1

  \}

}

; ---   *   ---   *   ---
; can we do trees?
;
;  ==
;  |
;  |-+
;  | \->a
;  | \->1
;  |
;  \-->2

macro EVAL ev,c {

  local exp
  local status

  status equ 0
  exp equ ev

  equality exp,c

  rept logic@stack_ptr \{

    local elem
    List@$shift logic@stack,elem

    elem

  \}

}

; ---   *   ---   *   ---
