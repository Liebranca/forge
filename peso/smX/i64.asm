; ---   *   ---   *   ---
; PESO SMX I64
; Old school registers
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
  use '.inc' peso::smX::op
  use '.inc' peso::smX::scope

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.smX.i64

  VERSION   v0.01.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; iface wraps for smX.mem.onew

macro smX.alloc {

  ; unpack args
  local rX
  mach.marg rX,ar

  ; ^call cstruc
  local uid
  OBJ.new uid,smX.mem,rX

  ; ^give
  match %M , uid \{
    mach.mov ar,%M

  \}

}

; ---   *   ---   *   ---
; ^undo

macro smX.free {

  ; unpack args
  local rX
  mach.marg rX,ar

  ; ^call dstruc
  match %M , rX \{
    %M\#.del

  \}

}

; ---   *   ---   *   ---
; r <= [m]

macro smX.ld.proto dst,chunk,ali,_nullarg& {

  local step

  dst   equ
  step  equ

  ; generate array of sized movs
  smX.bat_size_adv step,chunk

  ; ^walk
  match list , step \{
    smX.bat_sized_mov dst,ali,1,list

  \}

}

; ---   *   ---   *   ---
; [m] <= r

macro smX.st.proto dst,chunk,ali,src& {

  dst equ

  ; walk passed mems
  match list , src \{
    smX.bat_sized_mov dst,ali,0,list

  \}

}

; ---   *   ---   *   ---
; advance N steps by size

macro smX.size_adv dst,chunk,key {

  rept ((chunk) shr sizep2.#key) \{

    commacat dst,key
    chunk equ chunk - sizeof.#key

  \}

}

; ---   *   ---   *   ---
; ^ALL the sizes

macro smX.bat_size_adv dst,chunk {

  macro inner [key] \{
    smX.size_adv dst,chunk,key

  \}

  inner yword,xword,qword,dword,word,byte

}

; ---   *   ---   *   ---
; give [ins=>reg] array
; where ins eq sized mov
;
; IF need_alloc, arg eq mem size
; ELSE, arg eq memice

macro smX.bat_sized_mov dst,ali,need_alloc,[arg] {

  forward

    ; get dst mem
    local mem

    ; ^alloc new
    match =1 , need_alloc \{
      smX.mem.from_size mem,arg

    \}

    ; ^mem passed
    match =0 , need_alloc \{
      mem equ arg

    \}


    ; gen mov variant
    match %M0 , mem \{

      ; ^get ins
      local ins
      smX.sized_mov ins,%M0\#.size,ali

      ; ^write out
      commacat dst,mem ins

    \}

}

; ---   *   ---   *   ---
; multi-step read/write

macro smX.multi_rw rX,mode,src& {

  local chunk
  local ali

  local expr
  local out

  ; unpack args
  mach.marg chunk,ar
  mach.marg ali,cr


  ; get dst and src regs
  smX.#mode#.proto expr,chunk,ali,src

  ; ^save src
  out equ

  match %M1 list , rX expr \{
    smX.bat_mov_paste out,mode,%M1,list

  \}


  ; give back regs
  match list , out \{
    mach.mov ar,list

  \}

}

; ---   *   ---   *   ---
; ^paste generated

macro smX.bat_mov_paste out,mode,%M1,[expr] {

  ; make buff
  common

    cline.new

    out equ
    commacat out,%M1


  ; ^save expr to buff
  forward match %M0 ins , expr \{


    ; ^r <= [m]
    match =ld , mode \\{

      cline ins \
        %M0\#.loc,\
        %M0\#.size [%M1#.xloc+%M1#.off]

    \\}


    ; ^[m] <= r
    match =st , mode \\{

      cline ins \
        %M0\#.size [%M1#.xloc+%M1#.off],\
        %M0\#.loc

    \\}


    ; save gotten reg
    commacat out,%M0

    ; ^go next on known
    match size , %M0\#.size \\{
      %M1#.add_off sizeof.\\#size

    \\}

  \}


  ; ^flush buff
  common
    cline.commit

}

; ---   *   ---   *   ---
; ^make rw proto variations

macro smX.ld {

  local rX
  mach.marg rX,br

  smX.multi_rw rX,ld

}

macro smX.st {

  local rX
  local src

  mach.marg rX,br
  mach.marg src,dr
  mach.mmov src,dr

  smX.multi_rw rX,st,src

}

; ---   *   ---   *   ---
; ^combo

macro smX.cpy {

  ; unpack args
  local dst
  local src
  local size
  local ali

  mach.marg dst,ar
  mach.marg src,br
  mach.marg size,cr
  mach.marg ali,dr


  ; get src mem
  mach.mov  ar,qword m=src
  mach.call alloc

  mach.mmov src,ar

  ; ^read to regs
  mach.mov  ar,size
  mach.mov  br,src
  mach.mov  cr,ali

  mach.call ld
  mach.rmov dr,ar


  ; get dst mem
  mach.mov  ar,qword m=dst
  mach.call alloc

  mach.mmov dst,ar

  ; ^[dst] <= [src]
  mach.mov  ar,size
  mach.mov  br,dst
  mach.mov  cr,ali

  mach.call st


  ; release dst,src
  mach.mov  ar,dst
  mach.call free

  mach.mov  ar,src
  mach.call free

}

; ---   *   ---   *   ---
; clear [?A]

macro smX.i64.cl A {

  ; clear size ptr A
  match =m , A#.mode \{
    cline mov A#.size [A#.xloc+A#.off],$00

  \}

  ; clear A
  match =r , A#.mode \{

    ; clear whole register
    match =1 , A#.repl \\{
      cline xor A#.xloc,A#.xloc

    \\}

    ; ^clear only sized part (byte or word)
    match =0 , A#.repl \\{
      cline xor A#.loc,A#.loc

    \\}

  \}

}

; ---   *   ---   *   ---
; generate X-sized op

macro smX.i64.walk op,size,args& {

  local step
  step equ sizeof.#size

  ; paste op [args]
  op size,step,args

  smX.paste_footer op

}

; ---   *   ---   *   ---
; ^table generator ice

macro smX.i64.tab op,eob,args& {

  ; list possible sizes
  local entry
  local entry.len

  List.from entry,entry.len,\
    byte,word,dword,qword

  ; ^make elem for each
  smX.gen_tab \
    smX.i64.walk,byte,\
    entry,entry.len,\
    eob,smX.i64.#op,args

}

; ---   *   ---   *   ---
