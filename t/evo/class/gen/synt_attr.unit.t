use Evo 'Test::More; Evo::Class::Gen; -Internal::Exception';

BUILD_SHAPE: {
  my $gen   = Evo::Class::Gen->new();
  my $dfn   = sub {'DFN'};
  my $check = sub {1};
  $gen->gen_attr('simple_rw');
  $gen->gen_attr('simple_ro', is => 'ro');
  $gen->gen_attr(req => required => 1);
  $gen->gen_attr(dv  => default  => 'DV');
  $gen->gen_attr(dfn => default  => $dfn);
  $gen->gen_attr(ch  => check    => $check);

  is_deeply $gen->{builder},
    {
    known    => {simple_rw => 1, simple_ro => 1, req => 1, dv => 1, dfn => 1, ch => 1},
    dv       => {dv        => 'DV'},
    dfn      => {dfn       => $dfn},
    check    => {ch        => $check},
    required => ['req'],
    };

}

INDEXES: {
  my $gen = Evo::Class::Gen->new();
  $gen->gen_attr('a0');
  is_deeply $gen->{indexes}, {a0 => 0};

  # can't generate twice
  like exception { $gen->gen_attr('a0', required => 1) }, qr/Attribute "a0".+already/;
  is_deeply $gen->{builder},
    {known => {a0 => 1}, dv => {}, dfn => {}, check => {}, required => []};

  $gen->gen_attr('a1');
  is_deeply $gen->{indexes}, {a0 => 0, a1 => 1};
}


done_testing;
