; ---   *   ---   *   ---
; STYLE
; The ubiquitous and oft-used
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Arstd.INCFILE
  include '%ARPATH%/forge/Arstd/INCFILE.inc'

end if

; ---   *   ---   *   ---
; info

  TITLE     Style

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

  define    loaded?Style 1

; ---   *   ---   *   ---
; pastes comma separated as lines

macro npaste [line] {forward line}

; ---   *   ---   *   ---
; space cats at end

macro spacecat s,token {

  match any,s \{s equ s token\}
  match ,s \{s equ token\}

}

; ^space cats at beg
macro r_spacecat s,token {

  match any,s \{s equ token s\}
  match ,s \{s equ token\}

}

; ---   *   ---   *   ---
; uses a symbolic constant as a counter (!!)

macro symcnt sym,value=+1 {

  local cnt

  ; increment
  cnt equ sym
  cnt equ cnt#value

  sym equ cnt

}

; ---   *   ---   *   ---
; stringify and cat

macro strfcat a,b,c {
  a equ `a#`b#`c

}

; ---   *   ---   *   ---
; sets a to catted a,b,c
; ignores b if a is blank

macro stirr7 a,b,c {

  match any,a \{
    a equ any\#b#c

  \}

  match ,a \{
    a equ c

  \}

}

; cat b to beg of a
macro prefix a,b {
  a equ b#a

}

; ---   *   ---   *   ---
