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
  use Arstd::Bitformat;

# ---   *   ---   *   ---
# adds to your namespace

  use Exporter 'import';
  our @EXPORT=qw(

    $SIZED_OP
    $INS_DEF_SZ

    $OPCODE_ROM
    $OPCODE_MFLAG
    $MEMARG_REL

    $BIN_HEADER

  );

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly our $SIZED_OP   => qr{rm|mr|m};
  Readonly our $INS_DEF_SZ => 'word';

# ---   *   ---   *   ---
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

# ---   *   ---   *   ---
# fmat for memargs flag

our $OPCODE_MFLAG=Arstd::Bitformat->new(
  rel => 1,
  seg => 1,

);

# ---   *   ---   *   ---
# fmat for relative memargs

our $MEMARG_REL=Arstd::Bitformat->new(

  rX    => 4,
  rY    => 4,

  off   => 8,
  scale => 2,

);

# ---   *   ---   *   ---
# fmat for binary section
# of resulting ROM

our $BIN_HEADER=Arstd::Bitformat->new(

  opcode_len  => 16,
  opcode_cnt  => 16,

  string_base => 16,

);

# ---   *   ---   *   ---
1; # ret
