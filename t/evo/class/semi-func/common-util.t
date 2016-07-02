use Evo 'Test::More; -Class::Common::Util; -Internal::Exception';

*compile_attr = *Evo::Class::Common::Util::compile_attr;
*process_is   = *Evo::Class::Common::Util::process_is;

# compile
is_deeply [compile_attr('name')], [qw(gen_gs name)];
is_deeply [compile_attr('name', check => 'CH')], [qw(gen_gsch name CH)];

my ($lazy, $check) = (sub {'l'}, sub {'ch'});
is_deeply [compile_attr('name', lazy => $lazy)], [qw(gen_gs_code name), $lazy];

is_deeply [compile_attr('name', lazy => $lazy, check => $check)],
  [qw(gen_gsch_code name), $check, $lazy];

# process is

my $res;
$res = {process_is('name', check => 'old', is => 'ro')};
like exception { $res->{check}->(); }, qr/name.+readonly/;

$res = {process_is('name', is => 'ro')};
like exception { $res->{check}->(); }, qr/name.+readonly/;

$res = {process_is('name', check => 'old')};
is $res->{check}, 'old';

done_testing;
