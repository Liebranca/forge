; ---   *   ---   *   ---
; CLOCK
; Sleeping on the job again
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; deps

if ~ defined loaded?Imp
  include '%ARPATH%/forge/Imp.inc'

end if

library ARPATH '/forge/'
  use '.inc' peso::proc

import

; ---   *   ---   *   ---
; info

  TITLE     OS.Clock

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

  CLAN      Clock

; ---   *   ---   *   ---
; GBL

  define SYS_SLEEP  $23
  define SYS_TIME   $E4

; ---   *   ---   *   ---
; used for ticking

reg

  dq sec   $00
  dq nan   $00

  dq prev  $00

end_reg CLK

; ---   *   ---   *   ---
; *in nanoseconds

macro get_time dst* {

  push rbx
  lea rsi,[dst]

  ; CLOCK_THREAD_CPUTIME_ID
  mov rdi,$03
  mov rax,SYS_TIME

  syscall

  mov rax,[rsi+CLK.sec]
  mov rbx,1000000000
  mul rbx
  add rax,[rsi+CLK.nan]

  pop rbx

}

; ---   *   ---   *   ---
; stop what you're doing
; for a lil while

macro nsleep src*,delta* {

  local redundant
  redundant equ 0

  match =rdi,src \{

  \}

  match =0,redundant \{
    lea rdi,[src]

  \}

  mov qword [rdi+CLK.sec],$00
  mov qword [rdi+CLK.nan],delta
  xor rsi,rsi

  mov rax,SYS_SLEEP
  syscall

}

; ---   *   ---   *   ---
; get frame delta
; sleep if it's small

segment readable executable
align $10

proc tick

  qword clk
  mov [%clk],rdi

  push rbx

  mov rax,qword [rdi+CLK.prev]
  push rax

  get_time rdi

  mov rdi,[%clk]
  mov qword [rdi+CLK.prev],rax

  pop rbx

  sub rax,rbx
  mov rbx,flen

  cmp rax,rbx
  jge .skip

  sub rbx,rax
  and rbx,999999999

  nsleep rdi,rbx

; ---   *   ---   *   ---

.skip:
  pop rbx

end_proc ret

; ---   *   ---   *   ---
END_CLAN
