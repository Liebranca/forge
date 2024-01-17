; ---   *   ---   *   ---
; A9M VMC ISARCANA
; Instructions unique
; to the Arcane 9
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.vmc.isarcana

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define vmc.REG.ctx_type

; ---   *   ---   *   ---
; load ctx register with a
; struc ptr, then alias
; access to it's fields

macro $loadctx TN {

  match type name , TN \{

    ; save previous
    $push qword ctx

    ; reserve mem and get addr
    $sub sp,sizeof.\#type
    $lea ctx,[vmc.STACK:sp]

    ; typecast
    $cast type name ctx

    ; remember passed type
    vmc.REG.ctx_type equ type name

  \}

}

; ---   *   ---   *   ---
; ^undo

macro $unloadctx {

  match type name , vmc.REG.ctx_type \{

    ; retire aliases
    $undef name

    ; give back memory and get previous
    $add sp,sizeof.\#type
    $pop qword ctx

  \}

  ; rollback
  restore vmc.REG.ctx_type

}

; ---   *   ---   *   ---
; swap two values

macro $swap dst,src {

  local value
  local tmp

  value = 0
  tmp   = 0

  vmc.decode value,src,read
  vmc.decode tmp,dst,read

  vmc.decode value,dst,write
  vmc.decode tmp,src,write

}

; ---   *   ---   *   ---
; get N-bits, all set to one
; ie, BONES

macro $bones dst,src {

  local mask
  local bits

  vmc.decode bits,src,read

  if bits > $3F
    mask=sizebm.qword

  else
    mask=(1 shl bits)-1

  end if

  vmc.decode mask,dst,write

}

; ---   *   ---   *   ---
; rounded-up division by
; a power of 2

macro $urdivp2 dst,src,N {

  local w0
  local w1

  w0=0
  w1=0

  vmc.decode    w0,src,read
  vmc.decode    w1,N,read

  vuint.urdivp2 w0,w0,w1
  vmc.decode    w0,dst,write

}

; ---   *   ---   *   ---
; these are not *real*
; instructions, just unique
; enough to the vmc to be
; thrown here!

; ---   *   ---   *   ---
; enter/leave addressing space

macro $casset id {

  local ok
  ok equ 0

  ; return to previous space
  match =rewind , id\{
    restore vmc.CAS
    ok equ 1

  \}

  ; ^set new
  match =0 , ok \{
    vmc.CAS equ id

  \}

}

; ---   *   ---   *   ---
; ^make new segment on CAS

macro $casseg dst,ct& {
  vmem.seg dst,vmc.CAS,ct

}

; ---   *   ---   *   ---
; ^wraps for extending
; such a segment.
;
; this is needed for CAS
; to know it's actual size
; when it's indirectly
; made larger

macro $caswrite dst,ct& {

  match par id , vmc.CAS dst \{

    ; make note of old size
    local old
    old = id\#.size

    ; ^grow segment
    vmem.write dst,ct

    ; ^get size difference
    local diff
    diff = id\#.size - old

    ; ^add diff to root size
    par\#.size = par\#.size + diff
    par\#.pad  = par\#.pad  + diff

  \}

}

; ---   *   ---   *   ---
; get view of memory on
; *current* addressing space

macro $view DOL {

  ; eg name at $00:$40
  match dst =at _off =: _len , DOL \{

    ; unpack args
    local off
    local len

    vmc.decode len,_len,read
    vmc.decode off,_off,read

    ; ^give
    vmem.view dst,vmc.CAS,off,len

  \}

}

; ---   *   ---   *   ---
; make symbolic lises

macro $def NV {

  match id value , NV \{
    define @\#id value

  \}

}

; ---   *   ---   *   ---
; ^plus struc fields

macro $cast TNV {

  match type id value , TNV \{

    $def id value

    define @\#id\#%casted type
    vreg.from_ptr @\#id,type,define

  \}

}

; ---   *   ---   *   ---
; ^undo for both

macro $undef name {

  match id , name \{

    restore @\#id

    match any , @\#id\#%casted \\{
      vreg.from_ptr @\#id,any,restore
      restore @\#id\#%casted

    \\}

  \}

}

; ---   *   ---   *   ---
