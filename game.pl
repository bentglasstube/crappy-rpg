#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes 'usleep';
use Character;

$| = 1;

sub roll {
  my $roll;

  if (@_) {
    for (1 .. 50) {
      print "\r", @_, $roll = int(rand(6)) + 1;
      usleep 10000;
    }

    print "\n";
    usleep 100000;
  } else {
    $roll = int(rand(6)) + 1;
  }

  return $roll;
}

sub prompt {
  print @_;
  my $input = <>;
  chomp $input;
  return $input;
}

sub menu {
  my ($title, @options) = @_;

  while (1) {
    print $title, "\n";
    printf "%u - %s\n", $_, $options[$_ - 1] for 1 .. @options;
    my $item = prompt "Choice: ";

    if ($item =~ /\D/) {
      for (@options) {
        return $_ if m/^$item/i
      }
    } else {
      return $options[$item - 1] if $options[$item - 1];
    }

    print "Invalid choice!\n";
  }
}

my @ROOM_DESC = (
  undef,
  'You enter a long and dimly lit corridor.  There is a door at the far end 
    of the corridor.',
  'The door opens into a small room.  Some rats are scuttling around the floor.',
  'You enter a large room.  Torches line the walls and there is a fountain 
    in the middle of the room.',
  'The door opens into an enormous natural cavern.  A spring flows gently 
    through the cavern.',
  'You find yourself in an abandonned temple.  There is a dust-covered altar
    and several piles of splintered wood scattered across the floor.',
  'The door leads to a great hall.  A throne lies toppled at the head of a long
    stone table.  A chandelier hangs precariously above the table.',
);

my @MONSTER_DATA = (
  undef,
  undef,
  'a goblin',
  'an orc',
  'a bear',
  'an ogre',
  'a dragon',
);

my $character;

sub status {
  print "\n", '=' x 60, "\n";

  printf "%-40s %10s Level %2u\n", 
    $character->name, 
    $character->class, 
    $character->level;

  print '=' x 60, "\n";

  printf "Strength   %u / %u %-12s   %s\n",
    $character->str,
    $character->str_base,
    $character->str ? '' : '[ Wounded  ]',
    $character->sword ? sprintf('Sword +%u', $character->sword) : '';

  printf "Agility    %u / %u %-12s   %s\n",
    $character->agi,
    $character->agi_base,
    $character->agi ? '' : '[ Unsteady ]',
    $character->boots ? sprintf('Boots +%u', $character->boots) : '';

  printf "Intellect  %u / %u %-12s   %s\n",
    $character->int,
    $character->int_base,
    $character->int ? '' : '[ Confused ]',
    $character->scrolls ? sprintf('%u Scrolls', $character->scrolls) : '';

  print '=' x 60, "\n\n";
}

sub intro {
  my $name  = prompt "Enter a name:          ";
  my $str   = roll   "Rolling for strength:  ";
  my $agi   = roll   "Rolling for agility:   ";
  my $int   = roll   "Rolling for intellect: ";

  $character = Character->new($name, $str, $agi, $int);

  printf "Welcome, %s the %s!\n", $character->name, $character->class;
  print "Your adventure is about to begin!\n";
}

sub level_up {
  print "You have gained a level of experience!\n";
  print "All of your wounds are washed away.\n";
  print "Your treasures are no longer useful to you.\n";
  print "Your aptitude increases!\n";

  my $stat = menu('Choose an attribute to improve:', 'Strength', 'Agility', 'Intellect');
  
  my $old_class = $character->class;
  $character->level_up(lc substr($stat, 0, 3));

  if ($old_class ne $character->class) {
    printf "You have transformed into a %s!\n", $character->class;
  }
}

sub turn {
  my $room      = roll;
  my $monster   = roll;
  my $treasure  = roll;

  print $ROOM_DESC[$room], "\n";

  if (battle($monster)) {
    loot($treasure);

    my $experience = $room + $monster + $treasure;
    print "You gain $experience experience points.\n";
    $character->get_experience($experience);
    
    level_up if $character->experience > 50;
  }
}

sub battle {
  my ($monster) = @_;

  return 1 unless $MONSTER_DATA[$monster];

  my @descriptions = (
    "Suddenly, %s rushes toward you!\n",
    "You hear the menacing growl of %s nearby!\n",
    "Out of the darkness, %s approaches!\n",
  );

  printf $descriptions[rand(@descriptions)], $MONSTER_DATA[$monster];

  my $monster_hp = $monster;
  while ($monster_hp > 0) {
    my @actions = ();
    push @actions, 'Strike' if $character->str;
    push @actions, 'Dodge'  if $character->agi;
    push @actions, 'Cast'   if $character->int;
    push @actions, 'Scroll' if $character->int && $character->scrolls;

    unless (@actions) {
      print "The enemy has dealt a mortal blow.\n";
      print "Your body collapses to the ground.\n";
      print "This is the end of your story.\n";
      exit;
    }

    my $action = lc menu(sprintf('%s is attacking!', ucfirst $MONSTER_DATA[$monster]), @actions, 'Flee');
    my $target;
    my $stat;

    if ($action eq 'strike') {
      $target = $character->str_check;
      $stat = 'str';
    } elsif ($action eq 'dodge') {
      $target = $character->agi_check;
      $stat = 'agi';
    } elsif ($action eq 'cast' || $action eq 'scroll') {
      if ($action eq 'scroll') {
        print "You read one of your magic scrolls.\n";
        $character->use_scroll;
      }
      $target = $character->int_check($action eq 'scroll');
      $stat = 'int';
    } elsif ($action eq 'flee') {
      $character->hurt($_) for qw(str agi int);

      if ($character->str or $character->agi or $character->int) {
        print "You flee from the battle and suffer a penalty to all attributes";
        return 0;
      } else {
        print "You try to flee, but you are too exhausted.\n";
        print "You collapse to the ground and wait for the innevitable.\n";
        print "This is where your story ends.\n";
        exit;
      }
    }

    my %flavor = (
      str => {
        name => 'strength',
        crit => 'You wield your sword expertly and deal a critical blow to the enemy!',
        hit  => 'You strike the enemy squarely with your sword.',
        miss => 'The enemy dodges your clumsy attack and returns the blow.',
      },
      agi => {
        name => 'agility',
        crit => 'You throw dirt into the face of your enemy, giving you time to deal a critital strike!',
        hit  => 'You evade the enemy\'s attack and riposte.',
        miss => 'You are not quick enough to dodge the incoming attack.',
      },
      int => {
        name => 'intellect',
        crit => 'Your spell is amplified by latent energies, critically damaging the enemy!',
        hit  => 'The enemy is afflicted by your magical attacks.',
        miss => 'The enemy strikes while you are casting, interrupting you.',
      },
    );

    my $roll = roll "Rolling against $flavor{$stat}{name} $target: ";
    
    if ($roll == 1) {
      print $flavor{$stat}{crit}, "\n";
      $monster_hp -= 2;
    } elsif ($roll == 6 or $roll >= $target) {
      print $flavor{$stat}{miss}, "\n";
      $character->hurt($stat);
      print "You suffer a penalty to $flavor{$stat}{name}.\n";
    } else {
      print $flavor{$stat}{hit}, "\n";
      $monster_hp--;
    }

    status if $monster_hp > 0;
  }

  print "The enemy falls, lifeless, to the ground!\n";
  return 1;
}

sub loot {
  my ($treasure) = @_;

  if ($treasure == 2) {
    print "You find a healing salve.  It can heal up to two injuries.\n";
    healing() and healing();
  } elsif ($treasure == 3) {
    $character->get_sword;
    printf "You find an enchanted sword of +%u strength!\n", $character->sword;
  } elsif ($treasure == 4) {
    $character->get_boots;
    printf "You find enchanted boots of +%u agility!\n", $character->boots;
  } elsif ($treasure == 5) {
    $character->get_scroll;
    printf "You find a magical scroll that will increase the efficacy of a single spell!\n";
  } elsif ($treasure == 6) {
    # double treasure, choose one
    my $first = roll;
    my $second = roll;

    # non-choices
    return loot($second) if $first  == 1 or $first == 6;
    return loot($first)  if $second == 1 or $second == 6;
    return loot($first)  if $first  == $second;

    my @short = qw(_ _ Bottle Sword Boots Scroll _);

    print "There are two treasures but you can only take one.\n";
    my $choice = lc menu('Which do you choose:', $short[$first], $short[$second]);
    return loot(2) if $choice eq 'bottle';
    return loot(3) if $choice eq 'sword';
    return loot(4) if $choice eq 'boots';
    return loot(5) if $choice eq 'scroll';
  }
}

sub healing {
  my @options = ();
  push @options, 'Strength'  if $character->str < $character->str_base;
  push @options, 'Agility'   if $character->agi < $character->agi_base;
  push @options, 'Intellect' if $character->int < $character->int_base;

  if (@options) {
    my $choice = menu('Which attribute would you like to heal:', @options);
    $character->heal(lc substr($choice, 0, 3));
    return 1;
  } else {
    print "You do not have any wounds to heal.\n";
    return 0;
  }
}

intro;
while (1) {
  status;
  turn;
}
