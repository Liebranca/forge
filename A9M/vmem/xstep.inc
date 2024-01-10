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

  VERSION   v0.00.2b
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
; ^shorthands

macro vmem._xld dst,src,off,size {

  match id , src \{

    load dst size from id\#.base:\
      id\#.beg+(off*sizeof.#size)

  \}

}

macro vmem._xst dst,src,off,size {

  match id , dst \{

    store size (src and sizebm.#size) \
      at id\#.base:\
      id\#.beg+(off*sizeof.#size)

  \}

}

; ---   *   ---   *   ---
; iter through buff in
; progressively smaller
; steps, as required

macro vmem.xwalk size,fn,args& {

  local shift
  local len
  local have
  local step
  local i

  ; save total
  have = size
  i    = 0

  ; ^iter
  while have

    vmem.xstep shift,have,sizep2

    len  = have shr shift
    step = 1 shl shift
    i    = i shr shift

    repeat len

      match list , args \{
        fn list,i,i,step

      \}

      match , args \{
        fn i,i,step

      \}

      i = i+1

    end repeat

    i    = i shl shift
    have = have - (len shl shift)

  end while

}

; ---   *   ---   *   ---
; write value to dst

macro vmem.WTA dst,value,i0,i1,step {
  vmem.xst dst,value,i0,step

}

; ---   *   ---   *   ---
; read value from src

macro vmem.LDA dst,src,i0,i1,step {
  vmem.xld dst,src,i0,step

}

; ---   *   ---   *   ---
; put into current space

macro vmem.DUMPA src,i0,i1,step {

  local w0

  vmem.LDA w0,src,i0,i1,step
  vmem.xdd w0,step

}

; ---   *   ---   *   ---
; write step from src to dst

macro vmem.BTOA dst,src,i0,i1,step {

  local w0

  vmem.xld w0,src,i1,step
  vmem.xst dst,w0,i0,step

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

  vmem.BTOA  dst,src,b0+i0,b1+i1,step
  vmem.lseek dst,step

  local ok
  ok equ 0

  match =0 , b1 \{
    ok equ 1

  \}

  match =0 , ok \{
    vmem.lseek src,step

  \}

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

  vmem.LOADAB A,B,w0,w1,i0,i1,step

  dst = dst or (w0 xor w1)

}

; ---   *   ---   *   ---
; writes buff repr to tty

macro vmem.DBOUT id,i0,i1,step {

  local w0

  vmem.xld w0,id,i0,step

  xesay    w0,8*step
  out@nl

}

; ---   *   ---   *   ---
