package main;
use Evo 'Test::More; -Internal::Exception; -Class::Gen::In; -Class::Gen::Out; -Class::Meta';
use Symbol 'delete_package';

{

  package My::Class;
}

my $FILE = __FILE__;

my $positive = sub($v) { $v >= 0 ? 1 : (0, 'OOPS') };

sub test ($gen, $build) {
  delete_package 'My::Class::Parent';
  my $meta = Evo::Class::Meta->register('My::Class::Parent');


  #  # required
  $gen->sync_attrs(req => {required => 1});
  like exception { $build->() }, qr#"req" is required.+$0#;

  # unknown
  $gen->sync_attrs();
  like exception { $build->(bad => 1) }, qr#Unknown.+"bad".+$0#;

  # check if passed but bypass checking of default value, even if it's negative
  $gen->sync_attrs(foo => {default => -222, check => $positive});
  like exception { $build->(foo => -11) }, qr#Bad value.+"-11".+"foo".+OOPS.+$0#i;
  is $gen->gen_attr('foo')->($build->()), -222;

  # default val
  $gen->sync_attrs(foo => {default => 222});
  is $gen->gen_attr('foo')->($build->()), '222';
  is $gen->gen_attr('foo')->($build->(foo => 'mine')), 'mine';

  # default code
  my $sub = sub {222};
  $gen->sync_attrs(foo => {default => $sub});
  is $gen->gen_attr('foo')->($build->()), '222';
  is $gen->gen_attr('foo')->($build->(foo => 'mine')), 'mine';

  # ro
  $gen->sync_attrs(foo => {is => 'ro'});
  is $gen->gen_attr('foo', is => 'ro')->($build->(foo => 'mine')), 'mine';
  like exception { $gen->gen_attr('foo', is => 'ro')->($build->(foo => 'mine'), 'val'), },
    qr/foo.+readonly.+$0/;

}

OUT: {
  my $gen = Evo::Class::Gen::Out->register('My::Class::Out');
  my $build = sub(%opts) { $gen->gen_init()->('My::Class::Out', [], %opts) };
  is ref($build->()), 'My::Class::Out';
  test($gen, $build);

  # exceptions
  like exception { $gen->gen_init()->('My::Class::Out', 'FOO') }, qr/ref/;
}

IN: {
  my $gen = Evo::Class::Gen::In->register('My::Class::In');
  my $build = sub(%opts) { $gen->gen_new()->('My::Class::In', %opts) };
  is ref($build->()), 'My::Class::In';
  test($gen, $build);
}

done_testing;
