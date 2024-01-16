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

  VERSION   v0.00.3b
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
    $bsf br,br

  end if


  ; ^recalc element pos
  $mov %[ctx bit],br

  $mov dr,1
  $shl dr,br
  $mov %[ctx elem],dr

}

; ---   *   ---   *   ---
; find first free bit

macro vmpart.get_free {

  ; get first unset
  $xor cr,cr
  $not er
  $bsf fr,er

  ; ^skip if all set
  $on ~(fr=0)
    $mov cr,fr

  end if

  $mov ar,cr
  $not er

}

; ---   *   ---   *   ---
; ^shift to fred

macro vmpart.shr_free {

  ; get first unset
  vmpart.get_free

  ; ^shift to start of free space
  $shr er,cr

  $add dr,ar
  $mov ar,er

  ; ^add shift-sized stop
  $mov er,$01
  $shl er,cr
  $dec er
  $ror er,cr

  $or  ar,er

}

; ---   *   ---   *   ---
; ^find last occupied bit

macro vmpart.get_occu {

  ; get idex
  $xor cr,cr
  $bsr fr,er

  ; conditional mov && add
  $mov br,$01

  $on fr = 0
    $mov br,cr

  else
    $mov cr,fr

  end if


  ; ^A+(1*?A)
  $add cr,br

  ; cleanup and give
  $mov ar,cr

}

; ---   *   ---   *   ---
; ^shift them out

macro vmpart.shr_occu {

  ; get first set
  vmpart.get_occu

  ; ^shift it out
  $shr er,cr
  $add dr,ar


  ; cleanup and give
  $mov ar,er

}

; ---   *   ---   *   ---
; get N free bits

macro vmpart.fit {

  ; save tmp
  $push  br
  $qword reqm er
  $qword mask fr

  $enter


  ; reset counters
  $xor dr,dr

  ; get next free section
  while 1

    ; save tmp
    $mov qword [@mask],fr

    ; get next free chunk
    $mov er,fr

    vmpart.shr_free
    $mov fr,ar

    ; ^compare to requested
    ; repeat if free chunk is too small
    $mov ar,qword [@reqm]
    $and ar,fr

    $break on ar  = $00
    $break on dr >= $3F


    ; ^get bits to shift if no fit
    ; skip occupied portion
    $mov er,ar
    vmpart.get_occu


    ; ^shift it out
    $dec ar
    $mov fr,qword [@mask]
    $shr fr,cr
    $add dr,ar

    ; ^add shift-sized stop
    $mov ar,$01
    $shl ar,cr
    $ror ar,cr

    $or  fr,ar

    ; rept on X < 63
    $break on dr >= $3F


  end while


  ; cleanup and give
  $mov ar,dr
  $mov er,qword [@reqm]

  $leave
  $pop br

}

; ---   *   ---   *   ---
