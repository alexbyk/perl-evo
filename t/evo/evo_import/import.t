package main;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use Evo 'MyExternalNoEvoImport';
use Test::More;
use Test::Fatal;


# no import method
like exception {
  Evo::->import('MyExternalNoEvoImport(foo)');
},
  qr/MyExternalNoEvoImport hasn't "import" method/;


# order
my @called;
my $N = 20;
EVAL: {
  local $@;
  eval    ## no critic
    "package Evo::My$_; use Evo -Loaded; sub import { push \@called, $_ }" for 1 .. $N;
  die if $@;
}

Evo::->import("-My$_") for 1 .. $N;
is_deeply \@called, [1 .. $N];


# errors
FATAL: {
  local $@;
  eval "package My::Foo; use Evo '[]'";    ## no critic
  like $@, qr/Can't parse/;
}

# oneline
{

  package My::Foo;
  use Evo '-Export *', -Loaded;
  sub foo : Export {'foo'}

  package Evo::My::Bar;
  use Evo '-Export *', -Loaded;
  sub bar : Export {'bar'}
}

use Evo 'My::Foo; -My::Bar *;';
use Evo 'My::Foo; -My::Bar';

# one string
{
  package My::Foo;
  use Evo '-Export *; -Realm ';
  use Evo '-Export *; -Realm;';
  use Evo '-Export *; -Realm; ';
}

done_testing;
