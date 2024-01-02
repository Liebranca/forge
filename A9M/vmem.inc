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

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; tmp, we'll move this
; somewhere else later!

macro UInt.urdivp2_c dst,size,ali {

  ; [1] cx is exponent
  ; get 2^N thru shift
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

macro vmem.new dst,req,ct& {

  ; force size to a multiple of 8
  local size

  size equ vmem.new.size
  UInt.align_c size,req,$03


  ; get id
  local uid
  uid.new uid,A9M.vmem,npglobal

  ; ^gen buff
  match id , uid \{

    ; save vars
    id\#.size = size
    id\#.ptr  = $00

    ; ^open buff
    virtual at $00

      id\#.beg:
      id\#.base::

      ; paste passed string
      match any , ct \\{db ct\\}

      ; ^get length
      id\#.len=$-id\#.beg
      id\#.pad=size-id\#.len

      ; ^pad to size with null
      db id\#.pad dup $00

    end virtual


    ; give id
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
; clear buff

macro vmem.clear dst {

  match id , dst \{

    repeat id\#.size shr $03
      store qword $00 at id\#.base:(%-1)*$08

    end repeat

    id\#.ptr = 0

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

  match id , src \{

    display $0A,'BUF ',\`id,':',$0A


    display '  size '
    hexsay  id\#.size,$08
    out@nl

    display '  len  '
    hexsay  id\#.len,$08
    out@nl

    display '  pad  '
    hexsay  id\#.pad,$08
    out@nl

    display $0A,IO.string,"'"

    repeat id\#.len
      load    id\#.c byte from id\#.base:%-1
      display id\#.c

    end repeat

    display "'",IO.ncolor,$0A,$0A

  \}

}

; ---   *   ---   *   ---
