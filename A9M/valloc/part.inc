; ---   *   ---   *   ---
; A9M VALLOC PART
; Split up a big buff ;>
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.valloc.part

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; base struc

vreg.new valloc.part
  szmy qword mask
  szmy qword ahead

vreg.end

; ---   *   ---   *   ---
; get size of partition to
; use for a given block size

macro valloc.get_part_size req {

  ; fits in first partition
  if req < sizeof.line * $04
    $mov ar,$00

  ; ^or in second
  else if req < sizeof.dline * $04
    $mov ar,$01

  ; ^or in third...
  else if req < sizeof.qline * $04
    $mov ar,$02

  ; ^fourth...
  else if req < sizeof.xline * $40
    $mov ar,$03

  ; ^or die!
  else

    display ERRTAG,'request of '
    hexsay  req,$10

    display ' exceeds maximum partition size',$0A

    err

  end if

}

; ---   *   ---   *   ---
; get partition to use for
; a new block

macro valloc.part.search req {

  ; get partition size as idex
  valloc.get_part_size req

  ; ^get ptr to beg of partition table
  $mov er,[VALLOCM+ar*8]


  ; is first entry on table?
  $on er = 0

    match id , VALLOCM \{
      $mov qword [VALLOCM+ar*8],id\#.ptr
      valloc.part.new

    \}

  ; ^get
  else

    ; save tmp
    $qword ezy ar
    $mov   ar,er

    ; iter existing partitions
    local have
    have = 0

    while have=0

      ; get ahead
      $mov er,ar
      valloc.part.get_next

      ; ^block fits?
      vmpart.get_free

    end while

  end if

}

; ---   *   ---   *   ---
; make partition

macro valloc.part.new {

  local size
  size = 0

  ; extend buff by size of partition head
  vmem.write VALLOCM,blk sizeof.valloc.part

  ; get partition size
  $mov size,sizeof.line
  $shl size,ar

  ; ^extend buff by size times elems
;  size = size shl sizep2.line
  vmem.write VALLOCM,blk size

}

; ---   *   ---   *   ---
; get next partition of size

macro valloc.part.get_next {
  $mov ar,qword [VALLOCM+er+valloc.part.ahead]

}

; ---   *   ---   *   ---
; get last partition of size

macro valloc.part.get_last {

  while 1

    valloc.part.get_next

    ; ^keep going on ! null
    $on ~(ar=0)
      $mov er,ar

    ; else stop
    else
      break

    end if

  end while

}

; ---   *   ---   *   ---
