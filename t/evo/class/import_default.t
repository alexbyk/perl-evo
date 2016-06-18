package main;
use Evo;
use Test::More;
use Test::Evo::Helpers "exception";

{

  package My::Foo1;
  use Evo '-Class *';
  has 'foo';

  package My::Foo2;
  use Evo '-Class *';
  has 'foo';

  package My::Foo3;
  use Evo '-Class::Out *';
  has 'foo';

  package My::Role1;
  use Evo '-Class::Role *';
  has 'foo';


  package My::Foo4;
  use Evo -Class;
  has 'foo';

  package My::Foo5;
  use Evo -Class;
  has 'foo';

  package My::Foo6;
  use Evo -Class::Out;
  has 'foo';

  package My::Role2;
  use Evo -Class::Role;
  has 'foo';
};

ok 1;

done_testing;
