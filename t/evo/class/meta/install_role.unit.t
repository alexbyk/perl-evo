package main;
use Evo '-Class::Meta; -Role::Exporter; Test::More; Test::Fatal; Test::Evo::Helpers *';

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
        is $_[0], 'My::Class';
      }
    );
  }
}

EMPTY: {
  my $meta = comp_meta;
  like exception { $meta->install_roles('My::Class', 'My::Role') }, qr/Empty.+"My::Role".+$0/;
}

INSTALL: {

  my $meta = Evo::Class::Meta::new(rex => My::Rex::new());

  no warnings 'redefine';
  local *Evo::Class::Meta::install_attr = sub {
    is_deeply \@_, [$meta, 'My::Class', 'a1', 'is', 'rw'];
    $called++;

  };
  local *Evo::Class::Meta::monkey_patch = sub {
    is_deeply \@_, ['My::Class', 'm1', $m1];
    $called++;

  };
  $meta->install_roles('My::Class', 'My::Role');

  is $called, 3;
}

done_testing;
