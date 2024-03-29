#!/usr/bin/perl
# ---   *   ---   *   ---
# F1 MACRO
# Bane of programmers
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package f1::macro;

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

  our $VERSION = v0.00.2;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# cstruc

sub new($class,$name,%O) {

  # defaults
  $O{args} //= [];

  # make ice
  my $self=f1::blk::new(
    $class,$name,%O

  );

  $self->{args}=$O{args};


  return $self;

};

# ---   *   ---   *   ---
# open

sub head($self) {

  my $pad=' ' x (@{$self->{args}} > 0);

  return

    "macro $self->{name} "
  . (join ',',@{$self->{args}})
  . $pad

  . $self->scapop('{')
  ;

};

# ---   *   ---   *   ---
# ^close

sub foot($self) {
  return $self->scapop('}');

};

# ---   *   ---   *   ---
# wraps for match

package f1::match;

  use v5.36.0;
  use strict;
  use warnings;

  use lib $ENV{ARPATH}.'/forge/A9M/';
  use parent 'f1::blk';

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
# wraps for rept

package f1::rept;

  use v5.36.0;
  use strict;
  use warnings;

  use lib $ENV{ARPATH}.'/forge/A9M/';
  use parent 'f1::blk';

# ---   *   ---   *   ---
# open

sub head($self) {

  return

    "rept $self->{name} "
  . (join ':',@{$self->{args}})

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
