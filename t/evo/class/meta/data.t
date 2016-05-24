use Evo '-Class::Meta; Test::More; Test::Fatal; Test::Evo::Helpers *';


ERRORS: {
  my $obj = dummy_meta;

  foreach my $what (qw(reg_method reg_attr)) {
    like exception {
      $obj->$what(foo => code => sub { }) for 1 .. 2;
    }, qr/My::Dummy.+already.+foo.+$0/;

    like exception {
      $obj->$what('4bad', code => sub { });
    }, qr/4bad.+$0/i;
  }

}


ATTR: {
  my $obj = dummy_meta;
  $obj->reg_attr('attr1', is => 'rw');
  $obj->reg_attr('attr2', is => 'ro');

  is_deeply { $obj->attrs }, {attr1 => {is => 'rw'}, attr2 => {is => 'ro'}};

}

METHOD: {
  my $obj = dummy_meta;
  my $cb = sub { };
  $obj->reg_method('meth1', code => $cb);
  $obj->reg_method('meth2', code => $cb);

  is_deeply { $obj->methods }, {meth1 => {code => $cb}, meth2 => {code => $cb}};
}

MARK_OVERRIDEN: {
  my $obj = dummy_meta;
  $obj->mark_overriden('mymeth');
  ok $obj->is_overriden('mymeth');
  ok !$obj->is_overriden('mymeth2');
}

REQUIREMENTS: {
  my $obj = dummy_meta;
  $obj->reg_method('meth1', code => sub { });
  $obj->reg_attr('attr1', is => 'rw');
  $obj->reg_requirement('req1');

  is_deeply [sort $obj->requirements], [sort qw(req1 attr1 meth1)];
}

done_testing;
