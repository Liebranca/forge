; ---   *   ---   *   ---
; A9M VMPART
; Spatial bitmasks
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.vmpart

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; search struc

vreg.new vmpart.lkp

  szmy qword mask
  szmy qword kmask
  szmy qword elem

  szmy byte  bit
  szmy byte  idex

vreg.end

; ---   *   ---   *   ---
; cstruc

macro vmpart.new dst,size,addr= {

  local ok
  local sz

  sz = (size)*8
  ok equ 0

  ; from existing buffer?
  match any , addr \{

    match =view off atid, any \\{
      vmem.view dst,atid,off,sz

    \\}

    match =seg atid , any \\{
      vmem.seg dst,atid,blk sz

    \\}

    ok equ 1

  \}

  ; ^nope, make new!
  match =0 , ok \{
    vmem.new dst,blk sz

  \}

}

; ---   *   ---   *   ---
; map key in ar to bitmask coords

macro vmpart.keycoord src {

  ; load ctx struc
  $mov ptr ctx,src

  ; map key to mask idex (key/64)
  $mov cr,ar
  $shr cr,sizep2.line
  $mov %[ctx idex],cr

  ; map key to mask *bit* idex
  $mov dr,cr
  $shl dr,sizep2.line

  $mov er,ar
  $sub er,dr
  $mov %[ctx bit],er

  ; get mask *elem* bit
  $mov dr,1
  $shl dr,er

  $mov %[ctx elem],dr

}

; ---   *   ---   *   ---
; ^get masks from keycoords

macro vmpart.get_mask src,atid,mode=single {

  vmpart._get_mask %[ctx mask],src,atid

  match =dual , mode \{
    vmpart._get_mask %[ctx kmask],src,k#atid

  \}

}

; ---   *   ---   *   ---
; ^guts

macro vmpart._get_mask dst,src,atid {

  match id , src \{
    $mov dst,qword [id\#.#atid+cr*8]

  \}

}

; ---   *   ---   *   ---
; tries to find free slot

macro vmpart.search {

  ; R search
  $bsf br,ar

  ; ^L search on fail
  $on br > $3F
    $mov br,ar
    $mov dr,%[ctx bit]
    $shr br,dr
    $bsf br,ar

  end if


  ; ^recalc element pos
  $mov %[ctx bit],br

  $mov dr,1
  $shl dr,br
  $mov %[ctx elem],dr

}

; ---   *   ---   *   ---
