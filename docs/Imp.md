# SYNOPSIS

```asm

if ~ defined loaded?Imp
  include 'path/to/Imp.inc'

end if

; ---   *   ---   *   ---

library ENV_ROOT '/subdir/'

  use '.ext' path::to::file

import

```

# DESCRIPTION

A recurring question in fasm boards: how do I ensure a file is included only once? Imp is simply one of many answers. It's original draft coded in just a few hours entirely with f1 macros, it provides a very simple interface to importing code and offers a little bit of help in managing your files.

# WAY IT WORKS

Imp checks for a `define`d symbol by the name of `loaded?<ID>` to identify if a file has already been imported by another dependency somewhere else in the program; `ID` always corresponds to the name of the file without extensions.

The following snippet:

```asm

library ARPATH '/forge/'
  use '.inc' OS
  use '.inc' Arstd::IO

import

```

Looks for the files `OS.inc` and `Arstd/IO.inc` in the `/forge/` subdirectory of the environment variable `$ARPATH`. This invocation will define the symbols `loaded?OS` and `loaded?Arstd.IO` if they are not defined already, such that:

```asm
if ~ defined loaded?OS
  ; will not be executed

end if

```

Uppon first being included, Imp inserts itself into the `loaded?` namespace to allow it's own status to be evaluated in this way.

In addition to file imports, Imp provides the macros `TITLE`, `VERSION` and `AUTHOR` from `Arstd/INCFILE.inc` to go along with it. These are used like so:

```asm

TITLE     module

VERSION   version_string
AUTHOR    'your_name'


```

Which defines the symbols `<module>?version` and `<module>?author` which are used by the `module_info` macro from `Arstd::IO`; the `INFO_FIELD` macro can also be used to declare your own module data.

Usage of `INFO_FIELD` is fairly straight-forward:

```asm

macro FIELD_NAME value {
  INFO_FIELD name value

}

```

The only requirement is that all your fields are defined *after* `TITLE`.

# FUTURE PLANS

Right from the very start Imp was complete enough for what I needed it for. However, improvements can always be made. For any oddities or annoyances you might encounter, please open an issue or contact me directly.

# CHANGELOG

### v0.01.2a

- Fullreim of most internal macros to improve performance and massively lower memory usage.

- Ditched the `module@$method` syntax for the more straightforward `module.method`.

### v0.01.1a

- Syntax change: replaced `imp` and `end_imp` with `library` and `import`, respectively.

- Fixed recursive `use`. Imp will now paste the `include` directive in-place of the new `import` keyword rather than inside a macro.

### v0.01.0a

- Importing from absolute paths. If you do not wish for Imp to use an environment variable to build the path to the files, you may simply pass a single `_` underscore in place of the name of an environ.

- General purpose macros moved to `Arstd::Style`

- Using `::` two colons for module paths instead of a single one, to keep consistency with the Perl and C++ sides of the codebase.