if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'
  use '.inc' peso::reg

import

; ---   *   ---   *   ---

reg.new rtest
  my .top dq $00
  my .bot dq $00

reg.end

reg.ice rtest x

display x.bot

; ---   *   ---   *   ---
