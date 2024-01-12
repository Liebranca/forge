; ---   *   ---   *   ---
; A9M OUTBUF:SHARE
; Default output interface
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.SHARE.OUTBUF

  VERSION   v0.00.1b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; batch declares output buffs
; and cats them to output queue

macro A9M.MKOUTBUFS [name] {

  forward

    ; make ice
    define   A9M.#name
    vmem.new A9M.#name,blk $00

    ; ^lis buffer -> get sized ptr
    macro A9M.#name#.view dst,addr,len \{

      match id , A9M.#name \\{
        vmem.view sbuf,id,addr,len

      \\}

    \}

    ; ^lis buffer -> write full any
    macro A9M.#name#.write ct& \{
      vmem.write A9M.#name,ct

    \}

    ; ^lis buffer -> write element
    macro A9M.#name#.set cmd \{

      match size value =at addr , cmd \\{
        vmem.set A9M.#name,value,addr,size

      \\}

    \}

    ; ^lis buffer -> write other partial
    macro A9M.#name#.cat src,beg=0 \{

      match id , src \\{

        local      sbuf

        vmem.view  sbuf,id,beg,id\\#.len
        vmem.write A9M.#name,ptr sbuf

      \\}

    \}

    ; add to fout list
    commacat A9M.$$,A9M.#name

}

; ---   *   ---   *   ---
; special names used by core

  ; I/O buffers (read,write)
  define A9M.FSRC
  define A9M.FDST

  ; list of auxiliary output buffers
  ; these are compiled into FDST
  define A9M.$$

; ---   *   ---   *   ---
; generic write-to-out

if ~ defined A9M.OUTBUF_LIST

  define A9M.OUTBUF_LIST \
    STROUT,SYMOUT

end if

; ---   *   ---   *   ---
; run the generator

match __list , A9M.OUTBUF_LIST {
  A9M.MKOUTBUFS __list

}

; ---   *   ---   *   ---
