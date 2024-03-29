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

  VERSION   v0.00.4a
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  IO.colorsay=1

; ---   *   ---   *   ---
; color escape+string

macro ANSIC dst,color,value& {
  define dst $1B,$5B,color,'m',value

}

; ---   *   ---   *   ---
; ^multi

macro ANSIC.bat [DCV] {

  forward match dst color value , DCV \{
    ANSIC dst,color,value

  \}

}

; ---   *   ---   *   ---
; ROM I

  ANSIC IO.tag_open,'37;1','<'
  ANSIC IO.tag_close,'37;1','>'
  ANSIC IO.ncolor,'0',$00
  ANSIC IO.comma,'37;1',',',IO.ncolor,' '
  ANSIC IO.number,'33;22',$00
  ANSIC IO.money,'37;1','$'
  ANSIC IO.colon,'37;1',':'

  ANSIC IO.string,'36;1',$00

; ---   *   ---   *   ---
; add <color> to tag ;>

macro IO.CTAGIT dst,color,value& {

  local body
  ANSIC body,color,value

  match any , body \{

    pastedef dst,comma,$0A,\
      IO.tag_open,\
      any,\
      IO.tag_close,\
      IO.ncolor

  \}

}

; ---   *   ---   *   ---
; ROM II

  define PADTAG           \
    $1B,$5B,'37;1m.',     \
    $1B,$5B,'0m'

  define CHDTAG           \
    $1B,$5B,'37;1m::',    \
    $1B,$5B,'0m'

  IO.CTAGIT SYSTAG,'34;22','AR'
  IO.CTAGIT ERRTAG,'31;1','FATAL'
  IO.CTAGIT PETAG,'35;1','peso'

  define BLANK $20

; ---   *   ---   *   ---
; give "file <filename>"

macro IO.FILEIT dst,name {

  local body
  ANSIC body,'32;1',name

  match any , body \{
    dst equ 'file ',any,IO.ncolor

  \}

}

; ---   *   ---   *   ---
; shame

_$recsay fix macro _$recsay.outer args2& \\{\
\
  macro _$recsay.inner [args3] \\\{\
    forward display $20,args3\
  \\\}\
  match any,args2 \\\{_$recsay.inner any\\\}\
\
\\}\
_$recsay.outer 

; ---   *   ---   *   ---
; old and weird args ipret

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
      _$recsay x,y
      status equ 1

    \}

    match =0,status \{
      display $20,`args

    \}

  common

    if src eq ERRTAG
      out@nl 2
      err

    else if src eq BLANK

    else
      out@nl

    end if

}

; ---   *   ---   *   ---
; ^sugar

macro out@sys args& {d'oh! SYSTAG,args}
macro out@chd args& {d'oh! CHDTAG,args}
macro out@err args& {d'oh! ERRTAG,args}

macro out@nl  r=1   {rept r\{display $0A\}}

; ---   *   ---   *   ---
; meta prints

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
; display constant in hexn
; adapted from fasm manual ;>

macro hexsay N,bits {

  local ._v.d

  ; display colored?
  if IO.colorsay=1
    display IO.money,IO.number

  end if


  ; iter nibbles
  repeat (bits)/4

    ._v.d = \
      '0' + (((N) \
      shr ((bits)-(%*4))) and $0F)

    if ._v.d > '9'
      ._v.d = ._v.d + ('A'-'9'-1)

    end if

    display ._v.d

  end repeat


  ; ^close wraps
  if IO.colorsay=1
    display IO.ncolor

  end if

}

; ---   *   ---   *   ---
; ^print version

macro humansay N,bits {

  local ._v.d

  ; display colored?
  if IO.colorsay=1
    display IO.string,"'"

  end if


  ; iter bytes
  repeat (bits)/8

    ._v.d = (N shr ((%-1)*8)) and $FF

    if (._v.d > $7E) | (._v.d < $20)
      ._v.d='.'

    end if

    display ._v.d

  end repeat


  ; ^close wrap
  if IO.colorsay=1
    display "'",IO.ncolor

  end if

}

; ---   *   ---   *   ---
; ^a combination of the two

macro xesay N,bits {

  hexsay N,bits

  if IO.colorsay=1
    display $20,IO.colon,$20

  else
    display  $20,':',$20

  end if

  humansay N,bits

}

; ---   *   ---   *   ---
; display expanded list

macro out@EX [item] {

  common
    local list
    list equ

  forward match any , item \{

    local ok
    local body

    body equ
    ok   equ 0

    match =~ cmd arg , any \\{
      cmd body,arg
      ok equ 1

      commacat list,body

    \\}

    match =0 , ok \\{
      commacat list,any

    \\}

  \}

  common match any , list \{
    display any

  \}

}

; ---   *   ---   *   ---
