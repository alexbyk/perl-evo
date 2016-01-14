package main;
use Evo '-Loop *; Test::More; Test::Fatal; Socket :all; -Net::Socket; Symbol gensym';
use Fcntl qw(F_GETFL O_NONBLOCK);

OPTS: {
  # ro
  my $sock = Evo::Net::Socket::new()->socket_open(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  is $sock->socket_domain,   AF_INET;
  is $sock->socket_type,     SOCK_DGRAM;
  is $sock->socket_protocol, IPPROTO_UDP;

  # rw sock
  $sock = Evo::Net::Socket::new()->socket_open(AF_INET6);
  is $sock->socket_reuseaddr(1)->socket_reuseaddr, 1;
  is $sock->socket_reuseport(1)->socket_reuseport, 1;
  is $sock->socket_nodelay(1)->socket_nodelay,     1;

  # rw fcntl
  is $sock->socket_nb(1)->socket_nb, 1;

  # defaults
  $sock = Evo::Net::Socket::new()->socket_open();
  is $sock->socket_domain,    AF_INET6;
  is $sock->socket_type,      SOCK_STREAM;
  is $sock->socket_protocol,  IPPROTO_TCP;
  is $sock->socket_nodelay,   0;
  is $sock->socket_nb,        0;
  is $sock->socket_reuseaddr, 0;
  is $sock->socket_reuseport, 0;

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
  $cl->socket_connect(pack_sockaddr_in6($port, $naddr6));

  # accept
  my ($ch_s, $err) = $serv->socket_accept();
  ok !$err;
  is $ch_s->socket_domain, AF_INET6;
  ok $ch_s->socket_reuseaddr;


  is_deeply [$cl->socket_local],  [$ch_s->socket_remote];
  is_deeply [$cl->socket_remote], [$ch_s->socket_local];

}

done_testing;
