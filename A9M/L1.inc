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

  VERSION   v0.00.3b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define   A9M.L1.mem
  vmem.new A9M.L1.mem,blk A9M.L1.TOKEN_SZ

  define   A9M.L1.dict

; ---   *   ---   *   ---
; decl/set default GBL

macro A9M.L1.reset {
  vmem.clear  A9M.L1.mem

}

; ---   *   ---   *   ---
; save token to expr

macro A9M.L1.store {

  ; have chars to push?
  match token expr , A9M.L1.mem A9M.L2.mem \{

    if token\#.ptr > 0

      $xor ar,ar

      ; 4-bit curly
      $mov br,A9M.L0.nest_curly
      $or  ar,br

      ; 4-bit parens
      $mov br,A9M.L0.nest_parens
      $shl br,$04
      $or  ar,br

      ; 2-bit brak
      $mov br,A9M.L0.nest_brak
      $shl br,$08
      $or  ar,br


      ; get token length
      $mov br,token\#.len
      $shl br,$0A
      $or  ar,br

      ; ^save to L2
      A9M.L2.cat
      A9M.L1.reset

    end if

  \}

}

; ---   *   ---   *   ---
; ^retrieve

macro A9M.L1.load {

  match token expr , A9M.L1.mem A9M.L2.mem \{

    ; load token head
    local meta
    meta = 0

    vmem.load meta,A9M.L2.mem,word
    $mov ar,meta

    ; 4-bit curly
    $mov dr,ar
    $and dr,$0F
    $shr ar,$04

    ; 4-bit parens
    $mov br,ar
    $and br,$1F
    $shr ar,$04

    ; ^combine into ctx
    $shl br,$04
    $or  dr,br

    $mov %[A9M.L1.ctx CP],dr


    ; 2-bit brak
    $mov dr,ar
    $and dr,$03
    $shr ar,$02

    ; ^6-bit len
    $mov br,ar
    $and br,$3F

    local len
    $mov  len,br

    ; ^combine into ctx
    $shl br,$04
    $or  dr,br

    $mov %[A9M.L1.ctx BL],dr


    ; get token ptr from L2
    local     sbuf
    vmem.view sbuf,A9M.L2.mem,expr\#.ptr,len

    ; ^load to L1
    vmem.cat    A9M.L1.mem,sbuf
    vmem.lseek  A9M.L2.mem,len
    vmem.rewind A9M.L1.mem

  \}

}

; ---   *   ---   *   ---
