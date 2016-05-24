package Evo::Io::Socket;
use Evo -Class::Out;
with 'Evo::Io::Handle';

use Evo '-Lib::Net *; Symbol gensym; Carp croak';
use Socket qw(
  SOCK_STREAM AF_INET AF_INET6 SOL_SOCKET IPPROTO_TCP IPPROTO_IPV6 IPV6_V6ONLY TCP_NODELAY
  SO_REUSEADDR SO_REUSEPORT SO_DOMAIN SO_TYPE SO_PROTOCOL SO_SNDBUF SO_RCVBUF
);

sub _die($type) : prototype($) { croak "$type: $!" }

sub _opt ($level, $opt, $debug, $sock, $val = undef) {
  return unpack('i', getsockopt($sock, $level, $opt) || _die $debug) if @_ == 4;
  setsockopt($sock, $level, $opt, $val) || _die $debug;
  $sock;
}


# not portable
sub io_v6only : Public { _opt(IPPROTO_IPV6, IPV6_V6ONLY, v6only => @_); }
sub io_domain : Public { _opt(SOL_SOCKET,   SO_DOMAIN,   domain => @_); }


sub io_type : Public     { _opt(SOL_SOCKET, SO_TYPE,     type     => @_); }
sub io_protocol : Public { _opt(SOL_SOCKET, SO_PROTOCOL, protocol => @_); }
sub io_rcvbuf : Public   { _opt(SOL_SOCKET, SO_RCVBUF,   rcvbuf   => @_); }
sub io_sndbuf : Public   { _opt(SOL_SOCKET, SO_SNDBUF,   sndbuf   => @_); }

sub io_reuseaddr : Public { _opt(SOL_SOCKET, SO_REUSEADDR, reuseaddr => @_); }
sub io_reuseport : Public { _opt(SOL_SOCKET, SO_REUSEPORT, reuseport => @_); }

sub io_nodelay : Public { _opt(IPPROTO_TCP, TCP_NODELAY, nodelay => @_); }


# bind and listen croak on failures
sub io_bind ($s, $saddr) : Public { bind($s, $saddr) or _die "bind"; $s }
sub io_listen ($s, $n) : Public { listen($s, $n) or _die "listen"; $s }

sub io_local($s) : Public {
  my $saddr = getsockname($s) or return;
  net_smart_unpack($saddr);
}

sub io_remote($s) : Public {
  my $saddr = getpeername($s) or return;
  net_smart_unpack($saddr);
}

sub io_connected($s) : Public { getpeername($s) && 1 }

sub io_accept($self) : Public {
  accept(my $child, $self) or return;
  bless $child, ref $self;
  $child->io_non_blocking(1);
}


1;

=head1 METHODS


=head2 io_local

=head2 io_remote

  my ($ip, $port) = $sock->io_remote;
  ($ip, $port) = $sock->io_local;

More frienly results than C<getpeername> and C<getsockname> 

=head2 io_accept

Instead of saddr return a new socket and initiate with the C<init> method of the derived class


=head1 Info

  say $sock->io_reuseaddr(1)->io_reuseaddr;    # 1

=head2 read only

=over


=item * io_domain 

=item * io_type

=item * io_protocol 

=back

=head2 read/write

=over

=item * io_reuseaddr

=item * io_reuseport

=item * io_nodelay

=item * io_rcvbuf

=item * io_sndbuf

=item * non_blocking

=back



=cut
