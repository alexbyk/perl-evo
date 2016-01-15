package main;
use Evo '-Promises::Util *; -Promises::Promise; -Promises *';
use Test::More;

*p = *Evo::Promises::Promise::new;

# is_fulfilled
ok is_fulfilled_with(0, p()->d_fulfill(0));
ok !is_fulfilled_with(0, p()->d_reject(0));
ok !is_fulfilled_with(1, p()->d_fulfill(0));

# is_rejected
ok is_rejected_with(0, p()->d_reject(0));
ok !is_rejected_with(0, p()->d_fulfill(0));
ok !is_rejected_with(1, p()->d_fulfill(0));

# is_locked_on
my $par = p();
my $ch  = p();
unshift $par->d_children->@*, $ch;
ok is_locked_in($par, $ch);
ok !is_locked_in(p(), $ch);

# resolved/rejected
ok is_fulfilled_with 33, promises_resolve(33);
ok is_rejected_with 44,  promises_reject(44);

# resolve will follow, reject not
my $p = promise(sub { });
ok is_locked_in $p,     promises_resolve($p);
ok is_rejected_with $p, promises_reject($p);
done_testing;

1;
