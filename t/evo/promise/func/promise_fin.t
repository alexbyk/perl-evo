use Evo 'Test::More; -Promise *; -Loop *';

# fulfill chain
F_FIN_RETURNS_VALUE: {
  my $p = promise_resolve('VAL');
  my ($V, $called);
  $p->fin(sub() { $called++; "IGNORE" })->then(sub($v) { $V = $v; }, sub {fail});
  loop_start;
  is $called, 1;
  is $V,      'VAL';
}

F_FIN_RETURNS_PROMISE_F: {
  my $p = promise_resolve('VAL');
  my ($called, $fcalled, $V);
  $p->fin(sub() { $fcalled++; promise_resolve('IGNORE') })->then(sub($v) { $called++; $V = $v; });
  loop_start;
  is $called,  1;
  is $V,       'VAL';
  is $fcalled, 1;
}


F_FIN_RETURNS_PROMISE_R: {
  my $p = promise_resolve('BAD');
  my ($called, $fcalled, $R);
  $p->fin(sub() { $fcalled++; promise_reject('REASON') })
    ->then(sub {fail}, sub($r) { $called++; $R = $r; });
  loop_start;
  is $called,  1;
  is $R,       'REASON';
  is $fcalled, 1;
}

F_FIN_DIES: {
  my $p = promise_resolve('BAD');
  my ($called, $fcalled, $R);
  $p->fin(sub() { $fcalled++; die "REASON\n" })->catch(sub($r) { $called++; $R = $r; });
  loop_start;
  is $called,  1;
  is $R,       "REASON\n";
  is $fcalled, 1;
}

# reject chain
R_FIN_RETURNS_VALUE: {
  my $p = promise_reject('REASON');
  my ($reason, $fcalled);
  $p->fin(sub() { $fcalled++; "IGNORE" })->catch(sub($r) { $reason = $r; });
  loop_start;
  is $reason,  'REASON';
  is $fcalled, 1;
}

R_FIN_RETURNS_PROMISE_F: {
  my $p = promise_reject('REASON');
  my ($reason, $fcalled);
  $p->fin(sub() { $fcalled++; promise_resolve('IGNORE') })->catch(sub($r) { $reason = $r; });
  loop_start;
  is $fcalled, 1;
  is $reason,  'REASON';
}

R_FIN_RETURNS_PROMISE_R: {
  my $p = promise_reject('BAD');
  my ($reason, $fcalled);
  $p->fin(sub() { $fcalled++; promise_reject('REPLACED') })->catch(sub($r) { $reason = $r; });
  loop_start;
  is $fcalled, 1;
  is $reason,  'REPLACED';
}

R_FIN_DIES: {
  my $p = promise_reject('BAD');
  my ($reason, $fcalled);
  $p->fin(sub { $fcalled++; die "REPLACED\n" })->catch(sub($r) { $reason = $r; });
  loop_start;
  is $fcalled, 1;
  is $reason,  "REPLACED\n";
}

done_testing;
