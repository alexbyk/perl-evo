use Evo;
use Test::More;
use FindBin;
use lib "$FindBin::Bin";
use MyZone;


my @got;

sub w($label) {

  sub ($next) {
    sub { push @got, $label; $next->(); };
  };
}

my $obj = MyZone::new();

sub zone {
  $obj->zone(@_);
}

my ($cb1, $cb2);
zone sub {
  zone w(1), w(2), sub {
    is_deeply \@got, [];

    zone w(3), sub {
      is_deeply \@got, [];
      $cb2 = $obj->zone_cb(sub { });
    };

    $cb1 = $obj->zone_cb(sub { });
  };
};

@got = ();
$cb1->();
is_deeply \@got, [1, 2];

@got = ();
$cb2->();
is_deeply \@got, [1, 2, 3];

done_testing;
