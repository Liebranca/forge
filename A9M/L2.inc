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

  VERSION   v0.00.5b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL I

  define   A9M.L2.mem
  vmem.new A9M.L2.mem,blk A9M.L1.TOKEN_SZ

  A9M.L2.exprcnt = 0

; ---   *   ---   *   ---
; ~

macro A9M.L2.reset {
  vmem.clear A9M.L2.mem

}

; ---   *   ---   *   ---
; write data to expr

macro A9M.L2.cat [item] {
  forward vmem.cat A9M.L2.mem,item

}

; ---   *   ---   *   ---
; crux

macro A9M.L2.proc_expr {

  ; do the dance
  vmem.rewind A9M.L2.mem

  A9M.L2.walk_expr

  ; cleanup and go next
  A9M.L2.exprcnt=A9M.L2.exprcnt+1
  A9M.L2.reset

}

; ---   *   ---   *   ---
; walk expr

macro A9M.L2.walk_expr {

  match token expr , A9M.L1.mem A9M.L2.mem \{

    while expr\#.ptr < expr\#.len

      ; get serialized token
      A9M.L1.load

      ; TODO: proc token
      ; for now just write as-is
      A9M.SYMOUT.cat A9M.L1.mem

      ; save, cleanup and go next
      A9M.L1.reset

    end while

  \}

}

; ---   *   ---   *   ---
