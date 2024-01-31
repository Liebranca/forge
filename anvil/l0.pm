#!/usr/bin/perl
# ---   *   ---   *   ---
# ANVIL L0
# Byte-sized chunks
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package anvil::l0;

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

  our $VERSION = v0.00.3;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly my $SF=>{
    sqstr => 0x01,
    dqstr => 0x02,
    blank => 0x04,

  };

  Readonly my $CHARSET=>{

    ';' => 'term',

    ',' => 'operator_single',
    ':' => 'operator_single',
    '+' => 'operator_single',
    '-' => 'operator_single',
    '*' => 'operator_single',

    '[' => 'delim_beg',
    ']' => 'delim_end',

    "\n" => 'blank',
    ' '  => 'blank',

  };

  Readonly my $DELIM_TAB=>{
    '[' => 'addr',

  };

# ---   *   ---   *   ---
# procs input codestr

sub read($self,$src) {

  # setup
  my $JMP=load_JMP();

  # walk input
  map {

    # save current char
    $self->{l0}=$ARG;

    # get proc for this char
    my $fn=$JMP->[ord($ARG)];
       $fn=\&$fn;

    # ^invoke and go next
    $fn->($self);


  } split $NULLSTR,$src;


  return;

};

# ---   *   ---   *   ---
# standard char proc

sub default($self) {
  $self->{l1}     .=  $self->{l0};
  $self->{status} &=~ $SF->{blank};

};

# ---   *   ---   *   ---
# expression terminator

sub term($self) {

  commit($self);

  $self->{anchor} = undef;
  $self->{nest}   = [];


  anvil::l1::proc($self);
  anvil::l2::proc($self);

};

# ---   *   ---   *   ---
# argument separator

sub operator_single($self) {

  commit($self);
  $self->{l1}="[*op] $self->{l0}";

  commit($self);

};

# ---   *   ---   *   ---
# nesting

sub nest_up($self) {

  push @{$self->{nest}},$self->{anchor};

  $self->{anchor}=
    $self->{anchor}->{leaves}->[-1];

};

sub nest_down($self) {
  $self->{anchor}=pop @{$self->{nest}};

};

# ---   *   ---   *   ---
# delimiters

sub delim_beg($self) {

  commit($self);

  $self->{l1}=
    "[*cmd] "
  . $DELIM_TAB->{$self->{l0}}
  ;

  commit($self);
  nest_up($self);

};

sub delim_end($self) {
  commit($self);
  nest_down($self);

};

# ---   *   ---   *   ---
# whitespace

sub blank($self) {

  # tick line counter
  if($self->{l0} eq "\n") {
    $A9M->{parse}->{line}++;

  };


  # terminate *token* if first blank
  if(! ($self->{status} & $SF->{blank})) {
    commit($self);

  };

  $self->{status} |= $SF->{blank};

};

# ---   *   ---   *   ---
# push token to tree

sub commit($self) {

  if(length $self->{l1}) {

    if(! defined $self->{anchor}) {

      my $tag=(defined $A9M->is_ins($self->{l1}))
        ? '[*ins]'
        : '[*cmd]'
        ;

      $self->{anchor}=$self->{l2}->inew(
        "$tag $self->{l1}"

      );

    } else {
      $self->{anchor}->inew($self->{l1});

    };

  };

  $self->{l1}=$NULLSTR;

};

# ---   *   ---   *   ---
# generates l0 "jmptab"

sub load_JMP() {

  return [map {

    my $key   = chr($ARG);
    my $value = (exists $CHARSET->{$key})
      ? $CHARSET->{$key}
      : 'default'
      ;

    $value;

  } 0..127];

};

# ---   *   ---   *   ---
1; # ret
