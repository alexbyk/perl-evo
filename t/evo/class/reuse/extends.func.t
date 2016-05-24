package main;
use Evo 'Test::More';

{

  package My::A;
  use Evo '-Class; -Loaded';

  has attr_a => 'a';
  sub meth_a : Public {'A'}

  package My::B;
  use Evo '-Class; -Loaded';
  extends "My::A";
  has 'attr_b' => 'b';
  sub meth_b : Public {'B'}

  package My::C;
  use Evo '-Class; -Loaded';
  extends "My::B";


}

my $c = My::C::new();

is $c->attr_a, 'a';
is $c->attr_b, 'b';
is $c->meth_a, 'A';
is $c->meth_b, 'B';


done_testing;
