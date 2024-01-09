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
; info

  TITLE     A9M.L1

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM I

if ~ defined A9M.L1.TOKEN_SZ
  define A9M.L1.TOKEN_SZ $40

end if

; ---   *   ---   *   ---
; GBL I

  define   A9M.L1.mem
  vmem.new A9M.L1.mem,blk A9M.L1.TOKEN_SZ

; ---   *   ---   *   ---
; decl/set default GBL

macro A9M.L1.reset {
  vmem.clear  A9M.L1.mem

}

; ---   *   ---   *   ---
; base struc

vreg.new A9M.L1.head
  szmy byte nest.parens
  szmy byte nest.brak
  szmy byte nest.curly
  szmy byte token.len

vreg.end
sizeof.A9M.L1.head=$04

; ---   *   ---   *   ---
; reserve space for ctx at
; beg of L1 buffer

define          A9M.L1.ctx
A9M.L1.head.new A9M.L1.ctx

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

      ; 1-bit brak
      $mov br,A9M.L0.nest_brak
      $shl br,$04
      $or  ar,br

      ; 5-bit parens
      $mov br,A9M.L0.nest_parens
      $shl br,$05
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

    ; 1-bit brak
    $mov cr,ar
    $and cr,$01
    $shr ar,$01

    ; 5-bit parens
    $mov br,ar
    $and br,$1F
    $shr ar,$05

    ; ^get token len
    $mov er,ar
    $and er,$3F

    ; ^save to ctx
    $mov %[A9M.L1.ctx nest.curly],dr
    $mov %[A9M.L1.ctx nest.brak],cr
    $mov %[A9M.L1.ctx nest.parens],br
    $mov %[A9M.L1.ctx token.len],er


    ; get token
    vmem.cat    A9M.L1.mem,A9M.L2.mem,1
    vmem.rewind A9M.L1.mem

  \}

}

; ---   *   ---   *   ---
