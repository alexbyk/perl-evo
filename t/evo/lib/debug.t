package main;
BEGIN { $ENV{EVO_DEBUG} = 1 }    ## no critic
use Evo;
use Test::More;

{

  package Foo;
  use Evo::Lib 'debug';

  sub foo { debug(shift); }
}

my $got;
local $SIG{__WARN__} = sub {
  $got = shift;
};

Foo::foo('hello');
like $got, qr/\[Foo\].+hello/;

done_testing;
