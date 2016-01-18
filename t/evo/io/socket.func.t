use Evo
  '-Loop *; Test::More; Test::Fatal; Test::Evo::Helpers *; Socket :all; -Io *; Symbol gensym';

CAN_BIND6 or plan skip_all => "No IPv6: " . $! || $@;


if (HAS_SO_DOMAIN()) {
  my $sock = io_socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  is $sock->io_domain, AF_INET;

  $sock = io_socket();
  is $sock->io_domain, AF_INET6;
}

if (HAS_REUSEPORT()) {
  my $sock = io_socket();
  ok $sock->io_reuseport(1);
  ok $sock->io_reuseport(1)->io_reuseport;
}

OPTS: {
  # ro
  my $sock = io_socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  is $sock->io_type,     SOCK_DGRAM;
  is $sock->io_protocol, IPPROTO_UDP;

  # rw sock
  $sock = io_socket(AF_INET6);

  # defaults
  $sock = io_socket();
  is $sock->io_type,     SOCK_STREAM;
  is $sock->io_protocol, IPPROTO_TCP;
  ok $sock->io_nodelay;
  ok $sock->io_non_blocking;
  ok !$sock->io_reuseaddr;

  ok $sock->io_reuseaddr(1)->io_reuseaddr;
  ok $sock->io_nodelay(1)->io_nodelay;

  # rw fcntl
  ok $sock->io_non_blocking(1)->io_non_blocking;

}

FUNCS: {
  my $sock = io_socket();
  my ($addr, $port) = $sock->io_remote;
  ok !$sock->io_remote;
  ok !$sock->io_local;
  ok $sock->io_rcvbuf;
  ok $sock->io_sndbuf;
}

BIND_LISTEN_CONNECTv6: {

  my $naddr6 = inet_pton(AF_INET6, '::1');
  my $saddr6 = pack_sockaddr_in6(0, $naddr6);
  my $serv
    = io_socket()->io_reuseaddr(1)->io_bind($saddr6)->io_listen(1);

  my ($ip, $port) = $serv->io_local();
  ok $port;
  is $ip, '::1';

  # cl
  my $cl = io_socket;

  $serv->io_non_blocking(0); # just for test
  $cl->io_non_blocking(0); # for test!

  connect($cl, pack_sockaddr_in6($port, $naddr6));

  # accept
  my $ch_s = $serv->io_accept();
  is $ch_s->io_domain, AF_INET6 if HAS_SO_DOMAIN;
  ok $ch_s->io_reuseaddr;
  ok $ch_s->io_non_blocking;


  is_deeply [$cl->io_local],  [$ch_s->io_remote];
  is_deeply [$cl->io_remote], [$ch_s->io_local];

}

done_testing;
