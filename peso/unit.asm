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

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  define sizeof.unit $10
  define sizep2.unit $04

  define sizeof.line $40
  define sizep2.line $06

  define sizeof.page $1000
  define sizep2.page $0C

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
; division templates

macro unit.div.proto name {


  align $10
  name#.urdiv:

  macro name#.urdiv.inline \{
    UInt.urdivp2.proto sizep2.#name

  \}

  name#.urdiv.inline
  ret


  align $10
  name#.align:

  macro name#.align.inline \{
    UInt.align.proto sizep2.#name

  \}

  name#.align.inline
  ret

}

; ---   *   ---   *   ---
; ^ice

unit.salign r,x

unit.div.proto unit
unit.div.proto line
unit.div.proto page

; ---   *   ---   *   ---
