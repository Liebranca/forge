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

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.constr

  VERSION   v0.00.4b
  AUTHOR    'IBN-3DILA'


; ---   *   ---   *   ---
; GBL

  define  constr.data

; ---   *   ---   *   ---
; get (then set) visibility
; flag for elem

macro constr.get_vflag dst,name {

  local vflag
  local vis
  vflag equ

  match s0 s1 , name \{
    dst   equ s1
    vflag equ s0

  \}

  match , vflag \{
    dst equ name

  \}

  match s0 s1 , vflag dst \{
    MAM.sym_vflag vis,s1,s0

  \}

}

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

macro constr.new vn,[ct] {

  ; alignment not subject to MAM config
  ; as peso standard requires that all
  ; strings and strucs be unit-aligned
  common

    ; set public/private
    local dst
    dst equ

    constr.get_vflag dst,vn


    ; ^align data
    match name , dst \{
      constr._ins ._v.bpad = $10\
      - (name\#.length and $0F)

      constr._ins db ._v.bpad dup $00

      ; ^paste label
      constr._ins name\#:

    \}

  ; ^paste bytes
  forward
    constr._ins db ct

  ; ^get string length in bytes
  ; then pad buffer to unit size
  common

    match name , dst \{
      constr._ins .length = $-name
      constr._ins .pad    = .length mod $10

      constr._ins db .pad dup $00

    \}

}


; ---   *   ---   *   ---
; ^paste

macro constr mode* {

  local type
  type equ

  match ,mode \{
    type equ ROM

  \}

  match T,type \{
    T\#SEG

  \}


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
  mov  rdi,stderr
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

constr.new public tag.FATAL, \
  $1B,$5B,'37;1m<',\
  $1B,$5B,'31;1mFATAL',\
  $1B,$5B,'37;1m> ',\
  $1B,$5B,'0m'

constr ROM

; ---   *   ---   *   ---
