; ---   *   ---   *   ---
; A9M L2
; K-sized tree of
; J-sized arrays of
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

  VERSION   v0.00.7b
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

macro A9M.L2.cat {


  ; put serialized token
  match ctx , A9M.L1.ctx \{
    vmem.cat A9M.L2.mem,ctx\#%origin

  \}

  ; have ptr to str?
  local loc
  loc = 0

  $mov loc,%[A9M.L1.idx \loc]

  ; ^put ptr if so
  if ~(loc = $FFFF)

    match id , A9M.L1.idx \{
      vmem.cat A9M.L2.mem,id\#%origin

    \}

  end if

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

      local value
      value = 0

      A9M.L1.get_token_id value

      ; we have proc token now!
      ;
      ; what we don't have done yet
      ; is *implemented* the methods
      ; this generated entry point
      ; branches off to ;>
      ;
      ; A9M.L1.proc_token   value

      A9M.SYMOUT.cat A9M.L1.mem

      ; save, cleanup and go next
      A9M.L1.reset

    end while

  \}

}

; ---   *   ---   *   ---
