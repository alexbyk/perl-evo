package main;
use Evo 'Test::More; -Loop::Class; -Io *';
use IO::Poll qw(POLLERR POLLHUP POLLIN POLLNVAL POLLOUT POLLPRI);


*newloop = *Evo::Loop::Class::new;

my $handle = io_open_anon;

my $fd = fileno $handle;
no warnings 'once', 'redefine';

UTT: {
  my $called;
  my $loop = newloop();
  local *Evo::Loop::Class::update_tick_time = sub { $called++ };
  local *Evo::Loop::Role::Io::io_poll = sub { $_[2] = POLLIN; 1; };
  $loop->io_in($handle, sub { });
  $loop->io_process;
  is $called, 1;
}

POLLIN: {
  my $loop = newloop();
  local *Evo::Loop::Role::Io::io_poll = sub { $_[2] = POLLIN; 1; };
  my $called;
  $loop->io_in($handle, sub { $called++ });
  $loop->io_process();

  is $called, 1;
}

POLLOUT: {
  my $loop = newloop();
  local *Evo::Loop::Role::Io::io_poll = sub { $_[2] = POLLOUT; 1; };
  my $called;
  $loop->io_out($handle, sub { $called++ });
  $loop->io_process();

  is $called, 1;
}

POLLERR: {
  my $loop = newloop();
  local *Evo::Loop::Role::Io::io_poll = sub { $_[2] = POLLERR; 1; };
  my $called;
  $loop->io_in($handle, sub {fail});
  $loop->io_error($handle, sub { $called++ });
  $loop->io_process();
  is $called, 1;
}

POLLERR_EMPTY: {
  my $loop = newloop();
  local *Evo::Loop::Role::Io::io_poll = sub { $_[2] = POLLERR; 1; };
  my $called;
  $loop->io_in($handle, sub {fail});
  $loop->io_process();
  pass "not died";
}

POLL_ARG: {
  my $loop = newloop();
  my ($arg_t, $called, $pcalled);
  local *Evo::Loop::Role::Io::io_poll = sub { $pcalled++; $arg_t = $_[0]; };
  $loop->io_process(0.123456);
  ok !$pcalled;

  $loop->io_in($handle, sub { $called++ });
  $loop->io_process(0.123456);
  is $arg_t,   123;
  is $pcalled, 1;
  is $called,  1;
}

done_testing;
