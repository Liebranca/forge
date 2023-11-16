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
  use '.hed' Arstd::UInt

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.unit

  VERSION   v0.00.5b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; template-spawn

macro unit.proto name {

  macro name#.urdiv \{
    UInt.urdivp2.proto sizep2.#name

  \}

  macro name#.align \{
    UInt.align.proto sizep2.#name

  \}

  macro name#.malign \{
    MAM.calign name

  \}

}

; ---   *   ---   *   ---
; ^ice

unit.proto unit

unit.proto line
unit.proto dline
unit.proto qline
unit.proto xline
unit.proto yline
unit.proto zline

unit.proto page
unit.proto dpage

; ---   *   ---   *   ---
