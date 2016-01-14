package main;
use Evo -Net::Socket;
use Test::More;
use IO::Poll qw(POLLERR POLLHUP POLLIN POLLNVAL POLLOUT POLLPRI);

{

  package MyLoop;
  use Evo '-Comp *', -Loaded;
  with 'Evo::Loop::Role::Handle';
  sub update_tick_time { }

  sub zone_cb { $_[1] }
}


my $handle = Evo::Net::Socket::new()->socket_open() or die "Cannot construct handle - $@";


my $fd = fileno $handle;
no warnings 'once', 'redefine';

UTT: {
  my $called;
  my $loop = MyLoop::new();
  local *MyLoop::update_tick_time = sub { $called++ };
  local *Evo::Loop::Role::Handle::handle_poll = sub { $_[2] = POLLIN; 1; };
  $loop->handle_in($handle, sub { });
  $loop->handle_process;
  is $called, 1;
}

POLLIN: {
  my $loop = MyLoop::new();
  local *Evo::Loop::Role::Handle::handle_poll = sub { $_[2] = POLLIN; 1; };
  my $called;
  $loop->handle_in($handle, sub { $called++ });
  $loop->handle_process();

  is $called, 1;
}

POLLOUT: {
  my $loop = MyLoop::new();
  local *Evo::Loop::Role::Handle::handle_poll = sub { $_[2] = POLLOUT; 1; };
  my $called;
  $loop->handle_out($handle, sub { $called++ });
  $loop->handle_process();

  is $called, 1;
}

POLLERR: {
  my $loop = MyLoop::new();
  local *Evo::Loop::Role::Handle::handle_poll = sub { $_[2] = POLLERR; 1; };
  my $called;
  $loop->handle_in($handle, sub {fail});
  $loop->handle_error($handle, sub { $called++ });
  $loop->handle_process();
  is $called, 1;
}

POLLERR_EMPTY: {
  my $loop = MyLoop::new();
  local *Evo::Loop::Role::Handle::handle_poll = sub { $_[2] = POLLERR; 1; };
  my $called;
  $loop->handle_in($handle, sub {fail});
  $loop->handle_process();
  pass "not died";
}

POLL_ARG: {
  my $loop = MyLoop::new();
  my ($arg_t, $called, $pcalled);
  local *Evo::Loop::Role::Handle::handle_poll = sub { $pcalled++; $arg_t = $_[0]; };
  $loop->handle_process(0.123456);
  ok !$pcalled;

  $loop->handle_in($handle, sub { $called++ });
  $loop->handle_process(0.123456);
  is $arg_t,   123;
  is $pcalled, 1;
  is $called,  1;
}

done_testing;
