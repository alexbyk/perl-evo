package main;
use Evo;
use Test::Evo::Benchmark;
use Test::More;

plan skip_all => 'set TEST_EVO_PERF env to enable this test' unless $ENV{TEST_EVO_PERF};

my $EXPECT = 500_000 * $ENV{TEST_EVO_PERF};

my $N = 500_000;

my $k = 0;

{

  package My::Obj;
  use Evo '-Realm *';
}

my $obj = bless {}, 'My::Obj';
my $fn = sub {
  $k++;
  $obj->realm_run(
    sub {
      die unless My::Obj::realm('foo') == $obj;
    }
  );
};


faster_ok(fn => $fn, iters => $N, expect => $EXPECT, diag => 1);

is $k, $N, "$k = $N";

done_testing;
