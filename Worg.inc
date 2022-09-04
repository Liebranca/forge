; ---   *   ---   *   ---
; WORG
; Hunts you down
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Arstd.List
  include '%ARPATH%/forge/Arstd/List.inc'

end if

; ---   *   ---   *   ---
; info

  TITLE     Worg

  VERSION   v0.00.2a
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; utils

; pastes comma separated as lines
macro Worg@$npaste [line] {forward line}

; ---   *   ---   *   ---
; pops first elem from path:to:file

macro Worg@$break_path list,elem {

  local status
  status equ 0

  match value =: next,list \{

    elem equ value
    list equ next

    status equ 1

  \}

  match =0 value,status list \{

    elem equ value
    list equ

  \}

}

; ---   *   ---   *   ---

; ^space cats at end
macro Worg@$ecat list,item {

  match any,list \{list equ list item\}
  match ,list \{list equ item\}

}

; ---   *   ---   *   ---
; ^space cats at beg

macro Worg@$bcat list,item {

  match any,list \{list equ item list\}
  match ,list \{list equ item\}

}

; ^takes left-most token
macro Worg@$uncat list,elem {

  match value next,list \{

    elem equ value
    list equ next

  \}

}

; ---   *   ---   *   ---
; uses a symbolic constant as a counter (!!)

macro Worg@$symcnt sym,value=1 {

  local cnt

  ; increment
  cnt equ sym
  cnt equ cnt+value

  sym equ cnt

}

; ---   *   ---   *   ---
; ensures file is included only once

macro Worg@$load {

  local fcnt
  local list

  list equ Worg@pending_list
  fcnt equ Worg@pending_cnt

  rept fcnt \{

  define elem
  List@$shift list,elem

; ---   *   ---   *   ---
; get next item in list

  match name fpath,elem \\{

    if ~ defined loaded?#name

      define loaded?#name 1
      include fpath

      display $1B,$5B,'37;1m',\
        ':: ',$1B,$5B,'0m',\
        fpath,' included',$0A

    else

      display $1B,$5B,'37;1m',\
        ':: ',$1B,$5B,'0m',\
        fpath,' already included',$0A

    end if

  \\}
  restore elem

  \}

}

; ---   *   ---   *   ---
; cats vars from get_files and attemps
; to load in the file

macro Worg@$mkpath env,md,sd,sd_alt,fname,ext {

  List@$push Worg@pending_list,sd_alt#.#fname \
    '%'#`env#'%'#md#`sd#`/#`fname#ext

}

; ---   *   ---   *   ---
; ive been writing macros for 17 hours straight and
; no longer know what to call them: the movie

macro stirr3 a,b,c {
  a equ `a#`b#`c

}

macro stirr7 a,b,c {

  match any,a \{
    a equ any\#b#c

  \}

  match ,a \{
    a equ c

  \}

}

macro stirr99 a,b {
  a equ b#a

}

; ---   *   ---   *   ---
; walks collected file list

macro Worg@$get_files header {

  local cnt
  local fcnt
  local status

  cnt equ Worg@file_count
  status equ 0

  define tmp 0

  rept cnt \{

    match env module,header \\{

      define elem
      define Worg@module module

      define Worg@path
      define Worg@fname
      define Worg@subdir
      define Worg@subdir_alt

      List@$shift Worg@file_list,elem
      Worg@$symcnt tmp

; ---   *   ---   *   ---
; break down the path for this module

      match ext path,elem \\\{

        Worg@path equ path
        status equ 0

; ---   *   ---   *   ---
; handle dir/subdir/.../file
; up to 7 levels deep

        rept 7 \\\\{

          if status<2
          status equ 0

          match any next,Worg@path \\\\\{

; ---   *   ---   *   ---
; cat 'dir' to 'subdir'
; this makes 'dir/subdir' ;>

            match prev,Worg@subdir \\\\\\{

              define tmp prev

              ; are you going mad yet?
              match pprev,tmp \\\\\\\{

                stirr7 pprev,.,any
                Worg@subdir_alt equ pprev

              \\\\\\\}

              stirr3 prev,'/',any
              Worg@subdir equ prev

              restore tmp

            \\\\\\}

; ---   *   ---   *   ---
; only filename pending!

            match ,Worg@subdir \\\\\\{
              Worg@subdir equ any
              Worg@subdir_alt equ any

            \\\\\\}

            Worg@path equ next
            status equ 1


; ---   *   ---   *   ---
; path fully solved

          \\\\\}

          match =0 any,status Worg@path \\\\\{
            Worg@fname equ any
            Worg@path equ

            status equ 2

          \\\\\}

          end if

        \\\\}

; ---   *   ---   *   ---
; cat resulting vars together and load module

        match ,Worg@subdir_alt \\\\{
          Worg@subdir_alt equ _
          Worg@subdir equ ''

        \\\\}

        match md sd sd_alt fname ,\
          Worg@module Worg@subdir \
          Worg@subdir_alt Worg@fname  \\\\{

          Worg@$mkpath env,md,sd,sd_alt,fname,ext

        \\\\}

; ---   *   ---   *   ---

      \\\}

      restore Worg@subdir_alt
      restore Worg@subdir
      restore Worg@fname
      restore Worg@path

      restore Worg@module
      restore elem

    \\}

  \}

  restore Worg@file_list
  restore Worg@file_count

  Worg@pending_cnt equ tmp

  Worg@$load

  restore Worg@pending_cnt
  restore Worg@pending_list

}

; ---   *   ---   *   ---
; creates the 'use' keyword

macro Worg@$enable_use {

  macro use value \{

    define nested
    define remain

; ---   *   ---   *   ---
; break down value (use '.ext' path:to:file)

    match ext path,value \\{

      ; again, paths go 7 subdirs deep at most
      remain equ path
      rept 7 \\\{

        ; iter until path is empty
        match any,remain \\\\{

          define elem

          Worg@$break_path remain,elem
          Worg@$ecat nested,elem

          ; ^then push to list
          match ,remain \\\\\{

            List@$push Worg@file_list,ext nested
            Worg@$symcnt Worg@file_count

          \\\\\}

          restore elem

        \\\\}

      \\\}

; ---   *   ---   *   ---

    \\}

    restore remain
    restore nested

  \}

}

; ^destroys the use keyword
macro Worg@$disable_use {purge use}

; ---   *   ---   *   ---
; generator header/tail

%Worg fix Worg@$npaste
  Worg@$npaste Worg@$enable_use,\
  define Worg@file_count 0,\
  define Worg@file_list,\
  define Worg@pending_list,\
  define Worg@pending_cnt 0

^Worg fix Worg@$npaste Worg@$disable_use,\
  Worg@$get_files

; ---   *   ---   *   ---
