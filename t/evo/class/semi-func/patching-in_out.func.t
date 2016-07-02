package main;
use Evo 'Test::More; -Internal::Exception';

{

  package My::Class::Out;
  use Evo -Class::Out;
  has 'attr1';
  has_over 'attr2', is => 'rw';

  package My::Class::In;
  use Evo -Class;
  has 'attr1';
  has_over 'attr2';

  package My::Class::In2;
  use Evo '-Class new:new2 META:META2';
}

ok(My::Class::Out->can($_)) for qw(attr1 attr2 attr_exists attr_delete init);
ok(My::Class::In->can($_))  for qw(attr1 attr2 attr_exists attr_delete new);
ok(My::Class::In2->can('new2'));

ok $My::Class::Out::EVO_CLASS_META;
ok $My::Class::In::EVO_CLASS_META;
is(My::Class::Out->META,  $My::Class::Out::EVO_CLASS_META);
is(My::Class::In->META,   $My::Class::In::EVO_CLASS_META);
is(My::Class::In2->META2, $My::Class::In2::EVO_CLASS_META);

my $obj_in = My::Class::In->new(attr1 => 1, attr2 => 2);
is $obj_in->attr1, 1;
is $obj_in->attr2, 2;
is ref $obj_in, 'My::Class::In';

my $obj_out = My::Class::Out->init([], attr1 => 1, attr2 => 2);
is $obj_out->attr1, 1;
is $obj_out->attr2, 2;
is ref $obj_out, 'My::Class::Out';

is ref(My::Class::In2->new2), 'My::Class::In2';

done_testing;
