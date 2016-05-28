use Evo -Loop::Class;
use Test::More;

no warnings 'redefine';
no warnings 'once';

my $loop = Evo::Loop::Class->new();

my $MOCK_TIME = 12.34567;
local *Evo::Loop::Class::steady_time = sub {$MOCK_TIME};
UPDATE_TICK_TIME: {
  $loop->update_tick_time;
  is $loop->tick_time, $MOCK_TIME;
}

TICK_CALL_UTT: {
  my $called;
  local *Evo::Loop::Class::update_tick_time = sub { $called++ };
  $loop->tick;
  is $called, 1;
}

NOTHING: {
  local *Evo::Loop::Class::timer_count    = sub {0};
  local *Evo::Loop::Class::io_count       = sub {0};
  local *Evo::Loop::Class::postpone_count = sub {0};
  ok !$loop->tick;
}

HAVE_EVENTS: {
  local *Evo::Loop::Class::timer_count = sub {1};
  ok $loop->tick;
}


done_testing;
