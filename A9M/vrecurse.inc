; ---   *   ---   *   ---
; VRECURSE
; Just how much can a
; macro paste itself?!
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.vrecurse

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; ROM

if ~ defined A9M.XDEPTH
  define A9M.XDEPTH $10

end if

; ---   *   ---   *   ---
; errme to put when max
; depth is reached

macro vrecurse.CRASH {


  display PETAG,'xdepth reached'
  out@nl

  display PADTAG
  out@nl


  match xs xp , vmc.REG.xs vmc.REG.xp \{
    display CHDTAG,'XS    ',\`xs
    out@nl

    display CHDTAG,'XP    ',\`xp
    out@nl

  \}


  display PADTAG
  out@nl

  display CHDTAG,'MCBET '
  hexsay  A9M.XDEPTH,$10
  out@nl

  display PADTAG
  out@nl  2

  err

}

; ---   *   ---   *   ---
; ^crux

macro vrecurse.head name,args& {

  match , name\#._vrecurse \{
    macro name _nullarg& \\{vrecurse.CRASH\\}
    define name#\._vrecurse 1

  \}

}

; ---   *   ---   *   ---
; ^icef*ck!

$RECURSIVE fix macro vrecurse.inner name,args& {\
  cline.filter \
    if % = A9M.XDEPTH "\n",\
      vrecurse.head name,args "\n",\
    end if\
}\
\
rept A9M.XDEPTH {\
vrecurse.inner

$RECURSIVE.end fix }

; ---   *   ---   *   ---
