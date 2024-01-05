; ---   *   ---   *   ---
; A9M VCRYPT
; Spooky stuff (virtualized!)
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

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.vcrypt

  VERSION   v0.00.5b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  vcrypt.ASCII_MIN = $2020202020202020
  vcrypt.ASCII_MAX = $7F7F7F7F7F7F7F7F

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
; ^cstruc wraps

macro vhash.new dst,type,kbits,kezy=$20 {

  ; varlis
  local ezy
  local cnt
  local cap
  local masksz

  ezy    equ vhash.new.ezy
  cnt    equ vhash.new.cnt
  cap    equ vhash.new.cap
  masksz equ vhash.new.masksz


  ; ezy == bytesize per key
  ; cnt == capacity in N of elems
  ; cap == capacity in bytes
  cnt = (1 shl kbits)
  ezy = sizeof.#type
  cap = ezy*cnt

  ; masksz is number of qwords used
  ; to detect occupied slots
  ;
  ; so cnt/64 rounded up
  vuint.urdivp2 masksz,cnt,sizep2.line


  ; make ice
  vhash.new dst

  ; ^save attrs
  vhash.ezy.set    dst,ezy
  vhash.cap.set    dst,cap
  vhash.cnt.set    dst,cnt
  vhash.kbits.set  dst,kbits
  vhash.kezy.set   dst,kezy
  vhash.masksz.set dst,masksz


  ; decl storage buffs
  match id , dst \{

    vmem.seg id\#.values,id\#%origin,\
      blk cap

    vmem.seg id\#.mask,id\#%origin,\
      blk masksz*8*2

    vmem.seg id\#.keys,id\#%origin,\
      blk kezy*cnt

  \}

}

; ---   *   ---   *   ---
; ^put id

macro vhash.store tab,IV,chunk=qword {

  ; varlis
  local key
  local kbits
  local addr

  key   equ vhash.store.key
  kbits equ vhash.store.kbits
  addr  equ vhash.store.addr

  ; get key size
  vhash.kbits.get kbits,tab

  ; ^get key
  match idex ===> value , IV \{


    ; is idex a buffer?
    local sref
    vhash.unpack_key_src sref,idex

    ; is value a buffer?
    local vref
    vhash.unpack_value vref,value


    ; idex into hash
    vcrypt.hash key,sref,chunk,kbits

    ; ^write at idex
    vhash.get_free addr,tab,sref,key
    vhash.set_slot_value tab,vref,addr

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

macro vhash.keycoord tab,idex,mask,kmask,bit {

  ; varlis
  local masksz
  masksz equ vhash.keycoord.masksz

  ; get kmask offset
  vhash.masksz.get masksz,tab


  ; get mask idex
  idex = bit shr sizep2.line

  ; ^get *elem* idex in mask
  bit = (bit) - (idex shl sizep2.line)


  ; ^get value of mask@idex
  match id , tab \{
    vmem.get mask,id\#.mask,idex*8,qword
    vmem.get kmask,id\#.mask,(idex+masksz)*8,qword

  \}

}

; ---   *   ---   *   ---
; get *occupied* slot
; used to fetch elem
;
; TODO:
;
; * catch unsolvable

macro vhash.get_slot elem,tab,sref,key,fn& {

  ; varlis
  local mask
  local kmask
  local idex
  local bit

  mask  equ vhash.get_slot.mask
  kmask equ vhash.get_slot.kmask
  idex  equ vhash.get_slot.idex
  bit   equ vhash.get_slot.bit
  spin  equ vhash.get_slot.spin


  ; map key to bitmask array
  bit = key
  vhash.keycoord tab,idex,mask,kmask,bit

  elem = 1 shl bit

  ; slot free?
  if ~(mask and elem)
    vhash.throw_nokey sref

  end if


  ; ^nope, get key eq sref
  spin = 0

  while (mask and elem)

    ; skip sentinels
    if ~(kmask and elem)
      vhash.mask_search kmask,bit,elem

    ; ^actual elem, compare buffers
    else

      ; varlis for bool
      local ok
      ok equ vhash.get_slot.ok

      ; ^compare
      vhash.keycmp ok,tab,elem,bit,sref,idex


      ; ^break if so
      if ok = 1
        break

      end if


    end if


    ; lazy out!
    spin=spin+1

    if spin > 8
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
;
; TODO:
;
; * catch unsolvable

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

macro vhash.mask_search mask,bit,elem,op= {

  local tmp
  tmp equ vhash.mask_search.tmp


  ; R search
  tmp=bsf op (mask)


  ; ^L search on fail
  if (tmp > $3F)
    tmp=bit + bsf op (mask shr bit)

  end if

  bit  = tmp
  elem = 1 shl bit

}

; ---   *   ---   *   ---
; compare current key to
; pointed one

macro vhash.keycmp dst,tab,elem,bit,sref,idex {

  ; get *elem* idex
  elem = bit + (idex shl sizep2.line)

  ; key match?
  match id , tab \{

    ; get width
    local kezy
    kezy equ vhash.keycmp.kezy
    vhash.kezy.get kezy,tab

    ; get key src at offset
    local sbuf
    vmem.view sbuf,id\#.keys,\
      elem*kezy,kezy

vmem.prich sbuf
vmem.prich sref

display '__________________',$0A,$0A

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
; ^set value at elem idex

macro vhash.set_slot_value tab,value,elem {

  match id , tab \{

    ; varlis
    local ezy
    ezy equ vhash.set_slot_value.ezy

    ; ^get elem size
    vhash.ezy.get ezy,tab

    ; ^get dst
    local vbuf
    vmem.view vbuf,id\#.values,\
      elem*ezy,\
      ezy

    ; ^write
    vmem.copy vbuf,value

  \}

}

; ---   *   ---   *   ---
; ^fetch

macro vhash.get_slot_value dst,tab,elem {

  match id , tab \{

    ; varlis
    local ezy
    ezy equ vhash.get_slot_value.ezy

    ; ^get elem size
    vhash.ezy.get ezy,tab

    ; ^get dst
    local vbuf
    vmem.view vbuf,id\#.values,\
      elem*ezy,\
      ezy

    ; ^write
    vmem.copy dst,vbuf

  \}

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
; get chunk-sized hash

macro vcrypt.xorkey dst,src,size {

  local mask
  local chunk
  local len
  local flip

  ; varlis
  mask  equ vcrypt.xorkey.mask
  chunk equ vcrypt.xorkey.chunk
  len   equ vcrypt.xorkey.len
  flip  equ vcrypt.xorkey.flip

  if sizeof.#size = 8
    mask=not 0

  else
    mask=(1 shl (sizeof.#size*8))-1

  end if

  dst   = 0


  ; reset ptr
  vmem.rewind src

  ; walk src
  flip=0

  match id , src \{

    ; walk in N-sized steps
    vuint.urdivp2 len,id\#.len,sizep2.#size

    ; ^xor chunks together
    repeat len

      vmem.read chunk,src,size

      chunk = chunk - (ASCII_MIN and sizebm.#size)
      chunk = chunk + flip
      flip  = flip xor ASCII_MAX

      dst   = dst xor (chunk and mask)

    end repeat

  \}

  ; ^re-reset
  vmem.rewind src

}

; ---   *   ---   *   ---
; ^clamp to N-bits

macro vcrypt.rotcap dst,bits {

  local mask
  local imask
  local tmp

  ; varlis
  mask  equ vcrypt.rotcap.mask
  imask equ vcrypt.rotcap.imask
  tmp   equ vcrypt.rotcap.tmp

  mask  = (1 shl bits)-1
  imask = not mask

  ; ^collapse
  while 1

    tmp = dst
    dst = dst and mask
    tmp = (tmp and imask) shr bits
    dst = dst xor tmp

    if dst <= mask
      break

    end if


  end while

}

; ---   *   ---   *   ---
; ^wraps

macro vcrypt.hash dst,src,chunk,bits {
  vcrypt.xorkey dst,src,chunk
  vcrypt.rotcap dst,bits

}

; ---   *   ---   *   ---
