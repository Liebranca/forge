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
  use Type;

  use Arstd::Array;
  use Arstd::Bytes;
  use Arstd::Re;
  use Arstd::IO;
  use Arstd::PM;

  use lib $ENV{'ARPATH'}.'/forge/';

  use A9M::SHARE::ISA;
  use A9M::SHARE::path;
  use A9M::SHARE::registers;

  use A9M::ISA;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.2;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly our $MODULES=>[qw(
    A9M::ISA
    A9M::SHARE::registers

  )];

# ---   *   ---   *   ---
# GBL/ROM
  our $A9M=bless {

    path  => {

      root  => $A9M::SHARE::path::ROOT,
      rom   => $A9M::SHARE::path::ROM,
      share => $A9M::SHARE::path::SHARE,

    },

    reg   => {

      list   => $A9M::SHARE::registers::LIST,
      cnt    => $A9M::SHARE::registers::CNT,
      cnt_bs => $A9M::SHARE::registers::CNT_BS,
      cnt_bm => $A9M::SHARE::registers::CNT_BM,

    },

    fpath => {
      isa => $NULLSTR,

    },

    retab => {

      ptr => re_eiths(
        [qw(thin wide long)]

      ),

      ezy =>re_eiths(
        [qw(byte word dword qword)]

      ),

      reg => $A9M::SHARE::registers::RE,
      ins => undef,

    },

    isa   => undef,
    log   => undef,

  },'A9M';


  # ^set filepaths
  $A9M->{fpath}->{isa}=
    "$A9M->{path}->{rom}/ISA";


# ---   *   ---   *   ---
# regex wraps: got register?

sub is_reg($self,$name) {
  return A9M::SHARE::registers::tokin($name);

};

# ---   *   ---   *   ---
# ^got size specifier?

sub is_ezy($self,$s) {

  return ($s=~ $self->{retab}->{ezy})
    ? bitsize(sizeof($s))-1
    : undef
    ;

};

# ---   *   ---   *   ---
# ^got addr size specifier?

sub is_ptr($self,$s) {

  state $idex={
    thin=>1,
    wide=>2,
    long=>3,

  };

  return ($s=~ $self->{retab}->{ptr})
    ? $idex->{$s}
    : undef
    ;

};

# ---   *   ---   *   ---
# ^got a valid instruction name?

sub is_ins($self,$name) {

  return ($name=~ $self->{retab}->{ins})
    ? array_iof($self->{isa}->{mnemonic},$name)
    : undef
    ;

};

# ---   *   ---   *   ---
# AR/IMP
#
# * runs self builds/updates
#   on exec
#
# * exports $A9M hash on use,
#   loading instruction ROM

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

sub ON_USE($from,$to,@mods) {

  # get ROM if not loaded yet
  if(my $ROM=load_ISA()) {

    my $ins_re=re_eiths(
      [@{$ROM->{mnemonic}}]

    );

    $A9M->{retab}->{ins}=$ins_re;

  };


  # share hashref with caller
  Arstd::PM::add_scalar(
    "$to\::A9M","$from\::A9M"

  );

};

# ---   *   ---   *   ---
# load instruction set ROM
# generated by A9M::ismaker

sub load_ISA() {

  if(! defined $A9M->{isa}) {

    my $len   = undef;
    my $bytes = orc("$A9M->{fpath}->{isa}.bin");

    ($A9M->{isa},$len)=
      $OPCODE_TAB->from_bytes(\$bytes);

    return $A9M->{isa};


  } else {
    return 0;

  };

};

# ---   *   ---   *   ---
1; # ret
