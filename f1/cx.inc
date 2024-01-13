; ---   *   ---   *   ---
; F1 CX
; Makes switches!
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     f1.cx

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; line on a conditional

macro f1.cxline ct& {

  local N
  N equ (f1.ident.lvl+(f1.cexpr.lvl-1))*2

  f1.cout $0A

  rept N \{f1.cout $20\}
  match any , ct \{f1.cout ct\}

}

; ---   *   ---   *   ---
; begin conditional block

macro f1.cxbeg type {

  f1.cout $0A

  f1.cexpr.type._back equ f1.cexpr.type
  f1.cexpr.idex._back equ f1.cexpr.idex

  f1.cexpr.type equ type
  f1.cexpr.idex equ 0

  f1.cexpr.lvl  equ (f1.cexpr.lvl)+1

}

; ---   *   ---   *   ---
; ^endof

macro f1.cxend {

  local ok
  ok equ 0

  match =OPEN , f1.cexpr.type \{
    f1.cxline 'end if'

  \}

  f1.cexpr.type equ f1.cexpr.type._back
  f1.cexpr.idex equ f1.cexpr.idex._back

  restore f1.cexpr.type._back
  restore f1.cexpr.idex._back

  f1.cexpr.lvl equ (f1.cexpr.lvl)-1

}

; ---   *   ---   *   ---
; paste switch case

macro f1.cxopen expr& {

  match =CLOSED , f1.cexpr.type \{
    f1.cxline 'if ',expr

  \}

  match =OPEN , f1.cexpr.type \{

    local ok
    ok equ 0

    match =0 , f1.cexpr.idex \\{
      f1.cxline 'if ',expr
      ok equ 1

    \\}


    match =0 any , ok expr \\{
      f1.cxline 'else if ',expr
      ok equ 1

    \\}

    match =0 , ok \\{
      f1.cxline 'else '

    \\}

  \}

  f1.cexpr.idex equ (f1.cexpr.idex)+1

}

; ---   *   ---   *   ---
; ^endof

macro f1.cxclose {

  match =CLOSED , f1.cexpr.type \{
    f1.cxline 'end if'

  \}

}

; ---   *   ---   *   ---
; conditional paste

macro f1.ccall fn,expr& {

  f1.cxopen expr
    f1.line fn
    f1.cout $0A

  f1.cxclose

}

; ---   *   ---   *   ---
; multi-conditional paste

macro f1.cxswitch X,[item] {

  common f1.cxbeg OPEN

  forward match value ===> fn , item \{

    local ok
    ok equ 0

    match =DEF , value \\{
      f1.ccall \`fn
      ok equ 1

    \\}

    match =0 , ok \\{

      match =ptr buf , value \\\{
        f1.ccall \`fn,`X,' = ',value
        ok equ 1

      \\\}

      match =0 , ok \\\{
        f1.ccall \`fn,`X#' = '\#\`value

      \\\}

    \\}

  \}

  common f1.cxend

}

; ---   *   ---   *   ---
