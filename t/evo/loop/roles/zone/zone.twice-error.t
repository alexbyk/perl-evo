package main;
use Evo 'Test::More; Test::Fatal; -Loop *';

{

  package MyZone;
  use Evo '-Class *';
  with 'Evo::Loop::Role::Zone';

}

my $loop = MyZone::->new();
my ($CB, $MW_CALLED);

$loop->zone_middleware(
  sub($next) {
    sub { $MW_CALLED++; $next->() }
  }
);

$loop->zone(
  sub {
    $loop->zone_level;
    $CB = $loop->zone_cb(
      sub {
        $loop->zone_cb(sub { is $loop->zone_level, 1 })->();
      }
    );

  }
);


local $SIG{__WARN__} = sub { };
$CB->();
is $loop->zone_level, 0;
is $MW_CALLED, 1;

done_testing;
