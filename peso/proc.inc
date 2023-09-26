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

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'
  use '.inc' peso::reg

import

; ---   *   ---   *   ---
; info

  TITLE     peso.proc

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define hier.cproc

; ---   *   ---   *   ---
; start new block

macro proc.new name {

  hier.cproc equ name

  define name#.$proc.vars
  define name#.$proc.rpres
  define name#.$proc.stksize 0

  unit.malign
  name#:

}

; ---   *   ---   *   ---
; push register list, then
; reserve N bytes in stack

macro proc.enter [rX] {

  forward

    match name,rX \{
      proc.preserve rX

    \}

  common

    sfield.get n,hier.cproc,$proc.stksize

    ; get size in units
    n=n+(sizeof.unit-1)
    n=n shr sizep2.unit
    n=n shl sizep2.unit

    ; ^paste prologue
    if n > 0
      push rbp
      mov  rbp,rsp
      sub  rsp,n

    end if

}

; ---   *   ---   *   ---
; ^adds to preserved register list

macro proc.preserve rX {
  sfield.unshift hier.cproc,$proc.rpres,rX
  push rX

}

; ---   *   ---   *   ---
; add stack space

macro proc.var sn {

  match size name,sn \{

    ; get current top
    size equ sizeof.\#size

    ; calc new size && var offset
    sfield.get offset,hier.cproc,$proc.stksize

    top=offset+size

    ; set name -> rbp-offset
    proc.var_decl name,top

    ; reset stack top
    sfield.set  hier.cproc,$proc.stksize,top

  \}

}

; ---   *   ---   *   ---
; ^make define for varname

macro proc.var_decl name,offset {
  define name rbp-offset

}

; ---   *   ---   *   ---
; ^pops

macro proc.leave {

  ; restore registers
  proc.restore hier.cproc

  ; get stack was used
  sfield.get n,hier.cproc,$proc.stksize

  ; ^paste epilogue
  if n > 0
    pop rbp

  end if

}

; ---   *   ---   *   ---
; ^restore registers

macro proc.restore base {

  local list

  ; get list of registers
  match name,base \{
    list equ name\#.$proc.rpres

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
