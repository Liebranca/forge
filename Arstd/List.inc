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
; info

  TITLE     List

  VERSION   v0.00.4b
  AUTHOR    'IBN-3DILA'

  define    loaded?Arstd.List 2

; ---   *   ---   *   ---
; add to end of list

macro List.push list,elem& {

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
; add to beggining

macro List.unshift list,elem& {

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
; remove last element

macro List.pop list,elem {

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
; remove first element

macro List.shift list,elem {

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
; converts [elem : elem] to [elem elem]

macro List.flatten list,len,out {

  local cpy
  local elem

  cpy  equ list
  elem equ

  rept len \{

    List.shift cpy,elem

    match any,out \\{
      out equ any elem

    \\}

    match ,out \\{
      out equ elem

    \\}

  \}

}

; ---   *   ---   *   ---
; ^comma-separated

macro List.cflatten list,len,out {

  local cpy
  local elem

  cpy  equ list
  elem equ

  rept len \{

    List.shift cpy,elem

    match any,out \\{
      out equ any,elem

    \\}

    match ,out \\{
      out equ elem

    \\}

  \}

}

; ---   *   ---   *   ---
; cstruc

macro List.new name {

  define name#.m_list
  define name#.m_len

  macro name#.push item& \{
    List.push name#.m_list,item
    name#.m_len equ name#.m_len + 1

  \}

  macro name#.unshift item& \{
    List.unshift name#.m_list,item
    name#.m_len equ name#.m_len + 1

  \}

  macro name#.cflatten dst \{

    dst equ

    match any,name#.m_len \\{
      List.cflatten name#.m_list,name#.m_len,dst

    \\}

  \}

  macro name#.clear \{
    name#.m_list equ
    name#.m_len  equ 0

  \}

  macro name#.npaste \{

    local dst

    macro inner [item] \\{

      forward

        local final
        local ok

        ok equ 0

        match s0 '\,' s1 , item \\\{
          final equ s0,s1
          ok    equ 1

        \\\}

        match =0 , ok \\\{
          final equ item

        \\\}

        match any , final \\\{
          any

        \\\}

    \\}

    name#.cflatten dst
    match any,dst \\{inner any\\}

  \}

  macro name \{name#.npaste\}

}

; ---   *   ---   *   ---
; ^anon from set

macro List.from dst,len,[item] {

  common
    dst equ
    len equ 0

  forward
    List.push dst,item
    len equ len+1

}

; ---   *   ---   *   ---
