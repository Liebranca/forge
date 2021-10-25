;/   ---     ---     ---     ---     ---
; to compile:
;   fasm c_hello.asm c_hello.o
;   gcc  c_hello.o -o c_hello.exe

;/   ---     ---     ---     ---     ---

format ms64 coff

public main

extrn 'puts' as _puts

;/   ---     ---     ---     ---     ---

section '.text' code readable executable

  main:
    mov   rcx,message
    call  _puts
    ret

;/   ---     ---     ---     ---     ---

section '.data' data readable writeable
  message         db 'Hello World!',0x0A,0x00
  message_length  = $ - message

;/   ---     ---     ---     ---     ---
