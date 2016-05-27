use Evo '-Lib *';
use Test::Evo::Benchmark;
use Test::More;

plan skip_all => 'set TEST_EVO_PERF env to enable this test' unless $ENV{TEST_EVO_PERF};

my $EXPECT = 900_000 * $ENV{TEST_EVO_PERF};
my $N      = 1_000_000;

my $N_WRAPPERS = 10;

my $k = 0;

sub w_add {
  my $add = $_[0];
  sub {
    my $next = $_[0];
    sub {
      $k += $add;
      $next->(@_);
    };
  };
}


my @wrappers = map { w_add(1) } 1 .. $N_WRAPPERS;
my $fn_wrapped = ws_fn(@wrappers, sub { });

$k = 0;

faster_ok(fn => $fn_wrapped, iters => $N, expect => $EXPECT, diag => 1);
is $k, $N * $N_WRAPPERS, "$k = $N";


done_testing;
