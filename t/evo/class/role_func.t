package main;
use Evo;
use Test::More;
use Test::Fatal;

{

  package My::Role;
  use Evo '-Class::Role *; -Loaded';
  has 'foo_short' => 11;
  has 'foo'       => 111;
  sub bar : Public {44}

  package My::Class;
  use Evo '-Class *';
  extends 'My::Role';


};

like exception { My::Role->new() }, qr/can't.+role.+$0/;

my $obj = My::Class->new();
is $obj->foo_short, 11;
is $obj->foo,       111;
is $obj->bar,       44;

done_testing;
