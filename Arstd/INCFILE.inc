; ---   *   ---   *   ---
; INCFILE
; Book-keeping
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; quick and dirty namespace aggregation ;>

macro INFO_FIELD line {

  match module field value,this?module line \{

    module \# ? \# field equ module \# ? \# field
    define module \# ? \# field value

  \}

}

; ---   *   ---   *   ---
; ^please only aggregate to it this way

macro TITLE name {
  define this?module  name
  define loaded?#name 1

}

macro VERSION number {
  INFO_FIELD version number

}

macro AUTHOR name {
  INFO_FIELD author name

}

; ---   *   ---   *   ---
; an example of usage:

  TITLE     Arstd.INCFILE

  VERSION   v0.01.1a
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
