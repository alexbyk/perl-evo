package main;
use Evo;
use Test::More;
use Test::Fatal;

{

  package My::Foo;
  use Evo '-Realm *';

}

ERR: {
  like exception { My::Foo::realm_run({}) }, qr/instance of "My::Foo".+$0/;
}

NOT_IN_REALM: {
  like exception { My::Foo::realm() }, qr/not in realm of "My::Foo".+$0/;
  is My::Foo::realm('DEFAULT'), 'DEFAULT';
}

IN_REALM: {
  my $obj1 = bless {}, 'My::Foo';
  my $obj2 = bless {}, 'My::Foo';

  My::Foo::realm_run $obj1, sub {
    is My::Foo::realm('DEFAULT'), $obj1;
    is My::Foo::realm(), $obj1;

    My::Foo::realm_run $obj2, sub { is My::Foo::realm(), $obj2; };

    is My::Foo::realm(), $obj1;
  };

}

done_testing;
