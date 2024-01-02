; ---   *   ---   *   ---
; A9M
; The [AR]cane-[9I]ne [MA]chine,
; or [ANIMA],
; and sometimes [A9MA]
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
  use '.inc' A9M::vmem

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  IO.CTAGIT A9MTAG,'35;1','A9M'

  A9M.debug = 1

  A9M.scap  = 0
  A9M.join  = 0
  A9M.term  = 0
  A9M.delim = 0

  A9M.nest_curly  = 0
  A9M.nest_parens = 0
  A9M.nest_brak   = 0

  define A9M.ctoken
  vmem.new A9M.ctoken,$40

; ---   *   ---   *   ---
; terminate current token

macro A9M.ctoken.end {

  match id , A9M.ctoken \{

    if id\#.ptr

      display $0A,$0A,'A9M.ctoken END',$0A
      vmem.prich A9M.ctoken

      ; [INSERT STRCMP]
      vmem.clear A9M.ctoken

    end if

  \}

}

; ---   *   ---   *   ---
; conditional maker

macro A9M.make_pat dst,[item] {

  common
    define A9M.pat.#dst

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
    borcat A9M.pat.#dst,(A9M.CHAR=s)

}

; ---   *   ---   *   ---
; ^similar, used for delimiters

macro A9M.make_delim name,dbeg,dend {

  A9M.delim.#name#_beg=dbeg
  A9M.delim.#name#_end=dend

  A9M.make_pat name,lit dbeg,lit dend

}

; ---   *   ---   *   ---
; ^makes conditions with
; expanded symbols

macro A9M.make_chk name,[item] {

  common
    define A9M.chk.#name

  forward match any , item \{
    spacecat A9M.chk.#name,any

  \}

}

; ---   *   ---   *   ---
; ROM

  A9M.make_pat join_op,++,+,lit $2C
  A9M.make_pat ws,lit $20,lit $0A
  A9M.make_pat term,lit $3B
  A9M.make_pat scap,lit $5C

  A9M.make_delim curly,$7B,$7D


  A9M.make_chk ws,\
    (A9M.join|A9M.term|A9M.delim)

  A9M.make_chk term,\
    (A9M.pat.term) &~ A9M.scap

  define A9M.fulnest \
    A9M.nest_curly \
  + A9M.nest_brak  \
  + A9M.nest_parens


; ---   *   ---   *   ---
; reset default clan state

macro A9M.reset {

  A9M.scap  = 0
  A9M.join  = 0
  A9M.term  = 0
  A9M.delim = 0

  A9M.nest_curly  = 0
  A9M.nest_parens = 0
  A9M.nest_brak   = 0

  vmem.clear A9M.ctoken

}

; ---   *   ---   *   ---
; read into virtual
;
; TODO:
;
; * read pehead
;
; * read pescap
;
; * strip comments
;
; * string scap

macro A9M.rd {

  ; setup
  A9M.reset

  ; read file into vmem
  virtual at $00

    A9M.fbeg:
    A9M.fbase::
      file A9M.FPATH

    A9M.flen=$-A9M.fbeg

  end virtual

  ; ^dbout
  if A9M.debug

    out@EX $0A,A9MTAG,\
      ' ',~IO.FILEIT A9M.FPATH,IO.comma

    hexsay A9M.flen,32

    display ' bytes',$0A,$0A

  end if


  ; ^decl out blk
  virtual at $00 as 'p3'
    A9M.fout::

  end virtual


  ; ^proc input
  repeat A9M.flen

    ; get next byte
    load A9M.CHAR byte from A9M.fbase:%-1

    ; pass
    if A9M.pat.ws
      A9M.logic.ws


    ; term
    else if A9M.chk.term
      A9M.logic.term

    ; ^scap next
    else if A9M.pat.scap
      A9M.logic.scap

    ; ^nterm
    else
      A9M.logic.nterm

    end if


  end repeat

}

; ---   *   ---   *   ---
; proc whitespace

macro A9M.logic.ws {

  A9M.ctoken.end
  A9M.scap=0

  if ~ A9M.chk.ws
    A9M.wt $0A
    A9M.wt.nest_branch

  end if

}

; ---   *   ---   *   ---
; proc terminator

macro A9M.logic.term {
  A9M.term=1
  A9M.wt $0A,$0A

  A9M.ctoken.end

}

; ---   *   ---   *   ---
; proc escape char

macro A9M.logic.scap {
  A9M.scap=1

}

; ---   *   ---   *   ---
; proc any non-term char

macro A9M.logic.nterm {

  ; joined to prev token?
  if A9M.pat.join_op
    A9M.join=1

  ; ^else sep on next ws
  else
    A9M.join=0

  end if


  ; have delim?
  if A9M.pat.curly
    A9M.ctoken.end
    A9M.logic.nesting curly

  ; ^nope, common char
  else

    ; was last char a delim?
    ; are we now at ident lvl 0?
    if A9M.delim &~ A9M.fulnest
      A9M.wt.branch

    end if

    ; cat to current token
    vmem.write A9M.ctoken,A9M.CHAR

    ; ^cat char to fout
    A9M.wt A9M.CHAR

    ; ^mark last as nterm
    A9M.delim = 0
    A9M.term  = 0


  end if

  ; turn off escape flag
  A9M.scap=0

}

; ---   *   ---   *   ---
; proc nesting delimiter

macro A9M.logic.nesting name {

  A9M.delim=1

  d0=A9M.delim.#name#_beg
  d1=A9M.delim.#name#_end


  ; open delim, nest++
  if (A9M.CHAR=d0)

    A9M.nest_#name = A9M.nest_#name+1

    A9M.wt d0,$0A
    A9M.wt.nest_pad
    A9M.wt.branch


  ; ^close, nest--
  else

    A9M.nest_#name = A9M.nest_#name-1

    A9M.wt $0A
    A9M.wt.nest_pad
    A9M.wt '.'

    A9M.wt $0A
    A9M.wt.nest_pad

    A9M.wt.branch d1,$0A
    A9M.wt.nest_pad

  end if

}

; ---   *   ---   *   ---
; ^write to fout

macro A9M.wt ct& {

  ; cat to file
  virtual A9M.fout
    db ct

  end virtual

  ; ^optionally cout ;>
  if A9M.debug
    display ct

  end if

}

; ---   *   ---   *   ---
; ^outs ident lvl

macro A9M.wt.nest_pad {

  repeat A9M.fulnest
    A9M.wt '.  '

  end repeat

}

; ---   *   ---   *   ---
; ^outs branch beg

macro A9M.wt.branch ct& {

  match any , ct \{
    A9M.wt '\-->',ct

  \}

  match , ct \{
    A9M.wt '\-->'

  \}

}

; ---   *   ---   *   ---
; ^combo

macro A9M.wt.nest_branch ct& {
  A9M.wt.nest_pad
  A9M.wt.branch ct

}

; ---   *   ---   *   ---
