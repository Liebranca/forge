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

library ARPATH '/forge/'
  use '.inc' peso::proc

library.import

; ---   *   ---   *   ---
; info

  TITLE     OS.Clock

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

SYS.nanosleep:
  .id     = $23

SYS.clktime:
  .id     = $E4
  .thrcpu = $03

; ---   *   ---   *   ---
; used for ticking

reg.new CLK,public

  my .sec  dq $00
  my .nan  dq $00

  my .prev dq $00
  my .flen dq $00

reg.end

; ---   *   ---   *   ---
; get frame delta
; sleep if it's small

EXESEG

proc.new CLK.tick,public
proc.lis CLK self rdi

  proc.enter

  ; save beg, get end
  push qword [@self.prev]
  call CLK.time

  ; ^overwrite end
  mov qword [@self.prev],rax

  ; ^end-beg
  pop rsi
  sub rax,rsi
  mov rsi,qword [@self.flen]


  ; on elapsed < frame length
  cmp rax,rsi
  jge .skip

  ; ^sleep if so
  sub  rsi,rax
  and  rsi,999999999
  xor  rdx,rdx

  call CLK.sleep


  ; cleanup and give
  .skip:

  proc.leave
  ret

; ---   *   ---   *   ---
; get elapsed in nanoseconds

proc.new CLK.time,public
proc.lis CLK self rdi

  proc.enter

  ; write sec+sub to struc
  push @self
  lea  rsi,[@self]
  mov  rdi,SYS.clktime.thrcpu
  mov  rax,SYS.clktime.id

  syscall


  ; ^approx. sec to nano
  pop  @self
  mov  rax,[@self.sec]
  mov  rcx,1000000000
  imul rax,rcx
  add  rax,[@self.nan]


  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
; stop what you're doing
; for a while!

proc.new CLK.sleep,public
proc.lis CLK self rdi

  proc.enter

  mov qword [@self.sec],rdx
  mov qword [@self.nan],rsi
  mov rax,SYS.nanosleep.id

  xor rsi,rsi

  syscall

  ; cleanup and give
  proc.leave
  ret

; ---   *   ---   *   ---
