# SYNOPSIS

```asm
; fasm -d A9M.FPATH="'path/to/file'"
; ---   *   ---   *   ---
; get importer

if ~ defined loaded?Imp
  include 'path/to/Imp.inc'

end if

; ---   *   ---   *   ---
; get deps

library ARPATH '/forge/'
  use '.inc' A9M

library.import

; ---   *   ---   *   ---
; ^invoke

A9M.rd

; ---   *   ---   *   ---

```

# DESCRIPTION

A very simple question: can you write a lexer entirely with `f1` macros?

Some would think you crazy to even ask, but the answer is still yes. `A9M` is one such lexer, made for the `peso` language.

# WAY IT WORKS

Given a path, open it through `file` inside a virtual block, then get the total length of the file as one would a regular string constant. Then, inside a `repeat` block, each byte is read through `load` and evaluated.

Each token character is in turn read into it's own virtual block according to some internal logic and state; single character tokens can be given meaning as early as this stage, as it's effectively only evaluating one byte at a time:

```asm

if A9M.CHAR = value
  ...

end if

```

That much is sufficient in such cases. However, to give meaning to a multi-byte sequence we must evaluate wider chunks of memory, which is a bit more involved.

Assuming both buffers have equal length, and qword-aligned size, then a very simple way to do this comparison is to `xor` one buffer against another in qword-sized chunks:

```asm

result=0

repeat src.len shr 3

  load q0 qword from src:(%-1)*8 
  load q1 qword from other:(%-1)*8

  result=result or (q0 xor q1)  

end repeat

```

Such an 'other' virtual buffer can be declared like so:

```asm

virtual at $00

  base:
  other::
    db 'to-match-with'

  len=$-base
  pad=size-len

  db pad dup $00

end virtual

```

Repeating this declaration for every keyword can be tedious, but thankfully, we're working entirely with macros. This bit is reduced to a couple of lines:

```asm

local buff
vmem.new buff,size,'[string]'

```

`vmem.new` uses `Arstd::uid` to generate a unique identifier, then uses it to declare the previously detailed structure using the provided arguments, and saves the generated `uid` to the passed destination, in this case `buff`.

This identifier is the "key" to accessing the defined symbols, so to operate on a virtual buffer, you must first unroll it:

```asm

match id , buff {
  store byte '$' at id#.base:id#.ptr
  id#.ptr=id#.ptr+1

}

```

And once again, macros can save us a lot of time with these repeating patterns. `A9M::vmem` defines many such operations and can easily be extended by the user.

Of particular note is the `vmem.eq` macro, which performs the aforementioned string comparison. This macro takes as arguments the name of a variable to overwrite with the result of the operation, plus the names of the two buffers to compare.

To show an example of it's usage:

```asm

macro strcmp_test {

  local b0
  local b1
  locak res


  ; varlis
  res equ strcmp_test.res

  ; make ice
  vmem.new b0,$20,'a$$$$$$$$$$$'
  vmem.new b1,$20,'x$$$$$$$$$$$'

  ; ^compare
  res=0
  vmem.eq res,b0,b1


  ; ^dbout
  if ok
    display 'EQ',$0A

  else
    display 'NE',$0A

  end if

}

```

With this mechanism, tokens can be compared against keywords and given meaning, thus completing the minimum necessities of a lexer.

# OUTPUT FORMAT

On a successful run, `A9M` outputs a `peso` tree file, or `*.p3`, storing an array of trees where each element details an expression.

A way to look at this format in plain text:

```$

(first token)
\-->(nest-beg?)
.  \-->(...)
.
\-->(nest-end)
\-->(...)

```

Would be the result, for instance, of lexing the expression:

```$
cmd spec arg0,arg1 {recurse}

```

Which is output as:

```$

cmd
\-->spec
\-->arg0,arg1
\-->{
.  \-->recurse
.
\-->}

```

Further processing of the tree is left up to another program to carry out.

# CHANGELOG

### v0.00.4b

- Initial sketching on `*::vcrypt` for implementing hash tables on virtual buffers.

- `*::vmem.bop` macro for quick implementation of operations on virtual buffers. Currently used solely for binary operators, but can be easily extended by calling the `*::vmem._gen_bop` generator macro.

- `*::vmem.view` macro for taking a "slice" of a virtual buffer. This handle can then be manipulated as one would a regular `vmem ice`.

### v0.00.3b

- Added segments to `*::vmem`: essentially, a virtual buffer can be extended to contain another. The parent segment can write to a child, but not the other way around.

- Added `*::vreg` to provide a struc-like interface to virtual buffers: strucs can be defined, instanced and their fields accessed through wrapper macros such as `get`, `set` and the like.

### v0.00.2b

- Made this document ;>

- Initial implementation of `*::vmem`; methods `new`, `clear`, `write`, `read`, `seek` and `eq`.

- Storing of current token inside `vmem *.ctoken`.

### v0.00.1b

- Turned a 'just-for-kicks' into a thing.

- Initial implementation of the main loop; pattern and check-making macros, basic state and logic.
