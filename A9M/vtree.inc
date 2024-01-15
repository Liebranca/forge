; ---   *   ---   *   ---
; A9M VTREE
; It branches out!
;
; LIBRE SOFTWARE
; Licensed under GNU GPL3
; be a bro and inherit
;
; CONTRIBUTORS
; lyeb,

; ---   *   ---   *   ---
; info

  TITLE     A9M.vtree

  VERSION   v0.00.2b
  AUTHOR    'IBN-3DILA'

; ---   *   ---   *   ---
; base struc

virtual at $00

vtree:

  .size dw $00
  .par  dw $00
  .chd  dw $00
  .sib  dw $00

sizeof.vtree = $-.size

end virtual

; ---   *   ---   *   ---
; cstruc

macro vtree.new dst,par= {

  ; make root block
  match , par \{
    vmem.new   dst,blk sizeof.vtree
    vmem.lseek dst,sizeof.vtree

  \}

  ; ^make child
  match addr id , par vmc.REG.ice \{

    $mov er,word [id+addr+vtree.chd]

    ; first child
    $on er = 0

      ; get base of child
      $mov er,id\#.ptr
      $mov word [id+addr+vtree.chd],er
      $mov dst,er

      ; ^calc base of parent
      $mov br,er
      $sub br,word [id+addr+vtree.size]
      $sub br,sizeof.vtree

    ; ^sibling jump!
    else

      vtree.get_last

      $mov word [id+ar+vtree.sib],er
      $mov br,word [id+ar+vtree.par]

      $mov dst,er

    end if


    ; make room for header
    vmem.bstore id,$00,qword

    ; ^write par
    $mov word [id+er+vtree.par],br

  \}

}

; ---   *   ---   *   ---
; extends the buffer

macro vtree.grow addr,src,sz=word {

  match size id , sz vmc.REG.ice \{
    vmem.bstore id,src,size
    $add word [id+addr+vtree.size],sizeof.\#size

  \}

}

; ---   *   ---   *   ---
; gets last children in list

macro vtree.get_last {

  match id , vmc.REG.ice \{

    local ahead
    ahead = 1

    while ahead

      $mov ahead,[id+er+vtree.sib]

      ; got pointer to next
      if ahead
        $mov er,ahead

      ; ^nope, calculate offset to end
      else
        $mov ar,er
        $add er,[id+er+vtree.size]
        $add er,ahead+sizeof.vtree

        break

      end if

    end while

  \}

}

; ---   *   ---   *   ---
