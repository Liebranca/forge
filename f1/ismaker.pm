#!/usr/bin/perl
# ---   *   ---   *   ---
# F1 ISMAKER
# Makes instruction sets
# for the Arcane 9
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package f1::ismaker;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_words);
  use List::Util qw(max);

  use lib $ENV{ARPATH}.'/lib/sys/';

  use Style;

  use Arstd::Array;
  use Arstd::String;
  use Arstd::Bytes;


  use lib $ENV{ARPATH}.'/forge/';

  use f1::macro;
  use f1::logic;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly our $NULLARY=>[qw(
    enter leave ret

  )];

  Readonly our $UNARY=>[qw(
    push pop not neg inc dec

  )];

  Readonly our $BINARY=>[qw(
    mov lea xor and
    shl shr or  not

  )];

  Readonly our $NO_OPSZ=>[
    @$NULLARY,qw(push pop)

  ];

# ---   *   ---   *   ---
# crux

sub import($class,@args) {

  my ($enum,$rng)=get_enum(
    $NULLARY,$UNARY,$BINARY

  );


  # get opid width
  my $cnt  = $rng->{binary}->[1];
  my $bits = bitsize($cnt);

  $enum->lines("MASKOF OPID,$bits");

  # must read opsz bits?
  my $opsz=get_opsz(@$NO_OPSZ);

  # make optype branch
  my $ratcnt=get_ratcnt($rng);


  # dbout
  map {
    map {say $ARG} $ARG->collapse()

  } $enum,$opsz,$ratcnt;


};

# ---   *   ---   *   ---
# make unique ids from enums

sub get_enum($nullary,$unary,$binary) {

  my $blk=f1::blk->new('non',loc=>0);
  my $key='OPID';

  my $rng={

    nullary => [0,int @$unary-1],

    unary   => [int @$nullary,0],
    binary  => [0,0],

  };

  my $align=max(map {
    length $ARG

  } @$nullary,@$unary,@$binary);


  $blk->stcache('align',$align);


  # "nullary" as in zero args ;>
  $blk->enum('OPID',@$nullary);

  # define unary ops
  $blk->enum('OPID',@$unary);
  $rng->{unary}->[1]=$blk->ldcache($key);
  $rng->{binary}->[0]=$blk->ldcache($key)+1;

  # define binary ops
  $blk->enum('OPID',@$binary);
  $rng->{binary}->[1]=$blk->ldcache($key);

  return $blk,$rng;

};

# ---   *   ---   *   ---
# ^makes check for ins
# having operand size

sub get_opsz(@names) {

  my $mac=f1::macro->new(

    '@ipret$get_opsz',

    loc   => 1,
    args  => [],

  );


  # make condition
  my $nohave=join '|',map {
    "(\@ipret.opid = OPID.$ARG)"

  } @names;


  # ^make body
  $mac->switch(

     $nohave => '@ipret.opsz=0;',
     'else'  => '@ipret.opsz=1;'

  );

  return $mac;

};

# ---   *   ---   *   ---
# ^makes check for ins type

sub get_ratcnt($rng) {

  # make new block
  my $mac=f1::macro->new(

    '@ipret$get_ratcnt',

    loc   => 2,
    args  => [],

  );

  # ^make body
  $mac->switch(

     "  (\@ipret.opid >= $rng->{nullary}->[0])"
  .  "| (\@ipret.opid <= $rng->{nullary}->[1])"

  => '@ipret.ratcnt=0;@ipret.ratmask=0',


     "  (\@ipret.opid >= $rng->{unary}->[0])"
  .  "| (\@ipret.opid <= $rng->{unary}->[1])"

  => '@ipret.ratcnt=1;@ipret.ratmask=1',


     "  (\@ipret.opid >= $rng->{binary}->[0])"
  .  "| (\@ipret.opid <= $rng->{binary}->[1])"

  => '@ipret.ratcnt=2;@ipret.ratmask=3'

  );

  return $mac;

};

# ---   *   ---   *   ---
1; # ret
