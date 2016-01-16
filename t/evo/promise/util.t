package main;
use Evo '-Promise::Util *; -Promise::Comp; -Promise *';
use Test::More;

*p = *Evo::Promise::Comp::new;

# is_fulfilled
ok is_fulfilled_with(0,     p()->d_fulfill(0));
ok is_fulfilled_with(undef, p()->d_fulfill(undef));
ok !is_fulfilled_with(0, p()->d_reject(0));
ok !is_fulfilled_with(1, p()->d_fulfill(0));

# is_rejected
ok is_rejected_with(0,     p()->d_reject(0));
ok is_rejected_with(undef, p()->d_reject(undef));
ok !is_rejected_with(0, p()->d_fulfill(0));
ok !is_rejected_with(1, p()->d_fulfill(0));

# is_locked_on
my $par = p();
my $ch  = p();
unshift $par->d_children->@*, $ch;
ok is_locked_in($par, $ch);
ok !is_locked_in(p(), $ch);

# resolved/rejected
ok is_fulfilled_with 33, promise_resolve(33);
ok is_rejected_with 44,  promise_reject(44);

# resolve will follow, reject not
my $p = promise(sub { });
ok is_locked_in $p,     promise_resolve($p);
ok is_rejected_with $p, promise_reject($p);
done_testing;

1;
