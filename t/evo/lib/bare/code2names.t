package main;
use Evo 'Test::More; -Lib::Bare';

{

  package My::Foo;
  sub foo { }
}

*bar = *My::Foo::foo;
my ($pkg, $name);

($pkg, $name) = Evo::Lib::Bare::code2names(\&bar);
is $pkg,  'My::Foo';
is $name, 'foo';


($pkg, $name) = Evo::Lib::Bare::code2names(\&My::Foo::foo);
is $pkg,  'My::Foo';
is $name, 'foo';

($pkg, $name) = Evo::Lib::Bare::code2names(sub { });
is $pkg,  'main';
is $name, '__ANON__';


# names2code
is Evo::Lib::Bare::names2code('My::Foo', 'foo'), \&My::Foo::foo;
ok !Evo::Lib::Bare::names2code('My::Foo', 'foo2');


done_testing;
