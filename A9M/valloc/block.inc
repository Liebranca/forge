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

  VERSION   v0.00.1b
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
; GBL

  valloc.block.new valloc.ctx

; ---   *   ---   *   ---
; occupies block

macro valloc.block.take src {

  ; set bits
  $mov cr,%[src reqm]
  $shl cr,%[src pos]

  $or  qword [VALLOCM+ar+valloc.part.mask],cr


  ; write block header
  match id , src \{

    valloc.block.get_head src

    $add ar,sizeof.valloc.part
    $mov dword [VALLOCM+ar+cr],dword [id\#%origin]

  \}

  ; reset out
  $add ar,cr
  $add ar,sizeof.valloc.block

}

; ---   *   ---   *   ---
; ^undo

macro valloc.block.give src {

  $mov er,%[src idex]
  $mov fr,%[src head]

  valloc.part.get_nth er,fr

  $mov cr,%[src reqm]
  $shl cr,%[src pos]
  $not cr

  $and qword [VALLOCM+ar+valloc.part.mask],cr

  ; clear block header
  match id , src \{

    valloc.block.get_head src

    ; die on null
    $mov br,dword [VALLOCM+ar+cr]
    $on br = 0
      out@err 'vfree called on a fred block'

    end if

    ; ^else *set* to null
    $add ar,sizeof.valloc.part
    $mov dword [VALLOCM+ar+cr],$00

  \}

}

; ---   *   ---   *   ---
; get addr of block

macro valloc.block.get_head src {

  ; get sub-block size
  valloc.block.get_sb_size src

  ; scale up to partition size
  $mov cr,%[src pos]
  $mul cr,dr

}

; ---   *   ---   *   ---
; get size of a sub-block,
; ie ezy per bit of the
; partition mask

macro valloc.block.get_sb_size src {

  $mov br,%[src idex]
  $add br,$06
  $mov dr,1
  $shl dr,br

}

; ---   *   ---   *   ---
; get sub-block count accto
; block mask

macro valloc.block.get_sb_cnt src {
  $mov br,%[src reqm]
  $not br
  $bsf br,br

}

; ---   *   ---   *   ---
; get full size of block,
; that includes the header

macro valloc.block.get_real_size src {

  ; get sub-block count and size
  valloc.block.get_sb_size src
  valloc.block.get_sb_cnt src

  ; ^mul by each other
  $mul br,dr

}

; ---   *   ---   *   ---
; get size of buffer, ie
; total minus block header

macro valloc.block.get_size src {
  valloc.block.get_real_size src
  $sub br,sizeof.valloc.block

}

; ---   *   ---   *   ---
; copies block header to
; struc, based on addr

macro valloc.block.deref dst,addr {

  match id , dst \{
    $mov ar,addr
    $sub ar,sizeof.valloc.block
    $mov dword [id\#%origin],dword [VALLOCM+ar]

  \}

}

; ---   *   ---   *   ---
