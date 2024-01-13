; ---   *   ---   *   ---
; F1
; Macro f*cktory
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     f1

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define    f1.OUTBUF
  vmem.new  f1.OUTBUF,blk $00

  define    f1.ident.lvl  0
  define    f1.queue

  define    f1.cexpr.lvl  0
  define    f1.cexpr.idex 0
  define    f1.cexpr.type CLOSED

  define    f1.cexpr.idex._back
  define    f1.cexpr.type._back

  f1.debug = 0

; ---   *   ---   *   ---
; cat to output queue

macro f1.cout [item] {

  forward

    local ok
    ok equ 0

    match =ptr buf , item \{
      f1.commit
      f1.queue equ item

      f1.commit

      ok equ 1

    \}

    match =0 , ok \{
      commacat f1.queue,item

    \}

}

; ---   *   ---   *   ---
; paste value full ident*2

macro f1.ident value=$20 {

  local N
  N equ (f1.ident.lvl+f1.cexpr.lvl)*2

  rept N \{f1.cout value\}

}

; ---   *   ---   *   ---
; ident+1

macro f1.identp1 value=$20 {
  rept f1.ident.lvl+1 \{f1.cout value\}

}

; ---   *   ---   *   ---
; *just* ident

macro f1.ident1 value=$20 {
  rept f1.ident.lvl \{f1.cout value\}

}

; ---   *   ---   *   ---
; ident-1; none if 0

macro f1.identm1 value=$20 {

  local ok
  ok equ 0

  rept 1 cnt:f1.ident.lvl \{
    f1.ident.lvl equ cnt

  \}

  match =0 , f1.ident.lvl \{
    ok equ 1

  \}

  match =0 , ok \{
    rept f1.ident.lvl-1 \\{f1.cout value\\}

  \}

}

; ---   *   ---   *   ---
; byte escaped ident times

macro f1.scap value {
  f1.ident1 $5C
  f1.cout   value

}

; ---   *   ---   *   ---
; ident-1

macro f1.scapm1 value {
  f1.identm1 $5C
  f1.cout    value

}

; ---   *   ---   *   ---
; begins/ends a line

macro f1.line ct& {

  f1.cout  $0A
  f1.ident

  match any , ct \{f1.cout ct\}

}

; ---   *   ---   *   ---
; open/close curly

macro f1.cbeg {

  f1.ident.lvl equ (f1.ident.lvl)+1

  f1.cout   $20
  f1.scapm1 $7B

}

macro f1.cend {

  f1.cout $0A
  f1.ident.lvl equ (f1.ident.lvl)-1

  f1.line
  f1.scap $7D

}

; ---   *   ---   *   ---
; make local

macro f1.local name,value='' {

  local ok
  ok equ 0

  f1.line 'local '#`name
  f1.line `name,' equ ',`value,$0A

}

; ---   *   ---   *   ---
; stringify vars

macro f1.stirr name {

  f1.scapm1 $60
  f1.cout   `name

}

; ---   *   ---   *   ---
; ^cat em

macro f1.cat [name] {

  forward
    f1.scapm1 $23
    f1.cout   `name

}

; ---   *   ---   *   ---
; both!

macro f1.stirrcat [name] {

  forward
    f1.scapm1 $23
    f1.scapm1 $60
    f1.cout   `name

}

; ---   *   ---   *   ---
; lazy way to stirr and out tokens ;>

macro f1.stirrout catchar,src& {

  local rem

  match any , src \{
    rem equ any

  \}


  rept $10 \{

    local ok
    ok equ 0

    match  , rem \\{
      ok equ 1

    \\}

    ; =V (continued...)
    match =0 == any next , ok rem \\{

      f1.cout '='\\#\\`any,catchar

      rem equ next
      ok  equ 1

    \\}

    ; =V (end)
    match =0 == any , ok rem \\{

      f1.cout '='\\#\\`any,catchar

      rem equ
      ok  equ 1

    \\}


    ; sym (continued)
    match =0 any next , ok rem \\{

      f1.cout \\`any,catchar

      rem equ next
      ok  equ 1

    \\}

    ; ^sym (end)
    match =0 any , ok rem \\{
      f1.cout \\`any,catchar
      rem equ

    \\}

  \}

}

; ---   *   ---   *   ---
; dbout a var (for the generated code! ;>)

macro f1.vsay name {
  f1.line  'display '
  f1.stirr name

}

; ---   *   ---   *   ---
; begs a macro block

macro f1.macro fa?,[arg] {

  ; write "macro name "
  common

    local fa
    local name
    local cnt

    fa   equ
    name equ fa?

    cnt  equ 0

    ; have first arg?
    match any arg0 , fa? \{
      fa   equ arg0
      name equ any

    \}

    ; ^put macro [name]
    match any , name \{
      f1.line 'macro '\#\`any,$20

    \}

    ; ^put (arg0...)?
    match any , fa \{
      f1.cout \`any

    \}


  ; put any other arguments!
  forward

    f1.cout     ','
    f1.stirrout $00,arg

    cnt equ 1

  ; ^open curly
  common
    f1.cbeg
    f1.cout $0A

}

; ---   *   ---   *   ---
; ^same for match

macro f1.match expr& {


  f1.line 'match '

  match dst =<=: src , expr \{

    f1.stirrout $20,dst
    f1.cout     ', '

    f1.stirrout $20,src

  \}


  f1.cbeg

}

; ---   *   ---   *   ---
; writes queue to out buffer

macro f1.commit {

  match any , f1.queue \{

    vmem.write f1.OUTBUF,f1.queue
    f1.queue equ

    if f1.debug = 1
      display $0A,'f1:',$0A
      f1.prich

    end if

  \}

}

; ---   *   ---   *   ---
; put to file

macro f1.to_disk ext=inc {

  local dst

  vmem.owc   dst,'.'#`ext,blk $00
  vmem.write dst,ptr f1.OUTBUF

}

; ---   *   ---   *   ---
; dbout

macro f1.prich {
  vmem.stringsay f1.OUTBUF

}

; ---   *   ---   *   ---
