; dynamic linking test
;
; ---   *   ---   *   ---

format ELF64 executable 3

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

imp
  use '.inc' import64

end_imp _ ''

imp

  use '.inc' OS

  use '.inc' Arstd::IO
  use '.inc' Peso::Proc

end_imp ARPATH '/forge/'

; ---   *   ---   *   ---
; dyn

  interpreter interp@default

  needed      'libdl.so.2'
  import      dlopen,dlsym

  entry       start

; ---   *   ---   *   ---

segment readable executable

start:

  lea rdi,[fname]
  mov esi,1
  call [dlopen]

  mov rdi,rax
  lea rsi,[fn]
  call [dlsym]

  call rax
  exit

; ---   *   ---   *   ---

segment readable
  fname db 'libtest.so',$00
  fn db 'sayhi',$00

; ---   *   ---   *   ---
