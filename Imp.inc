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

  VERSION   v0.01.1a
  AUTHOR    'IBN-3DILA'

  define    loaded?Imp 1

; ---   *   ---   *   ---
; GBL

  define interp@default '/lib64/ld-linux-x86-64.so.2'

  define Imp@library
  define Imp@module

  define Imp@includes

; ---   *   ---   *   ---

macro Imp@$append elem {

  match any,Imp@includes \{
    Imp@includes equ Imp@includes,elem

  \}

  match ,Imp@includes \{
    Imp@includes equ elem

  \}

}

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

macro Imp@$load name,fpath {

  if ~ defined loaded?#name

    define loaded?#name 1
;    display $1B,$5B,'37;1m',\
;      ':: ',$1B,$5B,'0m',\
;      fpath,' included',$0A

    Imp@$append include fpath

; ---   *   ---   *   ---

  else

;    display $1B,$5B,'37;1m',\
;      ':: ',$1B,$5B,'0m',\
;      fpath,' already included',$0A

  end if

}

; ---   *   ---   *   ---
; cats vars from get_files and attemps
; to load in the file

macro Imp@$mkpath env,md,sd,sd_alt,fname,ext {

  local status
  status equ 0

  ; blank env
  match =_,env \{
    Imp@$load sd_alt#.#fname,\
      md#`sd#`/#`fname#ext

    status equ 1

  \}

  ; use env
  match =0,status \{

    Imp@$load sd_alt#.#fname,\
      '%'#`env#'%'#md#`sd#`/#`fname#ext

  \}

}

; ---   *   ---   *   ---
; walks collected file list

macro Imp@$get_file ext,_path {

  local status
  local path

  local elem

  local fname
  local subdir
  local subdir_alt

  fname equ
  subdir equ
  subdir_alt equ

  path equ _path
  status equ 0

; ---   *   ---   *   ---
; handle dir/subdir/.../file
; up to 7 levels deep

  match env module,Imp@library Imp@module \{

    rept 7 \\{

      if status<2
      status equ 0

      match any next,path \\\{

; ---   *   ---   *   ---
; cat 'dir' to 'subdir'
; this makes 'dir/subdir' ;>

        match prev,subdir \\\\{

          ; are you going mad yet?
          match pprev,prev \\\\\{

            stirr7 pprev,.,any
            subdir_alt equ pprev

          \\\\\}

          strfcat prev,'/',any
          subdir equ prev

        \\\\}

; ---   *   ---   *   ---
; only filename pending!

        match ,subdir \\\\{
          subdir equ any
          subdir_alt equ any

        \\\\}

        path equ next
        status equ 1


; ---   *   ---   *   ---
; path fully solved

      \\\}

      match =0 any,status path \\\{
        fname equ any
        path equ

        status equ 2

      \\\}

      end if

    \\}

; ---   *   ---   *   ---
; cat resulting vars together and load module

    match ,subdir_alt \\{
      subdir_alt equ _
      subdir equ ''

    \\}

    match md sd sd_alt _fname ,\
      module subdir \
      subdir_alt fname \\{

      Imp@$mkpath env,md,sd,sd_alt,_fname,ext

    \\}

; ---   *   ---   *   ---

  \}

}

; ---   *   ---   *   ---

macro use value {

  local nested
  local remain

  nested equ
  remain equ

; ---   *   ---   *   ---
; break down value (use '.ext' path:to:file)

  match ext path,value \{

    ; again, paths go 7 subdirs deep at most
    remain equ path
    rept 7 \\{

      ; iter until path is empty
      match any,remain \\\{

        local elem

        Imp@$break_path remain,elem
        spacecat nested,elem

        ; ^then push to list
        match ,remain \\\\{
          Imp@$get_file ext,nested

        \\\\}

      \\\}

    \\}

; ---   *   ---   *   ---

  \}

}

; ^destroys the use keyword
macro Imp@$disable_use {purge use}

; ---   *   ---   *   ---

macro library em {

  local status
  status equ 0

  match env module,em \{
    Imp@library equ env
    Imp@module equ module

  \}

}

import fix npaste2 Imp@includes,\
  restore Imp@library,restore Imp@module,\
  Imp@includes equ

; ---   *   ---   *   ---

