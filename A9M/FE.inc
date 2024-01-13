; ---   *   ---   *   ---
; A9M FE
; First expression ;>
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.FE

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; NOTE:
;
; FE exists solely to separate
; the inconvenient check for
; ipret line having been
; already processed...
;
; because fixed rules apply
; to it only once, it makes
; sense to separate them
; from the other bits
;
; however this creates a
; weird feeling, of FE
; belonging with L0 and L1;
;
; don't fall for that feeling!

; ---   *   ---   *   ---
; read first expr to get ipret

macro A9M.FE.read {

  A9M.dbout 'FE:'

  match id step , A9M.FSRC A9M.L0.CHAR_SZ \{

    repeat id\#.len shr sizep2.\#step

      A9M.L0._chrin

      if A9M.L0.chk.expr_term
        break

      else
        A9M.L0.store

      end if

    end repeat

    ; ^execute directive
    A9M.FE.run

  \}

  A9M.L0.reset
  A9M.dbout $0A,$0A

}

; ---   *   ---   *   ---
; L1: import ipret

macro A9M.FE.run {

  ; get token

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
  if name = 0

    vhash.from_disk A9M.L1.keywtab,A9M.L1.DEFTAB

    match any , A9M.ROMPATH \{
      include any\#'L1.pinc'

    \}

  ; we should get the ipret here,
  ; but we don't yet have an ipret table!
  else
    vmem.seek A9M.L1.mem,sigil

  end if

  ; cleanup
  A9M.L1.reset

}

; ---   *   ---   *   ---
