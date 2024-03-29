; ---   *   ---   *   ---
; A9M VMEM
; Phantom buffers
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
  use '.inc' peso::cline
  use '.inc' A9M::vuint

library.import

; ---   *   ---   *   ---
; info

  TITLE     A9M.vmem

  VERSION   v0.01.8a
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; make new buff

macro vmem.new dst,ct& {

  ; get id
  local uid
  uid.new uid,A9M.vmem,npglobal

  ; ^gen buff
  match id , uid \{

    local args
    local ok

    args equ ct
    ok   equ 0

    ; write bytes to file
    match =fout EL , ct \\{

      local ext

      ext  equ EL
      args equ

      match e list , EL \\\{
        ext  equ e
        args equ list

      \\\}

      virtual at $00 as ext
      ok equ 1

    \\}

    ; ^regular buffer
    match =0 , ok \\{
      virtual at $00

    \\}

      id\#.base::
      id\#.size = 0

    end virtual

    ; ^write
    match any , args \\{
      vmem.segat id,id,any

    \\}

    ; give id
    dst equ id

  \}

}

; ---   *   ---   *   ---
; ^write segment

macro vmem.segat dst,atid,ct& {

  match par id , dst atid \{

    virtual par\#.base

      id\#.beg=par\#.size
      id\#.ptr=id\#.beg

      ; par != id, make new base ptr
      if ~(par\#.beg = id\#.beg)
        id\#.base::

      end if

      local ok
      ok equ 0

      ; ct from file?
      match =file args , ct \\{

        file args

        id\#.len = $-id\#.beg
        vuint.align id\#.size,id\#.len,$03

        ok equ 1

      \\}

      ; produce blank of size N?
      match =0 =blk size , ok ct \\{

        db size dup $00
        ok equ 1

        id\#.len  = $00
        id\#.size = size

      \\}

      ; ^paste passed string
      match =0 any , ok ct \\{

        db ct
        ok equ 1

        id\#.len = $-id\#.beg
        vuint.align id\#.size,id\#.len,$03

      \\}

      ; ^do nothing ;>
      match =0 , ok \\{
        id\#.len  = $00
        id\#.size = $00

      \\}

      ; ^pad to size with null
      id\#.pad = id\#.size-id\#.len
      db id\#.pad dup $00

    end virtual


    ; par != id, update par size
    if ~(par\#.beg = id\#.beg)
      par\#.size=par\#.size+id\#.size

    end if

  \}

}

; ---   *   ---   *   ---
; ^add new segment to existing

macro vmem.seg dst,par,ct& {

  ; get id
  local uid
  uid.new uid,A9M.vmem,npglobal

  ; ^use id for new segment
  vmem.segat par,uid,ct

  ; ^give segptr
  match id , uid \{
    dst equ id

  \}

}

; ---   *   ---   *   ---
; get handle to slice

macro vmem.view dst,src,addr,len {

  ; get id
  local uid
  uid.new uid,A9M.vmem,npglobal

  ; get offset into parent
  match par id , src uid \{

    ; base is just an alias
    id\#.base equ par\#.base

    ; ^addr is all that counts ;>
    id\#.beg = (par\#.beg)+(addr)
    id\#.ptr = $00

    ; note: no pad len on vmem view!
    id\#.len  = len
    id\#.size = len
    id\#.pad  = 0

  \}

  ; ^give ptr
  match id , uid \{
    dst equ id

  \}

}

; ---   *   ---   *   ---
; store at arbitrary offset

macro vmem.set dst,src,addr,sz=byte {

  match size id , sz dst \{

    local ok
    ok equ 0

    ; possibly multiple writes
    match =bounded , size \\{

      local bits
      bits=0

      vmem.xwalk_s 8,dst,addr,\
        vmem.STAP,src,bits

      ok equ 1

    \\}

    ; ^single write
    match =0 , ok \\{

      vmem.boundschk id,addr,size,\
        "set past end of vmem"

      local w0
      local w1
      w0 = (src) and sizebm.\#size
      w1 = id\#.beg+(addr)

      store size w0 at id\#.base:w1

    \\}

  \}

}

; ---   *   ---   *   ---
; ^load at arbitrary offset

macro vmem.get dst,src,addr,sz=byte {

  match size id , sz src \{

    local ok
    ok equ 0

    ; possibly multiple reads
    match =bounded , size \\{

      local bits
      bits=0

      vmem.xwalk_s 8,src,addr,\
        vmem.LDAP,dst,bits

      ok equ 1

    \\}

    ; ^single read
    match =0 , ok \\{
      vmem.boundschk id,addr,size,\
        "get past end of vmem"

      local w0
      w0 = id\#.beg+(addr)

      load dst size from id\#.base:w0

    \\}

  \}

}

; ---   *   ---   *   ---
; move range of buffer
; N bytes right or left

macro vmem.shift V,base,step,len {

  local dst
  local src

  dst = base
  src = base

  vmem.shift.inner V,base,step,len,\
    qword,dword,word,byte

}

; ---   *   ---   *   ---
; ^gutsof

macro vmem.shift.inner V,base,step,len,[key] {

  forward

    repeat len shr sizep2.#key

      base = base-sizeof.#key

      local w0

      vmem.get w0,V,base,key
      vmem.set V,w0,base+step,key

      len  = len-sizeof.#key

    end repeat

}

; ---   *   ---   *   ---
; dbout

macro vmem.prich src,get_real=0,header=0 {

  match id , src \{

    ; give seg name/addr
    display $0A,'BUFID ',\`id,$0A

    display 'SEGAT '
    hexsay  id\#.beg,$20
    out@nl  2


    ; give seg attrs
    display '  size '
    hexsay  id\#.size,$20
    out@nl

    display '  len  '
    hexsay  id\#.len,$20
    out@nl

    display '  pad  '
    hexsay  id\#.pad,$20
    out@nl

    display '  ptr  '
    hexsay  id\#.ptr,$20
    out@nl  2


    ; give buffer
    vmem.bprich src,get_real,header

  \}

}

; ---   *   ---   *   ---
; ^just the buffer

macro vmem.bprich src,get_real=0,header=0 {

  match id , src \{

    local len
    len = 0

    ; show real size?
    if get_real = 1
      len=id\#.size

    ; ^skip child segments
    else
      len=(id\#.len+id\#.pad)

    end if

    ; show raw : print
    local i
    i=0

    IO.colorsay=0
    repeat len shr $04

      ; add blank each cache line
      local j
      j=(i/2)

      if(~ (j mod $04))
        out@nl

      end if

      if(~(j mod $10))

        out@nl

        if header = 1

          display '$'
          hexsay  (i/2) shr 4,$10

          display ' <:'
          out@nl

        end if

        out@nl


      end if


      local w0
      local w1
      w0=0
      w1=0

      vmem.xldus  w0,src,(i+0)*8,8
      vmem.xldus  w1,src,(i+1)*8,8

      vmem.xwordsay w0,w1


      i   = i+2
      len = len-$10

    end repeat


    ; read bytes left
    i=i*8

    if len > 0

      local w0
      local w1

      w0 = 0
      w1 = 0

      out@nl
      if header = 1

        display '+'

        hexsay  len,$04
        out@nl

      end if

      while len > 0


        ; get next char
        local char
        char=0

        vmem.xldus char,src,i,1


        ; L qword if first 8 bytes
        if (%-1) < 8
          w0 = w0 or (char shl ((%-1)*8))

        ; ^then R qword from 9th onwards
        else
          w1 = w1 or (char shl ((%-9)*8))

        end if

        ; go next
        i   = i+1
        len = len-1

      end while


      ; prich it all
      vmem.xwordsay w0,w1


    end if
    out@nl 2

    IO.colorsay=1

  \}

}

; ---   *   ---   *   ---
; show 64 bits

macro vmem.qwordsay X {

  display   $20

  hexsay    X shr $20,$20
  display   $20

  hexsay    X,$20

}

; ---   *   ---   *   ---
; ^show 128 ;>

macro vmem.xwordsay X,Y {

  vmem.qwordsay X
  display ' :'

  vmem.qwordsay Y
  display ' | '

  humansay  X,$40
  humansay  Y,$40
  out@nl

}

; ---   *   ---   *   ---
; treat buffer as a string

macro vmem.stringsay src {

  match id , src \{

    repeat id\#.size

      local w0
      vmem.xld w0,id,(%-1),1

      display w0

    end repeat

  \}

}

; ---   *   ---   *   ---
; stringify symbol

macro symstirr dst,X {

  ; the easy way
  if (X > $1F) & (X < $7F)
    vmem.write dst,$27,X,$27

  ; the hard way...
  else

    ; get closest bit (L -> R)
    ; then flip that
    local bits
    bits = $40-($3F-(bsr X))

    ; round up to a multiple of 8 ;>
    vuint.align bits,bits,$03
    vmem.write  dst,$24


    ; convert X to hex notation
    ; 4-bits at a time
    repeat bits/4

      local elem

      elem = X shr (bits-(%*4))

      elem = elem and $F
      elem = elem + '0'

      if elem > '9'
        elem = elem+('A'-'9'-1)

      end if

      vmem.write dst,elem

    end repeat

  end if

}

; ---   *   ---   *   ---
; load extensions

library ARPATH '/forge/'

  use '.inc' A9M::vmem::xop
  use '.inc' A9M::vmem::bin
  use '.inc' A9M::valloc

library.import

; ---   *   ---   *   ---
