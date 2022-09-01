;format ELF64
include '%ARPATH%/forge/St.inc'

; ---   *   ---   *   ---

define SYSTAG           \
  $1B,$5B,'37;1m<',     \
  $1B,$5B,'34;22m','AR',\
  $1B,$5B,'37;1m>',     \
  $1B,$5B,'0m'

define CHDTAG           \
  $1B,$5B,'37;1m::',    \
  $1B,$5B,'0m'

define ERRTAG           \
  $1B,$5B,'37;1m<',     \
  $1B,$5B,'31;1m','AR', \
  $1B,$5B,'37;1m>',     \
  $1B,$5B,'0m'

macro d'oh! src,[args] {

  common
    display src

  forward
    if args eq '__FILE__'
      display $20,__FILE__

    else
      display $20,`args

    end if

  common
    display $0A

  if src eq ERRTAG
    err

  end if

}

macro out@sys args& {d'oh! SYSTAG,args}
macro out@chd args& {d'oh! CHDTAG,args}
macro out@err args& {d'oh! ERRTAG,args}

; ---   *   ---   *   ---

macro __ptr_decl kls,NTA {

  local status
  status equ 0

  match type name =: addr,NTA \{
    out@sys type,name,':',addr
    out@chd 'fukkkkkk'

    status equ 1

  \}

  match =0,status \{
    out@err 'bad NTA for',kls

  \}

}

macro nit NTA {

  __ptr_decl 'obj',NTA

}

; ---   *   ---   *   ---
