use Evo '-Promises *; -Loop *';
use Test::More;


my ($v, $r);

# promise
promise(
  sub($resolve, $reject) {
    $resolve->('hello');
  }
)->then(sub { $v = shift; die "Foo\n" })->catch(sub { $r = shift });

ok !$v;
ok !$r;

loop_start();

is $v, 'hello';
is $r, "Foo\n";

# deferred
($v, $r) = @_;
my $d = deferred;
$d->promise->then(sub { $v = shift; die "Foo\n" })->catch(sub { $r = shift });
$d->resolve('hello');

ok !$v;
ok !$r;

loop_start();

is $v, 'hello';
is $r, "Foo\n";

done_testing;
