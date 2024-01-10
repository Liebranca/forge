; ---   *   ---   *   ---
; A9M L1:ROM
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
  use '.inc' A9M::vhash
  use '.inc' A9M::SHARE::L1

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.ROM.L1

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; crux

define    tab
vhash.new tab,A9M.L1.head,$06,A9M.L1.TOKEN_SZ shr 3

$mov      ptr ice,ptr tab

; ---   *   ---   *   ---
; make value placeholder

define          item
A9M.L1.head.new item

; ---   *   ---   *   ---
; table fill helper

macro settab X,[tag] {

  common
    local i
    i = 0

    A9M.L1.head.TRF.set item,X

  forward
    A9M.L1.head.SID.set item,i
    vhash.store tag,% item

    i = i+1

}

; ---   *   ---   *   ---
; fill table

; top-level hierarchicals
settab $08,\
  'clan','rom','reg','proc','blk'

; hier specs
settab $01,\
  'iface','guts'

; width specs
settab $11,\
  'byte','wide','brad','word'


; ---   *   ---   *   ---
; save tab

vhash.prich tab
err
;vhash.to_disk tab

; ---   *   ---   *   ---
