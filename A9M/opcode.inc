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

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; mask generator

macro MASKOF name,bits {

  SIZE.#name = bits
  MASK.#name = (1 shl bits) - 1

}

; ---   *   ---   *   ---
; ROM

  ; opcode chunk bit-sizes
  MASKOF OPSZ , $02
  MASKOF RATX , $01
  MASKOF SEG  , $02

  ; segment types
  SEG.ANIMA  = $00
  SEG.STACK  = $01
  SEG.ICEREL = $02
  SEG.NONREL = $03

; ---   *   ---   *   ---
; GBL

@ipret:

  .opcd       = $00
  .opid       = $00
  .opsz       = $00
  .opsz.mask  = $00
  .opsz.bits  = $00

  .ratcnt     = $00
  .ratmask    = $00

  .vX         = $00
  .vY         = $00

  .seg        = $00
  .seg.scale  = $00
  .seg.bitsz  = $00

  .mm         = $00
  .mX         = $00
  .mY         = $00

; ---   *   ---   *   ---
; reads segment address

macro @ipret$getseg dst,name {

  match id , name \{
    dst = id\#.beg

  \}

}

; ---   *   ---   *   ---
; reads operand

macro @ipret$getrat dst,mode,cnt {

  ; memory location
  if mode = 0

    ; fetch modifiers
    @ipret.seg.bitsz = 0
    @ipret.seg.scale = 1

    ; consume segment bits
    $mash @ipret.seg,@ipret.opcd,SEG


    ; ^reading register
    if @ipret.seg = SEG.ANIMA

      @ipret.seg.bitsz = $04
      @ipret.seg.scale = $08

      @ipret$getseg @ipret.seg,vmc.ANIMA


    ; ^reading stack or instance
    else if (@ipret.seg = SEG.STACK) \
    | (@ipret.seg = SEG.ICEREL)

      @ipret.seg.bitsz = $08

      ; get begof stack
      if @ipret.seg = SEG.STACK
        @ipret$getseg @ipret.seg,vmc.STACK

        @ipret.seg = @ipret.seg + A9M.STACK_SZ
        @ipret.seg.scale = -1


      ; ^get addrof ice
      else

        vmem.xldus @ipret.seg,
          \vmc.ANIMA,$0C,2

      end if


    ; ^reading from parent block
    else if @ipret.seg = SEG.NONREL
      @ipret.seg.bitsz = $10

    end if


    ; get encoded value
    dst = @ipret.opcd \
    and ((1 shl @ipret.seg.bitsz)-1)

    @ipret.opcd = @ipret.opcd \
    shr @ipret.seg.bitsz

    dst = @ipret.seg \
    + (dst * @ipret.seg.scale)


    ; fetch src
    if cnt = 1

      vmem.xldus dst,\
        vmc.NON,dst,@ipret.opsz

    end if


  ; ^immediate
  else
    dst = @ipret.opcd and ((1 shl $20)-1)
    @ipret.opcd = @ipret.opcd shr $20

  end if

}

; ---   *   ---   *   ---
; mask and shift!

macro $mash dst,src,name {
  dst = src and MASK.#name
  src = src shr SIZE.#name

}

; ---   *   ---   *   ---
; N-bits all set to one

macro $bones dst,src {
  dst = 1 shl (src and $3F)
  dst = dst or (sizebm.qword * (src shr 6))

}

; ---   *   ---   *   ---
; read opcode

macro $ipret X {

  ; copy input
  @ipret.opcd = X

  ; consume opid bits
  $mash @ipret.opid,@ipret.opcd,OPID

  ; read op size needed from ROM
  @ipret$get_opsz

  if @ipret.opsz = 1

    $mash  @ipret.opsz,@ipret.opcd,OPSZ

    @ipret.opsz = 1 shl @ipret.opsz
    @ipret.opsz.bits = 1 shl 3

    $bones @ipret.opsz.mask,@ipret.opsz

  end if


  ; read operands needed from ROM
  @ipret$get_ratcnt

  ; ^consume operand bits if any
  if @ipret.ratcnt > 0

    ; read operand mode bits
    @ipret.mm   = @ipret.opcd and @ipret.ratmask
    @ipret.opcd = @ipret.opcd shl @ipret.ratcnt

    ; get mode/value of first operand
    $mash @ipret.mX,@ipret.mm,RATX
    @ipret$getrat @ipret.rX,@ipret.mX,0

    ; ^second
    if @ipret.ratcnt > 1
      $mash @ipret.mY,@ipret.mm,RATX
      @ipret$getrat @ipret.rY,@ipret.mY,1

    end if

  end if


  ; perform write
  vmem.xstus vmc.NON,\
    @ipret.rY,@ipret.rX,@ipret.opsz

}

;; ---   *   ---   *   ---
;
;000 => r,r
;010 => r,m
;001 => m,r
;
;100 => r,i
;101 => m,i
;
;110 => r,lea
;011 => lea,r
;111 => lea,i

mov qword [heap:$40],r
mov qword [stack:sb-8]

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

macro @ipret$read_reg dst,src {
  dst = (src and 7) * 8
  src = src shr 3

}

; ---   *   ---   *   ---
; read immediate operand
;
; simply refers to opsz
; to determine how many
; bits to read, capping
; at 32

macro @ipret$read_imm dst,src {

  ; halves read size when
  ; opsz is 64
  local cap
  cap = @ipret.opsz shr 6

  ; read and shift out
  dst = src & (@ipret.opsz.mask shr cap)
  src = src shr (@ipret.opsz.bits shr cap)

}

; ---   *   ---   *   ---
; mflag:GBL

virtual at $00
@ipret.read_mem.tab::

  ; sb register
  dq $00

  ; beg of heap
  dq sizeof.vmc+$38

  ; ice register
  dq $00

  ; also beg of heap
  ; repeated to avoid an if
  dq sizeof.vmc+$38


  ; used for branchless fetch
  .sb   = $00
  .ice  = $00

  ; used to offset result
  .base = $00


end virtual

; ---   *   ---   *   ---
; read common memory operand
;
;
; here we map the flag to
; read size like so:
;
; * 00 => stack-rel :$08
; * 10 => ice-rel   :$08
;
; * 01 => heap-rel  :$10
; * 11 => heap-rel  :$20
;
;
; the addr is then read
; and casted to absolute

macro @ipret$read_mem dst,src {

  ; copy the segment flags
  local mflag
  mflag = src and 3

  ; then shift them out
  src = src shr 2


  ; double size if first bit set
  dst = 8 shl (mflag and 1)

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
  load @ipret.read_mem.tab.base qword \
  from @ipret.read_mem.tab:mflag*8


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
  mflag = not mflag and 3
  dst   = dst * (1 - (2 * (mflag * $AB) shr 9))


  ; add base and offset to get absolute
  dst = @ipret.read_mem.tab.base+dst

  ; shift out the already read values
  src = src shr bits

}

; ---   *   ---   *   ---
; inconditional reload of ice
; and sb into the read_mem table
;
; this makes it so we can read
; addresses that are relative to
; these pointers without an if

macro @ipret$read_mem$reload {

  load @ipret.read_mem.tab.sb qword \
  from ANIMA.base:$58

  load @ipret.read_mem.tab.ice qword \
  from ANIMA.base:$60

  store qword @ipret.read_mem.tab.sb \
  at @ipret.read_mem.tab:$00

  store qword @ipret.read_mem.tab.ice \
  at @ipret.read_mem.tab:$10

}

;; ---   *   ---   *   ---
;; makes binary opcode
;
;macro $encode NE {
;
;X tokin ok,val,vmc.REGISTERS
;
;size =ptr reg/imm
;size =[ subexpr =]
;
;
;
;reg/imm+reg/imm+reg/imm*[0,2,4,8]
;
;$encode mov ar,qword [blala]
;
;  local _name
;  local _expr
;
;  _name equ NE
;  _expr equ
;
;
;  ; got expression?
;  match N E , NE \{
;    _name equ N
;    _expr equ E
;
;  \}
;
;  ; ^yes
;  match name expr , _name _expr \{
;    
;
;  \}
;
;}
;
;; ---   *   ---   *   ---
;; rd subexpr
;
;macro $encode.subexpr expr {
;
;
;  local ok
;  ok equ 0
;
;+ - * / -> 8
;A B C D -> 32
;
;  ; four values, three operations
;  match A opa B opb C opc D , expr \{
;
;    ok equ 1
;
;  \}
;
;  ; three values, two operations
;  match =0 A opa B opb C , ok expr \{
;
;    ok equ 1
;
;  \}
;
;  ; two values, one operation
;  match =0 A opa B , ok expr \{
;
;    ok equ 1
;
;  \}
;
;  ; single value
;  match =0 A , ok expr \{
;
;    ok equ 1
;
;  \}
;
;}
;
;; ---   *   ---   *   ---
;
;macro $encode.subexpr.read_op bits,value,op {
;
;  match =* , op \{
;    bits = bits shl 2
;    bits = bits or ((bsf value) and $03)
;
;  \}
;
;  match =- , op \{
;    bits = bits shl 1
;    bits = bits or 1
;
;  \}
;
;  match =+ , op \{
;    bits = bits shl 1
;
;  \}
;
;}

; ---   *   ---   *   ---
; Arcane 9 mov $24 to sb-1
; but in binary!
;
;            STACK
;            +------>:   /-->operand modes
;            |           |
;     .......^.......|.|.||
;            [           [
;$ipret 001001000000000101101b
;            ]        -]
;     .......v         v
;            |         |
;     <------+         \-->segment
;     IMM32

;STACK.bprich

; ---   *   ---   *   ---
