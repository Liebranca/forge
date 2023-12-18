; ---   *   ---   *   ---
; IOCTL
; Swiss army chainsaw
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

  TITLE     peso.ioctl

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

SYS.ioctl:

  .id      = $10


  ; file ctl
  .fionbio = $5421


  ; tty ctl
  .tcgets  = $5401
  .tcsets  = $5402
  .tcsetsf = $5404

  ; ^KDSKBMODE
  .kbmode  = $4B45
  .kbxlate = $01

  ; ^actually medium raw
  ; ^but we never use the other ;>
  .kbraw   = $02

; ---   *   ---   *   ---
; syscall proto

macro ioctl dst,mode,src {

  local ok
  ok equ 0


  ; clairvoyance: recognize bin ice
  match =bin any , dst \{
    mov edi,dword [any+bin.fd]
    ok equ 1

  \}


  ; ^regular dst, fill conditionally
  match =0 , ok \{
    i_ldX di,dst

  \}

  ; ^idem
  i_ldX si,mode
  i_ldX d,src


  ; ^commit
  mov rax,SYS.ioctl.id
  syscall

}

; ---   *   ---   *   ---
