include '%ARPATH%/forge/Worg.inc'

if ~ defined loaded?Worg
  include '%ARPATH%/forge/Worg.inc'

end if

%Worg

  use '.inc' Arstd:IO
  use '.inc' St

^Worg ARPATH '/forge/'

%St

  dq a $2424242426262626
  dq b $110011FF0099AABB

^St Kls

inst Kls
dq sizeof.Kls
