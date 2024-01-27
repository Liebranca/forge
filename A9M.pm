# ---   *   ---   *   ---
# A9M
# Buncha globs
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package A9M;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys';

  use Style;
  use Arstd::PM;

  use lib $ENV{'ARPATH'}.'/forge/';

  use A9M::SHARE::path;
  use A9M::SHARE::registers;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly our $MODULES=>[qw(
    A9M::SHARE::registers
    A9M::ismaker

  )];

# ---   *   ---   *   ---
# GBL/ROM

  our $A9M={

    path => {

      root  => $A9M::SHARE::path::ROOT,
      rom   => $A9M::SHARE::path::ROM,
      share => $A9M::SHARE::path::SHARE,

    },

    reg => {

      list   => $A9M::SHARE::registers::LIST,
      cnt    => $A9M::SHARE::registers::CNT,
      cnt_bs => $A9M::SHARE::registers::CNT_BS,
      cnt_bm => $A9M::SHARE::registers::CNT_BM,

    },

    log => undef,

  };

# ---   *   ---   *   ---
# AR/IMP
#
# * runs self builds/updates
#   on exec
#
# * exports $A9M hash on use

sub import($class,@req) {

  return IMP(

    $class,

    \&ON_USE,
    \&ON_EXE,

    @req,

  );

};

# ---   *   ---   *   ---
# ^exec via arperl

sub ON_EXE($class,@args) {

  # sanitize/validate input
  @args=grep {defined $ARG} @args;

  # get logger
  use Arstd::WLog;
  $A9M->{log} //= Arstd::WLog->genesis();
  $A9M->{log}->ex('A9M');

  # walk passed commands
  map {

    my $mode=$ARG;

    # do module update?
    if($mode eq '-u') {

      $A9M->{log}->step('upgrading modules');
      map {$ARG->update($A9M)} @$MODULES;

      $A9M->{log}->step('done');


    # invalid!
    } else {

      $A9M->{log}->err(
        "Unrecognized switch: '$mode'",
        from=>'A9M',

      );

      exit -1;

    };

  } @args;

};

# ---   *   ---   *   ---
# ^module via use

sub ON_USE($class,$from,@mods) {

  Arstd::PM::add_scalar(
    "$from\::A9M",
    "$class\::A9M"

  );

};

# ---   *   ---   *   ---
1; # ret
