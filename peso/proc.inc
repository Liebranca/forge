; ---   *   ---   *   ---
; PROC
; F-repeating patterns
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.inc' peso::reg

import

; ---   *   ---   *   ---
; info

  TITLE     peso.proc

  VERSION   v0.00.6b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define hier.cproc

  proc.debug=0

; ---   *   ---   *   ---
; start new block

macro proc.new name {

  if proc.debug
    out@sys name

  end if

  ; reset current
  hier.cproc equ name

  ; symbol declare/restore queues
  define name#.$proc.nsmk
  define name#.$proc.nsrm
  define name#.$proc.nslen 0

  ; ^not-so-effed stuff
  define name#.$proc.vars
  define name#.$proc.rpres_a
  define name#.$proc.rpres_b
  define name#.$proc.stksize 0


  ; add unit aligned label
  unit.malign
  name#:

}

; ---   *   ---   *   ---
; push register list, then
; reserve N bytes in stack

macro proc.enter {

  if proc.debug

    match any,hier.cproc \{
      out@sys 'entering',any

    \}

  end if


  ; get declared stack size
  local n
  sfield.get n,hier.cproc,$proc.stksize

  ; ^convert size to units
  n equ n*-1
  n equ n+(sizeof.unit-1)
  n equ n shr sizep2.unit
  n equ n shl sizep2.unit

  ; ^paste prologue
  if n > 0
    push rbp
    mov  rbp,rsp
    sub  rsp,n

  end if


  proc.preserve hier.cproc
  proc.open_scope hier.cproc

}

; ---   *   ---   *   ---
; ^adds to preserved register list

macro proc.cpr [rX] {

  forward
    sfield.push hier.cproc,$proc.rpres_a,rX
    sfield.unshift hier.cproc,$proc.rpres_b,rX

}

; ---   *   ---   *   ---
; exec symbol definitions
; for this scope

macro proc.open_scope base {

  local Q

  proc.scope_queue Q,nsmk
  proc.scope_paste Q

}

; ---   *   ---   *   ---
; ^undo

macro proc.close_scope base {

  local Q

  proc.scope_queue Q,nsrm
  proc.scope_paste Q

}

; ---   *   ---   *   ---
; ^it's the same for both

macro proc.scope_queue Q,base {

  local QD
  local len

  sfield.get QD,hier.cproc,$proc.#base
  sfield.get len,hier.cproc,$proc.nslen

  Q equ
  List.cflatten QD,len,Q

}

; ---   *   ---   *   ---
; ^idem, handles pasting
; of Q'd lines

macro proc.scope_paste Q {

  macro mkdef lis,value \{

    if proc.debug
      out@chd lis,value

    end if

    define @\#lis value

  \}

  macro rmdef lis \{
    restore @\#lis

  \}

  macro inner [line] \{

    forward

      match =define lis value,line \\{
        mkdef lis,value

      \\}

      match =restore lis,line \\{
        rmdef lis

      \\}

  \}

  match lines,Q \{inner lines\}

}

; ---   *   ---   *   ---
; add stack space

macro proc.stk sn {

  local Q0
  local Q1

  local top
  local len
  local offset

  top    equ 0
  offset equ 0


  ; get namespace queues
  sfield.get Q0,hier.cproc,$proc.nsmk
  sfield.get Q1,hier.cproc,$proc.nsrm
  sfield.get len,hier.cproc,$proc.nslen


  ; ^Q definitions and undos
  match type name,sn \{

    ; calc new size && var offset
    sfield.get offset,hier.cproc,$proc.stksize
    top equ 0-(sizeof.\#type)-offset

    ; make name -> rbp-offset
    match x,top \\{

      if defined type\#.$reg
        reg.qvice Q0,Q1,len,rbp-x,type name

      else
        List.push Q0,define  name rbp-x
        List.push Q1,restore name

        len equ len+1

      end if

      ; reset stack top
      sfield.set hier.cproc,$proc.stksize,\
        offset-sizeof.\#type

    \\}

  \}

  ; ^reset queues
  sfield.set hier.cproc,$proc.nsmk,Q0
  sfield.set hier.cproc,$proc.nsrm,Q1
  sfield.set hier.cproc,$proc.nslen,len

}

; ---   *   ---   *   ---
; ^detail args

macro proc.arg snr {

  local Q0
  local Q1
  local len

  ; get namespace queues
  sfield.get Q0,hier.cproc,$proc.nsmk
  sfield.get Q1,hier.cproc,$proc.nsrm
  sfield.get len,hier.cproc,$proc.nslen


  ; ^Q definitions and undos
  match type name rX,snr \{

    if proc.debug
      out@chd snr

    end if


    if defined type\#.$reg
      reg.qvice Q0,Q1,len,rX,type name

    else
      List.push Q0,define  name rX
      List.push Q1,restore name

      len equ len+1

    end if

  \}

  ; ^reset queues
  sfield.set hier.cproc,$proc.nsmk,Q0
  sfield.set hier.cproc,$proc.nsrm,Q1
  sfield.set hier.cproc,$proc.nslen,len

}

; ---   *   ---   *   ---
; ^proc.arg can be used for
; aliasing values, but that
; is a bit confusing!
;
; so, this wrap is just to
; fix that semantical issue

macro proc.lis snr {proc.arg snr}

; ---   *   ---   *   ---
; end-of

macro proc.leave {

  ; pop rX
  proc.restore hier.cproc

  ; get stack was used
  sfield.get n,hier.cproc,$proc.stksize

  ; ^paste epilogue
  n equ n*-1
  if n > 0
    leave

  end if


  proc.close_scope hier.cproc

}

; ---   *   ---   *   ---
; preserve registers

macro proc.preserve base {

  local list

  ; get list of registers
  match name,base \{
    list equ name\#.$proc.rpres_a

  \}

  ; ^iter thru
  macro inner [rX] \{
    forward
      push rX

  \}

  ; ^invoke
  match rX,list \{
    inner rX

  \}

}

; ---   *   ---   *   ---
; ^restore registers

macro proc.restore base {

  local list

  ; get list of registers
  match name,base \{
    list equ name\#.$proc.rpres_b

  \}

  ; ^iter thru
  macro inner [rX] \{
    forward
      pop rX

  \}

  ; ^invoke
  match rX,list \{
    inner rX

  \}

}

; ---   *   ---   *   ---
; recursive [label].inline

inline fix macro inline.inner F {\
  rept 1 \{hier.cproc equ F\}\
  rept 1 \{F#.#inline\}\
  rept 1 \{restore hier.cproc\}\
\
}\
inline.inner 

; ---   *   ---   *   ---
; ^for use within inlines themselves

dpline fix macro dpline.inner F \{\
  rept 1 \\{hier.cproc equ F\\}\
  rept 1 \\{F\#.#inline\\}\
  rept 1 \\{restore hier.cproc\\}\
\
\}\
dpline.inner 

; ---   *   ---   *   ---
