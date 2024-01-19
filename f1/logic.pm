#!/usr/bin/perl
# ---   *   ---   *   ---
# F1 LOGIC
# Mostly conditionals ;>
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package f1::logic;

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
# cstruc

sub new($class,$name,%O) {

  # defaults
  $O{expr}   //= 1;
  $O{type}   //= 'if';
  $O{switch} //= undef;

  # make ice
  my $self=f1::blk::new(
    $class,$name,%O

  );

  # write new attrs
  $self->{expr}   = $O{expr};
  $self->{type}   = $O{type};
  $self->{switch} = $O{switch};

  # proc input
  my $buf      = $self->{buf};
  $self->{buf} = $NULLSTR;

  $self->lines($buf);


  return $self;

};

# ---   *   ---   *   ---
# open

sub head($self) {

  goto case_noexpr
  if $self->{expr} eq 'else';


  goto case_switch

  if $self->{type}   eq 'if'
  && defined $self->{switch}
  && $self->{switch} ne 'BEG'
  ;


  case_common:
    return "$self->{type} $self->{expr}";

  case_switch:
    return "else $self->{type} $self->{expr}";

  case_noexpr:
    return "else";

};

# ---   *   ---   *   ---
# ^close

sub foot($self) {

  goto case_switch

  if $self->{type}   eq 'if'
  && defined $self->{switch}
  && $self->{switch} ne 'END'
  ;


  case_common:
    return "end $self->{type}";

  case_switch:
    return $NULLSTR;

};

# ---   *   ---   *   ---
# testcrux

sub import($class,@args) {
  my $sw=f1::logic->new('iff',)

};

# ---   *   ---   *   ---
