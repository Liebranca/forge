format ELF64

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

imp

  use '.inc' Arstd::IO
  use '.inc' Peso::Proc

end_imp _ '/home/lyeb/AR/forge/'

section '.text' executable

  xor rax,rax
