use Evo 'Test::More; -Lib *; Test::Evo::Helpers exception';

my %hash = (foo => 33, bar => 44, baz => 55);

{

  package My::Foo;
  use Evo::Lib 'strict_opts';

  sub foo(%opts) { strict_opts(1, \%opts, 'foo', 'bar'); }
};

is_deeply [My::Foo::foo(foo => 33, bar => 44)], [33, 44];

like exception { My::Foo::foo(bad => 33) }, qr/unknown options.+bad.+$0/i;

done_testing;
