package Evo::Promises;
use Evo '-Export *; :Deferred; :Promise; :Util *';

export_proxy ':Util', qw(promises_resolve promises_reject promises_all promises_race);

sub promise($fn) : Export {
  my $d = Evo::Promises::Deferred::new(promise => my $p = Evo::Promises::Promise::new());
  $fn->(sub { $d->resolve(@_) }, sub { $d->reject(@_) });
  $p;
}

sub deferred : Export :
  prototype() { Evo::Promises::Deferred::new(promise => Evo::Promises::Promise::new()); }

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

=head2 promises_resolve

  my $p = promises_resolve('hello');

Generate a resolved promise with a given value. If value is a thenable object or another promise, the resulting promise will follow it. Otherwise it will be fulfilled with that value

=head2 promises_reject

  my $p = promises_reject('hello');

Generate a rejected promise with a reason. If the reason is a promise, resulting promise will NOT follow it.

=head2 promises_all

Creates a promise that will be resolved only when all promises are resolved. The result will be an array containing resolved value with the same order, as passed to this function. If one of the collected promises become rejected, that promise will be rejected to with that reason.

  my ($d1, $d2) = (deferred, deferred);
  loop_timer 1,   sub { $d1->resolve('first') };
  loop_timer 0.1, sub { $d2->resolve('second') };

  promises_all($d1->promise, $d2->promise)->then(sub($v) { say join ';', $v->@* });

Will print C<first;second>

=head2 promises_race

Return a promise that will be resolved or rejected with the value/reason of the first resolved/rejected promise

  promises_race($d1->promise, $d1->promise)->then(sub($v) { say $v });

  loop_timer 1 => sub { $d1->resolve('1') };
  loop_timer 2 => sub { $d2->resolve('2') };

Will print C<2>

=head2 fin

Chain promise with a handler, that gets called with no argument when the parent promise is settled(fulfilled or rejected). When that handler returns a result, the next promise gets postponed. Value are ignored. If that handler causes an exception or returns rejected promise (or promise that will eventually gets rejected), the chain would be rejected.

A shorter. Causes no effect on the chain unless rejection happens

  promises_resolve('VAL')->fin(sub() {'IGNORED'})->then(sub($v) { say $v});

Usefull for closing connections etc. The idea described here: L<https://github.com/kriskowal/q#propagation>


=head1 SEE ALSO

More info about promises, race, all etc.: L<https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Promise>

=cut
