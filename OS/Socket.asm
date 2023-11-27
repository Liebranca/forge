; ---   *   ---   *   ---
; SOCKET
; Talks to the clouds
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
  use '.hed' peso::alloc

library.import

; ---   *   ---   *   ---
; info

  TITLE     OS.Socket

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

SYS.socket:

  .id      = $29

  ; domain
  .unix    = $01
  .inet    = $02
  .inet6   = $0A

  ; type
  .stream  = $01
  .dgram   = $02
  .raw     = $03

  ; O, POSIX!
  .addrsz  = $77

; ---   *   ---   *   ---
; ^const table

ROMSEG Socket.CON,public

  .ADDRSZ:
    .sunsz  db $6E
    .sinsz  db $10
    .sin6sz db $1C

; ---   *   ---   *   ---
; base struc

reg.new Socket,public

  my .fd   dd $00
  my .sz   dd $00
  my .dom  db $00

  my .addr db SYS.socket.addrsz dup $00

reg.end

; ---   *   ---   *   ---
; ^cstruc

EXESEG

proc.new Socket.new,public
proc.stk qword out

  proc.enter

  ; save tmp
  push rdi
  push rsi

  ; get mem
  mov  rdi,sizeof.Socket
  call alloc

  mov  qword [@out],rax

  ; ^restore tmp
  pop rsi
  pop rdi


  ; get dom addr
  mov rcx,rax
  add rcx,Socket.dom

  ; ^map dom to idex
  mov       rax,rdi
  branchtab getdom

  ; ^AF_UNIX
  getdom.branch SYS.socket.unix => .unix
    mov byte [rcx],$00
    jmp .make_sock

  ; ^AF_INET
  getdom.branch SYS.socket.inet => .inet
    mov byte [rcx],$01
    jmp .make_sock

  ; ^AF_INET6
  getdom.branch SYS.socket.inet6 => .inet6
    mov byte [rcx],$02
    jmp .make_sock

  getdom.end


  ; issue syscall
  .make_sock:

    ; auto-protocol
    xor  rdx,rdx

    ; get fd
    mov rax,SYS.socket.id
    syscall

    ; ^errchk
    cmp rax,$00
    jge .sockok

    ; ^errme
    OS.throw FATAL,\
      "Failed to create new socket",$0A


  ; ^fd is valid
  ; ^save fd to struc
  .sockok:

    mov rcx,qword [@out]
    mov dword [rcx+Socket.fd],eax

    ; ^get size accto dom
    xor rdx,rdx
    mov dl,byte [rcx+Socket.dom]
    mov dl,byte [Socket.CON.ADDRSZ+edx]

    ; ^write to struc
    mov dword [rcx+Socket.sz],edx


  ; reset out
  mov rax,rcx

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; ^dstruc

proc.new Socket.del,public
proc.lis Socket self rdi

  proc.enter

  

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; footer

constr ROM

; ---   *   ---   *   ---
