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

  sizeof.byte  = $0001
  sizep2.byte  = $0000

  sizeof.word  = $0002
  sizep2.word  = $0001

  sizeof.dword = $0004
  sizep2.dword = $0002

  sizeof.qword = $0008
  sizep2.qword = $0003

  sizeof.unit  = $0010
  sizep2.unit  = $0004

  sizeof.half  = $0020
  sizep2.half  = $0005

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

  local mode
  mode equ

  macro inner dst,src \{
    dst equ dst src

  \}

  forward

    match =r , type \{
      inner mode,readable

    \}

    match =x , type \{
      inner mode,executable

    \}

    match =w , type \{
      inner mode,writeable

    \}

  common

    macro inner [M] \{
      segment M

    \}

    match any,mode \{
      inner mode

    \}

    unit.malign

}

; ---   *   ---   *   ---
; division templates

macro unit.div.proto name {

  macro name#.urdiv \{
    UInt.urdivp2.proto sizep2.#name

  \}

  macro name#.align \{
    UInt.align.proto sizep2.#name

  \}

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
