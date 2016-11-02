package main;
use Evo 'Test::More; Evo::Internal::Exception';

{

  package My::Alien;
  use Evo -Loaded;
  sub foo {'ALIEN'}

  package My::Class;
  use Evo -Class, -Loaded;
  sub foo {'FOO'}
  sub bar {'BAR'}

  package My::Child;
  use parent 'My::Alien';
  use Evo -Class;

  package My::Child2;
  use parent 'My::Alien';
  use Evo -Class;

  with 'My::Class';
  sub foo : Over { My::Class::foo(@_) }

}

like exception { My::Child->META->extend_with('My::Class'); }, qr/inherited/;
is(My::Child2->foo(), 'FOO');

done_testing;
