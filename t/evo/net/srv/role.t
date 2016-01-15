package main;
use Evo '-Net::Util *; -Loop *; -Net::Socket';
use Evo 'Socket :all; Test::More; Test::Fatal; Errno EINVAL';

my $HAS_REUSEPORT = eval { my $v = SO_REUSEPORT(); 1 } or diag "NO REUSEPORT $@";
my $CAN_REUSEPORT6 = eval { Evo::Net::Socket::new()->socket_open()->socket_reuseport; 1 }
  or diag "CAN'T REUSEPORT6 $@";

my $LAST;
{

  package My::Stream;
  use Evo '-Comp *';
  with -Ee, -Net::Socket::Role;
  sub ee_events { }


  package My::Server;
  use Evo '-Comp *';
  sub ee_events {qw(srv_error)}
  with -Net::Srv::Role, -Ee;
  sub srv_handle_accept($self, $sock) { $LAST = bless $sock, 'My::Stream' }

  sub srv_handle_error($self, $sock, $err) : Override {
    $self->emit(srv_error => $err);
    Evo::Net::Srv::Role::srv_handle_error(@_);
  }
}

LISTEN_OPTS: {

  my $srv = My::Server::new();

  # default with ip
  like exception { $srv->srv_listen(ip => '::1', bad => 'foo') }, qr/unknown.+bad.+$0/;

  my $sock = $srv->srv_listen(ip => '::1');
  ok $sock->socket_reuseaddr;
  ok $sock->non_blocking;
  ok $sock->socket_nodelay;
  ok !$sock->socket_reuseport if $HAS_REUSEPORT;

  # passed with ip
  $sock = $srv->srv_listen(ip => '::1', reuseaddr => 0, nodelay => 0);
  is $sock->socket_reuseaddr, 0;
  is $sock->socket_nodelay,   0;

  # reuseport
  if ($HAS_REUSEPORT) {
    $sock = $srv->srv_listen(ip => '::1', reuseport => 1);
    is $sock->socket_reuseport, 1;
  }

  # with wildcard
  $sock = $srv->srv_listen(ip => '*');
  ok $sock->socket_reuseaddr;
  ok $sock->non_blocking;
  ok $sock->socket_nodelay;
  ok !$sock->socket_reuseport if $HAS_REUSEPORT;
  is [$sock->socket_local]->[0], '::';
}


LISTEN_RUNNING: {
  my $loop = Evo::Loop::Comp::new();
  my $srv = My::Server::new();
  $loop->realm(
    sub {
      my $sock = $srv->srv_listen(ip => '::1');
      is_deeply $srv->srv_sockets, [$sock];
      is_deeply $loop->handle_count, 1;
    }
  );
}

LISTEN_STOPPED: {
  my $loop = Evo::Loop::Comp::new();
  my $srv = My::Server::new()->srv_is_running(0);
  $loop->realm(
    sub {
      my $sock = $srv->srv_listen(ip => '::1');
      is_deeply $srv->srv_sockets, [$sock];
      is_deeply $loop->handle_count, 0;
    }
  );
}

START_STOP: {
  my $loop = Evo::Loop::Comp::new();
  my $srv = My::Server::new();
  $loop->realm(
    sub {

      $srv->srv_listen(ip => '::1') for 1 .. 3;

      $srv->srv_stop();
      like exception { $srv->srv_stop }, qr/already/;
      ok !$srv->srv_is_running;
      is $loop->handle_count, 0;

      $srv->srv_start();
      like exception { $srv->srv_start }, qr/already/;
      ok $srv->srv_is_running;
      is $loop->handle_count, 3;

    }
  );
}

CONNECTIONS: {
  my $srv = My::Server::new();
SCOPE: {
    my $obj1 = bless {n => 1}, "My::Temp";
    my $obj2 = bless {n => 2}, "My::Temp";
    my $obj3 = bless {n => 3}, "My::Temp";
    $srv->srv_streams($obj1);
    is_deeply [$srv->srv_streams], [$obj1];
    $srv->srv_streams($obj2, $obj3);
    is_deeply [sort $srv->srv_streams], [sort $obj1, $obj2, $obj3];
  }

  $srv->srv_streams({});
  is_deeply [$srv->srv_streams], [];
}

ACCEPT: {
  my $srv  = My::Server::new();
  my $sock  = $srv->srv_listen(ip => '::1');
  my $saddr = getsockname $sock;
  my $cl1   = Evo::Net::Socket::new()->socket_open();
  connect $cl1, $saddr;
  $srv->srv_accept_socket($sock);
  is_deeply [$LAST->socket_local], [$cl1->socket_remote];
  is $LAST->non_blocking,   1;
  is $LAST->socket_nodelay, 1;
}

ACCEPT_ERROR: {
  my $srv  = My::Server::new();
  my $sock  = $srv->srv_listen(ip => '::1');
  my $sock2 = $srv->srv_listen(ip => '::1');
  shutdown $sock, 2;
  my $e;
  $srv->on(srv_error => sub { $e = $_[1] })->srv_accept_socket($sock);
  is $e + 0, EINVAL;
  is_deeply $srv->srv_sockets, [$sock2];
}

done_testing;
