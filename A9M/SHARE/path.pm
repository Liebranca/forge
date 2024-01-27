# ---   *   ---   *   ---
# A9M PATH:SHARE
# Just so I don't have to type em!
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package A9M::SHARE::path;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly our $ROOT  => "$ENV{ARPATH}/forge/A9M";

  Readonly our $ROM   => "$ROOT/ROM";
  Readonly our $SHARE => "$ROOT/SHARE";

# ---   *   ---   *   ---
1; # ret
