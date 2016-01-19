use Evo
  '-Loop *; Test::More; Test::Fatal; Test::Evo::Helpers *; Socket :all; -Io *; Symbol gensym';

CAN_BIND6     or plan skip_all => "No IPv6: " . $!      || $@;
HAS_SO_DOMAIN or plan skip_all => "No SO_DOMAIN: " . $! || $@;
HAS_REUSEPORT or plan skip_all => "No REUSEPORT: " . $! || $@;

# ro
my $sock = io_socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
is $sock->io_type,     SOCK_DGRAM;
is $sock->io_protocol, IPPROTO_UDP;
is $sock->io_domain,   AF_INET;

# defaults
$sock = io_socket();
is $sock->io_type,     SOCK_STREAM;
is $sock->io_protocol, IPPROTO_TCP;
is $sock->io_domain,   AF_INET6;
ok $sock->io_nodelay;
ok $sock->io_non_blocking;
ok !$sock->io_reuseaddr;
ok !$sock->io_reuseport;

ok $sock->io_reuseaddr(1)->io_reuseaddr;
ok $sock->io_reuseport(1)->io_reuseport;
ok $sock->io_nodelay(1)->io_nodelay;

# rw fcntl
ok $sock->io_non_blocking(1)->io_non_blocking;
ok !$sock->io_non_blocking(0)->io_non_blocking;

ok !$sock->io_remote;
ok !$sock->io_local;

ok $sock->io_rcvbuf;
ok $sock->io_sndbuf;

done_testing;
