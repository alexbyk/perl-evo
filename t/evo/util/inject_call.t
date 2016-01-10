use Evo;
use Evo::Util;
use Test::More;

my $fn = Evo::Util::inject(
  package  => 'My::Module',
  line     => 33,
  filename => 'my.pl',
  code     => sub { caller(); }
);

is_deeply [$fn->()], ['My::Module', 'my.pl', 33];

done_testing;
