use Evo -Loop::Comp;
use Test::More;
use Test::Fatal;

no warnings 'redefine';
no warnings 'once';

my $MOCK_TIME = 12.34567;
local *Evo::Loop::Comp::steady_time = sub {$MOCK_TIME};

MAYBE_SLEEP_CALL_UTT: {
  my $loop = Evo::Loop::Comp::new();
  my $called;
  local *Evo::Loop::Comp::update_tick_time        = sub { $called++ };
  local *Evo::Loop::Comp::timer_calculate_timeout = sub {0};
  like exception { $loop->maybe_sleep; }, qr /no events/;
  is $called, 1;
}

my ($got_sp, $got_usleep);
local *Evo::Loop::Comp::io_process = sub { $got_sp     = $_[1] };
local *Evo::Loop::Comp::usleep         = sub { $got_usleep = $_[0] };

Y_SOCK_Y_TIMERS: {
  ($got_sp, $got_usleep) = ();
  my $loop = Evo::Loop::Comp::new();
  local *Evo::Loop::Comp::io_count            = sub {1};
  local *Evo::Loop::Comp::timer_count             = sub {1};
  local *Evo::Loop::Comp::timer_calculate_timeout = sub {1.23};
  $loop->maybe_sleep;
  is $got_usleep, undef;
  is $got_sp,     1.23;
}

Y_SOCK_N_TIMERS: {
  ($got_sp, $got_usleep) = ();
  my $loop = Evo::Loop::Comp::new();
  local *Evo::Loop::Comp::io_count = sub {1};
  local *Evo::Loop::Comp::timer_count  = sub {0};
  $loop->maybe_sleep;
  is $got_usleep, undef;
  is $got_sp,     -1;
}

N_SOCK_Y_TIMERS: {
  ($got_sp, $got_usleep) = ();
  my $loop = Evo::Loop::Comp::new();
  local *Evo::Loop::Comp::io_count            = sub {0};
  local *Evo::Loop::Comp::timer_count             = sub {1};
  local *Evo::Loop::Comp::timer_calculate_timeout = sub {1.23};
  $loop->maybe_sleep;
  is $got_usleep, 1_230_000;
  is $got_sp,     undef;
}

done_testing;
