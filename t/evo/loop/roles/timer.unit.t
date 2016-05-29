package main;
use Evo 'Test::More; Test::Fatal';

my $MOCK_TIME = 12.34_567;

{

  package MyLoop;
  use Evo '-Class *', -Loaded;
  with 'Evo::Loop::Role::Timer';

  my $id = 0;
  sub gen_id { $id++ }

  has zone_cb_called => 0;

  sub zone_cb ($self, $cb) {
    $self->zone_cb_called($self->zone_cb_called + 1);
    $cb;
  }
  sub tick_time($self) { $self->{ttcalled}++; $MOCK_TIME }

  sub timer_sort_if_needed($self) : Overriden {
    $self->{sortcalled}++;
    Evo::Loop::Role::Timer::timer_sort_if_needed(@_);
  }
}

EXCEPTION: {
  my $loop = MyLoop->new();
  like exception { $loop->timer_periodic(1, -1, 'CB2'); }, qr/negative period.+$0/i;
}


TIMER: {
  my $loop  = MyLoop->new();
  my $queue = $loop->timer_queue;
  ok !$loop->timer_need_sort;
  $loop->timer(0 => 'CB1');
  $loop->timer_periodic(0, 0.2, 'CB2');
  $loop->timer_periodic(0, 0,   'CB3');
  is $loop->zone_cb_called, 3;
  my $que = $loop->timer_queue;
  is_deeply $que,
    [
    {when => $MOCK_TIME, cb => 'CB1', id     => $que->[0]{id}},
    {when => $MOCK_TIME, cb => 'CB2', period => 0.2, id => => $que->[1]{id}},
    {when => $MOCK_TIME, cb => 'CB3', period => 0, id => $que->[2]{id}}
    ];
  is $loop->timer_count, 3;
  ok $loop->timer_need_sort;
}

TIMER_REMOVE: {
  my $loop  = MyLoop->new();
  my $queue = $loop->timer_queue;
  $loop->timer(1 => 'CB1');
  my $id = $loop->timer(0 => 'CANCELED');
  $loop->timer(2 => 'CB2');
  $loop->timer_need_sort(0);
  $loop->timer_remove($id) for 1 .. 2;    # not die
  is $loop->timer_need_sort, 0;
  is $loop->timer_queue->[0]{cb}, 'CB1';
  is $loop->timer_queue->[1]{cb}, 'CB2';
  is $loop->timer_queue->@*, 2;

}

TIMER_REMOVE_0: {
  my $loop  = MyLoop->new();
  my $queue = $loop->timer_queue;
  my $id    = $loop->timer(0 => 'CANCELED');
  $loop->timer_remove($id);
  is $loop->timer_count, 0;
}

TIMER_SORT: {
  my $loop = MyLoop->new();
  $loop->timer(2 => 'CB2');
  $loop->timer(1 => 'CB1');
  $loop->timer_need_sort(0)->timer_sort_if_needed;
  is $loop->timer_queue->[0]{cb}, 'CB2';
  is $loop->timer_queue->[1]{cb}, 'CB1';
  $loop->timer_need_sort(1)->timer_sort_if_needed;
  is $loop->timer_queue->[0]{cb}, 'CB1';
  is $loop->timer_queue->[1]{cb}, 'CB2';
}

TIMER_PROCESS: {
  my $t_called;
  my $loop = MyLoop->new();

  $loop->timer_queue(
    [
      {when => $MOCK_TIME + 2, cb => 'F16'},
      {when => $MOCK_TIME + 1, cb => 'F15'},
      {
        when => $MOCK_TIME - 2,
        cb   => sub { $t_called++ }
      },
      {
        when => $MOCK_TIME - 1,
        cb   => sub { $t_called++ }
      },
    ]
  );

  $loop->timer_need_sort(1)->timer_process();
  is $loop->timer_queue->[0]{cb}, 'F15';
  is $loop->timer_queue->[1]{cb}, 'F16';

  # should be called only once to avoid lingering timers on overloaded machines
  is $loop->{ttcalled},   1;
  is $loop->{sortcalled}, 1;
  is $t_called, 2;
}


TIMER_PROCESS_PERIODIC: {
  my $t_called;
  my $sub05 = sub {1};
  my $sub20 = sub {2};
  my $loop  = MyLoop->new(
    timer_queue => [
      {when => $MOCK_TIME + 1, cb => 'F15'}, {when => $MOCK_TIME - 1, cb => $sub05, period => 0.5},
      {when => $MOCK_TIME - 1, cb => $sub20, period => 2}    # from tick_time, not current time
    ]
  );

  $loop->timer_need_sort(1)->timer_process();
  $loop->timer_need_sort(1)->timer_sort_if_needed();
  my $que = $loop->timer_queue;

  is $que->[0]{when}, $MOCK_TIME + 0.5;
  is $que->[0]{cb},   $sub05;

  is $que->[1]{cb}, 'F15';

  is $que->[2]{cb},   $sub20;
  is $que->[2]{when}, $MOCK_TIME + 2;

}


# we should resubscribe timer before processing
CHECK_SPECIAL_DIE_CASE_PERIODIC: {
  my $die = sub { die 22 };
  my $loop = MyLoop->new();
  $loop->timer_periodic(-1, 2, $die);
  eval { $loop->timer_process(); };
  is $loop->timer_queue->[0]{when}, $MOCK_TIME + 2;
}

CHECK_SPECIAL_DIE_CASE_NOT_PERIODIC: {
  my $loop = MyLoop->new();
  $loop->timer(-1, sub {die});
  eval { $loop->timer_process(); };
  ok !$loop->timer_queue->@*;
}

CALC_TIMEOUT: {

  my $noop = sub { };

  # positive - sort and find the closest
  my $loop = MyLoop->new();
  $loop->timer(2,        'CB2');
  $loop->timer(1.001_02, 'CB1');

  is $loop->timer_calculate_timeout(), 1.00102;
  is $loop->timer_queue->[0]{cb}, 'CB1';
  is $loop->timer_queue->[1]{cb}, 'CB2';

  # negative
  $loop = MyLoop->new();
  $loop->timer(2, 'CB2');
  $loop->timer(-1, 'CB1');
  is $loop->timer_calculate_timeout(), 0;
  is $loop->timer_queue->[0]{cb}, 'CB1';
  is $loop->timer_queue->[1]{cb}, 'CB2';
  is $loop->timer_calculate_timeout(), 0;
}


done_testing;
