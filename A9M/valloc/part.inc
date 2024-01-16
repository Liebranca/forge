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

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; base struc

vreg.new valloc.part
  szmy qword mask
  szmy qword ahead

vreg.end

; ---   *   ---   *   ---
; make partition

macro valloc.part.new {

  local size
  size = 0

  match id , VALLOCM \{
    $mov qword [VALLOCM+er],id\#.ptr
    $mov ar,id\#.ptr

  \}

  ; extend buff by size of partition head
  vmem.write VALLOCM,blk sizeof.valloc.part

  ; get partition size
  $mov size,sizeof.line
  $shl size,fr

  ; ^extend buff by size times elems
  size = size shl 2;sizep2.line
  vmem.write VALLOCM,blk size

}

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

macro valloc.part.search dst,req {

  $qword lice $00
  $enter

  ; get partition size as idex
  valloc.get_part_size req
  $mov %[dst idex],ar


  ; map requested size to
  ; block cnt bitmask
  $add     ar,$06
  $mov     cr,req

  $urdivp2 cr,cr,ar
  $bones   %[dst reqm],cr
  $sub     ar,$06


  ; ^get ptr to beg of partition table
  $mov fr,ar
  $mov er,ar
  $shl er,$03

  $mov br,qword [VALLOCM+er]


  ; is first entry on table?
  $on br = 0

    valloc.part.new

    $mov %[dst head],$00
    $mov %[dst pos],$00

    $mov qword [@lice],ar

  ; ^nope, get existing
  else

    $mov qword [@lice],br

    ; walk partitions
    while 1

      ; get occupation mask
      $mov br,qword [@lice]
      valloc.part.get_mask fr,br

      ; block fits?
      $mov er,%[dst reqm]
      vmpart.fit

      ; ^yes, write to this partition
      $on ar < $3F
        $mov %[dst pos],ar
        break

      ; ^nope, get another partition
      else

        valloc.part.get_next br,br

        ; ^none left; make new
        $on br=0

          $mov er,qword [@lice]
          $add er,valloc.part.ahead

          $mov fr,%[dst idex]

          valloc.part.new

          $mov %[dst pos],$00

          break

        end if

        ; got one, keep going
        $mov qword [@lice],br
        $inc %[dst head]

      end if


    end while

  end if


  ; reset out
  $mov ar,qword [@lice]

  ; cleanup
  $leave

}

; ---   *   ---   *   ---
; getset protos

macro valloc.part.get dst,src,what {
  $mov dst,qword [VALLOCM+src+valloc.part.#what]

}

macro valloc.part.set dst,src,what {
  $mov qword [VALLOCM+dst+valloc.part.#what],src

}

; ---   *   ---   *   ---
; getset next partition of size

macro valloc.part.get_next dst=ar,src=er {
  valloc.part.get dst,src,ahead

}

macro valloc.part.set_next dst=ar,src=er {
  valloc.part.set dst,src,ahead

}

; ---   *   ---   *   ---
; ^get partition occu mask

macro valloc.part.get_mask dst=ar,src=er {
  valloc.part.get dst,src,mask

}

macro valloc.part.set_mask dst=ar,src=er {
  valloc.part.set dst,src,mask

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
; ^get Nth partition of size

macro valloc.part.get_nth idex,N {

  $mov ar,qword [VALLOCM+idex*8]

  $repeat N
    valloc.part.get_next ar,ar

  end repeat

}

; ---   *   ---   *   ---
