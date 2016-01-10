package main;
use Evo '-Export';
use Test::More;
use Test::Fatal;

*find_subnames = *Evo::Util::find_subnames;

{

  package Foo;
  sub foo { }
  no warnings 'once';
  *bar = *foo;
}

$Foo::{not_a_glob} = \33;
is_deeply [sort(find_subnames('Foo', *Foo::foo{CODE}))], [sort qw(foo bar)];

ok !find_subnames('Foo', sub { });

done_testing;
