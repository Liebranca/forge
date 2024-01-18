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

  VERSION   v0.00.4b
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

  define    vmc.USRMEM

  $casseg   vmc.USRMEM,blk sizeof.valloc.head
  vmem.seek vmc.USRMEM,sizeof.valloc.head

  define    valloc.have_blk 0

; ---   *   ---   *   ---
; load/set ctx struc

macro valloc.loadctx {

  match =0 , valloc.have_blk \{

    $enter

    $loadctx valloc.block blk
    $mov     dword [@blk],$00

  \}

}

; ---   *   ---   *   ---
; ^undo

macro valloc.unloadctx {

  match =0 , valloc.have_blk \{
    $unloadctx
    $leave

  \}

}

; ---   *   ---   *   ---
; crux

macro valloc sz {

  ; setup
  valloc.loadctx

  ; add size of block header
  ; to requested
  local req
  req = sz+sizeof.valloc.block

  ; get partition
  valloc.part.search req

  ; ^occupy
  valloc.block.take


  ; cleanup
  valloc.unloadctx

}

; ---   *   ---   *   ---
; ^undo

macro vfree addr {

  ; setup
  valloc.loadctx

  ; get block header
  valloc.block.deref addr

  ; ^find part and release
  valloc.block.give

  ; nullout
  $mov addr,$00


  ; cleanup
  valloc.unloadctx

}

; ---   *   ---   *   ---
; ^a bit of both ;>

macro vrealloc addr,sz {


  ; setup
  valloc.loadctx
  valloc.have_blk equ 1

  ; save tmp
  local old
  $mov old,addr


  ; release old
  vfree addr

  ; ^get old size
  local len

  valloc.block.get_size
  $mov len,br


  ; get new
  local  new
  valloc sz
  $mov   new,ar

  ; ^copy data if addr changed
  if ~(old = new)

    $xor br,br
    repeat len shr $03

      $mov qword [new+br],\
        qword [old+br]

      $add br,$08

    end repeat

  end if


  ; cleanup
  valloc.have_blk equ 0
  valloc.unloadctx

}

; ---   *   ---   *   ---
