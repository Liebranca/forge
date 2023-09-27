format ELF64 executable 3
entry _start

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'
  use '.inc' OS
  use '.inc' peso::proc

import

; ---   *   ---   *   ---
; struc

reg.new rtest

  my .a dw $2424
  my .b dw $2525

  my .c dd $26262727

reg.end

; ---   *   ---   *   ---

unit.salign r,x

proc.new proc_test
proc.arg rtest self rdi

  proc.enter
  mov dword [%self.a],$24242424


  proc.leave
  ret

; ---   *   ---   *   ---

proc.new _start
proc.stk rtest self

  proc.enter

  lea rdi,[%self]
  call proc_test


  proc.leave
  exit

; ---   *   ---   *   ---
