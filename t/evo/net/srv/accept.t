package main;
use Evo '-Lib::Net *; -Loop *; -Io::Socket; -Lib *';
use Test::Evo::Helpers '*';
use Evo 'Socket :all; Test::More; Test::Fatal; Errno EBADF';

CAN_BIND6 or plan skip_all => "No IPv6: " . $! || $@;

my $LAST;
{

  package My::Server;
  use Evo '-Comp *';

  with -Net::Srv::Role;
  has 'last';
  sub srv_handle_accept($self, $sock) : Override { $self->last($sock); $sock }

}


ACCEPT: {
  my $loop = Evo::Loop::Comp::new();
  my $srv  = My::Server::new();

  # stop
  no warnings 'redefine';
  my $cl1 = Evo::Io::Socket::socket_open_nb();

  local *My::Server::srv_handle_accept = sub {
    $loop->io_data({});
    $LAST = $_[1];
  };

  $loop->realm(
    sub {
      my $srv   = My::Server::new();
      my $sock  = $srv->srv_listen(ip => '::1');
      my $saddr = getsockname $sock;
      connect $cl1, $saddr;
      $srv->srv_accept($sock);
    }
  );

  $loop->start;

  is_deeply [$LAST->socket_local],  [$cl1->socket_remote];
  is_deeply [$LAST->socket_remote], [$cl1->socket_local];
  ok $LAST->handle_non_blocking;
  ok $LAST->socket_nodelay;

}

done_testing;
