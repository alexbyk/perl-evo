use Evo -Loop::Comp, '-Lib *', '-W::Eval w_eval_run';
use Test::More;

no warnings 'redefine';

EVAL: {
  my $loop = Evo::Loop::Comp::new();

  my $catched;
  $loop->zone(
    sub {
      $loop->zone_middleware(w_eval_run(sub { $catched = shift }));
      $loop->postpone(sub { die "Foo\n" });
    }
  );

  $loop->tick();
  is $catched, "Foo\n";
}

TIMER_LIKE_ZONE: {
  my $loop = Evo::Loop::Comp::new();
  my ($w_called, $t_called);
  my $w_log = sub($next) {
    sub { $w_called++; $next->(@_); };
  };

  my $reg = sub { $t_called++ };
  $loop->zone(sub { $loop->zone_middleware($w_log); $loop->timer(0, $reg); });
  ok !$w_called;

  $loop->tick();
  is $w_called, 1;
  is $t_called, 1;
}

TIMER_TICK: {
  my $loop = Evo::Loop::Comp::new();
  my $t_called;
  my $reg = sub { $t_called++ };
  $loop->timer(
    0,
    sub {
      $loop->timer(0, $reg);    # in next tick
      $reg->();
    }
  );
  $loop->timer(1, $reg);

  is $loop->tick(), 2;          # 1 + delayed
  ok $loop->timer_need_sort;
  is $t_called, 1;

  my $time = $loop->tick_time;
  local *Evo::Loop::Comp::steady_time = sub { $time + 1 };
  is $loop->tick(), 0;
  is $t_called, 3;
  is $loop->tick_time, $time + 1;
}

IGNORE_SIGPIPE: {
  my $loop = Evo::Loop::Comp::new();

  ok !$SIG{PIPE};
  $loop->postpone(sub { is $SIG{PIPE}, 'IGNORE'; });
  ok !$SIG{PIPE};
  $loop->start;
}


done_testing;
