package main;
use Evo 'Test::More tests 5; Test::Evo::Helpers exception; -Loop *';

{

  package MyZone;
  use Evo '-Class *';
  with 'Evo::Loop::Role::Zone';

}

my $loop = MyZone::->new();
my ($CB, $MW_CALLED);

$loop->zone_middleware(
  sub($next) {
    sub { $MW_CALLED++; $next->(@_) }
  }
);

$loop->zone(
  sub {
    $loop->zone_level;
    $CB = $loop->zone_cb(
      sub {
        is shift, 11;
        $loop->zone_cb(sub { is $loop->zone_level, 1; is shift, 22; })->(22);
      }
    );

  }
);


local $SIG{__WARN__} = sub { };
$CB->(11);
is $loop->zone_level, 0;
is $MW_CALLED, 1;
