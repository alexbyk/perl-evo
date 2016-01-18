package main;
BEGIN { $ENV{EVO_DEBUG} = 1 }    ## no critic
use Evo '-Lib::Internal *; Test::More';

STEADY_TIME: { ok steady_time() }


# DEBUG
{

  package Foo;
  use Evo::Lib::Internal 'debug';

  sub foo { debug(shift); }
}

my $got;
local $SIG{__WARN__} = sub {
  $got = shift;
};

Foo::foo('hello');
like $got, qr/\[Foo\].+hello/;

done_testing;
