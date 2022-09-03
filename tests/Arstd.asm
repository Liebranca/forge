include '%ARPATH%/forge/Worg.inc'

if ~ defined loaded?Worg
  include '%ARPATH%/forge/Worg.inc'

end if

%Worg

  use '.inc' Arstd:IO
  use '.inc' St

^Worg ARPATH '/forge/'

%St

  db a $24
  db b $26
  dw c $21

^St Kls
inst virtual_Kls 0x0100

match any,Kls@self {
  dw any#.b

}
