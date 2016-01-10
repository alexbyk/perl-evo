package main;
use Evo;
use Evo::Util;
use Test::More;

sub undef_symbols { Evo::Util::undef_symbols(@_) }

{

  package My::Src;
  sub foo {'ok'}
  our $foo = 'ok';

  package My::Src::Child;
}

ok grep  { $_ eq 'Child::' } keys %My::Src::;
ok !grep { $_ eq 'Child::' } Evo::Util::list_symbols('My::Src');

done_testing;

1;

