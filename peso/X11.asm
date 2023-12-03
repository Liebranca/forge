; ---   *   ---   *   ---
; X11
; Bane of the lazy
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

library.import

; ---   *   ---   *   ---
; info

  TITLE     peso.X11

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; GBL

RAMSEG

reg.new X11.GBL

  my .sock     dq $00
  my .sockpath dq $00

reg.end
reg.ice X11.GBL X11.main

; ---   *   ---   *   ---
; ^signature shorthand

macro X11.sigt.mess T {

  proc.lis X11.GBL     self X11.main
  proc.stk X11.mess.#T mess

}

; ---   *   ---   *   ---
; nit handshake

EXESEG

reg.new X11.mess.nit

  my .order  db $00
  my .pad0   db $00

  my .vmajor dw $00
  my .vminor dw $00

  my .auth_proto  dw $00
  my .auth_string dw $00
  my .pad1        dw $00

reg.end

; ---   *   ---   *   ---
; ^make socket and perform
; handshake

proc.new X11.nit
X11.sigt.mess nit

  proc.enter

  ; get path
  string.from "/tmp/.X11-unix/X0"
  mov qword [@self.sock],rax

  ; make socket
  call socket.unix.new
  mov  qword [@self.sock],rax

  ; ^conx
  mov  rdi,qword [@self.sock]
  mov  rsi,qword [@self.sockpath]

  call socket.unix.connect


  ; clear mem
  lea  rdi,[@mess]
  mov  r8d,sizeof.X11.mess.nit
  call memclr

  ; ^fill out mess
  mov word [@mess.order],'l'
  mov word [@mess.vmajor],$0B

  ; ^deliver
  mov  rdi,qword [@self.sock]
  lea  rsi,[@mess]
  mov  rdx,sizeof.X11.mess.nit

  call socket.dwrite


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; footer

constr ROM

; ---   *   ---   *   ---
