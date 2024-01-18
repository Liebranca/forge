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

  VERSION   v0.00.5b
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
; shorthand. loads:
;
; * buff into ar
;
; * elem size into dr
;
; * passed ptr into cr (else top!)

macro varray.preread i=-1 {

  ; get elem size
  $mov dr,dword [ice+varray.ezy]

  ; get index
  $mov ar,i

  ; backwards indexing ;>
  $on ar > negate.qword

    $mov cr,dword [ice+varray.top]
    $neg ar

    $mul ar,dr
    $sub cr,ar

    ; clamp to zero
    $on cr > negate.qword
      $xor cr,cr

    end if

  ; ^else get passed as-is
  else
    $mov cr,i
    $mul cr,dr

  end if


  ; get buff addr
  $mov ar,qword [ice+varray.buff]

}

; ---   *   ---   *   ---
; read at idex

macro varray.view dst,i=-1 {
  varray.preread i
  varray.get     dst

}

; ---   *   ---   *   ---
; write to end

macro varray.push src {

  ; will value fit?
  $mov er,[ice+varray.ezy]
  varray.resize_chk er

  ; perform write
  varray.preread
  varray.set src

  ; step right one slot
  $add dword [ice+varray.top],dr

}

; ---   *   ---   *   ---
; write to beg

macro varray.unshift src {

  ; re-push last element
  ; this grows the array by one slot
  local head

  varray.view head
  varray.push head


  ; move every element right one slot
  local len
  $mov  len,cr
  $div  len,dr

  repeat len+1


    ; get current
    local      elem
    varray.get elem

    ; ^put ahead
    $add cr,dr
    varray.set elem


    ; go back
    $lea cr,[cr-dr*2]
    $sub len,dr


  end repeat


  ; now insert new elem at beg
  $mov cr,$00
  varray.set src

}

; ---   *   ---   *   ---
; remove from end-1
; optional write to dst

macro varray.pop dst= {

  ; go back one slot
  $sub dword [ice+varray.top],\
    dword [ice+varray.ezy]

  ; ^die on empty
  $mov ar,dword [ice+varray.top]
  $on ar > negate.dword
    out@err 'array overpop'

  end if


  ; perform write?
  match any , dst \{
    varray.preread
    varray.get dst

  \}

}

; ---   *   ---   *   ---
; remove from beg
; optional write to dst

macro varray.shift dst {

  ; save first element if
  ; requested
  match any , dst \{
    varray.view dst,0

  \}


  ; shrink one slot
  $sub dword [ice+varray.top],dr

  local len
  $mov  len,dword [ice+varray.top]

  ; ^die on empty array
  if len > negate.dword
    out@err 'array overshift'

  end if


  ; move every element left one slot
  $xor  cr,cr
  $div len,dr

  repeat len+1

    ; get ahead
    local elem
    $add  cr,dr

    varray.get elem

    ; ^put back
    $sub cr,dr
    varray.set elem


    ; go back
    $lea cr,[cr+dr*2]
    $sub len,dr


  end repeat

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
