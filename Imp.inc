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

if ~ defined loaded?Arstd.INCFILE
  include '%ARPATH%/forge/Arstd/INCFILE.inc'

end if

if ~  defined loaded?Arstd.Style
  include '%ARPATH%/forge/Arstd/Style.inc'

end if

if ~  defined loaded?Arstd.List
  include '%ARPATH%/forge/Arstd/List.inc'

end if

if ~  defined loaded?Arstd.IO
  include '%ARPATH%/forge/Arstd/IO.inc'

end if

; ---   *   ---   *   ---
; info

  TITLE     Imp

  VERSION   v0.01.5
  AUTHOR    'IBN-3DILA'


  Imp.debug=0

; ---   *   ---   *   ---
; GBL

  define interp.default '/lib64/ld-linux-x86-64.so.2'

  define Imp.library
  define Imp.module

  define Imp.includes
  define Imp.includes_len 0

  define Imp.final

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

    match ,fname \\{
      fname equ s0

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

    match ,fname \\{
      fname equ s0

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

    Imp.load fname,full

  \}

}

; ---   *   ---   *   ---
; queue files for inclusion

macro Imp.load name,fpath {

  match any ff,name fpath \{

    ; dbout
    if Imp.debug

      if ~ defined loaded?\#any
        out@chd ff,' queued'

      else
        out@chd ff,' already queued'

      end if

    end if


    ; push fpath to Q if not already added
    List.unshift Imp.includes,fpath any
    Imp.includes_len equ Imp.includes_len+1

  \}

}

; ---   *   ---   *   ---
; turns use ... to include

macro use expr {

  match ext src,expr \{

    fpath equ ''
    fname equ

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
    out@sys 'IMP:',`__FILE__

  end if


  ; reset current
  match env module,em \{
    Imp.library equ env
    Imp.module  equ module

  \}

}

; ---   *   ---   *   ---
; ^pull use from library

macro library.import.prologue {

  local list
  list equ

  List.cflatten Imp.includes,Imp.includes_len,list

  restore Imp.library
  restore Imp.module

  Imp.includes     equ
  Imp.includes_len equ

  Imp.final        equ

  macro inner [fpath] \{

    forward

      match prev,Imp.final \\{
        Imp.final equ fpath,prev

      \\}

      match ,Imp.final \\{
        Imp.final equ fpath

      \\}

  \}

  match item,list \{
    inner item

  \}

}

; ---   *   ---   *   ---
; ^recursive include hack

library.import fix \
\
rept 1 {\
\
  macro paste [line] \{forward line\}\
  macro discombobulate fpath,name \{\
    paste \
      if ~ defined loaded?\#name,\
        include fpath,\
\
      end if\
  \}\
\
  macro recurse [item] \{\
    match fpath name,item \\{\
      discombobulate fpath,name\
\
    \\}\
\
  \}\
\
  macro convolute list \{\
    macro inner [item] \\{forward recurse item\\}\
    match any,list \\{\inner any\\}\
\
  \}\
\
  rept 1 \{library.import.prologue\}\
  rept 1 \{convolute Imp.final\}\
\
}

; ---   *   ---   *   ---
