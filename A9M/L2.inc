; ---   *   ---   *   ---
; A9M L2
; K-sized tree of
; J-sized array of
; I-sized chunks!
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.L2

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL I

  define   A9M.L2.mem
  vmem.new A9M.L2.mem,blk A9M.L1.TOKEN_SZ

  A9M.L2.exprcnt = 0

; ---   *   ---   *   ---
; write token to expr

macro A9M.L2.cat {

  ; save meta
  $pass ptr A9M.L2.mem,ar,lit word
  $call vmem.store

  ; ^save token
  vmem.cat A9M.L2.mem,A9M.L1.mem

  ; is expr complete?
  if A9M.L0.term
    A9M.L2.proc_expr

  end if

}

; ---   *   ---   *   ---
; crux

macro A9M.L2.proc_expr {

  vmem.rewind A9M.L2.mem

  ; get ipret on first expr
  if A9M.L2.exprcnt=0
    A9M.L2.first_line

  ; ^nope, run ipret proc
  else

    match id , A9M.ipret \{
      A9M.L2.common_line

    \}

  end if

  A9M.L2.exprcnt=A9M.L2.exprcnt+1

}

; ---   *   ---   *   ---
; first line of an arcane file!

macro A9M.L2.first_line {

  A9M.L1.load

  match token step , A9M.L1.mem A9M.L0.CHAR_SZ \{

    repeat token\#.len shr sizep2.\#step

      A9M.L0.load

      if A9M.L0.chk.usrchr
        display 'USERC '

      else
        display 'SIGIL '

      end if

      hexsay A9M.L0.mem,$08
      out@nl

    end repeat

    err

  \}

}

; ---   *   ---   *   ---
