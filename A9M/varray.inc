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

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; base struc

vreg.new varray

  szmy dword cap
  szmy dword grow
  szmy dword ezy
  szmy dword cnt
  szmy dword top
  szmy dword pad

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
  $mov dword [ice+varray.ezy],ezy
  $mov dword [ice+varray.cnt],cnt
  $mov dword [ice+varray.top],$00


  ; make buffer
  valloc cap
  $mov   qword [ice+varray.buff],ar

  ; reset out
  $mov ar,ice

}

;; ---   *   ---   *   ---
;; write to top
;
;macro varray.push value {
;
;  match ice , vmc.REG.ice \{
;
;
;
;  \}
;
;}

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
