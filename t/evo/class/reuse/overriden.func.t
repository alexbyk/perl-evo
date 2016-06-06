package main;
use Evo 'Test::More';

{

  package My::A;
  use Evo '-Class; -Loaded';

  has attr_a1 => 'a1';
  has attr_a2 => 'a2';
  sub meth_a {'A'}

  package My::B;
  use Evo '-Class; -Loaded';

  # order doesn't matters
  has_overriden attr_a1 => 'over1';
  extends "My::A";
  has_overriden attr_a2 => 'over2';

  sub meth_a : Overriden {'A2'}

}

my $b = My::B->new();

is $b->attr_a1, 'over1';
is $b->attr_a2, 'over2';
is $b->meth_a,  'A2';

done_testing;
