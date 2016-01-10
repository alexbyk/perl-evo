package main;
use Evo;
use Test::More;
use Test::Fatal;
use Evo::Comp::Role::Exporter;

{

  package My::Role;
  use Evo;
  sub foo {'FOO'}
  sub bar {'BAR'}


}

ERRORS: {
  my $obj = Evo::Comp::Role::Exporter::new();

  # methods
  like exception { $obj->add_methods('My::Role', 'not_existing'); }, qr/method.+not_existing.+$0/i;

  # first time is ok, but second should fail
  like exception { $obj->add_methods('My::Role', qw(foo bar)) for 1 .. 2; },
    qr/My::Role.+already.+foo.+$0/;

  # attrs
  like exception { $obj->add_attr('My::Role', '4bad'); }, qr/4bad.+$0/i;
  like exception { $obj->add_attr('My::Role', 'attr1', is => 'rw') for 1 .. 2 },
    qr/My::Role.+already.+attr1.+$0/;

  like exception { $obj->request_gen('My::Role', 'not_existing', 'MyComp') }, qr/My::Role.+not_existing.+$0/;
}

GEN: {
  my $obj = Evo::Comp::Role::Exporter::new();
  $obj->add_gen(
    'My::Role',
    gm => sub {
      my $class = shift;
      sub {$class};
    }
  );
  my $m = $obj->request_gen('My::Role', 'gm', 'My::Comp');
  is $obj->request_gen('My::Role', 'gm', 'My::Comp'), $m;
  isnt $obj->request_gen('My::Role', 'gm', 'My::Comp2'), $m;
  is $m->(), 'My::Comp';
}


OK: {
  my $obj = Evo::Comp::Role::Exporter::new();
  $obj->add_attr('My::Role', 'attr1', is => 'rw');
  $obj->add_attr('My::Role', 'attr2', is => 'ro');
  $obj->add_methods('My::Role', qw(foo bar));
  my $meth;
  $obj->add_gen(
    'My::Role',
    'gen1',
    sub {
      my $class = shift;
      $meth = sub {$class}
    }
  );

  # get attr and methods
  my %methods = $obj->methods('My::Role', 'My::Comp');
  is_deeply \%methods, {foo => *My::Role::foo{CODE}, bar => *My::Role::bar{CODE}, gen1 => $meth};

  is $methods{gen1}->(), 'My::Comp';

  is_deeply { $obj->attrs('My::Role') }, {attr1 => [is => 'rw'], attr2 => [is => 'ro']};


  # hooks

  ok !$obj->hooks('My::Role');
  $obj->hooks('My::Role', 'h1', 'h2');
  is_deeply [$obj->hooks('My::Role')], ['h1', 'h2'];
}

done_testing;
