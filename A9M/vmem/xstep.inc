; ---   *   ---   *   ---
; A9M VMEM XSTEP
; I-sized generators
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.vmem.xstep

  VERSION   v0.00.4b
  AUTHOR    'IBN-3DILA'

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
; ^REPEATED
; N-sized data declaration

macro vmem.xdd src,len {

  if len = 1
    db src

  else if len < 4
    dw src

  else if len < 8
    dd src

  else
    dq src

  end if

}

; ---   *   ---   *   ---
; get N-sized step/mask/shift

macro vmem.xstep dst,len,mode=sizeof {
  vmem.xfn len,vmem._xstep,dst,mode

}

; ---   *   ---   *   ---
; ^guts

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
; ^guts

macro vmem._xld dst,src,off,sz {

  match size id , sz src \{

    local w0
    w0=id\#.beg+((off) * sizeof.\#size)

    vmem.boundschk id,w0,size,\
      "load past end of vmem"

    load dst size from id\#.base:w0

  \}

}

macro vmem._xst dst,src,off,sz {

  match size id , sz dst \{

    local w0
    local w1

    w0=(src) and sizebm.\#size
    w1=id\#.beg+((off) * sizeof.\#size)

    vmem.boundschk id,w1,size,\
      "store past end of vmem"

    store size w0 at id\#.base:w1

  \}

}

; ---   *   ---   *   ---
; ^N-sized ld/st (unscaled)

macro vmem.xldus dst,src,off,len {
  vmem.xfn len,vmem._xldus,dst,src,off

}

macro vmem.xstus dst,src,off,len {
  vmem.xfn len,vmem._xstus,dst,src,off

}

; ---   *   ---   *   ---
; ^guts

macro vmem._xldus dst,src,off,sz {

  match size id , sz src \{

    local w0
    w0=id\#.beg+(off)

    vmem.boundschk id,w0,size,\
      "load past end of vmem"

    load dst size from id\#.base:w0

  \}

}

macro vmem._xstus dst,src,off,sz {

  match size id , sz dst \{

    local w0
    local w1

    w0=(src) and sizebm.\#size
    w1=id\#.beg+(off)

    vmem.boundschk id,w1,size,\
      "store past end of vmem"

    store size w0 at id\#.base:w1

  \}

}

; ---   *   ---   *   ---
; caps len to bounds

macro vmem.xwall dst,src,addr {

  match id , src \{

    local diff

    ; assume qword read
    diff = id\#.size-addr

    if diff < 0
      diff = -diff

    end if

    ; ^cap to bounds
    if diff < dst
      dst = diff

    end if

  \}

}

; ---   *   ---   *   ---
; gutsof a walk!

macro vmem.xhave.next have,len,i,step,shift {

  vmem.xstep shift,have,sizep2

  len  = have shr shift
  step = 1 shl shift
  i    = i shr shift

}

macro vmem.xhave.cnt have,len,i,step,shift {

  i    = i shl shift
  have = have - (len shl shift)

}

; ---   *   ---   *   ---
; goes through buff

macro vmem.xhave have,fn,args& {

  ; lotsa vars
  local shift
  local step
  local len
  local i

  i     = 0
  step  = 0
  shift = 0
  len   = 0


  ; iter until all consumed
  while have

    vmem.xhave.next have,\
      len,i,step,shift

    repeat len
      vmem.xcall i,step,fn,args
      i = i+1

    end repeat

    vmem.xhave.cnt have,\
      len,i,step,shift

  end while

}

; ---   *   ---   *   ---
; ^the call itself

macro vmem.xcall i,step,fn,args& {

  ; have args
  match list , args \{
    fn list,i,i,step

  \}

  ; no args
  match , args \{
    fn i,i,step

  \}

}

; ---   *   ---   *   ---
; iter through buff in
; progressively smaller
; steps, as required

macro vmem.xwalk size,fn,args& {

  ; save total
  local have
  have = size

  ; default walk
  vmem.xhave have,fn,args

}

; ---   *   ---   *   ---
; ^bounded

macro vmem.xwalk_s size,src,addr,fn,args& {

  ; save total
  local have
  have = size

  ; default walk
  vmem.xwall have,src,addr
  vmem.xhave have,fn,args,src,addr

}

; ---   *   ---   *   ---
; write value to dst

macro vmem.STA dst,value,i0,i1,step {
  vmem.xst dst,value,i0,step

}

; ---   *   ---   *   ---
; read value from src

macro vmem.LDA dst,src,i0,i1,step {
  vmem.xld dst,src,i0,step

}

; ---   *   ---   *   ---
; bounded, piece-by-piece write

macro vmem.STAP dst,bits,src,addr,i0,i1,step {

  local      w0

  w0   = src shr bits
  bits = bits + (step*8)

  vmem.xstus dst,w0,i0,step

}

; ---   *   ---   *   ---
; ^same for load

macro vmem.LDAP dst,bits,src,addr,i0,i1,step {

  local      w0
  vmem.xldus w0,src,i0,step

  dst  = dst or (w0 shl bits)
  bits = bits + (step*8)

}

; ---   *   ---   *   ---
; put into current space

macro vmem.DUMPA src,i0,i1,step {

  local w0
  w0 = 0

  vmem.LDA w0,src,i0,i1,step
  vmem.xdd w0,step

}

; ---   *   ---   *   ---
; write step from src to dst

macro vmem.BTOA dst,src,i0,i1,step {

  local w0
  w0 = 0

  vmem.xldus w0,src,i1,step
  vmem.xstus dst,w0,i0,step

}

; ---   *   ---   *   ---
; ^write and move dst ptr

macro vmem.BTOAPTR dst,src,base,i0,i1,step {
  vmem.BTOA  dst,src,base+i0,i1,step
  vmem.lseek dst,step

}

; ---   *   ---   *   ---
; ^apply offset to src

macro vmem.BPTRTOAPTR dst,src,b0,b1,i0,i1,step {

  local w0
  w0 = 0

  vmem.xldus w0,src,b1+i1,step
  vmem.xstus dst,w0,b0+i0,step

  vmem.lseek dst,step
  vmem.lseek src,step

}

; ---   *   ---   *   ---
; get values

macro vmem.LOADAB A,B,w0,w1,i0,i1,step {
  vmem.xld w0,A,i0,step
  vmem.xld w1,B,i1,step

}

; ---   *   ---   *   ---
; ^dst or (A xor B)

macro vmem.EQAB dst,A,B,i0,i1,step {

  local w0
  local w1

  w0 = 0
  w1 = 0

  vmem.LOADAB A,B,w0,w1,i0,i1,step

  dst = dst or (w0 xor w1)

}

; ---   *   ---   *   ---
; writes buff repr to tty

macro vmem.DBOUT id,off,i0,i1,step {

  local w0

  w0=0

  vmem.xldus    w0,id,i0+off,step
  vmem.qwordsay w0,$00

}

; ---   *   ---   *   ---
