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
  use '.inc' Arstd::uid
  use '.inc' peso::seg

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.vmem

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; tmp, we'll move this
; somewhere else later!

macro UInt.urdivp2_c dst,size,ali {

  if ~ (size)
    dst = 1 shl ali

  else
    dst = size+((1 shl ali)-1)
    dst = dst shr ali

  end if

}

macro UInt.align_c dst,size,ali {
  UInt.urdivp2_c dst,size,ali
  dst = dst shl ali

}

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

      id\#.off  = 0
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

      id\#.beg=par\#.off+par\#.size
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

      \\}

      ; ^get length
      id\#.len  = $-id\#.beg
      id\#.pad  = $08 - (id\#.len mod $08)
      id\#.size = id\#.len+id\#.pad

      ; ^pad to size with null
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

macro vmem.seg par,dst,ct& {

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
; set value at ptr

macro vmem.write dst,src,size=byte {

  match id , dst \{

    if (id\#.ptr+sizeof.#size) > id\#.size
      out@err "write past end of vmem"

    end if

    store size src at id\#.base:id\#.ptr
    id\#.ptr=id\#.ptr+sizeof.#size

    if id\#.ptr > id\#.len
      id\#.len = id\#.ptr
      id\#.pad = id\#.size-id\#.ptr

    end if

  \}

}

; ---   *   ---   *   ---
; ^get

macro vmem.read dst,src,size=byte {

  match id , src \{

    if (id\#.ptr+sizeof.#size) > id\#.size
      out@err "read past end of vmem"

    end if

    load dst size from id\#.base:id\#.ptr
    id\#.ptr=id\#.ptr+sizeof.#size

  \}

}

; ---   *   ---   *   ---
; ^move ptr (absolute)

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
      store qword $00 at id\#.base:(%-1)*$08

    end repeat

    id\#.ptr = 0
    id\#.len = 0
    id\#.pad = id\#.size

  \}

}

; ---   *   ---   *   ---
; compare two buffers

macro vmem.eq dst,s0,s1 {


  local len
  local w0
  local w1

  dst = 0

  ; varlis
  len  equ vmem.eq.len
  w0   equ vmem.eq.w0
  w1   equ vmem.eq.w1


  ; unroll srcs
  match id0 id1 , s0 s1 \{

    ; skip on unequal length
    if ~(id0\#.len = id1\#.len)
      dst = 1

    ; ^else compare
    else

      ; walk in qword steps
      UInt.urdivp2_c len,id0\#.len,$03

      repeat len

        ; ^read next chunk
        load w0 qword \
          from id0\#.base:(%-1)*$08

        load w1 qword \
          from id1\#.base:(%-1)*$08

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

macro vmem.prich src {

  ; varlis
  local c
  c equ vmem.prich.c

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


    ; show raw ct : print ct
    display $0A

    repeat id\#.size shr $03

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
