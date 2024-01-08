; ---   *   ---   *   ---
; A9M VMEM BIN
; ORC/OWC ;>
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
  use '.inc' A9M::vmem::meta
  use '.inc' A9M::vmem::xstep

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.vmem.bin

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; open file as a virtual buffer
; used for reading

macro vmem.orc dst,fpath,off=$00 {
  vmem.new dst,file fpath:off
  match id , dst \{id\#.fpath equ fpath\}

}

; ---   *   ---   *   ---
; ^writing

macro vmem.owc dst,ext,args {
  vmem.new dst,fout ext args
  match id , dst \{id\#.fpath equ '*.'#ext\}

}

; ---   *   ---   *   ---
; set value at ptr

macro vmem.store dst,src,size=byte {

  match id , dst \{

    vmem.boundschk id,id\#.ptr,size,\
      "store past end of vmem"


    ; set and move ptr
    store size src at id\#.base:\
      id\#.beg+id\#.ptr

    vmem.lseek       dst,sizeof.#size
    vmem.update_meta dst,id\#.ptr

  \}

}

; ---   *   ---   *   ---
; get value at ptr

macro vmem.load dst,src,size=byte {

  match id , src \{

    vmem.boundschk id,id\#.ptr,size,\
      "load past end of vmem"

    ; get and move ptr
    load dst size from id\#.base:\
      id\#.beg+id\#.ptr

    vmem.lseek src,sizeof.#size

  \}

}

; ---   *   ---   *   ---
; clear buff

macro vmem.clear dst {

  match id , dst \{

    vmem.xwalk id\#.len,\
      vmem.WTA,dst,$00

    vmem.clear_meta dst

  \}

}

; ---   *   ---   *   ---
; boundless write at ptr,
; will extend dst if too small

macro vmem.cat A,B,srcptr= {

  match dst src , A B \{

    local off
    local len
    local fn

    len equ src\#.len
    off equ 0

    match any , srcptr \{
      off equ src\#.ptr

    \}

    len equ (len-off)


    ; resize dst?
    if dst\#.size < (dst\#.ptr+len)

      local nchunk
      local diff

      diff equ vmem.cat.diff
      diff = (dst\#.ptr+len) - dst\#.size

      vmem.seg nchunk,dst,blk diff

    end if


    ; get base offset
    local base

    base equ vmem.cat.base
    base = dst\#.ptr

    ; ^write src+off to dst ptr
    vmem.xwalk len,\
      vmem.BPTRTOAPTR,dst,src,base,off

    vmem.update_meta dst,dst\#.ptr

  \}

}

; ---   *   ---   *   ---
; write contents of one
; buffer to another

macro vmem.copy dst,src,ow= {

  ; varlis
  local len
  len equ vmem.copy.len

  match A B , dst src \{

    ; size passed?
    vuint.defval len,B\#.len,ow

    ; errchk
    if len > A\#.size
      out@err 'OOB vmem copy'

    end if

    vmem.clear_meta  A

    vmem.xwalk       len,vmem.BTOA,A,B
    vmem.update_meta A,len

  \}

}

; ---   *   ---   *   ---
; compare two buffers

macro vmem.eq dst,s0,s1,ow= {

  ; varlis
  local len
  len equ vmem.eq.len

  ; reset out
  dst = 0


  ; unroll srcs
  match A B , s0 s1 \{

    ; get chunk size
    vuint.defval len,B\#.len,ow

    ; skip on bad length
    if ~(A\#.len = len)
      dst = 1

    ; ^else compare
    else
      vmem.xwalk len,vmem.EQAB,dst,A,B

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
