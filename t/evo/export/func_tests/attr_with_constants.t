package main;
use Evo;
use Test::More;


# because package symbols can be not code refs
{

  package My::Lib;
  use Evo '-Export *', -Loaded;
  use constant MYCONST => 22;

  BEGIN {
    export 'MYCONST';
  }
  sub foo : Export { 'FOO'; }
}

use My::Lib '*';
is foo(),     'FOO';
is MYCONST(), 22;

done_testing;
