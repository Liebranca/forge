; ---   *   ---   *   ---
; ARSTD IO
; Debug prints
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb

; ---   *   ---   *   ---
; info

  TITLE     Arstd.IO

  VERSION   v0.00.2a
  AUTHOR    'IBN-3DILA'

  loaded?Arstd.IO=2

; ---   *   ---   *   ---
; GBL

  define SYSTAG $0A,      \
    $1B,$5B,'37;1m<',     \
    $1B,$5B,'34;22m','AR',\
    $1B,$5B,'37;1m>',     \
    $1B,$5B,'0m'

  define CHDTAG           \
    $1B,$5B,'37;1m::',    \
    $1B,$5B,'0m'

  define ERRTAG $0A,      \
    $1B,$5B,'37;1m<',     \
    $1B,$5B,'31;1m','AR', \
    $1B,$5B,'37;1m>',     \
    $1B,$5B,'0m'

  define BLANK $20

; ---   *   ---   *   ---

macro d'oh! src,[args] {

  common
    display src

  forward

    local status
    status equ 0

    match '__FILE__',args \{
      display $20,__FILE__
      status equ 1

    \}

    match =0 x y,status args \{

      display ','

      d'oh! BLANK,x,y
      status equ 1

    \}

    match =0,status \{
      display $20,`args

    \}

  common
    display $0A

  if src eq ERRTAG
    err

  end if

}

macro out@sys args& {d'oh! SYSTAG,args}
macro out@chd args& {d'oh! CHDTAG,args}
macro out@err args& {d'oh! ERRTAG,args}

; ---   *   ---   *   ---

macro module_info [name] {

forward
  if ~ loaded?#name
    out@err name,'not loaded'

  else

    match v a,name#?#version name#?#author \{
      out@sys name,v
      out@chd 'Copyleft',a

    \}

  end if

}

; ---   *   ---   *   ---
