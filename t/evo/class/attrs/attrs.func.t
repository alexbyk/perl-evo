use Evo 'Test::More; -Internal::Exception; -Class::Meta; -Class::Attrs *; -Class::Syntax *';

sub parse { Evo::Class::Meta->parse_attr(@_) }

sub run_tests {

  diag "TESTING $Evo::Class::Attrs::IMPL";

SLOTS: {
    my $noop   = sub {1};
    my $attrs  = Evo::Class::Attrs->new();
    my $inject = {foo => 2};

    $attrs->gen_attr(foo => parse 'DEF', ro, inject $inject, check $noop);
    $attrs->gen_attr(bar => parse optional);
    $attrs->gen_attr(baz => parse lazy, $noop);

    is_deeply [$attrs->slots],
      [
      {
        name   => 'foo',
        inject => {foo => 2},
        value  => 'DEF',
        check  => $noop,
        ro     => 1,
        type   => ECA_DEFAULT
      },
      {
        name   => 'bar',
        inject => undef,
        value  => undef,
        check  => undef,
        ro     => 0,
        type   => ECA_OPTIONAL
      },
      {name => 'baz', inject => undef, value => $noop, check => undef, ro => 0, type => ECA_LAZY}
      ];

    ok $attrs->exists('foo');
    ok $attrs->exists('bar');
    ok $attrs->exists('baz');
    ok !$attrs->exists('bar404');
  }

OVERWRITE: {
    my $attrs = Evo::Class::Attrs->new();
    $attrs->gen_attr('foo', parse());
    $attrs->gen_attr('bar', parse());
    $attrs->gen_attr('baz', parse());
    $attrs->gen_attr('bar', parse('DV'));
    is [$attrs->slots]->[1]->{type}, ECA_DEFAULT;
    is [$attrs->slots]->[1]->{name}, 'bar';

  }

}

run_tests();

do "t/test_memory.pl";
die $@ if $@;

done_testing;
