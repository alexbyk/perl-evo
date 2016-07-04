use Evo 'Test::More; -Class::Gen';
use Evo '-Internal::Exception';
use Symbol 'delete_package';

sub test_gen ($gclass, $bargs) {

  my ($gen, $obj, $exists, $delete, $lcalled, $chcalled);
  my $lazy = sub($o) { is $o, $obj; $lcalled++; 'LAZY'; };
  my $check = sub { $chcalled++; $_[0] > 0 ? (1) : (0, "Ooops") };
  my sub before() {
    $gen      = $gclass->new;
    $obj      = $gen->gen_init->($bargs->());
    $exists   = $gen->gen_attr_exists;
    $delete   = $gen->gen_attr_delete;
    $lcalled  = 0;
    $chcalled = 0;
  }

EXISTS_DELETE: {
    before();

    like exception { $exists->($obj, 'name'); }, qr/name.+registered.+$0/;
    like exception { $delete->($obj, 'name'); }, qr/name.+registered.+$0/;
    my $gs = $gen->gen_attr('name');


    ok !$exists->($obj, 'name');

    # set 'name'
    $gs->($obj, 'val');
    ok $exists->($obj, 'name');

    # clear it
    ok $delete->($obj, 'name');
    ok !$exists->($obj, 'name');
  }

RO: {
    before();
    my $sub = $gen->gen_attr('name', ro => 1);
    is $sub->($obj), undef;
    like exception { $sub->($obj, 22) }, qr/name.+readonly.+$0/;
    is $sub->($obj), undef;
  }


GS: {
    before();
    my $sub = $gen->gen_attr('name', is => 'rw');

    is $sub->($obj), undef;
    ok !$exists->($obj, 'name');
    $sub->($obj, 'foo');
    is $sub->($obj), 'foo';
  }

GS_LAZY: {
    before();
    my $sub = $gen->gen_attr('name', is => 'rw', lazy => $lazy);

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
    my $sub = $gen->gen_attr('name', check => $check);

    is $sub->($obj), undef;
    $sub->($obj, 22);
    is $chcalled, 1;
    is $sub->($obj), 22;

    like exception { $sub->($obj, -22); }, qr/bad value "-22".+"name".+Ooops.+$0/i;
  }

GSCH_LAZY: {
    before();
    my $sub = $gen->gen_attr('name', check => $check, lazy => $lazy);

    is $sub->($obj), 'LAZY';
    is $lcalled, 1;
    $sub->($obj, 22);
    is $chcalled, 1;
    is $sub->($obj), 22;

    like exception { $sub->($obj, -22); }, qr/bad value "-22".+"name".+Ooops.+$0/i;
  }
}


test_gen('Evo::Class::Gen', sub { 'My::Class', {} });

done_testing;
