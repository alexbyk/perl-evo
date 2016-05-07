package main;
use Evo '-Class::Meta; -Role::Class; Test::More; Test::Fatal; Test::Evo::Helpers *';

my $m1 = sub { };
{

  package My::Role;
  use Evo -Loaded;

  package My::Parent;
  use Evo;
  sub clashing {'CL'}

  package My::Clashing;
  use Evo;
  our @ISA = ('My::Parent');

}
EMPTY: {
  my $meta = comp_meta;
  like exception { $meta->install_roles('My::Class', 'My::Role') }, qr/Empty.+"My::Role".+$0/;
}

CLASHING_ATTR_WITH_ATTR: {
  my $meta = comp_meta;
  $meta->install_attr('My::Class', 'myattr');
  $meta->rex->add_attr('My::Role', 'myattr');
  like exception { $meta->install_roles('My::Class', 'My::Role') }, qr/My::Class.+already.+myattr/;
}

CLASHING_ATTR_WITH_SUB: {
  my $meta = comp_meta;
  $meta->rex->add_attr('My::Role', 'clashing');
  like exception { $meta->install_roles('My::Clashing', 'My::Role') },
    qr/My::Clashing.+already.+clashing/;
}

CLASHING_METH_WITH_SUB: {
  my $meta = comp_meta;
  my $noop = sub { };
  $meta->rex->add_gen('My::Role', 'clashing', sub {$noop});
  like exception { $meta->install_roles('My::Clashing', 'My::Role') },
    qr/My::Clashing.+already.+clashing/;
}

CLASHING_ATTR_WITH_SUB_OVERRIDE: {
  my $meta = comp_meta;
  $meta->rex->add_attr('My::Role', 'clashing');
  $meta->mark_overriden('My::Clashing', 'clashing');
  $meta->install_roles('My::Clashing', 'My::Role');
  is(My::Clashing->clashing, 'CL');
}

CLASHING_METH_WITH_SUB_OVERRIDE: {
  my $meta = comp_meta;
  my $noop = sub { };
  $meta->mark_overriden('My::Clashing', 'clashing');
  $meta->rex->add_gen('My::Role', 'clashing', sub {$noop});
  $meta->install_roles('My::Clashing', 'My::Role');
  is(My::Clashing->clashing, 'CL');
}

done_testing;
