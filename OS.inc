; ---   *   ---   *   ---
; OS
; Get me out of here
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
  use '.hed' peso::constr

library.import

; ---   *   ---   *   ---
; info

  TITLE     OS

  VERSION   v0.00.5b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

SYS.write:

  .id=$01

  ; stdfd are all global
  ; deal with it
  stdin  = $00
  stdout = $01
  stderr = $02


SYS.exit.id=$3C

; ---   *   ---   *   ---
; terminate

macro exit code=0 {

  push code

  ; run 'atexit' queue
  MAM.atexit

  ; kill
  pop rdi
  mov rax,SYS.exit.id

  syscall

}

; ---   *   ---   *   ---
; give errmes without sow/reap

macro OS.throw code,[ct] { common

  ; get errme id
  local name
  proc.get_id name,code#_errme

  ; ^put tag
  mov rdi,stderr
  lea rsi,[code#.tag]
  mov rdx,code#.tag.length

  mov rax,SYS.write.id

  syscall


  ; ^put errme
  match any,name \{

    constr.new any,ct

    mov rdi,stderr
    lea rsi,[any]
    mov rdx,any\#.length

    mov rax,SYS.write.id

    syscall

  \}


  ; conditional die
  match =FATAL,code \{
    exit code#.num

  \}

}

; ---   *   ---   *   ---
