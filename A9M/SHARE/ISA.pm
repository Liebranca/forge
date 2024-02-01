#!/usr/bin/perl
# ---   *   ---   *   ---
# A9M ISA:SHARE
# General instruction set data
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package A9M::SHARE::ISA;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_words);

  use lib $ENV{ARPATH}.'/lib/sys/';

  use Style;
  use Type;

  use Arstd::Bytes;
  use Arstd::Struc;

# ---   *   ---   *   ---
# adds to your namespace

  use Exporter 'import';
  our @EXPORT=qw(

    $INS_DEF_SZ
    $INS_DEF_SZ_BITS

    $PTR_DEF_SZ
    $PTR_DEF_SZ_BITS

    $OPCODE_ROM

    $ARGFLAG
    $ARGFLAG_FBS

    $PTR_STACK
    $PTR_SHORT
    $PTR_LONG
    $PTR_POS

    $OPCODE_TAB

  );

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.3;#a
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly our $INS_DEF_SZ    => 'word';
  Readonly our $PTR_DEF_SZ    => 'short';
  Readonly our $OPCODE_ROM_SZ => 'dword';


  # default sizes as bitfield
  Readonly our $INS_DEF_SZ_BITS =>
    bitsize(sizeof($INS_DEF_SZ))-1;

  Readonly our $PTR_DEF_SZ_BITS =>
    bitsize(sizeof($PTR_DEF_SZ))-1;


  # fmat for argument types
  our $ARGFLAG_FBS = 3;
  our $ARGFLAG     = Arstd::Bitformat->new(
    dst => $ARGFLAG_FBS,
    src => $ARGFLAG_FBS,

  );


  # ^possible values for dst/src
  $ARGFLAG->{reg}      = 0b000;

  $ARGFLAG->{memstk}   = 0b001;
  $ARGFLAG->{memshort} = 0b010;
  $ARGFLAG->{memlong}  = 0b011;
  $ARGFLAG->{mempos}   = 0b100;

  # ^additional values for src
  $ARGFLAG->{imm8}     = 0b101;
  $ARGFLAG->{imm16}    = 0b110;


  # ^values shifted to src bit
  map {

    $ARGFLAG->{"src_$ARG"}=
       $ARGFLAG->{$ARG}
    << $ARGFLAG->{pos}->{src}
    ;

  } qw(

    reg

    memstk memshort memlong mempos
    imm8   imm16

  );


  # fmat for opcode data
  our $OPCODE_ROM=Arstd::Bitformat->new(

    load_src    => 1,
    load_dst    => 1,
    overwrite   => 1,

    fix_immsrc  => 2,
    fix_regsrc  => 4,

    argcnt      => 2,
    argflag     => $ARGFLAG->{bitsize},

    opsize      => 2,
    idx         => 16,

  );


  # format for stack relative ptrs
  our $PTR_STACK=Arstd::Bitformat->new(
    imm=>8,

  );

  # format for position relative ptrs
  our $PTR_POS=Arstd::Bitformat->new(
    seg=>4,
    imm=>16,

  );


  # format for short-form relative ptrs
  our $PTR_SHORT=Arstd::Bitformat->new(
    seg=>4,
    reg=>4,
    imm=>8,

  );

  # format for long-form relative ptrs
  our $PTR_LONG=Arstd::Bitformat->new(

    seg   => 4,

    rX    => 4,
    rY    => 4,

    imm   => 10,
    scale => 2,

  );


  # fmat for binary section
  # of resulting ROM
  our $OPCODE_TAB=Arstd::Struc->new(

    id_mask  => ['word'],
    idx_mask => ['word'],

    id_bits  => ['byte'],
    idx_bits => ['byte'],

    opcode   => [$OPCODE_ROM   => 'word'],

    mnemonic => ['plcstr'      => 'word'],
    idx      => ['plcstr,word' => '^opcode'],

  );

# ---   *   ---   *   ---
1; # ret
