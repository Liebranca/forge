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

  VERSION   v0.01.0a
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; pops first elem from path:to:file

macro Imp@$break_path list,elem {

  local status
  status equ 0

  match value =:: next,list \{

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
; ensures file is included only once

macro Imp@$load {

  local fcnt
  local list

  list equ Imp@pending_list
  fcnt equ Imp@pending_cnt

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

macro Imp@$mkpath env,md,sd,sd_alt,fname,ext {

  local status
  status equ 0

  ; blank env
  match =_,env \{
    List@$push Imp@pending_list,sd_alt#.#fname \
      md#`sd#`/#`fname#ext

    status equ 1

  \}

  ; use env
  match =0,status \{

    List@$push Imp@pending_list,sd_alt#.#fname \
      '%'#`env#'%'#md#`sd#`/#`fname#ext

  \}

}

; ---   *   ---   *   ---
; walks collected file list

macro Imp@$get_files header {

  local cnt
  local fcnt
  local status

  cnt equ Imp@file_count
  status equ 0

  define tmp 0

  rept cnt \{

    match env module,header \\{

      define elem
      define Imp@module module

      define Imp@path
      define Imp@fname
      define Imp@subdir
      define Imp@subdir_alt

      List@$shift Imp@file_list,elem
      symcnt tmp

; ---   *   ---   *   ---
; break down the path for this module

      match ext path,elem \\\{

        Imp@path equ path
        status equ 0

; ---   *   ---   *   ---
; handle dir/subdir/.../file
; up to 7 levels deep

        rept 7 \\\\{

          if status<2
          status equ 0

          match any next,Imp@path \\\\\{

; ---   *   ---   *   ---
; cat 'dir' to 'subdir'
; this makes 'dir/subdir' ;>

            match prev,Imp@subdir \\\\\\{

              define tmp prev

              ; are you going mad yet?
              match pprev,tmp \\\\\\\{

                stirr7 pprev,.,any
                Imp@subdir_alt equ pprev

              \\\\\\\}

              strfcat prev,'/',any
              Imp@subdir equ prev

              restore tmp

            \\\\\\}

; ---   *   ---   *   ---
; only filename pending!

            match ,Imp@subdir \\\\\\{
              Imp@subdir equ any
              Imp@subdir_alt equ any

            \\\\\\}

            Imp@path equ next
            status equ 1


; ---   *   ---   *   ---
; path fully solved

          \\\\\}

          match =0 any,status Imp@path \\\\\{
            Imp@fname equ any
            Imp@path equ

            status equ 2

          \\\\\}

          end if

        \\\\}

; ---   *   ---   *   ---
; cat resulting vars together and load module

        match ,Imp@subdir_alt \\\\{
          Imp@subdir_alt equ _
          Imp@subdir equ ''

        \\\\}

        match md sd sd_alt fname ,\
          Imp@module Imp@subdir \
          Imp@subdir_alt Imp@fname  \\\\{

          Imp@$mkpath env,md,sd,sd_alt,fname,ext

        \\\\}

; ---   *   ---   *   ---

      \\\}

      restore Imp@subdir_alt
      restore Imp@subdir
      restore Imp@fname
      restore Imp@path

      restore Imp@module
      restore elem

    \\}

  \}

  restore Imp@file_list
  restore Imp@file_count

  Imp@pending_cnt equ tmp

  Imp@$load

  restore Imp@pending_cnt
  restore Imp@pending_list

}

; ---   *   ---   *   ---
; creates the 'use' keyword

macro Imp@$enable_use {

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

          Imp@$break_path remain,elem
          spacecat nested,elem

          ; ^then push to list
          match ,remain \\\\\{

            List@$push Imp@file_list,ext nested
            symcnt Imp@file_count

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
macro Imp@$disable_use {purge use}

; ---   *   ---   *   ---
; generator header/tail

imp fix npaste Imp@$enable_use,\
  define Imp@file_count 0,\
  define Imp@file_list,\
  define Imp@pending_list,\
  define Imp@pending_cnt 0

end_imp fix npaste Imp@$disable_use,\
  Imp@$get_files

; ---   *   ---   *   ---
