; ---   *   ---   *   ---
; PESO ALLOC (H)
; Iface trick
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'
  use '.asm' peso::mpart

import

; ---   *   ---   *   ---
; info

  TITLE     peso.alloc_h

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'


  alloc.debug        = 1
  alloc.hash_dynamic = 0

  alloc.hash_cnt     = 0
  alloc.hash_max     = 0
  alloc.hash_bits    = 0

; ---   *   ---   *   ---
; eponymous sweetcrux

macro alloc size {

  local p2
  local ok

  p2 equ 0
  ok equ 0

  ; get mem
  mov  rdi,size
  call alloc.crux

  ; check concurrent allocations
  alloc.hash_cnt=alloc.hash_cnt+1

  ; ^extend maximum
  if alloc.hash_cnt > alloc.hash_max

    alloc.hash_max=alloc.hash_cnt

    ; max > next pow2
    p2 equ 1  shl (alloc.hash_bits+$08)
    ok equ p2 <=  (alloc.hash_max)

    ; ^increase size of hashtab if so
    if ok
      alloc.hash_bits=alloc.hash_bits+1

    end if

  end if

}

; ---   *   ---   *   ---
; ^resizes

macro realloc addr,size {

  mov  rdi,addr
  mov  rsi,size

  call alloc.realloc

}

; ---   *   ---   *   ---
; ^closes

macro free addr {

  mov  rdi,addr
  call alloc.free

  alloc.hash_cnt=alloc.hash_cnt-1

}

; ---   *   ---   *   ---
; footer

macro alloc.seg {

  local bX

  if ~ defined loaded?peso.alloc

    if alloc.debug

      bX equ alloc.hash_bits
      display PETAG,\
        'alloc.hash_bits => ',bX+$30

    end if

    include '%ARPATH%/forge/peso/alloc.asm'

  end if

}

; ---   *   ---   *   ---
