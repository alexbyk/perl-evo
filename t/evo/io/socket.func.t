use Evo '-Loop *; Test::More; Test::Fatal; Socket :all; -Io::Socket; Symbol gensym';

my $HAS_REUSEPORT = eval { my $v = SO_REUSEPORT(); 1 } or diag "NO REUSEPORT $@";
my $CAN_REUSEPORT6 = eval { Evo::Io::Socket::socket_open()->socket_reuseport; 1 }
  or diag "CAN'T REUSEPORT6 $@";
my $HAS_SO_DOMAIN = eval { my $v = SO_DOMAIN(); 1 } or diag "NO SO_DOMAIN $@";


OPTS: {
  # ro
  my $sock = Evo::Io::Socket::socket_open(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  is $sock->socket_domain, AF_INET if $HAS_SO_DOMAIN;
  is $sock->socket_type, SOCK_DGRAM;
  is $sock->socket_protocol, IPPROTO_UDP;

  # rw sock
  $sock = Evo::Io::Socket::socket_open(AF_INET6);
  ok $sock->socket_reuseaddr(1)->socket_reuseaddr;
  ok $sock->socket_nodelay(1)->socket_nodelay;

  ok $sock->socket_reuseport(1)->socket_reuseport if $CAN_REUSEPORT6;

  # rw fcntl
  ok $sock->handle_non_blocking(1)->handle_non_blocking;

  # defaults
  $sock = Evo::Io::Socket::socket_open();
  is $sock->socket_domain, AF_INET6 if $HAS_SO_DOMAIN;
  is $sock->socket_type, SOCK_STREAM;
  is $sock->socket_protocol, IPPROTO_TCP;
  ok $sock->socket_nodelay;
  ok $sock->handle_non_blocking;
  ok !$sock->socket_reuseaddr;
  ok !$sock->socket_reuseport if $HAS_REUSEPORT;

}

FUNCS: {
  my $sock = Evo::Io::Socket::socket_open();
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
    = Evo::Io::Socket::socket_open()->socket_reuseaddr(1)->socket_bind($saddr6)->socket_listen(1);

  my ($ip, $port) = $serv->socket_local();
  ok $port;
  is $ip, '::1';

  # cl
  my $cl = Evo::Io::Socket::socket_open;
  connect($cl, pack_sockaddr_in6($port, $naddr6));

  # accept
  my $ch_s = $serv->socket_accept();
  is $ch_s->socket_domain, AF_INET6 if $HAS_SO_DOMAIN;
  ok $ch_s->socket_reuseaddr;


  is_deeply [$cl->socket_local],  [$ch_s->socket_remote];
  is_deeply [$cl->socket_remote], [$ch_s->socket_local];

}

done_testing;
