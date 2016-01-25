package main;
use Evo;
use Test::More;
use Test::Fatal;

{

  package My::Foo1;
  use Evo '-Comp *';
  has 'foo';

  package My::Foo2;
  use Evo '-Comp::Hash *';
  has 'foo';

  package My::Foo3;
  use Evo '-Comp::Out *';
  has 'foo';

  package My::Role1;
  use Evo '-Role *';
  has 'foo';



  package My::Foo4;
  use Evo -Comp;
  has 'foo';

  package My::Foo5;
  use Evo -Comp::Hash;
  has 'foo';

  package My::Foo6;
  use Evo -Comp::Out;
  has 'foo';

  package My::Role2;
  use Evo -Role;
  has 'foo';
};

ok 1;

done_testing;
