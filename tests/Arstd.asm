if ~ defined loaded?Worg
  include '%ARPATH%/forge/Worg.inc'

end if

%Worg

  use '.inc' OS
  use '.inc' Arstd:IO
  use '.inc' Peso:Proc

^Worg ARPATH '/forge/'

Proc@$enter here

Proc@$var word pt

db .pt

Proc@$leave
