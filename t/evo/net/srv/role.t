package main;
use Evo '-Lib::Net *; -Loop *; -Io::Socket; -Lib *';
use Evo 'Test::Evo::Helpers *';
use Evo 'Socket :all; Test::More; Test::Fatal; Errno EBADF';

CAN_BIND6     or plan skip_all => "No IPv6: " . $!      || $@;
HAS_REUSEPORT or plan skip_all => "No REUSEPORT: " . $! || $@;

my $LAST;
{

  package My::Server;
  use Evo '-Class *';
  sub ee_events {qw(srv_error)}
  with -Net::Srv::Role, -Ee;

  sub srv_handle_accept ($self, $sock)
    : Override { $LAST = Evo::Net::Srv::Role::srv_handle_accept($self, $sock) }

  sub srv_handle_error ($self, $sock, $err) : Override {
    $self->emit(srv_error => $err);
    Evo::Net::Srv::Role::srv_handle_error(@_);
  }
}


LISTEN_OPTS: {
  my $srv = My::Server->new();
  like exception { $srv->srv_listen(ip => '::1', bad => 'foo') }, qr/unknown.+bad.+$0/;

  my $sock = $srv->srv_listen(ip => '::1', reuseport => 1);
  ok $sock->io_reuseport;
  my ($ip, $port) = $sock->io_local;
  is $ip, '::1';
}


LISTEN_RUNNING: {
  local $Evo::Loop::SINGLE = my $loop = Evo::Loop::Class->new();
  my $srv = My::Server->new();
  my $sock = $srv->srv_listen(ip => '::1');
  is_deeply $srv->srv_acceptors, [$sock];
  is $loop->io_count, 1;
}

LISTEN_STOPPED: {
  local $Evo::Loop::SINGLE = my $loop = Evo::Loop::Class->new();
  my $srv = My::Server->new()->srv_is_running(0);
  my $sock = $srv->srv_listen(ip => '::1');
  is_deeply $srv->srv_acceptors, [$sock];
  is_deeply $loop->io_count, 0;
}

START_STOP: {
  local $Evo::Loop::SINGLE = my $loop = Evo::Loop::Class->new();
  my $srv = My::Server->new();
  $srv->srv_listen(ip => '::1') for 1 .. 3;

  $srv->srv_stop();
  like exception { $srv->srv_stop }, qr/already/;
  ok !$srv->srv_is_running;
  is $loop->io_count, 0;

  $srv->srv_start();
  like exception { $srv->srv_start }, qr/already/;
  ok $srv->srv_is_running;
  is $loop->io_count, 3;

}

CONNECTIONS: {
  my $srv = My::Server->new();
SCOPE: {
    my $obj1 = bless {n => 1}, "My::Temp";
    my $obj2 = bless {n => 2}, "My::Temp";
    my $obj3 = bless {n => 3}, "My::Temp";
    $srv->srv_connectionss($obj1);
    is_deeply [$srv->srv_connectionss], [$obj1];
    $srv->srv_connectionss($obj2, $obj3);
    is_deeply [sort $srv->srv_connectionss], [sort $obj1, $obj2, $obj3];
  }

  $srv->srv_connectionss({});
  is_deeply [$srv->srv_connectionss], [];
}

ACCEPT_ERROR: {
  my $srv   = My::Server->new();
  my $sock  = $srv->srv_listen(ip => '::1');
  my $sock2 = $srv->srv_listen(ip => '::1');
  my $e;
  close $sock;
  local $SIG{__WARN__} = sub { };
  $srv->on(srv_error => sub { $e = $_[1] })->srv_accept($sock);
  is $e + 0, EBADF;
  is_deeply $srv->srv_acceptors, [$sock2];
}

done_testing;
