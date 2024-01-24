#!/usr/bin/perl
# ---   *   ---   *   ---
# F1 BLK
# Recursive string array
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package f1::blk;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_words);

  use lib $ENV{ARPATH}.'/lib/sys/';

  use Style;
  use Type;
  use Chk;

  use Arstd::Array;
  use Arstd::String;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.3;#b
  our $AUTHOR  = 'IBN-3DILA';


# ---   *   ---   *   ---
# GBL

  my $Cache={};

# ---   *   ---   *   ---
# getset cached value

sub ldcache($class,$key) {
  $Cache->{$key}

};

sub stcache($class,$key,$value) {
  $Cache->{$key}=$value

};

# ---   *   ---   *   ---
# cstruc

sub new($class,$name,%O) {

  # avtopar
  if(length ref $class) {
    $O{par} = $class;
    $class  = ref $class;

  };

  # defaults
  $O{par}     //= undef;
  $O{chd}     //= [];
  $O{seg}     //= [];

  $O{buf}     //= $NULLSTR;
  $O{loc}     //= 0x0000;
  $O{lvl}     //= 0x00;

  $O{binary}  //= 0;


  # make ice
  my $self=bless {

    name   => $name,

    par    => $O{par},
    chd    => $O{chd},
    seg    => $O{seg},

    buf    => $O{buf},
    loc    => $O{loc},
    lvl    => $O{lvl},

    mlvl   => 0,
    binary => $O{binary},

  },$class;


  # ^calculate offset from parent
  $self->get_chd_loc() if defined $O{par};

  # give ice
  return $self;

};

# ---   *   ---   *   ---
# get nesting level

sub ances($self) {

  my $lvl  = 0;
  my $mlvl = 0;
  my $par  = $self->{par};

  while(defined $self->{par}) {

    my $class=ref $self->{par};

    $mlvl += int $class->isa('f1::macro');
    $lvl  += 1;

    $self  = $self->{par};

  };

  return ($lvl,$mlvl);

};

# ---   *   ---   *   ---
# ^as ident

sub ident($self,$off=0) {
  my $lvl=(! $self->{binary})
    ? $self->{lvl}+$off
    : 0
    ;

  return ' ' x ($lvl*2);

}

# ---   *   ---   *   ---
# apply ident to whole buf

sub idented($self,$lvl) {

  my $pad = $self->ident($lvl);
  my @ar  = grep {length $ARG} map {
    strip(\$ARG);
    $ARG;

  } split $NEWLINE_RE,$self->{buf};

  return (! $self->{binary})
    ? join "\n",map {"$pad$ARG"} @ar
    : join $NULLSTR,@ar
    ;

};

# ---   *   ---   *   ---
# wrap buff between head and foot

sub idented_full($self) {

  my $head = $self->head();
  my $foot = $self->foot();

  my $have = 0 < length "$head$foot";

  my $buf  = $self->idented($have);
  my $pad  = $self->ident(0);

  return ($have)
    ? ("$pad$head",$buf,"$pad$foot")
    : ($NULLSTR,$buf,$NULLSTR)
    ;

};

# ---   *   ---   *   ---
# ^placeholders

sub head($self) {$NULLSTR};
sub foot($self) {$NULLSTR};

# ---   *   ---   *   ---
# escapes an operator by
# block level

sub scapop($self,$op) {
  return ("\\" x $self->{mlvl}) . $op;

};

# ---   *   ---   *   ---
# (re)assign parent to blk

sub set_parent($self,$par) {
  $self->{par}=$par;
  $self->get_chd_loc();

};

# ---   *   ---   *   ---
# get child position

sub get_chd_loc($self) {

  # get ctx
  my $par=$self->{par};
  my $chd=$par->{chd};

  # find self in array
  my $have=int grep {$ARG eq $self} @$chd;

  # ^get idex
  my $idex=($have)
    ? array_iof($chd,$self)
    : @$chd
    ;

  # ^set segment location
  push @$chd,$self if ! $have;

  $self->{loc}=$idex;
  $self->recalc_lvl();

};

# ---   *   ---   *   ---
# recalculates lvl for a
# whole hierarchy

sub recalc_lvl($self) {

  # setup
  my @lvl =(defined $self->{par})
    ? $self->ances()
    : (0,0)
    ;

  ($self->{lvl},$self->{mlvl})=@lvl;


  # recursive walk
  my @pending = @{$self->{chd}};

  while(@pending) {

    my $ice=shift @pending;
    @lvl=$ice->ances();

    ($ice->{lvl},$ice->{mlvl})=@lvl;

    unshift @pending,@{$ice->{chd}};

  };

};

# ---   *   ---   *   ---
# join hierarchy

sub collapse($self) {

  # setup
  my @pending = @{$self->{chd}};
  my @foot    = ();
  my $out     = $NULLSTR;

  # recursive walk
  while(@pending) {

    # cat footer at end of sub-hierarchy
    if($pending[0] eq 0) {

      shift @pending;

      my $body=shift @foot;

      $body = (! $self->{binary})
        ? "$body\n"
        : $body
        ;

      $out .= (length $body)
        ? $body
        : $NULLSTR
        ;

      next;

    };


    # get ice contents
    my $ice = shift @pending;

    my ($head,$buf,$foot)=
      $ice->idented_full();

    # ^cat header, postpone footer
    $out .= (! $self->{binary})
      ? joinfilt("\n",$head,$buf)."\n"
      : joinfilt($NULLSTR,$head,$buf)
      ;

    push @foot,$foot;

    # ^go next
    unshift @pending,@{$ice->{chd}},0;

  };


  # repl own buf
  my ($head,$buf,$foot)=
    $self->idented_full();

  $out=(! $self->{binary})
    ? joinfilt("\n",$head,$buf,$out,$foot)."\n"
    : joinfilt($NULLSTR,$head,$buf,$out,$foot)
    ;

  # ^give collapsed buf
  return $out;

};

# ---   *   ---   *   ---
# join array of blocks

sub cat($class,$name,@ar) {

  # get lowest first
  @ar=sort {
    $a->{loc} > $b->{loc}

  } @ar;

  # ^paste in order
  my $c   = (! $ar[0]->{binary})
    ? "\n"
    : $NULLSTR
    ;

  my $out = join $c,map {
    $ARG->collapse()

  } @ar;

  # repl top
  my $top=shift @ar;
  $top->{buf}=$out;

  # give top
  return $top;

};

# ---   *   ---   *   ---
# add lines to buffer

sub lines($self,$s) {

  my $scapnl = "\\\n";
  my @lines  = grep  {length $ARG} map {

    strip(\$ARG);

    $ARG=~ s[$NEWLINE_RE+][$scapnl]sxmg;
    $ARG;

  } split $SEMI_RE,$s;


  my $pad=$self->ident();

  $self->{buf}.=join "\n",map {"$pad$ARG"} @lines;
  $self->{buf}.="\n";

};

# ---   *   ---   *   ---
# ^add raw binary

sub blines($self,$ezy,@data) {

  my ($ct,@cnt) = bpack($ezy,@data);
  $self->{buf} .= $ct;

  return ((length $ct),@cnt);

};

# ---   *   ---   *   ---
# ^labeled binary

sub seg($self,@order) {

  # array as hash
  my $idex   = 0;
  my @keys   = array_keys(\@order);
  my @values = array_values(\@order);

  # ^walk
  map {

    # get beg of next segment
    my $label = $ARG;
    my $loc   = length $self->{buf};

    # ^put into buf
    my $arg=$values[$idex++];

    my $len=0;
    my @cnt=();

    # content passed?
    if(is_arrayref($arg)) {
      my ($ezy,@data)=@$arg;
      ($len,@cnt)=$self->blines($ezy,@data);

    # else assume N-reserved
    } else {
      my ($ezy,$data)=split $SPACE_RE,$arg;
      ($len,@cnt)=$self->blines(
        $ezy,(0x00) x $data

      );

    };


    # record beg,len
    push @{$self->{seg}},$label=>[$loc,$len,@cnt];

  } @keys;

};

# ---   *   ---   *   ---
# ^overwrite

sub segat($self,$loc,$len,@order) {
  substr $self->{buf},$loc,$len,bpack(@order);

};

# ---   *   ---   *   ---
# makes enum from name list

sub enum($self,$base,@names) {

  $Cache->{$base} //= -1;
  $Cache->{align} //= 0;

  $self->lines(join ';',map {

    sprintf "${base}.%-$Cache->{align}s = \$%04X",
      $ARG,++$Cache->{$base}

  } @names);

};

# ---   *   ---   *   ---
# makes switch

sub switch($self,@expr) {

  # setup
  my $idex  = 0;
  my @lines = array_values(\@expr);


  # make branches
  map {

    # get position
    my $bme=0;

    if($#lines eq 0) {
      $bme='BEG+END';

    } else {
      $bme=($idex eq 0      ) ? 'BEG' : $bme;
      $bme=($idex eq $#lines) ? 'END' : $bme;

    };


    # get sub-block body and go next
    my $buf=$lines[$idex++];

    # ^make sub-block
    f1::logic->new(

      ".L$idex",

      type   => 'if',

      expr   => $ARG,
      switch => $bme,
      buf    => $buf,

      par    => $self,

    );

  } array_keys(\@expr);

  return;

};

# ---   *   ---   *   ---
# declares var

sub local($self,$name,$value=undef) {

  $self->lines(

    "local $name;"
  . ("$name $value;" x defined $value)

  );

};

# ---   *   ---   *   ---
1; # ret
