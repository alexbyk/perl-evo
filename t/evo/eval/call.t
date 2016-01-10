use Evo '-Eval::Call; -Want *';
use Test::More;

my $call = bless {}, 'Evo::Eval::Call';

$call->{result} = [33, 2, 3];

$call->{wanted} = WANT_VOID;
is $call->result, undef;
is_deeply [$call->result], [];

$call->{wanted} = WANT_SCALAR;
is $call->result, 33;
is_deeply [$call->result], [33];

$call->{wanted} = WANT_LIST;
is $call->result, 3;
is_deeply [$call->result], [33, 2, 3];

done_testing;
