use Evo '-Lib ws_fn; Test::More; Evo::Internal::Exception';


sub w_add($add) {
  sub($next) {
    sub($val) {
      $next->($val + $add);
    };
  };
}

# 1
is ws_fn(w_add(44), sub($val) { return "ret $val" })->(22), 'ret ' . (22 + 44);

# many
is ws_fn(w_add(1), w_add(2), w_add(3), sub($val) { return "ret $val" })->(22),
  'ret ' . (22 + 1 + 2 + 3);

# only cb
is ws_fn(sub($val) { return "ret $val" })->(22), 'ret ' . 22;


like exception { ws_fn() }, qr/Provide.+$0/;

done_testing;
