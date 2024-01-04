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

  VERSION   v0.00.3b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  vcrypt.SKEY_SIZE=$20

; ---   *   ---   *   ---
; table head struc

vreg.new vhash

  szmy dword ezy
  szmy dword cap

  szmy word  cnt
  szmy word  kbits
  szmy word  masksz

vreg.end

; ---   *   ---   *   ---
; ^cstruc wraps

macro vhash.new dst,type,kbits {

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
  vhash.masksz.set dst,masksz


  ; decl storage buffs
  match id , dst \{

    vmem.seg id\#.head,id\#%origin,\
      blk cap

    vmem.seg id\#.mask,id\#%origin,\
      blk masksz*8*2

    vmem.seg id\#.keys,id\#%origin,\
      blk vcrypt.SKEY_SIZE*cnt

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
    local ok
    local buff

    ok equ 0

    match ptr name , idex \\{
      buff equ name
      ok equ 1

    \\}

    ; ^else make tmp
    match =0 , ok \\{
      vmem.new buff,idex

    \\}


    vcrypt.hash    key,buff,chunk,kbits
    vhash.get_free addr,tab,buff,key

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

macro vhash.get_slot dst,tab,sref,key,fn= {

  ; varlis
  local mask
  local kmask
  local idex
  local bit
  local tmp

  mask  equ vhash.get_slot.mask
  kmask equ vhash.get_slot.kmask
  idex  equ vhash.get_slot.idex
  bit   equ vhash.get_slot.bit
  tmp   equ vhash.get_slot.tmp


  ; map key to bitmask array
  bit = key
  vhash.keycoord tab,idex,mask,kmask,bit

  dst = 1 shl bit

  ; slot free?
  if ~(mask & dst)
    vhash.throw_nokey sref

  end if


  ; ^nope, get key eq sref
  while (mask & dst)

    ; R skip sentinels
    if ~(kmask & dst)
      tmp=bsf kmask

      ; ^L skip on fail
      if(tmp > $3F)
        tmp=bit + bsf (kmask shr bit)

      end if

      bit=tmp
      dst=1 shl bit


    ; ^actual elem, compare buffers
    else

      ; varlis for bool
      local ok
      ok equ vhash.get_slot.ok

      ; get *elem* idex
      dst = bit + (idex shl sizep2.line)


      ; key match?
      match id , tab \{

        ; get key src at offset
        local sbuf
        vmem.view sbuf,id\#.keys,\
          dst*vcrypt.SKEY_SIZE,\
          ,vcrypt.SKEY_SIZE

        ; ^compare buffers
        vmem.eq ok,sref,sbuf

      \}


      ; ^break if so
      if ok = 1
        break

      end if


    end if

  end while


  ; optinal footer
  match any , fn \{
    fn idex,bit

  \}

}

; ---   *   ---   *   ---
; ^errme

macro vhash.throw_nokey sref {

  display  'Key '
  humansay sref,$100

  display  'not found in vhash'
  out@nl

  err

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
  local tmp

  mask  equ vhash.get_free.mask
  kmask equ vhash.get_free.kmask
  idex  equ vhash.get_free.idex
  bit   equ vhash.get_free.bit
  tmp   equ vhash.get_free.tmp


  ; map key to bitmask array
  bit = key
  vhash.keycoord tab,idex,mask,kmask,bit

  elem = 1 shl bit

  ; get first free or sentinel
  while (mask & elem)

    ; standing on sentinel!
    if ~(kmask & elem)
      break


    else

      ; varlis for bool
      local ok
      ok equ vhash.get_slot.ok

      ; get *elem* idex
      elem = bit + (idex shl sizep2.line)


      ; key match?
      match id , tab \{

        ; get key src at offset
        local sbuf
        vmem.view sbuf,id\#.keys,\
          elem,vcrypt.SKEY_SIZE

        ; ^compare buffers
        vmem.eq ok,sref,sbuf

      \}


      ; wrong idex, R get free
      if ok = 0

        tmp=bsf (not kmask)

        ; ^L get free on fail
        if(tmp > $3F)
          tmp=bit + bsf not (kmask shr bit)

        end if

        bit  = tmp
        elem = 1 shl bit

      end if


    end if

  end while


  ; reset *elem* idex
  elem = bit + (idex shl sizep2.line)

  ; occupy mask slot
  match id , tab \{

    ; varlis
    local masksz
    masksz equ vhash.get_free.masksz

    ; get kmask offset
    vhash.masksz.get masksz,tab

    ; ^update masks
    vmem.or id\#.mask,(1 shl bit),idex,qword
    vmem.or id\#.mask,(1 shl bit),idex+masksz,qword

    ; ^update key src
    local sbuf
    vmem.view sbuf,id\#.keys,\
      elem*vcrypt.SKEY_SIZE,\
      vcrypt.SKEY_SIZE

    vmem.copy  sbuf,sref

  \}

}

; ---   *   ---   *   ---
; get chunk-sized hash

macro vcrypt.xorkey dst,src,size {

  local mask
  local chunk
  local len

  ; varlis
  mask  equ vcrypt.xorkey.mask
  chunk equ vcrypt.xorkey.chunk
  len   equ vcrypt.xorkey.len

  if sizeof.#size = 8
    mask=not 0

  else
    mask=(1 shl (sizeof.#size*8))-1

  end if

  dst   = 0


  ; reset ptr
  vmem.rewind src

  ; walk src
  match id , src \{

    ; walk in N-sized steps
    vuint.urdivp2 len,id\#.len,sizep2.#size

    ; ^xor chunks together
    repeat len
      vmem.read chunk,src,size
      dst = dst xor (chunk and mask)

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
