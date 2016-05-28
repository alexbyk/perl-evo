package Evo::Promise;
use Evo '-Export *; ::Deferred; ::Class; ::Util *';

export_proxy '::Util', qw(promise_resolve promise_reject promise_all promise_race);

sub promise($fn) : Export {
  my $d = Evo::Promise::Deferred->new(promise => my $p = Evo::Promise::Class->new());
  $fn->(sub { $d->resolve(@_) }, sub { $d->reject(@_) });
  $p;
}

sub deferred : Export :
  prototype() { Evo::Promise::Deferred->new(promise => Evo::Promise::Class->new()); }

1;

=head1 FUNCTIONS

=head2 promise

  promise(
    sub($resolve, $reject) {
      loop_timer 1 => sub { $resolve->('HELLO') };
    }
  )->then(sub($v) { say "Fulfilled: $v"; });


Return ES6 syntax promise. The first argument should be a function. Resolve and reject handlers(functions) will be passed to it  

Only the first invocation of either C<$resolve> or C<$reject> matters. The second one will be ignored.

=head2 deferred

Create a promise and attach it to the deferred object. Deferred object is a handler for the promise.

  my $d = deferred();
  loop_timer 1 => sub { $d->resolve('HELLO') };
  $d->promise->then(sub($v) { say "Fulfilled: $v"; });

=head2 promise_resolve

  my $p = promise_resolve('hello');

Generate a resolved promise with a given value. If value is a thenable object or another promise, the resulting promise will follow it. Otherwise it will be fulfilled with that value

=head2 promise_reject

  my $p = promise_reject('hello');

Generate a rejected promise with a reason. If the reason is a promise, resulting promise will NOT follow it.

=head2 promise_all

Creates a promise that will be resolved only when all promise are resolved. The result will be an array containing resolved value with the same order, as passed to this function. If one of the collected promise become rejected, that promise will be rejected to with that reason.

  my ($d1, $d2) = (deferred, deferred);
  loop_timer 1,   sub { $d1->resolve('first') };
  loop_timer 0.1, sub { $d2->resolve('second') };

  promise_all($d1->promise, $d2->promise)->then(sub($v) { say join ';', $v->@* });

Will print C<first;second>

L</"spread"> will help a lot

=head2 promise_race

Return a promise that will be resolved or rejected with the value/reason of the first resolved/rejected promise

  promise_race($d1->promise, $d1->promise)->then(sub($v) { say $v });

  loop_timer 1 => sub { $d1->resolve('1') };
  loop_timer 2 => sub { $d2->resolve('2') };

Will print C<2>

=head1 METHODS

=head2 then

Make a chain and return a promise. The 2 args form C<onResolve, onReject> isn't recommended. Better use L</"catch">

  $promise->then(sub($v) { say "Resolved $v" })->then(sub($v) { say "Step 2 $v" });
  $promise->then(sub($v) { say "Resolved $v" }, sub($r) { say "Rejected $r" });

=head2 catch

The same as C<then(undef, sub($r) {})>, recommended form

  $d->promise->then(sub { })->catch(sub($r) { say "Rejected with $r" });

=head2 spread

If you expect promise gets fulfilled with the array reference, you can dereference it and pass to function

promise_all(first => $d1->promise, second => $d2->promise)
  ->spread(sub(%res) { say $_ , ': ', $res{$_} for keys %res });


=head2 fin

Chain promise with a handler, that gets called with no argument when the parent promise is settled(fulfilled or rejected). When that handler returns a result, the next promise gets postponed. Value are ignored. If that handler causes an exception or returns rejected promise (or promise that will eventually gets rejected), the chain would be rejected.

A shorter. Causes no effect on the chain unless rejection happens

  promise_resolve('VAL')->fin(sub() {'IGNORED'})->then(sub($v) { say $v});

Usefull for closing connections etc. The idea described here: L<https://github.com/kriskowal/q#propagation>

=head1 IMPLEMENTATION

This is a sexy and fast non-recursive implementation of Promise/A+

The end-user library L<Evo::Promise> works with L<Evo::Loop> (promise require event loop because of L<https://promisesaplus.com/#point-34>)
But the main part (see L<Evo::Promise::Driver>) is designed to be reused and it's ridiculously simple to implement variant for other loops with a few lines of code (see the source code of L<Evo::Promise>)


Different implementations of promise should work together well by design. Right now there are other implementations in CPAN. But when I tested them(2016yr), they were far away from A+ and contained many bugs. So if need to mix different promise libraries, try to start the chain from this one



=head1 SEE ALSO

More info about promise, race, all etc.: L<https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Promise>

=cut
