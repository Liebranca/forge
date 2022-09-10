; ---   *   ---   *   ---
; ARSTD LYCON
; dus the lycon charset
; not a real utf8 encoder ;>
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

; ---   *   ---   *   ---
; info

  TITLE     Arstd.Lycon

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---

macro lydu [char] {

  forward

    low=(char and $FF)
    high=(((char shr 8)-1)+low+$80)/0x40

    low=(low or $80) and $BF
    high=(high) + $C2

    du (low shl 8) or high

}

; ---   *   ---   *   ---
