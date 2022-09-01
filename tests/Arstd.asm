include '%ARPATH%/forge/Worg.inc'

%Worg

  use '.inc' Arstd:IO

^Worg ARPATH '/forge/'

if ~ defined loaded?Arstd.IO
  display 'Arstd.IO not loaded!',$0A

else
  out@chd 'Arstd.IO loaded ;>'

end if

