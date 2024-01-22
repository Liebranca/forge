#!/usr/bin/perl
# ---   *   ---   *   ---
# F1 ISMAKER
# Makes instruction sets
# for the Arcane 9
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package f1::ismaker;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_words);
  use List::Util qw(max);

  use lib $ENV{ARPATH}.'/lib/sys/';

  use Style;

  use Arstd::Array;
  use Arstd::String;
  use Arstd::Bytes;


  use lib $ENV{ARPATH}.'/forge/';

  use f1::macro;
  use f1::logic;
  use f1::ROM;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.2;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly our $SIZED_OP=>qr{rm|mr|m};

# ---   *   ---   *   ---
# GBL

  our $Opcode_ID = 0;
  our $Table     = 0;

# ---   *   ---   *   ---
# crux

sub import($class,@args) {

  my $ROM=$class->build_ROM();
  my $EXE=$class->build_EXE();

  my $INC=f1::blk->cat('pinc',$ROM,$EXE);

  say $INC->{buf};

};

# ---   *   ---   *   ---
# makes "procs" to fetch
# instruction data
#
# done to simplify decode ;>

sub build_EXE($class) {


  # decode helper
  my $EXE=f1::macro->new(

    'A9M.OPCODE.read',

    loc  => 1,
    args => [qw(

      src

      load_src load_dst overwrite
      argcnt argflag
      opsize opsize_bm opsize_bs

    )]

  );

  # ^paste the proc
  $EXE->lines(q[


    opid      = src and OPCODE_ID_MASK;
    src       = src shr OPCODE_ID_BITS;


    local flags;
    load  flags word from A9M.OPCODE:opid shl 1;


    load_src  = (flags shr 0) and 1;
    load_dst  = (flags shr 1) and 1;
    overwrite = (flags shr 2) and 1;

    argcnt    = (flags shr 3) and 3;
    argflag   = (flags shr 5) and 7;


    opsize    = 1 shl ((flags shr 8) and 1);
    opsize_bs = opsize shl 3
    opsize_bm = 1 shl opsize


  ]);

  return $EXE;

};

# ---   *   ---   *   ---
# makes fasm virtual from
# generated opcode table

sub build_ROM($class) {

  # access array like a hash
  my $idex   = 0;

  my @keys   = array_keys($Table);
  my @values = array_values($Table);

  # meaningless; pads the equal signs
  my $pad = max(map {length $ARG} @keys);


  # build map of opcode to flags
  my $data = join ";",map {

    my $e=$values[$idex++];

    sprintf

      "A9M.OPCODE.%-${pad}s = \$%04X;"
    . "dw \$%04X",

      $ARG,$e->{id},$e->{ROM}

    ;

  } @keys;


  # make new block
  my $ROM = f1::ROM->new(
    'A9M.OPCODE',
    loc=>0

  );


  # get bitsize of opcodes
  my $opbits = bitsize($Opcode_ID-1);
  my $opmask = (1 << $opbits)-1;


  # ^write as constants
  $ROM->lines(sprintf
    "OPCODE_ID_MASK = %04X;"
  . "OPCODE_ID_BITS = %04X;",

    $opmask,$opbits

  );

  # ^write the table itself
  $ROM->lines($data);


  return $ROM;

};

# ---   *   ---   *   ---
# cstruc instruction(s)

sub opcode($name,$ct,%O) {

  # defaults
  $O{args}      //= 2;
  $O{nosize}    //= 0;

  $O{load_src}  //= 1;
  $O{load_dst}  //= 1;

  $O{overwrite} //= 1;
  $O{dst}       //= 'r';
  $O{src}       //= 'ri';

  # ^binpacked
  my $ROM =
    ($O{load_src}  << 0)
  | ($O{load_dst}  << 1)
  | ($O{overwrite} << 2)
  | ($O{args}      << 3)
  ;


  # get possible operand sizes
  state $sizetab={
    'byte' => 0,
    'word' => 1,

  };

  my @size=(! $O{nosize})
    ? qw(byte word)
    : qw(word)
    ;

  # get possible operand combinations
  my @combo=();

  # ^for two-operand instruction
  if($O{args} eq 2) {

    @combo=grep {length $ARG} map {

      my $dst   = substr $ARG,0,1;
      my $src   = substr $ARG,1,1;

      my $allow =
         (0 <= index $O{dst},$dst)
      && (0 <= index $O{src},$src)
      ;

      $ARG if $allow;

    } 'rr','rm','ri','mr','mi';


  # ^single operand, so no combo ;>
  } else {
    @combo=split $NULLSTR,$O{dst};

  };


  # make descriptors
  my $rflag_tab={

    $NULLSTR => 0b000,

    'dr'     => 0b000,
    'dm'     => 0b001,

    'sr'     => 0b000,
    'sm'     => 0b010,
    'si'     => 0b100,

  };

  return map {

    my $dst  = substr $ARG,0,1;
    my $src  = substr $ARG,1,1;

    my $args =
      ($rflag_tab->{"d$dst"})
    | ($rflag_tab->{"s$src"})

    ;

    my $ins  = "${name}_$ARG";


    # combo is rm/mr
    if("$dst$src" =~ $SIZED_OP) {

      map {

        my $data=

          $ROM

        | ($args << 5)
        | ($sizetab->{$ARG} << 8)

        ;


        "${ins}_${ARG}" => {
          id  => $Opcode_ID++,
          ROM => $data,

        };

      } @size;

    # ^combo is rr
    } else {

      my $data=$ROM | ($args << 5) | (1 << 8);

      "${name}_${ARG}" => {
        id  => $Opcode_ID++,
        ROM => $data,

      };

    };

  } @combo;

};

# ---   *   ---   *   ---
# ^definitions

$Table=[

# ---   *   ---   *   ---
# most used ones

  # imm/mem to reg
  opcode(

    load     => q[dst = src;],
    load_dst => 0,

    dst      => 'r',
    src      => 'mi',

  ),

  # reg/imm to mem
  opcode(

    store    => q[dst = src;],
    load_dst => 0,

    dst      => 'm',
    src      => 'ri',

  ),

  # reg to reg
  opcode(

    copy     => q[dst = src;],
    load_dst => 0,

    dst      => 'r',
    src      => 'r',

  ),

];

# ---   *   ---   *   ---
1; # ret
