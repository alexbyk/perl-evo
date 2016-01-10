package main;
use Evo '-Eval *; -Lib *; -Want *';
use Test::More;
use Test::Fatal;


my ($e, $reg, $res);
sub reg($) { push @$reg, shift; }
sub reset_test() { ($e, $res, @$reg) = () }

# try + catch =============
# live
reset_test;
$res = eval_try sub { reg 1; 44 }, sub { reg 2 };
ok !$@;
is_deeply $reg, [1];
is $res, 44;

# die
reset_test;
$res = eval_try sub { reg 1; die "Try\n" }, sub { $e = shift; reg 2; 44 };
ok !$@;
is_deeply $reg, [1, 2];
is $e,   "Try\n";
is $res, 44;

# die twice
reset_test;
like exception {
  eval_try sub { reg 1; die "Try\n" }, sub { reg 2; die "Catch" }
},
  qr/Catch/;
is_deeply $reg, [1, 2];


# try + catch + fin =============
# live
reset_test;
$res = eval_try sub { reg 1; 44 }, sub { reg 2 }, sub { reg 3; };
ok !$@;
is_deeply $reg, [1, 3];
is $res, 44;

# die
reset_test;
$res = eval_try sub { reg 1; die "Try\n" }, sub { $e = shift; reg 2; 44 }, sub { reg 3 };
ok !$@;
is_deeply $reg, [1, 2, 3];
is $e,   "Try\n";
is $res, 44;

# die in catch
reset_test;
like exception {
  eval_try sub { reg 1; die "Try\n" }, sub { reg 2; die "Catch" }, sub { reg 3 }
}, qr/Catch/;
is_deeply $reg, [1, 2, 3];

# die in fin
reset_test;
like exception {
  eval_try sub { reg 1; die "Try\n" }, sub { reg 2; }, sub { reg 3; die "Fin" }
}, qr/Fin/;
is_deeply $reg, [1, 2, 3];

# die in catch and fin
reset_test;
like exception {
  eval_try sub { reg 1; die "Try\n" }, sub { reg 2; die "Catch\n" }, sub { reg 3; die "Fin" }
}, qr/Fin/;
is_deeply $reg, [1, 2, 3];

# try + fin =============
# live
reset_test;
$res = eval_try sub { reg 1; 44 }, undef, sub { reg 3; };
ok !$@;
is_deeply $reg, [1, 3];
is $res, 44;

# die in catch and fin
reset_test;
like exception {
  eval_try sub { reg 1; die "Try\n" }, undef, sub { reg 3; }
}, qr/Try/;
is_deeply $reg, [1, 3];

# die in try and fin
reset_test;
like exception {
  eval_try sub { reg 1; die "Try\n" }, undef, sub { reg 3; die "Fin" }
}, qr/Fin/;
is_deeply $reg, [1, 3];


WANT: {
  my ($wanted, @list);
  @list = eval_try sub { $wanted = wantarray; return (1, 2) }, sub { };
  ok want_is_list $wanted;
  is_deeply \@list, [1, 2];

  @list = eval_try sub { die "Foo" }, sub { $wanted = wantarray; return (1, 2) };
  ok want_is_list $wanted;
  is_deeply \@list, [1, 2];
}

done_testing;
