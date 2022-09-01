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

;  include '%ARPATH%/forge/Arstd/IO.inc'

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

define loaded?Worg 1
define Worg?version 'v0.00.1a'

display 'Using Worg ',Worg?version,$0A

macro Worg@$load name,fpath {

  if ~ defined loaded?#name

    define loaded?#name 1
    include fpath

    display fpath,$0A

  else

    display $1B,$5B,'37;1m',\
      ':: ',$1B,$5B,'0m',\
      fpath,' already included',$0A

  end if

}

; ---   *   ---   *   ---

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

macro Worg@$get_files header {

  local cnt
  cnt equ Worg@file_count

  rept cnt \{

    match env module,header \\{

      define elem
      define Worg@module module

      Worg@$shift Worg@file_list,elem

; ---   *   ---   *   ---

      match ext path,elem \\\{

        define Worg@path path
        define Worg@fname
        define Worg@subdir
        define Worg@subdir_alt

        status equ 0

        rept 7 \\\\{

          if status<2
          status equ 0

          match any next,Worg@path \\\\\{

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

            match ,Worg@subdir \\\\\\{
              Worg@subdir equ any
              Worg@subdir_alt equ any

            \\\\\\}

            Worg@path equ next
            status equ 1

          \\\\\}

; ---   *   ---   *   ---

          match =0 any,status Worg@path \\\\\{

            Worg@fname equ any
            Worg@path equ

            status equ 2

          \\\\\}

          end if

        \\\\}

; ---   *   ---   *   ---

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

    match ext path,value \\{

      remain equ path
      rept 7 \\\{

        match any,remain \\\\{
          define elem

          Worg@$shift remain,elem
          Worg@$ecat nested,elem

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

; ^destroys it
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
