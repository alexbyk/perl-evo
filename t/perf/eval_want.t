use Evo '-Eval *', '-Want *';
use Test::Evo::Benchmark;
use Test::More;

plan skip_all => 'set TEST_EVO_PERF env to enable this test' unless $ENV{TEST_EVO_PERF};

my $EXPECT = 500_000 * $ENV{TEST_EVO_PERF};
my $N      = 500_000;

my $k;
my $inc = sub { ++$k };

my $fn = sub {
  my $call = eval_want WANT_SCALAR, $inc;
  die unless $call->result == $k;
};


faster_ok(fn => $fn, iters => $N, expect => $EXPECT, diag => 1);
is $k, $N, "$k = $N";


done_testing;
