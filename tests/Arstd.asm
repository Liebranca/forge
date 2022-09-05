format ELF64

if ~ defined loaded?Worg
  include '%ARPATH%/forge/Worg.inc'

end if

%Worg

  use '.inc' OS
  use '.inc' Arstd:IO
  use '.inc' Peso:Proc

^Worg ARPATH '/forge/'

section '.text' executable

proc s

  Proc@$var word x
  Proc@$var half y
  Proc@$var half z

  mov rax,[%x]
  mov rax,[%y]
  mov rax,[%z]

end_proc leave
