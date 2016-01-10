use Evo -Loop::Comp;
use Test::More;

no warnings 'redefine';
no warnings 'once';

my $loop = Evo::Loop::Comp::new();

my $MOCK_TIME = 12.34567;
local *Evo::Loop::Comp::steady_time = sub {$MOCK_TIME};
UPDATE_TICK_TIME: {
  $loop->update_tick_time;
  is $loop->tick_time, $MOCK_TIME;
}

TICK_CALL_UTT: {
  my $called;
  local *Evo::Loop::Comp::update_tick_time = sub { $called++ };
  $loop->tick;
  is $called, 1;
}

NOTHING: {
  local *Evo::Loop::Comp::timer_count    = sub {0};
  local *Evo::Loop::Comp::socket_count   = sub {0};
  local *Evo::Loop::Comp::postpone_count = sub {0};
  ok !$loop->tick;
}

HAVE_EVENTS: {
  local *Evo::Loop::Comp::timer_count = sub {1};
  ok $loop->tick;
}


done_testing;
