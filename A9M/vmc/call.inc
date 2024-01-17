; ---   *   ---   *   ---
; A9M VMC CALL
; Operator, get me the
; proc on the line...
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.vmc.call

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define    vmc.ARGV

; ---   *   ---   *   ---
; cats to argv
; used by call!

macro $pass [item] {

  forward

    local    X
    vmc.bget X,item

    commacat vmc.ARGV,X

}

; ---   *   ---   *   ---
; when you want to decode a
; value for a call

macro vmc.bget dst,src {

  local value

  match id , value \{
    vmc.decode id,src,read
    dst equ id

  \}

}

; ---   *   ---   *   ---
; ^here we go...

$RECURSIVE $call,fn

  macro $call fn \{

    local ok
    ok equ 0

;    ; setup the F "addresses" ;>
;    vmc.REG.xp equ vmc.REG.xs
;    vmc.REG.xs equ fn

    ; have args, pass and clear
    match list , vmc.ARGV \\{

      vmc.ARGV equ

      fn list
      ok equ 1

    \\}

    ; argless
    match =0 , ok \\{fn\\}


;    ; remember who you are, simba!
;    restore vmc.REG.xs
;    restore vmc.REG.xp

  \}

$RECURSIVE.end

; ---   *   ---   *   ---
