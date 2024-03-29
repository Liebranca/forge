; ---   *   ---   *   ---
; A9M VMC ISBASIC
; Basic instruction set
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.vmc.isbasic

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; put src in dst
; *the* most used one ;>

macro $mov dst,src {

  local value
  value=0

  vmc.decode value,src,read
  vmc.decode value,dst,write

}

; ---   *   ---   *   ---
; ^second most used i think...

macro $lea dst,src {

  local value
  value=0

  vmc.decode.addr value,src
  vmc.decode      value,dst,write

}

; ---   *   ---   *   ---
; bit rotate right
; a beautiful instruction!

macro $ror SD,src {

  ; unpack args
  local bits
  vmc.decode bits,src,read

  local name
  local sz
  local value

  cunpack SD,sz=>qword,name=>-BASE

  ; ^unroll
  match dst size , name sz \{

    ; clamp bits to size of chunk
    bits = bits mod (sizeof.\#size * 8)

    ; fetch value to rot
    vmc.decode value,dst,read

    ; get a mask N-bits wide
    local  mask
    $bones mask,bits

    ; get shift to end of value
    local shift
    shift = sizeof.\#size * 8
    shift = shift-bits


    ; get the portion to be rotated out!
    local out
    out = value and mask

    ; ^take it out ;>
    value = value shr bits

    ; ^now put it back!
    out   = out shl shift
    value = value or out


    ; final write to dst
    vmc.decode value,dst,write

  \}

}

; ---   *   ---   *   ---
; ^rotating in the opposite
; direction is just a matter
; of faking it ;>

macro $rol SD,src {

  ; preliminary unpack
  local name
  local sz

  cunpack SD,sz=>qword,name=>-BASE

  ; get size minus bits!
  match size , sz \{
    $ror SD,\
      (sizeof.\#size * 8)\
    - (src mod (sizeof.\#size * 8))

  \}

}

; ---   *   ---   *   ---
; * where are xor,or,and,
;   not?
;
; * where are shl and shr??
;
; * where are bsf,bsr,add,
;   sub,inc,,dec,etc???
;
; they are all generated by
; this operator icef*ck!

macro vmc._gen_op type,[name] {

  forward

    ; unary
    match =u , type \{

      macro $\#name dst \\{

        local w0
        w0=0

        vmc.decode w0,dst,type#op name

      \\}

    \}


    ; ^binary
    match =b , type \{

      macro $\#name dst,src \\{

        local w0
        w0=0

        vmc.decode w0,src,read
        vmc.decode w0,dst,type#op name

      \\}

    \}

}

; ---   *   ---   *   ---
; ^bat-run

match __list , vmem.uops_list {
  vmc._gen_op u,__list

}

match __list , vmem.bops_list {
  vmc._gen_op b,__list

}

; ---   *   ---   *   ---
