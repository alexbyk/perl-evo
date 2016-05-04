package main;
use Evo;
use Test::More;
use Test::Fatal;

{

  package My::Role;
  use Evo '-Role *; -Loaded';
  has 'foo', 'foov';
  sub foo_uc : Role { uc shift->foo }
  role_gen gm => sub {
    my $class = shift;
    sub { shift->foo_uc() . $class };
  };

  package My::PRole;
  use Evo '-Role *; -Loaded';
  has 'own', 'ownv';
  role_proxy 'My::Role';

  package My::Class;
  use Evo '-Class *';
  with 'My::PRole';

};


my $obj = My::Class::new();
is $obj->own,    'ownv';
is $obj->foo,    'foov';
is $obj->foo_uc, 'FOOV';
is $obj->gm,     'FOOVMy::Class';

done_testing;
