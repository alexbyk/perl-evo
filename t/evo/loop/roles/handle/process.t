package main;
use Evo;
use Test::More;
use IO::Socket::IP;
use IO::Poll qw(POLLERR POLLHUP POLLIN POLLNVAL POLLOUT POLLPRI);

{

  package MyLoop;
  use Evo '-Comp *', -Loaded;
  with 'Evo::Loop::Role::Handle';

  sub zone_cb { $_[1] }
}


my $handle = IO::Socket::IP->new(LocalHost => "127.0.0.1:12345", Blocking => 0, Listen => 1)
  or die "Cannot construct handle - $@";


my $fd = fileno $handle;
no warnings 'once', 'redefine';

POLLIN: {
  my $loop = MyLoop::new();
  local *Evo::Loop::Role::Handle::handle_poll = sub { $_[2] = POLLIN; 1; };
  my $called;
  $loop->handle($handle, in => sub { $called++ });
  $loop->handle_process();

  is $called, 1;
}

POLLOUT: {
  my $loop = MyLoop::new();
  local *Evo::Loop::Role::Handle::handle_poll = sub { $_[2] = POLLOUT; 1; };
  my $called;
  $loop->handle($handle, out => sub { $called++ });
  $loop->handle_process();

  is $called, 1;
}

POLLERR: {
  my $loop = MyLoop::new();
  local *Evo::Loop::Role::Handle::handle_poll = sub { $_[2] = POLLERR; 1; };
  my $called;
  $loop->handle($handle, in => sub {fail});
  $loop->handle_catch($handle, sub { $called++ });
  $loop->handle_process();
  is $called, 1;
}

POLLERR_EMPTY: {
  my $loop = MyLoop::new();
  local *Evo::Loop::Role::Handle::handle_poll = sub { $_[2] = POLLERR; 1; };
  my $called;
  $loop->handle($handle, in => sub {fail});
  $loop->handle_process();
  pass "not died";
}

POLL_ARG: {
  my $loop = MyLoop::new();
  my ($arg_t, $called, $pcalled);
  local *Evo::Loop::Role::Handle::handle_poll = sub { $pcalled++; $arg_t = $_[0]; };
  $loop->handle_process(0.123456);
  ok !$pcalled;

  $loop->handle($handle, in => sub { $called++ });
  $loop->handle_process(0.123456);
  is $arg_t,   123;
  is $pcalled, 1;
  is $called,  1;
}

done_testing;
