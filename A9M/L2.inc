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

  ; ^counts L2
  A9M.L2.exprcnt = 0

; ---   *   ---   *   ---
; TODO
;
;  ; get iproc on first expr
;  if A9M.exprcnt=0
;    A9M.load_ipret
;
;  ; ^nope, run ipret proc
;  else
;
;    match id , A9M.ipret \{
;      A9M.ipret
;
;    \}
;
;  end if
;
;  A9M.exprcnt=A9M.exprcnt+1

; ---   *   ---   *   ---
