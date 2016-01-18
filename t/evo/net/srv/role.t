package main;
use Evo '-Lib::Net *; -Loop *; -Io::Socket; -Lib *';
use Test::Evo::Helpers '*';
use Evo 'Socket :all; Test::More; Test::Fatal; Errno EBADF';

HAS_IPV6 or plan skip_all => "No IPv6: " . $! || $@;

my $LAST;
{

  package My::Stream;
  use Evo '-Comp *';
  with -Ee, -Io::Socket::Role;
  sub ee_events { }


  package My::Server;
  use Evo '-Comp *';
  sub ee_events {qw(srv_error)}
  with -Net::Srv::Role, -Ee;
  sub srv_handle_accept($self, $sock) :
    Override { $LAST = Evo::Net::Srv::Role::srv_handle_accept($self, $sock) }

  sub srv_handle_error($self, $sock, $err) : Override {
    $self->emit(srv_error => $err);
    Evo::Net::Srv::Role::srv_handle_error(@_);
  }
}

if (HAS_REUSEPORT) {
  my $srv = My::Server::new();
  my $sock = $srv->srv_listen(ip => '::1');
  ok !$sock->socket_reuseport;
  $sock = $srv->srv_listen(ip => '::1', reuseport => 1);

  $sock = $srv->srv_listen(ip => '*');
  ok !$sock->socket_reuseport if HAS_REUSEPORT;

  $sock = $srv->srv_listen(ip => '::1', reuseport => 1);
  ok $sock->socket_reuseport;
}

LISTEN_OPTS: {

  my $srv = My::Server::new();

  # default with ip
  like exception { $srv->srv_listen(ip => '::1', bad => 'foo') }, qr/unknown.+bad.+$0/;

  my $sock = $srv->srv_listen(ip => '::1');
  ok $sock->socket_reuseaddr;
  ok $sock->handle_non_blocking;
  ok $sock->socket_nodelay;
  ok !$sock->socket_reuseport if HAS_REUSEPORT;

  # passed with ip
  $sock = $srv->srv_listen(ip => '::1');
  ok $sock->socket_reuseaddr;

  # with wildcard
  $sock = $srv->srv_listen(ip => '*');
  ok $sock->socket_reuseaddr;
  is [$sock->socket_local]->[0], '::';
}


LISTEN_RUNNING: {
  my $loop = Evo::Loop::Comp::new();
  my $srv  = My::Server::new();
  $loop->realm(
    sub {
      my $sock = $srv->srv_listen(ip => '::1');
      is_deeply $srv->srv_sockets, [$sock];
      is $loop->io_count, 1;
    }
  );
}

LISTEN_STOPPED: {
  my $loop = Evo::Loop::Comp::new();
  my $srv  = My::Server::new()->srv_is_running(0);
  $loop->realm(
    sub {
      my $sock = $srv->srv_listen(ip => '::1');
      is_deeply $srv->srv_sockets, [$sock];
      is_deeply $loop->io_count, 0;
    }
  );
}

START_STOP: {
  my $loop = Evo::Loop::Comp::new();
  my $srv  = My::Server::new();
  $loop->realm(
    sub {

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
  my $srv   = My::Server::new();
  my $sock  = $srv->srv_listen(ip => '::1');
  my $saddr = getsockname $sock;
  my $cl1   = Evo::Io::Socket::socket_open();
  connect $cl1, $saddr;
  $srv->srv_accept($sock);
  is_deeply [$LAST->socket_local],  [$cl1->socket_remote];
  is_deeply [$LAST->socket_remote], [$cl1->socket_local];
  ok $LAST->handle_non_blocking;
  ok $LAST->socket_nodelay;
}

ACCEPT_ERROR: {
  my $srv   = My::Server::new();
  my $sock  = $srv->srv_listen(ip => '::1');
  my $sock2 = $srv->srv_listen(ip => '::1');
  my $e;
  close $sock;
  local $SIG{__WARN__} = sub { };
  $srv->on(srv_error => sub { $e = $_[1] })->srv_accept($sock);
  is $e + 0, EBADF;
  is_deeply $srv->srv_sockets, [$sock2];
}

done_testing;
