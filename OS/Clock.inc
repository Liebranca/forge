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

imp
  use '.inc' Peso::Proc

end_imp ARPATH '/forge/'

; ---   *   ---   *   ---
; info

  TITLE     OS.Clock

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

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

end_reg Clock

; ---   *   ---   *   ---
; *in nanoseconds

macro get_time dst* {

  push rbx
  lea rsi,[dst]

  ; CLOCK_THREAD_CPUTIME_ID
  mov rdi,$03
  mov rax,SYS_TIME

  syscall

  mov rax,[rsi+Clock.sec]
  mov rbx,1000000000
  mul rbx
  add rax,[rsi+Clock.nan]

  pop rbx

}

; ---   *   ---   *   ---

macro nsleep src*,delta* {

  local redundat
  redunddant equ 0

  match =rdi,src \{

  \}

  match =0,redundant \{
    lea rdi,[src]

  \}

  mov qword [rdi+Clock.sec],$00
  mov qword [rdi+Clock.nan],delta
  xor rsi,rsi

  mov rax,SYS_SLEEP
  syscall

}

; ---   *   ---   *   ---

segment readable executable

clan clock

proc tick

  qword clk
  mov [%clk],rdi

  push rbx

  mov rax,qword [rdi+Clock.prev]
  push rax

  get_time rdi

  mov rdi,[%clk]
  mov qword [rdi+Clock.prev],rax

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

end_clan

; ---   *   ---   *   ---
