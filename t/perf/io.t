package main;
use Evo '-Io *; -Loop *; Socket :all';
use Test::Evo::Benchmark;
use Test::More;

plan skip_all => 'set TEST_EVO_PERF env to enable this test' unless $ENV{TEST_EVO_PERF};

my $EXPECT = 730 * $ENV{TEST_EVO_PERF};

my $N = 1000;

my @cons = map { io_socket() } 0 .. 1000;
my $comp = Evo::Loop::Comp::new();
$comp->io_in($_, sub { }) for @cons;
$comp->io_out($_, sub { }) for @cons;

my $fn = sub {
  $comp->io_process;
};


faster_ok(fn => $fn, iters => $N, expect => $EXPECT, diag => 1);

done_testing;
