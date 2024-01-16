; ---   *   ---   *   ---
; A9M VMC STACK
; A plate on another ;>
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.vmc.stack

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

if ~ defined A9M.STACK_SZ
  define A9M.STACK_SZ $100

end if

; ---   *   ---   *   ---
; write to current top

macro $push src {

  local ok
  local size
  local value

  ; defaults
  value equ src
  size  equ word

  ; size passed?
  match sz v , src \{
    size  equ sz
    value equ v

  \}

  ; ^paste ops
  match sz v , size value \{
    $sub sp,sizeof.\#sz
    $mov sz [vmc.STACK+sp],v

  \}

}

; ---   *   ---   *   ---
; ^read from current top

macro $pop dst {

  local ok
  local size
  local value

  ; defaults
  value equ dst
  size  equ word

  ; size passed?
  match sz v , dst \{
    size  equ sz
    value equ v

  \}

  ; ^paste ops
  match sz v , size value \{
    $mov v,sz [vmc.STACK+sp]
    $add sp,sizeof.\#sz

  \}

}

; ---   *   ---   *   ---
; setup frame

macro $enter {

  ; save old block size
  vmc.STACK.frame_sz.back equ \
    vmc.STACK.frame_sz

  vmc.STACK.frame_sz equ 0


  ; make varlises
  macro inner [TNV] \{

    forward match type NV , TNV \\{
      $\\#type\\#%vmc_stknew NV

    \\}

  \}

  ; ^run
  match list , vmc.STACK.frame_vars \{
    inner list

  \}


  ; ^save stack ptrs
  $push sb
  $mov  sb,sp


  ; align?
  local ali
  ali equ 1

  match =0 , vmc.STACK.frame_sz \{
    ali equ 0

  \}


  ; ^grow downwards ;>
  match =1 , ali \{

    vmc.STACK.frame_sz equ \
      (((vmc.STACK.frame_sz+1) shr 1) shl 1)

    $sub sp,vmc.STACK.frame_sz

    ; set default values
    match list , vmc.STACK.frame_set \\{
      cline.filter list

    \\}

  \}


  ; save lissing data
  vmc.STACK.frame_vars.back equ \
    vmc.STACK.frame_vars

  ; ^clear
  vmc.STACK.frame_vars equ
  vmc.STACK.frame_set equ

}

; ---   *   ---   *   ---
; ^cleanup

macro $leave {

  ; have frame?
  local ali
  ali equ 1

  match =0 , vmc.STACK.frame_sz \{
    ali equ 0

  \}

  ; ^yes, adjust stack ptr
  match =1 , ali \{
    $add sp,vmc.STACK.frame_sz
    $pop sb

  \}

  ; ^else just pop
  match =0 , ali \{
    $pop sb

  \}


  ; undo lises
  vmc.STACK.frame_vars equ \
    vmc.STACK.frame_vars.back

  restore vmc.STACK.frame_vars.back

  macro rmdef lis \{
    restore @\#lis

  \}

  macro inner [item] \{

    forward match type name , item \\{

      local lis
      ok equ name

      match n v , name \\\{
        lis equ n

      \\}

      match any , lis \\\{
        rmdef any

      \\\}

    \\}

  \}

  ; ^run
  match list , vmc.STACK.frame_vars \{
    inner list

  \}


  ; ^get old block size
  vmc.STACK.frame_sz equ \
    vmc.STACK.frame_sz.back

  restore vmc.STACK.frame_sz.back

}

; ---   *   ---   *   ---
; makes comfty label for
; stack allocations

macro vmc._icedecl type,name,value= {

  ; calc and flatten offset
  local off
  off equ (-(vmc.STACK.frame_sz))-sizeof.#type

  flatn off,off


  ; ^make label
  match id x , name off \{
    define @\#id vmc.STACK+sb+x

  \}

  ; ^set defval if passed
  match id any , name value \{
    eolcat vmc.STACK.frame_set, \
      $mov type [@\#id],any

  \}


  ; ^inc and flatten frame size
  vmc.STACK.frame_sz equ \
    vmc.STACK.frame_sz+sizeof.#type

  rept 1 x:vmc.STACK.frame_sz \{
    vmc.STACK.frame_sz equ x

  \}

}

; ---   *   ---   *   ---
; ^icef*ck

macro vmc._gen_icedecl type {


  ; *promised* innards
  macro $#type#%vmc_stknew NV \{

    local v
    local n

    n equ NV
    v equ

    match name value , NV \\{
      n equ name
      v equ value

    \\}

    vmc._icedecl type,n,v

  \}

  ; ^entry point
  macro $#type NV \{
    commacat vmc.STACK.frame_vars,type NV

  \}

}

; ---   *   ---   *   ---
; ^run

vmc._gen_icedecl byte
vmc._gen_icedecl word
vmc._gen_icedecl dword
vmc._gen_icedecl qword

; ---   *   ---   *   ---
; nit yourself!

define   vmc.STACK
define   vmc.STACK.args

define   vmc.STACK.frame_sz      0
define   vmc.STACK.frame_sz.back 0

define   vmc.STACK.frame_vars
define   vmc.STACK.frame_vars.back
define   vmc.STACK.frame_set

vmem.new vmc.STACK,blk A9M.STACK_SZ
$mov     sp,A9M.STACK_SZ

; ---   *   ---   *   ---
; dbout wraps

macro STACK.prich {
  vmem.prich vmc.STACK,1

}

macro STACK.bprich {
  display $0A,'STACK:'
  vmem.bprich vmc.STACK,1

}

; ---   *   ---   *   ---
