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

  VERSION   v0.00.4b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL I

  define   A9M.L2.mem
  vmem.new A9M.L2.mem,blk A9M.L1.TOKEN_SZ

  A9M.L2.exprcnt = 0

  vmem.new A9M.L2.STROUT,blk $00
  vmem.new A9M.L2.SYMOUT,blk $00

  commacat A9M.$$,ptr A9M.L2.STROUT
  commacat A9M.$$,ptr A9M.L2.SYMOUT

; ---   *   ---   *   ---
; ~

macro A9M.L2.reset {
  vmem.clear A9M.L2.mem

}

; ---   *   ---   *   ---
; write token to expr

macro A9M.L2.cat {

  ; save meta
  $pass ptr A9M.L2.mem,ar,lit word
  $call vmem.bstore

  ; ^save token
  vmem.cat A9M.L2.mem,A9M.L1.mem

}

; ---   *   ---   *   ---
; write expr to fout

macro A9M.L2.store ct& {
  vmem.write A9M.L2.SYMOUT,ct

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
    A9M.L2.common_line

  end if

  A9M.L2.exprcnt=A9M.L2.exprcnt+1
  A9M.L2.reset

}

; ---   *   ---   *   ---
; first line of an arcane file!

macro A9M.L2.first_line {

  ; get token
  A9M.L1.load

  local name
  local sigil

  name  = 0
  sigil = 0


  ; walk chars of token
  match token step , A9M.L1.mem A9M.L0.CHAR_SZ \{

    repeat token\#.len shr sizep2.\#step

      A9M.L0.load

      ; char is name of ipret
      if A9M.L0.chk.usrchr
        name=name+1

      ; errchk
      else if (% > 1) & (name > 0)
        out@err 'peso standard forbids ' \
          #'sigils on ipret name'

      ; ^sigil gives ipret mode
      else
        sigil=sigil+1

      end if

    end repeat

  \}


  ; get base ipret
  if ~name
    vhash.from_disk A9M.L1.tab,A9M.L1.DEFTAB

  ; we should get the ipret here,
  ; but we don't yet have an ipret table!
  else
    vmem.seek A9M.L1.mem,sigil

  end if


  ; cleanup
  A9M.L1.reset

}

; ---   *   ---   *   ---
; hash for ids (test)

vreg.new A9M.L1.id_t
  szmy word loc

vreg.end
sizeof.A9M.L1.id_t=$02


define          A9M.L1.idx
A9M.L1.id_t.new A9M.L1.idx


define    A9M.L2.idtab
vhash.new A9M.L2.idtab,A9M.L1.id_t,\
  $04,A9M.L1.TOKEN_SZ


; ---   *   ---   *   ---
; walk expr

macro A9M.L2.common_line {

  match token expr , A9M.L1.mem A9M.L2.mem \{

    while expr\#.ptr < expr\#.len

      ; get token
      A9M.L1.load

      ; ^match against dict
      $mov ptr ice,ptr A9M.L1.tab
      vhash.find % vmc.REG,ptr token

      ; ^is keyw?
      $on br = 1

        ; get token class
        $mov %[A9M.L1.ctx TRF],ar
        $shr ar,$08
        $mov %[A9M.L1.ctx SID],ar

        ; ^write to out
        A9M.L2.store % A9M.L1.ctx


      ; ^nope, assume ID
      else

        ; use generic ID class
        $mov %[A9M.L1.ctx TRF],A9M.L1.ID_T
        $mov %[A9M.L1.ctx SID],$FF

        ; ^write to out
        A9M.L2.store % A9M.L1.ctx


        ; now we want to link to the
        ; string itself, so...
        ;
        ; have we parsed this ID before?
        $mov ptr ice,ptr A9M.L2.idtab
        vhash.find % vmc.REG,ptr token

        ; ^yes!
        $on br = 1

          ; just save ptr to string
          ; we got from the table
          $mov %[A9M.L1.idx loc],ar
          A9M.L2.store % A9M.L1.idx

        ; ^no :c
        else

          ; alright don't panic
          ; we want to get the top of
          ; STROUT and save that to the table
          local top
          match strout , A9M.L2.STROUT \\{

            top = strout\\#.ptr

            $mov %[A9M.L1.idx loc],top
            vhash.store ptr token,% A9M.L1.idx

          \\}

          ; ^now write the string to STROUT!
          local sbuf
          vmem.view  sbuf,token,0,token\#.len
          vmem.write A9M.L2.STROUT,ptr sbuf

          ; now write ptr for *this* instance!
          $mov %[A9M.L1.idx loc],top
          A9M.L2.store % A9M.L1.idx

        end if


      end if

      ; save, cleanup and go next
      A9M.L1.reset

    end while

  \}

}

; ---   *   ---   *   ---
