#!/usr/bin/perl
# ---   *   ---   *   ---
# F1 BITS
# Binary kitchen sink
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package f1::bits;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_words);

  use lib $ENV{ARPATH}.'/lib/sys/';
  use Style;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# shorthand for generating
# fasm code that reads from
# an Arstd::Bitformat

sub csume($fmat,$src,@keys) {

  return (join ';',map {
    "$ARG="
  . "($src shr $fmat->{pos}->{$ARG})"
  . "and $fmat->{mask}->{$ARG}"

  } @keys) . ';';

};

# ---   *   ---   *   ---
# makes const decls from
# an Arstd::Bitformat

sub as_const($fmat,$base,@keys) {

  return (join ';',map {(

    "$base.${ARG}_bs  = $fmat->{size}->{$ARG}",
    "$base.${ARG}_bm  = $fmat->{mask}->{$ARG}",

    "$base.${ARG}_pos = $fmat->{pos}->{$ARG}",

  )} @keys) . ';'

  . "$base._fmat_bs="
  . $fmat->{pos}->{'$:top;>'} . ';'

  . "$base._fmat_bm="
  . $fmat->{mask}->{'$:top;>'} . ';'

  ;

};

# ---   *   ---   *   ---
1; # ret
