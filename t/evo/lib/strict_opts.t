use Evo 'Test::More; -Lib *; Evo::Internal::Exception';

my %hash = (foo => 33, bar => 44, baz => 55);

{

  package My::Foo; ## no critic
  use Evo::Lib 'strict_opts';

  sub foo(%opts) { strict_opts(\%opts, [qw(foo bar)]); }
};

is_deeply [My::Foo::foo(foo => 33, bar => 44)], [33, 44];

like exception { My::Foo::foo(bad => 33) }, qr/unknown options.+bad.+$0/i;

done_testing;
