; ---   *   ---   *   ---
; deps

library ARPATH '/forge/'

  use '.hed' OS::Clock
  use '.hed' peso::file

  use '.inc' Arstd::Lycon

library.import

; ---   *   ---   *   ---
; GBL

RAMSEG

msg:
  db $1B,$5B,'999H'

clkchr:
  lydu $01A9
  db   $00

  msg_len=$-msg
  flen=400000000


reg.ice CLK gclk

; ---   *   ---   *   ---
; the bit

EXESEG

proc.new crux,public
proc.stk byte cnt
proc.lis CLK clk gclk

  proc.enter

  ; setup struc
  mov [@clk.flen],flen


  ; iter draw
  .top:

    ; sprite frame
    mov byte [@cnt],cl
    and byte [@cnt],$07

    ; go next
    push rcx
    mov  rdi,@clk
    call CLK.tick


    ; fetch sprite
    xor rax,rax
    mov ah,$A9
    add ah,byte [@cnt]
    or  al,$C6

    ; ^draw
    mov  word [clkchr],ax
    mov  rdi,msg
    mov  rsi,msg_len

    call sow
    call reap


    ; up the counter
    pop rcx
    inc rcx
    cmp rcx,8*8
    jne .top


  ; slap a newline at end
  mov  byte [msg+msg_len-1],$0A
  mov  word [clkchr],ax
  mov  rdi,msg
  mov  rsi,msg_len

  call sow

  ; cleanup and give
  proc.leave
  exit


; ---   *   ---   *   ---
