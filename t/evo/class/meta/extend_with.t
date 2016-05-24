use Evo '-Class::Meta; Test::More; Test::Fatal; Test::Evo::Helpers *';

no warnings qw(once redefine );
local *Evo::Class::Meta::monkey_patch = sub { };

#EMPTY: {
#  like exception { dummy_meta->extend_with(dummy_meta()) }, qr/Empty/;
#}

EXTEND_ATTR: {
  my $parent = dummy_meta('My::Parent');
  my $child  = dummy_meta('My::Child');

  $parent->install_attr('myattr1', 'DEF', check => sub {1});
  $parent->install_attr('myattr2', is => 'ro', check => sub {1});

  $child->extend_with($parent);

  is_deeply { $parent->attrs }, {$child->attrs};
  is_deeply $parent->builder_options, $child->builder_options;

}

CLASHING_ATTRS: {
  my $parent = dummy_meta('My::Parent');
  my $child  = dummy_meta('My::Child');
  $parent->install_attr('myattr', default => 'DEF', check => sub {1});
  local *My::Child::myattr = sub { };
  like exception { $child->extend_with($parent) }, qr/can.+myattr/;
}

EXTEND_METHOD: {
  my $parent = dummy_meta('My::Parent');
  my $child  = dummy_meta('My::Child');

  $parent->reg_method('meth1', code => sub { });
  $parent->reg_method('meth2', code => sub { });

  $child->extend_with($parent);
  is_deeply { $parent->methods }, {$child->methods};

}

CLASHING_METHODS: {
  my $parent = dummy_meta('My::Parent');
  my $child  = dummy_meta('My::Child');
  $parent->reg_method('mymeth', code => sub { });
  local *My::Child::mymeth = sub { };
  like exception { $child->extend_with($parent) }, qr/can.+mymeth/;
}

OVERRIDEN: {
  my $parent = dummy_meta('My::Parent');
  my $child  = dummy_meta('My::Child');
  $parent->reg_method('mymeth', code => sub { });
  $parent->reg_attr('myattr');
  local *My::Child::mymeth = sub { };
  local *My::Child::myattr = sub { };
  $child->mark_overriden("mymeth");
  $child->mark_overriden("myattr");
  $child->extend_with($parent);
}


done_testing;
