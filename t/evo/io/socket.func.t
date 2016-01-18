use Evo
  '-Loop *; Test::More; Test::Fatal; Test::Evo::Helpers *; Socket :all; -Io::Socket; Symbol gensym';

CAN_BIND6 or plan skip_all => "No IPv6: " . $! || $@;


if (HAS_SO_DOMAIN()) {
  my $sock = Evo::Io::Socket::socket_open_nb(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  is $sock->socket_domain, AF_INET;

  $sock = Evo::Io::Socket::socket_open_nb();
  is $sock->socket_domain, AF_INET6;
}

if (HAS_REUSEPORT()) {
  my $sock = Evo::Io::Socket::socket_open_nb();
  ok $sock->socket_reuseport(1);
  ok $sock->socket_reuseport(1)->socket_reuseport;
}

OPTS: {
  # ro
  my $sock = Evo::Io::Socket::socket_open_nb(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  is $sock->socket_type,     SOCK_DGRAM;
  is $sock->socket_protocol, IPPROTO_UDP;

  # rw sock
  $sock = Evo::Io::Socket::socket_open_nb(AF_INET6);

  # defaults
  $sock = Evo::Io::Socket::socket_open_nb();
  is $sock->socket_type,     SOCK_STREAM;
  is $sock->socket_protocol, IPPROTO_TCP;
  ok $sock->socket_nodelay;
  ok $sock->handle_non_blocking;
  ok !$sock->socket_reuseaddr;

  ok $sock->socket_reuseaddr(1)->socket_reuseaddr;
  ok $sock->socket_nodelay(1)->socket_nodelay;

  # rw fcntl
  ok $sock->handle_non_blocking(1)->handle_non_blocking;

}

FUNCS: {
  my $sock = Evo::Io::Socket::socket_open_nb();
  my ($addr, $port) = $sock->socket_remote;
  ok !$sock->socket_remote;
  ok !$sock->socket_local;
  ok $sock->socket_rcvbuf;
  ok $sock->socket_sndbuf;
}

BIND_LISTEN_CONNECTv6: {

  my $naddr6 = inet_pton(AF_INET6, '::1');
  my $saddr6 = pack_sockaddr_in6(0, $naddr6);
  my $serv
    = Evo::Io::Socket::socket_open_nb()->socket_reuseaddr(1)->socket_bind($saddr6)->socket_listen(1);

  my ($ip, $port) = $serv->socket_local();
  ok $port;
  is $ip, '::1';

  # cl
  my $cl = Evo::Io::Socket::socket_open_nb;

  $serv->handle_non_blocking(0); # just for test
  $cl->handle_non_blocking(0); # for test!

  connect($cl, pack_sockaddr_in6($port, $naddr6));

  # accept
  my $ch_s = $serv->socket_accept();
  is $ch_s->socket_domain, AF_INET6 if HAS_SO_DOMAIN;
  ok $ch_s->socket_reuseaddr;
  ok $ch_s->handle_non_blocking;


  is_deeply [$cl->socket_local],  [$ch_s->socket_remote];
  is_deeply [$cl->socket_remote], [$ch_s->socket_local];

}

done_testing;
