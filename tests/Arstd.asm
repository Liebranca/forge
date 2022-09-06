;format ELF64

if ~ defined loaded?Worg
  include '%ARPATH%/forge/Worg.inc'

end if

%Worg

;  use '.inc' OS
  use '.inc' Arstd:IO
  use '.inc' Peso:Proc

^Worg ARPATH '/forge/'

;section '.text' executable

reg

  dq a    $21
  db ws0  $24

  dq b    $21
  db ws1  $24

  dq c    $21
  db ws2  $24

  dq d    $21
  dw nl   $24

end_reg Log_Unit

lu Log_Unit


