; ---   *   ---   *   ---
; A9M VMEM META
; Pointers to self!
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.vmem.meta

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; adjust meta on write

macro vmem.update_meta dst,size {

  match id , dst \{

    if size > id\#.len
      id\#.len = size
      id\#.pad = id\#.size-size

    end if

  \}

}

; ---   *   ---   *   ---
; ^clear

macro vmem.clear_meta dst {

  match id , dst \{

    id\#.len = 0
    id\#.pad = id\#.size

    vmem.rewind dst

  \}

}

; ---   *   ---   *   ---
; move ptr by direction
; relative to current

macro vmem.lseek dst,step {

  match id , dst \{
    id\#.ptr=id\#.ptr+step
    vmem.ptr_boundschk dst

  \}

}

; ---   *   ---   *   ---
; ^relative to end

macro vmem.rseek dst,step,top=len {

  match id , dst \{

    vmem.fastfwd dst,top
    id\#.ptr=id\#.ptr-step

    vmem.ptr_boundschk dst

  \}

}

; ---   *   ---   *   ---
; move ptr (absolute)

macro vmem.seek dst,N {

  match id , dst \{
    id\#.ptr=N
    vmem.ptr_boundschk dst

  \}

}

; ---   *   ---   *   ---
; reset ptr

macro vmem.rewind dst {
  match id , dst \{id\#.ptr=$00\}

}

; ---   *   ---   *   ---
; ^go to end

macro vmem.fastfwd dst,top=len {
  match id , dst \{id\#.ptr=id\#.#top\}

}

; ---   *   ---   *   ---
; errchk protos

macro vmem.boundschk id,addr,size,me {

  if (addr+sizeof.#size) > id#.size
    out@err me

  end if

}

; ---   *   ---   *   ---
; ^ptr movement

macro vmem.ptr_boundschk dst {

  match id , dst \{

    if (id\#.ptr >= id\#.size) \
    |  (id\#.ptr <  0)

      out@err 'seek past end of vmem'

    end if

  \}

}

; ---   *   ---   *   ---
