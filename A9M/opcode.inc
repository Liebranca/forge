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

  VERSION   v0.00.5b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; load tables

  include   '%ARPATH%/forge/A9M/ROM/isbasic.pinc'

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

  local argcnt
  local argflag

  local opsize
  local opsize_bm
  local opsize_bs

  ; ^fetch em from ROM ;>
  A9M.OPCODE.read opid,opcode,\
    load_src,load_dst,overwrite,\
    argcnt,argflag,\
    opsize,opsize_bm,opsize_bs


  ; ^consume operand bits if any
  if argcnt > 0


    ; reload offsets table for
    ; memory operands
    $bipret.memarg.reload


    ; get destination: memory
    local vX

    if argflag and A9M.OPCODE.MEMDST
      $bipret.memarg vX,opcode

    ; ^register
    else
      $bipret.regarg vX,opcode

    end if


    ; have source operand?
    if argcnt > 1

      local vY

      ; get source: memory
      if argflag and A9M.OPCODE.MEMSRC
        $bipret.memarg vY,opcode

      ; ^immediate
      else if argflag and A9M.OPCODE.IMMSRC
        $bipret.immarg vY,opcode,\
          opsize_bm,opsize_bs

      ; ^register
      else
        $bipret.regarg vY,opcode

      end if


      display 'ARG0   '
      hexsay  vX,$10
      out@nl

      display 'ARG1   '
      hexsay  vY,$10
      out@nl


      ; handle deref
      local pX
      local pY

      pX=vX
      pY=vY

      match id , vmc.CAS \{

        if load_dst & argflag and 001b
          load vX word from id\#.base:pX

        end if

        if load_src & argflag and 010b
          load vY word from id\#.base:pY

        end if

      \}


      ; instruction jump table
      A9M.OPCODE.switch_args2 opid,vX,vY

      ; store result to dst?
      if overwrite
        store word vX at ANIMA.base:pX

      end if


    ; nope, single operand
    else

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
; always 16-bit for now

macro $bipret.immarg dst,src,bm,bs {
  dst = src and bm
  src = src shr bs

}

; ---   *   ---   *   ---
; mflag:GBL

virtual at $00
bipret.memarg.tab::

  ; sb register
  dq $00

  ; lea
  dq $00

  ; segment relative :o
  dq $00

  ; something something heap fetches
  dq sizeof.vmc+$38


  ; used for branchless fetch
  .sb   = $00
  .ice  = $00

  ; used to offset result
  .base = $00


end virtual

; ---   *   ---   *   ---
; read memory operand
;
;
; here we map the flag to
; read size like so:
;
; * 00 => stack-rel :$08
; * 10 => seg-rel   :$08
;
; * 01 => long-rel  :$10
; * 11 => heap-rel  :$20
;
;
; the addr is then read
; and casted to absolute

macro $bipret.memarg dst,src {

  ; copy the segment flags
  local mflag
  mflag = src and A9M.OPCODE.MFLAG_BM

  ; then shift them out
  src = src shr A9M.OPCODE.MFLAG_BS


  ; double size if long-form relative
  dst = 8 shl (mflag and A9M.OPCODE.MFLAG_REL)

  ; (byte) dst shl (src/3)
  ; thanks gcc ;>
  ;
  ; this doubles size again
  ; if *both* bits are set
  dst = dst shl ((mflag * $AB) shr 9)

  ; dst is now number of bits to read
  ; make a copy of that
  local bits
  bits = dst

  ; read bits to get offset
  dst = src and ((1 shl bits)-1)

  ; read base addr from table
  load bipret.memarg.tab.base qword \
  from bipret.memarg.tab:mflag shl sizep2.qword


  ; the worst case: 16-bit relative
  ; can't do it without a switch :c
  if mflag = A9M.OPCODE.MFLAG_REL
    $bipret.memarg.rel dst

  end if


  ; [negate offset if stack relative]
  ;
  ; we achieve this by using (again)
  ; the GNU div3 formula
  ;
  ; except this time src is inverted,
  ; so 0/3 becomes 3/3, and 3/3 becomes 0/3
  ;
  ; ie this means mul by -1 if both
  ; bits are turned off
  mflag = not mflag and A9M.OPCODE.MFLAG_BM
  dst   = dst * (1 - (((mflag * $AB) shr 9) shl 1))


  ; add base and offset to get absolute
  dst = bipret.memarg.tab.base+dst

  ; shift out the already read values
  src = src shr bits

}

; ---   *   ---   *   ---
; inconditional reload of ice
; and sb into the memarg table
;
; this makes it so we can read
; addresses that are relative to
; these pointers without an if

macro $bipret.memarg.reload {

  ; get sb register
  load bipret.memarg.tab.sb qword \
  from ANIMA.base:$0B shl A9M.REGISTER_SZP2

  ; ^get ice register
  load bipret.memarg.tab.ice qword \
  from ANIMA.base:$0C shl A9M.REGISTER_SZP2


  ; make sb absolute
  bipret.memarg.tab.sb = \
    bipret.memarg.tab.sb + sizeof.ANIMA


  ; store addrs in table
  store qword bipret.memarg.tab.sb \
  at bipret.memarg.tab:$00

  store qword bipret.memarg.tab.ice \
  at bipret.memarg.tab:$10

}

; ---   *   ---   *   ---
; relative offset, calc'd
; by adding/shifting registers
;
; * first field is null or [0-register_sz)
;
; * ^idem for second field
;
; * third is imm offset
;
; * scale, used as shift

macro $bipret.memarg.rel dst {

  local rX
  local rY
  local off
  local scale


  ; decode register part
  $bipret.memarg.relreg rX,dst,\
    bipret.memarg.rel.rX_bm,\
    bipret.memarg.rel.rX_bs

  $bipret.memarg.relreg rY,dst,\
    bipret.memarg.rel.rY_bm,\
    bipret.memarg.rel.rY_bs


  ; get scale and offset
  off   = dst and bipret.memarg.rel.off_bm
  dst   = dst shr bipret.memarg.rel.off_bs
  scale = dst and bipret.memarg.rel.scale_bm
  dst   = dst shr bipret.memarg.rel.scale_bs


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

macro $bipret.memarg.relreg dst,src,bm,bs {

  dst = src and bm
  src = src shr bs

  if dst > 0
    dst = (dst-1) shl A9M.REGISTER_SZP2
    load dst word from ANIMA.base:dst

  end if

}

; ---   *   ---   *   ---
; makes binary opcode

macro $bencode dst,NE& {

  local ok
  local _name
  local _expr
  local _size

  ok    equ 0
  _name equ NE
  _expr equ
  _size equ _


  ; got expression?
  match N E , NE \{

    local ok2
    ok2 equ 0

    _name equ N
    _expr equ E

    ; ^got size?
    match =byte _E , _expr \\{
      _size equ byte
      _expr equ _E
      ok2   equ 1

    \\}

    match =0 =word _E , ok _expr \\{
      _size equ word
      _expr equ _E

    \\}

  \}


  ; get args
  match name size expr , _name _size _expr \{

    ; two operands
    match A =, B , expr \\{

      local rX
      local rY
      local out

      local argflag_a
      local argflag_b
      local bitsz

      bitsz = 0


      ; encode both arguments
      $bencode.arg rX,argflag_a,bitsz,A,\
        A9M.OPCODE.IMM_BS

      out   = bitsz
      bitsz = 0

      $bencode.arg rY,argflag_b,bitsz,B,\
        A9M.OPCODE.IMM_BS

      local opcode


      ; lookup opcode in table
      $bencode.get_opcode opcode,name,size,\
        argflag_a,argflag_b

      ; ^cat to encoded args
      dst = opcode \
        or (rX shl OPCODE_ID_BITS) \
        or (rY shl (OPCODE_ID_BITS+out))


      ok equ 1

    \\}

    ; ^single
    match =0 A , ok expr \\{\\}
    ok equ 1

  \}

  ; ^no
  match =0 name , ok _name \{\}

}

; ---   *   ---   *   ---
; messy: gets name of a
; constant holding the
; opcode, based on the
; instruction passed

macro $bencode.get_opcode dst,name,size,\
  argflag_a,argflag_b {

  ; tmp
  local id
  local ok
  ok equ 0

  ; copy input
  local sizen
  sizen equ size


  ; skip size on reg to reg or imm to reg
  match =r =i , argflag_a argflag_b \{
    sizen equ

  \}

  match =r =r , argflag_a argflag_b \{
    sizen equ

  \}


  ; ^else cat size to id
  match AF BF SF , argflag_a argflag_b sizen \{
    id equ name#_\#AF\#BF\#_\#SF
    ok equ 1

  \}

  ; ^size skipped
  match =0 AF BF , ok argflag_a argflag_b \{
    id equ name#_\#AF\#BF

  \}


  ; give back opcode from id
  match any , id \{
    dst equ A9M.OPCODE.\#any

  \}

}

; ---   *   ---   *   ---
; identifies operand type,
; gives encoded value and
; writes type to argflag

macro $bencode.arg dst,\
  argflag,bitsz,expr,immbs {

  local ok
  ok equ 0

  $bencode.reg ok,dst,argflag,bitsz,expr
  $bencode.mem ok,dst,argflag,bitsz,expr
  $bencode.imm ok,dst,argflag,bitsz,expr,immbs

}

; ---   *   ---   *   ---
; value is register?

macro $bencode.reg ok,dst,argflag,bitsz,expr {

  match =0 list , ok A9M.REGISTERS \{

    ok equ 'I'
    tokin ok,expr,list

    ; yes
    match idex , ok \\{

      dst   = idex
      bitsz = A9M.REGISTER_CNT_BS

      argflag equ \r

      ok equ 1

    \\}

    ; no
    match , ok \\{
      ok equ 0

    \\}

  \}

}

; ---   *   ---   *   ---
; value is memory?

macro $bencode.mem ok,dst,argflag,bitsz,expr {

  match =[ subexpr =] , expr \{

    argflag equ \m

    $bencode.rel ok,dst,argflag,bitsz,subexpr

    ok equ 1

  \}

}

; ---   *   ---   *   ---
; value is immediate?

macro $bencode.imm ok,dst,\
  argflag,bitsz,expr,bs {

  match =0 , ok \{
    bitsz = bs
    dst   = expr
    argflag equ \i

  \}

}

; ---   *   ---   *   ---
; is value a relative ptr?

macro $bencode.rel ok,dst,argflag,bitsz,expr {

  local dummy

  local rX
  local rY
  local off
  local scale

  rX    = 0
  rY    = 0
  off   = 0
  scale = 0


  ; [rX + rY + (off << scale)]
  match A =+ B =+ C =* D , expr \{

    $bencode.reg ok,rX,dummy,dummy,A
    rX = (rX+1) and A9M.REGISTER_CNT_BM

    ok equ 0
    $bencode.reg ok,rY,dummy,dummy,B
    rY = (rY+1) and A9M.REGISTER_CNT_BM

    ok equ 0
    $bencode.imm ok,off,dummy,dummy,C,\
      bipret.memarg.rel.off_bs

    scale = (bsf D) \
      and bipret.memarg.rel.scale_bm

    ok equ 1

  \}

  ; [rX + ((rY|off) << scale)]
  match =0 A =+ B =* C , ok expr \{

    $bencode.reg ok,rX,dummy,dummy,A
    rX = (rX+1) and A9M.REGISTER_CNT_BM

    ok equ 0
    $bencode.reg ok,rY,dummy,dummy,B

    if ok
      rY  = (rY+1) and A9M.REGISTER_CNT_BM

    end if

    $bencode.imm ok,off,dummy,dummy,B,\
      bipret.memarg.rel.off_bs

    scale = (bsf C) \
      and bipret.memarg.rel.scale_bm

    ok equ 1

  \}

  ; [rX + rY + off]
  match =0 A =+ B =+ C , ok expr \{

    $bencode.reg ok,rX,dummy,dummy,A
    rX = (rX+1) and A9M.REGISTER_CNT_BM

    ok equ 0
    $bencode.reg ok,rY,dummy,dummy,B
    rY = (rY+1) and A9M.REGISTER_CNT_BM

    ok equ 0
    $bencode.imm ok,off,dummy,dummy,C,\
      bipret.memarg.rel.off_bs

    ok equ 1

  \}

  ; [rX << scale]
  match =0 A =* B , ok expr \{

    $bencode.reg ok,rX,dummy,dummy,A

    rX    = (rX+1) and A9M.REGISTER_CNT_BM
    scale = (bsf B) and \
      and bipret.memarg.rel.scale_bm

    ok equ 1

  \}

  ; [rX + (rY|off)]
  match =0 A =+ B , ok expr \{

    $bencode.reg ok,rX,dummy,dummy,A
    rX=(rX+1) and A9M.REGISTER_CNT_BM

    ok equ 0
    $bencode.reg ok,rY,dummy,dummy,B

    if ok
      rY  = (rY+1) and A9M.REGISTER_CNT_BM

    end if

    $bencode.imm ok,off,dummy,dummy,B,\
      bipret.memarg.rel.off_bs

    ok equ 1

  \}

  ; [rX|off]
  match =0 A , ok expr \{

    $bencode.reg ok,rX,dummy,dummy,A

    if ok
      rX=(rX+1) and A9M.REGISTER_CNT_BM

    end if

    $bencode.imm ok,off,dummy,dummy,A,\
      bipret.memarg.rel.off_bs

    ok equ 1

  \}


  ; pack result
  match =1 , ok \{

    off = off and bipret.memarg.rel.off_bm

    dst = \
       (rX    shl bipret.memarg.rel.rX_pos) \
    or (rY    shl bipret.memarg.rel.rY_pos) \
    or (off   shl bipret.memarg.rel.off_pos) \
    or (scale shl bipret.memarg.rel.scale_pos)

    dst = A9M.OPCODE.MFLAG_REL \
    or (dst shl A9M.OPCODE.MFLAG_BS)

    bitsz = bipret.memarg.rel._fmat_bs

  \}

}

; ---   *   ---   *   ---
