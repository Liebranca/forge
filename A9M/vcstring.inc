; ---   *   ---   *   ---
; VIRTUAL C STRINGS
; This is my life now
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.vcstring

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  vcstring.MASK_Z0 = $7F7F7F7F7F7F7F7F
  vcstring.MASK_Z1 = $0101010101010101
  vcstring.MASK_Z2 = $8080808080808080

; ---   *   ---   *   ---
; gives 0 or 1+nullidex

macro vcstring.ziw {

  $xor cr,cr

  ; convert 00 to 80 && 01-7E to 00 ;>
  $xor  fr,vcstring.MASK_Z0
  $badd fr,vcstring.MASK_Z1
  $and  fr,vcstring.MASK_Z2

  ; get first null byte (80)+1
  $on ~(fr = $00)

    $bsf cr,fr
    $shr cr,$03
    $inc cr

  end if

}

; ---   *   ---   *   ---
; length of cstr if chars
; are in 00-7E range, else bogus

macro vcstring.length src {

  match id , src \{

    $xor ar,ar
    while $01

      ; boundschk
      $break on er >= id\#.size

      ; get null in qword
      $mov fr,bounded [id+er]
      vcstring.ziw

      ; have?
      $on cr = $00
        $add ar,$08
        $add er,$08

      ; ^nope, null found
      else
        break

      end if

    end while

    ; sum final length
    $on cr > 0
      $dec cr

    end if

    $add ar,cr
    $sub er,ar

  \}

}

; ---   *   ---   *   ---
