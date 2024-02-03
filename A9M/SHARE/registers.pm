# ---   *   ---   *   ---
# A9M VMC REGISTERS:SHARE
# Decls em souls!
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package A9M::SHARE::registers;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;

  use Arstd::Array;
  use Arstd::Bytes;
  use Arstd::Re;
  use Arstd::IO;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.3;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly our $LIST=>[qw(

    ar    br    cr    dr
    er    fr    gr    hr

    xp    xs    sp    sb

    ice   ctx   opt   chan

  )];

  Readonly our $CNT    => int @$LIST;

  Readonly our $CNT_BS => bitsize($CNT-1);
  Readonly our $CNT_BM => bitmask($CNT_BS);

  Readonly our $RE     => re_eiths($LIST);

# ---   *   ---   *   ---
# get token is register
# if so, give idex
# else undef

sub tokin($name) {

  return ($name=~ $RE)
    ? array_iof($LIST,$name)
    : undef
    ;

};

# ---   *   ---   *   ---
# generates *.pinc ROM file
# if this one is updated

sub update($class,$A9M) {

  # get additional deps
  use Shb7::Path;

  use lib $ENV{'ARPATH'}.'/forge/';
  use f1::blk;


  # file to (re)generate
  my $dst="$A9M->{path}->{rom}/registers.pinc";

  # ^missing or older?
  if(moo($dst,__FILE__)) {

    # dbout
    $A9M->{log}->substep('vmc.registers:SHARE');

    # make codestr with constants
    my $blk=f1::blk->new('ROM');

    $blk->lines(

      'define A9M.registers '
    . (join ',',@$LIST) . ';'

    . "A9M.REGISTER_CNT    = $CNT;"
    . "A9M.REGISTER_CNT_BS = $CNT_BS;"
    . "A9M.REGISTER_CNT_BM = $CNT_BM;"

    );

    # ^commit to file
    owc($dst,$blk->{buf});

  };

};

# ---   *   ---   *   ---
1; # ret
