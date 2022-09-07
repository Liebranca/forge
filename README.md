# WELCOME TO THE FORGE

Here are my utilities and experiments with flat assembler on GNU/Linux. As I get better at assembly and solve the problems I encounter, I will share the solutions to those problems.

# SOME SETUP NEEDED

- [Get fasm](https://flatassembler.net/)

- Once you have fasm installed, copy `elf.inc` and `import64.inc` from <fasm/examples/elfexe/dynamic> into <fasm/inc>. These are of great help when dynamic linking, so I like keeping them at hand.

- Append <path/to/fasm/inc> to your `INCLUDE`.

### OPTIONAL

If you have [avtomat](https://github.com/Liebranca/avtomat) installed then you get to use additional utils I wrote to make life easier. These are not necessary. Something as simple as:

```
cd /path/to/this/repo/ && cd ..
ARPATH=$(pwd)

```

At the start of the session is sufficient to satisfy the importer that my `*.inc` files depend on.
