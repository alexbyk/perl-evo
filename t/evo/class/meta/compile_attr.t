use Evo;
use Evo::Class::Meta;
use Test::More;


sub mock {
  my $label = shift;
  sub { $label . ' ' . join ',', @_ };
}

my $gen = {
  gs         => mock('gs'),
  gsch       => mock('gsch'),
  gs_value   => mock('gs_value'),
  gsch_value => mock('gsch_value'),
  gs_code    => mock('gs_code'),
  gsch_code  => mock('gsch_code'),
};
my $meta = Evo::Class::Meta::new(gen => $gen);

# no lazy value
GS: {
  my $attr = $meta->compile_attr('name');
  is $attr, 'gs name';
}
GSCH: {
  my $attr = $meta->compile_attr('name', check => 'CH');
  like $attr, qr/gsch name/;
}


GS_VALUE: {
  my $attr = $meta->compile_attr('name', lazy => 0);
  is $attr, 'gs_value name,0';
}

GSCH_VALUE: {
  my $attr = $meta->compile_attr('name', lazy => 'V', check => 'CH');
  like $attr, qr/gsch_value name,CH.+V/;
}

my $noop = sub { };
GS_CODE: {
  my $attr = $meta->compile_attr('name', lazy => $noop);
  is $attr, "gs_code name,$noop";
}

GSCH_CODE: {
  my $attr = $meta->compile_attr('name', lazy => $noop, check => 'CH');
  like $attr, qr/gsch_code name,CH.+CODE/;
}


done_testing;
