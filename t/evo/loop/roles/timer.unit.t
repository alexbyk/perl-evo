package main;
use Evo 'Test::More; Test::Fatal';

my $MOCK_TIME = 12.34_567;

{

  package MyLoop;
  use Evo '-Class *', -Loaded;
  with 'Evo::Loop::Role::Timer';

  sub zone_cb { $_[1] . '-Z' }
  sub tick_time($self) { $self->{ttcalled}++; $MOCK_TIME }

  sub timer_sort_if_needed($self) : Override {
    $self->{sortcalled}++;
    Evo::Loop::Role::Timer::timer_sort_if_needed(@_);
  }
}

EXCEPTION: {
  my $loop = MyLoop::new();
  like exception { $loop->timer(1, -1, 'CB2'); }, qr/negative period.+$0/i;
}


TIMER: {
  my $loop  = MyLoop::new();
  my $queue = $loop->timer_queue;
  ok !$loop->timer_need_sort;
  $loop->timer(0 => 'CB1');
  $loop->timer(0, 0.2, 'CB2');
  $loop->timer(0, 0,   'CB3');
  is_deeply $loop->timer_queue,
    [[$MOCK_TIME, 'CB1-Z'], [$MOCK_TIME, 'CB2-Z', 0.2], [$MOCK_TIME, 'CB3-Z']];
  is $loop->timer_count, 3;
  ok $loop->timer_need_sort;
}

TIMER_REMOVE: {
  my $loop  = MyLoop::new();
  my $queue = $loop->timer_queue;
  my $ref   = $loop->timer(0 => 'CANCELED');
  unshift $queue->@*, [1, 'CB1'];
  push $queue->@*,    [2, 'CB2'];
  $loop->timer_need_sort(0);
  $loop->timer_remove($ref) for 1 .. 2;    # not die
  is $loop->timer_need_sort, 0;
  is_deeply $loop->timer_queue, [[1, 'CB1'], [2, 'CB2']];
}

TIMER_REMOVE_0: {
  my $loop  = MyLoop::new();
  my $queue = $loop->timer_queue;
  my $ref   = $loop->timer(0 => 'CANCELED');
  $loop->timer_remove($ref);               # not die
  is $loop->timer_count, 0;
}

TIMER_SORT: {
  my $loop = MyLoop::new(timer_queue => [[2, 'CB2'], [1, 'CB1']]);
  $loop->timer_need_sort(0)->timer_sort_if_needed;
  is_deeply $loop->timer_queue, [[2, 'CB2'], [1, 'CB1']];
  $loop->timer_need_sort(1)->timer_sort_if_needed;
  is_deeply $loop->timer_queue, [[1, 'CB1'], [2, 'CB2']];
}

TIMER_PROCESS: {
  my $t_called;
  my $loop = MyLoop::new(
    timer_queue => [
      [$MOCK_TIME + 2, 'F16'],
      [$MOCK_TIME + 1, 'F15'],
      [$MOCK_TIME - 2, sub { $t_called++ }],
      [$MOCK_TIME - 1, sub { $t_called++ }]
    ]
  );

  $loop->timer_need_sort(1)->timer_process();
  is_deeply $loop->timer_queue, [[$MOCK_TIME + 1, 'F15'], [$MOCK_TIME + 2, 'F16']];

  # should be called only once to avoid lingering timers on overloaded machines
  is $loop->{ttcalled},   1;
  is $loop->{sortcalled}, 1;
  is $t_called, 2;
}

TIMER_PROCESS_PERIODIC: {
  my $t_called;
  my $sub05 = sub {1};
  my $sub20 = sub {2};
  my $loop  = MyLoop::new(
    timer_queue => [
      [$MOCK_TIME + 1, 'F15'], [$MOCK_TIME - 1, $sub05, 0.5],
      [$MOCK_TIME - 1, $sub20, 2]    # from tick_time, not current time
    ]
  );

  $loop->timer_need_sort(1)->timer_process();
  $loop->timer_need_sort(1)->timer_sort_if_needed();
  is_deeply $loop->timer_queue,
    [[$MOCK_TIME + 0.5, $sub05, 0.5], [$MOCK_TIME + 1, 'F15'], [$MOCK_TIME + 2, $sub20, 2]];
}

# we should resubscribe timer before processing
CHECK_SPECIAL_DIE_CASE_PERIODIC: {
  my $die = sub { die 22 };
  my $loop = MyLoop::new(timer_queue => [[$MOCK_TIME - 1, $die, 2]]);
  eval { $loop->timer_process(); };
  is_deeply $loop->timer_queue, [[$MOCK_TIME + 2, $die, 2]];
}

CHECK_SPECIAL_DIE_CASE_NOT_PERIODIC: {
  my $loop = MyLoop::new(timer_queue => [[$MOCK_TIME - 1, sub { die 22 }]]);
  eval { $loop->timer_process(); };
  ok !$loop->timer_queue->@*;
}

CALC_TIMEOUT: {

  my $noop = sub { };

  # positive - sort and find the closest
  my $loop = MyLoop::new(
    timer_need_sort => 1,
    timer_queue     => [[$MOCK_TIME + 2, $noop], [$MOCK_TIME + 1.001_02, $noop]]
  );
  is $loop->timer_calculate_timeout(), 1.00102;
  is_deeply $loop->timer_queue, [[$MOCK_TIME + 1.001_02, $noop], [$MOCK_TIME + 2, $noop]];

  # negative
  $loop = MyLoop::new(
    timer_need_sort => 1,
    timer_queue     => [[$MOCK_TIME + 2, $noop], [$MOCK_TIME - 1, $noop]]
  );
  is $loop->timer_calculate_timeout(), 0;
  is_deeply $loop->timer_queue, [[$MOCK_TIME - 1, $noop], [$MOCK_TIME + 2, $noop]];
  is $loop->timer_calculate_timeout(), 0;
}
done_testing;
