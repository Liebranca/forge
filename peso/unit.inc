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

library.import

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
; make aligned segment of type

macro SEG MS {

  local type
  local name
  local mode
  local size

  type equ
  name equ
  mode equ MS
  size equ unit


  match M S , MS \{
    mode equ M
    size equ S

  \}


  ; constants
  match =ROM , mode \{
    type equ readable
    name equ '.rodata'

  \}

  ; globals
  match =RAM , mode \{
    type equ readable writeable
    name equ '.data'

  \}

  ; code
  match =EXE , mode \{
    type equ readable executable
    name equ '.text'

  \}


  ; ^paste in
  match any,size \{
    MAM.segment name,type,sizeof.\#any

  \}

}

; ---   *   ---   *   ---
; ^sugar

macro SEG.ice NS,type {

  local size
  local name
  local status

  size   equ unit
  name   equ
  status equ 0

  ; [name,size] provided
  match N S , NS \{
    size   equ S
    name   equ N

    status equ 1

  \}

  ; ^size omitted
  match =0 N , status NS \{
    name equ N

  \}


  ; ^invoke
  SEG type size

  ; ^put label if any
  match any,name \{
    any\#:

  \}

}

; ---   *   ---   *   ---
; ^ice-of

macro ROMSEG NS= {SEG.ice NS,ROM}
macro RAMSEG NS= {SEG.ice NS,RAM}
macro EXESEG NS= {SEG.ice NS,EXE}

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
    align sizeof.#name

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
