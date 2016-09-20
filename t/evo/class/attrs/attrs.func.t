use Evo 'Test::More; -Internal::Exception; -Class::Meta; -Class::Attrs *';


sub parse { Evo::Class::Meta->parse_attr(@_) }

SLOTS: {
  my $noop  = sub {1};
  my $attrs = Evo::Class::Attrs->new();
  my $stash = {foo => 2};

  $attrs->gen_attr(foo => parse 'DEF', stash => $stash, check => $noop, is => 'ro');
  $attrs->gen_attr(bar => parse);
  $attrs->gen_attr(baz => parse lazy => $noop);
  is_deeply [$attrs->slots],
    [
    {
      name  => 'foo',
      stash => {foo => 2},
      value => 'DEF',
      check => $noop,
      ro    => 1,
      type  => ECA_DEFAULT
    },
    {name => 'bar', stash => undef, value => undef, check => undef, ro => 0, type => ECA_SIMPLE},
    {name => 'baz', stash => undef, value => $noop, check => undef, ro => 0, type => ECA_LAZY}
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

done_testing;
