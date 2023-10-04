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
; deps

library ARPATH '/forge/'
  use '.asm' peso::file

import

; ---   *   ---   *   ---
; info

  TITLE     peso.constr

  VERSION   v0.00.2b
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
    constr._ins align $10
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

  constr.data equ

}

; ---   *   ---   *   ---
; ^invoke sys

macro constr.sow name {

  mov rdi,name
  mov rsi,name#.length

  call sow

}

; ---   *   ---   *   ---
; ^errout

macro constr.errout name,code {

  ; switch file
  mov  rdi,STDERR
  call fto

  ; ^write
  constr.sow tag.#code
  constr.sow name

  match =FATAL,code \{
    call reap
    exit -1

  \}

}

; ---   *   ---   *   ---
; ROM II

constr.new tag.FATAL, \
  $1B,$5B,'37;1m<',\
  $1B,$5B,'31;1mFATAL',\
  $1B,$5B,'37;1m> ',\
  $1B,$5B,'0m'

constr.seg

; ---   *   ---   *   ---
