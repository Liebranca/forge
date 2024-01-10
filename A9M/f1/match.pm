#!/usr/bin/perl
# ---   *   ---   *   ---
# F1 MATCH
# Dang wraps
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package f1::match;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_words);

  use lib $ENV{ARPATH}.'/lib/sys/';
  use Style;

  use lib $ENV{ARPATH}.'/forge/A9M/';
  use parent 'f1::blk';

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# open

sub head($self) {

  return

    "match $self->{name} , "
  . (join ' ',@{$self->{args}})

  . $self->scapop('{')
  ;

};

# ---   *   ---   *   ---
# ^close

sub foot($self) {
  return $self->scapop('}');

};

# ---   *   ---   *   ---
1; # ret

