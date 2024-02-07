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

  our $VERSION = v0.00.5;#b
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

    # ^subdivs of
    blk  => [],

    iblk => 0,
    cblk => undef,


    # name of current segment
    segment => {},
    curseg  => undef,


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

    pass => 0,


    # directive interpreter state
    cmdflag => {
      public=>0,

    },

    # "public" (iface) symbols get added to this list
    public=>[],

    # enable/disable debug prints
    debug => 0,

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
# resets state for a new
# iteration of parse blocks

sub next_pass($self) {
  $self->{pass}++;
  $self->{iblk}=0;

};

# ---   *   ---   *   ---
# make output sub-segment

sub new_parse_block($self) {

  state $loc=0x00;


  # calc base of new
  # (old->base + old->ptr)
  my $base=0x00;

  if(defined $self->{cblk}) {
    $base  = $self->{cblk}->{base};
    $base += $self->{cblk}->{ptr}
    if defined $base;

  };


  # make ice
  my $blk={

    loc  => $loc++,

    ptr  => 0x0000,
    buf  => $NULLSTR,

    base => $base,


    pending => [],
    rewrit  => [],

  };


  # save and make current
  push @{$self->{blk}},$blk;
  $self->{cblk}=$blk;


  return $blk;

};

# ---   *   ---   *   ---
# ^walk

sub get_parse_block($self) {

  my $idex = $self->{iblk}++;
  my $pool = $self->{blk};

  # have blocks left?
  if($idex < @$pool) {

    my $blk=$pool->[$idex];

    $blk->{ptr}   = 0;
    $self->{cblk} = $blk;

    return $blk;

  # ^nope, signal endof
  } else {
    return undef;

  };

};

# ---   *   ---   *   ---
# combine output of all blocks

sub cat_parse_blocks($self) {

  my $out=$NULLSTR;

  # reset
  $self->next_pass();

  # ^walk
  while(my $blk=$self->get_parse_block()) {
    $out .= $blk->{buf};

  };

  return $out;

};

# ---   *   ---   *   ---
# put branch collapse on hold

sub solve_next_pass($self,$branch,$mode=0) {

  my $pool=($mode == 0)
    ? $self->{cblk}->{pending}
    : $self->{cblk}->{rewrit}
    ;

  push @$pool,[$self->{cblk}->{ptr},$branch];


  return;

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
# cat data to current block

sub blkout($self,$data) {

  # lis current block
  my $blk = $self->{cblk};


  # array to string
  my $s    = join $NULLSTR,@$data;
  my $size = length $s;

  # first pass
  if(! $self->{pass}) {

    # push to new block if branches
    # pending collapse!
    my $pool = $blk->{pending};

    if($blk eq $self->{cblk} && @$pool) {
      $blk=$self->new_parse_block();

    };

    # extend output buf
    $blk->{buf} .= $s;


  # ^overwrite existing buf bytes on
  # any subsequent pass
  } else {

    substr $blk->{buf},
      $blk->{ptr},$size,$s;

  };


  # go next
  $blk->{ptr} += $size;

};

# ---   *   ---   *   ---
# lookup value by name

sub symfet($self,$name) {

  my $value = undef;
  my $ezy   = 1;

  # is segment name?
  if(exists $self->{segment}->{$name}) {

    my $blk = $self->{segment}->{$name};

    $value = $blk->{base};
#    $ezy   = 1;

  };


  return ($ezy,$value);

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
  my $ahead = $lv->[0];
  my $name  = $ahead->{value}->{name};

  # ^set as current segment
  $self->new_parse_block();

  $self->{curseg}           = $name;
  $self->{segment}->{$name} = $self->{cblk};


  # debug
  if(defined $self->{cblk}->{base}) {

    $self->dbout(sprintf "%-16s:SEGAT %04X",
      $name,$self->{cblk}->{base}

    );

  } else {

    $self->dbout(
      sprintf "%-16s:SEGAT [0?]",$name

    );

  };


  return undef;

};

# ---   *   ---   *   ---
# directive specifier: make public

sub cmd_public($self,$branch) {

  # get first operand
  my $lv    = $branch->{leaves};
  my $ahead = $lv->[0];
  my $name  = $ahead->{value}->{name};

  # ^make first operand the next directive
  # then pop it from the sub-branch
  $branch->{value}=$ahead->{value}->{name};
  $ahead->flatten_branch();

  # ^convert from name to command
  $branch->{value}= "[*cmd] $name";

  # ^setting this flag is the real point
  # of having the directive ;>
  $self->{cmdflag}->{public}=1;


  return $branch;

};

# ---   *   ---   *   ---
# out to stderr

sub dbout($self,@me) {

  map {say {*STDERR} $ARG} @me
  if $self->{debug};

};

# ---   *   ---   *   ---
1; # ret
