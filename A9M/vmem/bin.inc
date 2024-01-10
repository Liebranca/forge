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

  VERSION   v0.00.2b
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
; ^cat to fout

macro vmem.write dst,ct& {

  match id , dst \{

    virtual id\#.base

      local len
      local beg

      beg=$

      local ok
      ok equ 0

      ; src is a buffer
      match =ptr src , ct \\{
        vmem.paste src
        ok equ 1

      \\}

      ; ^typecasted buffer
      match =% src , ct \\{
        vmem.paste src\\#%origin
        ok equ 1

      \\}

      ; ^regular string
      match =0 , ok \\{
        db ct

      \\}

      len=$-beg
      id\#.size=id\#.size+len

      vmem.update_meta dst,len

    end virtual

  \}

}

; ---   *   ---   *   ---
; dump whole buffer

macro vmem.paste src {

  match id , src \{
    vmem.xwalk id\#.size,vmem.DUMPA,src

  \}

}

; ---   *   ---   *   ---
; set value at ptr

macro vmem.store dst,src,size=byte {

  match id , dst \{

    vmem.boundschk id,id\#.ptr,size,\
      "store past end of vmem"


    ; set and move ptr
    store size (src and sizebm.#size) \
      at id\#.base:\
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

    vmem.xwalk id\#.size,\
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

    len = src\#.len
    off = 0

    match any , srcptr \\{
      off = src\#.ptr

    \\}

    len = (len-off)


    ; resize dst?
    if dst\#.size < (dst\#.ptr+len)

      local nchunk
      local diff

      diff = (dst\#.ptr+len) - dst\#.size

      vmem.seg nchunk,dst,blk diff

    end if


    ; get base offset
    local base
    base = dst\#.ptr

    ; ^write src+off to dst ptr
    vmem.xwalk len,\
      vmem.BPTRTOAPTR,dst,src,base,off

    vmem.update_meta dst,dst\#.ptr

    match any , srcptr \\{
      vmem.update_meta src,src\#.ptr

    \\}

  \}

}

; ---   *   ---   *   ---
; write contents of one
; buffer to another

macro vmem.copy dst,src,ow= {

  match A B , dst src \{

    ; size passed?
    local len
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
  len = 0

  ; reset out
  dst = 0


  ; unroll srcs
  match A B , s0 s1 \{

    ; get chunk size
    vuint.defval len,B\#.len,ow

    ; skip on bad length
    if ~(A\#.len < len)
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
