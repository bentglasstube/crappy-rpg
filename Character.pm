package Character;

use strict;
use warnings;

use List::Util qw(min max);

sub __roll { 
  my ($max) = @_;
  $max ||= 6;
  
  return int(rand($max)) + 1;
}

sub new {
  my ($class, $name, $str, $agi, $int) = @_;

  my $self = bless {
    name      => $name,
    str       => {
      base    => $str,
      penalty => 0,
    },
    agi       => {
      base    => $agi, 
      penalty => 0,
    },
    int       => {
      base    => $int,
      penalty => 0,
    },
    exp       => 0,
    level     => 1,
    sword     => 0,
    boots     => 0,
    scrolls   => 0,
  }, $class;
}

sub name {
  my ($self) = @_;
  return $self->{name};
}

sub str {
  my ($self) = @_;
  return $self->str_base - $self->{str}{penalty};
}

sub str_base {
  my ($self) = @_;
  return $self->{str}{base};
}

sub agi {
  my ($self) = @_;
  return $self->agi_base - $self->{agi}{penalty};
}

sub agi_base {
  my ($self) = @_;
  return $self->{agi}{base};
}

sub int {
  my ($self) = @_;
  return $self->int_base - $self->{int}{penalty};
}

sub int_base {
  my ($self) = @_;
  return $self->{int}{base};
}

sub str_check {
  my ($self) = @_;

  my $target = $self->str + $self->sword;

  $target-- if $self->agi < 1;
  $target-- if $self->int < 1;

  return $target;
}

sub agi_check {
  my ($self) = @_;

  my $target = $self->agi + $self->boots;

  $target-- if $self->str < 1;
  $target-- if $self->int < 1;

  return $target;
}

sub int_check {
  my ($self, $scroll) = @_;

  my $target = $self->int + ($scroll ? 3 : 0);

  $target-- if $self->str < 1;
  $target-- if $self->agi < 1;

  return $target;
}

sub experience {
  my ($self, $value) = @_;
  return $self->{exp};
}

sub get_experience {
  my ($self, $amount) = @_;
  $self->{exp} += $amount;
}

sub level {
  my ($self) = @_;
  return $self->{level};
}

sub level_up {
  my ($self, $stat) = @_;

  $self->{exp} = 0;
  $self->{level}++;

  # increase chosen attribute
  $self->{$stat}{base}++;

  # heal wounds
  $self->{$_}{penalty} = 0 for qw(str agi int);
  
  # lose treasure
  $self->{sword} = 0;
  $self->{boots} = 0;
  $self->{scrolls} = 0;
}

sub sword {
  my ($self) = @_;
  return $self->{sword};
}

sub get_sword {
  my ($self) = @_;
  $self->{sword}++;
}

sub boots {
  my ($self) = @_;
  return $self->{boots};
}

sub get_boots {
  my ($self) = @_;
  $self->{boots}++;
}

sub scrolls {
  my ($self) = @_;
  return $self->{scrolls};
}

sub get_scroll {
  my ($self) = @_;
  $self->{scrolls}++;
}

sub use_scroll {
  my ($self) = @_;
  $self->{scrolls}--;
}

sub hurt {
  my ($self, $stat) = @_;
  $self->{$stat}{penalty} = min($self->{$stat}{base}, $self->{$stat}{penalty} + 1);
}

sub heal {
  my ($self, $stat) = @_;
  $self->{$stat}{penalty} = max(0, $self->{$stat}{penalty} - 1);
}

my @__range = qw(L L L L M M M H H H H H H H H H H H H H H H);
my %__class = qw(
  LLL Adventurer      LLM Conjurer      LLH Wizard
  LML Thief           LMM Acolyte       LMH Priest
  LHL Rogue           LHM Mystic        LHH Monk
  MLL Fighter         MLM Squire        MLH Templar
  MML Pugilist        MMM Sage          MMH Mage
  MHL Ranger          MHM Ninja         MHH Sensei
  HLL Brute           HLM Knight        HLH Crusader
  HML Soldier         HMM Warrior       HMH Paladin
  HHL Samurai         HHM Dragoon       HHH Ascendant
);

sub class {
  my ($self) = @_;

  my $key = join '', map $__range[$self->{$_}{base}], qw(str agi int);
  return $__class{$key};
}

1;
