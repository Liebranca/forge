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
; quick and dirty namespace aggregation ;>

macro INFO_FIELD line {

  match module field value,this?module line \{

    module \# ? \# field equ module \# ? \# field
    define module \# ? \# field value

  \}

}

; ---   *   ---   *   ---
; ^please only aggregate to it this way

macro TITLE name {
  define this?module name
  define loaded?#name 1

}

macro VERSION number {
  INFO_FIELD version number

}

macro AUTHOR name {
  INFO_FIELD author name

}

; ---   *   ---   *   ---
; info

  TITLE     Worg

  VERSION   v0.00.1a
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; utils

; pastes comma separated as lines
macro Worg@$npaste [line] {forward line}

; colon cats at end
macro Worg@$append list,item {

  match any,list \{list equ list : item\}
  match ,list \{list equ item\}

}

; ^colon cats at beg
macro Worg@$unshift list,item {

  match any,list \{list equ item : list\}
  match ,list \{list equ item\}

}

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
; pops first elem from list

macro Worg@$shift list,elem {

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
; uses a symbolic constant as a counter (!!)

macro Worg@$symcnt sym {

  local cnt

  ; increment
  cnt equ sym
  cnt equ cnt+1

  sym equ cnt

}

; ---   *   ---   *   ---
; ensures file is included only once

macro Worg@$load name,fpath {

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

}

; ---   *   ---   *   ---
; cats vars from get_files and attemps
; to load in the file

macro Worg@$mkpath env,md,sd,sd_alt,fname,ext {

  Worg@$load sd_alt#.#fname,\
    '%'#`env#'%'#md#`sd#`/#`fname#ext

}

; ---   *   ---   *   ---
; ive been writing macros for 17 hours straight and
; no longer know what to call them: the movie

macro stirr3 a,b,c {
  a equ `a#`b#`c

}

macro stirr7 a,b,c {
  a equ a#b#c

}

macro stirr99 a,b {
  a equ b#a

}

; ---   *   ---   *   ---
; walks collected file list

macro Worg@$get_files header {

  local cnt
  cnt equ Worg@file_count

  rept cnt \{

    match env module,header \\{

      define elem
      define Worg@module module

      Worg@$shift Worg@file_list,elem

; ---   *   ---   *   ---
; break down the path for this module

      match ext path,elem \\\{

        define Worg@path path
        define Worg@fname
        define Worg@subdir
        define Worg@subdir_alt

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

        match md sd sd_alt fname ,\
          Worg@module Worg@subdir \
          Worg@subdir_alt Worg@fname  \\\\{

          Worg@$mkpath env,md,sd,sd_alt,fname,ext

        \\\\}

      \\\}

    \\}

  \}

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

          Worg@$shift remain,elem
          Worg@$ecat nested,elem

          ; ^then push to list
          match ,remain \\\\\{

            Worg@$append Worg@file_list,ext nested
            Worg@$symcnt Worg@file_count

          \\\\\}

          restore elem

        \\\\}

      \\\}

; ---   *   ---   *   ---

    \\}

    restore nested
    restore remain

  \}

}

; ^destroys the use keyword
macro Worg@$disable_use {purge use}

; ---   *   ---   *   ---
; generator header/tail

%Worg fix macro Worg@$fetch header {\
  Worg@$npaste Worg@$enable_use,\
  define Worg@file_count 0,\
  define Worg@file_list

^Worg fix Worg@$npaste Worg@$disable_use,\
  Worg@$get_files header,}\
  Worg@$fetch

; ---   *   ---   *   ---
