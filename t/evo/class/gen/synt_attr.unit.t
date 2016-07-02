use Evo 'Test::More; Evo::Class::Gen::Out';

my $gen   = Evo::Class::Gen::Out->register('My::Class');
my $dfn   = sub {'DFN'};
my $check = sub {1};
$gen->sync_attrs(
  req    => {required => 1},
  dv     => {default  => 'DV'},
  dfn    => {default  => $dfn},
  ch     => {check    => $check},
  simple => {},
);

is_deeply [sort keys $gen->{_known}->%*], [sort qw(req dv dfn simple ch)];
is_deeply [$gen->{_required}->@*], [qw(req)];
is_deeply $gen->{_dv},    {dv  => 'DV'};
is_deeply $gen->{_dfn},   {dfn => $dfn};
is_deeply $gen->{_check}, {ch  => $check};

$gen->sync_attrs();
is_deeply $gen->{_known}, {};
is_deeply $gen->{_required}, [];
is_deeply $gen->{_dv},    {};
is_deeply $gen->{_dfn},   {};
is_deeply $gen->{_check}, {};

done_testing;
