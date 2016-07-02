use Evo 'Test::More; -Class::Gen::Out; -Class::Gen::In';
use Evo '-Internal::Exception';
use Symbol 'delete_package';

sub test_gen ($gen, $build) {

EXISTS_DELETE: {

    my $obj = $build->();
    ok !$gen->gen_attr_exists->($obj, 'name');

    # set 'name'
    $gen->gen_gs('name')->($obj, 'val');
    ok $gen->gen_attr_exists->($obj, 'name');

    # clear it
    ok $gen->gen_attr_delete->($obj, 'name');
    ok !$gen->gen_attr_exists->($obj, 'name');
  }

RO: {
    my $obj = $build->();
    my $sub = $gen->gen_attr('name', is => 'ro');

    is $sub->($obj), undef;
    like exception { $sub->($obj, 22) }, qr/name.+readonly.+$0/;
    is $sub->($obj), undef;
  }


GS: {
    my $obj = $build->();
    my $sub = $gen->gen_attr('name', is => 'rw');

    is $sub->($obj), undef;
    $sub->($obj, 'foo');
    is $sub->($obj), 'foo';
    is_deeply { $gen->obj_to_hash($obj) }, {name => 'foo'};
  }


GS_CODE: {
    my $obj = $build->();
    my $sub = $gen->gen_attr('name', is => 'rw', lazy => sub($o) { is $o, $obj; 'LAZY'; });

    is $sub->($obj), 'LAZY';
    is_deeply { $gen->obj_to_hash($obj) }, {name => 'LAZY'};
    $sub->($obj, 'foo');
    is_deeply { $gen->obj_to_hash($obj) }, {name => 'foo'};
  }


  my $check = sub { $_[0] > 0 ? (1) : (0, "Ooops") };
GSCH: {
    my $obj = $build->();
    my $sub = $gen->gen_attr('name', is => 'rw', check => $check);

    is $sub->($obj), undef;
    $sub->($obj, 22);
    is $sub->($obj), 22;
    is_deeply { $gen->obj_to_hash($obj) }, {name => 22};

    like exception { $sub->($obj, -22); }, qr/bad value "-22".+"name".+Ooops.+$0/i;
  }

GSCH_CODE: {
    my $obj = $build->();
    my $sub = $gen->gen_attr(
      'name',
      is    => 'rw',
      check => $check,
      lazy  => sub($o) { is $o, $obj; 'LAZY'; }
    );

    is $sub->($obj), 'LAZY';
    $sub->($obj, 22);
    is $sub->($obj), 22;
    is_deeply { $gen->obj_to_hash($obj) }, {name => 22};

    like exception { $sub->($obj, -22); }, qr/bad value "-22".+"name".+Ooops.+$0/i;
  }
}


OUT: {
  my $gen = Evo::Class::Gen::Out->register('My::Class::Out');
  my $build = sub { $gen->gen_init()->('My::Class::Out', []) };
  test_gen($gen, $build);
}

IN: {
  my $gen = Evo::Class::Gen::In->register('My::Class::In');
  my $build = sub { $gen->gen_new()->('My::Class::In') };
  test_gen($gen, $build);
}

done_testing;
