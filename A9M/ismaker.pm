#!/usr/bin/perl
# ---   *   ---   *   ---
# A9M ISMAKER
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

package A9M::ismaker;

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
  use Arstd::Bitformat;
  use Arstd::IO;


  use lib $ENV{ARPATH}.'/forge/';

  use f1::bits;
  use f1::macro;
  use f1::logic;
  use f1::ROM;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.5;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly our $SIZED_OP   => qr{rm|mr|m};
  Readonly our $INS_DEF_SZ => 'word';

# ---   *   ---   *   ---
# GBL

  our $Opcode_ROM = 0;
  our $Opcode_EXE = 0;

  our $ROM_Table  = [];
  our $EXE_Table  = {};

  our $EXE_Crux   = {};

# ---   *   ---   *   ---
# fmat for opcode data

my $OPCODE_ROM=Arstd::Bitformat->new(

  load_src  => 1,
  load_dst  => 1,
  overwrite => 1,

  argcnt    => 2,
  argflag   => 3,

  opsize    => 1,
  idx       => 16,

);

# ---   *   ---   *   ---
# fmat for memargs flag

my $OPCODE_MFLAG=Arstd::Bitformat->new(
  rel => 1,
  seg => 1,

);

# ---   *   ---   *   ---
# fmat for relative memargs

my $MEMARG_REL=Arstd::Bitformat->new(

  rX    => 4,
  rY    => 4,

  off   => 8,
  scale => 2,

);

# ---   *   ---   *   ---
# crux

sub import($class,@args) {

  # defaults
  my ($name,$dst)=@args;

  $name //= 'isbasic';
  $dst  //= "$ENV{ARPATH}/forge/A9M/ROM";


  # make include
  my $ROM=$class->build_ROM();
  my $EXE=$class->build_EXE();

  my $INC=join "\n",$ROM->collapse(),$EXE->{buf};


  # write to file
  owc("$dst/$name.pinc",$INC);

};

# ---   *   ---   *   ---
# makes procs used during
# decode and execution

sub build_EXE($class) {

  return f1::blk->cat(

    'EXE',

    $class->build_EXE_decoder(),
    $class->build_EXE_logic(),

  );

};

# ---   *   ---   *   ---
# makes a proc to fetch
# instruction data
#
# done to simplify decode ;>

sub build_EXE_decoder($class) {

  my $read=f1::macro->new(

    'A9M.OPCODE.read',

    loc  => 1,
    args => [qw(

      idx src

      load_src load_dst overwrite
      argcnt argflag
      opsize opsize_bm opsize_bs

    )]

  );

  # ^paste the proc
  $read->lines(q[


    local idex;

    idex      = src and OPCODE_ID_MASK;
    src       = src shr OPCODE_ID_BITS;


    local flags;
    load  flags word from A9M.OPCODE:idex shl 1;

  ] . f1::bits::csume(

    $OPCODE_ROM,'flags',qw(

      load_src load_dst overwrite
      argcnt argflag
      opsize

    )) . q[


    opsize    = 1 shl opsize;
    opsize_bs = opsize shl 3;
    opsize_bm = (1 shl opsize_bs)-1;


    idx=

  ] . "(flags shr $OPCODE_ROM->{pos}->{idx})"
    . "and OPCODE_IDX_MASK;"


  );


  return $read

};

# ---   *   ---   *   ---
# fetches instruction
# definitions and makes a
# conditional table for
# executing them

  Readonly my $ARGNAMES=>[
    [],['dst'],['dst','src'],

  ];

sub build_EXE_logic($class) {

  # gen individual instructions
  my $idex = 0;

  return map {

    my $cnt      = $ARG;
    my @branches = ();

    my @defs     = map {

      my ($def,$branch)=inscode($ARG,\$idex);

      push @branches,@$branch;
      $def;

    } grep {
      $EXE_Table->{$ARG}->{argcnt} eq $cnt

    } keys %$EXE_Table;


    # make conditionals?
    if(@defs) {

      my $tab=f1::macro->new(

        "A9M.OPCODE.switch_args$cnt",

        loc  => $idex++,
        args => ['opid',@{$ARGNAMES->[$cnt]}],

      );

      $tab->switch(@branches);
      push @defs,$tab;

    };

    @defs;


  } 0,1,2;

};

# ---   *   ---   *   ---
# makes wraps around an
# instruction definition

sub inscode($body,$iref) {

  my $attr=$EXE_Table->{$body};
  my $args=$ARGNAMES->[$attr->{argcnt}];

  my $ins=f1::macro->new(

    "A9M.OPCODE._exe_$attr->{name}",

    loc  => $$iref+2,
    args => $args,

  );

  my $branch=[
     "opid = $attr->{idx}"
  => "A9M.OPCODE._exe_$attr->{name} "

  .  (join ',' , @$args)

  ];


  # paste
  $ins->lines($body);


  # go next and give
  $$iref++;
  return $ins,$branch;

};

# ---   *   ---   *   ---
# makes fasm virtual from
# generated opcode table

sub build_ROM($class) {

  # access array like a hash
  my $idex   = 0;

  my @keys   = array_keys($ROM_Table);
  my @values = array_values($ROM_Table);

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
  my $opbits  = bitsize($Opcode_ROM-1);
  my $opmask  = (1 << $opbits)-1;

  my $exebits = bitsize($Opcode_EXE-1);
  my $exemask = (1 << $exebits)-1;


  # ^write constants
  $ROM->lines(


    "define A9M.INS_DEF_SZ $INS_DEF_SZ;"

  . "A9M.OPCODE.MEMDST    = 001b;"
  . "A9M.OPCODE.MEMSRC    = 010b;"
  . "A9M.OPCODE.IMMSRC    = 100b;"

  . "A9M.OPCODE.MFLAG_BS  = 2;"
  . "A9M.OPCODE.MFLAG_BM  = 3;"

  . "A9M.OPCODE.MEM_BS_BASE = "
  . $MEMARG_REL->{pos}->{'$:top;>'} . ';'


  . f1::bits::as_const(
      $MEMARG_REL,'bipret.memarg.rel',
      qw(rX rY off scale),

  ) . f1::bits::as_const(
      $OPCODE_MFLAG,'A9M.OPCODE.MFLAG',
      qw(rel seg)

  ) . f1::bits::as_flag(
      $OPCODE_MFLAG,'A9M.OPCODE.MFLAG',
      qw(rel seg)

  ) . (sprintf

      "OPCODE_ID_MASK  = \$%04X;"
    . "OPCODE_ID_BITS  = \$%04X;"

    . "OPCODE_IDX_MASK = \$%04X;"
    . "OPCODE_IDX_BITS = \$%04X;",

      $opmask,$opbits,
      $exemask,$exebits

    ),

  );

  # ^write the table itself
  $ROM->lines($data);


  return $ROM;

};

# ---   *   ---   *   ---
# avoids repeated logic guts

sub fetch_logic($name,%O) {

  if(! exists $EXE_Table->{$O{body}}) {

    $EXE_Table->{$O{body}}={

      %O,

      name => $name,
      idx  => $Opcode_EXE++,

    };

  };

  return $EXE_Table->{$O{body}}->{idx};

};

# ---   *   ---   *   ---
# cstruc instruction(s)

sub opcode($name,$ct,%O) {

  # defaults
  $O{argcnt}    //= 2;
  $O{nosize}    //= 0;

  $O{load_src}  //= int($O{argcnt} == 2);
  $O{load_dst}  //= 1;

  $O{overwrite} //= 1;
  $O{dst}       //= 'r';
  $O{src}       //= 'ri';

  # ^binpacked
  my $ROM=$OPCODE_ROM->bor(

    load_src  => $O{load_src},
    load_dst  => $O{load_dst},
    overwrite => $O{overwrite},

    argcnt    => $O{argcnt},

  );


  # queue logic generation
  my $idx=fetch_logic($name,%O,body=>$ct);


  # get possible operand sizes
  state $sizetab={
    'byte'  => 0,
    'word'  => 1,
    'dword' => 2,
    'qword' => 3,

  };

  my @size=(! $O{nosize})
    ? qw(byte word dword qword)
    : $INS_DEF_SZ
    ;

  # get possible operand combinations
  my @combo=();

  # ^for two-operand instruction
  if($O{argcnt} eq 2) {

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
  my $argflag_tab={

    $NULLSTR => 0b000,
    's'      => 0b000,

    'dr'     => 0b000,
    'dm'     => 0b001,

    'sr'     => 0b000,
    'sm'     => 0b010,
    'si'     => 0b100,

  };


  return map {

    my $dst   = substr $ARG,0,1;

    my $src   = substr $ARG,1,1;
       $src //= $NULLSTR;

    my $argflag =
      ($argflag_tab->{"d$dst"})
    | ($argflag_tab->{"s$src"})

    ;

    my $ins  = "${name}_$ARG";


    map {

      my $data=$ROM | $OPCODE_ROM->bor(

        argflag => $argflag,
        opsize  => $sizetab->{$ARG},
        idx     => $idx,

      );


      "${ins}_${ARG}" => {
        id  => $Opcode_ROM++,
        ROM => $data,

      };

    } @size;

  } @combo;

};

# ---   *   ---   *   ---
# ^definitions

$ROM_Table=[

# ---   *   ---   *   ---
# most used ones

  # imm/mem/reg to reg
  opcode(

    cpy      => q[dst = src;],
    load_dst => 0,

    dst      => 'rm',
    src      => 'rmi',

  ),

  opcode(

    lea      => q[dst = src;],
    load_dst => 0,
    load_src => 0,

    dst      => 'rm',
    src      => 'm',

  ),


# ---   *   ---   *   ---
# bitops

  # reg ^ reg
  opcode(

    xor      => q[dst = dst xor src;],

    dst      => 'rm',
    src      => 'rmi',

  ),

  # reg ^ reg
  opcode(

    and      => q[dst = dst and src;],

    dst      => 'rm',
    src      => 'rmi',

  ),

  # reg ^ reg
  opcode(

    not      => q[dst = not dst;],

    dst      => 'rm',
    argcnt   => 1,

  ),

];

# ---   *   ---   *   ---
1; # ret
