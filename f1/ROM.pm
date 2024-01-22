#!/usr/bin/perl
# ---   *   ---   *   ---
# F1 ROM
# Makes data blocks
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package f1::ROM;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_words);
  use List::Util qw(max);

  use lib $ENV{ARPATH}.'/lib/sys/';

  use Style;

  use lib $ENV{ARPATH}.'/forge/';
  use parent 'f1::blk';

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# cstruc

sub new($class,$name,%O) {
  return f1::blk::new($class,$name,%O);

};

# ---   *   ---   *   ---
# open/close

sub head($self) {
  return "virtual at \$00\n$self->{name}\::";

};

sub foot($self) {
  return "end virtual";

};

# ---   *   ---   *   ---
1; # ret
