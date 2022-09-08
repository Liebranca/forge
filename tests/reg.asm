if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

imp

  use '.inc' Peso::Reg

end_imp ARPATH '/forge/'

; ---   *   ---   *   ---

reg

  dq x ?
  dq y ?

end_reg myReg

; ---   *   ---   *   ---

ldkls myReg2

; ---   *   ---   *   ---
