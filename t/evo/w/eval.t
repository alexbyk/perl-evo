use Evo '-W::Eval *', '-Lib *';
use Test::More;

my $e;
my $catch = sub { $e = shift; };

# validate

# die
$e = '';
ws_combine(w_eval_run($catch))->(sub { die "foo\n" })->();
is $e, "foo\n";

# live
$e = '';
my @res = ws_combine(w_eval_run($catch))->(sub { ok wantarray })->();
ok !$e;

done_testing;
