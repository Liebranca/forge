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

  VERSION   v0.00.3b
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

; ---   *   ---   *   ---
; crux

macro valloc dst,sz {

  ; add size of block header
  local req
  req = sz+sizeof.valloc.block

  ; get partition
  valloc.part.search valloc.ctx,req

  ; ^occupy
  valloc.block.take valloc.ctx

  ; give beg of buffer
  $mov dst,ar

}

; ---   *   ---   *   ---
; ^undo

macro vfree addr {

  ; get block header
  valloc.block.deref valloc.ctx,addr

  ; ^find part and release
  valloc.block.give valloc.ctx

  ; nullout
  $mov addr,$00

}

; ---   *   ---   *   ---
; ^a bit of both ;>

macro vrealloc addr,sz {

  ; save tmp
  local old
  old = addr


  ; release old
  vfree addr

  ; ^get old size
  local len

  valloc.block.get_size valloc.ctx
  $mov len,br


  ; get new
  valloc addr,sz

  ; ^copy data if addr changed
  if ~(old = addr)

    $xor ar,ar
    repeat len shr $03

      $mov qword [VALLOCM+addr+ar],\
        qword [VALLOCM+old+ar]

      $add ar,$08

    end repeat

  end if

}

; ---   *   ---   *   ---
