package main;
use Evo;
use Test::More;
use Test::Fatal;

{

  package My::Foo;
  use Evo '-Realm *';

}

IN_ALIEN_REALM: {
  My::Foo::realm 'LORD' => sub {
    is My::Foo::realm_lord, 'LORD';
  };
}

NOT_IN_REALM: {
  like exception { My::Foo::realm_lord() }, qr/not in realm of "My::Foo".+$0/;
  is My::Foo::realm_lord('DEFAULT'), 'DEFAULT';
}

IN_REALM: {
  my $obj1 = bless {}, 'My::Foo';
  my $obj2 = bless {}, 'My::Foo';

  My::Foo::realm $obj1, sub {
    is My::Foo::realm_lord('DEFAULT'), $obj1;
    is My::Foo::realm_lord(), $obj1;

    My::Foo::realm $obj2, sub { is My::Foo::realm_lord(), $obj2; };

    is My::Foo::realm_lord(), $obj1;
  };

}

done_testing;
