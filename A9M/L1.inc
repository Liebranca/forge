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

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM I

if ~ defined A9M.TOKEN_SZ
  define A9M.TOKEN_SZ $40

end if

; ---   *   ---   *   ---
; GBL I

  define   A9M.L1.mem
  vmem.new A9M.L1.mem,blk A9M.TOKEN_SZ

; ---   *   ---   *   ---
; decl/set default GBL

macro A9M.L1.reset {

  vmem.clear A9M.L1.mem

}

A9M.L1.reset

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
A9M.L1.head.new A9M.L1.ctx,A9M.cexpr at $00

vmem.advptr     A9M.cexpr,sizeof.A9M.L1.head

; ---   *   ---   *   ---
; common storage

define   A9M.L1.tmp
vmem.new A9M.L1.tmp,blk $40

; ---   *   ---   *   ---
; save token to expr

macro A9M.L1.store {

  ; have chars to push?
  if token\#.ptr

    match token expr , A9M.L1.mem A9M.L2.mem \{

      $xor ar,ar

      ; get [PBC] levels
      $mov br,A9M.L0.nest_parens
      $or  ar,br
      $shl ar,$05

      $mov br,A9M.L0.nest_brak
      $or  ar,br
      $shl ar,$01

      $mov br,A9M.L0.nest_curly
      $or  ar,br

      ; ^get token length
      $mov br,token\#.len
      $shl br,$0A
      $or  ar,br

      ; ^save to L2
      A9M.L2.cat
      vmem.clear A9M.L1.mem

    \}

  end if

}

; ---   *   ---   *   ---
; ^retrieve

macro A9M.L1.load off {

  match id , A9M.cexpr \{

    ; load meta
    $mov ar,word [id+sizeof.#A9M.L1.head+off]

    ; ^get [PBC] level
    $mov br,ar
    $and br,$1F
    $shr ar,$05

    $mov cr,ar
    $and cr,$01
    $shr ar,$01

    $mov dr,ar
    $and dr,$07
    $shr ar,$04

    ; ^get token len
    $mov er,ar
    $and er,$3F

    ; ^save to ctx
    $mov %[A9M.L1.ctx nest.parens],br
    $mov %[A9M.L1.ctx nest.brak],cr
    $mov %[A9M.L1.ctx nest.curly],dr
    $mov %[A9M.L1.ctx token.len],er

  \}

}

; ---   *   ---   *   ---
; first line of an arcane file!

macro A9M.L1.read_ipret_name {}

; ---   *   ---   *   ---
