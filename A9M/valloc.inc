; ---   *   ---   *   ---
; A9M VALLOC
; Get money
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
  use '.inc' A9M::vmc
  use '.inc' A9M::vmpart

  use '.inc' A9M::valloc::part
  use '.inc' A9M::valloc::block

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.valloc

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; base header

vreg.new valloc.head
  szmy qword line_part
  szmy qword dline_part
  szmy qword qline_part
  szmy qword xline_part

vreg.end

; ---   *   ---   *   ---
; GBL

  define     VALLOCM
  vmem.new   VALLOCM,blk sizeof.valloc.head
  vmem.seek  VALLOCM,sizeof.valloc.head

  ; static lookup ctx
  valloc.block.new valloc._lkp_0

; ---   *   ---   *   ---
; crux

macro valloc dst,sz {

  ; add size of block header
  local req
  req = sz+sizeof.valloc.block

  ; get partition
  valloc.part.search valloc._lkp_0,req

  ; ^occupy
  valloc.block.take valloc._lkp_0

  ; give beg of buffer
  $mov dst,ar

}

; ---   *   ---   *   ---
; ^undo

macro vfree addr {

  match id , valloc._lkp_0 \{

    $mov ar,addr
    $sub ar,sizeof.valloc.block
    $mov dword [id\#%origin],dword [VALLOCM+ar]

    valloc.block.give valloc._lkp_0

  \}

  $mov addr,$00

}

; ---   *   ---   *   ---
