extern puts

SECTION .DATA
  hello:     db 'Hello world!',10,0

SECTION .TEXT
  GLOBAL main

main:
  mov   rcx,hello
  call  puts
  ret
