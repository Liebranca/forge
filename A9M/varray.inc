; ---   *   ---   *   ---
; A9M VARRAY
; A barrel of things
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.varray

  VERSION   v0.00.4b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; base struc

vreg.new varray

  szmy dword grow
  szmy dword igrow

  szmy dword ezy
  szmy dword cnt

  szmy dword cap
  szmy dword top

  szmy qword buff

vreg.end

; ---   *   ---   *   ---
; cstruc

macro varray.new ezy,cnt {

  ; get total size
  local cap
  local self

  cap = ezy * cnt


  ; make container
  valloc sizeof.varray
  $mov   ice,ar

  ; ^fill struc
  $mov dword [ice+varray.cap],cap
  $mov dword [ice+varray.grow],cap
  $mov dword [ice+varray.cnt],cnt
  $mov dword [ice+varray.igrow],cnt
  $mov dword [ice+varray.ezy],ezy
  $mov dword [ice+varray.top],$00


  ; make buffer
  valloc cap
  $mov   qword [ice+varray.buff],ar

  ; reset out
  $mov ar,ice

}

; ---   *   ---   *   ---
; grow array on cap hit

macro varray.resize_chk step {

  local top
  local have
  local need
  local grow

  top  = 0
  have = 0
  need = 0

  ; get top,capacity
  $mov top,dword [ice+varray.top]
  $add top,step

  $mov have,dword [ice+varray.cap]

  ; ^over the limit?
  while have < top

    $add have,dword [ice+varray.grow]
    $add dword [ice+varray.cnt],\
      dword [ice+varray.igrow]

    need = 1

  end while

  ; ^perform realloc?
  if need = 1

    $mov     er,qword [ice+varray.buff]
    vrealloc er,have

    $mov     qword [ice+varray.buff],ar
    $mov     dword [ice+varray.cap],have

  end if

}

; ---   *   ---   *   ---
; write [dr] bytes at [ar+cr]

macro varray.set src {

  local len
  local i

  len = 0
  i   = 0

  $mov len,dr

  while len > 0
    vmem.xmov len,ptr ar+cr,src,i

  end while

}

; ---   *   ---   *   ---
; read [dr] bytes from [ar+cr]

macro varray.get dst {

  local len
  local i

  len = 0
  i   = 0

  $mov len,dr

  while len > 0
    vmem.xmov len,dst,ptr ar+cr,i

  end while

}

; ---   *   ---   *   ---
; * load buff into ar
; * elem size into dr
; * passed ptr into cr (else top!)

macro varray.preread i=-1 {

  $mov ar,i

  ; backwards indexing ;>
  $on ar > negate.qword

    $mov cr,dword [ice+varray.top]
    $inc ar
    $add cr,ar

  ; ^else get passed as-is
  else
    $mov cr,i

  end if


  ; no conditions here
  $mov ar,qword [ice+varray.buff]
  $mov dr,dword [ice+varray.ezy]

}

; ---   *   ---   *   ---
; write to top

macro varray.push src {

  ; will value fit?
  $mov er,[ice+varray.ezy]
  varray.resize_chk er

  ; perform write
  varray.preread
  varray.set src

  ; step over next slot
  $add dword [ice+varray.top],dr

}

; ---   *   ---   *   ---
; ^read at idex

macro varray.view dst,i=-1 {
  varray.preread i
  varray.get     dst

}

; ---   *   ---   *   ---
; remove from top-1
; optional write to dst

macro varray.pop dst= {

  ; go back one slot
  $sub dword [ice+varray.top],\
    dword [ice+varray.ezy]

  ; perform write?
  match any , dst \{
    varray.preread
    varray.get dst

  \}

}

; ---   *   ---   *   ---
; dbout

macro varray.prich header=1 {

  out@nl

  ; show header?
  if header = 1

    display     'HEAD:',$0A

    local       vi

    $view       vi at ice:sizeof.varray
    vmem.bprich vi,1,0

  end if


  ; get buffer and size
  local size
  local buff

  $mov  size,dword [ice+varray.cap]
  $mov  buff,qword [ice+varray.buff]

  ; ^make view of buffer and out
  display     'BUFF:',$0A

  local       vi

  $view       vi at buff:size
  vmem.bprich vi,1,0

}

; ---   *   ---   *   ---
