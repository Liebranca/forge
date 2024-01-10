; ---   *   ---   *   ---
; A9M VHASH
; Map value to idex
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
  use '.inc' A9M::vcrypt

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.vhash

  VERSION   v0.00.7b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; table head struc

vreg.new vhash

  szmy dword ezy
  szmy dword cap

  szmy word  cnt
  szmy word  kbits
  szmy word  kezy
  szmy word  masksz

vreg.end

; ---   *   ---   *   ---
; ^holds lookup vars

vreg.new vhash.lkp

  szmy qword mask
  szmy qword kmask
  szmy qword elem

  szmy byte  bit
  szmy byte  idex

vreg.end

define        vhash._lkp_0
vhash.lkp.new vhash._lkp_0

; ---   *   ---   *   ---
; ^cstruc wraps

macro vhash.new dst,type,kbits,kezy=$20 {

  ; cr => cnt == capacity in N of elems
  ; dr => ezy == bytesize per key
  $mov cr,1 shl kbits
  $mov dr,sizeof.#type

  ; er => cap == capacity in bytes
  $mov er,cr
  $mul er,dr

  ; br => masksz
  ;
  ; that's number of qwords used
  ; to detect occupied slots
  ;
  ; so cnt/64 rounded up
  $urdivp2 br,cr,sizep2.line


  ; make ice
  vhash.new dst

  ; ^save attrs
  $mov %[dst cnt],cr
  $mov %[dst ezy],dr
  $mov %[dst cap],er
  $mov %[dst \kbits],kbits
  $mov %[dst \kezy],kezy
  $mov %[dst masksz],br


  ; decl storage buffs
  match id , dst \{

    local tmp

    vmc.bget tmp,%[dst masksz]
    vmem.seg id\#.mask,id\#%origin,\
      blk tmp*8*2

    vmc.bget tmp,%[dst cap]
    vmem.seg id\#.values,id\#%origin,\
      blk tmp

    vmc.bget tmp,%[dst cnt]
    vmem.seg id\#.keys,id\#%origin,\
      blk kezy*tmp

  \}

}

; ---   *   ---   *   ---
; ^read from file wraps

macro vhash.from_disk dst,fpath {

  vhash.from_disk dst,fpath

  match id , dst \{

    local off
    local tmp
    local kezy

    off=sizeof.vhash

    vmc.bget tmp,%[dst masksz]
    vmem.view id\#.mask,id\#%origin,\
      off,tmp*8*2

    off=off+(tmp*8*2)

    vmc.bget tmp,%[dst cap]
    vmem.view id\#.values,id\#%origin,\
      off,tmp

    off=off+tmp

    vmc.bget tmp,%[dst cnt]
    vmc.bget kezy,%[dst \kezy]

    vmem.view id\#.keys,id\#%origin,\
      off,kezy*tmp

  \}

}

; ---   *   ---   *   ---
; put id => value

macro vhash.store idex,value,chunk=qword {

  ; is key a buffer?
  local sref
  vhash.unpack_key_src sref,idex

  ; is value a buffer?
  local vref
  vhash.unpack_value vref,value

  ; key to idex
  $pass ptr sref,ptr chunk,%[ice kbits]
  $call vcrypt.hash

  ; ^write at idex
  vhash.keycoord
  vhash.get_free_slot  sref
  vhash.set_slot_value vref

}

; ---   *   ---   *   ---
; ^fetch value from id

macro vhash.load dst,idex,chunk=qword {

  ; is idex a buffer?
  local sref
  vhash.unpack_key_src sref,idex

  ; is dst a buffer?
  local vref
  vhash.unpack_value vref,dst

  ; key to idex
  $pass ptr sref,ptr chunk,%[ice kbits]
  $call vcrypt.hash

  ; ^write at idex
  vhash.keycoord
  vhash.get_occ_slot   sref
  vhash.get_slot_value vref

}

; ---   *   ---   *   ---
; ^sugar for freeing slot

macro vhash.free idex,chunk=qword {

  ; is idex a buffer?
  local sref
  vhash.unpack_key_src sref,idex

  ; key to idex
  $pass ptr sref,ptr chunk,%[ice kbits]
  $call vcrypt.hash

  ; ^clear idex
  vhash.keycoord
  vhash.free_occ_slot  sref

}

; ---   *   ---   *   ---
; ^sugar for checking if
; a key exists

macro vhash.find dst,idex,chunk=qword {

  ; is idex a buffer?
  local sref
  vhash.unpack_key_src sref,idex

  ; is dst a buffer?
  local vref
  vhash.unpack_value vref,dst

  ; key to idex
  $pass ptr sref,lit chunk,%[ice kbits]
  $call vcrypt.hash


  ; check le length before search
  match id , sref \{

    $mov br,%[ice kezy]
    $on id\#.len <= br

      vhash.keycoord
      vhash.have? sref

      ; ^give if found
      $on ar = 1
        vhash.get_slot_value vref

      end if

    else
      ar=0

    end if

  \}

}

; ---   *   ---   *   ---
; get type of key passed to store/load

macro vhash.unpack_key_src dst,idex {

  local ok
  ok equ 0

  match ptr name , idex \{
    dst equ name
    ok  equ 1

  \}

  ; ^else make tmp
  match =0 , ok \{
    vmem.new dst,idex

  \}

}

; ---   *   ---   *   ---
; ^similar thing for the value

macro vhash.unpack_value dst,value {

  local ok
  ok equ 0

  ; ptr to vmem or casted pointer
  match type name , value \{

    ; raw vmem
    match =ptr , type \\{
      dst equ name

    \\}

    ; ^some vreg typecast
    match =% , type \\{
      dst equ name\#%origin

    \\}

    ok equ 1

  \}

  ; ^else make tmp
  match =0 , ok \{
    vmem.new dst,value

  \}


  ; override buff length if zero
  match id , dst \{

    if id\#.len = 0
      id\#.len = id\#.size
      id\#.pad = 0

    end if

  \}

}

; ---   *   ---   *   ---
; map key to bitmask coords

macro vhash.keycoord {

  ; load ctx
  $mov ptr ctx,ptr vhash._lkp_0

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


  ; get mask
  match id , vmc.REG.ice \{

    $mov %[ctx mask],qword [id\#.mask+cr*8]

    $add cr,%[ice masksz]
    $mov %[ctx kmask],qword [id\#.mask+cr*8]

  \}

}

; ---   *   ---   *   ---
; get *occupied* slot
; used to fetch elem

macro vhash.get_occ_slot sref,die?,fn& {

  $mov   ar,%[ctx mask]
  $mov   dr,%[ctx kmask]
  $mov   br,%[ctx elem]
  $xor   cr,cr

  ; slot free?
  $on ~(ar and br)

    if die? = 1
      vhash.throw_nokey sref

    else
      $mov cr,$09

    end if

  else

    ; ^nope, get key eq sref
    $xor   cr,cr
    $while ar and br

      ; skip sentinels
      $on ~(dr and br)
        $mov ar,%[ctx kmask]
        vhash.mask_search

      ; ^actual elem, compare buffers
      ; ^then stop if same
      else
        vhash.keycmp sref
        $break on ar = 1

      end if


      ; die if unsolvable
      vhash.search_fail? sref,die?


    end while


    ; optinal footer
    match mode , fn \{
      vhash.set_slot_meta sref,mode

    \}

  end if

}

; ---   *   ---   *   ---
; ^wraps for freeing

macro vhash.free_occ_slot sref {
  vhash.get_occ_slot sref,1,unset

}

; ---   *   ---   *   ---
; ^wraps for merely checking!

macro vhash.have? sref {

  ; search for key
  vhash.get_occ_slot sref,0

  ; ^reset out
  $mov ar,1
  $on  cr > 8
    $mov ar,0

  end if

}

; ---   *   ---   *   ---
; get *free* slot
; used to insert new elem

macro vhash.get_free_slot sref {

  $mov   ar,%[ctx mask]
  $mov   dr,%[ctx kmask]
  $mov   br,%[ctx elem]
  $xor   cr,cr

  $while ar & br

    ; standing on sentinel!
    $break on ~(dr and br)

    ; ^key match?
    vhash.keycmp sref


    ; ^wrong idex, R get free
    $on ar = 0

      $mov  ar,%[ctx kmask]
      $not  ar

      vhash.mask_search

    ; ^same key, overwrite
    else
      break

    end if


    ; die if unsolvable
    vhash.search_fail? sref


  end while


  ; update meta
  vhash.set_slot_meta sref,set

}

; ---   *   ---   *   ---
; quits a search loop

macro vhash.search_fail? sref,die?=1 {

  $inc cr
  $on cr > 8

    if die? = 1
      vhash.throw_unsolvable sref

    else
      break

    end if

  end if

}

; ---   *   ---   *   ---
; tries to find free slot

macro vhash.mask_search {

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
; get *elem* idex from
; mask bit and idex

macro vhash.get_elem_idex {
  $mov ar,%[ctx idex]
  $shl ar,sizep2.line
  $add ar,%[ctx bit]

}

; ---   *   ---   *   ---
; read [key|value] at position

macro vhash.get_elem dst,type {

  local size
  local src

  size equ ezy
  src  equ values

  match =key , type \{
    size equ kezy
    src  equ keys

  \}


  match id tag , vmc.REG.ice src \{

    ; get elem and width
    vhash.get_elem_idex
    $mov br,%[ice size]

    ; get key src at offset
    local sbuf
    $mul  ar,br

    $pass ptr sbuf,ptr id\#.\#tag,ar,br
    $call vmem.view

    match any , sbuf \\{
      dst equ any

    \\}

  \}

}

; ---   *   ---   *   ---
; ^icebox

macro vhash.get_elem_key dst {
  vhash.get_elem dst,key

}

macro vhash.get_elem_value dst {
  vhash.get_elem dst,value

}

; ---   *   ---   *   ---
; compare current key to
; pointed one

macro vhash.keycmp sref {

  ; key match?
  match id , vmc.REG.ice \{

    local sbuf
    vhash.get_elem_key sbuf

    local ok
    ok = 0

    vmem.eq ok,sref,sbuf
    $mov ar,ok

  \}

}

; ---   *   ---   *   ---
; overwrite slot meta

macro vhash.set_slot_meta sref,mode {

  ; get mask [idex,bit]
  $xor cr,cr
  $xor ar,ar

  $mov cr,%[ctx idex]
  $mov ar,%[ctx elem]

  ; get width
  $mov br,%[ice masksz]

  ; occupy mask slot
  match id , vmc.REG.ice \{

    ; occupy slot
    match =set , mode \\{

      ; set mask bits
      $or  qword [id\#.mask+cr*8],ar

      $add cr,br
      $or  qword [id\#.mask+cr*8],ar

      ; get elem key
      local sbuf
      vhash.get_elem_key sbuf

      ; ^update
      vmem.copy sbuf,sref

    \\}

    ; ^free
    match =unset , mode \\{

      ; actually, free nothing
      ; just put a sentinel ;>
      $not ar
      $add cr,br
      $and qword [id\#.mask+cr*8],ar

    \\}

  \}

}

; ---   *   ---   *   ---
; fetch elem at idex proto

macro vhash._value_copy value,mode= {

  ; fetch mem
  local vbuf
  vhash.get_elem_value vbuf

  ; ^mode switch
  match =get , mode \{
    vmem.copy value,vbuf

  \}

  match =set , mode \{
    vmem.copy vbuf,value

  \}

}

; ---   *   ---   *   ---
; ^shorthands

macro vhash.get_slot_value dst {
  vhash._value_copy dst,get

}

macro vhash.set_slot_value value {
  vhash._value_copy value,set

}

; ---   *   ---   *   ---
; errmes

macro vhash.throw_nokey sref {

  display  'Key '
  humansay sref,$100

  display  'not found in vhash'
  out@nl

  err

}

macro vhash.throw_unsolvable sref {

  display  'Unsolvable collision, key '
  humansay sref,$100
  out@nl

  err

}

; ---   *   ---   *   ---
