package main;
use Evo;
use Test::More;
use Evo::Internal::Exception;

{

  package My::External;
  use Evo;
  no warnings 'once';
  *My::Role::external = sub {'external'};


  package My::Role;
  use Evo -Class::Role, -Loaded;
  has 'foo'  => 'FOO';
  has 'foo2' => 'OLD';

  META->reg_method('external');

  no warnings 'once';
  *generated = sub {'generated'};

  my sub hidden {'HIDDEN'}

  sub bar {44}

  package My::Role::Child;
  use Evo -Class::Role, -Loaded;
  extends 'My::Role';
  has_over foo2 => 'FOO2';

  package My::Role::Child::Child;
  use Evo -Class::Role, -Loaded;
  with 'My::Role::Child';

  package My::Class;
  use Evo '-Class *';
  with 'My::Role::Child::Child';


};


my $obj = My::Class->new();

# attrs
is $obj->foo,  'FOO';
is $obj->foo2, 'FOO2';
is $obj->bar,  44;

is $obj->external,  'external';
is $obj->generated, 'generated';
ok !$obj->can('hidden');

done_testing;
