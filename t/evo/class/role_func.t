package main;
use Evo;
use Test::More;
use Test::Fatal;

{

  package My::Role;
  use Evo '-Class::Role *; -Loaded';
  has 'foo_short' => 11;
  has 'foo'       => 111;

  no warnings 'once';
  *generated = sub {'gen'};
  reg_method 'generated';

  *not_public = sub {'bad'};

  sub hidden : Private {'HIDDEN'}

  sub bar {44}

  package My::Class;
  use Evo '-Class *';
  extends 'My::Role';


};

like exception { My::Role->new() }, qr/can't.+role.+$0/;

my $obj = My::Class->new();
is $obj->foo_short, 11;
is $obj->foo,       111;
is $obj->bar,       44;

is $obj->generated, 'gen';
ok !$obj->can('hidden');
ok !$obj->can('not_public');
ok !$obj->can('hidden');

done_testing;
