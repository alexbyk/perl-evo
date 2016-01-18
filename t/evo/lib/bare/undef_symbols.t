package main;
use Evo;
use Evo::Lib::Bare;
use Test::More;

sub undef_symbols { Evo::Lib::Bare::undef_symbols(@_) }

{

  package My::Src;
  use Evo;
  sub foo {'ok'}
  our $foo = 'ok';

  package My::Src::Child;
  sub child {'ok'}
  our $child = 'ok';
}


is My::Src::foo(), 'ok';
is $My::Src::foo, 'ok';
is My::Src::Child::child(), 'ok';
is $My::Src::Child::child, 'ok';

# clear parent, not child
undef_symbols('My::Src');
is $My::Src::foo, undef;
ok !My::Src->can('foo');

ok %My::Src::Child::;
is My::Src::Child::child(), 'ok';
is $My::Src::Child::child, 'ok';

## clear child to be sure
undef_symbols('My::Src::Child');
ok !My::Src::Child->can('foo');
is $My::Src::Child::child, undef;

done_testing;

1;

