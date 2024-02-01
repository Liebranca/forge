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

  VERSION   v0.00.6b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  define sizebs.nibb  $0004
  define sizebm.nibb  $000F

  define sizeof.byte  $0001
  define sizep2.byte  $0000
  define sizebs.byte  $0008
  define sizebm.byte  $00FF
  define negate.byte  $007F

  define sizeof.word  $0002
  define sizep2.word  $0001
  define sizebs.word  $0010
  define sizebm.word  $FFFF
  define negate.word  $7FFF

  define sizeof.dword $0004
  define sizep2.dword $0002
  define sizebs.dword $0020
  define sizebm.dword $FFFFFFFF
  define negate.dword $7FFFFFFF

  define sizeof.qword $0008
  define sizep2.qword $0003
  define sizebs.qword $0040
  define sizebm.qword $FFFFFFFFFFFFFFFF
  define negate.qword $7FFFFFFFFFFFFFFF

  define sizeof.unit  $0010
  define sizep2.unit  $0004

  define sizeof.xword $0010
  define sizep2.xword $0004

  define sizeof.half  $0020
  define sizep2.half  $0005

  define sizeof.yword $0020
  define sizep2.yword $0005

  define sizeof.line  $0040
  define sizep2.line  $0006

  define sizeof.zword $0040
  define sizep2.zword $0006

  define sizeof.dline $0080
  define sizep2.dline $0007
  define sizeof.qline $0100
  define sizep2.qline $0008

  define sizeof.xline $0200
  define sizep2.xline $0009

  define sizeof.yline $0400
  define sizep2.yline $000A

  define sizeof.zline $0800
  define sizep2.zline $000B

  define sizeof.page  $1000
  define sizep2.page  $000C

  define sizeof.dpage $2000
  define sizep2.dpage $000D

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
