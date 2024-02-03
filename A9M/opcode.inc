; ---   *   ---   *   ---
; A9M OPCODE
; Punching bits
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.opcode

  VERSION   v0.00.8a
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; load tables

  include   '%ARPATH%/forge/A9M/ROM/ISA.pinc'

; ---   *   ---   *   ---
; GBL

  bipret.opsize    = $00
  bipret.opsize_bs = $00
  bipret.opsize_bm = $00

; ---   *   ---   *   ---
; read opcode

macro $bipret X {

  ; copy input
  local opcode
  opcode = X

  ; ^vars to unpack
  local opid

  local load_src
  local load_dst
  local overwrite
  local immbs
  local immbm

  local argcnt
  local argflag

  ; ^fetch em from ROM ;>
  A9M.OPCODE.read opid,opcode,\
\
    load_src,load_dst,overwrite,\
\
    argcnt,argflag,\
\
    bipret.opsize,bipret.opsize_bm,\
    bipret.opsize_bs,immbs,immbm


  ; ^consume operand bits if any
  if argcnt > 0

    ; ptr/value A
    local vX
    local pX

    ; ptr/value B
    local vY
    local pY

    ; separate dst/src argflags
    local dstflag
    dstflag = argflag and A9M.OPCODE.ARGFLAG_FBM


    ; destination is register
    if dstflag = A9M.OPCODE.ARGFLAG_REG
      $bipret.regarg vX,opcode


    ; destination is memory
    else if dstflag = A9M.OPCODE.ARGFLAG_MEMSTK
      $bipret.memarg_stk vX,opcode

    else if dstflag = A9M.OPCODE.ARGFLAG_MEMSHORT
      $bipret.memarg_short vX,opcode

    else if dstflag = A9M.OPCODE.ARGFLAG_MEMLONG
      $bipret.memarg_long vX,opcode

    else if dstflag = A9M.OPCODE.ARGFLAG_MEMPOS
      $bipret.memarg_pos vX,opcode

    end if


    ; handle deref A
    pX = vX

    if load_dst=1
      vmem.xldus vX,vmc.CAS,pX,bipret.opsize

    end if


    ; have source operand?
    if argcnt = 2

      local srcflag
      local immflag

      srcflag=argflag shr A9M.OPCODE.ARGFLAG_FBS
      immflag= \
         (srcflag and A9M.OPCODE.ARGFLAG_IMM8)  \
      or (srcflag and A9M.OPCODE.ARGFLAG_IMM16) \
      -  srcflag

      ; source is register
      if srcflag = A9M.OPCODE.ARGFLAG_REG
        $bipret.regarg vY,opcode

      ; source is immediate
      else if immflag = 0
        $bipret.immarg vY,opcode,immbm,immbs


      ; source is memory
      else if srcflag = A9M.OPCODE.ARGFLAG_MEMSTK
        $bipret.memarg_stk vY,opcode

      else if srcflag = A9M.OPCODE.ARGFLAG_MEMSHORT
        $bipret.memarg_short vY,opcode

      else if srcflag = A9M.OPCODE.ARGFLAG_MEMLONG
        $bipret.memarg_long vY,opcode

      else if srcflag = A9M.OPCODE.ARGFLAG_MEMPOS
        $bipret.memarg_pos vY,opcode

      end if


      ; handle deref B
      pY=vY


      if load_src &~ (immflag = 0)
        vmem.xldus vY,vmc.CAS,pY,bipret.opsize

      end if


      ; instruction jump table
      A9M.OPCODE.switch_args2 opid,vX,vY


    ; nope, single operand
    else
      A9M.OPCODE.switch_args1 opid,vX

    end if


    ; store result to dst?
    if overwrite
      vmem.xstus vmc.CAS,vX,pX,bipret.opsize

    end if


  ; no operands
  else

  end if

}

; ---   *   ---   *   ---
; read register operand
;
; this is a straight mapping
; of idex to ANIMA addr, so
; fairly trivial; the Arcane 9
; sees only sixteen registers:
;
; * (a  ,b  ,c  ,d   ) :0-3
; * (e  ,f  ,g  ,h   ) :4-7
; * (xp ,xs ,sp ,sb  ) :8-B
; * (ice,ctx,opt,chan) :C-F
;
; note though that these are
; used for opsizes less than 16
;
; for opsizes with vector (AVX)
; registers, we'll have to
; pair this with a base add to
; conditionally offset into
; the vector ANIMA, which isn't
; yet implemented!
;
; so for now we'll leave this
; as a straight and+mul ;>

macro $bipret.regarg dst,src {

  dst = (src and A9M.REGISTER_CNT_BM) \
    shl A9M.REGISTER_SZP2

  src = src shr A9M.REGISTER_CNT_BS

}

; ---   *   ---   *   ---
; read immediate operand

macro $bipret.immarg dst,src,bm,bs {
  dst = src and bm
  src = src shr bs

}

; ---   *   ---   *   ---
; segment table
;
; used to fetch address bases,
; as all pointers are relative
;
; modified by call/ret

virtual at $00
bipret.segtab::

  repeat A9M.SEGTAB_SZ
    dq $00

  end repeat

end virtual

; ---   *   ---   *   ---
; read stack relative memory

macro $bipret.memarg_stk dst,src {

  ; mask imm bits and shift them out
  dst = src and bipret.memarg_stk.imm_bm
  src = src shr bipret.memarg_stk.imm_bs

  ; get sb register
  local rX
  rX = $0B shl A9M.REGISTER_SZP2
  load rX word from ANIMA.base:rX


  ; give sb-offset
  dst = rX-dst

}

; ---   *   ---   *   ---
; read segment relative memory

macro $bipret.memarg_pos dst,src {

  ; mask seg/imm bits and shift them out
  local seg
  local imm

  seg = src and A9M.SEGTAB_BM
  src = src shr A9M.SEGTAB_BS

  imm = src and bipret.memarg_pos.imm_bm
  src = src shr bipret.memarg_pos.imm_bs


  ; read base from segment table
  load seg qword from bipret.segtab:seg shl 3

  ; give absolute
  dst = seg+imm

}

; ---   *   ---   *   ---
; read short-form relative

macro $bipret.memarg_short dst,src {

  ; mask seg/imm/reg bits and shift them out
  local seg
  local reg
  local imm

  seg = src and A9M.SEGTAB_BM
  src = src shr A9M.SEGTAB_BS

  reg = src and A9M.REGISTER_CNT_BM
  src = src shr A9M.REGISTER_CNT_BS

  imm = src and bipret.memarg_short.imm_bm
  src = src shr bipret.memarg_short.imm_bs


  ; read base from segment table
  load seg qword from bipret.segtab:seg shl 3

  ; read register
  load reg qword from ANIMA.base:\
    reg shl A9M.REGISTER_SZP2

  ; give absolute
  dst = seg+reg+imm

}

; ---   *   ---   *   ---
; long-form relative, calc'd
; by adding/shifting registers
;
; * first field is null or [0-register_sz)
;
; * ^idem for second field
;
; * third is imm offset
;
; * scale, used as shift

macro $bipret.memarg_long dst,src {

  local rX
  local rY
  local off
  local scale


  ; decode register part
  $bipret.memarg_long.reg rX,dst
  $bipret.memarg_long.reg rY,dst


  ; get scale and offset
  off   = dst and bipret.memarg_long.imm_bm
  dst   = dst shr bipret.memarg_long.imm_bs
  scale = dst and bipret.memarg_long.scale_bm
  dst   = dst shr bipret.memarg_long.scale_bs


  ; apply scale to offset if non-zero
  if off > 0
    off = off shl scale

  ; ^else apply it to second register
  ; if it's non-zero
  else if rY > 0
    rY = rY shl scale

  ; ^else apply it to first register
  else
    rX = rX shl scale

  end if


  dst = rX+rY+off

}

; ---   *   ---   *   ---
; conditionally get value
; in register

macro $bipret.memarg_long.reg dst,src {

  dst = src and A9M.REGISTER_CNT_BM
  src = src shr A9M.REGISTER_CNT_BS

  if dst > 0
    dst = (dst-1) shl A9M.REGISTER_SZP2
    load dst word from ANIMA.base:dst

  end if

}

; ---   *   ---   *   ---
