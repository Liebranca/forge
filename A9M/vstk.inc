; ---   *   ---   *   ---
; A9M VSTK
; Phantom piles!
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.vstk

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

if ~ defined A9M.STACK_SZ
  A9M.STACK_SZ=$40

end if

; ---   *   ---   *   ---
; write to current top

macro $push src {

  local ok
  local size
  local value

  ; defaults
  value equ src
  size  equ qword

  ; size passed?
  match sz v , src \{
    size  equ sz
    value equ v

  \}

  ; ^paste ops
  match sz v , size value \{
    $sub sp,sizeof.\#sz
    $mov sz [vmc.STK+sp],v

  \}

}

; ---   *   ---   *   ---
; ^read from current top

macro $pop dst {

  local ok
  local size
  local value

  ; defaults
  value equ dst
  size  equ qword

  ; size passed?
  match sz v , dst \{
    size  equ sz
    value equ v

  \}

  ; ^paste ops
  match sz v , size value \{
    $mov v,sz [vmc.STK+sp]
    $add sp,sizeof.\#sz

  \}

}

; ---   *   ---   *   ---
; setup frame

macro $enter size=$00 {

  $push sb
  $mov  sb,sp
  $sub  sp,size

  vmc.STK.frame_sz equ size

}

; ---   *   ---   *   ---
; ^cleanup

macro $leave {

  $add sp,vmc.STK.frame_sz
  $pop sb

  restore vmc.STK.frame_sz

}

; ---   *   ---   *   ---
