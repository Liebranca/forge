; ---   *   ---   *   ---
; A9M VMEM XOP
; Operator protos
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.vmem.xop

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define vmem.bops_list
  define vmem.uops_list

; ---   *   ---   *   ---
; template for operator wraps

macro vmem._op_proto buff,addr,size,fn,args& {

  ; varlis
  local dst
  dst equ vmem._op_proto.dst

  ; ^get current value
  vmem.get dst,buff,addr,size

  ; ^run op
  match any , args \{
    fn dst,args

  \}

  match , args \{
    fn dst

  \}


  ; ^overwrite
  vmem.set buff,dst,addr,size

}

; ---   *   ---   *   ---
; ^generator

macro vmem._gen_op MN,ct& {

  match mode name list , MN ct \{


    ; signature for unary op
    match =u , mode \\{

      ; register F name
      commacat vmem.uops_list,name

      ; execute passed code
      macro vmem.\#name\#.inner dst \\\{
        cline.filter list

      \\\}

      ; ^wraps
      macro vmem.\#name \
        buff,addr,size=byte \\\{

        vmem._op_proto buff,addr,size,\
          vmem.\#name\#.inner

      \\\}

    \\}


    ; ^binary
    match =b , mode \\{

      ; register F name
      commacat vmem.bops_list,name

      ; execute passed code
      macro vmem.\#name\#.inner dst,src \\\{
        cline.filter list

      \\\}

      ; ^wraps
      macro vmem.\#name \
        buff,src,addr,size=byte \\\{

        vmem._op_proto buff,addr,size,\
          vmem.\#name\#.inner,src

      \\\}

    \\}


  \}

}

; ---   *   ---   *   ---
; ^icebox

vmem._gen_op b xor   , dst=dst xor src
vmem._gen_op b or    , dst=dst or  src
vmem._gen_op b and   , dst=dst and src

vmem._gen_op u not   , dst=not dst
vmem._gen_op b xnor  , dst=not (dst xor src)
vmem._gen_op b nor   , dst=not (dst or  src)
vmem._gen_op b nand  , dst=not (dst and src)

vmem._gen_op b shr   , dst=dst shr src
vmem._gen_op b shl   , dst=dst shl src

vmem._gen_op b bsf   , dst=bsf src
vmem._gen_op b bsr   , dst=bsr src

vmem._gen_op b add   , dst=dst+src
vmem._gen_op u inc   , dst=dst+1
vmem._gen_op b sub   , dst=dst-src
vmem._gen_op u dec   , dst=dst-1

vmem._gen_op b mul   , dst=dst * src

; ---   *   ---   *   ---
