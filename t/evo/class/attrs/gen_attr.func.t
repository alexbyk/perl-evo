use Evo 'Test::More; -Class::Meta; -Class::Attrs';
use Evo '-Internal::Exception';

sub parse { Evo::Class::Meta->parse_attr(@_) }

my ($attrs, $obj, $lcalled, $chcalled);
my $lazy = sub { $lcalled++; 'LAZY' };
my $check = sub { $chcalled++; $_[0] > 0 ? (1) : (0, "Ooops"); };

sub before() {
  $attrs    = Evo::Class::Attrs->new();
  $obj      = {};
  $lcalled  = 0;
  $chcalled = 0;
}

GS: {
  before();
  my $sub = $attrs->gen_attr('name', parse is => 'rw');
  my $val = 'foo';
  is $sub->($obj), undef;
  ok !exists $obj->{name};
  $sub->($obj, $val);
  $val = 'BAD';
  is $sub->($obj), 'foo';
}

RO: {
  before();
  my $sub = $attrs->gen_attr('name', parse is => 'ro');
  is $sub->($obj), undef;
  like exception { $sub->($obj, 22) }, qr/name.+readonly.+$0/;
  is $sub->($obj), undef;
}

GS_LAZY: {
  before();
  my $sub = $attrs->gen_attr('name', parse is => 'rw', lazy => $lazy);

  is $sub->($obj), 'LAZY' for 1 .. 2;
  is $lcalled, 1;
  ok exists $obj->{name};
  $sub->($obj, 'foo');
  is $sub->($obj), 'foo';
  delete $obj->{name};
  is $sub->($obj), 'LAZY';
}

GSCH: {
  before();
  my $sub = $attrs->gen_attr('name', parse check => $check);

  is $sub->($obj), undef;
  $sub->($obj, 22);
  is $chcalled, 1;
  is $sub->($obj), 22;

  like exception { $sub->($obj, -22); }, qr/bad value "-22".+"name".+Ooops.+$0/i;

  # empty check
  like exception {
    $attrs->gen_attr('name', parse check => sub { })->($obj, -22);
  }, qr/bad value "-22".+"name".+$0/i;
}

GSCH_CHANGE: {
  my $subinc = $attrs->gen_attr('nameinc', parse check => sub { $_[0] .= "BAD"; 1 });
  my $val = "VAL";
  $subinc->($obj, $val);
  is $subinc->($obj), "VAL";
  is $val, "VAL";
}

GSCH_LAZY: {
  before();
  my $sub = $attrs->gen_attr('name', parse check => $check, lazy => $lazy);

  is $sub->($obj), 'LAZY';
  is $lcalled, 1;
  $sub->($obj, 22);
  is $chcalled, 1;
  is $sub->($obj), 22;

  like exception { $sub->($obj, -22); }, qr/bad value "-22".+"name".+Ooops.+$0/i;
}

done_testing;
