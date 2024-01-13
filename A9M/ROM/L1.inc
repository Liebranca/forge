; ---   *   ---   *   ---
; A9M L1:ROM
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

  use '.inc' A9M::vmc
  use '.inc' A9M::vhash

  use '.inc' A9M::SHARE::L1

  use '.inc' f1
  use '.inc' f1::cx

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.ROM.L1

  VERSION   v0.00.3b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; crux

define    tab
vhash.new tab,A9M.L1.head,\
  $06,A9M.L1.TOKEN_SZ shr 3

define    branch.outer
define    branch.inner

$mov ptr ice,ptr tab

; ---   *   ---   *   ---
; table fill helper

macro settab X,[item] {

  common

    local i
    i = 0

    ; set token class
    A9M.L1.head.TRF.set A9M.L1.ctx,A9M.L1.#X

    ; ^make note of
    commacat branch.outer,X


  forward


    ; unpack args
    local T
    local K
    local ok
    ok equ 0

    ; passed as tag => key
    match tag ===> key , item \{

      T  equ tag
      K  equ key

      ok equ 1

    \}

    ; ^passed as *just* tag
    ; so make key from it!
    match =0 tag , ok item \{
      T equ tag
      K equ \`tag

    \}


    ; store serialized token to
    ; associate with key
    match key , K \{
      A9M.L1.head.SID.set A9M.L1.ctx,i
      vhash.store key,% A9M.L1.ctx

    \}

    ; ^generate definition to
    ; associate with tag
    match tag id , T A9M.L1.ctx \{

      local w0
      local buf

      w0 = 0

      ; stringify hashed value
      vmem.new  buf,blk $00
      $combr    w0,byte %[id SID],byte %[id TRF]

      ; ^save it to a constant
      symstirr  buf,w0
      f1.define A9M.L1.SYM.\#tag,ptr buf

      ; ^save it to def Q
      commacat branch.inner,tag

    \}

    i = i+1

  common match list , branch.inner \{
    _gen_layer_1 X,list
    branch.inner equ

  \}

}

; ---   *   ---   *   ---
; branching: outer layer

macro _gen_layer_0 [item] {

  common
    f1.macro A9M.L1.proc_token token
    f1.cxbeg OPEN

  forward

    ; stringify token subclass
    local    TRF_b

    vmem.new TRF_b,blk $00
    symstirr TRF_b,A9M.L1.#item

    ; ^branch
    f1.ccall 'A9M.L1.proc_'#`item#' token',\
      '(token and $FF) = ',ptr TRF_b

  common
    f1.cxend
    f1.cend

}

; ---   *   ---   *   ---
; branching: inner layer

macro _gen_layer_1 name,[item] {

  common
    f1.macro A9M.L1.proc_#name token
    f1.cxbeg OPEN

  forward

    ; ^branch
    f1.ccall 'A9M.L1.logic.'#`item,\
      'token = A9M.L1.SYM.'#`item

  common
    f1.cxend
    f1.cend

}

; ---   *   ---   *   ---
; fill table

; top-level hierarchicals
settab HIER_T,\
  clan,rom,reg,proc,blk

; hier specs
settab HIER_S,\
  iface,guts

; width specs
settab TYPE_S,\
  byte,wide,brad,word

; "special" operators
settab METAOP_T,\
  dot     => '.',\
  comma   => ',',\
  ellipse => '...',\
  dcolon  => '::' ,\
  arrow   => '->'

;; operators
;settab A9M.L1.OP_T,\
;\

;\
;  '^'  ,'|'  ,'&'  ,\
;  '~'  ,'!'  ,\
;\
;  '^~' ,'|~' ,'&~' ,\
;  '<<' ,'>>' ,'||' ,'&&' ,\
;  '^^!','||!','&&!',\
;\
;  '<'  ,'>'  ,'<=' ,'>=' ,\
;  '==' ,'!=' ,\
;\
;  '*^' ,'*'  ,'*!' ,'/'  ,\
;  '++' ,'+'  ,'--' ,'-'  ,

; ---   *   ---   *   ---
; spawn convenience macros

match __list , branch.outer {
  _gen_layer_0 __list

}


; ---   *   ---   *   ---
; save tab

f1.to_disk
vhash.to_disk tab

; ---   *   ---   *   ---
