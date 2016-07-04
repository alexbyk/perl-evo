package main;
use Evo 'Test::More', -Class::Meta, -Internal::Exception;
use Symbol 'delete_package';

no warnings 'once';        ## no critic
no warnings 'redefine';    ## no critic
my $loaded;
local *Module::Load::load = sub { $loaded = shift };

{

  package My::Gen;
  use Evo;
  sub new($class) { bless {}, $class }

  sub gen_attr ($self, $name, %opts) {
    sub { uc "ATTR-$name" };
  }

};


sub gen_meta($class = 'My::Class') {
  delete_package $class;
  Evo::Internal::Util::pkg_stash($class, 'EVO_CLASS_META', undef);
  Evo::Class::Meta->register($class, 'My::Gen');
}

REGISTER: {
  my ($meta) = Evo::Class::Meta->register('My::Class', 'My::Gen');
  is $My::Class::EVO_CLASS_META, $meta;
  is $meta, Evo::Class::Meta->register('My::Class', 'My::Gen');
}

BUILD_DEF: {
  ok gen_meta->package;
  ok gen_meta->reqs;
  ok gen_meta->attrs;
  ok gen_meta->methods;
  ok gen_meta->gen;
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

  eval 'package My::Class; sub own {}';    ## no critic
  ok $meta->is_method('own');

  eval 'package My::Class; *own2 = sub {}';    ## no critic
  ok $meta->is_method('own2');
  ok !$meta->is_method('not_exists');

  # external sub
  eval '*My::Class::external = sub { };';      ## no critic
  ok !$meta->is_method('external');
  $meta->reg_method('external');
  ok $meta->is_method('external');

  # skip xsubs
  eval 'package My::Class; use Fcntl "SEEK_CUR"';    ## no critic
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
  eval 'package My::Class; sub own {}';      ## no critic
  eval '*My::Class::external = sub { };';    ## no critic

  $meta->attrs->{'attr1'}++;
  like exception { $meta->reg_method('attr1'); },        qr/has attribute.+attr1.+$0/;
  like exception { $meta->reg_method('not_existing'); }, qr/doesn't exist.+$0/;
  like exception { $meta->reg_method('own'); },          qr/already.+own.+$0/;

  ok !$meta->is_method('external');
  $meta->reg_method('external');
  ok $meta->is_method('external');
}

PUBLIC_METHODS: {

  my $meta = gen_meta;
  eval '*My::Class::external = sub { };';    ## no critic
  eval 'package My::Class; sub own {}';      ## no critic


  # only own
  $meta->attrs->{bad} = {};
  is_deeply { $meta->public_methods }, {own => My::Class->can('own')};

  # add external
  $meta->reg_method('external');
  is_deeply { $meta->public_methods },
    {external => My::Class->can('external'), own => My::Class->can('own')};

  # now mark as private
  $meta->mark_as_private('own');
  is_deeply { $meta->public_methods }, {external => My::Class->can('external')};
}

EXTEND_METHODS: {

  my $parent = gen_meta;
NORMAL: {
    eval 'package My::Class; sub own {"OWN"}';    ## no critic
    my $child = gen_meta('My::Child');
    $child->extend_with('/::Class');
    is $loaded, 'My::Class';
    ok $child->is_method('own');
    is(My::Child->own, 'OWN');
  }

PRIVATE: {
    eval 'package My::Class; sub own {}; sub priv {}';    ## no critic
    $parent->mark_as_private('priv');
    my $child = gen_meta('My::Child');
    $child->extend_with('My::Class');
    ok !$child->is_method('priv');
    ok(My::Child->can('own'));
    ok(!My::Child->can('priv'));
  }

OVERRIDEN: {
    my $parent = gen_meta;
    my $child  = gen_meta('My::Child');
    eval 'package My::Class; sub own {"OWN"}';            ## no critic
    eval 'package My::Child; sub own {"OVER"}';           ## no critic
    $child->mark_as_overridden('own');
    $child->extend_with('My::Class');
    is(My::Child->own, 'OVER');
  }

CLASH_SUB: {
    my $child = gen_meta('My::Child');
    eval 'package My::Child; sub own {"OVER"}';           ## no critic
    like exception { $child->extend_with('My::Class') }, qr/My::Child.+own.+$0/;
  }

CLASH_ATTR: {
    my $child = gen_meta('My::Child');
    $child->reg_attr('own');
    like exception { $child->extend_with('My::Class') }, qr/My::Child.+own.+$0/;
    is(My::Child->own, 'ATTR-OWN');
  }

CLASH_METHOD: {
    my $child = gen_meta('My::Child');
    eval 'package My::Child; sub own {"CHILD"}';    ## no critic
    like exception { $child->extend_with('My::Class') }, qr/My::Child.+own.+$0/;
    is(My::Child->own, 'CHILD');
  }

}


REG_ATTR: {
  my $meta = gen_meta;
  $meta->reg_attr('pub1', is => 'rw');

  ok $meta->is_attr('pub1');
  is(My::Class->pub1, 'ATTR-PUB1');

  eval '*My::Class::mysub = sub { }';       ## no critic
  eval 'package My::Class; sub own { }';    ## no critic


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

  ok $meta->is_attr('pub1');
  is(My::Class->pub1, 'ATTR-PUB1');

  eval '*My::Class::external = sub { }';    ## no critic
  eval 'package My::Class; sub own { }';    ## no critic

  $meta->reg_attr_over('external');
  $meta->reg_attr_over('pub1');
  $meta->reg_attr_over('own');
  ok $meta->is_overridden('pub1');
  ok $meta->is_overridden('own');
  ok $meta->is_overridden('external');
  is(My::Class->own,      'ATTR-OWN');
  is(My::Class->external, 'ATTR-EXTERNAL');
}


PUBLIC_ATTRS: {
  my $meta = gen_meta;
  $meta->reg_attr('attr1', is => 'rw');
  $meta->reg_attr('attr2', is => 'rw');
  is(My::Class->attr1, 'ATTR-ATTR1');
  is(My::Class->attr2, 'ATTR-ATTR2');
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
    eval '*My::Child::own = sub {"OVER"}';    ## no critic
    $child->mark_as_overridden('own');
    $child->extend_with('My::Parent');
    is(My::Child->own, 'OVER');
  }

CLASH_SUB: {
    my $child = gen_meta('My::Child');
    eval '*My::Child::pub1 = sub {"OVER"}';    ## no critic
    like exception { $child->extend_with('My::Parent') }, qr/My::Child.+pub1.+$0/;
  }

CLASH_ATTR: {
    my $child = gen_meta('My::Child');
    $child->reg_attr('pub1');
    like exception { $child->extend_with('My::Parent') }, qr/My::Child.+pub1.+$0/;
  }

CLASH_METHOD: {
    my $child = gen_meta('My::Child');
    eval '*My::Child::pub1 = sub {"FOO"}';     ## no critic
    $child->reg_method('pub1');
    like exception { $child->extend_with('My::Parent') }, qr/My::Child.+pub1.+$0/;
    is(My::Child->pub1, 'FOO');
  }

}


REQUIREMENTS: {
  my $meta  = gen_meta;
  my $child = gen_meta('My::Child');
  eval '*My::Class::bad = sub {"FOO"}';        ## no critic
  eval '*My::Class::meth1 = sub {"FOO"}';      ## no critic
  eval 'package My::Class; sub own {}';        ## no critic
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
  eval '*My::Class::meth1 = sub {"FOO"}';       ## no critic
  eval '*My::Class::methpriv = sub {"FOO"}';    ## no critic
  eval 'package My::Class; sub own {}';         ## no critic
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
  eval 'package My::Class; sub mymeth {"FOO"}';    ## no critic
  eval '*My::Class::mysub = sub {"FOO"}';          ## no critic

  $meta->check_implementation('/::Inter');
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
    like exception { parse_attr(lazy  => 0) },     qr/lazy.+$0/;
    like exception { parse_attr(check => 0) },     qr/check.+$0/;
    like exception { parse_attr(is    => 'foo') }, qr/invalid "is".+$0/;
    like exception { parse_attr(un1 => 1, un2 => 2) }, qr/unknown.+un1.+un2.+$0/;
  }


  is_deeply { parse_attr() }, {};

  my $dc = sub { };

  # perl6 && mojo style for default
  is_deeply { parse_attr('FOO') }, {default => 'FOO'};
  is_deeply { parse_attr($dc) }, {default => $dc, default_is_code => 1};

  # perl6 style
  is_deeply { parse_attr('FOO', is => 'ro') }, {ro => 1, default => 'FOO'};
  is_deeply { parse_attr($dc, is => 'ro') }, {default => $dc, default_is_code => 1, ro => 1};

  #  moose style
  is_deeply { parse_attr(is => 'rw', default => 'FOO') }, {default => 'FOO'};
  is_deeply { parse_attr(is => 'ro', default => $dc) },
    {ro => 1, default => $dc, default_is_code => 1};

  # required
  is_deeply { parse_attr(is => 'ro', required => 1) }, {ro => 1, required => 1};


  # rw ro
  is_deeply { parse_attr() }, {};
  is_deeply { parse_attr(is => 'rw') }, {};
  is_deeply { parse_attr(is => 'ro') }, {ro => 1};


  # all
  my $t    = sub {1};
  my $lazy = sub { };
  is_deeply { parse_attr(is => 'ro', check => $t, required => 1, lazy => $lazy,) },
    {ro => 1, required => 1, lazy => $lazy, check => $t};


}

done_testing;
