; ---   *   ---   *   ---
; PESO CLINE
; Promised bytes
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

  TITLE     peso.cline

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

  define cline.dst
  define cline.src

; ---   *   ---   *   ---
; set commit target

macro cline.set_dst name {
  cline.dst equ name

}

; ---   *   ---   *   ---
; clear codestr array

macro cline.new {

  ; get id for codestr
  local uid
  uid.new uid,cline.codestr,global

  ; ^save for later
  match id,uid \{
    cline.src equ id
    define id\#.sref

  \}

}

; ---   *   ---   *   ---
; push line to array

macro cline src& {

  match id,cline.src \{
    eolcat id\#.sref,src

  \}

}

; ---   *   ---   *   ---
; ^push array of lines to dst

macro cline.commit {

  ; get id for wrapper
  local uid
  uid.new uid,cline.commit,global

  match dst src id , cline.dst cline.src uid \{

    ; ^make wraps
    macro paste\#.\#id \\{
      match sref , src\#.sref \\\{
        cline.filter sref

      \\\}

    \\}

    ; ^add wraps to dst
    dst\#.push paste\#.\#id

  \}


  ; clear array
  cline.new

}

; ---   *   ---   *   ---
; ^procs the code to come

macro cline.filter [item] {

  ; decl accum
  common

    local line
    line equ

  ; ^cat to
  forward
    local ok
    ok equ 0

    ; ^EOL, paste and clear
    match ="\n" , item \{

      line
      line equ

      ok equ 1

    \}

    ; ^code+EOL, cat, paste and clear
    match =0 any ="\n" , ok item \{

      commacat line,any

      line
      line equ

      ok equ 1

    \}

    ; ^continue
    match =0 any , ok item \{
      commacat line,any

    \}

  ; ^paste
  common line

}

; ---   *   ---   *   ---
