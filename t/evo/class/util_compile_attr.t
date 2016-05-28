use Evo '-Class::Meta; Test::More';
use Evo::Class::Util 'compile_attr';

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
my $meta = Evo::Class::Meta->new(gen => $gen, class => 'My::Dummy');

# gs
is compile_attr($gen, 'name'), 'gs name';

# gsch
like compile_attr($gen, 'name', check => 'CH'), qr/gsch name/;


# gs_vslue
is compile_attr($gen, 'name', lazy => 0), 'gs_value name,0';

# gsch_value
like compile_attr($gen, 'name', lazy => 'V', check => 'CH'), qr/gsch_value name,CH.+V/;

my $noop = sub { };

# gs_code
is compile_attr($gen, 'name', lazy => $noop), "gs_code name,$noop";

# gsch_code
like compile_attr($gen, 'name', lazy => $noop, check => 'CH'), qr/gsch_code name,CH.+CODE/;

done_testing;
