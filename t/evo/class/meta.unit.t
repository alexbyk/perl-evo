package main;
use Evo 'Test::More', -Class::Meta, -Internal::Exception;

no warnings 'once';        ## no critic
no warnings 'redefine';    ## no critic
my $loaded;
local *Module::Load::load = sub { $loaded = shift };

{

  package My::Class;
  sub own     {'OWN'}
  my sub priv {'PRIV'}
  use Fcntl "SEEK_CUR";

};

sub gen_meta($class = 'My::Class') {
  Evo::Internal::Util::pkg_stash($class, 'EVO_CLASS_META', undef);
  (Evo::Class::Meta->register($class))[0];
}

REGISTER: {
  my ($meta) = Evo::Class::Meta->register('My::Class');
  is $My::Class::EVO_CLASS_META, $meta;
  is $meta,                      Evo::Class::Meta->register('My::Class');
}

BUILD_DEF: {
  ok gen_meta->reqs;
  ok gen_meta->attrs;
  ok gen_meta->methods;
}

FIND_OR_CROAK: {
  like exception { Evo::Class::Meta->find_or_croak('My::Bad'); }, qr/My::Bad.+$0/;
}


MARK_OVERRIDEN: {
  my $meta = gen_meta;
  $meta->mark_as_overridden('mymeth');
  ok $meta->is_overridden('mymeth');
  ok !$meta->is_overridden('mymeth2');
}

MARK_PRIVATE: {
  my $meta = gen_meta;
  $meta->mark_as_private('private');
  ok $meta->is_private('private');
  ok !$meta->is_private('any');
}


IS_METHOD__REG_METHOD: {
  my $meta = gen_meta;

  ok $meta->is_method('own');

  local *My::Class::own2;
  eval 'package My::Class; *own2 = sub {}';    ## no critic
  ok $meta->is_method('own2');
  ok !$meta->is_method('not_exists');

  # external sub
  local *My::Class::external = sub { };
  ok !$meta->is_method('external');
  $meta->reg_method('external');
  ok $meta->is_method('external');

  # skip xsubs
  ok(My::Class->can('SEEK_CUR'));
  ok !$meta->is_method('SEEK_CUR');

  $meta->reg_attr('attr1');
  like exception { $meta->reg_method('not_existing'); }, qr/doesn't exist.+$0/;
  like exception { $meta->reg_method('attr1'); },        qr/already.+attribute.+attr1.+$0/;
  like exception { $meta->reg_method('own'); },          qr/already.+own".+$0/;
  like exception { $meta->reg_attr('4bad'); },           qr/4bad.+invalid.+$0/i;

}

REG_METHOD: {
  my $meta = gen_meta;

  $meta->attrs->{'attr1'}++;
  like exception { $meta->reg_method('attr1'); },        qr/has attribute.+attr1.+$0/;
  like exception { $meta->reg_method('not_existing'); }, qr/doesn't exist.+$0/;
  like exception { $meta->reg_method('own'); },          qr/already.+own.+$0/;

  local *My::Class::external = sub { };
  ok !$meta->is_method('external');
  $meta->reg_method('external');
  ok $meta->is_method('external');
}

PUBLIC_METHODS: {

  my $meta = gen_meta;

  # only own
  $meta->attrs->{bad} = {};
  local *My::Class::mysub = sub { };
  is_deeply { $meta->public_methods }, {own => \&My::Class::own};

  # add external
  $meta->reg_method('mysub');
  is_deeply { $meta->public_methods }, {mysub => \&My::Class::mysub, own => \&My::Class::own};

  # now mark as private
  $meta->mark_as_private('own');
  is_deeply { $meta->public_methods }, {mysub => \&My::Class::mysub};
}

EXTEND_METHODS: {
  my $parent = gen_meta;

NORMAL: {
    local *My::Child::own;
    my $child = gen_meta('My::Child');
    $child->extend_with('My::Class');
    is $loaded, 'My::Class';
    ok $child->is_method('own');
    is(My::Child->own, 'OWN');
  }

PRIVATE: {
    local *My::Child::own;
    local *My::Class::priv = sub { };
    $parent->reg_method('priv');
    $parent->mark_as_private('priv');
    my $child = gen_meta('My::Child');
    $child->extend_with('My::Class');
    ok !$child->is_method('priv');
  }

OVERRIDEN: {
    my $child = gen_meta('My::Child');
    local *My::Child::own = sub {'OVER'};
    $child->mark_as_overridden('own');
    $child->extend_with('My::Class');
    is(My::Child->own, 'OVER');
  }

CLASH_SUB: {
    my $child = gen_meta('My::Child');
    local *My::Child::own = sub {'FOO'};
    like exception { $child->extend_with('My::Class') }, qr/My::Child.+own.+$0/;
  }

CLASH_ATTR: {
    my $child = gen_meta('My::Child');
    $child->reg_attr('own');
    like exception { $child->extend_with('My::Class') }, qr/My::Child.+own.+$0/;
    ok !(My::Child->can('own'));
  }

CLASH_METHOD: {
    my $child = gen_meta('My::Child');
    local *My::Child::own = sub {'FOO'};
    $child->reg_method('own');
    like exception { $child->extend_with('My::Class') }, qr/My::Child.+own.+$0/;
    is(My::Child->own, 'FOO');
  }

}


REG_ATTR: {
  my $meta = gen_meta;
  $meta->reg_attr('pub1', is => 'rw');
  ok $meta->is_attr('pub1');

  local *My::Class::mysub = sub { };

  # errors
  like exception { $meta->reg_attr('pub1') },  qr/My::Class.+already.+attribute.+pub1.+$0/;
  like exception { $meta->reg_attr('mysub') }, qr/My::Class.+already.+subroutine.+mysub.+$0/;
  like exception { $meta->reg_attr('own') },   qr/My::Class.+already.+method.+own.+$0/;
  like exception { $meta->reg_attr('4bad'); }, qr/4bad.+invalid.+$0/i;
  ok !$meta->is_attr($_) for qw(mysub own 4bad);
}

REG_ATTR_OVER: {
  my $meta = gen_meta;
  $meta->reg_attr('pub1', is => 'rw');
  local *My::Class::mysub = sub { };

  $meta->reg_attr_over('mysub');
  $meta->reg_attr_over('pub1');
  $meta->reg_attr_over('own');
  ok $meta->is_overridden('pub1');
}


PUBLIC_ATTRS: {
  my $meta = gen_meta;
  $meta->reg_attr('attr1', is => 'rw');
  $meta->reg_attr('attr2', is => 'rw');
  my %map = $meta->public_attrs;
  is_deeply [sort keys %map], [sort qw(attr1 attr2)];

  $meta->mark_as_private('attr1');
  %map = $meta->public_attrs;
  is_deeply [sort keys %map], [sort qw(attr2)];
}

EXTEND_ATTRS: {
  my $parent = gen_meta('My::Parent');
  $parent->reg_attr('pub1');

NORMAL: {
    my $child = gen_meta('My::Child');
    $child->extend_with('My::Parent');
    ok $child->is_attr('pub1');
  }


PRIVATE: {
    local *My::Child::own;
    local *My::Class::priv = sub { };
    $parent->reg_attr('priv');
    $parent->mark_as_private('priv');
    my $child = gen_meta('My::Child');
    $child->extend_with('My::Class');
    ok !$child->is_attr('priv');
  }

OVERRIDEN: {
    my $child = gen_meta('My::Child');
    local *My::Child::own = sub {'OVER'};
    $child->mark_as_overridden('own');
    $child->extend_with('My::Parent');
    is(My::Child->own, 'OVER');
  }

CLASH_SUB: {
    my $child = gen_meta('My::Child');
    local *My::Child::pub1 = sub { };
    like exception { $child->extend_with('My::Parent') }, qr/My::Child.+pub1.+$0/;
  }

CLASH_ATTR: {
    my $child = gen_meta('My::Child');
    $child->reg_attr('pub1');
    like exception { $child->extend_with('My::Parent') }, qr/My::Child.+pub1.+$0/;
  }

CLASH_METHOD: {
    my $child = gen_meta('My::Child');
    local *My::Child::pub1 = sub {'FOO'};
    $child->reg_method('pub1');
    like exception { $child->extend_with('My::Parent') }, qr/My::Child.+pub1.+$0/;
    is(My::Child->pub1, 'FOO');
  }

}


REQUIREMENTS: {
  my $meta  = gen_meta;
  my $child = gen_meta('My::Child');
  local *My::Class::bad   = sub { };
  local *My::Class::meth1 = sub { };
  $meta->reg_attr('attr1');
  $meta->reg_method('meth1');
  $meta->reg_requirement('req1');

  is_deeply [sort $meta->requirements], [sort qw(req1 attr1 meth1 own)];

  $meta->mark_as_private('attr1');
  $meta->mark_as_private('meth1');
  is_deeply [sort $meta->requirements], [sort qw(req1 own)];

}

EXTEND_REQUIREMENTS: {
  my $meta  = gen_meta;
  my $child = gen_meta('My::ChildR');
  local *My::Class::meth1 = sub { };
  local *My::Class::metho = sub { };
  $meta->reg_requirement('req1');
  $meta->reg_method('meth1');
  $meta->reg_attr('attr1');
  $child->extend_with('My::Class');

  is_deeply [sort $child->requirements], [sort qw(req1 meth1 own attr1)];
}


CHECK_IMPLEMENTATION: {
  my $inter = gen_meta('My::Inter');
  my $meta  = gen_meta();

  like exception { $meta->check_implementation('My::NotExists') },
    qr/NotExists isn't.+Evo::Class.+$0/;
  like exception { $meta->check_implementation('My::Inter') }, qr/Empty.+$0/i;

  $inter->reg_requirement('myattr');
  $inter->reg_requirement('mymeth');
  $inter->reg_requirement('mysub');

  like exception { $meta->check_implementation('My::Inter'); }, qr/myattr;mymeth.+$0/;

  # method, attr, sub
  $meta->reg_attr('myattr');
  local *My::Class::mymeth = sub { };
  $meta->reg_method('mymeth');
  local *My::Class::mysub = sub { };

  $meta->check_implementation('My::Inter');
  is $loaded, 'My::Inter';
}

sub parse_attr { Evo::Class::Meta->parse_attr(@_) }
PARSE_ATTR: {
ERRORS: {
    # required + default doesn't make sense
    like exception { parse_attr(required => 1, default => 'foo') }, qr/default.+required.+$0/;

    # default or lazy should be either scalar or coderef
    like exception { parse_attr(default => {}) }, qr/default.+$0/;
    like exception { parse_attr(lazy    => {}) }, qr/lazy.+$0/;
    like exception { parse_attr(lazy  => 0) }, qr/lazy.+$0/;
    like exception { parse_attr(check => 0) }, qr/check.+$0/;

    # extra known
    like exception { parse_attr(un1 => 1, un2 => 2) }, qr/unknown.+un1.+un2.+$0/;
  }


  is_deeply { parse_attr() }, {};

  # perl6 && mojo style for default
  is_deeply { parse_attr('FOO') }, {default => 'FOO'};

  # perl6 style
  is_deeply { parse_attr('FOO', is => 'rw') }, {is => 'rw', default => 'FOO'};

  #  moose style
  is_deeply { parse_attr(is => 'rw', default => 'FOO') }, {is => 'rw', default => 'FOO'};

  # required
  is_deeply { parse_attr(is => 'rw', required => 1) }, {is => 'rw', required => 1};


  # all
  my $t    = sub {1};
  my $lazy = sub { };
  is_deeply { parse_attr(is => 'rw', check => $t, required => 1, lazy => $lazy,) },
    {is => 'rw', required => 1, lazy => $lazy, check => $t};


}

done_testing;
