#!/usr/bin/perl
# ---   *   ---   *   ---
# ANVIL L1
# Token walker
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package anvil::l1;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_words);

  use lib $ENV{ARPATH}.'/lib/sys/';
  use Style;

  use lib $ENV{ARPATH}.'/forge/';
  use A9M;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.2;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly our $SORTED   => qr{
    ^\[\*([^\]]+)\]

  };

  Readonly our $UNSORTED => qr{
    ^(?! \[\*)

  }x;

# ---   *   ---   *   ---
# ~

sub proc($self) {

  my $branch = $self->{l2}->{leaves}->[-1];
  my @ar     = $branch->branches_in($UNSORTED);

  map {

    my $x=$ARG->{value};

    # is register
    if(defined (my $idex=$A9M->is_reg($x))) {
      $ARG->{value}="[*reg] $idex";

    # ^element size
    } elsif(defined (my $ezy=$A9M->is_ezy($x))) {
      $ARG->{value}="[*ezy] $ezy";

    # ^ptr size
    } elsif(defined (my $ptr=$A9M->is_ptr($x))) {
      $ARG->{value}="[*ptr] $ptr";

    # ^immediate
    } else {
      $ARG->{value}="[*imm] $x";

    };

  } @ar;

};

# ---   *   ---   *   ---
1; # ret
