use Evo 'Test::More; Evo::Internal::Exception; Evo::Lib::Net *, net_gen_saddr_family:gen';
use Socket ':all';

# net_parse
is_deeply [net_parse('127.0.0.1')],       [inet_pton(AF_INET,  '127.0.0.1'),       AF_INET];
is_deeply [net_parse('0:0:0:0:0:0:0:1')], [inet_pton(AF_INET6, '0:0:0:0:0:0:0:1'), AF_INET6];
is_deeply [net_parse('::1')],             [inet_pton(AF_INET6, '0:0:0:0:0:0:0:1'), AF_INET6];
is_deeply [net_parse('2001:cdba:0000:0000:0000:0000:3257:9652')],
  [inet_pton(AF_INET6, '2001:cdba:0000:0000:0000:0000:3257:9652'), AF_INET6];

is_deeply [net_parse('bad.valu')], [];


# net_smart_unpack
my $saddr = pack_sockaddr_in6(80, inet_pton(AF_INET6, '::1'));
is_deeply [net_smart_unpack($saddr)], ['::1', 80];

$saddr = pack_sockaddr_in(80, inet_pton(AF_INET, '127.0.0.1'));
is_deeply [net_smart_unpack($saddr)], ['127.0.0.1', 80];

GEN_SAF: {

  like exception { gen('BAD', 80); }, qr/bad ip BAD.+$0/;

  # ip6 port
  my ($saddr, $family) = gen('::1', 80);
  is_deeply [net_smart_unpack($saddr)], ['::1', 80];
  is $family, AF_INET6;

  # ip4 port
  ($saddr, $family) = gen('127.0.0.1', 80);
  is_deeply [net_smart_unpack($saddr)], ['127.0.0.1', 80];
  is $family, AF_INET;

  # anyv6 port
  ($saddr, $family) = gen('::', 80);
  is_deeply [net_smart_unpack($saddr)], ['::', 80];
  is $family, AF_INET6;

  # anyv4 port
  ($saddr, $family) = gen('0.0.0.0', 80);
  is_deeply [net_smart_unpack($saddr)], ['0.0.0.0', 80];
  is $family, AF_INET;

  # ipv6 gen
  ($saddr, $family) = gen('::1', undef);
  is_deeply [net_smart_unpack($saddr)]->[0], '::1';
  is $family, AF_INET6;
}


done_testing;
