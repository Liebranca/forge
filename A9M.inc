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
  use '.inc' A9M::vmc
  use '.inc' A9M::vcstring
  use '.inc' A9M::vhash

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M

  VERSION   v0.00.6b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

if ~ defined A9M.ROMPATH
  define A9M.ROMPATH "%ARPATH%/forge/A9M/ROM/"

end if

; ---   *   ---   *   ---
; GBL

  IO.CTAGIT A9MTAG,'35;1','A9M'

  ; ^name of interpreter
  define A9M.ipret

  ; for use by all ;>
  A9M.debug = 0

; ---   *   ---   *   ---
; makes conditions with
; expanded symbols

macro A9M.make_chk base,name,[item] {

  common
    define A9M.#base#.chk.#name

  forward match any , item \{
    spacecat A9M.#base#.chk.#name,any

  \}

}

; ---   *   ---   *   ---
; insert I/O code

library ARPATH '/forge/'
  use '.inc' A9M::SHARE::OUTBUF

library.import

; ---   *   ---   *   ---
; insert memory levels code

library ARPATH '/forge/'
  use '.inc' A9M::L0
  use '.inc' A9M::L1
  use '.inc' A9M::L2
  use '.inc' A9M::FE

library.import

; ---   *   ---   *   ---
; reset default clan state

macro A9M.reset {
  A9M.L0.reset
  A9M.L1.reset
  A9M.L2.reset

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

macro A9M.read fpath?= {


  ; fpath passed as arg?
  match any , fpath? \{
    define A9M.FPATH any

  \}

  ; ^ensure we *have* a file!
  match , A9M.FPATH \{

    display $0A,A9MTAG,\
      'missing read input'

    err

  \}


  ; setup
  A9M.reset

  ; read file into vmem
  vmem.orc A9M.FSRC,A9M.FPATH

  ; ^decl out file
  vmem.owc A9M.FDST,'p3',blk $00


  ; ^dbout
  if A9M.debug

    out@EX $0A,A9MTAG,\
      ~IO.FILEIT A9M.FPATH,IO.comma

    match id , A9M.FSRC \{
      hexsay id\#.len,32

    \}

    display ' bytes',$0A,$0A

  end if


  ; consume file and clear
  A9M.L0.orc
  A9M.FPATH equ

  ; invoke footer
  match buffers , A9M.$$ \{
    A9M.foot buffers

  \}

}

; ---   *   ---   *   ---
; exec at end of program
; generally used as a final
; write to out

macro A9M.foot [buff] {

  ; invoke module footers
  common

  ; perform final write
  forward match id , buff \{

    vmem.bstore A9M.FDST,id\#.size,dword
    vmem.align  A9M.FDST

    vmem.write  A9M.FDST,ptr buff
    vmem.align  A9M.FDST

  \}


  ; dbout
  common if A9M.debug

    display $0A,'__________________',$0A,$0A
    display 'fout:',$0A

    vmem.bprich A9M.FDST,1
    err

  end if

}

; ---   *   ---   *   ---
; debug out

macro A9M.dbout ct& {

  ; ^optionally cout ;>
  if A9M.debug
    display ct

  end if

}

; ---   *   ---   *   ---
; ^outs ident lvl

macro A9M.dbout.nest_pad {

  repeat A9M.L0.fulnest
    A9M.dbout '.  '

  end repeat

}

; ---   *   ---   *   ---
; ^outs branch beg

macro A9M.dbout.branch ct& {

  match any , ct \{
    A9M.dbout '\-->',ct

  \}

  match , ct \{
    A9M.dbout '\-->'

  \}

}

; ---   *   ---   *   ---
; ^combo

macro A9M.dbout.nest_branch ct& {
  A9M.dbout.nest_pad
  A9M.dbout.branch ct

}

; ---   *   ---   *   ---
