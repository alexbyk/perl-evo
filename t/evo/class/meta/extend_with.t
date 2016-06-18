use Evo '-Class::Meta; Test::More; Test::Fatal; Test::Evo::Helpers *';

no warnings qw(once redefine );
local *Evo::Class::Meta::monkey_patch = sub { };

#EMPTY: {
#  like exception { dummy_meta->extend_with(dummy_meta()) }, qr/Empty/;
#}

EXTEND_ATTR: {
  my $parent = dummy_meta('My::Parent');
  my $child  = dummy_meta('My::Child');
  my $child2 = dummy_meta('My::Child2');

  $parent->install_attr('myattr1', 'DEF', check => sub {1});
  $parent->install_attr('myattr2', is => 'ro', check => sub {1});

  $child->extend_with($parent);

  is_deeply { $parent->public_attrs }, {$child->public_attrs};
  is_deeply $parent->builder_options, $child->builder_options;

  $parent->mark_private('myattr2');
  $child2->extend_with($parent);
  is_deeply [keys {$child2->public_attrs}->%*], ['myattr1'];

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

  my $sub = sub { };
  local *Evo::Class::Meta::names2code = sub {$sub};

  $parent->reg_method('meth1');
  $parent->reg_method('meth2');

  $child->extend_with($parent);
  is_deeply { $parent->public_methods }, {$child->public_methods};

}

CLASHING_METHODS: {
  my $parent = dummy_meta('My::Parent');
  my $child  = dummy_meta('My::Child');
  local *My::Parent::mymeth = sub {'p'};
  $parent->reg_method('mymeth');
  local *My::Child::mymeth = sub {'ch'};
  like exception { $child->extend_with($parent) }, qr/can.+mymeth/;
}

OVERRIDEN: {
  my $parent = dummy_meta('My::Parent');
  my $child  = dummy_meta('My::Child');
  local *My::Parent::mymeth = sub {'p'};
  $parent->reg_method('mymeth');
  $parent->reg_attr('myattr');
  local *My::Child::mymeth = sub { };
  local *My::Child::myattr = sub { };
  $child->mark_overridden("mymeth");
  $child->mark_overridden("myattr");
  $child->extend_with($parent);
}


done_testing;
