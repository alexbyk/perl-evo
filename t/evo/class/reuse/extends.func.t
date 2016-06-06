package main;
use Evo 'Test::More';

{

  package My::A;
  use Evo '-Class; -Loaded';
  use Evo::Class::Common 'meta_of';

  has attr_a => 'a';
  sub meth_a            {'A'}
  sub private : Private {'HIDDEN'}
  no warnings 'once';
  *generated = sub {'gen'};
  reg_method 'generated';
  *not_public = sub {'bad'};

  package My::B;
  use Evo '-Class; -Loaded';
  extends "My::A";
  has 'attr_b' => 'b';
  sub meth_b {'B'}

  package My::C;
  use Evo '-Class; -Loaded';
  extends "My::B";


}

my $c = My::C->new();

is $c->attr_a,    'a';
is $c->attr_b,    'b';
is $c->meth_a,    'A';
is $c->meth_b,    'B';
is $c->generated, 'gen';
ok !$c->can('private');
ok !$c->can('not_public');
is(My::A->new()->private, 'HIDDEN');


done_testing;
