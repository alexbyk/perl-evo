package main;
use Evo;
use Evo::Comp::Meta;
use Test::More;

my $called;
my $m1 = sub { };
{

  package My::Role;
  use Evo -Loaded;
  sub new { bless {}, __PACKAGE__ }
  use Test::More;

  sub methods {
    return (m1 => $m1);
  }

  sub attrs {
    return (a1 => [is => 'rw']);
  }

  sub hooks {
    (
      sub {
        $called++;
        is $_[0], 'My::Comp';
      }
    );
  }
}


my $meta = Evo::Comp::Meta::new(rex => My::Role::new());

no warnings 'redefine';
local *Evo::Comp::Meta::install_attr = sub {
  is_deeply \@_, [$meta, 'My::Comp', 'a1', 'is', 'rw'];
  $called++;

};
local *Evo::Comp::Meta::monkey_patch = sub {
  is_deeply \@_, ['My::Comp', 'm1', $m1];
  $called++;

};
$meta->install_roles('My::Comp', 'My::Role');

is $called, 3;
done_testing;
