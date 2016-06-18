use Evo::Attr::Class;
use Evo 'Test::More; Test::Evo::Helpers exception';

my $m = Evo::Attr::Class->new();
my $SUB = sub {222};

my $h1 = sub ($pkg, $code, @got) {
  is $pkg,  'Dest';
  is $code, $SUB;
  is_deeply \@got, [qw(A1 A2 A3)];
  return qw(A2 A3);
};

my $h2 = sub ($pkg, $code, @got) {
  is $pkg,  'Dest';
  is $code, $SUB;
  is_deeply \@got, [qw(A2 A3)];
  return qw(A3);
};

$m->register_handler_of('Provider1', $h1);
$m->register_handler_of('Provider2', $h2);

# second time - error
like exception { $m->register_handler_of('Provider1', $h1) },
  qr/"Provider1" has been already registered.+$0/;

# not installed
is_deeply [$m->run_handlers('Dest', $SUB, 'A1', 'A2')], [qw(A1 A2)];

# install not existing
like exception { $m->install_handler_in("Dest", 'Provider404') },
  qr/"Provider404" hasn't been registered.+$0/;

# install
$m->install_handler_in("Dest", "Provider1");
$m->install_handler_in("Dest", "Provider2");

# install not existing
like exception { $m->install_handler_in("Dest", 'Provider1') },
  qr/"Provider1" has been already installed in "Dest".+$0/;
my @res = $m->run_handlers('Dest', $SUB, qw(A1 A2 A3));
is_deeply \@res, ['A3'];

done_testing;
