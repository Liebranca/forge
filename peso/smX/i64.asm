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

  VERSION   v0.00.9b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; load [?dst] <= [?src]

macro smX.i64.ld {

  ; unpack args
  local A
  local B

  smX.memarg A,ar
  smX.memarg B,br

  ; ^build op
  local op
  i64.mov op,A,B


  ; run through steps
  macro inner [step] \{

    forward

      ; match size to elem
      match UA UB , A B \\{
        UA\\#.set_size step
        UB\\#.set_size step

      \\}

      ; mov [?dst],[?src]
      smX.op.batrun run,op

      ; ^go next
      match UA UB , A B \\{
        UA\\#.add_off sizeof.\#step
        UB\\#.add_off sizeof.\#step

      \\}

  \}

  ; ^exec
  match list , smX.REG.cr \{
    inner list

  \}

  ; cleanup
  match %O UA UB , op A B \{

    smX.op.odel %O

    smX.mem.free UA
    smX.mem.free UB

  \}

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
