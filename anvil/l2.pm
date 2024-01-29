#!/usr/bin/perl
# ---   *   ---   *   ---
# ANVIL L2
# Collapses tree branches
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package anvil::l2;

  use v5.36.0;
  use strict;
  use warnings;

  use Carp;
  use Readonly;
  use English qw(-no_match_words);

  use lib $ENV{ARPATH}.'/lib/sys/';

  use Style;
  use Type;

  use Arstd::Bytes;

  use lib $ENV{ARPATH}.'/forge/';

  use A9M;
  use A9M::SHARE::ISA;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly our $OP_COMMA => qr{^\[\*op\]\s,};

  Readonly our $INS_RE   => qr{^\[\*ins\]\s};

  Readonly our $ARG_REG  => qr{^\[\*reg\]\s};
  Readonly our $ARG_EZY  => qr{^\[\*ezy\]\s};
  Readonly our $ARG_PTR  => qr{^\[\*ptr\]\s};

  Readonly our $CMD_ADDR => qr{^\[\*cmd\]\saddr};

  Readonly our $SPLITD   => qr{^B\d+$};

# ---   *   ---   *   ---
# ~

sub proc($self) {

  my $branch=$self->{l2}->{leaves}->[-1];

  # get operand types and sizes
  split_by_operand($branch);

  map {
    get_operand_type($ARG)

  } @{$branch->{leaves}};

  my $opsize=check_operand_sizes($branch);


  # get full form of instruction
  #
  # we use this as a key into
  # the ISA ROM
  $branch->{value}=~ s[$INS_RE][];

  my $full_form =

    $branch->{value}

  . '_' . (join $NULLSTR,map {
      $ARG->{value}->{type}

    } @{$branch->{leaves}})

  . '_' . $Type::EZY_LIST->[$opsize]

  ;

  say sprintf "$full_form : %08X",
    $A9M->{instab}->{$full_form};

  exit;

};

# ---   *   ---   *   ---
# split into sub-branches
# at nodes marked ([*op] comma)

sub split_by_operand($branch) {

  my @pending = @{$branch->{leaves}};
  my $idex    = 0;


  # walk immediate children
  while(@pending) {


    # get all up to comma
    my $nd=shift @pending;
    my @ar=$branch->match_until(
      $nd,$OP_COMMA,inclusive=>1

    );


    # ^comma found
    if(@ar) {


      # remove the comma itself
      my $ahead  = pop @ar;

      # add sub-branch
      my ($tail) = $branch->insert(
        $idex,"[$idex]"

      );


      # ^populate sub-branch
      $tail->pushlv($nd,@ar);
      $idex++;

      # drop moved nodes and remove comma
      @pending=$branch->all_from($ahead);
      $ahead->discard();


    # ^no comma
    } else {

      # add sub-branch
      my ($tail) = $branch->insert(
        $idex,"[$idex]"

      );

      # ^put everything on it
      $tail->pushlv($nd,@pending);
      last;

    };

  };

};

# ---   *   ---   *   ---
# selfex

sub get_operand_type($branch) {

  if(is_reg($branch)) {

  } elsif(is_mem($branch)) {

  } else {

  };

};

# ---   *   ---   *   ---
# see that *passed* sizes match
#
# overwrites default if any
# other specified

sub check_operand_sizes($branch) {

  my $idex = -1;
  my @lv   = @{$branch->{leaves}};

  # any sizes passed?
  my $ezy  = $INS_DEF_SZ;
  my @have = grep {
    $ARG->{ezy} ne 'def'

  } $branch->branch_values();


  # check that they're all equal if so
  if(@have) {

    $ezy = $have[0]->{ezy};

    # ^die if they don't
    croak "Operand sizes don't match"
    if @have > grep {$ARG->{ezy} eq $ezy} @have;

  };


  # overwite default value
  map {$ARG->{value}->{ezy}=$ezy} @lv;

  return $ezy


};

# ---   *   ---   *   ---
# is operand a register?

sub is_reg($branch) {

  my @series=(
    [$ARG_EZY,$ARG_REG],
    [$ARG_REG]

  );


  # ^match any pattern sequence?
  if(-1 < (my $idex=
    $branch->match_series(@series))

  ) {

    my $ezy  = 'def';
    my $name = 0x00;

    # got size specifier?
    if($idex == 0) {

      ($ezy,$name)=$branch->branch_values();

      $ezy  =~ s[$ARG_EZY][];
      $name =~ s[$ARG_REG][];


    # ^nope, use default
    } else {
      $name =  $branch->{leaves}->[0]->{value};
      $name =~ s[$ARG_REG][];

    };


    # replace node with descriptor
    $branch->{value}={

      type => 'r',

      name => $name,
      ezy  => $ezy,

    };

    $branch->clear();

    return 1;

  };


  # ^nope
  return 0;

};

# ---   *   ---   *   ---
# is operand memory?

sub is_mem($branch) {

  my @series=(

    [$ARG_EZY,$ARG_PTR,$CMD_ADDR],

    [$ARG_EZY,$CMD_ADDR],
    [$ARG_PTR,$CMD_ADDR],

    [$CMD_ADDR],

  );


  # ^match any pattern sequence?
  if(-1 < (my $idex=
    $branch->match_series(@series))

  ) {

    my ($ezy,$ptr,$cmd)=(

      'def',
      $PTR_DEF_SZ_BITS,

      $branch->{leaves}->[0],

    );


    # two optional fields specified
    if($idex==0) {

      ($ezy,$ptr)=
        $branch->branch_values();

      $ezy =~ s[$ARG_EZY][];
      $ptr =~ s[$ARG_PTR][];

      $cmd =  $branch->{leaves}->[2];


    # ^only element size
    } elsif($idex==1) {
      $ezy =  $branch->{leaves}->[0]->{value};
      $ezy =~ s[$ARG_EZY][];

      $cmd =  $branch->{leaves}->[1];

    # ^only ptr size
    } else {

      $ptr =  $branch->{leaves}->[0]->{value};
      $ptr =~ s[$ARG_PTR][];

      $cmd =  $branch->{leaves}->[1];

    };


    # replace node with descriptor
    $branch->{value}={

      type=>'m',

      ezy  =>$ezy,
      ptr  =>$ptr,

      addr =>$cmd,

    };

    $branch->clear();

    return 1;

  };


  # ^nope
  return 0;

};

# ---   *   ---   *   ---
1; # ret
