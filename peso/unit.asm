; ---   *   ---   *   ---
; PESO UNIT
; Basic metric of memory
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
  use '.asm' Arstd::UInt

import

; ---   *   ---   *   ---
; info

  TITLE     peso.unit

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  define sizeof.unit $10
  define sizep2.unit $04

; ---   *   ---   *   ---
; memory align to unit

macro unit.malign {
  align sizeof.unit

}

; ---   *   ---   *   ---
; ^make aligned segment of type

macro unit.salign [type] {

  define .mode

  forward

    match =r , type \{
      .mode equ .mode readable

    \}

    match =x ,type \{
      .mode equ .mode executable

    \}

    match =w ,type \{
      .mode equ .mode writeable

    \}

  common

    segment .mode
    unit.malign

}

; ---   *   ---   *   ---
; division by 16 rounded up

unit.salign r,x

unit.align:
macro unit.align.inline {

  ; scale by unit size
  mov rcx,sizep2.unit

  ; round-up division
  ; then apply scale
  UInt.urdivp2.inline
  shl rax,sizep2.unit

}

  ; ^invoke
  unit.align.inline

  ret

; ---   *   ---   *   ---
