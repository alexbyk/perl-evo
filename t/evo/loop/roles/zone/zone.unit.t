use Evo;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin";
use MyZone;

my $w = sub {shift};


CB_WITHOUT_W: {
  my $obj = MyZone::new();
  my $zcb = $obj->zone_cb(
    sub {
      ok !$obj->zone_data->{w};
      $_[0];
    }
  );
  $obj->zone_data->{w} = sub { fail "prev w should be restored" };
  is $zcb->(33), 33;
}

CB_WITH_W: {
  my $obj = MyZone::new();
  my $w = sub {shift};
  $obj->zone_data->{w} = sub {shift};
  my $zcb = $obj->zone_cb(
    sub {
      ok $obj->zone_data->{w};
    }
  );
  $obj->zone_data->{w} = sub { fail "prev w should be restored" };
  $zcb->();
}

ZONE_WITHOUT_WS: {
  my $obj = MyZone::new();
  ok !$obj->zone_data->{w};
  $obj->zone(sub { ok !$obj->zone_data->{w}; });
}

ZONE_LOCALIZATION: {
  my $obj = MyZone::new();
  $obj->zone($w, sub { $obj->zone_data->{w} = 'bad'; });
  ok !$obj->zone_data->{w};
}


done_testing;
