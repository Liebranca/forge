; ---   *   ---   *   ---
; A9M L1
; J-sized array of
; I-sized chunks
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.inc' A9M::SHARE::L1

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.L1

  VERSION   v0.00.6b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; cstruc for generic tokens

vreg.new A9M.L1.id_t
  szmy word loc

vreg.end
sizeof.A9M.L1.id_t=$02

; ---   *   ---   *   ---
; GBL

  ; basemem
  define   A9M.L1.mem
  vmem.new A9M.L1.mem,blk A9M.L1.TOKEN_SZ


  ; generic element
  define          A9M.L1.idx
  A9M.L1.id_t.new A9M.L1.idx

  ; ^table of generics
  define    A9M.L1.idtab
  vhash.new A9M.L1.idtab,A9M.L1.id_t,\
    $04,A9M.L1.TOKEN_SZ

  ; table of keywords
  ; loaded on first token
  define A9M.L1.keywtab

  ; ^this is how we know
  A9M.L1.tokencnt     = 0
  A9M.L1.postcall_ptr = 0

; ---   *   ---   *   ---
; reserve len bytes in
; string buffer

match __strout , A9M.STROUT {
  A9M.STROUT.write $00,$00,$00,$00
  __strout#.ptr = $04

}

; ---   *   ---   *   ---
; decl/set default GBL

macro A9M.L1.reset {
  vmem.clear A9M.L1.mem
  A9M.postcall_ptr = $00

}

; ---   *   ---   *   ---
; save token to expr

macro A9M.L1.store {

  ; have chars to push?
  match token , A9M.L1.mem \{

    if token\#.ptr > 0

      ; load ipret on first token
      if A9M.L1.tokencnt = 0
        A9M.L1.postcall_ptr = $01

      ; ^else store serial
      else if A9M.L1.tokencnt > 0
        A9M.L1.postcall_ptr = $02

      end if

      ; up counter
      A9M.L1.tokencnt=A9M.L1.tokencnt+1

    else
      A9M.L1.postcall_ptr=$00

    end if

  \}

}

; ---   *   ---   *   ---
; retrieve serialized token from L2

macro A9M.L1.load {

  match token ctx , A9M.L1.mem A9M.L1.ctx \{

    ; load token head
    local meta
    meta = 0

    vmem.load   meta,A9M.L2.mem,dword
    vmem.bstore A9M.L1.mem,meta,dword


    ; ^back to ctx buff
    $mov ar,meta

    $cons %[ctx TRF],byte ar
    $cons %[ctx SID],byte ar
    $cons %[ctx  CP],byte ar
    $cons %[ctx  BL],byte ar

    ; is token a generic id?
    $combr br,byte %[ctx TRF],byte %[ctx SID]
    $on br = $F3FF

      ; read ptr
      local addr
      addr = 0

      vmem.load addr,A9M.L2.mem,word

      ; ^get strlen
      local len
      len = 0

      $mov len,%[ctx BL]
      $shr len,$02

      ; ^load string from buff
      local      sbuf
      A9M.STROUT sbuf,addr,len

      ; ^load to L1
      vmem.cat    A9M.L1.mem,sbuf
      vmem.rewind A9M.L1.mem

    end if

  \}

}

; ---   *   ---   *   ---
; selfex

macro A9M.L1.serialize {

  ; queue of output buffs
  local Q
  Q equ

  ; ^build queue
  A9M.L1.serial_state
  A9M.L1.serial_token Q

  ; ^pass to L2
  match list , Q \{
    A9M.L2.cat list

  \}

  ; cleanup
  A9M.L1.reset

}

; ---   *   ---   *   ---
; write relevant bits of
; current program state
; to serialized output

macro A9M.L1.serial_state {

  match token , A9M.L1.mem \{

    $xor ar,ar

    ; 4-bit curly
    $mov br,A9M.L0.nest_curly
    $or  ar,br

    ; 4-bit parens
    $mov br,A9M.L0.nest_parens
    $shl br,$04
    $or  ar,br

    $mov %[A9M.L1.ctx CP],ar


    ; 2-bit brak
    $mov br,A9M.L0.nest_brak
    $or  ar,br


    ; get token length
    $mov br,token\#.len
    $shl br,$02
    $or  ar,br

    $mov %[A9M.L1.ctx BL],ar

  \}

}

; ---   *   ---   *   ---
; ^get numrepr of string

macro A9M.L1.serial_token Q {

  ; add state to output queue
  match id , A9M.L1.ctx \{
    commacat Q,id\#%origin

  \}


  ; get the promised data
  match token , A9M.L1.mem \{

    ; is keyword?
    A9M.L1.find A9M.L1.keywtab,ptr token

    ; ^yes, get token class
    $on br = 1

      $mov %[A9M.L1.ctx TRF],ar
      $shr ar,$08
      $mov %[A9M.L1.ctx SID],ar


    ; ^nope, use generic class (ID)
    else

      $mov %[A9M.L1.ctx TRF],A9M.L1.ID_T
      $mov %[A9M.L1.ctx SID],$FF

      ; add string ptr to output queue
      match id , A9M.L1.idx \\{
        commacat Q,id\\#%origin

      \\}


      ; have we parsed this ID before?
      A9M.L1.find A9M.L1.idtab,ptr token

      ; ^get ptr to string buff if so
      $on br = 1
        $mov %[A9M.L1.idx loc],ar

      ; ^nope, add to string buff
      else
        A9M.L1.to_strout

      end if

    end if

  \}

}

; ---   *   ---   *   ---
; match token against vhash

macro A9M.L1.find tab,src {
  $mov ptr ice,ptr tab
  vhash.find % vmc.REG,src

}

; ---   *   ---   *   ---
; add token to string buffer

macro A9M.L1.to_strout {

  match token strout , A9M.L1.mem A9M.STROUT \{

    ; get current pos
    local top
    top = strout\#.ptr

    ; ^save to hash
    $mov ptr ice,ptr A9M.L1.idtab
    $mov %[A9M.L1.idx loc],top

    vhash.store ptr token,% A9M.L1.idx

    ; ^add new string at pos
    A9M.STROUT.cat token

  \}

}

; ---   *   ---   *   ---
; first thing in an arcane file!

macro A9M.L1.load_ipret {

  ; get token

  local name
  local sigil

  name  = 0
  sigil = 0


  ; walk chars of token
  match token step , A9M.L1.mem A9M.L0.CHAR_SZ \{

    repeat token\#.len shr sizep2.\#step

      A9M.L0.load

      ; char is name of ipret
      if A9M.L0.chk.usrchr
        name=name+1

      ; errchk
      else if (% > 1) & (name > 0)
        out@err 'peso standard forbids ' \
          #'sigils on ipret name'

      ; ^sigil gives ipret mode
      else
        sigil=sigil+1

      end if

    end repeat

  \}


  ; get base ipret
  if name = 0
    vhash.from_disk A9M.L1.keywtab,A9M.L1.DEFTAB

  ; we should get the ipret here,
  ; but we don't yet have an ipret table!
  else
    vmem.seek A9M.L1.mem,sigil

  end if

  ; cleanup
  A9M.L1.reset

}

; ---   *   ---   *   ---
; invoked at end of file read

macro A9M.L1.foot {

  match strout , A9M.STROUT \{

    local pos
    pos = strout\#.size - 4

    if pos > 0
      A9M.STROUT.set dword pos at $00

    else
      strout\#.size=0

    end if

  \}

}

; ---   *   ---   *   ---
; takes this bit out of
; another conditional

macro A9M.L1.postcall {

  if A9M.L1.postcall_ptr = $01
    A9M.L1.load_ipret
    A9M.L1.postcall_ptr=$02

  else if A9M.L1.postcall_ptr = $02
    A9M.L1.serialize
    A9M.L1.postcall_ptr = $00

  end if

}

; ---   *   ---   *   ---
