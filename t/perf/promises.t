package main;
use Evo '-Promise *; -Loop *';
use Test::Evo::Benchmark;
use Test::More;

plan skip_all => 'set TEST_EVO_PERF env to enable this test' unless $ENV{TEST_EVO_PERF};

my $EXPECT = 2600 * $ENV{TEST_EVO_PERF};

my $N = 5_000;

my $k = 0;

my $fn = sub {
  my $p = promise(sub($res, $rej) { $res->(undef) });
  $p = $p->then(sub { $k++ }) for 1 .. 10;
  $p = $p->then(sub { $k-- }) for 1 .. 9;
  loop_start;
};


faster_ok(fn => $fn, iters => $N, expect => $EXPECT, diag => 1);
is $k, $N, "$k = $N";

done_testing;
