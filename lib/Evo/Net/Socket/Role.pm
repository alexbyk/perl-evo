package Evo::Net::Socket::Role;
use Evo '-Comp::Role *; -Net::Util *; Symbol gensym; Carp croak';
use Socket qw(
  SOCK_STREAM AF_INET AF_INET6 SOL_SOCKET IPPROTO_TCP TCP_NODELAY
  SO_REUSEADDR SO_REUSEPORT SO_DOMAIN SO_TYPE SO_PROTOCOL SO_SNDBUF SO_RCVBUF
);
use Fcntl qw(F_SETFL F_GETFL O_NONBLOCK);

sub _die($type) : prototype($) { croak "$type: $!" }

sub socket_open : Role {
  my ($s, $family, $type, $proto) = @_;
  croak "Already opened" if fileno $s;
  socket($s, $family || AF_INET6, $type || SOCK_STREAM, $proto || IPPROTO_TCP) || die "socket: $!";
  $s;
}

sub _opt($level, $opt, $debug, $sock, $val=undef) {
  return unpack('i', getsockopt($sock, $level, $opt) || _die $debug) if @_ == 4;
  setsockopt($sock, $level, $opt, $val) || _die $debug;
  $sock;
}


sub socket_domain : Role   { _opt(SOL_SOCKET, SO_DOMAIN,   domain   => @_); }
sub socket_type : Role     { _opt(SOL_SOCKET, SO_TYPE,     type     => @_); }
sub socket_protocol : Role { _opt(SOL_SOCKET, SO_PROTOCOL, protocol => @_); }

sub socket_reuseaddr : Role { _opt(SOL_SOCKET, SO_REUSEADDR, reuseaddr => @_); }
sub socket_reuseport : Role { _opt(SOL_SOCKET, SO_REUSEPORT, reuseport => @_); }
sub socket_rcvbuf : Role    { _opt(SOL_SOCKET, SO_RCVBUF,    rcvbuf    => @_); }
sub socket_sndbuf : Role    { _opt(SOL_SOCKET, SO_SNDBUF,    sndbuf    => @_); }

sub socket_nodelay : Role { _opt(IPPROTO_TCP, TCP_NODELAY, nodelay => @_); }

sub _fopt($flag, $debug, $s, $val=undef) {
  my $flags = fcntl($s, F_GETFL, 0) or _die $debug;
  return !!($flags & $flag) + 0 if @_ == 3;
  fcntl($s, F_SETFL, $flags | $flag) or _die $debug;
  $s;
}

sub non_blocking : Role { _fopt(O_NONBLOCK, "nb", @_) }

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

role_gen socket_accept => sub($class) {
  sub($s) {
    my $saddr = accept(my $child, $s) or return;
    bless $child, $class;
  };
};


1;
