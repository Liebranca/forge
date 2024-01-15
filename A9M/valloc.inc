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

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.valloc

  VERSION   v0.00.1b
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
; block header

vreg.new valloc.block

  szmy dword size
  szmy dword idex

  szmy qword addr

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

  ; get partition block
  valloc.get_block req

}

; ---   *   ---   *   ---
; get slot in partition

macro valloc.get_block req {

  local have
  have = 0

  $xor fr,fr

  ; get partition
  valloc.get_part req

;  ; ^scour!
;  while have = 0
;
;    ; read mask
;    $mov er,req
;    vmpart.fit VALLOCM
;
;
;  end while

}

; ---   *   ---   *   ---
