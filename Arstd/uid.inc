; ---   *   ---   *   ---
; UID
; Ice boxing
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     Arstd.uid

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; get unique id
;
; doesn't make sense,
; but it works ;>

macro uid.new dst,prefix,_nullarg& {
  local UID
  dst equ prefix#UID

}

; ---   *   ---   *   ---
; counters ctl

macro uid.cnt.new prefix {
  define prefix#._cnt 0

}

macro uid.cnt._flatten prefix {
  rept 1 cnt:prefix#._cnt \{
    prefix#._cnt equ cnt

  \}

}

macro uid.cnt.tick prefix {
  prefix#._cnt equ prefix#._cnt+1
  uid.cnt._flatten prefix

}

; ---   *   ---   *   ---
