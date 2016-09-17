use Evo;
use Test::More;

BEGIN {
  eval { require Mojo::IOLoop; 1 } or plan skip_all => 'Install Mojolicious to run this test';
}

use Mojo::Promise '*';


my ($v, $r);

# promise
my $p = promise(
  sub ($resolve, $reject) {
    $resolve->('hello');
  }
)->then(sub { $v = shift; die "Foo\n" })->catch(sub { $r = shift });

ok !$v;
ok !$r;

Mojo::IOLoop->start;

is $v, 'hello';
is $r, "Foo\n";


# deferred
($v, $r) = @_;
my $d = deferred;
$d->promise->then(sub { $v = shift; die "Foo\n" })->catch(sub { $r = shift });
$d->resolve('hello');

ok !$v;
ok !$r;

Mojo::IOLoop->start;

is $v, 'hello';
is $r, "Foo\n";

# functions

ok(main::->can($_), $_) for qw(resolve reject race all);
ok resolve(2);

done_testing;
