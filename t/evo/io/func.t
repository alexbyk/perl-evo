use Evo 'Test::More; Test::Fatal; Socket :all; -Io *; File::Temp tempfile; Test::Evo::Helpers *';

CAN_BIND6     or plan skip_all => "No IPv6: " . $!      || $@;
HAS_SO_DOMAIN or plan skip_all => "No SO_DOMAIN: " . $! || $@;
HAS_REUSEPORT or plan skip_all => "No REUSEPORT: " . $! || $@;

HANDLE: {
  my $str = "hello";
  my ($fh, $filename) = tempfile();
  my $io = io_open('>', $filename);
  ok fileno $io;
  ok $io->io_non_blocking(1);

  # anon
  $io = io_open_anon;
  ok fileno $io;
  ok $io->io_non_blocking(1);
  ok !$io->io_non_blocking(0)->io_non_blocking;
  ok $io->io_non_blocking(1)->io_non_blocking;
}

SOCKET: {
  my $sock = io_socket();
  ok $sock->io_non_blocking;
  ok fileno $sock;
}

# listen
OPTS: {
  like exception { io_listen() }, qr/provide ip.+$0/i;
  like exception { io_listen(ip => '*', bad => 33) }, qr/unknown.+bad.+$0/i;

  # ip, anyport
  my $sock = io_listen(ip => '::1', reuseport => 1);
  ok $sock->io_reuseaddr;
  ok $sock->io_reuseport;
  my ($ip, $port) = $sock->io_local;

  # ip, port
  $sock = io_listen(ip => '::1', port => $port, reuseport => 1);
  ok $sock->io_reuseaddr;
  ok $sock->io_reuseport;
  is_deeply [$sock->io_local], [$ip, $port];

  # default with ip
  $sock = io_listen(ip => '::1');
  ok $sock->io_reuseaddr;
  ok !$sock->io_reuseport;

  # default with any
  $sock = io_listen(ip => '*');
  ok $sock->io_reuseaddr;
  ok !$sock->io_reuseport;
  is [$sock->io_local]->[0], '::';

}

BIND_LISTEN_CONNECTv6: {
  my $serv = io_listen(ip => '*');


  my $cl  = io_socket;
  my $cl4 = io_socket(AF_INET);
  $serv->io_non_blocking(0);    # just for test
  $cl->io_non_blocking(0);      # for test!
  $cl4->io_non_blocking(0);     # for test!

  my ($ip, $port) = $serv->io_local;

  # 6
  my $naddr6 = inet_pton(AF_INET6, '::1');
  connect($cl, pack_sockaddr_in6($port, $naddr6)) or die $!;
  my $conn6 = $serv->io_accept();

  is $conn6->io_domain, AF_INET6;
  ok $conn6->io_reuseaddr;
  ok $conn6->io_non_blocking;

  is_deeply [$cl->io_local],  [$conn6->io_remote];
  is_deeply [$cl->io_remote], [$conn6->io_local];

  my $naddr4 = inet_pton(AF_INET, '127.0.0.1');
  connect($cl4, pack_sockaddr_in($port, $naddr4)) or die $!;
  my $conn4 = $serv->io_accept();
  is $conn4->io_domain, AF_INET6;
  ok $conn4->io_reuseaddr;
  ok $conn4->io_non_blocking;

  is [$cl4->io_remote]->[1],  $port;
  is [$conn4->io_local]->[1], $port;

}


done_testing;
