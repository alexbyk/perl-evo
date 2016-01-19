package Evo::Io::Socket::Role;
use Evo '-Role *; -Lib::Net *; Symbol gensym; Carp croak';
use Socket qw(
  SOCK_STREAM AF_INET AF_INET6 SOL_SOCKET IPPROTO_TCP IPPROTO_IPV6 IPV6_V6ONLY TCP_NODELAY
  SO_REUSEADDR SO_REUSEPORT SO_DOMAIN SO_TYPE SO_PROTOCOL SO_SNDBUF SO_RCVBUF
);

sub _die($type) : prototype($) { croak "$type: $!" }

sub _opt($level, $opt, $debug, $sock, $val=undef) {
  return unpack('i', getsockopt($sock, $level, $opt) || _die $debug) if @_ == 4;
  setsockopt($sock, $level, $opt, $val) || _die $debug;
  $sock;
}


# not portable
sub io_v6only : Role { _opt(IPPROTO_IPV6, IPV6_V6ONLY, v6only => @_); }
sub io_domain : Role { _opt(SOL_SOCKET,   SO_DOMAIN,   domain => @_); }


sub io_type : Role     { _opt(SOL_SOCKET, SO_TYPE,     type     => @_); }
sub io_protocol : Role { _opt(SOL_SOCKET, SO_PROTOCOL, protocol => @_); }
sub io_rcvbuf : Role   { _opt(SOL_SOCKET, SO_RCVBUF,   rcvbuf   => @_); }
sub io_sndbuf : Role   { _opt(SOL_SOCKET, SO_SNDBUF,   sndbuf   => @_); }

sub io_reuseaddr : Role { _opt(SOL_SOCKET, SO_REUSEADDR, reuseaddr => @_); }
sub io_reuseport : Role { _opt(SOL_SOCKET, SO_REUSEPORT, reuseport => @_); }

sub io_nodelay : Role { _opt(IPPROTO_TCP, TCP_NODELAY, nodelay => @_); }


# bind and listen croak on failures
sub io_bind($s, $saddr) : Role { bind($s, $saddr) or _die "bind"; $s }
sub io_listen($s, $n) : Role { listen($s, $n) or _die "listen"; $s }

sub io_local($s) : Role {
  my $saddr = getsockname($s) or return;
  net_smart_unpack($saddr);
}

sub io_remote($s) : Role {
  my $saddr = getpeername($s) or return;
  net_smart_unpack($saddr);
}

sub io_connected($s) : Role { getpeername($s) && 1 }

sub io_accept($self) : Role {
  accept(my $child, $self) or return;
  bless $child, ref $self;
  $child->io_non_blocking(1);
}


1;
