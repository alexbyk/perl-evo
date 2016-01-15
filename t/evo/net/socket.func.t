package main;
use Evo '-Loop *; Test::More; Test::Fatal; Socket :all; -Net::Socket; Symbol gensym';

my $HAS_REUSEPORT = eval { my $v = SO_REUSEPORT(); 1 };

OPTS: {
  # ro
  my $sock = Evo::Net::Socket::new()->socket_open(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  is $sock->socket_domain,   AF_INET;
  is $sock->socket_type,     SOCK_DGRAM;
  is $sock->socket_protocol, IPPROTO_UDP;

  # rw sock
  $sock = Evo::Net::Socket::new()->socket_open(AF_INET6);
  is $sock->socket_reuseaddr(1)->socket_reuseaddr, 1;
  is $sock->socket_nodelay(1)->socket_nodelay,     1;

  is $sock->socket_reuseport(1)->socket_reuseport, 1 if $HAS_REUSEPORT;

  # rw fcntl
  is $sock->non_blocking(1)->non_blocking, 1;

  # defaults
  $sock = Evo::Net::Socket::new()->socket_open();
  is $sock->socket_domain,    AF_INET6;
  is $sock->socket_type,      SOCK_STREAM;
  is $sock->socket_protocol,  IPPROTO_TCP;
  is $sock->socket_nodelay,   0;
  is $sock->non_blocking,     0;
  is $sock->socket_reuseaddr, 0;
  is $sock->socket_reuseport, 0 if $HAS_REUSEPORT;

}

FUNCS: {
  my $sock = Evo::Net::Socket::new()->socket_open();
  my ($addr, $port) = $sock->socket_remote;
  ok !$sock->socket_remote;
  ok !$sock->socket_local;
  ok $sock->socket_rcvbuf;
  ok $sock->socket_sndbuf;
}

BIND_LISTEN_CONNECTv6: {

  my $naddr6 = inet_pton(AF_INET6, '::1');
  my $saddr6 = pack_sockaddr_in6(0, $naddr6);
  my $serv = Evo::Net::Socket::new()->socket_open()->socket_reuseaddr(1)->socket_bind($saddr6)
    ->socket_listen(1);

  my ($ip, $port) = $serv->socket_local();
  ok $port;
  is $ip, '::1';

  # cl
  my $cl = Evo::Net::Socket::new()->socket_open;
  connect($cl, pack_sockaddr_in6($port, $naddr6));

  # accept
  my $ch_s = $serv->socket_accept();
  is $ch_s->socket_domain, AF_INET6;
  ok $ch_s->socket_reuseaddr;


  is_deeply [$cl->socket_local],  [$ch_s->socket_remote];
  is_deeply [$cl->socket_remote], [$ch_s->socket_local];

}

done_testing;
