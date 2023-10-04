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

  VERSION   v0.00.3b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  sizeof.unit  = $0010
  sizep2.unit  = $0004

  sizeof.line  = $0040
  sizep2.line  = $0006

  sizeof.dline = $0080
  sizep2.dline = $0007

  sizeof.qline = $0100
  sizep2.qline = $0008

  sizeof.xline = $0200
  sizep2.xline = $0009

  sizeof.yline = $0400
  sizep2.yline = $000A

  sizeof.zline = $0800
  sizep2.zline = $000B

  sizeof.page  = $1000
  sizep2.page  = $000C

  sizeof.dpage = $2000
  sizep2.dpage = $000D

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
unit.div.proto dline
unit.div.proto qline
unit.div.proto xline
unit.div.proto yline
unit.div.proto zline

unit.div.proto page
unit.div.proto dpage

; ---   *   ---   *   ---
