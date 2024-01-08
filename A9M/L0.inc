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

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; decl/set default GBL

macro A9M.L0.reset {

  ; tmp storage
  A9M.L0.mem = 0

  ; rd switches
  A9M.L0.scap  = 0
  A9M.L0.join  = 0
  A9M.L0.term  = 0
  A9M.L0.delim = 0

  ; rd nesting counters
  A9M.L0.nest_curly  = 0
  A9M.L0.nest_parens = 0
  A9M.L0.nest_brak   = 0

}

;A9M.L0.reset

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
  A9M.L0.make_pat join_op,++,+,lit $2C
  A9M.L0.make_pat ws,lit $20,lit $0A
  A9M.L0.make_pat term,lit $3B
  A9M.L0.make_pat scap,lit $5C

  ; ^two-char checks, kind of
  A9M.L0.make_delim curly,$7B,$7D
  A9M.L0.make_delim brak,$5B,$5D
  A9M.L0.make_delim parens,$28,$29

  ; ^expanded conditionals
  A9M.make_chk L0,ws,\
    (A9M.L0.join|A9M.L0.term|A9M.L0.delim)

  A9M.make_chk L0,term,\
    (A9M.L0.pat.term) &~ A9M.L0.scap

  A9M.make_chk L0,usrchr,\
    ((A9M.L0.mem > $2F) & (A9M.L0.mem < $3A)) \
  | ((A9M.L0.mem > $40) & (A9M.L0.mem < $5B)) \
  | ((A9M.L0.mem > $60) & (A9M.L0.mem < $7B)) \
  | ((A9M.L0.mem = $5F))

  ; ^sumof all accums
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
; consume and proc next
; input chunk

macro A9M.L0.chrin {

  match step , A9M.L0.CHAR_SZ \{

    vmem.load A9M.L0.mem,\
      A9M.FSRC,step

    A9M.L0.procin

  \}

}

; ---   *   ---   *   ---
; ^defproc

macro A9M.L0.procin {

  ; pass
  if A9M.L0.pat.ws
    A9M.L0.logic.ws

  ; term
  else if A9M.L0.chk.term
    A9M.L0.logic.term

  ; ^scap next
  else if A9M.L0.pat.scap
    A9M.L0.logic.scap

  ; ^nterm
  else
    A9M.L0.logic.nterm

  end if

}

; ---   *   ---   *   ---
; ^crux

macro A9M.L0.orc {

  match id step , A9M.FSRC A9M.L0.CHAR_SZ \{

    repeat id\#.len shr sizep2.\#step
      A9M.L0.chrin

    end repeat

  \}

}

; ---   *   ---   *   ---
; whitespace defproc

macro A9M.L0.logic.ws {

  match id , A9M.L0.mem \{

    if (id\#.ptr) &~ A9M.L0.chk.ws
      A9M.write $0A
      A9M.write.nest_branch

    end if

  \}

  A9M.L1.store
  A9M.L0.scap=0

}

; ---   *   ---   *   ---
; terminator defproc

macro A9M.L0.logic.term {

  A9M.L0.term=1
  A9M.write $0A,$0A

  A9M.L1.store

}

; ---   *   ---   *   ---
; escape char defproc

macro A9M.L0.logic.scap {
  A9M.L0.scap=1

}

; ---   *   ---   *   ---
; non-term char defproc

macro A9M.L0.logic.nterm {

  ; joined to prev token?
  if A9M.L0.pat.join_op
    A9M.L0.join=1

  ; ^else sep on next ws
  else
    A9M.L0.join=0

  end if


  ; have delim?
  if A9M.L0.pat.curly
    A9M.L1.term
    A9M.L0.logic.nesting curly

  ; ^nope, common char
  else

    ; was last char a delim?
    ; are we now at ident lvl 0?
    if A9M.L0.delim &~ A9M.L0.fulnest
      A9M.write.branch

    end if

    ; save char to L1
    A9M.L0.store

    ; ^cat char to fout
    A9M.write A9M.L0.mem

    ; ^mark last as nterm
    A9M.L0.delim = 0
    A9M.L0.term  = 0


  end if

  ; turn off escape flag
  A9M.L0.scap=0

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

    A9M.write d0,$0A
    A9M.write.nest_pad
    A9M.write.branch


  ; ^close, nest--
  else

    A9M.L0.nest_#name = A9M.L0.nest_#name-1

    A9M.write $0A
    A9M.write.nest_pad
    A9M.write '.'

    A9M.write $0A
    A9M.write.nest_pad

    A9M.write.branch d1,$0A
    A9M.write.nest_pad

  end if

}

; ---   *   ---   *   ---
