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

  VERSION   v0.00.7b
  AUTHOR    'IBN-3DILA'


; ---   *   ---   *   ---
; GBL

  define   constr.data
  List.new constr.throw_code

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

  match ='PASTE' , type \{
    type equ

  \}

  match T , type \{
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

  local blkname
  local ok

  ok equ 0

  uid.new blkname,constr._throw_gen

  ; generate errcall
  match blk , blkname \{

    macro blk\#._gen \\{

      blk\#:

      ; setup stack
      push rbp
      mov  rbp,rsp
      sub  rsp,2

      ; ^back old fto
      call fto.get
      mov  word [rbp-2],ax

      ; switch file
      mov  di,stderr
      call fto

      ; ^write
      constr.sow code#.tag
      constr.sow name

      match =FATAL,code \\\{
        exit code#.num
        ok equ 1

      \\\}

      match =0 , ok \\\{

        ; reset file
        mov  di,word [rbp-2]
        call fto


        ; cleanup and give
        pop rbp

        leave
        ret

      \\\}

    \\}

    constr.throw_code.push blk\#._gen
    call blk

  \}

}

; ---   *   ---   *   ---
; ^all-in-one sugar

macro constr.throw code,ct& {

  local name
  uid.new name,code#_errme

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

; ---   *   ---   *   ---
; ^if not explicitly called,
; then paste constants on ROM

macro constr._gen_footer {

  match any , constr.data \{
    constr ROM

  \}

  match any , constr.throw_code \{

    EXESEG
    constr.throw_code
    constr.throw_code.clear

  \}

}

MAM.xfoot constr

; ---   *   ---   *   ---
