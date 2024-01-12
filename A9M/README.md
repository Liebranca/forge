# A9M: THE ARCANE 9 MACHINE

__NOTE__ | Currently, we at `AR/` are still implementing the Arcane 9, and by the grace of God, the reasoning behind it is fully fleshed out. But documentation is outdated when not outright missing, and this is indeed our mistake.

## SYNOPSIS

```asm

library ARPATH '/forge/'
  use '.inc' A9M

library.import

; ...

A9M.read filepath

```

(See also: [AR/Imp](https://github.com/Liebranca/forge/blob/main/docs/Imp.md))

If the argument is omitted, `A9M.read` will use `A9M.FPATH`, which can simply be set through `define A9M.FPATH 'path/to/file'` or `A9M.FPATH equ 'path/to/file'`. Alternatively, the path can be passed through the commandline, eg `fasm -d A9M.FPATH="'path/to/file'"`.

A commandline util to do this is also provided in this repo, in `bin/peso`; `peso path/to/file` is more or less equivalent to the previously mentioned methods.

## DESCRIPTION

The Arcane 9 is a *theoretical* virtual machine and compiler, which right here and now, we have begun implementing with flat assembler macros. In essence: this a framework for code generation from within the assembler itself.

## CHANGELOG

### v0.01.2b

- `*::vmem` tweaks for `cat`, `align` and `resize`. Fixed the `bstore` mistake were resizing would crash the subsequent write!

- Ported `*::vcstring` from `peso`: it just gives a quick way to calculate the length of C strings, but that's enough for now.

- Reworked the string buffer used to collect identifiers into a standard `char**`; there's no longer a need to encode the length of each token.

- Turns out that the additional metadata that was encoded with each token can also be inferred by the time `L2` gets to need that information, so tokens are now 16-bit for keywords and 32-bit for identifiers. We might revisit this later, but good enough for now.

- `*::$$` buffers are now padded to a 16-bit boundary and their length is stored automatically to final output.

### v0.01.1b

- Moved first expression logic into `*::FE`; this makes it so we don't have to check for it every single time, and in turns simplifies the logic at all three levels. Quite obvious in retrospect ;>

- Added `ahead` and `tail` to `*::L0`; we use these to look at neighboring bytes while reading tokens.

- Heavily modified `L0` logic for operators.

- Added `lseek_s` and `rseek_s` to `*::vmem::meta` for when you explicitly want to skip ahead or backwards without crossing buffer bounds.

### v0.01.0b

- Slight modification to `L0` which takes token and expression processing out of the main switch.

- `L1` memory serialization happens before the expression itself is processed; and so now syntactical analysis is performed directly on serialized tokens.

- Added `*::SHARE::OUTBUF` file for defining output buffers, all catted to `*::$$` via footer.

- Combine, consume and reverse macros for `*::vmc`.

### v0.00.9b

- Generating token tables using `*::vhash`.

- Matching `L1` tokens against the default token table.
- Subdivided the output buffer into symbols and strings. Useful for storing identifiers that are syntactically valid but don't match against any reserved token.

- Added commandline utils for running test `A9M` compilations.

### v0.00.8b

- Added `write` and `paste` macros to `*::vmem::bin`: these let us quickly commit the contents of a buffer to disk.

- Added `to_disk` and `from_disk` macros to `*::vreg`, which similarly, provide a simplified interface to freezing and thawing structures between sessions.

- `*::vhash` de-serialization wrapper in the form of `vhash.from_disk`.

- Minor fixes to `*::vhash`.

### v0.00.7b

- Implemented memory levels: file processing is divided into sections for chunk, array of chunk, and trees of arrays of chunks -- `*::L0`, `*::L1` and `*::L2`, respectively.

- Added `*::vmc`, which in short bridges the gap between assembler macros and programming a full Arcane 9.

- Added `*::vrecurse`, a small util to allow macros to be self-referential, up to a limit determined by `A9M.XDEPTH`.

- Subdivided `*::vmem` into smaller modules for maintenance reasons.

- Added `*::vmem::xstep` module to ease generating iterators for unaligned buffers.

- Expanded the scope of the project beyond just lexing ;>

### v0.00.6b

- Automatic, variable-sized steps for the macros `copy`, `eq` and `prich` from `*::vmem`; this makes it easier to work with slices of data smaller than the base alignment of a virtual buffer.

- Fixed mistakes in `*::vcrypt` that prevented hash collisions from being solved.

### v0.00.5b

- Largely untested, but working: `vhash.store` && `vhash.load` at `*::vcrypt`; so, we have effectively implemented hash tables on virtual buffers.

- Small fixes to `*::vmem` copying and comparison macros.

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
