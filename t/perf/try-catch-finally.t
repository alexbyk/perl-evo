use Evo;
use Test::Evo::Benchmark;
use Test::More;

plan skip_all => 'set TEST_EVO_PERF env to enable this test' unless $ENV{TEST_EVO_PERF};

my $EXPECT = 450_000 * $ENV{TEST_EVO_PERF};
my $N      = 500_000;

my $k = 0;
my $s = 0;
sub inc_s { $s += shift }
sub inc_k { $k += shift }


use Evo '-Eval *';    # ~ 520 000

my $fn = sub {
  eval_try sub { inc_s(1) }, sub {...}, sub { inc_k(1) };
};

#use Try::Tiny; # ~ 110 000
#my $fn = sub {
#  try { inc_s(1) } catch {...} finally { inc_k(1) };
#};

faster_ok(fn => $fn, iters => $N, expect => $EXPECT, diag => 1);
is $k, $N;
is $s, $N;


done_testing;
