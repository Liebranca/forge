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

  VERSION   v0.00.3b
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

  ; make note of header addr
  match id , vmc.USRMEM \{
    $mov qword [vmc.USRMEM:er],id\#.ptr
    $mov ar,id\#.ptr

  \}

  ; extend brk by size of partition head
  $caswrite vmc.USRMEM,blk sizeof.valloc.part

  ; get partition size
  $mov size,sizeof.line
  $shl size,fr

  ; ^extend buff by size times elems
  size = size shl sizep2.line
  $caswrite vmc.USRMEM,blk size

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

macro valloc.part.search req {

  $qword lice $00
  $enter

  ; get partition size as idex
  valloc.get_part_size req
  $mov byte [@blk.idex],ar


  ; map requested size to
  ; block cnt bitmask
  $add     ar,$06
  $mov     cr,req

  $urdivp2 cr,cr,ar
  $bones   byte [@blk.reqm],cr
  $sub     ar,$06


  ; ^get ptr to beg of partition table
  $mov fr,ar
  $mov er,ar
  $shl er,$03

  $mov br,qword [vmc.USRMEM:er]


  ; is first entry on table?
  $on br = 0

    valloc.part.new

    $mov byte [@blk.head],$00
    $mov byte [@blk.pos],$00

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
      $mov er,byte [@blk.reqm]
      vmpart.fit

      ; ^yes, write to this partition
      $on ar < $3F
        $mov byte [@blk.pos],ar
        break

      ; ^nope, get another partition
      else

        valloc.part.get_next br,br

        ; ^none left; make new
        $on br=0

          $mov er,qword [@lice]
          $add er,valloc.part.ahead

          $mov fr,byte [@blk.idex]

          valloc.part.new

          $mov byte [@blk.pos],$00

          break

        end if

        ; got one, keep going
        $mov qword [@lice],br
        $inc byte [@blk.head]

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
  $mov dst,qword [vmc.USRMEM:src+valloc.part.#what]

}

macro valloc.part.set dst,src,what {
  $mov qword [vmc.USRMEM:dst+valloc.part.#what],src

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

  $mov ar,qword [vmc.USRMEM:idex*8]

  $repeat N
    valloc.part.get_next ar,ar

  end repeat

}

; ---   *   ---   *   ---
