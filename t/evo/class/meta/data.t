package main;
use Evo '-Class::Meta; Test::More; Test::Evo::Helpers exception; Test::Evo::Helpers *';

no warnings 'once';    ## no critic
{

  package My::Foo;
  sub own { }
  *ownalias = *own;
};
*My::Foo::external = sub { };

IS_HIDDEN: {
  my $obj = dummy_meta('My::Foo');
  $obj->mark_private('own');
  ok $obj->is_private('own');
  $obj->reg_attr('foo');
  $obj->mark_private('foo');
  ok $obj->is_private('foo');
}

IS_PUBLIC_METHOD: {
  my $obj = dummy_meta('My::Foo');

  # own sub
  ok $obj->is_public_method('own');
  $obj->mark_private('own');
  ok !$obj->is_public_method('own');

  # external sub
  ok !$obj->is_public_method('external');
  $obj->reg_method('external');
  ok $obj->is_public_method('external');

  # attr
  $obj->reg_attr('foo');
  local *My::Foo::foo = sub { };
  ok !$obj->is_public_method('foo'), 'attr, not method';

}


IS_PUBLIC_ATTR: {
  my $obj = dummy_meta('My::Foo');
  ok !$obj->is_public_attr('own');

  $obj->reg_attr('foo');
  ok $obj->is_public_attr('foo');

  $obj->mark_private('foo');
  ok !$obj->is_public_attr('foo');
}


MARK_OVERRIDEN: {
  my $obj = dummy_meta;
  $obj->mark_overridden('mymeth');
  ok $obj->is_overridden('mymeth');
  ok !$obj->is_overridden('mymeth2');

  $obj->reg_attr('foo');
  $obj->mark_overridden('foo');
  $obj->reg_attr('foo');
}


METHOD_ERRORS: {
  my $obj = dummy_meta('My::Foo');
  like exception { $obj->reg_method('not_existing'); }, qr/doesn't exist.+$0/;
  like exception { $obj->reg_method('own'); },          qr/already has "own".+$0/;
}


ATTR_ERRORS: {
  my $obj = dummy_meta;
  like exception { $obj->reg_attr('foo') for 1 .. 2; }, qr/My::Dummy.+already.+foo.+$0/;
  like exception { $obj->reg_attr('own') for 1 .. 2; }, qr/My::Dummy.+already.+own.+$0/;
  like exception { $obj->reg_attr('4bad'); }, qr/4bad.+$0/i;
}


ATTR: {
  my $obj = dummy_meta;
  $obj->reg_attr('attr1', is => 'rw');
  $obj->reg_attr('attr2', is => 'ro');
  is_deeply { $obj->public_attrs }, {attr1 => {is => 'rw'}, attr2 => {is => 'ro'}};

  $obj->mark_private('attr1');
  $obj->mark_private('attr2');
  is_deeply { $obj->public_attrs }, {};
}

METHOD: {
  my $obj = dummy_meta('My::Foo');
  my %map = $obj->public_methods;
  is_deeply [keys %map], [qw(own)];

  $obj->reg_attr('attr1', is => 'rw');
  $obj->reg_method('ownalias');
  %map = $obj->public_methods;
  is_deeply [sort keys %map], [sort qw(own ownalias)];

  $obj->mark_private('own');
  %map = $obj->public_methods;
  is_deeply [keys %map], [sort qw(ownalias)];
}

SKIP_XSUBS: {
  eval 'package My::WithConst; use Fcntl "SEEK_CUR";';    ## no critic
  my $obj  = dummy_meta('My::WithConst');
  my %hash = $obj->public_methods;
  ok !keys %hash;
}


REQUIREMENTS: {
  my $obj = dummy_meta('My::Bar');
  local *My::Bar::meth1 = sub { };
  $obj->reg_method('meth1');
  $obj->reg_attr('attr1');
  $obj->reg_requirement('req1');

  is_deeply [sort $obj->requirements], [sort qw(req1 attr1 meth1)];
}

done_testing;
