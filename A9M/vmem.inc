; ---   *   ---   *   ---
; A9M VMEM
; Phantom buffers
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
  use '.inc' peso::cline
  use '.inc' A9M::vuint

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.vmem

  VERSION   v0.00.5b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; make new buff

macro vmem.new dst,ct& {

  ; get id
  local uid
  uid.new uid,A9M.vmem,npglobal

  ; ^gen buff
  match id , uid \{

    virtual at $00

      id\#.base::
      id\#.size = 0

    end virtual

    ; ^write
    vmem.segat id,id,ct

    ; give id
    dst equ id

  \}

}

; ---   *   ---   *   ---
; ^write segment

macro vmem.segat dst,atid,ct& {

  match par id , dst atid \{

    virtual par\#.base

      id\#.beg=par\#.size
      id\#.ptr=id\#.beg

      ; par != id, make new base ptr
      if ~(par\#.beg = id\#.beg)
        id\#.base::

      end if

      local ok
      ok equ 0

      ; produce blank of size N?
      match =blk size , ct \\{
        db size dup $00
        ok equ 1

      \\}

      ; ^paste passed string
      match =0 any , ok ct \\{
        db ct
        ok equ 1

      \\}

      ; ^just pad
      match =0 , ok \\{
        db $00

      \\}


      ; ^get length
      id\#.len = $-id\#.beg

      ; ^align to qword
      vuint.align id\#.size,id\#.len,$03

      ; ^pad to size with null
      id\#.pad = id\#.size-id\#.len
      db id\#.pad dup $00

    end virtual


    ; par != id, update par size
    if ~(par\#.beg = id\#.beg)
      par\#.size=par\#.size+id\#.size

    end if

  \}

}

; ---   *   ---   *   ---
; ^add new segment to existing

macro vmem.seg dst,par,ct& {

  ; get id
  local uid
  uid.new uid,A9M.vmem,npglobal

  ; ^use id for new segment
  vmem.segat par,uid,ct

  ; ^give segptr
  match id , uid \{
    dst equ id

  \}

}

; ---   *   ---   *   ---
; get handle to slice

macro vmem.view dst,src,addr,len {

  ; get id
  local uid
  uid.new uid,A9M.vmem,npglobal

  ; get offset into parent
  match par id , src uid \{

    ; base is just an alias
    id\#.base equ par\#.base

    ; ^addr is all that counts ;>
    id\#.beg = par\#.beg+addr
    id\#.ptr = id\#.beg

    ; note: no pad len on vmem view!
    id\#.len  = len
    id\#.size = len
    id\#.pad  = 0

  \}

  ; ^give ptr
  match id , uid \{
    dst equ id

  \}

}

; ---   *   ---   *   ---
; errchk proto

macro vmem.boundschk id,addr,size,me {

  if (addr+sizeof.#size) > id#.size
    out@err me

  end if

}

; ---   *   ---   *   ---
; set value at ptr

macro vmem.write dst,src,size=byte {

  match id , dst \{

    vmem.boundschk id,id\#.ptr,size,\
      "write past end of vmem"


    ; set and move ptr
    store size src at id\#.base:\
      id\#.beg+id\#.ptr

    id\#.ptr=id\#.ptr+sizeof.#size


    ; ^adjust meta
    if id\#.ptr > id\#.len
      id\#.len = id\#.ptr
      id\#.pad = id\#.size-id\#.ptr

    end if

  \}

}

; ---   *   ---   *   ---
; ^arbitrary set

macro vmem.set dst,src,addr,size=byte {

  match id , dst \{

    vmem.boundschk id,addr,size,\
      "set past end of vmem"

    store size src at id\#.base:\
      id\#.beg+addr

  \}

}

; ---   *   ---   *   ---
; ^get

macro vmem.read dst,src,size=byte {

  match id , src \{

    vmem.boundschk id,id\#.ptr,size,\
      "read past end of vmem"

    ; get and move ptr
    load dst size from id\#.base:\
      id\#.beg+id\#.ptr

    id\#.ptr=id\#.ptr+sizeof.#size

  \}

}

; ---   *   ---   *   ---
; ^arbitrary

macro vmem.get dst,src,addr,size=byte {

  match id , src \{

    vmem.boundschk id,addr,size,\
      "get past end of vmem"

    load dst size from id\#.base:\
      id\#.beg+addr

  \}

}

; ---   *   ---   *   ---
; write contents of one
; buffer to another

macro vmem.copy dst,src {

  ; varlis
  local w0
  w0 equ vmem.copy.w0

  match A B , dst src \{

    ; errchk
    if B\#.size > A\#.size
      out@err 'OOB vmem copy'

    end if

    ; walk B and set A
    repeat B\#.size shr $03

      load w0 qword from B\#.base:\
        B\#.beg+((%-1)*8)

      store qword w0 at A\#.base:\
        A\#.beg+((%-1)*8)

    end repeat

  \}

}

; ---   *   ---   *   ---
; template for operator wraps

macro vmem.bop buff,fn,src,addr,size=byte {

  ; varlis
  local dst
  dst equ vmem.or.dst

  ; ^get current value
  vmem.get dst,buff,addr,size

  ; ^run op
  fn dst,src

  ; ^overwrite
  vmem.set buff,dst,addr,size

}

; ---   *   ---   *   ---
; ^generator

macro vmem._gen_bop name,ct& {

  match list , ct \{

    ; inner F to run from within bop
    macro vmem.#name#_inner dst,src \\{
      cline.filter list

    \\}

    ; ^the wraps themselves
    macro vmem.#name \
      buff,src,addr,size=byte \\{

      vmem.bop buff,\
        vmem.#name#_inner,src,addr,size

    \\}

  \}

}

; ---   *   ---   *   ---
; ^binary ops icebox

vmem._gen_bop xor   , dst=dst xor src
vmem._gen_bop or    , dst=dst or  src
vmem._gen_bop and   , dst=dst and src

vmem._gen_bop not   , dst=not dst
vmem._gen_bop xnor  , dst=not (dst xor src)
vmem._gen_bop nor   , dst=not (dst or  src)
vmem._gen_bop nand  , dst=not (dst and src)

; ---   *   ---   *   ---
; move ptr (absolute)

macro vmem.seek dst,N {

  match id , dst \{

    ; boundschk
    if N >= id\#.size
      out@err 'seek past end of vmem'

    end if

    id\#.ptr=N

  \}

}

; ---   *   ---   *   ---
; ^wraps for seek 0

macro vmem.rewind dst {
  vmem.seek dst,$00

}

; ---   *   ---   *   ---
; clear buff

macro vmem.clear dst {

  match id , dst \{

    repeat id\#.size shr $03
      store qword $00 at id\#.base:\
        id\#.beg+((%-1)*$08)

    end repeat

    id\#.ptr = 0
    id\#.len = 0
    id\#.pad = id\#.size

  \}

}

; ---   *   ---   *   ---
; compare two buffers

macro vmem.eq dst,s0,s1,len_ow= {


  local len
  local w0
  local w1

  dst = 0

  ; varlis
  len equ vmem.eq.len
  w0  equ vmem.eq.w0
  w1  equ vmem.eq.w1


  ; unroll srcs
  match id0 id1 , s0 s1 \{

    ; overwrite comparison length
    len = id1\#.len

    match any , len_ow \\{
      len=len_ow

    \\}

    ; skip on bad length
    if ~(id0\#.len < len)
      dst = 1

    ; ^else compare
    else

      ; walk in qword steps
      vuint.urdivp2 len,len,$03

      repeat len

        ; ^read next chunk
        load w0 qword from id0\#.base:\
          id0\#.beg+((%-1)*$08)

        load w1 qword from id1\#.base:\
          id1\#.beg+((%-1)*$08)

        ; compare and go next
        dst = dst or (w0 xor w1)

      end repeat

    end if

  \}


  ; reset out
  if ~ dst
    dst = 1

  else
    dst = 0

  end if

}

; ---   *   ---   *   ---
; get size left

macro vmem.have dst,src,sptr {

  local have
  have equ vmem.have.X

  dst=$01

  match id , src \{

    have=id\#.len - sptr

    if have >= $08
      dst=$08

    else if have >= $04
      dst=$04

    else if have >= $02
      dst=$02

    end if

  \}

}

; ---   *   ---   *   ---
; dbout

macro vmem.prich src,parshow=0 {

  ; varlis
  local c
  local psize

  c     equ vmem.prich.c
  psize equ vmem.prich.pshow


  match id , src \{

    ; give seg name/addr
    display $0A,'BUFID ',\`id,$0A

    display 'SEGAT '
    hexsay  id\#.beg,$10
    out@nl  2


    ; give seg attrs
    display '  size '
    hexsay  id\#.size,$08
    out@nl

    display '  len  '
    hexsay  id\#.len,$08
    out@nl

    display '  pad  '
    hexsay  id\#.pad,$08
    out@nl


    ; get print size
    if parshow & 1
      psize=id\#.size shr $03

    else
      psize=(id\#.len+id\#.pad) shr $03

    end if


    ; show raw ct : print ct
    display $0A

    repeat psize

      load  \c qword \
        from id\#.base:((%-1)*8) \
      + id\#.beg

      xesay \c,$40
      out@nl


    end repeat

    display $0A,$0A

  \}

}

; ---   *   ---   *   ---