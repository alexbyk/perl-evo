package main;
use Evo 'Test::More; -Internal::Exception';

{

  package My::Class;
  use Evo -Class;
  has 'attr1';
  has_over 'attr2', is => 'rw';


  package My::Class2;
  use Evo '-Class new:new2 META:META2';
}

ok(My::Class->can($_), "$_ exists") for qw(attr1 attr2 attr_exists attr_delete init);
ok(My::Class2->can('new2'));

ok $My::Class::EVO_CLASS_META;
is(My::Class->META,   $My::Class::EVO_CLASS_META);
is(My::Class2->META2, $My::Class2::EVO_CLASS_META);

my $obj = My::Class->new(attr1 => 1, attr2 => 2);
is $obj->attr1, 1;
is $obj->attr2, 2;
is ref $obj, 'My::Class';

my $obj = My::Class->init([], attr1 => 1, attr2 => 2);
is $obj->attr1, 1;
is $obj->attr2, 2;
is ref $obj, 'My::Class';

is ref(My::Class2->new2), 'My::Class2';

done_testing;
