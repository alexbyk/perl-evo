use Evo 'Test::More; -Internal::Exception; -Class::Attrs *';

DUPL: {
  my $attrs = Evo::Class::Attrs->new();
  $attrs->gen_attr('foo', ECA_RELAXED, (undef) x 3);
  $attrs->gen_attr('bar', ECA_RELAXED, (undef) x 3);
  is_deeply $attrs, [['foo', ECA_RELAXED, (undef) x 3], ['bar', ECA_RELAXED, (undef) x 3]];
  $attrs->gen_attr('foo', ECA_DEFAULT,  (undef) x 3);
  $attrs->gen_attr('bar', ECA_REQUIRED, (undef) x 3);
  is_deeply $attrs, [['foo', ECA_DEFAULT, (undef) x 3], ['bar', ECA_REQUIRED, (undef) x 3]];
}

NAMES_EXISTS: {
  my $attrs = Evo::Class::Attrs->new();
  $attrs->gen_attr('foo', ECA_RELAXED, (undef) x 3);
  $attrs->gen_attr('bar', ECA_DEFAULT, (undef) x 3);

  is_deeply [$attrs->slots], [['foo', ECA_RELAXED, (undef) x 3], ['bar', ECA_DEFAULT, (undef) x 3]];
  is_deeply [$attrs->list_names], [qw(foo bar)];

  ok $attrs->exists('foo');
  ok $attrs->exists('bar');
  ok !$attrs->exists('bar404');
}

done_testing;
