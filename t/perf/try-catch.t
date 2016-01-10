use Evo;
use Test::Evo::Benchmark;
use Test::More;

plan skip_all => 'set TEST_EVO_PERF env to enable this test' unless $ENV{TEST_EVO_PERF};

my $EXPECT = 500_000 * $ENV{TEST_EVO_PERF};
my $N      = 1_000_000;

my $k = 0;
sub inc_k { $k += shift }

use Evo '-Eval *';    # ~ 610 000
my $fn = sub {
  eval_try sub { inc_k(1) }, sub {...};
};


#use TryCatch; # ~1 900 000
#use Try::Tiny; # ~ 200 000
#my $fn = sub {
#  try { inc_k(1) } catch {...};
#};

faster_ok(fn => $fn, iters => $N, expect => $EXPECT, diag => 1);
is $k, $N;

done_testing;
