use Evo 'Test::More; -Class::Gen; -Class::Meta; -Internal::Exception';

sub parse { Evo::Class::Meta->parse_attr(@_) }

REG_ATTR: {
  my $gen = Evo::Class::Gen->new();
  $gen->reg_attr('a0', parse(is => 'ro'));
  $gen->reg_attr('a1', parse());
  is_deeply $gen->{attrs},
    {a0 => {ro => 1, rtype => 'relaxed', index => 0}, a1 => {rtype => 'relaxed', index => 1}};

  # change attr but don't change an index
  $gen->reg_attr('a0', parse(required => 1));
  is_deeply $gen->{attrs},
    {a0 => {rtype => 'required', index => 0}, a1 => {rtype => 'relaxed', index => 1}};
}

GEN_MAP: {
  my $gen = Evo::Class::Gen->new;
  my $new = $gen->gen_new;

  my $map = $gen->gen_attrs_map;
  is_deeply [$map->($new->('My::Class'))], [];
  $gen->gen_attr('foo', parse());

  $gen->gen_attr('bar', parse());

  is_deeply [$map->($new->('My::Class', foo => 1))], [foo => 1, bar => undef];
  is_deeply [$map->($new->('My::Class', foo => 1, bar => 2))], [foo => 1, bar => 2];
}
done_testing;
