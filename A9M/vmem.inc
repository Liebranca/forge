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

  VERSION   v0.00.8b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define vmem.bops_list
  define vmem.uops_list

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
; my favorite conditional
; REALLY

macro vmem.xfn len,op,args& {

  if len = 1
    op args,byte

  else if len < 4
    op args,word

  else if len < 8
    op args,dword

  else
    op args,qword

  end if

}

; ---   *   ---   *   ---
; ^get N-sized step/mask/shift

macro vmem.xstep dst,len,mode=sizeof {
  vmem.xfn len,vmem._xstep,dst,mode

}

; ---   *   ---   *   ---
; ^shorthand

macro vmem._xstep dst,mode,size {

  match =sizeof , mode \{
    dst = sizeof.#size

  \}

  match =sizep2 , mode \{
    dst = sizep2.#size

  \}

  match =sizebm , mode \{
    dst = sizebm.#size

  \}

}

; ---   *   ---   *   ---
; ^N-sized ld/st

macro vmem.xld dst,src,off,len {
  vmem.xfn len,vmem._xld,dst,src,off

}

macro vmem.xst dst,src,off,len {
  vmem.xfn len,vmem._xst,dst,src,off

}

; ---   *   ---   *   ---
; ^shorthands

macro vmem._xld dst,src,off,size {

  match id , src \{

    load dst size from id\#.base:\
      id\#.beg+off*sizeof.#size

  \}

}

macro vmem._xst dst,src,off,size {

  match id , dst \{
    store size src at id\#.base:\
      id\#.beg+off*sizeof.#size

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
; overwrite length

macro vmem.proclen dst,src,ow {

  dst=src

  match any , ow \{
    dst=ow

  \}

}

; ---   *   ---   *   ---
; write contents of one
; buffer to another

macro vmem.copy dst,src,ow= {

  ; varlis
  local w0
  local len

  w0  equ vmem.copy.w0
  len equ vmem.copy.len

  match A B , dst src \{

    ; get chunk size
    vmem.proclen len,B\#.len,ow

    ; errchk
    if len > A\#.len
      out@err 'OOB vmem copy'

    end if


    ; walk B and set A
    local shift
    shift equ vmem.copy.shift

    vmem.xstep    shift,len,sizep2

    vuint.urdivp2 len,len,shift


    repeat len
      vmem.xld w0,B,(%-1),(len shl shift)
      vmem.xst A,w0,(%-1),(len shl shift)

    end repeat

  \}

}

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

    local len
    local shift

    len   equ vmem.clear.len
    shift equ vmem.clear.shift

    vmem.xstep    shift,id\#.len,sizep2
    vuint.urdivp2 len,id\#.len,shift

    repeat len
      vmem.xst dst,$00,(%-1),(len shl shift)

    end repeat

    id\#.ptr = 0
    id\#.len = 0
    id\#.pad = id\#.size

  \}

}

; ---   *   ---   *   ---
; compare two buffers

macro vmem.eq dst,s0,s1,ow= {


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

    ; get chunk size
    local _step
    vmem.proclen len,id1\#.size,ow

    ; skip on bad length
    if ~(id0\#.len < len)
      dst = 1

    ; ^else compare
    else

      ; walk in N-sized steps
      local shift
      shift equ vmem.eq.shift

      vmem.xstep    step,len,sizep2

      vuint.urdivp2 len,len,shift

      repeat len

        vmem.xld w0,id0,(%-1),(len shl shift)
        vmem.xld w1,id1,(%-1),(len shl shift)

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
    out@nl  2


    ; get print size
    if parshow & 1
      psize=id\#.size

    else
      psize=(id\#.len+id\#.pad)

    end if


    ; walk in N-sized steps
    local shift
    local step

    shift equ vmem.prich.shift
    step  equ vmem.prich.step

    vmem.xstep    shift,psize,sizep2
    vmem.xstep    step,psize,sizeof

    vuint.urdivp2 psize,psize,shift


    ; show raw : print
    repeat psize

      vmem.xld \c,id,(%-1),(psize shl shift)

      xesay    \c,8*step
      out@nl


    end repeat
    out@nl 2

  \}

}

; ---   *   ---   *   ---
; template for operator wraps

macro vmem._op_proto buff,addr,size,fn,args& {

  ; varlis
  local dst
  dst equ vmem._op_proto.dst

  ; ^get current value
  vmem.get dst,buff,addr,size

  ; ^run op
  match any , args \{
    fn dst,args

  \}

  match , args \{
    fn dst

  \}


  ; ^overwrite
  vmem.set buff,dst,addr,size

}

; ---   *   ---   *   ---
; ^generator

macro vmem._gen_op MN,ct& {

  match mode name list , MN ct \{


    ; signature for unary op
    match =u , mode \\{

      ; register F name
      commacat vmem.uops_list,name

      ; execute passed code
      macro vmem.\#name\#.inner dst \\\{
        cline.filter list

      \\\}

      ; ^wraps
      macro vmem.\#name \
        buff,addr,size=byte \\\{

        vmem._op_proto buff,addr,size,\
          vmem.\#name\#.inner

      \\\}

    \\}


    ; ^binary
    match =b , mode \\{

      ; register F name
      commacat vmem.bops_list,name

      ; execute passed code
      macro vmem.\#name\#.inner dst,src \\\{
        cline.filter list

      \\\}

      ; ^wraps
      macro vmem.\#name \
        buff,src,addr,size=byte \\\{

        vmem._op_proto buff,addr,size,\
          vmem.\#name\#.inner,src

      \\\}

    \\}


  \}

}

; ---   *   ---   *   ---
; ^icebox

vmem._gen_op b xor   , dst=dst xor src
vmem._gen_op b or    , dst=dst or  src
vmem._gen_op b and   , dst=dst and src

vmem._gen_op u not   , dst=not dst
vmem._gen_op b xnor  , dst=not (dst xor src)
vmem._gen_op b nor   , dst=not (dst or  src)
vmem._gen_op b nand  , dst=not (dst and src)

vmem._gen_op b shr   , dst=dst shr src
vmem._gen_op b shl   , dst=dst shl src

vmem._gen_op b bsf   , dst=bsf src
vmem._gen_op b bsr   , dst=bsr src

vmem._gen_op b add   , dst=dst+src
vmem._gen_op u inc   , dst=dst+1
vmem._gen_op b sub   , dst=dst-src
vmem._gen_op u dec   , dst=dst-1

vmem._gen_op b mul   , dst=dst * src

; ---   *   ---   *   ---
