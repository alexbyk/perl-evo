package main;
use Evo 'Test::More', '-Class::Attrs *', -Class::Meta, -Internal::Exception;
use Symbol 'delete_package';

no warnings 'once';        ## no critic
no warnings 'redefine';    ## no critic
my $loaded;
local *Module::Load::load = sub { $loaded = shift };

sub parse { Evo::Class::Meta->parse_attr(@_) }

my $prev = Evo::Class::Attrs->can('gen_attr');
local *Evo::Class::Attrs::gen_attr = sub ($self, $name, @opts) {
  $prev->($self, $name, @opts);
  sub { uc "ATTR-$name" };
};

sub gen_meta($class = 'My::Class') {
  delete_package $class;
  Evo::Internal::Util::pkg_stash($class, 'EVO_CLASS_META', undef);
  Evo::Class::Meta->register($class);
}

REGISTER: {
  my ($meta) = Evo::Class::Meta->register('My::Class');
  is $My::Class::EVO_CLASS_META, $meta;
  is $meta,                      Evo::Class::Meta->register('My::Class');
}

BUILD_DEF: {
  ok gen_meta->package;
  ok gen_meta->reqs;
  ok gen_meta->attrs;
  ok gen_meta->methods;
}

FIND_OR_CROAK: {
  like exception { Evo::Class::Meta->find_or_croak('My::Bad'); }, qr/My::Bad.+$0/;
}

PARSE_ATTR: {
ERRORS: {
    # required + default doesn't make sense
    # lazy + default doesn't make sense
    my $sub = sub { };
    like exception { parse_attr(required => 1, default => 'foo') }, qr/default.+required.+$0/;
    like exception { parse_attr(required => 1, lazy => $sub) }, qr/default.+required.+$0/;
    like exception { parse_attr(default  => 1, lazy => $sub) }, qr/default.+required.+$0/;

    # default or lazy should be either scalar or coderef
    like exception { parse_attr(default => {}) }, qr/default.+$0/;
    like exception { parse_attr(lazy    => {}) }, qr/lazy.+$0/;
    like exception { parse_attr(lazy  => undef) }, qr/lazy.+$0/;
    like exception { parse_attr(check => undef) }, qr/check.+$0/;
    like exception { parse_attr(is    => 'foo') }, qr/invalid "is".+$0/;
    like exception { parse_attr(un1 => 1, un2 => 2) }, qr/unknown.+un1.+un2.+$0/;

  }

  is_deeply [parse_attr()], [ECA_SIMPLE, (undef) x 2, 0, undef];
  is_deeply [parse_attr(is => 'rw')], [ECA_SIMPLE, (undef) x 2, 0, undef];

  my $dc = sub { };

  # perl6 && mojo style for default
  is_deeply [parse_attr('FOO')], [ECA_DEFAULT, 'FOO', undef, 0, undef];
  is_deeply [parse_attr($dc)], [ECA_DEFAULT_CODE, $dc, undef, 0, undef];


  # perl6 style
  is_deeply [parse_attr('FOO', is => 'ro')], [ECA_DEFAULT, 'FOO', undef, 1, undef];
  is_deeply [parse_attr($dc, is => 'ro')], [ECA_DEFAULT_CODE, $dc, undef, 1, undef];


  #  moose style
  is_deeply [parse_attr(is => 'rw', default => 'FOO')], [ECA_DEFAULT, 'FOO', undef, 0, undef];

  is_deeply [parse_attr(is => 'ro', default => $dc)], [ECA_DEFAULT_CODE, $dc, undef, 1, undef];

  # required
  is_deeply [parse_attr(required => 1)],     [ECA_REQUIRED, undef, undef, 0, undef];
  is_deeply [parse_attr(required => 'BOO')], [ECA_REQUIRED, undef, undef, 0, undef];
  is_deeply [parse_attr(required => 0)],     [ECA_SIMPLE,   undef, undef, 0, undef];


  # ro
  is_deeply [parse_attr(is => 'ro')], [ECA_SIMPLE, (undef) x 2, 1, undef];

  # all
  my $check = sub {1};
  my $lazy  = sub { {} };
  is_deeply [parse_attr(is => 'ro', check => $check, required => 1)],
    [ECA_REQUIRED, undef, $check, 1, undef];

  is_deeply [parse_attr(is => 'ro', check => $check, lazy => $lazy)],
    [ECA_LAZY, $lazy, $check, 1, undef];

  # extra default => undef
  is_deeply [parse_attr(default => undef)], [ECA_DEFAULT, undef, undef, 0, undef];

  # stash
  is_deeply [parse_attr(stash => {foo => 'bar'})], [ECA_SIMPLE, undef, undef, 0, {foo => 'bar'}];
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

  $meta->reg_attr('attr1', parse());
  like exception { $meta->reg_method('not_existing'); }, qr/doesn't exist.+$0/;
  like exception { $meta->reg_method('attr1'); },        qr/already.+attribute.+attr1.+$0/;
  like exception { $meta->reg_method('own'); },          qr/already.+own".+$0/;
  like exception { $meta->reg_attr('4bad', parse()); }, qr/4bad.+invalid.+$0/i;

}

REG_METHOD: {
  my $meta = gen_meta;
  eval 'package My::Class; sub own {}';      ## no critic
  eval '*My::Class::external = sub { };';    ## no critic

  $meta->attrs->gen_attr(attr1 => parse );
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
  $meta->attrs->gen_attr(bad => parse);
  is_deeply { $meta->_public_methods_map }, {own => My::Class->can('own')};
  is_deeply [$meta->public_methods], [qw(own)];

  # add external
  $meta->reg_method('external');
  is_deeply { $meta->_public_methods_map },
    {external => My::Class->can('external'), own => My::Class->can('own')};

  is_deeply [sort $meta->public_methods], [sort qw(external own)];

  # now mark as private
  $meta->mark_as_private('own');
  is_deeply { $meta->_public_methods_map }, {external => My::Class->can('external')};
  is_deeply [$meta->public_methods], [qw(external)];
}


EXTEND_METHODS: {

NORMAL: {
    my $parent = gen_meta;
    eval 'package My::Class; sub own {"OWN"}';    ## no critic
    my $child = gen_meta('My::Child');
    $child->extend_with('/::Class');
    is $loaded, 'My::Class';
    ok $child->is_method('own');
    is(My::Child->own, 'OWN');
  }

PRIVATE: {
    my $parent = gen_meta;
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

CLASH_METHOD: {
    my $parent = gen_meta;
    my $child  = gen_meta('My::Child');
    eval 'package My::Class; sub own {"OWN"}';            ## no critic
    eval 'package My::Child; sub own {"CHILD"}';          ## no critic
    like exception { $child->extend_with('My::Class') }, qr/My::Child.+own.+$0/;
    is(My::Child->own, 'CHILD');
  }

CLASH_ATTR: {
    my $parent = gen_meta;
    eval 'package My::Class; sub own {"OWN"}';            ## no critic
    my $child = gen_meta('My::Child');
    $child->reg_attr('own', parse(lazy => sub {'ATTR-OWN'}));
    like exception { $child->extend_with('My::Class') }, qr/My::Child.+own.+$0/;
    is(My::Child->own, 'ATTR-OWN');
  }


}


REG_ATTR: {
  my $meta = gen_meta;
  $meta->reg_attr('pub1', parse lazy => sub {'ATTR-PUB1'});

  ok $meta->is_attr('pub1');
  is(My::Class->pub1, 'ATTR-PUB1');

  eval '*My::Class::mysub = sub { }';       ## no critic
  eval 'package My::Class; sub own { }';    ## no critic


  # errors
  like exception { $meta->reg_attr('pub1', parse()) }, qr/My::Class.+already.+attribute.+pub1.+$0/;
  like exception { $meta->reg_attr('mysub', parse()) },
    qr/My::Class.+already.+subroutine.+mysub.+$0/;
  like exception { $meta->reg_attr('own', parse()) }, qr/My::Class.+already.+method.+own.+$0/;
  like exception { $meta->reg_attr('4bad', parse()); }, qr/4bad.+invalid.+$0/i;
  ok !$meta->is_attr($_) for qw(mysub own 4bad);
}

REG_ATTR_OVER: {
  my $meta = gen_meta;
  $meta->reg_attr('pub1', parse lazy => sub {'ATTR-PUB1'});

  ok $meta->is_attr('pub1');
  is(My::Class->pub1, 'ATTR-PUB1');

  eval '*My::Class::external = sub { }';    ## no critic
  eval 'package My::Class; sub own { }';    ## no critic

  $meta->reg_attr_over('external', parse lazy => sub {'ATTR-EXTERNAL'});
  $meta->reg_attr_over('pub1',     parse());
  $meta->reg_attr_over('own',      parse lazy => sub {'ATTR-OWN'});
  ok $meta->is_overridden('pub1');
  ok $meta->is_overridden('own');
  ok $meta->is_overridden('external');
  is(My::Class->own,      'ATTR-OWN');
  is(My::Class->external, 'ATTR-EXTERNAL');
}

PUBLIC_ATTRS: {
  my $meta = gen_meta;
  $meta->reg_attr('attr1', parse is => 'rw');
  $meta->reg_attr('attr2', parse is => 'rw');
  is(My::Class->attr1, 'ATTR-ATTR1');
  is(My::Class->attr2, 'ATTR-ATTR2');
  my @attrs = $meta->public_attrs;
  is_deeply \@attrs, [sort qw(attr1 attr2)];

  $meta->mark_as_private('attr1');
  @attrs = $meta->public_attrs;
  is_deeply \@attrs, [sort qw(attr2)];

}


EXTEND_ATTRS: {

NORMAL: {
    my $parent = gen_meta('My::Class');
    $parent->reg_attr('pub1', parse());
    my $child = gen_meta('My::Child');
    $child->extend_with('My::Class');
    ok $child->is_attr('pub1');
  }


PRIVATE: {
    my $parent = gen_meta('My::Class');
    $parent->reg_attr('priv', parse());
    $parent->mark_as_private('priv');
    my $child = gen_meta('My::Child');
    $child->extend_with('My::Class');
    ok !$child->is_attr('priv');
  }

OVERRIDEN: {
    my $parent = gen_meta('My::Class');
    $parent->reg_attr('pub1', parse());
    my $child = gen_meta('My::Child');
    eval '*My::Child::pub1 = sub {"OVER"}';    ## no critic
    $child->mark_as_overridden('pub1');
    $child->extend_with('My::Class');
    is(My::Child->pub1, 'OVER');
  }

CLASH_SUB: {
    my $parent = gen_meta('My::Class');
    $parent->reg_attr('pub1', parse());
    my $child = gen_meta('My::Child');
    eval '*My::Child::pub1 = sub {"OVER"}';    ## no critic
    like exception { $child->extend_with('My::Class') }, qr/My::Child.+pub1.+$0/;
  }

CLASH_ATTR: {
    my $parent = gen_meta('My::Class');
    $parent->reg_attr('pub1', parse());
    my $child = gen_meta('My::Child');
    $child->reg_attr('pub1', parse());
    like exception { $child->extend_with('My::Class') }, qr/My::Child.+pub1.+$0/;
  }

}


REQUIREMENTS: {
  my $meta  = gen_meta;
  my $child = gen_meta('My::Child');
  eval '*My::Class::bad = sub {"FOO"}';      ## no critic
  eval '*My::Class::meth1 = sub {"FOO"}';    ## no critic
  eval 'package My::Class; sub own {}';      ## no critic
  $meta->reg_attr('attr1', parse());
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
  $meta->reg_attr('attr1', parse());
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
  $meta->reg_attr('myattr', parse());
  eval 'package My::Class; sub mymeth {"FOO"}';    ## no critic
  eval '*My::Class::mysub = sub {"FOO"}';          ## no critic

  $meta->check_implementation('/::Inter');
  is $loaded, 'My::Inter';
}

sub parse_attr { Evo::Class::Meta->parse_attr(@_) }

DUMPING: {

  my $meta = gen_meta();
  $meta->reg_attr('a', parse());
  $meta->reg_requirement('r');
  eval '*My::Class::mymethod = sub {"FOO"}';    ## no critic
  $meta->reg_method('mymethod');
  $meta->mark_as_overridden('over');
  $meta->mark_as_private('priv');

  is_deeply $meta->info,
    {
    public     => {methods => ['mymethod'], attrs => ['a'], reqs => ['r'],},
    overridden => ['over'],
    private    => ['priv'],
    }

}

done_testing;
