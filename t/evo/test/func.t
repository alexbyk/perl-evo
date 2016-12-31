use Evo 'Test::More; -Test *';

{

  package My::Foo;    ## no critic
  sub foo {'FOO'}
}

my $mock = mock('My::Foo::foo', sub { call_original() });
is(My::Foo->foo(), 'FOO');
is $mock->get_call(0)->result, 'FOO';
is $mock->calls->[0]->args->[0], 'My::Foo';

done_testing;
