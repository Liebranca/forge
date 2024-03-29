; ---   *   ---   *   ---
; A9M L0
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

  TITLE     A9M.L0

  VERSION   v0.00.4b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; decl/set default GBL

macro A9M.L0.reset {

  ; tmp storage
  A9M.L0.mem   = 0

  ; rd switches
  A9M.L0.scap    = 0
  A9M.L0.join_op = 0
  A9M.L0.delim   = 0

  ; rd propagation switches
  A9M.L0.token_term = 0
  A9M.L0.expr_term  = 0

  ; rd nesting counters
  A9M.L0.nest_curly  = 0
  A9M.L0.nest_parens = 0
  A9M.L0.nest_brak   = 0

  ; ^rd ahead/tail
  A9M.L0.reset_visions

}

; ---   *   ---   *   ---
; ^subset A

macro A9M.L0.reset_visions {

  A9M.L0.ahead     = 0
  A9M.L0.ahead_mul = 1

  A9M.L0.tail      = 0
  A9M.L0.tail_mul  = 1

}

A9M.L0.reset

; ---   *   ---   *   ---
; conditional maker

macro A9M.L0.make_pat dst,[item] {

  common
    define A9M.L0.pat.#dst

  forward

    local s
    local ok

    ok equ 0


    ; skip stirr?
    match =lit b , item \{
      s  equ b
      ok equ 1

    \}

    ; ^nope, go ahead ;>
    match =0 , ok \{
      stirr9 s,item,$04

    \}


    ; make (*c==a) | (*c==b) ...
    borcat A9M.L0.pat.#dst,(A9M.L0.mem=s)

}

; ---   *   ---   *   ---
; ^similar, used for delimiters

macro A9M.L0.make_delim name,dbeg,dend {

  A9M.L0.delim.#name#_beg=dbeg
  A9M.L0.delim.#name#_end=dend

  A9M.L0.make_pat name,lit dbeg,lit dend

}

; ---   *   ---   *   ---
; ROM

if ~ defined A9M.L0.CHAR_SZ
  define A9M.L0.CHAR_SZ byte

end if

  ; one-char checks
  A9M.L0.make_pat ws,lit $20,lit $0A
  A9M.L0.make_pat expr_term,lit $3B
  A9M.L0.make_pat scap,lit $5C

  ; ^two-char checks, kind of
  A9M.L0.make_delim curly,$7B,$7D
  A9M.L0.make_delim brak,$5B,$5D
  A9M.L0.make_delim parens,$28,$29

  ; ^expanded conditionals
  A9M.make_chk L0,ws,\
    (A9M.L0.join_op|A9M.L0.expr_term|A9M.L0.delim)

  A9M.make_chk L0,expr_term,\
    (A9M.L0.pat.expr_term) &~ A9M.L0.scap

  ; operators
  A9M.make_chk L0,oprat,\
    ((A9M.L0.mem > $29) & (A9M.L0.mem < $30)) \
  | ((A9M.L0.mem > $3B) & (A9M.L0.mem < $40)) \
  | ((A9M.L0.mem = $21) | (A9M.L0.mem = $5E)) \
  | ((A9M.L0.mem = $7C) | (A9M.L0.mem = $7E)) \
  | ((A9M.L0.mem = $25) | (A9M.L0.mem = $25))

  ; valid names ;>
  A9M.make_chk L0,usrchr,\
    ((A9M.L0.mem > $2F) & (A9M.L0.mem < $3A)) \
  | ((A9M.L0.mem > $40) & (A9M.L0.mem < $5B)) \
  | ((A9M.L0.mem > $60) & (A9M.L0.mem < $7B)) \
  | ((A9M.L0.mem = $5F))


  ; sumof accums
  define A9M.L0.fulnest \
    A9M.L0.nest_curly \
  + A9M.L0.nest_brak  \
  + A9M.L0.nest_parens

; ---   *   ---   *   ---
; save char to token

macro A9M.L0.store {

  match step , A9M.L0.CHAR_SZ \{

    vmem.store A9M.L1.mem,\
      A9M.L0.mem,step

  \}

  ; ^cat char to fout
  A9M.dbout A9M.L0.mem

}

; ---   *   ---   *   ---
; ^retrieve

macro A9M.L0.load {

  match step , A9M.L0.CHAR_SZ \{

    vmem.load A9M.L0.mem,\
      A9M.L1.mem,step

  \}

}

; ---   *   ---   *   ---
; consume next input chunk

macro A9M.L0._chrin {

  match step , A9M.L0.CHAR_SZ \{

    vmem.load A9M.L0.mem,\
      A9M.FSRC,step

  \}

}

; ---   *   ---   *   ---
; ^consume++

macro A9M.L0.chrin {

  A9M.L0.get_ahead
  A9M.L0.get_tail

  A9M.L0._chrin

}

; ---   *   ---   *   ---
; ^get byte some N positions
; forward or backward

macro A9M.L0.nchrin dst,off {

  match id step , A9M.FSRC A9M.L0.CHAR_SZ \{

    local addr
    addr = id\#.ptr+(off)

    ; null if OOB
    if addr > id\#.size | addr < $00
      dst = $00

    ; ^else read
    else
      vmem.get dst,A9M.FSRC,addr,step

    end if

  \}

}

; ---   *   ---   *   ---
; ^icebox

macro A9M.L0.get_ahead {
  A9M.L0.nchrin A9M.L0.ahead,\
    1*A9M.L0.ahead_mul

  A9M.L0.ahead_mul=A9M.L0.ahead_mul+1

}

macro A9M.L0.get_tail {
  A9M.L0.nchrin A9M.L0.tail,\
    -1*A9M.L0.tail_mul

  A9M.L0.tail_mul=A9M.L0.tail_mul+1

}

; ---   *   ---   *   ---
; char-reading rules

macro A9M.L0.procin {

  ; pass
  if A9M.L0.pat.ws
    A9M.L0.logic.ws

  ; term
  else if A9M.L0.chk.expr_term
    A9M.L0.logic.expr_term

  ; ^scap next
  else if A9M.L0.pat.scap
    A9M.L0.logic.scap

  ; ^operator
  else if A9M.L0.chk.oprat
    A9M.L0.logic.oprat

  ; ^nterm
  else
    A9M.L0.logic.nterm

  end if

}

; ---   *   ---   *   ---
; should we ping the upper
; memory levels?

macro A9M.L0.propagate {

  if A9M.L0.token_term=1
    A9M.L1.store

  end if

  if A9M.L0.expr_term=1
    A9M.L2.proc_expr

  end if

}

; ---   *   ---   *   ---
; crux

macro A9M.L0.orc {

  ; read/run first expression
  A9M.FE.read

  ; ^read the rest of the file
  match id step , A9M.FSRC A9M.L0.CHAR_SZ \{

    repeat id\#.len shr sizep2.\#step

      A9M.L0.chrin
      A9M.L0.procin

      A9M.L0.propagate

      A9M.L0.reset_visions

    end repeat

  \}

}

; ---   *   ---   *   ---
; whitespace defproc

macro A9M.L0.logic.ws {

  match token , A9M.L1.mem \{

    if (token\#.ptr) &~ A9M.L0.chk.ws
      A9M.dbout $0A
      A9M.dbout.nest_branch

      A9M.L0.token_term

    end if

  \}

  A9M.L0.scap=0

}

; ---   *   ---   *   ---
; terminator defproc

macro A9M.L0.logic.expr_term {
  A9M.L0.token_term = 1
  A9M.L0.expr_term  = 1

}

; ---   *   ---   *   ---
; escape char defproc

macro A9M.L0.logic.scap {
  A9M.L0.scap=1

}

; ---   *   ---   *   ---
; consume operators

macro A9M.L0.logic.oprat {

  A9M.L1.store

  while 1

    if ~(A9M.L0.chk.oprat)
      break

    else

      A9M.L0.store
;      A9M.dbout '?>>',A9M.L0.mem,A9M.L0.ahead,$0A

      $swap A9M.L0.mem,A9M.L0.ahead

      if A9M.L0.chk.oprat
        A9M.L0.reset_visions
        A9M.L0.chrin

      else
        $swap A9M.L0.ahead,A9M.L0.mem
        break

      end if

    end if

  end while

  A9M.L1.store
  A9M.L0.token_term = 0
  A9M.L0.join_op    = 1

}

; ---   *   ---   *   ---
; non-term char defproc

macro A9M.L0.logic.nterm {

  ; have delim?
  if A9M.L0.pat.curly
    A9M.L0.store
    A9M.L0.logic.nesting curly

  ; ^nope, common char
  else

    ; was last char a delim?
    ; are we now at ident lvl 0?
    if A9M.L0.delim &~ A9M.L0.fulnest
      A9M.dbout.branch

    end if

    ; save char to L1
    A9M.L0.store

    ; ^mark last as nterm
    A9M.L0.delim     = 0
    A9M.L0.expr_term = 0


  end if

  ; turn off escape flag
  A9M.L0.scap    = 0
  A9M.L0.join_op = 0

}

; ---   *   ---   *   ---
; proc nesting delimiter

macro A9M.L0.logic.nesting name {

  A9M.L0.delim=1

  local d0
  local d1

  d0 equ A9M.L0.nesting.d0
  d1 equ A9M.L0.nesting.d1

  d0=A9M.L0.delim.#name#_beg
  d1=A9M.L0.delim.#name#_end


  ; open delim, nest++
  if (A9M.L0.mem=d0)

    A9M.L0.nest_#name = A9M.L0.nest_#name+1

    A9M.dbout d0,$0A
    A9M.dbout.nest_pad
    A9M.dbout.branch


  ; ^close, nest--
  else

    A9M.L0.nest_#name = A9M.L0.nest_#name-1

    A9M.dbout $0A
    A9M.dbout.nest_pad
    A9M.dbout '.'

    A9M.dbout $0A
    A9M.dbout.nest_pad

    A9M.dbout.branch d1,$0A
    A9M.dbout.nest_pad

  end if

}

; ---   *   ---   *   ---
