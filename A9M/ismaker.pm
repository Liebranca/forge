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
  use Type;

  use Arstd::Array;
  use Arstd::String;
  use Arstd::Bytes;
  use Arstd::Bitformat;
  use Arstd::IO;


  use lib $ENV{ARPATH}.'/forge/';

  use A9M::SHARE::is;

  use f1::bits;
  use f1::macro;
  use f1::logic;
  use f1::ROM;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.8;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# GBL

  our $Opcode_ROM = 0;
  our $Opcode_EXE = 0;

  our $ROM_Table  = [];
  our $EXE_Table  = {};

  our $EXE_Crux   = {};
  our $Paths      = {};

# ---   *   ---   *   ---
# crux

sub import($class,@args) {


  # defaults
  my ($name,$dst)=@args;

  $name //= 'isbasic';
  $dst  //= "$ENV{ARPATH}/forge/A9M/ROM";

  $Paths->{fdst}  = $dst;
  $Paths->{fname} = $name;


  # make include
  my ($ROM)=$class->build_ROM();
  my $EXE=$class->build_EXE();

  # ^flatten
  my $INC=join "\n",$ROM->collapse(),$EXE->{buf};

  # ^write to file
  owc("$Paths->{fdst}/$Paths->{fname}.pinc",$INC);

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
      immbs immbm

    )]

  );

  # ^paste the proc
  $read->lines(q[


    local idex;

    idex      = src and OPCODE_ID_MASK;
    src       = src shr OPCODE_ID_BITS;


    local flags;
    load  flags dword from A9M.OPCODE:idex shl 2;

    local fix_immsrc;

  ] . f1::bits::csume(

    $OPCODE_ROM,'flags',qw(

      load_src load_dst overwrite
      fix_immsrc

      argcnt argflag
      opsize

    )) . q[


    opsize    = 1 shl opsize;
    opsize_bs = opsize shl 3;
    opsize_bm = (1 shl opsize_bs)-1;
    opsize_bm = opsize_bm
    or (sizebm.qword * (opsize_bs shr 6));

    if fix_immsrc > 0;
      immbs = (1 shl (fix_immsrc-1)) shl 3;
      immbm = (1 shl immbs)-1;

    else;
      immbs = opsize_bs;
      immbm = opsize_bm;

    end if;


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

        loc  => ++$idex,
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
      "A9M.OPCODE.%-${pad}s = \$%04X;",
      $ARG,$e->{id}

    ;

  } @keys;
  $idex=0;


  # the actual flags?
  # out them to a separate file!
  #
  # done so anvil can imp them too ;>
  my $fdata  = f1::blk->new('fdata',binary=>1);

  # get name=>opid
  my @strtab = map {
    $ARG=>$values[$idex++]->{id}

  } @keys;

  # ^make binary ROM part
  $fdata->strucseg(

    $OPCODE_TAB,

    opcode => [map {$ARG->{ROM}} @values],
    idx    => [@strtab],

  );


  # make new block for constants...
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

  # ^write the nshare table bits
  $ROM->lines($data);

  # ^append opcode section to ROM
  my $seg={@{$fdata->{seg}}};

  $ROM->lines(

    "file '$Paths->{fdst}"
  . "/$Paths->{fname}.bin'"

  . ":$seg->{opcode}->[0]"
  . ",$seg->{opcode}->[1]"

  . ';'

  );


  # save share table bits to file
  owc(

    "$Paths->{fdst}/$Paths->{fname}.bin",
    $fdata->{buf}

  );


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
  $O{argcnt}      //= 2;
  $O{nosize}      //= 0;

  $O{load_src}    //= int($O{argcnt} == 2);
  $O{load_dst}    //= 1;

  $O{fix_immsrc}  //= 0;
  $O{fix_regsrc}  //= 0;

  $O{overwrite}   //= 1;
  $O{dst}         //= 'rm';
  $O{src}         //= 'rmi';

  # ^for writing/instancing
  my $ROM={

    load_src    => $O{load_src},
    load_dst    => $O{load_dst},
    overwrite   => $O{overwrite},

    fix_immsrc  => $O{fix_immsrc},
    fix_regsrc  => $O{fix_regsrc},

    argcnt      => $O{argcnt},

  };


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

      my $data={

        %$ROM,

        argflag => $argflag,
        opsize  => $sizetab->{$ARG},
        idx     => $idx,

      };


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

  ),

  # our beloved
  # load effective address ;>
  opcode(
    lea      => q[dst = src;],
    load_dst => 0,
    load_src => 0,

    src      => 'm',

  ),


# ---   *   ---   *   ---
# bitops

  opcode(xor  => q[dst = dst xor src;]),
  opcode(and  => q[dst = dst and src;]),
  opcode(or   => q[dst = dst or src;]),

  opcode(not  => q[dst = not dst;],argcnt => 1),

  opcode(xnor => q[dst = not (dst xor src);]),
  opcode(nor  => q[dst = not (dst or src);]),
  opcode(nand => q[dst = not (dst and src);]),


  # bitmask, all ones
  opcode(

    bones => q[
      dst = (1 shl (src and $3F))-1;
      dst = dst or (sizebm.qword * (src shr 6));

    ],

    fix_immsrc => 1,

  ),

  opcode(

    shl        => q[dst = dst shl src;],

    fix_immsrc => 1,
    fix_regsrc => 3,

  ),

  opcode(

    shr        => q[dst = dst shr src;],

    fix_immsrc => 1,
    fix_regsrc => 3,

  ),

  opcode(bsf => q[dst = bsf src;]),
  opcode(bsr => q[dst = bsr src;]),


  # bit rotate right
  # a thing of pure beauty!
  opcode(

    ror => q[

      local out;
      local mask;
      local shift;

      A9M.OPCODE._exe_bones mask,src;

      shift = bipret.opsize_bs-src;
      out   = (dst and mask) shl shift;
      dst   = (dst shr src)  or  out;

    ],

    fix_immsrc => 1,
    fix_regsrc => 3,

  ),

  # ^rotate left ;>
  opcode(

    rol => q[

      local out;
      local mask;
      local shift;

      A9M.OPCODE._exe_bones mask,src;

      shift = bipret.opsize_bs-src;
      out   = dst and (mask shl shift);
      dst   = (dst shl src)  or  (out shr shift);

    ],

    fix_immsrc => 1,
    fix_regsrc => 3,

  ),

# ---   *   ---   *   ---
# math

  opcode(add  => q[dst = dst+src;]),

  opcode(sub  => q[dst = dst-src;]),
  opcode(mul  => q[dst = dst*src;]),
  opcode(div  => q[dst = dst/src;]),

  opcode(inc => q[dst = dst+1;],argcnt => 1),
  opcode(dec => q[dst = dst-1;],argcnt => 1),
  opcode(neg => q[dst = -dst;] ,argcnt => 1),


  # waltzaround for integer overflow
  opcode(badd => q[

    local shift;
    local carry;
    local res;

    carry = dst and src;
    res   = dst xor src;

    while ~(carry = 0);
      shift = (carry and 0x7FFFFFFFFFFFFFFF) shl 1;
      carry = res and shift;
      res   = res xor shift;

    end while;

    dst = res;

  ]),

];

# ---   *   ---   *   ---
1; # ret
