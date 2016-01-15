package main;
use Evo '-Comp::Meta; -Role::Exporter; Test::More; Test::Fatal; Test::Evo::Helpers *';

my $called;
my $m1 = sub { };
{

  package My::Role;
  use Evo -Loaded;

  # ms and a1 mocked


  package My::Rex::Empty;
  use Evo -Loaded;
  sub new { bless {}, __PACKAGE__ }

  sub methods { }
  sub attrs   { }

  package My::Rex;
  use Evo -Loaded;
  sub new { bless {}, __PACKAGE__ }
  use Test::More;

  sub methods { return (m1 => $m1); }
  sub attrs { return (a1 => [is => 'rw']); }

  sub hooks {
    (
      sub {
        $called++;
        is $_[0], 'My::Comp';
      }
    );
  }
}

EMPTY: {
  my $meta = comp_meta;
  like exception { $meta->install_roles('My::Comp', 'My::Role') }, qr/Empty.+"My::Role".+$0/;
}

INSTALL: {

  my $meta = Evo::Comp::Meta::new(rex => My::Rex::new());

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
}

done_testing;
