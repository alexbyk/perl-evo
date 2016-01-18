package Evo::Io::Socket::Role;
use Evo '-Role *; -Lib::Net *; Symbol gensym; Carp croak';
use Socket qw(
  SOCK_STREAM AF_INET AF_INET6 SOL_SOCKET IPPROTO_TCP TCP_NODELAY
  SO_REUSEADDR SO_REUSEPORT SO_DOMAIN SO_TYPE SO_PROTOCOL SO_SNDBUF SO_RCVBUF
);

sub _die($type) : prototype($) { croak "$type: $!" }

sub _opt($level, $opt, $debug, $sock, $val=undef) {
  return unpack('i', getsockopt($sock, $level, $opt) || _die $debug) if @_ == 4;
  setsockopt($sock, $level, $opt, $val) || _die $debug;
  $sock;
}


sub socket_domain : Role   { _opt(SOL_SOCKET, SO_DOMAIN,   domain   => @_); }
sub socket_type : Role     { _opt(SOL_SOCKET, SO_TYPE,     type     => @_); }
sub socket_protocol : Role { _opt(SOL_SOCKET, SO_PROTOCOL, protocol => @_); }
sub socket_rcvbuf : Role   { _opt(SOL_SOCKET, SO_RCVBUF,   rcvbuf   => @_); }
sub socket_sndbuf : Role   { _opt(SOL_SOCKET, SO_SNDBUF,   sndbuf   => @_); }

sub socket_reuseaddr : Role { _opt(SOL_SOCKET, SO_REUSEADDR, reuseaddr => @_); }
sub socket_reuseport : Role { _opt(SOL_SOCKET, SO_REUSEPORT, reuseport => @_); }

sub socket_nodelay : Role { _opt(IPPROTO_TCP, TCP_NODELAY, nodelay => @_); }


# bind and listen croak on failures
sub socket_bind($s, $saddr) : Role { bind($s, $saddr) or _die "bind"; $s }
sub socket_listen($s, $n) : Role { listen($s, $n) or _die "listen"; $s }

sub socket_local($s) : Role {
  my $saddr = getsockname($s) or return;
  net_smart_unpack($saddr);
}

sub socket_remote($s) : Role {
  my $saddr = getpeername($s) or return;
  net_smart_unpack($saddr);
}

sub socket_connected($s) : Role { getpeername($s) && 1 }

sub socket_accept($self) : Role {
  my $saddr = accept(my $child, $self) or return;
  bless $child, ref $self;
  $child->handle_non_blocking(1);
  $child;
}


1;
