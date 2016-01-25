use Evo;
use Test::More;
use Evo '-Loop 
  loop_start
  loop_timer loop_timer_remove
  loop_io_error loop_io_remove_all
  loop_io_in loop_io_remove_in
  loop_io_out loop_io_remove_out
  loop_postpone
  loop_zone
';

my ($counter, @debug);
sub debug($m) { push @debug, $m }

sub w_debug($name) {

  sub ($next) {
    sub {
      debug "$name";
      eval { $next->(@_) };
      $@ ? debug "!$name" : debug "/$name";
    };
  };
}


loop_zone sub {
  loop_zone w_debug(1), w_debug(2), sub {
    loop_zone w_debug(3), sub {

      loop_timer 0, sub {

        loop_postpone sub {
          loop_timer 0, sub { debug "t2"; };
          debug "p1";
        };
        loop_postpone sub { debug "p2"; };

        debug "t1";
        die "Foo";
        debug "BAD";
      };

    };
  };
};

loop_start();

is_deeply \@debug, [
  qw(
    1 2 3 t1 !3 /2 /1
    1 2 3 p1 /3 /2 /1
    1 2 3 p2 /3 /2 /1
    1 2 3 t2 /3 /2 /1
    )
];

done_testing;
