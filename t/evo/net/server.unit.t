package main;
use Evo '-Net::Util *; -Loop *';
use Socket ':all';
use Fcntl qw(F_GETFL O_NONBLOCK);
use Test::More;
use Test::Fatal;
use Errno 'EINVAL';

my $LAST;
{

  package My::Stream;
  use Evo '-Comp *';
  with -Ee, -Net::Socket::Role;
  sub ee_events { }


  package My::Server;
  use Evo '-Comp *';
  sub ee_events {qw(s_error s_accept)}
  with -Net::Server::Role, -Ee;
  sub handle_accept($self, $sock) { $LAST = bless $sock, 'My::Stream' }
}

LISTEN_OPTS: {

  my $serv = My::Server::new();

  # default
  like exception { $serv->s_listen(ip => '::1', bad => 'foo') }, qr/unknown.+bad.+$0/;

  my $sock = $serv->s_listen(ip => '::1');
  is $sock->socket_reuseaddr, 1;
  is $sock->socket_nb,        1;
  is $sock->socket_nodelay,   1;
  is $sock->socket_reuseport, 0;

  # passed
  $sock = $serv->s_listen(ip => '::1', reuseaddr => 0, reuseport => 1, nodelay => 0);
  is $sock->socket_reuseaddr, 0;
  is $sock->socket_nodelay,   0;
  is $sock->socket_reuseport, 1;
}


LISTEN_RUNNING: {
  my $loop = Evo::Loop::Comp::new();
  my $serv = My::Server::new();
  $loop->realm(
    sub {
      my $sock = $serv->s_listen(ip => '::1');
      is_deeply $serv->s_sockets, [$sock];
      is_deeply $loop->handle_count, 1;
    }
  );
}

LISTEN_STOPPED: {
  my $loop = Evo::Loop::Comp::new();
  my $serv = My::Server::new()->s_is_running(0);
  $loop->realm(
    sub {
      my $sock = $serv->s_listen(ip => '::1');
      is_deeply $serv->s_sockets, [$sock];
      is_deeply $loop->handle_count, 0;
    }
  );
}

START_STOP: {
  my $loop = Evo::Loop::Comp::new();
  my $serv = My::Server::new();
  $loop->realm(
    sub {

      $serv->s_listen(ip => '::1') for 1 .. 3;

      $serv->s_stop();
      like exception { $serv->s_stop }, qr/already/;
      ok !$serv->s_is_running;
      is $loop->handle_count, 0;

      $serv->s_start();
      like exception { $serv->s_start }, qr/already/;
      ok $serv->s_is_running;
      is $loop->handle_count, 3;

    }
  );
}

CONNECTIONS: {
  my $serv = My::Server::new();
SCOPE: {
    my $obj1 = bless {n => 1}, "My::Temp";
    my $obj2 = bless {n => 2}, "My::Temp";
    my $obj3 = bless {n => 3}, "My::Temp";
    $serv->s_streams($obj1);
    is_deeply [$serv->s_streams], [$obj1];
    $serv->s_streams($obj2, $obj3);
    is_deeply [sort $serv->s_streams], [sort $obj1, $obj2, $obj3];
  }

  $serv->s_streams({});
  is_deeply [$serv->s_streams], [];
}

ACCEPT: {
  my $serv  = My::Server::new();
  my $sock  = $serv->s_listen(ip => '::1');
  my $saddr = getsockname $sock;
  my $cl1   = Evo::Net::Socket::new()->socket_open();
  $cl1->socket_connect($saddr);
  $serv->s_accept_socket($sock);
  is_deeply [$LAST->socket_local], [$cl1->socket_remote];
  is $LAST->socket_nb,      1;
  is $LAST->socket_nodelay, 1;
}

ACCEPT_ERROR: {
  my $serv  = My::Server::new();
  my $sock  = $serv->s_listen(ip => '::1');
  my $sock2 = $serv->s_listen(ip => '::1');
  $sock->shutdown(2);
  my $e;
  $serv->on(s_error => sub { $e = $_[1] })->s_accept_socket($sock);
  is $e + 0, EINVAL;
  is_deeply $serv->s_sockets, [$sock2];
}

done_testing;
