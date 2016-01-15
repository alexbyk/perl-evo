package Evo::Promises;
use Evo '-Export *; :Deferred; :Promise';

sub promise($fn) : Export {
  my $d = Evo::Promises::Deferred::new(promise => my $p = Evo::Promises::Promise::new());
  $fn->(sub { $d->resolve(@_) }, sub { $d->reject(@_) });
  $p;
}

sub deferred : Export :
  prototype() { Evo::Promises::Deferred::new(promise => Evo::Promises::Promise::new()); }

sub promises_race : Export {
  my $d   = deferred;
  my $onF = sub { $d->resolve(@_) };
  my $onR = sub { $d->reject(@_) };
  foreach my $cur (@_) {
    if (ref $cur eq 'Evo::Promises::Promise') {
      $cur->then($onF, $onR);
    }
    else {
      # wrap with our promise
      my $wd = deferred;
      $wd->promise->then($onF, $onR);
      $wd->resolve($cur);
    }
  }

  $d->promise;
}

sub promises_all : Export {
  my $d = deferred;
  do { $d->resolve([]); return $d->promise; } unless @_;

  my @prms    = @_;
  my $pending = @prms;

  my @result;
  my $onR = sub { $d->reject($_[0]) };

  for (my $i = 0; $i < @prms; $i++) {
    my $cur_i = $i;
    my $cur_p = $prms[$cur_i];
    my $onF   = sub { $result[$cur_i] = $_[0]; $d->resolve(\@result) if --$pending == 0; };

    if (ref $cur_p eq 'Evo::Promises::Promise') {
      $cur_p->then($onF, $onR);
    }
    else {
      # wrap with our promise
      my $wd = deferred;
      $wd->promise->then($onF, $onR);
      $wd->resolve($cur_p);
    }
  }
  $d->promise;
}

1;

=head1 FUNCTIONS

=head1 promise


  promise(
    sub($resolve, $reject) {
      loop_timer 1 => sub { $resolve->('HELLO') };
    }
  )->then(sub($v) { say "Fulfilled: $v"; });


Return ES6 syntax promise. The first argument should be a function. Resolve and reject handlers(functions) will be passed to it  

Only the first invocation of either C<$resolve> or C<$reject> matters. The second one will be ignored.

=head1 deferred

Create a promise and attach it to the deferred object. Deferred object is a handler for the promise.

  my $d = deferred();
  loop_timer 1 => sub { $d->resolve('HELLO') };
  $d->promise->then(sub($v) { say "Fulfilled: $v"; });


=head1 promises_all

Creates a promise that will be resolved only when all promises are resolved. The result will be an array containing resolved value with the same order, as passed to this function. If one of the collected promises become rejected, that promise will be rejected to with that reason.

  my ($d1, $d2) = (deferred, deferred);
  loop_timer 1,   sub { $d1->resolve('first') };
  loop_timer 0.1, sub { $d2->resolve('second') };

  promises_all($d1->promise, $d2->promise)->then(sub($v) { say join ';', $v->@* });

Will print C<first;second>

=head1 promises_race

Return a promise that will be resolved or rejected with the value/reason of the first resolved/rejected promise

  promises_race($d1->promise, $d1->promise)->then(sub($v) { say $v });

  loop_timer 1 => sub { $d1->resolve('1') };
  loop_timer 2 => sub { $d2->resolve('2') };

Will print C<2>

=head1 SEE ALSO

More info about promises, race, all etc.: L<https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Promise>

=cut
