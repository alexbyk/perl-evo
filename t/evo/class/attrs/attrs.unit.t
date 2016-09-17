use Evo 'Test::More; -Internal::Exception; -Class::Attrs; Evo::Class::Const *';

DUPL: {
  my $attrs = Evo::Class::Attrs->new();
  $attrs->gen_attr('foo', A_RELAXED, (undef) x 3);
  $attrs->gen_attr('bar', A_RELAXED, (undef) x 3);
  is_deeply $attrs, [['foo', A_RELAXED, (undef) x 3], ['bar', A_RELAXED, (undef) x 3]];
  $attrs->gen_attr('foo', A_DEFAULT,  (undef) x 3);
  $attrs->gen_attr('bar', A_REQUIRED, (undef) x 3);
  is_deeply $attrs, [['foo', A_DEFAULT, (undef) x 3], ['bar', A_REQUIRED, (undef) x 3]];
}

NAMES_EXISTS: {
  my $attrs = Evo::Class::Attrs->new();
  $attrs->gen_attr('foo', A_RELAXED, (undef) x 3);
  $attrs->gen_attr('bar', A_DEFAULT, (undef) x 3);

  is_deeply [$attrs->slots], [['foo', A_RELAXED, (undef) x 3], ['bar', A_DEFAULT, (undef) x 3]];
  is_deeply [$attrs->list_names], [qw(foo bar)];

  ok $attrs->exists('foo');
  ok $attrs->exists('bar');
  ok !$attrs->exists('bar404');
}

done_testing;
