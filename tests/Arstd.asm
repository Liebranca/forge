if ~ defined loaded?Worg
  include '%ARPATH%/forge/Worg.inc'

end if

%Worg

  use '.inc' OS
  use '.inc' Arstd:IO
  use '.inc' Peso:Proc

^Worg ARPATH '/forge/'

Proc@$enter here,$

dq $9AD

Proc@$enter there,$
Proc@$var x,rbp-8

.a=-8

db here.there.a
