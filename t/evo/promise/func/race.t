use Evo 'Test::More; -Promise *; -Loop *';

EMPTY: {
  my ($called);
  my $p = promise_race()->then(sub { $called++; });
  loop_start;
  ok !$called;
}


SIMPLE_VAL: {
  my ($called, $result);
  my $d = deferred;
  my $p = promise_race('simple', $d->promise)->then(sub { $called++; $result = shift; });
  $d->resolve('bad');
  loop_start();
  is $called, 1;
  is $result, 'simple';
}

RESOLVE_BY_PROMISE: {
  my ($d1, $d2, $d3) = (deferred, deferred, deferred);
  my $p = promise_race($d1->promise, $d2->promise, $d3->promise);
  my ($called, $result);
  $p->then(sub { $called++; $result = shift }, sub {fail});

  loop_start;
  ok !$called;
  $d1->resolve('ok');
  $d2->resolve('bad');
  $d3->reject('bad');
  loop_start();
  is $called, 1;
  is $result, 'ok';
}

RESOLVE_BY_PROMISE_WITH_PROMISE_AND_VAL: {
  my ($d1, $d2, $d3) = (deferred, deferred, deferred);
  my $p = promise_race($d1->promise, $d2->promise, $d3->promise);
  my ($called, $result);
  $p->then(sub { $called++; $result = shift }, sub {fail});

  loop_start;
  ok !$called;
  my $dres = deferred;
  $d1->resolve($dres->promise);
  $d2->resolve('ok');
  $d3->resolve('bad');
  loop_start();
  is $called, 1;
  is $result, 'ok';
}

REJECT_BY_PROMISE: {
  my ($d1, $d2, $d3) = (deferred, deferred, deferred);
  my $p = promise_race($d1->promise, $d2->promise, $d3->promise);
  my ($called, $reason);
  $p->then(sub {fail}, sub { $called++; $reason = shift });

  loop_start;
  ok !$called;
  $d1->reject('reason');
  $d2->resolve('bad');
  $d3->reject('bad');
  loop_start();
  is $called, 1;
  is $reason, 'reason';
}


RESOLVE_BY_THENABLE: {
  no warnings 'once';
  my $resolve;
  local *My::Thenable::then = sub($th, $res, $rej) { $resolve = $res; };
  my $thenable = bless {}, 'My::Thenable';
  my ($d1, $d2) = (deferred, deferred);
  my $p = promise_race($d1->promise, $d2->promise, $thenable);
  my ($called, $result);
  $p->then(sub { $called++; $result = shift }, sub {fail});

  loop_start;
  ok !$called;
  $resolve->('ok');
  $d1->resolve('bad');
  $d2->reject('bad');
  loop_start();
  is $called, 1;
  is $result, 'ok';
}


REJECT_BY_THENABLE: {
  no warnings 'once';
  my $reject;
  local *My::Thenable::then = sub($th, $res, $rej) { $reject = $rej; };
  my $thenable = bless {}, 'My::Thenable';
  my ($d1, $d2) = (deferred, deferred);
  my $p = promise_race($d1->promise, $d2->promise, $thenable);
  my ($called, $reason);
  $p->then(sub {fail}, sub { $called++; $reason = shift });

  loop_start;
  ok !$called;
  $reject->('reason');
  $d1->resolve('bad');
  $d2->reject('bad');
  loop_start();
  is $called, 1;
  is $reason, 'reason';
}

done_testing;
