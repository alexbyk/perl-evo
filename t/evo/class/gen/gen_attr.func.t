use Evo 'Test::More; -Class::Gen';
use Evo '-Internal::Exception';
use Symbol 'delete_package';

sub parse { Evo::Class::Meta->parse_attr(@_) }

sub test_gen ($gclass) {

  my ($gen, $obj, $exists, $delete, $map, $lcalled, $chcalled);
  my $lazy = sub($o) { is $o, $obj; $lcalled++; 'LAZY'; };
  my $check = sub { $chcalled++; $_[0] > 0 ? (1) : (0, "Ooops") };

  # inc passed var, to be sure we don't do extra copies
  my $check_inc = sub { $_[0]++ };

  my sub before() {
    $gen      = $gclass->new;
    $obj      = $gen->gen_new->('My::Class');
    $exists   = $gen->gen_attr_exists;
    $delete   = $gen->gen_attr_delete;
    $map      = $gen->gen_attrs_map;
    $lcalled  = 0;
    $chcalled = 0;
  }

EXISTS_DELETE: {
    before();

    like exception { $exists->($obj, 'name'); }, qr/Unknown.+name.+$0/;
    like exception { $delete->($obj, 'name'); }, qr/Unknown.+name.+$0/;


    $gen->gen_attr('name', parse());

    $obj = $gen->gen_new->('My::Class');
    ok !$exists->($obj, 'name');

    $obj = $gen->gen_new->('My::Class', name => 22);
    ok $exists->($obj, 'name');
    ok $delete->($obj, 'name');
    ok !$exists->($obj, 'name');
  }

RO: {
    before();
    my $sub = $gen->gen_attr('name', parse is => 'ro');
    is $sub->($obj), undef;
    like exception { $sub->($obj, 22) }, qr/name.+readonly.+$0/;
    is $sub->($obj), undef;
  }


GS: {
    before();
    my $sub = $gen->gen_attr('name', parse is => 'rw');
    my $val = 'foo';

    is $sub->($obj), undef;
    ok !$exists->($obj, 'name');
    $sub->($obj, $val);
    $val = 'BAD';
    is $sub->($obj), 'foo';

  }

GS_LAZY: {
    before();
    my $sub = $gen->gen_attr('name', parse is => 'rw', lazy => $lazy);

    is $sub->($obj), 'LAZY' for 1 .. 2;
    is $lcalled, 1;
    ok $exists->($obj, 'name');
    $sub->($obj, 'foo');
    is $sub->($obj), 'foo';
    $delete->($obj, 'name');
    is $sub->($obj), 'LAZY';
  }

GSCH: {
    before();
    my $sub = $gen->gen_attr('name', parse check => $check);

    is $sub->($obj), undef;
    $sub->($obj, 22);
    is $chcalled, 1;
    is $sub->($obj), 22;

    like exception { $sub->($obj, -22); }, qr/bad value "-22".+"name".+Ooops.+$0/i;

    # should pass arg as is
    my $subinc = $gen->gen_attr('nameinc', parse check => sub { $_[0]++ });
    my $val = 1;
    $subinc->($obj, $val);
    is $val, 2;
  }

GSCH_LAZY: {
    before();
    my $sub = $gen->gen_attr('name', parse check => $check, lazy => $lazy);

    is $sub->($obj), 'LAZY';
    is $lcalled, 1;
    $sub->($obj, 22);
    is $chcalled, 1;
    is $sub->($obj), 22;

    like exception { $sub->($obj, -22); }, qr/bad value "-22".+"name".+Ooops.+$0/i;
  }


GEN_MAP: {
    before();

    my $map = $gen->gen_attrs_map;
    is_deeply [$map->($obj)], [];

    my $foo = $gen->gen_attr('foo', parse());
    my $bar = $gen->gen_attr('bar', parse());

    is_deeply [$map->($obj)], [foo => undef, bar => undef];
    $foo->($obj, 'FOO');
    is_deeply [$map->($obj)], [foo => 'FOO', bar => undef];
  }

}

test_gen('Evo::Class::Gen');

done_testing;
