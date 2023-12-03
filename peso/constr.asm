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
  use '.hed' peso::io

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.constr

  VERSION   v0.00.6b
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
; ^virtual, needed for import

macro constr._ns_get_vflag dst,name {

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

      ; ^paste label
      constr._ins MAM.malign unit
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

    \}

}

; ---   *   ---   *   ---
; ^virtual, needed for import

macro constr._ns_new vn,[ct] {

  ; alignment not subject to MAM config
  ; as peso standard requires that all
  ; strings and strucs be unit-aligned
  common

    ; set public/private
    local dst
    dst equ

    constr._ns_get_vflag dst,vn


    ; ^align data
    match name , dst \{

      ; ^paste label
      constr._ins virtual at $00
      constr._ins MAM.malign unit

    \}

  ; ^paste bytes
  forward
    constr._ins db ct

  ; ^get string length in bytes
  ; then pad buffer to unit size
  common

    match name , dst \{
      constr._ins name\#.length = $
      constr._ins end virtual

    \}

}

; ---   *   ---   *   ---
; ^paste

macro constr mode= {

  local type
  type equ ROM

  match any , mode \{
    type equ any

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
; ^const

macro constr.sow name {

  mov  rdi,name
  mov  rsi,name#.length

  call sow

}

; ---   *   ---   *   ---
; ^errout

macro constr.errout name,code {

  ; switch file
  mov  rdi,stderr
  call fto

  ; ^write
  constr.sow code#.tag
  constr.sow name

  match =FATAL,code \{
    call reap
    exit code#.num

  \}

}

; ---   *   ---   *   ---
; ^all-in-one sugar

macro constr.throw code,[ct] {

  local name
  proc.get_id name,code#_errme

  match any,name \{
    constr.new    any,ct
    constr.errout any,code

  \}

}

; ---   *   ---   *   ---
; footer

FATAL.num = -1
MESS.num  = 1

constr.new public FATAL.tag, \
  $1B,$5B,'37;1m<',\
  $1B,$5B,'31;1mFATAL',\
  $1B,$5B,'37;1m> ',\
  $1B,$5B,'0m'

constr.new public MESS.tag, \
  $1B,$5B,'37;1m::',\
  $1B,$5B,'0m'

constr ROM

; ---   *   ---   *   ---
