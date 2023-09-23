; ---   *   ---   *   ---
; IMP
; Little depsearchin devil
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Arstd.Style
  include '%ARPATH%/forge/Arstd/Style.inc'

end if

if ~ defined loaded?Arstd.List
  include '%ARPATH%/forge/Arstd/List.inc'

end if

; ---   *   ---   *   ---
; info

  TITLE     Imp

  VERSION   v0.01.2a
  AUTHOR    'IBN-3DILA'

  define    loaded?Imp 1

; ---   *   ---   *   ---
; GBL

  define interp.default '/lib64/ld-linux-x86-64.so.2'

  define Imp.library
  define Imp.module

  define Imp.includes

; ---   *   ---   *   ---
; split m[::],src
; then (join '/'),(join '.')

macro Imp.get_path_elem fpath,fname,next,ja,jb {

  local  status
  status equ 0

  ; A::B
  match s0 =:: s1,next \{

    match any,fpath \\{
      stircat fpath,any,ja,s0

    \\}

    match any,fname \\{
      tcat fname,any,jb,s0

    \\}

    next   equ s1
    status equ 1

  \}

  ; ^just A ;>
  match =0 s0,status next \{

    match any,fpath \\{
      stircat fpath,any,ja,s0

    \\}

    match any,fname \\{
      tcat fname,any,jb,s0

    \\}

    next equ

  \}

}

; ---   *   ---   *   ---
; ^bat

macro Imp.get_path fpath,fname,src {

  local next
  next  equ src

  Imp.get_path_elem fpath,fname,next,'',

  rept 6 \{
    Imp.get_path_elem fpath,fname,next,'/',.

  \}

}

; ---   *   ---   *   ---
; ^build full path

macro Imp.get_file env,md,ext,fpath,fname {

  local status
  local full

  status equ 0
  full   equ


  ; blank env
  match =_,env \{

    ; join path
    match f,fpath \\{
      stircat full,md,f,ext

    \\}

    Imp.load fname,full
    status equ 1

  \}

  ; ^same, uses env
  match =0,status \{

    match f,fpath \\{
      stircat full,'%'#`env#'%'#md,f,ext

    \\}

    Imp.load fname,full

  \}

}

; ---   *   ---   *   ---
; adds include to final list

macro Imp.append elem {

  match any,Imp.includes \{
    Imp.includes equ elem,Imp.includes

  \}

  match ,Imp.includes \{
    Imp.includes equ elem

  \}

}

; ---   *   ---   *   ---
; ensures file is included only once

macro Imp.load name,fpath {

  if ~ defined loaded#name

    define loaded#name 1
    Imp.append include fpath

; old dbout
;
;    display $1B,$5B,'37;1m',\
;      ':: ',$1B,$5B,'0m',\
;      fpath,' included',$0A
;
;  else
;
;    display $1B,$5B,'37;1m',\
;      ':: ',$1B,$5B,'0m',\
;      fpath,' already included',$0A


  end if

}

; ---   *   ---   *   ---
; turns use ... to include

macro use expr {

  match ext src,expr \{

    fpath equ ''
    fname equ ?

    Imp.get_path fpath,fname,src

    match env md,Imp.library Imp.module \\{
      Imp.get_file env,md,ext,fpath,fname

    \\}

  \}

}

; ---   *   ---   *   ---
; ^destroys the use keyword

macro Imp.disable_use {purge use}

; ---   *   ---   *   ---

macro library em {

  local status
  status equ 0

  match env module,em \{
    Imp.library equ env
    Imp.module equ module

  \}

}

import fix npaste2 Imp.includes,\
  restore Imp.library,restore Imp.module,\
  Imp.includes equ

; ---   *   ---   *   ---

