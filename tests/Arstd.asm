include '%ARPATH%/forge/Worg.inc'

if ~ defined loaded?Worg
  include '%ARPATH%/forge/Worg.inc'

end if

%Worg

  use '.inc' Arstd:IO

^Worg ARPATH '/forge/'

module_info Worg,Arstd.IO
