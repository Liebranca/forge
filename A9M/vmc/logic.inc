; ---   *   ---   *   ---
; A9M VMC LOGIC
; Think harder!
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.vmc.logic

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; breaks down simple expressions

macro vmc.decode.logical dst,EXPR {

  local prefix
  local expr

  prefix equ
  expr   equ EXPR

  match =~ =( inner =) , expr \{
    prefix equ ~
    expr   equ inner

  \}

  match A op? B? , expr \{

    local op
    local B

    op equ op?
    B  equ B?

    match == any , B? \\{
      op equ op =
      B  equ any

    \\}

    dst equ A,op,B

  \}

  dst equ prefix (dst)

}

; ---   *   ---   *   ---
; ^shorthand

macro $logic fn,EXPR {

  local vars
  local prefix

  prefix equ

  vmc.decode.logical vars,EXPR


  match P =( inner =) , vars \{
    prefix equ P
    vars   equ inner

  \}

  match =( inner =) , vars \{
    vars equ inner

  \}


  fn vars,prefix

}

; ---   *   ---   *   ---
; kind of an if ;>

macro $on EXPR,mode=if {

  ; do on [EXPR]
  macro $on.inner vars,prefix= \{

    match X =, op =, Y , vars \\{

      local w0
      local w1

      w0=0
      w1=0

      vmc.decode w0,X,read
      vmc.decode w1,Y,read

      mode prefix (w0 op w1)

    \\}

  \}

  ; ^run
  $logic $on.inner,EXPR

}

; ---   *   ---   *   ---
; ^repeated!

macro $while EXPR {
  $on EXPR,while

}

; ---   *   ---   *   ---
; stop!

macro $break EXPR {

  local ok
  ok equ 0

  ; conditional break
  match =on expr , EXPR \{

    $on expr
      break

    end if
    ok equ 1

  \}

  ; ^no condition
  match =0 , ok \{
    break

  \}

}

; ---   *   ---   *   ---
; kind of a for!

macro $repeat src,step= {

  local w0
  w0=0

  vmc.decode w0,src,read


  repeat w0
  match any , step \{$mov src,(%-1)*step\}

}

; ---   *   ---   *   ---
; kind of an else if ;>
;
; NOTE:
;
; The Arcane 9 uses on/or/off
; rather than if/(else or else if)/end if
;
; number one, because it's a switch
; but also, it's shorter and doesn't
; throw off your line alignment
;
; but this also means B(inary) OR
; becomes BOR to avoid a name conflict!
;
; we won't do that rename here, so sadface
; but E(lse) ON will do ;>

macro $eon EXPR,mode=if {

  ; do on [EXPR]
  macro inner pre,X,op,Y \{

    local w0
    local w1

    w0=0
    w1=0

    vmc.decode w0,X,read
    vmc.decode w1,Y,read

    else if prefix (w0 op w1)

  \}

  ; ^have expr?
  match any , EXPR \{
    $logic inner,EXPR

  \}

  ; ^else it's an else!
  match , EXPR \{
    else

  \}

}

; ---   *   ---   *   ---
