use Evo '-Lib ws_combine';
use Test::More;


sub w_add($add) {
  sub($next) {
    sub($val) {
      $next->($val + $add);
    };
  };
}

# combine
my $w = ws_combine(w_add(1), w_add(2), ws_combine(w_add(3)));
is $w->(sub($val) { return "ret $val" })->(22), 'ret ' . (22 + 1 + 2 + 3);
is $w->(sub($val) { return "! $val" })->(10),   '! ' .   (10 + 1 + 2 + 3);

# special cases
my $wsingle = w_add(10);
is ws_combine($wsingle), $wsingle;

ok !ws_combine();

done_testing;
