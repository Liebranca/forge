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

  VERSION   v0.00.6b
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


    ; reload offsets table for
    ; memory operands
    $bipret.memarg.reload


    ; get destination: memory
    if argflag and A9M.OPCODE.MEMDST
      $bipret.memarg vX,opcode

    ; ^register
    else
      $bipret.regarg vX,opcode

    end if


    ; handle deref A
    pX = vX

    if load_dst=1
      vmem.xldus vX,vmc.CAS,pX,bipret.opsize

    end if


    ; have source operand?
    if argcnt = 2

      ; get source: memory
      if argflag and A9M.OPCODE.MEMSRC
        $bipret.memarg vY,opcode

      ; ^immediate
      else if argflag and A9M.OPCODE.IMMSRC
        $bipret.immarg vY,opcode,\
          immbm,immbs

      ; ^register
      else
        $bipret.regarg vY,opcode

      end if


      ; handle deref B
      pY=vY


      if load_src \
      &~ (argflag and A9M.OPCODE.IMMSRC)
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
; 32-bit capped

macro $bipret.immarg dst,src,bm,bs {
  dst = src and (bm shr (bs shr $06))
  src = src shr bs

}

; ---   *   ---   *   ---
; mflag:GBL

virtual at $00
bipret.memarg.tab::

  ; sb register
  dq $00

  ; long-form relative
  dq $00

  ; segment relative :o
  dq $00

  ; something something heap fetches
  dq sizeof.vmc+$38


  ; used for branchless fetch
  .sb = $00

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
  mflag = src and A9M.OPCODE.MFLAG._fmat_bm

  ; then shift them out
  src = src shr A9M.OPCODE.MFLAG._fmat_bs

  ; base size if short-form relative
  ; double size if long-form relative
  dst = A9M.OPCODE.MEM_BS_BASE \
  shl ((mflag and A9M.OPCODE.MFLAG.rel)\
    shr A9M.OPCODE.MFLAG.rel_pos)

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


  ; the worst case: long-form relative
  ; this is when you [r+r+imm*scale]
  ;
  ; i can't decode that without switches :c
  if mflag = A9M.OPCODE.MFLAG.rel
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
  mflag = not mflag \
    and A9M.OPCODE.MFLAG._fmat_bm

  dst   = dst * (1 - (((mflag * $AB) shr 9) shl 1))


  ; add base and offset to get absolute
  dst = bipret.memarg.tab.base+dst

  ; shift out the already read values
  src = src shr bits

}

; ---   *   ---   *   ---
; inconditional reload of sb
; into the memarg table
;
; this makes it so we can read
; addresses that are relative to
; the stack base without an if

macro $bipret.memarg.reload {

  ; get sb register
  load bipret.memarg.tab.sb qword \
  from ANIMA.base:$0B shl A9M.REGISTER_SZP2

  ; make absolute
  bipret.memarg.tab.sb = \
    bipret.memarg.tab.sb + sizeof.ANIMA


  ; ^store absolute in table
  store qword bipret.memarg.tab.sb \
  at bipret.memarg.tab:$00

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
  _size equ A9M.INS_DEF_SZ


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

    match =0 =qword _E , ok2 _expr \\{
      _size equ qword
      _expr equ _E
      ok2   equ 1

    \\}

    match =0 =dword _E , ok2 _expr \\{
      _size equ dword
      _expr equ _E
      ok2   equ 1

    \\}

    match =0 =word _E , ok2 _expr \\{
      _size equ word
      _expr equ _E
      ok2   equ 1

    \\}

  \}


  ; block o vars
  local rX
  local rY
  local out

  local argflag_a
  local argflag_b
  local bitsz
  local opcode
  local args

  bitsz = 0


  ; get args
  match name expr , _name _expr \{

    ; two arguments
    match A =, B , expr \\{

      ; encode first argument
      $bencode.arg rX,argflag_a,bitsz,A,_size

      ; ^get size
      out   = bitsz
      bitsz = 0

      ; ^encode second argument
      $bencode.arg rY,argflag_b,bitsz,B,_size
      args = rX or (rY shl out)


      ok equ 1

    \\}

    ; ^one argument
    match =0 A , ok expr \\{

      ; encode first argument
      $bencode.arg rX,argflag_a,bitsz,A,_size

      argflag_b equ
      args=rX

    \\}


    ; lookup opcode in table
    $bencode.get_opcode opcode,name,_size,\
      argflag_a,argflag_b

    ; ^cat to encoded args
    dst = opcode or (args shl OPCODE_ID_BITS)
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

  local id
  local ok
  ok equ 0

  ; cat size to id
  match AF BF SF , argflag_a argflag_b size \{
    id equ name#_\#AF\#BF\#_\#SF
    ok equ 1

  \}

  ; ^single-arg
  match =0 AF SF , ok argflag_a size \{
    id equ name#_\#AF\#_\#SF
    ok equ 1

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
  argflag,bitsz,expr,size {

  local ok
  ok equ 0

  $bencode.reg ok,dst,argflag,bitsz,expr
  $bencode.mem ok,dst,argflag,bitsz,expr
  $bencode.imm ok,dst,argflag,bitsz,expr,size

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
  argflag,bitsz,expr,size {

  match =0 any , ok size \{

    bitsz = \
        (sizeof.\#any shl 3) \
    shr (sizeof.\#any shr 3)

    dst   = expr and sizebm.dword
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

    $bencode.rel.reg   rX,A
    $bencode.rel.reg   rY,B
    $bencode.rel.imm   off,C
    $bencode.rel.scale scale,D

    ok equ 1

  \}

  ; [rX + ((rY|off) << scale)]
  match =0 A =+ B =* C , ok expr \{

    $bencode.rel.reg        rX,A
    $bencode.rel.reg_or_imm rY,off,B
    $bencode.rel.scale      scale,C

    ok equ 1

  \}

  ; [rX + rY + off]
  match =0 A =+ B =+ C , ok expr \{

    $bencode.rel.reg rX,A
    $bencode.rel.reg rY,B
    $bencode.rel.imm off,C

    ok equ 1

  \}

  ; [(rX|off) << scale]
  match =0 A =* B , ok expr \{

    $bencode.rel.reg_or_imm rX,off,A
    $bencode.rel.scale      scale,B

    ok equ 1

  \}

  ; [rX + (rY|off)]
  match =0 A =+ B , ok expr \{

    $bencode.rel.reg        rX,A
    $bencode.rel.reg_or_imm rY,off,B

    ok equ 1

  \}

  ; [rX|off]
  match =0 A , ok expr \{
    $bencode.rel.reg_or_imm rX,off,A
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

    dst = A9M.OPCODE.MFLAG.rel \
    or (dst shl A9M.OPCODE.MFLAG._fmat_bs)

    bitsz = bipret.memarg.rel._fmat_bs \
    + A9M.OPCODE.MFLAG._fmat_bs

  \}

}

; ---   *   ---   *   ---
; value can be either of

macro $bencode.rel.reg_or_imm reg,imm,X {

  local dummy
  local ok
  ok equ 0

  $bencode.reg ok,reg,dummy,dummy,X

  if ok
    reg=(reg+1) and A9M.REGISTER_CNT_BM

  end if

  $bencode.imm ok,imm,dummy,dummy,X,\
    bipret.memarg.rel.off_bs

}

; ---   *   ---   *   ---
; value can only be

macro $bencode.rel.reg dst,X {

  local dummy
  local ok
  ok equ 0

  $bencode.reg ok,dst,dummy,dummy,X
  dst=(dst+1) and A9M.REGISTER_CNT_BM

}

macro $bencode.rel.imm dst,X {

  local dummy
  local ok
  ok equ 0

  $bencode.imm ok,dst,dummy,dummy,X,\
    bipret.memarg.rel.off_bs

}

macro $bencode.rel.scale dst,X {

  dst = (bsf X) \
    and bipret.memarg.rel.scale_bm

}

; ---   *   ---   *   ---
