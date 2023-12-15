; ---   *   ---   *   ---
; PESO SEG
; Dude, what IS a section?!
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     peso.seg

  VERSION   v0.00.2b
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

  sizeof.xword = sizeof.unit
  sizep2.xword = sizep2.unit

  sizeof.half  = $0020
  sizep2.half  = $0005

  sizeof.yword = sizeof.half
  sizep2.yword = sizep2.half

  sizeof.line  = $0040
  sizep2.line  = $0006

  sizeof.zword = sizeof.line
  sizep2.zword = sizep2.line

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
; GBL

  define SEG.name
  define SEG.vflag

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
    name equ '.data' writeable

  \}

  ; code
  match =EXE , mode \{
    type equ readable executable
    name equ '.text' executable

  \}


  ; ^paste in
  match any,size \{
    MAM.segment name,type,sizeof.\#any

  \}

}

; ---   *   ---   *   ---
; ^sugar

macro SEG.ice NS,vflag,type {

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

    SEG.name  equ any
    SEG.vflag equ vflag

    MAM.sym any,vflag

  \}

}

; ---   *   ---   *   ---
; ^ice-of

macro ROMSEG NS=,vflag= {SEG.ice NS,vflag,ROM}
macro RAMSEG NS=,vflag= {SEG.ice NS,vflag,RAM}
macro EXESEG NS=,vflag= {SEG.ice NS,vflag,EXE}

; ---   *   ---   *   ---
; register offset within segment

macro segptr NC {

  match pre name ct , SEG.name NC \{
    MAM.sym pre\#.\#name,SEG.vflag
    ct

  \}

}

; ---   *   ---   *   ---
