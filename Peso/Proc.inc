; ---   *   ---   *   ---
; PROC
; Repeating patterns
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Worg
  include '%ARPATH%/forge/Worg.inc'

end if

%Worg
  use '.inc' Arstd:IO

^Worg ARPATH '/forge/'

; ---   *   ---   *   ---
; info

  TITLE     Proc

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define Proc@current

  define sizeof.byte  1
  define sizeof.word  2
  define sizeof.dword 4
  define sizeof.qword 8

; ---   *   ---   *   ---

macro Proc@$make_list cur {

  define cur#@var_list
  define cur#@var_sz 0

}

macro Proc@$grow_list cur,name,size {

  Worg@$unshift cur#@var_list,name
  Worg@$symcnt cur#@var_sz,size

}

; ---   *   ---   *   ---
; aggregate to current namespace

macro Proc@$enter name,addr=$ {

  status equ 0

  match ,Proc@current \{
    label name at addr

    Proc@current equ name
    status equ 1

    match any,Proc@current \\{
      Proc@$make_list any

    \\}

  \}

; ---   *   ---   *   ---

  match =0 any,status Proc@current \{
    label any\#.\#name at addr

    Proc@current equ any\#.\#name
    Proc@$make_list any

  \}

  ; debug
  match any,Proc@current \{
    out@chd any

  \}

}

macro longcat [tokens] {

  common
    local status
    local name

    name equ

  forward

    status equ 0

    match ,name \{
      name equ tokens
      status equ 1

    \}

    match =0 prev,status name \{
      name equ prev \# tokens

    \}

}

; ---   *   ---   *   ---

macro Proc@$get_varoffset cur,dst {
  dst equ cur#@var_sz

}

macro Proc@$catvar cur,name,value {
  define %#cur#.#name %#cur#.#name
  %#cur#.#name equ value

}

; ---   *   ---   *   ---
; declare in current namespace

macro Proc@$var TN {

  match type name,TN\{

    match any,Proc@current \\{

      if defined sizeof.\#type
        size equ sizeof.\#type
        size equ size

      else
        out@err 'Unrecognized type:',type

      end if

; ---   *   ---   *   ---

      local off
      off equ 0

      Proc@$get_varoffset any,off

      Proc@$catvar any,name,rbp-#size#+off
      %\#name equ rbp-size+off

      Proc@$grow_list any,name,size

    \\}

  \}

}

; ---   *   ---   *   ---
