# SYNOPSIS

```asm

if ~ defined loaded?Worg
  include 'path/to/Worg.inc'

end if

; ---   *   ---   *   ---

%Worg

  use '.ext' path:to:file

^Worg ENV_ROOT '/subdir/'

```

# DESCRIPTION

A recurring question in fasm boards: how do I ensure a file is included only once? Worg is simply one of many answers. It's original draft coded in just a few hours entirely with fasm 1 macros, it provides a very simple interface to importing code and offers a little bit of help in managing your files.

# WAY IT WORKS

Worg checks for a `define`d symbol by the name of `loaded?<ID>` to identify if a file has already been imported by another dependency somewhere else in the program; `ID` always corresponds to the name of the file without extensions.

The following snippet:

```asm

%Worg
  use '.inc' OS
  use '.inc' Arstd:IO

^Worg ARPATH '/forge/'

```

Looks for the files `OS.inc` and `Arstd/IO.inc` in the `/forge/` subdirectory of the environment variable ARPATH. This invocation will define the symbols `loaded?OS` and `loaded?Arstd.IO` if they are not defined already, such that:

```asm
if ~ defined loaded?OS
  ; will not be executed

end if

```

Uppon first being included, Worg inserts itself into the `loaded?` namespace to allow it's own status to be evaluated in this way.

In addition to file imports, Worg provides the macros `TITLE`, `VERSION` and `AUTHOR` from `Arstd/INCFILE.inc` to go along with it. These are used like so:

```asm

TITLE     module

VERSION   version_string
AUTHOR    'your_name'


```

Which defines the symbols `<module>?version` and `<module>?author` which are used by the `module_info` macro from `Arstd.IO`; and Worg's own `INFO_FIELD` macro can be used to declare your own module data.

Usage of `INFO_FIELD` is fairly straight-forward:

```asm

macro FIELD_NAME value {
  INFO_FIELD name value

}

```

The only requirement is that all your fields are defined *after* `TITLE`.

# FUTURE PLANS

Right from the very start Worg was complete enough for what I needed it for. However, improvements can always be made.

As it stands now, you must always build the basepath to your files from an environment variable, which in certain cases is undesirable; thus adding the option to bypass this argument entirely is on the to-do list.

For any other corner-cases, oddities or annoyances, please open an issue or contact me directly.

Cheers, lyeb
