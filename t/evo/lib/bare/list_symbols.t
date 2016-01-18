package main;
use Evo;
use Evo::Lib::Bare;
use Test::More;

sub undef_symbols { Evo::Lib::Bare::undef_symbols(@_) }

{

  package My::Src;
  sub foo {'ok'}
  our $foo = 'ok';

  package My::Src::Child;
}

ok grep  { $_ eq 'Child::' } keys %My::Src::;
ok !grep { $_ eq 'Child::' } Evo::Lib::Bare::list_symbols('My::Src');

done_testing;

1;

