use Evo -Export::Class;
use Test::More;
use Test::Evo::Helpers "exception";

sub gen_gen {
  my $v = shift;
  sub {
    sub {$v}
  };
}

PATCH: {
  my $obj = Evo::Export::Class->new();

  $obj->add_gen('Lib', 'name1', gen_gen(1));
  $obj->add_gen('Lib', 'name2', gen_gen(2));

  $obj->install('Lib', 'My::Dst', 'name1');
  is My::Dst::name1(), 1;
  ok !My::Dst->can('name2');

  $obj->install('Lib', 'My::Dst', 'name1', '*');
  is My::Dst::name1(), 1;
  is My::Dst::name2(), 2;

  $obj->install('Lib', 'My::Dst', 'name1:alias1');
  is My::Dst::alias1(), 1;
  is \&My::Dst::name1, \&My::Dst::alias1;
}

done_testing;
