package main;
use Evo 'Test::More; -Internal::Exception;-Class::Meta; -Class::Gen';

{

  package My::Class;
}

my $FILE = __FILE__;

my $positive = sub($v) { $v > 0 ? 1 : (0, 'OOPS') };

sub test_gen ($gclass) {

  my ($gen, $build, $meta);
  my sub before() {
    undef $My::Class::Parent::EVO_CLASS_META;
    $meta = Evo::Class::Meta->register('My::Class::Parent', $gclass);
    $gen = $meta->gen;
    ok $My::Class::Parent::EVO_CLASS_META;
    $build = sub { $gen->gen_init()->('My::Class', {}, @_) };
  }

REQUIRED: {
    before();
    $gen->gen_attr(req => required => 1);
    like exception { $build->() }, qr#"req" is required.+$0#;
  }

UNKNOWN: {
    before();
    like exception { $build->(bad => 1) }, qr#Unknown.+"bad".+$0#;
  }

CHECK: {
    # check if passed but bypass checking of default value, even if it's negative
    before();
    my $sub = $gen->gen_attr(foo => default => 0, check => $positive);
    like exception { $build->(foo => 0) }, qr#Bad value.+"0".+"foo".+OOPS.+$0#i;
    is $sub->($build->()), 0;
  }

DEFAULT_VALUE: {
    before();
    my $sub = $gen->gen_attr(foo => default => 222);
    is $sub->($build->()), '222';
    is $sub->($build->(foo => 'mine')), 'mine';
  }

DEFAULT_CODE: {
    before();
    my $sub = sub {222};
    my $sub = $gen->gen_attr(foo => default => $sub);
    is $sub->($build->()), '222';
    is $sub->($build->(foo => 'mine')), 'mine';
  }

}

test_gen('Evo::Class::Gen');

done_testing;
