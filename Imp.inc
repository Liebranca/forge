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

if ~ loaded?Arstd.Style
  include '%ARPATH%/forge/Arstd/Style.inc'

end if

if ~ loaded?Arstd.List
  include '%ARPATH%/forge/Arstd/List.inc'

end if

if ~ loaded?Arstd.IO
  include '%ARPATH%/forge/Arstd/IO.inc'

end if

; ---   *   ---   *   ---
; info

  TITLE     Imp

  VERSION   v0.01.3a
  AUTHOR    'IBN-3DILA'

  loaded?Imp = 2
  Imp.debug  = 0

; ---   *   ---   *   ---
; GBL

  define interp.default '/lib64/ld-linux-x86-64.so.2'

  define Imp.library
  define Imp.module

  define Imp.includes
  define Imp.includes_len 0

  define Imp.prev.includes
  define Imp.prev.includes_len 0

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

    Imp.qload fname,full
    status equ 1

  \}

  ; ^same, uses env
  match =0,status \{

    match f,fpath \\{
      stircat full,'%'#`env#'%'#md,f,ext

    \\}

    Imp.qload fname,full

  \}

}

; ---   *   ---   *   ---
; ensures file is queued for
; inclusion only once

macro Imp.qload name,fpath {

  match any ff,name fpath \{

    ; dbout
    if Imp.debug

      if ~ loaded\#any
        out@chd ff,' queued'

      else
        out@chd ff,' already queued'

      end if

    end if


    ; push fpath to Q if not already added
    if ~ loaded\#any

      loaded\#any=1

      List.push Imp.includes,fpath any
      Imp.includes_len equ Imp.includes_len+1

    end if


  \}

}

; ---   *   ---   *   ---
; ^walks the Q

macro Imp.load {

  local Q

  ; ^walks Q
  macro outer [fn] \{

    forward

      match fpath name,fn \\{
        inner fpath,name

      \\}

  \}

  ; ^procs each item from Q
  macro inner fpath,name \{

    if loaded?\#name < 1

      ; this stops recursive queues from
      ; accidentally pushing a file twice
      loaded?\#name=2
      include fpath

      ; dbout
      if Imp.debug
        out@chd 'loaded',fpath

      end if

    end if

  \}


  ; get queue as comma-separated
  Q equ
  List.cflatten Imp.includes,Imp.includes_len,Q

  match list,Q \{
    outer list

  \}

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
; define imports src

macro library em {

  local status

  ; dbout
  if Imp.debug
    out@sys `Included,`__FILE__

  end if

  Imp.prev.includes     equ Imp.includes
  Imp.prev.includes_len equ Imp.includes_len


  ; reset current
  match env module,em \{
    Imp.library equ env
    Imp.module  equ module

  \}

}

; ---   *   ---   *   ---
; ^pull use from library

macro import {

  Imp.load

  restore Imp.library
  restore Imp.module

  restore Imp.prev.includes
  restore Imp.prev.includes_len

  Imp.includes     equ Imp.prev.includes
  Imp.includes_len equ Imp.prev.includes_len

}

; ---   *   ---   *   ---

