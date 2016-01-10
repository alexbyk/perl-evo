package main;
use Evo;
use Test::Evo::Benchmark;
use Test::More;

plan skip_all => 'set TEST_EVO_PERF env to enable this test' unless $ENV{TEST_EVO_PERF};

my $EXPECT = 100_000 * $ENV{TEST_EVO_PERF};

my $N = 100_000;

my $k = 0;

{

  package My::Obj;
  use Evo '-Comp::Out *';
  has 'simple';
  has 'default', is => 'rw', default => 'foo';
  has 'lazy', is => 'rw', lazy => sub { $k++; 'bar' };
}

my $fn = sub {
  my $obj = My::Obj::init(sub {$k}, simple => 'hello');
  my $res = join ' ', $obj->simple, $obj->default, $obj->lazy;
  die unless $res eq 'hello foo bar';
};


faster_ok(fn => $fn, iters => $N, expect => $EXPECT, diag => 1);
is $k, $N, "$k = $N";

done_testing;
