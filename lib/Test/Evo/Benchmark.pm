package Test::Evo::Benchmark;
use Evo;
use parent 'Exporter';
use Test::More;
use Carp 'croak';

use Benchmark 'timeit';

our @EXPORT = qw(faster_ok);

sub faster_ok {
  my %args = @_;

  $args{$_} or croak "define $_ option" for qw(iters fn expect);
  my ($iters, $fn, $expect, $diag) = @args{qw(iters fn expect diag)};


  my $t = timeit($iters, $fn);
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  if ($t->cpu_a) {
    my $perf = $iters / $t->cpu_a;
    do { diag timestr $t; diag $perf } if $diag;
    ok $perf > $expect, "$perf > $expect";
  }
  else {
    fail "too few itreations $iters";
  }

  $t;
}

1;
