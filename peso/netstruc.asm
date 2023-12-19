; ---   *   ---   *   ---
; PESO NETSTRUC
; A fisherman's tool
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
  use '.hed' peso::socket
  use '.hed' peso::shmem
  use '.hed' peso::env

library.import

; ---   *   ---   *   ---
; GBL

  List.new server.icebox
  List.new server.icecode

; ---   *   ---   *   ---
; base struc (client beqs)

reg.new netstruc,public
  my .sock dq $00
  my .mem  dq $00

reg.end

; ---   *   ---   *   ---
; cstruc

EXESEG

proc.new netstruc.alloc
proc.lis netstruc dst rdi

  proc.enter

  ; make container
  push @dst
  mov  rdi,rsi

  call alloc

  ; ^back
  pop @dst
  mov qword [@dst],rax
  mov rbx,qword [@dst]

  ; ^make socket
  call socket.unix.new
  mov  qword [rbx+netstruc.sock],rax


  ; cleanup and leave
  proc.leave
  ret

; ---   *   ---   *   ---
; cstruc generator for beqers

macro netstruc.icemaker type,VN,size,path& {

  ; ensure environs are fetched
  if ~ defined AR.nestruc.NIT
    define AR.nestruc.NIT 1
    call   AR.nestruc.nit

  end if


  ; ^F proper
  local dst
  local name
  local vflag
  local F

  dst   equ
  name  equ VN
  vflag equ

  F     equ hier.cproc

  ; ^unroll args
  match V N , VN \{
    name  equ N
    vflag equ V

  \}


  ; ^generate code
  match any,name \{

    ; promise ram
    macro any\#._gen_addr \\{
      any\#._addr dq $00

    \\}


    ; make nit
    macro any\#._gen_cstruc \\{

      ; set visibility
      MAM.sym_vflag dst,any\#.ice,vflag
      any\#.ice=$

      ; return existing
      mov  rax,qword [any\#._addr]
      test rax,rax

      jnz  @f


      ; setup frame
      push rbp
      mov  rbp,rsp
      sub  rsp,$10

      ; ^save strings to stack
      string.fcat qword [rbp-$08],\
        path,\`#any

      string.fcat qword [rbp-$10],\
        path,\`#any\#\`.mem


      ; make ice
      mov  rdi,qword [rbp-$08]
      mov  rsi,qword [rbp-$10]
      mov  rdx,size

      call type#.new
      mov  qword [any\#._addr],rax


      ; cleanup and give
      leave
      @@:ret

    \\}


    ; ^make del
    macro any\#._gen_dstruc \\{

      ; set visibility
      MAM.sym_vflag dst,any\#.free,vflag
      any\#.free=$

      ; already fred
      mov  rax,qword [any\#._addr]
      test rax,rax

      jz   @f


      ; ^free ice
      mov  rdi,rax

      call type#.del
      mov  qword [any\#._addr],$00


      ; cleanup and give
      @@:ret

    \\}


    ; ^promise exe
    macro any\#._gen_proc \\{

      hier.cproc equ F

      any\#._gen_cstruc
      any\#._gen_dstruc

      restore hier.cproc

    \\}

    server.icebox.push  any\#._gen_addr
    server.icecode.push any\#._gen_proc

    call any\#.ice

  \}

}

; ---   *   ---   *   ---
; get common environs

proc.new AR.netstruc.nit,public
proc.stk env.lkp env0

  proc.enter

  lea rdi,[@env0]
  env.getv ARPATH

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; footer

macro netstruc._gen_footer {

  match any , netstruc.icebox.m_list \{

    RAMSEG
    server.icebox

    EXESEG
    server.icecode

  \}

  netstruc.icebox.clear
  netstruc.icecode.clear

}

MAM.xfoot netstruc

; ---   *   ---   *   ---
