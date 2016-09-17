use Evo 'Test::More; -Internal::Exception;-Class::Meta; -Class::Attrs';

sub parse { Evo::Class::Meta->parse_attr(@_) }

my $positive = sub($v) { $v > 0 ? 1 : (0, 'OOPS') };

my ($attrs, $new);
sub before() {
  $attrs = Evo::Class::Attrs->new();
  my $_new = $attrs->gen_new;
  $new = sub {$_new->('My::Class', @_)};
};


SIMPLE: {
  before();
  $attrs->gen_attr(simple => parse is => 'rw');
  my $val = 333;
  my $obj = $new->(simple => $val);
  $val = 'bad';
  is_deeply $obj, {'simple', 333};
}

REQUIRED: {
  before();
  $attrs->gen_attr(req => parse required => 1);
  like exception { $new->() }, qr#"req" is required.+$0#;
}

UNKNOWN: {
  before();
  like exception { $new->(bad => 1) }, qr#Unknown.+bad.+$0#;
}


DEFAULT_CODE: {
  before();
  my $def = sub($class) { is $class, 'My::Class'; 'DEF' };
  $attrs->gen_attr(foo => parse default => $def);
  is_deeply $new->(foo => 222), {foo => 222};
  is_deeply $new->(), {foo => 'DEF'};
  is_deeply $new->(foo => undef), {foo => undef};
}

DEFAULT_VALUE: {
  before();
  my $val = 'DEF';
  $attrs->gen_attr(foo => parse default => $val);
  $val = 'bad';
  is_deeply $new->(foo => 222), {foo => 222};
  is_deeply $new->(), {foo => 'DEF'};
  is_deeply $new->(foo => undef), {foo => undef};
}


CHECK: {
  before();
  # check if passed but bypass checking of default value, even if it's negative
  $attrs->gen_attr(foo => parse default => 0, check => $positive);
  like exception { $new->(foo => 0) }, qr#Bad value.+"0".+"foo".+OOPS.+$0#i;
  is_deeply $new->(), {foo => 0};
  is_deeply $new->(foo => 1), {foo => 1};
}


done_testing;
