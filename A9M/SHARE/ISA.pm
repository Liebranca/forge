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
    $OPCODE_MFLAG
    $MEMARG_REL

    $OPCODE_TAB

  );

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.3;#b
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



  # fmat for opcode data
  our $OPCODE_ROM=Arstd::Bitformat->new(

    load_src    => 1,
    load_dst    => 1,
    overwrite   => 1,

    fix_immsrc  => 2,
    fix_regsrc  => 4,

    argcnt      => 2,
    argflag     => 3,

    opsize      => 2,
    idx         => 16,

  );


  # fmat for memargs flag
  our $OPCODE_MFLAG=Arstd::Bitformat->new(
    rel => 1,
    seg => 1,

  );


  # fmat for relative memargs
  our $MEMARG_REL=Arstd::Bitformat->new(

    rX    => 4,
    rY    => 4,

    off   => 8,
    scale => 2,

  );


  # fmat for binary section
  # of resulting ROM
  our $OPCODE_TAB=Arstd::Struc->new(

    opcode   => [$OPCODE_ROM   => 'word'],

    mnemonic => ['plcstr'      => 'byte'],
    idx      => ['plcstr,word' => '^opcode'],

  );

# ---   *   ---   *   ---
1; # ret
