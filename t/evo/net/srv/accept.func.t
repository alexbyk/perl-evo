package main;
use Evo '-Lib::Net *; -Loop *; -Io *; -Lib *';
use Evo 'Test::Evo::Helpers *';
use Evo 'Socket :all; Test::More; Test::Fatal; Errno EBADF';

CAN_BIND6 or plan skip_all => "No IPv6: " . $! || $@;

my $LAST;
{

  package My::Server;
  use Evo '-Class *';

  with -Net::Srv::Role;
  has 'last';
  sub srv_handle_accept ($self, $sock) : Override { $self->last($sock); $sock }

}


ACCEPT: {
  my $loop = Evo::Loop::Class::new();
  my $srv  = My::Server::new();

  # stop
  no warnings 'redefine';
  my $cl1 = io_socket();

  local *My::Server::srv_handle_accept = sub {
    use Data::Dumper;
    ok keys $loop->io_data->%*;
    $loop->io_data({});
    $LAST = $_[1];
  };

MOCK: {
    local $Evo::Loop::SINGLE = $loop;
    my $srv   = My::Server::new();
    my $sock  = $srv->srv_listen(ip => '::1');
    my $saddr = getsockname $sock;
    connect $cl1, $saddr;
    $srv->srv_accept($sock);
  }

  $loop->start;

  is_deeply [$LAST->io_local],  [$cl1->io_remote];
  is_deeply [$LAST->io_remote], [$cl1->io_local];
  ok $LAST->io_non_blocking;
  ok $LAST->io_nodelay;

}

done_testing;
