; ---   *   ---   *   ---
; LIST
; It's all take and give
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Arstd.INCFILE
  include '%ARPATH%/forge/Arstd/INCFILE.inc'

end if

; ---   *   ---   *   ---
; an example of usage:

  TITLE     List

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

  define    loaded?List 1

; ---   *   ---   *   ---

macro List@$push list,elem& {

  match any,list \{

    local status
    status equ 0

    match items =:& last , list \\{
      list equ items : last :& elem
      status equ 1

    \\}

    match =0 =:& items , status list \\{
      list equ items :& elem

    \\}

  \}

  match ,list \{
    list equ :& elem

  \}

}

; ---   *   ---   *   ---

macro List@$unshift list,elem& {

  match any,list \{

    local status
    status equ 0

    match items =:& last , list \\{
      list equ elem : items :& last
      status equ 1

    \\}

    match =0 =:& items , status list \\{
      list equ  elem :& items

    \\}

  \}

  match ,list \{
    list equ :& elem

  \}

}

; ---   *   ---   *   ---

macro List@$pop list,elem {

  local status
  status equ 0

  match items =: pen =:& last , list \{
    elem equ last
    list equ items :& pen

    status equ 1

  \}

  match =0 items =:& last , status list \{
    elem equ last
    list equ :& items

    status equ 1

  \}

  match =0 =:& last , status list \{
    elem equ last
    list equ

  \}

}

; ---   *   ---   *   ---

macro List@$shift list,elem {

  local status
  status equ 0

  match first =: pen =:& last , list \{
    elem equ first
    list equ pen :& last

    status equ 1

  \}

  match =0 first =:& last , status list \{
    elem equ first
    list equ :& last

    status equ 1

  \}

  match =0 =:& last , status list \{
    elem equ last
    list equ

  \}

}

; ---   *   ---   *   ---

macro List@$flatten list,len,out {

  local cpy
  local elem

  cpy equ list
  elem equ

  rept len \{
    List@$shift cpy,elem

    match any,out \\{
      out equ any elem

    \\}

    match ,out \\{
      out equ elem

    \\}

  \}

}

; ---   *   ---   *   ---
