package main;
use Evo;
use Test::More;

my $MOCK_TIME = 12.34_567;

{

  package MyLoop;
  use Evo '-Comp *', -Loaded;
  with 'Evo::Loop::Role::Timer';

  sub zone_cb   { $_[1] . '-Z' }
  sub tick_time {$MOCK_TIME}
}


TIMER: {
  my $loop  = MyLoop::new();
  my $queue = $loop->timer_queue;
  ok !$loop->timer_need_sort;
  $loop->timer(0 => 'CB1');
  is_deeply $loop->timer_queue, [[$MOCK_TIME, 'CB1-Z']];
  is $loop->timer_count, 1;
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
  no warnings 'redefine', 'once';
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
  is $t_called, 2;
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
