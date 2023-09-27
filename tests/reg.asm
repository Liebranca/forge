format ELF64 executable 3
entry _start

; ---   *   ---   *   ---

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'
  use '.inc' OS
  use '.inc' peso::reg

import

; ---   *   ---   *   ---
; test struc

unit.salign r,w

reg.new rtest
  my .top dq $00
  my .bot dw $00

reg.end

reg.ice rtest rt0
reg.ice rtest rt1

reg.vice rbp-16,rtest rt2

; ---   *   ---   *   ---
; ^the bit

unit.salign r,x
_start:

  push rbp
  mov  rbp,rsp

  and  spl,$F0
  and  bpl,$F0
  sub  rsp,$10

  lea rax,[rt0.top]
  mov qword [rax],$2424

  lea rax,[rt1.top]
  mov qword [rax],$2525

  lea rax,[rt2.bot]
  mov dword [rax],$2626

  exit

; ---   *   ---   *   ---
