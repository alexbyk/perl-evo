package Evo::Lib::Net;
use Evo '-Export *';
use Socket qw(AF_INET6 AF_INET INADDR_ANY IN6ADDR_ANY
  inet_pton inet_ntop
  pack_sockaddr_in pack_sockaddr_in6 unpack_sockaddr_in unpack_sockaddr_in6
  sockaddr_family
);

use Carp 'croak';


sub net_gen_saddr_family ($ip, $port) : Export {
  $port ||= 0;

  my ($naddr, $family) = net_parse($ip);
  croak "bad ip $ip" unless $naddr;
  my $saddr
    = $family == AF_INET6 ? pack_sockaddr_in6($port, $naddr) : pack_sockaddr_in($port, $naddr);
  ($saddr, $family);
}


# return address and family(AF_INET6 AF_INET)
sub net_parse($str) : Export {
  my $addr = inet_pton(AF_INET, $str);
  return ($addr, AF_INET) if $addr;

  $addr = inet_pton(AF_INET6, $str);
  return ($addr, AF_INET6) if $addr;

  return ();
}


sub net_smart_unpack($saddr) : Export {
  my $family = sockaddr_family($saddr) or croak "sockaddr_family: $!";

  if ($family == AF_INET6) {
    my ($port, $naddr) = unpack_sockaddr_in6($saddr);
    return (inet_ntop(AF_INET6, $naddr), $port);
  }
  elsif ($family == AF_INET) {
    my ($port, $naddr) = unpack_sockaddr_in($saddr);
    return (inet_ntop(AF_INET, $naddr), $port);
  }

  croak "Unknown family $family";
}

1;

=head2 net_gen_saddr_family

Takes ip and port and returns C<saddr> and C<family>. C<saddr> can be used to bind, C<family> to call C<socket>

=head2 net_parse

Parse string C<address> and return C<naddr> and C<AF_INET> or C<AF_INET6>.
If address isn't valid ipv4|6, return empty list

=head2 net_smart_unpack

returns C<address> as string and port from the saddr structure. Die if addres isn't IVp6 or IPv4

=cut
