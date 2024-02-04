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

  our $VERSION = v0.00.3;#b
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

      ptr => $Type::PTR_RE,
      ezy => $Type::EZY_RE,

      reg => $A9M::SHARE::registers::RE,
      ins => undef,

    },

    isa   => undef,
    log   => undef,


    # stores current procedure metadata
    proc => {
      segcnt => 1,

    },

    # output buffer, holding binary data
    out => $NULLSTR,

    # ^absolute pointer to current byte
    '$' => 0x00000000,

    # name of current segment
    curseg => undef,

    # stores base addr of segments
    #
    # we take references to this whenever
    # working with symbols so that they don't
    # have to be defined right away ;>
    segbase => {},

    # ^stores the references themselves
    #
    # done to keep track of undefined symbols
    # and assign an idex to each required symbol
    # within a specific proc
    segref => {},


    # parser metadata, mostly used for debug
    parse => {

      fname => $NULLSTR,
      line  => 0,

    },


    # directive interpreter state
    cmdflag => {
      public=>0,

    },

    # "public" (iface) symbols get added to this list
    public=>[],

  },'A9M';


  # ^set filepaths
  $A9M->{fpath}->{isa}=
    "$A9M->{path}->{rom}/ISA";

# ---   *   ---   *   ---
# resets the directive interpreter

sub reset_ipret($self) {

  $self->{cmdflag}={
    public=>0,

  };

};

# ---   *   ---   *   ---
# give error at lineno

sub parse_error($self,$me,$lvl=$AR_FATAL) {

  my $pre='FATAL';

  if($lvl eq $AR_WARNING) {
    $pre='WARNING';

  } elsif($lvl eq $AR_ERROR) {
    $pre='ERROR';

  };


  say

    "$pre: $me "
  . "at $self->{parse}->{fname} "
  . "line $self->{parse}->{line}"

  ;

  exit -1 if $lvl eq $AR_FATAL;

};

# ---   *   ---   *   ---
# adds symbol reference to
# current proc

sub symref($self,$name) {

  if(! exists $self->{segref}->{$name}) {
    $self->{segref}->{$name}=
      $self->{proc}->{segcnt}++;

  };

  return $self->{segref}->{$name};

};

# ---   *   ---   *   ---
# get current position,
# relative to current segment

sub relpos($self) {

  my $base=($self->{curseg})
    ? $self->{segbase}->{$self->{curseg}}
    : 0x00000000
    ;

  return $self->{'$'} - $base;

};

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

  return ($s=~ $self->{retab}->{ptr})
    ? bitsize(sizeof($s))-1
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

    $A9M->{isa}->{mnemonic}=
      $A9M::ISA::Cache->{mnemonic};

    my $ins_re=re_eiths(
      [@{$A9M->{isa}->{mnemonic}}]

    );

    $A9M->{retab}->{ins} = $ins_re;

  };


  # share hashref with caller
  Arstd::PM::add_scalar(
    "$to\::A9M","$from\::A9M"

  );

};

# ---   *   ---   *   ---
# load instruction set ROM
# generated by A9M::ISA

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
# directive: segment decl

sub cmd_seg($self,$branch) {

  # get specs from previous iterations
  my $public=$self->{cmdflag}->{public};

  # get first operand
  my $lv    = $branch->{leaves};
  my $ahead = $lv->[0]->{leaves}->[0];
  my $name  = $ahead->{value};

  # ^clear tag
  $name=~ s[$anvil::l2::ARG_SYM][];

  # ^set as current segment
  # then write to segment table
  $self->{curseg}=$name;
  $self->{segbase}->{$name}=$self->{'$'};


  return undef;

};

# ---   *   ---   *   ---
# directive specifier: make public

sub cmd_public($self,$branch) {

  # get first operand
  my $lv    = $branch->{leaves};
  my $ahead = $lv->[0]->{leaves}->[0];

  # ^make first operand the next directive
  # then pop it from the sub-branch
  $branch->{value}=$ahead->{value};
  $ahead->discard();

  # ^convert from name to command
  $branch->{value}=~ s[\*imm][\*cmd];

  # ^setting this flag is the real point
  # of having the directive ;>
  $self->{cmdflag}->{public}=1;


  return $branch;

};

# ---   *   ---   *   ---
1; # ret
