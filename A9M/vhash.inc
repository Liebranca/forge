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
  use '.inc' A9M::vreg
  use '.inc' A9M::vcrypt

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.vhash

  VERSION   v0.00.2b
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

  szmy qword c_mask
  szmy qword c_kmask

vreg.end

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

    vmc.bget tmp,%[dst cap]
    vmem.seg id\#.values,id\#%origin,\
      blk tmp

    vmc.bget tmp,%[dst masksz]
    vmem.seg id\#.mask,id\#%origin,\
      blk tmp*8*2

    vmc.bget tmp,%[dst cnt]
    vmem.seg id\#.keys,id\#%origin,\
      blk kezy*tmp

  \}

}

; ---   *   ---   *   ---
; ^put id

macro vhash.store tab,IV,chunk=qword {

  ; ^get key
  match idex ===> value , IV \{


    ; is key a buffer?
    local sref
    vhash.unpack_key_src sref,idex

    ; is value a buffer?
    local vref
    vhash.unpack_value vref,value


    ; key to idex
    $mov  ar,%[tab kbits]
    $pass ptr sref,ptr chunk,ar

    $call vcrypt.hash

    ; ^write at idex
    vhash.get_free       tab,sref
    vhash.set_slot_value tab,vref

  \}

}

; ---   *   ---   *   ---
; ^fetch id

macro vhash.load dst,tab,idex,chunk=qword {

  ; varlis
  local key
  local kbits
  local addr

  key   equ vhash.load.key
  kbits equ vhash.load.kbits
  addr  equ vhash.load.addr

  ; get key size
  vhash.kbits.get kbits,tab

  ; is idex a buffer?
  local sref
  vhash.unpack_key_src sref,idex

  ; is dst a buffer?
  local vref
  vhash.unpack_value vref,dst


  ; idex into hash
  vcrypt.hash key,sref,chunk,kbits

  ; ^write at idex
  vhash.get_slot addr,tab,sref,key
  vhash.get_slot_value vref,tab,addr

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

}

; ---   *   ---   *   ---
; map key to bitmask coords

macro vhash.keycoord {

  ; get kmask offset
  $mov br,%[ice masksz]

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
  match id , tab \{

    $mov %[ctx mask],qword [id\#.mask+cr*8]

    $add cr,br
    $mov %[ctx kmask],qword [id\#.mask+cr*8]

  \}

}

; ---   *   ---   *   ---
; get *occupied* slot
; used to fetch elem

macro vhash.get_slot sref,fn& {

  ; map key to bitmask array
  vhash.keycoord

  ; slot free?
  $on ~(%[ctx mask] and %[ctx elem])
    vhash.throw_nokey sref

  end if


  ; ^nope, get key eq sref
  $xor   cr,cr
  $while %[ctx mask] and %[ctx elem]

    ; skip sentinels
    $on ~(%[ctx kmask] and %[ctx elem])
      $pass %[ctx mask]
      $call vhash.mask_search

    ; ^actual elem, compare buffers
    else

      vhash.keycmp sref

      ; ^stop if same
      $break on ar = 1


    end if


    ; lazy out!
    $inc cr

    $on cr > 8
      vhash.throw_unsolvable sref

    end if

  end while


  ; optinal footer
  match mode , fn \{
    vhash.set_slot_meta elem,\
      tab,bit,idex,sref,mode

  \}

  ; ^else just give *elem* idex
  match , fn \{
    elem = bit + (idex shl sizep2.line)

  \}

}

; ---   *   ---   *   ---
; get *free* slot
; used to insert new elem

macro vhash.get_free elem,tab,sref,key {

  ; varlis
  local mask
  local kmask
  local idex
  local bit
  local spin

  mask  equ vhash.get_free.mask
  kmask equ vhash.get_free.kmask
  idex  equ vhash.get_free.idex
  bit   equ vhash.get_free.bit
  spin  equ vhash.get_free.spin


  ; map key to bitmask array
  bit = key
  vhash.keycoord tab,idex,mask,kmask,bit

  elem = 1 shl bit


  ; get first free or sentinel
  spin = 0

  while (mask and elem)

    ; standing on sentinel!
    if ~(kmask and elem)
      break


    else

      ; varlis for bool
      local ok
      ok equ vhash.get_free.ok

      ; ^key match?
      vhash.keycmp ok,tab,elem,bit,sref,idex


      ; ^wrong idex, R get free
      if ok = 0
        vhash.mask_search kmask,bit,elem,not

      ; ^same key, overwrite
      else
        break

      end if


    end if


    ; lazy out!
    spin=spin+1

    if spin > 8
      vhash.throw_unsolvable sref

    end if

  end while


  ; update meta
  vhash.set_slot_meta \
    elem,tab,bit,idex,sref,or copy

}

; ---   *   ---   *   ---
; ^wraps for freeing

macro vhash.free_slot elem,tab,sref,key {
  vhash.get_slot elem,tab,sref,key,xor clear

}

; ---   *   ---   *   ---
; tries to find free slot

macro vhash.mask_search mask {

  ; R search
  $bsf ar,mask

  ; ^L search on fail
  $on ar > $3F
    $mov ar,mask
    $mov br,%[ctx bit]
    $shr mask,br
    $bsf ar,mask

  end if


  ; ^recalc element pos
  $mov %[ctx bit],ar

  $mov br,1
  $shl br,ar
  $mov %[ctx elem],br

}

; ---   *   ---   *   ---
; compare current key to
; pointed one

macro vhash.keycmp sref {

  ; get *elem* idex
  $mov ar,%[ctx idex]
  $shl ar,sizep2.line
  $add ar,%[ctx bit]

  ; get width
  $mov $br,%[ice kezy]

  ; key match?
  match id , tab \{

    ; get key src at offset
    local sbuf
    vmem.view sbuf,id\#.keys,\
      elem*kezy,kezy

    ; ^compare buffers
    vmem.eq dst,sref,sbuf

  \}

}

; ---   *   ---   *   ---
; overwrite slot meta

macro vhash.set_slot_meta \
  elem,tab,bit,idex,sref,mode {


  ; get *elem* idex
  elem = bit + (idex shl sizep2.line)

  ; occupy mask slot
  match id , tab \{

    ; varlis
    local masksz
    masksz equ vhash.get_free.masksz

    ; get kmask offset
    vhash.masksz.get masksz,tab


    ; ^update masks
    match mask_op sbuf_op , mode \\{

      vmem.\\#mask_op id\#.mask,(1 shl bit),\
        idex*8,qword

      vmem.\\#mask_op id\#.mask,(1 shl bit),\
        (idex+masksz)*8,qword


      ; get src width
      local kezy
      kezy equ vhash.set_slot_meta
      vhash.kezy.get kezy,tab

      ; ^update key src
      local sbuf
      vmem.view sbuf,id\#.keys,\
        elem*kezy,kezy

      ; ^mode switch
      local sbuf_args
      sbuf_args equ sbuf,sref

      match =clear , sbuf_op \\\{
        sbuf_args equ sbuf

      \\\}

      match list , sbuf_args \\\{
        vmem.\\#sbuf_op list

      \\\}

    \\}

  \}

}

; ---   *   ---   *   ---
; fetch elem at idex proto

macro vhash._value_copy value,tab,elem,mode= {

  match id , tab \{

    ; varlis
    local ezy
    ezy equ vhash._value_write.ezy

    ; ^get elem size
    vhash.ezy.get ezy,tab

    ; ^get dst
    local vbuf
    vmem.view vbuf,id\#.values,\
      elem*ezy,\
      ezy


    ; select args order
    local args
    args equ vbuf,value

    match =get , mode \{
      args value,vbuf

    \}

    ; ^write
    match list , args \{
      vmem.copy list

    \}

  \}

}

; ---   *   ---   *   ---
; ^shorthands

macro vhash.get_slot_value dst,tab,elem {
  vhash._value_copy dst,tab,elem,mode=get

}

macro vhash.set_slot_value tab,value,elem {
  vhash._value_copy value,tab,elem,mode=set

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
