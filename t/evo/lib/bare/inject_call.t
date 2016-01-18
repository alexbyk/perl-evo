use Evo;
use Evo::Lib::Bare;
use Test::More;

my $fn = Evo::Lib::Bare::inject(
  package  => 'My::Module',
  line     => 33,
  filename => 'my.pl',
  code     => sub { caller(); }
);

is_deeply [$fn->()], ['My::Module', 'my.pl', 33];

done_testing;
