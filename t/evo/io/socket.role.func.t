use Evo
  '-Loop *; Test::More; Test::Fatal; Test::Evo::Helpers *; Socket :all; -Io *; Symbol gensym';

CAN_BIND6     or plan skip_all => "No IPv6: " . $!      || $@;
HAS_REUSEPORT or plan skip_all => "No REUSEPORT: " . $! || $@;

# ro
my $sock = io_socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
is $sock->io_type,     SOCK_DGRAM;
is $sock->io_protocol, IPPROTO_UDP;
is $sock->io_domain,   AF_INET if HAS_SO_DOMAIN;


# freebsd
SKIP: {
  $sock = io_socket();
  skip "NO_SO_DOMAIN", 1 unless HAS_SO_DOMAIN;
  is $sock->io_domain, AF_INET6;

  skip "Can't change IPV6_V6ONLY", 1 unless CAN_CHANGEV6ONLY;
  ok !$sock->io_v6only(0)->io_v6only;
  ok $sock->io_v6only(1)->io_v6only;
}

# defaults
$sock = io_socket();

is $sock->io_type,     SOCK_STREAM;
is $sock->io_protocol, IPPROTO_TCP;
ok $sock->io_nodelay;
ok $sock->io_non_blocking;
ok !$sock->io_reuseaddr;
ok !$sock->io_reuseport;
ok $sock->io_v6only;

ok $sock->io_reuseaddr(1)->io_reuseaddr;
ok !$sock->io_reuseaddr(0)->io_reuseaddr;

ok $sock->io_reuseport(1)->io_reuseport;
ok !$sock->io_reuseport(0)->io_reuseport;

ok $sock->io_nodelay(1)->io_nodelay;
ok !$sock->io_nodelay(0)->io_nodelay;

# rw fcntl
ok $sock->io_non_blocking(1)->io_non_blocking;
ok !$sock->io_non_blocking(0)->io_non_blocking;

ok !$sock->io_remote;
ok !$sock->io_local;

ok $sock->io_rcvbuf;
ok $sock->io_sndbuf;

done_testing;
