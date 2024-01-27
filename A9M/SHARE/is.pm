#!/usr/bin/perl
# ---   *   ---   *   ---
# A9M IS:SHARE
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

package A9M::SHARE::is;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_words);

  use lib $ENV{ARPATH}.'/lib/sys/';

  use Style;
  use Arstd::Struc;

# ---   *   ---   *   ---
# adds to your namespace

  use Exporter 'import';
  our @EXPORT=qw(

    $INS_DEF_SZ

    $OPCODE_ROM
    $OPCODE_MFLAG
    $MEMARG_REL

    $OPCODE_TAB

  );

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.2;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly our $INS_DEF_SZ    => 'word';
  Readonly our $OPCODE_ROM_SZ => 'brad';


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
    opcode => [$OPCODE_ROM   => 'wide'],
    idx    => ['plcstr,wide' => '^opcode'],

  );

# ---   *   ---   *   ---
1; # ret
