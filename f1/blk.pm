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
  use Arstd::Array;
  use Arstd::String;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.2;#b
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
  $O{par}  //= undef;
  $O{chd}  //= [];

  $O{buf}  //= $NULLSTR;
  $O{loc}  //= 0x0000;
  $O{lvl}  //= 0x00;


  # make ice
  my $self=bless {

    name => $name,

    par  => $O{par},
    chd  => $O{chd},

    buf  => $O{buf},
    loc  => $O{loc},
    lvl  => $O{lvl},

    mlvl => 0,

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
  my $lvl=$self->{lvl}+$off;
  return ' ' x ($lvl*2);

}

# ---   *   ---   *   ---
# apply ident to whole buf

sub idented($self,$lvl) {

  my $pad = $self->ident($lvl);
  my @ar  = map {
    strip(\$ARG);
    $ARG;

  } split $NEWLINE_RE,$self->{buf};

  return join "\n",map {
    "$pad$ARG"

  } grep {length $ARG} @ar;

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
      $out .= (length $body)
        ? "$body\n"
        : $NULLSTR
        ;

      next;

    };


    # get ice contents
    my $ice = shift @pending;

    my ($head,$buf,$foot)=
      $ice->idented_full();

    # ^cat header, postpone footer
    $out .= joinfilt("\n",$head,$buf)."\n";

    push @foot,$foot;

    # ^go next
    unshift @pending,@{$ice->{chd}},0;

  };


  # repl own buf
  my ($head,$buf,$foot)=
    $self->idented_full();

  $out=joinfilt("\n",$head,$buf,$out,$foot)."\n";

  # ^give collapsed buf
  return $out;

};

# ---   *   ---   *   ---
# join array of blocks

sub cat($class,$name,%O) {

  # get lowest first
  my @ar=sort {
    $a->{loc} > $b->{loc}

  } @{$O{elems}};

  # ^paste in order
  my $buf=$NULLSTR;

  my $out=join "\n",map {
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

  my @lines=

    grep  {length $ARG}
    map   {strip(\$ARG);$ARG}

    split $SEMI_RE,$s

  ;


  my $pad=$self->ident();

  $self->{buf}.=join "\n",map {"$pad$ARG"} @lines;
  $self->{buf}.="\n";

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

    $bme=($idex eq 0      ) ? 'BEG' : $bme;
    $bme=($idex eq $#lines) ? 'END' : $bme;


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
