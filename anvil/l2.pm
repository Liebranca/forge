#!/usr/bin/perl
# ---   *   ---   *   ---
# ANVIL L2
# Collapses tree branches
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package anvil::l2;

  use v5.36.0;
  use strict;
  use warnings;

  use Carp;
  use Readonly;
  use English qw(-no_match_words);

  use lib $ENV{ARPATH}.'/lib/sys/';

  use Style;
  use Type;

  use Arstd::Bytes;
  use Arstd::Bitformat;
  use Arstd::String;
  use Arstd::Int;

  use lib $ENV{ARPATH}.'/forge/';

  use A9M;
  use A9M::ISA;
  use A9M::SHARE::ISA;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.7;#a
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly our $OP_COMMA => qr{^\[\*op\]\s,};
  Readonly our $OP_PLUS  => qr{^\[\*op\]\s\+};
  Readonly our $OP_MINUS => qr{^\[\*op\]\s\-};
  Readonly our $OP_COLON => qr{^\[\*op\]\s\:};
  Readonly our $OP_ASTER => qr{^\[\*op\]\s\*};

  Readonly our $SYM_NAME =>
    qr{[_A-Za-z][_A-Za-z0-9]*};

  Readonly our $INS_RE   => qr{^\[\*ins\]\s};
  Readonly our $CMD_RE   => qr{^\[\*cmd\]\s};

  Readonly our $ARG_REG  => qr{^\[\*reg\]\s};
  Readonly our $ARG_EZY  => qr{^\[\*ezy\]\s};
  Readonly our $ARG_PTR  => qr{^\[\*ptr\]\s};
  Readonly our $ARG_IMM  => qr{^\[\*imm\]\s};
  Readonly our $ARG_SYM  => qr{^\[\*sym\]\s};

  Readonly our $ARG_PENDING => qr{
    (?: $ARG_IMM|$ARG_SYM)
    $SYM_NAME

  }x;

  Readonly our $IMM_SYM  =>
    qr{$ARG_IMM$SYM_NAME};

  Readonly our $SYM_LEFT => qr{($SYM_NAME\:\:)+};

  Readonly our $CMD_ADDR => qr{${CMD_RE}addr};

  Readonly our $SPLITD   => qr{^B\d+$};


# ---   *   ---   *   ---
# process token-tree representing
# a single expression

sub proc($self,$branch) {


  # make sub-branches from commas
  reproc_branch:

  split_by_operand($branch);

  # get operand types and sizes
    map {
      cat_symbols($ARG);
      get_operand_type($ARG);

    } @{$branch->{leaves}};


  # step into interpreter if top-level
  # node is labeled "command"
  #
  # this means: do not encode, just execute
  # some directive and evaluate it's result...
  #
  # IF the directive returns a new node,
  # evaluate *that* as the next instruction or
  # directive!
  #
  # this keeps repeating until we get an
  # instruction to encode, or a directive that
  # returns undef ;>

  if($branch->{value}=~ $CMD_RE) {

    # clear the [*cmd] tag
    my $name =  $branch->{value};
       $name =~ s[$CMD_RE][];

    # ^get subroutine from cmd!
    $name   = "cmd_$name";
    $branch = $A9M->$name($branch);


    # need for repeat?
    goto reproc_branch if $branch;

    # ^else terminate ipret and keep parsing
    $A9M->reset_ipret();
    return;


  # ^else process instruction!
  } else {

    # double-check sizes
    $branch->{opsize}=
      check_operand_sizes($branch);

    # either encode the instruction now
    # or push it to the next pass
    pack_instruction($branch)
    if defined_operands($branch);

  };

};

# ---   *   ---   *   ---
# revisit suspended branches

sub solve_pending($self) {

  while(my $blk=$A9M->get_parse_block()) {

    my $pool=$blk->{rewrit};
    next if ! @$pool;

    # ^make copy and clear
    my @pool  = @$pool;
       @$pool = ();

    # ^walk copy
    map {


      # seek to saved position
      my ($ptr,$branch)=@$ARG;
      $blk->{ptr}=$ptr;


      # get previously undefined values
      resolve_symbols($branch);

      # retry encoding the instruction
      pack_instruction($branch)
      if defined_operands($branch);

    } @pool;

  };

};

# ---   *   ---   *   ---
# ^get value from symbol name

sub resolve_symbols($branch) {

  map {

    if($ARG->{type}=~ m[i]) {

      my $name=$ARG->{name};
      my ($size,$value)=$A9M->symfet($name);

      $ARG->{size}  = $size;
      $ARG->{value} = $value;

    };

  } $branch->branch_values();

};

# ---   *   ---   *   ---
# bytepack instruction

sub pack_instruction($branch) {

  # clear [*ins] tag
  $branch->{value}=~ s[$INS_RE][];

  # fetch instruction matching opsize and
  # argument types
  my @argtypes=map {
      $ARG->{value}->{type}

  } @{$branch->{leaves}};

  # get the gory details!
  my $meta=A9M::ISA->get_ins_meta(
    $branch->{value}

  );

  # ^validate
  $A9M->parse_error(
    "unexistent"

  ) if ! defined $meta;


  # handle instruction quirks
  $branch->{opsize} = ($meta->{fix_size})
    ? (sizeof($meta->{fix_size}->[0]) >> 1)-1
    : $branch->{opsize}
    ;



  # get encoding accto args
  my $idex=A9M::ISA->get_ins_idex(

    $branch->{value},
    $branch->{opsize},

    @argtypes

  );

  # ^validate
  $A9M->parse_error(
    "unencodable or unexistent"

  ) if ! defined $idex;


  my $idex_bs=$A9M->{isa}->{id_bits}->[0];

# ---   *   ---   *   ---
# NOTE:
#
# with this idex, we can fetch instruction
# metadata from the $A9M->{opcode} array
#
# that's the table the decoder reads from,
# so all we need to encode is idex and operands!
#
# the tradeoff is that our ROM is pretty big,
# at exactly 1KB for every 256 encodings,
# as it holds all the flags that we'd otherwise
# store within the opcode itself...
#
# but this way we can manage much shorter
# opcodes, and minimal decoder logic, which is
# way more important ;>
#
# ---   *   ---   *   ---


  # get opcode and total bytesize
  my ($cnt,$args) = @{$branch->{packed_args}};


  my $opcode   = $idex | ($args << $idex_bs);
  my $bytesize = int_urdiv($cnt+$idex_bs,8);


  # break up into bpack chunks
  my @types  = array_typeof($bytesize);
  my @opcode = map {

    my $bits = sizeof($ARG) << 3;
    my $mask = bitmask($bits);

    my $out  = $opcode & $mask;

    $opcode >>= $bits;
    $out;

  } @types;


  # cat opcode to out and advance ptr
  my $fmat      = join ',',@types;
  my ($ct,@len) = bpack($fmat,@opcode);

  my $diff      = $bytesize-$len[-1];

  push @$ct,chr(0x00) x $diff;

  $A9M->blkout($ct);


  # dbout, nevermind this
  $A9M->dbout(

    (sprintf "  %016X",$opcode),

    '  ' . ($cnt+$idex_bs) . "-bit opcode",
    '  ' . $bytesize . " bytes\n"

  );

};

# ---   *   ---   *   ---
# bit-pack operands
# this also expands type

sub defined_operands($branch) {

  my $args   = 0x00;
  my $cnt    = 0;
  my $solved = 0b01;

  # walk hashrefs
  map {


    # get numrepr for element
    my $e=$ARG->{value};
    my ($size,$value)=pack_operand($e);


    # value known?
    if(defined $value) {
      $args |= $value << $cnt;
      $cnt  += $size;

    # ^value unknown, but known size!
    } elsif(defined $size && $size ne 0) {
      $cnt    += $size;
      $solved |= 2;

    # ^both value and size are unknown
    # put encoding on hold
    } else {
      $solved |=  2;
      $solved &=~ 1;

    };


  } @{$branch->{leaves}};


  # save results in branch
  $branch->{packed_args}=[$cnt,$args];


  # true if arguments couldn't be fully resolved
  #
  # the instruction can still be *written*,
  # but it must be re-evaluated at a later pass
  $A9M->solve_next_pass($branch,$solved & 1)
  if $solved & 2;

  # true if instruction can be *written*
  #
  # if not, that means starting a new parse block
  # to write encodable instructions...
  return $solved & 1;

};

# ---   *   ---   *   ---
# split into sub-branches
# at nodes marked ([*op] comma)

sub split_by_operand($branch) {

  my @pending = @{$branch->{leaves}};
  my $idex    = 0;


  # walk immediate children
  while(@pending) {


    # get all up to comma
    my $nd=shift @pending;
    my @ar=$branch->match_until(
      $nd,$OP_COMMA,inclusive=>1

    );


    # ^comma found
    if(@ar) {


      # remove the comma itself
      my $ahead  = pop @ar;

      # add sub-branch
      my ($tail) = $branch->insert(
        $idex,"[$idex]"

      );


      # ^populate sub-branch
      $tail->pushlv($nd,@ar);
      $idex++;

      # drop moved nodes and remove comma
      @pending=$branch->all_from($ahead);
      $ahead->discard();


    # ^no comma
    } else {

      # add sub-branch
      my ($tail) = $branch->insert(
        $idex,"[$idex]"

      );

      # ^put everything on it
      $tail->pushlv($nd,@pending);
      last;

    };

  };

};

# ---   *   ---   *   ---
# join immediates and operators
# that form a compound symbol name

sub cat_symbols($branch) {

  my @series=(

    # sym::
    [$IMM_SYM,$OP_COLON,$OP_COLON],

    # sym:: sub
    [$SYM_LEFT,$IMM_SYM],

    # sym::sub ::ssub
    [$SYM_LEFT,$OP_COLON,$OP_COLON,$IMM_SYM],

    # sym:
    [$IMM_SYM,$OP_COLON],

  );

  my @pending=($branch);

  while(@pending) {

    my $sym = 0;
    my $nd  = shift @pending;

    # match any pattern sequence?
    repeat:

    if(-1 < (my $idex=
      $nd->match_series(@series))

    ) {

      # mark first child node as symbol
      $sym |= 1;


      # sym::
      if($idex == 0) {

        my @lv=@{$nd->{leaves}}[0..2];

        $lv[0]->{value}  =~ s[$ARG_IMM][];
        $lv[0]->{value} .=  '::';

        $lv[1]->discard();
        $lv[2]->discard();


        goto repeat;

      # sym:: sub
      } elsif($idex == 1) {

        my @lv=@{$nd->{leaves}}[0..2];

        $lv[1]->{value}  =~ s[$ARG_IMM][];
        $lv[0]->{value} .=  "$lv[1]->{value}";

        $lv[1]->discard();


        goto repeat;

      # sym::sub ::ssub
      } elsif($idex == 2) {

        my @lv=@{$nd->{leaves}}[0..3];

        $lv[3]->{value}  =~ s[$ARG_IMM][];
        $lv[0]->{value} .=  "\::$lv[3]->{value}";

        $lv[1]->discard();
        $lv[2]->discard();
        $lv[3]->discard();


        goto repeat;

      # sym:
      } elsif($idex == 3) {
        $nd->{leaves}->[0]->{value}=~
          s[$ARG_IMM][];

      };

    };


    # tag first node if need
    if($sym) {
      my $chd=$nd->{leaves}->[0];
      $chd->{value}="[*sym] $chd->{value}";

    };

    unshift @pending,@{$nd->{leaves}};

  };

};

# ---   *   ---   *   ---
# selfex

sub get_operand_type($branch) {

     is_reg($branch)
  or is_mem($branch)
  or is_imm($branch);

};

# ---   *   ---   *   ---
# see that *passed* sizes match
#
# overwrites default if any
# other specified

sub check_operand_sizes($branch) {

  my $idex = -1;
  my @lv   = grep {
    $ARG->{value}->{type} ne 'i'

  } @{$branch->{leaves}};


  # any sizes passed?
  my $ezy  = sizeof($INS_DEF_SZ);
  my @have = grep {
    $ARG->{value}->{ezy} ne 'def'

  } @lv;


  # check that they're all equal if so
  if(@have) {

    $ezy = $have[0]->{ezy};

    # ^die if they don't
    $A9M->parse_error("operand sizes don't match")
    if @have > grep {$ARG->{ezy} eq $ezy} @have;

  };


  # overwite default value
  map {$ARG->{value}->{ezy}=$ezy} @lv;

  return $ezy


};

# ---   *   ---   *   ---
# is operand a register?

sub is_reg($branch) {

  my @series=(
    [$ARG_EZY,$ARG_REG],
    [$ARG_REG]

  );


  # ^match any pattern sequence?
  if(-1 < (my $idex=
    $branch->match_series(@series))

  ) {

    my $ezy  = 'def';
    my $name = 0x00;

    # got size specifier?
    if($idex == 0) {

      ($ezy,$name)=$branch->branch_values();

      $ezy  =~ s[$ARG_EZY][];
      $name =~ s[$ARG_REG][];


    # ^nope, use default
    } else {
      $name =  $branch->{leaves}->[0]->{value};
      $name =~ s[$ARG_REG][];

    };


    # replace node with descriptor
    $branch->{value}={

      type  => 'r',

      ezy   => $ezy,
      value => $name,

    };

    $branch->clear();

    return 1;

  };


  # ^nope
  return 0;

};

# ---   *   ---   *   ---
# is operand memory?

sub is_mem($branch) {

  my @series=(

    [$ARG_EZY,$ARG_PTR,$CMD_ADDR],

    [$ARG_EZY,$CMD_ADDR],
    [$ARG_PTR,$CMD_ADDR],

    [$CMD_ADDR],

  );


  # ^match any pattern sequence?
  if(-1 < (my $idex=
    $branch->match_series(@series))

  ) {

    my ($ezy,$ptr,$cmd)=(

      'def',
      $PTR_DEF_SZ_BITS,

      $branch->{leaves}->[0],

    );


    # two optional fields specified
    if($idex==0) {

      ($ezy,$ptr)=
        $branch->branch_values();

      $ezy =~ s[$ARG_EZY][];
      $ptr =~ s[$ARG_PTR][];

      $cmd =  $branch->{leaves}->[2];


    # ^only element size
    } elsif($idex == 1) {
      $ezy =  $branch->{leaves}->[0]->{value};
      $ezy =~ s[$ARG_EZY][];

      $cmd =  $branch->{leaves}->[1];

    # ^only ptr size
    } elsif($idex == 2) {

      $ptr =  $branch->{leaves}->[0]->{value};
      $ptr =~ s[$ARG_PTR][];

      $cmd =  $branch->{leaves}->[1];

    };


    # replace node with descriptor
    $branch->{value}={

      type  => 'm',

      ezy   => $ezy,
      ptr   => $ptr,

      value => $cmd,

    };

    $branch->clear();

    return 1;

  };


  # ^nope
  return 0;

};

# ---   *   ---   *   ---
# is operand an immediate?

sub is_imm($branch) {

  my $ezy   = 0;
  my $value = $branch->{leaves}->[0]->{value};

  my $spec  = 0;


  # have size specifier?
  if(defined $value) {
    if($branch->match_sequence($ARG_EZY)) {

      $spec  = 1;

      $ezy   =  $branch->{leaves}->[0]->{value};
      $ezy   =~ s[$ARG_EZY][];

      $value = $branch->{leaves}->[1]->{value};

    };


    # transform to number if need
    $value =~ s[(?:$ARG_IMM|$ARG_SYM)][];

    my $is_num=sstoi($value,0);

    $value=(defined $is_num)
      ? $is_num
      : $value
      ;


    # calc size manually if no size specifier
    if(! $spec && $is_num) {
      $ezy=int_urdiv(bitsize($value),8)-1;

    };

    # validate size
    $A9M->parse_error(
      "immediate size limit is 16-bit"

    ) if $ezy > 1;

    # is value a symbol name?
    if(! defined $is_num) {
      ($ezy,$is_num)=$A9M->symfet($value);

    };


    # make hashref
    $branch->{value}={

      type  => 'i',

      ezy   => $ezy,
      value => $is_num,

      name  => $value,

    };

    # we clear only the first leave, from
    # which the get the hashref for the immediate
    #
    # done because a sequence of barewords is
    # parsed as a sequence of immediates, so
    # cmd may be expecting them...
    $branch->{leaves}->[0]->discard();


    return 1;

  };


  return 0;

};

# ---   *   ---   *   ---
# convert argument to binary

sub pack_operand($e) {

  my $size  = 0;
  my $value = $e->{value};


  # operand is register:
  #
  # * use plain value
  #
  # * bitsize is a constant

  if($e->{type}=~ qr{^r}) {
    $size=$A9M->{reg}->{cnt_bs};


  # operand is immediate:
  #
  # * use plain value
  #
  # * bitsize depends on value,
  #   and is calculated by get_operand_type

  } elsif($e->{type}=~ qr{^i}) {
    $size=($e->{ezy}+1) << 3;
    $e->{type}="i$size";


  # operand is memory:
  #
  # * first off, all pointers are relative ;>
  #
  # * multiple encodings are possible,
  #   so this is the most complex one!
  #
  # * the exact bitsizes are provided by the
  #   ($PTR_*) bitformats defined in the
  #   ROM section of this file
  #
  #
  # for reference, these are the encodings:
  #
  # * [sb-imm] is stack relative,
  #   we simply encode an immediate
  #
  # * [seg:imm] is segment relative with immediate
  #   offset, we encode a segment idex plus an
  #   immediate
  #
  # * [seg:r+imm] is short-form segment-relative,
  #   we encode segment idex, register idex
  #   and an immediate; stack is used as base addr
  #   if seg == 0
  #
  # * [seg:rX+rY+imm*scale] is long form
  #   segment relative, we encode segment idex,
  #   two register indices, an immediate and
  #   a scale (to be used as a left-bitshift!);
  #   stack is used as base addr if seg == 0

  } elsif($e->{type}=~ qr{^m}) {

    my $branch = $e->{value};
    my @data   = ();

    # short-form segment relative
    if(@data=memarg_short($branch)) {

      $value=$PTR_SHORT->bor(
        seg=>$data[0],
        reg=>$data[1],
        imm=>$data[2],

      );

      $size=$PTR_SHORT->{bitsize};
      $e->{type}='mshort';

    # long-form segment relative
    } elsif(@data=memarg_long($branch)) {

      $value=$PTR_LONG->bor(

        seg   => $data[0],

        rX    => $data[1],
        rY    => $data[2],

        imm   => $data[3],
        scale => $data[4],

      );

      $size=$PTR_LONG->{bitsize};
      $e->{type}='mlong';

    # stack relative
    } elsif(@data=memarg_stack($branch)) {
      $value = $PTR_STACK->bor(imm=>$data[0]);
      $size  = $PTR_STACK->{bitsize};
      $e->{type} = 'mstk';

    # position relative
    } elsif(@data=memarg_pos($branch)) {

      $value=$PTR_POS->bor(
        seg=>$data[0],
        imm=>$data[1],

      );

      $size=$PTR_POS->{bitsize};
      $e->{type}='mpos';

    } else {
      $A9M->parse_error('unencodable address');

    };

  };


  return ($size,$value);

};

# ---   *   ---   *   ---
# ROM II

  # ()+imm
  Readonly my $PLUS_IMM=>[
    $OP_PLUS,$ARG_IMM

  ];

  # ()*imm
  Readonly my $TIMES_IMM=>[
    $OP_ASTER,$ARG_IMM

  ];

  # ()+reg
  Readonly my $PLUS_REG=>[
    $OP_PLUS,$ARG_REG

  ];

  # ^reg+imm
  Readonly my $REG_PLUS_IMM=>[
    $ARG_REG,@$PLUS_IMM

  ];

  # ^reg+reg
  Readonly my $REG_PLUS_REG=>[
    $ARG_REG,@$PLUS_REG

  ];

  # sym:()
  Readonly my $SYM_COLON=>[
    $ARG_SYM,$OP_COLON

  ];

# ---   *   ---   *   ---
# detect [seg:reg+imm] form
# for memory operand

sub memarg_short($branch) {

  my @series=(

    # reg+imm
    $REG_PLUS_IMM,

    # reg
    [$ARG_REG],

    # sym:reg+imm
    [@$SYM_COLON,@$REG_PLUS_IMM],

    # sym:reg
    [@$SYM_COLON,$ARG_REG],

  );


  # ^match any pattern sequence?
  if(-1 < (my $idex=
    $branch->match_series(@series))

  ) {


    # catch false positive ;>
    if(@{$branch->{leaves}}
    >  @{$series[$idex]}

    ) {return ()};


    my $sym = 0x00;

    my $reg = 0x00;
    my $imm = 0x00;


    # reg+imm
    if($idex == 0) {
      $reg=$branch->{leaves}->[0]->{value};
      $imm=$branch->{leaves}->[2]->{value};

    # reg
    } elsif($idex == 1) {
      $reg=$branch->{leaves}->[0]->{value};

    # sym:reg+imm
    } elsif($idex == 2) {
      $sym=$branch->{leaves}->[0]->{value};
      $reg=$branch->{leaves}->[2]->{value};
      $imm=$branch->{leaves}->[4]->{value};

    # sym:reg
    } else {
      $sym=$branch->{leaves}->[0]->{value};
      $reg=$branch->{leaves}->[2]->{value};

    };


    $sym =~ s[$ARG_SYM][];
    $reg =~ s[$ARG_REG][];
    $imm =~ s[$ARG_IMM][];

    $sym = $A9M->symref($sym) if $sym;
    $imm = sstoi($imm);


    return ($sym,$reg,$imm);

  };

  return ();

};

# ---   *   ---   *   ---
# detect [seg:rX+rY+imm*scale]
# form for memory operand

sub memarg_long($branch) {

  my @series=(


    # reg+reg+imm*scale
    [@$REG_PLUS_REG,@$PLUS_IMM,@$TIMES_IMM],


    # reg+reg*scale
    [@$REG_PLUS_REG,@$TIMES_IMM],

    # reg+imm*scale
    [$ARG_REG,@$PLUS_IMM,@$TIMES_IMM],


    # reg*scale
    [$ARG_REG,@$TIMES_IMM],

    # imm*scale
    [$ARG_IMM,@$TIMES_IMM],


    # reg+reg+imm
    [@$REG_PLUS_REG,@$PLUS_IMM],

    # reg+imm
    $REG_PLUS_IMM,

  );

  # ^add segment-relative variation!
  @series=(@series,map {
    [@$SYM_COLON,@$ARG]

  } @series);


  # ^match any pattern sequence?
  if(-1 < (my $idex=
    $branch->match_series(@series))

  ) {


    # catch false positive ;>
    if(@{$branch->{leaves}}
    >  @{$series[$idex]}

    ) {return ()};


    my $sym   = 0x00;

    my $rX    = 0x00;
    my $rY    = 0x00;
    my $imm   = 0x00;
    my $scale = 0x00;


    have_symbol:

    # reg+reg+imm*scale
    if($idex == 0) {
      $rX    = $branch->{leaves}->[0]->{value};
      $rY    = $branch->{leaves}->[2]->{value};
      $imm   = $branch->{leaves}->[4]->{value};
      $scale = $branch->{leaves}->[6]->{value};

    # reg+reg*scale
    } elsif($idex == 1) {
      $rX    = $branch->{leaves}->[0]->{value};
      $rY    = $branch->{leaves}->[2]->{value};
      $scale = $branch->{leaves}->[4]->{value};

    # reg+imm*scale
    } elsif($idex == 2) {
      $rX    = $branch->{leaves}->[0]->{value};
      $imm   = $branch->{leaves}->[2]->{value};
      $scale = $branch->{leaves}->[4]->{value};

    # reg*scale
    } elsif($idex == 3) {
      $rX    = $branch->{leaves}->[0]->{value};
      $scale = $branch->{leaves}->[2]->{value};

    # imm*scale
    } elsif($idex == 4) {
      $imm   = $branch->{leaves}->[0]->{value};
      $scale = $branch->{leaves}->[2]->{value};

    # reg+reg+imm
    } elsif($idex == 5) {
      $rX = $branch->{leaves}->[0]->{value};
      $rY = $branch->{leaves}->[2]->{value};

    # reg+imm
    } elsif($idex == 6) {
      $rX  = $branch->{leaves}->[0]->{value};
      $imm = $branch->{leaves}->[2]->{value};


    # ^any of the above plus segment base
    } else {

      $sym = $branch->{leaves}->[0]->{value};

      # remove the first two nodes so that
      # we can read the tree as if the
      # symbol wasn't there ;>
      $branch->{leaves}->[0]->discard();
      $branch->{leaves}->[1]->discard();


      # ^ repeat the switch without the symbol
      $idex-=7;
      goto have_symbol;

    };


    my $rX_mod=$rX ne 0;
    my $rY_mod=$rY ne 0;


    $sym   =~ s[$ARG_SYM][];
    $rX    =~ s[$ARG_REG][];
    $rY    =~ s[$ARG_REG][];
    $imm   =~ s[$ARG_IMM][];
    $scale =~ s[$ARG_IMM][];

    $sym   = $A9M->symref($sym) if $sym;
    $imm   = sstoi($imm);
    $scale = sstoi($scale);


    $rX=(++$rX) & $PTR_LONG->{mask}->{rX}
    if $rX_mod;

    $rY=(++$rY) & $PTR_LONG->{mask}->{rY}
    if $rY_mod;


    return ($sym,$rX,$rY,$imm,$scale);

  };

  return ();

};

# ---   *   ---   *   ---
# detect [sb-imm] form for
# memory operand

sub memarg_stack($branch) {

  my @seq=(

    qr{${ARG_REG}11},

    $OP_MINUS,
    $ARG_IMM,

  );

  if($branch->match_sequence(@seq)) {

    my $value =  $branch->{leaves}->[2]->{value};
       $value =~ s[$ARG_IMM][];

    return (sstoi($value));

  };


  return ();

};

# ---   *   ---   *   ---
# detect [sym:imm] form for
# memory operand

sub memarg_pos($branch) {

  my @series=(

    # imm
    [$ARG_IMM],

    # sym:imm
    [@$SYM_COLON,$ARG_IMM],

  );

  # ^add segment-relative variation!
  @series=(@series,map {
    [@$SYM_COLON,@$ARG]

  } @series);


  # ^match any pattern sequence?
  if(-1 < (my $idex=
    $branch->match_series(@series))

  ) {


    # catch false positive ;>
    if(@{$branch->{leaves}}
    >  @{$series[$idex]}

    ) {return ()};


    my $sym=0x00;
    my $imm=0x00;


    # imm
    if($idex==0) {
      $imm=$branch->{leaves}->[0]->{value};

    # sym:imm
    } else {
      $sym=$branch->{leaves}->[0]->{value};
      $imm=$branch->{leaves}->[2]->{value};

    };


    $imm =~ s[$ARG_IMM][];
    $sym =~ s[$ARG_SYM][];

    $sym = $A9M->symref($sym) if $sym;
    $imm = sstoi($imm);


    return ($sym,$imm);

  };


  return ();

};

# ---   *   ---   *   ---
1; # ret
