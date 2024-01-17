; ---   *   ---   *   ---
; A9M VALLOC BLOCK
; Slice o' mem
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.valloc.block

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; base struc

vreg.new valloc.block

  szmy byte head
  szmy byte idex
  szmy byte pos
  szmy byte reqm

vreg.end
sizeof.valloc.block=$08

; ---   *   ---   *   ---
; occupies block

macro valloc.block.take {

  ; set bits
  $mov cr,byte [@blk.reqm]
  $shl cr,byte [@blk.pos]

  $or  qword [vmc.USRMEM:ar+valloc.part.mask],cr


  ; write block header
  valloc.block.get_head

  $add ar,sizeof.valloc.part
  $mov dword [vmc.USRMEM:ar+cr],dword [@blk]


  ; reset out
  $add ar,cr
  $add ar,sizeof.valloc.block

  ; make addr absolute
  match id , vmc.USRMEM \{
    $add ar,id\#.beg

  \}

}

; ---   *   ---   *   ---
; ^undo

macro valloc.block.give {

  $mov er,byte [@blk.idex]
  $mov fr,byte [@blk.head]

  valloc.part.get_nth er,fr

  $mov cr,byte [@blk.reqm]
  $shl cr,byte [@blk.pos]
  $not cr

  $and qword [vmc.USRMEM:ar+valloc.part.mask],cr
  $add ar,sizeof.valloc.part

  ; clear block header
  match id , src \{

    valloc.block.get_head

    ; die on null
    $mov br,dword [vmc.USRMEM:ar+cr]

    $on br = 0
      out@err 'vfree called on a fred block'

    end if

    ; ^else *set* to null
    $mov dword [vmc.USRMEM:ar+cr],$00

  \}

}

; ---   *   ---   *   ---
; get addr of block

macro valloc.block.get_head {

  ; get sub-block size
  valloc.block.get_sb_size

  ; scale up to partition size
  $mov cr,byte [@blk.pos]
  $mul cr,dr

}

; ---   *   ---   *   ---
; get size of a sub-block,
; ie ezy per bit of the
; partition mask

macro valloc.block.get_sb_size {

  $mov br,byte [@blk.idex]
  $add br,$06
  $mov dr,1
  $shl dr,br

}

; ---   *   ---   *   ---
; get sub-block count accto
; block mask

macro valloc.block.get_sb_cnt {
  $mov br,byte [@blk.reqm]
  $not br
  $bsf br,br

}

; ---   *   ---   *   ---
; get full size of block,
; that includes the header

macro valloc.block.get_real_size {

  ; get sub-block count and size
  valloc.block.get_sb_size
  valloc.block.get_sb_cnt

  ; ^mul by each other
  $mul br,dr

}

; ---   *   ---   *   ---
; get size of buffer, ie
; total minus block header

macro valloc.block.get_size {
  valloc.block.get_real_size
  $sub br,sizeof.valloc.block

}

; ---   *   ---   *   ---
; copies header from usrmem
; to ctx on stack

macro valloc.block.deref addr {

  match id , dst \{
    $mov ar,addr
    $sub ar,sizeof.valloc.block
    $mov dword [@blk],dword [ar]

  \}

  ; make addr relative
  match id , vmc.USRMEM \{
    $sub ar,id\#.beg

  \}

}

; ---   *   ---   *   ---
