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
  use '.inc' peso::swan
  use '.asm' peso::smX::common

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.smX.i64

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

  define i64.REGISTERS \
    a,b,c,d,\
    di,si,r8,r9,\
    r10,r11,r12,r13,\
    r14,r15

; ---   *   ---   *   ---
; GBL

  define i64.cscope

; ---   *   ---   *   ---
; ctx struc

swan.new i64.scope

swan.attr avail,
swan.attr avail.len,0

swan.attr unav,
swan.attr unav.len,0

swan.attr mems,
swan.attr mems.len,0

swan.end

; ---   *   ---   *   ---
; ^cstruc

macro smX.i64.open_scope dst,list& {

  local v_avail
  local v_avail.len

  local v_unav
  local v_unav.len

  v_avail     equ
  v_avail.len equ 0

  v_unav      equ
  v_unav.len  equ 0


  ; build list of avail registers
  macro inner [rX] \{

    forward

      ; get rX is used
      local ok
      tokin ok,rX,list

      ; ^push to unav if so
      match =1 , ok \\{
        List.push v_unav,rX
        v_unav.len equ v_unav.len+1

      \\}

      ; ^else push to avail
      match =0 , ok \\{
        List.push v_avail,rX
        v_avail.len equ v_avail.len+1

      \\}

  \}


  ; ^run
  match any , i64.REGISTERS \{
    inner any

  \}

  ; make ice
  i64.scope.new dst,\
    avail     => v_avail,\
    avail.len => v_avail.len,\
    unav      => v_unav,\
    unav.len  => v_unav.len,\

  dst#.mems equ
  i64.cscope equ dst

}

; ---   *   ---   *   ---
; ^dstruc

macro smX.i64.close_scope {

  match any , i64.cscope \{

    ; ^release mems
    rept any\#.mems.len \\{
      smX.i64.free_mem

    \\}

    ; release container
    any\#.del

  \}

  restore i64.cscope

}

; ---   *   ---   *   ---
; get unused register

macro smX.i64.get_mem dst,args {

  match scp , i64.cscope \{

    ; get registers left
    local have
    have equ

    rept scp\#.avail.len \\{have equ 1\\}


    ; ^got scratch
    match any,have \\{

      local name

      List.shift scp\#.avail,name
      scp\#.avail.len equ scp\#.avail.len-1

      smX.i64.new_mem dst,args+name

      List.push scp\#.mems,dst
      scp\#.mems.len equ scp\#.mems.len+1

    \\}


    ; ^TODO: none avail, move to stack
    match , have \\{\\}

  \}

}

; ---   *   ---   *   ---
; ^release N mems from top

macro smX.i64.free_mem {

  match scp , i64.cscope \{

    local rX
    rX equ

    List.pop scp\#.mems,rX
    scp\#.mems.len equ scp\#.mems.len-1

    match any , rX \\{
      List.push scp\#.avail,any\\#.name
      scp\#.avail.len equ scp\#.avail.len+1

      any\\#.del

    \\}

  \}

}

; ---   *   ---   *   ---
; elem struc

swan.new i64.mem

swan.attr name,a
swan.attr loc,al
swan.attr xloc,rax
swan.attr size,byte
swan.attr off,0
swan.attr mode,r

swan.end

; ---   *   ---   *   ---
; ^cstruc

macro smX.i64.new_mem dst,args {

  ; make ice
  match sz md =+ rX , args \{

    i64.mem.new dst,\
      name=>rX,\
      size=>sz,\
      mode=>md

    i64.mem.set_loc dst,rX

  \}

  ; ^lis macros
  swan.batlis dst,i64.mem,\
    set_size,set_loc,\
    set_mode,set_off,\
    add_off

}

; ---   *   ---   *   ---
; modifies size-variant of
; used register

macro i64.mem.set_size dst,sz {

  ; get sized variant
  local rX
  match loc , dst#.name \{
    i_sized_reg rX,loc,sz

  \}

  ; ^write field
  dst#.loc.set rX
  dst#.size.set sz

}

; ---   *   ---   *   ---
; ^modifies used register

macro i64.mem.set_loc dst,name {

  ; get largest (used for deref)
  local rX
  i_sized_reg rX,name,qword

  ; ^write field
  dst#.xloc.set rX
  dst#.name.set name

  ; ^update ice
  match sz,dst#.size \{
    i64.mem.set_size dst,sz

  \}

}

; ---   *   ---   *   ---
; ^mere wraps

macro i64.mem.set_mode dst,value {
  dst#.mode.set value

}

macro i64.mem.set_off dst,value {
  dst#.off.set value

}

; ---   *   ---   *   ---
; ^adds to current offset

macro i64.mem.add_off dst,value {

  match off , dst#.off \{
    dst#.off.set off+(value)

  \}

}

; ---   *   ---   *   ---
; load [?dst],[?src]

macro smX.i64.ld A,B,repl?= {

  local src
  local tmp

  src equ B
  tmp equ

  ; need deref?
  match =m , B#.mode \{

    ; mem to mem, use tmp
    match =m , A#.mode \\{

      local name

      ; ^overwrite src,[src]
      match =1 bname , repl? B#.name \\\{
        mov B#.loc,B#.size [B#.xloc+B#.off]

      \\\}

      ; ^get new reg
      match , repl? \\\{

        smX.i64.get_mem C,B#.size r
        mov C.loc,B#.size [B#.xloc+B#.off]

        src equ C
        tmp equ C

      \\\}

    \\}

    ; ^no tmp needed ;>
    match =r , A#.mode \\{
      mov A#.loc,B#.size [rX+B#.off]
      src equ

    \\}

  \}


  ; ^copy dst,src
  match any,src \{
    smX.i64.ld_switch A,any

  \}


  ; cleanup tmp
  match any,tmp \{
    smX.i64.free_mem

  \}

}

; ---   *   ---   *   ---
; ^pick op based on mode

macro smX.i64.ld_switch A,src {

  ; [dst] <= src
  match =m , A#.mode \{
    mov A#.size [A#.xloc+A#.off],src#.loc

  \}

  ; ^dst <= src
  match =r , A#.mode \{
    mov A#.loc,src#.loc

  \}

}

; ---   *   ---   *   ---
; clear [A]

macro smX.i64.clm size,step,_nullarg& {
  mov size [rdi],$00

}

; ---   *   ---   *   ---
; clear A

macro smX.i64.clr size,step,_nullarg& {
  xor rdi,rdi

}

; ---   *   ---   *   ---
; ^[A] eq [B]

macro smX.i64.eqmm size,step,_nullarg& {

  ; get src
  local rX
  i_sized_reg rX,si,size

  ; get dst
  local rY
  i_sized_reg rY,di,size

  ; get scratch
  local rZ
  i_sized_reg rZ,b,size


  ; deref
  mov rX,size [rsi]
  mov rY,size [rdi]

  ; ^compare values
  mov rZ,rX
  xor rZ,rY

  ; ^go next
  add rdi,step
  add rsi,step
  sub r8d,step

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
