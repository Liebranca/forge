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

  VERSION   v0.00.3b
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

macro varray.set value {

  local len
  local i

  len = 0
  i   = 0

  $mov len,dr

  while len > 0
    vmem.xmov len,ptr ar+cr,value,i

  end while

}

; ---   *   ---   *   ---
; write to top

macro varray.push value {

  $mov er,[ice+varray.ezy]
  varray.resize_chk er

  $mov ar,qword [ice+varray.buff]
  $mov cr,dword [ice+varray.top]
  $mov dr,dword [ice+varray.ezy]

  varray.set value

  $add dword [ice+varray.top],dr

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
