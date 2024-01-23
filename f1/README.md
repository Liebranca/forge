# f1

## SYNOPSIS

Generate fasm using fasm:

```asm

f1.macro saywat? arg0,arg1&

  f1.match any =, next <: arg1
    f1.vsay any

  f1.cend

f1.cend


```

Will write the following to a `A9M::vmem` virtual buffer:

```asm

macro saywat? arg0,arg1& {

  match any =, next , arg1  \{
    display \`any

  \}

}

```

The macro `f1.to_disk` will then dump the contents of the virtual buffer to a file on a succesful run.

A few perl modules for generating fasm code are also included in this package, mostly for interop with `AR/avtomat`.

## DEPENDENCIES

`f1` fasm files `include` nothing, so here's a manual listing:

### `Arstd::INCFILE`

- `INFO_FIELD`. You can't take this out without breaking the `AR/` importer.

### `Arstd::Style`

- Uses `commacat`, which is a trivial macro. You may safely replace this with your own version.

### `A9M::vmem`

- This flat out doesn't work without virtual blocks.

- Requires `A9M::vmem::bin` for write to buffer and dump to disk.


## CHANGELOG

### v0.00.2b

- Added some old (and new!) perl code to the package for general convenience when doing commandline incantations.

### v0.00.1b

- Initial sketching out and implementation of chicken-and-egg generation of fasm macros through fasm macros.

- Basic switch-case making through `*::cx`
