format ELF64 executable 3

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

imp
  use '.inc' OS
  use '.inc' Peso::Proc

end_imp ARPATH '/forge/'

; ---   *   ---   *   ---

segment executable

proc myProc

  dword x
  mov [%x],dword $00000A24

  proc inner
    byte y
    word z
    mov [%y],byte $21

    write 1,%y,1

  end_proc leave

  write 1,%x,4
  exit [%x]

end_proc leave

; ---   *   ---   *   ---
