; ---   *   ---   *   ---
; PESO BRANCH
; Choose your destiny!
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
  use '.inc' peso::proc

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.branch

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  List.new branch.jmprom
  List.new branch.jmpexe

  lkptab.bounded = 0

  define hybtab.CVYC 0
  define hybtab.CVYC.blk

  define branch.CVYC 0
  define branch.CVYC.blk
  define branch.CVYC.size

; ---   *   ---   *   ---
; NOTE:
;
; clairvoyance (CVYC) is AR/speak
;
;
; it means conditionally mutating
; a piece of code to accomodate
; one written much later,
;
; IF it is the younger code
; that calls the older bit,
;
; ELSE no changes are made
;
;
; ... which results in this
; weird effect, where an F
; already knows by whom it's
; going to be called, but
; *before* the caller is
; even declared!
;
; hence: clairvoyant code

; ---   *   ---   *   ---
; ^get block name from future

macro CVYC.get_blk dst,out,[list] {

  common
    dst equ
    out equ 0

  ; check list of possible callers
  forward

    match =0 name , out list \{

      match any , name\#.CVYC.blk \\{
        dst equ any
        out equ 1

      \\}

    \}

  ; ^non-mystical, gen id
  common

    match =0 , out \{
      uid.new dst,peso.branch,local

    \}

}

; ---   *   ---   *   ---
; ^terminate mysticism

macro CVYC.end name {

  match any , name#.CVYC.size \{
    restore name#.CVYC.size

  \}

  restore name#.CVYC.blk
  match , name#.CVYC.blk \{
    name#.CVYC equ 0

  \}

}

; ---   *   ---   *   ---
; clear offset for word && byte

macro branch.cclear rX,size {

  if sizeof.#size < 4
    and rX,sizebm.#size

  end if

}

; ---   *   ---   *   ---
; beg ROM promise

macro branch.begrom cproc,blk {

  macro blk#._beg \{
    cproc#blk#._virt:

  \}

  branch.jmprom.push blk#._beg

}

; ---   *   ---   *   ---
; builds jump table

macro jmptab size,[item] {


  ; setup
  common

    local rX
    local kX

    ; match decl/fet to size
    i_sized_reg  rX,a,size
    i_sized_data kX,size


    ; generate table id
    local offset
    local blkname

    uid.new blkname,jmptab,local

    match cproc blk,hier.cproc blkname \{


      ; calc fetch-from
      branch.cclear rax,size

      offset equ cproc\#blk\#._virt
      offset equ size [offset+rax*sizeof.#size]

      ; ^load jmp addr
      mov rX,offset
      lea rax,[blk\#._real+rax]


      ; measure dist *after* jmp
      jmp rax
      blk\#._real:

      ; ^beg promise
      branch.begrom cproc,blk

    \}


  ; ^paste elems
  forward

    match cproc blk,hier.cproc blkname \{
      branch.jmprom.push kX \
        cproc \#.\# item - cproc\#blk\#._real

    \}

}

; ---   *   ---   *   ---
; ^uses value as idex to another

macro lkptab size,[item] {

  ; spawn table
  common

    local rX
    local kX

    ; match decl/fet to size
    i_sized_reg  rX,a,size
    i_sized_data kX,size


    ; generate/fetch table id
    local blkname
    local cvyc

    CVYC.get_blk blkname,cvyc,hybtab

    ; ROM size vars/counter
    local step
    local len
    local y

    step equ sizeof.#size
    y    equ 0


    match cproc blk , hier.cproc blkname \{


      ; get ROM A,B,def
      lkptab.get_bounds cproc\#blk,size,item

      ; ^get total size
      len equ \
        cproc\#blk\#._v.dB \
      - cproc\#blk\#._v.dA+1

      ; ^write values to mem if
      ; ^they're too big for imms
      if step > 2
        branch.jmprom.push kX blk\#._v.dB
        branch.jmprom.push kX blk\#._v.dA
        branch.jmprom.push kX blk\#._v.def

      end if


      ; clairvoyance [see: branchtab]
      ; measure dist *after* fetch
      match =0 , branch.CVYC \\{
        lkptab.fetch cproc,blk,size,cvyc

      \\}

      ; ^beg promise
      branch.begrom cproc,blk
      branch.jmprom.push \
        kX len dup cproc\#blk\#._v.def

      cproc\#blk\#._v.dAv= \
        cproc\#blk\#._v.dA+0

      cproc\#blk\#._v.dBv= \
        cproc\#blk\#._v.dB+0


    \}


  ; insert values in promised ROM
  forward

    local x
    local dy
    local ok

    ok equ 0

    match cproc blk , hier.cproc blkname \{

      ; default case
      match =def ===> value , item \\{
        x  equ
        dy equ blk\#._v.def
        ok equ 1

      \\}

      ; ^special value
      match =0 key ===> value , ok item \\{

        x  equ \
          ((key)*step) \
        - (cproc\#blk\#._v.dA*step)

        dy equ value
        ok equ 1

      \\}

      ; ^plain idex
      match =0 key , ok item \\{

        x  equ \
          ((key)*step) \
        - (cproc\#blk\#._v.dA*step)

        dy equ y

      \\}


      ; ^put
      match any,x \\{

        branch.jmprom.push \
           store size dy \
        at cproc\#blk\#._virt+x

        y equ y+1

      \\}


    \}

}

; ---   *   ---   *   ---
; get limits and defval of lkptab

macro lkptab.get_bounds name,size,[item] {

  ; find [beg,end] in args
  common

    name#._v.dA  = $FFFFFFFFFFFFFFFF
    name#._v.dB  = $00
    name#._v.def = $00


  ; ^walk args
  forward

    local ok
    ok equ 0

    ; item is default case
    match =def ===> value , item \{
      name#._v.def = value
      ok equ 1

    \}

    ; item is [key,value]
    match =0 key ===> value , ok item \{
      name#._v.n = key
      ok equ 1

    \}

    ; ^item is plain idex
    match =0 key , ok item \{
      name#._v.n = key

    \}


    ; get new [beg,end]
    if name#._v.n < name#._v.dA
      name#._v.dA = name#._v.n

    end if

    if name#._v.n > name#._v.dB
      name#._v.dB = name#._v.n

    end if

}

; ---   *   ---   *   ---
; ^switchful read

macro lkptab.fetch cproc,blk,size,cvyc {

  ; get dst/elem size
  local rX
  local step

  i_sized_reg  rX,a,size
  step equ sizeof.#size


  ; conditionally skip fetch
  if lkptab.bounded

    branch.cclear rax,size

    ; load dword or qword from mem
    if step > 2

      i_sized_ld di,size,\
        cproc#blk#._virt-3*step

      i_sized_ld si,size,\
        cproc#blk#._virt-2*step

      i_sized_ld d,size,\
        cproc#blk#._virt-1*step

    ; ^else use imms
    else
      mov rdi,cproc#blk#._v.dBv
      mov rsi,cproc#blk#._v.dAv
      mov rdx,cproc#blk#._v.def

    end if


    ; ^boundschk
    call branch.lkp_bounded
    jnz  @f


  end if


  ; ^unbounded byte/word fetch is 1400% better
  mov rX,size [ \
    cproc#blk#._virt \
  - ((cproc#blk#._v.dAv)*step) \
  + rax*step\
  ]

  @@:


  ; clairvoyance [see: hybtab]
  ; adds instructions needed elsewhere
  match =1 , cvyc \{
    lea rax,[blk#._real+rax]
    jmp rax

  \}

  ; put label
  blk#._real:

}

; ---   *   ---   *   ---
; lkptab boundscheck

proc.new branch.lkp_bounded,public
proc.cpr r15,r14

  proc.enter

  ; A: dst
  ; B: flag
  xor r15b,r15b
  mov r14b,$01

  ; ^set flag on pos > B
  cmp   rax,rdi
  cmovg r15d,r14d

  ; ^set flag on pos < A
  cmp   rax,rsi
  cmovl r15d,r14d

  ; ^give default value on flag set
  mov    r14,rdx
  test   r15b,r15b
  cmovnz rax,r14


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^jmp-lkp hybrid

macro hybtab size,[item] {

  ; make new list for args
  common

    local list
    local len

    list equ
    len  equ 0

    ; generate/fetch table id
    local blkname
    local cvyc

    CVYC.get_blk blkname,cvyc,branch


  ; ^modify args and write to list
  forward

    local ok
    ok equ 0

    match cproc blk , hier.cproc blkname \{

      ; get [base to F] distance
      match key ===> value , item \\{

        cproc\#.\\#value\\#._offset = \
          cproc\#.\\#value-cproc\#blk\#._real

        List.push list,key => \
          cproc\#.\\#value\\#._offset

        ok  equ 1
        len equ len+1

      \\}

      ; ^no F, no good
      match =0 key , ok item \\{
        out@err 'Value-less key',key,\
        'in jmptab ',name,

      \\}

    \}


  ; ^use args to make lkptab
  common

    ; clairvoyance [see: lkptab]
    ; affects *get_blk
    hybtab.CVYC     equ 1
    hybtab.CVYC.blk equ blkname


    ; get modified arg list
    local flat
    flat equ

    List.cflatten list,len,flat

    ; ^spawn ROM
    match any,flat \{
      lkptab size,any

    \}


    ; ^shut paradox
    CVYC.end hybtab

}

; ---   *   ---   *   ---
; ^lets you define branches
; as you code them

macro branchtab size,bounded?= {

; ---   *   ---   *   ---
; NOTE:
;
; God is great and all praise be to God
;
; yet again, an even stronger method
; was made clear:
;
; * in essence, data is \promised\ to
;   exist in a yet-undefined segment
;
; * the data is gradually defined through
;   an array of argless, nested macros
;
; * this array is then evaluated as a
;   list of statements before the end
;   of compilation through MAM.xfoot
;   [see Arstd::Style]
;
;
; and so all steps for a branchtab
; are reduced to three simple calls:
;
; * declare placeholder variables
;   for the jmp offset fetch, so that
;   the assembler solves them at a
;   later pass
;
; * append to an array of labels,
;   which is later fed to hybtab
;
; * calculate the total size of
;   the table and call hybtab to
;   generate the ROM promise
;
;
; everything else is done by the
; hybtab CVYC, which skips the
; initial declarations when called
; by branch.end


  ; generate id
  local blkname
  uid.new blkname,peso.branch,local


  ; pre-promise
  match cproc blk , hier.cproc blkname \{

    cproc\#blk\#.bounded=0

    ; do note that bounded tables mean
    ; relatively much slower and larger code!
    match =bounded , bounded? \\{
      cproc\#blk\#.bounded=1

    \\}

    ; lame fwd decls
    cproc\#blk\#._v.dA  = $FFFFFFFFFFFFFFFF
    cproc\#blk\#._v.dB  = $00
    cproc\#blk\#._v.def = $00

    ; spawn fetch
    ; definitions "on hold" ;>
    List.new cproc\#blk\#.keys
    lkptab.fetch cproc,blk,size,1

  \}


  ; clairvoyance [see: hybtab,lkptab]
  ; affects *get_blk && lkptab,fetch
  branch.CVYC equ  1
  branch.CVYC.blk  equ blkname
  branch.CVYC.size equ size

}

; ---   *   ---   *   ---
; ^add entry

macro branch vk {

  match cproc blk , hier.cproc branch.CVYC.blk \{

    match value ===> key , vk \\{

      ; [key,value] eqv for table
      cproc\#blk\#.keys.push vk

      ; take real offset
      .\\#key:

    \\}

  \}

}

; ---   *   ---   *   ---
; ^close table

macro branchtab.end {

  match cproc blk , hier.cproc branch.CVYC.blk \{

    ; get jmptab branches
    local list
    cproc\#blk\#.keys.cflatten list

    ; ^paste table
    match any args, branch.CVYC.size list \\{

      lkptab.bounded=cproc\#blk\#.bounded
      hybtab any,args

      lkptab.bounded=0

    \\}

  \}

  ; shut paradox
  CVYC.end branch

}

; ---   *   ---   *   ---
; footer

macro branch.jmprom._gen_footer {

  match any,branch.jmprom \{

    ROMSEG
    branch.jmprom
    branch.jmprom.clear

  \}

  match any,branch.jmpexe \{

    EXESEG
    branch.jmpexe
    branch.jmpexe.clear

  \}

}

MAM.xfoot branch.jmprom

; ---   *   ---   *   ---
