package main;
use Evo 'Try::Tiny; -Lib try:evo_try; Benchmark cmpthese';

sub add2($val) { $val + 2 }

cmpthese - 1, {
  'Try::Tiny' => sub {
    try {1} catch { } finally {2};
  },
  'Evo::Lib::try' => sub {
    evo_try {1} sub { }, sub {2}
  }
};
