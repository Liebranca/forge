; ---   *   ---   *   ---
; PESO CONSTR
; Const string boilerpaste
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; get importer

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.asm' peso::file

import

; ---   *   ---   *   ---
; info

  TITLE     peso.constr

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'


; ---   *   ---   *   ---
; GBL

  define  constr.data

; ---   *   ---   *   ---
; make elem

macro constr._ins line {

  match any,constr.data \{
    constr.data equ any,line

  \}

  match ,constr.data \{
    constr.data equ line

  \}

}

; ---   *   ---   *   ---
; ^append

macro constr.new name,[ct] {

  common
    constr._ins  align $10
    constr._ins name#:

  forward
    constr._ins db ct

  common
    constr._ins name#.length=$-name

}


; ---   *   ---   *   ---
; ^paste

macro constr.seg {

  segment readable

  macro _inner [line] \{
    npaste line

  \}

  match any,constr.data \{
    _inner any

  \}

}

; ---   *   ---   *   ---
; ^invoke sys

macro constr.sow name {

  mov rdi,name
  mov rsi,name#.length

  call sow

}

; ---   *   ---   *   ---
