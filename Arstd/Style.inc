; ---   *   ---   *   ---
; STYLE
; The ubiquitous and oft-used
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     Arstd.Style

  VERSION   v0.02.4a
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  MAM.xmode='stat'
  MAM.align=0

; ---   *   ---   *   ---
; top-level switch

macro MAM.head name= {

  if MAM.xmode = 'stat'
    format ELF64 executable 3

    match any , name \{
      entry any

    \}

  else if MAM.xmode = 'obj'
    format ELF64

    match any , name \{
      public any

    \}

  end if

  List.new MAM.foot
  List.new MAM.atexit
  List.new MAM.symtab

}

; ---   *   ---   *   ---
; footer push proto

macro MAM.xfoot name {

  local flat
  local have

  have equ 0

  ; detect duplicate entry
  MAM.foot.cflatten flat
  match any,flat \{
    tokin have,name\#._gen_footer,any

  \}

  ; ^add non-duplicate
  match =0 , have \{
    MAM.foot.unshift name\#._gen_footer

  \}

}

; ---   *   ---   *   ---
; visibility flag, used for
; object exports/imports

macro MAM.sym_vflag dst,name,vflag= {

  local ok
  dst equ
  ok  equ 0

  match =public,vflag \{

    dst equ public name

    MAM.symtab.push db `extrn  # ' ' \
      # `name '\,' $0A

    ok equ 1

  \}

  ; ^lis given
  match =0 any , ok vflag \{

    dst equ public name as any

    MAM.symtab.push db `extrn # ' ' \
      # ' "' \# any \# '"' \
      # ' ' # `as # ' ' # `name '\,' $0A

  \}

  if MAM.xmode = 'obj'
    dst

  end if;

}

; ---   *   ---   *   ---
; ^conditionally declare
; both visibility and symbol

macro MAM.sym name,vflag= {

  local dst
  MAM.sym_vflag dst,name,vflag

  match any , name \{
    any\#:

  \}

}

; ---   *   ---   *   ---
; align to sizeof

macro MAM.malign size {
  align sizeof.#size

}

; ---   *   ---   *   ---
; ^conditionally

macro MAM.calign size {

  if MAM.align
    MAM.malign size

  end if

}

; ---   *   ---   *   ---
; paste avtohed obj stuff

macro MAM.avto {

  virtual at $00 as 'preshwl'
    MAM.symtab

  end virtual

}

; ---   *   ---   *   ---
; dude, what *is* a SECTION?!

macro MAM.segment name,type,size {

  if MAM.xmode = 'stat'
    segment type
    MAM.calign size

  else if MAM.xmode = 'obj'
    section name align size

  end if

}

; ---   *   ---   *   ---
; binary choice

macro bincho dst,x,a,b {

  match =0 , x \{
    dst equ a

  \}

  match =1 , x \{
    dst equ b

  \}

}

; ---   *   ---   *   ---
; ~ with { y = N >> x }
; ^ give { y/y if y >= 1 }
;
; ~ else 0

macro shrsdiv dst,N,x {

  local y
  local ok

  y   equ ((N) shr x)
  ok  equ 1
  dst equ 0


  ; ^flatten result
  rept 1 cnt:y \{
    y equ cnt

  \}

  ; ^chk 0/0
  match =0 , y \{
    ok equ 0

  \}


  ; ^all good, divide and flatten
  match =1 , ok \{
    rept 1 cnt:y/y \\{
      dst equ cnt

    \\}

  \}

}

; ---   *   ---   *   ---
; get {match =[which] , item}

macro tokis dst,item,which {

  local which2

  which2 equ =#which
  dst    equ 0

  ; ^unroll
  match pat , which2 \{

    match pat , item \\{
      dst equ 1

    \\}

  \}

}

; ---   *   ---   *   ---
; inneficient way of finding
; a symbol within a common list

macro tokin dst,N,[item] {

  common

    local ok
    local idex

    ok    equ 0
    idex  equ -1

    ; mode 'I' outs idex
    local mode
    mode equ 'B'

    ; ^passed in dst ;>
    match any , dst \{
      mode equ dst

    \}


  ; iter match N against list
  forward match =0 , ok \{

    tokis ok,N,item

    idex equ idex+1
    dst  equ ok

  \}


  ; ^alter result on idexof mode
  common

    ; give idex on success
    match =1 ='I' , ok mode \{

      ; flatten i+1+1...
      rept 1 cnt:idex \\{
        idex equ cnt

      \\}

      ; ^save to dst
      match any , idex \\{
        dst equ any

      \\}

    \}

    ; ^give non on failure
    match =0 ='I' , ok mode \{
      dst equ

    \}

}

; ---   *   ---   *   ---
; get Nth elem in list

macro nthof dst,[item] {

  common

    local cap
    local idex
    local ok

    cap  equ dst
    dst  equ

    idex equ 0
    ok   equ 0


  ; walk list
  forward match =0 , ok \{

    ; i eq cap?
    tokis ok,idex,cap

    match =1 , ok \\{
      dst equ item

    \\}

    ; flatten i++
    idex equ idex+1

    rept 1 cnt:idex \\{
      idex equ cnt

    \\}

  \}

}

; ---   *   ---   *   ---
; ^get value from key
; where list_a is keys
; and list_b is values

macro listmap dst,map& {

  match A ===> B , map \{

    local idex
    local key

    idex equ 'I'
    key  equ dst

    tokin idex,key,A
    dst equ idex

    nthof dst,B

  \}

}

; ---   *   ---   *   ---
; map size keyword to value

macro i_rX_proto \
  dst,size,b8,b16,b32,b64 {

  dst equ

  ; 8-bit
  match =byte , size \{
    dst equ b8

  \}

  ; ^16-bit
  match =word , size \{
    dst equ b16

  \}

  ; ^32-bit
  match =dword , size \{
    dst equ b32

  \}

  ; ^64-bit
  match =qword , size \{
    dst equ b64

  \}

}

; ---   *   ---   *   ---
; ^map to data decl

macro i_sized_data dst,size {
  i_rX_proto dst,size,db,dw,dd,dq

}

; ---   *   ---   *   ---
; ^map to register
; (E/R) [name] (L/X)

macro i_sized_reg0 dst,name,size {
  i_rX_proto dst,size,\
    name#l,name#x,e#name#x,r#name#x

}

; ---   *   ---   *   ---
; ^(R) [name] (D/W/B)

macro i_sized_reg1 dst,name,size {
  i_rX_proto dst,size,\
    name#b,name#w,name#d,name

}

; ---   *   ---   *   ---
; ^(E/R) [name] (L)

macro i_sized_reg2 dst,name,size {
  i_rX_proto dst,size,\
    name#l,name,e#name,r#name

}

; ---   *   ---   *   ---
; ^sweetcrux

macro i_sized_reg dst,name,size {

  local ok
  ok equ 0

  ; (E/R) [name] (L/X)
  tokin ok,name,a,b,c,d
  match =1 , ok \{
    i_sized_reg0 dst,name,size
    ok equ 2

  \}

  ; (R) [name] (D/W/B)
  match =0 , ok \{
    tokin ok,name,\
      r8,r9,r10,r11,r12,r13,r14,r15

  \}

  match =1 , ok \{
    i_sized_reg1 dst,name,size
    ok equ 2

  \}

  ; (E/R) [name] (L)
  match =0 , ok \{
    tokin ok,name,di,si,bp,sp

  \}

  match =1 , ok \{
    i_sized_reg2 dst,name,size

  \}

}

; ---   *   ---   *   ---
; ^sized register load

macro i_sized_ld name,size,src {

  local rX
  i_sized_reg rX,name,size

  mov rX,size [src]

}

; ---   *   ---   *   ---
; conditionally load register

macro i_ldX dst,src {

  local ok
  local rX

  ok equ 0
  rX equ

  tokin ok,dst,src

  if ~ok

    ok equ 0

    ; nothing passed!
    match , src \{
      ok equ 1

    \}


    ; src is address
    match =0 =ptr any , ok src \{

      i_sized_reg rX,dst,qword

      lea rX,[any]
      ok equ 1

    \}

    ; ^src is sized deref
    match =0 size =ptr any , ok src \{

      i_sized_reg rX,dst,size

      mov rX,size [any]
      ok  equ 1

    \}

    ; ^src is raw value
    match =0 , ok \{
      i_sized_reg rX,dst,qword
      mov rX,src

    \}

  end if

}

; ---   *   ---   *   ---
; gives [XYZ]mm+N accto size

macro x_sized_reg dst,N,size {

  local K
  K equ

  ; ^get letter
  match =xword , size \{
    K equ x

  \}

  match =yword , size \{
    K equ y

  \}

  match =zword , size \{
    K equ z

  \}

  ; ^cat to xmmN
  match any , K \{
    dst equ any\#mm#N

  \}

}

; ---   *   ---   *   ---
; open/close virtual "promise" paste

macro virblk.beg blkname {

  match any , blkname \{
    virtual at any
    virblk.\#any\#._vmem.beg=$
    virblk.\#any\#._vmem::

  \}

}

macro virblk.end blkname {

  match any , blkname \{

    virblk.\#any\#._vmem.size=\
      $-virblk.\#any\#._vmem.beg

    end virtual

  \}

}

; ---   *   ---   *   ---
; ^perform paste

macro virblk.paste blkname {

  match any , blkname \{

    any\#:

    repeat virblk.\#any\#._vmem.size

      load virblk.lb from \
        virblk.\#any\#._vmem:\
        virblk.\#any\#._vmem.beg+(%-1)

      db virblk.lb

    end repeat

  \}

}

; ---   *   ---   *   ---
; pastes comma separated as lines

macro npaste [line] {forward line}

macro npaste2 [line] {

  forward

    local elem
    local status

    status equ 0
    elem   equ line

  rept 2 \{

    status equ 0

    ; split m[,]
    match item =, next,elem \\{

      item

      elem   equ next
      status equ 1

    \\}

    ; ^single item
    match =0 any args,status elem \\{

      any args

      elem   equ
      status equ 1

    \\}

  \}

}

; ---   *   ---   *   ---
; please end my suffering

macro fnpaste list {
  macro inner [item] \{forward item\}
  match any,list \{inner any\}

}

macro fnpaste2 pro,list {
  pro
  fnpaste list

}

; ---   *   ---   *   ---
; cat A B C

macro protocat dst,sep,token& {
  match any , dst \{dst equ dst sep token\}
  match     , dst \{dst equ token\}

}

; ---   *   ---   *   ---
; ^C B A

macro lprotocat dst,sep,token& {
  match any , dst \{dst equ token sep dst\}
  match     , dst \{dst equ token\}

}

; ---   *   ---   *   ---
; ^sep is space

macro spacecat dst,token& {

  local sep
  sep equ

  protocat dst,sep,token

}

macro lspacecat dst,token& {

  local sep
  sep equ

  lprotocat dst,sep,token

}

; ---   *   ---   *   ---
; ^comma

macro commacat dst,token& {

  local sep
  sep equ ,

  protocat dst,sep,token

}

macro lcommacat dst,token& {

  local sep
  sep equ ,

  lprotocat dst,sep,token

}

; ---   *   ---   *   ---
; ^newline

macro eolcat dst,token& {

  local sep
  sep equ "\n",

  protocat dst,sep,token

}

macro leolcat dst,token& {

  local sep
  sep equ "\n",

  lprotocat dst,sep,token

}

; ---   *   ---   *   ---
; ^plus +++ ;>

macro pluscat dst,token& {

  local sep
  sep equ +

  protocat dst,sep,token

}

; ---   *   ---   *   ---
; cut A from A B C

macro protocut dst,sep,src& {

  local ok
  local eqsep

  dst   equ

  ok    equ 0
  eqsep equ =#sep

  match pat , eqsep \{

    ; A [sep] B
    match any pat next , src \\{
      src equ next
      dst equ any

      ok  equ 1

    \\}

    ; ^A [end]
    match =0 any , ok src \\{
      src equ
      dst equ any

      ok  equ 1

    \\}

    match =0 , ok \\{
      dst equ 0

    \\}

  \}

}

; ---   *   ---   *   ---
; comma ice

macro commacut dst,src& {

  local sep
  sep equ ,

  protocut dst,sep,src

}

; ---   *   ---   *   ---
; plus ++++ ice

macro pluscut dst,src& {

  local sep
  sep equ +

  protocut dst,sep,src

}

; ---   *   ---   *   ---
; uses a symbolic constant as a counter (!!)

macro symcnt sym,value=+1 {

  local cnt

  ; increment
  cnt equ sym
  cnt equ cnt#value

  sym equ cnt

}

; ---   *   ---   *   ---
; stringify and cat

macro strfcat a,b,c {
  a equ `a#`b#`c

}

macro stircat dst,a,b,c {
  dst equ a#`b#`c

}

macro tcat dst,a,b,c {
  dst equ a#b#c

}

; ---   *   ---   *   ---
; sets a to catted a,b,c
; ignores b if a is blank

macro stirr7 a,b,c {

  match any,a \{
    a equ any\#b#c

  \}

  match ,a \{
    a equ c

  \}

}

; ---   *   ---   *   ---
; cat b to beg of a

macro prefix a,b {
  a equ b#a

}

; ---   *   ---   *   ---
