
; to compile:
;   fasm hello_dyn.asm hello.o 
;   ld -o hello.exe hello.o -lkernel32

;/   ---     ---     ---     ---     ---

format ms64 coff

STD_OUTPUT_HANDLE       = -11

extrn '__imp_GetStdHandle' as GetStdHandle:qword
extrn '__imp_WriteFile' as WriteFile:qword
extrn '__imp_ExitProcess' as ExitProcess:qword

section '.text' code readable executable

  public main

;/   ---     ---     ---     ---     ---

main:
  sub     rsp,8*7
  mov     rcx,STD_OUTPUT_HANDLE
  call    [GetStdHandle]

  mov     rcx,rax
  lea     rdx,[message]
  mov     r8d,message_length
  lea     r9,[rsp+4*8]
  mov     qword[rsp+4*8],0
  call    [WriteFile]

  mov     ecx,eax
  call    [ExitProcess]

;/   ---     ---     ---     ---     ---

section '.data' data readable writeable
  message db 'Hello, world!',0x0A,0x00
  message_length  = $ - message
