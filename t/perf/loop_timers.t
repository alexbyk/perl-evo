use Evo '-Loop *';
use Test::Evo::Benchmark;
use Test::More;

plan skip_all => 'set TEST_EVO_PERF env to enable this test' unless $ENV{TEST_EVO_PERF};

my $EXPECT = 1700 * $ENV{TEST_EVO_PERF};
my $N      = 5_000;

my $L = 100;

my $k;

my $fn = sub {
  loop_timer(0 => sub { $k++ }) for 1 .. $L;
  loop_start;
};


faster_ok(fn => $fn, iters => $N, expect => $EXPECT, diag => 1);
is $k , $N * $L, "$k = $N * $L";


done_testing;
