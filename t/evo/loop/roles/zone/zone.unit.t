package main;
use Evo 'Test::More tests 6; Test::Fatal; FindBin';
use lib "$FindBin::Bin";


{

  package MyZone;
  use Evo '-Class *';
  with 'Evo::Loop::Role::Zone';

}

ZONE_CB: {
  my $comp = MyZone::new();

  my $mw = sub($next) {$next};
  push $comp->zone_middleware->@*, $mw;
  my ($zcb1, $zcb2);
  $zcb1 = $comp->zone_cb(
    sub {
      is_deeply $comp->zone_middleware, [$mw];
      $zcb2 = $comp->zone_cb(sub { is_deeply $comp->zone_middleware, [$mw]; });
    }
  );

  $comp->zone_middleware->@* = ('bad');
  $zcb1->();
  is_deeply $comp->zone_middleware, ['bad'];
  $zcb2->();
}

ZONE_FORK: {
  my ($m0, $m1, $m2);
  my $comp = MyZone::new();
  $m0 = $comp->zone_middleware;
  $comp->zone(
    sub {
      $m1 = $comp->zone_middleware;
      push $comp->zone_middleware->@*, '1';
      $comp->zone(sub { $m2 = $comp->zone_middleware; push $comp->zone_middleware->@*, '2'; });
    }
  );

  is_deeply $m0, [];
  is_deeply $m1, [1];
  is_deeply $m2, [1, 2];
}

done_testing;
