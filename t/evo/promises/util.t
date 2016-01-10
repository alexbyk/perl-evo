package main;
use Evo '-Promises::Util *; -Promises::Promise';
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

done_testing;

1;
